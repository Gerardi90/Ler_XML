USE [OCSVAR]
GO
/****** Object:  StoredProcedure [dbo].[ProcessarXML]    Script Date: 09/23/2024 15:43:52 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[ProcessarXML]
  @CAMINHO NVARCHAR(255)
AS BEGIN

--DECLARE @CAMINHO VARCHAR(255)
--SET @CAMINHO = 'C:\XML\NF.txt'

declare @xmlcom xml;

IF OBJECT_ID('tempdb..#FileContent') IS NOT NULL
BEGIN
    DROP TABLE #FileContent;
END

-- Tabela temp para colocar conteudo XML
CREATE TABLE #FileContent (
    Content XML
);


-- Construir a consulta dinâmica, pois não aceita variavel em BULK
DECLARE @sql NVARCHAR(MAX);
SET @sql = N'
INSERT INTO #FileContent (Content)
SELECT CAST(BulkColumn AS XML)
FROM OPENROWSET(
    BULK ''' + @CAMINHO + ''',
    SINGLE_CLOB
) AS FileContent;';

-- Executar a consulta dinâmica
EXEC sp_executesql @sql;

DECLARE @xml XML;

-- Atribuir o conteúdo da tabela temporária à variável
SELECT @xml = Content
FROM #FileContent;

--- ROTINA PRA TIRAR LINK PARA NAO DAR ERRO NA TAG
SET @xml = REPLACE(
    REPLACE(
        CAST(@xml AS NVARCHAR(MAX)),
        ' xmlns="http://www.portalfiscal.inf.br/nfe"',
        ''
    ),
    '<NFe>',
    '<NFe xmlns="">'
);

IF OBJECT_ID('tempdb..#CNPJ') IS NOT NULL
BEGIN
    DROP TABLE #CNPJ;
END

IF OBJECT_ID('tempdb..#Produtos') IS NOT NULL
BEGIN
    DROP TABLE #Produtos;
END

IF OBJECT_ID('tempdb..#DadosNota') IS NOT NULL
BEGIN
    DROP TABLE #DadosNota;
END


CREATE TABLE #DadosNota (
    NumeroNota NVARCHAR(50),
    Serie NVARCHAR(50),
    ValorTotal NUmeric(18,2),
    Frete NUmeric(18,2),
    PesoTotal decimal(18,2),
    ICMS NUMERIC(18,2)
);

CREATE TABLE #CNPJ (
    Tipo NVARCHAR(10),
    CNPJ NVARCHAR(14)
);

CREATE TABLE #Produtos (
    cProd NVARCHAR(18),
    xProd NVARCHAR(255),
    quantidade decimal(9,2),
    valor numeric(18,2),
    ean numeric(15,0),
    ncm numeric(15,0),
    unidade varchar(20)
);

-- DADOS EM VARIAVEIS
DECLARE @VALOR_TOTAL NUMERIC(18,2)
SET @VALOR_TOTAL = (SELECT
    Ide.value('(vNF)[1]', 'NUMERIC') AS ValorTotalNota
FROM @xml.nodes('nfeProc/NFe/infNFe/total/ICMSTot') AS I(Ide))

DECLARE @VALOR_FRETE NUMERIC(18,2)
SET @VALOR_FRETE = (SELECT
    Ide.value('(vFrete)[1]', 'NUMERIC') AS ValorFrete
FROM @xml.nodes('nfeProc/NFe/infNFe/total/ICMSTot') AS I(Ide))

DECLARE @PESO_TOTAL DECIMAL(18, 3);
SET @PESO_TOTAL = (
    SELECT
        SUM(CASE
                WHEN ISNUMERIC(Ide.value('(pesoL)[1]', 'NVARCHAR(MAX)')) = 1
                THEN CAST(Ide.value('(pesoL)[1]', 'NVARCHAR(MAX)') AS DECIMAL(18,3))
                ELSE 0
            END)
    FROM @xml.nodes('nfeProc/NFe/infNFe/transp/vol') AS I(Ide)
);

DECLARE @ICMS NUMERIC(18,2)
SET @ICMS = (
SELECT
    Ide.value('(vICMS)[1]', 'NUMERIC') AS ICMS
FROM @xml.nodes('nfeProc/NFe/infNFe/total/ICMSTot') AS I(Ide))

-- PEGAR CABEÇALHO
INSERT INTO #DadosNota (NumeroNota, Serie, ValorTotal, Frete, PesoTotal, ICMS)
SELECT
    Ide.value('(nNF)[1]', 'NVARCHAR(50)') AS NumeroNota,
    Ide.value('(serie)[1]', 'NVARCHAR(50)') AS Serie,
    @VALOR_TOTAL AS ValorTotal,
    @VALOR_FRETE AS Frete,
    @PESO_TOTAL AS PesoTotal,
    @ICMS AS IcmsTotal
FROM @xml.nodes('nfeProc/NFe/infNFe/ide') AS I(Ide);

DECLARE @NumeroNF varchar(30)
DECLARE @serie varchar(30)

SET @NumeroNf = (SELECT TOP 1 NumeroNota from #DadosNota)
SET @Serie = (SELECT TOP 1 serie from #DadosNota)


-- EMITENTE E DESTINATARIO
INSERT INTO #CNPJ (Tipo, CNPJ)
SELECT
    'Emit' AS Tipo,
    Emit.value('(CNPJ)[1]', 'NVARCHAR(14)') AS CNPJ
FROM @xml.nodes('nfeProc/NFe/infNFe/emit') AS E(Emit)
UNION ALL
SELECT
    'Dest' AS Tipo,
    Dest.value('(CNPJ)[1]', 'NVARCHAR(14)') AS CNPJ
FROM @xml.nodes('nfeProc/NFe/infNFe/dest') AS D(Dest);

-- DADOS PRODUTOS
INSERT INTO #Produtos (cProd, xProd, quantidade, valor, EAN, NCM, unidade)
    SELECT
        Prod.value('(cProd)[1]', 'NVARCHAR(18)') AS cProd,
        Prod.value('(xProd)[1]', 'NVARCHAR(255)') AS xProd,
        Prod.value('(qCom)[1]', 'DECIMAL') AS quantidade,
        Prod.value('(vUnCom)[1]', 'NUMERIC(9,2)') AS valor,
        CASE 
            WHEN Prod.value('(cEAN)[1]', 'VARCHAR(20)') = 'SEM GTIN' THEN 0
         ELSE Prod.value('(cEAN)[1]', 'NUMERIC')
         END AS EAN, 
        Prod.value('(NCM)[1]', 'NUMERIC') AS NCM,
        Prod.value('(uCom)[1]', 'VARCHAR(20)') AS UNIDADE
FROM @xml.nodes('nfeProc/NFe/infNFe/det/prod') AS P(Prod)
 


---- ROTINA PRA VER QUAL É A EMPRESA
DECLARE @CNPJ_DEST VARCHAR(30)
SET @CNPJ_DEST = (SELECT CNPJ FROM #CNPJ WHERE TIPO = 'Dest')

DECLARE @CODEMP NUMERIC(9) 
SET @CODEMP = (SELECT
isnull(codloj,1) FROM 
cadloj 
where 
REPLACE(REPLACE(REPLACE(REPLACE(cnpj, '.', ''), '-', ''), '/', ''), ' ', '')
 = @CNPJ_DEST)
---------------------------------------------


---- ROTINA PRA PEGAR FORNECEDOR
DECLARE @CNPJ_EMIT VARCHAR(30)
SET @CNPJ_EMIT = (SELECT CNPJ FROM #CNPJ WHERE TIPO = 'Emit')

declare @fornecedor numeric(12, 0)

set @fornecedor = (select codigo from participante where cpf_cnpj = @CNPJ_EMIT)
------ ROTINA PARA CADASTRAR FORNECEDOR CASO NÃO EXISTA
IF @fornecedor IS NULL
BEGIN

set @fornecedor = (select max(codigo) + 1 from participante)

DECLARE @INSCRI NUMERIC(12)
SET @INSCRI = (SELECT Emit.value('(IE)[1]', 'NUMERIC(12,0)') AS inscri
FROM @xml.nodes('nfeProc/NFe/infNFe/emit') AS E(Emit))

DECLARE @ENDERE VARCHAR(100)
DECLARE @BAIRRO VARCHAR(100)
DECLARE @COMPLE VARCHAR(100)
DECLARE @NUMERO NUMERIC(12)
DECLARE @CEP NUMERIC(8)
DECLARE @ESTADO VARCHAR(2)

SET @ENDERE = (SELECT Emit.value('(xLgr)[1]',  'VARCHAR(200)') FROM @xml.nodes('nfeProc/NFe/infNFe/emit/enderEmit')   AS E(Emit))
SET @NUMERO = (SELECT Emit.value('(nro)[1]',   'NUMERIC(9)')   FROM @xml.nodes('nfeProc/NFe/infNFe/emit/enderEmit')   AS E(Emit))
SET @COMPLE = (SELECT Emit.value('(Cpl)[1]', 'VARCHAR(200)')   FROM @xml.nodes('nfeProc/NFe/infNFe/emit/enderEmit')   AS E(Emit))
SET @BAIRRO = (SELECT Emit.value('(xBairro)[1]', 'VARCHAR(200)')FROM @xml.nodes('nfeProc/NFe/infNFe/emit/enderEmit')   AS E(Emit))
SET @CEP = (SELECT Emit.value('(CEP)[1]', 'VARCHAR(200)')FROM @xml.nodes('nfeProc/NFe/infNFe/emit/enderEmit')   AS E(Emit))
SET @ESTADO = (SELECT Emit.value('(UF)[1]', 'VARCHAR(200)')FROM @xml.nodes('nfeProc/NFe/infNFe/emit/enderEmit')   AS E(Emit))


INSERT INTO PARTICIPANTE 
SELECT
    @FORNECEDOR                                AS CODIGO,
    @CNPJ_EMIT                                 AS CNPJ,
    Emit.value('(xNome)[1]', 'VARCHAR(200)')   AS nome,
    Emit.value('(xNome)[1]', 'VARCHAR(200)')   AS nome_fantasia,
    @ENDERE                                    AS endere,
    @NUMERO                                    AS numero,
    @COMPLE                                    AS comple,
    @BAIRRO                                    AS bairro,
    0                                          AS codcid,
    @ESTADO                                    AS estado,
    @CEP                                       AS CEP,
    0                                          AS dddtel,
    0                                          AS TL1CEL,
    0                                          AS TL2CEL,
    0                                          AS DDDCEL,
    0                                          AS TELCEL,
    ''                                         AS EMAIL,
    'ATIVO'                                    AS SITUAC,
    @INSCRI                                    AS INSCRI,
    0                                          AS CHKCLI,
    1                                          AS CHKFOR,
    ''                                         AS OBSERV,
    ''                                         AS CONTATO,
    0                                          AS CODVEN,
    0                                          AS CODCON,
    GETDATE()                                  AS DATINC,
    'JURÍDICA'                                 AS FISJUR,
    GETDATE()                                  AS DATNAS
FROM @xml.nodes('nfeProc/NFe/infNFe/emit') AS E(Emit)

END
---------------------------------------------

-- Inserir os dados em tabela
INSERT INTO DADOSNOTA_XML
SELECT * FROM #DADOSNOTA

INSERT INTO CNPJ_XML
SELECT @numeroNF, @Serie, TIPO, CNPJ FROM #CNPJ

INSERT INTO PRODUTOS_XML
select @NUMERONF, @SERIE, cProd, xProd, quantidade, Valor, EAN, NCM, unidade from #Produtos

INSERT INTO XML_lOG (CAMPO_XML, DATA_LOG, CAMINHO, NUMERONOTA, SERIE) VALUES (@XML, GETDATE(), @CAMINHO,@numeroNF, @Serie)

insert into Prod_NaoCadastrados_XML
select distinct @numeronf, @serie, cProd from produtos_xml
where cProd not in (select codpro_fornecedor from cadpro where codfor = @fornecedor) and NumeroNota = @numeroNF and serie = @serie

insert into nf_agora (codfor, numeronota, serie) values (@fornecedor, @NumeroNf, @Serie)

END


CREATE TABLE XML_LOG(
     CHAVE NUMERIC(9,0) IDENTITY PRIMARY KEY,
     CAMPO_XML XML,
     CAMINHO NVARCHAR(MAX),
     DATA_LOG DATETIME,
     NumeroNota NVARCHAR(50),
     Serie NVARCHAR(50),)

-- PARA PODER EXECUTAR CONSULTAS DINAMICAS
EXEC sp_configure 'show advanced options', 1;
RECONFIGURE;
EXEC sp_configure 'Ad Hoc Distributed Queries', 1;
RECONFIGURE;


CREATE TABLE DadosNota_XML (
    NumeroNota NVARCHAR(50),
    Serie NVARCHAR(50),
    ValorTotal NUmeric(18,2),
    Frete NUmeric(18,2),
    PesoTotal decimal(18,2),
    ICMS NUMERIC(18,2),
    PRIMARY KEY (NumeroNota, Serie)
);

CREATE TABLE CNPJ_XML (
    NumeroNota NVARCHAR(50),
    Serie NVARCHAR(50),
    Tipo NVARCHAR(10),
    CNPJ NVARCHAR(14),
    PRIMARY KEY (NumeroNota, Serie, Tipo, CNPJ)
);

CREATE TABLE Produtos_XML (
    NumeroNota NVARCHAR(50),
    Serie NVARCHAR(50),
    cProd NVARCHAR(19),
    xProd NVARCHAR(255),
    quantidade decimal(9,2),
    valor numeric(18,2),
    ean numeric(15,0),
    ncm numeric(15,0),
    unidade varchar(20)
);

CREATE TABLE Prod_NaoCadastrados_XML (
    NumeroNota NVARCHAR(50),
    Serie NVARCHAR(50),
    cProd NVARCHAR(50),
    PRIMARY KEY (NumeroNota, Serie, cProd)
);

CREATE TABLE DEPARA (
CODFOR NUMERIC(9,0),
CODPRO_FORNECEDOR NVARCHAR(18),
CODPRO NUMERIC(9,0)
PRIMARY KEY(CODFOR, CODPRO_FORNECEDOR, CODPRO)
)

CREATE TABLE NF_AGORA (
    NumeroNota NVARCHAR(50),
    Serie NVARCHAR(50),
    CODFOR NUMERIC(9,0)
    PRIMARY KEY (NumeroNota, Serie, CODFOR)
)



CREATE TABLE DePara_Unidades (
    Id INT IDENTITY(1,1) PRIMARY KEY,
    UnidadeInterna NVARCHAR(50),
    UnidadeNFe NVARCHAR(50),
    CodigoNFe NVARCHAR(10)
);

INSERT INTO DePara_Unidades (UnidadeInterna, UnidadeNFe, CodigoNFe)
VALUES ('UNIDADE', 'Unidade', 'UN');

INSERT INTO DePara_Unidades (UnidadeInterna, UnidadeNFe, CodigoNFe)
VALUES ('KG', 'Quilograma', 'KG');

INSERT INTO DePara_Unidades (UnidadeInterna, UnidadeNFe, CodigoNFe)
VALUES ('LITRO', 'Litro', 'L');

INSERT INTO DePara_Unidades (UnidadeInterna, UnidadeNFe, CodigoNFe)
VALUES ('CAIXA', 'Caixa', 'CX');

INSERT INTO DePara_Unidades (UnidadeInterna, UnidadeNFe, CodigoNFe)
VALUES ('PACOTE', 'Pacote', 'PCT');

INSERT INTO DePara_Unidades (UnidadeInterna, UnidadeNFe, CodigoNFe)
VALUES ('FARDO', 'Fardo', 'FD');

INSERT INTO DePara_Unidades (UnidadeInterna, UnidadeNFe, CodigoNFe)
VALUES ('BALDE', 'Balde', 'BD');

INSERT INTO DePara_Unidades (UnidadeInterna, UnidadeNFe, CodigoNFe)
VALUES ('LATA', 'Lata', 'LT');

INSERT INTO DePara_Unidades (UnidadeInterna, UnidadeNFe, CodigoNFe)
VALUES ('GALAO', 'Galão', 'GL');

INSERT INTO DePara_Unidades (UnidadeInterna, UnidadeNFe, CodigoNFe)
VALUES ('ROLO', 'Rolo', 'RL');

INSERT INTO DePara_Unidades (UnidadeInterna, UnidadeNFe, CodigoNFe)
VALUES ('PECA', 'Peça', 'PEC');

INSERT INTO DePara_Unidades (UnidadeInterna, UnidadeNFe, CodigoNFe)
VALUES ('1/4', '1/4', '1/4');

ALTER TABLE PARTICIPANTE
ALTER COLUMN NOMCLI VARCHAR(80);

 
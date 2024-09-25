# Ler_XML


A stored procedure ProcessarXML processa arquivos XML de notas fiscais eletrônicas (NFe). A partir do caminho do arquivo XML, ela lê o conteúdo, remove namespaces problemáticos e extrai dados como número da nota, série, valores de ICMS, frete, produtos, peso e CNPJ do emitente e destinatário.

Os dados são temporariamente armazenados em tabelas para serem manipulados e, em seguida, inseridos nas tabelas de destino do sistema. Caso o fornecedor não esteja cadastrado, a procedure também realiza seu cadastro automaticamente com as informações extraídas do XML.

Além disso, a procedure gera logs do processo e identifica produtos não cadastrados no sistema, inserindo-os em uma tabela separada para análise.

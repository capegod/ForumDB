/* CRIAÇÃO DO BANCO + SELECIONAR PARA USO*/

CREATE DATABASE forumDB;
GO

USE forumDB;
GO

/*INICIO DDL - CRIAÇÃO DAS TABELAS */

-- Tabela de estados
CREATE TABLE Estado(
	id INT IDENTITY(1,1) PRIMARY KEY,
	sigla CHAR(2),
	nome VARCHAR(30)
);
GO

-- Tabela de Usuários
CREATE TABLE Usuario(
    	id INT IDENTITY(1,1) PRIMARY KEY,
	nome VARCHAR(100) UNIQUE NOT NULL,
  	nasc DATE NOT NULL
	CHECK(DATEDIFF(year, nasc, CONVERT(DATE, GETDATE())) >= 16),
	email VARCHAR(255) UNIQUE NOT NULL,
    	senha CHAR(60) NOT NULL,
	saldo INT DEFAULT 0,
	pontuacao INT DEFAULT 0,
	id_estado INT FOREIGN KEY REFERENCES estado(id)
);
GO

-- Tabela de Tópicos
CREATE TABLE Topico(
	id INT IDENTITY(1,1) PRIMARY KEY,
	titulo VARCHAR(100) NOT NULL,
	descricao VARCHAR(5000) NOT NULL,
	data_criacao SMALLDATETIME DEFAULT SYSDATETIME(),
	id_usuario INT FOREIGN KEY REFERENCES Usuario(id),
	stat BIT NOT NULL DEFAULT 0
);
GO

-- Tabela de Respostas
CREATE TABLE Resposta(
	id INT IDENTITY(1,1) PRIMARY KEY,
	conteudo VARCHAR(5000) NOT NULL,
	data_resposta SMALLDATETIME DEFAULT SYSDATETIME(),
	resp BIT NOT NULL DEFAULT 0,
	id_usuario INT FOREIGN KEY REFERENCES Usuario(id),
	id_topico INT FOREIGN KEY REFERENCES Topico(id),
);
GO

-- Tabela da Loja
CREATE TABLE Produto(
	id INT IDENTITY(1,1) PRIMARY KEY,
	marca varchar(25),
	nome_item VARCHAR(100) NOT NULL,
	descricao VARCHAR(5000) NOT NULL,
	preco INT NOT NULL,
	quant INT DEFAULT NULL
);
GO

-- Tabela de recibos
CREATE TABLE Compra(
	id INT IDENTITY(1,1) PRIMARY KEY,
	id_item INT FOREIGN KEY REFERENCES Produto(id),
	id_usuario INT FOREIGN KEY REFERENCES Usuario(id),
	hora SMALLDATETIME DEFAULT SYSDATETIME(),
	stat VARCHAR(100)
);
GO

/* CRIAÇÃO DOS GATILHOS DO BANCO */

-- CRIAÇÃO DE TRIGGER PARA EFETUAR compra
CREATE TRIGGER efetuar_compra
ON compra
FOR INSERT
AS
BEGIN
	DECLARE @numcompra INT
	DECLARE @id_usuario INT
	DECLARE @item INT
	DECLARE @preco INT
	DECLARE @saldo INT
	DECLARE @quant INT
	

	SELECT @numcompra = id, @id_usuario = id_usuario, @item = id_item FROM inserted
	SELECT @preco = preco FROM Produto WHERE id = @item
	SELECT @saldo = saldo FROM Usuario WHERE id = @id_usuario
	SELECT @quant = quant FROM Produto WHERE id = @item

	IF @saldo >= @preco AND @quant = 0 
		BEGIN
		UPDATE compra SET stat = 'FALHOU! Não há mais itens na loja.' WHERE id = @numcompra
		END
	ELSE IF @saldo < @preco AND (@quant > 0 OR @quant IS NULL)
		BEGIN
		UPDATE compra SET stat = 'FALHOU! O usuário não tem pontos suficientes.' WHERE id = @numcompra
		END
	ELSE IF @saldo >= @preco AND (@quant > 0 OR @quant IS NULL)
		BEGIN
		UPDATE Usuario SET saldo = saldo - @preco WHERE id = @id_usuario
		UPDATE compra SET stat = 'SUCESSO! Compra efetuada.' WHERE id = @numcompra
			
		IF ISNUMERIC(@quant) = 1
			BEGIN
			UPDATE Produto SET quant = quant - 1 WHERE id = @item
			END
		END	
END
GO

-- Criação do trigger para atualização dos pontos 
CREATE TRIGGER update_pontos_topico
ON Resposta 
AFTER UPDATE
AS
BEGIN
	DECLARE @id INT
	DECLARE @topico INT

	SELECT @id = id_usuario, @topico = id_topico FROM inserted
	
	UPDATE Usuario SET saldo = saldo + 1
	WHERE id = @id

	UPDATE Usuario SET pontuacao = pontuacao + 1
	WHERE id = @id

	UPDATE Topico SET stat = 1
	WHERE id = @topico
END
GO

/* CRIAÇÃO DOS PROCEDURES DO BANCO */

-- Criação do procedure para ver histórico de compra de um usuário
-- COMANDO: EXEC Historico @user = id de um usuário
CREATE PROCEDURE Historico @user INT
AS
SELECT compra.id AS 'Nº pedido', Produto.nome_item AS 'Nome do item', compra.stat AS 'Status do Pedido', compra.hora AS 'Data e Hora'
FROM compra
INNER JOIN Produto ON compra.id_item = Produto.id
WHERE compra.id_usuario = @user;
GO

-- Criação do procedure para sinalizar 
-- uma resposta de um tópico como definitiva
-- COMANDO: EXEC responde @num = id de uma resposta
CREATE PROCEDURE responde @num INT
AS
UPDATE Resposta
SET resp = 1
WHERE id = @num;
GO

-- Criação do procedure para adicionar mais itens de um item já existente
-- COMANDO: EXEC adicionar_itens @cod_item = id do item, 
-- @quant = quantidade a ser adicionada
CREATE PROCEDURE adicionar_itens @cod_item INT, @quant INT
AS
UPDATE Produto
SET quant = quant + @quant
WHERE id = @cod_item;
GO

-- Criação do procedure que faz as compra de um item por um usuário
-- COMANDO: EXEC fazer_compra @id_item = id do item desejado, @id_usuario = id do usuário comprador
CREATE PROCEDURE fazer_compra @id_item INT, @id_usuario INT
AS
INSERT INTO compra(id_item, id_usuario)
VALUES
	(@id_item, @id_usuario);
GO

/* INICIO DO DML COM DADOS DE AMOSTRA */

-- Lista de estados brasileiros
INSERT INTO estado(sigla, nome)
VALUES
	('AC', 'Acre'),
	('AL', 'Alagoas'),
	('AP', 'Amapá'),
	('AM', 'Amazonas'),
	('BA', 'Bahia'),
	('CE', 'Ceará'),
	('DF', 'Distrito Federal'),
	('ES', 'Espírito Santo'),
	('GO', 'Goiás'),
	('MA', 'Maranhão'),
	('MT', 'Mato Grosso'),
	('MS', 'Mato Grosso do Sul'),
	('MG', 'Minas Gerais'),
	('PA', 'Pará'),
	('PB', 'Paraíba'),
	('PR', 'Paraná'),
	('PE', 'Pernambuco'),
	('PI', 'Piauí'),
	('RJ', 'Rio de Janeiro'),
	('RN', 'Rio Grande do Norte'),
	('RS', 'Rio Grande do Sul'),
	('RO', 'Rondônia'),
	('RR', 'Roraima'),
	('SC', 'Santa Catarina'),
	('SP', 'São Paulo'),
	('SE', 'Sergipe'),
	('TO', 'Tocantins');
GO

-- AMOSTRA DE USUÁRIOS
INSERT INTO Usuario(nome, nasc, email, senha, id_estado)
VALUES 
	('Amanda', '1996-07-19', 'amanda@gmail.com', '$2a$12$okBbHPzatD3LfsR9.seTlucsGmRbK2aY5YPspFNt/eZ3HvLQra6xy', 5),
	('Jorge', '1987-02-20', 'jorge@gmail.com', '$2a$12$59bfLAu1DmihSln.1ikGW.ASfgvhqXQ214g//EUM3S9jIkOrqUy0a', 7),
	('Baptiste', '2000-05-14', 'baptiste@gmail.com', '$2a$12$AgY3jduT2MeEq15p1AihbO8WqUFKJVhGOmAiMKyCGgVv2XtnljMOq', 15),
	('QT', '2006-11-11', 'QT@gmail.com', '$2a$12$F/UBFO8LHq9z952LIPhdM.Bqbowg.0eXL.tXDpbPK2dyzyCwyEH8S', 9),
	('Babi', '2008-11-11', 'Babi@gmail.com', '$2a$12$lVw9KbQm0/uytEwPkgy3EOHiTtGJ8ocGcjmVX5NRuRGlza4aG/DCG', 10),
	('Rossi', '2008-11-20', 'Rossi@gmail.com', '$2a$12$FxXiH9MhMcOadvTgvnQo2O9x9l2eWJWzo5zRStQwVHwqq8JSgzIOG', 4),
	('Trevor', '2008-12-01', 'Trevor@gmail.com', '$2a$12$KA2/OzT8t84fr8iFJ8y4.e9cw0IhD019wbVOmuCB0s6AFPIdk0CGu', 20),
	('Sheila', '2008-12-01', 'Sheila@gmail.com', '$2a$12$76PzYQY.xN4SpJT4CgWQRuQhdbYGSxQwH.jGvDfljt52n.ZeDfe5G', 13);
GO

-- AMOSTRA DE TÓPICO
INSERT INTO Topico(titulo, descricao, id_usuario)
VALUES
	('Dúvida sobre regra de três simples', 'Como faço para resolver uma regra de três simples?', 3);
GO

-- AMOSTRA DE RESPOSTA
INSERT INTO Resposta(conteudo, id_usuario, id_topico)
VALUES
	('Basta multiplicar os valores em cruz e depois dividir pelo que sobrar!', 7, 1);
GO

-- AMOSTRA DE ITENS NA LOJA
INSERT INTO	Produto(nome_item, descricao, preco, quant, marca)
VALUES 
	('Wallpaper', 'Kit de papeis de parede em alta resolução', 5, NULL, NULL),
	('Sticker', 'Sticker digital para perfil', 10, NULL, NULL),
	('Cupom de desconto 5%', 'Cupom de desconto em lojas parceiras', 50, NULL, NULL),
	('E-book de Receitas', 'Livro digital com 50 receitas exclusivas', 100, NULL, 'Editora Fernanda'),
	('Assinatura Premium Spotify - 1 mês', 'Assinatura de 1 mês para serviço de streaming de músicas Spotify', 150, NULL, 'Spotify'),
	('Gift Card Steam - R$50', 'Gift card de R$50 para compra na loja digital Steam', 200, NULL, 'Steam'),
	('Fone de Ouvido Bluetooth', 'Fone de ouvido sem fio com qualidade de som superior', 250, 100, 'Xiaomi'),
	('Teclado Mecânico Gamer', 'Teclado mecânico RGB para jogos', 500, 100, 'Redragon'),
	('Console de Videogame', 'Console de videogame de última geração', 1000, 1, 'XBOX');
GO

-- AMOSTRA DE USUÁRIOS COM PONTOS
INSERT INTO Usuario(nome, nasc, email, senha, saldo, pontuacao, id_estado)
VALUES 
	('Rafael', '1980-03-20', 'Rafael@gmail.com', '$2a$12$jwrhSMjq/eVWb8bzxEoVH.zHs22a8sGpw/ZDQdEhyubnR.mfHeApy', 50, 50, 10),
	('Samantha', '1999-08-04', 'Samantha@gmail.com', '$2a$12$MTjSRPsgFzgEZR18/.foS.s28bQJ9fsW2NRvr5NVSwiI7Jd9d80Fe', 9999, 9999, 22),
	('Bruno', '2002-06-08', 'Bruno@gmail.com', '$2a$12$jS3yud30wFOw406zOnvpKO82m4Z2tCLXbaXsHB0YbY/DTUpvkg.Zi', 10, 10, 3);
GO

/* INICIO DOS TESTES COM PROCEDURES */

-- TESTE PARA RETORNO DE NÃO TEM PONTOS compra
EXEC fazer_compra @id_item = 4, @id_usuario = 3;
GO

-- TESTE PARA SUCESSO DE compra
EXEC fazer_compra @id_item = 9, @id_usuario = 10;
GO

-- TESTE PARA NÃO TEM MAIS ITENS DE compra
EXEC fazer_compra @id_item = 9, @id_usuario = 10;
GO

-- TESTE PARA SINALIZAR RESPOSTA COMO VERDADEIRA
EXEC responde @num = 1;
GO

-- Código para execução do procedure
EXEC Historico @user = 10;
GO

-- Adicionar item na loja
EXEC adicionar_itens @cod_item = 9, @quant = 3;
GO

/* INICIO DO DQL */

-- RANKING TOP 3 DAS PONTUAÇÕES
SELECT	TOP 3
		ROW_NUMBER() OVER(ORDER BY usuario.pontuacao desc) AS 'Ranking',
		usuario.nome AS Usuario,
		estado.sigla AS Estado,
		usuario.pontuacao AS Pontos
FROM Usuario
INNER JOIN estado ON Usuario.id_estado = estado.id;
GO

-- VISUALIZADOR DE TABELAS COMPLETAS
SELECT * FROM Usuario;

SELECT * FROM Topico;

SELECT * FROM Resposta;

SELECT * FROM estado;

SELECT * FROM Produto;

SELECT * FROM compra;

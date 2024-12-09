/* CRIAÇÃO DO BANCO + SELECIONAR PARA USO*/

-- CRIAÇÃO DO BANCO
CREATE DATABASE forumDB;
GO

-- DESIGNAÇÃO COMO BANCO ATUAL
USE forumDB;
GO

/*INICIO DDL - CRIAÇÃO DAS TABELAS */

-- TABELA DE ESTADOS
CREATE TABLE estado(
	id INT IDENTITY(1,1) PRIMARY KEY,
	sigla CHAR(2),
	nome VARCHAR(30)
);
GO

-- TABELA DE USUÁRIOS
CREATE TABLE usuario(
	id INT IDENTITY(1,1) PRIMARY KEY,
	nome VARCHAR(100) UNIQUE NOT NULL,
	nasc DATE NOT NULL
	CHECK(DATEDIFF(year, nasc, CONVERT(DATE, GETDATE())) >= 16),
	email VARCHAR(255) UNIQUE NOT NULL,
	senha CHAR(60) NOT NULL,
	saldo INT DEFAULT 0,
	pontuacao INT DEFAULT 0,
	ban_stats BIT NOT NULL DEFAULT 0,
	ban_expira DATE NULL,
	conta_tipo INT NOT NULL DEFAULT 0,
	id_estado INT FOREIGN KEY REFERENCES estado(id)
);
GO

-- TABELA DE TÓPICOS
CREATE TABLE topico(
	id INT IDENTITY(1,1) PRIMARY KEY,
	titulo VARCHAR(100) NOT NULL,
	descricao VARCHAR(5000) NOT NULL,
	data_criacao SMALLDATETIME DEFAULT SYSDATETIME(),
	id_usuario INT FOREIGN KEY REFERENCES usuario(id),
	respondido BIT NOT NULL DEFAULT 0
);
GO

-- TABELA DE RESPOSTAS
CREATE TABLE resposta(
	id INT IDENTITY(1,1) PRIMARY KEY,
	conteudo VARCHAR(5000) NOT NULL,
	data_resposta SMALLDATETIME DEFAULT SYSDATETIME(),
	responde BIT NOT NULL DEFAULT 0,
	id_usuario INT FOREIGN KEY REFERENCES usuario(id),
	id_topico INT FOREIGN KEY REFERENCES Topico(id),
);
GO

-- TABELA DE PRODUTOS
CREATE TABLE produto(
	id INT IDENTITY(1,1) PRIMARY KEY,
	marca varchar(25),
	nome_item VARCHAR(100) NOT NULL,
	descricao VARCHAR(5000) NOT NULL,
	preco INT NOT NULL,
	quant INT DEFAULT NULL
);
GO

-- TABELA DE LOG DE RESGATES DE ITENS
CREATE TABLE registro_resgate(
	id INT IDENTITY(1,1) PRIMARY KEY,
	id_item INT FOREIGN KEY REFERENCES produto(id),
	id_usuario INT FOREIGN KEY REFERENCES usuario(id),
	hora SMALLDATETIME DEFAULT SYSDATETIME(),
	stat VARCHAR(100)
);
GO

/* CRIAÇÃO DOS GATILHOS DO BANCO */

-- CRIAÇÃO DE TRIGGER AO EFETUAR RESGATE
CREATE TRIGGER efetuar_resgate
ON registro_resgate
FOR INSERT
AS
BEGIN
	DECLARE @id_resgate INT
	DECLARE @id_usuario INT
	DECLARE @item INT
	DECLARE @preco INT
	DECLARE @saldo INT
	DECLARE @quant INT
	
	SELECT @id_resgate = id, @id_usuario = id_usuario, @item = id_item FROM inserted
	SELECT @preco = preco FROM produto WHERE id = @item
	SELECT @saldo = saldo FROM usuario WHERE id = @id_usuario
	SELECT @quant = quant FROM produto WHERE id = @item

	IF @saldo >= @preco AND @quant = 0 
		BEGIN
		UPDATE registro_resgate SET stat = 'FALHOU! Não há mais itens na loja.' WHERE id = @id_resgate
		END
	ELSE IF @saldo < @preco AND (@quant > 0 OR @quant IS NULL)
		BEGIN
		UPDATE registro_resgate SET stat = 'FALHOU! O usuário não tem pontos suficientes.' WHERE id = @id_resgate
		END
	ELSE IF @saldo >= @preco AND (@quant > 0 OR @quant IS NULL)
		BEGIN
		UPDATE usuario SET saldo = saldo - @preco WHERE id = @id_usuario
		UPDATE registro_resgate SET stat = 'SUCESSO! Resgate efetuado.' WHERE id = @id_resgate
			
		IF ISNUMERIC(@quant) = 1
			BEGIN
			UPDATE produto SET quant = quant - 1 WHERE id = @item
			END
		END	
END
GO

-- CRIAÇÃO DO TRIGGER PARA ATUALIZAÇÃO DOS PONTOS 
CREATE TRIGGER update_pontos_topico
ON resposta 
AFTER UPDATE
AS
BEGIN
	DECLARE @id INT
	DECLARE @topico INT

	SELECT @id = id_usuario, @topico = id_topico FROM inserted
	
	UPDATE usuario SET saldo = saldo + 1
	WHERE id = @id

	UPDATE usuario SET pontuacao = pontuacao + 1
	WHERE id = @id

	UPDATE topico SET respondido = 1
	WHERE id = @topico
END
GO

-- CRIAÇÃO DO PROCEDURE PARA ADICIONAR O STATUS DE BAN DE UM USUÁRIO
-- COMANDO: EXEC ban @id_usuario = id de um usuário, @ban_ate = data no formato YYYY-MM-DD
CREATE PROCEDURE ban @id_usuario INT, @ban_ate DATE
AS
UPDATE usuario
SET ban_stats = 1, ban_expira = @ban_ate
WHERE id = @id_usuario;
GO

-- CRIAÇÃO DO PROCEDURE PARA REMOVER O STATUS DE BAN DE UM USUÁRIO
-- COMANDO: EXEC remover_ban @id_usuário = id de um usuário
CREATE PROCEDURE remover_ban @id_usuario INT
AS
UPDATE usuario
SET ban_stats = 0, ban_expira = NULL
WHERE id = @id_usuario;
GO

-- CRIAÇÃO DO PROCEDURE PARA VER HISTÓRICO DE RESGATE DE UM USUÁRIO
-- COMANDO: EXEC Historico @id_usuario = id de um usuário
CREATE PROCEDURE historico @id_usuario INT
AS
SELECT registro_resgate.id AS 'Nº pedido', produto.nome_item AS 'Nome do item', registro_resgate.stat AS 'Status do Pedido', registro_resgate.hora AS 'Data e Hora'
FROM registro_resgate
INNER JOIN produto ON registro_resgate.id_item = produto.id
WHERE registro_resgate.id_usuario = @id_usuario;
GO

-- CRIAÇÃO DO PROCEDURE PARA SINALIZAR 
-- UMA RESPOSTA DE UM TÓPICO COMO DEFINITIVA
-- COMANDO: EXEC responde @id_resposta = id de uma resposta
CREATE PROCEDURE responde @id_resposta INT
AS
UPDATE resposta
SET responde = 1
WHERE id = @id_resposta;
GO

-- CRIAÇÃO DO PROCEDURE PARA ADICIONAR MAIS PRODUTOS EM UM JÁ EXISTENTE
-- COMANDO: EXEC adicionar_itens @id_produto = id do item, 
-- @quant = quantidade a ser adicionada
CREATE PROCEDURE adicionar_itens @id_produto INT, @quant INT
AS
UPDATE produto
SET quant = quant + @quant
WHERE id = @id_produto;
GO

-- CRIAÇÃO DO PROCEDURE QUE FAZ O RESGATE DE UM PRODUTO POR UM USUÁRIO
-- COMANDO: EXEC realizar_resgate @id_item = id do item desejado, @id_usuario = id do usuário resgatedor
CREATE PROCEDURE realizar_resgate @id_item INT, @id_usuario INT
AS
INSERT INTO registro_resgate(id_item, id_usuario)
VALUES
	(@id_item, @id_usuario);
GO

/* INICIO DO DML COM DADOS DE AMOSTRA */

-- LISTA DE ESTADOS BRASILEIROS
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
INSERT INTO usuario(nome, nasc, email, senha, id_estado)
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
INSERT INTO topico(titulo, descricao, id_usuario)
VALUES
	('Dúvida sobre regra de três simples', 'Como faço para resolver uma regra de três simples?', 3);
GO

-- AMOSTRA DE RESPOSTA
INSERT INTO resposta(conteudo, id_usuario, id_topico)
VALUES
	('Basta multiplicar os valores em cruz e depois dividir pelo que sobrar!', 7, 1);
GO

-- AMOSTRA DE ITENS NA LOJA
INSERT INTO	produto(nome_item, descricao, preco, quant, marca)
VALUES 
	('Wallpaper', 'Kit de papeis de parede em alta resolução', 5, NULL, NULL),
	('Sticker', 'Sticker digital para perfil', 10, NULL, NULL),
	('Cupom de desconto 5%', 'Cupom de desconto em lojas parceiras', 50, NULL, NULL),
	('E-book de Receitas', 'Livro digital com 50 receitas exclusivas', 100, NULL, 'Editora Fernanda'),
	('Assinatura Premium Spotify - 1 mês', 'Assinatura de 1 mês para serviço de streaming de músicas Spotify', 150, NULL, 'Spotify'),
	('Gift Card Steam - R$50', 'Gift card de R$50 para resgate na loja digital Steam', 200, NULL, 'Steam'),
	('Fone de Ouvido Bluetooth', 'Fone de ouvido sem fio com qualidade de som superior', 250, 100, 'Xiaomi'),
	('Teclado Mecânico Gamer', 'Teclado mecânico RGB para jogos', 500, 100, 'Redragon'),
	('Console de Videogame', 'Console de videogame de última geração', 1000, 1, 'XBOX');
GO

-- AMOSTRA DE USUÁRIOS COM PONTOS
INSERT INTO usuario(nome, nasc, email, senha, saldo, pontuacao, id_estado)
VALUES 
	('Rafael', '1980-03-20', 'Rafael@gmail.com', '$2a$12$jwrhSMjq/eVWb8bzxEoVH.zHs22a8sGpw/ZDQdEhyubnR.mfHeApy', 50, 50, 10),
	('Samantha', '1999-08-04', 'Samantha@gmail.com', '$2a$12$MTjSRPsgFzgEZR18/.foS.s28bQJ9fsW2NRvr5NVSwiI7Jd9d80Fe', 9999, 9999, 22),
	('Bruno', '2002-06-08', 'Bruno@gmail.com', '$2a$12$jS3yud30wFOw406zOnvpKO82m4Z2tCLXbaXsHB0YbY/DTUpvkg.Zi', 10, 10, 3);
GO

/* INICIO DOS TESTES COM PROCEDURES */

-- TESTE PARA “NÃO TEM PONTOS” PARA RESGATE
EXEC realizar_resgate @id_item = 4, @id_usuario = 3;
GO

-- TESTE PARA SUCESSO NO RESGATE
EXEC realizar_resgate @id_item = 9, @id_usuario = 10;
GO

-- TESTE PARA “NÃO TEM MAIS ITENS” PARA RESGATE
EXEC realizar_resgate @id_item = 9, @id_usuario = 10;
GO

-- TESTE PARA SINALIZAR RESPOSTA COMO VERDADEIRA
EXEC responde @id_resposta = 1;
GO

-- TESTE PARA VER HISTÓRICO DO USUÁRIO
EXEC historico @id_usuario = 10;
GO

-- TESTE PARA ADICIONAR MAIS PRODUTOS NA LOJA
EXEC adicionar_itens @id_produto = 9, @quant = 3;
GO

-- TESTE PARA BANIR UM USUÁRIO
EXEC ban @id_usuario = 1, @ban_ate = '2025-12-08';
GO

-- TESTE PARA REMOVER O BAN DE UM USUARIO
EXEC remover_ban @id_usuario = 1;
GO

/* INICIO DO DQL */

-- RANKING TOP 3 DAS PONTUAÇÕES
SELECT	TOP 3
	ROW_NUMBER() OVER(ORDER BY usuario.pontuacao desc) AS 'Ranking',
	usuario.nome AS Usuario,
	estado.sigla AS Estado,
	usuario.pontuacao AS Pontos
FROM usuario
INNER JOIN estado ON usuario.id_estado = estado.id;
GO

-- VISUALIZADOR DE TABELAS COMPLETAS
SELECT * FROM usuario;

SELECT * FROM topico;

SELECT * FROM resposta;

SELECT * FROM estado;

SELECT * FROM produto;

SELECT * FROM registro_resgate;

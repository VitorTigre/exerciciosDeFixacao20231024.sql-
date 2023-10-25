CREATE DATABASE exercicios_trigger;
USE exercicios_trigger;

-- Criação das tabelas
CREATE TABLE Clientes (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nome VARCHAR(255) NOT NULL
);

CREATE TABLE Auditoria (
    id INT AUTO_INCREMENT PRIMARY KEY,
    mensagem TEXT NOT NULL,
    data_hora TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE Produtos (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nome VARCHAR(255) NOT NULL,
    estoque INT NOT NULL
);

CREATE TABLE Pedidos (
    id INT AUTO_INCREMENT PRIMARY KEY,
    produto_id INT,
    quantidade INT NOT NULL,
    FOREIGN KEY (produto_id) REFERENCES Produtos(id)
);


DELIMITER $$
CREATE TRIGGER insere_cliente_trigger
AFTER INSERT ON Clientes
FOR EACH ROW
BEGIN
    INSERT INTO Auditoria (mensagem)
    VALUES (CONCAT('Novo cliente inserido em ', NOW()));
END;
$$
DELIMITER ;

DELIMITER $$
CREATE TRIGGER tentativa_exclusao_cliente_trigger
BEFORE DELETE ON Clientes
FOR EACH ROW
BEGIN
    INSERT INTO Auditoria (mensagem)
    VALUES (CONCAT('Tentativa de exclusão do cliente ', OLD.nome));
END;
$$
DELIMITER ;

DELIMITER $$
CREATE TRIGGER atualiza_nome_cliente_trigger
AFTER UPDATE ON Clientes
FOR EACH ROW
BEGIN
    IF NEW.nome != OLD.nome THEN
        INSERT INTO Auditoria (mensagem)
        VALUES (CONCAT('Nome do cliente atualizado de "', OLD.nome, '" para "', NEW.nome, '"'));
    END IF;
END;
$$
DELIMITER ;

DELIMITER $$
CREATE TRIGGER impede_atualizacao_nome_vazio_trigger
BEFORE UPDATE ON Clientes
FOR EACH ROW
BEGIN
    IF NEW.nome = '' OR NEW.nome IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Não é permitido atualizar o nome para vazio ou NULL.';
    END IF;
END;
$$
DELIMITER ;

DELIMITER $$
CREATE TRIGGER decrementa_estoque_trigger
AFTER INSERT ON Pedidos
FOR EACH ROW
BEGIN
    UPDATE Produtos
    SET estoque = estoque - NEW.quantidade
    WHERE id = NEW.produto_id;

    IF (SELECT estoque FROM Produtos WHERE id = NEW.produto_id) < 5 THEN
        INSERT INTO Auditoria (mensagem)
        VALUES (CONCAT('Estoque do produto "', (SELECT nome FROM Produtos WHERE id = NEW.produto_id), '" está abaixo de 5 unidades.'));
    END IF;
END;
$$
DELIMITER ;

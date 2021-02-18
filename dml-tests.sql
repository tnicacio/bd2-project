insert into usuario(nome, email, senha) values 
('admin','admin@email.com','pass123'),
('tiago','tiago@gmail.com','123456'),
('aline','aline@gmail.com','654321');

/*
Observação relativa à questão 1:
Implementei para registrar log apenas ao alterar um registro de produto.
Uma vez registrada a venda, os seus itens não podem ser modificados.
*/
insert into produto(descricao, preco, qtd_estoque, estoque_minimo, qtde_reservada, usuario_id) values 
('Pizza', 12.50, 300, 5, 12, 1),
('Queijo', 4.99, 400, 6, 10, 1),
('Nuggets', 16.80, 350, 10, 6, 1);

update produto
set descricao = 'Pizza congelada',
	preco = 12.51,
	qtd_estoque = 299,
	usuario_id = 2
where id = 1;

insert into venda(data, pagto_prazo, numero_parcelas, status, usuario_id) values
('25/02/2021', false, null, null, 2),
('25/02/2021', false, null, null, 3),
('25/02/2021', true, 3, null, 2);

/*
O preço unitário será inserido na tabela de itens automaticamente, caso a transação seja válida.
*/
insert into itens(produto_id, venda_id, quantidade) values
(1, 1, 2),
(3, 1, 3),
(2, 2, 4),
(1, 3, 4);

/*
Uma venda é criada com o status em aberto. Após o registro de venda, ela pode ser confirmada ou cancelada. Se a venda for finalizada
deve ser atualizado o estoque dos itens, caso seja cancelada deve ser estornado a quantidade dos itens para o estoque;

Status:
O = confirmada,
X = cancelada}
*/
update	venda
set		status = 'O'
where	id = 1;



create table produto(
id 				serial primary key,
descricao		varchar(50),
preco			decimal(6,2),
qtd_estoque		decimal(5,2),
estoque_minimo	decimal(5,2),
qtde_reservada	decimal(6,2),
usuario_id		int4 not null
);

create table venda(
id				serial primary key,
data			date,
pagto_prazo		boolean,
numero_parcelas	int4,
status			char,
usuario_id		int4 not null
);

create table itens(
produto_id		int4 not null,
venda_id		int4 not null,
quantidade		decimal(6,2),
preco_unitario	decimal(6,2),
primary key(produto_id, venda_id)
);

alter table if exists itens 
add constraint fk_itens_produto
foreign key (produto_id) references produto;

alter table if exists itens
add constraint fk_itens_venda
foreign key (venda_id) references venda;

create table parcelamento(
id				serial primary key,
venda_id		int4 not null,
valor			decimal(6,2),
data_vencimento	date
);

alter table if exists parcelamento
add constraint fk_parcelamento_venda
foreign key (venda_id) references venda;

create table log_movimentos(
id				serial primary key,
data			timestamp,
descricao		varchar(500),
valor_anterior	decimal(6,2),
valor_atual		decimal(6,2),
qtde_anterior	decimal(5,2),
qtde_atual		decimal(6,2),
usuario_id		int4 not null
);

create table usuario(
id				serial primary key,
nome			varchar(50),
email			varchar(50),
senha			varchar(50)
);

alter table log_movimentos
add constraint fk_logmovimentos_usuario
foreign key (usuario_id) references usuario;

alter table produto
add constraint fk_produto_usuario
foreign key (usuario_id) references usuario;

alter table venda
add constraint fk_venda_usuario
foreign key (usuario_id) references usuario;

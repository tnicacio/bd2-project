create table usuario(
id				serial primary key,
nome			varchar(255),
email			varchar(255),
senha			varchar(255)
);

create table produto(
id 					serial primary key,
descricao			varchar(255),
preco				decimal(6,2),
qt_estoque			decimal(6,2),
qt_estoque_minimo	decimal(6,2),
qt_reservada		decimal(6,2),
dt_atualizacao		timestamp,
usuario_id			int4 not null
);

create table venda(
id				serial primary key,
dt_venda		timestamp,
is_pagto_prazo	boolean,
nr_parcelas		int4,
status			char,
dt_atualizacao	timestamp,
usuario_id		int4 not null
);

create table itens(
produto_id		int4 not null,
venda_id		int4 not null,
qt_produto		decimal(6,2),
preco_unitario	decimal(6,2),
primary key(produto_id, venda_id)
);

create table parcelamento(
id				serial primary key,
venda_id		int4 not null,
valor			decimal(6,2),
dt_vencimento	date
);

create table produto_audit(
id 					serial primary key,
produto_id			int4 not null,
usuario_id			int4 not null,
dt_atualizacao		timestamp,
descricao			varchar(255),
preco				decimal(6,2),
qt_estoque_minimo	decimal(6,2)
);

create table log_movimentos(
id						serial primary key,
produto_id				int4 not null,
venda_id				int4,
dt_atualizacao			timestamp,
ds_movimento			varchar(255),
qt_estoque_anterior		decimal(6,2),
qt_estoque_atual		decimal(6,2),
qt_reservada_anterior	decimal(5,2),
qt_reservada_atual		decimal(6,2),
usuario_id				int4 not null
);

alter table produto
add constraint fk_produto_usuario
foreign key (usuario_id) references usuario;

alter table venda
add constraint fk_venda_usuario
foreign key (usuario_id) references usuario;

alter table if exists itens 
add constraint fk_itens_produto
foreign key (produto_id) references produto;

alter table if exists itens
add constraint fk_itens_venda
foreign key (venda_id) references venda;

alter table if exists parcelamento
add constraint fk_parcelamento_venda
foreign key (venda_id) references venda;

alter table produto_audit
add constraint fk_produtoaudit_produto
foreign key (produto_id) references produto;

alter table produto_audit
add constraint fk_produtoaudit_usuario
foreign key (usuario_id) references usuario;

alter table log_movimentos
add constraint fk_logmovimentos_usuario
foreign key (usuario_id) references usuario;

alter table log_movimentos
add constraint fk_logmovimentos_produto
foreign key (produto_id) references produto;

alter table log_movimentos
add constraint fk_logmovimentos_venda
foreign key (venda_id) references venda;

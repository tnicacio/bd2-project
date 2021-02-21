create table usuario(
id serial primary key,
nome varchar(255),
email varchar(255),
senha varchar(255),
cargo integer
);

create table produto(
id serial primary key,
descricao varchar(255),
preco decimal(6,2),
qt_estoque decimal(6,2),
qt_estoque_minimo decimal(6,2),
qt_reservada decimal(6,2),
dt_atualizacao timestamp,
usuario_id int4 not null
);

create table venda(
id serial primary key,
dt_venda timestamp,
is_pagto_prazo boolean,
nr_parcelas int4,
status char,
dt_atualizacao timestamp,
usuario_id int4 not null
);

create table itens(
produto_id int4 not null,
venda_id int4 not null,
qt_produto decimal(6,2),
preco_unitario decimal(6,2),
primary key(produto_id, venda_id)
);

create table parcelamento(
id serial primary key,
venda_id int4 not null,
valor decimal(6,2),
dt_vencimento date
);

create table produto_audit(
id serial primary key,
produto_id int4 not null,
usuario_id int4 not null,
dt_atualizacao timestamp,
descricao varchar(255),
preco decimal(6,2),
qt_estoque_minimo decimal(6,2)
);

create table log_movimentos(
id serial primary key,
produto_id int4 not null,
venda_id int4,
dt_atualizacao timestamp,
ds_movimento varchar(255),
qt_estoque_anterior decimal(6,2),
qt_estoque_atual decimal(6,2),
qt_reservada_anterior decimal(5,2),
qt_reservada_atual decimal(6,2),
usuario_id int4 not null
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

----- FUNCTIONS -----

create or replace function fnc_get_monthly_payment_from_venda(venda_id_p integer)
returns decimal(6,2)
language plpgsql
as $fnc_get_monthly_payment_from_venda$

declare
total_w				itens.preco_unitario%type;
payment_w 			itens.preco_unitario%type := 0;
num_parcelas_w		venda.nr_parcelas%type;

begin

	total_w 		:= fnc_get_total_from_venda(venda_id_p);
	num_parcelas_w 	:= fnc_get_nr_parcelas_from_venda(venda_id_p);

	if (num_parcelas_w = 0) or (total_w = 0) then
		return payment_w;
	end if;

	payment_w := total_w/num_parcelas_w;
	return payment_w;
end;
$fnc_get_monthly_payment_from_venda$;


create or replace function fnc_get_nr_parcelas_from_venda(venda_id_p integer)
returns integer
language plpgsql
as $fnc_get_nr_parcelas_from_venda$

declare
num_parcelas_w		venda.nr_parcelas%type;

begin

	select	coalesce(nr_parcelas, 0)
	into	num_parcelas_w
	from	venda
	where	id = venda_id_p;
	
	return num_parcelas_w;

end;
$fnc_get_nr_parcelas_from_venda$;


create or replace function fnc_get_total_from_venda(venda_id_p integer)
returns decimal(6,2)
language plpgsql
as $fnc_get_total_from_venda$

declare
sumTotal decimal(6,2) := 0;

begin

	select 	coalesce(sum(qt_produto * preco_unitario) ,0)
	from	itens
	into	sumTotal
	where	venda_id = venda_id_p;
	
	return sumTotal;
end;
$fnc_get_total_from_venda$;


create or replace function fnc_get_usuario_from_venda(venda_id_p integer)
returns integer
language plpgsql
as $fnc_get_usuario_from_venda$

declare
usuario_id_w integer;

begin
	select	v.usuario_id
	into	usuario_id_w
	from	venda v
	where	v.id = venda_id_p;
	
	return usuario_id_w;
end;
$fnc_get_usuario_from_venda$;


----- PROCEDURES -----

create or replace procedure prc_generate_installments(venda_id_p integer,interval_p interval)
language plpgsql
as $$
declare

month_counter		integer;
num_parcelas_w		venda.nr_parcelas%type;
total_w				itens.preco_unitario%type;
monthly_payment_w	itens.preco_unitario%type;

begin

total_w 		:= fnc_get_total_from_venda(venda_id_p);
num_parcelas_w 	:= fnc_get_nr_parcelas_from_venda(venda_id_p);

if (num_parcelas_w = 0) or (total_w = 0) then
	return;
end if;

monthly_payment_w = total_w/num_parcelas_w;

month_counter := 0;
loop

	insert into parcelamento(venda_id, valor, dt_vencimento)
	values(venda_id_p, monthly_payment_w, CURRENT_DATE + (month_counter * interval_p));

	month_counter = month_counter + 1;
	exit when month_counter = num_parcelas_w;
end loop;

end;
$$;


create or replace 
procedure prc_log_movimentos(	produto_id_p	integer,
								venda_id_p	integer,
								ds_movimento_p	varchar,
								qt_estoque_anterior_p decimal,
								qt_estoque_atual_p decimal,
								qt_reservada_anterior_p	decimal,
								qt_reservada_atual_p decimal,
								usuario_id_p integer)
language plpgsql
as $$
declare

begin

	if (coalesce(usuario_id_p,0) > 0)
		and (coalesce(produto_id_p,0) > 0)then

		insert into log_movimentos (produto_id,
									venda_id,
									dt_atualizacao,
									ds_movimento,
									qt_estoque_anterior,
									qt_estoque_atual,
									qt_reservada_anterior,
									qt_reservada_atual,
									usuario_id)
							values (produto_id_p,
									venda_id_p,
									now(),
									ds_movimento_p,
									qt_estoque_anterior_p,
									qt_estoque_atual_p,
									qt_reservada_anterior_p,
									qt_reservada_atual_p,
									usuario_id_p);
	end if;

end;
$$;


----- TRIGGER FUNCTIONS -----

create or replace function trf_itens_validation() 
returns trigger as 
$trf_itens_validation$

declare

preco_w				produto.preco%type;
qt_estoque_w		produto.qt_estoque%type;
qt_estoque_minimo_w	produto.qt_estoque_minimo%type;
qt_reservada_w		produto.qt_reservada%type;
new_qt_reservada_w	produto.qt_reservada%type;
new_qt_estoque_w	produto.qt_estoque%type;

begin

select	p.preco,
		p.qt_estoque,
		p.qt_estoque_minimo,
		p.qt_reservada
into	preco_w,
		qt_estoque_w,
		qt_estoque_minimo_w,
		qt_reservada_w
from	produto p
where	p.id = new.produto_id;


raise notice 'new.produto_id: %; qt_estoque: %; new.qt_produto: %; qt_estoque_minimo: %', new.produto_id, qt_estoque_w, new.qt_produto, qt_estoque_minimo_w;

if ((qt_estoque_w - new.qt_produto) >= qt_estoque_minimo_w) then
	
	new.preco_unitario := preco_w;
	
	new_qt_reservada_w := qt_reservada_w + new.qt_produto;
	new_qt_estoque_w := qt_estoque_w - new.qt_produto;
	
	update 	produto
	set		qt_reservada = new_qt_reservada_w,
			qt_estoque = new_qt_estoque_w
	where 	produto.id = new.produto_id;
	
	call prc_log_movimentos(new.produto_id, new.venda_id, 'Reserving items', qt_estoque_w, new_qt_estoque_w, qt_reservada_w, new_qt_reservada_w, fnc_get_usuario_from_venda(new.venda_id));
	
	return NEW;	
	
end if;

raise exception 'Not enough items in stock';
	
end;	
$trf_itens_validation$ language plpgsql;


create or replace function trf_produto_audit() 
returns trigger as 
$trf_produto_audit$

declare

begin

	if (new.usuario_id is not null)
		and (	coalesce(old.preco, -1) <> coalesce(new.preco, -1)
			or	coalesce(old.qt_estoque_minimo, -1) <> coalesce(new.qt_estoque_minimo, -1)
			or	coalesce(old.descricao,'xpto') <> coalesce(new.descricao,'xpto')
			)
		then
	
		insert into produto_audit ( produto_id,
									usuario_id,
									dt_atualizacao,
									descricao,
									preco,
									qt_estoque_minimo)
							values (new.id,
									new.usuario_id,
									now(),
									new.descricao,
									new.preco,
									new.qt_estoque_minimo);
		return NEW;
	end if;
	
	return NULL; 
end;	
$trf_produto_audit$ language plpgsql;


create or replace function trf_produto_before_insert_update() 
returns trigger as 
$trf_produto_before_insert_update$

declare

begin

	if (new.usuario_id is null) then
		raise exception 'User id is null'
			using hint = 'Cannot register a product without specify it''s responsible user';
	end if;
	
	if (new.dt_atualizacao is null) then
		new.dt_atualizacao := now();
	end if;
	
	return NEW; 
end;	
$trf_produto_before_insert_update$ language plpgsql;


create or replace function trf_venda_after_update() 
returns trigger as 
$trf_venda_after_update$

declare
cur_venda_dados cursor (id_p integer)
				for
				select 	i.produto_id,
						i.itens_qt_produto,
						i.qt_estoque,
						i.qt_reservada,
						(i.qt_reservada - i.itens_qt_produto) as new_qt_reservada_w,
						(i.qt_estoque + i.itens_qt_produto) as new_cancel_estoque_quantidade_w,
						i.itens_preco_unit as preco_antigo_w,
						i.produto_preco_atual as preco_novo_w,
						i.usuario_venda
				from	v_itens i
				where	i.venda_id = id_p;
			
begin

	if 	(new.status is null) or
		(coalesce(new.status,'xpto') = coalesce(old.status,'xpto')) then
		return NULL;
	end if;

	if (new.status = 'O') then -- Venda confirmada
		new.dt_atualizacao := now();
		
		for cur in cur_venda_dados(new.id) loop
		
			update 	produto p
			set		qt_reservada = cur.new_qt_reservada_w
			where	p.id = cur.produto_id;
			
			RAISE NOTICE 'confirming order id = % with product id = %', new.id, cur.produto_id;
			call prc_log_movimentos(cur.produto_id, new.id
									,'Confirming order id = ' || new.id || ' , shipping reserved quantity(' || cur.itens_qt_produto || ') from product id = ' || cur.produto_id
									, cur.qt_estoque, cur.qt_estoque, cur.qt_reservada, cur.new_qt_reservada_w, cur.usuario_venda);
		
		end loop;
		
		if (old.is_pagto_prazo) and (old.nr_parcelas > 0) then
			call prc_generate_installments(new.id,'30 days');
		end if;
		
		return NEW;
		
	elsif (new.status = 'X') then	-- Venda cancelada
		new.dt_atualizacao := now();
	
		for cur in cur_venda_dados(new.id) loop
		
			update 	produto p
			set		qt_reservada = cur.new_qt_reservada_w,
					qt_estoque = cur.new_cancel_estoque_quantidade_w
			where	p.id = cur.produto_id;
			
			RAISE NOTICE 'canceling order id = % with product id = %', new.id, cur.produto_id;
			call prc_log_movimentos(cur.produto_id, new.id
									,'Canceling order id = ' || new.id || ' , returning reserved quantity(' || cur.itens_qt_produto || ') to stock from product id = ' || cur.produto_id
									, cur.qt_estoque, cur.new_cancel_estoque_quantidade_w, cur.qt_reservada, cur.new_qt_reservada_w, cur.usuario_venda);
		
		end loop;
		
		return NEW;
	end if;
	
	return NULL; 
end;	
$trf_venda_after_update$ language plpgsql;


create or replace function trf_venda_validation() 
returns trigger as 
$trf_venda_validation$
			
begin

	if (new.usuario_id is null) then
		RAISE EXCEPTION 'User id cannot be null';
	end if;
	
	if (new.is_pagto_prazo) and (coalesce(new.nr_parcelas, 0) = 0) then
		RAISE EXCEPTION 'An installment payment order must have more than 0 installments';
	end if;
	
	if (new.is_pagto_prazo is null)	or (new.is_pagto_prazo = false) then
		new.is_pagto_prazo := false;
		new.nr_parcelas := 0;
	end if;		

	if (TG_OP = 'INSERT') then
		
		if (new.status is not null) then
			RAISE EXCEPTION 'A new order must be registered with an empty status';
		end if;
	
		if (new.dt_venda is null) then
			new.dt_venda := now();
		end if;
		
		if (new.dt_atualizacao is not null) then
			new.dt_atualizacao := null;
		end if;
		
		RETURN NEW;
		
	elsif (TG_OP = 'UPDATE') then
		
		if (new.dt_atualizacao is null) then
			new.dt_atualizacao := now();
		end if;
		
		if (old.status is not null)
			and (new.status is not null) then
			RAISE EXCEPTION 'Order status already defined as %', old.status;
		end if;
	
		RETURN NEW;
	end if;
	
	RETURN NULL;
end;	
$trf_venda_validation$ language plpgsql;


----- TRIGGERS -----

create trigger trg_itens_before_insert
before insert on itens
for each row
execute procedure trf_itens_validation();

create trigger trg_produto_after_insert_update
after insert or update on produto
for each row
execute procedure trf_produto_audit();

create trigger trg_produto_before_insert_update
before insert or update on produto
for each row
execute procedure trf_produto_before_insert_update();

create trigger trg_venda_after_update
after update on venda
for each row
execute procedure trf_venda_after_update();

create trigger trg_venda_before_insert_update
before insert or update on venda
for each row
execute procedure trf_venda_validation();

----- VIEWS -----

create or replace view v_itens as

select  p.id								produto_id,
		v.id								venda_id,
		p.descricao							produto_descricao,
		coalesce(p.preco, 0) 				produto_preco_atual,
		coalesce(p.qt_estoque, 0) 			qt_estoque,
		coalesce(p.qt_estoque_minimo, 0) 	qt_estoque_minimo,
		coalesce(p.qt_reservada, 0) 		qt_reservada,
		p.usuario_id						produto_usuario_cadastro,
		coalesce(i.qt_produto, 0)			itens_qt_produto,
		coalesce(i.preco_unitario,0)		itens_preco_unit,
		v.dt_venda							venda_dt,
		v.dt_atualizacao					venda_dt_atualizacao,
		coalesce(v.is_pagto_prazo, false)	venda_pagto_prazo,
		coalesce(v.nr_parcelas, 0)			venda_numero_parcelas,
		v.status							venda_status,
		v.usuario_id 						usuario_venda
from	produto p,
		venda v,
		itens i
where	i.produto_id = p.id
and		i.venda_id = v.id;


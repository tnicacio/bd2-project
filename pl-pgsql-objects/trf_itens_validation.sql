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
	
	call prc_log_movimentos(new.produto_id, new.venda_id, 'desc', qt_estoque_w, new_qt_estoque_w, qt_reservada_w, new_qt_reservada_w, fnc_get_usuario_from_venda(new.venda_id));
	
	return NEW;	
	
end if;

raise exception 'Not enough items in stock';
	
end;	
$trf_itens_validation$ language plpgsql;

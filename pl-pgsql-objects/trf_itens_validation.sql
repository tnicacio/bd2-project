create or replace function trf_itens_validation() 
returns trigger as 
$trf_itens_validation$

declare

preco_w				produto.preco%type;
qtde_estoque_w		produto.qtd_estoque%type;
estoque_minimo_w	produto.estoque_minimo%type;

begin

select  coalesce(p.preco, 0),
		coalesce(p.qtd_estoque, 0),
		coalesce(p.estoque_minimo, 0)
into	preco_w,
		qtde_estoque_w,
		estoque_minimo_w
from	produto p
where	p.id = new.produto_id;

if ((qtde_estoque_w - new.quantidade) >= estoque_minimo_w) then
	
	new.preco_unitario := preco_w;
	
	update 	produto
	set		qtde_reservada = qtde_reservada + new.quantidade,
			qtd_estoque = qtd_estoque - new.quantidade
	where 	produto.id = new.produto_id;
	
	return NEW;	
	
end if;

raise exception 'Not enough items in stock';
	
end;	
$trf_itens_validation$ language plpgsql;

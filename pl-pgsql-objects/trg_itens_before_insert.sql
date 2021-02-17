create or replace function itens_validation() 
returns trigger as 
$itens_validation$

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
where	p.id = new.id_produto;

if ((qtde_estoque_w - new.quantidade) >= estoque_minimo_w) then
	
	new.preco_unitario := preco_w;
	
	update 	produto
	set		qtde_reservada = qtde_reservada + new.quantidade,
			qtd_estoque = qtd_estoque - new.quantidade
	where 	produto.id = new.id_produto;
	
	RAISE NOTICE 'Atualizando produto id = %', new.id_produto;
	
	return NEW;
	
end if;
	
return null; 

end;	
$itens_validation$ language plpgsql;

create trigger trg_itens_before_insert
before insert on itens
for each row
execute procedure itens_validation();

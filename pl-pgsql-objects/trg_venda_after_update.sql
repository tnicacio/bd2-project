create or replace function venda_update() 
returns trigger as 
$venda_update$

declare

id_produto_w	itens.id_produto%type;
quantidade_w	itens.quantidade%type;

cur_produto cursor (id_p integer)
			for
			select 	i.id_produto,
					i.quantidade
			from	itens i
			where	i.id_venda = id_p;

begin

	if (coalesce(new.status,'xpto') = coalesce(old.status,'xpto')) then
		return NULL;
	end if;

	if (coalesce(new.status,'xpto') = 'O') then -- Venda confirmada
		
		open cur_produto(new.id);
		loop
			
			fetch	cur_produto 
			into	id_produto_w,
					quantidade_w;
			exit when not found;
			
			update 	produto p
			set		qtde_reservada = qtde_reservada - quantidade_w
			where	p.id =  id_produto_w;
		
			RAISE NOTICE 'Atualizando produto id = %',id_produto_w;
		
		end loop;
		close cur_produto;
		
		return NEW;
		
	elsif (coalesce(new.status,'xpto') = 'X') then	-- Venda cancelada
	
		open cur_produto(new.id);
		
		loop
			
			fetch	cur_produto 
			into	id_produto_w,
					quantidade_w;
			exit when not found;
			
			update	produto p
			set		qtde_reservada = qtde_reservada - quantidade_w,
					qtd_estoque = qtd_estoque + quantidade_w
			where	p.id = id_produto_w;
			
			RAISE NOTICE 'Atualizando produto id = %',id_produto_w;
		
		end loop;
		close cur_produto;
		
		return NEW;
	end if;
	
	return NULL; 
end;	
$venda_update$ language plpgsql;

create trigger trg_venda_after_update
after update on venda
for each row
execute procedure venda_update();

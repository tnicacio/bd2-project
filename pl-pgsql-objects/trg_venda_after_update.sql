create or replace function venda_update() 
returns trigger as 
$venda_update$

declare

id_produto_w		itens.id_produto%type;
quantidade_w		itens.quantidade%type;

month_counter		integer;
num_parcelas_w		venda.numero_parcelas%type;
total_w				itens.preco_unitario%type;
monthly_payment_w	itens.preco_unitario%type;

cur_produto cursor (id_p integer)
			for
			select 	i.id_produto,
					i.quantidade
			from	itens i
			where	i.id_venda = id_p;

begin

	if 	(new.status is null) or
		(coalesce(new.status,'xpto') = coalesce(old.status,'xpto')) then
		return NULL;
	end if;

	if (new.status = 'O') then -- Venda confirmada
		
		open cur_produto(new.id);
		loop
			
			fetch	cur_produto 
			into	id_produto_w,
					quantidade_w;
			exit when not found;
			
			update 	produto p
			set		qtde_reservada = qtde_reservada - quantidade_w
			where	p.id =  id_produto_w;
		
			RAISE NOTICE 'Atualizando qtde_reservada do produto id = %',id_produto_w;
		
		end loop;
		close cur_produto;
		
		if (old.pagto_prazo)
			and (coalesce(old.numero_parcelas, new.numero_parcelas) > 0)then
			
			num_parcelas_w := coalesce(old.numero_parcelas, new.numero_parcelas);
							
			select 	sum(quantidade * preco_unitario)
			into	total_w
			from	itens
			where	id_venda = new.id;
			
			monthly_payment_w = total_w/num_parcelas_w;
			
			month_counter := 0;
			loop
			
				insert into parcelamento(id_venda, valor, data_vencimento)
				values(new.id, monthly_payment_w, CURRENT_DATE + (month_counter*30));
				
				month_counter = month_counter + 1;
				exit when month_counter = num_parcelas_w;
			end loop;
		
		end if;
		
		return NEW;
		
	elsif (new.status = 'X') then	-- Venda cancelada
	
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
			
			RAISE NOTICE 'Atualizando qtde_reservada e qtd_estoque do produto id = %',id_produto_w;
		
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

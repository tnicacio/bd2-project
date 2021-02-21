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

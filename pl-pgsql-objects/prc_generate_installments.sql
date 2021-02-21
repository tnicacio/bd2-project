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

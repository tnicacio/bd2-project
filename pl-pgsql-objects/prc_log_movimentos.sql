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

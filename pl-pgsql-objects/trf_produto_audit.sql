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

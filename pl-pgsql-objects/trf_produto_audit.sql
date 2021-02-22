create or replace function trf_produto_audit() 
returns trigger as 
$trf_produto_audit$

declare

begin

	if (new.usuario_id is not null)
		and (	coalesce(old.preco, -1) <> coalesce(new.preco, -1)
			or	coalesce(old.qt_estoque_minimo, -1) <> coalesce(new.qt_estoque_minimo, -1)
			or	coalesce(old.descricao,'xpto') <> coalesce(new.descricao,'xpto')
			or	coalesce(old.ie_ativo,false) <> coalesce(new.ie_ativo,false)
			)
		then
	
		insert into produto_audit ( produto_id,
									usuario_id,
									image_uri,
									dt_atualizacao,
									descricao,
									preco,
									qt_estoque_minimo,
									ie_ativo,
									dt_inativacao)
							values (new.id,
									new.usuario_id,
									new.image_uri,
									now(),
									new.descricao,
									new.preco,
									new.qt_estoque_minimo,
									new.ie_ativo,
									new.dt_inativacao);
		return NEW;
	end if;
	
	return NULL; 
end;	
$trf_produto_audit$ language plpgsql;

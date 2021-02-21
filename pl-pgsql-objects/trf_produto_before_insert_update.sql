create or replace function trf_produto_before_insert_update() 
returns trigger as 
$trf_produto_before_insert_update$

declare

begin

	if (new.usuario_id is null) then
		raise exception 'User id is null'
			using hint = 'Cannot register a product without specify it''s responsible user';
	end if;
	
	if (new.dt_atualizacao is null) then
		new.dt_atualizacao := now();
	end if;
	
	return NEW; 
end;	
$trf_produto_before_insert_update$ language plpgsql;

create or replace function trf_produto_before_insert_update() 
returns trigger as 
$trf_produto_before_insert_update$

declare

begin

	new.dt_atualizacao := now();

	if (TG_OP = 'INSERT') then
		
		if (new.ie_ativo is null) then
			new.ie_ativo := true;
		end if;
		
		if (new.ie_ativo is not null) and (new.ie_ativo = false) then
			new.dt_inativacao := now();
		end if;
		
	end if;

	if (TG_OP = 'UPDATE') then
	
		if (new.ie_ativo is null) then
			new.ie_ativo := false;
			new.dt_inativacao := now();
		end if;
	
		if (new.ie_ativo is not null) and (new.ie_ativo) then
			new.dt_inativacao := null;

		elsif (new.ie_ativo is not null) and (new.ie_ativo = false) then
			new.dt_inativacao := now();
		end if;
			
	end if;
		
	if (new.usuario_id is null) then
		raise exception 'User id is null'
			using hint = 'Cannot register a product without specify it''s responsible user';
	end if;
	
	return NEW; 
end;	
$trf_produto_before_insert_update$ language plpgsql;

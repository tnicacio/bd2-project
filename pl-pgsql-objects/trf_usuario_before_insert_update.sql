create or replace function trf_usuario_before_insert_update() 
returns trigger as 
$trf_usuario_before_insert_update$

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
		
	if (new.id is null) then
		raise exception 'User id is null';
	end if;
	
	if (new.senha is null) then
		raise exception 'Password cannot be null';
	end if;
	
	if (new.nome is null) then
		raise exception 'User name cannot be null';
	end if;
	
	if (new.cargo is null) then
		new.cargo = 2;
	end if;
	
	return NEW; 
end;	
$trf_usuario_before_insert_update$ language plpgsql;

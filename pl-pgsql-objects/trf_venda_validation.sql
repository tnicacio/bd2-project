create or replace function trf_venda_validation() 
returns trigger as 
$trf_venda_validation$
			
begin

	if (new.usuario_id is null) then
		RAISE EXCEPTION 'User id cannot be null';
	end if;
	
	if (new.endereco is null) then
		RAISE EXCEPTION 'Adress cannot be null';
	end if;

	if (new.is_pagto_prazo) and (coalesce(new.nr_parcelas, 0) = 0) then
		RAISE EXCEPTION 'An installment payment order must have more than 0 installments';
	end if;
	
	if (new.is_pagto_prazo is null)	or (new.is_pagto_prazo = false) then
		new.is_pagto_prazo := false;
		new.nr_parcelas := 0;
	end if;		

	if (TG_OP = 'INSERT') then
		
		if (new.status is not null) then
			RAISE EXCEPTION 'A new order must be registered with an empty status';
		end if;
	
		if (new.dt_venda is null) then
			new.dt_venda := now();
		end if;
		
		if (new.dt_atualizacao is not null) then
			new.dt_atualizacao := null;
		end if;
		
		RETURN NEW;
		
	elsif (TG_OP = 'UPDATE') then
		
		if (new.dt_atualizacao is null) then
			new.dt_atualizacao := now();
		end if;
		
		if (old.status is not null)
			and (new.status is not null) then
			RAISE EXCEPTION 'Order status already defined as %', old.status;
		end if;
	
		RETURN NEW;
	end if;
	
	RETURN NULL;
end;	
$trf_venda_validation$ language plpgsql;

create or replace function get_usuario_from_venda(venda_id_p integer)
returns integer
language plpgsql
as $get_usuario_from_venda$

declare
usuario_id_w integer;

begin
	select	v.usuario_id
	into	usuario_id_w
	from	venda v
	where	v.id = venda_id_p;
	
	return usuario_id_w;
end;
$get_usuario_from_venda$;

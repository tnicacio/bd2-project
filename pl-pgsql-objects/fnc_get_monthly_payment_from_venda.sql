create or replace function fnc_get_monthly_payment_from_venda(venda_id_p integer)
returns decimal(6,2)
language plpgsql
as $fnc_get_monthly_payment_from_venda$

declare
total_w				itens.preco_unitario%type;
payment_w 			itens.preco_unitario%type := 0;
num_parcelas_w		venda.nr_parcelas%type;

begin

	total_w 		:= fnc_get_total_from_venda(venda_id_p);
	num_parcelas_w 	:= fnc_get_nr_parcelas_from_venda(venda_id_p);

	if (num_parcelas_w = 0) or (total_w = 0) then
		return payment_w;
	end if;

	payment_w := total_w/num_parcelas_w;
	return payment_w;
end;
$fnc_get_monthly_payment_from_venda$;

create or replace function getTotalFromVenda(venda_id_p integer)
returns decimal(6,2)
language plpgsql
as $getTotalFromVenda$

declare
sumTotal decimal(6,2) := 0;

begin

	select 	coalesce(sum(qt_produto * preco_unitario) ,0)
	from	itens
	into	sumTotal
	where	venda_id = venda_id_p;
	
	return sumTotal;
end;
$getTotalFromVenda$

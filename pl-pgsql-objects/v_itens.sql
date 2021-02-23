create or replace view v_itens as

select  p.id								produto_id,
		v.id								venda_id,
		p.descricao							produto_descricao,
		coalesce(p.preco, 0) 				produto_preco_atual,
		coalesce(p.qt_estoque, 0) 			qt_estoque,
		coalesce(p.qt_estoque_minimo, 0) 	qt_estoque_minimo,
		coalesce(p.qt_reservada, 0) 		qt_reservada,
		p.usuario_id						produto_usuario_cadastro,
		coalesce(i.qt_produto, 0)			itens_qt_produto,
		coalesce(i.preco_unitario,0)		itens_preco_unit,
		v.dt_venda							venda_dt,
		v.dt_atualizacao					venda_dt_atualizacao,
		coalesce(v.is_pagto_prazo, false)	venda_pagto_prazo,
		coalesce(v.nr_parcelas, 0)			venda_numero_parcelas,
		v.status							venda_status,
		v.endereco							venda_endereco,
		v.usuario_id 						usuario_venda
from	produto p,
		venda v,
		itens i
where	i.produto_id = p.id
and		i.venda_id = v.id;

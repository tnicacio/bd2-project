create trigger trg_produto_before_insert_update
before insert or update on produto
for each row
execute procedure trf_produto_before_insert_update();

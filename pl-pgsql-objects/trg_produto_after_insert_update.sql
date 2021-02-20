create trigger trg_produto_after_insert_update
after insert or update on produto
for each row
execute procedure trf_produto_audit();

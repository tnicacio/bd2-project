create trigger trg_produto_before_update
before update on produto
for each row
execute procedure trf_produto_log_mov();

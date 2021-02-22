create trigger trg_usuario_before_insert_update
before insert or update on usuario
for each row
execute procedure trf_usuario_before_insert_update();

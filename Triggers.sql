--! 5. Triggers 
--? 1. Auditoría INSERT Clientes
CREATE OR REPLACE TRIGGER trg_auditoria_insert_cliente
AFTER INSERT ON cliente
FOR EACH ROW
BEGIN
    sp_registrar_auditoria(
        a_accion         => 'INSERT',
        a_tabla_afectada => 'cliente',
        a_valor_nuevo    => 'id_cliente=' || :NEW.id_cliente ||
                            ', nombre=' || :NEW.nombre ||
                            ', apellido=' || :NEW.apellido ||
                            ', correo=' || :NEW.correo
    );
END;
/

SELECT * FROM AUDITORIA;

--? 2. Auditoría UPDATE Clientes
CREATE OR REPLACE TRIGGER trg_auditoria_update_cliente
AFTER UPDATE ON cliente
FOR EACH ROW
DECLARE
    v_anterior VARCHAR2(500);
    v_nuevo    VARCHAR2(500);
BEGIN
    v_anterior :=
        (CASE WHEN :OLD.nombre != :NEW.nombre THEN 'nombre=' || :OLD.nombre || '; ' ELSE '' END) ||
        (CASE WHEN :OLD.apellido != :NEW.apellido THEN 'apellido=' || :OLD.apellido || '; ' ELSE '' END) ||
        (CASE WHEN :OLD.telefono != :NEW.telefono THEN 'telefono=' || :OLD.telefono || '; ' ELSE '' END) ||
        (CASE WHEN :OLD.correo != :NEW.correo THEN 'correo=' || :OLD.correo || '; ' ELSE '' END) ||
        (CASE WHEN :OLD.provincia != :NEW.provincia THEN 'provincia=' || :OLD.provincia || '; ' ELSE '' END) ||
        (CASE WHEN :OLD.direccion != :NEW.direccion THEN 'direccion=' || :OLD.direccion || '; ' ELSE '' END);

    v_nuevo :=
        (CASE WHEN :OLD.nombre != :NEW.nombre THEN 'nombre=' || :NEW.nombre || '; ' ELSE '' END) ||
        (CASE WHEN :OLD.apellido != :NEW.apellido THEN 'apellido=' || :NEW.apellido || '; ' ELSE '' END) ||
        (CASE WHEN :OLD.telefono != :NEW.telefono THEN 'telefono=' || :NEW.telefono || '; ' ELSE '' END) ||
        (CASE WHEN :OLD.correo != :NEW.correo THEN 'correo=' || :NEW.correo || '; ' ELSE '' END) ||
        (CASE WHEN :OLD.provincia != :NEW.provincia THEN 'provincia=' || :NEW.provincia || '; ' ELSE '' END) ||
        (CASE WHEN :OLD.direccion != :NEW.direccion THEN 'direccion=' || :NEW.direccion || '; ' ELSE '' END);

    IF LENGTH(v_anterior) > 0 THEN
        sp_registrar_auditoria(
            a_accion         => 'UPDATE',
            a_tabla_afectada => 'cliente',
            a_valor_anterior => v_anterior,
            a_valor_nuevo    => v_nuevo
        );
    END IF;
END trg_auditoria_update_cliente;
/

--? 3. Auditoría DELETE Clientes

CREATE OR REPLACE TRIGGER trg_auditoria_delete_cliente
BEFORE DELETE ON cliente
FOR EACH ROW
DECLARE
    v_anterior VARCHAR2(500);
BEGIN
    v_anterior :=
        'cedula=' || :OLD.cedula || '; ' ||
        'nombre=' || :OLD.nombre || '; ' ||
        'apellido=' || :OLD.apellido || '; ' ||
        'telefono=' || :OLD.telefono || '; ' ||
        'correo=' || :OLD.correo || '; ' ||
        'provincia=' || :OLD.provincia || '; ' ||
        'direccion=' || :OLD.direccion || '; ';

    sp_registrar_auditoria(
        a_accion => 'DELETE',
        a_tabla_afectada => 'cliente',
        a_valor_anterior => v_anterior,
        a_valor_nuevo => NULL
    );
END trg_auditoria_delete_cliente;
/

--? 4. Descontar Stock por Venta
CREATE OR REPLACE TRIGGER trg_descontar_stock
AFTER INSERT ON detalle_venta
FOR EACH ROW
BEGIN
    UPDATE producto
    SET stock_actual = stock_actual - :NEW.cantidad
    WHERE id_producto = :NEW.id_producto;

    INSERT INTO inventario(id_producto, tipo_movimiento, cantidad, motivo)
    VALUES (:NEW.id_producto, 'Salida', :NEW.cantidad,
            'Venta automatica - id_venta: ' || :NEW.id_venta);
END trg_descontar_stock;
/

SELECT nombre, stock_actual FROM producto WHERE id_producto = 5;
INSERT INTO detalle_venta (id_venta, id_producto, cantidad, precio_unitario, subtotal)
VALUES (1, 5, 3, 14.29, 42.87);

--? 5. Incrementar Stock por Devolución
CREATE OR REPLACE TRIGGER trg_incrementar_stock
AFTER INSERT ON devolucion
FOR EACH ROW
BEGIN
    UPDATE producto
    SET stock_actual = stock_actual + :NEW.cantidad
    WHERE id_producto = :NEW.id_producto;

    INSERT INTO inventario(id_producto, tipo_movimiento, cantidad, motivo)
    VALUES (:NEW.id_producto, 'Entrada', :NEW.cantidad,
            'Devolucion automatica - id_devolucion: ' || :NEW.id_devolucion);
END trg_incrementar_stock;
/

SELECT nombre, stock_actual FROM producto WHERE id_producto = 7;
INSERT INTO devolucion (id_venta, id_producto, cantidad, motivo)
VALUES (24, 7, 2, 'Prueba trigger - empaque roto');
SELECT nombre, stock_actual FROM producto WHERE id_producto = 7;


--? 6. Control de Stock Negativo
CREATE OR REPLACE TRIGGER trg_control_stock_negativo
BEFORE UPDATE OF stock_actual ON producto
FOR EACH ROW
BEGIN
    IF :NEW.stock_actual < 0 THEN
        RAISE_APPLICATION_ERROR(-20001,
            'Stock negativo no permitido. ' ||
            'Producto: '   || :NEW.nombre       ||
            ' | Antes: '   || :OLD.stock_actual ||
            ' | Despues: ' || :NEW.stock_actual);
    END IF;
END trg_control_stock_negativo;
/

UPDATE producto SET stock_actual = -99 WHERE id_producto = 1;
SELECT nombre, stock_actual FROM producto WHERE id_producto = 1;

--? 7. Registro de Cambio de Precio
CREATE OR REPLACE TRIGGER trg_Registro_Cambio_Precio
AFTER UPDATE OF precio
ON producto
FOR EACH ROW
BEGIN

    IF :NEW.precio<0 THEN
    RAISE_APPLICATION_ERROR( -20001, 'El precio ingresado no es valido');
    END IF;

    IF NVL(:OLD.precio, 0) <> NVL(:NEW.precio, 0) THEN
    INSERT INTO auditoria (usuario,accion,tabla_afectada,fecha_hora,valor_anterior,valor_nuevo)
    VALUES(USER,'UPDATE','PRODUCTO',SYSTIMESTAMP,:OLD.precio,:NEW.precio);
    END IF; 
END;


SELECT id_producto, nombre, precio
FROM producto
WHERE id_producto = 1;

UPDATE producto
SET precio = 25.50
WHERE id_producto = 1;

select * from auditoria;

--? 8. Registro de Acceso
CREATE OR REPLACE TRIGGER trg_registro_acceso
AFTER LOGON ON SCHEMA
BEGIN
    INSERT INTO auditoria (usuario, accion, tabla_afectada, fecha_hora, valor_anterior, valor_nuevo)
    VALUES (USER, 'ACCESO', 'BASE DE DATOS', SYSTIMESTAMP, NULL, 'Inicio de sesion');
    COMMIT;
END;
/
commit;
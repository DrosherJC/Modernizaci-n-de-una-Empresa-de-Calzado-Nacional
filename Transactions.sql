--! Venta completa
DECLARE
    v_id_venta NUMBER;
    v_precio NUMBER;
    v_stock NUMBER;
    v_cantidad NUMBER := 2;
    v_id_prod NUMBER := 1;
    v_subtotal NUMBER;
    v_descuento NUMBER;
    v_iva NUMBER;
    v_total NUMBER;
BEGIN
    SAVEPOINT inicio_venta;

    SELECT precio, stock_actual INTO v_precio, v_stock
    FROM producto WHERE id_producto = v_id_prod;

    IF v_stock < v_cantidad THEN
        RAISE_APPLICATION_ERROR(-20001, 'Stock insuficiente');
    END IF;

    v_subtotal := v_precio * v_cantidad;
    v_descuento := fn_calcular_descuento(v_subtotal, 'Dia del Padre');
    v_iva := fn_calcular_iva(v_subtotal - v_descuento);
    v_total := v_subtotal - v_descuento + v_iva;

    INSERT INTO venta (id_cliente, id_empleado, id_promocion, fecha_venta, tipo_venta, descuento, iva, total)
    VALUES (1, 3, (SELECT id_promocion FROM promocion WHERE nombre = 'Dia del Padre'),SYSDATE, 'Menor', v_descuento, v_iva, v_total)
    RETURNING id_venta INTO v_id_venta;

    INSERT INTO detalle_venta (id_venta, id_producto, cantidad, precio_unitario, subtotal)
    VALUES (v_id_venta, v_id_prod, v_cantidad, v_precio, v_subtotal);

    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Venta registrada, ID: ' || v_id_venta || ' - Total: ' || v_total);
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK TO SAVEPOINT inicio_venta;
        DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
END;
/
select * from venta;
--!Devolución completa

DECLARE
    v_id_devolucion NUMBER;
    v_id_venta NUMBER := 1;
    v_id_prod NUMBER := 14;
    v_cantidad NUMBER := 1;
    v_cantidad_vendida  NUMBER;
    v_cantidad_devuelta NUMBER;
BEGIN
    SAVEPOINT inicio_devolucion;

    SELECT cantidad INTO v_cantidad_vendida
    FROM detalle_venta
    WHERE id_venta = v_id_venta AND id_producto = v_id_prod;

    SELECT NVL(SUM(cantidad), 0) INTO v_cantidad_devuelta
    FROM devolucion
    WHERE id_venta = v_id_venta AND id_producto = v_id_prod;

    IF v_cantidad > (v_cantidad_vendida - v_cantidad_devuelta) THEN
        RAISE_APPLICATION_ERROR(-20001, 'No se puede devolver mas de lo disponible');
    END IF;

    INSERT INTO devolucion (id_venta, id_producto, cantidad, fecha_devolucion, motivo)
    VALUES (v_id_venta, v_id_prod, v_cantidad, SYSDATE, 'Talla incorrecta')
    RETURNING id_devolucion INTO v_id_devolucion;

    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Devolucion registrada, ID: ' || v_id_devolucion);
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK TO SAVEPOINT inicio_devolucion;
        DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
END;
/
--! Compra al proveedor

DECLARE
    v_id_compra NUMBER;
    v_id_prod NUMBER := 5;
    v_cantidad NUMBER := 30;
    v_precio NUMBER := 28.00;
    v_existe NUMBER;
BEGIN
    SAVEPOINT inicio_compra;

    SELECT COUNT(*) INTO v_existe FROM producto WHERE id_producto = v_id_prod;
    IF v_existe = 0 THEN
        RAISE_APPLICATION_ERROR(-20001, 'El producto indicado no existe');
    END IF;

    INSERT INTO compra (id_proveedor, id_empleado, fecha_compra, total)
    VALUES (7, 3, SYSDATE, v_cantidad * v_precio)
    RETURNING id_compra INTO v_id_compra;

    INSERT INTO detalle_compra (id_compra, id_producto, cantidad, precio_unitario, subtotal)
    VALUES (v_id_compra, v_id_prod, v_cantidad, v_precio, v_cantidad * v_precio);

    UPDATE producto SET stock_actual = stock_actual + v_cantidad WHERE id_producto = v_id_prod;

    INSERT INTO inventario (id_producto, tipo_movimiento, cantidad, motivo)
    VALUES (v_id_prod, 'Entrada', v_cantidad, 'Compra a proveedor #' || v_id_compra);

    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Compra registrada, ID: ' || v_id_compra);
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK TO SAVEPOINT inicio_compra;
        DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
END;
/

--!Actualización masiva de inventario
DECLARE
    v_porcentaje NUMBER := 10;  
BEGIN
    SAVEPOINT inicio_ajuste;

    INSERT INTO inventario (id_producto, tipo_movimiento, cantidad, motivo)
    SELECT id_producto,
        CASE WHEN v_porcentaje >= 0 THEN 'Entrada' ELSE 'Salida' END,
           ABS(ROUND(stock_actual * (v_porcentaje / 100))),
        'Ajuste masivo de inventario ' || v_porcentaje || '%'
    FROM producto
    WHERE id_categoria = 1
      AND ROUND(stock_actual * (v_porcentaje / 100)) <> 0;

    UPDATE producto
    SET stock_actual = stock_actual + ROUND(stock_actual * (v_porcentaje / 100))
    WHERE id_categoria = 1;

    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Ajuste masivo aplicado a categoria 1');
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK TO SAVEPOINT inicio_ajuste;
        DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
END;
/

SELECT stock_actual FROM PRODUCTO;
SELECT  * FROM inventario;

SELECT DISTINCT(cargo) FROM empleado;

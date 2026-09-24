--! 4. Store Procedures
--? 1. Registrar Cliente
CREATE OR REPLACE PROCEDURE sp_registrar_cliente(
    c_cedula VARCHAR2,
    c_nombre VARCHAR2,
    c_apellido VARCHAR2,
    c_telefono VARCHAR2,
    c_correo VARCHAR2,
    c_provincia VARCHAR2,
    c_direccion VARCHAR2
)
IS
c_cedula_existe NUMBER;
c_correo_existe NUMBER;
BEGIN
    IF c_cedula IS NULL THEN
        RAISE_APPLICATION_ERROR(-20001,'La cedula no puede estar vacía');
    ELSIF c_nombre IS NULL THEN
        RAISE_APPLICATION_ERROR(-20001,'El nombre no puede estar vacío');

    ELSIF c_apellido IS NULL THEN
        RAISE_APPLICATION_ERROR(-20001,'El apellido no puede estar vacío');

    ELSIF c_telefono IS NULL THEN
        RAISE_APPLICATION_ERROR(-20001,'EL teléfono no puede estar vacío');

    ELSIF c_correo IS NULL THEN
        RAISE_APPLICATION_ERROR(-20001,'El correo no puede estar vacío');

    ELSIF c_provincia IS NULL THEN
        RAISE_APPLICATION_ERROR(-20001,'La provincia no puede estar vacía');

    ELSIF c_direccion IS NULL THEN
        RAISE_APPLICATION_ERROR(-20001,'La dirección no puede estar vacía');
    END IF;

    IF INSTR(c_correo, '@') = 0 THEN
    RAISE_APPLICATION_ERROR(-20001, 'El correo debe contener @');
    END IF;

    SELECT
    COUNT(cedula)
    INTO c_cedula_existe
    FROM cliente
    WHERE cedula = c_cedula;
    
    SELECT
    COUNT(correo)
    INTO c_correo_existe
    FROM cliente
    WHERE correo = c_correo;

    IF c_cedula_existe >0 THEN
        RAISE_APPLICATION_ERROR(-20001,'La cédula ya se encuentra registrada, intente nuevamente');
    ELSIF c_correo_existe>0 THEN
        RAISE_APPLICATION_ERROR(-20001,'El correo ya se encuentra registrado, intente nuevamente');
    END IF;

    INSERT INTO cliente(cedula,nombre,apellido,telefono,correo,provincia,direccion,fecha_registro)
    VALUES(c_cedula,c_nombre,c_apellido,c_telefono,c_correo,c_provincia,c_direccion,SYSDATE);

    COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE;
END;
EXEC sp_registrar_cliente('1702693824', 'Paddy', 'Pimblett', '09876542727', 'paddy.pimblett@gmail.com', 'Cayambe', 'Diagonal Eugenio Espejo ');
EXEC sp_registrar_cliente('1728396450', 'Lionel', 'Messi', '0987633221', 'lionel.messi@gmail.com', 'Pichincha', 'El Inca');

SELECT * FROM cliente WHERE nombre = 'Paddy' OR nombre='Lionel';

select * from cliente;

--? 2. Registrar Producto

CREATE OR REPLACE PROCEDURE sp_registrar_producto(
    p_nombre IN VARCHAR2,
    p_id_categoria IN NUMBER,
    p_id_proveedor IN NUMBER,
    p_precio IN NUMBER,
    p_stock IN NUMBER,
    p_stock_min IN NUMBER
) AS
    v_existe NUMBER;
    v_id NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_existe
    FROM producto
    WHERE UPPER(nombre) = UPPER(p_nombre);

    IF v_existe > 0 THEN
        RAISE_APPLICATION_ERROR(-20001, 'Ya existe un producto con ese nombre.');
    END IF;

    INSERT INTO producto(nombre, id_categoria, id_proveedor, precio, stock_actual, stock_minimo)
    VALUES (p_nombre, p_id_categoria, p_id_proveedor, p_precio, p_stock, p_stock_min)
    RETURNING id_producto INTO v_id;

    INSERT INTO inventario(id_producto, tipo_movimiento, cantidad, motivo)
    VALUES (v_id, 'Entrada', p_stock, 'Stock inicial al registrar producto');

    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Producto registrado. ID: ' || v_id);
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
END sp_registrar_producto;
/

SET SERVEROUTPUT ON;
EXEC sp_registrar_producto('Zapatilla Trail Explorer', 4, 5, 105.00, 30, 8)
SELECT * FROM PRODUCTO;



--TODO 3. Registrar Venta
CREATE OR REPLACE TYPE t_producto_venta AS OBJECT (
    nombre_producto VARCHAR2(100),
    cantidad NUMBER
);


CREATE OR REPLACE TYPE t_lista_productos AS TABLE OF t_producto_venta;


CREATE OR REPLACE PROCEDURE sp_registrar_venta(
    p_cedula_cliente IN VARCHAR2,
    p_id_empleado IN NUMBER,
    p_tipo_venta IN VARCHAR2,
    p_nombre_promocion IN VARCHAR2 DEFAULT NULL,
    p_productos IN t_lista_productos,
    p_id_venta OUT NUMBER
)
IS
    v_id_cliente cliente.id_cliente%TYPE;
    v_id_prod producto.id_producto%TYPE;
    v_precio producto.precio%TYPE;
    v_stock producto.stock_actual%TYPE;
    v_subtotal NUMBER := 0;
    v_descuento NUMBER := 0;
    v_iva NUMBER := 0;
    v_count_emp NUMBER;
BEGIN
    IF p_productos IS NULL OR p_productos.COUNT = 0 THEN
        RAISE_APPLICATION_ERROR(-20001, 'La venta debe incluir al menos un producto.');
    END IF;

    IF p_tipo_venta IS NULL OR p_tipo_venta NOT IN ('Mayor', 'Menor') THEN
        RAISE_APPLICATION_ERROR(-20001, 'Tipo de venta invalido');
    END IF;

    SELECT id_cliente INTO v_id_cliente FROM cliente WHERE cedula = p_cedula_cliente;

    SELECT COUNT(*) INTO v_count_emp FROM empleado WHERE id_empleado = p_id_empleado;
    IF v_count_emp = 0 THEN
        RAISE_APPLICATION_ERROR(-20001, 'No existe un empleado con ID ' || p_id_empleado);
    END IF;

    INSERT INTO venta (id_cliente, id_empleado, tipo_venta, descuento, iva, total)
    VALUES (v_id_cliente, p_id_empleado, p_tipo_venta, 0, 0, 0)
    RETURNING id_venta INTO p_id_venta;

    FOR i IN 1..p_productos.COUNT LOOP

        IF p_productos(i).cantidad <= 0 THEN
            RAISE_APPLICATION_ERROR(-20001,
                'Cantidad inválida para "' || p_productos(i).nombre_producto || '".');
        END IF;

        SELECT id_producto, precio, stock_actual
        INTO v_id_prod, v_precio, v_stock
        FROM producto
        WHERE nombre = p_productos(i).nombre_producto;

        IF v_stock < p_productos(i).cantidad THEN
            RAISE_APPLICATION_ERROR(-20001,
                'Stock insuficiente para "' || p_productos(i).nombre_producto || '".');
        END IF;

        INSERT INTO detalle_venta (id_venta, id_producto, cantidad, precio_unitario, subtotal)
        VALUES (p_id_venta, v_id_prod, p_productos(i).cantidad, v_precio,
                v_precio * p_productos(i).cantidad);

        v_subtotal := v_subtotal + (v_precio * p_productos(i).cantidad);
    END LOOP;

    sp_aplicar_promocion(p_nombre_promocion, v_subtotal, v_descuento);

    v_iva := fn_calcular_iva(v_subtotal - v_descuento);

    UPDATE venta
    SET descuento = v_descuento,
        iva = v_iva,
        total = v_subtotal - v_descuento + v_iva,
        id_promocion = (SELECT id_promocion FROM promocion WHERE nombre = p_nombre_promocion)
    WHERE id_venta = p_id_venta;

    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END sp_registrar_venta;
/

DECLARE
    v_productos t_lista_productos := t_lista_productos(
        t_producto_venta('Zapatilla Running Air Max', 2),
        t_producto_venta('Sandalia Playera Comfort', 1)
    );
    v_id_venta NUMBER;
BEGIN
    sp_registrar_venta(
        p_cedula_cliente => '17936043811',
        p_id_empleado => 3,
        p_tipo_venta => 'Menor',
        p_nombre_promocion => 'Dia del Padre',
        p_productos => v_productos,
        p_id_venta => v_id_venta
    );

    DBMS_OUTPUT.PUT_LINE('Venta registrada con ID: ' || v_id_venta);
END;
/



--? 4. Registrar Devolución

CREATE OR REPLACE PROCEDURE sp_registrar_devolucion(
    p_id_venta IN NUMBER,
    p_id_producto IN NUMBER,
    p_cantidad IN NUMBER,
    p_motivo IN VARCHAR2
) AS
    v_en_venta NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_en_venta
    FROM detalle_venta
    WHERE id_venta = p_id_venta AND id_producto = p_id_producto;

    IF v_en_venta = 0 THEN
        RAISE_APPLICATION_ERROR(-20002, 'El producto no pertenece a esa venta.');
    END IF;

    INSERT INTO devolucion(id_venta, id_producto, cantidad, fecha_devolucion,motivo)
    VALUES (p_id_venta, p_id_producto, p_cantidad, SYSDATE,p_motivo);

    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Devolucion registrada correctamente.');
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
END sp_registrar_devolucion;
/

SELECT * FROM DEVOLUCION;
SET SERVEROUTPUT ON;
EXEC sp_registrar_devolucion(2, 1, 1, 'Empaque dañado');
SELECT * FROM devolucion WHERE motivo = 'Empaque dañado';

--? 5. Aplicar Promoción
CREATE OR REPLACE PROCEDURE sp_aplicar_promocion(
    p_nombre_promocion IN VARCHAR2,
    p_subtotal IN NUMBER,
    p_descuento OUT NUMBER
)
IS
BEGIN
    p_descuento := fn_calcular_descuento(p_subtotal, p_nombre_promocion);
END sp_aplicar_promocion;
/


DECLARE
    v_descuento NUMBER;
BEGIN
    sp_aplicar_promocion(
        p_nombre_promocion => 'Dia del Padre',
        p_subtotal => 500,
        p_descuento => v_descuento
    );

    DBMS_OUTPUT.PUT_LINE('Descuento calculado: ' || v_descuento);
END;
/

--? 6. Calcular Ventas Mensuales

CREATE OR REPLACE PROCEDURE sp_calcular_Ventas_Mensuales (
    v_mes NUMBER,
    v_anio NUMBER
)
IS
v_total NUMBER;
BEGIN
    IF v_mes <1 OR v_mes >12 THEN
    RAISE_APPLICATION_ERROR( -20001, 'El mes debe estar entre 1 y 12');
    END IF;
    
    IF V_anio <2000 OR V_anio >EXTRACT(YEAR FROM SYSDATE) THEN
    RAISE_APPLICATION_ERROR( -20002, 'El anio ingresado no es valido');
    END IF;
    
    SELECT NVL(SUM(total),0)
    INTO v_total
    FROM venta
    WHERE EXTRACT(MONTH FROM fecha_venta) = v_mes
    AND EXTRACT(YEAR FROM fecha_venta) = v_anio;

    IF v_total = 0 THEN
    RAISE_APPLICATION_ERROR(-20003,'No existen ventas para el mes y año indicados');
    END IF;
    
    DBMS_OUTPUT.PUT_LINE(
        'Mes: ' || v_mes ||
        ' - Año: ' || v_anio ||
        ' - Total ventas: $' || v_total
    );
END;


EXEC sp_calcular_ventas_mensuales(4, 2026);

--? 7. Registrar Proveedor

CREATE OR REPLACE PROCEDURE sp_registrar_Proveedor (
    p_nombre IN VARCHAR2,
    p_pais IN VARCHAR2,
    p_tipo_proveedor IN VARCHAR2 ,
    p_telefono IN VARCHAR2,
    p_correo IN VARCHAR2,
    p_direccion IN VARCHAR2
)
IS
BEGIN
    IF p_tipo_proveedor NOT IN ('Nacional', 'Importado') THEN
    RAISE_APPLICATION_ERROR(-20001, 'El tipo de proveedor no es valido');
    END IF;
    
    IF LENGTH(p_telefono)<>10  THEN
    RAISE_APPLICATION_ERROR(-20002,'El teléfono debe tener 10 dígitos' );
    END IF;
    
    INSERT INTO proveedor(nombre,pais,tipo_proveedor,telefono,correo,direccion)
        
    VALUES (p_nombre,p_pais,p_tipo_proveedor,p_telefono,p_correo,p_direccion
    );   
    COMMIT;
    EXCEPTION 
    WHEN OTHERS THEN 
        ROLLBACK;
        RAISE;
END;

EXEC sp_registrar_proveedor('Distribuidora Andes','Ecuador','Nacional','0991234567','andes@correo.com','Quito, Av. Amazonas');
SELECT * FROM proveedor WHERE nombre = 'Distribuidora Andes';

--? 8. Actualizar Inventario

CREATE OR REPLACE PROCEDURE sp_actualizar_inventario(
    p_id_producto IN NUMBER,
    p_tipo_movimiento IN VARCHAR2,
    p_cantidad IN NUMBER,
    p_motivo IN VARCHAR2
) AS
    v_stock NUMBER;
BEGIN
    SELECT stock_actual INTO v_stock
    FROM producto WHERE id_producto = p_id_producto;

    IF p_tipo_movimiento = 'Salida' AND v_stock < p_cantidad THEN
        RAISE_APPLICATION_ERROR(-20003, 'Stock insuficiente para registrar la salida.');
    END IF;

    INSERT INTO inventario(id_producto, tipo_movimiento, cantidad, fecha_movimiento,motivo)
    VALUES (p_id_producto, p_tipo_movimiento, p_cantidad, SYSDATE,p_motivo);

    IF p_tipo_movimiento = 'Entrada' THEN
        UPDATE producto SET stock_actual = stock_actual + p_cantidad WHERE id_producto = p_id_producto;
    ELSE
        UPDATE producto SET stock_actual = stock_actual - p_cantidad WHERE id_producto = p_id_producto;
    END IF;

    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Inventario actualizado correctamente.');
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('Producto no encontrado.');
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
END sp_actualizar_inventario;
/

SET SERVEROUTPUT ON;
EXEC sp_actualizar_inventario(3, 'Entrada', 20, 'Nuevo cargamento');
SELECT * FROM inventario WHERE id_producto = 3;

--? 9. Registrar Queja

CREATE OR REPLACE PROCEDURE sp_registrar_queja (
        q_id_cliente IN NUMBER,
        q_tipo IN VARCHAR2,
        q_descripcion IN VARCHAR2
)
IS
    id_cliente_existe NUMBER;
BEGIN
    SELECT COUNT(*)
    INTO id_cliente_existe
    FROM cliente
    WHERE id_cliente=q_id_cliente;
    
    IF id_cliente_existe=0 THEN
        RAISE_APPLICATION_ERROR(-20001,'El cliente ingresado no existe.');
    END IF;
    
    IF q_tipo NOT IN ('Reclamo', 'Sugerencia') THEN
        RAISE_APPLICATION_ERROR(-20002,'El tipo debe ser Reclamo o Sugerencia.' ); 
    END IF;
    
    IF q_descripcion IS NULL THEN
        RAISE_APPLICATION_ERROR(-20003,'La descripción no puede estar vacia.' ); 
    END IF;
    
    INSERT INTO queja (id_cliente,tipo,descripcion)
    VALUES (q_id_cliente,q_tipo,q_descripcion);
    
    DBMS_OUTPUT.PUT_LINE('Queja registrada correctamente');
    
    COMMIT;

    EXCEPTION 
        WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END;

SET SERVEROUTPUT ON;
BEGIN
    sp_registrar_queja(
        1,
        'Reclamo','Producto defectuoso'
    );
END;

SELECT * FROM queja;

--? 10. Registrar Auditoría

CREATE OR REPLACE PROCEDURE sp_registrar_auditoria (
    a_accion IN VARCHAR2,
    a_tabla_afectada IN VARCHAR2,
    a_valor_anterior IN VARCHAR2 DEFAULT NULL,
    a_valor_nuevo IN VARCHAR2 DEFAULT NULL
)
IS
PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN
    IF a_accion IS NULL OR a_accion NOT IN ('INSERT', 'UPDATE', 'DELETE') THEN
        RAISE_APPLICATION_ERROR(-20001, 'La accion debe ser INSERT, UPDATE o DELETE');
    END IF;

    IF a_tabla_afectada IS NULL THEN
        RAISE_APPLICATION_ERROR(-20002, 'La tabla afectada no puede estar vacia');
    END IF;

    INSERT INTO auditoria (usuario, accion, tabla_afectada, valor_anterior, valor_nuevo)
    VALUES (USER, a_accion, a_tabla_afectada, a_valor_anterior, a_valor_nuevo);

    COMMIT;
END sp_registrar_auditoria;
/
EXEC sp_registrar_auditoria('INSERT', 'producto', NULL, 'nombre=Zapatilla Trail Explorer, precio=105.00')
SELECT * FROM auditoria;


--! 3. Funciones =====================
--? 1. Calcular IVA
CREATE OR REPLACE FUNCTION fn_calcular_iva(
    monto NUMBER
)
RETURN NUMBER
IS
iva_calculado NUMBER;
BEGIN
    IF monto IS NULL OR monto < 0 THEN
    RAISE_APPLICATION_ERROR(-20001, 'El monto no puede ser nulo o negativo');
    END IF;

    iva_calculado := ROUND(monto *0.15,2);
    RETURN iva_calculado;
END fn_calcular_iva;
/

--* Éxito
SELECT fn_calcular_iva(100) AS iva FROM dual;        -- Resultado: 15
--* Fallo
SELECT fn_calcular_iva(-50) AS iva FROM dual;          -- Resultado: ORA-20001 "El monto no puede ser nulo o negativo"

--? 2. Calcular descuento

CREATE OR REPLACE FUNCTION fn_calcular_descuento(
    valor NUMBER,
    nombre_promocion VARCHAR2 DEFAULT NULL)
RETURN number
IS
    v_tipo VARCHAR2(20);
    v_valor NUMBER;
    v_count NUMBER;
    v_minimo  NUMBER;
    descuento NUMBER;
BEGIN
    IF valor IS NULL OR valor <0 THEN
        RAISE_APPLICATION_ERROR(-20001,'El valor no puede ser nulo o negativo');
    END IF;
    IF nombre_promocion IS NULL THEN
        RETURN 0;
    END IF;

    SELECT COUNT(*)
    INTO v_count
    FROM PROMOCION
    WHERE nombre = nombre_promocion;

    IF v_count = 0 THEN
    RAISE_APPLICATION_ERROR(-20001,'La promoción no existe');
    END IF;

    SELECT tipo_descuento, valor_descuento, monto_minimo
    INTO v_tipo, v_valor, v_minimo
    FROM promocion WHERE nombre = nombre_promocion;

    IF valor < v_minimo THEN
        RETURN 0;
    END IF;
    IF v_tipo = 'Porcentaje' then
        descuento := valor*(v_valor/100);
    ELSE 
        descuento := v_valor;
    END IF;

    RETURN ROUND(descuento,2);
END fn_calcular_descuento;

--* Éxito (promo 'Dia del Padre': Monto 7.23, mínimo 0, siempre aplica)
SELECT fn_calcular_descuento(80,'Dia del Padre') AS descuento FROM dual;  
--* Fallo (promoción inexistente)
SELECT fn_calcular_descuento(80,'Promo Inventada') AS descuento FROM dual;

--? 3. Calcular antiguedad del cliente

CREATE OR REPLACE FUNCTION fn_calcular_antiguedad_cliente(
    C_id_cliente NUMBER
)
RETURN VARCHAR2
IS 
    resultado VARCHAR2(20);
BEGIN
    SELECT 
    TRUNC (
        MONTHS_BETWEEN(SYSDATE,fecha_registro)/12
    ) || ' ' || 'Años'
    INTO resultado
    FROM cliente
    WHERE id_cliente = C_id_cliente;
    
    RETURN resultado;
END;

--* Éxito
SELECT fn_calcular_antiguedad_cliente(1) AS antiguedad FROM dual;  

--* Fallo (cliente que no existe)
SELECT fn_calcular_antiguedad_cliente(9999) AS antiguedad FROM dual;

--? 4. Calcular comisión

CREATE OR REPLACE FUNCTION fn_calcular_comision(
    p_id_empleado IN NUMBER,
    p_porcentaje IN NUMBER DEFAULT 5
) RETURN NUMBER IS
    v_total NUMBER;
BEGIN
    SELECT NVL(SUM(total), 0)
    INTO v_total
    FROM venta
    WHERE id_empleado = p_id_empleado;
    RETURN ROUND(v_total * p_porcentaje / 100, 2);
END fn_calcular_comision;
/

--* Éxito
SELECT fn_calcular_comision(1, 8) AS comision FROM dual; 
--* Fallo como usa NVL, un ID inexistente NO falla, retorna 0.
SELECT fn_calcular_comision(9999, 8) AS comision FROM dual; 

--? 5. Productos bajo stock

CREATE OR REPLACE FUNCTION fn_productos_bajo_stock
RETURN NUMBER IS
    v_count NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_count
    FROM producto
    WHERE stock_actual < stock_minimo;
    RETURN v_count;
END fn_productos_bajo_stock;
/

--* Éxito
SELECT fn_productos_bajo_stock AS productos_bajo_stock FROM dual;

--? 6. Clientes frecuentes

CREATE OR REPLACE FUNCTION Clientes_Frecuentes(
    f_cedula_cliente VARCHAR2
)
RETURN VARCHAR2
IS 
numero_compras NUMBER;
monto_acumulado DECIMAL(10,2);
BEGIN
    SELECT COUNT(id_venta),
        NVL(SUM(total),0)
    INTO numero_compras,
        monto_acumulado
    FROM venta v
    JOIN cliente c ON c.id_cliente=v.id_cliente 
    WHERE c.cedula=f_cedula_cliente;
    
    IF numero_compras>5 OR monto_acumulado>=500 THEN
        RETURN 'Cliente frecuente';
    ELSE
    RETURN 'Cliente no frecuente';
    END IF;
END;

--* Éxito 
SELECT Clientes_Frecuentes('17936043811') AS estado FROM dual;
--* "Fallo" 
SELECT Clientes_Frecuentes('00000000000') AS estado FROM dual; 

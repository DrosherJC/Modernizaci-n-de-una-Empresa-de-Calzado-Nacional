
--! 2. Vistas===============
--? 1. Clientes Frecuentes 
CREATE OR REPLACE VIEW vw_clientes_frecuentes
AS
SELECT
    c.id_cliente,
    CONCAT(c.nombre, ' ',c.apellido) AS nombre_cliente,
    c.provincia,
    COUNT(v.id_cliente) AS total_compras,
    NVL(SUM(v.total),0) AS monto_acumulado
FROM cliente c
JOIN venta v ON v.id_cliente = c.id_cliente
GROUP BY c.id_cliente, c.nombre, c.apellido, c.provincia
ORDER BY total_compras DESC;

SELECT * FROM VW_CLIENTES_FRECUENTES;

--? 2. Ventas Consolidadas

CREATE OR REPLACE VIEW vw_ventas_consolidadas
AS
SELECT
    v.id_venta,
    v.fecha_venta,
    CONCAT(c.nombre, ' ',c.apellido) AS nombre_cliente,
    CONCAT(e.nombre, ' ',e.apellido) AS nombre_vendedor,
    v.tipo_venta,
    SUM(dv.subtotal) AS subtotal,
    v.iva,
    v.descuento,
    v.total
FROM venta v
JOIN empleado e ON e.id_empleado = v.id_empleado
JOIN cliente c ON c.id_cliente = v.id_cliente
JOIN detalle_venta dv ON dv.id_venta = v.id_venta
GROUP BY v.id_venta,c.nombre,c.apellido,e.nombre,e.apellido,
v.fecha_venta, v.tipo_venta, v.descuento,v.total, v.iva
ORDER BY v.fecha_venta DESC;

SELECT * FROM vw_ventas_consolidadas;

--? 3. Productos con Bajo Stock 

CREATE OR REPLACE VIEW vw_productos_bajo_stock AS
SELECT 
    p.id_producto,
    p.nombre AS nombre_producto,
    c.nombre AS categoria,
    p.stock_actual,
    p.stock_minimo 
FROM producto p
JOIN categoria c ON p.id_categoria = c.id_categoria
WHERE p.stock_actual < p.stock_minimo;


SELECT * FROM vw_productos_bajo_stock;

--? 4. Promociones Aplicadas

CREATE OR REPLACE VIEW vw_promociones_aplicadas AS 
SELECT v.id_venta,
    c.nombre|| ' ' ||c.apellido AS cliente,
    p.nombre AS Promocion,
    v.descuento AS Descuento_aplicado,
    v.fecha_venta
FROM venta v
JOIN cliente c ON v.id_cliente = c.id_cliente
JOIN promocion p ON v.id_promocion = p.id_promocion;

SELECT * FROM vw_promociones_aplicadas;

--? 5. Devoluciones

CREATE OR REPLACE VIEW vw_devoluciones_aplicadas AS
SELECT d.id_devolucion,
    d.fecha_devolucion                AS Fecha,
    cl.nombre || ' ' || cl.apellido  AS Cliente,
    p.nombre                          AS Producto,
    d.cantidad,
    d.motivo
FROM devolucion d
JOIN venta    v  ON d.id_venta    = v.id_venta
JOIN cliente  cl ON v.id_cliente  = cl.id_cliente
JOIN producto p  ON d.id_producto = p.id_producto;

SELECT * FROM vw_devoluciones_aplicadas;

--? 6. Desempeño de Vendedores

CREATE OR REPLACE VIEW vw_desempeno_vendedores AS
SELECT e.id_empleado,
    e.nombre || ' ' || e.apellido AS Empleado,
    NVL(ventas.total_ventas, 0) AS total_ventas,
    NVL(ventas.monto_generado, 0) AS monto_generado,
    NVL(devolucion.total_devoluciones, 0) AS total_devoluciones
FROM empleado e
LEFT JOIN (SELECT id_empleado,
    COUNT(id_venta) AS total_ventas,
    SUM(total) AS monto_generado
            FROM venta
            GROUP BY id_empleado) ventas ON e.id_empleado=ventas.id_empleado
LEFT JOIN (SELECT v.id_empleado,
    COUNT(d.id_devolucion) AS total_devoluciones
            FROM devolucion d 
            JOIN venta v  ON d.id_venta = v.id_venta
            GROUP BY v.id_empleado) devolucion ON e.id_empleado=devolucion.id_empleado
WHERE e.cargo='Vendedor';

SELECT * FROM vw_desempeno_vendedores;   
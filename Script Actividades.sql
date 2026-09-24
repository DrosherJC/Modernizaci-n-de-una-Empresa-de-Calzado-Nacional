--! Consultas
--? 1. Listado de clientes
SELECT
    id_cliente,
    CONCAT(nombre,' ',apellido) AS nombre_cliente,
    telefono,
    correo,
    provincia
FROM cliente
ORDER BY nombre DESC;

--? 2.  Productos disponibles 
SELECT p.id_producto,
    p.nombre AS nombre_producto,
    pr.tipo_proveedor AS tipo_producto,
    p.precio,
    p.stock_actual AS stock_actual
FROM producto p
JOIN proveedor pr ON p.id_proveedor = pr.id_proveedor
ORDER BY p.nombre;

--? 3.Ventas por fecha
SELECT
    v.id_venta,
    v.fecha_venta,
    CONCAT(c.nombre,' ',c.apellido) AS nombre_cliente,
    v.total AS total_venta
FROM venta v
JOIN cliente c ON c.id_cliente = v.id_cliente;

--? 4.Proveedores registrados 

SELECT
    id_proveedor,
    nombre AS proveedor,
    pais,
    tipo_proveedor,
    telefono
FROM proveedor;

--? 5.Empleados por rol 

SELECT
    id_empleado,
    nombre ||' '||apellido AS nombre_empleado,
    cargo,
    rol
FROM empleado;

--? 6.Clientes con sus compras (JOIN) 

SELECT
    CONCAT(c.nombre,' ',c.apellido) AS nombre_cliente,
    v.fecha_venta,
    v.total AS total_venta,
    v.tipo_venta
FROM cliente c
JOIN venta v ON v.id_cliente = c.id_cliente;

--? 7.Ventas con vendedor (JOIN) 

SELECT
    v.id_venta,
    CONCAT(c.nombre,' ',c.apellido) AS nombre_cliente,
    CONCAT(e.nombre,' ',e.apellido) AS nombre_empleado,
    v.fecha_venta,
    v.total AS total_venta
FROM venta v
JOIN cliente c ON c.id_cliente = v.id_cliente
JOIN empleado e ON e.id_empleado = v.id_empleado;

--? 8.Detalle de productos vendidos (JOIN) 

SELECT
    p.nombre AS producto,
    c.nombre AS categoria,
    p.precio AS precio_unitario,
    SUM(dv.subtotal) AS subtotal
FROM producto p
JOIN detalle_venta dv ON dv.id_producto = p.id_producto
JOIN categoria c ON c.id_categoria = p.id_categoria
GROUP BY p.nombre,c.nombre,p.precio;

--? 9.Productos con proveedor (JOIN) 

SELECT p.nombre AS producto,
    pr.tipo_proveedor AS tipo_rpducto,
    pr.nombre AS proveedor,
    pr.pais AS pais_proveedor
FROM producto p
JOIN proveedor pr ON p.id_proveedor = pr.id_proveedor
ORDER BY p.nombre;

--? 10.Devoluciones con cliente y producto (JOIN) 

SELECT cl.nombre || ' ' || cl.apellido AS cliente,
    p.nombre AS producto,
    d.fecha_devolucion AS fecha_devolucion,
    d.motivo,
    d.cantidad
FROM devolucion d
JOIN venta v  ON d.id_venta = v.id_venta
JOIN cliente cl ON v.id_cliente = cl.id_cliente
JOIN producto p  ON d.id_producto = p.id_producto
ORDER BY d.fecha_devolucion DESC;

--? 11.Total vendido por vendedor (GROUP BY) 

SELECT
    e.nombre || ' ' || e.apellido AS vendedor,
    COUNT(v.id_venta) AS cantidad_ventas,
    SUM(v.total) AS total_vendido
FROM empleado e
LEFT JOIN venta v ON e.id_empleado = v.id_empleado
WHERE e.cargo = 'Vendedor'
GROUP BY
    e.id_empleado,
    e.nombre,
    e.apellido
ORDER BY total_vendido DESC;


--? 12.Productos más vendidos (GROUP BY) 

SELECT p.nombre AS producto,
    SUM(dv.cantidad) AS total_unidades_vendidas
FROM detalle_venta dv
JOIN producto p ON dv.id_producto = p.id_producto
GROUP BY p.nombre
ORDER BY total_unidades_vendidas DESC;

--? 13.Ventas por mes (GROUP BY) 

SELECT
    EXTRACT( MONTH FROM fecha_venta) AS mes,
    COUNT(*) AS ventAS_realizadAS,
    SUM(total) AS total_ingreso
FROM venta
GROUP BY mes
ORDER BY mes DESC;

--? 14.Compras por cliente (GROUP BY)  

SELECT
    c.nombre || ' ' || c.apellido AS cliente,
    COUNT(v.id_venta) AS cantidad_compras,
    NVL(SUM(v.total),0) AS monto_acumulado
FROM cliente c
LEFT JOIN venta v ON c.id_cliente = v.id_cliente
GROUP BY
    c.id_cliente,
    c.nombre,
    c.apellido
ORDER BY monto_acumulado DESC;


--? 15.Devoluciones por vendedor (GROUP BY) 

SELECT
    e.nombre || ' ' || e.apellido AS vendedor,
    COUNT(d.id_devolucion) AS total_devoluciones
FROM devolucion d
JOIN venta v ON d.id_venta = v.id_venta
JOIN empleado e ON v.id_empleado = e.id_empleado
WHERE e.cargo = 'Vendedor'
GROUP BY e.nombre, e.apellido
ORDER BY total_devoluciones DESC;

--? 16.Clientes con compras superiores al promedio (Subconsulta) 

SELECT
    CONCAT(c.nombre,' ',c.apellido) AS nombre_cliente,
    SUM(v.total) AS total_comprado
FROM cliente c
JOIN venta v ON v.id_cliente = c.id_cliente
GROUP BY c.id_cliente, c.nombre, c.apellido
HAVING SUM(v.total) > (
    SELECT
    AVG(total)
    FROM venta
);

--? 17. Productos con precio mayor al promedio (Subconsulta)
SELECT nombre AS producto,
    precio  AS precio
FROM producto
WHERE precio > (SELECT AVG(precio) FROM producto)
ORDER BY precio DESC;

--? 18. Vendedores con ventas superiores al promedio (Subconsulta) 

SELECT
    e.nombre||' '||e.apellido AS vendedor,
    SUM(v.total) AS total_vendido
FROM empleado e
JOIN venta v ON e.id_empleado = v.id_empleado
WHERE e.cargo = 'Vendedor'
GROUP BY e.id_empleado, e.nombre, e.apellido
HAVING SUM(v.total) > (
    SELECT AVG(total_vendido) 
    FROM (
        SELECT 
            v2.id_empleado, 
            SUM(v2.total) AS total_vendido
        FROM venta v2
        JOIN empleado e2 ON v2.id_empleado = e2.id_empleado
        WHERE e2.cargo = 'Vendedor'
        GROUP BY v2.id_empleado))
ORDER BY total_vendido DESC;  

--? 19. Productos que nunca se han vendido (Subconsulta) 

SELECT id_producto,
    nombre AS nombre_producto,
    stock_actual AS sotck_actual
FROM producto
WHERE id_producto NOT IN (
    SELECT DISTINCT id_producto FROM detalle_venta
)
ORDER BY nombre;

--? 20. Clientes que no han realizado compras (Subconsulta) 

SELECT
    c.id_cliente,
    c.nombre AS nombres,
    c.apellido AS apellidos,
    c.telefono
FROM cliente c
WHERE c.id_cliente NOT IN (
    SELECT v.id_cliente
    FROM venta v
);








--! 6. Transacciones =================
--? 1. Venta Completa
--? 2. Devolución Completa
--? 3. Compra a Proveedor
--? 4. Actualización MASiva de Inventario

--! 7. Seguridad - Usuarios y Privilegios =================

--! 8. Auditoría =================

--! 9. Respaldo y Recuperación =================
--? 1. Respaldo inicial

--? 2. Respaldo intermedio
--? 3. Respaldo final




SELECT * FROM VENTA;
select * from detalle_venta;
SELECT * FROM promocion;
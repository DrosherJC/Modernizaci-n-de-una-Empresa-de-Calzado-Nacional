

--! rol vendedor: registra clientes y ventas 
GRANT SELECT ON producto TO rol_vendedor;
GRANT SELECT ON categoria TO rol_vendedor;
GRANT SELECT ON promocion TO rol_vendedor;
GRANT SELECT, INSERT ON cliente TO rol_vendedor;
GRANT SELECT, INSERT ON venta TO rol_vendedor;
GRANT SELECT, INSERT ON detalle_venta TO rol_vendedor;
GRANT SELECT, INSERT ON queja TO rol_vendedor;

GRANT EXECUTE ON sp_registrar_cliente TO rol_vendedor;
GRANT EXECUTE ON sp_registrar_venta TO rol_vendedor;
GRANT EXECUTE ON sp_registrar_queja TO rol_vendedor;
GRANT EXECUTE ON sp_aplicar_promocion TO rol_vendedor;
GRANT EXECUTE ON fn_calcular_iva TO rol_vendedor;
GRANT EXECUTE ON fn_calcular_descuento TO rol_vendedor;
GRANT EXECUTE ON fn_calcular_antiguedad_cliente TO rol_vendedor;
GRANT EXECUTE ON t_producto_venta TO rol_vendedor;
GRANT EXECUTE ON t_lista_productos TO rol_vendedor;

--! rol cajero: procesa pagos y devoluciones, no crea ventas nuevas
GRANT SELECT ON producto TO rol_cajero;
GRANT SELECT ON promocion TO rol_cajero;
GRANT SELECT ON venta TO rol_cajero;
GRANT SELECT, INSERT ON devolucion TO rol_cajero;

GRANT EXECUTE ON sp_registrar_devolucion TO rol_cajero;
GRANT EXECUTE ON fn_calcular_iva TO rol_cajero;

--!  rol bodeguero: stock, movimientos y compras a proveedor 
GRANT SELECT, UPDATE ON producto TO rol_bodeguero;
GRANT SELECT, INSERT ON inventario TO rol_bodeguero;
GRANT SELECT ON proveedor TO rol_bodeguero;
GRANT SELECT, INSERT ON compra TO rol_bodeguero;
GRANT SELECT, INSERT ON detalle_compra TO rol_bodeguero;

GRANT EXECUTE ON sp_actualizar_inventario TO rol_bodeguero;
GRANT EXECUTE ON fn_productos_bajo_stock TO rol_bodeguero;

--!  rol contador: solo lectura de todo lo financiero 
GRANT SELECT ON venta TO rol_contador;
GRANT SELECT ON detalle_venta TO rol_contador;
GRANT SELECT ON compra TO rol_contador;
GRANT SELECT ON detalle_compra TO rol_contador;
GRANT SELECT ON devolucion TO rol_contador;
GRANT SELECT ON promocion TO rol_contador;
GRANT SELECT ON auditoria TO rol_contador;

GRANT EXECUTE ON sp_calcular_ventas_mensuales TO rol_contador;
GRANT EXECUTE ON fn_calcular_comision TO rol_contador;
GRANT EXECUTE ON fn_calcular_iva TO rol_contador;

--! rol supervisor ventas: hereda vendedor + gestiona promociones y catalogo 

GRANT SELECT, INSERT, UPDATE ON promocion TO rol_supervisor_ventas;
GRANT SELECT, INSERT, UPDATE ON producto TO rol_supervisor_ventas;
GRANT SELECT, INSERT ON categoria TO rol_supervisor_ventas;
GRANT SELECT ON empleado TO rol_supervisor_ventas;

GRANT EXECUTE ON sp_registrar_producto TO rol_supervisor_ventas;
GRANT EXECUTE ON Clientes_Frecuentes TO rol_supervisor_ventas;

--! rol gerente sucursal: vision total de la sucursal, gestiona personal y proveedores 
GRANT SELECT ON venta TO rol_gerente_sucursal;
GRANT SELECT ON detalle_venta TO rol_gerente_sucursal;
GRANT SELECT ON compra TO rol_gerente_sucursal;
GRANT SELECT ON detalle_compra TO rol_gerente_sucursal;
GRANT SELECT ON producto TO rol_gerente_sucursal;
GRANT SELECT ON inventario TO rol_gerente_sucursal;
GRANT SELECT ON cliente TO rol_gerente_sucursal;
GRANT SELECT, INSERT, UPDATE ON empleado TO rol_gerente_sucursal;
GRANT SELECT, INSERT, UPDATE ON proveedor TO rol_gerente_sucursal;
GRANT SELECT, UPDATE ON queja TO rol_gerente_sucursal;
GRANT SELECT ON auditoria TO rol_gerente_sucursal;

GRANT EXECUTE ON sp_registrar_proveedor TO rol_gerente_sucursal;
GRANT EXECUTE ON sp_calcular_ventas_mensuales TO rol_gerente_sucursal;
GRANT EXECUTE ON fn_calcular_comision TO rol_gerente_sucursal;
GRANT EXECUTE ON Clientes_Frecuentes TO rol_gerente_sucursal;
GRANT EXECUTE ON fn_productos_bajo_stock TO rol_gerente_sucursal;


-- =========================================================
-- Prueba: menor privilegio (conectado como usr_cajero1 esto debe fallar)
-- =========================================================
-- DELETE FROM producto WHERE id_producto = 1;
-- Esperado: ORA-01031: insufficient privileges
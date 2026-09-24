# Modernización de una Empresa de Calzado Nacional — Ecuador

Proyecto final de Bases de Datos (ESFOT - Escuela Politécnica Nacional).
Sistema de información en **Oracle Database** que centraliza la gestión de
clientes, productos, proveedores, empleados, ventas, compras, devoluciones,
promociones, inventario y auditoría de una empresa ecuatoriana de calzado.

## Descripción

Antes de este sistema, cada sucursal llevaba su inventario y ventas en hojas
de cálculo independientes, lo que generaba descuadres de stock, ventas sin
verificación de existencias y ausencia de trazabilidad sobre quién modificaba
precios o datos de clientes. Este proyecto resuelve eso con un esquema Oracle
normalizado (14 entidades), reglas de negocio garantizadas a nivel de motor,
lógica encapsulada en funciones/procedimientos/triggers, control de acceso
basado en roles y una estrategia de respaldo con Oracle Data Pump.

## Estructura del repositorio

| Archivo | Contenido |
|---|---|
| `Diseño Fisico.sql` | DDL: creación de las 14 tablas con restricciones (`NOT NULL`, `UNIQUE`, `CHECK`) e integridad referencial |
| `Inserts.sql` | Carga de datos de prueba para todas las tablas |
| `Functions.sql` | Funciones: IVA, descuento, antigüedad de cliente, comisión, productos bajo stock, clientes frecuentes |
| `Store Procedures.sql` | Procedimientos: registrar cliente/producto/venta/devolución/proveedor/queja, actualizar inventario, aplicar promoción, calcular ventas mensuales, registrar auditoría |
| `Triggers.sql` | Triggers de auditoría (INSERT/UPDATE/DELETE cliente), control de stock (descuento/incremento/bloqueo negativo), cambio de precio y registro de acceso (AFTER LOGON) |
| `Views.sql` | Vistas: clientes frecuentes, ventas consolidadas, productos con bajo stock, promociones aplicadas, devoluciones, desempeño de vendedores |
| `Script Actividades.sql` | Las 20 consultas del proyecto (listados, JOINs, GROUP BY, subconsultas) |
| `Transactions.sql` | Transacciones con `SAVEPOINT`/`ROLLBACK`: venta completa, devolución completa, compra a proveedor, actualización masiva de inventario |
| `RolesSystem.sql` | Creación de roles y usuarios de aplicación |
| `roles.sql` | Asignación de privilegios (`GRANT`) por rol sobre tablas y procedimientos |

## Modelo de datos

14 entidades: `cliente`, `categoria`, `proveedor`, `empleado`, `venta`,
`detalle_venta`, `compra`, `detalle_compra`, `devolucion`, `promocion`,
`inventario`, `queja`, `producto` y `auditoria` (bitácora transversal
alimentada por triggers).

## Reglas de negocio principales

- Cédula y correo únicos por cliente.
- El stock nunca queda negativo; toda salida se valida contra existencia.
- Toda venta se clasifica como `Mayor` o `Menor` e incluye al menos un producto.
- Una devolución no puede superar la cantidad disponible de la venta original.
- IVA = 15% del subtotal ya con descuento aplicado.
- Cliente "frecuente": más de 5 compras o monto acumulado ≥ $500.
- Cambios en precios de producto y datos de cliente quedan auditados.

## Seguridad

6 roles con privilegio mínimo, alineados a los perfiles reales de la empresa:
`rol_vendedor`, `rol_cajero`, `rol_bodeguero`, `rol_contador`,
`rol_supervisor_ventas` (hereda de `rol_vendedor`) y `rol_gerente_sucursal`.
Ningún rol operativo tiene privilegios de `DROP`/`ALTER`/`DELETE` general;
solo el propietario del esquema (`proyectoBD`) tiene control total.

## Respaldo

Respaldo lógico a nivel de esquema con **Oracle Data Pump**, sobre una
instancia de Oracle Database Free 23ai en un contenedor Podman.

## Orden de ejecución sugerido

1. `Diseño Fisico.sql`
2. `Functions.sql`
3. `Store Procedures.sql`
4. `Triggers.sql`
5. `Inserts.sql`
6. `Views.sql`
7. `Transactions.sql`
8. `RolesSystem.sql`
9. `roles.sql`
10. `Script Actividades.sql` (consultas de verificación)

## Alcance

No incluye integración con hardware de punto de venta, facturación
electrónica ante el SRI ni sincronización en tiempo real entre sucursales
(ver recomendaciones en el informe final).

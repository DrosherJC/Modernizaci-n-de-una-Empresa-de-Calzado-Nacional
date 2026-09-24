--*System user

--! Roles
CREATE ROLE rol_cajero;
CREATE ROLE rol_vendedor;
CREATE ROLE rol_supervisor_ventas;
CREATE ROLE rol_bodeguero;
CREATE ROLE rol_contador;
CREATE ROLE rol_gerente_sucursal;

GRANT rol_vendedor TO rol_supervisor_ventas;

--! Usuarios
CREATE USER usr_cajero1 IDENTIFIED BY Cajero2026;
CREATE USER usr_vendedor1 IDENTIFIED BY Vendedor2026;
CREATE USER usr_supervisor1 IDENTIFIED BY Supervisor2026;
CREATE USER usr_bodeguero1 IDENTIFIED BY Bodega2026;
CREATE USER usr_contador1 IDENTIFIED BY Conta2026;
CREATE USER usr_gerente1 IDENTIFIED BY Gerente2026;

--! Conexion 
GRANT CONNECT TO usr_cajero1;
GRANT rol_cajero TO usr_cajero1;

GRANT CONNECT TO usr_vendedor1;
GRANT rol_vendedor TO usr_vendedor1;

GRANT CONNECT TO usr_supervisor1;
GRANT rol_supervisor_ventas TO usr_supervisor1;

GRANT CONNECT TO usr_bodeguero1;
GRANT rol_bodeguero TO usr_bodeguero1;

GRANT CONNECT TO usr_contador1;
GRANT rol_contador TO usr_contador1;

GRANT CONNECT TO usr_gerente1;
GRANT rol_gerente_sucursal TO usr_gerente1;


--! Verificacion
SELECT role FROM dba_roles WHERE role LIKE 'ROL_%';
SELECT username, account_status, created FROM dba_users WHERE username LIKE 'USR_%';
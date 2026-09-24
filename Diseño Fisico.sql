CREATE TABLE proveedor (
    id_proveedor NUMBER GENERATED ALWAYS AS IDENTITY,
    nombre VARCHAR2(100) NOT NULL UNIQUE,
    pais VARCHAR2(50) NOT NULL,
    tipo_proveedor VARCHAR2(20) CHECK (tipo_proveedor IN ('Nacional','Importado')),
    telefono VARCHAR2(20) NOT NULL UNIQUE,
    correo VARCHAR2(100) NOT NULL UNIQUE,
    direccion VARCHAR2(150) NOT NULL,
    CONSTRAINT pk_proveedor PRIMARY KEY (id_proveedor)
);

CREATE TABLE empleado (
    id_empleado NUMBER GENERATED ALWAYS AS IDENTITY,
    cedula VARCHAR2(13) NOT NULL UNIQUE,
    nombre VARCHAR2(60) NOT NULL,
    apellido VARCHAR2(60) NOT NULL,
    cargo VARCHAR2(40) NOT NULL,
    rol VARCHAR2(30) NOT NULL,
    telefono VARCHAR2(20) NOT NULL,
    correo VARCHAR2(100) NOT NULL UNIQUE,
    fecha_contratacion DATE DEFAULT SYSDATE,
    salario NUMBER(10,2) CHECK (salario >= 0),
    CONSTRAINT pk_empleado PRIMARY KEY (id_empleado)
);

CREATE TABLE cliente (
    id_cliente NUMBER GENERATED ALWAYS AS IDENTITY,
    cedula VARCHAR2(13) NOT NULL UNIQUE,
    nombre VARCHAR2(60) NOT NULL,
    apellido VARCHAR2(60) NOT NULL,
    telefono VARCHAR2(20) NOT NULL,
    correo VARCHAR2(100) NOT NULL UNIQUE,
    provincia VARCHAR2(40) NOT NULL,
    direccion VARCHAR2(150) NOT NULL,
    fecha_registro DATE DEFAULT SYSDATE,
    CONSTRAINT pk_cliente PRIMARY KEY (id_cliente)
);

CREATE TABLE promocion (
    id_promocion NUMBER GENERATED ALWAYS AS IDENTITY,
    nombre VARCHAR2(80) NOT NULL UNIQUE,
    tipo_descuento VARCHAR2(20) CHECK (tipo_descuento IN ('Porcentaje','Monto')),
    valor_descuento NUMBER(8,2) NOT NULL CHECK (valor_descuento >= 0),
    condicion VARCHAR2(150),
    monto_minimo NUMBER(10,2) DEFAULT 0 NOT NULL CHECK (monto_minimo >= 0),
    CONSTRAINT pk_promocion PRIMARY KEY (id_promocion)
);

CREATE TABLE categoria (
    id_categoria NUMBER GENERATED ALWAYS AS IDENTITY,
    nombre VARCHAR2(60) NOT NULL UNIQUE,
    descripcion VARCHAR2(150) NOT NULL,
    CONSTRAINT pk_categoria PRIMARY KEY (id_categoria)
);

CREATE TABLE producto (
    id_producto NUMBER GENERATED ALWAYS AS IDENTITY,
    nombre VARCHAR2(100) NOT NULL UNIQUE,
    id_categoria NUMBER NOT NULL,
    id_proveedor NUMBER NOT NULL,
    precio NUMBER(10,2) NOT NULL CHECK (precio >= 0),
    stock_actual NUMBER(8) DEFAULT 0 CHECK (stock_actual >= 0) NOT NULL,
    stock_minimo NUMBER(8) CHECK (stock_minimo >= 0) NOT NULL,
    CONSTRAINT pk_productos PRIMARY KEY (id_producto),
    CONSTRAINT fk_prod_categoria FOREIGN KEY (id_categoria) REFERENCES categoria(id_categoria),
    CONSTRAINT fk_prod_proveedor FOREIGN KEY (id_proveedor) REFERENCES proveedor(id_proveedor)
);

CREATE TABLE inventario (
    id_movimiento NUMBER GENERATED ALWAYS AS IDENTITY,
    id_producto NUMBER NOT NULL,
    tipo_movimiento VARCHAR2(10) CHECK (tipo_movimiento IN ('Entrada','Salida')) NOT NULL,
    cantidad NUMBER(8) NOT NULL CHECK (cantidad > 0),
    fecha_movimiento DATE DEFAULT SYSDATE,
    motivo VARCHAR2(150) NOT NULL,
    CONSTRAINT pk_inventario PRIMARY KEY (id_movimiento),
    CONSTRAINT fk_inv_producto FOREIGN KEY (id_producto) REFERENCES producto(id_producto) ON DELETE CASCADE
);

CREATE TABLE venta (
    id_venta        NUMBER GENERATED ALWAYS AS IDENTITY,
    id_cliente      NUMBER NOT NULL,
    id_empleado     NUMBER NOT NULL,
    id_promocion    NUMBER,
    fecha_venta     DATE DEFAULT SYSDATE,
    tipo_venta      VARCHAR2(20) CHECK (tipo_venta IN ('Mayor','Menor')) NOT NULL,
    descuento       NUMBER(10,2) DEFAULT 0 CHECK (descuento >= 0),
    iva             NUMBER(10,2) DEFAULT 0 NOT NULL CHECK (iva >= 0),
    total           NUMBER(10,2) DEFAULT 0 CHECK (total >= 0),
    CONSTRAINT pk_venta PRIMARY KEY (id_venta),
    CONSTRAINT fk_venta_cliente FOREIGN KEY (id_cliente) REFERENCES cliente(id_cliente),
    CONSTRAINT fk_venta_empleado FOREIGN KEY (id_empleado) REFERENCES empleado(id_empleado),
    CONSTRAINT fk_venta_promocion FOREIGN KEY (id_promocion) REFERENCES promocion(id_promocion) ON DELETE SET NULL
);

CREATE TABLE detalle_venta (
    id_detalle_venta   NUMBER GENERATED ALWAYS AS IDENTITY,
    id_venta           NUMBER NOT NULL,
    id_producto        NUMBER NOT NULL,
    cantidad           NUMBER(8) NOT NULL CHECK (cantidad > 0),
    precio_unitario    NUMBER(10,2) NOT NULL CHECK (precio_unitario >= 0),
    subtotal           NUMBER(10,2) NOT NULL CHECK (subtotal >= 0),
    CONSTRAINT pk_detalle_venta PRIMARY KEY (id_detalle_venta),
    CONSTRAINT fk_detv_venta FOREIGN KEY (id_venta) REFERENCES venta(id_venta) ON DELETE CASCADE,
    CONSTRAINT fk_detv_producto FOREIGN KEY (id_producto) REFERENCES producto(id_producto)
);

CREATE TABLE devolucion (
    id_devolucion NUMBER GENERATED ALWAYS AS IDENTITY,
    id_venta NUMBER NOT NULL,
    id_producto NUMBER NOT NULL,
    cantidad NUMBER(8) NOT NULL CHECK (cantidad > 0),
    fecha_devolucion DATE DEFAULT SYSDATE,
    motivo VARCHAR2(150),
    CONSTRAINT pk_devolucion PRIMARY KEY (id_devolucion),
    CONSTRAINT fk_dev_venta FOREIGN KEY (id_venta) REFERENCES venta(id_venta),
    CONSTRAINT fk_dev_producto FOREIGN KEY (id_producto) REFERENCES producto(id_producto)
);

CREATE TABLE compra (
    id_compra       NUMBER GENERATED ALWAYS AS IDENTITY,
    id_proveedor    NUMBER NOT NULL,
    id_empleado     NUMBER NOT NULL,
    fecha_compra    DATE DEFAULT SYSDATE,
    total           NUMBER(10,2) DEFAULT 0 CHECK (total >= 0),
    CONSTRAINT pk_compra PRIMARY KEY (id_compra),
    CONSTRAINT fk_compra_proveedor FOREIGN KEY (id_proveedor) REFERENCES proveedor(id_proveedor),
    CONSTRAINT fk_compra_empleado FOREIGN KEY (id_empleado) REFERENCES empleado(id_empleado)
);

CREATE TABLE detalle_compra (
    id_detalle_compra  NUMBER GENERATED ALWAYS AS IDENTITY,
    id_compra          NUMBER NOT NULL,
    id_producto         NUMBER NOT NULL,
    cantidad            NUMBER(8) NOT NULL CHECK (cantidad > 0),
    precio_unitario     NUMBER(10,2) NOT NULL CHECK (precio_unitario >= 0),
    subtotal            NUMBER(10,2) NOT NULL CHECK (subtotal >= 0),
    CONSTRAINT pk_detalle_compra PRIMARY KEY (id_detalle_compra),
    CONSTRAINT fk_detc_compra FOREIGN KEY (id_compra) REFERENCES compra(id_compra) ON DELETE CASCADE,
    CONSTRAINT fk_detc_producto FOREIGN KEY (id_producto) REFERENCES producto(id_producto)
);

CREATE TABLE auditoria (
    id_auditoria NUMBER GENERATED ALWAYS AS IDENTITY,
    usuario VARCHAR2(60) NOT NULL,
    accion VARCHAR2(20) NOT NULL,
    tabla_afectada VARCHAR2(60) NOT NULL,
    fecha_hora TIMESTAMP DEFAULT SYSTIMESTAMP,
    valor_anterior VARCHAR2(4000),
    valor_nuevo VARCHAR2(4000),
    CONSTRAINT pk_auditoria PRIMARY KEY (id_auditoria)
);

CREATE TABLE queja (
    id_queja       NUMBER GENERATED ALWAYS AS IDENTITY,
    id_cliente     NUMBER,
    tipo           VARCHAR2(20) CHECK (tipo IN ('Reclamo','Sugerencia')) NOT NULL,
    descripcion    VARCHAR2(500) NOT NULL,
    fecha_registro DATE DEFAULT SYSDATE,
    CONSTRAINT pk_queja PRIMARY KEY (id_queja),
    CONSTRAINT fk_queja_cliente FOREIGN KEY (id_cliente)
        REFERENCES cliente(id_cliente)
);

-- DROP TABLE auditoria;
-- DROP TABLE categoria;
-- DROP TABLE cliente;
-- DROP TABLE compra;
-- DROP TABLE detalle_compra;
-- DROP TABLE detalle_venta;
-- DROP TABLE devolucion;
-- DROP TABLE empleado;
-- DROP TABLE inventario;
-- DROP TABLE producto;
-- DROP TABLE promocion;
-- DROP TABLE proveedor;
-- DROP TABLE venta;

-- SELECT table_name FROM user_tables;
SELECT object_name, original_name FROM user_recyclebin;
PURGE RECYCLEBIN;

DROP TABLE IF EXISTS document_items;
DROP TABLE IF EXISTS documents;
DROP TABLE IF EXISTS user_types;
DROP TABLE IF EXISTS permissions;
DROP TABLE IF EXISTS  role_permissions;
DROP TABLE IF EXISTS warehouses;
DROP TABLE IF EXISTS users;
DROP TABLE IF EXISTS books;




CREATE TABLE warehouses(
    warehouse_id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT Null UNIQUE,
    created_at TIMESTAMP DEFAULT NOW()
);



CREATE TABLE books(
    book_id SERIAL PRIMARY KEY,
    title VARCHAR(200) NOT Null,
    created_at TIMESTAMP DEFAULT NOW()
);


CREATE TABLE documents(
    document_id BIGSERIAL PRIMARY KEY,
    document_type VARCHAR(10) NOT NULL CHECK(document_type IN('OUTGOING','INCOMING','PRODUCTION')),
    from_warehouse_id INT NOT NULL REFERENCES warehouses(warehouse_id),
    to_warehouse_id INT  REFERENCES warehouses(warehouse_id),
    related_document_id BIGINT REFERENCES documents(document_id),

    created_at TIMESTAMP DEFAULT NOW(),
    CHECK(to_warehouse_id IS  NULL OR from_warehouse_id <> to_warehouse_id)
);

CREATE TABLE document_items(
    document_items_id BIGSERIAL PRIMARY KEY,
    document_id BIGINT NOT NULL REFERENCES documents(document_id) ON DELETE  CASCADE,
    book_id INT NOT NULL REFERENCES books(book_id),
    quantity INT NOT Null CHECK(quantity >0),
    UNIQUE(document_id,book_id)
);



CREATE TABLE user_types(
    user_type_id SERIAL PRIMARY KEY,
    name VARCHAR(50) NOT NULL UNIQUE
);


CREATE TABLE permissions(
    permission_id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE
);

--جدول كسر علاقة (جدول وسيط)
CREATE TABLE role_permissions(
    user_type_id INT NOT NULL REFERENCES user_types(user_type_id) ON DELETE CASCADE,
    permission_id INT NOT NULL REFERENCES permissions(permission_id) ON DELETE CASCADE ,
    PRIMARY KEY(user_type_id ,permission_id)

);


CREATE TABLE users(

  user_id SERIAL PRIMARY KEY,
  name     VARCHAR(100) NOT Null,
  email   VARCHAR(100) NOT Null UNIQUE,
  password  VARCHAR(100) NOT Null,
  user_type_id INT REFERENCES user_types(user_type_id),
  warehouse_id INT REFERENCES warehouses(warehouse_id),
  created_at TIMESTAMP DEFAULT NOW()
);


-- INSERT INTO warehouses(name) VALUES ('المطبعة'),('المستودع المركزي'),('المستودع الرئيسي');
-- INSERT INTO books (title) VALUES ('قواعد بيانات'),('معرفية '),('برمجة');


-- INSERT INTO user_types (name)
-- VALUES
--     ('PRINT_MANAGER'),
--     ('CENTRAL_WAREHOUSE_MANAGER'),
--     ('MAIN_WAREHOUSE_MANAGER');
-- --==========================
-- INSERT INTO permissions (name)
-- VALUES
--     ('CREATE_PRODUCTION'),
--     ('CREATE_OUTGOING'),
--     ('CREATE_INCOMING'),
--     ('VIEW_MY_BALANCE'),
--     ('VIEW_ALL_MOVEMENTS');

--============================
-- صلاحيات امين مستودع المطبعة

-- INSERT INTO role_permissions (user_type_id, permission_id)
-- SELECT ut.user_type_id, p.permission_id
-- FROM user_types ut, permissions p
-- WHERE ut.name = 'PRINT_MANAGER'
-- AND p.name IN (
--     'CREATE_PRODUCTION',
--     'CREATE_OUTGOING',
--     'VIEW_MY_BALANCE'
-- );

--==================================
--صلاحيات امين المستودع المركزي 
-- INSERT INTO role_permissions (user_type_id, permission_id)
-- SELECT ut.user_type_id, p.permission_id
-- FROM user_types ut, permissions p
-- WHERE ut.name = 'CENTRAL_WAREHOUSE_MANAGER'
-- AND p.name IN (
--     'CREATE_INCOMING',
--     'CREATE_OUTGOING',
--     'VIEW_MY_BALANCE'
-- );

--===========================================
-- صلاحيات امين مستودع الرئيسي 

-- INSERT INTO role_permissions (user_type_id, permission_id)
-- SELECT ut.user_type_id, p.permission_id
-- FROM user_types ut, permissions p
-- WHERE ut.name = 'MAIN_WAREHOUSE_MANAGER'
-- AND p.name IN (
--     'CREATE_INCOMING',
--     'VIEW_MY_BALANCE'
-- );

--=================================
-- انشاء ال الادمن واخذ كلمة مروره و منعملا 
-- hash باستخدام المكتبة 
-- bcrypt 
-- ثم نحشرها 

-- INSERT INTO users (
--     name,
--     email,
--     password,
--     user_type_id,
--     warehouse_id
-- )
-- VALUES (
--     'مدير النظام',
--     'admin@example.com',
--     '123456',
--     NULL,
--     NULL
-- );


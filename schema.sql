DROP TABLE IF EXISTS document_items;
DROP TABLE IF EXISTS documents;
DROP TABLE IF EXISTS users;
DROP TABLE IF EXISTS warehouses;
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

CREATE TABLE users(

  user_id SERIAL PRIMARY KEY,
  name     VARCHAR(100) NOT Null,
  email   VARCHAR(100) NOT Null UNIQUE,
  password  VARCHAR(100) NOT Null,
  role VARCHAR(30) NOT Null CHECK(role IN('SUPER_ADMIN','WH_MANAGER','PRINT_MANAGER')),
  warehouse_id INT REFERENCES warehouses(warehouse_id),
  created_at TIMESTAMP DEFAULT NOW()
);

--Admin 
--POST http://localhost:3000/auth/register
-- {
--   "name": "نور",
--   "email": "nour@gmail.com",
--   "password": "123456"
-- } 
--التعديل ع الدور ليصبح ادمن 
--UPDATE users SET  role='SUPER_ADMIN'WHERE user_id=8;

--=====================================

--للتجريب 
-- INSERT INTO warehouses(name) VALUES ('المطبعة'),('المستودع المركزي'),('المستودع الرئيسي');
-- INSERT INTO books (title) VALUES ('قواعد بيانات'),('معرفية '),('برمجة');



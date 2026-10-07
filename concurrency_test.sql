SELECT create_incoming_document(29, 2);


--(Concurrency Test)
-- اختبار التزامن لإنشاء مذكرة وارد

-- الهدف

-- التأكد من أن النظام يمنع إنشاء أكثر من مذكرة وارد  لنفس المذكرة الصادرة 
-- عند وصول عدة طلبات في نفس الوقت

--  "pgbench" تم استخدام 
-- لمحاكاة 20 طلبًا متزامنًا يحاولون استلام نفس المذكرة الصادرة

-- ---

-- الحماية المستخدمة

-- تم الاعتماد على آليتين لحماية البيانات من التكرار

-- 1. قفل الصف باستخدام FOR UPDATE

-- داخل الدالة انشاء الوارد

-- SELECT from_warehouse_id,
--        to_warehouse_id,
--        document_type
-- INTO v_fromWarehouseId,
--      v_toWarehouseId,
--      v_document_type
-- FROM documents
-- WHERE document_id = p_outgoingDocumentId
-- FOR UPDATE;

-- يقوم 
--"FOR UPDATE"
-- بقفل سجل المذكرة الصادرة أثناء تنفيذ المعاملة، مما يمنع الطلبات المتزامنة من معالجة نفس المذكرة في الوقت نفسه

-- 2. Unique Partial Index تم انشاء 
-- CREATE UNIQUE INDEX IF NOT EXISTS
-- unique_incoming_per_outgoing
-- ON documents (related_document_id)
-- WHERE document_type = 'INCOMING';

-- هذا يضمن على مستوى قاعدة البيانات أن كل مذكرة صادرة يمكن أن يكون لها مذكرة وارد واحدة فقط

-- إعداد الاختبار

-- تم اختيار المذكرة الصادرة
-- OUTGOING ID: 10
-- From Warehouse: 1
-- To Warehouse: 2

--  10 وكانت المذكرة الصادرة للي رقمهام
-- لا تحتوي على مذكرة وارد قبل بدء الاختبار
-- تم إنشاء ملف:
-- concurrency_test.sql

-- ومحتواه:
-- SELECT create_incoming_document(10, 2);
-- أمر تشغيل الاختبار

-- & "C:\Program Files\PostgreSQL\18\bin\pgbench.exe" -n -c 20 -j 4 -t 1 -f concurrency_test.sql -U postgres try


-- FOR UPDATE
-- +
-- Unique Partial Index

-- وهذا يضمن عدم تسجيل نفس المذكرة الصادرة كمستلمة أكثر من مرة حتى في حالة وصول عدة طلبات في الوقت نفسه.

## فكرة المشروع 

نظام لإدارة حركة الكتب بين المطبعة والمستودع المركزي والمستودع الرئيسي
يسمح النظام بتسجيل إنتاج الكتب، وانشاء المذكرات الصادرة والواردة، وتتبع حركة الكتب بين المستودعات، وحساب الرصيد الحالي لكل مستودع
حيث:
يتم حساب رصيد الكتب اعتمادًا على حركات الإنتاج + والوارد + والصادر-، ولا يتم تخزين الرصيد كقيمة ثابتة
يوجد 3 مستودعات في  النظام حاليا (مستودع المطبعة و مستودع المركزي و مستودع رئيسي )

## التقنيات المستخدمة بالمشروع 
يعتمد النظام على 
NestJS + PostgreSQL+ Prisma7 + مع نظام مصادقة JWT 
ونظام صلاحيات يعتمد على نوع المستخدم والصلاحيات المرتبطة به
منطق العمل موجود داخل  PostgreSQL Functions
(5 دوال sql موجودة بملف functions.sql)


## تشغيل المشرووع 

1. تحميل المشروع
 git clone https://github.com/AyatSwais/documents_books
cd books-documents/nest-app
2. تثبيت الحزم
npm install
3. إعداد متغيرات البيئة
إنشاء ملف .env في جذر المشروع وإضافة إعدادات قاعدة البيانات ومفتاح JWT.
بالشكل التالي 
DATABASE_URL="postgresql://postgres:password@localhost:5432/try"
JWT_SECRET="your-secret-key"

// try هي اسم قاعدة البيانات التي تم انشا,ها من خلال تنفيذ ملفل shcema.sql + ملف functions.sql


4. توليد Prisma Client
npx prisma generate

5. إعداد قاعدة البيانات
يتم إنشاء الجداول والدوال المطلوبة في PostgreSQL 
من خلال الملفات 
schema.sql
functions.sql
 ثم  ننفذ الامر 
npx prisma db pull لنستطيع التعرف لبنية القاعدة والقدرة ع التعامل معها من NESTjs 

6. (books-documents/nest-app)تشغيل المشروع في التيرمينال بالمسار 
npm run start:dev

## أنواع المستخدمين والصلاحيات

1. PRINT_MANAGER(مسؤول عن المطبعة)

الصلاحيات
CREATE_PRODUCTION  ( إنشاء مذكرة ل إنتاج الكتب وتكوين رصيد من الكتب )
CREATE_OUTGOING  (إنشاء مذكرة صادرة من المطبعة)
VIEW_MY_BALANCE (عرض رصيد الكتب في المطبعة)

2. CENTRAL_WAREHOUSE_MANAGER (مسؤول عن المستودع المركزي)

الصلاحيات
CREATE_INCOMING (إنشاء مذكرة وارد لاستلام الصادر الموجه من لمطبعة )
CREATE_OUTGOING (إنشاء مذكرة صادرة من المستودع المركزي إلى مستودع الرئيسي)
VIEW_MY_BALANCE  (عرض رصيد الكتب في المستودع المركزي)

3. MAIN_WAREHOUSE_MANAGER  (مسؤول عن المستودع الرئيسي)

الصلاحيات
CREATE_INCOMING (إنشاء مذكرة وارد لاستلام الصادر الموجه إلى المستودع الرئيسي من المركزي )
VIEW_MY_BALANCE (عرض رصيد الكتب في المستودع الرئيسي)

4. SuperAdmin
الـ SuperAdmin 
هو المستخدم الذي لا يرتبط بـ user_type_id في قاعدة البيانات
يستطيع إدارة المستخدمين والاطلاع على بيانات النظام حسب الصلاحيات الخاصة بإدارة المستخدمين
صلاحيات إدارة المستخدمين تشمل:
* انشاء / تسجيل مستخدمين جدد
* VIEW_ALL_MOVEMENTS ( الاطلاع على جميع حركات الكتب)

## حماية التزامن
تم اختبار إنشاء الوارد لنفس الصادر بشكل متزامن باستخدام pgbench  (concurrency_test.sql  موثقة بملف )
آليات الحماية 
  FOR UPDATE
     +
  Unique Partial Index


  ## endpoints اهم ال 
  في postman :

 POST http://localhost:3000/auth/login
 {
  "email": "ayat@gmail.com",
  "password": "123456"
}


 POST http://localhost:3000/auth/register  
{
  "name": "آيات صويص",
  "email": "ayat@gmail.com",
  "password": "123456",
  "usertypeId":1
  "warehouseId": 1
}  

 POST  http://localhost:3000/documents/production
 { 
    "items": [
        {
            "bookId": 1,
            "quantity": 200
        },
        {
            "bookId": 2,
            "quantity": 100
        }
    ]
  }

 GET  http://localhost:3000/documents/my-balance

 GET  http://localhost:3000/documents/movements

 POST  http://localhost:3000/documents/outgoing
 {  "toWarehouseId": 2,
    "items": [
        {
            "bookId": 1,
            "quantity": 40
        },
        {
            "bookId": 2,
            "quantity": 20
        }
    ]
  }


 POST  http://localhost:3000/documents/incoming
{ "outgoingDocumentId":رقم المذكرة الصادرة الناتجة عن الطلب  الصادر السابق }

## ملاحظة
تم انشاء ال الادمن من خلال تعليمة sql على القاعدة 
يستطيع لاحقا انشاء مستخدمين 
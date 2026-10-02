-- 
CREATE OR REPLACE FUNCTION create_outgoing_document(
    p_fromWarehouseId INT,
    p_toWarehouseId INT,
    p_items JSONB
)
RETURNS BIGINT
LANGUAGE plpgsql
AS $$
DECLARE
   v_document_id INT;
   v_quantity INT;
   v_book_id INT;
   v_balance INT;
   v_item JSONB;
   
BEGIN

PERFORM 1 FROM warehouses WHERE warehouse_id=p_toWarehouseId;
if NOT FOUND THEN 
RAISE EXCEPTION 'المستودع الهدف % غير موجود ', p_toWarehouseId ;
END IF;

IF p_fromWarehouseId = p_toWarehouseId THEN
        RAISE EXCEPTION 'لا يمكن النقل من وإلى نفس المستودع ';
    END IF;

 -- التأكد أن الطلب يحتوي على نوع كتب  واحد على الأقل
    IF p_items IS NULL
    OR jsonb_array_length(p_items) = 0 THEN

        RAISE EXCEPTION 'الطلب لازم يحوي كمية من كتاب معين ع الاقل ';
    END IF;


    -- التأكد أن كل كمية أكبر من صفر
    FOR v_item IN
        SELECT value
        FROM jsonb_array_elements(p_items)
    LOOP

        v_quantity := (v_item ->> 'quantity')::INT;

        IF v_quantity <= 0 THEN
            RAISE EXCEPTION
                'الكية لازم تكون اكبر من الصفر ';
        END IF;

    END LOOP;


    -- منع تكرار نفس الكتاب  داخل الطلب 
    IF EXISTS (
        SELECT 1
        FROM (
            SELECT
                (value ->> 'bookId')::INT AS book_id,
                COUNT(*) AS book_count
            FROM jsonb_array_elements(p_items)
            GROUP BY (value ->> 'bookId')::INT
            HAVING COUNT(*) > 1
        ) duplicated_books
    ) THEN

        RAISE EXCEPTION
            'الكتاب لا يجب ان يظهلا مرة واحدة ';
    END IF;

    -- قفل جميع كتب الطلب  دفعة واحدة
    PERFORM
    book_id
    FROM books
    WHERE book_id IN (
    SELECT (value ->> 'bookId')::INT
    FROM jsonb_array_elements(p_items)
)
FOR UPDATE;

IF (
    SELECT COUNT(*)
    FROM books
    WHERE book_id IN (
        SELECT (value ->> 'bookId')::INT
        FROM jsonb_array_elements(p_items)
    )
) <> jsonb_array_length(p_items) THEN

    RAISE EXCEPTION 'أحد الكتب الموجودة في الطلب غير موجود';

END IF;
FOR v_item IN
        SELECT value
        FROM jsonb_array_elements(p_items)
    LOOP
    v_book_id :=(v_item->>'bookId') ::INT ;
    v_quantity :=(v_item->>'quantity')::INT;

SELECT COALESCE(SUM(
    CASE
	   WHEN d.document_type = 'PRODUCTION' AND 
	   d.from_warehouse_id = p_fromWarehouseId
       THEN di.quantity
	
        WHEN d.document_type = 'INCOMING' AND 
		d.to_warehouse_id = p_fromWarehouseId
            THEN di.quantity

        WHEN d.document_type = 'OUTGOING' AND
		d.from_warehouse_id = p_fromWarehouseId
            THEN -di.quantity

        ELSE 0
    END
), 0)
INTO v_balance
FROM documents d
INNER JOIN document_items di
    ON di.document_id = d.document_id
WHERE di.book_id = v_book_id;

IF v_balance < v_quantity THEN
    RAISE EXCEPTION
        'الرصيد غير كافٍ للكتاب %، الرصيد الحالي: %، المطلوب: %',
        v_book_id,
        v_balance,
        v_quantity;
END IF;
END LOOP;

--انشااااااااء المذكرة بنوع صادر 

INSERT INTO documents (
    document_type,
    from_warehouse_id,
    to_warehouse_id
)
VALUES (
    'OUTGOING',
    p_fromWarehouseId,
    p_toWarehouseId
)
RETURNING document_id
INTO v_document_id;


-- انشاء سجلات للكتب في تفاصيل المذكرة 
FOR v_item IN
    SELECT value
    FROM jsonb_array_elements(p_items)
LOOP

    v_book_id := (v_item ->> 'bookId')::INT;
    v_quantity := (v_item ->> 'quantity')::INT;

    INSERT INTO document_items (
        document_id,
        book_id,
        quantity
    )
    VALUES (
        v_document_id,
        v_book_id,
        v_quantity
    );

END LOOP;

RETURN v_document_id;
End;
$$;

--========================================================================

--دالة لانتاج كتب ضمن مستودع المطبعة 
CREATE OR REPLACE FUNCTION create_production(
    p_warehouseId INT,
    p_items JSONB
)
RETURNS BIGINT
LANGUAGE plpgsql
AS $$
DECLARE
    v_document_id BIGINT;
    v_book_id INT;
    v_quantity INT;
    v_item JSONB;
BEGIN

    -- التأكد أن المستودع موجود
    PERFORM 1
    FROM warehouses
    WHERE warehouse_id = p_warehouseId;

    IF NOT FOUND THEN
        RAISE EXCEPTION
            'المستودع % غير موجود',
            p_warehouseId;
    END IF;


    -- التأكد أن هناك كتب
    IF p_items IS NULL
       OR jsonb_array_length(p_items) = 0 THEN

        RAISE EXCEPTION
            'يجب إدخال كتاب واحد على الأقل';

    END IF;


    -- التأكد أن الكمية أكبر من صفر
    FOR v_item IN
        SELECT value
        FROM jsonb_array_elements(p_items)
    LOOP

        v_quantity := (v_item ->> 'quantity')::INT;

        IF v_quantity <= 0 THEN
            RAISE EXCEPTION
                'الكمية يجب أن تكون أكبر من الصفر';
        END IF;

    END LOOP;


    -- التأكد أن الكتب موجودة
    IF (
        SELECT COUNT(*)
        FROM books
        WHERE book_id IN (
            SELECT (value ->> 'bookId')::INT
            FROM jsonb_array_elements(p_items)
        )
    ) <> jsonb_array_length(p_items) THEN

        RAISE EXCEPTION
            'أحد الكتب غير موجود';

    END IF;


    -- إنشاء مذكرة الإنتاج
    INSERT INTO documents (
        document_type,
        from_warehouse_id,
        to_warehouse_id
    )
    VALUES (
        'PRODUCTION',
        p_warehouseId,
        NULL
    )
    RETURNING document_id
    INTO v_document_id;


    -- إضافة الكتب المنتجة
    FOR v_item IN
        SELECT value
        FROM jsonb_array_elements(p_items)
    LOOP

        v_book_id := (v_item ->> 'bookId')::INT;
        v_quantity := (v_item ->> 'quantity')::INT;

        INSERT INTO document_items (
            document_id,
            book_id,
            quantity
        )
        VALUES (
            v_document_id,
            v_book_id,
            v_quantity
        );

    END LOOP;


    RETURN v_document_id;

END;
$$;


--======================================

CREATE OR REPLACE FUNCTION create_incoming_document(
    p_outgoingDocumentId BIGINT,
    p_toWarehouseId INT
)
RETURNS BIGINT
LANGUAGE plpgsql
AS $$
DECLARE
    v_incomingDocument_id BIGINT ;
    v_fromWarehouseId INT;
    v_toWarehouseId INT;
    v_document_type VARCHAR(10);

BEGIN

SELECT from_warehouse_id ,to_warehouse_id ,document_type INTO v_fromWarehouseId , v_toWarehouseId, v_document_type
FROM documents WHERE document_id =p_outgoingDocumentId ;
IF NOT FOUND THEN  
RAISE EXCEPTION 'لا يوجد مذكرة صادرة برقم % لاستلامها ', p_outgoingDocumentId ;
END IF;

IF v_document_type <> 'OUTGOING' THEN
RAISE EXCEPTION 'المذكرة %  ليست مذكرة صادرة ',p_outgoingDocumentId ;
END IF;

-- التأكد ان هذا المستودع هو المستودع المستلم كما حددننا في مذكرة الصادر 
IF v_toWarehouseId <> p_toWarehouseId THEN 
RAISE EXCEPTION 'هذا الصادر موجه للمستودع % وليس للمستودع % حاول مرة اخرى ',v_toWarehouseId , p_toWarehouseId ;
END IF;

--منع انشاء وارد انفس الصادر اكتر من مرة يعني منع الاستلام اكتر من مرة 
IF EXISTS (SELECT 1 FROM documents WHERE related_document_id = p_outgoingDocumentId
AND document_type ='INCOMING') THEN
RAISE EXCEPTION 'تم انشاء مذكرة وارد لهذا الصادر مسبقا ';
END IF;

--انشاء المذكرة 
INSERT INTO documents(document_type , from_warehouse_id , to_warehouse_id ,related_document_id) VALUES
('INCOMING' ,v_fromWarehouseId ,v_toWarehouseId ,p_outgoingDocumentId)
RETURNING document_id INTO v_incomingDocument_id;


INSERT INTO document_items(document_id,book_id ,quantity) SELECT v_incomingDocument_id ,book_id,quantity
FROM document_items WHERE document_id=p_outgoingDocumentId; 

RETURN v_incomingDocument_id ;
END;
$$

--=====================================================
--معرفة رصيد الكتب في مستودعي 
CREATE OR REPLACE FUNCTION get_warehouse_book_balance(
    p_WarehouseId INT
)
RETURNS TABLE(
    book_id INT,
    title VARCHAR(200),
    quantity BIGINT
)
LANGUAGE plpgsql 
AS $$
BEGIN
IF NOT EXISTS (SELECT 1 FROM warehouses WHERE warehouse_id=p_WarehouseId) THEN 
RAISE EXCEPTION 'المستودع % غير موجود ',p_WarehouseId;
END IF;

RETURN QUERY SELECT b.book_id ,b.title ,COALESCE(
SUM(
    CASE
        WHEN d.document_type='PRODUCTION' AND d.from_warehouse_id =p_WarehouseId  THEN di.quantity
        WHEN d.document_type='INCOMING'   AND d.to_warehouse_id =p_WarehouseId THEN di.quantity
        WHEN d.document_type='OUTGOING' AND d.from_warehouse_id =p_WarehouseId  THEN -di.quantity
        ELSE 0
    END
)
    ,0) As quantity FROM books b LEFT JOIN document_items di
ON di.book_id=b.book_id
LEFT JOIN documents d ON d.document_id =di.document_id 
GROUP BY b.book_id ,b.title ORDER BY b.book_id;

END;
$$
--=====================================================================
-- اظهالا حركة الكتب مع كميتها ونوع المذكرة ...
CREATE OR REPLACE FUNCTION get_movements_warehouses()
RETURNS TABLE(
    document_id BIGINT,
    document_type VARCHAR(10),
    book_id INT,
    title VARCHAR(200),
    quantity INT,
    from_warehouse_id INT,
    from_warehouse_name VARCHAR(100),
    to_warehouse_id INT,
    to_warehouse_name VARCHAR(100),
    related_document_id BIGINT,
    created_at TIMESTAMP
)
LANGUAGE plpgsql
AS $$
BEGIN

    RETURN QUERY
    SELECT
        d.document_id,
        d.document_type,
        b.book_id,
        b.title,
        di.quantity,
        d.from_warehouse_id,
        fw.name,
        d.to_warehouse_id,
        tw.name,
        d.related_document_id,
        d.created_at

    FROM documents d

    INNER JOIN document_items di
        ON di.document_id = d.document_id

    INNER JOIN books b
        ON b.book_id = di.book_id

    INNER JOIN warehouses fw
        ON fw.warehouse_id = d.from_warehouse_id

    LEFT JOIN warehouses tw
        ON tw.warehouse_id = d.to_warehouse_id

    ORDER BY
        d.created_at DESC,
        d.document_id DESC,
        b.book_id;

END;
$$;

--=================================================
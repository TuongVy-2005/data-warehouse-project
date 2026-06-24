/* điều chỉnh kiểu dữ liệu */
ALTER TABLE dim_customers 
ALTER COLUMN customerID NVARCHAR(10) NOT NULL;
ALTER TABLE dim_products
ALTER COLUMN productID NVARCHAR(10) NOT NULL;
ALTER TABLE dim_logistics
ALTER COLUMN logisticID NVARCHAR(10) NOT NULL;
ALTER TABLE dim_orders
ALTER COLUMN orderID NVARCHAR(10) NOT NULL;
ALTER TABLE dim_orders
ALTER COLUMN customerID NVARCHAR(10) NOT NULL;
ALTER TABLE fact_returns
ALTER COLUMN return_ID NVARCHAR(10) NOT NULL;
ALTER TABLE fact_returns
ALTER COLUMN orderID NVARCHAR(10) NOT NULL;
ALTER TABLE fact_returns
ALTER COLUMN productID NVARCHAR(10) NOT NULL;
ALTER TABLE fact_returns
ALTER COLUMN logisticID NVARCHAR(10) NOT NULL;
ALTER TABLE fact_returns
ALTER COLUMN customerID NVARCHAR(10) NOT NULL;

/* tạo khóa chính cho các bảng */
ALTER TABLE dim_customers 
ADD CONSTRAINT PK_dim_customers PRIMARY KEY (customerID);
ALTER TABLE dim_products 
ADD CONSTRAINT PK_dim_products PRIMARY KEY (productID);
ALTER TABLE dim_logistics
ADD CONSTRAINT PK_dim_logistics PRIMARY KEY (logisticID);
ALTER TABLE dim_orders
ADD CONSTRAINT PK_dim_orders PRIMARY KEY (orderID);
ALTER TABLE fact_returns 
ADD CONSTRAINT PK_fact_returns PRIMARY KEY (return_ID);

/* tạo khóa ngoại cho orders */
ALTER TABLE dim_orders
ADD CONSTRAINT FK_orders_customers
FOREIGN KEY (customerID)
REFERENCES dim_customers (customerID);

/* tạo khóa ngoại cho fact */
ALTER TABLE fact_returns
ADD CONSTRAINT FK_fact_customers
FOREIGN KEY (customerID)
REFERENCES dim_customers (customerID);

ALTER TABLE fact_returns
ADD CONSTRAINT FK_fact_products
FOREIGN KEY (productID)
REFERENCES dim_products (productID);

ALTER TABLE fact_returns
ADD CONSTRAINT FK_fact_orders
FOREIGN KEY (orderID)
REFERENCES dim_orders (orderID);

ALTER TABLE fact_returns
ADD CONSTRAINT FK_fact_logistics
FOREIGN KEY (logisticID)
REFERENCES dim_logistics (logisticID);

SELECT 
    COLUMN_NAME, 
    CONSTRAINT_NAME, 
    TABLE_NAME 
FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE 
WHERE TABLE_NAME IN ('dim_customers', 'dim_products', 'dim_logistics', 'dim_orders', 'fact_returns');

/* Số ngày hoàn trả kể từ khi nhận hàng */
SELECT 
    f.return_id,
    o.orderid,
    o.[shipping date],
    f.returndate,
    DATEDIFF(DAY, o.[shipping date], f.returndate) AS days_to_return
FROM fact_returns f
JOIN dim_orders o ON f.orderid = o.orderid
ORDER BY days_to_return;

/*Tỷ lệ hoàn trả theo khu vực địa lý*/
SELECT  
    c.location,
    COUNT(o.orderid) AS total_returns,
    (COUNT(o.orderid) * 100.0) / (SELECT COUNT(*) FROM dim_orders) AS return_rate
FROM dim_orders o
JOIN dim_customers c ON o.customerid = c.customerid
GROUP BY c.location
ORDER BY return_rate DESC;

/* Phân tích nhân khẩu học khách hàng có xu hướng hoàn trả cao*/
SELECT 
    c.gender,
    CASE 
        WHEN c.age BETWEEN 18 AND 25 THEN '18-25'
        WHEN c.age BETWEEN 26 AND 35 THEN '26-35'
        WHEN c.age BETWEEN 36 AND 50 THEN '36-50'
        ELSE '51+'
    END AS age_group,
    COUNT(r.return_id) AS total_returns,
    COUNT(r.return_id) * 100.0 / (SELECT COUNT(*) FROM dim_orders) AS return_rate
FROM fact_returns r
JOIN dim_customers c ON r.customerid = c.customerid
GROUP BY c.gender,
         CASE 
             WHEN c.age BETWEEN 18 AND 25 THEN '18-25'
             WHEN c.age BETWEEN 26 AND 35 THEN '26-35'
             WHEN c.age BETWEEN 36 AND 50 THEN '36-50'
             ELSE '51+'
         END
ORDER BY return_rate DESC;

/*Nguyên nhân trả hàng phổ biến nhất*/
SELECT 
    f.returnreason, 
    COUNT(f.return_id) AS return_count
FROM 
    fact_returns f
GROUP BY 
    f.returnreason
ORDER BY 
    return_count DESC;

/*Số lần hoàn trả theo lý do và danh mục sản phẩm*/
SELECT
    p.category,
    f.returnreason,
    COUNT(f.return_id) AS total_returns
FROM fact_returns f
JOIN dim_products p ON f.productid = p.productid
GROUP BY p.category, f.returnreason;

/*Số lượng hoàn trả theo vấn đề giao hàng do đơn vị vận chuyển*/
SELECT 
    CASE 
        WHEN l.isshippingorlate = 1 THEN 'Do don vi van chuyen'
        WHEN l.isshippingorlate = 0 THEN 'Khong phai do don vi van chuyen'
        ELSE 'Khong xac dinh'
    END AS return_reason, 
    l.isshippingorlate AS shipping_issue,
    COUNT(f.return_id) AS total_returns
FROM 
    fact_returns f
JOIN 
    dim_logistics l ON f.logisticid = l.logisticid
GROUP BY 
    l.isshippingorlate
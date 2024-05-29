WITH SALES AS (
  SELECT
"public"."sales_entry"."id",
DATE_PART('year' , "public"."sales_entry"."transaction_date") AS "YEAR",
DATE_PART('month' , "public"."sales_entry"."transaction_date") AS "MONTH",
TO_CHAR("public"."sales_entry"."transaction_date", 'Month') AS "MONTH_NAME",
"public"."sales_entry"."transaction_date",
"public"."sales_entry"."transaction_type",
"public"."sales_entry"."sales_type",
--"public"."sales_entry"."sales_date",
"public"."sales_entry"."sales_category",
--"public"."sales_entry"."report_date",
"public"."sales_entry"."sales_volume",
"public"."sales_entry"."unit_id",
"public"."sales_entry"."lease_id",
"public"."sales_entry"."tenant_id",
"public"."sales_entry"."company_relation_id" 

FROM "public"."sales_entry"
INNER JOIN "public"."units" 
    ON "public"."units"."id"="public"."sales_entry"."unit_id"
    AND "public"."units"."company_relation_id"="public"."sales_entry"."company_relation_id"
INNER JOIN "public"."tenants" ON "public"."tenants"."id"="public"."sales_entry"."tenant_id"
INNER JOIN "public"."properties" 
    ON "public"."properties"."id"="public"."units"."property_id"
    AND "public"."properties"."company_relation_id"="public"."units"."company_relation_id"
	
WHERE "public"."sales_entry"."company_relation_id"  = @REAL_COMPANY_ID
  AND "public"."sales_entry"."transaction_date" >= CURRENT_DATE - INTERVAL '5 years'
  AND "public"."sales_entry"."transaction_date" <= CURRENT_DATE
)  

SELECT 
SALES."YEAR",
SALES."MONTH",
SALES."MONTH_NAME",
SALES."transaction_type",
SALES."sales_type",
SALES."sales_category",
SALES."unit_id",
SALES."lease_id",
SALES."tenant_id",
SALES."company_relation_id",
SUM(SALES."sales_volume") "MONTHLY_AMOUNT"

FROM SALES

GROUP BY 1,2,3,4,5,6,7,8,9,10

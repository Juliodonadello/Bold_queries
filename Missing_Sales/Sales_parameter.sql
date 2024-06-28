WITH SALES AS (
  SELECT
"public"."sales_entry"."id",
DATE_PART('year' , "public"."sales_entry"."transaction_date") AS "YEAR",
DATE_PART('month' , "public"."sales_entry"."transaction_date") AS "MONTH",
TRIM(TO_CHAR("public"."sales_entry"."transaction_date", 'Month')) AS "MONTH_NAME",
"public"."sales_entry"."transaction_date",
"public"."sales_entry"."transaction_type",
 CASE WHEN "public"."sales_entry"."transaction_type" LIKE '%Month%' THEN 'Monthly'
  			WHEN "public"."sales_entry"."transaction_type" LIKE '%Year%' THEN 'Annual'
			ELSE '-'
			END AS "transaction_type_group",
"public"."sales_entry"."sales_type",
--"public"."sales_entry"."sales_date",
"public"."sales_entry"."sales_category",
--"public"."sales_entry"."report_date",
"public"."sales_entry"."sales_volume",
"public"."sales_entry"."unit_id",
"public"."units"."name" "UNIT_NAME",
"public"."sales_entry"."lease_id",
"public"."leases"."name" "LEASE_NAME",
"public"."sales_entry"."tenant_id",
"public"."tenants"."name" "TENANT_NAME",
"public"."properties"."name" "PROP_NAME",
"public"."properties"."id" "PROP_ID",
"public"."sales_entry"."company_relation_id",
"public"."leases"."start" "LEASE_START",
"public"."leases"."end" "LEASE_END"

FROM "public"."sales_entry"
INNER JOIN "public"."units" 
    ON "public"."units"."id"="public"."sales_entry"."unit_id"
    AND "public"."units"."company_relation_id"="public"."sales_entry"."company_relation_id"
INNER JOIN "public"."tenants" ON "public"."tenants"."id"="public"."sales_entry"."tenant_id"
INNER JOIN "public"."properties" 
    ON "public"."properties"."id"="public"."units"."property_id"
    AND "public"."properties"."company_relation_id"="public"."units"."company_relation_id"
INNER JOIN "public"."leases" ON "public"."leases"."id"="public"."sales_entry"."lease_id"
	
WHERE CAST("public"."properties"."company_relation_id" AS INT) = CAST(@REAL_COMPANY_ID AS INT)
  AND "public"."sales_entry"."transaction_date" >= CURRENT_DATE - INTERVAL '4 years'
  AND "public"."sales_entry"."transaction_date" <= CURRENT_DATE
  AND "public"."leases"."name" IN (@Lease_Name)
  AND "public"."properties"."name" IN (@Property_Name)
)
select SALES."sales_type",
SALES."sales_category"

from SALES
group by 1,2
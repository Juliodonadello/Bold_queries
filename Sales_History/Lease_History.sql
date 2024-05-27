SELECT "public"."sales_entry"."id",
DATE_PART('year' , "public"."sales_entry"."transaction_date") AS "created_at_YEAR",
DATE_PART('month' , "public"."sales_entry"."transaction_date") AS "created_at_MONTH",
TO_CHAR("public"."sales_entry"."transaction_date", 'Month') AS "created_aaat_MONTH",
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
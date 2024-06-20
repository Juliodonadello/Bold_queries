
SELECT  "public"."properties"."name" AS "PROP_NAME" 
, COUNT("public"."sales_entry"."lease_id") AS "Q_leases_sales_entries"

FROM  "public"."properties"
LEFT JOIN  "public"."leases"
	ON "public"."properties"."id" = "public"."leases"."property_id"
LEFT JOIN  "public"."sales_entry"
	ON "public"."leases"."id" = "public"."sales_entry"."lease_id"

WHERE CAST("public"."properties"."company_relation_id" AS INT)  = CAST(@REAL_COMPANY_ID AS INT)
 	and "public"."properties"."deleted_at" IS NULL
	AND "public"."sales_entry"."transaction_date" >= CURRENT_DATE - INTERVAL '4 years'
  	AND "public"."sales_entry"."transaction_date" <= CURRENT_DATE

GROUP BY  "public"."properties"."name"

HAVING COUNT("public"."sales_entry"."lease_id") >0

ORDER BY "public"."properties"."name" asc
 
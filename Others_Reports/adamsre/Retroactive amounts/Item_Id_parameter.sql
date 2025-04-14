SELECT DISTINCT "lease_recurring_charges"."order_entry_item_id" AS "ITEM_ID"

FROM "public"."lease_recurring_charges"
INNER JOIN "public"."units" ON "lease_recurring_charges"."unit_id" =  "units"."id"
INNER  JOIN "public"."properties" ON "public"."units"."property_id"="public"."properties"."id"

WHERE  "public"."properties"."name" IN (@Property_Name)
	AND CAST("public"."properties"."company_relation_id" AS INT) = CAST(@REAL_COMPANY_ID AS INT)
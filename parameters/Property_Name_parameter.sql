
SELECT  "public"."properties"."name" AS "PROP_NAME" 

FROM  "public"."properties"

WHERE CAST("public"."properties"."company_relation_id" AS INT)  = CAST(@REAL_COMPANY_ID AS INT)
 and "public"."properties"."deleted_at" IS NULL
 AND "public"."properties"."entity_id" IN (@Entity_Id)

GROUP BY  "public"."properties"."name"

ORDER BY "public"."properties"."name" asc
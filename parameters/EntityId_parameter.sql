SELECT  "public"."properties"."entity_id" AS "ENTITY_ID" 

FROM  "public"."properties"

WHERE CAST("public"."properties"."company_relation_id" AS INT)  = CAST(@REAL_COMPANY_ID AS INT)
 and "public"."properties"."deleted_at" IS NULL

GROUP BY  "public"."properties"."entity_id"

ORDER BY "public"."properties"."entity_id" asc
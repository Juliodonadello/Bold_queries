SELECT  distinct "public"."properties"."department" AS "DEPARTMENT"

FROM  "public"."properties"

WHERE CAST("public"."properties"."company_relation_id" AS INT) = CAST(@REAL_COMPANY_ID AS INT)

GROUP BY  1

ORDER BY "public"."properties"."department" asc
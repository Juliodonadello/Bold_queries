SELECT  "public"."properties"."department" AS "DEPARTMENT"

FROM  "public"."properties"

WHERE "public"."properties"."company_relation_id" = @REAL_COMPANY_ID

GROUP BY  1

ORDER BY "public"."properties"."department" asc
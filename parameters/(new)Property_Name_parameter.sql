SELECT  "public"."properties"."name" AS "PROP_NAME"

FROM  "public"."properties"

WHERE "public"."company_accounts"."company_id" = @REAL_COMPANY_ID

GROUP BY  "public"."properties"."name"

ORDER BY "public"."properties"."name" asc




SELECT  "public"."properties"."property_type" AS "PROP_TYPE"

FROM  "public"."properties"

WHERE "public"."properties"."company_relation_id" = @REAL_COMPANY_ID
	AND "public"."properties"."department" = @Department

GROUP BY  1

ORDER BY "public"."properties"."property_type" asc
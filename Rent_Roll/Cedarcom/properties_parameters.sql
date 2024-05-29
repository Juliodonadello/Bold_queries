SELECT  "public"."properties"."name" AS "PROP_NAME"

FROM  "public"."properties"

WHERE "public"."properties"."company_relation_id" = @REAL_COMPANY_ID
AND "public"."properties"."department" = @Department
AND "public"."properties"."property_type" = @Property_Type

GROUP BY  1

ORDER BY "public"."properties"."name" asc
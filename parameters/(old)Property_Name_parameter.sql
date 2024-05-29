SELECT  "public"."properties"."name" AS "PROP_NAME" 
--,count("public"."properties"."id") AS "Q"
,"public"."company_accounts"."company_id" "COMPANY_NAME"

FROM  "public"."properties"
--INNER JOIN  "public"."units"
	--ON "public"."units"."property_id" = "public"."properties"."id"
INNER JOIN "public"."company_accounts"
		ON "public"."properties"."company_relation_id" = "public"."company_accounts"."id"

WHERE "public"."company_accounts"."company_id" = @COMPANY_ID

GROUP BY  "public"."properties"."name","public"."company_accounts"."company_id"

--having count("public"."properties"."id") >0 -- filtering properties without units

ORDER BY "public"."properties"."name" asc




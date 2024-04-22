WITH UNITS AS 
(
  SELECT 
		"public"."properties"."id" AS "PROP_ID",
		"public"."properties"."name" AS "PROP_NAME",
		"public"."units"."id" AS "UNIT_ID",
  		"public"."units"."name" AS "UNIT_NAME",
  		"public"."unit_square_footage_items"."square_footage_type" AS "SQ_FT_TYPE",
  		"public"."units"."unit_class" AS "UNIT_CLASS",
  		"public"."company_accounts"."company_id" AS "COMPANY_ID"
  		
	FROM   "public"."units"
	INNER JOIN "public"."properties"
		ON "public"."units"."property_id" = "public"."properties"."id"
  	INNER JOIN "public"."unit_square_footage_items"
		ON "public"."unit_square_footage_items"."unit_id" = "public"."units"."id"
  	INNER JOIN "public"."company_accounts"
		ON "public"."properties"."company_relation_id" = "public"."company_accounts"."id"
	
  	WHERE "public"."units"."deleted_at" IS NULL
  	AND "public"."properties"."deleted_at" IS NULL
	AND "public"."properties"."name" IN (@Property_Name)
	AND "public"."company_accounts"."company_id" IN (@COMPANY_ID)
  
	GROUP BY 
		"public"."properties"."id",
		"public"."properties"."name",
		"public"."units"."id",
  		"public"."units"."name",
  		"public"."unit_square_footage_items"."square_footage_type",
  		"public"."company_accounts"."company_id"
)

select 
	UNITS."SQ_FT_TYPE",
	UNITS."UNIT_CLASS"
	
	from UNITS

	GROUP BY UNITS."SQ_FT_TYPE",
		UNITS."UNIT_CLASS"

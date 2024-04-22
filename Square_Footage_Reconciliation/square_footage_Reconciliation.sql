WITH SQ_FT_TEMP AS (
	SELECT
		"public"."properties"."id" AS "PROP_ID",
		SUM("public"."units"."total_square_footage") AS "TOT_SQ_FT",
  		"public"."unit_square_footage_items"."square_footage_type" AS "SQ_FT_TYPE",
  		"public"."company_accounts"."company_id" AS "COMPANY_ID"
	 
	FROM   "public"."units"
	INNER JOIN "public"."properties"
		ON "public"."units"."property_id" = "public"."properties"."id"
	INNER JOIN "public"."company_accounts"
		ON "public"."properties"."company_relation_id" = "public"."company_accounts"."id"
  	INNER JOIN "public"."unit_square_footage_items"
		ON "public"."unit_square_footage_items"."unit_id" = "public"."units"."id"

  	WHERE "public"."units"."deleted_at" IS NULL
  		AND "public"."properties"."deleted_at" IS NULL
  		AND ("public"."units"."deleted_at" >= @AsOfDate OR "public"."units"."deleted_at" IS NULL)
		AND "public"."properties"."name" IN (@Property_Name)
		AND "public"."company_accounts"."company_id" IN (@COMPANY_ID)
		
	GROUP BY  "public"."properties"."id", "public"."company_accounts"."company_id",
  		"public"."unit_square_footage_items"."square_footage_type",
  		"public"."company_accounts"."company_id"
),
UNITS AS (
  SELECT 
		"public"."properties"."id" AS "PROP_ID",
		"public"."properties"."name" AS "PROP_NAME",
		"public"."units"."id" AS "UNIT_ID",
  		"public"."units"."name" AS "UNIT_NAME",
		MAX("public"."units"."total_square_footage") AS "UNIT_SQ_FT",
		"public"."unit_square_footage_items"."square_footage_type" AS "SQ_FT_TYPE",
		"public"."units"."unit_class" AS "UNIT_CLASS",
  		"public"."company_accounts"."company_id" AS "COMPANY_ID"
  		
	FROM   "public"."units"
	INNER JOIN "public"."properties"
		ON "public"."units"."property_id" = "public"."properties"."id"
  	INNER JOIN "public"."company_accounts"
		ON "public"."properties"."company_relation_id" = "public"."company_accounts"."id"
  	INNER JOIN "public"."unit_square_footage_items"
		ON "public"."unit_square_footage_items"."unit_id" = "public"."units"."id"
	
  	WHERE "public"."units"."deleted_at" IS NULL
  	AND "public"."properties"."deleted_at" IS NULL
  	AND ("public"."units"."deleted_at" >= @AsOfDate OR "public"."units"."deleted_at" IS NULL)
	AND "public"."properties"."name" IN (@Property_Name)
	AND "public"."company_accounts"."company_id" IN (@COMPANY_ID)
	
	GROUP BY 
		"public"."properties"."id",
		"public"."properties"."name",
		"public"."units"."id",
  		"public"."units"."name",
		"public"."unit_square_footage_items"."square_footage_type",
		"public"."units"."unit_class",
  		"public"."company_accounts"."company_id"
)

SELECT 		UNITS."PROP_ID",
		UNITS."PROP_NAME",
		UNITS."UNIT_ID",
  		UNITS."UNIT_NAME",
		UNITS."UNIT_SQ_FT",
		UNITS."SQ_FT_TYPE",
		UNITS."UNIT_CLASS",
  		UNITS."COMPANY_ID",
		SQ_FT_TEMP."TOT_SQ_FT" -- ESTE CAMPO DEBERIA SACARSE DE SAGE, PARA COMPARARLO CON LA SUMA DE SQ FT POR UNIT. PREGUNTAR A DEVBASE

FROM UNITS
	INNER JOIN SQ_FT_TEMP
		ON SQ_FT_TEMP."COMPANY_ID" = UNITS."COMPANY_ID" 
			AND SQ_FT_TEMP."PROP_ID" = UNITS."PROP_ID" 

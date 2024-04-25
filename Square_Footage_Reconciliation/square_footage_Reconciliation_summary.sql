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
		AND "public"."unit_square_footage_items"."square_footage_type" IN (@Sqft_Type)
		
	GROUP BY  "public"."properties"."id", "public"."company_accounts"."company_id",
  		"public"."company_accounts"."company_id",
		"public"."unit_square_footage_items"."square_footage_type"
),
aux AS (
  	SELECT
    "public"."properties"."id" "PROP_ID",
    "public"."properties"."name" "PROP_NAME",
    "public"."properties"."square_footage_items" AS "square_footage_items",
	"public"."company_accounts"."company_id" as "COMPANY_ID"
  	FROM "public"."properties"
	INNER JOIN "public"."company_accounts"
		ON "public"."properties"."company_relation_id" = "public"."company_accounts"."id"
  WHERE "public"."company_accounts"."company_id" IN (@COMPANY_ID)
	AND "public"."properties"."name" IN (@Property_Name)
),
json1 AS (
  SELECT
  aux."PROP_ID",
  aux."PROP_NAME",
  json_array_elements_text(CAST(aux."square_footage_items" AS JSON)) AS "square_footage_items",
  aux."COMPANY_ID"
  FROM aux
),
PROP_SQ_FT AS (
  	SELECT
	json1."PROP_ID",
	json1."PROP_NAME",
  	--json1."square_footage_items",
	CAST(("square_footage_items"::JSONB->>'asOfDate') AS DATE) AS "AsOfDate",
	(("square_footage_items"::JSONB->>'value')::numeric) AS "Value",
	("square_footage_items"::JSONB->>'squareFootageType') AS "SquareFootageType",
	json1."COMPANY_ID"
	
	FROM json1

	WHERE ("square_footage_items"::JSONB->>'squareFootageType') IN (@Sqft_Type)
	and CAST(("square_footage_items"::JSONB->>'asOfDate') AS DATE) <= @AsOfDate
)
,
UNITS AS (
  SELECT 
		"public"."properties"."id" AS "PROP_ID",
		"public"."properties"."name" AS "PROP_NAME",
		"public"."units"."id" AS "UNIT_ID",
  		"public"."units"."name" AS "UNIT_NAME",
		MAX("public"."units"."total_square_footage") AS "UNIT_SQ_FT",
		"public"."unit_square_footage_items"."square_footage_type" AS "SQ_FT_TYPE",
		"public"."units"."unit_class" AS "UNIT_CLASS",
  		"public"."company_accounts"."company_id" AS "COMPANY_ID",
  		MAX(PROP_SQ_FT."Value") as "PROP_SQ_FT_Value"
  		
	FROM   "public"."units"
	INNER JOIN "public"."properties"
		ON "public"."units"."property_id" = "public"."properties"."id"
  	INNER JOIN "public"."company_accounts"
		ON "public"."properties"."company_relation_id" = "public"."company_accounts"."id"
  	INNER JOIN "public"."unit_square_footage_items"
		ON "public"."unit_square_footage_items"."unit_id" = "public"."units"."id"
  	INNER JOIN PROP_SQ_FT 
		ON PROP_SQ_FT."COMPANY_ID" = "public"."company_accounts"."company_id" 
			AND PROP_SQ_FT."PROP_ID" = "public"."properties"."id"
  			AND PROP_SQ_FT."SquareFootageType" = "public"."unit_square_footage_items"."square_footage_type"
	
  	WHERE "public"."units"."deleted_at" IS NULL
  	AND "public"."properties"."deleted_at" IS NULL
  	AND ("public"."units"."deleted_at" >= @AsOfDate OR "public"."units"."deleted_at" IS NULL)
	AND "public"."properties"."name" IN (@Property_Name)
	AND "public"."company_accounts"."company_id" IN (@COMPANY_ID)
	AND "public"."unit_square_footage_items"."square_footage_type" IN (@Sqft_Type)
	
	GROUP BY 
		"public"."properties"."id",
		"public"."properties"."name",
		"public"."units"."id",
  		"public"."units"."name",
		"public"."unit_square_footage_items"."square_footage_type",
		"public"."units"."unit_class",
  		"public"."company_accounts"."company_id"
)

SELECT 	UNITS."PROP_ID",
		UNITS."PROP_NAME",
		UNITS."SQ_FT_TYPE",
		UNITS."COMPANY_ID",
		SUM(UNITS."UNIT_SQ_FT") "check_TOT_SQ_FT",  		
		MAX(SQ_FT_TEMP."TOT_SQ_FT") "TOT_SQ_FT",
		MAX(UNITS."PROP_SQ_FT_Value") "PROP_SQ_FT"

FROM UNITS
	INNER JOIN SQ_FT_TEMP
		ON SQ_FT_TEMP."COMPANY_ID" = UNITS."COMPANY_ID" 
			AND SQ_FT_TEMP."PROP_ID" = UNITS."PROP_ID" 
/*	INNER JOIN PROP_SQ_FT 
		ON PROP_SQ_FT."COMPANY_ID" = UNITS."COMPANY_ID" 
			AND PROP_SQ_FT."PROP_ID" = UNITS."PROP_ID"
*/
WHERE UNITS."SQ_FT_TYPE" IN (@Sqft_Type)
	
GROUP BY 1,2,3,4
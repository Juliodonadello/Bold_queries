WITH SQ_FT_TEMP AS (
	SELECT
		"public"."properties"."id" AS "PROP_ID",
		SUM("public"."units"."total_square_footage") AS "TOT_SQ_FT",
  		"public"."unit_square_footage_items"."square_footage_type" AS "SQ_FT_TYPE",
  		"public"."property_square_footage_items"."value" AS "PROP_SQ_FT",
  		"public"."property_square_footage_items"."square_footage_type" AS "PROP_SQ_FT_TYPE",
		"public"."properties"."company_relation_id" as "COMPANY_ID"
	 
	FROM   "public"."units"
	INNER JOIN "public"."properties"
		ON "public"."units"."property_id" = "public"."properties"."id"
  	INNER JOIN "public"."property_square_footage_items"
  		ON "public"."property_square_footage_items"."property_id" = "public"."properties"."id"
  	INNER JOIN "public"."unit_square_footage_items"
		ON "public"."unit_square_footage_items"."unit_id" = "public"."units"."id"

  	WHERE "public"."units"."deleted_at" IS NULL
  		AND "public"."properties"."deleted_at" IS NULL
  		AND ("public"."units"."deleted_at" >= @AsOfDate OR "public"."units"."deleted_at" IS NULL)
		AND "public"."properties"."name" IN (@Property_Name)
		AND CAST("public"."properties"."company_relation_id" AS INT)  = CAST(@REAL_COMPANY_ID AS INT)
		AND "public"."unit_square_footage_items"."square_footage_type" IN (@Sqft_Type)
  		AND "public"."property_square_footage_items"."square_footage_type" IN (@Sqft_Type)
  		AND "public"."property_square_footage_items"."as_of_date" <= @AsOfDate
		
	GROUP BY  1,3,4,5,6
  		
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
		"public"."properties"."company_relation_id" as "COMPANY_ID"
  		
	FROM   "public"."units"
	INNER JOIN "public"."properties"
		ON "public"."units"."property_id" = "public"."properties"."id"
  	INNER JOIN "public"."unit_square_footage_items"
		ON "public"."unit_square_footage_items"."unit_id" = "public"."units"."id"
	
  	WHERE "public"."units"."deleted_at" IS NULL
  	AND "public"."properties"."deleted_at" IS NULL
  	AND ("public"."units"."deleted_at" >= @AsOfDate OR "public"."units"."deleted_at" IS NULL)
	AND "public"."properties"."name" IN (@Property_Name)
	AND CAST("public"."properties"."company_relation_id" AS INT)  = CAST(@REAL_COMPANY_ID AS INT)
	AND "public"."unit_square_footage_items"."square_footage_type" IN (@Sqft_Type)
  	AND "public"."unit_square_footage_items"."as_of_date" <= @AsOfDate
	
	GROUP BY 
		"public"."properties"."id",
		"public"."properties"."name",
		"public"."units"."id",
  		"public"."units"."name",
		"public"."unit_square_footage_items"."square_footage_type",
		"public"."units"."unit_class",
  		"public"."properties"."company_relation_id"
)

SELECT 	UNITS."PROP_ID",
		UNITS."PROP_NAME",
		UNITS."SQ_FT_TYPE",
		UNITS."COMPANY_ID",
		COUNT(DISTINCT UNITS."UNIT_ID")  "COUNT_UNITS",
		SUM(UNITS."UNIT_SQ_FT") "sum_units_TOT_SQ_FT",  		
		SQ_FT_TEMP."TOT_SQ_FT" "TOT_SQ_FT",
		SQ_FT_TEMP."PROP_SQ_FT" "PROP_SQ_FT",
		CASE   WHEN (SQ_FT_TEMP."TOT_SQ_FT" > SQ_FT_TEMP."PROP_SQ_FT") THEN 1 
							WHEN (SQ_FT_TEMP."TOT_SQ_FT" < SQ_FT_TEMP."PROP_SQ_FT") THEN 1 
							ELSE 0 
				END AS "COUNT_PROP_DIFF_SQ_FT"

FROM UNITS
INNER JOIN SQ_FT_TEMP
	ON SQ_FT_TEMP."COMPANY_ID" = UNITS."COMPANY_ID" 
		AND SQ_FT_TEMP."PROP_ID" = UNITS."PROP_ID"
		AND SQ_FT_TEMP."SQ_FT_TYPE" = UNITS."SQ_FT_TYPE"
		AND SQ_FT_TEMP."PROP_SQ_FT_TYPE" = UNITS."SQ_FT_TYPE"
			
WHERE UNITS."SQ_FT_TYPE" IN (@Sqft_Type)
	
GROUP BY 1,2,3,4,7,8,9
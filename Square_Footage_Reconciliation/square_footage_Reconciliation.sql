WITH SQ_FT_TEMP AS (
	SELECT
		"public"."properties"."id" AS "PROP_ID",
		--SUM("public"."units"."total_square_footage") AS "TOT_SQ_FT",}
		SUM("public"."unit_square_footage_items"."value") AS "TOT_SQ_FT",
  		"public"."unit_square_footage_items"."square_footage_type" AS "SQ_FT_TYPE",
  		"public"."property_square_footage_items"."value" AS "PROP_SQ_FT",
  		"public"."property_square_footage_items"."square_footage_type" AS "PROP_SQ_FT_TYPE",
		"public"."properties"."company_relation_id" as "COMPANY_ID"
	 
	FROM   "public"."units"
	INNER JOIN "public"."properties"
		ON "public"."units"."property_id" = "public"."properties"."id"
  	INNER JOIN "public"."property_square_footage_items"
  		ON "public"."property_square_footage_items"."property_id" = "public"."properties"."id"
  	LEFT JOIN "public"."unit_square_footage_items"
		ON "public"."unit_square_footage_items"."unit_id" = "public"."units"."id"
  		AND "public"."unit_square_footage_items"."as_of_date" <= @AsOfDate
  		AND "public"."unit_square_footage_items"."square_footage_type" IN (@Sqft_Type)
  	

  	WHERE "public"."properties"."deleted_at" IS NULL
  		AND ("public"."units"."deleted_at" >= @AsOfDate OR "public"."units"."deleted_at" IS NULL)
		AND "public"."properties"."name" IN (@Property_Name)
		AND CAST("public"."properties"."company_relation_id" AS INT)  = CAST(@REAL_COMPANY_ID AS INT)
  		AND "public"."property_square_footage_items"."as_of_date" <= @AsOfDate
		AND "public"."property_square_footage_items"."square_footage_type" IN (@Sqft_Type)
		
	GROUP BY  1,3,4,5,6
  		
),
UNITS AS (
  SELECT 
		"public"."properties"."id" AS "PROP_ID",
		"public"."properties"."name" AS "PROP_NAME",
		"public"."units"."id" AS "UNIT_ID",
  		"public"."units"."name" AS "UNIT_NAME",
		--MAX("public"."units"."total_square_footage") AS "UNIT_SQ_FT",
		MAX("public"."unit_square_footage_items"."value") AS "UNIT_SQ_FT",
		"public"."unit_square_footage_items"."square_footage_type" AS "SQ_FT_TYPE",
		"public"."units"."unit_class" AS "UNIT_CLASS",
		"public"."properties"."company_relation_id" as "COMPANY_ID"
  		
	FROM   "public"."units"
	INNER JOIN "public"."properties"
		ON "public"."units"."property_id" = "public"."properties"."id"
  	LEFT JOIN "public"."unit_square_footage_items"
		ON "public"."unit_square_footage_items"."unit_id" = "public"."units"."id"
  		AND "public"."unit_square_footage_items"."as_of_date" <= @AsOfDate
  		AND "public"."unit_square_footage_items"."square_footage_type" IN (@Sqft_Type)
	
  	WHERE "public"."properties"."deleted_at" IS NULL
  	AND ("public"."units"."deleted_at" >= @AsOfDate OR "public"."units"."deleted_at" IS NULL)
	AND "public"."properties"."name" IN (@Property_Name)
	AND CAST("public"."properties"."company_relation_id" AS INT)  = CAST(@REAL_COMPANY_ID AS INT)

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
		UNITS."UNIT_ID",
  		UNITS."UNIT_NAME",
		UNITS."UNIT_SQ_FT",
		UNITS."SQ_FT_TYPE",
		UNITS."UNIT_CLASS",
  		UNITS."COMPANY_ID",
		SQ_FT_TEMP."TOT_SQ_FT" ,
		SQ_FT_TEMP."PROP_SQ_FT"

FROM UNITS
INNER JOIN SQ_FT_TEMP
	ON SQ_FT_TEMP."COMPANY_ID" = UNITS."COMPANY_ID" 
		AND SQ_FT_TEMP."PROP_ID" = UNITS."PROP_ID"
		AND SQ_FT_TEMP."SQ_FT_TYPE" = UNITS."SQ_FT_TYPE"
		AND SQ_FT_TEMP."PROP_SQ_FT_TYPE" = UNITS."SQ_FT_TYPE"

WHERE UNITS."SQ_FT_TYPE" IN (@Sqft_Type) --UNITS."UNIT_CLASS" IN (@Unit_Class)
	
GROUP BY 1,2,3,4,5,6,7,8,9,10
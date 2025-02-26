WITH UNITS AS (
  SELECT 
		"public"."properties"."id" AS "PROP_ID",
		"public"."properties"."name" AS "PROP_NAME",
		"public"."units"."id" AS "UNIT_ID",
  		"public"."units"."name" AS "UNIT_NAME",
		"public"."units"."unit_class" AS "UNIT_CLASS"
  		
	FROM   "public"."units"
	INNER JOIN "public"."properties"
		ON "public"."units"."property_id" = "public"."properties"."id"
  	
  	WHERE "public"."properties"."deleted_at" IS NULL
		AND CAST("public"."properties"."company_relation_id" AS INT) = CAST(@REAL_COMPANY_ID AS INT)
		AND ("public"."units"."deleted_at" >= @AsOfDate OR "public"."units"."deleted_at" IS NULL)
  		AND "public"."units"."status" = 'active'
  		
	GROUP BY 
		1,2,3,4,5
),
SQ_FT_TEMP AS (
	SELECT
		"public"."properties"."id" AS "PROP_ID",
		"public"."units"."id" AS "UNIT_ID",
		"public"."unit_square_footage_items"."as_of_date" AS "SQ_FT_AS_OF_DATE",
		CASE 	WHEN "public"."unit_square_footage_items"."value" IS NULL THEN "public"."units"."total_square_footage"
				ELSE "public"."unit_square_footage_items"."value"
			END AS "UNIT_SQ_FT"
  
	FROM "public"."units"
	INNER JOIN "public"."properties"
		ON "public"."units"."property_id" = "public"."properties"."id"
  	LEFT JOIN "public"."unit_square_footage_items"
		ON "public"."unit_square_footage_items"."unit_id" = "public"."units"."id"
  		AND "public"."unit_square_footage_items"."as_of_date" <= @AsOfDate
  		AND "public"."unit_square_footage_items"."square_footage_type" = 'Total'
		
	WHERE "public"."units"."deleted_at" IS NULL
  		AND "public"."properties"."deleted_at" IS NULL
		AND CAST("public"."properties"."company_relation_id" AS INT) = CAST(@REAL_COMPANY_ID AS INT)
  		AND "public"."units"."status" = 'active'
		 
	),
SQ_FT_AS_OF AS (
	SELECT
		"PROP_ID",
		"UNIT_ID",
		MAX("SQ_FT_AS_OF_DATE") AS "SQ_FT_AS_OF_DATE"
	FROM SQ_FT_TEMP
	GROUP BY 1, 2
	),
UNIT_SQ_FT AS (
	SELECT
		SQ_FT_TEMP."PROP_ID",
		SQ_FT_TEMP."UNIT_ID",
		--"SQ_FT_AS_OF_DATE",
		MAX("UNIT_SQ_FT") "UNIT_SQ_FT"
	FROM SQ_FT_TEMP
	INNER JOIN SQ_FT_AS_OF
		ON SQ_FT_TEMP."PROP_ID" = SQ_FT_AS_OF."PROP_ID"
		AND SQ_FT_TEMP."UNIT_ID" = SQ_FT_AS_OF."UNIT_ID"
		AND SQ_FT_TEMP."SQ_FT_AS_OF_DATE" = SQ_FT_AS_OF."SQ_FT_AS_OF_DATE"
	
	GROUP BY 1,2
	),
PROP_SQ_FT AS (
	SELECT 
		"PROP_ID",
		SUM("UNIT_SQ_FT") AS "PROP_SQ_FT"
	FROM UNIT_SQ_FT
	GROUP BY 1
	)

SELECT 
 	"public"."leases"."id" AS "id",
	UNITS."PROP_ID",
	UNITS."PROP_NAME",
	--UNITS."UNIT_ID",
	--UNITS."UNIT_NAME",
	--UNITS."UNIT_CLASS",
	SUM(UNIT_SQ_FT."UNIT_SQ_FT") "UNIT_SQ_FT",
	MAX(PROP_SQ_FT."PROP_SQ_FT") "PROP_SQ_FT"

FROM "public"."leases" 
INNER JOIN "public"."lease_units" 
	ON "public"."leases"."id"="public"."lease_units"."lease_id"
INNER JOIN UNITS
		ON UNITS."UNIT_ID"="public"."lease_units"."unit_id"
INNER JOIN UNIT_SQ_FT
	ON UNITS."PROP_ID" = UNIT_SQ_FT."PROP_ID"
	AND UNITS."UNIT_ID" = UNIT_SQ_FT."UNIT_ID"
INNER JOIN PROP_SQ_FT
	ON UNITS."PROP_ID" = PROP_SQ_FT."PROP_ID"

WHERE ("public"."lease_units"."deleted_at" IS NULL OR "public"."lease_units"."deleted_at" >= @AsOfDate)
	AND ("public"."leases"."deleted_at" IS NULL OR "public"."leases"."deleted_at" >= @AsOfDate)

GROUP BY 1,2,3
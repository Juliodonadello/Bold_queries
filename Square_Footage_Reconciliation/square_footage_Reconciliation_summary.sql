WITH LAST_PROP_SQFT AS (
    SELECT
        p.id AS PROP_ID,
  		p.company_relation_id as COMPANY_ID,
        psfi.value AS PROP_SQ_FT,
        psfi.square_footage_type AS PROP_SQ_FT_TYPE,
        psfi.as_of_date AS AS_OF_DATE,
        ROW_NUMBER() OVER (
            PARTITION BY p.id, p.company_relation_id, psfi.square_footage_type
            ORDER BY psfi.as_of_date asc
        ) AS rn
    FROM public.properties p
    INNER JOIN public.property_square_footage_items psfi
        ON psfi.property_id = p.id
    WHERE p.name IN (@Property_Name)
        AND CAST(p.company_relation_id AS INT) = CAST(@REAL_COMPANY_ID AS INT)
        AND psfi.square_footage_type IN (@Sqft_Type)
        AND psfi.as_of_date <= @AsOfDate
  		AND p."deleted_at" IS NULL
  		AND psfi."deleted_at" IS NULL
),
LAST_UNIT_SQFT AS (
    SELECT
        p.id AS PROP_ID,
  		u.id AS UNIT_ID,
  		u.name AS UNIT_NAME,
        psfi.value AS UNIT_SQ_FT,
        psfi.square_footage_type AS UNIT_SQ_FT_TYPE,
        psfi.as_of_date AS AS_OF_DATE,
        ROW_NUMBER() OVER (
            PARTITION BY p.id, u.id, psfi.square_footage_type,u.name
            ORDER BY psfi.as_of_date DESC
        ) AS rn
    FROM public.properties p
  	INNER JOIN public.units u
  		ON u.property_id = p.id
    INNER JOIN public.unit_square_footage_items psfi
        ON psfi.unit_id = u.id
    WHERE p.name IN (@Property_Name)
        AND CAST(p.company_relation_id AS INT) = CAST(@REAL_COMPANY_ID AS INT)
        AND psfi.square_footage_type IN (@Sqft_Type)
        AND psfi.as_of_date <= @AsOfDate
  		AND p."deleted_at" IS NULL
	  	AND u."deleted_at" IS NULL
	  	AND u."status" = 'active'
		AND psfi."deleted_at" is null
),
SQ_FT_TEMP AS (
	SELECT
		LAST_PROP_SQFT.PROP_ID AS "PROP_ID",
		--SUM("public"."units"."total_square_footage") AS "TOT_SQ_FT",
		SUM(CASE WHEN LAST_UNIT_SQFT.rn = 1 THEN LAST_UNIT_SQFT.UNIT_SQ_FT ELSE 0 END) AS "TOT_SQ_FT",
  		LAST_UNIT_SQFT.UNIT_SQ_FT_TYPE AS "SQ_FT_TYPE",
  		LAST_PROP_SQFT.PROP_SQ_FT AS "PROP_SQ_FT",
  		LAST_PROP_SQFT.PROP_SQ_FT_TYPE AS "PROP_SQ_FT_TYPE",
  		LAST_PROP_SQFT.COMPANY_ID as "COMPANY_ID"
	 
  	FROM LAST_PROP_SQFT
  	INNER JOIN LAST_UNIT_SQFT ON LAST_PROP_SQFT.PROP_ID = LAST_UNIT_SQFT.PROP_ID
  													AND LAST_PROP_SQFT.PROP_SQ_FT_TYPE = LAST_UNIT_SQFT.UNIT_SQ_FT_TYPE								
  
  	WHERE LAST_PROP_SQFT.rn = 1
  		AND LAST_UNIT_SQFT.rn = 1
		
	GROUP BY  1,3,4,5,6

),
UNITS AS (
  SELECT 
    "public"."properties"."id" AS "PROP_ID",
    "public"."properties"."name" AS "PROP_NAME",
    "public"."units"."id" AS "UNIT_ID",
    "public"."units"."name" AS "UNIT_NAME",
	'Total' AS "SQ_FT_TYPE",
	"public"."units"."unit_class" AS "UNIT_CLASS",
	"public"."properties"."company_relation_id" as "COMPANY_ID",
    MAX(COALESCE(uq."value", "public"."units"."total_square_footage")) AS "UNIT_SQ_FT"
  
  FROM "public"."units"
  INNER JOIN "public"."properties"
    ON "public"."units"."property_id" = "public"."properties"."id"
  
  LEFT JOIN (
    SELECT DISTINCT ON ("unit_id") 
      "unit_id",
      "value",
      "as_of_date"
    FROM "public"."unit_square_footage_items"
    WHERE "square_footage_type" = 'Total'
      AND "as_of_date" <= @AsOfDate
    ORDER BY "unit_id", "as_of_date" DESC
  ) AS uq
    ON uq."unit_id" = "public"."units"."id"
  
  WHERE "public"."properties"."deleted_at" IS NULL
    AND ("public"."units"."deleted_at" >= @AsOfDate OR "public"."units"."deleted_at" IS NULL)
    AND "public"."properties"."name" IN (@Property_Name)
    AND CAST("public"."properties"."company_relation_id" AS INT) = CAST(@REAL_COMPANY_ID AS INT)
	AND "public"."units"."status" = 'active'
  
  GROUP BY 1,2,3,4,5,6,7
)
SELECT 	UNITS."PROP_ID",
		UNITS."PROP_NAME",
		UNITS."SQ_FT_TYPE",
		UNITS."COMPANY_ID",
		COUNT(DISTINCT UNITS."UNIT_ID")  "COUNT_UNITS",
		SUM(UNITS."UNIT_SQ_FT") "sum_units_TOT_SQ_FT",  		
		--SQ_FT_TEMP."TOT_SQ_FT" "TOT_SQ_FT",
		SQ_FT_TEMP."PROP_SQ_FT" "PROP_SQ_FT",
		CASE 
			WHEN ABS(SQ_FT_TEMP."TOT_SQ_FT" - SQ_FT_TEMP."PROP_SQ_FT") >= 1 THEN 1
			ELSE 0
		END AS "COUNT_PROP_DIFF_SQ_FT"

FROM UNITS
INNER JOIN SQ_FT_TEMP
	ON SQ_FT_TEMP."COMPANY_ID" = UNITS."COMPANY_ID" 
		AND SQ_FT_TEMP."PROP_ID" = UNITS."PROP_ID"
		AND SQ_FT_TEMP."SQ_FT_TYPE" = UNITS."SQ_FT_TYPE"
		AND SQ_FT_TEMP."PROP_SQ_FT_TYPE" = UNITS."SQ_FT_TYPE"
			
WHERE UNITS."SQ_FT_TYPE" IN (@Sqft_Type)
	
GROUP BY 1,2,3,4,7,8--,9

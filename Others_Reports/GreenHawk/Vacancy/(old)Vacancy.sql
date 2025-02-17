WITH LEASES AS (
  SELECT "public"."leases"."id" AS "LEASE_ID",
		"public"."lease_units"."unit_id" AS "UNIT_ID",
		"public"."leases"."created_at" AS "lease_created_at",
  		"public"."leases"."start" AS "start",
		"public"."leases"."end" AS "lease_end",
  		CASE WHEN "public"."leases"."status" = 'current' THEN 'CURRENT' 
  				 WHEN "public"."leases"."status" = 'future' THEN 'FUTURE' 
  		ELSE 'NONE'
  		END AS "original_lease_status",
		CASE WHEN "public"."leases"."status" = 'current' THEN 'OCCUPIED' 
  				 WHEN "public"."leases"."status" = 'future' THEN 'VACANT' 
  		ELSE 'VACANT'
  		END AS "LEASE_STATUS",
		"public"."tenants"."name"  as "TENANT",
		"public"."leases"."name" AS "LEASE_NAME"
  
  FROM "public"."leases"
	INNER JOIN "public"."lease_units"
		ON "public"."leases"."id" ="public"."lease_units"."lease_id"
	LEFT OUTER JOIN "public"."lease_deposits"
		ON "public"."leases"."id" = "public"."lease_deposits"."lease_id" 
	LEFT OUTER JOIN "public"."tenants"
		ON "public"."leases"."primaryTenantId" = "public"."tenants"."id" 
  
	WHERE ("public"."leases"."deleted_at" >= @AsOfDate OR "public"."leases"."deleted_at" IS NULL)
  	
  GROUP BY 1,2,3,4,5,6,7,8,9
	),
SQ_FT_TEMP AS (
	SELECT
		"public"."properties"."id" AS "PROP_ID",
  		SUM (CASE WHEN "public"."unit_square_footage_items"."value" IS NULL THEN "public"."units"."total_square_footage"
							ELSE "public"."unit_square_footage_items"."value"
				END) AS "TOT_SQ_FT"
  
	FROM   "public"."units"
	INNER JOIN "public"."properties"
		ON "public"."units"."property_id" = "public"."properties"."id"
  	LEFT JOIN "public"."unit_square_footage_items"
		ON "public"."unit_square_footage_items"."unit_id" = "public"."units"."id"
  		AND "public"."unit_square_footage_items"."as_of_date" <= @AsOfDate
  		AND "public"."unit_square_footage_items"."square_footage_type" = 'Total'
		
	WHERE "public"."units"."deleted_at" IS NULL
  		AND "public"."properties"."deleted_at" IS NULL
		AND CAST("public"."properties"."company_relation_id" AS INT) = CAST(@REAL_COMPANY_ID AS INT)
		
	GROUP BY  "public"."properties"."id" 
	),
UNITS AS (
  SELECT 
		"public"."properties"."id" AS "PROP_ID",
		"public"."properties"."name" AS "PROP_NAME",
		"public"."units"."id" AS "UNIT_ID",
  		"public"."units"."name" AS "UNIT_NAME",
		"public"."unit_square_footage_items"."square_footage_type" AS "SQ_FT_TYPE",
  		"public"."unit_square_footage_items"."value" AS "EFF_UNIT_SQ_FT",
		"public"."units"."unit_class" AS "UNIT_CLASS",
  		MAX("public"."units"."total_square_footage") AS "UNIT_SQ_FT"
  		
	FROM   "public"."units"
	INNER JOIN "public"."properties"
		ON "public"."units"."property_id" = "public"."properties"."id"
	LEFT JOIN "public"."unit_square_footage_items"
		ON "public"."unit_square_footage_items"."unit_id" = "public"."units"."id"
  		AND "public"."unit_square_footage_items"."as_of_date" <= @AsOfDate
  		AND "public"."unit_square_footage_items"."square_footage_type" = 'Total'
  	
  	WHERE "public"."properties"."deleted_at" IS NULL
		AND CAST("public"."properties"."company_relation_id" AS INT) = CAST(@REAL_COMPANY_ID AS INT)
		AND ("public"."units"."deleted_at" >= @AsOfDate OR "public"."units"."deleted_at" IS NULL)
  		
	GROUP BY 
		1,2,3,4,5,6,7
),
FINAL AS (
	select 
  		UNITS."PROP_ID",
  		UNITS."PROP_NAME",
  		UNITS."UNIT_ID",
  		UNITS."UNIT_NAME",
  		UNITS."SQ_FT_TYPE",
  		UNITS."EFF_UNIT_SQ_FT",
  		UNITS."UNIT_CLASS",
  		UNITS."UNIT_SQ_FT",
		"LEASE_ID",
		"lease_created_at", 
		"start",
		"lease_end",
		"TENANT",
  		--CASE WHEN "LEASE_STATUS" IS NULL THEN 'VACANT' ELSE "LEASE_STATUS" END AS "LEASE_STATUS",
  		CASE WHEN FINAL."LEASE_STATUS" = 'OCCUPIED' THEN 'OCCUPIED' ELSE 'VACANT' END AS  "LEASE_STATUS",
  		CASE WHEN "original_lease_status" IS NULL THEN 'NONE' ELSE "original_lease_status" END AS "original_lease_status",
		"LEASE_NAME"
	
  from UNITS
  left join LEASES
  	ON UNITS."UNIT_ID" = LEASES."UNIT_ID"
),
FINAL_AUX AS (
    -- prop SQ FT fix when having 2 or more leases for the same unit
    -- we dont want to sum the unit sq ft twice
    SELECT COUNT(DISTINCT "LEASE_ID") "LEASES_COUNT",
    "UNIT_ID"
    FROM FINAL
    GROUP BY "UNIT_ID"
	)

SELECT 
FINAL."PROP_ID",
FINAL."PROP_NAME",
FINAL."UNIT_ID",
FINAL."UNIT_NAME" "UNIT_NAME" ,
FINAL."LEASE_STATUS" AS  "LEASE_STATUS",
FINAL."original_lease_status" AS  "original_lease_status",
FINAL."TENANT",
FINAL."lease_created_at" "lease_created_at",
FINAL."start" "lease_start",
FINAL."lease_end",	
CASE 	WHEN FINAL."EFF_UNIT_SQ_FT" IS NULL THEN FINAL."UNIT_SQ_FT" 
			ELSE FINAL."EFF_UNIT_SQ_FT"
END AS "UNIT_SQ_FT",
CASE WHEN FINAL_AUX."LEASES_COUNT" > 0 THEN  FINAL."UNIT_SQ_FT"/FINAL_AUX."LEASES_COUNT" ELSE FINAL."UNIT_SQ_FT" END AS  "UNIT_SQ_FT_fix",

CASE WHEN FINAL."LEASE_STATUS" = 'OCCUPIED' THEN FINAL."UNIT_SQ_FT" ELSE NULL END AS  "OCCUPIED_UNIT_SQ_FT",
CASE WHEN FINAL."LEASE_STATUS" = 'OCCUPIED' AND FINAL_AUX."LEASES_COUNT" > 0 THEN FINAL."UNIT_SQ_FT"/FINAL_AUX."LEASES_COUNT" 
		 WHEN FINAL."LEASE_STATUS" = 'OCCUPIED' THEN FINAL."UNIT_SQ_FT"
		ELSE NULL 
	END AS  "OCCUPIED_UNIT_SQ_FT_fix",

CASE WHEN FINAL."LEASE_STATUS" = 'VACANT' THEN FINAL."UNIT_SQ_FT" ELSE NULL END AS  "VACCANT_UNIT_SQ_FT",
CASE WHEN FINAL."LEASE_STATUS" = 'VACANT' AND FINAL_AUX."LEASES_COUNT" > 0 THEN FINAL."UNIT_SQ_FT"/FINAL_AUX."LEASES_COUNT" 
		 WHEN FINAL."LEASE_STATUS" = 'VACANT' THEN FINAL."UNIT_SQ_FT"
		ELSE NULL 
	END AS  "VACCANT_UNIT_SQ_FT_fix",

CASE 	WHEN SQ_FT_TEMP."TOT_SQ_FT" = 0 THEN 0 
		ELSE FINAL."UNIT_SQ_FT" / SQ_FT_TEMP."TOT_SQ_FT" * 100 
	END AS "Pct of Property",
CASE	WHEN SQ_FT_TEMP."TOT_SQ_FT" = 0 or SQ_FT_TEMP."TOT_SQ_FT" IS NULL THEN 0
		WHEN FINAL_AUX."LEASES_COUNT" > 0 THEN (FINAL."UNIT_SQ_FT"/FINAL_AUX."LEASES_COUNT") / SQ_FT_TEMP."TOT_SQ_FT" * 100
		WHEN FINAL_AUX."LEASES_COUNT" <= 0 OR FINAL_AUX."LEASES_COUNT" IS NULL THEN FINAL."UNIT_SQ_FT" / SQ_FT_TEMP."TOT_SQ_FT" * 100
		ELSE NULL 
	END AS  "Pct of Property_fix",

CASE 	WHEN SQ_FT_TEMP."TOT_SQ_FT" = 0 THEN 0 
		WHEN FINAL."LEASE_STATUS" = 'VACANT' THEN 0 
		ELSE FINAL."UNIT_SQ_FT" / SQ_FT_TEMP."TOT_SQ_FT" * 100 
	END AS "OCC Pct of Property",
CASE	WHEN SQ_FT_TEMP."TOT_SQ_FT" = 0 or SQ_FT_TEMP."TOT_SQ_FT" IS NULL THEN 0
		WHEN FINAL."LEASE_STATUS" = 'VACANT' OR FINAL_AUX."LEASES_COUNT" = 0 THEN 0 
		WHEN FINAL_AUX."LEASES_COUNT" > 0 THEN (FINAL."UNIT_SQ_FT"/FINAL_AUX."LEASES_COUNT") / SQ_FT_TEMP."TOT_SQ_FT" * 100
		ELSE NULL 
	END AS  "OCC Pct of Property_fix",

CASE 	WHEN SQ_FT_TEMP."TOT_SQ_FT" = 0 OR FINAL."LEASE_STATUS" = 'OCCUPIED' THEN 0 
		ELSE FINAL."UNIT_SQ_FT" / SQ_FT_TEMP."TOT_SQ_FT" * 100 
	END AS "VAC Pct of Property",
CASE	WHEN SQ_FT_TEMP."TOT_SQ_FT" = 0 or SQ_FT_TEMP."TOT_SQ_FT" IS NULL THEN 0 -- UNIT WITHOUT SQ FT
		WHEN FINAL_AUX."LEASES_COUNT" > 0 or FINAL."LEASE_STATUS" = 'OCCUPIED' THEN 0 -- con leases future
		WHEN FINAL_AUX."LEASES_COUNT" > 0 or FINAL."LEASE_STATUS" = 'OCCUPIED' THEN 0 -- con leases
		WHEN FINAL."LEASE_STATUS" = 'VACANT' OR FINAL_AUX."LEASES_COUNT" = 0 THEN  FINAL."UNIT_SQ_FT" / SQ_FT_TEMP."TOT_SQ_FT" * 100 -- sin lease
		ELSE NULL 
	END AS  "VAC Pct of Property_fix",

FINAL."LEASE_NAME",
FINAL."SQ_FT_TYPE",
FINAL."UNIT_CLASS" "UNIT_CLASS" 

FROM FINAL
LEFT JOIN SQ_FT_TEMP
	ON FINAL."PROP_ID" = SQ_FT_TEMP."PROP_ID"
LEFT JOIN FINAL_AUX
	ON FINAL."UNIT_ID" = FINAL_AUX."UNIT_ID"
		
where  	FINAL."PROP_NAME" IN (@Property_Name)
		AND FINAL."SQ_FT_TYPE" IN (@Sqft_Type)
		AND FINAL."UNIT_CLASS" IN (@Unit_Class)
		--AND CAST("public"."properties"."company_relation_id" AS INT) = CAST(@REAL_COMPANY_ID AS INT)

order by "PROP_NAME", FINAL."UNIT_NAME"
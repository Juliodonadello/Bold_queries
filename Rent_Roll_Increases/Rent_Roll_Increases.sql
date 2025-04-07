WITH CHARGE_CONTROL AS (
  	SELECT 
  			"public"."properties"."id" AS "PROP_ID",
  			"public"."property_charge_controls"."item_id" as "ITEM_ID",
  			CASE WHEN "public"."property_charge_controls"."base_rent" then 1 else 0 end as "BASE_RENT"
  		
  	FROM "public"."properties"
  	INNER JOIN "public"."property_charge_controls"
  		ON "public"."property_charge_controls"."property_id" = "public"."properties"."id"
  	
  	WHERE "public"."properties"."name" IN (@Property_Name)
	AND CAST("public"."properties"."company_relation_id" AS INT) = CAST(@REAL_COMPANY_ID AS INT)
	),
CHARGES_TOT AS (
  SELECT 
		MAX("recurring_charge_id") AS "RCHARGE_ID",
  		"public"."lease_recurring_charges"."lease_id" AS "LEASE_ID",
  		--old --CASE WHEN "public"."lease_recurring_charges"."order_entry_item_id" LIKE '%RENT%' OR  "public"."lease_recurring_charges"."order_entry_item_id" LIKE '%Rent%' THEN "public"."lease_recurring_charge_amounts"."amount" ELSE 0 END AS "RENT_CHARGE",
		--old --CASE WHEN "public"."lease_recurring_charges"."order_entry_item_id"  NOT LIKE '%RENT%' AND "public"."lease_recurring_charges"."order_entry_item_id"  NOT LIKE '%Rent%'  THEN "public"."lease_recurring_charge_amounts"."amount" ELSE 0 END AS "OTHER_CHARGE",
		CASE WHEN CHARGE_CONTROL. "BASE_RENT" = 1 THEN "public"."lease_recurring_charge_amounts"."amount" ELSE 0 END AS "RENT_CHARGE",
  		CASE WHEN CHARGE_CONTROL. "BASE_RENT" = 0 THEN "public"."lease_recurring_charge_amounts"."amount" ELSE 0 END AS "OTHER_CHARGE",
  		"public"."lease_recurring_charge_amounts"."effective_date" AS "EFFECTIVE_DATE",
  		"public"."units"."property_id" "PROP_ID",
  		"public"."lease_recurring_charges"."unit_id" "UNIT_ID"
  
	FROM "public"."lease_recurring_charges"
	LEFT OUTER JOIN "public"."lease_recurring_charge_amounts"
		ON "public"."lease_recurring_charges"."id" = "public"."lease_recurring_charge_amounts"."recurring_charge_id"
	--INNER JOIN "public"."lease_units"  --aumenta los registros pero esta bien que se duplique un lease con distintas units
  	--	ON "public"."lease_recurring_charges"."lease_id" ="public"."lease_units"."lease_id"
 	 INNER JOIN "public"."units"
  		ON "public"."lease_recurring_charges"."unit_id" =  "public"."units"."id"
  	INNER JOIN CHARGE_CONTROL
  		ON CHARGE_CONTROL. "PROP_ID" = "public"."units"."property_id"
  		AND CHARGE_CONTROL. "ITEM_ID" = "public"."lease_recurring_charges"."order_entry_item_id"
  
  	WHERE "public"."lease_recurring_charge_amounts"."effective_date" <= @AsOfDate
	AND (
		"public"."lease_recurring_charge_amounts"."deleted_at" >= @AsOfDate 
		OR 
		"public"."lease_recurring_charge_amounts"."deleted_at" IS NULL
		)
	AND (
		"public"."lease_recurring_charges"."deleted_at" >= @AsOfDate
		OR
		"public"."lease_recurring_charges"."deleted_at" IS NULL
		)
	AND (
		"public"."lease_recurring_charge_amounts"."frequency" != 'One Time' --not a one time charge
		OR
		(
			"public"."lease_recurring_charge_amounts"."frequency" = 'One Time'
			AND	 CAST(EXTRACT(DAY FROM (@AsOfDate - "public"."lease_recurring_charge_amounts"."effective_date")) AS INTEGER) > 0
		  	AND CAST(EXTRACT(DAY FROM (@AsOfDate - "public"."lease_recurring_charge_amounts"."effective_date")) AS INTEGER) < 31
		)--one time charge with less than a month differnce
		)
	AND (	
	  	"public"."lease_recurring_charges"."terminate_date" >= @AsOfDate
		OR
		"public"."lease_recurring_charges"."terminate_date" is NULL 
		)
	AND (	
	  	"public"."lease_recurring_charges"."deleted_at" >= @AsOfDate
		OR
		"public"."lease_recurring_charges"."deleted_at" is NULL 
		)
		
	GROUP BY 
		"public"."lease_recurring_charges"."lease_id",
		CASE WHEN CHARGE_CONTROL. "BASE_RENT" = 1 THEN "public"."lease_recurring_charge_amounts"."amount" ELSE 0 END ,
		CASE WHEN CHARGE_CONTROL. "BASE_RENT" = 0 THEN "public"."lease_recurring_charge_amounts"."amount" ELSE 0 END,
		"public"."lease_recurring_charge_amounts"."effective_date",
		"public"."units"."property_id",
		"public"."lease_recurring_charges"."unit_id"
	),
MAX_CHARGES AS (
 	SELECT  "RCHARGE_ID" "RCHARGE_ID",
   	MAX("EFFECTIVE_DATE") "EFFECTIVE_DATE"
 	FROM CHARGES_TOT
	GROUP BY "RCHARGE_ID"
 ),
CHARGES AS ( 
 SELECT CHARGES_TOT.*
 FROM CHARGES_TOT
 INNER JOIN MAX_CHARGES
 	ON CHARGES_TOT."RCHARGE_ID" =  MAX_CHARGES."RCHARGE_ID" 
	AND CHARGES_TOT."EFFECTIVE_DATE" =  MAX_CHARGES."EFFECTIVE_DATE"
  GROUP BY 
  CHARGES_TOT."RCHARGE_ID",
  CHARGES_TOT."LEASE_ID",
  CHARGES_TOT."RENT_CHARGE",
  CHARGES_TOT."OTHER_CHARGE",
  CHARGES_TOT."EFFECTIVE_DATE",
  CHARGES_TOT."PROP_ID",
  CHARGES_TOT."UNIT_ID"
	),
LEASES AS (
  SELECT "public"."leases"."id" AS "LEASE_ID",
  		"public"."leases"."name" AS "LEASE_NAME",
		"public"."lease_units"."unit_id" AS "UNIT_ID",
		"public"."leases"."created_at" AS "lease_created_at",
  		"public"."leases"."start" AS "start",
		"public"."leases"."end" AS "lease_end",
		CASE WHEN "public"."leases"."status" = 'current' THEN 'OCCUPIED' ELSE 'VACANT' END AS "LEASE_STATUS",
		CASE WHEN "public"."lease_deposits"."id" IS NULL THEN 'NO' ELSE 'YES' END AS "DEPOSIT",
		CASE
			WHEN COUNT(DISTINCT "public"."lease_deposits"."refundable") > 1 THEN 'MANY'
			WHEN MAX(CASE WHEN "public"."lease_deposits"."refundable" = 'true' THEN 1 ELSE 0 END) = 1 THEN 'YES'
			ELSE 'NO'
		END AS "REFUNDABLE",
		"public"."tenants"."name"  as "TENANT"
  
  FROM "public"."leases"
	INNER JOIN "public"."lease_units"
		ON "public"."leases"."id" ="public"."lease_units"."lease_id"
	LEFT OUTER JOIN "public"."lease_deposits"
		ON "public"."leases"."id" = "public"."lease_deposits"."lease_id"
		AND ("public"."lease_deposits"."deleted_at" >= @AsOfDate OR "public"."lease_deposits"."deleted_at" IS  NULL)
	LEFT OUTER JOIN "public"."tenants"
		ON "public"."leases"."primaryTenantId" = "public"."tenants"."id"
	INNER JOIN "public"."properties"
		ON "public"."properties"."id" = "public"."leases"."property_id"

  
	WHERE 
		(	("public"."leases"."start" <= @AsOfDate AND "public"."leases"."end" > @AsOfDate)
  			OR ("public"."leases"."start" <= @AsOfDate AND "public"."leases"."end" IS NULL)
		)
		AND "public"."leases"."status" = 'current'
		AND ("public"."leases"."deleted_at" >= @AsOfDate OR "public"."leases"."deleted_at" IS NULL)
		AND "public"."properties"."name" IN (@Property_Name)
  	
  GROUP BY
  		"public"."leases"."id",
  		"public"."leases"."name",
		"public"."lease_units"."unit_id",
		"public"."leases"."created_at",
  		"public"."leases"."start",
		"public"."leases"."end",
		CASE WHEN "public"."leases"."status" = 'current' THEN 'OCCUPIED' ELSE 'VACANT' END ,
		CASE WHEN "public"."lease_deposits"."id" IS NULL THEN 'NO' ELSE 'YES' END ,
		"public"."tenants"."name"
	),
LEASES_CHARGES AS (
	SELECT 
  	LEASES."LEASE_ID",
  	LEASES."LEASE_NAME",
	LEASES."UNIT_ID",
	MIN(LEASES."lease_created_at") "lease_created_at", --because of difference in seconds, can't be grouped
  	MIN(LEASES."start") "start",
	MAX(LEASES."lease_end") "lease_end", --because of difference in seconds, can't be grouped
  	LEASES."TENANT",
  	COALESCE(MAX(CASE WHEN LEASES."LEASE_STATUS" = 'OCCUPIED' THEN 'OCCUPIED' END), MAX(LEASES."LEASE_STATUS")) AS "LEASE_STATUS",
  	COALESCE(MAX(CASE WHEN LEASES."DEPOSIT" = 'YES' THEN 'YES' END), MAX(LEASES."DEPOSIT")) AS "DEPOSIT",
  	COALESCE(MAX(CASE WHEN LEASES."REFUNDABLE" = 'YES' THEN 'YES' END), MAX(LEASES."REFUNDABLE")) AS "REFUNDABLE",
  	SUM(CHARGES."RENT_CHARGE") "RENT_CHARGE",
  	SUM(CHARGES."OTHER_CHARGE") "OTHER_CHARGE"
		
	FROM LEASES
	LEFT JOIN CHARGES
		ON  LEASES."LEASE_ID" = CHARGES."LEASE_ID"
  		AND LEASES."UNIT_ID" = CHARGES."UNIT_ID"
	GROUP BY LEASES."LEASE_ID",
  		LEASES."LEASE_NAME",
		LEASES."UNIT_ID",
		LEASES."TENANT" 
	),
UNITS AS (
  SELECT 
    "public"."properties"."id" AS "PROP_ID",
    "public"."properties"."name" AS "PROP_NAME",
    "public"."units"."id" AS "UNIT_ID",
    "public"."units"."name" AS "UNIT_NAME",
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
  
  GROUP BY 
    "public"."properties"."id",
    "public"."properties"."name",
    "public"."units"."id",
    "public"."units"."name"
),
SQ_FT_TEMP AS (
	SELECT
		UNITS."PROP_ID" as "PROP_ID",
		SUM(UNITS."UNIT_SQ_FT") AS "TOT_SQ_FT"
	 
	FROM UNITS

	GROUP BY  UNITS."PROP_ID"
	),
FINAL AS (
	select 
		"LEASE_ID",
  		"LEASE_NAME",
		"UNIT_ID",
		"lease_created_at", 
		"start",
		"lease_end",
		"TENANT",
		"LEASE_STATUS",
		"DEPOSIT",
		"REFUNDABLE",
		"RENT_CHARGE",
		"OTHER_CHARGE"
	from LEASES_CHARGES
	group by 
		"LEASE_ID",
  		"LEASE_NAME",
		"UNIT_ID",
		"lease_created_at", 
		"start",
		"lease_end",
		"TENANT",
		"LEASE_STATUS",
		"DEPOSIT",
		"REFUNDABLE",
		"RENT_CHARGE",
		"OTHER_CHARGE"
	ORDER BY LEASES_CHARGES."LEASE_ID"
	),
FINAL_AUX AS (
    -- prop SQ FT fix when having 2 or more leases for the same unit
    -- we dont want to sum twice the unit sq ft
    SELECT COUNT(DISTINCT "LEASE_ID") "LEASES_COUNT",
    "UNIT_ID"
    FROM FINAL
    GROUP BY "UNIT_ID"
	),
RENT_SCALATIONS AS (
  SELECT 
  		"public"."lease_recurring_charges"."lease_id" AS "LEASE_ID",
  		CASE WHEN CHARGE_CONTROL."BASE_RENT" = 1 AND "public"."lease_recurring_charge_amounts"."amount" > 0 THEN 1 ELSE 0 END AS "FLAG_RENT_SCAL",
		CASE WHEN CHARGE_CONTROL."BASE_RENT" = 1 THEN "public"."lease_recurring_charge_amounts"."amount" ELSE 0 END AS "RENT_CHARGE_SCAL",
  		--CASE WHEN CHARGE_CONTROL. "BASE_RENT" = 0 THEN "public"."lease_recurring_charge_amounts"."amount" ELSE 0 END AS "OTHER_CHARGE",
  		"public"."lease_recurring_charge_amounts"."effective_date" AS "EFFECTIVE_DATE_SCAL",
  		"public"."units"."property_id" "PROP_ID",
  		"public"."lease_recurring_charges"."unit_id" "UNIT_ID"
  
	FROM "public"."lease_recurring_charges"
	LEFT OUTER JOIN "public"."lease_recurring_charge_amounts"
		ON "public"."lease_recurring_charges"."id" = "public"."lease_recurring_charge_amounts"."recurring_charge_id"
 	INNER JOIN "public"."units"
  		ON "public"."lease_recurring_charges"."unit_id" =  "public"."units"."id"
  	INNER JOIN CHARGE_CONTROL
  		ON CHARGE_CONTROL. "PROP_ID" = "public"."units"."property_id"
  		AND CHARGE_CONTROL. "ITEM_ID" = "public"."lease_recurring_charges"."order_entry_item_id"
	INNER JOIN "public"."properties"
		ON "public"."properties"."id" = "public"."units"."property_id"
  
  	WHERE "public"."lease_recurring_charge_amounts"."effective_date" > @AsOfDate
	AND (
		"public"."lease_recurring_charge_amounts"."deleted_at" > @AsOfDate 
		OR 
		"public"."lease_recurring_charge_amounts"."deleted_at" IS NULL
		)
	AND (
		"public"."lease_recurring_charges"."deleted_at" > @AsOfDate
		OR
		"public"."lease_recurring_charges"."deleted_at" IS NULL
		)
	AND (
		"public"."lease_recurring_charge_amounts"."frequency" != 'One Time' --not a one time charge 
		--OR
		/*(
			"public"."lease_recurring_charge_amounts"."frequency" = 'One Time'
			AND	 CAST(EXTRACT(DAY FROM (@AsOfDate - "public"."lease_recurring_charge_amounts"."effective_date")) AS INTEGER) > 0
		  	AND CAST(EXTRACT(DAY FROM (@AsOfDate - "public"."lease_recurring_charge_amounts"."effective_date")) AS INTEGER) < 31
		)--one time charge with less than a month differnce
		-- COMMENTED BECAUSE ONE TIME ARE NOT CONSIDER SCALATIONS
		*/
		)
	AND (	
	  	"public"."lease_recurring_charges"."terminate_date" > @AsOfDate
		OR
		"public"."lease_recurring_charges"."terminate_date" is NULL 
		)
	AND (	
	  	"public"."lease_recurring_charges"."deleted_at" > @AsOfDate
		OR
		"public"."lease_recurring_charges"."deleted_at" is NULL 
		)
	AND "public"."properties"."name" IN (@Property_Name)
  	AND CHARGE_CONTROL. "BASE_RENT" = 1
  	AND "public"."units"."status" = 'active'
		
	GROUP BY 
		"public"."lease_recurring_charges"."lease_id",
  		CASE WHEN CHARGE_CONTROL."BASE_RENT" = 1 AND "public"."lease_recurring_charge_amounts"."amount" > 0 THEN 1 ELSE 0 END,
		CASE WHEN CHARGE_CONTROL. "BASE_RENT" = 1 THEN "public"."lease_recurring_charge_amounts"."amount" ELSE 0 END,
		"public"."lease_recurring_charge_amounts"."effective_date",
		"public"."units"."property_id",
		"public"."lease_recurring_charges"."unit_id"
	ORDER BY 
			"public"."units"."property_id",
			"public"."lease_recurring_charges"."unit_id",
			"public"."lease_recurring_charges"."lease_id",
			"public"."lease_recurring_charge_amounts"."effective_date" ASC
	),
RENT_SCALATIONS_AUX AS (
	SELECT 
  			RENT_SCALATIONS."PROP_ID",
			RENT_SCALATIONS."UNIT_ID",
			--SUM(RENT_SCALATIONS."FLAG_RENT_SCAL") AS "COUNT_RENT_CHARGE_SCAL"
			CASE WHEN SUM(RENT_SCALATIONS."FLAG_RENT_SCAL") < 1 THEN 1 ELSE SUM(RENT_SCALATIONS."FLAG_RENT_SCAL") END AS "COUNT_RENT_CHARGE_SCAL"


	FROM RENT_SCALATIONS
  	--INNER JOIN CHARGE_CONTROL ON RENT_SCALATIONS."PROP_ID" = CHARGE_CONTROL."PROP_ID"

	GROUP BY RENT_SCALATIONS."PROP_ID",
			RENT_SCALATIONS."UNIT_ID",
  			RENT_SCALATIONS."LEASE_ID"
	ORDER BY RENT_SCALATIONS."PROP_ID",
			RENT_SCALATIONS."UNIT_ID"
),
RENT_SCALATIONS_FINAL AS (
	SELECT 
  			RENT_SCALATIONS."PROP_ID",
			RENT_SCALATIONS."UNIT_ID",
			RENT_SCALATIONS."LEASE_ID",
  			RENT_SCALATIONS."RENT_CHARGE_SCAL",
			RENT_SCALATIONS."EFFECTIVE_DATE_SCAL",
			MAX(RENT_SCALATIONS_AUX."COUNT_RENT_CHARGE_SCAL") "COUNT_RENT_CHARGE_SCAL"

	FROM RENT_SCALATIONS
  	LEFT JOIN RENT_SCALATIONS_AUX
  		ON RENT_SCALATIONS."PROP_ID" = RENT_SCALATIONS_AUX."PROP_ID"
  		AND RENT_SCALATIONS."UNIT_ID" = RENT_SCALATIONS_AUX."UNIT_ID"

	GROUP BY 1,2,3,4,5
	ORDER BY RENT_SCALATIONS."PROP_ID",
			RENT_SCALATIONS."UNIT_ID",
			RENT_SCALATIONS."LEASE_ID",
			RENT_SCALATIONS."EFFECTIVE_DATE_SCAL" ASC
)

SELECT 
UNITS."PROP_ID",
UNITS."PROP_NAME",
UNITS."UNIT_ID",
UNITS."UNIT_NAME" "UNIT_NAME" ,
FINAL."LEASE_ID",
FINAL."LEASE_NAME",
--CASE WHEN FINAL."LEASE_STATUS" = 'OCCUPIED' THEN 'OCCUPIED' ELSE 'VACANT' END AS  "LEASE_STATUS",
CASE WHEN FINAL."lease_created_at" IS NOT NULL THEN 'OCCUPIED' ELSE 'VACANT' END AS  "LEASE_STATUS", -- esto se hizo porque los status future se deben ver como Occupied si el asofdate coincide
FINAL."TENANT",
--FINAL."lease_created_at" "lease_created_at",
FINAL."start" "lease_start",
FINAL."lease_end",	
UNITS."UNIT_SQ_FT" "UNIT_SQ_FT",
FINAL_AUX."LEASES_COUNT",
CASE WHEN RENT_SCALATIONS_FINAL."COUNT_RENT_CHARGE_SCAL">1 THEN RENT_SCALATIONS_FINAL."COUNT_RENT_CHARGE_SCAL"
		ELSE 1
		END AS "COUNT_RENT_CHARGE_SCAL",
CASE 	WHEN ( FINAL_AUX."LEASES_COUNT" <2 AND RENT_SCALATIONS_FINAL."COUNT_RENT_CHARGE_SCAL" < 2)
						OR (FINAL_AUX."LEASES_COUNT" is null AND RENT_SCALATIONS_FINAL."COUNT_RENT_CHARGE_SCAL" is null) THEN UNITS."UNIT_SQ_FT"
			WHEN (FINAL_AUX."LEASES_COUNT" > 1 AND RENT_SCALATIONS_FINAL."COUNT_RENT_CHARGE_SCAL" is null) THEN UNITS."UNIT_SQ_FT"/FINAL_AUX."LEASES_COUNT"
			WHEN (RENT_SCALATIONS_FINAL."COUNT_RENT_CHARGE_SCAL" > 1 AND FINAL_AUX."LEASES_COUNT" is null) THEN UNITS."UNIT_SQ_FT"/RENT_SCALATIONS_FINAL."COUNT_RENT_CHARGE_SCAL"
			ELSE  UNITS."UNIT_SQ_FT"/(FINAL_AUX."LEASES_COUNT" *  COALESCE(RENT_SCALATIONS_FINAL."COUNT_RENT_CHARGE_SCAL", 1) )
	END AS "UNIT_SQ_FT_fix",
CASE 	WHEN SQ_FT_TEMP."TOT_SQ_FT" = 0 THEN 0 
			ELSE UNITS."UNIT_SQ_FT" / SQ_FT_TEMP."TOT_SQ_FT" * 100 
	END AS "Pct of Property",
CASE 	WHEN SQ_FT_TEMP."TOT_SQ_FT" = 0 THEN 0
			WHEN (FINAL_AUX."LEASES_COUNT"<2 AND RENT_SCALATIONS_FINAL."COUNT_RENT_CHARGE_SCAL" < 2)
						OR (FINAL_AUX."LEASES_COUNT" is null AND RENT_SCALATIONS_FINAL."COUNT_RENT_CHARGE_SCAL" is null) THEN UNITS."UNIT_SQ_FT" / SQ_FT_TEMP."TOT_SQ_FT" * 100
			WHEN (FINAL_AUX."LEASES_COUNT" > 1 AND RENT_SCALATIONS_FINAL."COUNT_RENT_CHARGE_SCAL" is null) THEN UNITS."UNIT_SQ_FT" / FINAL_AUX."LEASES_COUNT" / SQ_FT_TEMP."TOT_SQ_FT" * 100
			WHEN (RENT_SCALATIONS_FINAL."COUNT_RENT_CHARGE_SCAL" > 1 AND FINAL_AUX."LEASES_COUNT" is null) THEN UNITS."UNIT_SQ_FT" /RENT_SCALATIONS_FINAL."COUNT_RENT_CHARGE_SCAL" / SQ_FT_TEMP."TOT_SQ_FT" * 100
			ELSE UNITS."UNIT_SQ_FT"/(FINAL_AUX."LEASES_COUNT" *  COALESCE(RENT_SCALATIONS_FINAL."COUNT_RENT_CHARGE_SCAL", 1)) / SQ_FT_TEMP."TOT_SQ_FT" * 100
	END AS "Pct of Property_fix",
FINAL."DEPOSIT",
FINAL."REFUNDABLE",
--LEASES."RCHARGE_ID",
FINAL."RENT_CHARGE" "RENT_AMOUNT",
FINAL."OTHER_CHARGE" "OTHER_AMOUNT",
CASE 
    WHEN RENT_SCALATIONS_FINAL."COUNT_RENT_CHARGE_SCAL" IS NULL THEN FINAL."RENT_CHARGE"
    ELSE FINAL."RENT_CHARGE" / COALESCE(RENT_SCALATIONS_FINAL."COUNT_RENT_CHARGE_SCAL", 1)
END AS "RENT_AMOUNT_fix",
CASE 
    WHEN RENT_SCALATIONS_FINAL."COUNT_RENT_CHARGE_SCAL" IS NULL THEN FINAL."OTHER_CHARGE"
    ELSE FINAL."OTHER_CHARGE" / COALESCE(RENT_SCALATIONS_FINAL."COUNT_RENT_CHARGE_SCAL", 1)
END AS "OTHER_AMOUNT_fix",
CASE WHEN UNITS."UNIT_SQ_FT" = 0 THEN 0 ELSE FINAL."RENT_CHARGE" *12 /UNITS."UNIT_SQ_FT" END AS "Annual Rent/Sq Ft",
CASE WHEN UNITS."UNIT_SQ_FT" = 0 THEN 0 ELSE FINAL."OTHER_CHARGE" *12 /UNITS."UNIT_SQ_FT" END AS "Annual Other/Sq Ft",
CASE 
    WHEN UNITS."UNIT_SQ_FT" = 0 THEN 0
    ELSE FINAL."RENT_CHARGE" * 12 / UNITS."UNIT_SQ_FT" / COALESCE(RENT_SCALATIONS_FINAL."COUNT_RENT_CHARGE_SCAL", 1)
END AS "Annual Rent/Sq Ft_fix",
CASE 
    WHEN UNITS."UNIT_SQ_FT" = 0 THEN 0
    ELSE FINAL."OTHER_CHARGE" * 12 / UNITS."UNIT_SQ_FT" / COALESCE(RENT_SCALATIONS_FINAL."COUNT_RENT_CHARGE_SCAL", 1)
END AS "Annual Other/Sq Ft_fix",
RENT_SCALATIONS_FINAL."RENT_CHARGE_SCAL",
RENT_SCALATIONS_FINAL."EFFECTIVE_DATE_SCAL"

FROM UNITS
LEFT JOIN SQ_FT_TEMP
	ON UNITS."PROP_ID" = SQ_FT_TEMP."PROP_ID"
LEFT JOIN FINAL
	ON UNITS."UNIT_ID" = FINAL."UNIT_ID"
LEFT JOIN FINAL_AUX
	ON FINAL."UNIT_ID" = FINAL_AUX."UNIT_ID"
INNER JOIN "public"."properties"
	ON UNITS."PROP_ID" = "public"."properties"."id"
LEFT JOIN RENT_SCALATIONS_FINAL
	ON RENT_SCALATIONS_FINAL."PROP_ID" = UNITS."PROP_ID"
	AND RENT_SCALATIONS_FINAL."UNIT_ID" = UNITS."UNIT_ID"
	AND RENT_SCALATIONS_FINAL."LEASE_ID" = FINAL."LEASE_ID"

where  "PROP_NAME" IN (@Property_Name)
	AND CAST("public"."properties"."company_relation_id" AS INT) = CAST(@REAL_COMPANY_ID AS INT)

--group by 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28

order by "PROP_NAME", UNITS."UNIT_NAME",
			RENT_SCALATIONS_FINAL."EFFECTIVE_DATE_SCAL" ASC

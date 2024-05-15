WITH CHARGE_CONTROL AS (
  	SELECT 
  			"public"."properties"."id" AS "PROP_ID",
  			"public"."property_charge_controls"."item_id" as "ITEM_ID",
  			CASE WHEN "public"."property_charge_controls"."base_rent" then 1 else 0 end as "BASE_RENT"
  		
  	FROM "public"."properties"
  	INNER JOIN "public"."property_charge_controls"
  		ON "public"."property_charge_controls"."property_id" = "public"."properties"."id"
  	INNER JOIN "public"."company_accounts"
		ON "public"."properties"."company_relation_id" = "public"."company_accounts"."id"
  	
  	WHERE "public"."properties"."name" IN (@Property_Name)
	AND "public"."company_accounts"."company_id" IN (@COMPANY_ID)
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
	--INNER JOIN "public"."leases_units_units"  --aumenta los registros pero esta bien que se duplique un lease con distintas units
  	--	ON "public"."lease_recurring_charges"."lease_id" ="public"."leases_units_units"."leasesId"
 	 INNER JOIN "public"."units"
  		--ON "public"."leases_units_units"."unitsId" =  "public"."units"."id"
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
		"public"."leases_units_units"."unitsId" AS "UNIT_ID",
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
	INNER JOIN "public"."leases_units_units"
		ON "public"."leases"."id" ="public"."leases_units_units"."leasesId"
	LEFT OUTER JOIN "public"."lease_deposits"
		ON "public"."leases"."id" = "public"."lease_deposits"."lease_id"
		AND ("public"."lease_deposits"."deleted_at" >= @AsOfDate OR "public"."lease_deposits"."deleted_at" IS  NULL)
	LEFT OUTER JOIN "public"."tenants"
		ON "public"."leases"."primaryTenantId" = "public"."tenants"."id" 
  
	WHERE 
		(	("public"."leases"."start" <= @AsOfDate AND "public"."leases"."end" > @AsOfDate)
  			OR ("public"."leases"."start" <= @AsOfDate AND "public"."leases"."end" IS NULL)
		)
		AND "public"."leases"."status" = 'current'
		AND ("public"."leases"."deleted_at" >= @AsOfDate OR "public"."leases"."deleted_at" IS NULL)
  	
  GROUP BY
  		"public"."leases"."id",
		"public"."leases_units_units"."unitsId",
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
		LEASES."UNIT_ID",
		LEASES."TENANT" 
	),
SQ_FT_TEMP AS (
	SELECT
		"public"."properties"."id" AS "PROP_ID",
		SUM("public"."units"."total_square_footage") AS "TOT_SQ_FT"
	 
	FROM   "public"."units"
	INNER JOIN "public"."properties"
		ON "public"."units"."property_id" = "public"."properties"."id"
  	INNER JOIN "public"."company_accounts"
		ON "public"."properties"."company_relation_id" = "public"."company_accounts"."id"
  
  WHERE "public"."units"."deleted_at" IS NULL
  	and "public"."properties"."deleted_at" IS NULL
	AND "public"."company_accounts"."company_id" IN (@COMPANY_ID)
		
	GROUP BY  "public"."properties"."id" 
	),
UNITS AS (
  SELECT 
		"public"."properties"."id" AS "PROP_ID",
		"public"."properties"."name" AS "PROP_NAME",
		"public"."units"."id" AS "UNIT_ID",
  		"public"."units"."name" AS "UNIT_NAME",
		MAX("public"."units"."total_square_footage") AS "UNIT_SQ_FT"
  		
	FROM   "public"."units"
	INNER JOIN "public"."properties"
		ON "public"."units"."property_id" = "public"."properties"."id"
	INNER JOIN "public"."company_accounts"
		ON "public"."properties"."company_relation_id" = "public"."company_accounts"."id"
  
  	WHERE "public"."units"."deleted_at" IS NULL
  		AND "public"."properties"."deleted_at" IS NULL
		AND ("public"."units"."deleted_at" >= @AsOfDate OR "public"."units"."deleted_at" IS NULL)
	
	GROUP BY 
		"public"."properties"."id",
		"public"."properties"."name",
		"public"."units"."id",
  		"public"."units"."name"
	),
FINAL AS (
	select 
		"LEASE_ID",
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
	)


SELECT 
	UNITS."PROP_ID",
	UNITS."PROP_NAME",
	COUNT(DISTINCT UNITS."UNIT_ID") AS "UNIT_TOT",
	SUM(CASE
	  		WHEN (FINAL_AUX."LEASES_COUNT" = 0 OR FINAL_AUX."LEASES_COUNT" IS NULL) THEN UNITS."UNIT_SQ_FT" 
	  		ELSE UNITS."UNIT_SQ_FT"/FINAL_AUX."LEASES_COUNT"
	  	END ) AS "PROP_SQ_FT",
	--SUM(UNITS."UNIT_SQ_FT"/FINAL_AUX."LEASES_COUNT") AS  "PROP_SQ_FT",
	SUM(CASE WHEN (FINAL."LEASE_STATUS"='OCCUPIED') THEN UNITS."UNIT_SQ_FT"/FINAL_AUX."LEASES_COUNT" ELSE 0 END) AS "OCCUPIED_UNIT_SQ_FT",
	SUM(FINAL."RENT_CHARGE") "RENT_AMOUNT_TOT",
	SUM(FINAL."OTHER_CHARGE") "OTHER_AMOUNT_TOT",
	"public"."company_accounts"."company_id" "COMPANY_ID"
	
FROM UNITS
LEFT JOIN SQ_FT_TEMP
	ON UNITS."PROP_ID" = SQ_FT_TEMP."PROP_ID"
LEFT JOIN FINAL
	ON UNITS."UNIT_ID" = FINAL."UNIT_ID"
LEFT JOIN FINAL_AUX
	ON FINAL."UNIT_ID" = FINAL_AUX."UNIT_ID"
INNER JOIN "public"."properties"
		ON UNITS."PROP_ID" = "public"."properties"."id"
INNER JOIN "public"."company_accounts"
		ON "public"."properties"."company_relation_id" = "public"."company_accounts"."id"

where  "PROP_NAME" IN (@Property_Name)
 and "public"."properties"."deleted_at" IS NULL
 AND "public"."company_accounts"."company_id" IN (@COMPANY_ID)

group by UNITS."PROP_ID",UNITS."PROP_NAME","COMPANY_ID"
order by "PROP_NAME"

WITH CHARGES_TOT AS (
  SELECT 
		"public"."lease_recurring_charges"."id" AS "RCHARGE_ID",
  		"public"."lease_recurring_charges"."lease_id" AS "LEASE_ID",
  		"public"."lease_recurring_charge_amounts"."amount" "AMOUNT",
  		"public"."lease_recurring_charges"."order_entry_item_id" "ITEM_ID",
  		"public"."lease_recurring_charge_amounts"."effective_date" AS "EFFECTIVE_DATE",
  		"public"."units"."property_id" "PROP_ID",
  		"public"."lease_recurring_charges"."unit_id" "UNIT_ID"
  
	FROM "public"."lease_recurring_charges"
	LEFT OUTER JOIN "public"."lease_recurring_charge_amounts"
		ON "public"."lease_recurring_charges"."id" = "public"."lease_recurring_charge_amounts"."recurring_charge_id"
 	 INNER JOIN "public"."units"
  		ON "public"."lease_recurring_charges"."unit_id" =  "public"."units"."id"
  
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
  CHARGES_TOT."ITEM_ID",
  CHARGES_TOT. "AMOUNT",
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
  	
  GROUP BY 1,2,3,4,5,6,7
	),
LEASES_CHARGES AS (
	SELECT 
  	LEASES."LEASE_ID",
  	LEASES."LEASE_NAME",
	LEASES."UNIT_ID",
	LEASES."lease_created_at" "lease_created_at", --because of difference in seconds, can't be grouped
  	LEASES."start" "start",
	LEASES."lease_end" "lease_end", --because of difference in seconds, can't be grouped
    LEASES."TENANT" "TENANT",
	CHARGES."ITEM_ID",
	CHARGES. "AMOUNT"
		
	FROM LEASES
	LEFT JOIN CHARGES
		ON  LEASES."LEASE_ID" = CHARGES."LEASE_ID"
  		AND LEASES."UNIT_ID" = CHARGES."UNIT_ID"
	GROUP BY 1,2,3,4,5,6,7,8,9
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
		LEASES_CHARGES."LEASE_ID",
  		LEASES_CHARGES."LEASE_NAME",
		UNITS."UNIT_ID",
  		UNITS."UNIT_NAME",
		LEASES_CHARGES."start",
		LEASES_CHARGES."lease_end",
   		COALESCE(LEASES_CHARGES."TENANT",'Vacant') "TENANT",
		LEASES_CHARGES."ITEM_ID",
		LEASES_CHARGES."AMOUNT"
  
	from UNITS
  	LEFT JOIN LEASES_CHARGES ON UNITS."UNIT_ID" = LEASES_CHARGES."UNIT_ID"
	group by 1,2,3,4,5,6,7,8,9
	ORDER BY LEASES_CHARGES."LEASE_ID"
	)
	
SELECT *
FROM FINAL
natural_sort(FINAL."UNIT_NAME")

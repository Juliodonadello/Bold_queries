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
		"recurring_charge_id" AS "RCHARGE_ID",
  		"public"."lease_recurring_charges"."lease_id" AS "LEASE_ID",
		"public"."lease_recurring_charge_amounts"."amount" AS "AMOUNT",
		"public"."lease_recurring_charges"."order_entry_item_id" AS "ITEM_ID",
		"public"."lease_recurring_charge_amounts"."effective_date" AS "EFFECTIVE_DATE"
  
	FROM "public"."lease_recurring_charges"
	LEFT OUTER JOIN "public"."lease_recurring_charge_amounts"
		ON "public"."lease_recurring_charges"."id" = "public"."lease_recurring_charge_amounts"."recurring_charge_id"
 	 INNER JOIN "public"."units"
  		ON "public"."lease_recurring_charges"."unit_id" =  "public"."units"."id"
  	INNER JOIN CHARGE_CONTROL
  		ON CHARGE_CONTROL. "PROP_ID" = "public"."units"."property_id"
  		AND CHARGE_CONTROL. "ITEM_ID" = "public"."lease_recurring_charges"."order_entry_item_id"
  
  	WHERE ("public"."lease_recurring_charges"."order_entry_item_id" IN ('util', 'trash', 'fixcam', 'adv', 'ele'))
	AND "public"."lease_recurring_charge_amounts"."effective_date" <= @AsOfDate
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
	SELECT 
	CHARGES_TOT."RCHARGE_ID",
	CHARGES_TOT."LEASE_ID",
	CHARGES_TOT."AMOUNT",
	CHARGES_TOT."ITEM_ID"

	FROM CHARGES_TOT
	INNER JOIN MAX_CHARGES
		ON CHARGES_TOT."RCHARGE_ID" =  MAX_CHARGES."RCHARGE_ID"
		AND CHARGES_TOT."EFFECTIVE_DATE" =  MAX_CHARGES."EFFECTIVE_DATE"
),
LEASES AS (
  SELECT "public"."leases"."id" AS "LEASE_ID",
  		"public"."leases"."name" AS "LEASE_NAME"
  
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
  		"public"."leases"."name"
	),
LEASES_CHARGES AS (
	SELECT 
  	LEASES."LEASE_ID",
  	LEASES."LEASE_NAME",
	CHARGES."ITEM_ID",
	CHARGES."AMOUNT"
		
	FROM LEASES
	LEFT JOIN CHARGES
		ON  LEASES."LEASE_ID" = CHARGES."LEASE_ID"
	GROUP BY LEASES."LEASE_ID",
  	LEASES."LEASE_NAME",
	CHARGES."ITEM_ID",
	CHARGES."AMOUNT"
	)

SELECT *
FROM LEASES_CHARGES
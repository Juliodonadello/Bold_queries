WITH CHARGES_TOT AS (
  SELECT 
		"public"."units"."property_id" AS "PROP_ID",
  		"public"."properties"."name" AS "PROP_NAME",
  		"public"."units"."name" AS "UNIT_NAME",
		"public"."units"."total_square_footage" AS "UNIT_SQ_FT",
  		"public"."lease_recurring_charges"."unit_id" AS "UNIT_ID",
 		"public"."lease_recurring_charges"."lease_id" AS "LEASE_ID",
  		"public"."lease_recurring_charges"."id" AS "RCHARGE_ID",
  		"public"."lease_recurring_charges"."order_entry_item_id" AS "ITEM_ID" ,
  		"public"."lease_recurring_charge_amounts"."effective_date" AS "EFFECTIVE_DATE",
  		"public"."lease_recurring_charge_amounts"."amount" AS "AMOUNT",
  		"public"."lease_recurring_charge_amounts"."frequency" AS "FREQUENCY",
  		"public"."lease_recurring_charge_amounts"."amount"/COALESCE("public"."units"."total_square_footage", 100000) AS "Am/SqFt"
  
	FROM "public"."lease_recurring_charges"
	INNER JOIN "public"."lease_recurring_charge_amounts"
		ON "public"."lease_recurring_charges"."id" = "public"."lease_recurring_charge_amounts"."recurring_charge_id"
 	INNER JOIN "public"."units"
  		ON "public"."lease_recurring_charges"."unit_id" =  "public"."units"."id"
 	INNER JOIN "public"."properties"
  		ON "public"."properties"."id" =  "public"."units"."property_id"
  	INNER JOIN "public"."leases"
  		ON "public"."leases"."id"  = "public"."lease_recurring_charges"."lease_id" 
  
  	WHERE --"public"."lease_recurring_charge_amounts"."effective_date" <= @AsOfDate 
  	"public"."properties"."name" IN (@Property_Name)
	AND CAST("public"."properties"."company_relation_id" AS INT)  = CAST(@REAL_COMPANY_ID AS INT)
  	AND
	 (
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
		"public"."lease_recurring_charges"."terminate_date" IS NULL 
		)
	AND (
		"public"."lease_recurring_charges"."deleted_at" >= @AsOfDate
		OR
		"public"."lease_recurring_charges"."deleted_at" IS NULL
		)
  	AND "public"."leases"."start" <= @AsOfDate 
	AND (
		"public"."leases"."end" >= @AsOfDate
		OR
		"public"."leases"."end" IS NULL
		)
),
MAX_CHARGES AS (
 	SELECT  "RCHARGE_ID" "RCHARGE_ID",
   	MAX("EFFECTIVE_DATE") "EFFECTIVE_DATE",
  	MAX('Current') as "STATUS"
 	FROM CHARGES_TOT
  	WHERE "EFFECTIVE_DATE" <= @AsOfDate 
	GROUP BY "RCHARGE_ID"
 ), 
CHARGES AS (
   select CHARGES_TOT.*,
   CASE 	WHEN MAX_CHARGES."STATUS" IS NULL AND CHARGES_TOT."EFFECTIVE_DATE" >= @AsOfDate  THEN 'Future'
			  WHEN MAX_CHARGES."STATUS" IS NULL AND CHARGES_TOT."EFFECTIVE_DATE" < @AsOfDate THEN 'Historical'
			  ELSE MAX_CHARGES."STATUS"
	  END AS "RCHARGE_STATUS"

   from CHARGES_TOT
   LEFT JOIN MAX_CHARGES 
	  ON CHARGES_TOT."RCHARGE_ID" =  MAX_CHARGES."RCHARGE_ID" 
	  AND CHARGES_TOT."EFFECTIVE_DATE" =  MAX_CHARGES."EFFECTIVE_DATE"

  ORDER BY CHARGES_TOT."RCHARGE_ID", CHARGES_TOT."EFFECTIVE_DATE" ASC
 )
 
 SELECT * 
 FROM CHARGES
 WHERE CHARGES."LEASE_ID" IS NOT NULL
 
VER FILE TODO.TXT
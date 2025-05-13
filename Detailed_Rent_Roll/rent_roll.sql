WITH CHARGES_FULL AS (
  SELECT 
		"public"."lease_recurring_charges"."id" AS "RCHARGE_ID",
  		"public"."lease_recurring_charges"."lease_id" AS "LEASE_ID",
  		"public"."lease_recurring_charge_amounts"."amount" "AMOUNT",
  		"public"."lease_recurring_charges"."order_entry_item_id" "ITEM_ID",
  		"public"."lease_recurring_charge_amounts"."effective_date" AS "EFFECTIVE_DATE",
  		"public"."lease_recurring_charge_amounts"."frequency" AS "FREQUENCY",
  		"public"."units"."property_id" "PROP_ID",
  		"public"."lease_recurring_charges"."unit_id" "UNIT_ID"
  
	FROM "public"."lease_recurring_charges"
	LEFT JOIN "public"."lease_recurring_charge_amounts"
		ON "public"."lease_recurring_charges"."id" = "public"."lease_recurring_charge_amounts"."recurring_charge_id"
 	 INNER JOIN "public"."units"
  		ON "public"."lease_recurring_charges"."unit_id" =  "public"."units"."id"
  	INNER JOIN "public"."properties"
		ON "public"."properties"."id" = "public"."units"."property_id"
  
  	WHERE  (
		--"public"."lease_recurring_charge_amounts"."deleted_at" >= @AsOfDate OR 
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
  	AND "public"."properties"."name" IN (@Property_Name)
  	AND CAST("public"."properties"."company_relation_id" AS INT) = CAST(@REAL_COMPANY_ID AS INT)
  	AND "lease_recurring_charges"."order_entry_item_id" in (@Item_Id)
  
		group by 1,2,3,4,5,6,7,8
	),
CHARGES_TOT AS (
  SELECT * 
  FROM CHARGES_FULL
  WHERE CHARGES_FULL."EFFECTIVE_DATE" <= @AsOfDate
),
MAX_CHARGES AS (
 	SELECT  "RCHARGE_ID" "RCHARGE_ID",
  	"LEASE_ID" "LEASE_ID",
   	MAX("EFFECTIVE_DATE") "EFFECTIVE_DATE"
 	FROM CHARGES_TOT
	GROUP BY "LEASE_ID","RCHARGE_ID"
 ),
CHARGES AS ( 
 SELECT CHARGES_TOT.*
 FROM CHARGES_TOT
 INNER JOIN MAX_CHARGES
 	ON CHARGES_TOT."RCHARGE_ID" =  MAX_CHARGES."RCHARGE_ID" 
	AND CHARGES_TOT."LEASE_ID" =  MAX_CHARGES."LEASE_ID"
  	AND CHARGES_TOT."EFFECTIVE_DATE" =  MAX_CHARGES."EFFECTIVE_DATE"
  GROUP BY 
  CHARGES_TOT."RCHARGE_ID",
  CHARGES_TOT."LEASE_ID",
  CHARGES_TOT."ITEM_ID",
  CHARGES_TOT. "AMOUNT",
  CHARGES_TOT."EFFECTIVE_DATE",
  CHARGES_TOT."FREQUENCY",
  CHARGES_TOT."PROP_ID",
  CHARGES_TOT."UNIT_ID"
	),
LEASES AS (
  SELECT "public"."leases"."id" AS "LEASE_ID",
  		"public"."leases"."name" AS "LEASE_NAME",
		"public"."lease_units"."unit_id" AS "UNIT_ID",
		"public"."leases"."created_at" AS "lease_created_at",
  		"public"."leases"."move_in" AS "start",
		"public"."leases"."end" AS "lease_end",
		"public"."tenants"."name"  as "TENANT"
  
  FROM "public"."leases"
	INNER JOIN "public"."lease_units"
		ON "public"."leases"."id" ="public"."lease_units"."lease_id"
	LEFT OUTER JOIN "public"."tenants"
		ON "public"."leases"."primaryTenantId" = "public"."tenants"."id"
	INNER JOIN "public"."properties"
		ON "public"."properties"."id" = "public"."leases"."property_id"

	WHERE 
		(	("public"."leases"."start" <= @AsOfDate AND "public"."leases"."end" > @AsOfDate)
  			OR ("public"."leases"."start" <= @AsOfDate AND "public"."leases"."end" IS NULL)
			OR (CAST("public"."leases"."month_to_month" AS TEXT) ='true' AND CAST("public"."leases"."status" AS TEXT) = 'current')
		)
		--AND "public"."leases"."status" = 'current'
		AND ("public"."leases"."deleted_at" >= @AsOfDate OR "public"."leases"."deleted_at" IS NULL)
		AND "public"."properties"."name" IN (@Property_Name)
  		AND CAST("public"."leases"."status" AS TEXT) IN (@Lease_Status)
		AND CASE WHEN CAST("public"."leases"."month_to_month" AS TEXT) ='true' THEN 'True' ELSE 'False' END IN (@month_to_month)
  	
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
	CHARGES. "AMOUNT",
  	CHARGES."FREQUENCY",
  	CHARGES. "EFFECTIVE_DATE"
		
	FROM LEASES
	LEFT JOIN CHARGES
		ON  LEASES."LEASE_ID" = CHARGES."LEASE_ID"
  		AND LEASES."UNIT_ID" = CHARGES."UNIT_ID"
	GROUP BY 1,2,3,4,5,6,7,8,9,10,11
	),
UNITS AS (
  SELECT 
    "public"."properties"."id" AS "PROP_ID",
    "public"."properties"."name" AS "PROP_NAME",
    "public"."units"."id" AS "UNIT_ID",
    "public"."units"."name" AS "UNIT_NAME",
  	"public"."units"."available" AS "available",
  	"public"."units"."actual_move_in_date" AS "move_in",
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
	  AND "deleted_at" IS NULL	
    ORDER BY "unit_id", "as_of_date" DESC
  ) AS uq
    ON uq."unit_id" = "public"."units"."id"
  
  WHERE "public"."properties"."deleted_at" IS NULL
    AND ("public"."units"."deleted_at" >= @AsOfDate OR "public"."units"."deleted_at" IS NULL)
    AND "public"."properties"."name" IN (@Property_Name)
    AND CAST("public"."properties"."company_relation_id" AS INT) = CAST(@REAL_COMPANY_ID AS INT)
	AND "public"."units"."status" = 'active'
  
  GROUP BY 1,2,3,4,5,6
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
		UNITS."PROP_ID",
  		UNITS."PROP_NAME",
  		UNITS."UNIT_ID",
  		UNITS."UNIT_NAME",
  		UNITS."UNIT_SQ_FT",
  		UNITS."available",
		LEASES_CHARGES."start",
		LEASES_CHARGES."lease_end",
   		COALESCE(LEASES_CHARGES."TENANT",'Vacant') "TENANT",
		LEASES_CHARGES."ITEM_ID",
		LEASES_CHARGES."AMOUNT",
  		LEASES_CHARGES."FREQUENCY",
  		LEASES_CHARGES."EFFECTIVE_DATE",
  		CASE WHEN UNITS."UNIT_SQ_FT" = 0 THEN 0 ELSE LEASES_CHARGES."AMOUNT"/UNITS."UNIT_SQ_FT" END AS "amount/Sq.Ft."
  
	from UNITS
  	LEFT JOIN LEASES_CHARGES ON UNITS."UNIT_ID" = LEASES_CHARGES."UNIT_ID"
	group by 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16
	ORDER BY LEASES_CHARGES."LEASE_ID"
	),
INCREASES AS (
  select CHARGES_FULL."RCHARGE_ID",
  		CHARGES_FULL."LEASE_ID",
  		CHARGES_FULL."AMOUNT" "NEXT_AMOUNT",
  		CHARGES_FULL."ITEM_ID",
  		CHARGES_FULL."EFFECTIVE_DATE" "NEXT_INCREASE",
  		CHARGES_FULL."PROP_ID",
  		CHARGES_FULL."UNIT_ID"
  from CHARGES_FULL
  INNER JOIN MAX_CHARGES
	  ON CHARGES_FULL."RCHARGE_ID" =  MAX_CHARGES."RCHARGE_ID" 
	  AND CHARGES_FULL."LEASE_ID" =  MAX_CHARGES."LEASE_ID"
	AND CHARGES_FULL."EFFECTIVE_DATE" >  MAX_CHARGES."EFFECTIVE_DATE"
),
COUNT_INCREASES AS (
SELECT INCREASES."PROP_ID",
  		INCREASES."LEASE_ID",
  		INCREASES."UNIT_ID",
  		INCREASES."RCHARGE_ID",
  		INCREASES."ITEM_ID",
  		COUNT(1) AS "Q_INCREASES"
FROM INCREASES
GROUP BY 1,2,3,4,5
)

SELECT FINAL.*,
	INCREASES."NEXT_INCREASE", 
	INCREASES."NEXT_AMOUNT",
	FINAL."AMOUNT"/ COALESCE(COUNT_INCREASES."Q_INCREASES",1) "AMOUNT_FIX"
FROM FINAL
LEFT JOIN INCREASES 
	ON FINAL."PROP_ID" = INCREASES."PROP_ID"
	AND FINAL."UNIT_ID" = INCREASES."UNIT_ID"
	AND FINAL."LEASE_ID" = INCREASES."LEASE_ID"
	--AND FINAL."RCHARGE_ID" = INCREASES."RCHARGE_ID"
	AND FINAL."ITEM_ID" = INCREASES."ITEM_ID"
LEFT JOIN COUNT_INCREASES
	ON COUNT_INCREASES."PROP_ID" = INCREASES."PROP_ID"
	AND COUNT_INCREASES."UNIT_ID" = INCREASES."UNIT_ID"
	AND COUNT_INCREASES."LEASE_ID" = INCREASES."LEASE_ID"
	AND COUNT_INCREASES."RCHARGE_ID" = INCREASES."RCHARGE_ID"
	AND COUNT_INCREASES."ITEM_ID" = INCREASES."ITEM_ID"

ORDER BY natural_sort(FINAL."UNIT_NAME"), FINAL."ITEM_ID", INCREASES."NEXT_INCREASE"
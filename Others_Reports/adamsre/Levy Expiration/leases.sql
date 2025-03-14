WITH CHARGE_CONTROL AS (
  	SELECT 
  			"public"."properties"."id" AS "PROP_ID",
  			"public"."property_charge_controls"."item_id" as "ITEM_ID",
  			CASE WHEN "public"."property_charge_controls"."base_rent" then 1 else 0 end as "BASE_RENT"
  		
  	FROM "public"."properties"
  	INNER JOIN "public"."property_charge_controls"
  		ON "public"."property_charge_controls"."property_id" = "public"."properties"."id"
  	
  	WHERE "public"."properties"."name" IN (@Property_Name)
	AND CAST("public"."properties"."company_relation_id" AS INT)  = CAST(@REAL_COMPANY_ID AS INT)
	),
CHARGES_TOT AS (
  SELECT 
  		"public"."lease_recurring_charges"."lease_id" AS "LEASE_ID",
		CASE WHEN CHARGE_CONTROL. "BASE_RENT" = 1 
			THEN "public"."lease_recurring_charge_amounts"."amount" ELSE 0 END AS "RENT_CHARGE",
  		CASE WHEN CHARGE_CONTROL. "BASE_RENT" = 0 
			AND "public"."lease_recurring_charges"."order_entry_item_id" = 'ELECTRIC_METERED' 
			THEN "public"."lease_recurring_charge_amounts"."amount" ELSE 0 END AS "ELEC_CHARGE",
  		CASE WHEN CHARGE_CONTROL. "BASE_RENT" = 0 
			AND ( "public"."lease_recurring_charges"."order_entry_item_id" = 'TAX BID'
				OR "public"."lease_recurring_charges"."order_entry_item_id" = 'R. E. TAX'
				)
			THEN "public"."lease_recurring_charge_amounts"."amount" ELSE 0 END AS "RETax_CHARGE",
  		CASE WHEN CHARGE_CONTROL. "BASE_RENT" = 0 
			AND "public"."lease_recurring_charges"."order_entry_item_id" != 'ELECTRIC_METERED'
			AND "public"."lease_recurring_charges"."order_entry_item_id" != 'TAX BID'
			AND "public"."lease_recurring_charges"."order_entry_item_id" != 'R. E. TAX'
			THEN "public"."lease_recurring_charge_amounts"."amount" ELSE 0 END AS "OTHER_CHARGE",

  		"public"."lease_recurring_charge_amounts"."effective_date" AS "EFFECTIVE_DATE",
  		"public"."units"."property_id" "PROP_ID",
  		"public"."lease_recurring_charges"."unit_id" "UNIT_ID",
		"public"."lease_recurring_charge_amounts"."frequency" "FREQUENCY",
		"public"."lease_recurring_charge_amounts"."recurring_charge_id" AS "RCHARGE_ID"
  
	FROM "public"."lease_recurring_charges"
	LEFT OUTER JOIN "public"."lease_recurring_charge_amounts"
		ON "public"."lease_recurring_charges"."id" = "public"."lease_recurring_charge_amounts"."recurring_charge_id"
 	 INNER JOIN "public"."units"
  		ON "public"."lease_recurring_charges"."unit_id" =  "public"."units"."id"
  	INNER JOIN CHARGE_CONTROL
  		ON CHARGE_CONTROL. "PROP_ID" = "public"."units"."property_id"
  		AND CHARGE_CONTROL. "ITEM_ID" = "public"."lease_recurring_charges"."order_entry_item_id"
  
  	WHERE "public"."lease_recurring_charge_amounts"."effective_date" <= @To_Date
	--AND "public"."lease_recurring_charge_amounts"."effective_date" >= @From_Date
	AND (
		"public"."lease_recurring_charge_amounts"."deleted_at" >= @To_Date 
		OR 
		"public"."lease_recurring_charge_amounts"."deleted_at" IS NULL
		)
	AND (
		"public"."lease_recurring_charges"."deleted_at" >= @To_Date
		OR
		"public"."lease_recurring_charges"."deleted_at" IS NULL
		)
	AND (
		"public"."lease_recurring_charge_amounts"."frequency" != 'One Time' --not a one time charge
		OR
		(
			"public"."lease_recurring_charge_amounts"."frequency" = 'One Time'
			AND	 CAST(EXTRACT(DAY FROM (@From_Date - "public"."lease_recurring_charge_amounts"."effective_date")) AS INTEGER) > 0
		  	AND CAST(EXTRACT(DAY FROM (@From_Date - "public"."lease_recurring_charge_amounts"."effective_date")) AS INTEGER) < 31
		)--one time charge with less than a month differnce
		)
),
MAX_CHARGES AS (
 	SELECT  "RCHARGE_ID" "RCHARGE_ID",
   	--MAX("EFFECTIVE_DATE") "EFFECTIVE_DATE" -- using MIN based in Lynn requests
  	MIN("EFFECTIVE_DATE") "EFFECTIVE_DATE"
 	FROM CHARGES_TOT
	WHERE "EFFECTIVE_DATE" >= @From_Date
	GROUP BY "RCHARGE_ID"
 ),
FILLER_CHARGES AS (
 	SELECT  "RCHARGE_ID" "RCHARGE_ID",
  	MAX("EFFECTIVE_DATE") "EFFECTIVE_DATE"
 	FROM CHARGES_TOT
	WHERE "EFFECTIVE_DATE" < @From_Date
	GROUP BY "RCHARGE_ID"
 ),
CHARGES_FILLER AS ( 
 SELECT 
  CHARGES_TOT."LEASE_ID",
  CHARGES_TOT."PROP_ID", 
  CHARGES_TOT."UNIT_ID",
  SUM(CASE WHEN CHARGES_TOT."FREQUENCY" = 'Annually' THEN CHARGES_TOT."RENT_CHARGE"/12 ELSE CHARGES_TOT."RENT_CHARGE" END) "RENT_CHARGE",
  SUM(CASE WHEN CHARGES_TOT."FREQUENCY" = 'Annually' THEN CHARGES_TOT."ELEC_CHARGE"/12 ELSE CHARGES_TOT."ELEC_CHARGE" END) "ELEC_CHARGE",
  SUM(CASE WHEN CHARGES_TOT."FREQUENCY" = 'Annually' THEN CHARGES_TOT."RETax_CHARGE"/12 ELSE CHARGES_TOT."RETax_CHARGE" END) "RETax_CHARGE",
  SUM(CASE WHEN CHARGES_TOT."FREQUENCY" = 'Annually' THEN CHARGES_TOT."OTHER_CHARGE"/12 ELSE CHARGES_TOT."OTHER_CHARGE" END) "OTHER_CHARGE"  

 FROM CHARGES_TOT
 INNER JOIN FILLER_CHARGES
 	ON CHARGES_TOT."RCHARGE_ID" =  FILLER_CHARGES."RCHARGE_ID" 
	AND CHARGES_TOT."EFFECTIVE_DATE" =  FILLER_CHARGES."EFFECTIVE_DATE"
 GROUP BY 1,2,3
 ),
CHARGES AS ( 
	 SELECT 
  CHARGES_TOT."LEASE_ID",
  CHARGES_TOT."PROP_ID", 
  CHARGES_TOT."UNIT_ID",
  SUM(CASE WHEN CHARGES_TOT."FREQUENCY" = 'Annually' THEN CHARGES_TOT."RENT_CHARGE"/12 ELSE CHARGES_TOT."RENT_CHARGE" END) "RENT_CHARGE",
  SUM(CASE WHEN CHARGES_TOT."FREQUENCY" = 'Annually' THEN CHARGES_TOT."ELEC_CHARGE"/12 ELSE CHARGES_TOT."ELEC_CHARGE" END) "ELEC_CHARGE",
  SUM(CASE WHEN CHARGES_TOT."FREQUENCY" = 'Annually' THEN CHARGES_TOT."RETax_CHARGE"/12 ELSE CHARGES_TOT."RETax_CHARGE" END) "RETax_CHARGE",
  SUM(CASE WHEN CHARGES_TOT."FREQUENCY" = 'Annually' THEN CHARGES_TOT."OTHER_CHARGE"/12 ELSE CHARGES_TOT."OTHER_CHARGE" END) "OTHER_CHARGE"
	FROM CHARGES_TOT
	INNER JOIN MAX_CHARGES
		ON CHARGES_TOT."RCHARGE_ID" =  MAX_CHARGES."RCHARGE_ID" 
		AND CHARGES_TOT."EFFECTIVE_DATE" =  MAX_CHARGES."EFFECTIVE_DATE"
	GROUP BY 1,2,3
),
FINAL AS (
	SELECT "public"."leases"."id",
		"public"."leases"."name" AS "LEASE_NAME",
		"public"."leases"."end" AS "LEASE_END",
		"public"."units"."name" AS "units_name",
		"public"."units"."total_square_footage" AS "total_square_footage",
		"public"."tenants"."name" AS "TENANT_NAME",
		"public"."properties"."name" AS "properties_name",
		CASE WHEN CHARGES."RENT_CHARGE" = 0 THEN CHARGES_FILLER."RENT_CHARGE"
  				ELSE CHARGES."RENT_CHARGE"
  				END AS "RENT_CHARGE",
		CASE WHEN CHARGES."ELEC_CHARGE" = 0 THEN CHARGES_FILLER."ELEC_CHARGE"
  				ELSE CHARGES."ELEC_CHARGE"
  				END AS "ELEC_CHARGE",
  		CASE WHEN CHARGES."RETax_CHARGE" = 0 THEN CHARGES_FILLER."RETax_CHARGE"
  				ELSE CHARGES."RETax_CHARGE"
  				END AS "RETax_CHARGE" ,
  		CASE WHEN CHARGES."OTHER_CHARGE" = 0 THEN CHARGES_FILLER."OTHER_CHARGE"
  				ELSE CHARGES."OTHER_CHARGE"
  				END AS "OTHER_CHARGE" 
  
	FROM "public"."leases"
	INNER  JOIN "public"."lease_units" ON "public"."leases"."id"="public"."lease_units"."lease_id"
	INNER  JOIN "public"."units" ON "public"."units"."id"="public"."lease_units"."unit_id"
	INNER  JOIN "public"."tenants" ON "public"."tenants"."id"="public"."leases"."primaryTenantId"
	INNER  JOIN "public"."properties" ON "public"."units"."property_id"="public"."properties"."id"
	LEFT JOIN CHARGES ON "public"."leases"."id" = CHARGES."LEASE_ID"
					AND  "public"."units"."id" = CHARGES."UNIT_ID"
					AND  "public"."properties"."id" = CHARGES."PROP_ID"
	LEFT JOIN CHARGES_FILLER ON "public"."leases"."id" = CHARGES_FILLER."LEASE_ID"
					AND  "public"."units"."id" = CHARGES_FILLER."UNIT_ID"
					AND  "public"."properties"."id" = CHARGES_FILLER."PROP_ID"
  					--AND  CHARGES."RCHARGE_ID" != CHARGES_FILLER."RCHARGE_ID"

	WHERE  "public"."leases"."end" <= (@To_Date) 
		AND "public"."leases"."end" >= (@From_Date) 
		AND CAST("public"."properties"."company_relation_id" AS INT) = CAST(@REAL_COMPANY_ID AS INT)
		AND "public"."properties"."name" IN (@Property_Name)

	--GROUP BY 1,2,3,4,5,6,7

	ORDER BY 7,2
),
FINAL2 AS (
SELECT "LEASE_NAME",
	"LEASE_END",
	"TENANT_NAME",
	"properties_name",
	SUM("total_square_footage") "total_square_footage",
	string_agg("units_name", ', ') "units_name",
	SUM("RENT_CHARGE") AS "RENT_CHARGE",
	SUM("ELEC_CHARGE") "ELEC_CHARGE",
	SUM("RETax_CHARGE") "RETax_CHARGE",
	SUM("OTHER_CHARGE") "OTHER_CHARGE",
    SUM("RENT_CHARGE"+"ELEC_CHARGE"+"RETax_CHARGE"+"OTHER_CHARGE") AS "TOTAL_CHARGES",
    SUM(("RENT_CHARGE"+"ELEC_CHARGE"+"RETax_CHARGE"+"OTHER_CHARGE")/ NULLIF("total_square_footage", 0)) AS "TOTAL_CHARGES_sqft"
    
FROM FINAL

GROUP BY "LEASE_NAME",
	"LEASE_END",
	"TENANT_NAME",
	"properties_name"

ORDER BY "properties_name", "LEASE_NAME"
)

SELECT "LEASE_NAME",
	"LEASE_END",
	"properties_name",
	SUM("total_square_footage") "total_square_footage",
	string_agg("TENANT_NAME", ', ') "TENANT_NAME",
	string_agg("units_name", ', ') "units_name",
	SUM("RENT_CHARGE") AS "RENT_CHARGE",
	SUM("ELEC_CHARGE") "ELEC_CHARGE",
	SUM("RETax_CHARGE") "RETax_CHARGE",
	SUM("OTHER_CHARGE") "OTHER_CHARGE",
    SUM("TOTAL_CHARGES") AS "TOTAL_CHARGES",
    SUM("TOTAL_CHARGES_sqft") AS "TOTAL_CHARGES_sqft"
    
FROM FINAL2

GROUP BY "LEASE_NAME",
	"LEASE_END",
	"properties_name"

ORDER BY "properties_name", "LEASE_NAME"
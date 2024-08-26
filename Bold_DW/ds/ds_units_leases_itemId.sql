WITH UNITS AS (
  SELECT 
		"public"."properties"."id" AS "prop_id",
		"public"."properties"."name" AS "prop_name",
		"public"."units"."id" AS "unit_id",
  		"public"."units"."name" AS "unit_name",
		"public"."units"."unit_class",
		"public"."units"."address1",
		"public"."units"."city",
		"public"."units"."state",
		"public"."units"."zip_code",
		--"public"."units"."building",
		--"public"."units"."wing",
		--"public"."units"."floor",
		"public"."units"."market_rent",
		--"public"."units"."rooms",
		--"public"."units"."bedrooms",
		--"public"."units"."bathrooms",
		--"public"."units"."actual_move_in_date",
		"public"."units"."total_square_footage",
		--"public"."units"."available",
		--"public"."units"."property_id",
		"public"."units"."country",
		"public"."units"."unit_location_id",
		"public"."units"."current_rent"
  		
	FROM   "public"."units"
	INNER JOIN "public"."properties"
		ON "public"."units"."property_id" = "public"."properties"."id"
	
  	WHERE "public"."properties"."deleted_at" IS NULL
		AND CAST("public"."properties"."company_relation_id" AS INT)  = CAST(@REAL_COMPANY_ID AS INT)
  		AND "public"."properties"."name"  IN (@Property_Name)
		AND ("public"."units"."deleted_at" IS NULL)
	
	GROUP BY 1,2,3,4,5,6,7,8,9,10,11,12,13,14--,15,16,17,18,19,20,21,22,23
	),
LEASES AS (
SELECT 
"public"."leases"."name" AS "lease_name",
"public"."leases"."status" AS "lease_status",
"public"."leases"."start",
"public"."leases"."end",
"public"."leases"."move_in",
"public"."leases"."reason_for_termination",
"public"."leases"."actual_move_out",
"public"."leases"."certificateOfOccupancy",
"public"."leases"."month_to_month",
"public"."leases"."id" as "lease_id",
"public"."tenants"."name" AS "tenant_name",
"public"."tenants"."email"  AS "tenant_email",
"public"."tenants"."phone"  AS "tenant_phone",
"public"."leases_units_units"."unitsId" AS "unit_id",
 "public"."leases"."property_id"  AS "prop_id"

FROM "public"."leases" 
INNER JOIN "public"."leases_units_units" ON "public"."leases"."id"="public"."leases_units_units"."leasesId" 
INNER JOIN "public"."properties" ON "public"."properties"."id"="public"."leases"."property_id"
INNER JOIN "public"."tenants" ON "public"."tenants"."id"="public"."leases"."primaryTenantId"

WHERE "public"."properties"."name"  IN (@Property_Name)
	AND CAST("public"."properties"."company_relation_id" AS INT)  = CAST(@REAL_COMPANY_ID AS INT)
    AND ( ("public"."leases"."start" <= @AsOfDate AND "public"."leases"."end" >= @AsOfDate)
  	   			OR ("public"."leases"."start" <= @AsOfDate AND "public"."leases"."end" IS NULL) )
	AND CAST("public"."leases"."status"AS TEXT) IN (@Lease_Status)
	AND ("public"."leases"."deleted_at" >= @AsOfDate OR "public"."leases"."deleted_at" IS NULL)
),
CHARGES_TOT AS (
  SELECT 
		MAX("recurring_charge_id") AS "RCHARGE_ID",
  		"public"."lease_recurring_charges"."lease_id" AS "LEASE_ID",
  		"public"."lease_recurring_charge_amounts"."effective_date" AS "EFFECTIVE_DATE",
  		"public"."lease_recurring_charge_amounts"."amount" AS "AMOUNT",
  		"public"."units"."property_id" "PROP_ID",
  		"public"."lease_recurring_charges"."unit_id" "UNIT_ID",
  		"public"."lease_recurring_charges"."order_entry_item_id" AS "ITEM_ID",
		"public"."lease_recurring_charge_amounts"."frequency" "FREQUENCY"
  
	FROM "public"."lease_recurring_charges"
	INNER JOIN "public"."lease_recurring_charge_amounts"
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
  	AND "public"."lease_recurring_charges"."order_entry_item_id" IN (@Item_Id)
		
	GROUP BY 
		 "public"."lease_recurring_charges"."lease_id",
  		"public"."lease_recurring_charge_amounts"."effective_date",
  		"public"."lease_recurring_charge_amounts"."amount",
  		"public"."units"."property_id",
  		"public"."lease_recurring_charges"."unit_id",
  		"public"."lease_recurring_charges"."order_entry_item_id",
		"public"."lease_recurring_charge_amounts"."frequency"
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
  CHARGES_TOT."EFFECTIVE_DATE",
   CHARGES_TOT."AMOUNT",
   CHARGES_TOT."ITEM_ID",
  CHARGES_TOT."PROP_ID",
  CHARGES_TOT."UNIT_ID",
  CHARGES_TOT."FREQUENCY"
) 

SELECT
UNITS."prop_name",
UNITS."unit_name",
UNITS."unit_class",
UNITS."address1",
UNITS."city",
UNITS."state",
UNITS."zip_code",
UNITS."market_rent",
UNITS."total_square_footage",
UNITS."country",
UNITS."unit_location_id",
UNITS."current_rent",
LEASES."lease_name",
LEASES."lease_status",
LEASES."start",
LEASES."end",
LEASES."move_in",
LEASES."reason_for_termination",
LEASES."actual_move_out",
LEASES."certificateOfOccupancy",
LEASES."month_to_month",
LEASES."tenant_name",
LEASES."tenant_email",
LEASES."tenant_phone",
CHARGES."EFFECTIVE_DATE",
CHARGES."AMOUNT",
CHARGES."ITEM_ID",
CHARGES."FREQUENCY"

FROM UNITS
INNER JOIN LEASES ON LEASES."prop_id" = UNITS."prop_id"
								 	AND LEASES."unit_id" = UNITS."unit_id"
INNER JOIN CHARGES ON CHARGES."PROP_ID" = LEASES."prop_id"
								 		AND CHARGES."UNIT_ID" = LEASES."unit_id"
										AND CHARGES."LEASE_ID" = LEASES."lease_id"
							


 
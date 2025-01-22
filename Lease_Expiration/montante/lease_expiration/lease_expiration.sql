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
		MAX("recurring_charge_id") AS "RCHARGE_ID",
  		"public"."lease_recurring_charges"."lease_id" AS "LEASE_ID",
		CASE WHEN CHARGE_CONTROL. "BASE_RENT" = 1 THEN "public"."lease_recurring_charge_amounts"."amount" ELSE 0 END AS "RENT_CHARGE",
  		"public"."lease_recurring_charge_amounts"."effective_date" AS "EFFECTIVE_DATE",
  		"public"."units"."property_id" "PROP_ID",
  		"public"."lease_recurring_charges"."unit_id" "UNIT_ID",
		"public"."lease_recurring_charge_amounts"."frequency" "FREQUENCY"
  
	FROM "public"."lease_recurring_charges"
	LEFT OUTER JOIN "public"."lease_recurring_charge_amounts"
		ON "public"."lease_recurring_charges"."id" = "public"."lease_recurring_charge_amounts"."recurring_charge_id"
 	 INNER JOIN "public"."units"
  		ON "public"."lease_recurring_charges"."unit_id" =  "public"."units"."id"
  	INNER JOIN CHARGE_CONTROL
  		ON CHARGE_CONTROL. "PROP_ID" = "public"."units"."property_id"
  		AND CHARGE_CONTROL. "ITEM_ID" = "public"."lease_recurring_charges"."order_entry_item_id"
  
  	WHERE "public"."lease_recurring_charge_amounts"."effective_date" <= @ToDate
	AND (
		"public"."lease_recurring_charge_amounts"."deleted_at" >= @FromDate 
		OR 
		"public"."lease_recurring_charge_amounts"."deleted_at" IS NULL
		)
	AND (
		"public"."lease_recurring_charges"."deleted_at" >= @FromDate
		OR
		"public"."lease_recurring_charges"."deleted_at" IS NULL
		)
	AND (
		"public"."lease_recurring_charge_amounts"."frequency" != 'One Time' --not a one time charge
		OR
		(
			"public"."lease_recurring_charge_amounts"."frequency" = 'One Time'
			AND	 CAST(EXTRACT(DAY FROM (@FromDate - "public"."lease_recurring_charge_amounts"."effective_date")) AS INTEGER) > 0
		  	AND CAST(EXTRACT(DAY FROM (@FromDate - "public"."lease_recurring_charge_amounts"."effective_date")) AS INTEGER) < 31
		)--one time charge with less than a month differnce with respect to the fromDate. This is suposse to be applied with an AsOfDate.
		)
	AND (	
	  	"public"."lease_recurring_charges"."terminate_date" >= @FromDate
		OR
		"public"."lease_recurring_charges"."terminate_date" is NULL 
		)
		
	GROUP BY 
		"public"."lease_recurring_charges"."lease_id",
		CASE WHEN CHARGE_CONTROL. "BASE_RENT" = 1 THEN "public"."lease_recurring_charge_amounts"."amount" ELSE 0 END ,
		"public"."lease_recurring_charge_amounts"."effective_date",
		"public"."units"."property_id",
		"public"."lease_recurring_charges"."unit_id",
		"public"."lease_recurring_charge_amounts"."frequency"
	),
MAX_CHARGES AS (
 	SELECT  "RCHARGE_ID" "RCHARGE_ID",
   	MAX("EFFECTIVE_DATE") "EFFECTIVE_DATE"
 	FROM CHARGES_TOT
	GROUP BY "RCHARGE_ID"
 ),
CHARGES AS ( 
    SELECT
    CHARGES_TOT."LEASE_ID" "LEASE_ID",
    CHARGES_TOT."EFFECTIVE_DATE",
    CHARGES_TOT."PROP_ID" "PROP_ID",
    CHARGES_TOT."UNIT_ID" "UNIT_ID",
    CHARGES_TOT."FREQUENCY",
    SUM(CHARGES_TOT."RENT_CHARGE") AS "RENT_CHARGE"

    FROM CHARGES_TOT
    INNER JOIN MAX_CHARGES
        ON CHARGES_TOT."RCHARGE_ID" =  MAX_CHARGES."RCHARGE_ID" 
        AND CHARGES_TOT."EFFECTIVE_DATE" =  MAX_CHARGES."EFFECTIVE_DATE"

    GROUP BY 
    1,2,3,4,5
),
SQ_FT_TEMP AS
(
	SELECT
		"public"."properties"."id" AS "PROP_ID",
		SUM("public"."units"."total_square_footage") AS "TOT_SQ_FT"
	 
	FROM   "public"."units"
	INNER JOIN "public"."properties"
		ON "public"."units"."property_id" = "public"."properties"."id"
  
	 WHERE "public"."units"."deleted_at" IS NULL
  	and "public"."properties"."deleted_at" IS NULL
  
	GROUP BY  "public"."properties"."id" 
)

 SELECT "public"."leases"."id",
	"public"."leases"."name",
	"public"."leases"."status",
	"public"."leases"."start",
	"public"."leases"."end",
	"public"."lease_units"."lease_id",
	"public"."lease_units"."unit_id",
	"public"."units"."id" AS "units_id",
	"public"."units"."name" AS "units_name",
	"public"."units"."city",
	"public"."units"."total_square_footage",
	"public"."tenants"."id" AS "tenants_id",
	"public"."tenants"."name" AS "tenants_name",
	"public"."properties"."id" AS "properties_id",
	"public"."properties"."name" AS "properties_name",
	DATE_PART('year' , "end") AS "EndDate_YEAR",
	SQ_FT_TEMP."TOT_SQ_FT" as "TOT_SQ_FT",
    CHARGES."RENT_CHARGE" as "RENT_CHARGE"


FROM "public"."leases"
INNER  JOIN "public"."lease_units" ON "public"."leases"."id"="public"."lease_units"."lease_id"
INNER  JOIN "public"."units" ON "public"."units"."id"="public"."lease_units"."unit_id"
INNER  JOIN "public"."tenants" ON "public"."tenants"."id"="public"."leases"."primaryTenantId"
INNER  JOIN "public"."properties" ON "public"."units"."property_id"="public"."properties"."id"
INNER JOIN SQ_FT_TEMP ON "public"."properties"."id" = SQ_FT_TEMP."PROP_ID"
LEFT JOIN CHARGES  ON CHARGES."PROP_ID" = "public"."properties"."id"
                    AND CHARGES."LEASE_ID" = "public"."leases"."id"
                    AND CHARGES."UNIT_ID" = "public"."units"."id"

WHERE  "public"."leases"."end" IS NOT NULL
    AND CAST("public"."properties"."company_relation_id" AS INT) = CAST(@REAL_COMPANY_ID AS INT)
    AND "public"."properties"."name" IN (@Property_Name)
  WITH LEASES_TOT AS (
	SELECT "public"."leases"."id" AS "LEASE_ID",
		  "public"."leases_units_units"."unitsId" AS "UNIT_ID",
		  "public"."leases"."created_at" AS "lease_created_at",
		  "public"."leases"."start" AS "start",
		  "public"."leases"."end" AS "lease_end",
		  "public"."leases"."name" AS "lease_name",
		  CASE WHEN "public"."leases"."status" = 'current' THEN 'OCCUPIED' ELSE 'VACANT' END AS "LEASE_STATUS",
		  CASE WHEN "public"."lease_deposits"."id" IS NULL THEN 'NO' ELSE 'YES' END AS "DEPOSIT",
		  CASE WHEN  "public"."lease_deposits"."refundable" = 'true' THEN 'YES' ELSE 'NO' END AS "REFUNDABLE",
		  "public"."tenants"."name"  as "TENANT"

	FROM "public"."leases"
	  INNER JOIN "public"."leases_units_units"
		  ON "public"."leases"."id" ="public"."leases_units_units"."leasesId"
	  LEFT OUTER JOIN "public"."lease_deposits"
		  ON "public"."leases"."id" = "public"."lease_deposits"."lease_id" 
	  LEFT OUTER JOIN "public"."tenants"
		  ON "public"."leases"."primaryTenantId" = "public"."tenants"."id" 

	  WHERE ("public"."leases"."start" <= @AsOfDate AND "public"."leases"."end" > @AsOfDate)
		  OR ("public"."leases"."start" <= @AsOfDate AND "public"."leases"."end" IS NULL)
  ),
   MAX_LEASES AS (
	  SELECT MAX( "LEASE_ID") "LEASE_ID",
	  MAX("start") "start",
	  "UNIT_ID" as "UNIT_ID"
	  FROM LEASES_TOT
	  GROUP BY "UNIT_ID" --agrupo por unit y tomo max lease_id ya que parto de LEASES_TOT que filtró el AsOfDate.
   ),
   CURRENT_LEASES AS ( 
   SELECT  LEASES_TOT.*
   FROM  LEASES_TOT
   INNER JOIN MAX_LEASES
	  ON  LEASES_TOT."LEASE_ID" =  MAX_LEASES."LEASE_ID" 
	  AND  LEASES_TOT."start" =  MAX_LEASES."start"
	 AND  LEASES_TOT."UNIT_ID" =  MAX_LEASES."UNIT_ID"
  ),
  LEASES AS (
  SELECT 
	  CURRENT_LEASES."LEASE_ID",
	  CURRENT_LEASES."UNIT_ID",
	  MIN(CURRENT_LEASES."lease_created_at") "lease_created_at", --because of difference in seconds, can't be grouped
	  MIN(CURRENT_LEASES."start") "start",
	  MAX(CURRENT_LEASES."lease_end") "lease_end", --because of difference in seconds, can't be grouped
	  MAX(CURRENT_LEASES."lease_name") "lease_name",
	  CURRENT_LEASES."TENANT",
	  COALESCE(MAX(CASE WHEN CURRENT_LEASES."LEASE_STATUS" = 'OCCUPIED' THEN 'OCCUPIED' END), MAX(CURRENT_LEASES."LEASE_STATUS")) AS "LEASE_STATUS",
	  COALESCE(MAX(CASE WHEN CURRENT_LEASES."DEPOSIT" = 'YES' THEN 'YES' END), MAX(CURRENT_LEASES."DEPOSIT")) AS "DEPOSIT",
	  COALESCE(MAX(CASE WHEN CURRENT_LEASES."REFUNDABLE" = 'true' THEN 'YES' END), MAX(CURRENT_LEASES."REFUNDABLE")) AS "REFUNDABLE"

  FROM CURRENT_LEASES
  GROUP BY CURRENT_LEASES."LEASE_ID",
	  CURRENT_LEASES."UNIT_ID",
	  CURRENT_LEASES."TENANT"

  ),
CHARGES_TOT AS (
  SELECT 
		"recurring_charge_id" AS "RCHARGE_ID",
  		"public"."lease_recurring_charges"."lease_id" AS "LEASE_ID",
  		CASE WHEN "public"."lease_recurring_charges"."order_entry_item_id" LIKE '%RENT%' OR  "public"."lease_recurring_charges"."order_entry_item_id" LIKE '%Rent%' THEN "public"."lease_recurring_charge_amounts"."amount" ELSE 0 END AS "RENT_CHARGE",
		CASE WHEN "public"."lease_recurring_charges"."order_entry_item_id"  NOT LIKE '%RENT%' AND "public"."lease_recurring_charges"."order_entry_item_id"  NOT LIKE '%Rent%'  THEN "public"."lease_recurring_charge_amounts"."amount" ELSE 0 END AS "OTHER_CHARGE",
		"public"."lease_recurring_charge_amounts"."effective_date" AS "EFFECTIVE_DATE"
  
	FROM "public"."lease_recurring_charges"
	LEFT OUTER JOIN "public"."lease_recurring_charge_amounts"
		ON "public"."lease_recurring_charges"."id" = "public"."lease_recurring_charge_amounts"."recurring_charge_id"
	
  	WHERE "public"."lease_recurring_charge_amounts"."effective_date" <= @AsOfDate
  
  group by "recurring_charge_id" ,
  				"public"."lease_recurring_charges"."lease_id",
  				CASE WHEN "public"."lease_recurring_charges"."order_entry_item_id" LIKE '%RENT%' OR  "public"."lease_recurring_charges"."order_entry_item_id" LIKE '%Rent%' THEN "public"."lease_recurring_charge_amounts"."amount" ELSE 0 END,
				CASE WHEN "public"."lease_recurring_charges"."order_entry_item_id"  NOT LIKE '%RENT%' AND "public"."lease_recurring_charges"."order_entry_item_id"  NOT LIKE '%Rent%'  THEN "public"."lease_recurring_charge_amounts"."amount" ELSE 0 END,
				"public"."lease_recurring_charge_amounts"."effective_date"
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
),
UNITS AS 
(
  SELECT 
		"public"."properties"."id" AS "PROP_ID",
		"public"."properties"."name" AS "PROP_NAME",
		"public"."units"."id" AS "UNIT_ID",
  		"public"."units"."name" AS "UNIT_NAME",
  		"public"."units"."unit_class" AS "UNIT_CLASS",
  		"public"."unit_square_footage_items"."square_footage_type" AS "SQ_FT_TYPE",
		MAX("public"."units"."total_square_footage") AS "UNIT_SQ_FT"
  		
	FROM   "public"."units"
	INNER JOIN "public"."properties"
		ON "public"."units"."property_id" = "public"."properties"."id"
  	LEFT JOIN "public"."unit_square_footage_items"
		ON "public"."unit_square_footage_items"."unit_id" = "public"."units"."id"
	
  	WHERE "public"."units"."deleted_at" IS NULL
  	and "public"."properties"."deleted_at" IS NULL
  
	GROUP BY 
		"public"."properties"."id",
		"public"."properties"."name",
		"public"."units"."id",
  		"public"."units"."name",
  		"public"."unit_square_footage_items"."square_footage_type"
),
FINAL AS (
select 
	LEASES."LEASE_ID",
	LEASES."UNIT_ID",
	LEASES."lease_created_at", 
  	LEASES."start",
	LEASES."lease_end",
  	LEASES."lease_name",
  	LEASES."TENANT",
  	LEASES."LEASE_STATUS",
  	LEASES."DEPOSIT",
  	LEASES."REFUNDABLE",
  	SUM(CHARGES."RENT_CHARGE") "RENT_CHARGE"
  
from LEASES
LEFT JOIN CHARGES
	ON  LEASES."LEASE_ID" = CHARGES."LEASE_ID"
group by LEASES."LEASE_ID",
	LEASES."UNIT_ID",
	LEASES."lease_created_at", 
  	LEASES."start",
	LEASES."lease_end",
  	LEASES."lease_name",
  	LEASES."TENANT",
  	LEASES."LEASE_STATUS",
  	LEASES."DEPOSIT",
  	LEASES."REFUNDABLE"
ORDER BY LEASES."LEASE_ID"
)

SELECT 
	UNITS."PROP_ID",
	UNITS."PROP_NAME",
	UNITS."UNIT_ID",
	UNITS."UNIT_NAME" "UNIT_NAME" ,
	--CASE WHEN FINAL."LEASE_STATUS" = 'OCCUPIED' THEN 'OCCUPIED' ELSE 'VACANT' END AS  "LEASE_STATUS",
	CASE WHEN FINAL."lease_created_at" IS NOT NULL THEN 'OCCUPIED' ELSE 'VACANT' END AS  "LEASE_STATUS",
	FINAL."TENANT",
	FINAL."lease_created_at" "lease_created_at",
	FINAL."start" "lease_start",
	FINAL."lease_end",	
	FINAL."lease_name",
	UNITS."UNIT_SQ_FT" "UNIT_SQ_FT",
	CASE WHEN FINAL."lease_created_at" IS NOT NULL THEN UNITS."UNIT_SQ_FT" ELSE NULL END AS  "OCCUPIED_UNIT_SQ_FT",
	CASE WHEN FINAL."lease_created_at" IS NULL THEN UNITS."UNIT_SQ_FT" ELSE NULL END AS  "VACCANT_UNIT_SQ_FT",
	CASE WHEN SQ_FT_TEMP."TOT_SQ_FT" = 0 THEN 0 ELSE UNITS."UNIT_SQ_FT" / SQ_FT_TEMP."TOT_SQ_FT" * 100 END AS "Pct of Property",
	CASE WHEN SQ_FT_TEMP."TOT_SQ_FT" = 0 OR FINAL."lease_created_at" IS NULL THEN 0 ELSE UNITS."UNIT_SQ_FT" / SQ_FT_TEMP."TOT_SQ_FT" * 100 END AS "OCC Pct of Property",
	CASE WHEN SQ_FT_TEMP."TOT_SQ_FT" = 0 OR FINAL."lease_created_at" IS NOT NULL THEN 0 ELSE UNITS."UNIT_SQ_FT" / SQ_FT_TEMP."TOT_SQ_FT" * 100 END AS "VAC Pct of Property",
	FINAL."DEPOSIT",
	FINAL."REFUNDABLE",
	"public"."company_accounts"."company_id" "COMPANY_ID",
	FINAL."RENT_CHARGE",
	UNITS."SQ_FT_TYPE",
	UNITS."UNIT_CLASS"
	
FROM UNITS
LEFT JOIN SQ_FT_TEMP
	ON UNITS."PROP_ID" = SQ_FT_TEMP."PROP_ID"
LEFT JOIN FINAL
	ON UNITS."UNIT_ID" = FINAL."UNIT_ID"
INNER JOIN "public"."properties"
		ON UNITS."PROP_ID" = "public"."properties"."id"
INNER JOIN "public"."company_accounts"
		ON "public"."properties"."company_relation_id" = "public"."company_accounts"."id"
		
where  UNITS."PROP_NAME" IN (@Property_Name)
	AND UNITS."SQ_FT_TYPE" IN (@Sqft_Type)

order by "PROP_NAME"
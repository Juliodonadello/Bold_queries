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
		"public"."lease_recurring_charge_amounts"."recurring_charge_id" AS "RCHARGE_ID",
  		"public"."lease_recurring_charges"."lease_id" AS "LEASE_ID",
		CASE WHEN CHARGE_CONTROL. "BASE_RENT" = 1 THEN "public"."lease_recurring_charge_amounts"."amount" ELSE 0 END AS "RENT_CHARGE",
  		CASE WHEN "public"."lease_recurring_charges"."order_entry_item_id" = 'cam' THEN "public"."lease_recurring_charge_amounts"."amount" ELSE 0 END AS "CAM_CHARGE",
		CASE WHEN "public"."lease_recurring_charges"."order_entry_item_id" = 'ret' THEN "public"."lease_recurring_charge_amounts"."amount" ELSE 0 END AS "RET_CHARGE",
		CASE WHEN "public"."lease_recurring_charges"."order_entry_item_id" = 'ins' THEN "public"."lease_recurring_charge_amounts"."amount" ELSE 0 END AS "INS_CHARGE",
		CASE WHEN CHARGE_CONTROL. "BASE_RENT" != 1
					AND "public"."lease_recurring_charges"."order_entry_item_id" != 'cam'
					AND "public"."lease_recurring_charges"."order_entry_item_id" != 'ret'
					AND "public"."lease_recurring_charges"."order_entry_item_id" != 'ins'
					THEN "public"."lease_recurring_charge_amounts"."amount" ELSE 0 END AS "OTHER_CHARGE",
  		"public"."lease_recurring_charge_amounts"."effective_date" AS "EFFECTIVE_DATE",
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
	CHARGES_TOT."RENT_CHARGE",
	CHARGES_TOT."CAM_CHARGE",
	CHARGES_TOT."RET_CHARGE",
	CHARGES_TOT."INS_CHARGE",
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
		"public"."leases"."notice_termination" AS "notice_termination",
		CASE WHEN "public"."leases"."status" = 'current' THEN 'OCCUPIED' ELSE 'VACANT' END AS "LEASE_STATUS",
		"public"."tenants"."name"  as "TENANT"
  
  FROM "public"."leases"
	INNER JOIN "public"."lease_units"
		ON "public"."leases"."id" ="public"."lease_units"."lease_id"
	LEFT JOIN "public"."tenants"
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
		"public"."leases"."notice_termination",
		CASE WHEN "public"."leases"."status" = 'current' THEN 'OCCUPIED' ELSE 'VACANT' END ,
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
	MAX(LEASES."notice_termination") "notice_termination",
  	LEASES."TENANT",
  	COALESCE(MAX(CASE WHEN LEASES."LEASE_STATUS" = 'OCCUPIED' THEN 'OCCUPIED' END), MAX(LEASES."LEASE_STATUS")) AS "LEASE_STATUS",
  	SUM(CHARGES."RENT_CHARGE") "RENT_CHARGE",
  	SUM(CHARGES."CAM_CHARGE") "CAM_CHARGE",
	SUM(CHARGES."RET_CHARGE") "RET_CHARGE",
	SUM(CHARGES."INS_CHARGE") "INS_CHARGE",
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
		"notice_termination",
		"TENANT",
		"LEASE_STATUS",
		"RENT_CHARGE",
		"CAM_CHARGE",
		"RET_CHARGE",
		"INS_CHARGE",
		"OTHER_CHARGE"

	from LEASES_CHARGES
	group by 
		"LEASE_ID",
  		"LEASE_NAME",
		"UNIT_ID",
		"lease_created_at", 
		"start",
		"lease_end",
		"notice_termination",
		"TENANT",
		"LEASE_STATUS",
		"RENT_CHARGE",
		"CAM_CHARGE",
		"RET_CHARGE",
		"INS_CHARGE",
		"OTHER_CHARGE"

	ORDER BY LEASES_CHARGES."LEASE_ID"
	)

SELECT 
UNITS."PROP_ID",
UNITS."PROP_NAME",
UNITS."UNIT_ID",
UNITS."UNIT_NAME" "UNIT_NAME" ,
FINAL."LEASE_ID",
FINAL."LEASE_NAME",
CASE WHEN FINAL."lease_created_at" IS NOT NULL THEN 'OCCUPIED' ELSE 'VACANT' END AS  "LEASE_STATUS", -- esto se hizo porque los status future se deben ver como Occupied si el asofdate coincide
FINAL."TENANT",
FINAL."start" "lease_start",
FINAL."lease_end",
FINAL."notice_termination",
UNITS."UNIT_SQ_FT" "UNIT_SQ_FT",
CASE 	WHEN SQ_FT_TEMP."TOT_SQ_FT" = 0 THEN 0 
			ELSE UNITS."UNIT_SQ_FT" / SQ_FT_TEMP."TOT_SQ_FT" * 100 
	END AS "Pct of Property",
FINAL."RENT_CHARGE" "RENT_AMOUNT",
FINAL."CAM_CHARGE" "CAM_CHARGE",
FINAL."RET_CHARGE" "RET_CHARGE",
FINAL."INS_CHARGE" "INS_CHARGE",
FINAL."OTHER_CHARGE" "OTHER_CHARGE",
CASE  WHEN UNITS."UNIT_SQ_FT" = 0 THEN 0
		WHEN FINAL."RENT_CHARGE" = 0 THEN 0
		ELSE FINAL."RENT_CHARGE"/UNITS."UNIT_SQ_FT"
	END AS "Rent/Sq.Ft" 

FROM UNITS
LEFT JOIN SQ_FT_TEMP
	ON UNITS."PROP_ID" = SQ_FT_TEMP."PROP_ID"
LEFT JOIN FINAL
	ON UNITS."UNIT_ID" = FINAL."UNIT_ID"
INNER JOIN "public"."properties"
	ON UNITS."PROP_ID" = "public"."properties"."id"

where  "PROP_NAME" IN (@Property_Name)
	AND CAST("public"."properties"."company_relation_id" AS INT) = CAST(@REAL_COMPANY_ID AS INT)

--group by 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28

order by "PROP_NAME", UNITS."UNIT_NAME"
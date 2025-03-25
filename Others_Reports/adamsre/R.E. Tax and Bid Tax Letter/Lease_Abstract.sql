WITH CHARGES_TOT AS (
  SELECT 
  		"public"."properties"."name" AS "PROP_NAME",
  		"public"."units"."name" AS "UNIT_NAME",
 		"public"."lease_recurring_charges"."lease_id" AS "LEASE_ID",
  		CAST("public"."leases"."name" AS TEXT) AS "LEASE_NAME",
  		"public"."lease_recurring_charges"."order_entry_item_id" AS "ITEM_ID" ,
  		"public"."lease_recurring_charge_amounts"."effective_date" AS "EFFECTIVE_DATE",
  		"public"."lease_recurring_charge_amounts"."amount" AS "AMOUNT"
  
	FROM "public"."lease_recurring_charges"
	INNER JOIN "public"."lease_recurring_charge_amounts"
		ON "public"."lease_recurring_charges"."id" = "public"."lease_recurring_charge_amounts"."recurring_charge_id"
 	INNER JOIN "public"."units"
  		ON "public"."lease_recurring_charges"."unit_id" =  "public"."units"."id"
 	INNER JOIN "public"."properties"
  		ON "public"."properties"."id" =  "public"."units"."property_id"
  	INNER JOIN "public"."leases"
  		ON "public"."leases"."id"  = "public"."lease_recurring_charges"."lease_id" 
  
  	WHERE "public"."properties"."name" IN (@Property_Name)
	AND CAST("public"."properties"."company_relation_id" AS INT)  = CAST(@REAL_COMPANY_ID AS INT)
  	AND CASE 
  					WHEN "public"."leases"."status" = 'current' THEN 'Current'
					WHEN "public"."leases"."status" = 'canceled' THEN 'Canceled'
					WHEN "public"."leases"."status" = 'terminated' THEN 'Terminated'
					WHEN "public"."leases"."status" = 'future' THEN 'Future'
					ELSE 'null' 
			END  IN (@Lease_Status)
  	--AND CAST("public"."leases"."name" AS TEXT) IN (cast(@Lease_Name as text))
  	--AND CAST("public"."leases"."name" AS TEXT) IN  (CAST(@Lease_Name AS TEXT))
  	AND CAST("public"."leases"."name" AS TEXT) IN  (@Lease_Name) --('02401000')
  	AND
	 (
		"public"."lease_recurring_charge_amounts"."deleted_at" >= @AsOfDate 
		OR "public"."lease_recurring_charge_amounts"."deleted_at" IS NULL
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
		OR "public"."lease_recurring_charges"."terminate_date" IS NULL 
		)
	AND (
		"public"."lease_recurring_charges"."deleted_at" >= @AsOfDate
		OR "public"."lease_recurring_charges"."deleted_at" IS NULL
		)
	AND (
		"public"."leases"."end" >= @AsOfDate
		OR "public"."leases"."end" IS NULL
		)
  	AND ( 
	  "public"."lease_recurring_charges"."order_entry_item_id" = 'R. E. TAX'
		OR "public"."lease_recurring_charges"."order_entry_item_id" = 'TAX BID' )
),
SECOND_AUX AS (
    SELECT 
        "PROP_NAME",
  		"UNIT_NAME",
        "LEASE_ID",
  		"LEASE_NAME",
        "ITEM_ID",
        "EFFECTIVE_DATE",
  		--TO_CHAR("EFFECTIVE_DATE", 'Month YYYY') AS "formatted_date",
  		--(@AsOfDate + INTERVAL '1 month')::DATE - EXTRACT(DAY FROM @AsOfDate)::INTEGER + 1 AS "formatted_date",
        "AMOUNT",
        ROW_NUMBER() OVER (
            PARTITION BY "PROP_NAME", "LEASE_ID", "ITEM_ID" 
            ORDER BY "EFFECTIVE_DATE" DESC
        ) AS "ROW_NUM"
    FROM CHARGES_TOT
),
RECOVERY as (
  SELECT "public"."lease_recurring_charges"."id" "RCHARGE_ID",
"public"."lease_recurring_charges"."lease_id" "LEASE_ID",
"public"."lease_recovery_control"."id" "lease_recovery_control_ID",
"public"."lease_recovery_control"."name" AS "NAME",
"public"."lease_recovery_control"."process_recovery_month_frequency",
"public"."lease_recovery_control"."calculation_control_base_year",
"public"."lease_recovery_control"."calculation_control_base_amount",
"public"."recovery_control_expense_category"."expense_category",
"public"."recovery_control_expense_category"."manual_percent",
--"public"."lease_recovery_control"."recovery_from" AS "formatted_date",
CAST(CASE 	WHEN @AsOfDate <= CAST('2024/12/31' AS DATE) THEN '07/01/2024'
  			WHEN @AsOfDate BETWEEN CAST('2025/01/01' AS DATE)  AND CAST('2025/01/07' AS DATE)  THEN '01/01/2025'
  			WHEN @AsOfDate >= CAST('07/01/2025' AS DATE) THEN '07/01/2025'
  			ELSE '01/01/2025'
  END AS DATE) AS "formatted_date",
"public"."lease_recovery_control"."recovery_to" AS "recovery_to"

FROM "public"."lease_recovery_control" 
LEFT JOIN "public"."recovery_control_expense_category" 
	ON "public"."lease_recovery_control"."id"="public"."recovery_control_expense_category"."lease_recovery_control_id"
INNER JOIN "public"."lease_recurring_charges" 
	ON "public"."lease_recurring_charges"."recovery_control_id"="public"."lease_recovery_control"."id"
),
RECOVERY_FINAL AS (
  select
    "LEASE_ID",
    MAX(CASE WHEN "NAME" = 'R. E. TAX' THEN "process_recovery_month_frequency" END) AS "RETAX_process_frequency",
    MAX(CASE WHEN "NAME" = 'R. E. TAX' THEN "calculation_control_base_year" END) AS "RETAX_base_year",
    MAX(CASE WHEN "NAME" = 'R. E. TAX' THEN "calculation_control_base_amount" END) AS "RETAX_base_amount",
    MAX(CASE WHEN "NAME" = 'R. E. TAX' THEN "manual_percent" END) AS "RETAX_manual_percent",
  	MAX(CASE WHEN "NAME" = 'R. E. TAX' THEN "formatted_date" END) AS "RETAX_formatted_date",
    
    MAX(CASE WHEN "NAME" = 'TAX BID' THEN "process_recovery_month_frequency" END) AS "TAXBID_process_frequency",
    MAX(CASE WHEN "NAME" = 'TAX BID' THEN "calculation_control_base_year" END) AS "TAXBID_base_year",
    MAX(CASE WHEN "NAME" = 'TAX BID' THEN "calculation_control_base_amount" END) AS "TAXBID_base_amount",
    MAX(CASE WHEN "NAME" = 'TAX BID' THEN "manual_percent" END) AS "TAXBID_manual_percent",
  	MAX(CASE WHEN "NAME" = 'TAX BID' THEN "formatted_date" END) AS "TAXBID_formatted_date"
  
FROM RECOVERY
GROUP BY 1
)

SELECT 
    SECOND_AUX."PROP_NAME",
  	SECOND_AUX."UNIT_NAME",
    SECOND_AUX."LEASE_ID",
	SECOND_AUX."LEASE_NAME",
	
   	MAX(CASE WHEN SECOND_AUX."ITEM_ID" = 'R. E. TAX' AND SECOND_AUX."ROW_NUM" = 1 THEN SECOND_AUX."AMOUNT" END) AS "RETAX_amount_new",
    MAX(CASE WHEN SECOND_AUX."ITEM_ID" = 'R. E. TAX' AND SECOND_AUX."ROW_NUM" = 2 THEN SECOND_AUX."AMOUNT" END) AS "RETAX_amount_old",
	MAX(CASE WHEN SECOND_AUX."ITEM_ID" = 'R. E. TAX' THEN RECOVERY_FINAL."RETAX_formatted_date" END) AS "RETAX_formatted_date",
	
    MAX(CASE WHEN SECOND_AUX."ITEM_ID" = 'TAX BID' AND SECOND_AUX."ROW_NUM" = 1 THEN SECOND_AUX."AMOUNT" END) AS "TAXBID_amount_new",
    MAX(CASE WHEN SECOND_AUX."ITEM_ID" = 'TAX BID' AND SECOND_AUX."ROW_NUM" = 2 THEN SECOND_AUX."AMOUNT" END) AS "TAXBID_amount_old",
	MAX(CASE WHEN SECOND_AUX."ITEM_ID" = 'TAX BID' THEN RECOVERY_FINAL."TAXBID_formatted_date" END) AS "TAXBID_formatted_date",
	
	MAX(RECOVERY_FINAL."RETAX_process_frequency") "RETAX_process_frequency",
	MAX(RECOVERY_FINAL."RETAX_base_year") "RETAX_base_year",
	MAX(RECOVERY_FINAL."RETAX_base_amount") "RETAX_base_amount",
	MAX(RECOVERY_FINAL."RETAX_manual_percent") "RETAX_manual_percent",
	
    
    MAX(RECOVERY_FINAL."TAXBID_process_frequency") "TAXBID_process_frequency",
    MAX(RECOVERY_FINAL."TAXBID_base_year") "TAXBID_base_year",
    MAX(RECOVERY_FINAL."TAXBID_base_amount") "TAXBID_base_amount",
	MAX(RECOVERY_FINAL."TAXBID_manual_percent") "TAXBID_manual_percent"
	
FROM SECOND_AUX
LEFT JOIN RECOVERY_FINAL
	ON RECOVERY_FINAL."LEASE_ID" = SECOND_AUX."LEASE_ID"
WHERE "ROW_NUM" <= 2
GROUP BY 
    SECOND_AUX."PROP_NAME", 
  	SECOND_AUX."UNIT_NAME",
    SECOND_AUX."LEASE_ID",
	SECOND_AUX."LEASE_NAME"
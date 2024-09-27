WITH RECURSIVE date_series AS (
    SELECT @AsOfDate::DATE as month
    UNION ALL
    SELECT (month + INTERVAL '1 month')::DATE
    FROM date_series
    WHERE month + INTERVAL '1 month' < (@AsOfDate + INTERVAL '12 month')::DATE
),
CHARGES_TOT AS (
    SELECT 
        "lease_recurring_charges"."lease_id" AS "LEASE_ID",
  		"public"."leases"."name" AS "LEASE_NAME",
        "lease_recurring_charge_amounts"."effective_date" AS "EFFECTIVE_DATE",
        "lease_recurring_charge_amounts"."amount" AS "AMOUNT",
        "lease_recurring_charges"."order_entry_item_id" AS "ITEM_ID",
        "units"."property_id" AS "PROP_ID",
  		"public"."properties"."property_location_id" as "LOCATION_ID",
        "lease_recurring_charges"."unit_id" AS "UNIT_ID",
  		"public"."leases"."end" AS "LEASE_END"
  
    FROM "public"."lease_recurring_charges"
    INNER JOIN "public"."lease_recurring_charge_amounts"
        ON "lease_recurring_charges"."id" = "lease_recurring_charge_amounts"."recurring_charge_id"
    INNER JOIN "public"."units"
        ON "lease_recurring_charges"."unit_id" =  "units"."id"
    INNER JOIN "public"."properties"
        ON "units"."property_id" =  "properties"."id"
  	INNER JOIN "public"."leases" 
  		ON "lease_recurring_charges"."lease_id" = "public"."leases"."id"
  
    WHERE "lease_recurring_charge_amounts"."effective_date" <= (@AsOfDate + INTERVAL '12 month')
  		--AND "lease_recurring_charge_amounts"."effective_date" >= (@AsOfDate)
        AND ("lease_recurring_charge_amounts"."deleted_at" >= (@AsOfDate + INTERVAL '12 month') OR "lease_recurring_charge_amounts"."deleted_at" IS NULL)
        AND ("lease_recurring_charges"."deleted_at" >= (@AsOfDate + INTERVAL '12 month') OR "lease_recurring_charges"."deleted_at" IS NULL)
        AND ("lease_recurring_charges"."terminate_date" >= (@AsOfDate + INTERVAL '12 month') OR "lease_recurring_charges"."terminate_date" IS NULL)
        AND "lease_recurring_charges"."order_entry_item_id" in (@Item_Id)
        AND "public"."properties"."name" IN (@Property_Name)
        AND CAST("public"."properties"."company_relation_id" AS INT) = CAST(@REAL_COMPANY_ID AS INT)
  		AND ("lease_recurring_charge_amounts"."effective_date" <= "public"."leases"."end"
			OR "public"."leases"."end" is NULL)
),
charged_amounts AS (
    SELECT
        ds."month",
        ct."LEASE_ID",
  		ct."LEASE_NAME",
        ct."EFFECTIVE_DATE",
        ct."AMOUNT" AS "AMOUNT_OLD",
  		CASE WHEN ( EXTRACT(MONTH FROM ds."month") = EXTRACT(MONTH FROM ct."LEASE_END") 
				   			 AND EXTRACT(YEAR FROM ds."month") = EXTRACT(YEAR FROM ct."LEASE_END")  ) then ct."AMOUNT" * EXTRACT(DAY FROM ct."LEASE_END") / 30
  				ELSE ct."AMOUNT" 
  		END AS "AMOUNT",
        ct."ITEM_ID",
        ct."PROP_ID",
  		ct."LOCATION_ID",
        ct."UNIT_ID",
        ROW_NUMBER() OVER (PARTITION BY ct."LEASE_ID", ct."ITEM_ID", ds."month" ORDER BY ct."EFFECTIVE_DATE" DESC) AS rn,
  		ct."LEASE_END" 
    FROM
        date_series ds
    CROSS JOIN CHARGES_TOT ct
    WHERE ds."month" >= ct."EFFECTIVE_DATE"
  		AND ct."LEASE_END" >= ds."month"
),
FINAL_TO_PIVOT AS (
    SELECT
        ds."month" as "TIME_STAMP",
        EXTRACT(MONTH FROM ds."month") AS "MONTH",
        EXTRACT(YEAR FROM ds."month") AS "YEAR",
        ca."LEASE_ID",
  		ca."LEASE_NAME",
        COALESCE(ca."AMOUNT", 0) AS "AMOUNT",
        ca."ITEM_ID",
        ca."PROP_ID",
  		ca."LOCATION_ID",
        ca."UNIT_ID"
    FROM
        date_series ds
    LEFT JOIN charged_amounts ca ON ds."month" = ca."month" AND ca.rn = 1
    ORDER BY ca."PROP_ID", ca."LEASE_ID", ca."ITEM_ID", ds."month"
)
 
SELECT
	'' AS "DONOTIMPORT",
	MIN("TIME_STAMP") AS "BUDGET_ID",
    fp."ITEM_ID" AS "order_entry_item_id",
	"public"."properties"."department" AS "department_id",
	"public"."properties"."id" AS "property_id",
	fp."LOCATION_ID" as "LOCATION_ID",
	"public"."leases"."id" AS "lease_id",
	"public"."leases"."name" AS "lease_name",
	"public"."tenants"."tenant_id" AS "tenants_id",
	"public"."tenants"."vendor_id" AS "vendor_id",
	fp."ITEM_ID" AS "item_id",
	"public"."properties"."class_id" AS "class_id",
	ROUND(SUM(CASE WHEN DATE_TRUNC('month', @AsOfDate + INTERVAL '0 month') = DATE_TRUNC('month', fp."TIME_STAMP") THEN fp."AMOUNT" ELSE 0 END)::numeric, 2) AS "Month 1",
    TO_CHAR(@AsOfDate + INTERVAL '0 month', '"Month Ended "FMMonth YYYY') AS "month_1_full_name",
    ROUND(SUM(CASE WHEN DATE_TRUNC('month', @AsOfDate + INTERVAL '1 month') = DATE_TRUNC('month', fp."TIME_STAMP") THEN fp."AMOUNT" ELSE 0 END)::numeric, 2) AS "Month 2",
    TO_CHAR(@AsOfDate + INTERVAL '1 month', '"Month Ended "FMMonth YYYY') AS "month_2_full_name",
    ROUND(SUM(CASE WHEN DATE_TRUNC('month', @AsOfDate + INTERVAL '2 month') = DATE_TRUNC('month', fp."TIME_STAMP") THEN fp."AMOUNT" ELSE 0 END)::numeric, 2) AS "Month 3",
    TO_CHAR(@AsOfDate + INTERVAL '2 month', '"Month Ended "FMMonth YYYY') AS "month_3_full_name",
    ROUND(SUM(CASE WHEN DATE_TRUNC('month', @AsOfDate + INTERVAL '3 month') = DATE_TRUNC('month', fp."TIME_STAMP") THEN fp."AMOUNT" ELSE 0 END)::numeric, 2) AS "Month 4",
    TO_CHAR(@AsOfDate + INTERVAL '3 month', '"Month Ended "FMMonth YYYY') AS "month_4_full_name",
    ROUND(SUM(CASE WHEN DATE_TRUNC('month', @AsOfDate + INTERVAL '4 month') = DATE_TRUNC('month', fp."TIME_STAMP") THEN fp."AMOUNT" ELSE 0 END)::numeric, 2) AS "Month 5",
    TO_CHAR(@AsOfDate + INTERVAL '4 month', '"Month Ended "FMMonth YYYY') AS "month_5_full_name",
    ROUND(SUM(CASE WHEN DATE_TRUNC('month', @AsOfDate + INTERVAL '5 month') = DATE_TRUNC('month', fp."TIME_STAMP") THEN fp."AMOUNT" ELSE 0 END)::numeric, 2) AS "Month 6",
    TO_CHAR(@AsOfDate + INTERVAL '5 month', '"Month Ended "FMMonth YYYY') AS "month_6_full_name",
    ROUND(SUM(CASE WHEN DATE_TRUNC('month', @AsOfDate + INTERVAL '6 month') = DATE_TRUNC('month', fp."TIME_STAMP") THEN fp."AMOUNT" ELSE 0 END)::numeric, 2) AS "Month 7",
    TO_CHAR(@AsOfDate + INTERVAL '6 month', '"Month Ended "FMMonth YYYY') AS "month_7_full_name",
    ROUND(SUM(CASE WHEN DATE_TRUNC('month', @AsOfDate + INTERVAL '7 month') = DATE_TRUNC('month', fp."TIME_STAMP") THEN fp."AMOUNT" ELSE 0 END)::numeric, 2) AS "Month 8",
    TO_CHAR(@AsOfDate + INTERVAL '7 month', '"Month Ended "FMMonth YYYY') AS "month_8_full_name",
    ROUND(SUM(CASE WHEN DATE_TRUNC('month', @AsOfDate + INTERVAL '8 month') = DATE_TRUNC('month', fp."TIME_STAMP") THEN fp."AMOUNT" ELSE 0 END)::numeric, 2) AS "Month 9",
    TO_CHAR(@AsOfDate + INTERVAL '8 month', '"Month Ended "FMMonth YYYY') AS "month_9_full_name",
    ROUND(SUM(CASE WHEN DATE_TRUNC('month', @AsOfDate + INTERVAL '9 month') = DATE_TRUNC('month', fp."TIME_STAMP") THEN fp."AMOUNT" ELSE 0 END)::numeric, 2) AS "Month 10",
    TO_CHAR(@AsOfDate + INTERVAL '9 month', '"Month Ended "FMMonth YYYY') AS "month_10_full_name",
    ROUND(SUM(CASE WHEN DATE_TRUNC('month', @AsOfDate + INTERVAL '10 month') = DATE_TRUNC('month', fp."TIME_STAMP") THEN fp."AMOUNT" ELSE 0 END)::numeric, 2) AS "Month 11",
    TO_CHAR(@AsOfDate + INTERVAL '10 month', '"Month Ended "FMMonth YYYY') AS "month_11_full_name",
    ROUND(SUM(CASE WHEN DATE_TRUNC('month', @AsOfDate + INTERVAL '11 month') = DATE_TRUNC('month', fp."TIME_STAMP") THEN fp."AMOUNT" ELSE 0 END)::numeric, 2) AS "Month 12",
    TO_CHAR(@AsOfDate + INTERVAL '11 month', '"Month Ended "FMMonth YYYY') AS "month_12_full_name"
 	
FROM
    FINAL_TO_PIVOT as fp
INNER JOIN "public"."leases" ON fp."LEASE_ID" = "public"."leases"."id"
INNER JOIN "public"."tenants" ON "public"."tenants"."id" = "public"."leases"."primaryTenantId"
INNER JOIN "public"."properties" ON fp."PROP_ID" = "public"."properties"."id"

WHERE LOWER(CAST("public"."leases"."month_to_month" AS TEXT)) IN (LOWER(CAST(@month_to_month AS TEXT)))
	AND CAST("public"."leases"."status" AS TEXT) IN (@Lease_Status)
	
GROUP BY 1,3,4,5,6,7,8,9,10,11,12
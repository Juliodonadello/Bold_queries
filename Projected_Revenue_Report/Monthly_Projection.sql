WITH RECURSIVE date_series AS (
    SELECT @From_Date::DATE as month
    UNION ALL
    SELECT (month + INTERVAL '1 month')::DATE
    FROM date_series
    WHERE month + INTERVAL '1 month' <= @To_Date::DATE
),
CHARGES_TOT AS (
    SELECT 
        "lease_recurring_charges"."lease_id" AS "LEASE_ID",
        "lease_recurring_charge_amounts"."effective_date" AS "EFFECTIVE_DATE",
        "lease_recurring_charge_amounts"."amount" AS "AMOUNT",
        "lease_recurring_charges"."order_entry_item_id" AS "ITEM_ID",
        "units"."property_id" AS "PROP_ID",
        "lease_recurring_charges"."unit_id" AS "UNIT_ID",
  		"public"."leases"."end" AS "LEASE_END",
  		"lease_recurring_charge_amounts"."frequency" AS "FREQUENCY", 
  		"lease_recurring_charges"."terminate_date" AS "RCHARGE_END"
  
    FROM "public"."lease_recurring_charges"
    INNER JOIN "public"."lease_recurring_charge_amounts"
        ON "lease_recurring_charges"."id" = "lease_recurring_charge_amounts"."recurring_charge_id"
    INNER JOIN "public"."units"
        ON "lease_recurring_charges"."unit_id" =  "units"."id"
    INNER JOIN "public"."properties"
        ON "units"."property_id" =  "properties"."id"
  	INNER JOIN "public"."leases" 
  		ON "lease_recurring_charges"."lease_id" = "public"."leases"."id"
  
    WHERE "lease_recurring_charge_amounts"."effective_date" <= @To_Date
        AND ("lease_recurring_charge_amounts"."deleted_at" >= @To_Date OR "lease_recurring_charge_amounts"."deleted_at" IS NULL)
        AND ("lease_recurring_charges"."deleted_at" >= @To_Date OR "lease_recurring_charges"."deleted_at" IS NULL)
        --AND ("lease_recurring_charges"."terminate_date" >= @To_Date OR "lease_recurring_charges"."terminate_date" IS NULL)
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
        ct."EFFECTIVE_DATE",
        ct."AMOUNT" AS "AMOUNT_OLD",
  		CASE 
  				WHEN ct."FREQUENCY" = 'Annually' THEN ct."AMOUNT" / 12
  				WHEN ( EXTRACT(MONTH FROM ds."month") = EXTRACT(MONTH FROM ct."LEASE_END") 
				   			 AND EXTRACT(YEAR FROM ds."month") = EXTRACT(YEAR FROM ct."LEASE_END")  ) then ct."AMOUNT" * EXTRACT(DAY FROM ct."LEASE_END") / 30
  				ELSE ct."AMOUNT" 
  		END AS "AMOUNT",
        ct."ITEM_ID",
        ct."PROP_ID",
        ct."UNIT_ID",
        ROW_NUMBER() OVER (PARTITION BY ct."LEASE_ID", ct."ITEM_ID", ds."month" ORDER BY ct."EFFECTIVE_DATE" DESC) AS rn,
  		ct."LEASE_END" 
    FROM
        date_series ds
    CROSS JOIN CHARGES_TOT ct
    WHERE ds."month" >= ct."EFFECTIVE_DATE"
  		AND ct."LEASE_END" >= ds."month"
  		AND (ct."RCHARGE_END" >= ds."month" or ct."RCHARGE_END" is NULL)
),
FINAL_TO_PIVOT AS (
    SELECT
        ds."month" as "TIME_STAMP",
        EXTRACT(MONTH FROM ds."month") AS "MONTH",
        EXTRACT(YEAR FROM ds."month") AS "YEAR",
        ca."LEASE_ID",
        COALESCE(ca."AMOUNT", 0) AS "AMOUNT",
        ca."ITEM_ID",
        ca."PROP_ID",
        ca."UNIT_ID"
    FROM
        date_series ds
    LEFT JOIN charged_amounts ca ON ds."month" = ca."month" AND ca.rn = 1
    ORDER BY ca."PROP_ID", ca."LEASE_ID", ca."ITEM_ID", ds."month"
)
SELECT
    fp."ITEM_ID",
    "public"."leases"."name",
    "public"."leases"."start",
    "public"."leases"."end",
    "public"."tenants"."name" AS "tenants_name",
    "public"."properties"."name" AS "property_name",
    SUM(CASE WHEN DATE_TRUNC('month', @From_Date + INTERVAL '0 month') = DATE_TRUNC('month', fp."TIME_STAMP") THEN fp."AMOUNT" ELSE 0 END) AS "Month 1",
    TO_CHAR(@From_Date + INTERVAL '0 month', 'Mon, YY') AS "month_1_name",
    SUM(CASE WHEN DATE_TRUNC('month', @From_Date + INTERVAL '1 month') = DATE_TRUNC('month', fp."TIME_STAMP") THEN fp."AMOUNT" ELSE 0 END) AS "Month 2",
    TO_CHAR(@From_Date + INTERVAL '1 month', 'Mon, YY') AS "month_2_name",
    SUM(CASE WHEN DATE_TRUNC('month', @From_Date + INTERVAL '2 month') = DATE_TRUNC('month', fp."TIME_STAMP") THEN fp."AMOUNT" ELSE 0 END) AS "Month 3",
    TO_CHAR(@From_Date + INTERVAL '2 month', 'Mon, YY') AS "month_3_name",
    SUM(CASE WHEN DATE_TRUNC('month', @From_Date + INTERVAL '3 month') = DATE_TRUNC('month', fp."TIME_STAMP") THEN fp."AMOUNT" ELSE 0 END) AS "Month 4",
    TO_CHAR(@From_Date + INTERVAL '3 month', 'Mon, YY') AS "month_4_name",
    SUM(CASE WHEN DATE_TRUNC('month', @From_Date + INTERVAL '4 month') = DATE_TRUNC('month', fp."TIME_STAMP") THEN fp."AMOUNT" ELSE 0 END) AS "Month 5",
    TO_CHAR(@From_Date + INTERVAL '4 month', 'Mon, YY') AS "month_5_name",
    SUM(CASE WHEN DATE_TRUNC('month', @From_Date + INTERVAL '5 month') = DATE_TRUNC('month', fp."TIME_STAMP") THEN fp."AMOUNT" ELSE 0 END) AS "Month 6",
    TO_CHAR(@From_Date + INTERVAL '5 month', 'Mon, YY') AS "month_6_name",
    SUM(CASE WHEN DATE_TRUNC('month', @From_Date + INTERVAL '6 month') = DATE_TRUNC('month', fp."TIME_STAMP") THEN fp."AMOUNT" ELSE 0 END) AS "Month 7",
    TO_CHAR(@From_Date + INTERVAL '6 month', 'Mon, YY') AS "month_7_name",
    SUM(CASE WHEN DATE_TRUNC('month', @From_Date + INTERVAL '7 month') = DATE_TRUNC('month', fp."TIME_STAMP") THEN fp."AMOUNT" ELSE 0 END) AS "Month 8",
    TO_CHAR(@From_Date + INTERVAL '7 month', 'Mon, YY') AS "month_8_name",
    SUM(CASE WHEN DATE_TRUNC('month', @From_Date + INTERVAL '8 month') = DATE_TRUNC('month', fp."TIME_STAMP") THEN fp."AMOUNT" ELSE 0 END) AS "Month 9",
    TO_CHAR(@From_Date + INTERVAL '8 month', 'Mon, YY') AS "month_9_name",
    SUM(CASE WHEN DATE_TRUNC('month', @From_Date + INTERVAL '9 month') = DATE_TRUNC('month', fp."TIME_STAMP") THEN fp."AMOUNT" ELSE 0 END) AS "Month 10",
    TO_CHAR(@From_Date + INTERVAL '9 month', 'Mon, YY') AS "month_10_name",
    SUM(CASE WHEN DATE_TRUNC('month', @From_Date + INTERVAL '10 month') = DATE_TRUNC('month', fp."TIME_STAMP") THEN fp."AMOUNT" ELSE 0 END) AS "Month 11",
    TO_CHAR(@From_Date + INTERVAL '10 month', 'Mon, YY') AS "month_11_name",
    SUM(CASE WHEN DATE_TRUNC('month', @From_Date + INTERVAL '11 month') = DATE_TRUNC('month', fp."TIME_STAMP") THEN fp."AMOUNT" ELSE 0 END) AS "Month 12",
    TO_CHAR(@From_Date + INTERVAL '11 month', 'Mon, YY') AS "month_12_name",
    SUM(CASE WHEN DATE_TRUNC('year', @From_Date) = DATE_TRUNC('year', fp."TIME_STAMP") THEN fp."AMOUNT" ELSE 0 END) AS "YEAR 1",
    EXTRACT(YEAR FROM @From_Date) AS "year_1_name",
    SUM(CASE WHEN DATE_TRUNC('year', @From_Date + INTERVAL '1 year') = DATE_TRUNC('year', fp."TIME_STAMP") THEN fp."AMOUNT" ELSE 0 END) AS "YEAR 2",
    EXTRACT(YEAR FROM @From_Date + INTERVAL '1 year') AS "year_2_name",
    SUM(CASE WHEN DATE_TRUNC('year', @From_Date + INTERVAL '2 year') = DATE_TRUNC('year', fp."TIME_STAMP") THEN fp."AMOUNT" ELSE 0 END) AS "YEAR 3",
    EXTRACT(YEAR FROM @From_Date + INTERVAL '2 year') AS "year_3_name"
FROM
    FINAL_TO_PIVOT as fp
INNER JOIN "public"."leases" ON fp."LEASE_ID" = "public"."leases"."id"
INNER JOIN "public"."tenants" ON "public"."tenants"."id" = "public"."leases"."primaryTenantId"
INNER JOIN "public"."properties" ON fp."PROP_ID" = "public"."properties"."id"

WHERE CASE WHEN CAST("public"."leases"."month_to_month" AS TEXT) ='true' THEN 'True' ELSE 'False' END IN (@month_to_month) 
    AND CAST("public"."leases"."status" AS TEXT) IN (@Lease_Status)

GROUP BY
    1, 2, 3, 4, 5, 6
ORDER BY
    1, 2, 4
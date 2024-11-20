WITH RECURSIVE date_series AS (
    SELECT @From_Date::DATE as month
    UNION ALL
    SELECT (month + INTERVAL '1 month')::DATE
    FROM date_series
    WHERE month + INTERVAL '1 month' <= @From_Date + INTERVAL '10 year'
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
        "lease_recurring_charge_amounts"."frequency" AS "FREQUENCY"
    FROM "public"."lease_recurring_charges"
    INNER JOIN "public"."lease_recurring_charge_amounts"
        ON "lease_recurring_charges"."id" = "lease_recurring_charge_amounts"."recurring_charge_id"
    INNER JOIN "public"."units"
        ON "lease_recurring_charges"."unit_id" = "units"."id"
    INNER JOIN "public"."properties"
        ON "units"."property_id" = "properties"."id"
    INNER JOIN "public"."leases"
        ON "lease_recurring_charges"."lease_id" = "public"."leases"."id"
    WHERE "lease_recurring_charge_amounts"."effective_date" <= @From_Date + INTERVAL '10 year'
        AND ("lease_recurring_charge_amounts"."deleted_at" >= @From_Date + INTERVAL '10 year' OR "lease_recurring_charge_amounts"."deleted_at" IS NULL)
        AND ("lease_recurring_charges"."deleted_at" >= @From_Date + INTERVAL '10 year' OR "lease_recurring_charges"."deleted_at" IS NULL)
        AND "lease_recurring_charges"."order_entry_item_id" IN (@Item_Id)
        AND "public"."properties"."name" IN (@Property_Name)
        AND CAST("public"."properties"."company_relation_id" AS INT) = CAST(@REAL_COMPANY_ID AS INT)
),
charged_amounts AS (
    SELECT
        ds."month",
        ct."LEASE_ID",
        ct."EFFECTIVE_DATE",
        ct."AMOUNT" AS "AMOUNT_OLD",
        CASE 
            WHEN ct."FREQUENCY" = 'Annually' THEN ct."AMOUNT" / 12
            ELSE ct."AMOUNT"
        END AS "AMOUNT",
        ct."ITEM_ID",
        ct."PROP_ID",
        ct."UNIT_ID",
        ROW_NUMBER() OVER (PARTITION BY ct."LEASE_ID", ct."ITEM_ID", ds."month" ORDER BY ct."EFFECTIVE_DATE" DESC) AS rn
    FROM date_series ds
    CROSS JOIN CHARGES_TOT ct
    WHERE ds."month" >= ct."EFFECTIVE_DATE"
),
filled_amounts AS (
    SELECT
        ca."month",
        ca."LEASE_ID",
        ca."ITEM_ID",
        ca."PROP_ID",
        ca."UNIT_ID",
        COALESCE(
            LAST_VALUE(ca."AMOUNT") OVER (
                PARTITION BY ca."LEASE_ID", ca."ITEM_ID"
                ORDER BY ca."month"
                ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
            ), 0
        ) AS "FILLED_AMOUNT"
    FROM charged_amounts ca
    WHERE ca.rn = 1
),
FINAL_TO_PIVOT AS (
    SELECT
        ds."month" AS "TIME_STAMP",
        EXTRACT(MONTH FROM ds."month") AS "MONTH",
        EXTRACT(YEAR FROM ds."month") AS "YEAR",
        fa."LEASE_ID",
        fa."FILLED_AMOUNT" AS "AMOUNT",
        fa."ITEM_ID",
        fa."PROP_ID",
        fa."UNIT_ID"
    FROM date_series ds
    LEFT JOIN filled_amounts fa
        ON ds."month" = fa."month"
    ORDER BY fa."PROP_ID", fa."LEASE_ID", fa."ITEM_ID", ds."month"
)
SELECT
    fp."ITEM_ID",
    "public"."leases"."name",
    "public"."leases"."start",
    "public"."leases"."end",
    "public"."tenants"."name" AS "tenants_name",
    "public"."properties"."name" AS "property_name",
    SUM(CASE WHEN DATE_TRUNC('year', @From_Date) = DATE_TRUNC('year', fp."TIME_STAMP") THEN fp."AMOUNT" ELSE 0 END) AS "YEAR 1",
    EXTRACT(YEAR FROM @From_Date) AS "year_1_name",
    SUM(CASE WHEN DATE_TRUNC('year', @From_Date + INTERVAL '1 year') = DATE_TRUNC('year', fp."TIME_STAMP") THEN fp."AMOUNT" ELSE 0 END) AS "YEAR 2",
    EXTRACT(YEAR FROM @From_Date + INTERVAL '1 year') AS "year_2_name",
    SUM(CASE WHEN DATE_TRUNC('year', @From_Date + INTERVAL '2 year') = DATE_TRUNC('year', fp."TIME_STAMP") THEN fp."AMOUNT" ELSE 0 END) AS "YEAR 3",
    EXTRACT(YEAR FROM @From_Date + INTERVAL '2 year') AS "year_3_name",
    SUM(CASE WHEN DATE_TRUNC('year', @From_Date + INTERVAL '3 year') = DATE_TRUNC('year', fp."TIME_STAMP") THEN fp."AMOUNT" ELSE 0 END) AS "YEAR 4",
    EXTRACT(YEAR FROM @From_Date + INTERVAL '3 year') AS "year_4_name",
    SUM(CASE WHEN DATE_TRUNC('year', @From_Date + INTERVAL '4 year') = DATE_TRUNC('year', fp."TIME_STAMP") THEN fp."AMOUNT" ELSE 0 END) AS "YEAR 5",
    EXTRACT(YEAR FROM @From_Date + INTERVAL '4 year') AS "year_5_name",
    SUM(CASE WHEN DATE_TRUNC('year', @From_Date + INTERVAL '5 year') = DATE_TRUNC('year', fp."TIME_STAMP") THEN fp."AMOUNT" ELSE 0 END) AS "YEAR 6",
    EXTRACT(YEAR FROM @From_Date + INTERVAL '5 year') AS "year_6_name",
    SUM(CASE WHEN DATE_TRUNC('year', @From_Date + INTERVAL '6 year') = DATE_TRUNC('year', fp."TIME_STAMP") THEN fp."AMOUNT" ELSE 0 END) AS "YEAR 7",
    EXTRACT(YEAR FROM @From_Date + INTERVAL '6 year') AS "year_7_name",
    SUM(CASE WHEN DATE_TRUNC('year', @From_Date + INTERVAL '7 year') = DATE_TRUNC('year', fp."TIME_STAMP") THEN fp."AMOUNT" ELSE 0 END) AS "YEAR 8",
    EXTRACT(YEAR FROM @From_Date + INTERVAL '7 year') AS "year_8_name",
    SUM(CASE WHEN DATE_TRUNC('year', @From_Date + INTERVAL '8 year') = DATE_TRUNC('year', fp."TIME_STAMP") THEN fp."AMOUNT" ELSE 0 END) AS "YEAR 9",
    EXTRACT(YEAR FROM @From_Date + INTERVAL '8 year') AS "year_9_name",
    SUM(CASE WHEN DATE_TRUNC('year', @From_Date + INTERVAL '9 year') = DATE_TRUNC('year', fp."TIME_STAMP") THEN fp."AMOUNT" ELSE 0 END) AS "YEAR 10",
    EXTRACT(YEAR FROM @From_Date + INTERVAL '9 year') AS "year_10_name"
FROM
    FINAL_TO_PIVOT fp
INNER JOIN "public"."leases" ON fp."LEASE_ID" = "public"."leases"."id"
INNER JOIN "public"."tenants" ON "public"."tenants"."id" = "public"."leases"."primaryTenantId"
INNER JOIN "public"."properties" ON fp."PROP_ID" = "public"."properties"."id"
WHERE CAST("public"."leases"."status" AS TEXT) IN (@Lease_Status)
    AND CASE WHEN CAST("public"."leases"."month_to_month" AS TEXT) = 'true' THEN 'True' ELSE 'False' END IN (@month_to_month)
GROUP BY 1, 2, 3, 4, 5, 6
ORDER BY 1, 2, 4;

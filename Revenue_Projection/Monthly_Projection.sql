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
        "lease_recurring_charges"."unit_id" AS "UNIT_ID"
    FROM "public"."lease_recurring_charges"
    INNER JOIN "public"."lease_recurring_charge_amounts"
        ON "lease_recurring_charges"."id" = "lease_recurring_charge_amounts"."recurring_charge_id"
    INNER JOIN "public"."units"
        ON "lease_recurring_charges"."unit_id" =  "units"."id"
      INNER JOIN "public"."properties"
        ON "units"."property_id" =  "properties"."id"
  
    WHERE "lease_recurring_charge_amounts"."effective_date" <= @To_Date
		AND ("lease_recurring_charge_amounts"."deleted_at" >= @To_Date OR "lease_recurring_charge_amounts"."deleted_at" IS NULL)
		AND ("lease_recurring_charges"."deleted_at" >= @To_Date OR "lease_recurring_charges"."deleted_at" IS NULL)
		AND ("lease_recurring_charges"."terminate_date" >= @To_Date OR "lease_recurring_charges"."terminate_date" IS NULL)
		AND "lease_recurring_charges"."order_entry_item_id" in (@Item_Id)
		AND "public"."properties"."name" IN (@Property_Name)
	    AND CAST("public"."properties"."company_relation_id" AS INT) = CAST(@REAL_COMPANY_ID AS INT)
),
charged_amounts AS (
    SELECT
        ds."month",
        ct."LEASE_ID",
        ct."EFFECTIVE_DATE",
        ct."AMOUNT",
        ct."ITEM_ID",
        ct."PROP_ID",
        ct."UNIT_ID",
        ROW_NUMBER() OVER (PARTITION BY ct."LEASE_ID", ct."ITEM_ID", ds."month" ORDER BY ct."EFFECTIVE_DATE" DESC) AS rn
    FROM
        date_series ds
    CROSS JOIN CHARGES_TOT ct
    WHERE ds."month" >= ct."EFFECTIVE_DATE"
),
FINAL_TO_PIVOT AS (
    SELECT
        ds."month" as "TIME_STAMP",
        EXTRACT(MONTH FROM ds."month") AS "MONTH",
        --SUBSTRING(TO_CHAR(ds."month", 'Month'), 1, 3) AS "MONTH_NAME",
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
    --fp."PROP_ID",
	--fp."LEASE_ID", 
	--fp."UNIT_ID", --ver si no rompe la granularidad cuando lo sumamos al group by
	fp."ITEM_ID",
    "public"."leases"."name",
    "public"."leases"."start",
    "public"."leases"."end",
	"public"."tenants"."name" AS "tenants_name",
    "public"."properties"."name" AS "property_name",
    SUM(CASE WHEN EXTRACT(YEAR FROM @From_Date) = fp."YEAR" AND "MONTH" = 1 THEN "AMOUNT" ELSE 0 END) AS "Month 1",
    SUM(CASE WHEN EXTRACT(YEAR FROM @From_Date) = fp."YEAR" AND "MONTH" = 2 THEN "AMOUNT" ELSE 0 END) AS "Month 2",
    SUM(CASE WHEN EXTRACT(YEAR FROM @From_Date) = fp."YEAR" AND "MONTH" = 3 THEN "AMOUNT" ELSE 0 END) AS "Month 3",
    SUM(CASE WHEN EXTRACT(YEAR FROM @From_Date) = fp."YEAR" AND "MONTH" = 4 THEN "AMOUNT" ELSE 0 END) AS "Month 4",
    SUM(CASE WHEN EXTRACT(YEAR FROM @From_Date) = fp."YEAR" AND "MONTH" = 5 THEN "AMOUNT" ELSE 0 END) AS "Month 5",
    SUM(CASE WHEN EXTRACT(YEAR FROM @From_Date) = fp."YEAR" AND "MONTH" = 6 THEN "AMOUNT" ELSE 0 END) AS "Month 6",
    SUM(CASE WHEN EXTRACT(YEAR FROM @From_Date) = fp."YEAR" AND "MONTH" = 7 THEN "AMOUNT" ELSE 0 END) AS "Month 7",
    SUM(CASE WHEN EXTRACT(YEAR FROM @From_Date) = fp."YEAR" AND "MONTH" = 8 THEN "AMOUNT" ELSE 0 END) AS "Month 8",
    SUM(CASE WHEN EXTRACT(YEAR FROM @From_Date) = fp."YEAR" AND "MONTH" = 9 THEN "AMOUNT" ELSE 0 END) AS "Month 9",
    SUM(CASE WHEN EXTRACT(YEAR FROM @From_Date) = fp."YEAR" AND "MONTH" = 10 THEN "AMOUNT" ELSE 0 END) AS "Month 10",
    SUM(CASE WHEN EXTRACT(YEAR FROM @From_Date) = fp."YEAR" AND "MONTH" = 11 THEN "AMOUNT" ELSE 0 END) AS "Month 11",
    SUM(CASE WHEN EXTRACT(YEAR FROM @From_Date) = fp."YEAR" AND "MONTH" = 12 THEN "AMOUNT" ELSE 0 END) AS "Month 12",
	SUM(CASE WHEN EXTRACT(YEAR FROM @From_Date) = fp."YEAR" THEN "AMOUNT" ELSE 0 END) AS "YEAR 1",
	SUM(CASE WHEN EXTRACT(YEAR FROM @From_Date)+1 = fp."YEAR" THEN "AMOUNT" ELSE 0 END) AS "YEAR 2",
	SUM(CASE WHEN EXTRACT(YEAR FROM @From_Date)+2 = fp."YEAR" THEN "AMOUNT" ELSE 0 END) AS "YEAR 3"

FROM
    FINAL_TO_PIVOT as fp
INNER JOIN "public"."leases" ON fp."LEASE_ID" = "public"."leases"."id"
INNER  JOIN "public"."tenants" ON "public"."tenants"."id"="public"."leases"."primaryTenantId"
INNER  JOIN "public"."properties" ON fp."PROP_ID"="public"."properties"."id"

GROUP BY
    1,2,3,4,5,6
ORDER BY
   1,2,4

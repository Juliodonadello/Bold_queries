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
    WHERE "lease_recurring_charge_amounts"."effective_date" <= @To_Date
      AND ("lease_recurring_charge_amounts"."deleted_at" >= @To_Date OR "lease_recurring_charge_amounts"."deleted_at" IS NULL)
      AND ("lease_recurring_charges"."deleted_at" >= @To_Date OR "lease_recurring_charges"."deleted_at" IS NULL)
      AND ("lease_recurring_charges"."terminate_date" >= @To_Date OR "lease_recurring_charges"."terminate_date" IS NULL)
	AND "units"."property_id" = 1705 --120 Broadway
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
)
SELECT
    ds."month",
    ca."LEASE_ID",
    COALESCE(ca."AMOUNT", 0) AS "AMOUNT",
    ca."ITEM_ID",
    ca."PROP_ID",
    ca."UNIT_ID"
FROM
    date_series ds
LEFT JOIN charged_amounts ca ON ds."month" = ca."month" AND ca.rn = 1
ORDER BY ca."PROP_ID", ca."LEASE_ID", ca."ITEM_ID", ds."month";

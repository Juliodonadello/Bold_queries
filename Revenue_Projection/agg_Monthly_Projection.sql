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
      AND "lease_recurring_charge_amounts"."frequency" != 'One Time'
      OR ("lease_recurring_charge_amounts"."frequency" = 'One Time'
          AND EXTRACT(DAY FROM (@From_Date - "lease_recurring_charge_amounts"."effective_date")) > 0
          AND EXTRACT(DAY FROM (@From_Date - "lease_recurring_charge_amounts"."effective_date")) < 31)
),
monthly_rent AS (
    SELECT
        ds."month",
        ct."LEASE_ID",
        ct."AMOUNT",
        ct."ITEM_ID",
        ct."PROP_ID",
        ct."UNIT_ID"
    FROM
        date_series ds
    LEFT JOIN LATERAL (
        SELECT * FROM CHARGES_TOT ct
        WHERE ct."EFFECTIVE_DATE" <= ds."month"
        ORDER BY ct."EFFECTIVE_DATE" DESC
        LIMIT 1
    ) ct ON true
)
SELECT *
FROM monthly_rent
ORDER BY "PROP_ID", "LEASE_ID", "month"
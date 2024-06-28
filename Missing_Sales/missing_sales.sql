WITH LEASES_SALES AS (
  SELECT 
    "public"."leases"."id" AS "LEASE_ID",
    "public"."leases"."name" AS "LEASE_NAME",
    "public"."leases"."start" AS "start",
    "public"."leases"."end" AS "lease_end",
    "public"."rent_percentages"."overage_start_date" AS "overage_start_date",
    "public"."rent_percentages"."overage_end_date" AS "overage_end_date",
    "public"."rent_percentages"."months_frequency" AS "MONTHS_FRECUENCY",
    "public"."rent_percentages"."item_id" AS "ITEM_ID",
    "public"."rent_percentages"."sale_type" AS "TYPE_REQUIRED",
    "public"."sales_entry"."transaction_date" AS "transaction_date",
    SUBSTRING(TO_CHAR("public"."sales_entry"."transaction_date", 'Month'), 1, 3) AS "transaction_month",
    EXTRACT(YEAR FROM "public"."sales_entry"."transaction_date") AS "transaction_year",
    "public"."sales_entry"."sales_volume" AS "sales_volume",
    "public"."leases_units_units"."unitsId" AS "UNIT_ID",  		
    "public"."tenants"."name" AS "TENANT"
  FROM "public"."leases"
  INNER JOIN "public"."leases_units_units"
    ON "public"."leases"."id" = "public"."leases_units_units"."leasesId"
  INNER JOIN "public"."properties"
    ON "public"."properties"."id" = "public"."leases"."property_id"
  INNER JOIN "public"."rent_percentages"
    ON "public"."leases"."id" = "public"."rent_percentages"."lease_id"
  INNER JOIN "public"."sales_entry"
    ON "public"."leases"."id" = "public"."sales_entry"."lease_id"
  LEFT OUTER JOIN "public"."tenants"
    ON "public"."leases"."primaryTenantId" = "public"."tenants"."id"
  WHERE 
    (("public"."rent_percentages"."overage_start_date" < CURRENT_DATE AND "public"."rent_percentages"."overage_end_date" > CURRENT_DATE)
    OR ("public"."rent_percentages"."overage_start_date" < CURRENT_DATE AND "public"."rent_percentages"."overage_end_date" IS NULL))
    AND "public"."properties"."name" IN (@Property_Name)
    AND "public"."properties"."company_relation_id" = @REAL_COMPANY_ID
    AND ("public"."leases"."deleted_at" >= CURRENT_DATE OR "public"."leases"."deleted_at" IS NULL)
    AND ("public"."rent_percentages"."deleted_at" >= CURRENT_DATE OR "public"."rent_percentages"."deleted_at" IS NULL)
    AND ("public"."sales_entry"."deleted_at" >= CURRENT_DATE OR "public"."sales_entry"."deleted_at" IS NULL)
    AND "public"."sales_entry"."transaction_date" >= (CURRENT_DATE - INTERVAL '13 months')
),
MONTH_SALES AS (
  SELECT 
    "LEASE_ID",
    "LEASE_NAME",
    "start",
    "lease_end",
    "overage_start_date",
    "overage_end_date",
    "MONTHS_FRECUENCY",
    "ITEM_ID",
    "TYPE_REQUIRED",
    STRING_AGG(DISTINCT "UNIT_ID"::TEXT, '/') AS "UNIT_ID",
    STRING_AGG(DISTINCT "TENANT", '/') AS "TENANT",
    SUM(CASE WHEN TO_CHAR("transaction_date", 'YYYY-MM') = TO_CHAR(CURRENT_DATE - INTERVAL '0 month', 'YYYY-MM') THEN "sales_volume" ELSE 0 END) AS "current_month",
    SUM(CASE WHEN TO_CHAR("transaction_date", 'YYYY-MM') = TO_CHAR(CURRENT_DATE - INTERVAL '1 month', 'YYYY-MM') THEN "sales_volume" ELSE 0 END) AS "previous_month_1",
    SUM(CASE WHEN TO_CHAR("transaction_date", 'YYYY-MM') = TO_CHAR(CURRENT_DATE - INTERVAL '2 months', 'YYYY-MM') THEN "sales_volume" ELSE 0 END) AS "previous_month_2",
    SUM(CASE WHEN TO_CHAR("transaction_date", 'YYYY-MM') = TO_CHAR(CURRENT_DATE - INTERVAL '3 months', 'YYYY-MM') THEN "sales_volume" ELSE 0 END) AS "previous_month_3",
    SUM(CASE WHEN TO_CHAR("transaction_date", 'YYYY-MM') = TO_CHAR(CURRENT_DATE - INTERVAL '4 months', 'YYYY-MM') THEN "sales_volume" ELSE 0 END) AS "previous_month_4",
    SUM(CASE WHEN TO_CHAR("transaction_date", 'YYYY-MM') = TO_CHAR(CURRENT_DATE - INTERVAL '5 months', 'YYYY-MM') THEN "sales_volume" ELSE 0 END) AS "previous_month_5",
    SUM(CASE WHEN TO_CHAR("transaction_date", 'YYYY-MM') = TO_CHAR(CURRENT_DATE - INTERVAL '6 months', 'YYYY-MM') THEN "sales_volume" ELSE 0 END) AS "previous_month_6",
    SUM(CASE WHEN TO_CHAR("transaction_date", 'YYYY-MM') = TO_CHAR(CURRENT_DATE - INTERVAL '7 months', 'YYYY-MM') THEN "sales_volume" ELSE 0 END) AS "previous_month_7",
    SUM(CASE WHEN TO_CHAR("transaction_date", 'YYYY-MM') = TO_CHAR(CURRENT_DATE - INTERVAL '8 months', 'YYYY-MM') THEN "sales_volume" ELSE 0 END) AS "previous_month_8",
    SUM(CASE WHEN TO_CHAR("transaction_date", 'YYYY-MM') = TO_CHAR(CURRENT_DATE - INTERVAL '9 months', 'YYYY-MM') THEN "sales_volume" ELSE 0 END) AS "previous_month_9",
    SUM(CASE WHEN TO_CHAR("transaction_date", 'YYYY-MM') = TO_CHAR(CURRENT_DATE - INTERVAL '10 months', 'YYYY-MM') THEN "sales_volume" ELSE 0 END) AS "previous_month_10",
    SUM(CASE WHEN TO_CHAR("transaction_date", 'YYYY-MM') = TO_CHAR(CURRENT_DATE - INTERVAL '11 months', 'YYYY-MM') THEN "sales_volume" ELSE 0 END) AS "previous_month_11",
    SUM(CASE WHEN TO_CHAR("transaction_date", 'YYYY-MM') = TO_CHAR(CURRENT_DATE - INTERVAL '12 months', 'YYYY-MM') THEN "sales_volume" ELSE 0 END) AS "previous_month_12",
    SUBSTRING(TO_CHAR(CURRENT_DATE, 'Month'), 1, 3) AS "current_month_name",
    SUBSTRING(TO_CHAR(CURRENT_DATE - INTERVAL '1 month', 'Month'), 1, 3) AS "previous_month_1_name",
    SUBSTRING(TO_CHAR(CURRENT_DATE - INTERVAL '2 months', 'Month'), 1, 3) AS "previous_month_2_name",
    SUBSTRING(TO_CHAR(CURRENT_DATE - INTERVAL '3 months', 'Month'), 1, 3) AS "previous_month_3_name",
    SUBSTRING(TO_CHAR(CURRENT_DATE - INTERVAL '4 months', 'Month'), 1, 3) AS "previous_month_4_name",
    SUBSTRING(TO_CHAR(CURRENT_DATE - INTERVAL '5 months', 'Month'), 1, 3) AS "previous_month_5_name",
    SUBSTRING(TO_CHAR(CURRENT_DATE - INTERVAL '6 months', 'Month'), 1, 3) AS "previous_month_6_name",
    SUBSTRING(TO_CHAR(CURRENT_DATE - INTERVAL '7 months', 'Month'), 1, 3) AS "previous_month_7_name",
    SUBSTRING(TO_CHAR(CURRENT_DATE - INTERVAL '8 months', 'Month'), 1, 3) AS "previous_month_8_name",
    SUBSTRING(TO_CHAR(CURRENT_DATE - INTERVAL '9 months', 'Month'), 1, 3) AS "previous_month_9_name",
    SUBSTRING(TO_CHAR(CURRENT_DATE - INTERVAL '10 months', 'Month'), 1, 3) AS "previous_month_10_name",
    SUBSTRING(TO_CHAR(CURRENT_DATE - INTERVAL '11 months', 'Month'), 1, 3) AS "previous_month_11_name",
    SUBSTRING(TO_CHAR(CURRENT_DATE - INTERVAL '12 months', 'Month'), 1, 3) AS "previous_month_12_name"
  FROM LEASES_SALES
  GROUP BY 
    "LEASE_ID",
    "LEASE_NAME",
    "start",
    "lease_end",
    "overage_start_date",
    "overage_end_date",
    "MONTHS_FRECUENCY",
    "ITEM_ID",
    "TYPE_REQUIRED"
)
SELECT * FROM MONTH_SALES;

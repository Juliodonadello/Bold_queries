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
    "public"."lease_units"."unit_id" AS "UNIT_ID",  		
    "public"."tenants"."name" AS "TENANT",
    "public"."units"."name" AS "UNIT_NAME",
    "public"."units"."total_square_footage" AS "UNIT_SQ_FT",
    "public"."properties"."name" AS "PROP_NAME"

  FROM "public"."leases"
  INNER JOIN "public"."lease_units"
    ON "public"."leases"."id" = "public"."lease_units"."lease_id"
  INNER JOIN "public"."units"
    ON "public"."units"."id" = "public"."lease_units"."unit_id"
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
    AND CAST("public"."properties"."company_relation_id" AS TEXT) = CAST(@REAL_COMPANY_ID AS TEXT)
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
    "PROP_NAME",
    STRING_AGG(DISTINCT "UNIT_NAME"::TEXT, '/') AS "UNIT_NAME",
    MAX("UNIT_SQ_FT") AS "UNIT_SQ_FT",
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
    SUBSTRING(TO_CHAR(CURRENT_DATE - INTERVAL '12 months', 'Month'), 1, 3) AS "previous_month_12_name",
    
    CURRENT_DATE AS "current_month_date",
    CURRENT_DATE - INTERVAL '1 month' AS "previous_month_1_date",
    CURRENT_DATE - INTERVAL '2 months' AS "previous_month_2_date",
    CURRENT_DATE - INTERVAL '3 months' AS "previous_month_3_date",
    CURRENT_DATE - INTERVAL '4 months' AS "previous_month_4_date",
    CURRENT_DATE - INTERVAL '5 months' AS "previous_month_5_date",
    CURRENT_DATE - INTERVAL '6 months' AS "previous_month_6_date",
    CURRENT_DATE - INTERVAL '7 months' AS "previous_month_7_date",
    CURRENT_DATE - INTERVAL '8 months' AS "previous_month_8_date",
    CURRENT_DATE - INTERVAL '9 months' AS "previous_month_9_date",
    CURRENT_DATE - INTERVAL '10 months' AS "previous_month_10_date",
    CURRENT_DATE - INTERVAL '11 months' AS "previous_month_11_date",
    CURRENT_DATE - INTERVAL '12 months' AS "previous_month_12_date"


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
    "TYPE_REQUIRED",
    "PROP_NAME"
)
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
"PROP_NAME",
"UNIT_NAME",
"UNIT_SQ_FT",
"TENANT",
"current_month_name","previous_month_1_name","previous_month_2_name","previous_month_3_name","previous_month_4_name","previous_month_5_name","previous_month_6_name",
"previous_month_7_name","previous_month_8_name", "previous_month_9_name","previous_month_10_name","previous_month_11_name","previous_month_12_name",
CASE WHEN "current_month_date" < ("overage_start_date" + INTERVAL '1 day') OR "current_month_date" > "overage_end_date" THEN '   ' --Not Required
      WHEN "current_month_date" >= "overage_start_date" AND "current_month_date" <= "overage_end_date" AND "current_month" > 0 THEN 'CER' -- Sales Registered
      WHEN "current_month_date" >= "overage_start_date" AND "current_month_date" <= "overage_end_date" AND ("current_month" = 0 or "current_month" is null) THEN ' * ' -- Sales missing
      ELSE 'Not_end' --Not configured
END AS "status_current_month",
CASE WHEN "previous_month_1_date" < ("overage_start_date" + INTERVAL '1 day') OR "previous_month_1_date" > "overage_end_date" THEN '   ' --Not Required
      WHEN "previous_month_1_date" >= "overage_start_date" AND "previous_month_1_date" <= "overage_end_date" AND "previous_month_1" > 0 THEN 'CER' -- Sales Registered
      WHEN "previous_month_1_date" >= "overage_start_date" AND "previous_month_1_date" <= "overage_end_date" AND ("previous_month_1" = 0 or "previous_month_1" is null) THEN ' * ' -- Sales missing
      ELSE 'Not_end' --Not configured
END AS "status_previous_month_1",
CASE WHEN "previous_month_2_date" < ("overage_start_date" + INTERVAL '1 day') OR "previous_month_2_date" > "overage_end_date" THEN '   ' --Not Required
      WHEN "previous_month_2_date" >= "overage_start_date" AND "previous_month_2_date" <= "overage_end_date" AND "previous_month_2" > 0 THEN 'CER' -- Sales Registered
      WHEN "previous_month_2_date" >= "overage_start_date" AND "previous_month_2_date" <= "overage_end_date" AND ("previous_month_2" = 0 or "previous_month_2" is null) THEN ' * ' -- Sales missing
      ELSE 'Not_end' --Not configured
END AS "status_previous_month_2",
CASE WHEN "previous_month_3_date" < ("overage_start_date" + INTERVAL '1 day') OR "previous_month_3_date" > "overage_end_date" THEN '   ' --Not Required
      WHEN "previous_month_3_date" >= "overage_start_date" AND "previous_month_3_date" <= "overage_end_date" AND "previous_month_3" > 0 THEN 'CER' -- Sales Registered
      WHEN "previous_month_3_date" >= "overage_start_date" AND "previous_month_3_date" <= "overage_end_date" AND ("previous_month_3" = 0 or "previous_month_3" is null) THEN ' * ' -- Sales missing
      ELSE 'Not_end' --Not configured
END AS "status_previous_month_3",
CASE WHEN "previous_month_4_date" < ("overage_start_date" + INTERVAL '1 day') OR "previous_month_4_date" > "overage_end_date" THEN '   ' --Not Required
      WHEN "previous_month_4_date" >= "overage_start_date" AND "previous_month_4_date" <= "overage_end_date" AND "previous_month_4" > 0 THEN 'CER' -- Sales Registered
      WHEN "previous_month_4_date" >= "overage_start_date" AND "previous_month_4_date" <= "overage_end_date" AND ("previous_month_4" = 0 or "previous_month_4" is null) THEN ' * ' -- Sales missing
      ELSE 'Not_end' --Not configured
END AS "status_previous_month_4",
CASE WHEN "previous_month_5_date" < ("overage_start_date" + INTERVAL '1 day') OR "previous_month_5_date" > "overage_end_date" THEN '   ' --Not Required
      WHEN "previous_month_5_date" >= "overage_start_date" AND "previous_month_5_date" <= "overage_end_date" AND "previous_month_5" > 0 THEN 'CER' -- Sales Registered
      WHEN "previous_month_5_date" >= "overage_start_date" AND "previous_month_5_date" <= "overage_end_date" AND ("previous_month_5" = 0 or "previous_month_5" is null) THEN ' * ' -- Sales missing
      ELSE 'Not_end' --Not configured
END AS "status_previous_month_5",
CASE WHEN "previous_month_6_date" < ("overage_start_date" + INTERVAL '1 day') OR "previous_month_6_date" > "overage_end_date" THEN '   ' --Not Required
      WHEN "previous_month_6_date" >= "overage_start_date" AND "previous_month_6_date" <= "overage_end_date" AND "previous_month_6" > 0 THEN 'CER' -- Sales Registered
      WHEN "previous_month_6_date" >= "overage_start_date" AND "previous_month_6_date" <= "overage_end_date" AND ("previous_month_6" = 0 or "previous_month_6" is null) THEN ' * ' -- Sales missing
      ELSE 'Not_end' --Not configured
END AS "status_previous_month_6",
CASE WHEN "previous_month_7_date" < ("overage_start_date" + INTERVAL '1 day') OR "previous_month_7_date" > "overage_end_date" THEN '   ' --Not Required
      WHEN "previous_month_7_date" >= "overage_start_date" AND "previous_month_7_date" <= "overage_end_date" AND "previous_month_7" > 0 THEN 'CER' -- Sales Registered
      WHEN "previous_month_7_date" >= "overage_start_date" AND "previous_month_7_date" <= "overage_end_date" AND ("previous_month_7" = 0 or "previous_month_7" is null) THEN ' * ' -- Sales missing
      ELSE 'Not_end' --Not configured
END AS "status_previous_month_7",
CASE WHEN "previous_month_8_date" < ("overage_start_date" + INTERVAL '1 day') OR "previous_month_8_date" > "overage_end_date" THEN '   ' --Not Required
      WHEN "previous_month_8_date" >= "overage_start_date" AND "previous_month_8_date" <= "overage_end_date" AND "previous_month_8" > 0 THEN 'CER' -- Sales Registered
      WHEN "previous_month_8_date" >= "overage_start_date" AND "previous_month_8_date" <= "overage_end_date" AND ("previous_month_8" = 0 or "previous_month_8" is null) THEN ' * ' -- Sales missing
      ELSE 'Not_end' --Not configured
END AS "status_previous_month_8",
CASE WHEN "previous_month_9_date" < ("overage_start_date" + INTERVAL '1 day') OR "previous_month_9_date" > "overage_end_date" THEN '   ' --Not Required
      WHEN "previous_month_9_date" >= "overage_start_date" AND "previous_month_9_date" <= "overage_end_date" AND "previous_month_9" > 0 THEN 'CER' -- Sales Registered
      WHEN "previous_month_9_date" >= "overage_start_date" AND "previous_month_9_date" <= "overage_end_date" AND ("previous_month_9" = 0 or "previous_month_9" is null) THEN ' * ' -- Sales missing
      ELSE 'Not_end' --Not configured
END AS "status_previous_month_9",
CASE WHEN "previous_month_10_date" < ("overage_start_date" + INTERVAL '1 day') OR "previous_month_10_date" > "overage_end_date" THEN '   ' --Not Required
      WHEN "previous_month_10_date" >= "overage_start_date" AND "previous_month_10_date" <= "overage_end_date" AND "previous_month_10" > 0 THEN 'CER' -- Sales Registered
      WHEN "previous_month_10_date" >= "overage_start_date" AND "previous_month_10_date" <= "overage_end_date" AND ("previous_month_10" = 0 or "previous_month_10" is null) THEN ' * ' -- Sales missing
      ELSE 'Not_end' --Not configured
END AS "status_previous_month_10",
CASE WHEN "previous_month_11_date" < ("overage_start_date" + INTERVAL '1 day') OR "previous_month_11_date" > "overage_end_date" THEN '   ' --Not Required
      WHEN "previous_month_11_date" >= "overage_start_date" AND "previous_month_11_date" <= "overage_end_date" AND "previous_month_11" > 0 THEN 'CER' -- Sales Registered
      WHEN "previous_month_11_date" >= "overage_start_date" AND "previous_month_11_date" <= "overage_end_date" AND ("previous_month_11" = 0 or "previous_month_11" is null) THEN ' * ' -- Sales missing
      ELSE 'Not_end' --Not configured
END AS "status_previous_month_11",
CASE WHEN "previous_month_12_date" < ("overage_start_date" + INTERVAL '1 day') OR "previous_month_12_date" > "overage_end_date" THEN '   ' --Not Required
      WHEN "previous_month_12_date" >= "overage_start_date" AND "previous_month_12_date" <= "overage_end_date" AND "previous_month_12" > 0 THEN 'CER' -- Sales Registered
      WHEN "previous_month_12_date" >= "overage_start_date" AND "previous_month_12_date" <= "overage_end_date" AND ("previous_month_12" = 0 or "previous_month_12" is null) THEN ' * ' -- Sales missing
      ELSE 'Not_end' --Not configured
END AS "status_previous_month_12"


FROM MONTH_SALES


WITH SALES AS (
  SELECT
"public"."sales_entry"."id",
DATE_PART('year' , "public"."sales_entry"."transaction_date") AS "YEAR",
DATE_PART('month' , "public"."sales_entry"."transaction_date") AS "MONTH",
TRIM(TO_CHAR("public"."sales_entry"."transaction_date", 'Month')) AS "MONTH_NAME",
"public"."sales_entry"."transaction_date",
"public"."sales_entry"."transaction_type",
 CASE WHEN "public"."sales_entry"."transaction_type" LIKE '%Month%' THEN 'Monthly'
  			WHEN "public"."sales_entry"."transaction_type" LIKE '%Year%' THEN 'Annual'
			ELSE '-'
			END AS "transaction_type_group",
"public"."sales_entry"."sales_type",
--"public"."sales_entry"."sales_date",
"public"."sales_entry"."sales_category",
--"public"."sales_entry"."report_date",
"public"."sales_entry"."sales_volume",
"public"."sales_entry"."unit_id",
"public"."units"."name" "UNIT_NAME",
"public"."sales_entry"."lease_id",
"public"."leases"."name" "LEASE_NAME",
"public"."sales_entry"."tenant_id",
"public"."tenants"."name" "TENANT_NAME",
"public"."properties"."name" "PROP_NAME",
"public"."properties"."id" "PROP_ID",
"public"."sales_entry"."company_relation_id",
"public"."leases"."start" "LEASE_START",
"public"."leases"."end" "LEASE_END"

FROM "public"."sales_entry"
INNER JOIN "public"."units" 
    ON "public"."units"."id"="public"."sales_entry"."unit_id"
    AND "public"."units"."company_relation_id"="public"."sales_entry"."company_relation_id"
INNER JOIN "public"."tenants" ON "public"."tenants"."id"="public"."sales_entry"."tenant_id"
INNER JOIN "public"."properties" 
    ON "public"."properties"."id"="public"."units"."property_id"
    AND "public"."properties"."company_relation_id"="public"."units"."company_relation_id"
INNER JOIN "public"."leases" ON "public"."leases"."id"="public"."sales_entry"."lease_id"
	
WHERE CAST("public"."properties"."company_relation_id" AS INT) = CAST(@REAL_COMPANY_ID AS INT)
  AND "public"."sales_entry"."transaction_date" >= CURRENT_DATE - INTERVAL '4 years'
  AND "public"."sales_entry"."transaction_date" <= CURRENT_DATE
  AND "public"."leases"."name" IN (@Lease_Name)
  AND "public"."properties"."name" IN (@Property_Name)
  AND "public"."sales_entry"."sales_type" IN (@Sales_Type)
  AND "public"."sales_entry"."sales_category" IN (@Sales_Category)
),
Lease_History AS ( 
  SELECT 
  SALES."YEAR",
  SALES."MONTH",
  SALES."MONTH_NAME",
  SALES."transaction_type",
  SALES."transaction_type_group",
  SALES."sales_type",
  SALES."sales_category",
  SALES."unit_id",
  SALES."UNIT_NAME",
  SALES."lease_id",
  SALES."LEASE_NAME",
  SALES."tenant_id",
  SALES."TENANT_NAME",
  SALES."company_relation_id",
  SALES."PROP_NAME",
  SUM(SALES."sales_volume") "MONTHLY_AMOUNT"

  FROM SALES

  GROUP BY 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15
  ORDER BY  SALES."YEAR" DESC
),
Annual_Lease_History AS (
  SELECT 
	Lease_History."YEAR",
	Lease_History."transaction_type_group",
	Lease_History."lease_id",
	Lease_History."LEASE_NAME",
	Lease_History."PROP_NAME",
	Lease_History."company_relation_id",
	SUM(Lease_History."MONTHLY_AMOUNT") "ANNUAL_AMOUNT"
  FROM Lease_History
  GROUP BY 1,2,3,4,5,6
),
Lease_History_With_Variation AS (
  SELECT 
	ALH.*,
	LAG(ALH."ANNUAL_AMOUNT") OVER (PARTITION BY ALH."lease_id", ALH."transaction_type_group"  ORDER BY ALH."YEAR") AS "PREV_ANNUAL_AMOUNT",
	(ALH."ANNUAL_AMOUNT" - LAG(ALH."ANNUAL_AMOUNT") OVER (PARTITION BY ALH."lease_id", ALH."transaction_type_group"  ORDER BY ALH."YEAR")) / LAG(ALH."ANNUAL_AMOUNT") OVER (PARTITION BY ALH."lease_id", ALH."transaction_type_group" ORDER BY ALH."YEAR") AS "PERCENTAGE_VARIATION"
  FROM Annual_Lease_History ALH
), 
FINAL AS (
  SELECT 
  SALES."YEAR",
  SALES."MONTH",
  SALES."MONTH_NAME",
  SALES."transaction_type",
  SALES."transaction_type_group",
  SALES."sales_type",
  SALES."sales_category",
  SALES."unit_id",
  SALES."UNIT_NAME",
  SALES."lease_id",
  SALES."LEASE_NAME",
  SALES."tenant_id",
  SALES."TENANT_NAME",
  SALES."company_relation_id",
  SALES."PROP_NAME",
  Lease_History_With_Variation."PREV_ANNUAL_AMOUNT",
  Lease_History_With_Variation."PERCENTAGE_VARIATION",
  SUM(SALES."sales_volume") "MONTHLY_AMOUNT",
  MIN(SALES."LEASE_START") "LEASE_START" ,
   MAX(SALES."LEASE_END") "LEASE_END"

  FROM SALES
  LEFT JOIN Lease_History_With_Variation
	  ON Lease_History_With_Variation."YEAR" = SALES."YEAR"
	  AND Lease_History_With_Variation."transaction_type_group" = SALES."transaction_type_group"
	  AND Lease_History_With_Variation."lease_id" = SALES."lease_id"
	  AND Lease_History_With_Variation."LEASE_NAME" = SALES."LEASE_NAME"
	  AND Lease_History_With_Variation."PROP_NAME" = SALES."PROP_NAME"
	  AND Lease_History_With_Variation."company_relation_id" = SALES."company_relation_id"

  WHERE CAST(SALES."transaction_type_group" AS TEXT) IN (@Transaction_Type)

  GROUP BY 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17
  ORDER BY  SALES."YEAR" DESC
),
AUX AS (
	  SELECT 'January' AS "MONTH_NAME" 
  		UNION ALL
	  SELECT 'February' UNION ALL
	  SELECT 'March' UNION ALL
	  SELECT 'April' UNION ALL
	  SELECT 'May' UNION ALL
	  SELECT 'June' UNION ALL
	  SELECT 'July' UNION ALL
	  SELECT 'August' UNION ALL
	  SELECT 'September' UNION ALL
	  SELECT 'October' UNION ALL
	  SELECT 'November' UNION ALL
	  SELECT 'December'
)
SELECT 
AUX."MONTH_NAME" AS"MONTH_NAME" ,
FINAL."transaction_type",
FINAL."transaction_type_group",
FINAL."sales_type",
FINAL."sales_category",
FINAL."unit_id",
FINAL."UNIT_NAME",
FINAL."lease_id",
FINAL."LEASE_NAME",
FINAL."tenant_id",
FINAL."TENANT_NAME",
FINAL."PROP_NAME",
FINAL."LEASE_START",
FINAL."LEASE_END",
SUM(CASE WHEN CAST(FINAL."YEAR" AS INT) = 2024 THEN FINAL."MONTHLY_AMOUNT" ELSE 0 END) "2024",
SUM(CASE WHEN CAST(FINAL."YEAR" AS INT) = 2023 THEN FINAL."MONTHLY_AMOUNT" ELSE 0 END) "2023",
SUM(CASE WHEN CAST(FINAL."YEAR" AS INT) = 2022 THEN FINAL."MONTHLY_AMOUNT" ELSE 0 END) "2022",
--FINAL."PREV_ANNUAL_AMOUNT",
MAX(CASE WHEN CAST(FINAL."YEAR" AS INT) = 2024 THEN FINAL."PERCENTAGE_VARIATION" ELSE NULL END) "2024_variation",
MAX(CASE WHEN CAST(FINAL."YEAR" AS INT) = 2023 THEN FINAL."PERCENTAGE_VARIATION" ELSE NULL END) "2023_variation"
--,MAX(CASE WHEN CAST(FINAL."PERCENTAGE_VARIATION" AS INT) = 2022 THEN FINAL."MONTHLY_AMOUNT" ELSE NULL END) "2022" -- si pongo else 0 el max me pisa las variation negativas


FROM AUX
  LEFT  JOIN FINAL
  ON CAST(AUX."MONTH_NAME" AS TEXT) = CAST(FINAL."MONTH_NAME" AS TEXT)

--where FINAL."company_relation_id" = @REAL_COMPANY_ID

GROUP BY 1,2,3,4,5,6,7,8,9,10,11,12,13,14

ORDER BY 
  CASE AUX."MONTH_NAME"
    WHEN 'January' THEN 1
    WHEN 'February' THEN 2
    WHEN 'March' THEN 3
    WHEN 'April' THEN 4
    WHEN 'May' THEN 5
    WHEN 'June' THEN 6
    WHEN 'July' THEN 7
    WHEN 'August' THEN 8
    WHEN 'September' THEN 9
    WHEN 'October' THEN 10
    WHEN 'November' THEN 11
    WHEN 'December' THEN 12
  END


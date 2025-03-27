WITH date_series AS (
    SELECT generate_series(
                   @From_Date::DATE - INTERVAL '1 month',
                   @To_Date::DATE,
                   INTERVAL '1 month'
           )::DATE AS month
),
CHARGES_TOT AS MATERIALIZED (
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
        AND "lease_recurring_charges"."order_entry_item_id" in (@Item_Id)
        AND "public"."properties"."name" IN (@Property_Name)
        AND CAST("public"."properties"."company_relation_id" AS INT) = CAST(@REAL_COMPANY_ID AS INT)
  		AND ("lease_recurring_charge_amounts"."effective_date" <= "public"."leases"."end" OR "public"."leases"."end" is NULL)
),
charged_amounts AS (
    SELECT
        ds."month",
        ct."LEASE_ID",
        ct."EFFECTIVE_DATE",
        ct."AMOUNT" AS "AMOUNT_OLD",
  		-- proration in lease end calculation
  		CASE 
  				WHEN ct."FREQUENCY" = 'Annually' THEN ct."AMOUNT" / 12
  				WHEN ( EXTRACT(MONTH FROM ds."month") = EXTRACT(MONTH FROM ct."LEASE_END") 
				   			 AND EXTRACT(YEAR FROM ds."month") = EXTRACT(YEAR FROM ct."LEASE_END")  
					 		 AND 31 = EXTRACT(DAY FROM ct."LEASE_END") ) then ct."AMOUNT"
  				WHEN ( EXTRACT(MONTH FROM ds."month") = EXTRACT(MONTH FROM ct."LEASE_END") 
				   			 AND EXTRACT(YEAR FROM ds."month") = EXTRACT(YEAR FROM ct."LEASE_END")) then ct."AMOUNT" * EXTRACT(DAY FROM ct."LEASE_END") / 31	
  				WHEN ( EXTRACT(MONTH FROM ds."month") = EXTRACT(MONTH FROM ct."EFFECTIVE_DATE") 
				   			 AND EXTRACT(YEAR FROM ds."month") = EXTRACT(YEAR FROM ct."EFFECTIVE_DATE")  
					 		 AND 1 = EXTRACT(DAY FROM ct."EFFECTIVE_DATE") ) then ct."AMOUNT"
				WHEN ( EXTRACT(MONTH FROM ds."month") = EXTRACT(MONTH FROM ct."EFFECTIVE_DATE") 
								 AND EXTRACT(YEAR FROM ds."month") = EXTRACT(YEAR FROM ct."EFFECTIVE_DATE") ) then ct."AMOUNT" * (31-EXTRACT(DAY FROM ct."EFFECTIVE_DATE")+1) / 31	 --FALTA RELLENAR CON LOS DIAS CON EL EFFECTIVE DATE ANTERIOR 
                ELSE ct."AMOUNT" 
  		END AS "AMOUNT",
  		--end proration in lease end
        ct."ITEM_ID",
        ct."PROP_ID",
        ct."UNIT_ID",
        ROW_NUMBER() OVER (PARTITION BY ct."LEASE_ID", ct."ITEM_ID", ds."month" ORDER BY ct."EFFECTIVE_DATE" DESC) AS "rn",
  		ct."LEASE_END" 
    FROM
        date_series ds
    CROSS JOIN CHARGES_TOT ct
    WHERE 
  		(
  		(ct."FREQUENCY" <> 'One Time' AND EXTRACT(YEAR FROM ds."month")*100+EXTRACT(MONTH FROM ds."month") >= EXTRACT(YEAR FROM ct."EFFECTIVE_DATE")*100+EXTRACT(MONTH FROM ct."EFFECTIVE_DATE"))
		  OR
		(ct."FREQUENCY" = 'One Time' AND EXTRACT(YEAR FROM ds."month")*100+EXTRACT(MONTH FROM ds."month") = EXTRACT(YEAR FROM ct."EFFECTIVE_DATE")*100+EXTRACT(MONTH FROM ct."EFFECTIVE_DATE"))
		 )
  		AND (ct."LEASE_END" >= ds."month" or ct."LEASE_END" is null)
        AND (ct."RCHARGE_END" >= ds."month" or ct."RCHARGE_END" is NULL)
),
q_units_aux as (
  select "month",
        "LEASE_ID",
        "EFFECTIVE_DATE",
        "ITEM_ID",
        "PROP_ID",
  		"LEASE_END",
  		COUNT("UNIT_ID") "Q_UNITS"
  	FROM charged_amounts
  group by 1,2,3,4,5,6
),
compact_units_aux AS (
    SELECT
        ca."month",
        ca."LEASE_ID",
        ca."EFFECTIVE_DATE",
        ca."ITEM_ID",
        ca."PROP_ID",
		ca."LEASE_END",
        --ct."UNIT_ID",
		MIN(ca."rn") AS "rn",
		SUM(ca."AMOUNT_OLD") AS "AMOUNT_OLD",
		SUM(ca."AMOUNT") AS "AMOUNT"
  		
	FROM charged_amounts AS ca
	GROUP BY 1,2,3,4,5,6	
), 
charged_amounts_with_prev AS (
    SELECT
        ca."month",
        ca."LEASE_ID",
        ca."EFFECTIVE_DATE",
        ca."ITEM_ID",
        ca."PROP_ID",
        ca."LEASE_END",
  		ca."rn",
        ca."AMOUNT",
        LAG(ca."AMOUNT") OVER (
            PARTITION BY ca."LEASE_ID", ca."ITEM_ID"
            ORDER BY ca."month"
        ) AS "AMOUNT_OLD"
    FROM compact_units_aux ca
    WHERE ca."rn" = '1'
),
final_ca as (
    select charged_amounts_with_prev.*,
    CASE WHEN ( EXTRACT(MONTH FROM "month") = EXTRACT(MONTH FROM "EFFECTIVE_DATE") 
                            AND EXTRACT(YEAR FROM "month") = EXTRACT(YEAR FROM "EFFECTIVE_DATE") 
                            AND '1' != EXTRACT(DAY FROM "EFFECTIVE_DATE")
                            AND ("AMOUNT_OLD" IS NULL) ) 
                then  "AMOUNT" --( "AMOUNT" * ((EXTRACT(DAY FROM "EFFECTIVE_DATE")-1)) / 31 ) 								-- proration for first effective date in the charge 
            WHEN ( EXTRACT(MONTH FROM "month") = EXTRACT(MONTH FROM "EFFECTIVE_DATE") 
                            AND EXTRACT(YEAR FROM "month") = EXTRACT(YEAR FROM "EFFECTIVE_DATE") 
                            AND '1' != EXTRACT(DAY FROM "EFFECTIVE_DATE") ) 
                then "AMOUNT" + ( "AMOUNT_OLD" * ((EXTRACT(DAY FROM "EFFECTIVE_DATE")-1)) / 31 ) -- filling proration with previous charged amount 
                ELSE "AMOUNT"
                END AS "PRORATED_AMOUNT"
    from charged_amounts_with_prev
    where charged_amounts_with_prev."rn" = 1 and "month" >= @From_Date
),
charged_amounts_2 AS (
	SELECT  charged_amounts."month",
        charged_amounts."LEASE_ID",
        charged_amounts."EFFECTIVE_DATE",
        charged_amounts."ITEM_ID",
        charged_amounts."PROP_ID",
  		charged_amounts."LEASE_END",
  		SUM(charged_amounts."AMOUNT") "AMOUNT_OLD",
  		SUM(charged_amounts."PRORATED_AMOUNT") "AMOUNT"
  		
	FROM final_ca as charged_amounts
  		INNER JOIN q_units_aux	
  			ON q_units_aux."month" = charged_amounts."month"
			  AND q_units_aux."LEASE_ID" = charged_amounts."LEASE_ID"
			  AND q_units_aux."EFFECTIVE_DATE" = charged_amounts."EFFECTIVE_DATE"
			  AND q_units_aux."ITEM_ID" = charged_amounts."ITEM_ID"
			  AND q_units_aux."PROP_ID" = charged_amounts."PROP_ID"
			  AND q_units_aux."LEASE_END" = charged_amounts."LEASE_END"
  	WHERE "rn"  <= q_units_aux."Q_UNITS"
  	GROUP BY 1,2,3,4,5,6
  	ORDER BY 1
),
FINAL_TO_PIVOT AS (
    SELECT
        ds."month" as "TIME_STAMP",
        EXTRACT(MONTH FROM ds."month") AS "MONTH",
        EXTRACT(YEAR FROM ds."month") AS "YEAR",
        ca."LEASE_ID",
        COALESCE(ca."AMOUNT", 0) AS "AMOUNT",
        ca."ITEM_ID",
        ca."PROP_ID"
        --        ca."UNIT_ID"
    FROM date_series ds
    LEFT JOIN charged_amounts_2 ca 
  		ON ds."month" = ca."month" --AND ca."rn" = 1
    ORDER BY ca."PROP_ID", ca."LEASE_ID", ca."ITEM_ID", ds."month"
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
    FINAL_TO_PIVOT as fp
INNER JOIN "public"."leases" ON fp."LEASE_ID" = "public"."leases"."id"
INNER JOIN "public"."tenants" ON "public"."tenants"."id" = "public"."leases"."primaryTenantId"
INNER JOIN "public"."properties" ON fp."PROP_ID" = "public"."properties"."id"

WHERE CAST("public"."leases"."status" AS TEXT) IN (@Lease_Status)
	AND CASE WHEN CAST("public"."leases"."month_to_month" AS TEXT) ='true' THEN 'True' ELSE 'False' END IN (@month_to_month) 

GROUP BY
    1, 2, 3, 4, 5, 6
ORDER BY
    1, 2, 4

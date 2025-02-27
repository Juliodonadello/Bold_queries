WITH RECURSIVE date_series AS (
    SELECT  (DATE_TRUNC('year', @AsOfDate::DATE) - INTERVAL '1 month')::DATE as month
    UNION ALL
    SELECT (month + INTERVAL '1 month')::DATE
    FROM date_series
    WHERE month + INTERVAL '1 month' <= DATE_TRUNC('year', @AsOfDate::DATE) + INTERVAL '1 year' - INTERVAL '1 day'
),
CHARGE_CONTROL AS (
  	SELECT 
  			"public"."properties"."id" AS "PROP_ID",
  			"public"."property_charge_controls"."item_id" as "ITEM_ID",
  			CASE WHEN "public"."property_charge_controls"."base_rent" then 1 else 0 end as "BASE_RENT",
            CASE WHEN "public"."property_charge_controls"."item_id" LIKE '%TICAM%' then 1 else 0 end as "TICAM",
            CASE WHEN "public"."property_charge_controls"."item_id" LIKE '%TRUE UP%' then 1 else 0 end as "TRUE_UP", 
            CASE WHEN "public"."property_charge_controls"."item_id" LIKE '%RENT CONCESSIONS%' then 1 else 0 end as "RENT_CONCESSIONS"
  		
  	FROM "public"."properties"
  	INNER JOIN "public"."property_charge_controls"
  		ON "public"."property_charge_controls"."property_id" = "public"."properties"."id"
  	
  	WHERE "public"."properties"."name" IN (@Property_Name)
	AND CAST("public"."properties"."company_relation_id" AS INT)  = CAST(@REAL_COMPANY_ID AS INT)
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
  		"lease_recurring_charges"."terminate_date" AS "RCHARGE_END",
  		CHARGE_CONTROL."BASE_RENT",
  		CHARGE_CONTROL."TICAM",
  		CHARGE_CONTROL."TRUE_UP",
        CHARGE_CONTROL."RENT_CONCESSIONS"
  
  
    FROM "public"."lease_recurring_charges"
    INNER JOIN "public"."lease_recurring_charge_amounts"
        ON "lease_recurring_charges"."id" = "lease_recurring_charge_amounts"."recurring_charge_id"
    INNER JOIN "public"."units"
        ON "lease_recurring_charges"."unit_id" =  "units"."id"
    INNER JOIN "public"."properties"
        ON "units"."property_id" =  "properties"."id"
  	INNER JOIN "public"."leases" 
  		ON "lease_recurring_charges"."lease_id" = "public"."leases"."id"
    INNER JOIN CHARGE_CONTROL
  		ON CHARGE_CONTROL."PROP_ID" = "public"."units"."property_id"
  		AND CHARGE_CONTROL."ITEM_ID" = "public"."lease_recurring_charges"."order_entry_item_id"
  
    WHERE "lease_recurring_charge_amounts"."effective_date" <= DATE_TRUNC('year', @AsOfDate::DATE) + INTERVAL '1 year' - INTERVAL '1 day'
        AND ("lease_recurring_charge_amounts"."deleted_at" >= DATE_TRUNC('year', @AsOfDate::DATE) OR "lease_recurring_charge_amounts"."deleted_at" IS NULL)
        AND ("lease_recurring_charges"."deleted_at" >= DATE_TRUNC('year', @AsOfDate::DATE) OR "lease_recurring_charges"."deleted_at" IS NULL)
        AND (CHARGE_CONTROL."BASE_RENT" = 1 OR CHARGE_CONTROL."TICAM" = 1 OR CHARGE_CONTROL."TRUE_UP" = 1)
        AND "public"."properties"."name" IN (@Property_Name)
        AND CAST("public"."properties"."company_relation_id" AS INT) = CAST(@REAL_COMPANY_ID AS INT)
  		AND ("lease_recurring_charge_amounts"."effective_date" <= "public"."leases"."end" OR "public"."leases"."end" is NULL)
),
charged_amounts AS (
    SELECT
        ds."month",
        ct."LEASE_ID",
        ct."EFFECTIVE_DATE",
  		ct."AMOUNT" as "AMOUNT_OLD",
  		-- proration in lease end calculation
  		CASE 
  				WHEN ct."FREQUENCY" = 'Annually' THEN ct."AMOUNT" / 12
  				WHEN ( EXTRACT(MONTH FROM ds."month") = EXTRACT(MONTH FROM ct."LEASE_END") 
				   			 AND EXTRACT(YEAR FROM ds."month") = EXTRACT(YEAR FROM ct."LEASE_END")  
					 		 AND 31 = EXTRACT(DAY FROM ct."LEASE_END") ) then ct."AMOUNT"
  				WHEN ( EXTRACT(MONTH FROM ds."month") = EXTRACT(MONTH FROM ct."LEASE_END") 
				   			 AND EXTRACT(YEAR FROM ds."month") = EXTRACT(YEAR FROM ct."LEASE_END")) then ct."AMOUNT" * EXTRACT(DAY FROM ct."LEASE_END") / 31
                WHEN ( EXTRACT(MONTH FROM ds."month") = EXTRACT(MONTH FROM ct."RCHARGE_END") 
				   			 AND EXTRACT(YEAR FROM ds."month") = EXTRACT(YEAR FROM ct."RCHARGE_END")) then ct."AMOUNT" * EXTRACT(DAY FROM ct."RCHARGE_END") / 31	
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
  		ct."LEASE_END" , 
  		ct."BASE_RENT",
  		ct."TICAM",
  		ct."TRUE_UP",
        ct."RENT_CONCESSIONS"
    FROM
        date_series ds
    CROSS JOIN CHARGES_TOT ct
    WHERE (EXTRACT(YEAR FROM ds."month")*100+EXTRACT(MONTH FROM ds."month") >= EXTRACT(YEAR FROM ct."EFFECTIVE_DATE")*100+EXTRACT(MONTH FROM ct."EFFECTIVE_DATE"))
  		AND (ct."LEASE_END" >= ds."month" or ct."LEASE_END" is null)
  		AND (ct."RCHARGE_END" >= ds."month" or ct."RCHARGE_END" is null)
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
  		ca."BASE_RENT",
  		ca."TICAM",
  		ca."TRUE_UP",
        ca."RENT_CONCESSIONS",
		MIN(ca."rn") AS "rn",
		SUM(ca."AMOUNT_OLD") AS "AMOUNT_OLD",
		SUM(ca."AMOUNT") AS "AMOUNT"
  		
	FROM charged_amounts AS ca
	GROUP BY 1,2,3,4,5,6,7,8,9,10
	
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
  		ca."BASE_RENT",
  		ca."TICAM",
  		ca."TRUE_UP",
        ca."RENT_CONCESSIONS",
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
where "rn" = 1 and "month" >= DATE_TRUNC('year', @AsOfDate::DATE)
),
charged_amounts_2 AS (
	SELECT  charged_amounts."month",
        charged_amounts."LEASE_ID",
        charged_amounts."EFFECTIVE_DATE",
        charged_amounts."ITEM_ID",
        charged_amounts."PROP_ID",
  		charged_amounts."LEASE_END",
  		charged_amounts."BASE_RENT",
  		charged_amounts."TICAM",
  		charged_amounts."TRUE_UP",
        charged_amounts."RENT_CONCESSIONS",
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
  	GROUP BY 1,2,3,4,5,6,7,8,9, 10
  	ORDER BY 1
),
FINAL_TO_PIVOT AS (
    SELECT
        ds."month" as "TIME_STAMP",
        EXTRACT(MONTH FROM ds."month") AS "MONTH",
        EXTRACT(YEAR FROM ds."month") AS "YEAR",
        ca."LEASE_ID",
        SUM(COALESCE(ca."AMOUNT", 0)) AS "AMOUNT",
        ca."ITEM_ID",
        ca."PROP_ID",
  		ca."BASE_RENT",
  		ca."TICAM",
  		ca."TRUE_UP",
        ca."RENT_CONCESSIONS"
        --ca."UNIT_ID"
    FROM
        date_series ds
    LEFT JOIN charged_amounts_2 ca ON ds."month" = ca."month"
  GROUP BY 1,2,3,4,6,7,8,9,10,11
    ORDER BY ca."PROP_ID", ca."LEASE_ID", ca."ITEM_ID", ds."month"
)
SELECT
    "public"."leases"."id" as "LEASE_ID",
	"public"."leases"."name" as "LEASE_NAME",
    "public"."properties"."name" AS "property_name",
    "public"."leases"."name",
    "public"."leases"."start",
    "public"."leases"."end",
    "public"."tenants"."name" AS "tenants_name",
     --fp."ITEM_ID",
 
    -- Cálculo de Total Months Occupied
    CASE 
        WHEN EXTRACT(YEAR FROM "public"."leases"."move_in") < EXTRACT(YEAR FROM @AsOfDate) AND EXTRACT(YEAR FROM "public"."leases"."end") = EXTRACT(YEAR FROM @AsOfDate) 
            THEN EXTRACT(MONTH FROM "public"."leases"."end")
        WHEN EXTRACT(YEAR FROM "public"."leases"."move_in") < EXTRACT(YEAR FROM @AsOfDate) THEN 12
        WHEN EXTRACT(YEAR FROM "public"."leases"."move_in") = EXTRACT(YEAR FROM @AsOfDate) AND EXTRACT(YEAR FROM "public"."leases"."end") > EXTRACT(YEAR FROM @AsOfDate)
            THEN 12 - EXTRACT(MONTH FROM "public"."leases"."move_in") + 1
        WHEN EXTRACT(YEAR FROM "public"."leases"."move_in") = EXTRACT(YEAR FROM @AsOfDate) AND EXTRACT(YEAR FROM "public"."leases"."end") = EXTRACT(YEAR FROM @AsOfDate)
            THEN EXTRACT(MONTH FROM "public"."leases"."end") - EXTRACT(MONTH FROM "public"."leases"."move_in") + 1
        ELSE 0
    END AS "Total Months Occupied",

    SUM(CASE WHEN DATE_TRUNC('month', @AsOfDate + INTERVAL '0 month') = DATE_TRUNC('month', fp."TIME_STAMP") AND fp."TICAM" = 1 AND fp."TRUE_UP" = 0 
        THEN fp."AMOUNT" ELSE 0 END) AS "Estimated_Monthly_TICAM",
   
      
    SUM(CASE WHEN DATE_TRUNC('year', DATE_TRUNC('year', @AsOfDate::DATE)) = DATE_TRUNC('year', fp."TIME_STAMP") AND fp."BASE_RENT" = 1 THEN fp."AMOUNT" ELSE 0 END) AS "Gross Base Rent Paid",
	SUM(CASE WHEN DATE_TRUNC('year', DATE_TRUNC('year', @AsOfDate::DATE)) = DATE_TRUNC('year', fp."TIME_STAMP") AND fp."TICAM" = 1 AND fp."TRUE_UP" = 0 THEN fp."AMOUNT" ELSE 0 END) AS "Estimated TICAM Paid",
	SUM(CASE WHEN DATE_TRUNC('year', DATE_TRUNC('year', @AsOfDate::DATE)) = DATE_TRUNC('year', fp."TIME_STAMP") AND fp."TRUE_UP" = 1 THEN fp."AMOUNT" ELSE 0 END) AS "TICAM True Up Paid",
	EXTRACT(YEAR FROM DATE_TRUNC('year', @AsOfDate::DATE)) AS "year_1_name"
    
FROM
    FINAL_TO_PIVOT as fp
INNER JOIN "public"."leases" ON fp."LEASE_ID" = "public"."leases"."id"
INNER JOIN "public"."tenants" ON "public"."tenants"."id" = "public"."leases"."primaryTenantId"
INNER JOIN "public"."properties" ON fp."PROP_ID" = "public"."properties"."id"

WHERE  CAST("public"."leases"."status" AS TEXT) IN (@Lease_Status)
	--AND "public"."leases"."name" = 'PCY13-2030KIEW' --'PCY01-2049ABC'
    AND fp."TIME_STAMP" <= DATE_TRUNC('year', @AsOfDate::DATE) + INTERVAL '1 year' - INTERVAL '1 day'

GROUP BY
    1, 2, 3, 4, 5, 6, 7, 8 --, 9
ORDER BY
    2, 3



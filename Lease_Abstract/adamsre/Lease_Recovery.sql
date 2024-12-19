SELECT "public"."leases"."id" as "LEASE_ID",
"public"."leases"."name" as "LEASE_NAME",
"public"."properties"."name" as "PROP_NAME",
"public"."properties"."company_relation_id",
CASE 	WHEN "public"."leases"."month_to_month" = 'False' THEN 'NO'
					WHEN "public"."leases"."month_to_month" = 'True' THEN 'YES'
		END AS "M_t_M",
"public"."lease_recurring_charges"."order_entry_item_id",
"public"."lease_recurring_charges"."recovery_control_id",
"public"."lease_recovery_control"."name" AS "lease_recovery_control_name",
"public"."lease_recovery_control"."calculation_control_base_year",
"public"."lease_recovery_control"."calculation_control_base_amount",
"public"."recovery_control_expense_category"."manual_percent" 

FROM "public"."leases"
INNER JOIN "public"."properties"
  		ON "public"."properties"."id" =  "public"."leases"."property_id"
INNER JOIN "public"."lease_recurring_charges" 
	ON "public"."leases"."id"="public"."lease_recurring_charges"."lease_id" 
INNER JOIN "public"."lease_recovery_control" 
	ON "public"."lease_recurring_charges"."recovery_control_id"="public"."lease_recovery_control"."id" 
LEFT OUTER JOIN "public"."recovery_control_expense_category" 
	ON "public"."lease_recovery_control"."id"="public"."recovery_control_expense_category"."lease_recovery_control_id"

WHERE  	(("public"."lease_recovery_control"."calculation_control_base_year" IS NOT NULL)
	   			OR 
		 		("public"."lease_recovery_control"."calculation_control_base_amount" IS NOT NULL)
		 		OR 
		 		("public"."recovery_control_expense_category"."manual_percent" IS NOT NULL)
	   			)
		AND "public"."properties"."name" IN (@Property_Name)
		AND CAST("public"."properties"."company_relation_id" AS INT)  = CAST(@REAL_COMPANY_ID AS INT)
		AND (
					"public"."lease_recurring_charges"."deleted_at" >= @AsOfDate
					OR
					"public"."lease_recurring_charges"."deleted_at" IS NULL
					)
		AND (
					"public"."leases"."deleted_at" >= @AsOfDate
					OR
					"public"."leases"."deleted_at" IS NULL
					)
		/*AND (
					"public"."leases"."end" >= @AsOfDate
					OR
					"public"."leases"."end" IS NULL
					)
		*/
		AND (
					"public"."lease_recovery_control"."deleted_at" >= @AsOfDate
					OR
					"public"."lease_recovery_control"."deleted_at" IS NULL
					)
		AND (
					"public"."recovery_control_expense_category"."deleted_at" >= @AsOfDate
					OR
					"public"."recovery_control_expense_category"."deleted_at" IS NULL
					)
		AND (CASE WHEN "public"."leases"."month_to_month" = 'False' THEN 'NO'
							WHEN "public"."leases"."month_to_month" = 'True' THEN 'YES'
				END) IN (@month_to_month)
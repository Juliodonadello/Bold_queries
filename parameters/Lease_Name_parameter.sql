SELECT 
		distinct "public"."leases"."name" as "LEASE_NAME"
  
	FROM "public"."lease_recurring_charges"
	INNER JOIN "public"."lease_recurring_charge_amounts"
		ON "public"."lease_recurring_charges"."id" = "public"."lease_recurring_charge_amounts"."recurring_charge_id"
 	INNER JOIN "public"."units"
  		ON "public"."lease_recurring_charges"."unit_id" =  "public"."units"."id"
 	INNER JOIN "public"."properties"
  		ON "public"."properties"."id" =  "public"."units"."property_id"
  	INNER JOIN "public"."leases"
  		ON "public"."leases"."id"  = "public"."lease_recurring_charges"."lease_id" 
  
  	WHERE --"public"."lease_recurring_charge_amounts"."effective_date" <= @AsOfDate 
  	"public"."properties"."name" IN (@Property_Name)
	AND CAST("public"."properties"."company_relation_id" AS INT)  = CAST(@REAL_COMPANY_ID AS INT)
  	AND CASE 
  					WHEN "public"."leases"."status" = 'current' THEN 'Current'
					WHEN "public"."leases"."status" = 'canceled' THEN 'Canceled'
					WHEN "public"."leases"."status" = 'terminated' THEN 'Terminated'
					WHEN "public"."leases"."status" = 'future' THEN 'Future'
					ELSE 'null' 
			END  IN (@Lease_Status)
  	AND
	 (
		"public"."lease_recurring_charge_amounts"."deleted_at" >= @AsOfDate 
		OR 
		"public"."lease_recurring_charge_amounts"."deleted_at" IS NULL
		)
	AND (
		"public"."lease_recurring_charge_amounts"."frequency" != 'One Time' --not a one time charge
		OR
		(
			"public"."lease_recurring_charge_amounts"."frequency" = 'One Time'
			AND	 CAST(EXTRACT(DAY FROM (@AsOfDate - "public"."lease_recurring_charge_amounts"."effective_date")) AS INTEGER) > 0
		  	AND CAST(EXTRACT(DAY FROM (@AsOfDate - "public"."lease_recurring_charge_amounts"."effective_date")) AS INTEGER) < 31
		)--one time charge with less than a month differnce
		)
	AND (	
	  	"public"."lease_recurring_charges"."terminate_date" >= @AsOfDate
		OR
		"public"."lease_recurring_charges"."terminate_date" IS NULL 
		)
	AND (
		"public"."lease_recurring_charges"."deleted_at" >= @AsOfDate
		OR
		"public"."lease_recurring_charges"."deleted_at" IS NULL
		)
  	--AND "public"."leases"."start" <= @AsOfDate 
	AND (
		"public"."leases"."end" >= @AsOfDate
		OR
		"public"."leases"."end" IS NULL
		)

order by 1 desc
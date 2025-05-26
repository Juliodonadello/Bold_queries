
WITH CHARGE_CONTROL AS (
  	SELECT 
  			"public"."properties"."id" AS "PROP_ID",
  			"public"."property_charge_controls"."item_id" as "ITEM_ID",
  			CASE WHEN "public"."property_charge_controls"."base_rent" then 1 else 0 end as "BASE_RENT"
  		
  	FROM "public"."properties"
  	INNER JOIN "public"."property_charge_controls"
  		ON "public"."property_charge_controls"."property_id" = "public"."properties"."id"
  	
  	WHERE "public"."properties"."name" IN (@Property_Name)
	AND CAST("public"."properties"."company_relation_id" AS INT) = CAST(@REAL_COMPANY_ID AS INT)
	),
RENT_SCALATIONS AS (
  SELECT 
  		"public"."lease_recurring_charges"."lease_id" AS "LEASE_ID",
  		CASE WHEN CHARGE_CONTROL."BASE_RENT" = 1 THEN 1 ELSE 0 END AS "FLAG_RENT_SCAL",
		CASE WHEN CHARGE_CONTROL."BASE_RENT" = 1 THEN "public"."lease_recurring_charge_amounts"."amount" ELSE 0 END AS "RENT_CHARGE_SCAL",
  		"public"."lease_recurring_charge_amounts"."effective_date" AS "EFFECTIVE_DATE_SCAL",
  		"public"."units"."property_id" "PROP_ID",
  		"public"."lease_recurring_charges"."unit_id" "UNIT_ID",
		MAX(COALESCE(uq."value", "public"."units"."total_square_footage")) AS "UNIT_SQ_FT"

  
	FROM "public"."lease_recurring_charges"
	LEFT OUTER JOIN "public"."lease_recurring_charge_amounts"
		ON "public"."lease_recurring_charges"."id" = "public"."lease_recurring_charge_amounts"."recurring_charge_id"
 	INNER JOIN "public"."units"
  		ON "public"."lease_recurring_charges"."unit_id" =  "public"."units"."id"
  	INNER JOIN CHARGE_CONTROL
  		ON CHARGE_CONTROL. "PROP_ID" = "public"."units"."property_id"
  		AND CHARGE_CONTROL. "ITEM_ID" = "public"."lease_recurring_charges"."order_entry_item_id"
	INNER JOIN "public"."properties"
		ON "public"."properties"."id" = "public"."units"."property_id"
	LEFT JOIN (
		SELECT DISTINCT ON ("unit_id") 
		"unit_id",
		"value",
		"as_of_date"
		FROM "public"."unit_square_footage_items"
		WHERE "square_footage_type" = 'Total'
		AND "as_of_date" <= @AsOfDate
		AND "public"."unit_square_footage_items"."deleted_at" IS NULL
		ORDER BY "unit_id", "as_of_date" DESC
	) AS uq
		ON uq."unit_id" = "public"."units"."id"
  
  	WHERE "public"."lease_recurring_charge_amounts"."effective_date" > @AsOfDate
	AND (
		"public"."lease_recurring_charge_amounts"."deleted_at" > @AsOfDate 
		OR 
		"public"."lease_recurring_charge_amounts"."deleted_at" IS NULL
		)
	AND (
		"public"."lease_recurring_charges"."deleted_at" > @AsOfDate
		OR
		"public"."lease_recurring_charges"."deleted_at" IS NULL
		)
	AND (
		"public"."lease_recurring_charge_amounts"."frequency" != 'One Time' --not a one time charge 
		)
	AND (	
	  	"public"."lease_recurring_charges"."terminate_date" > @AsOfDate
		OR
		"public"."lease_recurring_charges"."terminate_date" is NULL 
		)
	AND (	
	  	"public"."lease_recurring_charges"."deleted_at" > @AsOfDate
		OR
		"public"."lease_recurring_charges"."deleted_at" is NULL 
		)
	AND "public"."properties"."name" IN (@Property_Name)
  	AND CHARGE_CONTROL. "BASE_RENT" = 1
  	AND "public"."units"."status" = 'active'
		
	GROUP BY 
		"public"."lease_recurring_charges"."lease_id",
  		CASE WHEN CHARGE_CONTROL."BASE_RENT" = 1 THEN 1 ELSE 0 END,
		CASE WHEN CHARGE_CONTROL."BASE_RENT" = 1 THEN "public"."lease_recurring_charge_amounts"."amount" ELSE 0 END,
		"public"."lease_recurring_charge_amounts"."effective_date",
		"public"."units"."property_id",
		"public"."lease_recurring_charges"."unit_id"
	ORDER BY 
			"public"."units"."property_id",
			"public"."lease_recurring_charges"."unit_id",
			"public"."lease_recurring_charges"."lease_id",
			"public"."lease_recurring_charge_amounts"."effective_date" ASC
	)
SELECT 
	RENT_SCALATIONS."PROP_ID",
	RENT_SCALATIONS."UNIT_ID",
	RENT_SCALATIONS."LEASE_ID",
	RENT_SCALATIONS."RENT_CHARGE_SCAL",
	RENT_SCALATIONS."EFFECTIVE_DATE_SCAL",
	RENT_SCALATIONS."UNIT_SQ_FT"

FROM RENT_SCALATIONS

ORDER BY RENT_SCALATIONS."PROP_ID",
	RENT_SCALATIONS."UNIT_ID",
	RENT_SCALATIONS."LEASE_ID",
	RENT_SCALATIONS."UNIT_SQ_FT",
	RENT_SCALATIONS."EFFECTIVE_DATE_SCAL" ASC

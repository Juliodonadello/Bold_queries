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
    AND "public"."property_charge_controls"."item_id" IN (@Item_Id)
),
CHARGES_TOT AS (
  SELECT 
  		"public"."lease_recurring_charges"."lease_id" AS "LEASE_ID",
  		"public"."lease_recurring_charge_amounts"."effective_date" AS "EFFECTIVE_DATE",
  		"public"."lease_recurring_charge_amounts"."amount" AS "AMOUNT",
        "public"."lease_recurring_charges"."order_entry_item_id" AS "ITEM_ID",
  		"public"."units"."property_id" AS "PROP_ID",
        "public"."lease_recurring_charges"."unit_id" AS "UNIT_ID"
  
	FROM "public"."lease_recurring_charges"
	INNER JOIN "public"."lease_recurring_charge_amounts"
		ON "public"."lease_recurring_charges"."id" = "public"."lease_recurring_charge_amounts"."recurring_charge_id"
 	INNER JOIN "public"."units"
  		ON "public"."lease_recurring_charges"."unit_id" =  "public"."units"."id"
  	INNER JOIN CHARGE_CONTROL
  		ON CHARGE_CONTROL. "PROP_ID" = "public"."units"."property_id"
  		AND CHARGE_CONTROL. "ITEM_ID" = "public"."lease_recurring_charges"."order_entry_item_id"
    INNER JOIN "public"."properties"
        ON "public"."properties"."id" = "public"."units"."property_id"
  
  	WHERE ("public"."lease_recurring_charge_amounts"."effective_date" <= @To_Date AND "public"."lease_recurring_charge_amounts"."effective_date" >= @From_Date)
        AND ("public"."lease_recurring_charge_amounts"."deleted_at" >= @To_Date OR "public"."lease_recurring_charge_amounts"."deleted_at" IS NULL)
        AND ("public"."lease_recurring_charges"."deleted_at" >= @To_Date OR "public"."lease_recurring_charges"."deleted_at" IS NULL)
        AND ("public"."lease_recurring_charges"."terminate_date" >= @To_Date OR "public"."lease_recurring_charges"."terminate_date" is NULL)
        AND ("public"."lease_recurring_charge_amounts"."frequency" != 'One Time' --not one time chargeS
            OR
            ("public"."lease_recurring_charge_amounts"."frequency" = 'One Time'
            AND	 CAST(EXTRACT(DAY FROM (@From_Date - "public"."lease_recurring_charge_amounts"."effective_date")) AS INTEGER) > 0
            AND CAST(EXTRACT(DAY FROM (@From_Date - "public"."lease_recurring_charge_amounts"."effective_date")) AS INTEGER) < 31
            )--one time charge with less than a month difference
            )
        AND CAST("public"."properties"."company_relation_id" AS INT) = CAST(@REAL_COMPANY_ID AS INT)
        AND "public"."properties"."name" IN (@Property_Name)
)

SELECT *
FROM CHARGES_TOT
ORDER BY 5,1,2
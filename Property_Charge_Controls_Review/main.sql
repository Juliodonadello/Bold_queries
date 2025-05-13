SELECT 
	 "public"."properties"."name" AS "properties_name",
	 "public"."property_charge_controls"."item_id" AS "item_id"
	 ,CASE when "public"."property_charge_controls"."base_rent" is TRUE then 'YES' ELSE '-' END AS "base_rent_text"
	 ,CASE when "public"."property_charge_controls"."subject_to_mgmt_fees" is TRUE then 'YES' ELSE '-' END AS "subject_to_mgmt_fees_text"
	 ,CASE when "public"."property_charge_controls"."subject_to_late_charges" is TRUE then 'YES' ELSE '-' END AS "subject_to_late_charges_text"
	 ,cast("public"."property_charge_controls"."base_rent" as int) AS "base_rent_flag"
	 ,cast("public"."property_charge_controls"."subject_to_mgmt_fees" as int) AS "subject_to_mgmt_fees_flag"
	 ,cast("public"."property_charge_controls"."subject_to_late_charges" as int) AS "subject_to_late_charges_flag"
	 


FROM "public"."properties"
INNER  JOIN "public"."property_charge_controls" ON "public"."property_charge_controls"."property_id"="public"."properties"."id"

WHERE  CAST("public"."properties"."company_relation_id" AS INT) = CAST(@REAL_COMPANY_ID AS INT)
    AND "public"."properties"."name" IN (@Property_Name)
	AND  "public"."property_charge_controls"."deleted_at" IS NULL
	
order by 1,2 asc
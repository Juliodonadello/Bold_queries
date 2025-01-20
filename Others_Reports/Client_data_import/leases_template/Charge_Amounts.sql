SELECT 
CONCAT(
        "public"."leases"."name", ' - ',
        "public"."lease_recurring_charges"."order_entry_item_id", ' - ',
        "public"."units"."unit_location_id", ' - ',
        "public"."lease_recurring_charges"."billToTenant"
    ) AS "ID",
"public"."lease_recurring_charge_amounts"."effective_date",
TO_CHAR("public"."lease_recurring_charge_amounts"."effective_date", 'MM/DD/YYYY') AS "formatted_date",
"public"."lease_recurring_charge_amounts"."amount",
"public"."lease_recurring_charge_amounts"."frequency"

FROM "public"."leases" 
INNER JOIN "public"."properties" 
	ON "public"."properties"."id"="public"."leases"."property_id"
INNER JOIN "public"."lease_recurring_charges" 
	ON "public"."lease_recurring_charges"."lease_id"="public"."leases"."id"
INNER JOIN "public"."units" 
	ON "public"."properties"."id"="public"."units"."property_id"
INNER JOIN "public"."lease_recurring_charge_amounts" 
	ON "public"."lease_recurring_charges"."id"="public"."lease_recurring_charge_amounts"."recurring_charge_id"
	
WHERE "public"."properties"."name" IN (@Property_Name)
AND "public"."units"."deleted_at" IS NULL
AND "public"."leases"."deleted_at" IS NULL
AND "public"."lease_recurring_charges"."deleted_at" IS NULL
AND  "public"."lease_recurring_charge_amounts"."deleted_at" is NULL
	
GROUP BY 1,2,3,4,5
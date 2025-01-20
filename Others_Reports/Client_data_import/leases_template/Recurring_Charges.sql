SELECT 
CONCAT(
        "public"."leases"."name", ' - ',
        "public"."lease_recurring_charges"."order_entry_item_id", ' - ',
        "public"."units"."unit_location_id", ' - ',
        "public"."lease_recurring_charges"."billToTenant"
    ) AS "ID",
"public"."leases"."name",
"public"."lease_recurring_charges"."order_entry_item_id",
"public"."units"."unit_location_id",
--"public"."lease_recurring_charges"."billToTenant",
"public"."tenants"."tenant_id",
CASE WHEN "public"."lease_recurring_charges"."subject_to_rent_percentage" IS TRUE THEN 'TRUE' ELSE 'FALSE' END AS "subject_to_rent_percentage",
"public"."lease_recurring_charges"."next_date",
"public"."lease_recurring_charges"."terminate_date",
"public"."lease_recurring_charges"."square_footage"

FROM "public"."leases" 
INNER JOIN "public"."properties" 
	ON "public"."properties"."id"="public"."leases"."property_id"
INNER JOIN "public"."lease_recurring_charges" 
	ON "public"."lease_recurring_charges"."lease_id"="public"."leases"."id"
INNER JOIN "public"."units" 
	ON "public"."properties"."id"="public"."units"."property_id"
INNER JOIN "public"."tenants"
	ON "public"."tenants"."id" = "public"."lease_recurring_charges"."billToTenant"
	
WHERE "public"."properties"."name" IN (@Property_Name)
AND "public"."units"."deleted_at" IS NULL
AND "public"."leases"."deleted_at" IS NULL
AND "public"."lease_recurring_charges"."deleted_at" IS NULL
AND "public"."tenants"."deleted_at" IS NULL
	
GROUP BY 1,2,3,4,5,6,7,8,9
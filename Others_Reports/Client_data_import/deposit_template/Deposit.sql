SELECT 
"public"."leases"."name" as "lease_name",
"public"."tenants"."tenant_id",
"public"."tenants"."name" as "tenant_name",
"public"."units"."unit_location_id",
"public"."units"."name" as "unit_name",
"public"."lease_deposits"."type" as "deposit_type",
CASE WHEN "public"."lease_deposits"."refundable" IS TRUE THEN 'Yes' else 'No' END AS "refundable",
"public"."lease_deposits"."invoice_number" as "invoice_number"

FROM "public"."lease_deposits" 
INNER JOIN "public"."leases" 
	ON "public"."leases"."id"="public"."lease_deposits"."lease_id"
INNER JOIN "public"."units" 
	ON "public"."units"."id"="public"."lease_deposits"."unit_id"
INNER JOIN "public"."tenants" 
	ON "public"."tenants"."id"="public"."lease_deposits"."tenant_id"
INNER JOIN "public"."properties" 
	ON "public"."properties"."id"="public"."leases"."property_id"
	
WHERE "public"."properties"."name" IN (@Property_Name)
AND "public"."properties"."deleted_at" IS NULL
AND "public"."units"."deleted_at" IS NULL
AND "public"."leases"."deleted_at" IS NULL
AND "public"."lease_deposits"."deleted_at" IS NULL
	
GROUP BY 1,2,3,4,5,6,7,8
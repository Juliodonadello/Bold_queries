SELECT 
CASE WHEN "public"."leases"."status" = 'current' THEN 'Current'
		  WHEN "public"."leases"."status" = 'canceled' THEN 'Canceled'
		  WHEN "public"."leases"."status" = 'terminated' THEN 'Terminated'
		  WHEN "public"."leases"."status" = 'future' THEN 'Future'
		  ELSE 'null' 
END AS "LEASE_STATUS"
FROM "public"."leases"
INNER  JOIN "public"."lease_units" ON "public"."leases"."id"="public"."lease_units"."lease_id"
INNER  JOIN "public"."units" ON "public"."units"."id"="public"."lease_units"."unit_id"
--INNER  JOIN "public"."tenants" ON "public"."tenants"."id"="public"."leases"."primaryTenantId"
INNER  JOIN "public"."properties" ON "public"."units"."property_id"="public"."properties"."id"

WHERE -- "public"."leases"."end" IS NOT NULL  AND
    CAST("public"."properties"."company_relation_id" AS INT) = CAST(@REAL_COMPANY_ID AS INT)
    AND "public"."properties"."name" IN (@Property_Name)
    
GROUP BY "public"."leases"."status" 
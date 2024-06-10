SELECT "public"."leases"."status" "LEASE_STATUS"

FROM "public"."leases"
INNER  JOIN "public"."leases_units_units" ON "public"."leases"."id"="public"."leases_units_units"."leasesId"
INNER  JOIN "public"."units" ON "public"."units"."id"="public"."leases_units_units"."unitsId"
INNER  JOIN "public"."tenants" ON "public"."tenants"."id"="public"."leases"."primaryTenantId"
INNER  JOIN "public"."properties" ON "public"."units"."property_id"="public"."properties"."id"
INNER  JOIN "public"."company_accounts" ON "public"."properties"."company_relation_id"="public"."company_accounts"."id"

WHERE  "public"."leases"."end" IS NOT NULL
    AND CAST("public"."properties"."company_relation_id" AS INT) = CAST(@REAL_COMPANY_ID AS INT)
    AND "public"."properties"."name" IN (@Property_Name)
    
    
GROUP BY "public"."leases"."status" 
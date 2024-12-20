SELECT distinct "public"."leases"."status" "LEASE_STATUS"

FROM "public"."leases"
INNER  JOIN "public"."leases_units_units" ON "public"."leases"."id"="public"."leases_units_units"."leasesId"
INNER  JOIN "public"."units" ON "public"."units"."id"="public"."leases_units_units"."unitsId"
INNER  JOIN "public"."properties" ON "public"."units"."property_id"="public"."properties"."id"

WHERE CAST("public"."properties"."company_relation_id" AS INT) = CAST(@REAL_COMPANY_ID AS INT)
    AND "public"."properties"."name" IN (@Property_Name)
    
GROUP BY "public"."leases"."status" 
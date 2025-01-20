SELECT "public"."leases"."status" "LEASE_STATUS"

FROM "public"."leases"
INNER  JOIN "public"."lease_units" ON "public"."leases"."id"="public"."lease_units"."lease_id"
INNER  JOIN "public"."units" ON "public"."units"."id"="public"."lease_units"."unit_id"
INNER  JOIN "public"."properties" ON "public"."units"."property_id"="public"."properties"."id"

WHERE  CAST("public"."properties"."company_relation_id" AS INT) = CAST(@REAL_COMPANY_ID AS INT)
    AND "public"."properties"."name" IN (@Property_Name)
    
    
GROUP BY "public"."leases"."status" 
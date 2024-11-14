SELECT distinct "public"."leases"."name" as "Lease_Name"

FROM "public"."leases"
INNER  JOIN "public"."properties" ON "public"."leases"."property_id" = "public"."properties"."id"

WHERE  CAST("public"."properties"."company_relation_id" AS INT) = CAST(@REAL_COMPANY_ID AS INT)
    AND "public"."properties"."name" IN (@Property_Name)
	AND  CAST("public"."leases"."status" AS TEXT) IN (@Lease_Status)
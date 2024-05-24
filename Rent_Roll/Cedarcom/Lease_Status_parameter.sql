 SELECT "public"."leases"."status"
 
FROM "public"."leases"
INNER JOIN "public"."leases_units_units"
    ON "public"."leases"."id" ="public"."leases_units_units"."leasesId"

WHERE 
    (
        (	("public"."leases"."start" <= @AsOfDate AND "public"."leases"."end" > @AsOfDate)
            OR ("public"."leases"."start" <= @AsOfDate AND "public"."leases"."end" IS NULL)
        )
        AND "public"."leases"."status" = 'current'
        AND ("public"."leases"."deleted_at" >= @AsOfDate OR "public"."leases"."deleted_at" IS NULL)
    )
    OR
    (	"public"."leases"."start" <= @AsOfDate
        AND CAST("public"."leases"."status" AS TEXT) IN (@Lease_Status)
        AND ("public"."leases"."deleted_at" >= @AsOfDate OR "public"."leases"."deleted_at" IS NULL)
    )
  	
GROUP BY "public"."leases"."status"

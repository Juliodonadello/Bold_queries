SELECT "public"."lease_options"."leaseId" "LEASE_ID",
"public"."lease_options"."lease_category",
"public"."lease_options"."description",
"public"."lease_options"."note" 

FROM "public"."lease_options"
INNER JOIN "public"."properties" on "public"."properties"."id" = "public"."lease_options"."property_id"
		 
WHERE CAST("public"."properties"."company_relation_id" AS INT)  = CAST(@REAL_COMPANY_ID AS INT)
  AND "public"."properties"."name" IN (@Property_Name)
  AND "public"."lease_options"."expiration_date" >= @AsOfDate
  AND "public"."lease_options"."deleted_at" IS NULL
  AND "public"."properties"."deleted_at" IS NULL
 
 GROUP BY 1,2,3,4
  
ORDER BY 1, 4 ASC
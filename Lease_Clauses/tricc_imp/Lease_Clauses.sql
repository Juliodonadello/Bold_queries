SELECT "public"."lease_options"."id"             AS "Clause_id",
       "public"."lease_options"."lease_category" AS "clause_category",
       "public"."lease_options"."notification_date",
       "public"."lease_options"."expiration_date",
       --"public"."lease_options"."tenant_email",
       "public"."lease_options"."property_manager_email",
       "public"."lease_options"."description",
	   "public"."lease_options"."note",
       "public"."lease_options"."sent",
       "public"."lease_options"."leaseId",
       "public"."lease_options"."property_id",
       "public"."lease_options"."unit_id",
       "public"."properties"."name",
	   "public"."tenants"."name" as "TENANT_NAME",
	   MIN("public"."units"."name") as "UNIT_NAME",
	   "public"."leases"."status"  as "LEASE_STATUS"
	  
FROM "public"."lease_options"
         INNER JOIN "public"."leases" ON "public"."lease_options"."leaseId" = "public"."leases"."id"
         inner join "public"."properties" on "public"."properties"."id" = "public"."leases"."property_id"
		 LEFT JOIN "public"."tenants" on "public"."leases"."primaryTenantId" = "public"."tenants"."id"
		 INNER JOIN "public"."lease_units" on "public"."leases"."id" = "public"."lease_units"."lease_id"
		 INNER JOIN "public"."units" on "public"."lease_units"."unit_id" = "public"."units"."id"
		 
WHERE CAST("public"."properties"."company_relation_id" AS INT)  = CAST(@REAL_COMPANY_ID AS INT)
  AND "public"."properties"."name" IN (@Property_Name)
  and ("public"."lease_options"."expiration_date" > @FromDate and "public"."lease_options"."expiration_date" < @ToDate)
  --AND "public"."leases"."status" = 'current'
  AND CAST("public"."leases"."status" AS TEXT) IN (@Lease_Status) --Reatrieving operator error. Fix: Implementing a filter over the table layout using the parameter values
  
 GROUP BY "public"."lease_options"."id",
       "public"."lease_options"."lease_category",
       "public"."lease_options"."notification_date",
       "public"."lease_options"."expiration_date",
       "public"."lease_options"."property_manager_email",
       "public"."lease_options"."description",
       "public"."lease_options"."sent",
       "public"."lease_options"."leaseId",
       "public"."lease_options"."property_id",
       "public"."lease_options"."unit_id",
       "public"."properties"."name",
	   "public"."tenants"."name",
	   "public"."leases"."status"
  
ORDER BY "public"."lease_options"."lease_category"
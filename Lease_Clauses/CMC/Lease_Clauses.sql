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
       "public"."company_accounts"."company_id",
	   "public"."tenants"."name" as "TENANT_NAME",
	   MIN("public"."units"."name") as "UNIT_NAME",
	   "public"."leases"."status"  as "LEASE_STATUS"
	  
FROM "public"."lease_options"
         INNER JOIN "public"."leases" ON "public"."lease_options"."leaseId" = "public"."leases"."id"
         inner join "public"."company_accounts" on "public"."company_accounts".id = "public"."leases".company_relation_id
         inner join "public"."properties" on "public"."properties".id = "public"."leases".property_id
		 LEFT JOIN "public"."tenants" on "public"."leases"."primaryTenantId" = "public"."tenants"."id"
		 INNER JOIN "public"."leases_units_units" on "public"."leases"."id" = "public"."leases_units_units"."leasesId"
		 INNER JOIN "public"."units" on "public"."leases_units_units"."unitsId" = "public"."units"."id"
		 
WHERE "public"."company_accounts"."company_id" = @COMPANY_ID
  AND "public"."properties"."name" IN (@Property_Name)
  and ("public"."lease_options"."expiration_date" > @FromDate and "public"."lease_options"."expiration_date" < @ToDate)
  --AND "public"."leases"."status" = 'current'
  --AND "public"."leases"."status" IN (@Lease_Status) --Reatrieving operator error. Fix: Implementing a filter over the table layout using the parameter values
  
 GROUP BY "public"."lease_options"."id",
       "public"."lease_options"."lease_category",
       "public"."lease_options"."notification_date",
       "public"."lease_options"."expiration_date",
       "public"."lease_options"."property_manager_email",
       "public"."lease_options"."description",
       "public"."lease_options"."note",
       "public"."lease_options"."sent",
       "public"."lease_options"."leaseId",
       "public"."lease_options"."property_id",
       "public"."lease_options"."unit_id",
       "public"."properties"."name",
       "public"."company_accounts"."company_id",
	   "public"."tenants"."name",
	   "public"."leases"."status"
  
ORDER BY "public"."lease_options"."lease_category",
    "public"."units"."name"
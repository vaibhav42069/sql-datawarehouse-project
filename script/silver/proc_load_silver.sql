insert into [silver].[crm_cust_info] (
    cst_id,
    cst_key,
    cst_firstname,
    cst_lastname,
    cst_marital_status,
    cst_gndr,
    cst_create_date)
    
   select
       cst_id , 
       cst_key, 
	   trim(cst_firstname) as cst_firstname  ,
	   trim(cst_lastname) as cst_lastname , 
	   case when Trim(upper(cst_marital_status))  = 'S' then 'Single'
	        when Trim(Upper(cst_marital_status))  = 'M' then 'Married'
			else 'N/A' 
	   end cst_marital_status , 
	   case when trim(upper(cst_gndr)) = 'F' then 'Female' 
	        when trim(upper(cst_gndr)) = 'M' then 'Male'
			else 'N/A'
	   end cst_gndr, 
	   cst_create_date 
from 
  ( select * , 
  ROW_NUMBER()over(partition by cst_id order by cst_create_date desc ) as id 
  From [bronze].[crm_cust_info] where cst_id is not null )t
 where id = 1



 -------------------------


 INSERT INTO silver.crm_prd_info (
			prd_id,
			cat_id,
			prd_key,
			prd_nm,
			prd_cost,
			prd_line,
			prd_start_dt,
			prd_end_dt
)
select 
    prd_id,
    REPLACE(SUBSTRING(prd_key, 1,5), '-', '_') as cat_id,
	SUBSTRING(prd_key, 7, LEN(prd_key)) as prd_key,
    prd_nm,
    isnull (prd_cost,0) as prd_cost,
	case UPPER(TRIM(prd_line))
	     When 'M' Then 'Mountain'
		 When 'R' Then  'Road'
		 When 'S' Then 'Other Sale'
		 When 'T' Then 'Touring'
		 Else 'n/a'
    End as prd_line,
    prd_start_dt,
    cast(DATEADD(DAY, -1, LEAD(prd_start_dt) OVER (PARTITION BY prd_key ORDER BY prd_start_dt))as date)
	AS prd_end_dt
from [bronze].[crm_prd_info]	


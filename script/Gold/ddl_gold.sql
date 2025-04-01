create View gold.dim_customer
as 
	select
		row_number() over(order by cst_id) As customer_key,
		ci.cst_id As customer_id,
		ci.cst_key As customer_number,
		ci.cst_firstname As first_name,
		ci.cst_lastname As last_name,
		case
		  when ci.cst_gndr!='n/a' then ci.cst_gndr
		  else coalesce(ca.gen, 'n/a')
		end as Gender,
		ci.cst_marital_status AS marital_status,
		ci.cst_create_date As create_date,
		ca.bdate As Birthdate,
		la.cntry As country
	from [silver].[crm_cust_info] ci
	left join [silver].[erp_cust_az12] ca
	on  ci.cst_key=ca.cid
	left join [silver].[erp_loc_a101] la
	on  ci.cst_key=la.cid 
-----------------------------------------------------------------------------------------------------------------

create view gold.dim_products 
as
select
    ROW_NUMBER() over(order by prd_key,prd_start_dt) as product_key,
	pn.prd_id as product_id,
	pn.prd_key as product_number,
	pn.prd_nm as product_name,
	pn.cat_id as category_id,
	pc.cat as category,
	pc.subcat subcategory,
	pc.maintenance,
	pn.prd_cost as product_cost,
	pn.prd_line as product_line,
	pn.prd_start_dt as start_date
from silver.crm_prd_info pn
left join silver.erp_px_cat_g1v2 pc 
on  pn.cat_id=pc.id   
where prd_end_dt is null
-----------------------------------------------------------------------------------------------------------------

create view gold.fact_sales
as

select 
sd.sls_ord_num as order_number,
pr.product_key,
cu.customer_key,
sd.sls_order_dt as order_date,
sd.sls_ship_dt as ship_date,
sd.sls_due_dt as due_date,
sd.sls_sales as sales_amount,
sd.sls_quantity as quantity,
sd.sls_price as price
from silver.crm_sales_details sd
left join gold.dim_products pr 
on sd.sls_prd_key = pr.product_number
left join gold.dim_customer cu
on sd.sls_cust_id = cu.customer_id


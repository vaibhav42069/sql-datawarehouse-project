CREATE OR ALTER PROCEDURE silver.load_silver AS
BEGIN
 DECLARE @start_time DATETIME, @end_time DATETIME, @batch_start_time DATETIME, @batch_end_time DATETIME;
  BEGIN TRY
  SET @batch_start_time = GETDATE();
        PRINT '================================================';
        PRINT 'Loading Silver Layer';
        PRINT '================================================';

		PRINT '------------------------------------------------';
		PRINT 'Loading CRM Tables';
		PRINT '------------------------------------------------';

		-- Loading silver.crm_cust_info
        SET @start_time = GETDATE();
		PRINT '>> Truncating Table: silver.crm_cust_info';
	

    TRUNCATE TABLE silver.crm_cust_info;
	PRINT '>> Inserting Data Into: silver.crm_cust_info';
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
	 where id = 1;
	 SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '>> -------------';



	 -------------------------
	 -- Loading silver.crm_prd_info
	 SET @start_time = GETDATE();
		PRINT '>> Truncating Table: silver.crm_prd_info';
	
	 TRUNCATE TABLE silver.crm_prd_info;
	 		PRINT '>> Inserting Data Into: silver.crm_prd_info';
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
	from [bronze].[crm_prd_info];	

	        SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '>> -------------';

	------------------------------------------------------
	        -- Loading crm_sales_details
        SET @start_time = GETDATE();
		PRINT '>> Truncating Table: silver.crm_sales_details';
       TRUNCATE TABLE silver.crm_sales_details;
			PRINT '>> Inserting Data Into: silver.crm_sales_details';
			INSERT INTO silver.crm_sales_details (
				sls_cust_id,
				sls_prd_key,
				sls_order_dt,
				sls_ship_dt,
				sls_due_dt,
				sls_ord_num,
				sls_sales,
				sls_quantity,
				sls_price
	)
		
	  select	        
		sls_cust_id,
		sls_prd_key,
		case 
		when sls_order_dt =0 or len(sls_order_dt)!=8 then null
		else cast(cast(sls_order_dt as varchar) as date)
		end as sls_order_dt,
		case
		when sls_ship_dt =0 or len(sls_ship_dt)!=8 then null
		else cast(cast(sls_ship_dt as varchar) as date)
		end as sls_ship_dt,
		case
		when sls_due_dt =0 or len(sls_due_dt)!=8 then null
		else cast(cast(sls_due_dt as varchar) as date)
		end as sls_due_dt,
		sls_ord_num,
		case 
		when sls_sales is null or sls_sales <=0 or sls_sales!=sls_quantity*ABS(sls_price) 
		then sls_quantity*ABS(sls_price) 
		else sls_sales
		end as sls_sales,
		sls_quantity,
		case 
		when sls_price is null or sls_price <=0  
		then sls_sales/nullif(sls_quantity,0)
		else sls_price
		end as sls_price

		From bronze.crm_sales_details;
		SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '>> -------------';

	----------------------------------------------------------------------
	  -- Loading erp_cust_az12
        SET @start_time = GETDATE();
		PRINT '>> Truncating Table: silver.erp_cust_az12';
	
	    TRUNCATE TABLE silver.erp_cust_az12;
			PRINT '>> Inserting Data Into: silver.erp_cust_az12';
	  INSERT INTO silver.erp_cust_az12 (
				cid,
				bdate,
				gen
			)         
	Select		   
	   case 
	   when cid LIKE 'NAS%' THEN SUBSTRING(CID,4,LEN(CID)) 
	   ELSE CID END as CID ,
	   CASE WHEN bdate> GETDATE() THEN NULL
	   ELSE bdate
	   END as bdate,
	   case 
	   when UPPER(TRIM(gen)) IN ( 'F' , 'FEMALE') THEN 'Female'
	   when UPPER(TRIM(gen)) IN ( 'M' , 'MALE') THEN 'Male'
	   Else 'n/a'
	   end as gen
	   From bronze.erp_cust_az12;
	   SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '>> -------------';

		PRINT '------------------------------------------------';
		PRINT 'Loading ERP Tables';
		PRINT '------------------------------------------------';


	--------------------------------------------------------------------------
	-- Loading erp_loc_a101
        SET @start_time = GETDATE();
		PRINT '>> Truncating Table: silver.erp_loc_a101';
	
	TRUNCATE TABLE silver.erp_loc_a101;
	PRINT '>> Inserting Data Into: silver.erp_loc_a101';
	INSERT INTO silver.erp_loc_a101 (
				cid,
				cntry
			)

	select replace (cid, '-','')as cid,
		   case 
		   when trim(cntry)= 'DE'  then 'Germany'
		   when trim(cntry) in ('US','USA')  then 'United States'
		   else trim(cntry)
		   end as cntry
	from [bronze].[erp_loc_a101];
	SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '>> -------------';
	

	----------------------------------------------------------------------
	-- Loading erp_px_cat_g1v2
		SET @start_time = GETDATE();
		PRINT '>> Truncating Table: silver.erp_px_cat_g1v2';

	TRUNCATE TABLE silver.erp_px_cat_g1v2;
	PRINT '>> Inserting Data Into: silver.erp_px_cat_g1v2';
	INSERT INTO silver.erp_px_cat_g1v2 (
				id,
				cat,
				subcat,
				maintenance
			)
			SELECT
				id,
				cat,
				subcat,
				maintenance
			FROM bronze.erp_px_cat_g1v2;
			SET @end_time = GETDATE();
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '>> -------------';

		SET @batch_end_time = GETDATE();
		PRINT '=========================================='
		PRINT 'Loading Silver Layer is Completed';
        PRINT '   - Total Load Duration: ' + CAST(DATEDIFF(SECOND, @batch_start_time, @batch_end_time) AS NVARCHAR) + ' seconds';
		PRINT '=========================================='

	------------------------------------------------------------------
END TRY
	BEGIN CATCH
		PRINT '=========================================='
		PRINT 'ERROR OCCURED DURING LOADING BRONZE LAYER'
		PRINT 'Error Message' + ERROR_MESSAGE();
		PRINT 'Error Message' + CAST (ERROR_NUMBER() AS NVARCHAR);
		PRINT 'Error Message' + CAST (ERROR_STATE() AS NVARCHAR);
		PRINT '=========================================='
	END CATCH
END


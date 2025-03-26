create or alter procedure bronze.load_data
as 
 begin
    begin try
	    TRUNCATE TABLE bronze.crm_cust_info;
		bulk insert [bronze].[crm_cust_info]
		from 'D:\sql-data-warehouse-project\datasets\source_crm\cust_info.csv'
		with (
			 firstrow = 2,
			 fieldterminator = ',',
			 tablock 
			 );
        
		TRUNCATE TABLE [bronze].[crm_prd_info];
		bulk insert [bronze].[crm_prd_info]
		from 'D:\sql-data-warehouse-project\datasets\source_crm\prd_info.csv'
		with (
			 firstrow = 2,
			 fieldterminator = ',',
			 tablock 
			 );

        TRUNCATE TABLE bronze.crm_sales_details;       
		bulk insert bronze.crm_sales_details
		from 'D:\sql-data-warehouse-project\datasets\source_crm\sales_details.csv'
		with (
			 firstrow = 2,
			 fieldterminator = ',',
			 tablock 
			 );

        TRUNCATE TABLE bronze.erp_loc_a101;    
		bulk insert [bronze].[erp_cust_az12]
		from 'D:\sql-data-warehouse-project\datasets\source_erp\CUST_AZ12.csv'
		with (
			 firstrow = 2,
			 fieldterminator = ',',
			 tablock 
			 );

        TRUNCATE TABLE bronze.erp_cust_az12;
		bulk insert [bronze].[erp_loc_a101]
		from 'D:\sql-data-warehouse-project\datasets\source_erp\LOC_A101.csv'
		with (
			 firstrow = 2,
			 fieldterminator = ',',
			 tablock 
			 );

		TRUNCATE TABLE bronze.erp_px_cat_g1v2;
		bulk insert [bronze].[erp_px_cat_g1v2]
		from 'D:\sql-data-warehouse-project\datasets\source_erp\PX_CAT_G1V2.csv'
		with (
			 firstrow = 2,
			 fieldterminator = ',',
			 tablock 
			 );
 end try
 begin catch
 		PRINT '=========================================='
		PRINT 'ERROR OCCURED DURING LOADING BRONZE LAYER'
		PRINT 'Error Message' + ERROR_MESSAGE();
		PRINT 'Error Message' + CAST (ERROR_NUMBER() AS NVARCHAR);
		PRINT 'Error Message' + CAST (ERROR_STATE() AS NVARCHAR);
		PRINT '=========================================='
	END CATCH
end;

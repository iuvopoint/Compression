CREATE TABLE [Compression].[Objects_to_exclude_t] (

	 [Database_Name] SYSNAME NOT NULL
	,[Schema_Name] SYSNAME NOT NULL
	,[Table_Name] SYSNAME NOT NULL
	,[Index_Name] NVARCHAR(128) NULL
	,[Reason] NVARCHAR(512) NULL

	,CONSTRAINT [UQ_Objects_to_exclude_t] UNIQUE CLUSTERED (
		[Database_Name] ASC, [Schema_Name] ASC, [Table_Name] ASC, [Index_Name] ASC
	 ) WITH ( DATA_COMPRESSION = PAGE )
);

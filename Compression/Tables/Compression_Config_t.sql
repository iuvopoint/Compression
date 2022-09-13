CREATE TABLE [Compression].[Compression_Config_t] (

	 [Database_Name] SYSNAME NOT NULL
	,[Schema_Name] SYSNAME NOT NULL
	,[Compression_enabled] BIT CONSTRAINT [DF_Compression__Compression_Config_t__enabled] DEFAULT (1) NOT NULL
	,[Planned_first_Compression_at] DATETIME2(0) CONSTRAINT [DF_Compression__Compression_Config_t__First_Compression] DEFAULT ( GETDATE() ) NOT NULL
	,[Last_Compression_occurred_at] DATETIME2(7) NULL
	,[Created_by] SYSNAME CONSTRAINT [DF_Compression__Compression_Config_t__Created_by] DEFAULT ( ORIGINAL_LOGIN() ) NOT NULL
	,[Created_at] DATETIME2(0) CONSTRAINT [DF_Compression__Compression_Config_t__Created_on] DEFAULT ( GETDATE() ) NOT NULL

	,[Valid_from] DATETIME2(7) GENERATED ALWAYS AS ROW START HIDDEN NOT NULL
	,[Valid_to] DATETIME2(7) GENERATED ALWAYS AS ROW END HIDDEN NOT NULL
	,PERIOD FOR SYSTEM_TIME ( [Valid_from], [Valid_to] )

	,CONSTRAINT [PK_Compression_Config_t] PRIMARY KEY CLUSTERED
		( [Database_Name] ASC, [Schema_Name] ASC ) WITH ( DATA_COMPRESSION = PAGE )
	,CONSTRAINT [CK_Compression_Config_t__Database_Name__No_sys_Database] CHECK (
		NOT (
			   [Database_Name] = N'msdb'
			OR [Database_Name] = N'model'
			OR [Database_Name] = N'tempdb'
			OR [Database_Name] = N'master'
		)
	 )
	,CONSTRAINT [CK_Compression_Config_t__Schema_Name__No_sys_Schema] CHECK (
		NOT (
			   [Database_Name] = N'sys'
			OR [Database_Name] = N'INFORMATION_SCHEMA'
		)
	 )

) WITH (
	SYSTEM_VERSIONING = ON ( HISTORY_TABLE = [Compression].[Compression_Config_History_t], DATA_CONSISTENCY_CHECK = ON )
)
;

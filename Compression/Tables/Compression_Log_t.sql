CREATE TABLE [Compression].[Compression_Log_t] (

	 [ID] BIGINT IDENTITY(1, 1) NOT NULL
	,[Database_Name] SYSNAME NOT NULL
	,[Schema_Name] SYSNAME NOT NULL
	,[Table_Name] SYSNAME NOT NULL
	,[Index_Name] NVARCHAR(128) NULL
	,[Begin_DateTime] DATETIME2(7) NOT NULL
	,[End_DateTime] DATETIME2(7) NULL

	,CONSTRAINT [PK_Compression_Log_t] PRIMARY KEY CLUSTERED
		( [ID] ASC ) WITH ( DATA_COMPRESSION = PAGE )
);

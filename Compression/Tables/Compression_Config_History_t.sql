CREATE TABLE [Compression].[Compression_Config_History_t] (

	 [Database_Name] SYSNAME NOT NULL
	,[Schema_Name] SYSNAME NOT NULL
	,[Compression_enabled] BIT NOT NULL
	,[Planned_first_Compression_at] DATETIME2(0) NOT NULL
	,[Last_Compression_occurred_at] DATETIME2(7) NULL
	,[Created_by] SYSNAME NOT NULL
	,[Created_at] DATETIME2(0) NOT NULL
	,[Valid_from] DATETIME2(7) NOT NULL
	,[Valid_to] DATETIME2(7) NOT NULL

);

GO
CREATE CLUSTERED INDEX [IX_Compression_Config_History_t]
 ON [Compression].[Compression_Config_History_t]
 ( [Valid_to] ASC, [Valid_from] ASC ) WITH ( DATA_COMPRESSION = PAGE );

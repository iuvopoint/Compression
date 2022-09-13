CREATE PROCEDURE [Compression].[Get_Objects_to_exclude_stp] (
 @MaxSizeGB SMALLINT = 12
	-- Tables larger than @MaxSizeGB won't be compressed
)
AS
BEGIN

	-- This procedure defines, which tables/indices won't be compressed.
	-- Table [Compression].[Objects_to_exclude_t] will be truncated and loaded.
	-- Can be modified as required by the business.

	SET NOCOUNT, XACT_ABORT ON;

	DECLARE @SQL NVARCHAR(MAX);
	SET @SQL = N'
		SELECT

			 [Database_Name] = ''?''
			,[Schema_Name] = [S].[name]
			,[Table_Name] = [T].[name]
			,[Index_Name] = [I].[name]
			,[Reason] = ''Size greater than ' + CAST( @MaxSizeGB AS NVARCHAR ) + ' GB ('' + CAST( CAST( [DM].[used_page_count] * 8. / 1024 / 1024 AS DECIMAL(10,2) ) AS NVARCHAR ) + '' GB).''

		FROM [?].[sys].[tables] AS [T]

		INNER JOIN [?].[sys].[schemas] AS [S] ON
			[T].[schema_id] = [S].[schema_id]

		INNER JOIN [?].[sys].[partitions] AS [P] ON
			[T].[object_id] = [P].[object_id]

		INNER JOIN [?].[sys].[indexes] AS [I] ON
				[T].[object_id] = [I].[object_id]
			AND [P].[index_id] = [I].[index_id]

		INNER JOIN [?].[sys].[dm_db_partition_stats] AS [DM]
			ON [P].[partition_id] = [DM].[partition_id]

		WHERE [DM].[used_page_count] * 8. / 1024 / 1024 > ' + CAST( @MaxSizeGB AS NVARCHAR ) + '
		;
	';

	DELETE FROM [Compression].[Objects_to_exclude_t];
	INSERT INTO [Compression].[Objects_to_exclude_t] ( [Database_Name], [Schema_Name], [Table_Name], [Index_Name], [Reason] )
	EXEC sp_msforeachdb @SQL;

	RETURN 0;

END
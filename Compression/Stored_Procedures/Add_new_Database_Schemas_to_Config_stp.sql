CREATE PROCEDURE [Compression].[Add_new_Database_Schemas_to_Config_stp] (
 @@NewConfigCompressionStrategy_Enabled_Disabled CHAR(1) = 'E'
	-- E -> Imediately enable new config entries for compression
	-- D -> Compression is disabled for new config entries
,@@Debug BIT = 0
	-- NULL, 0 -> Adds new databases and schemas to config
	-- 1 -> Returns list of fetched databases and schemas; does not modify any config
)
AS
BEGIN

	-- Procedure adds all databases and schemas residing on the server which are
	-- not yet entered in [Compression].[Compression_Config_t] to said table.
	-- Following databases/schemas are excluded:
	-- - DB [master]
	-- - DB [tempdb]
	-- - DB [model]
	-- - DB [msdb]
	-- - Schema [INFORMATION_SCHEMA] (for all DBs)
	-- - Schema [sys] (for all DBs)

	SET NOCOUNT, XACT_ABORT ON;

	IF @@Debug IS NULL
		SET @@Debug = 0;

	BEGIN TRY

		IF @@NewConfigCompressionStrategy_Enabled_Disabled NOT IN ( 'E', 'D' )
			THROW 50001, N'Invalid paramter value for @@NewConfigCompressionStrategy. Must be ''E'' (enabled) or ''D'' (disabled).', 1
		;

		DECLARE @AllDatabaseSchemas TABLE (
			 [Database_Name] SYSNAME NOT NULL
			,[Schema_Name] SYSNAME NOT NULL
		);

		DECLARE @SQL NVARCHAR(MAX) = N'
			SELECT

				 [Database_Name] = N''?''
				,[Schema_Name] = [name]

			FROM [?].[sys].[schemas]

			WHERE
					N''?'' NOT IN ( N''master'', N''tempdb'', N''model'', N''msdb'' )
				AND [name] NOT IN ( N''INFORMATION_SCHEMA'', N''sys'' )
			;
		';

		-- Executes dynamic Query for each DB on the server and UNIONs result sets
		INSERT INTO @AllDatabaseSchemas (
			 [Database_Name]
			,[Schema_Name]
		)
		EXEC sp_msforeachdb @SQL;

		IF @@Debug = 1
		BEGIN
			SELECT *
			FROM @AllDatabaseSchemas;
		END 
		ELSE
		BEGIN
			-- Add databases and schemas to config which are not yet there
			INSERT INTO [Compression].[Compression_Config_t] ( [Database_Name], [Schema_Name], [Compression_enabled] )
			SELECT
				 [Source].[Database_Name]
				,[Source].[Schema_Name]
				,CASE @@NewConfigCompressionStrategy_Enabled_Disabled
					WHEN 'E' THEN 1
					WHEN 'D' THEN 0
					ELSE NULL
				 END
			FROM @AllDatabaseSchemas AS [Source]
			LEFT JOIN [Compression].[Compression_Config_t] AS [Target] ON
					[Source].[Database_Name] = [Target].[Database_Name]
				AND [Source].[Schema_Name] = [Target].[Schema_Name]
			WHERE [Target].[Database_Name] IS NULL
			;
		END

	END TRY
	BEGIN CATCH

		-- < Add your custom logging routine here >
		THROW;

		RETURN 1;

	END CATCH

	RETURN 0;

END
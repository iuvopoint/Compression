CREATE PROCEDURE [Compression].[Compress_stp] (
 @@Print BIT = 1
	-- 1 -> No logging, no compression; 
		-- prints compression statements instead (logging statments are not printed!)
	-- NULL, 0 -> Compress tables and write to log
,@@Debug BIT = 0
	-- NULL, 0 -> look at @@Print documentation
	-- 1 -> No compression, no logging, no printing; returns some debugging query results
)
AS
BEGIN

	-- Procedure compresses all tables/indices that reside in databases/schemas
	-- returned by [Compression].[Database_Schemas_to_compress_v].
	-- Objects defined in [Compression].[Objects_to_exclude_t] are skipped.

	SET NOCOUNT, XACT_ABORT ON;

	IF @@Print IS NULL
		SET @@Print = 1;
	IF @@Debug IS NULL
		SET @@Debug = 0;

	BEGIN TRY

		DECLARE @CurrentCompressionOrder SMALLINT;
		DECLARE @MaxCompressionOrder SMALLINT;

		DECLARE @LogID BIGINT;
		DECLARE @EndDateTime DATETIME2(7);

		DECLARE @DatabaseName NVARCHAR(128);
		DECLARE @SchemaName NVARCHAR(128);
		DECLARE @TableName NVARCHAR(128);
		DECLARE @IndexName NVARCHAR(128);

		DECLARE @DynSQL NVARCHAR(4000);
		DECLARE @ParamDef NVARCHAR(128);

		DECLARE @AllDatabasesSchemasAndTables TABLE (
			 [Database_Name] SYSNAME NOT NULL
			,[Schema_Name] SYSNAME NOT NULL
			,[Table_Name] SYSNAME NOT NULL
			,[Index_Name] SYSNAME NULL
			,[Compression_Order] INT NULL
		);

		SET @DynSQL = N'
			SELECT

				 [Database_Name] = ''?''
				,[Schema_Name] = [S].[name]
				,[Table_Name] = [T].[name]
				,[Index_Name] = [I].[name]

			FROM [?].[sys].[tables] AS [T]

			INNER JOIN [?].[sys].[schemas] AS [S] ON
				[T].[schema_id] = [S].[schema_id]

			INNER JOIN [?].[sys].[partitions] AS [P] ON
				[T].[object_id] = [P].[object_id]

			INNER JOIN [?].[sys].[indexes] AS [I] ON
				    [T].[object_id] = [I].[object_id]
				AND [P].[index_id] = [I].[index_id]

			WHERE [P].[data_compression] < 2 -- 0 -> NONE, 1 -> ROW, 2 -> PAGE, 3 -> COLUMNSTORE
			;
		';

		-- Use as-is state of databases, schemas and tables/indices. Structures defined
		-- in [Compression].[Compression_Config_t] may not exist anymore.
		INSERT INTO @AllDatabasesSchemasAndTables (
			 [Database_Name]
			,[Schema_Name]
			,[Table_Name]
			,[Index_Name]
		)
		EXEC sp_msforeachdb @DynSQL;

		-- Update list of objects to exclude from compression
		EXEC [Compression].[Get_Objects_to_exclude_stp];

		-- Add incremetal ID for looping through all tables later on
		UPDATE [Tables]
			SET [Compression_Order] = [New_Compression_Order]
		FROM (	
			SELECT
				 [Tables].[Compression_Order]
				,[Tables].[Database_Name]
				,[Tables].[Schema_Name]
				,[New_Compression_Order] = ROW_NUMBER()
					OVER ( ORDER BY [Tables].[Database_Name], [Tables].[Schema_Name], [Tables].[Table_Name], [Tables].[Index_Name] )
			FROM @AllDatabasesSchemasAndTables AS [Tables]

			-- Database schema must be enabled for compression
			INNER JOIN [Compression].[Database_Schemas_to_compress_v] AS [Config] ON
				[Tables].[Database_Name] = [Config].[Database_Name]
			AND [Tables].[Schema_Name] = [Config].[Schema_Name]

			-- Compress objects that not excluded only
			LEFT JOIN [Compression].[Objects_to_exclude_t] AS [Excl] ON
				    [Tables].[Database_Name] = [Excl].[Database_Name]
				AND [Tables].[Schema_Name] = [Excl].[Schema_Name]
				AND [Tables].[Table_Name] = [Excl].[Table_Name]
				AND ( [Tables].[Index_Name] = [Excl].[Index_Name]
					OR ( [Tables].[Index_Name] IS NULL AND [Excl].[Index_Name] IS NULL ) )
			WHERE [Excl].[Database_Name] IS NULL

		) AS [Tables]
		;

		SET @CurrentCompressionOrder = 1;
		SET @MaxCompressionOrder = (
			SELECT COALESCE( MAX( [Compression_Order] ), 0 )
			FROM @AllDatabasesSchemasAndTables
			WHERE [Compression_Order] IS NOT NULL
				-- Omitting this condition leads to a warning message which is interpreted as error by SQL Server Agent
		);

		-- Activating @@Debug flag will return Statements useful for debugging.
		-- Can be modified as desired by the business.
		IF @@Debug = 1
		BEGIN

			SELECT [Debug] = 'AllDatabasesSchemasAndTables', *
			FROM @AllDatabasesSchemasAndTables;

			SELECT [Debug] = 'Object exclusion:', *
			FROM [Compression].[Objects_to_exclude_t];

			SELECT
				 [Debug] = 'Compression order eval (excl. NULL)'
				,[Min_Compression_Order] = MIN( [Compression_Order] )
				,[Max_Compression_Order] = MAX( [Compression_Order] )
				,[Compression_Order_Count] = COUNT( [Compression_Order] )
				,[Distinct_Compression_Order_Count] = COUNT( DISTINCT [Compression_Order] )
			FROM @AllDatabasesSchemasAndTables
			WHERE [Compression_Order] IS NOT NULL;
				-- Omitting this condition leads to a warning message which is interpreted as error by SQL Server Agent

			SELECT DISTINCT [Distinct_Compression_Order] = [Compression_Order]
			FROM @AllDatabasesSchemasAndTables;

		END

		-- Compress/print compression statement table by table
		WHILE ( @@Debug = 0 AND @CurrentCompressionOrder <= @MaxCompressionOrder )
		BEGIN

			SELECT
				 @DatabaseName = [Database_Name]
				,@SchemaName = [Schema_Name]
				,@TableName = [Table_Name]
				,@IndexName = [Index_Name]
			FROM @AllDatabasesSchemasAndTables
			WHERE [Compression_Order] = @CurrentCompressionOrder
			;

			-- No need for logging when printing the statement only
			IF @@Print = 0
			BEGIN

				INSERT INTO [Compression].[Compression_Log_t] ( [Database_Name], [Schema_Name], [Table_Name], [Index_Name], [Begin_DateTime] )
				VALUES ( @DatabaseName, @SchemaName, @TableName, @IndexName, SYSDATETIME() )
				;

				SET @LogID = SCOPE_IDENTITY();

			END

			BEGIN TRY
				IF @IndexName IS NULL
				BEGIN -- Table compression
					SET @DynSQL = [Compression].[Get_Table_Compression_DynSQL_fn]();
					SET @ParamDef = [Compression].[Get_Table_Compression_ParamDef_fn]();
					EXEC sp_executesql
						 @stmt = @DynSQL
						,@params = @ParamDef
						,@DatabaseName = @DatabaseName
						,@SchemaName = @SchemaName
						,@TableName = @TableName
						,@Print = @@Print
					;
				END
				ELSE
				BEGIN -- Index on table compression
					SET @DynSQL = [Compression].[Get_Index_Compression_DynSQL_fn]();
					SET @ParamDef = [Compression].[Get_Index_Compression_ParamDef_fn]();
					EXEC sp_executesql
						 @stmt = @DynSQL
						,@params = @ParamDef
						,@DatabaseName = @DatabaseName
						,@SchemaName = @SchemaName
						,@TableName = @TableName
						,@IndexName = @IndexName
						,@Print = @@Print
					;
				END -- IF @IndexName IS NULL
			END TRY
			BEGIN CATCH
				-- Tables can't be compressed if index is too large.
				-- It's not an error that should interrupt the compression process.
				IF ERROR_NUMBER() <> 1975
					THROW;
			END CATCH

			-- No need for updating config/log when printing the statement only
			IF @@Print = 0
			BEGIN

				SET @EndDateTime = SYSDATETIME();

				UPDATE [Compression].[Compression_Config_t]
				SET [Last_Compression_occurred_at] = @EndDateTime
				WHERE
						[Database_Name] = @DatabaseName
					AND [Schema_Name] = @SchemaName
				;

				UPDATE [Compression].[Compression_Log_t]
				SET [End_DateTime] = @EndDateTime
				WHERE [ID] = @LogID
				;

			END -- @@Print = 0

			SET @CurrentCompressionOrder = @CurrentCompressionOrder + 1;

		END -- WHILE ( @@Debug = 0 AND @CurrentCompressionOrder <= @MaxCompressionOrder )

	END TRY
	BEGIN CATCH

		-- < Add your custom logging routine here >
		THROW;

	END CATCH

	RETURN 0;

END
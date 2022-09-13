CREATE PROCEDURE [Compression].[Sync_Config_and_Compress_all_stp] (
 @@NewConfigCompressionStrategy_Enabled_Disabled CHAR(1) = 'E'
	-- E -> Imediately enable new config entries for compression
	-- D -> Compression is disabled for new config entries
,@@Print BIT = 1
,@@Debug BIT = 0
)
AS
BEGIN

	-- Main routine to update configuration table and compress tables right after.

	SET NOCOUNT, XACT_ABORT ON;

	IF @@Print IS NULL
		SET @@Print = 1;
	IF @@Debug IS NULL
		SET @@Debug = 0;

	DECLARE @ErrorCount INT = 0;

	IF @@Print = 1
	BEGIN
		BEGIN TRANSACTION;
		RAISERROR( N'@@Print = 1: Transaction opened. Changes done to config will be rolled back in the end.', 0, 0) WITH NOWAIT;
	END

	BEGIN TRY

		EXEC [Compression].[Add_new_Database_Schemas_to_Config_stp]
			 @@NewConfigCompressionStrategy_Enabled_Disabled = @@NewConfigCompressionStrategy_Enabled_Disabled
			,@@Debug = @@Debug
		;

	END TRY
	BEGIN CATCH
		SET @ErrorCount += 1;
	END CATCH

	BEGIN TRY

		EXEC [Compression].[Compress_stp]
			 @@Print = @@Print
			,@@Debug = @@Debug
		;

	END TRY
	BEGIN CATCH
		SET @ErrorCount += 1;
	END CATCH

	IF @@Print = 1
	BEGIN
		ROLLBACK;
	END

	IF @ErrorCount > 0
	BEGIN
		DECLARE @Msg NVARCHAR(4000) = CONCAT( @ErrorCount, N' errors occured on compression attempt.' );
		THROW 50001, @Msg, 1; 
	END

	RETURN 0;

END
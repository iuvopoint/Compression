CREATE FUNCTION [Compression].[Get_Index_Compression_DynSQL_fn]()
RETURNS NVARCHAR(4000)
AS
BEGIN

	RETURN
		N'IF @Print = 1' + CHAR(13) +
		N'BEGIN' + CHAR(13) +
		N'PRINT' + CHAR(13) +
			N'''ALTER INDEX [@IndexName] ON [@DatabaseName].[@SchemaName].[@TableName] REBUILD PARTITION = ALL' + CHAR(13) +
			N'	WITH ( DATA_COMPRESSION = PAGE );''' + CHAR(13) +
		N'END' + CHAR(13) +
		N'' + CHAR(13) +
		N'IF @Debug = 0' + CHAR(13) +
		N'BEGIN' + CHAR(13) +
		N'	ALTER INDEX [@IndexName] ON [@DatabaseName].[@SchemaName].[@TableName] REBUILD PARTITION = ALL' + CHAR(13) +
		N'		WITH ( DATA_COMPRESSION = PAGE );' + CHAR(13) +
		N'END';

END

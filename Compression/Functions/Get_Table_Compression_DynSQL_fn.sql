CREATE FUNCTION [Compression].[Get_Table_Compression_DynSQL_fn]()
RETURNS NVARCHAR(4000)
AS
BEGIN

	RETURN
		N'IF @Print = 1' + CHAR(13) +
		N'BEGIN' + CHAR(13) +
		N'PRINT' + CHAR(13) +
			N'''ALTER TABLE [@Database].[@Schema].[@Table] REBUILD PARTITION = ALL''' + CHAR(13) +
			N'''	WITH ( DATA_COMPRESSION = PAGE );''' + CHAR(13) +
		N'END' + CHAR(13) +
		N'ELSE' + CHAR(13) +
		N'BEGIN' + CHAR(13) +
		N'	ALTER TABLE [@Database].[@Schema].[@Table] REBUILD PARTITION = ALL' + CHAR(13) +
		N'		WITH ( DATA_COMPRESSION = PAGE );' + CHAR(13) +
		N'END';

END

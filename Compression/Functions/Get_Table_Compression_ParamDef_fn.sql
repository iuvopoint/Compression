CREATE FUNCTION [Compression].[Get_Table_Compression_ParamDef_fn]()
RETURNS NVARCHAR(128)
AS
BEGIN

	RETURN N'@Database SYSNAME, @Schema SYSNAME, @Table SYSNAME, @Print BIT';

END

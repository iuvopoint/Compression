CREATE FUNCTION [Compression].[Get_Index_Compression_ParamDef_fn]()
RETURNS NVARCHAR(128)
AS
BEGIN

	RETURN N'@Database SYSNAME, @Schema SYSNAME, @Table SYSNAME, @Index SYSNAME, @Print BIT';

END

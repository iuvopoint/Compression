CREATE VIEW [Compression].[Database_Schemas_to_compress_v]
AS

	SELECT

		 [Database_Name]
		,[Schema_Name]

	FROM [Compression].[Compression_Config_t]
	WHERE
		    [Compression_enabled] = 1
		AND [Planned_first_Compression_at] <= GETDATE()
	;

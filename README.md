# Compression

## What is Compression?

_Compression_ is a lightweight utlility to manage and apply page compression all over your SQL Server. It is written in T-SQL only, which makes it easy to install and use (no additional programming language, runtime, machines etc.).


## Concepts

_Compression_ consists of a server-scoped config table that holds all schemas per database. Using this config table, you are able to enable/disable and set the earliest possible point in time to apply compression to tables/indices on schema level. To exclude certain tables/indices from compression, there is a procedure you may modify.

However, compressing an SQL Server in a single step may take - depending on your specific environment - up to hours, days or even weeks. So the main idea is to roll out compression onto your server step by step. After roll-out, this tool can also be used to continuously integrate new tables/indices for page compression.


## Usage

To add all database schemas on your server to compression config, execute `[Compression].[Add_new_Database_Schemas_to_Config_stp]`. Be careful to disable compression for this first execution. All tables/indices on your server would be compressed during next compression run otherwise.

```tsql
EXECUTE [Compression].[Add_new_Database_Schemas_to_Config_stp]
    @@NewConfigCompressionStrategy_Enabled_Disabled = N'D' -- Disable compression for newly added database schemas!
;

-- Have a look at your compression config
SELECT TOP 1000 *
FROM [Compression].[Compression_Config_t];
```

---

Perhaps you don't want all tables/indices to be page compressed. By default, following tables/indices are excluded:
- greater than 12GB
- page compression or better (COLUMNSTORE INDEX) already applied

To have a look at currently excluded tables/indices execute following code:

```tsql
EXEC [Compression].[Get_Objects_to_exclude_stp];
SELECT *
FROM [Compression].[Objects_to_exclude_t];
```

Procedure `[Compression].[Get_Objects_to_exclude_stp]` can be modified as desired by your business.


---

In the next step, add your compression scheduling for database schemas:

```tsql
-- Database schemas that are to be compressed by the next run
UPDATE [Compression].[Compression_Config_t]
SET [Compression_enabled] = 1
WHERE
        [Database_Name] = N'<next_run_db>'
    AND [Schema_Name] IN ( N'<next_run_schema_1>', N'<next_run_schema_2>', N'<next_run_schema_n>' )
;

-- Database schemas that are to be compressed by later runs
UPDATE [Compression].[Compression_Config_t]
SET
     [Compression_enabled] = 1
    ,[Planned_first_Compression_at] = CONVERT( DATE, GETDATE() + 1 /*days*/ ) -- Compress tomorrow
WHERE
        [Database_Name] = N'<later_run_db>'
    AND [Schema_Name] IN ( N'<later_run_schema_1>', N'<later_run_schema_2>', N'<later_run_schema_n>' )
;

UPDATE [Compression].[Compression_Config_t]
SET
     [Compression_enabled] = 1
    ,[Planned_first_Compression_at] = CONVERT( DATE, GETDATE() + 2 /*days*/ ) -- Compress in two days
WHERE
        [Database_Name] = N'<even_later_run_db>'
    AND [Schema_Name] IN ( N'<even_later_run_schema_1>', N'<even_later_run_schema_2>', N'<even_later_run_schema_n>' )
;

-- The config table is system-versioned. This allows you to have a look at past configuration
SELECT *
FROM [Compression].[Compression_Config_t]
FOR SYSTEM_TIME ALL
WHERE [Valid_to] < SYSDATETIME()
;
```

---

After setting up your compression configuration, check what would be done by a compression run and actually run it if appropriate:

```tsql
-- Have a look at debugging output and compression
-- statements that would be executed
EXEC [Compression].[Compress_stp]
     @@Print = 1 --> Print compression SQL statements instead of executing
    ,@@Debug = 1 --> Show debugging query results
;

-- Actually execute compression for current compression config
EXEC [Compression].[Compress_stp]
     @@Print = 0 --> Execute; don't print statements
    ,@@Debug = 0 --> Execute; don't show debugging query results
;
```

It is recommended __not to__ copy, paste and execute __printed__ compression statements. _Compression_ adds entries to a log table and updates the last compression occurrence in your config which would then be ommited.


---

Your first compression run passed. Now have a look at the log table and your config (especially column `[Last_Compression_occurred_at]`):

```tsql
-- Have a look at compressed tables/indices
SELECT TOP 1000 *
FROM [Compression].[Compression_Config_t]
WHERE
        [Compression_enabled] = 1
    AND [Last_Compression_occurred_at] < SYSDATETIME()
;

-- Have a look at your compression log entries
SELECT TOP 1000 *
FROM [Compression].[Compression_Log_t]
;
```

---

If everything seems as desired, you now may schedule main procedure `[Compression].[Sync_Config_and_Compress_all_stp]` in a way to continuously integrate new tables/indices (on database schema level) to your compression process:

```tsql
-- For execution on a regular basis e.g. via SQL Server Agent:
-- Adds new database schemas to config and enables compression
EXEC [Compression].[Sync_Config_and_Compress_all_stp]
     @@NewCnofigCopmressionStrategy_Enabled_Disabled = N'E'
    ,@@Print = 0
    ,@@Debug = 0
;
```

## Prerequisites/Limitations

Tested against SQL Server 2019. Should work with SQL Server 2016 and newer, perhaps even some older versions.

_Compression_ has been tested in environments using '_regular_' tables/indices only. There could be issues in environments using things such as file tables, external tables, in-memory tables, partitions etc. In case, adjust object exclution procedure `[Compression].[Get_Objects_to_exclude_stp]` or feel free to fork this repo and add support for those objects :)


## Installation

Currently, installation via Visual Sutdio 2019 is supported only. Later on, an installation script may be added.

### Installation using Visual Studio

- Install [Visual Studio 2019](https://visualstudio.microsoft.com/vs/) (check [pricing/license terms](https://visualstudio.microsoft.com/vs/pricing/) first)
- In Visual Studio 2019 Installer, make sure _SQL Server Data Tools_ are installed
- Clone _Compression_ repository
- Open solution and deploy SSDT project _Compression_ to target database

If Visual Studio 2019 pricing/licensing terms are a blocking point, you may use [Visual Studio 2017 SSDT](https://docs.microsoft.com/en-us/sql/ssdt/download-sql-server-data-tools-ssdt?view=sql-server-ver15#ssdt-for-vs-2017-standalone-installer) which is completely free of charge. But you will have to adjust project database references to `[msdb]` and `[master]` as there are different file paths for each Visual Studio version.


### Installation using Installation Script

Coming soon(er or later ;) ).


## Contribution

Yet there is neither a code of conduct nor a feature roadmap etc. Nevertheless, if you have some questions or suggestions feel free to contact us :)


## License

Copyright © 2022 [iuvopoint Business Intelligence](https://www.iuvopoint.de/).

Licensed under the MIT License (MIT). See LICENSE for details.


## Credits

Your name could be listed here :)

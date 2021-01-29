USE [InstinctCITAU510]
GO

/****** Object:  StoredProcedure [dbo].[USP_DBA_Index_Stats]    Script Date: 7/28/2020 7:10:18 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



			-- =============================================
			-- Author     : GBG - Caroline Charles
			-- Create date: 22/07/2020
			-- Description:	Gather Index Stats
			-- =============================================

			CREATE PROCEDURE [dbo].[USP_DBA_Index_Stats]
				
			AS

--metadata about the index structure

SELECT  Tab.name  Table_Name 
,IX.name  Index_Name
,IX.type_desc Index_Type
,Col.name  Index_Column_Name
,IXC.is_included_column Is_Included_Column
,IX.fill_factor 
,IX.is_disabled
,IX.is_primary_key
,IX.is_unique
  
           FROM  sys.indexes IX 
           INNER JOIN sys.index_columns IXC  ON  IX.object_id   =   IXC.object_id AND  IX.index_id  =  IXC.index_id  
           INNER JOIN sys.columns Col   ON  IX.object_id   =   Col.object_id  AND IXC.column_id  =   Col.column_id     
           INNER JOIN sys.tables Tab      ON  IX.object_id = Tab.object_id



--index fragmentation

SELECT  OBJECT_NAME(IDX.OBJECT_ID) AS Table_Name, 
IDX.name AS Index_Name, 
IDXPS.index_type_desc AS Index_Type, 
IDXPS.avg_fragmentation_in_percent  Fragmentation_Percentage,
IDXPS.page_count
FROM sys.dm_db_index_physical_stats(DB_ID(), NULL, NULL, NULL, NULL) IDXPS 
INNER JOIN sys.indexes IDX  ON IDX.object_id = IDXPS.object_id 
AND IDX.index_id = IDXPS.index_id 
ORDER BY Fragmentation_Percentage DESC


--Index usage

SELECT OBJECT_NAME(IX.OBJECT_ID) Table_Name
   ,IX.name AS Index_Name
   ,IX.type_desc Index_Type
   ,SUM(PS.[used_page_count]) * 8 IndexSizeKB
   ,IXUS.user_seeks AS NumOfSeeks
   ,IXUS.user_scans AS NumOfScans
   ,IXUS.user_lookups AS NumOfLookups
   ,IXUS.user_updates AS NumOfUpdates
   ,IXUS.last_user_seek AS LastSeek
   ,IXUS.last_user_scan AS LastScan
   ,IXUS.last_user_lookup AS LastLookup
   ,IXUS.last_user_update AS LastUpdate
FROM sys.indexes IX
INNER JOIN sys.dm_db_index_usage_stats IXUS ON IXUS.index_id = IX.index_id AND IXUS.OBJECT_ID = IX.OBJECT_ID
INNER JOIN sys.dm_db_partition_stats PS on PS.object_id=IX.object_id
WHERE OBJECTPROPERTY(IX.OBJECT_ID,'IsUserTable') = 1
GROUP BY OBJECT_NAME(IX.OBJECT_ID) ,IX.name ,IX.type_desc ,IXUS.user_seeks ,IXUS.user_scans ,IXUS.user_lookups,IXUS.user_updates ,IXUS.last_user_seek ,IXUS.last_user_scan ,IXUS.last_user_lookup ,IXUS.last_user_update



--missing indexes in order of impact their creation would have

SELECT TOP 20
 ROUND(s.avg_total_user_cost *
       s.avg_user_impact
        * (s.user_seeks + s.user_scans),0)
                 AS [Total Cost]
 ,d.[statement] AS [Table Name]
 ,equality_columns
 ,inequality_columns
 ,included_columns
FROM sys.dm_db_missing_index_groups g
INNER JOIN sys.dm_db_missing_index_group_stats s
  ON s.group_handle = g.index_group_handle
INNER JOIN sys.dm_db_missing_index_details d
  ON d.index_handle = g.index_handle
ORDER BY [Total Cost] DESC



--Redundant indexes

SELECT
    objects.name AS Table_name,
    indexes.name AS Index_name,
indexes.type AS Index_type,
    dm_db_index_usage_stats.user_seeks,
    dm_db_index_usage_stats.user_scans,
    dm_db_index_usage_stats.user_updates
FROM
    sys.dm_db_index_usage_stats
    INNER JOIN sys.objects ON dm_db_index_usage_stats.OBJECT_ID = objects.OBJECT_ID
    INNER JOIN sys.indexes ON indexes.index_id = dm_db_index_usage_stats.index_id AND dm_db_index_usage_stats.OBJECT_ID = indexes.OBJECT_ID
WHERE
    indexes.is_primary_key = 0 --This line excludes primary key constraint
    AND
    indexes. is_unique = 0 --This line excludes unique key constraint
    AND 
    dm_db_index_usage_stats.user_updates <> 0 -- This line excludes indexes SQL Server hasn’t done any work with
    AND
   dm_db_index_usage_stats. user_lookups = 0
    AND
    dm_db_index_usage_stats.user_seeks = 0
    AND
    dm_db_index_usage_stats.user_scans = 0
ORDER BY
    dm_db_index_usage_stats.user_updates DESC



-- any memory pressure

SELECT object_name, counter_name, cntr_value
FROM sys.dm_os_performance_counters
WHERE [object_name] LIKE '%Buffer Manager%'
AND [counter_name] in ('Page life expectancy','Free list stalls/sec',
'Page reads/sec')



GO



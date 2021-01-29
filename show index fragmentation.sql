USE gbg_mscrm
GO
SELECT object_name(IPS.object_id) AS [TableName], 
   SI.name AS [IndexName], 
   IPS.Index_type_desc, 
   IPS.avg_fragmentation_in_percent, -- external frag, pages out of order on disk
   IPS.avg_page_space_used_in_percent, -- internal frag, empty space on pages, this matters more 
   IPS.page_count  
FROM sys.dm_db_index_physical_stats(db_id(N'gbg_mscrm'),OBJECT_ID('obx_uploadrecordbase'), NULL, NULL , 'sampled') IPS
   JOIN sys.tables ST WITH (nolock) ON IPS.object_id = ST.object_id
   JOIN sys.indexes SI WITH (nolock) ON IPS.object_id = SI.object_id AND IPS.index_id = SI.index_id
WHERE ST.is_ms_shipped = 0
and page_count >1000
ORDER BY 4 desc
GO
select
    t1.session_id
    , t1.request_id
    , task_alloc_GB = cast((t1.task_alloc_pages * 8./1024./1024.) as numeric(10,1))
    , task_dealloc_GB = cast((t1.task_dealloc_pages * 8./1024./1024.) as numeric(10,1))
    , host= case when t1.session_id <= 50 then 'SYS' else s1.host_name end
    , s1.login_name
    , s1.status
    , s1.last_request_start_time
    , s1.last_request_end_time
    , s1.row_count
    , s1.transaction_isolation_level
    , query_text=
        coalesce((SELECT SUBSTRING(text, t2.statement_start_offset/2 + 1,
          (CASE WHEN statement_end_offset = -1
              THEN LEN(CONVERT(nvarchar(max),text)) * 2
                   ELSE statement_end_offset
              END - t2.statement_start_offset)/2)
        FROM sys.dm_exec_sql_text(t2.sql_handle)) , 'Not currently executing')
    , query_plan=(SELECT query_plan from sys.dm_exec_query_plan(t2.plan_handle))
from
    (Select session_id, request_id
    , task_alloc_pages=sum(internal_objects_alloc_page_count +   user_objects_alloc_page_count)
    , task_dealloc_pages = sum (internal_objects_dealloc_page_count + user_objects_dealloc_page_count)
    from sys.dm_db_task_space_usage
    group by session_id, request_id) as t1
left join sys.dm_exec_requests as t2 on
    t1.session_id = t2.session_id
    and t1.request_id = t2.request_id
left join sys.dm_exec_sessions as s1 on
    t1.session_id=s1.session_id
where
    t1.session_id > 50 -- ignore system unless you suspect there's a problem there
    and t1.session_id <> @@SPID -- ignore this request itself
order by t1.task_alloc_pages DESC;
GO


-- how much is using version store

SELECT GETDATE() AS runtime,
    SUM(user_object_reserved_page_count) * 8 AS usr_obj_kb,
    SUM(internal_object_reserved_page_count) * 8 AS internal_obj_kb,
    SUM(version_store_reserved_page_count) * 8 AS version_store_kb,
    SUM(unallocated_extent_page_count) * 8 AS freespace_kb,
    SUM(mixed_extent_page_count) * 8 AS mixedextent_kb
FROM sys.dm_db_file_space_usage;  
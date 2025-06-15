-- ========================================================
-- SQL Script to Evaluate Missing Indexes
-- This script helps DBAs identify missing indexes in SQL Server that 
-- could potentially improve query performance. It calculates the 
-- "index advantage" based on factors such as user seeks, average 
-- user cost, and user impact.
-- The script allows filtering missing indexes with an "index 
-- advantage" greater than 5000, which indicates significant 
-- performance benefits.
-- Author: Ennis (alcsoft)
-- ========================================================

-- ========================================================
-- Key Features:
-- 1. **Index Advantage Calculation**:
--    - The script calculates the "index advantage" by multiplying 
--      `user_seeks`, `avg_total_user_cost`, and `avg_user_impact`.
--    - A higher `index_advantage` value indicates a more impactful index.
--
-- 2. **Threshold Filtering**:
--    - Filters missing indexes that have an `index_advantage` greater 
--      than 5000, identifying those that can provide significant performance 
--      improvement.
--
-- 3. **Join Missing Index Information**:
--    - Joins `sys.dm_db_missing_index_group_stats`, `sys.dm_db_missing_index_groups`, 
--      and `sys.dm_db_missing_index_details` to fetch detailed information about 
--      the missing indexes, including their names and specific details.
--
-- 4. **Performance Monitoring**:
--    - Helps monitor the impact of missing indexes, guiding DBAs in decisions 
--      regarding index creation for query performance optimization.
-- ========================================================

SELECT *
FROM
(
    SELECT 
        user_seeks * avg_total_user_cost * (avg_user_impact * 0.01) AS index_advantage, 
        migs.* 
    FROM sys.dm_db_missing_index_group_stats migs
) AS migs_adv
INNER JOIN sys.dm_db_missing_index_groups AS mig
    ON migs_adv.group_handle = mig.index_group_handle
INNER JOIN sys.dm_db_missing_index_details AS mid
    ON mig.index_handle = mid.index_handle
WHERE migs_adv.index_advantage > 5000  -- Filter by index advantage threshold
ORDER BY migs_adv.index_advantage DESC;  -- Order by index advantage in descending order

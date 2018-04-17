SELECT
	name,
    FULLTEXTCATALOGPROPERTY(cat.name,'ItemCount') AS [ItemCount],
    FULLTEXTCATALOGPROPERTY(cat.name,'MergeStatus') AS [MergeStatus],
    FULLTEXTCATALOGPROPERTY(cat.name,'PopulateCompletionAge') AS [PopulateCompletionAge],
    (SELECT CASE FULLTEXTCATALOGPROPERTY(name,'PopulateStatus')
        WHEN 0 THEN 'Idle'
        WHEN 1 THEN 'Full Population In Progress'
        WHEN 2 THEN 'Paused'
        WHEN 3 THEN 'Throttled'
        WHEN 4 THEN 'Recovering'
        WHEN 5 THEN 'Shutdown'
        WHEN 6 THEN 'Incremental Population In Progress'
        WHEN 7 THEN 'Building Index'
        WHEN 8 THEN 'Disk Full.  Paused'
        WHEN 9 THEN 'Change Tracking' END) AS PopulateStatus,
    FULLTEXTCATALOGPROPERTY(cat.name,'ImportStatus') AS [ImportStatus]
FROM sys.fulltext_catalogs AS cat
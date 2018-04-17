SET NOCOUNT ON

CREATE TABLE #Permisos (
[contid] INT IDENTITY PRIMARY KEY CLUSTERED, 
[action] INT NOT NULL, 
[column] NVARCHAR(128),
[uid] INT NOT NULL,
[username] NVARCHAR(256), 
[protecttype] INT NOT NULL,
[name] NVARCHAR(128), 
[owner] NVARCHAR(256),
[id] INT NOT NULL,
[grantor] NVARCHAR(256)
)

DECLARE @Owner sysname
DECLARE @ObjName sysname
DECLARE @Cmd VARCHAR(1000)

DECLARE Objeto CURSOR READ_ONLY FOR
SELECT USER_NAME(uid), name 
FROM dbo.sysobjects
WHERE type IN ('FN', 'P', 'U', 'V')
ORDER BY name

OPEN Objeto
FETCH NEXT FROM Objeto INTO @Owner, @ObjName
WHILE @@FETCH_STATUS = 0
BEGIN
SELECT @Cmd = 'INSERT INTO #Permisos EXEC dbo.sp_MSobjectprivs ' + '[' + @Owner + '.' + @ObjName + ']'
EXEC (@Cmd)

FETCH NEXT FROM Objeto INTO @Owner, @ObjName
END

CLOSE Objeto
DEALLOCATE Objeto

SELECT CASE WHEN [protecttype] = 206 THEN 'DENY ' ELSE 'GRANT ' END + 
CASE WHEN [action] = 193 THEN 'SELECT ON [' + [owner] + '].[' + [name] + '] TO ' + '[' + [username] + '] '
WHEN [action] = 195 THEN 'INSERT ON [' + [owner] + '].[' + [name] + '] TO ' + '[' + [username] + '] ' 
WHEN [action] = 196 THEN 'DELETE ON [' + [owner] + '].[' + [name] + '] TO ' + '[' + [username] + '] ' 
WHEN [action] = 197 THEN 'UPDATE ON [' + [owner] + '].[' + [name] + '] TO ' + '[' + [username] + '] ' 
WHEN [action] = 224 THEN 'EXECUTE ON [' + [owner] + '].[' + [name] + '] TO ' + '[' + [username] + '] ' END -- + 
-- CASE WHEN LOWER([username]) = 'public' THEN 'CASCADE ' ELSE '' END AS [privs]
FROM #Permisos
WHERE [action] IN (193, 195, 196, 197, 224) 
AND [username] <> 'public'

-- SELECT * FROM #Permisos
DROP TABLE #Permisos
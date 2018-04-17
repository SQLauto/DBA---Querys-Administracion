SELECT	USER_NAME(grantee_principal_id) AS 'User\RoleName',
		OBJECT_NAME(major_id) AS 'ObjectName',
		PERMISSION_NAME AS Permission,
		state_desc
FROM sys.database_permissions
WHERE	class = 1
		AND grantee_principal_id <> 0
--		AND OBJECT_NAME(major_id) = 'prodmaster'
SELECT major_id, minor_id, t.name AS [Table Name], c.name AS [Column Name], ep.name AS Name, value AS [Extended Property]
FROM sys.extended_properties AS ep
INNER JOIN sys.tables AS t ON ep.major_id = t.object_id 
INNER JOIN sys.columns AS c ON ep.major_id = c.object_id AND ep.minor_id = c.column_id
WHERE class = 1;


EXEC sys.sp_addextendedproperty 
@name = N'MS_Description', 
@value = N'Esto es una prueba', 
@level0type = N'SCHEMA', @level0name = dbo, 
@level1type = N'TABLE',  @level1name = Configuration,
@level2type = N'COLUMN', @level2name = ConfigurationName;

EXEC sys.sp_updateextendedproperty 
@name = N'MS_Description', 
@value = N'Esto es una prueba', 
@level0type = N'SCHEMA', @level0name = dbo, 
@level1type = N'TABLE',  @level1name = Configuration,
@level2type = N'COLUMN', @level2name = ConfigurationName;



EXEC sys.sp_dropextendedproperty
@name = N'MS_Description', 
@level0type = N'SCHEMA', @level0name = dbo, 
@level1type = N'TABLE',  @level1name = Configuration,
@level2type = N'COLUMN', @level2name = ConfigurationName;




EXEC sys.sp_addextendedproperty 
@name = N'MS_Description', 
@value = N'Esto es una prueba', 
@level0type = N'SCHEMA', @level0name = dbo, 
@level1type = N'VIEW',  @level1name = AvisoSolr,
@level2type = N'COLUMN', @level2name = IdAviso;

Y para luego traer la info hay que hacer join con la System view “sys.views” en lugar de “sys.tables”.

SELECT major_id, minor_id, t.name AS [Table Name], c.name AS [Column Name], ep.name AS Name, value AS [Extended Property]
FROM sys.extended_properties AS ep
INNER JOIN sys.views AS t ON ep.major_id = t.object_id 
INNER JOIN sys.columns AS c ON ep.major_id = c.object_id AND ep.minor_id = c.column_id
WHERE class = 1;

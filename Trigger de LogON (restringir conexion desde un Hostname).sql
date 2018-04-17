CREATE TABLE [dbo].[HostnameRestriction](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[LoginName] [nvarchar](256) NULL,
	[ValidHostName] [nvarchar](64) NULL,
	[ValidIp] [nvarchar](15) NULL,
	[Status] [bit] NULL,
 CONSTRAINT [PK_HostnameRestriction] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
CREATE UNIQUE INDEX IX_HostnameRestriction_LoginName_ValidHostName ON HostnameRestriction (LoginName,ValidHostName);
GO
GRANT SELECT ON master.dbo.HostnameRestriction TO Public
GO
ALTER TRIGGER tr_logon_block_user
ON ALL SERVER 
FOR LOGON 
AS
DECLARE @Ip AS NVARCHAR(15),
		@HostName AS NVARCHAR(64),
		@LoginName AS NVARCHAR(128),
		@error AS VARCHAR(MAX)
BEGIN
   SET @Ip = (SELECT EVENTDATA().value('(/EVENT_INSTANCE/ClientHost)[1]', 'NVARCHAR(15)'));
   SET @HostName = Cast(HOST_NAME() as NVARCHAR(64))
   SET @LoginName = (SELECT EVENTDATA().value('(/EVENT_INSTANCE/LoginName)[1]', 'VARCHAR(256)'))
   IF EXISTS (SELECT * FROM master.dbo.HostnameRestriction WHERE LoginName = @LoginName AND status = 1) -- Si el login tiene alguna restricción.
   BEGIN
	IF NOT EXISTS (SELECT * FROM master.dbo.HostnameRestriction WHERE LoginName = @LoginName AND ValidHostName = @HostName AND ValidIp =@Ip AND Status = 1) -- Verifico que el HostName e IP este autorizado.
	BEGIN
	  SET @error = 'The CONNECTION permission from LoginName: '+@LoginName+' HostName: '+@HostName + ' ('+@Ip+') was denied'
	  RAISERROR (@error, 16, 1) 
      ROLLBACK
	END 
   END
END


INSERT INTO  master.dbo.HostnameRestriction VALUES ('deautos_dev_app','C_SINM_FCHA_PWX','10.1.200.5',1)


DISABLE TRIGGER tr_logon_block_user ON ALL SERVER;
ENABLE TRIGGER tr_logon_block_user ON ALL SERVER;

sp_Readerrorlog




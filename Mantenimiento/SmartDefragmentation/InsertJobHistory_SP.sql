USE [Master]
GO
CREATE PROC dbo.InsertJobHistory_SP (@JobName SYSNAME, @Output VARCHAR(MAX))
AS
SET NOCOUNT ON
BEGIN
	INSERT INTO dbo.JobHistory (JobName,Output,Date)
	SELECT @JobName,@Output,GETDATE()
END
SET NOCOUNT OFF


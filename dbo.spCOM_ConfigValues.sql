USE PACT2C222
GO
SET ANSI_NULLS, QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spCOM_ConfigValues]
	@Type [int] = 0,
	@Param1 [nvarchar](max),
	@Param2 [nvarchar](max) = NULL
WITH ENCRYPTION, EXECUTE AS CALLER
AS
BEGIN TRY  
SET NOCOUNT ON;
	declare @UserID int,@SQL nvarchar(max)
	
	IF @Type=1
	BEGIN
		if @Param1='NotifTime'
			select Name,convert(datetime,convert(float,Value)) Value, getdate() SysDate from COM_Config with(nolock) where Name in ('NotficatonServiceLastAccessTime', 'DBBackupTime')
		else
			select Name,Value from COM_Config with(nolock) where Name=@Param1
	END
	ELSE IF @Type=2
	BEGIN
		if not exists (select Name from COM_Config with(nolock) where Name=@Param1)
			insert into COM_Config(Name,Value) values(@Param1,@Param2)
		else
			update COM_Config
			set Value=@Param2
			where Name=@Param1
		
		select 1 Saved
	END
	ELSE IF @Type=4
	BEGIN
		if not exists (select Name from COM_Config with(nolock) where Name=@Param1)
			insert into COM_Config(Name,Value) values(@Param1,convert(decimal(18,6),getdate()))
		else
			update COM_Config
			set Value=convert(decimal(18,6),getdate())
			where Name=@Param1
	END

SET NOCOUNT OFF;
RETURN 1
END TRY
BEGIN CATCH  
		--Return exception info [Message,Number,ProcedureName,LineNumber]  
		IF ERROR_NUMBER()=50000
		BEGIN
			SELECT ErrorMessage,ErrorNumber FROM COM_ErrorMessages WITH(NOLOCK) WHERE ErrorNumber=ERROR_MESSAGE() AND LanguageID=1
		END
		ELSE
		BEGIN
			SELECT ErrorMessage, ERROR_MESSAGE() AS ServerMessage,ERROR_NUMBER() as ErrorNumber, ERROR_PROCEDURE()as ProcedureName, ERROR_LINE() AS ErrorLine
			FROM COM_ErrorMessages WITH(NOLOCK) WHERE ErrorNumber=-999 AND LanguageID=1
		END
SET NOCOUNT OFF  
RETURN -999   
END CATCH
GO

USE PACT2C222
GO
SET ANSI_NULLS, QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spRPT_GetPrintFormateData]
	@Type [int],
	@FormateID [bigint]
WITH ENCRYPTION, EXECUTE AS CALLER
AS
BEGIN TRY  
SET NOCOUNT ON;

IF @Type=1
	select FormateID,Name,isdefault from ADM_PrintFormates WITH(NOLOCK) where Type='Report'
ELSE IF @Type=2
	select FormateID,Name,isdefault from ADM_PrintFormates WITH(NOLOCK) where Type='Document'
ELSE IF @Type=3
	select * from ADM_PrintFormates WITH(NOLOCK) where FormateID=@FormateID
ELSE IF @Type=4
	select * from ADM_PrintFormates WITH(NOLOCK) where isdefault=1 and Type='Report'
ELSE IF @Type=5
begin
	select ReportID,ReportName from ADM_RevenuReports WITH(NOLOCK) where ReportID>0 order by ReportName
end

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

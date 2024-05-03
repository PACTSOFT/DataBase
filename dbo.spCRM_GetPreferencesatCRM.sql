﻿USE PACT2C222
GO
SET ANSI_NULLS, QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spCRM_GetPreferencesatCRM]
	@CCID [bigint] = 0,
	@UserID [bigint] = 1,
	@LangID [int] = 1
WITH ENCRYPTION, EXECUTE AS CALLER
AS
BEGIN TRANSACTION
BEGIN TRY	
SET NOCOUNT ON
	DECLARE  @TBL TABLE(ID INT IDENTITY(1,1),DOCID BIGINT)
	DECLARE @DATA NVARCHAR(MAX)

	SELECT @DATA=Value FROM COM_CostCenterPreferences WITH(NOLOCK) 
	WHERE Name='CreateDocuments' and CostCenterID=@CCID 

	INSERT INTO @TBL(DOCID)
	EXEC SPSPLITSTRING @DATA,';'
	
	SELECT T.DOCID,D.DocumentName DOCNAME FROM ADM_DocumentTypes D WITH(NOLOCK) 
	JOIN @TBL T ON T.DOCID=D.CostCenterID

COMMIT TRANSACTION
SET NOCOUNT OFF;
RETURN 1
END TRY
BEGIN CATCH  
	--Return exception info [Message,Number,ProcedureName,LineNumber]  
	IF ERROR_NUMBER()=50000
	BEGIN
		SELECT ErrorMessage,ErrorNumber FROM COM_ErrorMessages WITH(nolock) WHERE ErrorNumber=ERROR_MESSAGE() AND LanguageID=@LangID
	END
	ELSE
	BEGIN
		SELECT ErrorMessage, ERROR_MESSAGE() AS ServerMessage,ERROR_NUMBER() as ErrorNumber, ERROR_PROCEDURE()as ProcedureName, ERROR_LINE() AS ErrorLine
		FROM COM_ErrorMessages WITH(nolock) WHERE ErrorNumber=-999 AND LanguageID=@LangID
	END
ROLLBACK TRANSACTION
SET NOCOUNT OFF  
RETURN -999   
END CATCH  
GO

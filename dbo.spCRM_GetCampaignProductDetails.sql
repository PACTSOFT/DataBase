﻿USE PACT2C222
GO
SET ANSI_NULLS, QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spCRM_GetCampaignProductDetails]
	@CampaignID [bigint] = 0,
	@UserId [int] = 0,
	@LangId [int] = 1
WITH ENCRYPTION, EXECUTE AS CALLER
AS
BEGIN TRANSACTION
BEGIN TRY	
SET NOCOUNT ON
 
 DECLARE @DATA NVARCHAR(300),@COUNT INT,@I INT
 SELECT @DATA=ISNULL(VALUE,0) FROM COM_COSTCENTERPREFERENCES WHERE COSTCENTERID=88 AND NAME='CampaignDimensionsAtProduct'
 
 CREATE TABLE #TBL(ID INT IDENTITY(1,1),VALUE NVARCHAR(300),FEATURENAME NVARCHAR(300)) 
 INSERT INTO #TBL(VALUE)
 EXEC SPSPLITSTRING @DATA,';'
 
 SELECT @COUNT=COUNT(*),@I=1 FROM #TBL
 WHILE @I<=@COUNT
 BEGIN
 UPDATE #TBL SET FEATURENAME=(SELECT NAME FROM ADM_FEATURES WHERE FEATUREID=(
 SELECT VALUE FROM #TBL WHERE ID=@I)) WHERE ID=@I
 SET @I=@I+1
 END
 
 SELECT * FROM #TBL ORDER BY FEATURENAME
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

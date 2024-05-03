USE PACT2C222
GO
SET ANSI_NULLS, QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spSVC_GetThirdPartyPrices]
	@AccountID [bigint] = 0,
	@ProductID [bigint] = 0,
	@LocationID [bigint],
	@VehicleID [bigint] = 0,
	@UserID [bigint],
	@LangID [int] = 1
WITH ENCRYPTION, EXECUTE AS CALLER
AS
BEGIN TRY  
SET NOCOUNT ON;	
	  
	--COSTCENTER WISE RATE
	SELECT * FROM COM_CCPrices WITH(NOLOCK)
	WHERE WEF<=CONVERT(FLOAT,GETDATE()) AND ProductID=@ProductID AND CCNID50=@AccountID
	AND   CCNID2=@LocationID  AND CCNID24 IN (SELECT SegmentID FROM SVC_VEHICLE WHERE VEHICLEID=@VehicleID)
	ORDER BY WEF DESC
	 
	
  
SET NOCOUNT OFF;
RETURN 1
END TRY
BEGIN CATCH  
		--Return exception info [Message,Number,ProcedureName,LineNumber]  
		IF ERROR_NUMBER()=50000
		BEGIN
			SELECT ErrorMessage,ErrorNumber FROM COM_ErrorMessages WITH(NOLOCK) WHERE ErrorNumber=ERROR_MESSAGE() AND LanguageID=@LangID
		END
		ELSE
		BEGIN
			SELECT ErrorMessage, ERROR_MESSAGE() AS ServerMessage,ERROR_NUMBER() as ErrorNumber, ERROR_PROCEDURE()as ProcedureName, ERROR_LINE() AS ErrorLine
			FROM COM_ErrorMessages WITH(NOLOCK) WHERE ErrorNumber=-999 AND LanguageID=@LangID
		END
 
SET NOCOUNT OFF  
RETURN -999   
END CATCH


GO

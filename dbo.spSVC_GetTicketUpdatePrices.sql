USE PACT2C222
GO
SET ANSI_NULLS, QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spSVC_GetTicketUpdatePrices]
	@TicketID [bigint],
	@USERID [int],
	@LANGID [int]
WITH ENCRYPTION, EXECUTE AS CALLER
AS
BEGIN TRY  
SET NOCOUNT ON;
		 
	 
		/****** SERVICE PARTS INFO ******/
		SELECT P.SerialNumber,P.ProductID,
		P.IsRequired,P.Quantity,P.EstimatedQty,P.Rate,P.Value,P.PartID  ,
	 	P.Link,P.Parent,   P.UpdatedPrice,Pro.ProductTypeID
		FROM SVC_ServicePartsInfo P WITH(NOLOCK) 
		JOIN INV_Product Pro WITH(NOLOCK) ON Pro.ProductID=P.ProductID  
		WHERE P.ServiceTicketID=@TicketID and P.Rate<>isnull(P.UpdatedPrice,P.Rate)
		ORDER BY P.SerialNumber 
			
		 
	 

SET NOCOUNT OFF;  
END TRY  
BEGIN CATCH  
	--Return exception info [Message,Number,ProcedureName,LineNumber]  
	IF ERROR_NUMBER()=50000
	BEGIN		  
		SELECT ErrorMessage,ErrorNumber FROM COM_ErrorMessages WITH(NOLOCK) WHERE ErrorNumber=ERROR_MESSAGE() AND LanguageID=@LangID
	END
	ELSE
	BEGIN
		SELECT ErrorMessage, ERROR_MESSAGE() AS ServerMessage,ERROR_NUMBER() AS ErrorNumber, ERROR_PROCEDURE()AS ProcedureName, ERROR_LINE() AS ErrorLine
		FROM COM_ErrorMessages WITH(NOLOCK) WHERE ErrorNumber=-999 AND LanguageID=@LangID
	END

	SET NOCOUNT OFF  
	RETURN -999   
END CATCH 
GO

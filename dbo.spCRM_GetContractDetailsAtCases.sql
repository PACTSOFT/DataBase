USE PACT2C222
GO
SET ANSI_NULLS, QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spCRM_GetContractDetailsAtCases]
	@CUSTOMERID [bigint] = 0,
	@UserID [bigint],
	@LangID [int] = 1
WITH ENCRYPTION, EXECUTE AS CALLER
AS
BEGIN TRANSACTION
BEGIN TRY	
SET NOCOUNT ON


SELECT DISTINCT DOCID,VOUCHERNO FROM INV_DOCDETAILS WITH(NOLOCK) WHERE DOCUMENTTYPEID=35 AND DEBITACCOUNT=@CUSTOMERID

SELECT P.ProductName,  C.ProductID,DOCID FROM INV_DOCDETAILS C WITH(NOLOCK) 
LEFT  JOIN
  INV_Product AS P ON P.ProductID = C.ProductID 
   WHERE DOCUMENTTYPEID=35 AND DEBITACCOUNT=@CUSTOMERID
                      
--		--Declaration Section
		   
--SELECT      P.ProductName,  C.ProductID,C.ContractLineID,CONVERT(VARCHAR,C.ContractLineID) + ' - ' +  P.ProductName as CP,
--C.SerialNumber
--FROM         CRM_ContractLines AS C WITH(NOLOCK) LEFT OUTER JOIN
--                      INV_Product AS P ON P.ProductID = C.ProductID 
-- WHERE     (C.SvcContractID = @SvcContractID)
 
 
-- SELECT ServiceLvlID,ServiceLvlName FROM CRM_ContractTemplate WITH(NOLOCK) WHERE ContractTemplID IN (
-- SELECT ContractTemplID FROM CRM_ServiceContract WITH(NOLOCK) WHERE SvcContractID=@SvcContractID)
  
				
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

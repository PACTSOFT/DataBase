USE PACT2C222
GO
SET ANSI_NULLS, QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spPAY_InsertYearwiseTaxAmountLimit]
	@Year [int],
	@TaxAmountLimitXML [nvarchar](max),
	@CreatedBy [nvarchar](50) = NULL,
	@UserID [int] = 1,
	@LangID [int] = 1
WITH ENCRYPTION, EXECUTE AS CALLER
AS
BEGIN TRANSACTION
Begin Try
DECLARE @XML xml

DELETE FROM PAY_YearwiseTaxAmountLimit WHERE Year=@Year

SET @XML=@TaxAmountLimitXML
INSERT INTO PAY_YearwiseTaxAmountLimit(Year,ComponentID,AmountLimit,CreatedBy,CreatedDate,ModifiedDate)
SELECT  @Year,A.value('@ComponentID','int'),A.value('@AmountLimit','nvarchar(50)'),@CreatedBy,getdate(),getdate()
FROM @XML.nodes('Rows/row') as Data(A)	

COMMIT TRANSACTION
--SELECT * FROM [COM_CC50051] WITH(nolock) WHERE NodeID=@EmpNode  
SELECT ErrorMessage,ErrorNumber FROM COM_ErrorMessages WITH(nolock)   
WHERE ErrorNumber=100 AND LanguageID=@LangID  
SET NOCOUNT OFF;    
RETURN @Year    

End Try
Begin Catch
   IF ERROR_NUMBER()=50000  
	BEGIN  
		--SELECT * FROM COM_CC50051 WITH(NOLOCK) WHERE NodeID=@EmpNode    
		SELECT ErrorMessage,ErrorNumber FROM COM_ErrorMessages WITH(NOLOCK)   
		WHERE ErrorNumber=ERROR_MESSAGE() AND LanguageID=@LangID  
	END  
	ELSE IF ERROR_NUMBER()=547  
	BEGIN  
		SELECT ErrorMessage, ERROR_MESSAGE() AS ServerMessage,ERROR_NUMBER() AS ErrorNumber, ERROR_PROCEDURE()as ProcedureName, ERROR_LINE() AS ErrorLine FROM COM_ErrorMessages WITH(NOLOCK)  
		WHERE ErrorNumber=-110 AND LanguageID=@LangID  
	END   
	ELSE  
	BEGIN  
		SELECT ErrorMessage, ERROR_MESSAGE() AS ServerMessage,ERROR_NUMBER() AS ErrorNumber, ERROR_PROCEDURE()as ProcedureName, ERROR_LINE() AS ErrorLine  
		FROM COM_ErrorMessages WITH(NOLOCK) WHERE ErrorNumber=-999 AND LanguageID=@LangID  
	END  
	ROLLBACK TRANSACTION  
	SET NOCOUNT OFF    
	RETURN -999     
End Catch
GO

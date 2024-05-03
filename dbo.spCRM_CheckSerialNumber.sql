USE PACT2C222
GO
SET ANSI_NULLS, QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spCRM_CheckSerialNumber]
	@ProductID [int],
	@SerialNumber [int],
	@UserID [bigint],
	@LangID [int] = 1
WITH ENCRYPTION, EXECUTE AS CALLER
AS
BEGIN TRANSACTION
BEGIN TRY  
SET NOCOUNT ON;    
		--Declaration Section  
		DECLARE @Dt FLOAT
		DECLARE @TempGuid NVARCHAR(50) 
		DECLARE @HasAccess bit
		declare @Count int


select @Count=count(*) from CRM_ContractLines with(nolock)
where 
ProductID=@ProductID
--and SvcContractID =@SvcContractID
and SerialNumber =@SerialNumber
 
 
  
COMMIT TRANSACTION    
SET NOCOUNT OFF;     
RETURN @Count
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
 ROLLBACK TRANSACTION  
 SET NOCOUNT OFF    
 RETURN -999     
END CATCH   
  
 
  
  
  
  
  








GO

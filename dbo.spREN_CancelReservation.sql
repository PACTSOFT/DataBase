USE PACT2C222
GO
SET ANSI_NULLS, QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spREN_CancelReservation]
	@QuotationID [bigint],
	@date [datetime],
	@PayOption [int],
	@CompanyGUID [nvarchar](50),
	@UserName [nvarchar](50),
	@UserID [int] = 0,
	@RoleID [int] = 0,
	@LangID [int] = 1
WITH ENCRYPTION, EXECUTE AS CALLER
AS
BEGIN TRANSACTION      
BEGIN TRY        
SET NOCOUNT ON;     


	UPDATE REN_Quotation  
	SET STATUSID = 469,CancellationDate=CONVERT(float,@date) 
	WHERE QuotationID = @QuotationID  
	
--------------------------Cancel  POSTINGS --------------------------  

	IF( @PayOption  = 1)  
	BEGIN 
		DECLARE @DELETEDOCID BIGINT , @DELETECCID BIGINT,@return_value int

		select @DELETEDOCID=DocID,@DELETECCID=COSTCENTERID from [REN_ContractDocMapping]  WITH(nolock)   
		where  [ContractID]=@QuotationID and ContractCCID=129

		IF @DELETEDOCID IS NOT NULL and @DELETEDOCID>0
		BEGIN
			EXEC @return_value = [dbo].[spDOC_SuspendAccDocument]  
			@CostCenterID = @DELETECCID, 
			@DocID=@DELETEDOCID,
			@DocPrefix = '',  
			@DocNumber = '', 
			@Remarks=N'', 
			@UserID = @UserID,  
			@UserName = @UserName,
			@RoleID=@RoleID,
			@LangID = @LangID 
		END
	END	
   
COMMIT TRANSACTION       
     
SELECT ErrorMessage,ErrorNumber FROM COM_ErrorMessages WITH(nolock)     
WHERE ErrorNumber=100 AND LanguageID=@LangID    
SET NOCOUNT OFF;
RETURN @QuotationID        
END TRY        
BEGIN CATCH   
 if(@return_value is null or  @return_value<>-999)     
 BEGIN          
IF ERROR_NUMBER()=50000    
 BEGIN    
 SELECT ErrorMessage,ErrorNumber FROM COM_ErrorMessages WITH(nolock)     
  WHERE ErrorNumber=ERROR_MESSAGE() AND LanguageID=@LangID    
 END    
 ELSE IF ERROR_NUMBER()=547    
 BEGIN    
  SELECT ErrorMessage, ERROR_MESSAGE() AS ServerMessage,ERROR_NUMBER() as ErrorNumber, ERROR_PROCEDURE()as ProcedureName, ERROR_LINE() AS ErrorLine FROM COM_ErrorMessages WITH(nolock)    
  WHERE ErrorNumber=-110 AND LanguageID=@LangID    
 END    
 ELSE IF ERROR_NUMBER()=2627    
 BEGIN    
  SELECT ErrorMessage, ERROR_MESSAGE() AS ServerMessage,ERROR_NUMBER() as ErrorNumber, ERROR_PROCEDURE()as ProcedureName, ERROR_LINE() AS ErrorLine FROM COM_ErrorMessages WITH(nolock)    
  WHERE ErrorNumber=-116 AND LanguageID=@LangID    
 END    
 ELSE    
 BEGIN    
  SELECT ErrorMessage, ERROR_MESSAGE() AS ServerMessage,ERROR_NUMBER() as ErrorNumber, ERROR_PROCEDURE()as ProcedureName, ERROR_LINE() AS ErrorLine    
  FROM COM_ErrorMessages WITH(nolock) WHERE ErrorNumber=-999 AND LanguageID=@LangID    
 END     
 ROLLBACK TRANSACTION      
 END  
 SET NOCOUNT OFF        
 RETURN -999         
    
    
END CATCH   
  
GO

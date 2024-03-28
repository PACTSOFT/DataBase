USE PACT2c253
GO
SET ANSI_NULLS, QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spREN_GetSecurityDeposit]
	@CostCenterID [int],
	@ContractID [int],
	@UserID [int],
	@LangID [int] = 1
WITH ENCRYPTION, EXECUTE AS CALLER
AS
BEGIN TRY                         
SET NOCOUNT ON    
	declare @Amt float
	set @Amt=0
	
 
 	while(@ContractID>0)
	BEGIN
	 
		SELECT @Amt=@Amt+sum(isnull(CP.Amount,0))
		
		FROM REN_ContractParticulars  CP WITH(NOLOCK)   
		LEFT JOIN REN_CONTRACT CNT WITH(NOLOCK) ON CP.CONTRACTID = CNT.CONTRACTID 
		LEFT JOIN REN_Particulars PART WITH(NOLOCK) ON CP.CCNODEID = PART.ParticularID  and  PART.PropertyID = CNT.PropertyID AND PART.UNITID = CNT.UnitID
		LEFT JOIN REN_Particulars PARTP WITH(NOLOCK) ON CP.CCNODEID = PARTP.ParticularID  and  PARTP.PropertyID = CNT.PropertyID AND PARTP.UNITID = 0
		where  CP.ContractID = @ContractID and 
		((PART.Refund is not null and PART.Refund =1) or (PARTP.Refund is not null and PARTP.Refund =1) )
		
		if exists(select isnull(RenewRefID,0) from REN_Contract		
		where ContractID=@ContractID)
			select @ContractID=isnull(RenewRefID,0) from REN_Contract		
			where ContractID=@ContractID
		ELSE
			set @ContractID=0
	END 	
	
	select @Amt	SecurityDeposit

END TRY    
BEGIN CATCH    
 --Return exception info [Message,Number,ProcedureName,LineNumber]    
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
 SET NOCOUNT OFF    
 RETURN -999     
END CATCH	
		
		
GO

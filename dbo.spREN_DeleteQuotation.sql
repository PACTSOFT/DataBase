USE PACT2C222
GO
SET ANSI_NULLS, QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spREN_DeleteQuotation]
	@CCID [bigint],
	@QuotationID [bigint] = 0,
	@UserID [bigint] = 1,
	@RoleID [int],
	@LangID [int] = 1
WITH ENCRYPTION, EXECUTE AS CALLER
AS
BEGIN TRANSACTION  
BEGIN TRY    
	SET NOCOUNT ON;    
  
	DECLARE @TBLCNT INT,@INCCNT INT,@DELETEDOCID BIGINT,@DELETECCID BIGINT
	DECLARE @return_value int,@HasAccess BIT
	
	--User acces check
	SET @HasAccess=dbo.fnCOM_HasAccess(@RoleID,@CCID,4)

	IF @HasAccess=0
	BEGIN
		RAISERROR('-105',16,1)
	END
	
	if @CCID=129 and exists(select ContractID  from REN_Contract with(NOLOCK) where QuotationID=@QuotationID)
		RAISERROR('-535',16,1)
	
	if @CCID=103 and exists(select ContractID  from REN_Contract with(NOLOCK) where QuotationID=@QuotationID)
		RAISERROR('-569',16,1)	
		
	if(@CCID=129)
	BEGIN
		DECLARE @tblListDEL TABLE(ID int identity(1,1),DocID BIGINT,COSTCENTERID BIGINT)      
		
		INSERT INTO @tblListDEL    
		SELECT DocID,CostCenterID
		FROM ACC_DOCDETAILS  
		WHERE RefCCID=129 and REFNODEID = @QuotationID 
	 
		SELECT @TBLCNT = COUNT(ID) FROM @tblListDEL  

		SET @INCCNT = 0  
		WHILE(@INCCNT < @TBLCNT)  
		BEGIN  
			SET @INCCNT = @INCCNT + 1  
			SELECT @DELETEDOCID = DocID  , @DELETECCID = CostCenterID FROM @tblListDEL 
			WHERE ID = @INCCNT  
			
				EXEC @return_value = [dbo].[spDOC_DeleteAccDocument]  
				@CostCenterID = @DELETECCID,  
				@DocPrefix =  '',  
				@DocNumber = '',  
				@DocID=@DELETEDOCID ,
				@UserID = 1,  
				@UserName = N'ADMIN',  
				@LangID = 1,
				@RoleID=1
		END   

		DELETE FROM REN_ContractDocMapping WHERE CONTRACTID = @QuotationID and ContractCCID=129  
	END
	
	delete from REN_QuotationExtended where QuotationID=@QuotationID  
	Delete from REN_ContractParticularsDetail where ContractID=@QuotationID and Costcenterid=@CCID  
	delete from REN_QuotationParticulars where QuotationID=@QuotationID    
	delete from REN_QuotationPayTerms where QuotationID=@QuotationID 
	delete from COM_CCCCDATA WHERE NodeID=@QuotationID and CostCenterID = @CCID
	delete from COM_Files WHERE FeatureID=@CCID and  FeaturePK=@QuotationID 
	delete from COM_Notes WHERE FeatureID=@ccid and  FeaturePK=@QuotationID
	delete from REN_Quotation where  QuotationID=@QuotationID 
	 

COMMIT TRANSACTION  
SET NOCOUNT OFF;    
SELECT ErrorMessage,ErrorNumber FROM COM_ErrorMessages WITH(nolock)   
WHERE ErrorNumber=102 AND LanguageID=@LangID 
RETURN 1  
END TRY  
BEGIN CATCH    
	--Return exception info [Message,Number,ProcedureName,LineNumber]
	if(@return_value=-999)
		return @return_value
	IF ERROR_NUMBER()=50000  
	BEGIN  
		SELECT ErrorMessage,ErrorNumber FROM COM_ErrorMessages WITH(nolock) 
		WHERE ErrorNumber=ERROR_MESSAGE() AND LanguageID=@LangID  
	END  
	ELSE IF ERROR_NUMBER()=547  
	BEGIN  
		SELECT ErrorMessage, ERROR_MESSAGE() AS ServerMessage,ERROR_NUMBER() as ErrorNumber, ERROR_PROCEDURE()as ProcedureName, ERROR_LINE() AS ErrorLine 
		FROM COM_ErrorMessages WITH(nolock)  
		WHERE ErrorNumber=-110 AND LanguageID=@LangID  
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

USE PACT2C222
GO
SET ANSI_NULLS, QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spREN_CancelReservation]
	@QuotationID [bigint],
	@date [datetime],
	@PayOption [int],
	@RemaingPaymentXML [nvarchar](max),
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
	else IF(@PayOption  = 2 and @RemaingPaymentXML is not null and @RemaingPaymentXML<>'')  
	BEGIN 
			DECLARE @Dt float,@XML xml,@SNO int,@RcptCCID BIGint,@Prefix nvarchar(200)
			DECLARE  @AA XML,@DocXml nvarchar(max)   ,@amt float
			DECLARE @PickAcc nvarchar(50) ,@AccountType xml
			
			select @amt=b.amount from [REN_ContractDocMapping] a WITH(nolock)   
			join acc_docdetails b WITH(nolock) on a.DocID=b.DocID
			where  [ContractID]=@QuotationID and ContractCCID=129

			set @RemaingPaymentXML=replace(@RemaingPaymentXML,'##Balance##',convert(nvarchar(max),@amt))
			
			
			set @XML=@RemaingPaymentXML
			
			SELECT  @AA=CONVERT(NVARCHAR(MAX),  X.query('DocumentXML'))   ,@AccountType= CONVERT(NVARCHAR(MAX),  X.query('AccountType'))
			from @XML.nodes('/ReceiptXML/ROWS') as Data(X)  
			
			SELECT   @PickAcc =  X.value ('@DD', 'NVARCHAR(100)' )        
			from @AccountType.nodes('/AccountType') as Data(X) 

			if(@PickAcc='BANK')
				select @RcptCCID=CONVERT(int,Value) from COM_CostCenterPreferences WITH(nolock)  
				where CostCenterID=95 and Name='ContractPDP' 
			ELSE if(@PickAcc='CASH')
				select @RcptCCID=CONVERT(int,Value) from COM_CostCenterPreferences WITH(nolock)
				where CostCenterID=95 and Name='ContractPayment'
			ELSE
				select @RcptCCID=CONVERT(int,Value) from COM_CostCenterPreferences WITH(nolock)  
				where CostCenterID=95 and Name='ContractJVReceipt' 
			 
			Set @DocXml = convert(nvarchar(max), @AA)  

			EXEC	@return_value = [dbo].[spDOC_SetTempAccDocument]
				@CostCenterID = @RcptCCID,
				@DocID = 0,
				@DocPrefix = N'',
				@DocNumber =1,
				@DocDate = @date,
				@DueDate = NULL,
				@BillNo = @SNO,
				@InvDocXML = @DocXml,
				@NotesXML = N'',
				@AttachmentsXML = N'',
				@ActivityXML  = N'', 
				@IsImport = 0,
				@LocationID = 0,
				@DivisionID = 0,
				@WID = 0,
				@RoleID = @RoleID,
				@RefCCID = 129,
				@RefNodeid = @QuotationID ,
				@CompanyGUID = @CompanyGUID,
				@UserName = @UserName,
				@UserID = @UserID,
				@LangID = @LangID
	  
	  
			INSERT INTO  [REN_ContractDocMapping]  
		   ([ContractID],[Type]  ,[Sno]  ,DocID  ,CostcenterID  
		   ,IsAccDoc,DocType  , ContractCCID)values
		   (@QuotationID,101,0,@return_value,@RcptCCID,1,0 , 129)
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

USE PACT2C222
GO
SET ANSI_NULLS, QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spREN_CloseReservation]
	@QuotationID [bigint],
	@VacancyDate [datetime],
	@PostPDRecieptXML [nvarchar](max),
	@ContractLocationID [bigint],
	@ContractDivisionID [bigint],
	@RoleID [bigint] = 0,
	@CompanyGUID [nvarchar](50),
	@UserName [nvarchar](50),
	@UserID [int] = 0,
	@LangID [int] = 1
WITH ENCRYPTION, EXECUTE AS CALLER
AS
BEGIN TRANSACTION        
BEGIN TRY      
	SET NOCOUNT ON; 
	
	UPDATE REN_Quotation SET StatusID=471,VacancyDate=CONVERT(FLOAT,@VacancyDate),
	ModifiedBy=@UserName,ModifiedDate=CONVERT(FLOAT,GETDATE())
	WHERE QuotationID=@QuotationID
		  
	if(@PostPDRecieptXML<>'')
	BEGIN
		declare @DocPrefix nvarchar(200),@XML xml,@CNT int,@i int,@AA nvarchar(max),@DocXML XML
		declare @AccValue nvarchar(100),@RcptCCID int,@SNO BIGINT,@return_value int 
		
		select @SNO=SNO from REN_Quotation WITH(NOLOCK) WHERE QuotationID = @QuotationID
		
		SET @XML=@PostPDRecieptXML       
		declare  @tblListPDR TABLE(ID int identity(1,1),TRANSXML NVARCHAR(MAX),Documents NVARCHAR(200) )          
		
		INSERT INTO @tblListPDR        
		SELECT  CONVERT(NVARCHAR(MAX),X.query('DocumentXML')),CONVERT(NVARCHAR(200),X.query('Documents'))                  
		from @XML.nodes('/PDR/ROWS') as Data(X)        

		SELECT @CNT = COUNT(ID) FROM @tblListPDR      
		SET @I = 0      
		WHILE(@I < @CNT)      
		BEGIN      
			SET @I =@I+1  
			SELECT @AA = TRANSXML,@DocXML = Documents  FROM @tblListPDR WHERE  ID = @I      

			SELECT @AccValue =  X.value ('@DD', 'NVARCHAR(100)' )
			from @DocXML.nodes('/Documents') as Data(X)      
			
			IF(@AccValue = 'BANK')    
			BEGIN    
				select @RcptCCID=CONVERT(int,Value) from COM_CostCenterPreferences WITH(nolock)      
				where CostCenterID=95 and Name='ContractPostDatedReceipt'      
			END    
			ELSE  IF(@AccValue = 'CASH')    
			BEGIN    
				select @RcptCCID=CONVERT(int,Value) from COM_CostCenterPreferences WITH(nolock)      
				where CostCenterID=95 and Name='ContractCashReceipt'      
			END    
			ELSE  IF(@AccValue = 'JV')    
			BEGIN    
				select @RcptCCID=CONVERT(int,Value) from COM_CostCenterPreferences WITH(nolock)      
				where CostCenterID=95 and Name='ContractJVReceipt'      
			END 
			
			set @DocPrefix=''
			EXEC [sp_GetDocPrefix] '',@VacancyDate,@RcptCCID,@DocPrefix output,@QuotationID,0,0,129

			EXEC @return_value = [dbo].[spDOC_SetTempAccDocument]      
				   @CostCenterID = @RcptCCID,      
				   @DocID = 0,      
				   @DocPrefix =@DocPrefix,      
				   @DocNumber =1,      
				   @DocDate = @VacancyDate,     
				   @DueDate = NULL,      
				   @BillNo = @SNO,      
				   @InvDocXML = @AA,      
				   @NotesXML = N'',      
				   @AttachmentsXML = N'',      
				   @ActivityXML  = N'',     
				   @IsImport = 0,      
				   @LocationID = @ContractLocationID,      
				   @DivisionID = @ContractDivisionID,      
				   @WID = 0,      
				   @RoleID = @RoleID,      
				   @RefCCID = 129,    
				   @RefNodeid = @QuotationID ,    
				   @CompanyGUID = @CompanyGUID,      
				   @UserName = @UserName,      
				   @UserID = @UserID,      
				   @LangID = @LangID      

			 INSERT INTO [REN_ContractDocMapping]([ContractID],[Type],[Sno],DocID,CostcenterID,IsAccDoc,DocType,ContractCCID)      
			 values(@QuotationID,101,@I,@return_value,@RcptCCID,1,4,129)        

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

USE PACT2C222
GO
SET ANSI_NULLS, QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spREN_VacanctContract]
	@ContractID [bigint],
	@VacancyDate [datetime],
	@SRTXML [nvarchar](max) = NULL,
	@VacantXML [nvarchar](max) = NULL,
	@PenaltyXML [nvarchar](max) = NULL,
	@RemaingPaymentXML [nvarchar](max) = NULL,
	@SRTAmount [float] = 0,
	@RefundAmt [float] = 0,
	@PDCRefund [float] = 0,
	@Penalty [float] = 0,
	@Amt [float] = 0,
	@TermPayMode [int] = 1,
	@TermChequeNo [nvarchar](max) = NULL,
	@TermChequeDate [datetime],
	@TermRemarks [nvarchar](max) = NULL,
	@SecurityDeposit [float] = 0,
	@action [int],
	@RentRecID [bigint] = 0,
	@LocationID [bigint] = 0,
	@divisionID [bigint] = 0,
	@RoleID [bigint] = 0,
	@TermPart [nvarchar](max),
	@CompanyGUID [nvarchar](50),
	@GUID [nvarchar](50),
	@UserName [nvarchar](50),
	@UserID [int] = 0,
	@LangID [int] = 1
WITH ENCRYPTION, EXECUTE AS CALLER
AS
BEGIN TRANSACTION    
DECLARE @QUERYTEST NVARCHAR(100)  , @IROWNO NVARCHAR(100) , @TYPE NVARCHAR(100)  
BEGIN TRY      
SET NOCOUNT ON;   
  
	DECLARE @Dt float,@XML xml,@return_value int,@SNO int,@RcptCCID BIGint,@tempAmt float,@Prefix nvarchar(200)
	DECLARE  @CNT INT ,  @ICNT INT,@AA XML,@DocXml nvarchar(max) ,@BillWiseXMl nvarchar(max) ,@CCNODEID BIGINT,@Dimesion int   
	DECLARE @PickAcc nvarchar(50) ,@penAccID BIGINT,@AccountType xml
	
	SET @Dt=convert(float,getdate())--Setting Current Date   

	if(@action=3)
		UPDATE REN_CONTRACT
		SET STATUSID = 450 ,RefundDate = CONVERT(FLOAT , @VacancyDate),SRTAmount=@SRTAmount,RefundAmt=@RefundAmt,
		PDCRefund=@PDCRefund,Penalty=@Penalty,Amt=@Amt,TermPayMode=@TermPayMode,TermChequeNo=@TermChequeNo,
		TermChequeDate= CONVERT(FLOAT , @TermChequeDate),TermRemarks=@TermRemarks,SecurityDeposit=@SecurityDeposit
		,modifieddate=@Dt,modifiedby=@UserName
		WHERE ContractID = @ContractID or RefContractID=@ContractID
	ELSE
		UPDATE REN_CONTRACT
		SET STATUSID = 450 ,VacancyDate = CONVERT(FLOAT , @VacancyDate),SRTAmount=@SRTAmount,RefundAmt=@RefundAmt,
		PDCRefund=@PDCRefund,Penalty=@Penalty,Amt=@Amt,TermPayMode=@TermPayMode,TermChequeNo=@TermChequeNo,
		TermChequeDate= CONVERT(FLOAT , @TermChequeDate),TermRemarks=@TermRemarks,SecurityDeposit=@SecurityDeposit
		,modifieddate=@Dt,modifiedby=@UserName
		WHERE ContractID = @ContractID or RefContractID=@ContractID
	    
    
	select @SNO=ISNULL(SNO,0),@CCNODEID = CCNODEID,@Dimesion = CCID  from [REN_Contract] with(NOLOCK) 
	WHERE   CONTRACTID = @ContractID and RefContractID=0
	   
 	
	if(@SRTXML is not null and @SRTXML<>'')
	BEGIN
		select @RcptCCID=CONVERT(int,Value) from COM_CostCenterPreferences WITH(nolock)
		where CostCenterID=95 and Name='ContractSalesReturn'

		SET @XML = @SRTXML
		declare  @tblListSIVTemp TABLE(ID int identity(1,1),TRANSXML NVARCHAR(MAX) ,Documents NVARCHAR(200))        
		INSERT INTO @tblListSIVTemp    
		SELECT  CONVERT(NVARCHAR(MAX),  X.query('DocumentXML'))   ,  CONVERT(NVARCHAR(200),X.query('Documents'))                 
		from @XML.nodes('/SIV//ROWS') as Data(X)    

		SELECT @CNT = COUNT(ID) FROM @tblListSIVTemp  

		SET @ICNT = 0  
		WHILE(@ICNT < @CNT)  
		BEGIN  
			SET @ICNT =@ICNT+1  

			SELECT @AA = TRANSXML    FROM @tblListSIVTemp WHERE  ID = @ICNT  

			Set @DocXml = convert(nvarchar(max), @AA)  

			if exists(SELECT IsBillwise FROM ACC_Accounts WITH(nolock) WHERE AccountID=@RentRecID and IsBillwise=1)
			begin
				IF EXISTS(select Value from ADM_GLOBALPREFERENCES WITH(nolock) where NAME  = 'On')
				BEGIN
					set @XML=@DocXml
					select top 1 @tempAmt=X.value('@Gross',' float')  
					from @XML.nodes('/DocumentXML/Row/Transactions') as Data(X)        
					set @BillWiseXMl='<BillWise> <Row DocSeqNo="1" AccountID="'+convert(nvarchar,@RentRecID)+'" AmountFC="-'+CONVERT(nvarchar,@tempAmt)+'
					" AdjAmount="-'+CONVERT(nvarchar,@tempAmt)+'" AdjCurrID="1" AdjExchRT="1" IsNewReference="1" Narration="" IsDocPDC="0" ></Row></BillWise>'
				END
				ELSE
				BEGIN
					set @BillWiseXMl=''
				END
			end
			else
			begin
				set @BillWiseXMl=''
			end

			set @Prefix=''
			 EXEC [sp_GetDocPrefix] @DocXml,@VacancyDate,@RcptCCID,@Prefix   output
	
			set @DocXml=Replace(@DocXml,'<RowHead/>','')
			set @DocXml=Replace(@DocXml,'</DocumentXML>','')
			set @DocXml=Replace(@DocXml,'<DocumentXML>','')


			EXEC	@return_value = [dbo].[spDOC_SetTempInvDoc]
			@CostCenterID = @RcptCCID,
			@DocID = 0,
			@DocPrefix = @Prefix,
			@DocNumber = N'',
			@DocDate = @VacancyDate,
			@DueDate = NULL,
			@BillNo = @SNO,
			@InvDocXML =@DocXml,
			@BillWiseXML = @BillWiseXMl,
			@NotesXML = N'',
			@AttachmentsXML = N'',
			@ActivityXML  = N'', 
			@IsImport = 0,
			@LocationID = @LocationID,
			@DivisionID = @DivisionID ,
			@WID = 0,
			@RoleID = @RoleID,
			@DocAddress = N'',
			@RefCCID = 95,
			@RefNodeid  = @ContractID,
			@CompanyGUID = @CompanyGUID,
			@UserName = @UserName,
			@UserID = @UserID,
			@LangID = @LangID 
			
			INSERT INTO  [REN_ContractDocMapping]  
			([ContractID],[Type],[Sno],DocID,COSTCENTERID,IsAccDoc,DocType,ContractCCID)  			        
			values(@ContractID,101,@SNO+@ICNT,@return_value,@RcptCCID,0,0,95)

		END
	END 
	
	select @SNO=ISNULL(max(SNO),0)  from [REN_Contract] with(NOLOCK) WHERE   CONTRACTID = @ContractID

	if(@VacantXML is not null and @VacantXML<>'')
	BEGIN
			select @RcptCCID=CONVERT(int,Value) from COM_CostCenterPreferences WITH(nolock)
			where CostCenterID=95 and Name='ContractVacantDocument' and ISNUMERIC(Value)=1 
 
			Set @DocXml = convert(nvarchar(max), @VacantXML)  

			set @Prefix=''
			EXEC [sp_GetDocPrefix] @DocXml,@VacancyDate,@RcptCCID,@Prefix   output
			
			if exists(select * from adm_documenttypes WITH(NOLOCK) where costcenterid= @RcptCCID and isinventory=1)
			BEGIN
				set @DocXml=Replace(@DocXml,'<RowHead/>','')
				set @DocXml=Replace(@DocXml,'</DocumentXML>','')
				set @DocXml=Replace(@DocXml,'<DocumentXML>','')
				
				EXEC @return_value = [dbo].[spDOC_SetTempInvDoc]  
				@CostCenterID = @RcptCCID,  
				@DocID = 0,  
				@DocPrefix = @Prefix,  
				@DocNumber = 1,  
				@DocDate = @VacancyDate,  
				@DueDate = NULL,  
				@BillNo = @SNO,  
				@InvDocXML =@DocXml,  
				@BillWiseXML = N'',  
				@NotesXML = N'',  
				@AttachmentsXML = N'',  
				@ActivityXML  = N'', 
				@IsImport = 0,  
				@LocationID = @LocationID,  
				@DivisionID = @DivisionID ,  
				@WID = 0,  
				@RoleID = @RoleID,  
				@DocAddress = N'',  
				@RefCCID = 95,
				@RefNodeid  = @ContractID,
				@CompanyGUID = @CompanyGUID,  
				@UserName = @UserName,  
				@UserID = @UserID,  
				@LangID = @LangID  
				
				INSERT INTO  [REN_ContractDocMapping]  
					([ContractID],[Type],[Sno],DocID,COSTCENTERID,IsAccDoc,DocType,ContractCCID)  			        
					values(@ContractID,101,@SNO+1,@return_value,@RcptCCID,0,0,95)
			END
			ELSE
			BEGIN
				  EXEC @return_value = [dbo].[spDOC_SetTempAccDocument]      
				   @CostCenterID = @RcptCCID,      
				   @DocID = 0,      
				   @DocPrefix = @Prefix,      
				   @DocNumber =1,      
				   @DocDate = @VacancyDate,      
				   @DueDate = NULL,      
				   @BillNo = @SNO,      
				   @InvDocXML = @DocXml,      
				   @NotesXML = N'',      
				   @AttachmentsXML = N'',      
				   @ActivityXML  = N'',     
				   @IsImport = 0,      		   
					@LocationID = @LocationID,
					@DivisionID = @DivisionID ,     
				   @WID = 0,      
				   @RoleID = @RoleID,      
				   @RefCCID = 95,    
				   @RefNodeid = @ContractID ,    
				   @CompanyGUID = @CompanyGUID,      
				   @UserName = @UserName,      
				   @UserID = @UserID,      
				   @LangID = @LangID    
				   
					INSERT INTO  [REN_ContractDocMapping]  
					([ContractID],[Type],[Sno],DocID,COSTCENTERID,IsAccDoc,DocType,ContractCCID)  			        
					values(@ContractID,101,@SNO+1,@return_value,@RcptCCID,1,0,95)
		     END     
			

		 
	END
	
	IF(@PenaltyXML is not null and @PenaltyXML<>'')  
	BEGIN 
			select @RcptCCID=CONVERT(int,Value) from COM_CostCenterPreferences WITH(nolock)  
			where CostCenterID=95 and Name='TerminatePenaltyJV' 
			 
			set @Prefix=''
			EXEC [sp_GetDocPrefix] @DocXml,@VacancyDate,@RcptCCID,@Prefix   output

			if exists(select * from adm_documenttypes WITH(NOLOCK) where costcenterid= @RcptCCID and isinventory=1)
			BEGIN
				set @PenaltyXML=Replace(@PenaltyXML,'<RowHead/>','')
				set @PenaltyXML=Replace(@PenaltyXML,'</DocumentXML>','')
				set @PenaltyXML=Replace(@PenaltyXML,'<DocumentXML>','')
				
				EXEC @return_value = [dbo].[spDOC_SetTempInvDoc]  
				@CostCenterID = @RcptCCID,  
				@DocID = 0,  
				@DocPrefix = @Prefix,  
				@DocNumber = 1,  
				@DocDate = @VacancyDate,  
				@DueDate = NULL,  
				@BillNo = @SNO,  
				@InvDocXML =@PenaltyXML,  
				@BillWiseXML = N'',  
				@NotesXML = N'',  
				@AttachmentsXML = N'',  
				@ActivityXML  = N'', 
				@IsImport = 0,  
				@LocationID = @LocationID,  
				@DivisionID = @DivisionID ,  
				@WID = 0,  
				@RoleID = @RoleID,  
				@DocAddress = N'',  
				@RefCCID = 95,
				@RefNodeid  = @ContractID,
				@CompanyGUID = @CompanyGUID,  
				@UserName = @UserName,  
				@UserID = @UserID,  
				@LangID = @LangID  
				
				INSERT INTO  [REN_ContractDocMapping]  
				   ([ContractID],[Type]  ,[Sno]  ,DocID  ,CostcenterID  
				   ,IsAccDoc,DocType  , ContractCCID)values
				   (@ContractID,101,0,@return_value,@RcptCCID,0,0 , 95    )
				
			END
			ELSE
			BEGIN
				EXEC	@return_value = [dbo].[spDOC_SetTempAccDocument]
				@CostCenterID = @RcptCCID,
				@DocID = 0,
				@DocPrefix = @Prefix,
				@DocNumber =1,
				@DocDate = @VacancyDate, --@TerminationDate,
				@DueDate = NULL,
				@BillNo = @SNO,
				@InvDocXML = @PenaltyXML,
				@NotesXML = N'',
				@AttachmentsXML = N'',
				@ActivityXML  = N'', 
				@IsImport = 0,
				@LocationID = @LocationID,
				@DivisionID = @DivisionID,
				@WID = 0,
				@RoleID = @RoleID,
				@RefCCID = 95,
				@RefNodeid = @ContractID ,
				@CompanyGUID = @CompanyGUID,
				@UserName = @UserName,
				@UserID = @UserID,
				@LangID = @LangID
				
				INSERT INTO  [REN_ContractDocMapping]  
				   ([ContractID],[Type]  ,[Sno]  ,DocID  ,CostcenterID  
				   ,IsAccDoc,DocType  , ContractCCID)values
				   (@ContractID,101,0,@return_value,@RcptCCID,1,0 , 95    )
	  
			END
			
	
	  END
	  
	  IF(@RemaingPaymentXML is not null and @RemaingPaymentXML<>'')  
	  BEGIN 
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
				where CostCenterID=95 and Name='TerminatePenaltyJV' 
			 
			Set @DocXml = convert(nvarchar(max), @AA)  

			EXEC	@return_value = [dbo].[spDOC_SetTempAccDocument]
				@CostCenterID = @RcptCCID,
				@DocID = 0,
				@DocPrefix = N'',
				@DocNumber =1,
				@DocDate = @VacancyDate,
				@DueDate = NULL,
				@BillNo = @SNO,
				@InvDocXML = @DocXml,
				@NotesXML = N'',
				@AttachmentsXML = N'',
				@ActivityXML  = N'', 
				@IsImport = 0,
				@LocationID = @LocationID,
				@DivisionID = @DivisionID,
				@WID = 0,
				@RoleID = @RoleID,
				@RefCCID = 95,
				@RefNodeid = @ContractID ,
				@CompanyGUID = @CompanyGUID,
				@UserName = @UserName,
				@UserID = @UserID,
				@LangID = @LangID
	  
	  
			INSERT INTO  [REN_ContractDocMapping]  
		   ([ContractID],[Type]  ,[Sno]  ,DocID  ,CostcenterID  
		   ,IsAccDoc,DocType  , ContractCCID)values
		   (@ContractID,101,0,@return_value,@RcptCCID,1,0 , 95)
	  END
	
		IF( @Dimesion IS NOT NULL AND  @Dimesion  > 50000 and @CCNODEID IS NOT NULL AND  @CCNODEID  > 0)  
		BEGIN  
			set @DocXml=' UPDATE COM_DOCCCDATA    
			SET DCCCNID'+convert(nvarchar,(@Dimesion-50000))+'='+CONVERT(NVARCHAR,@CCNODEID)+'   
			WHERE ACCDOCDETAILSID IN (SELECT ACCDOCDETAILSID  FROM ACC_DOCDETAILS WITH(nolock) WHERE REFCCID = 95 AND REFNODEID = '+convert(nvarchar,@ContractID) + ' and DOCID > 0)  
			OR INVDOCDETAILSID IN (SELECT INVDOCDETAILSID  FROM INV_DOCDETAILS WITH(nolock) WHERE REFCCID = 95 AND REFNODEID =  '+convert(nvarchar,@ContractID)+ ' and DOCID > 0)'     
			 
			EXEC (@DocXml) 
			
			Exec [spDOC_SetLinkDimension]
					@InvDocDetailsID=@ContractID, 
					@Costcenterid=95,         
					@DimCCID=@Dimesion,
					@DimNodeID=@CCNODEID,
					@UserID=@UserID,    
					@LangID=@LangID    
		END 
		
		if(@TermPart<>'')
		BEGIN
			set @XML=@TermPart
			
			delete from [REN_TerminationParticulars]
			where contractID=@ContractID
			
			insert into [REN_TerminationParticulars]
			SELECT   @ContractID,X.value ('@CCNodeID', 'BIGINT' )
			,X.value ('@CreditAccID', 'BIGINT' ),X.value ('@DebitAccID', 'BIGINT' ),X.value ('@Amount', 'float' )
			,X.value ('@VatPer', 'float' ),X.value ('@VatAmount', 'float' )
			from @XML.nodes('XML/Row') as Data(X) 
			
		END
 	
COMMIT TRANSACTION     
   
 SELECT ErrorMessage,ErrorNumber FROM COM_ErrorMessages WITH(nolock)   
WHERE ErrorNumber=100 AND LanguageID=@LangID  
SET NOCOUNT OFF;   
   
RETURN @ContractID      
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

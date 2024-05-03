﻿USE PACT2C222
GO
SET ANSI_NULLS, QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spREN_TerminateContract]
	@ContractID [bigint],
	@TerminationDate [datetime],
	@StatusID [int] = 0,
	@Reason [bigint],
	@PaymentXML [nvarchar](max) = NULL,
	@PDPaymentXML [nvarchar](max) = NULL,
	@ComPayXML [nvarchar](max) = NULL,
	@SRTXML [nvarchar](max) = NULL,
	@RentPayXML [nvarchar](max) = NULL,
	@PenaltyXML [nvarchar](max) = NULL,
	@RemaingPaymentXML [nvarchar](max) = NULL,
	@RentRecID [bigint] = 0,
	@IncomeID [bigint] = 0,
	@WONO [nvarchar](500),
	@SRTAmount [float] = 0,
	@RefundAmt [float] = 0,
	@PDCRefund [float] = 0,
	@Penalty [float] = 0,
	@Amt [float] = 0,
	@TermPayMode [int] = 1,
	@TermChequeNo [nvarchar](max) = NULL,
	@TermChequeDate [datetime],
	@TermRemarks [nvarchar](max) = NULL,
	@LocationID [bigint],
	@DivisionID [bigint],
	@RoleID [bigint],
	@SCostCenterID [bigint],
	@TermPart [nvarchar](max) = NULL,
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
  
	DECLARE @Dt float,@XML xml,@TempGuid nvarchar(50),@HasAccess bit,@IsDuplicateNameAllowed bit,@IsAccountCodeAutoGen bit    
	DECLARE @PickAcc nvarchar(50) ,@DDXML  nvarchar(max),@DDValue nvarchar(max),@penAccID BIGINT
	declare @BillWiseXMl Nvarchar(max),@SNO BIGINT ,@CCNODEID BIGINT,@Dimesion int,@DateXML XML,@PendingVchrs nvarchar(max)
	DECLARE @AccountType xml, @AccValue nvarchar(100) , @Documents xml , @DocIDValue nvarchar(100)
	declare @tempxml xml,@tempAmt Float,@Prefix nvarchar(200)
	DECLARE	@return_value int
	DECLARE @DELETEDOCID BIGINT , @DELETECCID BIGINT , @DELETEISACC BIT   
	DECLARE @DELDocPrefix NVARCHAR(50), @DELDocNumber NVARCHAR(500)
	
	declare @tabvchrs table(vno nvarchar(200))
	  
	SET @Dt=convert(float,getdate())--Setting Current Date  

	DECLARE @AUDITSTATUS NVARCHAR(50)  
	SET @AUDITSTATUS= 'TERMINATE'
	
	if exists(select * from REN_Contract where  parentContractID=@ContractID and statusid<>428)
		RAISERROR('Terminate child contracts',16,1)
	
	if exists(select * from REN_Contract where  parentContractID=@ContractID and statusid=428
	and TerminationDate>CONVERT(FLOAT , @TerminationDate))
		RAISERROR('Termination date is less than child contracts termination',16,1)
	 
	UPDATE REN_CONTRACT
	SET STATUSID = @StatusID ,TerminationDate = CONVERT(FLOAT , @TerminationDate) , Reason = @Reason,SRTAmount=@SRTAmount,RefundAmt=@RefundAmt,
	PDCRefund=@PDCRefund,Penalty=@Penalty,Amt=@Amt,TermPayMode=@TermPayMode,TermChequeNo=@TermChequeNo,TermChequeDate= CONVERT(FLOAT , @TermChequeDate),
	TermRemarks=@TermRemarks,modifieddate=@Dt,modifiedby=@UserName
	WHERE ContractID = @ContractID or RefContractID=@ContractID
	
	DECLARE @AuditTrial BIT    
	SET @AuditTrial=0    
	SELECT @AuditTrial= CONVERT(BIT,VALUE)  FROM [COM_COSTCENTERPreferences]  WITH(NOLOCK)  
	WHERE CostCenterID=@SCostCenterID  AND NAME='AllowAudit' 

	IF (@AuditTrial=1 AND (@SCostCenterID=95 OR @SCostCenterID=104))  
	BEGIN  
		INSERT INTO  [REN_Contract_History]
				([ContractID]
				,[ContractPrefix]
				,[ContractDate]
				,[ContractNumber]
				,[StatusID]
				,[PropertyID]
				,[UnitID]
				,[TenantID]
				,[RentAccID]
				,[IncomeAccID]
				,[Purpose]
				,[StartDate]
				,[EndDate]
				,[TotalAmount]
				,[NonRecurAmount]
				,[RecurAmount]
				,[Depth]
				,[ParentID]
				,[lft]
				,[rgt]
				,[IsGroup]
				,[CompanyGUID]
				,[GUID]
				,[CreatedBy]
				,[CreatedDate]
				,[ModifiedBy]
				,[ModifiedDate]
				,[TerminationDate]
				,[Reason]
				,[LocationID]
				,[DivisionID]
				,[CurrencyID]
				,[TermsConditions]
				,[SalesmanID]
				,[AccountantID]
				,[LandlordID]
				,[Narration]
				,[SNO]
				,[CostCenterID]
				,[HistoryStatus]
				,[SRTAmount]
				,[RefundAmt]
				,[PDCRefund]
				,[Penalty]
				,[Amt]
				,TermPayMode
				,TermChequeNo
				,TermChequeDate
				,TermRemarks)
			SELECT [ContractID]
				,[ContractPrefix]
				,[ContractDate]
				,[ContractNumber]
				,[StatusID]
				,[PropertyID]
				,[UnitID]
				,[TenantID]
				,[RentAccID]
				,[IncomeAccID]
				,[Purpose]
				,[StartDate]
				,[EndDate]
				,[TotalAmount]
				,[NonRecurAmount]
				,[RecurAmount]
				,[Depth]
				,[ParentID]
				,[lft]
				,[rgt]
				,[IsGroup]
				,[CompanyGUID]
				,[GUID]
				,[CreatedBy]
				,[CreatedDate]
				,@UserName
				,@Dt
				,[TerminationDate]
				,[Reason]
				,[LocationID]
				,[DivisionID]
				,[CurrencyID]
				,[TermsConditions]
				,[SalesmanID]
				,[AccountantID]
				,[LandlordID]
				,[Narration]
				,[SNO]
				,[CostCenterID] 
				,@AUDITSTATUS 
				,[SRTAmount]
				,[RefundAmt]
				,[PDCRefund]
				,[Penalty]
				,[Amt]
				,TermPayMode
				,TermChequeNo
				,TermChequeDate
				,TermRemarks
				FROM [REN_Contract]  WITH(NOLOCK)
				WHERE [ContractID] = @ContractID
  
  
		INSERT INTO  [REN_ContractParticulars_History]
				([NodeID]
				,[ContractID]
				,[CCID]
				,[CCHistoryID]
				,[CreditAccID]
				,[ChequeNo]
				,[ChequeDate]
				,[PayeeBank]
				,[DebitAccID]
				,[Amount]
				,[CompanyGUID]
				,[GUID]
				,[CreatedBy]
				,[CreatedDate]
				,[ModifiedBy]
				,[ModifiedDate]
				,[Sno]
				,[Narration]
				,[IsRecurr])
		SELECT [NodeID]
				,[ContractID]
				,[CCID]
				,[CCNodeID]
				,[CreditAccID]
				,[ChequeNo]
				,[ChequeDate]
				,[PayeeBank]
				,[DebitAccID]
				,[Amount]
				,[CompanyGUID]
				,[GUID]
				,[CreatedBy]
				,[CreatedDate]
				,@UserName
				,@Dt
				,[Sno]
				,[Narration]
				,[IsRecurr]  
				FROM  [REN_ContractParticulars] WITH(NOLOCK)
				WHERE  [ContractID] = @ContractID
  
  
		INSERT INTO [REN_ContractPayTerms_History]
				([NodeID]
				,[ContractID]
				,[ChequeNo]
				,[ChequeDate]
				,[CustomerBank]
				,[DebitAccID]
				,[Amount]
				,[CompanyGUID]
				,[GUID]
				,[CreatedBy]
				,[CreatedDate]
				,[ModifiedBy]
				,[ModifiedDate]
				,[Sno]
				,[Narration])
		SELECT [NodeID]
				,[ContractID]
				,[ChequeNo]
				,[ChequeDate]
				,[CustomerBank]
				,[DebitAccID]
				,[Amount]
				,[CompanyGUID]
				,[GUID]
				,[CreatedBy]
				,[CreatedDate]
				,@UserName
				,@Dt
				,[Sno]
				,[Narration]
				FROM  [REN_ContractPayTerms] WITH(NOLOCK)
				WHERE  [ContractID]  = @ContractID
  
		INSERT INTO  [REN_ContractExtended_History]
				([NodeID]
				,[CreatedBy]
				,[CreatedDate]
				,[ModifiedBy]
				,[ModifiedDate]
				,[alpha1]
				,[alpha2]
				,[alpha3]
				,[alpha4]
				,[alpha5]
				,[alpha6]
				,[alpha7]
				,[alpha8]
				,[alpha9]
				,[alpha10]
				,[alpha11]
				,[alpha12]
				,[alpha13]
				,[alpha14]
				,[alpha15]
				,[alpha16]
				,[alpha17]
				,[alpha18]
				,[alpha19]
				,[alpha20]
				,[alpha21]
				,[alpha22]
				,[alpha23]
				,[alpha24]
				,[alpha25]
				,[alpha26]
				,[alpha27]
				,[alpha28]
				,[alpha29]
				,[alpha30]
				,[alpha31]
				,[alpha32]
				,[alpha33]
				,[alpha34]
				,[alpha35]
				,[alpha36]
				,[alpha37]
				,[alpha38]
				,[alpha39]
				,[alpha40]
				,[alpha41]
				,[alpha42]
				,[alpha43]
				,[alpha44]
				,[alpha45]
				,[alpha46]
				,[alpha47]
				,[alpha48]
				,[alpha49]
				,[alpha50]
				,[HistoryStatus])
		SELECT [NodeID]
				,[CreatedBy]
				,[CreatedDate]
				,[ModifiedBy]
				,[ModifiedDate]
				,[alpha1]
				,[alpha2]
				,[alpha3]
				,[alpha4]
				,[alpha5]
				,[alpha6]
				,[alpha7]
				,[alpha8]
				,[alpha9]
				,[alpha10]
				,[alpha11]
				,[alpha12]
				,[alpha13]
				,[alpha14]
				,[alpha15]
				,[alpha16]
				,[alpha17]
				,[alpha18]
				,[alpha19]
				,[alpha20]
				,[alpha21]
				,[alpha22]
				,[alpha23]
				,[alpha24]
				,[alpha25]
				,[alpha26]
				,[alpha27]
				,[alpha28]
				,[alpha29]
				,[alpha30]
				,[alpha31]
				,[alpha32]
				,[alpha33]
				,[alpha34]
				,[alpha35]
				,[alpha36]
				,[alpha37]
				,[alpha38]
				,[alpha39]
				,[alpha40]
				,[alpha41]
				,[alpha42]
				,[alpha43]
				,[alpha44]
				,[alpha45]
				,[alpha46]
				,[alpha47]
				,[alpha48]
				,[alpha49]
				,[alpha50]
				,@AUDITSTATUS 
				FROM  [REN_ContractExtended] WITH(NOLOCK)
				WHERE  [NodeID]  = @ContractID
	END     

	update b
	set statusid=3
	from REN_ContractDocMapping DM WITH(NOLOCK)
	join COM_CCSchedules a WITH(NOLOCK) on DM.CostCenterID=a.CostCenterID
	join COM_SchEvents b WITH(NOLOCK) on a.ScheduleID=b.ScheduleID
	where a.NodeID=DM.DocID and DM.ContractID = @ContractID and b.statusid=1
	and (DM.TYPE = 1 OR DM.TYPE IS NULL) and (DM.isaccdoc = 0 OR DM.IsAccDoc  IS NULL )
		 

    --------------------------  POSTINGS --------------------------
    
    
	select @SNO=ISNULL(SNO,0),@CCNODEID = CCNODEID,@Dimesion = CCID  from [REN_Contract] with(NOLOCK) 
	WHERE   CONTRACTID = @ContractID and RefContractID=0
	   
	Declare @RcptCCID BIGint,@ComRcptCCID bigint,@SIVCCID bigint,@RentRcptCCID bigint, @PrefValue nvarchar(200)
	Declare @BnkRcpt BIGINT  , @PDRcpt BIGINT , @CommRcpt bigint , @SalesInv BIGINT, @RentRcpt BIGINT
	DECLARE @CNT INT ,  @ICNT INT
	DECLARE @AA XML 
	DECLARE @DocXml nvarchar(max) 
  
	IF( @SCostCenterID  = 95)
	BEGIN  
	 	
	 	if(@SRTXML is not null and @SRTXML<>'')
		BEGIN
			select @RcptCCID=CONVERT(int,Value) from COM_CostCenterPreferences WITH(nolock)
			where CostCenterID=95 and Name='ContractSalesReturn'

			SET @XML = @SRTXML
			CREATE TABLE #tblListSIVTemp(ID int identity(1,1),TRANSXML NVARCHAR(MAX) ,Documents NVARCHAR(200))        
			INSERT INTO #tblListSIVTemp    
			SELECT  CONVERT(NVARCHAR(MAX),  X.query('DocumentXML'))   ,  CONVERT(NVARCHAR(200),X.query('Documents'))                 
			from @XML.nodes('/SIV//ROWS') as Data(X)    

			SELECT @CNT = COUNT(ID) FROM #tblListSIVTemp  

			SET @ICNT = 0  
			WHILE(@ICNT < @CNT)  
			BEGIN  
				SET @ICNT =@ICNT+1  
				SELECT @AA = TRANSXML , @Documents = Documents    FROM #tblListSIVTemp WHERE  ID = @ICNT  
				Set @DocXml = convert(nvarchar(max), @AA)  
				SELECT   @DocIDValue=0
			 
				if exists(SELECT IsBillwise FROM ACC_Accounts WITH(NOLOCK) WHERE AccountID=@RentRecID and IsBillwise=1)
				begin
					IF EXISTS(select Value from ADM_GLOBALPREFERENCES WITH(NOLOCK) where NAME  = 'On')
					BEGIN
						set @tempxml=@DocXml
												
						select @tempAmt=sum(X.value('@Amount',' float'))
						from @tempxml.nodes('/DocumentXML/Row/AccountsXML/Accounts') as Data(X)
						set @tempAmt=@tempAmt*-1
				        
						set @BillWiseXMl='<BillWise> <Row DocSeqNo="1" AccountID="'+convert(nvarchar,@RentRecID)+'" AmountFC="'+CONVERT(nvarchar,@tempAmt)+'" 
						AdjAmount="'+CONVERT(nvarchar,@tempAmt)+'" AdjCurrID="1" AdjExchRT="1" IsNewReference="1" Narration="" IsDocPDC="0" ></Row></BillWise>'
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
				EXEC [sp_GetDocPrefix] @DocXml,@TerminationDate,@RcptCCID,@Prefix   output
				
				set @DocXml=Replace(@DocXml,'<RowHead/>','')
				set @DocXml=Replace(@DocXml,'</DocumentXML>','')
				set @DocXml=Replace(@DocXml,'<DocumentXML>','')
				
				EXEC	@return_value = [dbo].[spDOC_SetTempInvDoc]
						@CostCenterID = @RcptCCID,
						@DocID = 0,
						@DocPrefix = @Prefix,
						@DocNumber = 1,
						@DocDate = @TerminationDate,
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
						SET @SalesInv  = @return_value  

				set @XML = @AA  
				
				INSERT INTO  [REN_ContractDocMapping]([ContractID],[Type],[Sno],DocID,COSTCENTERID,IsAccDoc,DocType,ContractCCID) 
				values(@ContractID,-1,0,@SalesInv,@RcptCCID,0,0,95)
			END
		END 
		if(@PaymentXML is not null and @PaymentXML<>'')
		BEGIN
		
			SET @XML = @PaymentXML
			declare  @TermPaymentXML table (ID int identity(1,1),TRANSXML NVARCHAR(MAX)  , AccountType NVARCHAR(100) ,Documents NVARCHAR(200) )      
			INSERT INTO @TermPaymentXML    
			SELECT  CONVERT(NVARCHAR(MAX),  X.query('DocumentXML'))   ,  CONVERT(NVARCHAR(MAX),  X.query('AccountType')), CONVERT(NVARCHAR(200), X.query('Documents') )             
			from @XML.nodes('/ReceiptXML/ROWS') as Data(X)  
			select @RcptCCID=CONVERT(int,Value) from COM_CostCenterPreferences WITH(nolock)
			where CostCenterID=95 and Name='ContractPayment'

			SELECT @AA = TRANSXML , @AccountType = AccountType , @Documents = Documents  FROM @TermPaymentXML WHERE  ID = 1  

			SELECT   @AccValue =  X.value ('@DD', 'NVARCHAR(100)' )        
			from @AccountType.nodes('/AccountType') as Data(X) 

			set @DocIDValue=0
			 
			select @DocIDValue=DOCID from  [REN_ContractDocMapping] WITH(nolock)
			where contractid=@ContractID and Doctype =1 AND ContractCCID = 95

			IF(@AccValue = 'BANK')
			BEGIN
				select @RcptCCID=CONVERT(int,Value) from COM_CostCenterPreferences WITH(nolock)  
				where CostCenterID=95 and Name='ContractPDP'  
			END
			ELSE  IF(@AccValue = 'CASH')
			BEGIN  
				SET @RcptCCID=40023
			END
			ELSE  IF(@AccValue = 'JV')
			BEGIN
				SET @RcptCCID=40017
			END

			SET @DocXml = convert(nvarchar(max), @AA)  
			
			SET @DocIDValue = ISNULL(@DocIDValue,0)
			if(@DocIDValue = '')
				set @DocIDValue=0

			set @Prefix=''
			EXEC [sp_GetDocPrefix] @DocXml,@TerminationDate,@RcptCCID,@Prefix   output
 
			EXEC	@return_value = [dbo].[spDOC_SetTempAccDocument]
			@CostCenterID = @RcptCCID,
			@DocID = 0,
			@DocPrefix = @Prefix,
			@DocNumber =1,
			@DocDate = @TerminationDate,
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
			
			SET @BnkRcpt  = @return_value  
			select 'asdf'
			INSERT INTO  [REN_ContractDocMapping]([ContractID],[Type],[Sno],DocID,CostcenterID,IsAccDoc,DocType,ContractCCID)  
			VALUES (@ContractID,-2,0,@BnkRcpt,@RcptCCID,1,0,95)  
		END
   
		if(@PDPaymentXML is not null and @PDPaymentXML<>'')
		BEGIN  

			DECLARE @MPSNO NVARCHAR(MAX),@CancelDOCID bigint  

			SET @XML =   @PDPaymentXML   
			CREATE TABLE #tblListPDR(ID int identity(1,1),TRANSXML NVARCHAR(MAX) , DateXML NVARCHAR(MAX), AccountType NVARCHAR(100) ,Documents NVARCHAR(200) )      
			INSERT INTO #tblListPDR    
			SELECT  CONVERT(NVARCHAR(MAX),  X.query('DocumentXML')) ,  CONVERT(NVARCHAR(MAX),  X.query('ChequeDocDate')) ,  CONVERT(NVARCHAR(MAX),  X.query('AccountType')) ,  CONVERT(NVARCHAR(200),  X.query('Documents'))              
			from @XML.nodes('/PDR/ROWS') as Data(X)    

			SELECT @CNT = COUNT(ID) FROM #tblListPDR  

			SET @ICNT = 0  
			WHILE(@ICNT < @CNT)  
			BEGIN  
				SET @ICNT =@ICNT+1  

				SELECT @AA = TRANSXML , @DateXML = DateXML , @AccountType = AccountType , @Documents = Documents  FROM #tblListPDR WHERE  ID = @ICNT  
				set @CancelDOCID=0
				SELECT   @AccValue =  X.value ('@DD', 'NVARCHAR(100)'),@CancelDOCID= X.value('@CancelDOCID', 'BIGINT')        
				from @AccountType.nodes('/AccountType') as Data(X)  

				set @DocIDValue=0
				
				IF(@AccValue = 'BANK')
				BEGIN
					select @RcptCCID=CONVERT(int,Value) from COM_CostCenterPreferences WITH(nolock)  
					where CostCenterID=95 and Name='ContractPDP'  
					iF(@CancelDOCID is not null and @CancelDOCID>0)
					BEGIN
						 
						SELECT @DELDocPrefix = DocPrefix,@DELDocNumber=  DocNumber , @DELETECCID = COSTCENTERID FROM ACC_DocDetails  WITH(nolock)  
						where DocID=@CancelDOCID
							    
						 EXEC @return_value = [dbo].[spDOC_SuspendAccDocument]  
						 @CostCenterID = @DELETECCID, 
						 @DocID=@CancelDOCID,
						 @DocPrefix = @DELDocPrefix,  
						 @DocNumber = @DELDocNumber, 
						 @Remarks=N'', 
						 @UserID = @UserID,  
						 @UserName = @UserName,
						 @RoleID=@RoleID,
						 @LangID = @LangID  

						continue;
					END	
				END
				ELSE  IF(@AccValue = 'CASH')
				BEGIN 
					SET @RcptCCID=40023
				END
				ELSE  IF(@AccValue = 'JV')
				BEGIN 
					SET @RcptCCID=40017
				END

				Set @DocXml = convert(nvarchar(max), @AA)  

				set @Prefix=''
				EXEC [sp_GetDocPrefix] @DocXml,@TerminationDate,@RcptCCID,@Prefix   output

				EXEC	@return_value = [dbo].[spDOC_SetTempAccDocument]
				@CostCenterID = @RcptCCID,
				@DocID = 0,
				@DocPrefix = @Prefix,
				@DocNumber =1,
				@DocDate = @TerminationDate,
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
				 
				SET @PDRcpt  = @return_value  

				set @XML = @AA  

				INSERT INTO [REN_ContractDocMapping]([ContractID],[Type],[Sno],DocID,CostcenterID,IsAccDoc,DocType,ContractCCID)  
				values(@ContractID,-2,0,@PDRcpt,@RcptCCID ,1,0,95)			 
			END  
		END 
 
   
		if(@ComPayXML is not null and @ComPayXML<>'')
		BEGIN
			select @RcptCCID=CONVERT(int,Value) from COM_CostCenterPreferences WITH(nolock)
			where CostCenterID=95 and Name='ContractPayment'

			SET @XML =   @ComPayXML 
				
			CREATE TABLE #tblListCOM(ID int identity(1,1),TRANSXML NVARCHAR(MAX) , DateXML NVARCHAR(MAX) , AccountType NVARCHAR(100),Documents NVARCHAR(200) )        
			INSERT INTO #tblListCOM    
			SELECT  CONVERT(NVARCHAR(MAX),  X.query('DocumentXML')) ,  CONVERT(NVARCHAR(MAX),  X.query('ChequeDocDate'))  ,  CONVERT(NVARCHAR(MAX),  X.query('AccountType'))  ,  CONVERT(NVARCHAR(200),  X.query('Documents'))                
			from @XML.nodes('/PARTICULARS//ROWS') as Data(X) 

			SELECT  * FROM #tblListCOM
			SELECT @CNT = COUNT(ID) FROM #tblListCOM

			SET @ICNT = 0
			 
			WHILE(@ICNT < @CNT)
			BEGIN
				SET @ICNT =@ICNT+1

				SELECT @AA = TRANSXML , @DateXML = DateXML, @AccountType = AccountType  , @Documents = Documents   FROM #tblListCOM WHERE  ID = @ICNT  

				Set @DocXml = convert(nvarchar(max), @AA)

				SET @DocIDValue = ISNULL(@DocIDValue,0)

				SELECT   @AccValue =  X.value ('@DD', 'NVARCHAR(100)' )        
				from @AccountType.nodes('/AccountType') as Data(X)  

				IF(@AccValue = 'BANK')
				BEGIN
					declare @prefVal nvarchar(50)
					set @prefVal=''
					select @prefVal=Value from COM_CostCenterPreferences WITH(nolock)  
					where CostCenterID=95 and Name='ParticularsPDC'  
					if(@prefVal <>'' and @prefVal='True')
					begin
						select @RcptCCID=CONVERT(int,Value) from COM_CostCenterPreferences WITH(nolock)  
						where CostCenterID=95 and Name='ContractPDP'  
					end
					else
					begin
						select @RcptCCID=CONVERT(int,Value) from COM_CostCenterPreferences WITH(nolock)  
						where CostCenterID=95 and Name='ContractPayment'  
					end	
				END
				ELSE 
				BEGIN
					select @RcptCCID=CONVERT(int,Value) from COM_CostCenterPreferences WITH(nolock)  
					where CostCenterID=95 and Name='ContractPayment'  
				END
				
				set @Prefix=''
				EXEC [sp_GetDocPrefix] @DocXml,@TerminationDate,@RcptCCID,@Prefix   output

				EXEC	@return_value = [dbo].[spDOC_SetTempAccDocument]
				@CostCenterID = @RcptCCID,
				@DocID = 0,
				@DocPrefix = @Prefix,
				@DocNumber =1,
				@DocDate = @TerminationDate,
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

				INSERT INTO  [REN_ContractDocMapping]([ContractID],[Type],[Sno],DocID,CostcenterID,IsAccDoc,DocType,ContractCCID)  
				values( @ContractID,-1,0,@return_value,@RcptCCID,1,0,95 )   
			END
		END
 
		IF(@RentPayXML is not null and @RentPayXML<>'')
		BEGIN

			select @RcptCCID=CONVERT(int,Value) from COM_CostCenterPreferences WITH(nolock)  
			where CostCenterID=95 and Name='ContractRentPay'  
			SET @XML =   @RentPayXML   

			declare  @tblExistingRcs TABLE (ID int identity(1,1),DOCID bigint)       
			insert into @tblExistingRcs 
			select DOCID from  [REN_ContractDocMapping] WITH(NOLOCK)
			where contractid=@ContractID and DOCTYPE =5 AND ContractCCID = 95
			declare @totalPreviousRcts bigint
			select @totalPreviousRcts=COUNT(id) from @tblExistingRcs 

			CREATE TABLE #tblList(ID int identity(1,1),TRANSXML NVARCHAR(MAX) , DateXML NVARCHAR(MAX))       
			INSERT INTO #tblList    
			SELECT  CONVERT(NVARCHAR(MAX),  X.query('DocumentXML') ) ,  CONVERT(NVARCHAR(MAX),  X.query('ChequeDocDate'))      
			from @XML.nodes('/RENTRCT/ROWS') as Data(X)    

			SELECT @CNT = COUNT(ID) FROM #tblList  
			SET @ICNT = 0  
			WHILE(@ICNT < @CNT)  
			BEGIN  
				SET @ICNT =@ICNT+1  

				SELECT @AA = TRANSXML , @DateXML = DateXML  FROM #tblList WHERE  ID = @ICNT  

				if( @totalPreviousRcts>=@ICNT)
				begin
					SELECT @DocIDValue = DOCID   FROM @tblExistingRcs WHERE  ID = @ICNT  
				end
				else
				begin
					SELECT @DocIDValue=0
				end
				Set @DDXML = convert(nvarchar(max), @DateXML)  
				 
				SELECT   @DDValue =  X.value ('@DD', 'NVARCHAR(MAX)' )        
				from @DateXML.nodes('/ChequeDocDate') as Data(X)  
		     
				Set @DocXml = convert(nvarchar(max), @AA)  
				
				set @Prefix=''
				EXEC [sp_GetDocPrefix] @DocXml,@TerminationDate,@RcptCCID,@Prefix   output

				EXEC	@return_value = [dbo].[spDOC_SetTempAccDocument]
					@CostCenterID = @RcptCCID,
					@DocID = 0,
					@DocPrefix = @Prefix,
					@DocNumber =1,
					@DocDate = @DDValue, --@TerminationDate,
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

				INSERT INTO  [REN_ContractDocMapping]([ContractID],[Type],[Sno],DocID,CostcenterID,IsAccDoc,DocType,ContractCCID)  
				values( @ContractID,-5,0,@return_value,@RcptCCID,1,0,95)
			END
		END 
		
		IF(@PenaltyXML is not null and @PenaltyXML<>'')  
		BEGIN 
			select @RcptCCID=CONVERT(int,Value) from COM_CostCenterPreferences WITH(nolock)  
			where CostCenterID=95 and Name='TerminatePenaltyJV' 
			
			set @Prefix=''
			EXEC [sp_GetDocPrefix] @DocXml,@TerminationDate,@RcptCCID,@Prefix   output

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
				@DocDate = @TerminationDate,  
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
				
				INSERT INTO [REN_ContractDocMapping]([ContractID],[Type],[Sno],DocID,CostcenterID,IsAccDoc,DocType,ContractCCID)
				values(@ContractID,-3,0,@return_value,@RcptCCID,0,0,95)
				
			END
			ELSE
			BEGIN
				EXEC	@return_value = [dbo].[spDOC_SetTempAccDocument]
					@CostCenterID = @RcptCCID,
					@DocID = 0,
					@DocPrefix =@Prefix,
					@DocNumber =1,
					@DocDate = @TerminationDate,
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
					
					INSERT INTO [REN_ContractDocMapping]([ContractID],[Type],[Sno],DocID,CostcenterID,IsAccDoc,DocType,ContractCCID)
					values(@ContractID,-3,0,@return_value,@RcptCCID,1,0,95)

			END
		END
	  
		IF(@RemaingPaymentXML is not null and @RemaingPaymentXML<>'')  
		BEGIN 
			set @XML=@RemaingPaymentXML
			
			SELECT  @AA=CONVERT(NVARCHAR(MAX),  X.query('DocumentXML'))   ,@AccountType= CONVERT(NVARCHAR(MAX),  X.query('AccountType'))
			from @XML.nodes('/ReceiptXML/ROWS') as Data(X)  
			
			SELECT   @AccValue =  X.value ('@DD', 'NVARCHAR(100)' )        
			from @AccountType.nodes('/AccountType') as Data(X) 

			if(@AccValue='BANK')
				select @RcptCCID=CONVERT(int,Value) from COM_CostCenterPreferences WITH(nolock)  
				where CostCenterID=95 and Name='ContractPDP' 
			ELSE if(@AccValue='CASH')
				select @RcptCCID=CONVERT(int,Value) from COM_CostCenterPreferences WITH(nolock)
				where CostCenterID=95 and Name='ContractPayment'
			ELSE
				select @RcptCCID=CONVERT(int,Value) from COM_CostCenterPreferences WITH(nolock)  
				where CostCenterID=95 and Name='TerminatePenaltyJV' 
			 
			Set @DocXml = convert(nvarchar(max), @AA)  

			set @Prefix=''
			EXEC [sp_GetDocPrefix] @DocXml,@TerminationDate,@RcptCCID,@Prefix   output

			EXEC	@return_value = [dbo].[spDOC_SetTempAccDocument]
				@CostCenterID = @RcptCCID,
				@DocID = 0,
				@DocPrefix = @Prefix,
				@DocNumber =1,
				@DocDate = @TerminationDate,
				@DueDate = NULL,
				@BillNo = @SNO,
				@InvDocXML = @DocXml,
				@NotesXML = N'',
				@AttachmentsXML = N'',
				@ActivityXML  = N'<XML></XML>', 
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
	  
			INSERT INTO  [REN_ContractDocMapping]([ContractID],[Type],[Sno],DocID,CostcenterID,IsAccDoc,DocType,ContractCCID)
			values(@ContractID,-4,0,@return_value,@RcptCCID,1,0,95)
		END
	END
	ELSE IF( @SCostCenterID  = 104)
	BEGIN 
	
		IF(@SRTXML is not null and @SRTXML<>'')  
		BEGIN  
			select @RcptCCID=CONVERT(int,Value) from COM_CostCenterPreferences WITH(nolock)  
			where CostCenterID=104 and Name='PurchasePReturn'  
			
			SET @XML = @SRTXML
			CREATE TABLE #tblListPIVTemp(ID int identity(1,1),TRANSXML NVARCHAR(MAX) ,Documents NVARCHAR(200))        
			INSERT INTO #tblListPIVTemp    
			SELECT  CONVERT(NVARCHAR(MAX),  X.query('DocumentXML'))   ,  CONVERT(NVARCHAR(200),X.query('Documents'))                 
			from @XML.nodes('/PIV//ROWS') as Data(X)    

			SELECT @CNT = COUNT(ID) FROM #tblListPIVTemp  

			SET @ICNT = 0  
			WHILE(@ICNT < @CNT)  
			BEGIN  
				SET @ICNT =@ICNT+1  
				SELECT @AA = TRANSXML , @Documents = Documents    FROM #tblListPIVTemp WHERE  ID = @ICNT  
				Set @DocXml = convert(nvarchar(max), @AA)  
				SET @DocIDValue = ISNULL(@DocIDValue,0)
	  
				if exists(SELECT IsBillwise FROM ACC_Accounts WITH(NOLOCK) WHERE AccountID=@RentRecID and IsBillwise=1)
				begin
					IF EXISTS(select Value from ADM_GLOBALPREFERENCES WITH(NOLOCK) where NAME  = 'On')
					BEGIN
						SET @tempxml =''
						SET @tempAmt = 0
						set @tempxml=@DocXml
						select @tempAmt=sum(X.value('@Amount',' float'))
						from @tempxml.nodes('/DocumentXML/Row/AccountsXML/Accounts') as Data(X)						
						set @BillWiseXMl='<BillWise> <Row DocSeqNo="1" AccountID="'+convert(nvarchar,@RentRecID)+'" AmountFC="'+CONVERT(nvarchar,@tempAmt)+'" AdjAmount="'+CONVERT(nvarchar,@tempAmt)+'" AdjCurrID="1" AdjExchRT="1" IsNewReference="1" Narration="" IsDocPDC="0" ></Row></BillWise>'
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
				EXEC [sp_GetDocPrefix] @DocXml,@TerminationDate,@RcptCCID,@Prefix   output
				
				set @DocXml=Replace(@DocXml,'<RowHead/>','')
				set @DocXml=Replace(@DocXml,'</DocumentXML>','')
				set @DocXml=Replace(@DocXml,'<DocumentXML>','')
				
				EXEC @return_value = [dbo].[spDOC_SetTempInvDoc]  
				@CostCenterID = @RcptCCID,  
				@DocID = @DocIDValue,  
				@DocPrefix = @Prefix,  
				@DocNumber = 1,  
				@DocDate = @TerminationDate,  
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
				@RefCCID = 104,
				@RefNodeid  = @ContractID,
				@CompanyGUID = @CompanyGUID,  
				@UserName = @UserName,  
				@UserID = @UserID,  
				@LangID = @LangID   
			   
				SET @SalesInv  = @return_value  
			 
				set @XML = @AA  
				
				INSERT INTO  [REN_ContractDocMapping]([ContractID],[Type],[Sno],DocID,COSTCENTERID,IsAccDoc,DocType,ContractCCID) 
				values(@ContractID,-1,0,@SalesInv,@RcptCCID,0,0,104)
			END
		END   
	 
		IF(@PDPaymentXML is not null and @PDPaymentXML<>'')  
		BEGIN  
	 
			set @MPSNO = 0

			SET @XML =  @PDPaymentXML   
			CREATE TABLE #tblListPDP(ID int identity(1,1),TRANSXML NVARCHAR(MAX) , DateXML NVARCHAR(MAX), AccountType NVARCHAR(100) ,Documents NVARCHAR(200) )      
			INSERT INTO #tblListPDP    
			SELECT  CONVERT(NVARCHAR(MAX),  X.query('DocumentXML')) ,  CONVERT(NVARCHAR(MAX),  X.query('ChequeDocDate')) ,  CONVERT(NVARCHAR(MAX),  X.query('AccountType')) ,  CONVERT(NVARCHAR(200),  X.query('Documents'))              
			from @XML.nodes('/PDPayment/ROWS') as Data(X)    

			SELECT @CNT = COUNT(ID) FROM #tblListPDP  

			SET @ICNT = 0  
			WHILE(@ICNT < @CNT)  
			BEGIN  
				SET @ICNT =@ICNT+1  

				SELECT @AA = TRANSXML , @DateXML = DateXML , @AccountType = AccountType , @Documents = Documents  FROM #tblListPDP WHERE  ID = @ICNT  

				SELECT   @AccValue =  X.value('@DD', 'NVARCHAR(100)' )        
				from @AccountType.nodes('/AccountType') as Data(X)  

				SET @DocIDValue = ISNULL(@DocIDValue,0)
	     
				IF(@AccValue = 'BANK')
				BEGIN
					SELECT @RcptCCID=CONVERT(int,Value) from COM_CostCenterPreferences WITH(nolock)  
					WHERE CostCenterID=104 and Name='PurchasePostDatedReciept'  
				END
				ELSE  IF(@AccValue = 'CASH')
				BEGIN
					SELECT @RcptCCID=CONVERT(int,Value) from COM_CostCenterPreferences WITH(nolock)  
					WHERE CostCenterID=104 and Name='PurchaseCashReceipts'   
				END
				ELSE  IF(@AccValue = 'JV')
				BEGIN
					select @RcptCCID=CONVERT(int,Value) from COM_CostCenterPreferences WITH(nolock)  
					where CostCenterID=104 and Name='PurchaseTermJV'  
				END

				Set @DocXml = convert(nvarchar(max), @AA)  

				set @Prefix=''
				EXEC [sp_GetDocPrefix] @DocXml,@TerminationDate,@RcptCCID,@Prefix   output

				EXEC @return_value = [dbo].[spDOC_SetTempAccDocument]  
				@CostCenterID = @RcptCCID,  
				@DocID = @DocIDValue,  
				@DocPrefix = @Prefix,  
				@DocNumber =1,  
				@DocDate = @TerminationDate,  
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
				@RefCCID = 104,
				@RefNodeid = @ContractID ,
				@CompanyGUID = @CompanyGUID,  
				@UserName = @UserName,  
				@UserID = @UserID,  
				@LangID = @LangID  
				 
				SET @PDRcpt  = @return_value  

				set @XML = @AA  
				
				INSERT INTO [REN_ContractDocMapping]([ContractID],[Type],[Sno],DocID,CostcenterID,IsAccDoc,DocType,ContractCCID)  
				values(@ContractID,-2,0,@PDRcpt,@RcptCCID ,1,0,104)	
			END  
		END  
	   
		IF(@ComPayXML is not null and @ComPayXML<>'')  
		BEGIN  
	 
			SET @XML =   @ComPayXML   

			CREATE TABLE #tblListPayCOM(ID int identity(1,1),TRANSXML NVARCHAR(MAX) , DateXML NVARCHAR(MAX) , AccountType NVARCHAR(100),Documents NVARCHAR(200) )        
			INSERT INTO #tblListPayCOM    
			SELECT  CONVERT(NVARCHAR(MAX),  X.query('DocumentXML')) ,  CONVERT(NVARCHAR(MAX),  X.query('ChequeDocDate'))  ,  CONVERT(NVARCHAR(MAX),  X.query('AccountType'))  ,  CONVERT(NVARCHAR(200),  X.query('Documents'))                
			from @XML.nodes('/PARTICULARS//ROWS') as Data(X)    

			SELECT @CNT = COUNT(ID) FROM #tblListPayCOM  

			SET @ICNT = 0  
			WHILE(@ICNT < @CNT)  
			BEGIN  
				SET @ICNT =@ICNT+1  

				SELECT @AA = TRANSXML , @DateXML = DateXML, @AccountType = AccountType  , @Documents = Documents   FROM #tblListPayCOM WHERE  ID = @ICNT  

				Set @DocXml = convert(nvarchar(max), @AA)  

				SET @DocIDValue = ISNULL(@DocIDValue,0)

				SELECT   @AccValue =  X.value ('@DD', 'NVARCHAR(100)' )        
				from @AccountType.nodes('/AccountType') as Data(X)  

				IF(@AccValue = 'BANK')
				BEGIN
					set @prefVal=''
					select @prefVal=Value from COM_CostCenterPreferences WITH(nolock)  
					where CostCenterID=104 and Name='PurchaseParticularsPDC'  
					IF(@prefVal <>'' and @prefVal='True')
					BEGIN
						select @RcptCCID=CONVERT(int,Value) from COM_CostCenterPreferences WITH(nolock)  
						where CostCenterID=104 and Name='PurchasePostDatedReciept'  
					END
					ELSE
					BEGIN
						select @RcptCCID=CONVERT(int,Value) from COM_CostCenterPreferences WITH(nolock)  
						where CostCenterID=104 and Name='PurchaseBankReciept'  
					END 
				END
				ELSE 
				BEGIN
					select @RcptCCID=CONVERT(int,Value) from COM_CostCenterPreferences WITH(nolock)  
					where CostCenterID=104 and Name='PurchaseCashReceipts'  
				END
				
				set @Prefix=''
				EXEC [sp_GetDocPrefix] @DocXml,@TerminationDate,@RcptCCID,@Prefix   output

				EXEC @return_value = [dbo].[spDOC_SetTempAccDocument]  
				@CostCenterID = @RcptCCID,  
				@DocID = @DocIDValue,  
				@DocPrefix = @Prefix,  
				@DocNumber =1,  
				@DocDate = @TerminationDate, 
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
				@RefCCID = 104,
				@RefNodeid = @ContractID ,
				@CompanyGUID = @CompanyGUID,  
				@UserName = @UserName,  
				@UserID = @UserID,  
				@LangID = @LangID  

				SET @CommRcpt  = @return_value  

				set @XML = @AA  
				
				INSERT INTO  [REN_ContractDocMapping]([ContractID],[Type],[Sno],DocID,CostcenterID,IsAccDoc,DocType,ContractCCID)  
				values( @ContractID,-1,0,@return_value,@RcptCCID,1,0,104)   
			END  
		END  
	   
		IF(@RentPayXML is not null and @RentPayXML<>'')  
		BEGIN  
			select @RcptCCID=CONVERT(int,Value) from COM_CostCenterPreferences WITH(nolock)  
			where CostCenterID=104 and Name='PurchaseBankReciept'  
			SET @XML =   @RentPayXML   

			CREATE TABLE #tblPayList(ID int identity(1,1),TRANSXML NVARCHAR(MAX) , DateXML NVARCHAR(MAX))       
			INSERT INTO #tblPayList    
			SELECT  CONVERT(NVARCHAR(MAX),  X.query('DocumentXML') ) ,  CONVERT(NVARCHAR(MAX),  X.query('ChequeDocDate'))      
			from @XML.nodes('/RENTRCT/ROWS') as Data(X)    

			SELECT @CNT = COUNT(ID) FROM #tblPayList  
			SET @ICNT = 0  
			WHILE(@ICNT < @CNT)  
			BEGIN  
				SET @ICNT =@ICNT+1  

				SELECT @AA = TRANSXML , @DateXML = DateXML  FROM #tblPayList WHERE  ID = @ICNT  
				
				Set @DocXml = convert(nvarchar(max), @AA)  

				SELECT @DocIDValue=0

				set @Prefix=''
				EXEC [sp_GetDocPrefix] @DocXml,@TerminationDate,@RcptCCID,@Prefix   output

				EXEC @return_value = [dbo].[spDOC_SetTempAccDocument]  
				@CostCenterID = @RcptCCID,  
				@DocID = @DocIDValue,  
				@DocPrefix = N'',  
				@DocNumber =1,     
				@DocDate =  @TerminationDate,  
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
				@RefCCID = 104,
				@RefNodeid = @ContractID ,
				@CompanyGUID = @CompanyGUID,  
				@UserName = @UserName,  
				@UserID = @UserID,  
				@LangID = @LangID  
  
				SET @RentRcpt  = @return_value  

				set @XML = @AA  
				
				INSERT INTO  [REN_ContractDocMapping]([ContractID],[Type],[Sno],DocID,CostcenterID,IsAccDoc,DocType,ContractCCID)  
				values( @ContractID,-1,0,@return_value,@RcptCCID,1,0,104)   
			END  
		END   
	END
   
	-------------------------- END POSTINGS -----------------------

	IF( (@SCostCenterID = 95 OR @SCostCenterID = 104)and @Dimesion IS NOT NULL AND  @Dimesion  > 50000 and @CCNODEID IS NOT NULL AND  @CCNODEID  > 0)  
	BEGIN  
		set @DDXML=' UPDATE COM_DOCCCDATA SET DCCCNID'+convert(nvarchar,(@Dimesion-50000))+'='+CONVERT(NVARCHAR,@CCNODEID)+'   
		WHERE ACCDOCDETAILSID IN (SELECT ACCDOCDETAILSID  FROM ACC_DOCDETAILS WITH(NOLOCK) WHERE REFCCID = '+CONVERT(NVARCHAR,@SCostCenterID)+' AND REFNODEID = '+convert(nvarchar,@ContractID) + ' and DOCID > 0) 
		OR INVDOCDETAILSID IN (SELECT INVDOCDETAILSID  FROM INV_DOCDETAILS WITH(NOLOCK) WHERE REFCCID = '+CONVERT(NVARCHAR,@SCostCenterID)+' AND REFNODEID =  '+convert(nvarchar,@ContractID)+ ' and DOCID > 0)'  
		
		EXEC (@DDXML) 
		
		Exec [spDOC_SetLinkDimension]
				@InvDocDetailsID=@ContractID, 
				@Costcenterid=@SCostCenterID,         
				@DimCCID=@Dimesion,
				@DimNodeID=@CCNODEID,
				@UserID=@UserID,    
				@LangID=@LangID    
	END 
	
	IF( @SCostCenterID = 95 OR @SCostCenterID = 104)
	BEGIN		
		update ACC_DocDetails
		set StatusID=452
		from  ACC_DocDetails D with(nolock)
		join Ren_contract RC with(nolock) on Rc.ContractID=D.RefNOdeID 
		join  REN_ContractDocMapping RDM with(nolock) on D.DocID=RDM.DocID
		where D.StatusID =370 and RC.ContractID =@ContractID and D.refccid=@SCostCenterID
		and IsAccDoc=1 and Rc.ContractID=RDM.ContractID and Type<>-4
		
		set @PendingVchrs=''
		
		select @PendingVchrs=@PendingVchrs+dbo.[fnDoc_GetPendingVouchers](VoucherNo) from ACC_DocDetails WITH(NOLOCK)
		where RefCCID=@SCostCenterID and RefNodeid=@ContractID and StatusID=429
		
		insert into @tabvchrs
		exec SPSplitString @PendingVchrs,','
		
		update ACC_DocDetails 
		set StatusID=452
		where StatusID=370 and VoucherNo in(select vno from @tabvchrs)
	
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
	
	if exists(select Value from COM_CostCenterPreferences WITH(nolock)  
		where CostCenterID=95 and  Name = 'UseExtOnTerminate'  and Value='true')	
		EXEC [spEXT_TerminatePostings] @ContractID,@sno,@CompanyGUID,@UserName,@RoleID,@UserID,@LangID

		
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
			if(isnumeric(ERROR_MESSAGE())=1)
				SELECT ErrorMessage,ErrorNumber FROM COM_ErrorMessages WITH(nolock)   
				WHERE ErrorNumber=ERROR_MESSAGE() AND LanguageID=@LangID  
			else
				SELECT ERROR_MESSAGE() ErrorMessage
		END  
		ELSE IF ERROR_NUMBER()=547  
		BEGIN  
			SELECT ErrorMessage, ERROR_MESSAGE() AS ServerMessage,ERROR_NUMBER() as ErrorNumber, ERROR_PROCEDURE()as ProcedureName, ERROR_LINE() AS ErrorLine 
			FROM COM_ErrorMessages WITH(nolock)  
			WHERE ErrorNumber=-110 AND LanguageID=@LangID  
		END  
		ELSE IF ERROR_NUMBER()=2627  
		BEGIN  
			SELECT ErrorMessage, ERROR_MESSAGE() AS ServerMessage,ERROR_NUMBER() as ErrorNumber, ERROR_PROCEDURE()as ProcedureName, ERROR_LINE() AS ErrorLine 
			FROM COM_ErrorMessages WITH(nolock)  
			WHERE ErrorNumber=-116 AND LanguageID=@LangID  
		END  
		ELSE  
		BEGIN  
			SELECT ErrorMessage, ERROR_MESSAGE() AS ServerMessage,ERROR_NUMBER() as ErrorNumber, ERROR_PROCEDURE()as ProcedureName, ERROR_LINE() AS ErrorLine  
			FROM COM_ErrorMessages WITH(nolock) 
			WHERE ErrorNumber=-999 AND LanguageID=@LangID  
		END   
		ROLLBACK TRANSACTION    
	END
	SET NOCOUNT OFF      
	RETURN -999       
END CATCH 

GO

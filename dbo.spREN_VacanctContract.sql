USE PACT2C222
GO
SET ANSI_NULLS, QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spREN_VacanctContract]
	@ContractID [int],
	@VacancyDate [datetime],
	@PostingDate [datetime],
	@SRTXML [nvarchar](max) = NULL,
	@VacantXML [nvarchar](max) = NULL,
	@PenaltyXML [nvarchar](max) = NULL,
	@PenaltyRetXML [nvarchar](max) = NULL,
	@RemaingPaymentXML [nvarchar](max) = NULL,
	@finalsettXML [nvarchar](max) = NULL,
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
	@InputVAT [float] = 0,
	@OutputVAT [float] = 0,
	@action [int],
	@RentRecID [int] = 0,
	@Reason [int],
	@LocationID [int] = 0,
	@divisionID [int] = 0,
	@RoleID [int] = 0,
	@TermPart [nvarchar](max),
	@WID [int],
	@UnitStatusid [int],
	@SysInfo [nvarchar](500) = '',
	@AP [nvarchar](10) = '',
	@LockDims [nvarchar](max) = '',
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
  
	DECLARE @Dt float,@XML xml,@return_value int,@SNO int,@RcptCCID INT,@tempAmt float,@Prefix nvarchar(200)
	DECLARE  @CNT INT ,  @ICNT INT,@AA XML,@DocXml nvarchar(max) ,@BillWiseXMl nvarchar(max) ,@CCNODEID INT,@Dimesion int   
	DECLARE @PickAcc nvarchar(50) ,@penAccID INT,@AccountType xml,@level int,@maxLevel int,@StatusID int,@wfAction int ,@ActXml nvarchar(max)         
	
	set @ActXml='<XML SysInfo="'+@sysinfo+'" AP="'+@AP+'" ></XML>'   
	
	SET @Dt=convert(float,getdate())--Setting Current Date 
	DECLARE @AUDITSTATUS NVARCHAR(50)  
	
	
	if(@action=3)
	begin
		set @StatusID =450
		SET @AUDITSTATUS= 'REFUND'
	end
	else
	begin
		set @StatusID =480
		SET @AUDITSTATUS= 'CLOSE'
	end	
	if(@LockDims is not null and @LockDims<>'')
	BEGIN
		set @DocXml=' if exists(select a.ContractID from REN_Contract a WITH(NOLOCK)
		join COM_CCCCData b WITH(NOLOCK) on a.ContractID=b.NodeID and a.CostCenterID=b.CostCenterID
		join ADM_DimensionWiseLockData c WITH(NOLOCK) on '+convert(nvarchar(max),convert(float,@VacancyDate))+' between c.fromdate and c.todate and c.isEnable=1 
		where  a.CostCenterID=95 and a.ContractID='+convert(nvarchar,@ContractID)+' '+@LockDims
		+') RAISERROR(''-125'',16,1) '
		
		EXEC(@DocXml)
	END
	
	--VacantContract External function
	IF (@ContractID>0)
	BEGIN
		DECLARE @tablename NVARCHAR(200)
		set @tablename=''
		select @tablename=SpName from ADM_DocFunctions  WITH(NOLOCK) where CostCenterID=95 and Mode=23
		if(@tablename<>'')
			exec @tablename 95,@ContractID,'',@UserID,@LangID	
	END	
		
	if(@WID>0)
	begin
		set @level=(SELECT  top 1  LevelID FROM [COM_WorkFlow]   WITH(NOLOCK) 
		where WorkFlowID=@WID and  UserID =@UserID)

		if(@level is null )
			set @level=(SELECT top 1 LevelID FROM [COM_WorkFlow]  WITH(NOLOCK)  
			where WorkFlowID=@WID and  RoleID =@RoleID)

		if(@level is null ) 
			set @level=(SELECT top 1  LevelID FROM [COM_WorkFlow]   WITH(NOLOCK) 
			where WorkFlowID=@WID and  GroupID in (select GroupID from COM_Groups WITH(NOLOCK) where UserID=@UserID))

		if(@level is null )
			set @level=( SELECT top 1  LevelID FROM [COM_WorkFlow] WITH(NOLOCK) 
			where WorkFlowID=@WID and  GroupID in (select GroupID from COM_Groups WITH(NOLOCK) 
			where RoleID =@RoleID))

		select @maxLevel=max(LevelID) from COM_WorkFlow WITH(NOLOCK)  where WorkFlowID=@WID  
		
		if(@level is not null and  @maxLevel is not null and @maxLevel>@level)
		begin			
		    --set @StatusID=466
		    if(@action=2)
		    BEGIN
				set @StatusID=481
				set @wfAction=3
		    END
		    ELSE
		    BEGIN
				set @StatusID=478
				set @wfAction=2
			END	
		END
	END
	
	if(@action=3)
	begin
		--FullRefund/Refund External function
		IF (@ContractID>0)
		BEGIN
			DECLARE @FRtablename NVARCHAR(200)
			--Refund
			set @FRtablename=''
			select @FRtablename=SpName from ADM_DocFunctions  WITH(NOLOCK) where CostCenterID=95 and Mode=21
			if(@FRtablename<>'')
				exec @FRtablename 95,@ContractID,'',@UserID,@LangID	
			
			--FullRefund
			set @FRtablename=''
			select @FRtablename=SpName from ADM_DocFunctions  WITH(NOLOCK) where CostCenterID=95 and Mode=22
			if(@FRtablename<>'')
				exec @FRtablename 95,@ContractID,'',@UserID,@LangID		
		END	
		
		UPDATE REN_CONTRACT
		SET STATUSID = @StatusID, WorkFlowID=@WID,wfAction=@wfAction,WorkFlowLevel=case when @WID>0 then @level else WorkFlowLevel end
		 ,RefundDate = CONVERT(FLOAT , @VacancyDate),SRTAmount=@SRTAmount,RefundAmt=@RefundAmt,
		PDCRefund=@PDCRefund,Penalty=@Penalty,Amt=@Amt,TermPayMode=@TermPayMode,TermChequeNo=@TermChequeNo,
		TermChequeDate= CONVERT(FLOAT , @TermChequeDate),TermRemarks=@TermRemarks,SecurityDeposit=@SecurityDeposit
		,modifieddate=@Dt,modifiedby=@UserName,PendFinalSettl=null,Reason = @Reason,FinalSettlXML=@finalsettXML,OutputVAT=@OutputVAT
		WHERE ContractID = @ContractID or RefContractID=@ContractID
	end
	ELSE
		UPDATE REN_CONTRACT
		SET STATUSID = @StatusID, WorkFlowID=@WID,wfAction=@wfAction,WorkFlowLevel=case when @WID>0 then @level else WorkFlowLevel end
		 ,VacancyDate = CONVERT(FLOAT , @VacancyDate),SRTAmount=@SRTAmount,RefundAmt=@RefundAmt,
		PDCRefund=@PDCRefund,Penalty=@Penalty,Amt=@Amt,TermPayMode=@TermPayMode,TermChequeNo=@TermChequeNo,
		TermChequeDate= CONVERT(FLOAT , @TermChequeDate),TermRemarks=@TermRemarks,SecurityDeposit=@SecurityDeposit
		,modifieddate=@Dt,modifiedby=@UserName,PendFinalSettl=null,Reason = @Reason,FinalSettlXML=@finalsettXML,OutputVAT=@OutputVAT
		WHERE ContractID = @ContractID or RefContractID=@ContractID
	    
    DECLARE @AuditTrial BIT    
	SET @AuditTrial=0    
	SELECT @AuditTrial= CONVERT(BIT,VALUE)  FROM [COM_COSTCENTERPreferences]  WITH(NOLOCK)  
	WHERE CostCenterID=95  AND NAME='AllowAudit' 

	IF (@AuditTrial=1 )  
	BEGIN  
		EXEC [spCOM_SaveHistory]  
			@CostCenterID =95,    
			@NodeID =@ContractID,
			@HistoryStatus =@AUDITSTATUS,
			@UserName=@UserName,
			@Dt=@Dt 
	END 
	
	if(@UnitStatusid>0)
	BEGIN
		 update b
		 set UnitStatus= @UnitStatusid 
		 from REN_Contract a WITH(NOLOCK)
		 join REN_Units b WITH(NOLOCK) on a.UnitID=b.UnitID
		 WHERE a.ContractID = @ContractID or a.RefContractID=@ContractID		
    END      
	
	set @SNO=0	 
	select @SNO=Value from COM_CostCenterPreferences WITH(NOLOCK)
	where Name='CloseProfile' and CostCenterID=95 and Value is not null and Value<>'' and isnumeric(Value)=1
	if(@SNO>0)
	BEGIN
		if(@action=3)
			set @CCNODEID=450
		else
			set @CCNODEID=480
			
		exec @return_value =[spDOC_SetDocFlow] 
					  @CCID= 1000,
					  @DocID =1,
					  @ProfileID=@SNO,
					  @RefCCID=95,
					  @RefNodeID=@ContractID,
					  @RefStatusID=@CCNODEID,
					  @UserName=@UserName,
					  @UserID=@UserID,      
					  @LangID=@LangID
	END			
		
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
			 EXEC [sp_GetDocPrefix] @DocXml,@PostingDate,@RcptCCID,@Prefix   output
	
			set @DocXml=Replace(@DocXml,'<RowHead/>','')
			set @DocXml=Replace(@DocXml,'</DocumentXML>','')
			set @DocXml=Replace(@DocXml,'<DocumentXML>','')


			EXEC	@return_value = [dbo].[spDOC_SetTempInvDoc]
			@CostCenterID = @RcptCCID,
			@DocID = 0,
			@DocPrefix = @Prefix,
			@DocNumber = N'',
			@DocDate = @PostingDate,
			@DueDate = NULL,
			@BillNo = @SNO,
			@InvDocXML =@DocXml,
			@BillWiseXML = @BillWiseXMl,
			@NotesXML = N'',
			@AttachmentsXML = N'',
			@ActivityXML  = @ActXml, 
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
			EXEC [sp_GetDocPrefix] @DocXml,@PostingDate,@RcptCCID,@Prefix   output
			
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
				@DocDate = @PostingDate,  
				@DueDate = NULL,  
				@BillNo = @SNO,  
				@InvDocXML =@DocXml,  
				@BillWiseXML = N'',  
				@NotesXML = N'',  
				@AttachmentsXML = N'',  
				@ActivityXML  = @ActXml, 
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
				   @DocDate = @PostingDate,      
				   @DueDate = NULL,      
				   @BillNo = @SNO,      
				   @InvDocXML = @DocXml,      
				   @NotesXML = N'',      
				   @AttachmentsXML = N'',      
				   @ActivityXML  = @ActXml,     
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
			EXEC [sp_GetDocPrefix] @PenaltyXML,@PostingDate,@RcptCCID,@Prefix   output

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
				@DocDate = @PostingDate,  
				@DueDate = NULL,  
				@BillNo = @SNO,  
				@InvDocXML =@PenaltyXML,  
				@BillWiseXML = N'',  
				@NotesXML = N'',  
				@AttachmentsXML = N'',  
				@ActivityXML  = @ActXml, 
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
				@DocDate = @PostingDate, --@TerminationDate,
				@DueDate = NULL,
				@BillNo = @SNO,
				@InvDocXML = @PenaltyXML,
				@NotesXML = N'',
				@AttachmentsXML = N'',
				@ActivityXML  = @ActXml, 
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
	  
	  IF(@PenaltyRetXML is not null and @PenaltyRetXML<>'')  
	BEGIN 
				select @RcptCCID=CONVERT(int,Value) from COM_CostCenterPreferences WITH(nolock)  
				where CostCenterID=95 and Name='PenaltyRet' 
				 
				set @Prefix=''
				EXEC [sp_GetDocPrefix] @PenaltyRetXML,@PostingDate,@RcptCCID,@Prefix   output
			 
				set @PenaltyRetXML=Replace(@PenaltyRetXML,'<RowHead/>','')
				set @PenaltyRetXML=Replace(@PenaltyRetXML,'</DocumentXML>','')
				set @PenaltyRetXML=Replace(@PenaltyRetXML,'<DocumentXML>','')
				
				EXEC @return_value = [dbo].[spDOC_SetTempInvDoc]  
				@CostCenterID = @RcptCCID,  
				@DocID = 0,  
				@DocPrefix = @Prefix,  
				@DocNumber = 1,  
				@DocDate = @PostingDate,  
				@DueDate = NULL,  
				@BillNo = @SNO,  
				@InvDocXML =@PenaltyRetXML,  
				@BillWiseXML = N'',  
				@NotesXML = N'',  
				@AttachmentsXML = N'',  
				@ActivityXML  = @ActXml, 
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
	  
	  IF(@RemaingPaymentXML is not null and @RemaingPaymentXML<>'')  
	  BEGIN 
			set @XML=@RemaingPaymentXML
			
			SELECT  @AA=CONVERT(NVARCHAR(MAX),  X.query('DocumentXML'))   ,@AccountType= CONVERT(NVARCHAR(MAX),  X.query('AccountType'))
			from @XML.nodes('/ReceiptXML/ROWS') as Data(X)  
			
			SELECT   @PickAcc =  X.value ('@DD', 'NVARCHAR(100)' )        
			from @AccountType.nodes('/AccountType') as Data(X) 

			if(@PickAcc='BANK')
				select @RcptCCID=CONVERT(int,Value) from COM_CostCenterPreferences WITH(nolock)  
				where CostCenterID=95 and Name='RemainingPDP' 
			ELSE if(@PickAcc='CASH')
				select @RcptCCID=CONVERT(int,Value) from COM_CostCenterPreferences WITH(nolock)
				where CostCenterID=95 and Name='RemainingBankPay'
			ELSE
				select @RcptCCID=CONVERT(int,Value) from COM_CostCenterPreferences WITH(nolock)  
				where CostCenterID=95 and Name='RemainingJV' 
			 
			Set @DocXml = convert(nvarchar(max), @AA)  

			EXEC	@return_value = [dbo].[spDOC_SetTempAccDocument]
				@CostCenterID = @RcptCCID,
				@DocID = 0,
				@DocPrefix = N'',
				@DocNumber =1,
				@DocDate = @PostingDate,
				@DueDate = NULL,
				@BillNo = @SNO,
				@InvDocXML = @DocXml,
				@NotesXML = N'',
				@AttachmentsXML = N'',
				@ActivityXML  = @ActXml, 
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
			SELECT   @ContractID,X.value ('@CCNodeID', 'INT' )
			,X.value ('@CreditAccID', 'INT' ),X.value ('@DebitAccID', 'INT' ),X.value ('@Amount', 'float' )
			,X.value ('@VatPer', 'float' ),X.value ('@VatAmount', 'float' ),X.value('@NetAmount','float')
			from @XML.nodes('XML/Row') as Data(X) 
			
		END
		
		 
		if(@WID>0 and @wfAction is not null)
		BEGIN	 
		 
			INSERT INTO COM_Approvals(CCID,CCNODEID,StatusID,Date,Remarks,UserID   
			  ,CompanyGUID,GUID,CreatedBy,CreatedDate,WorkFlowLevel,DocDetID)      
			VALUES(95,@ContractID,@StatusID,@Dt,'',@UserID
			  ,@CompanyGUID,newid(),@UserName,@Dt,isnull(@level,0),0)
	 
		    if(@StatusID not in(426,427))
			BEGIN
				update INV_DOCDETAILS
				set StatusID=371
				FROM INV_DOCDETAILS a WITH(NOLOCK)
				join REN_CONTRACTDOCMAPPING b WITH(NOLOCK) on a.DocID=b.DocID 
				WHERE CONTRACTID = @ContractID  AND ISACCDOC = 0 and RefNodeID = @ContractID and b.Type=101      
						
				update ACC_DOCDETAILS
				set StatusID=371
				FROM ACC_DOCDETAILS b WITH(NOLOCK)
				join INV_DOCDETAILS a WITH(NOLOCK) on b.INVDOCDETAILSID=a.INVDOCDETAILSID
				join REN_CONTRACTDOCMAPPING c WITH(NOLOCK) on a.DocID=b.DocID 
				WHERE CONTRACTID = @ContractID  AND ISACCDOC = 0 and a.RefNodeid = @ContractID   and c.Type=101

				update ACC_DOCDETAILS
				set StatusID=371
				FROM ACC_DOCDETAILS a WITH(NOLOCK)
				join REN_CONTRACTDOCMAPPING b WITH(NOLOCK) on a.DocID=b.DocID 
				WHERE CONTRACTID = @ContractID AND ISACCDOC = 1  and RefNodeID = @ContractID and b.Type=101   
				and not (StatusID in(369,429) and DocumentType in(14,19))
			END	
		END	
	 
	  DECLARE @ActionType INT  
	IF(@StatusID = 428)
		SET @ActionType=150 
	ELSE IF(@StatusID = 450) --Refund
		SET @ActionType=161 
	ELSE IF(@StatusID = 480) --Close
		SET @ActionType=163 
    --Email on Termincate
		
		if(@ActionType>0)
			EXEC spCOM_SetNotifEvent @ActionType,95,@ContractID,@CompanyGUID,@UserName,@UserID,@RoleID  
 	
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

USE PACT2C222
GO
SET ANSI_NULLS, QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spREN_SetQuotation]
	@QuotationID [int],
	@CostCenterID [int],
	@Prefix [nvarchar](50),
	@Number [int],
	@Date [datetime],
	@StatusID [int],
	@SelectedNodeID [int],
	@PropertyID [int] = 0,
	@UnitID [int] = 0,
	@MultiUnitIds [nvarchar](max),
	@multiName [nvarchar](max),
	@TenantID [int] = 0,
	@RentRecID [int] = 0,
	@IncomeID [int] = 0,
	@Purpose [nvarchar](500) = NULL,
	@StartDate [datetime],
	@EndDate [datetime],
	@TotalAmount [float],
	@NonRecurAmount [float],
	@RecurAmount [float],
	@ContractXML [nvarchar](max) = NULL,
	@PayTermsXML [nvarchar](max) = NULL,
	@RoleID [int],
	@ContractLocationID [int],
	@ContractDivisionID [int],
	@ContractCurrencyID [int],
	@CustomFieldsQuery [nvarchar](max) = null,
	@CustomCostCenterFieldsQuery [nvarchar](max) = null,
	@TermsConditions [nvarchar](max) = NULL,
	@SalesmanID [int],
	@AccountantID [int],
	@LandlordID [int],
	@Narration [nvarchar](500),
	@AttachmentsXML [nvarchar](max),
	@ExtendTill [datetime],
	@NotesXML [nvarchar](max),
	@basedon [nvarchar](50),
	@PostPDRecieptXML [nvarchar](max),
	@WID [int],
	@RecurDuration [int],
	@ExpectedEndDate [datetime],
	@GracePeriod [int],
	@LinkedQuotationID [int],
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
    
    if(@ExpectedEndDate='1/JAN/1900')
		set @ExpectedEndDate=NULL  
		    
	DECLARE @Dt float,@XML xml,@CNT int,@i int, @level int,@maxLevel int
	DECLARE @UpdateSql nvarchar(max),@AA nvarchar(max),@DocXML XML ,@DDXML nvarchar(max)   
	DECLARE @lft INT,@rgt INT,@Selectedlft INT,@Selectedrgt INT,@Depth int,@ParentID INT 
	declare @tblExistingCNT INT,@AccValue nvarchar(100),@DocIDValue INT,@RcptCCID int,@DELETECCID int,@return_value int
	DECLARE @AUDITSTATUS NVARCHAR(50) 
	SET @AUDITSTATUS= 'EDIT'    
	
	declare @ChildUnits table(UnitID INT)  
	insert into @ChildUnits  
	exec SPSplitString @MultiUnitIds,','
	
	iF(@UnitID=0 and exists(select * from @ChildUnits))
		select @UnitID=UnitID from @ChildUnits
	
	if(@CostCenterID=129)
	BEGIN
		
		set @DDXML='if exists(SELECT QuotationID from REN_Quotation with(nolock)                      
		WHERE ( '''+convert(nvarchar,@StartDate)+'''   between CONVERT(datetime, StartDate) and CONVERT(datetime, EndDate)      
		or       '''+convert(nvarchar,@EndDate)+'''  between CONVERT(datetime, StartDate) and CONVERT(datetime, EndDate)
		or	CONVERT(datetime, StartDate) between '''+convert(nvarchar,@StartDate)+''' and  '''+convert(nvarchar,@EndDate)+''' 
	 	or CONVERT(datetime, EndDate) between '''+convert(nvarchar,@StartDate)+''' and  '''+convert(nvarchar,@EndDate)+'''   )             
		AND UnitID = '+convert(nvarchar,@UnitID)+' and StatusID =467
		and QuotationID<>'+convert(nvarchar,@QuotationID )+')
		RAISERROR(''-520'',16,1)'	
		exec(@DDXML)
		
		set @DDXML='if exists(SELECT ContractID, ContractPrefix, ContractDate,convert(datetime,StartDate) StartDate,                   
		convert(datetime, EndDate) EndDate,  ContractNumber, StatusID                       
		FROM REN_Contract with(nolock)                      
		WHERE ( '''+convert(nvarchar,@StartDate)+'''   between CONVERT(datetime, StartDate) and CONVERT(datetime, EndDate)      
		or       '''+convert(nvarchar,@EndDate)+'''  between CONVERT(datetime, StartDate) and CONVERT(datetime, EndDate)
		or	CONVERT(datetime, StartDate) between '''+convert(nvarchar,@StartDate)+''' and  '''+convert(nvarchar,@EndDate)+''' 
	 	or CONVERT(datetime, EndDate) between '''+convert(nvarchar,@StartDate)+''' and  '''+convert(nvarchar,@EndDate)+'''   )             
		AND UnitID = '+convert(nvarchar,@UnitID)+' and    StatusID <> 428   and    StatusID <> 451)
		RAISERROR(''-520'',16,1)'	
		exec(@DDXML)

	END   
	
	if(@LinkedQuotationID>0)
	BEGIN
		update REN_Quotation 
		set StatusID =467 
		where QuotationID=@LinkedQuotationID
	END
	 
	if(@ExtendTill='1/JAN/1900')
		set @ExtendTill=null       

	SET @Dt=convert(float,getdate())--Setting Current Date  
    
    if(@WID>0 and @StatusID not in(430,469,468))   	
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
			set @StatusID=440
		END
	END
         
    DECLARE @SelectedIsGroup bit,@SNO INT
    
	IF @QuotationID=0          
	BEGIN     
		SET @AUDITSTATUS = 'ADD'     
		SELECT @SelectedIsGroup=IsGroup,@Selectedlft =lft,@Selectedrgt=rgt,@ParentID=ParentID,@Depth=Depth          
		from REN_Quotation with(NOLOCK) where QuotationID=@SelectedNodeID          
	           
		select @SNO=ISNULL(max(SNO),0)+1 from REN_Quotation (holdlock)
		where CostCenterID=@CostCenterID AND StatusID<>430
		
		if (select count(*) from REN_Quotation with(nolock) where CostCenterID=@CostCenterID and propertyid=@PropertyID and number=@Number)>0
		begin
			select @Number=ISNULL(max(Number),0)+1 from REN_Quotation with(nolock) where propertyid=@PropertyID
		end
		
		--select @ContractNumber
	           
		--IF No Record Selected or Record Doesn't Exist          
		if(@SelectedIsGroup is null)           
			select @SelectedNodeID=QuotationID,@SelectedIsGroup=IsGroup,@Selectedlft =lft,@Selectedrgt=rgt,@ParentID=ParentID,@Depth=Depth          
			from REN_Quotation with(NOLOCK) where ParentID =0          

		if(@SelectedIsGroup = 1)--Adding Node Under the Group          
		BEGIN          
			UPDATE REN_Quotation SET rgt = rgt + 2 WHERE rgt > @Selectedlft;          
			UPDATE REN_Quotation SET lft = lft + 2 WHERE lft > @Selectedlft;          
			set @lft =  @Selectedlft + 1          
			set @rgt = @Selectedlft + 2          
			set @ParentID = @SelectedNodeID          
			set @Depth = @Depth + 1          
		END          
		else if(@SelectedIsGroup = 0)--Adding Node at Same level          
		BEGIN          
			UPDATE REN_Quotation SET rgt = rgt + 2 WHERE rgt > @Selectedrgt;          
			UPDATE REN_Quotation SET lft = lft + 2 WHERE lft > @Selectedrgt;          
			set @lft =  @Selectedrgt + 1          
			set @rgt = @Selectedrgt + 2           
		END          
		else  --Adding Root          
		BEGIN          
			set @lft =  1          
			set @rgt = 2           
			set @Depth = 0          
		END          
       
		-- INSERT CONTRACT      
		INSERT INTO  REN_Quotation        
		  ([Prefix],SNO        
		  ,[Date]        
		  ,[Number] ,StatusID             
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
		  ,[LocationID]      
		  ,[DivisionID]      
		  ,[CurrencyID]        
		  ,[TermsConditions]    
		  ,[SalesmanID]    
		  ,[AccountantID]      
		  ,[LandlordID]    
		  ,Narration,BasedOn,CostCenterID,ExtendTill
		  ,WorkFlowID,WorkFlowLevel,NoOfUnits,multiName,RefQuotation,RecurDuration,LinkedQuotationID
		  ,ExpectedEndDate,GracePeriod)   
	   VALUES        
		(@Prefix,  @SNO,     
		CONVERT(FLOAT,@Date),        
		@Number,     @StatusID,   
		@PropertyID,        
		@UnitID,        
		@TenantID,        
		@RentRecID,        
		@IncomeID,        
		@Purpose,        
		CONVERT(FLOAT,@StartDate),        
		CONVERT(FLOAT,@EndDate),       
		@TotalAmount,        
		@NonRecurAmount,        
		@RecurAmount ,      
		@Depth,      
		@SelectedNodeID,      
		@lft,      
		@rgt,      
		0,        
		@CompanyGUID,          
		newid(),          
		@UserName,          
		@Dt,      
		@ContractLocationID,      
		@ContractDivisionID,      
		@ContractCurrencyID,      
		@TermsConditions,    
		@SalesmanID,    
		@AccountantID,    
		@LandlordID,    
		@Narration,    
		@basedon,@CostCenterID,CONVERT(FLOAT,@ExtendTill)
		,@WID,@level,1,@multiName,0,@RecurDuration,@LinkedQuotationID
		,CONVERT(FLOAT,@ExpectedEndDate),@GracePeriod)        
		IF @@ERROR<>0 BEGIN ROLLBACK TRANSACTION RETURN -101 END        
			set @QuotationID=SCOPE_IDENTITY()        
         
		INSERT INTO REN_QuotationExtended([QuotationID])        
		VALUES(@QuotationID)        

		INSERT INTO COM_CCCCDATA ([CostCenterID],[NodeID],[Guid],[CreatedBy],[CreatedDate])      
		VALUES(@CostCenterID,@QuotationID,newid(),@UserName, @Dt)           
	END -- END CREATE        
	ELSE --UPDATE
	BEGIN      
		if(@WID=0)
		BEGIN      
			set @Selectedrgt=0
			select @SNO=SNO,@Selectedrgt=isnull(WorkFlowID,0),@level=WorkFlowLevel from REN_Quotation with(nolock) WHERE QuotationID =  @QuotationID
		END
		ELSE
		BEGIN
			select @SNO=SNO from REN_Quotation with(nolock) WHERE QuotationID =  @QuotationID
			set @Selectedrgt=@WID
		END	
		
		if exists(select * from REN_Quotation WITH(NOLOCK) WHERE QuotationID =  @QuotationID and statusid=469)
		BEGIN
				set @DocIDValue=0
				SELECT  @DELETECCID = CostcenterID ,@DocIDValue=DocID FROM REN_ContractDocMapping WITH(nolock)       				
				WHERE CONTRACTID = @QuotationID and [Type]=101    
				
				if(@DocIDValue>0)
				BEGIN
					EXEC @return_value = [dbo].[spDOC_DeleteAccDocument]      
					@CostCenterID = @DELETECCID,      
					@DocPrefix = '',      
					@DocNumber = '',  
					@DOCID = @DocIDValue,      
					@UserID = 1,      
					@UserName = N'ADMIN',      
					@LangID = 1,
					@RoleID=1

					DELETE FROM REN_ContractDocMapping WHERE CONTRACTID = @QuotationID  AND DOCID =  @DocIDValue
				end
		END
		
		UPDATE  REN_Quotation      
		SET --[ContractPrefix] = @ContractPrefix,        
		[Date] =  CONVERT(FLOAT,@Date)                
		,[PropertyID] = @PropertyID      
		,[UnitID] = @UnitID 
		,StatusID     =@StatusID
		,[TenantID] = @TenantID      
		,[RentAccID] = @RentRecID      
		,[IncomeAccID] = @IncomeID      
		,[Purpose] = @Purpose      
		,[StartDate] = CONVERT(FLOAT,@StartDate)      
		,[EndDate] = CONVERT(FLOAT,@EndDate)         
		,[TotalAmount] = @TotalAmount      
		,[NonRecurAmount] = @NonRecurAmount      
		,[RecurAmount] = @RecurAmount      
		,[CompanyGUID] = @CompanyGUID      
		,[GUID] = @GUID      
		,[ModifiedBy] = @UserName      
		,[ModifiedDate] =@Dt 
		,[LocationID] = @ContractLocationID      
		,[DivisionID] =@ContractDivisionID      
		,[CurrencyID] =@ContractCurrencyID      
		,[TermsConditions] =@TermsConditions      
		, [SalesmanID] =@SalesmanID    
		,[AccountantID] =@AccountantID    
		,[LandlordID] = @LandlordID    
		,[Narration] = @Narration      
		,BasedOn=@basedon 
		,ExtendTill  =CONVERT(FLOAT,@ExtendTill)
		,WorkFlowID=@Selectedrgt,WorkFlowLevel=@level
		,NoOfUnits=1
		,multiName=@multiName
		,RecurDuration=@RecurDuration
		,ExpectedEndDate=CONVERT(FLOAT,@ExpectedEndDate),GracePeriod=@GracePeriod
		WHERE QuotationID =  @QuotationID      
	END       
   
      
	IF(@ContractXML IS NOT NULL AND @ContractXML<>'')        
	BEGIN        
		SET @XML= @ContractXML          

		DELETE FROM [REN_QuotationParticulars] WHERE QuotationID = @QuotationID        

		INSERT INTO [REN_QuotationParticulars]        
				([QuotationID]        
				,[CCID]        
				,[CCNodeID]        
				,[CreditAccID]        
				,[ChequeNo]        
				,[ChequeDate]        
				,[PayeeBank]        
				,[DebitAccID]   
				,[RentAmount]    
				,[Discount]         
				,[Amount]        
				,[Sno]      
				,[IsRecurr],Narration ,VatPer,VatAmount         
				,Detailsxml,InclChkGen,VatType,TaxCategoryID
				,RecurInvoice,TaxableAmt,Sqft,Rate,LocationID,SPType,DimNodeID,[CreatedBy],[CreatedDate])   
		SELECT @QuotationID , X.value('@CCID','INT'),         
				X.value('@CCNodeID','INT'),          
				X.value('@CreditAccID','INT'),         
				X.value('@ChequeNo','NVARCHAR(200)'),        
				CONVERT(float,X.value('@ChequeDate','Datetime')),        
				X.value('@PayeeBank','nvarchar(500)'),        
				X.value('@DebitAccID','INT'),    
				X.value('@RentAmount','float'),    
				X.value('@Discount','float'),       
				X.value('@Amount','float'),        
				X.value('@SNO','int'),      
				X.value('@IsRecurr','bit'),  X.value('@Narration','nvarchar(max)'), 
				X.value('@VatPer','float'),
				X.value('@VatAmount','float'),    
				convert(nvarchar(max), X.query('XML'))  ,         
				 X.value('@InclChkGen','INT')
				, X.value('@VatType','Nvarchar(50)'),X.value('@TaxCategoryID','INT')
				, X.value('@Recur','BIT'),X.value('@TaxableAmt','float')
				, X.value('@Sqft','float'),X.value('@Rate','float'),        
				X.value('@LocationID','INT'),X.value('@SPType','INT'),X.value('@DimNodeID','INT')
				,@UserName,@Dt 
		FROM @XML.nodes('/ContractXML/Rows/Row') as Data(X)         
	END
  
  
  	declare @tabPart table(id int identity(1,1),NodeID INT,PartXML nvarchar(max))
	insert into @tabPart
	select NodeID,Detailsxml from [REN_QuotationParticulars] with(nolock)        
	where [QuotationID] = @QuotationID and Detailsxml is not null
	
	Delete from REN_ContractParticularsDetail where ContractID=@QuotationID and Costcenterid=@CostCenterID
	
	SELECT @I = 0,@CNT = COUNT(ID) FROM @tabPart      
     
	WHILE(@I < @CNT)      
	BEGIN      
		SET @I =@I+1 
		SELECT @DDXML = PartXML,@ParentID=NodeID   FROM @tabPart WHERE  ID = @I 

		SET @XML= @DDXML 
		if(@DDXML like '%UnitsRow%')
			INSERT INTO  REN_ContractParticularsDetail([ContractID],ParticularNodeID,FromDate,ToDate,Unit,Period,Amount,Rate,CostCenterID,Discount,ActAmount,Distribute,Narration)  
			SELECT @QuotationID,@ParentID,Convert(float,X.value('@FromDate','Datetime')),        
			Convert(float,X.value('@ToDate','Datetime')),        
			X.value('@Unit','INT'),        
			X.value('@Period','INT'),        
			X.value('@Amount','float'),
			ISNULL(X.value('@Rate','float'),0),
			@CostCenterID,
			ISNULL(X.value('@Discount','float'),0),
			ISNULL(X.value('@ActAmount','float'),0),
			X.value('@Distribute','INT'),
			X.value('@Narration','nvarchar(max)')
			FROM @XML.nodes('/XML/UnitsRow/Row') as Data(X) 
		ELSE
			INSERT INTO  REN_ContractParticularsDetail([ContractID],ParticularNodeID,FromDate,ToDate,Unit,Period,Amount,Rate,CostCenterID,Discount,ActAmount,Distribute,Narration)  
			SELECT @QuotationID,@ParentID,Convert(float,X.value('@FromDate','Datetime')),        
			Convert(float,X.value('@ToDate','Datetime')),        
			X.value('@Unit','INT'),        
			X.value('@Period','INT'),        
			X.value('@Amount','float'),
			ISNULL(X.value('@Rate','float'),0),
			@CostCenterID,
			ISNULL(X.value('@Discount','float'),0),
			ISNULL(X.value('@ActAmount','float'),0),
			X.value('@Distribute','INT'),
			X.value('@Narration','nvarchar(max)')
			FROM @XML.nodes('/XML/Row') as Data(X)   
	END

	IF(@PayTermsXML IS NOT NULL AND @PayTermsXML<>'')        
	BEGIN        
		SET @XML= @PayTermsXML          

		DELETE FROM [REN_QuotationPayTerms] WHERE QuotationID = @QuotationID

		INSERT INTO  [REN_QuotationPayTerms]        
		([QuotationID]        
		,[ChequeNo]        
		,[ChequeDate]        
		,[CustomerBank]        
		,[DebitAccID]        
		,[Amount]       
		,[SNO]       
		,[Narration],Period,[CreatedBy],[CreatedDate]    )        

		SELECT @QuotationID  ,        
		X.value('@ChequeNo','NVARCHAR(200)'),        
		Convert(float,X.value('@ChequeDate','Datetime')),        
		X.value('@CustomerBank','nvarchar(500)'),        
		X.value('@DebitAccID','INT'),        
		X.value('@Amount','float'),        
		X.value('@SNO','int'),      
		X.value('@Narration','nvarchar(MAX)'), X.value('@Period','INT')
		,@UserName,@Dt 
		FROM @XML.nodes('/PayTermXML/Rows/Row') as Data(X)          
	END         
 
 
	set @UpdateSql='update COM_CCCCDATA        
	SET '+@CustomCostCenterFieldsQuery+'[ModifiedBy] ='''+ @UserName+''',[ModifiedDate] =' + convert(nvarchar,@Dt) +' WHERE NodeID =        
	'+convert(nvarchar,@QuotationID) + ' AND CostCenterID =' +convert(nvarchar,@CostCenterID)      

	exec(@UpdateSql)  

	delete from REN_Quotation where RefQuotation=@QuotationID
	if(@MultiUnitIds is not null and @MultiUnitIds<>'' )
	BEGIN         
		
		INSERT INTO  REN_Quotation ([Prefix],SNO,[Date],[Number] ,StatusID             
		,[PropertyID],[UnitID],[TenantID],[RentAccID],[IncomeAccID],[Purpose]        
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
		,[LocationID]      
		,[DivisionID]      
		,[CurrencyID]        
		,[TermsConditions]    
		,[SalesmanID]    
		,[AccountantID]      
		,[LandlordID]    
		,Narration,BasedOn,CostCenterID,ExtendTill
		,WorkFlowID,WorkFlowLevel,NoOfUnits,RefQuotation,multiName)
		select [Prefix],SNO,[Date],[Number] ,StatusID             
		,[PropertyID],b.[UnitID],[TenantID],[RentAccID],[IncomeAccID],[Purpose]        
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
		,[LocationID]      
		,[DivisionID]      
		,[CurrencyID]        
		,[TermsConditions]    
		,[SalesmanID]    
		,[AccountantID]      
		,[LandlordID]    
		,Narration,BasedOn,CostCenterID,ExtendTill
		,WorkFlowID,WorkFlowLevel,NoOfUnits,@QuotationID,@multiName
		FROM REN_Quotation a with(nolock),@ChildUnits b
		where QuotationID=@QuotationID and b.unitid<>@UnitID
			
		UPDATE REN_Quotation SET NoOfUnits=(SELECT COUNT(*) FROM @ChildUnits) WHERE QuotationID=@QuotationID
	END
	
	DECLARE @AuditTrial BIT        
	SET @AuditTrial=0        
	SELECT @AuditTrial= CONVERT(BIT,VALUE)  FROM [COM_COSTCENTERPreferences] with(nolock)     
	WHERE CostCenterID=95  AND NAME='AllowAudit'   
	IF (@AuditTrial=1)      
	BEGIN 	
		--INSERT INTO HISTROY   
		EXEC [spCOM_SaveHistory]  
			@CostCenterID =@CostCenterID,    
			@NodeID =@QuotationID,
			@HistoryStatus =@AUDITSTATUS,
			@UserName=@UserName   
	END
			
	if(@CostCenterID=129)
	BEGIN
		declare @tblExisting TABLE (ID int identity(1,1),DOCID INT)           		
		declare @DocPrefix nvarchar(200)
		insert into @tblExisting     
		select DOCID from  [REN_ContractDocMapping]    
		where contractid=@QuotationID and Doctype =4 AND ContractCCID= 129    

		select @tblExistingCNT=COUNT(id) from @tblExisting     
	    set @CNT=0
		if(@PostPDRecieptXML<>'')
		BEGIN
			SET @XML =@PostPDRecieptXML       
			declare  @tblListPDR TABLE(ID int identity(1,1),TRANSXML NVARCHAR(MAX),Documents NVARCHAR(200) )          
			INSERT INTO @tblListPDR        
			SELECT  CONVERT(NVARCHAR(MAX),  X.query('DocumentXML')) , CONVERT(NVARCHAR(200),X.query('Documents'))                  
			from @XML.nodes('/PDR/ROWS') as Data(X)        

			SELECT @CNT = COUNT(ID) FROM @tblListPDR      
			SET @I = 0      
			WHILE(@I < @CNT)      
			BEGIN      
				SET @I =@I+1  
				SELECT @AA = TRANSXML,@DocXML = Documents  FROM @tblListPDR WHERE  ID = @I      

				SELECT   @AccValue =  X.value ('@DD', 'NVARCHAR(100)' )
				from @DocXML.nodes('/Documents') as Data(X)      

				set @DocIDValue=0    
				SELECT @DocIDValue = isnull(DOCID,0) FROM @tblExisting WHERE  ID = @I     
				
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
				
				IF(@DocIDValue>0)    					    
					SELECT  @DELETECCID = COSTCENTERID FROM dbo.ACC_DocDetails WITH(nolock)       
					WHERE DOCID = @DocIDValue    
				
				if(@DocIDValue >0 AND @DELETECCID <> 0 and @RcptCCID<>@DELETECCID)    
				begin    
					EXEC @return_value = [dbo].[spDOC_DeleteAccDocument]      
					@CostCenterID = @DELETECCID,      
					@DocPrefix = '',      
					@DocNumber = '',  
					@DOCID = @DocIDValue,      
					@UserID = 1,      
					@UserName = N'ADMIN',      
					@LangID = 1,
					@RoleID=1

					DELETE FROM REN_ContractDocMapping WHERE CONTRACTID = @QuotationID  AND DOCID =  @DocIDValue and DOCTYPE =4 AND ContractCCID = 129    

					set @DocIDValue=0       
				end 
				
				set @DocPrefix=''
				EXEC [sp_GetDocPrefix] '',@Date,@RcptCCID,@DocPrefix output,@QuotationID,0,0,129

				EXEC @return_value = [dbo].[spDOC_SetTempAccDocument]      
				   @CostCenterID = @RcptCCID,      
				   @DocID = @DocIDValue,      
				   @DocPrefix =@DocPrefix,      
				   @DocNumber =1,      
				   @DocDate = @Date,     
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
  
				IF(@DocIDValue = 0 )    
				BEGIN    
					INSERT INTO  [REN_ContractDocMapping] ([ContractID],[Type],[Sno],DocID,CostcenterID,IsAccDoc,DocType,ContractCCID)      
					values(@QuotationID,4,@I,@return_value,@RcptCCID,1,4,129)        
				END 
				ELSE
				BEGIN
					update [REN_ContractDocMapping] set Sno=@i
					where ContractCCID=129 and ContractID=@QuotationID and DocID=@DocIDValue
				END
			end
		END
		
		IF(@tblExistingCNT > @CNT)    
		BEGIN           
			WHILE(@CNT <  @tblExistingCNT)    
			BEGIN    
				SET @CNT = @CNT+1    
				SELECT @DocIDValue = DOCID FROM @tblExisting WHERE ID = @CNT    

				SELECT  @DELETECCID = COSTCENTERID FROM dbo.ACC_DocDetails WITH(nolock)       
				WHERE DOCID = @DocIDValue    

				EXEC @return_value = [dbo].[spDOC_DeleteAccDocument]      
				@CostCenterID = @DELETECCID,      
				@DocPrefix = '',      
				@DocNumber = '',  
				@DOCID = @DocIDValue,      
				@UserID = 1,      
				@UserName = N'ADMIN',      
				@LangID = 1,
				@RoleID=1

				DELETE FROM REN_ContractDocMapping WHERE CONTRACTID = @QuotationID  AND DOCID =  @DocIDValue and DOCTYPE =4 AND ContractCCID = 129    
			END    
		END   
		
		if(@WID>0)
		BEGIN	   
			INSERT INTO COM_Approvals(CCID,CCNODEID,StatusID,[Date],Remarks,UserID,CompanyGUID,[GUID],CreatedBy,CreatedDate,WorkFlowLevel,DocDetID)      
			VALUES(@COSTCENTERID,@QuotationID,@StatusID,CONVERT(FLOAT,getdate()),'',@UserID,@CompanyGUID,newid(),@UserName,CONVERT(FLOAT,getdate()),isnull(@level,0),0)
	 
			if(@StatusID not in(467,468))
			BEGIN
				update INV_DOCDETAILS
				set StatusID=371
				FROM INV_DOCDETAILS a WITH(NOLOCK)
				join REN_CONTRACTDOCMAPPING b WITH(NOLOCK) on a.DocID=b.DocID 
				WHERE CONTRACTID = @QuotationID  AND ISACCDOC = 0 and RefNodeID = @QuotationID    
				AND ContractCCID = 129    
						
				update ACC_DOCDETAILS
				set StatusID=371
				FROM ACC_DOCDETAILS b WITH(NOLOCK)
				join INV_DOCDETAILS a WITH(NOLOCK) on b.INVDOCDETAILSID=a.INVDOCDETAILSID
				join REN_CONTRACTDOCMAPPING c WITH(NOLOCK) on a.DocID=b.DocID 
				WHERE CONTRACTID = @QuotationID  AND ISACCDOC = 0 and a.RefNodeid = @QuotationID    
				AND ContractCCID = 129    
				
				update ACC_DOCDETAILS
				set StatusID=371
				FROM ACC_DOCDETAILS a WITH(NOLOCK)
				join REN_CONTRACTDOCMAPPING b WITH(NOLOCK) on a.DocID=b.DocID 
				WHERE CONTRACTID = @QuotationID AND ISACCDOC = 1  and RefNodeID = @QuotationID
				AND ContractCCID = 129    
			END	
		END	 
	END
	
	--Inserts Multiple Notes      
	IF (@NotesXML IS NOT NULL AND @NotesXML <> '')      
	BEGIN      
		SET @XML=@NotesXML      

		--If Action is NEW then insert new Notes      
		INSERT INTO COM_Notes(FeatureID,CostCenterID,FeaturePK,Note,         
		GUID,CreatedBy,CreatedDate)      
		SELECT @CostCenterID,@CostCenterID,@QuotationID,Replace(X.value('@Note','NVARCHAR(MAX)'),'@~',''),  
		newid(),@UserName,@Dt      
		FROM @XML.nodes('/NotesXML/Row') as Data(X)      
		WHERE X.value('@Action','NVARCHAR(10)')='NEW'      

		--If Action is MODIFY then update Notes      
		UPDATE COM_Notes      
		SET Note=Replace(X.value('@Note','NVARCHAR(MAX)'),'@~',''),  
		GUID=newid(),      
		ModifiedBy=@UserName,      
		ModifiedDate=@Dt      
		FROM COM_Notes C WITH(nolock)      
		INNER JOIN @XML.nodes('/NotesXML/Row') as Data(X)        
		ON convert(INT,X.value('@NoteID','INT'))=C.NoteID      
		WHERE X.value('@Action','NVARCHAR(500)')='MODIFY'      

		--If Action is DELETE then delete Notes      
		DELETE FROM COM_Notes      
		WHERE NoteID IN(SELECT X.value('@NoteID','INT')      
		FROM @XML.nodes('/NotesXML/Row') as Data(X)      
		WHERE X.value('@Action','NVARCHAR(10)')='DELETE')      

	END      
      
	--Inserts Multiple Attachments      
	IF (@AttachmentsXML IS NOT NULL AND @AttachmentsXML <> '')      
			exec [spCOM_SetAttachments] @QuotationID,@CostCenterID,@AttachmentsXML,@UserName,@Dt     

             
	if(@CustomFieldsQuery<>'')
	BEGIN
		set @CustomFieldsQuery= rtrim(@CustomFieldsQuery)
		set @CustomFieldsQuery=substring(@CustomFieldsQuery,0,len(@CustomFieldsQuery)- charindex(',',reverse(@CustomFieldsQuery))+1)

		set @UpdateSql='update [REN_QuotationExtended]      
		SET '+@CustomFieldsQuery+' WHERE QuotationID='+convert(nvarchar,@QuotationID)             
		exec(@UpdateSql)      
	END     
        
COMMIT TRANSACTION
--rollback TRANSACTION
         
SELECT ErrorMessage,ErrorNumber FROM COM_ErrorMessages WITH(nolock)         
WHERE ErrorNumber=100 AND LanguageID=@LangID        
SET NOCOUNT OFF;         
         
RETURN @QuotationID            
END TRY            
BEGIN CATCH      
       if(@return_value=-999)
		 return   -999    
IF ERROR_NUMBER()=50000        
 BEGIN        
 SELECT ErrorMessage,ErrorNumber FROM COM_ErrorMessages WITH(nolock)         
  WHERE ErrorNumber=ERROR_MESSAGE() AND LanguageID=@LangID        
 END        
 ELSE IF ERROR_NUMBER()=547        
 BEGIN        
  SELECT ErrorMessage, ERROR_MESSAGE() AS ServerMessage,ERROR_NUMBER() as ErrorNumber, ERROR_PROCEDURE()as ProcedureName, ERROR_LINE() AS ErrorLine FROM        
COM_ErrorMessages WITH(nolock)        
  WHERE ErrorNumber=-110 AND LanguageID=@LangID        
 END        
 ELSE IF ERROR_NUMBER()=2627        
 BEGIN        
  SELECT ErrorMessage, ERROR_MESSAGE() AS ServerMessage,ERROR_NUMBER() as ErrorNumber, ERROR_PROCEDURE()as ProcedureName, ERROR_LINE() AS ErrorLine FROM        
COM_ErrorMessages WITH(nolock)        
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

USE PACT2C222
GO
SET ANSI_NULLS, QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spDOC_SetTempBulkInvDoc]
	@CostCenterID [int],
	@DocID [bigint],
	@DocPrefix [nvarchar](50),
	@DocNumber [nvarchar](500),
	@DocDate [datetime],
	@DueDate [datetime] = NULL,
	@BillNo [nvarchar](500),
	@AccXML [nvarchar](max),
	@StatXML [nvarchar](max),
	@NumXML [nvarchar](max),
	@TextXML [nvarchar](max),
	@CCXML [nvarchar](max),
	@ExtraXML [nvarchar](max),
	@DocExtraXML [nvarchar](max),
	@BillWiseXML [nvarchar](max),
	@NotesXML [nvarchar](max),
	@AttachmentsXML [nvarchar](max),
	@ActivityXML [nvarchar](max),
	@IsImport [bit],
	@LocationID [bigint],
	@DivisionID [bigint],
	@WID [int],
	@RoleID [int],
	@DocAddress [nvarchar](max) = null,
	@RefCCID [bigint],
	@RefNodeid [bigint],
	@CompanyGUID [nvarchar](50),
	@UserName [nvarchar](50),
	@UserID [int] = 0,
	@LangID [int] = 1,
	@IsOffline [bit] = 0
WITH ENCRYPTION, EXECUTE AS CALLER
AS
BEGIN TRANSACTION      
BEGIN TRY        
SET NOCOUNT ON;  

	--Declaration Section      
	DECLARE @QUERYTEST NVARCHAR(100),@TYPE NVARCHAR(100),@Guid nvarchar(50),@ISSerial  BIT,@IsBatChes BIT,@IsDynamic BIT,@IStempINFO BIT,@UNIQUECNT int
	DECLARE  @tempDOc BIGINT,@HasAccess int,@ACCOUNT1 BIGINT,@ACCOUNT2 BIGINT,@ACCOUNT1Name nvarchar(500),@ACCOUNT2Name nvarchar(500)      
	DECLARE @Dt float,@XML XML,@DocumentType INT,@DocAbbr nvarchar(50),@ProductName nvarchar(500),@ProductID bigint      
	DECLARE @InvDocDetailsID BIGINT,@I int,@Cnt int,@SQL NVARCHAR(MAX),@VoucherNo NVARCHAR(500),@ProductType int,@VoucherType int,@BILLDate FLOAT      
	DECLARE @AccountsXML XML,@VersionNo INT ,@vno nvarchar(100)   
	DECLARE @Length int,@temp varchar(100),@t int ,@DocOrder int,@IsRevision BIT  ,@ind int,@indcnt int,@SECTIONID INT,@holseq int
	DECLARE @return_value int,@TEMPxml NVARCHAR(max),@PrefValue NVARCHAR(500),@LinkedID bigint,@oldStatus int,@ImpDocID BIGINT,@ActXML xml
	declare @level int,@maxLevel int,@StatusID int,@ReviseReason  nvarchar(max) ,@Iscode INT,@QtyAdjustments XML,@BinsXML XML,@TEmpWid BIGINT,@DeprXML nvarchar(max)
	declare @TotLinkedQty float,@CheckHold bit,@AppRejDate datetime,@Remarks nvarchar(max),@Series int,@prefixCCID bigint,@DUP_VoucherNo NVARCHAR(max)   
	declare @DetailIDs nvarchar(max),@HistoryStatus nvarchar(50),@DUPLICATECODE  NVARCHAR(MAX),@IsLockedPosting BIT,@BinDimesion bigint,@BinDimesionNodeID bigint
	DECLARE  @PrefValueDoc BIT , @hideBillNo BIT   ,@QtyFin FLOAT , @QthChld FLOAT,@Dimesion bigint,@DimesionNodeID bigint,@cctablename nvarchar(50)     
	DECLARE @ConsolidatedBatches nvarchar(50),@Tot float,@BatchID Bigint,@OldBatchID BIGINT,@NID BIGINT,@DLockCC BIGINT,@DLockCCValues NVARCHAR(max),@LockCC BIGINT,@LockCCValues NVARCHAR(max)
	declare @loc int,@div int,@dim int,@IsQtyIgnored BIT,@WHERE nvarchar(max),@tempProd bigint,@CCGuid nvarchar(100),@LineWiseApproval bit,@sysinfo nvarchar(max)
	declare @ddxml nvarchar(max),@bxml nvarchar(max),@ddID bigint,@Prefix nvarchar(200),@AUTOCCID bigint,@DetIDS nvarchar(max),@CCStatusID int,@TempDocDate DATETIME,@tempLevel BIGINT   
	DECLARE @EMPYEAR NVARCHAR(20),@EMPCODE INT,@DocGrade INT,@RefBatchID BIGINT,@batchCol nvarchar(100),@varxml xml
	DECLARE @EMPID INT,@LEAVETYPE INT,@FromDate DATETIME,@TDate DATETIME,@DocLoc INT,@actDocDate INT,@AssignLeaves float,@LeaveYear varchar(5)
	
	declare @Codetemp table (prefix nvarchar(100),number bigint, suffix nvarchar(100), code nvarchar(200),IsManualCode bit)
	declare @tblBILL TABLE(ID int identity(1,1),AccountID BIGINT, Amount FLOAT, DocNo NVARCHAR(500))        
	declare @caseTab table(id int identity(1,1),CaseID BIGINT,StartDate DATETIME,StartTime NVARCHAR(20),EndDate  DATETIME,EndTime  NVARCHAR(20),AssignedTo BIGINT,Remarks NVARCHAR(MAX),SERIALNUMBER NVARCHAR(MAX))
	declare @CustomerName nvarchar(500),@CaseNumber nvarchar(500),@SERIALNUMBER nvarchar(500),@CaseID bigint,@Assignedto bigint,@CaseDate float
	declare @LockCrAcc bigint,@LockDrAcc bigint,@AccLockDate DATETIME,@AccType nvarchar(max),@CAccountTypeID bigint,@DAccountTypeID bigint,@IsUniqueDoc BIT,@UniqueDefn NVARCHAR(MAX),@UniqueQuery NVARCHAR(MAX),@UniqueCount INT,@SYSCOL NVARCHAR(50)
	declare @TblUnique TABLE(ID INT IDENTITY(1,1),UsedColumn nvarchar(100))
		
	--Loading Global Preferences
	DECLARE @TblPref AS TABLE(Name nvarchar(100),Value nvarchar(max),IsGlobal BIT)
	INSERT INTO @TblPref
	SELECT Name,Value,1 FROM ADM_GlobalPreferences with(nolock)
	WHERE Name IN ('LockTransactionAccountType','Lock Data Between','LockCostCenterNodes','LockCostCenters'
	,'ShowProdCodeinErrMsg','NetFld','DimensionwiseBins','ConsiderHoldAndReserveAsIssued','ConsiderExpectedAsReceived','DW Batches','LW Batches','Maintain Dimensionwise Batches','DoNotAllowFutureDateDays','NoFuturetransaction','PosCoupons','EnableLocationWise','Location Stock','Check for -Ve Stock','NegatvieSotckSysDate','DontSaveReOrderLevelExceeds','Maintain Dimensionwise stock','Dontallowreceiptafterissue'
	,'LoyaltyOn','GBudgetUnapprove','GNegativeUnapprove','DocDateasPostedDate','UseDimWiseLock','Nobackdatedtransaction','POSItemCodeDimension','EnableSerialProducts','EnableBatchProducts','EnableDynamicProducts','EnableDivisionWise','Division Stock','DimensionwiseCurrency','BaseCurrency','DecimalsinAmount','DoNotAllowPastDateDays','NoPasttransaction')
	 
	--Loading Document Preferences	
	INSERT INTO @TblPref
	SELECT PrefName,PrefValue,0 FROM COM_DocumentPreferences with(nolock)
	WHERE CostCenterID=@CostCenterID and PrefName IN ('DocumentLinkDimension','AutoCode','BillwisePosting','Lock Data Between','EnableAssetSerialNo'
	,'DocwiseSNo','Paypercent','ValueType','onsystemdate','Billlanding','SameserialNo','Enabletolerance','DontSaveCompleteLinked','DisableQtyCheck','AllowMultipleLinking','VendorBasedBillNo','Hide_Billno','DuplicateProductClubBins','LockCostCenterNodes','LockCostCenters'
	,'VatAdvanceDoc','PostAsset','DimTransferSrc','IsBudgetDocument','UseQtyAdjustment','UpdateDueDate','UpdateLinkQty','UpdateLinkValue','UpdateJustReference','ExecReq','LinkForward','AuditTrial','EnableRevision','Autopostdocument','OverrideLock','Checkallproducts','ShortageDOC','ExcessDOC'
	,'IsBudgetDocument','EnablePromotions','samebatchtoall','DocDateasPostedDate','GenerateSeq','EnableUniqueDocument','BackTrack','AssignVendors','DoNotEmailOrSMSUn-ApprovedDocuments','DumpStockCodes','DonotupdateInventory','DonotupdateAccounts','TempInfo')
	
	set @batchCol=''
	if exists(select Value from @TblPref where IsGlobal=0 and Name='samebatchtoall' and Value='true')
	BEGIN
		select @batchCol=SysColumnName from ADM_CostCenterDef
		where CostCenterID=@CostCenterID and ColumnCostCenterID=16 and SysColumnName like 'dcalpha%'
	END
	
	 if(@DocID=0 and exists(select value from @TblPref where IsGlobal=0 and Name='onsystemdate' and Value='true'))
			set @DocDate=CONVERT(datetime,floor(convert(float,getdate())))
	 
	 set @PrefValue=''
	 select @PrefValue=Value from @TblPref where IsGlobal=1 and  Name='NoFuturetransaction'    
	 if(@PrefValue='true')
	 BEGIN
		set @ind=0
		select @ind=isnull(Value,0) from @TblPref where IsGlobal=1 and  Name='DoNotAllowFutureDateDays'
		and  isnumeric(Value)=1

		if(CONVERT(float,@DocDate)>FLOOR(CONVERT(float,GETDATE()))+@ind)
			RAISERROR('-530',16,1)  
	 END
	 
	 set @PrefValue=''
	 select @PrefValue=Value from @TblPref where IsGlobal=1 and  Name='NoPasttransaction'    
	 if(@PrefValue='true')
	 BEGIN
		set @ind=0
		select @ind=isnull(Value,0) from @TblPref where IsGlobal=1 and  Name='DoNotAllowPastDateDays'
		and  isnumeric(Value)=1
		
		if(CONVERT(float,@DocDate)<FLOOR(CONVERT(float,GETDATE()))-@ind)
			RAISERROR('-531',16,1) 
	 END
	 
	 set @PrefValue=''
	 select @PrefValue=Value from @TblPref where IsGlobal=1 and  Name='Nobackdatedtransaction'    
	 if(@PrefValue='true' and @DocID=0)
	 BEGIN
		if exists(select CostCenterID from INV_DocDetails WITH(NOLOCK) where CostCenterID=@CostCenterID and DocDate>CONVERT(float,@DocDate))
			RAISERROR('-531',16,1)  
	 END
	 
	 SET @HasAccess=dbo.fnCOM_HasAccess(@RoleID,@CostCenterID,673)
	 if(@HasAccess=1)
	 BEGIN
		SELECT @tempProd=FeatureActionID FROM ADM_FeatureAction WITH(nolock)
		WHERE  FeatureID=@CostCenterID AND FeatureActionTypeID=673
		
		set @ind=0
		SELECT @ind=CONVERT(int,Description) FROM ADM_FeatureActionRoleMap WITH(nolock)
		WHERE RoleID=@RoleID AND FeatureActionID=@tempProd and ISNUMERIC(Description)=1

		if(CONVERT(float,@DocDate)>FLOOR(CONVERT(float,GETDATE()))+@ind)
			RAISERROR('-530',16,1)  
	 END

	 SET @HasAccess=dbo.fnCOM_HasAccess(@RoleID,@CostCenterID,672)
	 if(@HasAccess=1)
	 BEGIN
		SELECT @tempProd=FeatureActionID FROM ADM_FeatureAction WITH(nolock)
		WHERE  FeatureID=@CostCenterID AND FeatureActionTypeID=672
		
		set @ind=0
		SELECT @ind=CONVERT(int,Description) FROM ADM_FeatureActionRoleMap WITH(nolock)
		WHERE RoleID=@RoleID AND FeatureActionID=@tempProd and ISNUMERIC(Description)=1

		if(CONVERT(float,@DocDate)<FLOOR(CONVERT(float,GETDATE()))-@ind)
			RAISERROR('-531',16,1) 
	 END

	 
	 set @LineWiseApproval=0
	 set @IsLockedPosting=0	
	 set @tempProd=0
	 select @PrefValue=Value from com_costcenterpreferences WITH(NOLOCK)   
	 where costcenterid=3 and name='TempPartProduct' and isnumeric(Value)=1 

	 if(@PrefValue is not null and @PrefValue<>'' and @PrefValue<>'0')
		set @tempProd=convert(BIGINT,@PrefValue)
	 
	SELECT @IsUniqueDoc=(case when Value='True' then 1 else 0 end) FROM @TblPref where IsGlobal=0 and  Name='EnableUniqueDocument'
	SELECT @ISSerial=(case when Value='True' then 1 else 0 end) FROM @TblPref where IsGlobal=1 and  Name='EnableSerialProducts'
	SELECT @IsBatChes=(case when Value='True' then 1 else 0 end) FROM @TblPref where IsGlobal=1 and  Name='EnableBatchProducts'
	SELECT @IsDynamic=(case when Value='True' then 1 else 0 end) FROM @TblPref where IsGlobal=1 and  Name='EnableDynamicProducts'
	SELECT @IStempINFO=(case when Value='True' then 1 else 0 end) FROM @TblPref where IsGlobal=0 and  Name='TempInfo'

	if (dbo.fnCOM_HasAccess(@RoleID,43,193)=0 and exists(select Value from @TblPref where IsGlobal=0 and  Name='DonotupdateAccounts' and Value='false'))
	BEGIN
		SELECT @AccType=Value FROM @TblPref WHERE Name='LockTransactionAccountType'  
	 
		declare @table table(TypeID nvarchar(50))  
		insert into @table  
		exec SPSplitString @AccType,','  

		declare @AcctypesTable table (ID bigint identity(1,1),AccountTypeID bigint,AccountDate datetime)  
		insert into @AcctypesTable   
		select reverse(parsename(replace(reverse(TypeID),'~','.'),1)) as [AccountTypeID],  
		 convert(datetime,reverse(parsename(replace(reverse(TypeID),'~','.'),2))) as [Date] from @table  
    END
     
	select @PrefValue=''	
	select @PrefValue=Value from @TblPref where IsGlobal=0 and  Name='DocumentLinkDimension'    

	if(@PrefValue is not null and @PrefValue<>'' and ISNUMERIC(@PrefValue)=1)
	begin
		set @Dimesion=0
		begin try
			select @Dimesion=convert(bigint,@PrefValue)
		end try
		begin catch
			set @Dimesion=0
		end catch
	END
	
	if(@DocNumber is null or @DocNumber='')    
		set @DocNumber='1'    

	SELECT @Series=Series,@DocumentType=DocumentType,@DocAbbr=DocumentAbbr,@DocOrder=DocOrder
		,@UniqueDefn=UniqueDocumentDefn,@UniqueQuery=UniqueDocumentQuery,@CCGuid=GUID
	FROM ADM_DocumentTypes WITH(NOLOCK) WHERE CostCenterID=@CostCenterID   
	
    if @IsUniqueDoc=1
    begin
		set @XML=@UniqueDefn
		declare @UsedColumns nvarchar(max)
		select @UsedColumns=@XML.value('(XML/UsedColumns)[1]','NVARCHAR(MAX)')
		
		INSERT INTO @TblUnique
		exec SPSplitString @UsedColumns,','
				
		select @UniqueCount=COUNT(*) from @TblUnique
    end

	SET @Dt=convert(float,getdate())--Setting Current Date
	set @StatusID=369    
	if(@DocumentType=31)
		set @StatusID=443
	
	SET @XML=@ActivityXML
	set @ActXML=@ActivityXML
	set @PrefValue=''
	
	SELECT @Guid=X.value('@CCGuid','nvarchar(100)'),@PrefValue=X.value('@Guid','nvarchar(100)'),@ImpDocID=X.value('@ImpDocID','BIGINT')
	,@bxml=X.value('@UniquNo','nvarchar(max)'),@DUPLICATECODE=X.value('@CheckStock','nvarchar(max)')    
	from @XML.nodes('/XML') as Data(X)
	
	--Pos Session Check
	declare @PosSessionID bigint
	SELECT @PosSessionID=X.value('@PosSessionID','bigint')  from @ActXML.nodes('/XML') as Data(X)
	if(@PosSessionID is not null and not exists(select POSLoginHistoryID from POS_loginHistory with(nolock) where POSLoginHistoryID=@PosSessionID and IsUserClose=0))
		RAISERROR('-152',16,1)	
	
	if(@Guid!=@CCGuid)
    BEGIN
		RAISERROR('-513',16,1)  
    END
    
	if(@DocID=0)
		set @HistoryStatus='Add'
	else
	BEGIN
		set @HistoryStatus='Update'
		
		SELECT  top 1 @oldStatus=StatusID,@TEmpWid=WorkflowID,@tempLevel=WorkFlowLevel,@VoucherNo=VoucherNo,@DocNumber=DocNumber,@DocPrefix=DocPrefix,
		@TempDocDate=DocDate,@VersionNo=VersionNo
		FROM INV_DocDetails WITH(NOLOCK) WHERE DocID=@DocID
		
		select @CCGuid=GUID from COM_DocID WITH(NOLOCK) WHERE ID=@DocID
		
		if(@PrefValue <>'' and @CCGuid!=@PrefValue)
		BEGIN
			RAISERROR('-101',16,1)  
		END
		
		set @Guid=NEWID()
		
		update COM_DocID
		set GUID= @guid,SysInfo =@SysInfo 
		where ID=@DocID
		
		update COM_DocID
		set LockedBY=null
		where ID=@DocID
		
	END
	
	--do not check -ve stock
	if(@DUPLICATECODE is not null and @DUPLICATECODE='false')
		delete from @TblPref where IsGlobal=1 and Name='Check for -Ve Stock'
	
	if(@WID is not null and @WID>0)    
	begin
		if(@DocID>0 and @tempLevel is not null and @oldStatus not in (369,372))
		BEGIN
		
			SELECT @level=LevelID FROM [COM_WorkFlow]   WITH(NOLOCK)   
			where WorkFlowID=@WID and UserID =@UserID and LevelID>=@tempLevel
			order by LevelID desc
			
			if(@level is null)  
				SELECT @level=LevelID FROM [COM_WorkFlow]  WITH(NOLOCK)    
				where WorkFlowID=@WID and RoleID =@RoleID and LevelID>=@tempLevel
				order by LevelID desc
				
			if(@level is null)       
				SELECT @level=LevelID FROM [COM_WorkFlow] W WITH(NOLOCK)
				JOIN COM_Groups G WITH(NOLOCK) on w.GroupID=g.GID     
				where g.UserID=@UserID and WorkFlowID=@WID and LevelID>=@tempLevel
				order by LevelID desc
				
			if(@level is null)  
				SELECT @level=LevelID FROM [COM_WorkFlow] W WITH(NOLOCK)
				JOIN COM_Groups G WITH(NOLOCK) on w.GroupID=g.GID     
				where g.RoleID =@RoleID and WorkFlowID=@WID and LevelID>=@tempLevel
				order by LevelID desc
		
		END
		
		if(@DocID=0 or @level is null or @oldStatus in (369,372))
		BEGIN
			
			SELECT @level=LevelID FROM [COM_WorkFlow]   WITH(NOLOCK)   
			where WorkFlowID=@WID and UserID =@UserID
			order by LevelID desc
			
			if(@level is null)  
				SELECT @level=LevelID FROM [COM_WorkFlow]  WITH(NOLOCK)    
				where WorkFlowID=@WID and RoleID =@RoleID
				order by LevelID desc
				
			if(@level is null)       
				SELECT @level=LevelID FROM [COM_WorkFlow] W WITH(NOLOCK)
				JOIN COM_Groups G WITH(NOLOCK) on w.GroupID=g.GID     
				where g.UserID=@UserID and WorkFlowID=@WID
				order by LevelID desc
				
			if(@level is null)  
				SELECT @level=LevelID FROM [COM_WorkFlow] W WITH(NOLOCK)
				JOIN COM_Groups G WITH(NOLOCK) on w.GroupID=g.GID     
				where g.RoleID =@RoleID and WorkFlowID=@WID
				order by LevelID desc
		END	
			
		select @maxLevel=max(a.LevelID) from COM_WorkFlow  a WITH(NOLOCK) 
		left join COM_WorkFlowDef b with(nolock) on a.WorkFlowID=b.WorkFlowID and IsEnabled=0 and a.LevelID=b.LevelID and CostCenterID=@CostCenterID		
		where a.WorkFlowID=@WID and b.WorkFlowID is null

		if(@level is not null and  @maxLevel is not null and @maxLevel>@level)    
		begin    
			SET @XML=@ActivityXML

			SELECT @AppRejDate=X.value('@AppRejDate','Datetime')   
			from @XML.nodes('/XML') as Data(X)    

			if(@AppRejDate is not null)
				set @StatusID=441
			else	
				set @StatusID=371    
		end     
	end    

  
	
	if(@DocumentType=1 or @DocumentType=39 or @DocumentType=27 or @DocumentType=26 or @DocumentType=25 or @DocumentType=2  or @DocumentType=34 or @DocumentType=6 or @DocumentType=3 or @DocumentType=4 or @DocumentType=13)      
		set @VoucherType=1
	else if(@DocumentType=11 or @DocumentType=38 or @DocumentType=7 or @DocumentType=9 or @DocumentType=24 or @DocumentType=33 or @DocumentType=10 or @DocumentType=8 or @DocumentType=12)      
		set @VoucherType=-1      
	else      
		set @VoucherType=0      
	

	
	set @PrefValue =null
	select @PrefValue=Value from @TblPref where IsGlobal=1 and Name='Check for -Ve Stock'    

	if((@PrefValue is not null and @PrefValue='true' and (@VoucherType=-1 or @DocumentType=30 or @DocumentType=5) ) or @DocumentType=31)
	BEGIN
		set @loc=0
		set @div=0
		set @dim=0
		
		set @PrefValue='' 
		select @PrefValue= Value from @TblPref where IsGlobal=1 and Name='EnableLocationWise'        
		if(@PrefValue='True')
		begin         
			set @PrefValue=''      
			select @PrefValue= Value from @TblPref where IsGlobal=1 and Name='Location Stock'        
			if(@PrefValue='True')      
			begin      
				set @loc=1
			end       
		end   
		
		set @PrefValue='' 
		select @PrefValue= Value from @TblPref where IsGlobal=1 and Name='EnableDivisionWise'        
		if(@PrefValue='True')
		begin         
			set @PrefValue=''      
			select @PrefValue= Value from @TblPref where IsGlobal=1 and Name='Division Stock'        
			if(@PrefValue='True')      
			begin 
				set @div=1			  
			end       
		end  	     
	           
		set @PrefValue=''      
		select @PrefValue= isnull(Value,'') from @TblPref where IsGlobal=1 and Name='Maintain Dimensionwise stock'        

		if(@PrefValue is not null and @PrefValue<>'' and convert(bigint,@PrefValue)>0)        
		begin 					 
			if(convert(bigint,@PrefValue)=50001)
				set @dim=1
			else if(convert(bigint,@PrefValue)=50002)
				set @dim=2
			else if(convert(bigint,@PrefValue)>50002)			
				set @dim=convert(bigint,@PrefValue)-50000 
		end 
	END	


	SET @XML=@ActivityXML   

	set @IsRevision=0
	set @CheckHold=0      
    set @CCStatusID=0  
	SELECT @IsRevision=X.value('@IsRevision','BIT')  , @ReviseReason=X.value('@ReviseReason','NVARCHAR(MAX)') 
		   ,@AppRejDate=X.value('@AppRejDate','DateTime'),@CheckHold=X.value('@HoldCheck','BIT'),@DetailIDs=X.value('@DetailIds','nvarchar(max)'),@PrefValue=X.value('@status','nvarchar(100)')  
		  ,@CCStatusID=X.value('@SaveUnapproved','int'),@sysinfo=X.value('@SysInfo','nvarchar(max)'),@LineWiseApproval=isnull(X.value('@LineWiseApproval','BIT'),0)
	from @XML.nodes('/XML') as Data(X)   
    
    
    if(@CCStatusID=1)--budget crossed save as unapproved
		set @StatusID=371 
    
    if exists(select Value from @TblPref where IsGlobal=1 and  Name='UseDimWiseLock' and Value ='true')
	BEGIN
		set @WHERE=''
		set @DUPLICATECODE=''
		select @WHERE=isnull(X.value('@LockDims','nvarchar(max)'),''),@DUPLICATECODE=isnull(X.value('@LockDimsjoin','nvarchar(max)'),'')
		from @XML.nodes('/XML') as Data(X)    		         
		if(@WHERE<>'')
		BEGIN
			set @SQL=' if exists(select FromDate from ADM_DimensionWiseLockData c WITH(NOLOCK) '+@DUPLICATECODE+'
			where '+convert(nvarchar,CONVERT(float,@DocDate))+' between FromDate and ToDate and c.isEnable=1 '+@WHERE
			+') RAISERROR(''-125'',16,1) '
			print @SQL
			exec(@SQL)
		END
	END
    
    if exists( select X.value('@LockedPosting','BIT') from @XML.nodes('/XML') as Data(X)  
			where X.value('@LockedPosting','BIT')  is not null and X.value('@LockedPosting','BIT')=1)
	BEGIN
				
					EXEC @return_value = spDOC_SuspendInvDocument        
				 @CostCenterID = @CostCenterID, 
				 @DocID=@DocID,
				 @DocPrefix = '',  
				 @DocNumber = '', 
				 @Remarks=N'', 
				 @UserID = @UserID,  
				 @UserName = @UserName,
				 @RoleID=@RoleID,
				 @LangID = @LangID  
				 
				if(@return_value=1)
					set @DocID=0
				else
					return -999;
				
				
				set @IsLockedPosting=1
				set @DocDate=@AppRejDate	
				
	END
        
	declare @tblIDsList table(Id bigint)  
	insert into @tblIDsList  
	exec SPSplitString @DetailIDs,'~'        
	
	if(@PrefValue='SaveonHold')  
	begin  
		set @StatusID=438    
	end  
 
	IF(@RefCCID=95)
	BEGIN
		IF EXISTS (SELECT [STATUS] FROM [adm_featureactionrolemap] WITH(NOLOCK) WHERE ROLEID=@RoleID AND FEATUREACTIONID=3764)
		BEGIN 
			set @StatusID=371 
		END
	END
  
	IF (@IsRevision=1 and @DocID>0 and not exists(select DocID from [INV_DocDetails_History] where DocID=@DocID))  
	BEGIN    
	 EXEC @return_value = [spDOC_SaveHistory]      
			@DocID =@DocID ,
			@HistoryStatus='ADD',
			@Ininv =1,
			@ReviseReason ='',
			@LangID =@LangID
	END 

	declare @bb nvarchar(max)
	set @bb=convert(varchar,CHAR(17))
	
  
	DECLARE @DAllowLockData BIT,@AllowLockData BIT ,@IsLock bit    
	
	SELECT @AllowLockData=CONVERT(BIT,Value) FROM @TblPref WHERE  IsGlobal=1 and Name='Lock Data Between'    	
	SELECT @DAllowLockData=CONVERT(BIT,Value) FROM @TblPref where IsGlobal=0 and  Name='Lock Data Between'
	
	set @IsLock=0	

	if((@AllowLockData=1 or @DAllowLockData=1) and dbo.fnCOM_HasAccess(@RoleID,43,193)=0)
	BEGIN
		IF exists(select LockID from ADM_LockedDates WITH(NOLOCK) where isEnable=1 
		and ((@AllowLockData=1 and CONVERT(float,@DocDate) between FromDate and ToDate and CostCenterID=0)
		or (@DAllowLockData=1 and CONVERT(float,@DocDate) between FromDate and ToDate and CostCenterID=@CostCenterID)))
			set @IsLock=1
			
		IF (@AllowLockData=1 and @IsLock=1 and  (SELECT Value FROM @TblPref where IsGlobal=0 and  Name='OverrideLock')<>'true')
		BEGIN	
			SELECT @LockCC=CONVERT(BIGINT,Value) FROM @TblPref WHERE  IsGlobal=1 and Name='LockCostCenters' and isnumeric(Value)=1

			if(@LockCC is null or @LockCC=0)
				RAISERROR('-125',16,1)      			
		END
		
		
		IF (@DAllowLockData=1 and @IsLock=1)
		BEGIN
			SELECT @DLockCC=CONVERT(BIGINT,Value) FROM @TblPref where IsGlobal=0 and  Name='LockCostCenters' and isnumeric(Value)=1
		
			if(@DLockCC is null or @DLockCC=0)
				RAISERROR('-125',16,1)      			
		END
	END
	
	  
	      
		
		if(@HistoryStatus<>'Add')
		BEGIN
		
			DECLARE @TblDeleteRows AS Table(ID BIGINT,DynamicType INT,Linkid BIGINT)
		
			INSERT INTO @TblDeleteRows(ID,DynamicType,Linkid)
			SELECT InvDocDetailsID,0,LinkedInvDocDetailsID FROM INV_DocDetails WITH(NOLOCK)
			WHERE DocID=@DocID and (DynamicInvDocDetailsID is null or DynamicInvDocDetailsID=0 or DynamicInvDocDetailsID=-1)  
			AND InvDocDetailsID NOT IN (SELECT ID from @tblIDsList)
			
			
			if exists(select ID from @TblDeleteRows)
			BEGIN
			
				if exists(SELECT ID from @tblIDsList a
				join INV_DocDetails b on b.InvDocDetailsID=a.ID
				where DocID<>@DocID)
					RAISERROR('-101',16,1)  
					
				--DELETE DOCUMENT EXTRA COSTCENTER FEILD DETAILS
				DELETE T FROM COM_DocCCData t
				join @TblDeleteRows a on t.InvDocDetailsID=a.ID		

				--DELETE DOCUMENT EXTRA NUMERIC FEILD DETAILS      
				DELETE T FROM [COM_DocNumData] t
				join @TblDeleteRows a on t.InvDocDetailsID=a.ID
				
				--DELETE DOCUMENT EXTRA TEXT FEILD DETAILS      
				DELETE T FROM [COM_DocTextData] T
				join @TblDeleteRows a on t.InvDocDetailsID=a.ID

				--DELETE Accounts DocDetails      
				DELETE T FROM [ACC_DocDetails] T
				join @TblDeleteRows a on t.InvDocDetailsID=a.ID 

				--DELETE Accounts DocDetails      
				DELETE T FROM [INV_SerialStockProduct] T
				join @TblDeleteRows a on t.InvDocDetailsID=a.ID 
				
				DELETE T FROM [INV_DocDetails] T
				join @TblDeleteRows a on t.InvDocDetailsID=a.ID	

			END
			
			DELETE T FROM INV_DocExtraDetails T
			join @TblDeleteRows a on t.InvDocDetailsID=a.ID
			
			DELETE T FROM INV_DocExtraDetails T
			join @tblIDsList a on t.InvDocDetailsID=a.ID
			
			DELETE T FROM [ACC_DocDetails] T
			join @tblIDsList a on t.InvDocDetailsID=a.ID
			
			DELETE T FROM [INV_SerialStockProduct] T
			join @tblIDsList a on t.InvDocDetailsID=a.ID

			SET  @xml=@StatXML       
			
			UPDATE [INV_DocDetails]      
				SET    VersionNo=@VersionNo    
				,VoucherNo=@VoucherNo  
				,DocDate= CONVERT(FLOAT,@DocDate)               
				,DueDate=  case when  X.value('@DueDate','Datetime') is not null THEN CONVERT(float, X.value('@DueDate','Datetime')) else   CONVERT(FLOAT,@DueDate)       end          
				,StatusID= @StatusID        
				,ActDocDate=@ActDocDate
				,BillNo=Case WHEN  X.value('@BillNo','NVarChar(500)') is not null THEN X.value('@BillNo','NVarChar(500)') ELSE @BillNo  END        
				,BillDate=CONVERT(FLOAT,X.value('@BillDate','datetime'))      
				,LinkedInvDocDetailsID= X.value('@LinkedInvDocDetailsID','bigint')      
				,LinkedFieldName=X.value('@LinkedFieldName','nvarchar(200)')      
				,LinkedFieldValue= X.value('@LinkedFieldValue','float')      
				,CommonNarration= X.value('@CommonNarration','nvarchar(max)')      
				,LineNarration= X.value('@LineNarration','nvarchar(max)')      
				,DebitAccount=ISNULL( X.value('@DebitAccount','bigint'),1)      
				,CreditAccount= ISNULL(X.value('@CreditAccount','bigint'),1)      
				,DocSeqNo= X.value('@DocSeqNo','int')      
				,ProductID= X.value('@ProductID','bigint')      
				,Quantity= X.value('@Quantity','float')      
				,Unit= X.value('@Unit','bigint')      
				,HoldQuantity=ISNULL( X.value('@HoldQuantity','float'),0)      
				,ReserveQuantity=ISNULL( X.value('@ReserveQuantity','float'),0)              
				,IsQtyIgnored= ISNULL(X.value('@IsQtyIgnored','bit'),0)      
				,IsQtyFreeOffer= ISNULL(X.value('@IsQtyFreeOffer','bigint'),0)      
				,Rate= X.value('@Rate',' float')      
				,AverageRate= ISNULL(X.value('@AverageRate','float'),0)      
				,Gross= (X.value('@Gross',' float') * ISNULL(X.value('@ExchangeRate','float'),1) )     
				,GrossFC=   X.value('@Gross',' float')     
				,StockValue= ISNULL(X.value('@StockValue','float'),0)      
				,CurrencyID=ISNULL(X.value('@CurrencyID','int'),1)      
				,ExchangeRate= ISNULL(X.value('@ExchangeRate','float'),1)      
				,StockValueFC=ISNULL(X.value('@StockValueFC','float'),ISNULL(X.value('@StockValue','float'),0))    
				,ModifiedBy= @UserName      
				,ModifiedDate= @Dt      
				,UOMConversion  = X.value('@UOMConversion','float')       
				,UOMConvertedQty =X.value('@UOMConvertedQty','float')             
				,WorkflowID=@WID    
				,WorkFlowStatus =@StatusID    
				,WorkFlowLevel=@level    
				,RefCCID=@RefCCID,RefNodeid=@RefNodeid 
				,vouchertype= case when @DocumentType in (5,30,54) then X.value('@VoucherType','int') 
								   when @DocumentType=38 and X.value('@VoucherType','int') is not null then 1 else  @VoucherType end 
				,ParentSchemeID= X.value('@ParentSchemeID','nvarchar(500)')
				,RefNO= X.value('@RefNO','nvarchar(200)')
				,[BatchID]=1
				,BatchHold =NULL
				,ReleaseQuantity =0
				,RefInvDocDetailsID=NULL				
				,CanRecur=X.value('@CanRecur','BIT')
				from @xml.nodes('DocXML/Transactions') as Data(X)      
				WHERE InvDocDetailsID=isnull(X.value('@DocDetailsID','BIGINT'),0)    
				
				set @xml=@NumXML
				SELECT @DetailIDs=X.value('@NumUpdateCols','nvarchar(max)')
				from @ActXML.nodes('/XML') as Data(X)
		
				set @SQL='update [COM_DocNumData] set '+@DetailIDs+' AccDocDetailsID=null
				from @xml.nodes(''NumXML/Numeric'') as Data(X)				
				where isnull(X.value(''@DocDetailsID'',''BIGINT''),0)=InvDocDetailsID'
				
				exec sp_executesql @sql,N'@xml xml',@xml
				

				SELECT @DetailIDs=X.value('@TextUpdateCols','nvarchar(max)')
				from @ActXML.nodes('/XML') as Data(X)
				
				set @SQL='update [COM_DocTextData] set '+@DetailIDs+' AccDocDetailsID=null
				from @xml.nodes(''TextXML/Alpha'') as Data(X)				
				where isnull(X.value(''@DocDetailsID'',''BIGINT''),0)=InvDocDetailsID'
							
				exec sp_executesql @sql,N'@xml xml',@TextXML
		
				SELECT @DetailIDs=X.value('@CCUpdateCols','nvarchar(max)')
				from @ActXML.nodes('/XML') as Data(X)
		
				set @SQL='update [COM_DocCCData] set '+@DetailIDs+' AccDocDetailsID=null
				from @xml.nodes(''CCXML/CostCenters'') as Data(X)				
				where isnull(X.value(''@DocDetailsID'',''BIGINT''),0)=InvDocDetailsID'
			
				exec sp_executesql @sql,N'@xml xml',@CCXML	
				
		END
		else
		BEGIN
			SET @VersionNo=1    		
			set @DimesionNodeID=0
		
		
			IF(@Series is not null and @Series>40000)
				set @prefixCCID=@Series
			ELSE
				set @prefixCCID=@CostCenterID
			
			if(@IsImport=1 and @ImpDocID is not null and @ImpDocID>0)
			BEGIN
				SELECT  top 1 @DocID=DocID,@VoucherNo=VoucherNo,@DocNumber=DocNumber,@DocPrefix=DocPrefix,@VersionNo=VersionNo
				FROM INV_DocDetails WHERE DocID=@ImpDocID
				
				select @Guid=GUID from COM_DocID WITH(NOLOCK) WHERE ID=@ImpDocID
				
			END
			ELSE
			BEGIN		
				if(@IsImport=1 and @ImpDocID is not null)
				BEGIN
					exec sp_GetDocPrefix @StatXML,@DocDate,@CostCenterID,@DocPrefix OUTPUT
				END
				set @Guid=NEWID()
				
				if NOT EXISTS(SELECT CurrentCodeNumber FROM COM_CostCenterCodeDef WITH(NOLOCK) WHERE CostCenterID=@prefixCCID AND CodePrefix=@DocPrefix)      
				begin      
					INSERT INTO COM_CostCenterCodeDef(CostCenteriD,FeatureiD,CodePrefix,CodeNumberRoot,CodeNumberInc,CurrentCodeNumber,CodeNumberLength,GUID,CreatedBy,CreatedDate,Location,Division)
					VALUES(@prefixCCID,@prefixCCID,@DocPrefix,CONVERT(BIGINT,@DocNumber),1,CONVERT(BIGINT,@DocNumber),len(@DocNumber),Newid(),@UserName,convert(float,getdate()),@LocationID,@DivisionID)      
					SET @tempDOc=CONVERT(BIGINT,@DocNumber)+1
					SET @Length=len(@DocNumber)
				end      
				ELSE
				BEGIN
					SELECT  @tempDOc=ISNULL(CurrentCodeNumber,0)+1,@Length=isnull(CodeNumberLength,1)  FROM COM_CostCenterCodeDef--AS CurrentCodeNumber
					WHERE CostCenterID=@prefixCCID AND CodePrefix=@DocPrefix
				 	
		 			  if(@DocNumber='1' and @RefCCID>0 and @RefCCID<>300)
							set  @DocNumber=@tempDOc
					IF(CONVERT(BIGINT,@DocNumber)>=@tempDOc)      
					BEGIN      
						SET @HasAccess=dbo.fnCOM_HasAccess(@RoleID,43,138)
						
						if(@HasAccess=0)
							SET @HasAccess=dbo.fnCOM_HasAccess(@RoleID,@CostCenterID,671)
						
						IF @HasAccess=0
						BEGIN
							if(len(@tempDOc)<@Length)    
							begin    
								set @t=1    
								set @temp=''    
								while(@t<=(@Length-len(@tempDOc)))    
								begin        
								set @temp=@temp+'0'        
									set @t=@t+1    
								end    
								SET @DocNumber=@temp+cast(@tempDOc as varchar)    
							end    
							ELSE    
								SET @DocNumber=@tempDOc    
								
							UPDATE COM_CostCenterCodeDef     
							SET CurrentCodeNumber=@DocNumber    
							WHERE CostCenterID=@prefixCCID AND CodePrefix=@DocPrefix 
						END
						ELSE
						BEGIN
							UPDATE COM_CostCenterCodeDef       
							SET CurrentCodeNumber=@DocNumber      
							WHERE CostCenterID=@prefixCCID AND CodePrefix=@DocPrefix      
						END	
					END
				END   
				   
				IF EXISTS(SELECT DocID FROM INV_DocDetails a WITH(NOLOCK) 
				LEFT JOIN  ADM_DocumentTypes b WITH(NOLOCK) on a.CostCenterID=b.CostCenterID
				WHERE (b.Series=@prefixCCID or a.CostCenterID=@prefixCCID) AND DocPrefix=@DocPrefix AND CONVERT(BIGINT,DocNumber)=CONVERT(BIGINT,@DocNumber))
				BEGIN 
					set @PrefValue=''  
					select @PrefValue=Value from @TblPref where IsGlobal=0 and  Name='SameserialNo'
				     
					if ((@IsImport=1 or @PrefValue='true')and @ImpDocID is null)
						RAISERROR('-122',16,1)      

					if(len(@tempDOc)<@Length)      
					begin      
						set @t=1      
						set @temp=''      
						while(@t<=(@Length-len(@tempDOc)))      
						begin          
							set @temp=@temp+'0'          
							set @t=@t+1      
						end      
						SET @DocNumber=@temp+cast(@tempDOc as varchar)      
					end      
					ELSE      
						SET @DocNumber=@tempDOc

					UPDATE COM_CostCenterCodeDef       
					SET CurrentCodeNumber=@DocNumber      
					WHERE CostCenterID=@prefixCCID AND CodePrefix=@DocPrefix      
				END      

				SET @VoucherNo=isnull(@DocAbbr,'')+'-'+isnull(@DocPrefix,'')+isnull(@DocNumber,'')

				if(@IsRevision=1)  
				begin    
					set @VoucherNo=@VoucherNo+'/'+convert(nvarchar, @VersionNo  )
				end
				
				--To Get Auto generate DocID
				while exists (select DocNo from COM_DocID with(nolock) where DocNo=@VoucherNo)
				begin			
					SET @DocNumber=@DocNumber+1
					SET @VoucherNo=isnull(@DocAbbr,'')+'-'+isnull(@DocPrefix,'')+isnull(@DocNumber,'')
				end	
				
				if @PosSessionID is not null
				begin
					INSERT INTO COM_DocID(DocNo,PosSessionID,[CompanyGUID],[GUID],sysinfo)
					VALUES(@VoucherNo,@PosSessionID,@CompanyGUID,@Guid,@sysinfo)
					SET @DocID=@@IDENTITY
				end
				else
				begin
					INSERT INTO COM_DocID(DocNo,[CompanyGUID],[GUID],sysinfo)
					VALUES(@VoucherNo,@CompanyGUID,@Guid,@sysinfo)
					SET @DocID=@@IDENTITY
				end
			END	
		END
		
		
		SET  @xml=@StatXML       
	  
		INSERT INTO [INV_DocDetails]      
				([DocID]      
				,[CostCenterID]      				
				,[DocumentType],DocOrder,ActDocDate
				,[VoucherType]      
				,[VoucherNo]      
				,[VersionNo]      
				,[DocAbbr]      
				,[DocPrefix]      
				,[DocNumber]      
				,[DocDate]      
				,[DueDate]      
				,[StatusID]      
				,[BillNo]      
				,BillDate      
				,[LinkedInvDocDetailsID]      
				,[LinkedFieldName]      
				,[LinkedFieldValue]      
				,[CommonNarration]      
				,LineNarration      
				,[DebitAccount]      
				,[CreditAccount]      
				,[DocSeqNo]      
				,[ProductID]      
				,[Quantity]      
				,[Unit]      
				,[HoldQuantity]    
				,[ReserveQuantity]     
				,[ReleaseQuantity]    
				,[IsQtyIgnored]      
				,[IsQtyFreeOffer]      
				,[Rate]      
				,[AverageRate]      
				,[Gross]      
				,[StockValue]      
				,[CurrencyID]      
				,[ExchangeRate]     
				,[GrossFC]    
				,[StockValueFC]
				,[CreatedBy]      
				,[CreatedDate],ModifiedBy,ModifiedDate,UOMConversion       
				,UOMConvertedQty,WorkflowID , WorkFlowStatus , WorkFlowLevel,RefCCID,RefNodeid,ParentSchemeID,RefNo,BatchID)    
				SELECT       
				 @DocID      
				, @CostCenterID
				, @DocumentType,@DocOrder,@ActDocDate
				, case when @DocumentType in(5,30,54) then X.value('@VoucherType','int') else  @VoucherType end    
				, @VoucherNo    
				, @VersionNo    
				, @DocAbbr    
				, @DocPrefix      
				, @DocNumber      
				, CONVERT(FLOAT,@DocDate)
				, case when  X.value('@DueDate','Datetime') is not null THEN CONVERT(float, X.value('@DueDate','Datetime')) else   CONVERT(FLOAT,@DueDate)       end                   
				, @StatusID  
				, Case WHEN  X.value('@BillNo','NVarChar(500)') is not null THEN X.value('@BillNo','NVarChar(500)') ELSE @BillNo  END    
				, @BILLDate      
				, X.value('@LinkedInvDocDetailsID','bigint')      
				, X.value('@LinkedFieldName','nvarchar(200)')      
				, X.value('@LinkedFieldValue','float')      
				, X.value('@CommonNarration','nvarchar(max)')      
				, X.value('@LineNarration','nvarchar(max)')      
				, X.value('@DebitAccount','BIGINT')      
				, X.value('@CreditAccount','BIGINT')      
				, X.value('@DocSeqNo','int')      
				, X.value('@ProductID','BIGINT')      
				, X.value('@Quantity','float')      
				, ISNULL( X.value('@Unit','bigint'),(select UOMID from inv_product  where productid=X.value('@ProductID','BIGINT')))
				, ISNULL( X.value('@HoldQuantity','float'),0)     
				, ISNULL( X.value('@ReserveQuantity','float'),0)      
				, ISNULL( X.value('@ReleaseQuantity','float'),0) --Release Qyt            
				, ISNULL(X.value('@IsQtyIgnored','bit'),0)      
				, ISNULL(X.value('@IsQtyFreeOffer','bigint'),0)      
				, X.value('@Rate',' float')      
				, ISNULL(X.value('@AverageRate','float'),0)      
				, ( X.value('@Gross',' float') * ISNULL(X.value('@ExchangeRate','float'),1) )     
				, ISNULL(X.value('@StockValue','float'),0)      
				, ISNULL(X.value('@CurrencyID','int'),1)      
				, ISNULL(X.value('@ExchangeRate','float'),1)    
				, X.value('@Gross',' float')    
				, ISNULL(X.value('@StockValueFC','float'),ISNULL(X.value('@StockValue','float'),0))       
				
				, @UserName      
				, @Dt  , @UserName      
				, @Dt      
				, X.value('@UOMConversion','float')       
				, X.value('@UOMConvertedQty','float')             
				, @WID,@StatusID,@level,@RefCCID,@RefNodeid, X.value('@ParentSchemeID','nvarchar(500)')
				, X.value('@RefNO','nvarchar(200)') ,isnull(X.value('@BatchID','BIGINT'),1)
				from @xml.nodes('DocXML/Transactions') as Data(X)
				where isnull(X.value('@DocDetailsID','BIGINT'),0)=0
				
				
				set @xml=@NumXML
				SELECT @DetailIDs=X.value('@NumCols','nvarchar(max)'),@DetIDS=X.value('@NumSelCols','nvarchar(Max)')
				from @ActXML.nodes('/XML') as Data(X)
		
				set @SQL='INSERT INTO [COM_DocNumData]('+@DetailIDs+'InvDocDetailsID)
				select '+@DetIDS+' a.[InvDocDetailsID]
				from @xml.nodes(''NumXML/Numeric'') as Data(X)
				Join [INV_DocDetails] a on X.value(''@DocSeqNo'',''int'')=a.DocSeqNo
				where isnull(X.value(''@DocDetailsID'',''BIGINT''),0)=0 and  a.docid='+convert(nvarchar(20),@DocID)
				
				exec sp_executesql @sql,N'@xml xml',@xml
				

				SELECT @DetailIDs=X.value('@TextCols','nvarchar(max)'),@DetIDS=X.value('@TextSelCols','nvarchar(Max)')
				from @ActXML.nodes('/XML') as Data(X)
				
				set @SQL='INSERT INTO [COM_DocTextData]('+@DetailIDs+'InvDocDetailsID)
				select '+@DetIDS+' a.[InvDocDetailsID]
				from @xml.nodes(''TextXML/Alpha'') as Data(X)
				Join [INV_DocDetails] a on X.value(''@DocSeqNo'',''int'')=a.DocSeqNo
				where isnull(X.value(''@DocDetailsID'',''BIGINT''),0)=0 and a.docid='+convert(nvarchar(20),@DocID)

				exec sp_executesql @sql,N'@xml xml',@TextXML
		
				SELECT @DetailIDs=X.value('@CCCols','nvarchar(max)'),@DetIDS=X.value('@CCSelCols','nvarchar(Max)')
				from @ActXML.nodes('/XML') as Data(X)
		
				set @SQL='INSERT INTO [COM_DocCCData]('+@DetailIDs+'InvDocDetailsID)
				select '+@DetIDS+' a.[InvDocDetailsID]
				from @xml.nodes(''CCXML/CostCenters'') as Data(X)
				Join [INV_DocDetails] a on X.value(''@DocSeqNo'',''int'')=a.DocSeqNo
				where isnull(X.value(''@DocDetailsID'',''BIGINT''),0)=0 and a.docid='+convert(nvarchar(20),@DocID)

				exec sp_executesql @sql,N'@xml xml',@CCXML
	
	
	--	and @tempProd<>@ProductID and @productType not in(6,8)
	if exists(select Value from @TblPref where IsGlobal=1 and Name='Check for -Ve Stock'  and Value='true')
	and exists(select Value from @TblPref where IsGlobal=0 and Name='DonotupdateInventory' and Value='false')
	and @VoucherType=-1
	BEGIN	
			set @DUPLICATECODE='
			declare @tab table(seq nvarchar(5),pid bigint'
			 if(@loc=1)
				set @DUPLICATECODE=@DUPLICATECODE+',c2 bigint' 
			if(@div=1)
				set @DUPLICATECODE=@DUPLICATECODE+',c1 bigint'
			if(@dim>0)
				set @DUPLICATECODE=@DUPLICATECODE+',cn bigint'
				
			set @DUPLICATECODE=@DUPLICATECODE+')
			insert into @tab
			select max(DocSeqNo),ProductID '
			if(@loc=1)
				set @DUPLICATECODE=@DUPLICATECODE+',dcCCNID2' 
			if(@div=1)
				set @DUPLICATECODE=@DUPLICATECODE+',dcCCNID1'
			if(@dim>0)
				set @DUPLICATECODE=@DUPLICATECODE+',dcCCNID'+convert(nvarchar,@dim)
				
			set @DUPLICATECODE=@DUPLICATECODE+'
			from INV_DocDetails Doc WITH(NOLOCK) 
			INNER JOIN COM_DocCCData DocCC with(nolock) ON DocCC.InvDocDetailsID=doc.InvDocDetailsID        
			where doc.docid='+convert(nvarchar,@DocID)+' and doc.CostCenterID='+convert(nvarchar,@CostCenterID)+'
			and IsQtyIgnored=0 and ProductID<>'+convert(nvarchar,@tempProd)+' 
			group by ProductID'
			if(@loc=1)
				set @DUPLICATECODE=@DUPLICATECODE+',dcCCNID2' 
			if(@div=1)
				set @DUPLICATECODE=@DUPLICATECODE+',dcCCNID1'
			if(@dim>0)
				set @DUPLICATECODE=@DUPLICATECODE+',dcCCNID'+convert(nvarchar,@dim)
				
			set @DUPLICATECODE=@DUPLICATECODE+'
			set @SQL=''''
			select @SQL=@SQL+ProductCode +'':''+seq+''    '' from 
			(SELECT t.seq,p.ProductCode,p.productName,			
			(select isnull(sum(UOMConvertedQty*case when vouchertype=1 and statusid in(371,441) then 0 else  VoucherType end),0) Bal 
			FROM INV_DocDetails D WITH(NOLOCK)
			INNER JOIN COM_DocCCData DCC with(nolock) ON DCC.InvDocDetailsID=D.InvDocDetailsID
			WHERE D.ProductID=t.pid and D.DocDate<='+CONVERT(nvarchar,convert(float,@DocDate)) 
			set @DUPLICATECODE=@DUPLICATECODE+' and D.StatusID in(371,441,369) 
			AND D.IsQtyIgnored=0 and (D.VoucherType=1 or D.VoucherType=-1) '
			if(@loc=1)	
				set @DUPLICATECODE=@DUPLICATECODE+' and DCC.dcCCNID2=t.c2'
			if(@div=1)
				set @DUPLICATECODE=@DUPLICATECODE+' and DCC.dcCCNID1=t.c1'
			if(@dim>0)
				set @DUPLICATECODE=@DUPLICATECODE+' and DCC.dcCCNID'+CONVERT(nvarchar,@dim)+'=t.cn '
				
			set @DUPLICATECODE=@DUPLICATECODE+')Bal
			from @tab t 
			join Inv_product p with(nolock) ON t.pid=p.ProductID
			where ProductTypeID not in(6,8)
			) as temp
			where round(Bal,2)<0'
			 
			print @DUPLICATECODE
			EXEC sp_executesql @DUPLICATECODE, N'@SQL nvarchar(max) OUTPUT', @SQL OUTPUT 
			if(@SQL<>'')
			BEGIN
				RAISERROR('-407',16,1)
			END			
	END
	
   IF(@ExtraXML IS NOT NULL and @ExtraXML<>'')      
   BEGIN 
		set @AccountsXML=@ExtraXML
		 INSERT INTO [INV_SerialStockProduct]      
        ([InvDocDetailsID]      
        ,[ProductID]      
        ,[SerialNumber]      
        ,[StockCode]      
        ,[Quantity]      
        ,[StatusID]      
       ,[RefInvDocDetailsID]      
      ,[Narration]      
      ,SerialGUID      
      ,IsIssue      
      ,IsAvailable      
        ,[CompanyGUID]      
        ,[GUID]      
        ,[CreatedBy]      
        ,[CreatedDate])      
      SELECT a.InvDocDetailsID      
        ,a.ProductID      
        ,X.value('@SerialNumber','nvarchar(500)')      
        ,X.value('@StockCode','nvarchar(500)')      
        ,X.value('@Quantity','float')      
        ,case when (@DocumentType=5 and @VoucherType=1) THEN 157 ELSE X.value('@StatusID','int') END
        ,case when (@DocumentType=5 and @VoucherType=1) THEN 0 ELSE X.value('@RefInvDocDetailsID','bigint') END
        ,X.value('@Narration','nvarchar(max)')       
        ,X.value('@SerialGUID','nvarchar(50)')      
        ,X.value('@IsIssue','bit')      
        ,case when (@DocumentType=5 and @VoucherType=1) THEN 1 ELSE X.value('@IsAvailable','bit') END      
      , @CompanyGUID      
      , @Guid
      , @UserName      
      , @Dt      
	  from @AccountsXML.nodes('/EXTRAXML/xml/Row') as Data(X)         
	  Join [INV_DocDetails] a on X.value('@DocSeqNo','int')=a.DocSeqNo
	  where a.docid=@DocID
   END 
   
   if(@DocExtraXML is not null and CONVERT(nvarchar(max),@DocExtraXML)<>'')	
	BEGIN	
		set @AccountsXML=@DocExtraXML
		insert into INV_DocExtraDetails(InvDocDetailsID,[Type],[RefID],[Quantity],label,fld1,fld2,fld3,fld4,fld5,fld6,fld7,fld8,fld9,fld10)
		select a.InvDocDetailsID,X.value('@Type','int'),case when X.value('@Type','int')=5 THEN @DocID else X.value('@RefID','Float') end,X.value('@Qty','Float'),X.value('@Label','Nvarchar(max)')
		,X.value('@Fld1','Nvarchar(max)'),X.value('@Fld2','Nvarchar(max)'),X.value('@Fld3','Nvarchar(max)'),X.value('@Fld4','Nvarchar(max)'),X.value('@Fld5','Nvarchar(max)')
		,X.value('@Fld6','Nvarchar(max)'),X.value('@Fld7','Nvarchar(max)'),X.value('@Fld8','Nvarchar(max)'),X.value('@Fld9','Nvarchar(max)'),X.value('@Fld10','Nvarchar(max)')
		from @AccountsXML.nodes('/DocExtraXML/DocExtraXML/Row') as Data(X) 
		 Join [INV_DocDetails] a on X.value('@DocSeqNo','int')=a.DocSeqNo
		 where a.docid=@DocID
		
	END	
   
   		
   IF(@AccXML IS NOT NULL and @AccXML<>'')      
   BEGIN 
		set @AccountsXML=@AccXML
		
		INSERT INTO ACC_DocDetails      
         (InvDocDetailsID  
         ,[DocID]  
         ,VOUCHERNO      
         ,[CostCenterID]      
               
         ,[DocumentType]      
         ,[VersionNo]      
         ,[DocAbbr]      
         ,[DocPrefix]      
         ,[DocNumber]      
         ,[DocDate]
         ,ActDocDate      
         ,[DueDate]      
         ,[StatusID]      
         ,[BillNo]      
         ,BillDate      
         ,[CommonNarration]      
         ,LineNarration      
         ,[DebitAccount]      
         ,[CreditAccount]      
         ,[Amount]      
         ,[DocSeqNo]      
         ,[CurrencyID]      
         ,[ExchangeRate]     
         ,[AmountFC]     
              
         ,[CreatedBy]      
         ,[CreatedDate]  
         ,WorkflowID   
         ,WorkFlowStatus   
         ,WorkFlowLevel  
         ,RefCCID  
         ,RefNodeid)      
            
        SELECT a.InvDocDetailsID,0,@VoucherNo      
         , @CostCenterID      
             
         , @DocumentType      
         , @VersionNo     
         , @DocAbbr      
         , @DocPrefix      
         , @DocNumber      
         , CONVERT(FLOAT,@DocDate)
         , @ActDocDate      
         , CONVERT(FLOAT,@DueDate)      
         , @StatusID      
         , @BillNo      
         , @BILLDate      
         , X.value('@CommonNarration','nvarchar(max)')      
         , X.value('@LineNarration','nvarchar(max)')               
         ,case when @IsImport=1  and X.value('@DebitAccount','nvarchar(500)')=@ACCOUNT1Name then  @ACCOUNT1      
             when @IsImport=1 and X.value('@IsNegative','bit')=1 and X.value('@DebitAccount','nvarchar(500)')=@ACCOUNT2Name then  @ACCOUNT2      
             else ISNULL( X.value('@DebitAccount','BIGINT'),0) end              
         ,case when @IsImport=1  and X.value('@CreditAccount','nvarchar(500)')=@ACCOUNT2Name then   @ACCOUNT2      
             when @IsImport=1 and X.value('@IsNegative','bit')=1  and X.value('@CreditAccount','nvarchar(500)')=@ACCOUNT1Name then   @ACCOUNT1      
             else ISNULL( X.value('@CreditAccount','BIGINT'),0) end 
         , X.value('@Amount','FLOAT')      
         , 0      
         , ISNULL(X.value('@CurrencyID','int'),1)      
         , ISNULL(X.value('@ExchangeRate','float'),1)      
         , ISNULL(X.value('@AmtFc','FLOAT'),X.value('@Amount','FLOAT'))     
             
         , @UserName      
         , @Dt    
         , @WID  
         , @StatusID  
         , @level   
         , @RefCCID  
         , @RefNodeid   
           from @AccountsXML.nodes('/AccXML/Accounts') as Data(X)         
		   Join [INV_DocDetails] a on X.value('@DocSeqNo','int')=a.DocSeqNo
				where a.docid=@DocID
   END 
     
    if(@DocumentType=32)
    BEGIN
		if exists(select b.docid from INV_DocDetails a WITH(NOLOCK)   
		join INV_DocDetails b WITH(NOLOCK)  on a.LinkedInvDocDetailsID=b.InvDocDetailsID 
		where a.CostCenterid=@CostCenterID and a.DocID =@DocID and b.DocumentType=31)
		BEGIN
			update INV_DocDetails
			set statusid=369
			where DocID=(select top 1 b.docid from INV_DocDetails a WITH(NOLOCK)   
			join INV_DocDetails b WITH(NOLOCK)  on a.LinkedInvDocDetailsID=b.InvDocDetailsID 
			where a.CostCenterid=@CostCenterID and a.DocID =@DocID and b.DocumentType=31)
		END
    END 
      
	select @InvDocDetailsID=InvDocDetailsID from [INV_DocDetails] WITH(NOLOCK)
	where docid=@DocID
	
	DECLARE @AuditTrial BIT    
	SELECT @AuditTrial=CONVERT(BIT,Value) FROM @TblPref where IsGlobal=0 and  Name='AuditTrial'      
	
	SET @PrefValue=''    
	SELECT @PrefValue=Value FROM @TblPref where IsGlobal=0 and  Name='EnableRevision' 
	    
	IF (@AuditTrial=1 or @PrefValue='true')  
	BEGIN    
		 EXEC @return_value = [spDOC_SaveHistory]      
				@DocID =@DocID ,
				@HistoryStatus=@HistoryStatus,
				@Ininv =1,
				@ReviseReason =@ReviseReason,
				@LangID =@LangID,
				@UserName =@UserName,
				@ModDate =@Dt,
				@CCID=@CostCenterID
	END    
 
      
  if(@BillWiseXML <>'')      
  BEGIN 
		declare  @DocCC    nvarchar(max) 
		set @DocCC=''		
		select @DocCC =@DocCC +','+a.name from sys.columns a
		join sys.tables b on a.object_id=b.object_id
		where b.name='COM_DocCCData' and a.name like 'dcCCNID%'
	

		 SET @XML=@BillWiseXML
    
		   update com_billwise  
		   set RefDocNo=NULL,RefDocSeqNo=NULL,[IsNewReference]=1,[RefDocDueDate]=NULL  
		   where RefDocNo=@VoucherNo and RefDocSeqNo=1  
		   and AccountID not in (select  X.value('@AccountID','bigint') from @XML.nodes('/BillWise/Row') as Data(X)  )   
		  
			set @sql='INSERT INTO [COM_Billwise]      
			 ([DocNo],[DocDate],[DocDueDate],[DocSeqNo],BillNo,BillDate,StatusID,RefStatusID      
			   ,[AccountID],[AdjAmount],[AdjCurrID],[AdjExchRT],AmountFC,[DocType],[IsNewReference],[RefDocNo]      
			   ,[RefDocSeqNo],[RefDocDate],[RefDocDueDate],[RefBillWiseID],[DiscAccountID],[DiscAmount],[DiscCurrID]      
			   ,[DiscExchRT],[Narration],[IsDocPDC],VatAdvance'+@DocCC+')
			 SELECT  '+convert(nvarchar(max),@VoucherNo)+'
			   , '+convert(nvarchar(max),CONVERT(FLOAT,@DocDate))+'    
			   , '+convert(nvarchar(max),CONVERT(FLOAT,@DueDate))+'        
			   , X.value(''@DocSeqNo'',''int''),'+convert(nvarchar(max),@BillNo)+','+convert(nvarchar(max),@BILLDate)+','+convert(nvarchar(max),@StatusID)+',X.value(''@RefStatusID'',''int'')
			   , X.value(''@AccountID'',''bigint'')      
			   , replace(X.value(''@AdjAmount'',''nvarchar(50)''),'','','''')    
			   , X.value(''@AdjCurrID'',''int'')      
			   , X.value(''@AdjExchRT'',''float'')  ,replace(X.value(''@AmountFC'',''nvarchar(50)''),'','','''')     
			   , '+convert(nvarchar(max),@DocumentType)+'      
			   , X.value(''@IsNewReference'',''bit'')      
			   , X.value(''@RefDocNo'',''nvarchar(200)'')      
			   , X.value(''@RefDocSeqNo'',''int'')      
			 , CONVERT(FLOAT,X.value(''@RefDocDate'',''DATETIME''))      
			 , CONVERT(FLOAT,X.value(''@RefDueDate'',''DATETIME''))      
			   , X.value(''@RefBillWiseID'',''bigint'')      
			   , X.value(''@DiscAccountID'',''bigint'')      
			   , X.value(''@DiscAmount'',''float'')      
			   , X.value(''@DiscCurrID'',''int'')      
			   , X.value(''@DiscExchRT'',''float'')      
			   , X.value(''@Narration'',''nvarchar(max)'')      
			   , X.value(''@IsDocPDC'',''bit'') , X.value(''@VatAdvance'',''float'')'+@DocCC+'
			 from @XML.nodes(''/BillWise/Row'') as Data(X)      
			 join [COM_DocCCData]  d WITH(NOLOCK)on d.InvDocDetailsID='+convert(nvarchar(max),@InvDocDetailsID)
			  EXEC sp_executesql @DUPLICATECODE,N'@XML XML',@XML
			 
  END      
  

  --Inserts Multiple Notes      
  IF (@NotesXML IS NOT NULL AND @NotesXML <> '')      
  BEGIN      
   SET @XML=@NotesXML      
      
   --If Action is NEW then insert new Notes      
   INSERT INTO COM_Notes(FeatureID,FeaturePK,Note,         
   GUID,CreatedBy,CreatedDate)      
   SELECT @CostCenterID,@DocID,Replace(X.value('@Note','NVARCHAR(max)'),'@~','
'),      
   @Guid,@UserName,@Dt      
   FROM @XML.nodes('/NotesXML/Row') as Data(X)      
   WHERE X.value('@Action','NVARCHAR(10)')='NEW'      
      
   --If Action is MODIFY then update Notes      
   UPDATE COM_Notes      
   SET Note=Replace(X.value('@Note','NVARCHAR(max)'),'@~','
'),    
    GUID=@Guid,      
    ModifiedBy=@UserName,      
    ModifiedDate=@Dt      
   FROM COM_Notes C       
   INNER JOIN @XML.nodes('/NotesXML/Row') as Data(X)        
   ON convert(bigint,X.value('@NoteID','bigint'))=C.NoteID      
   WHERE X.value('@Action','NVARCHAR(500)')='MODIFY'      
      
   --If Action is DELETE then delete Notes      
   DELETE FROM COM_Notes      
   WHERE NoteID IN(SELECT X.value('@NoteID','bigint')      
    FROM @XML.nodes('/NotesXML/Row') as Data(X)      
    WHERE X.value('@Action','NVARCHAR(10)')='DELETE')      
  END      
       
--  
  --Inserts Multiple Attachments      
  IF (@AttachmentsXML IS NOT NULL AND @AttachmentsXML <> '')      
  BEGIN      
   SET @XML=@AttachmentsXML      
      
   INSERT INTO COM_Files(FilePath,ActualFileName,RelativeFileName,      
   FileExtension,FileDescription,IsProductImage,AllowInPrint,FeatureID,FeaturePK,      
   GUID,CreatedBy,CreatedDate,RowSeqNo,ColName)      
   SELECT X.value('@FilePath','NVARCHAR(500)'),X.value('@ActualFileName','NVARCHAR(50)'),X.value('@RelativeFileName','NVARCHAR(50)'),      
   X.value('@FileExtension','NVARCHAR(50)'),X.value('@FileDescription','NVARCHAR(500)'),X.value('@IsProductImage','bit'),X.value('@AllowInPrint','bit'),@CostCenterID,@DocID,      
   X.value('@GUID','NVARCHAR(50)'),@UserName,@Dt,X.value('@RowSeqNo','int'),X.value('@ColName','NVARCHAR(100)')      
   FROM @XML.nodes('/AttachmentsXML/Row') as Data(X)        
   WHERE X.value('@Action','NVARCHAR(10)')='NEW'      
      
   --If Action is MODIFY then update Attachments      
   UPDATE COM_Files      
   SET FilePath=X.value('@FilePath','NVARCHAR(500)'),      
    ActualFileName=X.value('@ActualFileName','NVARCHAR(50)'),      
    RelativeFileName=X.value('@RelativeFileName','NVARCHAR(50)'),      
    FileExtension=X.value('@FileExtension','NVARCHAR(50)'),      
    FileDescription=X.value('@FileDescription','NVARCHAR(500)'),      
    IsProductImage=X.value('@IsProductImage','bit'),
    AllowInPrint=X.value('@AllowInPrint','bit'),
    GUID=X.value('@GUID','NVARCHAR(50)'),      
    ModifiedBy=@UserName,      
    ModifiedDate=@Dt      
   FROM COM_Files C       
   INNER JOIN @XML.nodes('/AttachmentsXML/Row') as Data(X)        
   ON convert(bigint,X.value('@AttachmentID','bigint'))=C.FileID      
   WHERE X.value('@Action','NVARCHAR(500)')='MODIFY'      
      
   --If Action is DELETE then delete Attachments      
   DELETE FROM COM_Files      
   WHERE FileID IN(SELECT X.value('@AttachmentID','bigint')      
    FROM @XML.nodes('/AttachmentsXML/Row') as Data(X)      
    WHERE X.value('@Action','NVARCHAR(10)')='DELETE')      
  END      
     
   
  
  if(@ActivityXML<>'' and @StatusID=369)
  begin
		
		set @XML=@ActivityXML
		
		--Shortage of stock
		set @TEMPxml=''
		SELECT @TEMPxml=CONVERT(NVARCHAR(MAX), X.query('ShortageXML'))
		from @XML.nodes('/XML') as Data(X)
		if(@TEMPxml<>'')
		begin
			select @PrefValue=Value from @TblPref where IsGlobal=0 and  Name='ShortageDOC'    
			set @AUTOCCID=0
			set @varxml=@TEMPxml
			set @AUTOCCID=convert(bigint,@PrefValue)
			
			SELECT @ddxml=CONVERT(NVARCHAR(MAX), X.query('DocXML'))
			from @varxml.nodes('/ShortageXML') as Data(X)
			SELECT @NumXML=CONVERT(NVARCHAR(MAX), X.query('NumXML'))
			from @varxml.nodes('/ShortageXML') as Data(X)
			SELECT @TextXML=CONVERT(NVARCHAR(MAX), X.query('TextXML'))
			from @varxml.nodes('/ShortageXML') as Data(X)
			SELECT @CCXML=CONVERT(NVARCHAR(MAX), X.query('CCXML'))
			from @varxml.nodes('/ShortageXML') as Data(X)
			SELECT @AccXML=CONVERT(NVARCHAR(MAX), X.query('AccXML'))
			from @varxml.nodes('/ShortageXML') as Data(X)
			SELECT @ExtraXML=CONVERT(NVARCHAR(MAX), X.query('EXTRAXML'))
			from @varxml.nodes('/ShortageXML') as Data(X)
			SELECT @bxml=CONVERT(NVARCHAR(MAX), X.query('BillXML'))
			from @varxml.nodes('/ShortageXML') as Data(X)
			
			SELECT @SQL=CONVERT(NVARCHAR(MAX), X.query('ActXML'))
			from @varxml.nodes('/ShortageXML') as Data(X)
			
			set @SQL=Replace(@SQL,'<ActXML','<XML')

			set @TEmpWid=0
			SELECT @TEmpWid=X.value('@WOrkFlowID','bigint')
			from @varxml.nodes('/ShortageXML') as Data(X)
			
			set @Prefix=''
			EXEC [sp_GetDocPrefix] @ddxml,@DocDate,@AUTOCCID,@Prefix output,@InvDocDetailsID,0,0 
						
			EXEC @return_value = [dbo].[spDOC_SetTempBulkInvDoc]      
			  @CostCenterID = @AUTOCCID,      
			  @DocID = 0,      
			  @DocPrefix = @Prefix,      
			  @DocNumber = N'',      
			  @DocDate = @DocDate,      
			  @DueDate = NULL,      
			  @BillNo = @BillNo,      
			  @AccXML  =@AccXML,  
			  @StatXML  =@ddxml,  
			  @NumXML  =@NumXML,  
			  @TextXML  =@TextXML,  
			  @CCXML  =@CCXML, 
			  @ExtraXML  =@ExtraXML,
			  @DocExtraXML= N'', 
			  @BillWiseXML = @bxml,      
			  @NotesXML = N'',      
			  @AttachmentsXML = N'',    
			  @ActivityXML = @SQL,       
			  @IsImport = 0,      
			  @LocationID = @LocationID,      
			  @DivisionID = @DivisionID ,      
			  @WID = @TEmpWid,      
			  @RoleID = @RoleID,      
			  @DocAddress = N'',      
			  @RefCCID = 300,    
			  @RefNodeid  = @InvDocDetailsID,    
			  @CompanyGUID = @CompanyGUID,      
			  @UserName = @UserName,      
			  @UserID = @UserID,      
			  @LangID = @LangID    
		END	
		
		--Excess of stock
		set @TEMPxml=''
		SELECT @TEMPxml=CONVERT(NVARCHAR(MAX), X.query('ExcessXML'))
		from @XML.nodes('/XML') as Data(X)
		if(@TEMPxml<>'')
		begin
			select @PrefValue=Value from @TblPref where IsGlobal=0 and  Name='ExcessDOC'    

			set @AUTOCCID=0
			set @varxml=@TEMPxml
			set @AUTOCCID=convert(bigint,@PrefValue)
			
			SELECT @ddxml=CONVERT(NVARCHAR(MAX), X.query('DocXML'))
			from @varxml.nodes('/ExcessXML') as Data(X)
			SELECT @NumXML=CONVERT(NVARCHAR(MAX), X.query('NumXML'))
			from @varxml.nodes('/ExcessXML') as Data(X)
			SELECT @TextXML=CONVERT(NVARCHAR(MAX), X.query('TextXML'))
			from @varxml.nodes('/ExcessXML') as Data(X)
			SELECT @CCXML=CONVERT(NVARCHAR(MAX), X.query('CCXML'))
			from @varxml.nodes('/ExcessXML') as Data(X)
			SELECT @AccXML=CONVERT(NVARCHAR(MAX), X.query('AccXML'))
			from @varxml.nodes('/ExcessXML') as Data(X)
			SELECT @EXTRAXML=CONVERT(NVARCHAR(MAX), X.query('EXTRAXML'))
			from @varxml.nodes('/ExcessXML') as Data(X)
		
			SELECT @bxml=CONVERT(NVARCHAR(MAX), X.query('BillXML'))
			from @varxml.nodes('/ExcessXML') as Data(X)
			
			SELECT @SQL=CONVERT(NVARCHAR(MAX), X.query('ActXML'))
			from @varxml.nodes('/ExcessXML') as Data(X)
			
			set @SQL=Replace(@SQL,'<ActXML','<XML')


			set @TEmpWid=0
			SELECT @TEmpWid=X.value('@WOrkFlowID','bigint')
			from @varxml.nodes('/ExcessXML') as Data(X)
			
			
			set @Prefix=''
			EXEC [sp_GetDocPrefix] @ddxml,@DocDate,@AUTOCCID,@Prefix output,@InvDocDetailsID,0,0
			
			
			EXEC @return_value = [dbo].[spDOC_SetTempBulkInvDoc]      
			  @CostCenterID = @AUTOCCID,      
			  @DocID = 0,      
			  @DocPrefix = @Prefix,      
			  @DocNumber = N'',      
			  @DocDate = @DocDate,      
			  @DueDate = NULL,      
			  @BillNo = @BillNo,      
			  @AccXML  =@AccXML,  
			  @StatXML  =@ddxml,  
			  @NumXML  =@NumXML,  
			  @TextXML  =@TextXML,  
			  @CCXML  =@CCXML,
			  @EXTRAXML=@EXTRAXML   ,     
			  @DocExtraXML= N'', 
			  @BillWiseXML = @bxml,      
			  @NotesXML = N'',      
			  @AttachmentsXML = N'',    
			  @ActivityXML = @SQL,			       
			  @IsImport = 0,      
			  @LocationID = @LocationID,      
			  @DivisionID = @DivisionID ,      
			  @WID = @TEmpWid,      
			  @RoleID = @RoleID,      
			  @DocAddress = N'',      
			  @RefCCID = 300,    
			  @RefNodeid  = @InvDocDetailsID,    
			  @CompanyGUID = @CompanyGUID,      
			  @UserName = @UserName,      
			  @UserID = @UserID,      
			  @LangID = @LangID    
		END
			
  end
	
	
	if(@LineWiseApproval=0 and (@AppRejDate is not null or @WID<>0) and @level is not null)
		begin
			if(@STATUSID=369 and @oldStatus not in (441,369))
			begin
				INSERT INTO COM_Approvals    
						(CCID,CCNODEID,StatusID,Date,Remarks,UserID,CompanyGUID,GUID,CreatedBy,CreatedDate,WorkFlowLevel,DocDetID)      
				VALUES(@COSTCENTERID,@DOCID,441,CONVERT(FLOAT,@AppRejDate),@Remarks,@UserID,@CompanyGUID    
						,newid(),@UserName,@Dt,@level,0)
				--set @Remarks='Workflow'		
				--set @AppRejDate=getdate()
				--Post Notification 
				EXEC spCOM_SetNotifEvent 441,@CostCenterID,@DocID,@CompanyGUID,@UserName,@UserID,@RoleID
				
			end
			
			if(@AppRejDate is not null and @WID>0 and @StatusID=369)
			BEGIN
				select @CaseNumber=isnull(SysColumnName,'') from ADM_CostCenterDef WITH(NOLOCK)
				where CostCenterID=@CostCenterID and LocalReference=79 and LinkData=55499
				if(@CaseNumber is not null and @CaseNumber like 'dcalpha%')
				BEGIN
					set @SQL='update [COM_DocTextData]
					set '+@CaseNumber+'='''+CONVERT(nvarchar,@AppRejDate)+'''
					from INV_DOcDetails d with(nolock)
					where d.InvDocDetailsID=COM_DocTextData.InvDocDetailsID and DOCID='+convert(nvarchar,@DocID)
					exec(@SQL)
				END
			end
			
			INSERT INTO COM_Approvals    
					(CCID,CCNODEID,StatusID,Date,Remarks,UserID,CompanyGUID,GUID,CreatedBy,CreatedDate,WorkFlowLevel,DocDetID)      
			VALUES(@COSTCENTERID,@DOCID,@STATUSID,CONVERT(FLOAT,@AppRejDate),@Remarks,@UserID,@CompanyGUID    
					,newid(),@UserName,@Dt,@level,0)  
			--Post Notification 
			EXEC spCOM_SetNotifEvent @STATUSID,@CostCenterID,@DocID,@CompanyGUID,@UserName,@UserID,@RoleID
		
	END	
	if (@StatusID=369 and @HistoryStatus='Add' and exists(select Value from @TblPref where Name='DocDateasPostedDate' and Value='true'))
	BEGIN
	
		update inv_docdetails
		set docdate=floor(@dt)
		where costcenterid=@CostCenterID and DocID=@DocID
		
		update acc_docdetails
		set docdate=floor(@dt)
		from ACC_DocDetails a WITH(NOLOCK) 
		join INV_DocDetails b WITH(NOLOCK)  on a.InvDocDetailsID=b.InvDocDetailsID
		where b.CostCenterID=@CostCenterID and b.DocID=@DocID
		
		update COM_Billwise 
		set docdate=floor(@dt)
		where DocNo=@VoucherNo
	END

	
COMMIT TRANSACTION  
--ROLLBACK TRANSACTION  

     
select @temp=ResourceData from COM_Status S  WITH(NOLOCK)   
join COM_LanguageResources R WITH(NOLOCK) on R.ResourceID=S.ResourceID and R.LanguageID=@LangID
where S.StatusID=@StatusID    
     
SELECT ErrorMessage + '   ' + isnull(@VoucherNo,'voucherempty') +' ['+@temp+']'  as ErrorMessage,ErrorNumber,@VoucherNo VoucherNo,@StatusID StatusID
FROM COM_ErrorMessages WITH(nolock)
WHERE ErrorNumber=105 AND LanguageID=@LangID

SET NOCOUNT OFF;        
RETURN @DocID
END TRY        
BEGIN CATCH  

	 if(@return_value is not null and  @return_value=-999 or @DimesionNodeID=-999)         
	 return -999
 --Return exception info [Message,Number,ProcedureName,LineNumber]      
 IF ERROR_NUMBER()=50000      
 BEGIN     
 IF ISNUMERIC(ERROR_MESSAGE())<>1
 BEGIN
	SELECT ERROR_MESSAGE() ErrorMessage
 END
  
  else if(ERROR_MESSAGE()=-127)    
  begin    
   set @VoucherNo=(select top 1 VoucherNo from [INV_DocDetails] WITH(NOLOCK) where LinkedInvDocDetailsID in (SELECT InvDocDetailsID FROM [INV_DocDetails]    
   WHERE CostCenterID=@CostCenterID AND DocPrefix=@DocPrefix AND DocNumber=@DocNumber))    
       
   SELECT ErrorMessage+' '+@VoucherNo as ErrorMessage,ErrorNumber FROM COM_ErrorMessages WITH(nolock) WHERE ErrorNumber=ERROR_MESSAGE() AND LanguageID=@LangID    
  end    

   else IF (ERROR_MESSAGE() LIKE '-346' )    
  BEGIN    
   SELECT   @TYPE +  replace(ErrorMessage,'#ROWNO#',CONVERT(NVARCHAR, @I -1 ) )  + @QUERYTEST ErrorMessage, ERROR_MESSAGE() AS ServerMessage,ERROR_NUMBER() as ErrorNumber, ERROR_PROCEDURE()as     
   ProcedureName, ERROR_LINE() AS ErrorLine  FROM COM_ErrorMessages WITH(nolock)      
   WHERE ErrorNumber=-346 AND LanguageID=@LangID      
  END 
  else IF (ERROR_MESSAGE() in('-364','-541','-542','-549'))    
  BEGIN    
   SELECT   replace(ErrorMessage,'##PROD##',@ProductName)  + CONVERT(NVARCHAR, @I -1 ) ErrorMessage, ERROR_MESSAGE() AS ServerMessage,ERROR_NUMBER() as ErrorNumber, ERROR_PROCEDURE()as     
   ProcedureName, ERROR_LINE() AS ErrorLine  FROM COM_ErrorMessages WITH(nolock)      
   WHERE ErrorNumber=ERROR_MESSAGE()  AND LanguageID=@LangID      
  END  
  else IF (ERROR_MESSAGE() in('-380','-387','-406','-510','-509','-511','-521','-537','-538','-566'))    
  BEGIN    
	  SELECT ErrorMessage + @ProductName  as ErrorMessage , ERROR_MESSAGE() AS ServerMessage,ERROR_NUMBER() as ErrorNumber, ERROR_PROCEDURE()as ProcedureName, ERROR_LINE() AS ErrorLine FROM COM_ErrorMessages WITH(nolock)      
	  WHERE ErrorNumber=ERROR_MESSAGE() AND LanguageID=@LangID        
  END   
  else IF (ERROR_MESSAGE() ='-407')
  BEGIN    
	  SELECT ErrorMessage + @SQL  as ErrorMessage , ERROR_MESSAGE() AS ServerMessage,ERROR_NUMBER() as ErrorNumber, ERROR_PROCEDURE()as ProcedureName, ERROR_LINE() AS ErrorLine FROM COM_ErrorMessages WITH(nolock)      
	  WHERE ErrorNumber=ERROR_MESSAGE() AND LanguageID=@LangID        
  END   
  ELSE IF (ERROR_MESSAGE() LIKE '-347' )    
  BEGIN    
   SELECT   @TYPE + ErrorMessage  + @QUERYTEST  as ErrorMessage, ERROR_MESSAGE() AS ServerMessage,ERROR_NUMBER() as ErrorNumber, ERROR_PROCEDURE()as     
   ProcedureName, ERROR_LINE() AS ErrorLine  FROM COM_ErrorMessages WITH(nolock)      
   WHERE ErrorNumber=-347 AND LanguageID=@LangID      
  END    
 ELSE IF (ERROR_MESSAGE() LIKE '-374')     
 BEGIN      
  SELECT ErrorMessage + @ProductName  as ErrorMessage , ERROR_MESSAGE() AS ServerMessage,ERROR_NUMBER() as ErrorNumber, ERROR_PROCEDURE()as ProcedureName, ERROR_LINE() AS ErrorLine FROM COM_ErrorMessages WITH(nolock)      
  WHERE ErrorNumber=ERROR_MESSAGE() AND LanguageID=@LangID      
 END   
  ELSE IF (ERROR_MESSAGE() LIKE '-389')     
 BEGIN      
	   select @VoucherNo=VoucherNo from [INV_DocDetails] WITH(NOLOCK) where [LinkedInvDocDetailsID]=@LinkedID

  SELECT ErrorMessage + @VoucherNo  as ErrorMessage , ERROR_MESSAGE() AS ServerMessage,ERROR_NUMBER() as ErrorNumber, ERROR_PROCEDURE()as ProcedureName, ERROR_LINE() AS ErrorLine FROM COM_ErrorMessages WITH(nolock)      
  WHERE ErrorNumber=ERROR_MESSAGE() AND LanguageID=@LangID      
 END 
  ELSE IF (ERROR_MESSAGE() in('-375','-547'))     
 BEGIN      
  SELECT ErrorMessage + @ProductName   as ErrorMessage , ERROR_MESSAGE() AS ServerMessage,ERROR_NUMBER() as ErrorNumber, ERROR_PROCEDURE()as ProcedureName, ERROR_LINE() AS ErrorLine FROM COM_ErrorMessages WITH(nolock)      
  WHERE ErrorNumber=ERROR_MESSAGE() AND LanguageID=@LangID      
 END   
 ELSE IF (ERROR_MESSAGE() = '-377' or ERROR_MESSAGE() = '-502' or ERROR_MESSAGE() = '-532' )     
 BEGIN      
  SELECT (ErrorMessage +  CONVERT(NVARCHAR, @I -1 ))  AS ErrorMessage, ERROR_MESSAGE() AS ServerMessage,ERROR_NUMBER() as ErrorNumber, ERROR_PROCEDURE()as ProcedureName, ERROR_LINE() AS ErrorLine FROM COM_ErrorMessages WITH(nolock)      
  WHERE ErrorNumber=ERROR_MESSAGE() AND LanguageID=@LangID      
 END   
 ELSE IF (ERROR_MESSAGE() LIKE '-378' )     
 BEGIN      
  SELECT 'Unique Document Exists: ' + @VoucherNo   as ErrorMessage , ERROR_MESSAGE() AS ServerMessage,ERROR_NUMBER() as ErrorNumber, ERROR_PROCEDURE()as ProcedureName, ERROR_LINE() AS ErrorLine 
  --FROM COM_ErrorMessages WITH(nolock)      
  --WHERE ErrorNumber=-375 AND LanguageID=@LangID      
 END   
  ELSE    
  BEGIN    
    --SELECT * FROM INV_DocDetails WITH(nolock) WHERE DocID=@DocID        
    SELECT  ERROR_MESSAGE() AS ServerMessage, ErrorMessage,ErrorNumber, ERROR_NUMBER() as ErrorNumber,ERROR_LINE() AS ErrorLine  FROM COM_ErrorMessages WITH(nolock)       
    WHERE ErrorNumber=ERROR_MESSAGE() AND LanguageID=@LangID      
  END    
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
 ELSE IF ERROR_NUMBER()=1205      
 BEGIN      
  SELECT ErrorMessage, ERROR_MESSAGE() AS ServerMessage,ERROR_NUMBER() as ErrorNumber, ERROR_PROCEDURE()as ProcedureName, ERROR_LINE() AS ErrorLine FROM COM_ErrorMessages WITH(nolock)      
  WHERE ErrorNumber=-350 AND LanguageID=@LangID      
 END    
 ELSE      
 BEGIN      
  SELECT ErrorMessage, ERROR_MESSAGE() AS ServerMessage,ERROR_NUMBER() as ErrorNumber, ERROR_PROCEDURE()as ProcedureName, ERROR_LINE() AS ErrorLine      
  FROM COM_ErrorMessages WITH(nolock) WHERE ErrorNumber=-999 AND LanguageID=@LangID      
 END    
 if(@return_value is null or  @return_value<>-999)   
 ROLLBACK TRANSACTION      
 SET NOCOUNT OFF        
 RETURN -999         
    
END CATCH
GO

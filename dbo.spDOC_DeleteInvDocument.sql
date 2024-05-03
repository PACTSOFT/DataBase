USE PACT2C222
GO
SET ANSI_NULLS, QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spDOC_DeleteInvDocument]
	@CostCenterID [int],
	@DocPrefix [nvarchar](50),
	@DocNumber [nvarchar](500),
	@DocID [bigint],
	@LockWhere [nvarchar](max) = '',
	@UserID [int] = 0,
	@UserName [nvarchar](100),
	@LangID [int] = 1,
	@RoleID [int] = 0
WITH ENCRYPTION, EXECUTE AS CALLER
AS
BEGIN TRANSACTION      
BEGIN TRY      
SET NOCOUNT ON;    
  --Declaration Section    
  DECLARE @HasAccess bit,@VoucherNo nvarchar(200),@PrefValue NVARCHAR(500),@NodeID bigint
  DECLARE @sql nvarchar(max),@tablename nvarchar(200),@CurrentNo bigint,@return_value int
  declare @AccDocID bigint,@DELETECCID BIGINT ,@DocumentType int,@CompanyGUID nvarchar(200),@DeleteDocID BIGINT
  declare @bi int,@bcnt int,@VoucherType int,@InvDocDetailsID bigint ,@DocDate datetime  ,@NID bigint
  DECLARE @ConsolidatedBatches nvarchar(50),@Tot float,@BatchID Bigint,@WHERE nvarchar(max)
  
  DECLARE @TblPref AS TABLE(Name nvarchar(100),Value nvarchar(max))
	INSERT INTO @TblPref
	SELECT Name,Value FROM ADM_GlobalPreferences with(nolock)
	WHERE Name IN ('DW Batches','LW Batches','Maintain Dimensionwise Batches','EnableLocationWise','ConsiderUnAppInHold','EnableDivisionWise')
	
	--SP Required Parameters Check
	IF(@CostCenterID<40000 or (@DocNumber='' and (@DocID is null or @DocID=0)))
	BEGIN
		RAISERROR('-100',16,1)
	END


	--User acces check
	SET @HasAccess=dbo.fnCOM_HasAccess(@RoleID,@CostCenterID,4)

	IF @HasAccess=0
	BEGIN
		RAISERROR('-105',16,1)
	END
	
	if(@DocID>0)
		SELECT @DocDate=convert(datetime,DocDate),@VoucherNo=VoucherNo,@DocPrefix=DocPrefix,@DocNumber=DocNumber,@DocumentType=DocumentType,@VoucherType=VoucherType FROM [INV_DocDetails] with(nolock)
		WHERE CostCenterID=@CostCenterID AND DocID=@DocID 
	ELSE
		SELECT @DocDate=convert(datetime,DocDate),@VoucherNo=VoucherNo,@DocID=DocID,@DocumentType=DocumentType,@VoucherType=VoucherType  FROM [INV_DocDetails] with(nolock)
		WHERE CostCenterID=@CostCenterID AND DocPrefix=@DocPrefix AND DocNumber=@DocNumber
	
	IF @DocID IS NULL
	BEGIN
		COMMIT TRANSACTION         
		SET NOCOUNT OFF; 
		SELECT ErrorMessage,ErrorNumber FROM COM_ErrorMessages WITH(nolock) 
		WHERE ErrorNumber=102 AND LanguageID=@LangID  
		RETURN 1	
	END	
	
	DECLARE @DLockFromDate DATETIME,@DLockToDate DATETIME,@DAllowLockData BIT ,@DLockCC bigint  
	DECLARE @LockFromDate DATETIME,@LockToDate DATETIME,@AllowLockData BIT,@LockCC bigint,@LockCCValues nvarchar(max)     
	declare @caseTab table(id int identity(1,1),CaseID BIGINT,fldName nvarchar(50))
	declare @CaseID BIGINT,@iUNIQ int,@UNIQUECNT int
		
 SELECT @AllowLockData=CONVERT(BIT,Value) FROM ADM_GlobalPreferences with(nolock) WHERE Name='Lock Data Between'       
 SELECT @DAllowLockData=CONVERT(BIT,PrefValue) FROM COM_DocumentPreferences WITH(NOLOCK) where CostCenterID=@CostCenterID and  PrefName='Lock Data Between'  
   
 if(dbo.fnCOM_HasAccess(@RoleID,43,193)=0 and (SELECT PrefValue FROM COM_DocumentPreferences WITH(NOLOCK) where CostCenterID=@CostCenterID and  PrefName='OverrideLock')<>'true')  
 BEGIN  
  IF (@AllowLockData=1)  
  BEGIN   
   SELECT @LockFromDate=CONVERT(DATETIME,Value) FROM ADM_GlobalPreferences with(nolock) WHERE Name='LockDataFromDate'      
   SELECT @LockToDate=CONVERT(DATETIME,Value) FROM ADM_GlobalPreferences with(nolock) WHERE Name='LockDataToDate'      
   SELECT @LockCC=CONVERT(BIGINT,Value) FROM ADM_GlobalPreferences with(nolock) WHERE Name='LockCostCenters' and isnumeric(Value)=1  
  
   if(@DocDate BETWEEN @LockFromDate AND @LockToDate)  
   BEGIN  
     if(@LockCC is null or @LockCC=0)  
		RAISERROR('-125',16,1)    
     else if(@LockCC>50000)  
     BEGIN  
		  SELECT @LockCCValues=CONVERT(BIGINT,Value) FROM ADM_GlobalPreferences with(nolock) WHERE Name='LockCostCenterNodes'  
	  
		  set @LockCCValues= rtrim(@LockCCValues)  
		  set @LockCCValues=substring(@LockCCValues,0,len(@LockCCValues)- charindex(',',reverse(@LockCCValues))+1)  
	  
		  set @sql ='if exists (select a.InvDocDetailsID FROM  [COM_DocCCData] a  
		  join [Inv_DocDetails] b with(nolock) on a.InvDocDetailsID=b.InvDocDetailsID  
		  WHERE b.CostCenterID='+convert(nvarchar,@CostCenterID)+' AND b.docid='+convert(nvarchar,@DocID)+' and a.dcccnid'+convert(nvarchar,(@LockCC-50000))+' in('+@LockCCValues+'))  
		  RAISERROR(''-125'',16,1)  '  
		  exec(@sql)  
     END  
   END      
  END  
  
  if(dbo.fnCOM_HasAccess(@RoleID,43,193)=0 and @LockWhere <>'')
  BEGIN
	if(@LockWhere like '<XML%')
		BEGIN
			declare @xml xml
			set @xml=@LockWhere					
			select @LockWhere=isnull(X.value('@where','nvarchar(max)'),''),@LockCCValues=isnull(X.value('@join','nvarchar(max)'),'')
			from @xml.nodes('/XML') as Data(X)  
			 set @sql ='if exists (select a.CostCenterID from INV_DocDetails a WITH(NOLOCK)
			join COM_DocCCData b WITH(NOLOCK) on a.InvDocDetailsID=b.InvDocDetailsID
			join ADM_DimensionWiseLockData c  WITH(NOLOCK) on a.DocDate between c.fromdate and c.todate and c.isEnable=1 '+@LockCCValues+'
			where  a.CostCenterID='+convert(nvarchar,@CostCenterID)+' AND a.docid='+convert(nvarchar,@DocID)+@LockWhere+')  
			RAISERROR(''-125'',16,1)  '  
	END
	ELSE
	BEGIN	
	  set @sql ='if exists (select a.CostCenterID from INV_DocDetails a WITH(NOLOCK)
			join COM_DocCCData b WITH(NOLOCK) on a.InvDocDetailsID=b.InvDocDetailsID
			join ADM_DimensionWiseLockData c  WITH(NOLOCK) on a.DocDate between c.fromdate and c.todate and c.isEnable=1 
			where  a.CostCenterID='+convert(nvarchar,@CostCenterID)+' AND a.docid='+convert(nvarchar,@DocID)+@LockWhere+')  
			RAISERROR(''-125'',16,1)  '  
	END		
      exec(@sql)
  END  
    
  IF (@DAllowLockData=1)  
  BEGIN  
   SELECT @DLockFromDate=CONVERT(DATETIME,PrefValue) FROM COM_DocumentPreferences WITH(NOLOCK) where CostCenterID=@CostCenterID and  PrefName='LockDataFromDate'  
   SELECT @DLockToDate=CONVERT(DATETIME,PrefValue) FROM COM_DocumentPreferences WITH(NOLOCK) where CostCenterID=@CostCenterID and  PrefName='LockDataToDate'  
   SELECT @DLockCC=CONVERT(BIGINT,PrefValue) FROM COM_DocumentPreferences WITH(NOLOCK) where CostCenterID=@CostCenterID and  PrefName='LockCostCenters' and isnumeric(PrefValue)=1  
    
   if(@DocDate BETWEEN @DLockFromDate AND @DLockToDate)  
   BEGIN  
    if(@DLockCC is null or @DLockCC=0)  
		RAISERROR('-125',16,1)    
     else if(@DLockCC>50000)  
     BEGIN  
		  SELECT @LockCCValues=CONVERT(BIGINT,PrefValue) FROM COM_DocumentPreferences with(nolock) WHERE CostCenterID=@CostCenterID and  PrefName='LockCostCenterNodes'  
	  
		  set @LockCCValues= rtrim(@LockCCValues)  
		  set @LockCCValues=substring(@LockCCValues,0,len(@LockCCValues)- charindex(',',reverse(@LockCCValues))+1)  
	  
		  set @sql ='if exists (select a.InvDocDetailsID FROM  [COM_DocCCData] a  
		  join [INV_DocDetails] b with(nolock) on a.InvDocDetailsID=b.InvDocDetailsID  
		  WHERE b.CostCenterID='+convert(nvarchar,@CostCenterID)+' AND b.docid='+convert(nvarchar,@DocID)+' and a.dcccnid'+convert(nvarchar,(@DLockCC-50000))+' in('+@LockCCValues+'))  
		  RAISERROR(''-125'',16,1)  '  
		  
		  exec(@sql)  
     END   
   END         
  END  
 END  
	
	
	
	
	
	select @PrefValue=Value from ADM_GlobalPreferences with(nolock) where Name='Check for -Ve Stock'  	
  
	if(@PrefValue is not null and @PrefValue='true' and @DocID>0 and (@VoucherType=1 or @DocumentType in(5,30)))
	BEGIN
		select @PrefValue=PrefValue from COM_DocumentPreferences where CostCenterID=@CostCenterID and PrefName='DonotupdateInventory'    
		if(@PrefValue is not null and @PrefValue='false')
		BEGIN		
			select @HasAccess=Value from @TblPref where Name='ConsiderUnAppInHold'    

			EXEC @return_value = [spDOC_Validate]      
				@InvDocXML ='', 
				@DocID =@DocID,
				@DocDate =@DocDate,
				@IsDel=1,
				@ActivityXML='',
				@docType=@DocumentType,
				@ConsiderUnAppInHold=@HasAccess,
				@UserName =@UserName,
				@LangID =@LangID
		END			
	END
	
	if exists(select b.DocID from INV_DocDetails a WITH(NOLOCK) 
	join INV_DocDetails b WITH(NOLOCK) on A.InvDocDetailsId=b.refnodeid and b.refccid=300
	where a.CostCenterID=@CostCenterID AND a.DocID=@DocID)
	begin
	
		select @DeleteDocID=b.DocID,@DELETECCID = b.CostCenterID from INV_DocDetails a WITH(NOLOCK) 
		join INV_DocDetails b WITH(NOLOCK) on A.InvDocDetailsId=b.refnodeid and b.refccid=300
		where a.CostCenterID=@CostCenterID AND a.DocID=@DocID
		  
	     
	    WHILE(@DeleteDocID>0)
		BEGIN 
		    
			 EXEC @return_value = [spDOC_DeleteInvDocument]      
			@CostCenterID = @DELETECCID,      
			@DocPrefix = '',      
			@DocNumber = '', 
			@DocID=@DeleteDocID,     
			@UserID = @UserID,      
			@UserName = @UserName,      
			@LangID = @LangID ,
			@RoleID=@RoleID
			
			set @DeleteDocID=0
			
			select @DeleteDocID=b.DocID,@DELETECCID = b.CostCenterID from INV_DocDetails a WITH(NOLOCK) 
			join INV_DocDetails b WITH(NOLOCK) on A.InvDocDetailsId=b.refnodeid and b.refccid=300
			where a.CostCenterID=@CostCenterID AND a.DocID=@DocID
		END	
	end	
	
	if (@DocumentType<>32 and exists(select a.LinkedInvDocDetailsID from [INV_DocDetails] a with(nolock) 
	join [INV_DocDetails] b with(nolock)  on a.InvDocDetailsID=b.LinkedInvDocDetailsID
	WHERE a.CostCenterID=@CostCenterID AND a.DocID=@DocID))
	begin			
		RAISERROR('-127',16,1)
	end

	if exists(select a.LinkedInvDocDetailsID from [INV_DocDetails] a with(nolock) 
	join [INV_DocExtraDetails] b with(nolock)  on a.InvDocDetailsID=b.RefID
	WHERE a.CostCenterID=@CostCenterID AND a.DocID=@DocID and b.Type=1)
	begin	
			select @VoucherNo=c.Voucherno from [INV_DocDetails] a with(nolock) 
			join [INV_DocExtraDetails] b with(nolock)  on a.InvDocDetailsID=b.RefID
			join [INV_DocDetails] c with(nolock)  on b.InvDocDetailsID=c.InvDocDetailsID
			WHERE a.CostCenterID=@CostCenterID AND a.DocID=@DocID and b.Type=1
			
			RAISERROR('-566',16,1)
	end
	
	if exists(select PrefValue from COM_DocumentPreferences where CostCenterID=@CostCenterID and  PrefName='BackTrack' and PrefValue='True')
	BEGIN
			update c
			set LinkedFieldValue=c.LinkedFieldValue+b.[Quantity]
			from INV_DocDetails a WITH(NOLOCK)    
			join INV_DocExtraDetails b WITH(NOLOCK)    on a.InvDocDetailsID=b.[RefID]
			join INV_DocDetails  c WITH(NOLOCK)  on b.InvDocDetailsID=c.InvDocDetailsID
			where b.type=10 and a.CostCenterID=@CostCenterID AND a.DocID=@DocID
	END
	
	if(@DocumentType=32)
	BEGIN
		update INV_DocDetails
		set StatusID=443
		from (select LinkedInvDocDetailsID id from INV_DocDetails WITH(NOLOCK) 
		where CostCenterID=@CostCenterID AND DocID=@DocID) as t
		where InvDocDetailsID=t.id
		
	END
	
	--CHECK AUDIT TRIAL ALLOWED AND INSERTING AUDIT TRIAL DATA    
	DECLARE @AuditTrial BIT,@dt FLOAT
	SET @AuditTrial=0    
	SELECT @AuditTrial=CONVERT(BIT,PrefValue)  FROM [COM_DocumentPreferences] with(nolock)    
	WHERE CostCenterID=@CostCenterID AND PrefName='AuditTrial'    
	    
    SET @dt=CONVERT(FLOAT,GETDATE())

	IF (@DocID is not null and @DocID>0 and @AuditTrial=1)  
	BEGIN
		INSERT INTO INV_DocDetails_History_ATUser(DocType,DocID,VoucherNo,ActionType,ActionTypeID,UserID,CreatedBy,CreatedDate)
		VALUES(@CostCenterID,@DocID,@VoucherNo,'Delete',3,@UserID,@UserName,@dt)			
		
		declare @ModDate float
		set @ModDate=convert(float,getdate())
		EXEC @return_value = [spDOC_SaveHistory]      
			@DocID =@DocID ,
			@HistoryStatus='Delete',
			@Ininv =1,
			@ReviseReason ='',
			@LangID =@LangID,
			@UserName=@UserName,
			@ModDate=@ModDate,
			@CCID=@CostCenterID
	END    
	     
	
	if exists(select AccDocDetailsID from acc_docdetails with(nolock) where refccid=300 and refnodeid=@DocID)
	begin
			 
		SELECT @DeleteDocID=DocID , @DELETECCID = COSTCENTERID FROM ACC_DocDetails with(nolock)   
		where refccid=300 and refnodeid=@DocID	
		
		while(@DeleteDocID>0)
		BEGIN	    
			
			 EXEC @return_value = [dbo].[spDOC_DeleteAccDocument]  
			 @CostCenterID = @DELETECCID,  
			 @DocPrefix = '',  
			 @DocNumber = '',  
			 @DOCID=@DeleteDocID,
			 @UserID = @UserID,  
			 @UserName = @UserName,  
			 @LangID = @LangID,
			 @RoleID=@RoleID
			 
			 set @DeleteDocID=0
			 
			 SELECT @DeleteDocID=DocID , @DELETECCID = COSTCENTERID FROM ACC_DocDetails with(nolock)   
			where refccid=300 and refnodeid=@DocID	
			 
		END	 		 
	end	
	
	if (@documenttype=5 and exists(SELECT PrefValue FROM COM_DocumentPreferences WITH(NOLOCK) 
	where CostCenterID=@COSTCENTERID and PrefName='IsBudgetDocument' and (PrefValue='1' or PrefValue='true')))
	begin		
	
		select @CompanyGUID=CompanyGUID FROM [COM_DocID] WITH(NOLOCK) WHERE ID=@DocID
		
		exec [spDoc_UpdateBudget] @CostCenterID,@DOCID,@CompanyGUID,@UserName,1
	END
	
	
	--ondelete External function
	set @tablename=''
	select @tablename=SpName from ADM_DocFunctions a WITH(NOLOCK) where CostCenterID=@CostCenterID and Mode=8
	if(@tablename<>'')
		exec @tablename @CostCenterID,@DocID,'',@UserID,@LangID
	
	 
		
	SELECT @CurrentNo=CurrentCodeNumber   FROM COM_CostCenterCodeDef with(nolock)
	WHERE CostCenterID=@CostCenterID AND CodePrefix=@DocPrefix

	if(@CurrentNo=convert(bigint,@DocNumber))
	begin
		UPDATE COM_CostCenterCodeDef     
		SET CurrentCodeNumber=convert(bigint,@DocNumber)-1
		WHERE CostCenterID=@CostCenterID AND CodePrefix=@DocPrefix  
	end
	
	select @PrefValue=PrefValue from COM_DocumentPreferences with(nolock)
	where CostCenterID=@CostCenterID and PrefName='DocumentLinkDimension'
	
	if(@PrefValue is not null and @PrefValue<>'' and ISNUMERIC(@PrefValue)=1)
	begin
		declare @Dimesion bigint
		set @Dimesion=0
		begin try
			select @Dimesion=convert(bigint,@PrefValue)
		end try
		begin catch
			set @Dimesion=0
		end catch
		
		if(@Dimesion>0)
		begin 
			if exists(select PrefValue from COM_DocumentPreferences with(nolock)
			where CostCenterID=@CostCenterID and PrefName='GenerateSeq' and PrefValue='true')
			BEGIN
				SET @sql='select dcCCNID'+CONVERT(NVARCHAR,(@Dimesion-50000))+' from COM_DocCCData a with(nolock)
					join Inv_DocDetails b with(nolock) on a.InvDocDetailsID =b.InvDocDetailsID
					WHERE COSTCENTERID='+CONVERT(NVARCHAR,@CostCenterID)+' AND DOCID='+CONVERT(NVARCHAR,@DocID)
				
				delete from @caseTab
				INSERT INTO @caseTab(CaseID)
				EXEC(@sql)
				
				delete from @caseTab
				where CaseID=1
				
				SET @sql='UPDATE COM_DocCCData 
				SET dcCCNID'+CONVERT(NVARCHAR,(@Dimesion-50000))+'=1'
				+' WHERE InvDocDetailsID IN (SELECT InvDocDetailsID FROM Inv_DocDetails with(nolock) 
				WHERE COSTCENTERID='+CONVERT(NVARCHAR,@CostCenterID)+' AND DOCID='+CONVERT(NVARCHAR,@DocID)+')'
				
				EXEC(@sql)
				
				select @iUNIQ=MIN(id),@UNIQUECNT=MAX(id) FROM @caseTab
		
				WHILE(@iUNIQ <= @UNIQUECNT)
				BEGIN
					SELECT @CaseID=CaseID FROM @caseTab WHERE id=@iUNIQ
					
					 EXEC @return_value = [dbo].[spCOM_DeleteCostCenter]
						@CostCenterID = @Dimesion,
						@NodeID = @CaseID,
						@RoleID=1,
						@UserID = 1,
						@LangID = @LangID
					 
					SET @iUNIQ=@iUNIQ+1
				END
				
			END
			ELSE
			BEGIN
				select @tablename=tablename from ADM_Features where FeatureID=@Dimesion
				set @sql='select @NodeID=NodeID from '+@tablename+' with(nolock) where Name='''+@VoucherNo+''''
				print @sql
				EXEC sp_executesql @sql,N'@NodeID bigint OUTPUT',@NodeID output
				 
				if(@NodeID>1)
				begin
						 
					SET @sql='UPDATE COM_DocCCData 
					SET dcCCNID'+CONVERT(NVARCHAR,(@Dimesion-50000))+'=1'
					+' WHERE InvDocDetailsID IN (SELECT InvDocDetailsID FROM Inv_DocDetails with(nolock) 
					WHERE COSTCENTERID='+CONVERT(NVARCHAR,@CostCenterID)+' AND DOCID='+CONVERT(NVARCHAR,@DocID)+')'
					
					EXEC(@sql)
					
					EXEC @return_value = [dbo].[spCOM_DeleteCostCenter]
						@CostCenterID = @Dimesion,
						@NodeID = @NodeID,
						@RoleID=1,
						@UserID = 1,
						@LangID = @LangID
				end
			END	
		end
	end	
	
	
	delete from @caseTab
	INSERT INTO @caseTab(CaseID)
	SELECT RefDimensionNodeID FROM COM_DocBridge
	WHERE InvDocID=@DocID AND RefDimensionID=72
					
	select @iUNIQ=MIN(id),@UNIQUECNT=MAX(id) FROM @caseTab

	WHILE(@iUNIQ <= @UNIQUECNT)
	BEGIN
		SELECT @CaseID=CaseID FROM @caseTab WHERE id=@iUNIQ
		
		EXEC @return_value = dbo.spACC_DeleteAsset
			@AssetID =@CaseID,
			@UserID =@UserID,
			@RoleID=@RoleID,
			@LangID =@LangID
		
		SET @iUNIQ=@iUNIQ+1
	end
	
	delete FROM COM_DocBridge
	WHERE InvDocID=@DocID AND RefDimensionID=72
	
	IF(@CostCenterID=40054) -- MONTHLY PAYROLL
	BEGIN
	
		DECLARE @EmpSeqNo BIGINT,@PayrollMonth DATETIME
		SELECT @EmpSeqNo=b.dcCCNID51,@PayrollMonth=CONVERT(DATETIME,a.DueDate)
		FROM INV_DocDetails a WITH(NOLOCK)
		JOIN COM_DocCCData b WITH(NOLOCK) ON b.InvDocDetailsID=a.InvDocDetailsID
		WHERE a.CostCenterID=40054 AND DOCID=@DocID
		
		DELETE FROM PAY_EmpMonthlyArrears WHERE EmpSeqNo=@EmpSeqNo AND PayrollMonth=@PayrollMonth
		DELETE FROM PAY_EmpMonthlyAdjustments WHERE EmpSeqNo=@EmpSeqNo AND PayrollMonth=@PayrollMonth
		DELETE FROM PAY_EmpMonthlyDues WHERE EmpSeqNo=@EmpSeqNo AND PayrollMonth=@PayrollMonth		
		
	END
	IF(@CostCenterID=40065) -- join FromVacation
	BEGIN
	Declare @FrmDt Datetime,@ToDt Datetime,@Emp bigint
	IF((SELECT COUNT(*) FROM INV_DOCDETAILS WITH(NOLOCK) WHERE DOCID=@DOCID AND STATUSID=369)>0)
		BEGIN
			SELECT @FrmDt=CONVERT(DATETIME,TD.DCALPHA1),@ToDt=CONVERT(DATETIME,TD.DCALPHA2),@Emp=Dcccnid51 FROM COM_DOCTEXTDATA TD INNER JOIN INV_DOCDETAILS ID ON TD.INVDOCDETAILSID=ID.INVDOCDETAILSID AND ID.DOCID=@DOCID
			Inner Join com_DocccData cc on cc.invDocdetailsid=ID.invDocdetailsid Where CostcenterID=40065
			UPDATE TD SET TD.dcAlpha1='' FROM COM_DOCTEXTDATA TD INNER JOIN COM_DOCCCDATA CC ON TD.INVDOCDETAILSID=CC.INVDOCDETAILSID AND CC.dcCCNID51=@Emp
				   INNER JOIN INV_DOCDETAILS ID ON TD.INVDOCDETAILSID=ID.INVDOCDETAILSID And ID.CostCenterId=40072 AND ISDATE(TD.DCALPHA2)=1 AND ISDATE(TD.DCALPHA3)=1
				   AND CONVERT(DATETIME,TD.DCALPHA2)=CONVERT(DATETIME,@FrmDt) AND CONVERT(DATETIME,TD.DCALPHA3)=CONVERT(DATETIME,@ToDt)
		END 
	END
	IF(@CostCenterID=40069) -- Apply Resignation
	BEGIN
	Declare @EmplRes bigint,@RESIGNSTATUS Nvarchar(max),@STRQRY nvarchar(max),@DocFinalSettlement nvarchar(max),@EmpRelDate INT
	IF((SELECT COUNT(*) FROM INV_DOCDETAILS WITH(NOLOCK) WHERE DOCID=@DOCID)>0)
		BEGIN		
		SELECT @EmplRes=cc.dcccnid51,@EmpRelDate=CONVERT(INT,CONVERT(DATETIME,TD.dcAlpha4)) FROM COM_DOCTEXTDATA TD INNER JOIN INV_DOCDETAILS ID ON TD.INVDOCDETAILSID=ID.INVDOCDETAILSID AND ID.DOCID=@DOCID
			Inner Join com_DocccData cc on cc.invDocdetailsid=ID.invDocdetailsid Where CostcenterID=40069
			IF((SELECT COUNT(*) FROM PAY_FinalSettlement WITH(NOLOCK) WHERE EmpSeqNo=@EmplRes)>0)
			BEGIN
				Select @DocFinalSettlement=Convert(nvarchar,DocNo) FROM PAY_FinalSettlement WITH(NOLOCK) WHERE EmpSeqNo=@EmplRes
				RAISERROR('-577',16,1)
			END
			ELSE
			BEGIN
			  SET @STRQRY='UPDATE COM_CC50051 SET  RESIGNREMARKS=NULL,RESIGNTYPE=NULL,RESIGNSTATUS=NULL,DORESIGN=NULL, DOTENTRELIEVE=NULL, DORELIEVE=NULL WHERE NODEID='''+ CONVERT(NVARCHAR,@EmplRes) +''''
			  print @STRQRY
		      EXEC (@STRQRY)
			END

			--deleting the entry in user status
			DECLARE @EmpUserID BIGINT
			SELECT @EmpUserID=ISNULL(UserID,0) From ADM_Users WITH(NOLOCK) Where UserName=(Select Code FROM COM_CC50051 WITH(NOLOCK) WHERE NodeID=@EmplRes)
			IF(@EmpUserID IS NOT NULL AND @EmpUserID<>0)
			BEGIN
				DELETE FROM [COM_CostCenterStatusMap] WHERE CostCenterID=7 AND NodeID=@EmpUserID AND Status=2 AND FromDate=@EmpRelDate AND ToDate IS NULL
			END

	   END
	END
	IF(@CostCenterID=40099) -- Regularization of Attendance
	BEGIN
		DECLARE @TABEMP TABLE (ID BIGINT IDENTITY(1,1),VNo NVARCHAR(600),DocSeqNo NVARCHAR(500),DailyAttDate NVARCHAR(100),EmpNodeID BIGINT)
		DECLARE @I INT,@CNT INT,@VNo NVARCHAR(600),@DocSeqNo NVARCHAR(500),@DailyAttDate NVARCHAR(100),@EmpNodeID BIGINT

		INSERT INTO @TABEMP
		SELECT T.DCALPHA1,T.DCALPHA2,T.DCALPHA3,CC.dcCCNID51 FROM INV_DocDetails I WITH(NOLOCK)
		JOIN COM_DocTextData T WITH(NOLOCK) ON T.InvDocDetailsID=I.InvDocDetailsID
		JOIN COM_DocCCData CC WITH(NOLOCK) ON CC.InvDocDetailsID=I.InvDocDetailsID
		WHERE costcenterid=@CostCenterID AND STATUSID=369 AND T.DCALPHA12='YES' AND DOCID=@DocID

		SELECT @CNT=COUNT(*) FROM @TABEMP
		SET @I=1
		WHILE(@I<=@CNT)
		BEGIN
			SELECT @VNo=VNo,@DocSeqNo=DocSeqNo,@DailyAttDate=DailyAttDate,@EmpNodeID=EmpNodeID FROM @TABEMP WHERE ID=@I 


			UPDATE T SET dcAlpha2=dcAlpha16,dcAlpha3=dcAlpha17 FROM INV_DocDetails I
			JOIN COM_DocTextData T ON T.InvDocDetailsID=I.InvDocDetailsID
			JOIN COM_DocCCData C ON C.InvDocDetailsID=I.InvDocDetailsID
			WHERE DocumentType=67 AND I.VoucherNo=@VNo AND I.DocSeqNo=@DocSeqNo AND C.dcCCNID51=@EmpNodeID AND ISDATE(T.DCALPHA1)=1
			AND CONVERT(DATETIME,T.DCALPHA1)=CONVERT(DATETIME,@DailyAttDate)

			UPDATE T SET dcAlpha16=NULL,dcAlpha17=NULL FROM INV_DocDetails I
			JOIN COM_DocTextData T ON T.InvDocDetailsID=I.InvDocDetailsID
			JOIN COM_DocCCData C ON C.InvDocDetailsID=I.InvDocDetailsID
			WHERE DocumentType=67 AND I.VoucherNo=@VNo AND I.DocSeqNo=@DocSeqNo AND C.dcCCNID51=@EmpNodeID AND ISDATE(T.DCALPHA1)=1
			AND CONVERT(DATETIME,T.DCALPHA1)=CONVERT(DATETIME,@DailyAttDate)

			SET @I=@I+1
		END
	END
	if(@DocumentType=5)
	begin
		if exists (SELECT * FROM COM_DocBridge with(nolock) where CostCenterID=@CostCenterID and NodeID=@DocID and RefDimensionID=132)
			RAISERROR('-138',16,1)
	end
	
	if exists (select PrefValue from COM_DocumentPreferences WITH(NOLOCK) where CostCenterID=@CostCenterID and PrefName='IsBudgetDocument' and PrefValue='1')
	begin
		declare @BudgetID bigint
		SELECT @BudgetID=RefDimensionNodeID FROM COM_DocBridge with(nolock) where CostCenterID=@CostCenterID and NodeID=@DocID and RefDimensionID=101
		if @BudgetID is not null
			exec @return_value=[spADM_DeleteBudgetDetails] @BudgetID,1,@UserID,@LangID
	end
	
	set @sql='SELECT a.InvDocDetailsID,BatchID,LinkedInvDocDetailsID,dcccnid2,dcccnid1,'
	set @PrefValue=''      
	select @PrefValue= isnull(Value,'') from @TblPref where Name='Maintain Dimensionwise Batches'        
	if(@PrefValue is not null and @PrefValue<>'' and convert(bigint,@PrefValue)>0)        	
		set @sql=@sql+'dcCCNID'+convert(nvarchar,(convert(bigint,@PrefValue)-50000)) 
	else
		set @sql=@sql+'0'
		
	set @sql=@sql+' FROM [INV_DocDetails] a with(nolock)
			join COM_DocCCData t with(nolock) on t.InvDocDetailsID=a.InvDocDetailsID
			WHERE CostCenterID='+convert(nvarchar(20),@CostCenterID)+' AND DocID='+convert(nvarchar(20),@DocID )
			
			       
	DECLARE @TblDeleteRows AS Table(idid bigint identity(1,1), ID BIGINT,BatchID BIGINT,linkinv bigint,loc bigint,div bigint,DIM bigint)
	
	insert into  @TblDeleteRows
	exec(@sql)
	
	DELETE T FROM COM_DocCCData t
	join @TblDeleteRows a on t.InvDocDetailsID=a.ID		

	--DELETE DOCUMENT EXTRA NUMERIC FEILD DETAILS      
	DELETE T FROM [COM_DocNumData] t
	join @TblDeleteRows a on t.InvDocDetailsID=a.ID
	
	if(@CostCenterID=40054)
	BEGIN
		set @sql='DELETE T FROM PAY_DocNumData t
		join [INV_DocDetails] a on t.InvDocDetailsID=a.InvDocDetailsID
		WHERE a.CostCenterID='+convert(nvarchar(Max),@CostCenterID)+' AND a.DocID= '+convert(nvarchar(Max),@DocID)
		exec(@sql)
	END
	
	--DELETE DOCUMENT EXTRA TEXT FEILD DETAILS      
	DELETE T FROM [COM_DocTextData] T
	join @TblDeleteRows a on t.InvDocDetailsID=a.ID

	--DELETE Accounts DocDetails      
	DELETE T FROM [ACC_DocDetails] T
	join @TblDeleteRows a on t.InvDocDetailsID=a.ID 
	
	DELETE T FROM INV_BinDetails T
	join @TblDeleteRows a on t.InvDocDetailsID=a.ID
	
	--DELETE Accounts DocDetails      
	DELETE T FROM COM_DocQtyAdjustments T
	join @TblDeleteRows a on t.InvDocDetailsID=a.ID 
	
	DELETE T FROM INV_DocExtraDetails T
	join @TblDeleteRows a on t.InvDocDetailsID=a.ID 

	DELETE T FROM INV_DocExtraDetails T
	join @TblDeleteRows a on t.REFID=a.ID 
	where t.type=10
	
	--to delete stock codes
	if exists(select PrefValue from COM_DocumentPreferences with(nolock)
	where CostCenterID=@CostCenterID and PrefName='DumpStockCodes' and PrefValue='true')    
	BEGIN
		set @tablename=''
		select @tablename=b.TableName from ADM_GlobalPreferences a WITH(NOLOCK) 
		join ADM_Features b on a.Value=b.FeatureID
		where a.Name='POSItemCodeDimension'
		if(@tablename<>'')
		BEGIN
			set @SQL='delete T FROM '+@tablename+' T
			join Inv_DocDetails b with(nolock) on T.InvDocDetailsID =b.InvDocDetailsID
			WHERE b.COSTCENTERID='+CONVERT(NVARCHAR,@CostCenterID)+' AND b.DOCID='+CONVERT(NVARCHAR,@DocID)
				
			exec(@SQL)
		END	
	END


	if exists(select [InvDocDetailsID] from [INV_SerialStockProduct] T
	join @TblDeleteRows a on t.InvDocDetailsID=a.ID)
	BEGIN	
	
		if(@VoucherType=1)
		BEGIN
			if exists(select [SerialNumber]  from [INV_SerialStockProduct] t
			 join @TblDeleteRows a on t.RefInvDocDetailsID=a.ID)
			BEGIN			
				RAISERROR('-508',16,1)
			END	
		END
		ELSE if(@VoucherType=-1)
		BEGIN		
			 UPDATE [INV_SerialStockProduct]      
			 SET [StatusID]=157      
			 ,IsAvailable=1 
			  from ( select [SerialNumber] sno ,SerialGUID sguid,[RefInvDocDetailsID] refinvID,[ProductID] PID from [INV_SerialStockProduct]  t    
			 join @TblDeleteRows a on t.InvDocDetailsID=a.ID) as t
			  where [ProductID]=PID and [SerialNumber]=sno and SerialGUID=sguid and [InvDocDetailsID]=refinvID
		END
		
		DELETE T FROM  [INV_SerialStockProduct]  T
		join @TblDeleteRows a on t.InvDocDetailsID=a.ID	 
	END	
	
	
	DELETE FROM COM_Billwise 
	WHERE DocNo=@VoucherNo
	
	DELETE FROM Com_BillwiseNonAcc 
	WHERE DocNo=@VoucherNo

	DELETE FROM COM_ChequeReturn 
	WHERE DocNo=@VoucherNo
	
	update COM_Billwise 
	set IsNewReference=1,RefDocNo=null,RefDocSeqNo=null,RefDocDate=null,RefDocDueDate=null
	WHERE RefDocNo=@VoucherNo
	
	DELETE FROM COM_Notes 
	WHERE FeatureID=@CostCenterID AND FeaturePK=@DocID

	
	DELETE FROM  COM_Files 
	WHERE FeatureID=@CostCenterID AND FeaturePK=@DocID
	
	DELETE T FROM INV_TempInfo   T
	join @TblDeleteRows a on t.InvDocDetailsID=a.ID	 
	
	DELETE FROM COM_DocDenominations 
	WHERE DOCID=@DocID
	
	DELETE FROM [COM_DocID] WHERE ID=@DocID

	DELETE FROM [INV_DocDetails] 
	WHERE CostCenterID=@CostCenterID AND DocID=@DocID
	
	DELETE FROM com_approvals 
	WHERE CCID=@CostCenterID AND CCNODEID=@DocID
	
	DELETE FROM  CRM_Activities 
	WHERE CostCenterID=@CostCenterID AND NodeID =@DocID
	
	update com_schevents
	set PostedVoucherNo=null,StatusID=1
	where PostedVoucherNo=@VoucherNo
	
	IF (@VoucherType=1 and exists(select Batchid from @TblDeleteRows where BatchID>1))
	BEGIN
		select @bi=0,@bcnt=COUNT(id) from @TblDeleteRows
		while(@bi<@bcnt)		
		BEGIN  		
			set @bi=@bi+1
			set @BatchID=1
			SELECT  @BatchID=BatchID,@InvDocDetailsID=Id from @TblDeleteRows where idid=@bi
			
			if(@BatchID>1)
			BEGIN
				select @ConsolidatedBatches=Value from [COM_CostCenterPreferences] with(nolock)
				where Name='AllowNegativebatches' and costcenterid=16  
				if(@ConsolidatedBatches is null or @ConsolidatedBatches ='' or @ConsolidatedBatches ='false')
				BEGIN
					select @ConsolidatedBatches=Value from [COM_CostCenterPreferences] with(nolock)
					where Name='ConsolidatedBatches' and costcenterid=16  
					if(@ConsolidatedBatches is null and @ConsolidatedBatches ='false')
					begin     
						set @Tot=isnull((SELECT sum(BD.ReleaseQuantity)    
						FROM [INV_DocDetails] AS BD WITH(NOLOCK)                 
						where vouchertype=1 and IsQtyIgnored=0  and batchid=@BatchID and [InvDocDetailsID]=@InvDocDetailsID),0)  

						set @Tot= @Tot-isnull((SELECT sum(BD.UOMConvertedQty)    
						FROM [INV_DocDetails] AS BD  with(nolock)                  
						where vouchertype=-1 and statusid in(369,371,441) and IsQtyIgnored=0  and batchid=@BatchID and RefInvDocDetailsID=@InvDocDetailsID),0)   
					end  
					else  
					begin  
								set @WHERE=''
								if exists(select value from @TblPref where  Name='LW Batches' and Value='true')
									 and exists(select value from @TblPref where  Name='EnableLocationWise' and Value='true')
								BEGIN				
									select @NID=Loc 	from @TblDeleteRows where idid=@bi  
									set @WHERE =@WHERE+' and dcCCNID2='+CONVERT(nvarchar,@NID)        
								END

								if exists(select value from @TblPref where  Name='DW Batches' and Value='true')
								and exists(select value from @TblPref where  Name='EnableDivisionWise' and Value='true')
								BEGIN		
									select @NID=DIV from @TblDeleteRows where idid=@bi		 
									set @WHERE =@WHERE+' and dcCCNID1='+CONVERT(nvarchar,@NID)       
								END
								
								set @PrefValue=''      
								select @PrefValue= isnull(Value,'') from @TblPref where Name='Maintain Dimensionwise Batches'        

								if(@PrefValue is not null and @PrefValue<>'' and convert(bigint,@PrefValue)>0)        
								begin 	
									select @NID=DIM from @TblDeleteRows where idid=@bi		 		 
									set @WHERE =@WHERE+' and dcCCNID'+CONVERT(nvarchar,(convert(bigint,@PrefValue)-50000))+'='+CONVERT(nvarchar,@NID)        
								end 
									  
								set @sql='set @Tot=(SELECT isnull(sum(BD.ReleaseQuantity),0)  
								FROM [INV_DocDetails] AS BD  WITH(NOLOCK)
								join COM_DocCCData c on BD.InvDocDetailsID=c.InvDocDetailsID 
								where vouchertype=1  and statusid=369 and IsQtyIgnored=0 '+@WHERE+' and batchid='+convert(nvarchar,@BatchID)+')  

								set @Tot= @Tot-(SELECT isnull(sum(BD.UOMConvertedQty),0)
								FROM [INV_DocDetails] AS BD  WITH(NOLOCK)                  
								join COM_DocCCData c on BD.InvDocDetailsID=c.InvDocDetailsID  
								where vouchertype=-1 and statusid in(369,371,441) and IsQtyIgnored=0 '+@WHERE+' and batchid='+convert(nvarchar,@BatchID)+')'
								EXEC sp_executesql @sql,N'@Tot float OUTPUT',@Tot output	
				
					end  
				
					if(@Tot<-0.001)   
					begin  
						RAISERROR('-502',16,1)      
					end 
				END	 
			END 
		END
	END  
	
		
		delete from @caseTab
		INSERT INTO @caseTab(CaseID)
		select CaseID FROM CRM_Cases with(nolock) where SvcContractID=@DocID  
		
		select @iUNIQ=MIN(id),@UNIQUECNT=MAX(id) FROM @caseTab
		
		WHILE(@iUNIQ <= @UNIQUECNT)
		BEGIN
			SELECT @CaseID=CaseID FROM @caseTab WHERE id=@iUNIQ
			--SELECT @CaseID
			exec spCRM_DeleteCase @CASEID=@CaseID,@USERID=@UserID,@LangID=@LangID,@RoleID=@RoleID
					
			SET @iUNIQ=@iUNIQ+1
		END
		
		if (@DocumentType=39)
	    BEGIN
		 if exists(select a.VoucherType from COM_PosPayModes a WITH(NOLOCK)
		 join COM_PosPayModes b WITH(NOLOCK) on a.VoucherNodeID=b.VoucherNodeID
		 where b.VoucherType=-1 and a.DOCID=@DocID)
		 BEGIN
				RAISERROR('-525',16,1)  
		 END
		 
		     if exists(select a.VoucherType from COM_PosPayModes a WITH(NOLOCK)
				where DOCID=@DocID and VoucherNodeID>0)
			  BEGIN
					delete from @caseTab
					INSERT INTO @caseTab(CaseID)      
					SELECT VoucherNodeID FROM COM_PosPayModes
					where DOCID=@DocID and VoucherNodeID>0
					
					
					delete from COM_PosPayModes where DOCID=@DocID
		
					
					select @iUNIQ=MIN(id),@UNIQUECNT=MAX(id) FROM @caseTab        
				    
				    select @PrefValue=Value FROM ADM_GlobalPreferences with(nolock) WHERE Name='PosCoupons'    
					set @Dimesion=0
					if(@PrefValue is not null and @PrefValue<>'' and ISNUMERIC(@PrefValue)=1)
					begin						
						begin try
							select @Dimesion=convert(bigint,@PrefValue)
						end try
						begin catch
							set @Dimesion=0
						end catch
					END
				           
					WHILE(@iUNIQ <= @UNIQUECNT and @Dimesion>50000)        
					BEGIN      
					  SELECT @CaseID=CaseID FROM @caseTab WHERE id=@iUNIQ
					  
					  EXEC @return_value = [dbo].[spCOM_DeleteCostCenter]
						@CostCenterID = @Dimesion,
						@NodeID = @CaseID,
						@RoleID=1,
						@UserID = 1,
						@LangID = @LangID
						
				
					  set @iUNIQ=@iUNIQ+1
				    END   
			  END
		END
		
		set @PrefValue=''
		select @PrefValue=PrefValue from COM_DocumentPreferences with(nolock)
		where CostCenterID=@CostCenterID and PrefName='BackTrack'
	
		select @bi=0,@bcnt=COUNT(id) from @TblDeleteRows
		while(@bi<@bcnt)		
		BEGIN  		
			set @bi=@bi+1			
			set @InvDocDetailsID=0
			SELECT  @BatchID=CostCenterID,@InvDocDetailsID=a.linkinv from @TblDeleteRows a
			join INV_DocDetails b on a.linkinv=b.InvDocDetailsID
			where idid=@bi
			
			if(@InvDocDetailsID is not null and @InvDocDetailsID>0)
			BEGIN
				if(@PrefValue='true')
				BEGIN
					SELECT @Tot=isnull(sum(Quantity),0) FROM INV_DocDetails a WITH(NOLOCK)    
					WHERE  LinkedInvDocDetailsID=@InvDocDetailsID and Costcenterid=@CostCenterID

					update INV_DocDetails    
					set LinkedFieldValue=Quantity-@Tot
					where InvDocDetailsID=@InvDocDetailsID
				END
				
				delete from @caseTab
				
				insert into @caseTab(CaseID,fldName)
				select SrcDoc,Fld from COM_DocLinkCloseDetails WITH(NOLOCK)
				where CostCenterID=@CostCenterID and linkedfrom=@BatchID
				
				
				select @iUNIQ=min(id) ,@UNIQUECNT=max(id) from @caseTab
				while(@iUNIQ<=@UNIQUECNT)
				BEGIN
					SELECT @DELETECCID=CaseID,@tablename=fldName from @caseTab where id=@iUNIQ
					
					if(@tablename like 'dcalpha%')
					BEGIN
						set @SQL='SELECT @LockCCValues='+@tablename+' from COM_DocTextData WITH(NOLOCK) where InvDocDetailsID='+convert(nvarchar,@InvDocDetailsID)				
						exec sp_executesql @SQL,N'@LockCCValues nvarchar(max) output',@LockCCValues output
						
						set @SQL='SELECT @Tot=isnull(Quantity,0),@DocumentType=LinkStatusID from INV_DocDetails a WITH(NOLOCK)
							join COM_DocTextData b WITH(NOLOCK) on a.InvDocDetailsID=b.InvDocDetailsID 
							where costcenterid='+CONVERT(nvarchar,@DELETECCID)+' and '+@tablename+'='''+@LockCCValues+''''
								
						exec sp_executesql @SQL,N'@Tot float output,@DocumentType int OUTPUT',@Tot output,@DocumentType OUTPUT
						
						if(@DocumentType=445)
						BEGIN
							set @dt=0
							set @SQL='SELECT @dt=isnull(sum(Quantity),0) from INV_DocDetails a WITH(NOLOCK)
								join COM_DocTextData b WITH(NOLOCK) on a.InvDocDetailsID=b.InvDocDetailsID 
								where a.statusid<>376 and  costcenterid='+convert(nvarchar,@CostCenterID)+' and '+@tablename+'='''+@LockCCValues+''''
										
							exec sp_executesql @SQL,N'@dt float output',@dt output
								select @DocumentType,@Tot,@dt,@LockCCValues
							if(@Tot>@dt and @LockCCValues is not null and @LockCCValues<>'')
							BEGIN
								set @SQL='update INV_DocDetails
								set LinkStatusID=443
								from COM_DocTextData b WITH(NOLOCK) 					
								where INV_DocDetails.InvDocDetailsID=b.InvDocDetailsID
								 and '+@tablename+'='''+@LockCCValues+''''
								
								EXEC(@SQL)
							END
						END	
					END
					set @iUNIQ=@iUNIQ+1
				END
			END	
		END
		
		delete from COM_PosPayModes where DOCID=@DocID
		
	
COMMIT TRANSACTION         
--ROLLBACK TRANSACTION         
SET NOCOUNT OFF;  
SELECT ErrorMessage,ErrorNumber FROM COM_ErrorMessages WITH(nolock) 
WHERE ErrorNumber=102 AND LanguageID=@LangID  
RETURN 1
END TRY
BEGIN CATCH 	

	if(@return_value=-999)
		return -999
	--Return exception info [Message,Number,ProcedureName,LineNumber] 	
	IF ERROR_NUMBER()=50000
	BEGIN
		if(ERROR_MESSAGE()=-127)
		begin
			set @VoucherNo=(select top 1 VoucherNo from [INV_DocDetails] where LinkedInvDocDetailsID in (SELECT InvDocDetailsID FROM [INV_DocDetails]
			WHERE CostCenterID=@CostCenterID AND DocPrefix=@DocPrefix AND DocNumber=@DocNumber))
			
			SELECT ErrorMessage+' '+@VoucherNo as ErrorMessage,ErrorNumber, ERROR_PROCEDURE()as ProcedureName, ERROR_LINE() AS ErrorLine  FROM COM_ErrorMessages WITH(nolock) WHERE ErrorNumber=ERROR_MESSAGE() AND LanguageID=@LangID
		end
		else if(ERROR_MESSAGE()=-502)
		begin			
			SELECT ErrorMessage+' '+convert(nvarchar,@bi) as ErrorMessage,ErrorNumber FROM COM_ErrorMessages WITH(nolock) WHERE ErrorNumber=ERROR_MESSAGE() AND LanguageID=@LangID
		end
		else if(ERROR_MESSAGE()=-566)
		begin			
			SELECT ErrorMessage+' '+@VoucherNo as ErrorMessage,ErrorNumber FROM COM_ErrorMessages WITH(nolock) WHERE ErrorNumber=ERROR_MESSAGE() AND LanguageID=@LangID
		end
		else if(ERROR_MESSAGE()=-577)
		begin	
			SELECT ErrorMessage+' '+@DocFinalSettlement as ErrorMessage,ErrorNumber FROM COM_ErrorMessages WITH(nolock) WHERE ErrorNumber=ERROR_MESSAGE() AND LanguageID=@LangID
		end
		else
			SELECT ErrorMessage,ErrorNumber FROM COM_ErrorMessages WITH(nolock) WHERE ErrorNumber=ERROR_MESSAGE() AND LanguageID=@LangID
	END
	ELSE IF ERROR_NUMBER()=547
	BEGIN
		SELECT ErrorMessage, ERROR_MESSAGE() AS ServerMessage,ERROR_NUMBER() as ErrorNumber, ERROR_PROCEDURE()as ProcedureName, ERROR_LINE() AS ErrorLine FROM COM_ErrorMessages WITH(nolock)
		WHERE ErrorNumber=-110 AND LanguageID=@LangID
	END
	ELSE
	BEGIN
		SELECT ErrorMessage, ERROR_MESSAGE() AS ServerMessage,ERROR_NUMBER() as ErrorNumber, ERROR_PROCEDURE()as ProcedureName, ERROR_LINE() AS ErrorLine
		FROM COM_ErrorMessages WITH(nolock) WHERE ErrorNumber=-999 AND LanguageID=@LangID
	END
	
ROLLBACK TRANSACTION
	
--Remove if any Delete notification
delete from COM_SchEvents Where CostCenterID=@CostCenterID and NodeID=@DocID and StatusID=1 and FilterXML like '<XML><FilePath>%'

SET NOCOUNT OFF  
RETURN -999   
END CATCH
GO

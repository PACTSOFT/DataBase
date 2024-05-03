USE PACT2C222
GO
SET ANSI_NULLS, QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spDOC_SuspendInvDocument]
	@CostCenterID [int],
	@DocID [bigint],
	@DocPrefix [nvarchar](50),
	@DocNumber [nvarchar](500),
	@Remarks [nvarchar](max),
	@LockWhere [nvarchar](max) = '',
	@SuspendAll [bit] = 0,
	@UserID [int] = 0,
	@UserName [nvarchar](100),
	@RoleID [int] = 0,
	@LangID [int] = 1
WITH ENCRYPTION, EXECUTE AS CALLER
AS
BEGIN TRANSACTION      
BEGIN TRY      
SET NOCOUNT ON;    
  --Declaration Section    
  DECLARE @HasAccess bit,@VoucherNo nvarchar(200),@PrefValue NVARCHAR(500),@NodeID bigint,@DocDate datetime,@DelDocID bigint,@DELETECCID BIGINT,@tot float,@WID BIGINT,@level bigint
  DECLARE @sql nvarchar(max),@tablename nvarchar(200),@CurrentNo bigint,@return_value int,@CompanyGUID nvarchar(200),@VoucherType bit,@DocumentType int,@InvDocDetailsID BIGINT
  declare @ModDate float,@bi int,@bcnt int,@totqty float
  set @ModDate=convert(float,getdate())
  
	--SP Required Parameters Check
	IF(@CostCenterID<40000)
	BEGIN
		RAISERROR('-100',16,1)
	END


	--User acces check
	SET @HasAccess=dbo.fnCOM_HasAccess(@RoleID,@CostCenterID,141)

	IF @HasAccess=0
	BEGIN
		RAISERROR('-105',16,1)
	END
	
	if(@DocID is not null and @DocID>0)
		SELECT  @DocDate=convert(datetime,DocDate),@VoucherType=VoucherType,@DocumentType=DocumentType,
		@VoucherNo=VoucherNo,@DocPrefix=DocPrefix,@DocNumber=DocNumber,@WID=WorkflowID FROM [INV_DocDetails] WITH(nolock)
		WHERE CostCenterID=@CostCenterID AND DocID=@DocID 
	ELSE
		SELECT  @DocDate=convert(datetime,DocDate),@VoucherNo=VoucherNo,@DocID=DocID,@VoucherType=VoucherType ,@DocumentType=DocumentType,@WID=WorkflowID  FROM [INV_DocDetails] WITH(nolock)
		WHERE CostCenterID=@CostCenterID AND DocPrefix=@DocPrefix AND DocNumber=@DocNumber
	
	IF @DocID IS NULL
	BEGIN
		COMMIT TRANSACTION         
		SET NOCOUNT OFF; 
		SELECT ErrorMessage,ErrorNumber FROM COM_ErrorMessages WITH(nolock) 
		WHERE ErrorNumber=109 AND LanguageID=@LangID  
		RETURN 1	
	END
	
	if exists(select LinkedInvDocDetailsID from [INV_DocDetails] WITH(nolock) where LinkedInvDocDetailsID in (SELECT InvDocDetailsID FROM [INV_DocDetails] WITH(nolock)
	WHERE CostCenterID=@CostCenterID AND DocPrefix=@DocPrefix AND DocNumber=@DocNumber))
	begin			
		RAISERROR('-127',16,1)
	end
	
	DECLARE @DLockFromDate DATETIME,@DLockToDate DATETIME,@DAllowLockData BIT ,@DLockCC bigint  
	DECLARE @LockFromDate DATETIME,@LockToDate DATETIME,@AllowLockData BIT,@LockCC bigint,@LockCCValues nvarchar(max)     
	
		
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
	  set @sql ='if exists (select a.CostCenterID from INV_DocDetails a WITH(NOLOCK)
			join COM_DocCCData b WITH(NOLOCK) on a.InvDocDetailsID=b.InvDocDetailsID
			join ADM_DimensionWiseLockData c  WITH(NOLOCK) on a.DocDate between c.fromdate and c.todate and c.isEnable=1
			where  a.CostCenterID='+convert(nvarchar,@CostCenterID)+' AND a.docid='+convert(nvarchar,@DocID)+@LockWhere+')  
			RAISERROR(''-125'',16,1)  '  
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
	
	set @PrefValue=''
	select @PrefValue=Value from ADM_GlobalPreferences where Name='Check for -Ve Stock'  	
  
	if(@PrefValue is not null and @PrefValue='true' and @DocID>0 and (@VoucherType=1 or @DocumentType in(5,30)))
	BEGIN
		select @PrefValue=PrefValue from COM_DocumentPreferences where CostCenterID=@CostCenterID and PrefName='DonotupdateInventory'    
		if(@PrefValue is not null and @PrefValue='false')
		BEGIN		
			
			select @HasAccess=Value FROM ADM_GlobalPreferences with(nolock) WHERE Name='ConsiderUnAppInHold'    
		
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
	
	
	if exists(select AccDocDetailsID from acc_docdetails WITH(nolock)
		where refccid=300 and refnodeid=@DocID and DocID>0)
	begin
		 
		SELECT @DelDocID = DocID , @DELETECCID = COSTCENTERID FROM dbo.ACC_DocDetails  WITH(nolock)  
		where refccid=300 and refnodeid=@DocID	and DocID>0
		while(	@DelDocID>0)
		BEGIN 	    
			 EXEC @return_value = [dbo].[spDOC_DeleteAccDocument]  
			 @CostCenterID = @DELETECCID, 
			 @DocID=@DelDocID,
			 @DocPrefix = '',  
			 @DocNumber = '', 		 
			 @UserID = @UserID,  
			 @UserName = @UserName,  
			 @LangID = @LangID,
			 @RoleID=@RoleID  
			 
			 set @DelDocID=0
			 SELECT @DelDocID = DocID , @DELETECCID = COSTCENTERID FROM dbo.ACC_DocDetails  WITH(nolock)  
			where refccid=300 and refnodeid=@DocID	and DocID>0
		END	 
	end
				
	if exists(select a.AccDocDetailsID from INV_DocDetails a WITH(nolock)
		join INV_DocDetails b WITH(nolock) on b.RefNodeid=a.InvDocDetailsID
		where b.refccid=300 and a.DocID=@DocID and a.CostCenterID=@CostCenterID)
	begin
		
		select @DelDocID = b.DocID , @DELETECCID = b.COSTCENTERID from INV_DocDetails a WITH(nolock)
		join INV_DocDetails b WITH(nolock) on b.RefNodeid=a.InvDocDetailsID
		where b.refccid=300 and a.DocID=@DocID and a.CostCenterID=@CostCenterID		 
		while(	@DelDocID>0)
		BEGIN    
			 EXEC @return_value = [dbo].[spDOC_DeleteInvDocument]  
			 @CostCenterID = @DELETECCID, 
			 @DocID=@DelDocID,
			 @DocPrefix = '',  
			 @DocNumber = '', 			 
			 @UserID = @UserID,  
			 @UserName = @UserName,  
			 @LangID = @LangID,
			 @RoleID=@RoleID
			
			set @DelDocID=0
			
			select @DelDocID = b.DocID , @DELETECCID = b.COSTCENTERID from INV_DocDetails a WITH(nolock)
			join INV_DocDetails b WITH(nolock) on b.RefNodeid=a.InvDocDetailsID
			where b.refccid=300 and a.DocID=@DocID and a.CostCenterID=@CostCenterID	
		 END
	end		
	
	DECLARE @TblDeleteRows AS Table(idid bigint identity(1,1), ID BIGINT,BatchID BIGINT,linkinv BIGINT)
	insert into  @TblDeleteRows
	SELECT InvDocDetailsID,BatchID,LinkedInvDocDetailsID FROM [INV_DocDetails] with(nolock)
	WHERE CostCenterID=@CostCenterID AND DocID=@DocID
	
	declare @caseTab table(id int identity(1,1),CaseID BIGINT,Batchid BIGINT,fldName nvarchar(50))
	declare @CaseID BIGINT,@iUNIQ int,@UNIQUECNT int,@BatchID bigint,@ConsolidatedBatches nvarchar(50),@AllowNegBatches nvarchar(50)
	
	insert into @caseTab(CaseID,Batchid)
	select InvDocDetailsID,Batchid from INV_DocDetails a WITH(nolock)		
	where a.DocID=@DocID and a.CostCenterID=@CostCenterID and BatchID is not null and BatchID>1
	

	IF (@VoucherType=1 and exists(select Batchid from @caseTab))
	BEGIN
		select @AllowNegBatches=Value from [COM_CostCenterPreferences] with(nolock)
		where Name='AllowNegativebatches' and costcenterid=16 
		
		select @ConsolidatedBatches=Value from [COM_CostCenterPreferences] with(nolock)
		where Name='ConsolidatedBatches' and costcenterid=16 
		 
		if(@AllowNegBatches is null or @AllowNegBatches ='' or @AllowNegBatches ='false')
		BEGIN
			select @iUNIQ=0,@UNIQUECNT=COUNT(id) from @caseTab
			while(@iUNIQ<@UNIQUECNT)		
			BEGIN  	
				
				set @iUNIQ=@iUNIQ+1			
				SELECT  @BatchID=Batchid,@InvDocDetailsID=CaseID from @caseTab where id=@iUNIQ
			
				if(@ConsolidatedBatches is null and @ConsolidatedBatches ='false')
				begin     
					set @Tot=isnull((SELECT sum(BD.ReleaseQuantity)    
					FROM [INV_DocDetails] AS BD WITH(NOLOCK)                 
					where vouchertype=1 and IsQtyIgnored=0  and batchid=@BatchID and [InvDocDetailsID]=@InvDocDetailsID),0)  

					set @Tot= @Tot-isnull((SELECT sum(BD.UOMConvertedQty)    
					FROM [INV_DocDetails] AS BD  with(nolock)                  
					where vouchertype=-1 and IsQtyIgnored=0  and batchid=@BatchID and RefInvDocDetailsID=@InvDocDetailsID),0)   
				end  
				else  
				begin  
					set @Tot=isnull((SELECT sum(BD.ReleaseQuantity)    
					FROM [INV_DocDetails] AS BD  WITH(NOLOCK)                  
					where vouchertype=1 and IsQtyIgnored=0  and batchid=@BatchID),0)  

					set @Tot= @Tot-isnull((SELECT sum(BD.UOMConvertedQty)    
					FROM [INV_DocDetails] AS BD  WITH(NOLOCK)                  
					where vouchertype=-1 and IsQtyIgnored=0  and batchid=@BatchID),0)
				end  
			
				if(@Tot<-0.001)   
				begin  
					RAISERROR('-502',16,1)      
				end 					 
			END 
		END
	END  
	
	set @PrefValue=''
	select @PrefValue=PrefValue from COM_DocumentPreferences WITH(nolock)
	where CostCenterID=@CostCenterID and PrefName='DocumentLinkDimension'
	
	if(@PrefValue is not null and @PrefValue<>'')
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
			select @tablename=tablename from ADM_Features WITH(nolock) where FeatureID=@Dimesion
			set @sql='select @NodeID=NodeID from '+@tablename+' WITH(nolock) where Name='''+@VoucherNo+''''
			print @sql
			EXEC sp_executesql @sql,N'@NodeID bigint OUTPUT',@NodeID output
			 
			if(@NodeID>1)
			begin
				if exists(SELECT PrefValue FROM COM_DocumentPreferences WITH(NOLOCK) where CostCenterID=@CostCenterID and  PrefName='Inactiveonsuspend' and prefvalue='true')
				BEGIN
					select @sql=tablename from adm_features WITH(NOLOCK) where featureid=@Dimesion
					set @sql='update '+@sql+' set statusid=1004 where NODEID='+CONVERT(NVARCHAR,@NodeID)
					EXEC(@sql)
				END
				ELSE
				BEGIN	 
					SET @sql='UPDATE COM_DocCCData 
					SET dcCCNID'+CONVERT(NVARCHAR,(@Dimesion-50000))+'=1'
					+' WHERE InvDocDetailsID IN (SELECT InvDocDetailsID FROM Inv_DocDetails WITH(nolock) 
					WHERE COSTCENTERID='+CONVERT(NVARCHAR,@CostCenterID)+' AND DOCID='+CONVERT(NVARCHAR,@DocID)+')'
					EXEC(@sql)
					 		 
					EXEC @return_value = [dbo].[spCOM_DeleteCostCenter]
						@CostCenterID = @Dimesion,
						@NodeID = @NodeID,
						@RoleID=1,
						@UserID = 1,
						@LangID = @LangID
				END		
			end
		end
	end	
	
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

	set @tablename=''
	select @tablename=SpName from ADM_DocFunctions a WITH(NOLOCK) where CostCenterID=@CostCenterID and Mode=11
	if(@tablename<>'')
		exec @tablename @CostCenterID,@DocID,'',@UserID,@LangID
	
	update [ACC_DocDetails]
	set StatusID=376,CancelledRemarks=@Remarks
	WHERE InvDocDetailsID IN (SELECT InvDocDetailsID FROM [INV_DocDetails] WITH(nolock) 
	WHERE CostCenterID=@CostCenterID AND DocPrefix=@DocPrefix AND DocNumber=@DocNumber)
 
	DELETE FROM  [INV_BatchDetails]  
    WHERE [InvDocDetailsID] IN (SELECT InvDocDetailsID FROM [INV_DocDetails] WITH(nolock) 
	WHERE CostCenterID=@CostCenterID AND DocPrefix=@DocPrefix AND DocNumber=@DocNumber)
	
	DELETE FROM COM_Billwise 
	WHERE DocNo=@VoucherNo

	DELETE FROM INV_BinDetails 
	WHERE InvDocDetailsID IN (SELECT InvDocDetailsID FROM [INV_DocDetails] WITH(nolock) 
	WHERE CostCenterID=@CostCenterID AND DocPrefix=@DocPrefix AND DocNumber=@DocNumber)
	
	DELETE FROM INV_DocExtraDetails 
	WHERE InvDocDetailsID IN (SELECT InvDocDetailsID FROM [INV_DocDetails] WITH(nolock) 
	WHERE CostCenterID=@CostCenterID AND DocPrefix=@DocPrefix AND DocNumber=@DocNumber)


	update COM_Billwise 
	set IsNewReference=1,RefDocNo=null,RefDocSeqNo=null,RefDocDate=null,RefDocDueDate=null
	WHERE RefDocNo=@VoucherNo
	
	 	
 
	update [INV_DocDetails] 
	set StatusID=376,IsQtyIgnored=1,CancelledRemarks=@Remarks,LinkedInvDocDetailsID=NULL,ModifiedBy=@UserName,ModifiedDate=@ModDate
	WHERE CostCenterID=@CostCenterID AND DocPrefix=@DocPrefix AND DocNumber=@DocNumber
	
 	
	----Check & Insert Notifications
	--EXEC spCOM_SetNotifEvent @CostCenterID,@DocID,4,'',@UserName,@RoleID,@UserID,@TemplateID OUTPUT
		delete from @caseTab
		INSERT INTO @caseTab(CaseID)
		select CaseID FROM CRM_Cases WITH(nolock) where SvcContractID=@DocID  
		
		select @iUNIQ=MIN(id),@UNIQUECNT=MAX(id) FROM @caseTab
		
		WHILE(@iUNIQ <= @UNIQUECNT)
		BEGIN
			SELECT @CaseID=CaseID FROM @caseTab WHERE id=@iUNIQ
			SELECT @CaseID
			exec spCRM_DeleteCase @CASEID=@CaseID,@USERID=@UserID,@LangID=@LangID,@RoleID=@RoleID
			
			delete from CRM_Activities 
			where CostCenterID=73 and NodeID=@CaseID
			
			SET @iUNIQ=@iUNIQ+1
		END
		
		
		
		
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
							set @totqty=0
							set @SQL='SELECT @totqty=isnull(sum(Quantity),0) from INV_DocDetails a WITH(NOLOCK)
								join COM_DocTextData b WITH(NOLOCK) on a.InvDocDetailsID=b.InvDocDetailsID 
								where a.statusid<>376 and costcenterid='+convert(nvarchar,@CostCenterID)+' and '+@tablename+'='''+@LockCCValues+''''
										
							exec sp_executesql @SQL,N'@totqty float output',@totqty output
								
							if(@Tot>@totqty and @LockCCValues is not null and @LockCCValues<>'')
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
	
	DELETE FROM COM_SchEvents WHERE StatusID=1 AND 
	ScheduleID IN (SELECT DISTINCT ScheduleID FROM COM_CCSchedules with(nolock) WHERE CostCenterID=@CostCenterID AND NodeID=@DocID)
	
	UPDATE S SET StatusID=3 FROM COM_Schedules S with(nolock) 
	INNER JOIN COM_CCSchedules CC with(nolock) ON S.ScheduleID=CC.ScheduleID
	WHERE CC.CostCenterID=@CostCenterID AND CC.NodeID=@DocID 
			
	--Post Notification On Suspend Doc
	EXEC spCOM_SetNotifEvent 376,@CostCenterID,@DocID,'GUID',@UserName,@UserID,@RoleID

	--Audit Trail
	IF (SELECT CONVERT(BIT,PrefValue) FROM COM_DocumentPreferences with(nolock) where CostCenterID=@CostCenterID and PrefName='AuditTrial')=1
	BEGIN    
	
		 EXEC @return_value = [spDOC_SaveHistory]      
			@DocID =@DocID ,
			@HistoryStatus='Suspend',
			@Ininv =1,
			@ReviseReason ='',
			@LangID =@LangID,
			@UserName=@UserName,
			@ModDate=@ModDate
	END
	
	
	if (@documenttype=5 and exists(SELECT PrefValue FROM COM_DocumentPreferences WITH(NOLOCK) 
	where CostCenterID=@COSTCENTERID and PrefName='IsBudgetDocument' and (PrefValue='1' or PrefValue='true')))
	begin		
		select @CompanyGUID=@CompanyGUID from com_DOCID WITH(NOLOCK) where id=@DOCID
		exec [spDoc_UpdateBudget] @CostCenterID,@DOCID,@CompanyGUID,@UserName
	END
		
	if exists(select * from COM_Approvals WITH(NOLOCK) where CCID=@COSTCENTERID and CCNODEID=@DOCID)
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
			if(@level is null)  
				set @level=1
		INSERT INTO COM_Approvals    
							(CCID,CCNODEID,StatusID,Date,Remarks,UserID,CompanyGUID,GUID,CreatedBy,CreatedDate,WorkFlowLevel,DocDetID)      
					VALUES(@COSTCENTERID,@DOCID,376,CONVERT(FLOAT,getdate()),@Remarks,@UserID,''    
							,newid(),@UserName,CONVERT(FLOAT,getdate()),@level,0)
	END	
					
	if(@SuspendAll=1)
	BEGIN	
		
		set @sql=''	
		SELECT @sql=PrefValue FROM COM_DocumentPreferences with(nolock) where CostCenterID=@CostCenterID and PrefName='SuspendDocs'
		delete from @caseTab
		if(@sql<>'')
		BEGIN
			insert into @caseTab(CaseID)
			exec SPSplitString @sql,','  
		END
		
		
		DECLARE @TotI INT,@TotCNT INT
		DECLARE @Tbl AS TABLE(ID INT NOT NULL IDENTITY(1,1), DetailsID BIGINT,CostCenterID int,DOCID BIGINT)
 
		INSERT INTO @Tbl(DetailsID,CostCenterID,DOCID)
		SELECT InvDocDetailsID,CostCenterID,inv.docid
		FROM INV_DocDetails INV with(nolock) 
		join @TblDeleteRows t on inv.InvDocDetailsID=t.linkinv
		
		set @TotI=0
		WHILE(1=1)
		BEGIN
			SET @TotCNT=(SELECT Count(*) FROM @Tbl)
			
			
			INSERT INTO @Tbl(DetailsID,CostCenterID,DOCID)
			SELECT Link.InvDocDetailsID,Link.CostCenterID,Link.DOCID
			FROM INV_DocDetails INV with(nolock) 
			join INV_DocDetails Link on INV.LINKEDInvDocDetailsID=Link.InvDocDetailsID
			INNER JOIN @Tbl T ON INV.InvDocDetailsID=T.DetailsID AND ID>@TotI
			where INV.LINKEDInvDocDetailsID is not null and INV.LINKEDInvDocDetailsID>0
			
			IF @TotCNT=(SELECT Count(*) FROM @Tbl)
				BREAK
			SET @TotI=@TotCNT
		END
		
				declare @table table(DocID BIGINT) 
				
				set @bi=0
				select @bcnt=Count(id) from @Tbl
				while(@bi<@bcnt)
				BEGIN
					set @bi=@bi+1
					
					select @DelDocID=DOCID,@DELETECCID=CostCenterID from @Tbl where id=@bi
					
					if exists(select * from @table where DocID=@DelDocID)
						continue;
					
					if(@sql<>'' and not exists(select CaseID from @caseTab where CaseID=@DELETECCID))
						BREAK
	
						
					insert into @table(DocID)values(@DelDocID)
					
					EXEC @return_value=spDOC_SuspendInvDocument        
					 @CostCenterID = @DELETECCID, 
					 @DocID=@DelDocID,
					 @DocPrefix = '',  
					 @DocNumber = '', 
					 @Remarks=@Remarks, 
					 @UserID = @UserID,  
					 @UserName = @UserName, 
					 @RoleID=@RoleID, 
					 @LangID = @LangID  
					 
					 if(@return_value=-999)
					 BEGIN
						 ROLLBACK TRANSACTION    
						 SET NOCOUNT OFF      
						 RETURN -999 
					 END
				END		
	END
		 
COMMIT TRANSACTION         
SET NOCOUNT OFF;  
SELECT ErrorMessage,ErrorNumber FROM COM_ErrorMessages WITH(nolock) 
WHERE ErrorNumber=109 AND LanguageID=@LangID  
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
			
			SELECT ErrorMessage+' '+@VoucherNo as ErrorMessage,ErrorNumber FROM COM_ErrorMessages WITH(nolock) WHERE ErrorNumber=ERROR_MESSAGE() AND LanguageID=@LangID
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
SET NOCOUNT OFF  
RETURN -999   
END CATCH
GO

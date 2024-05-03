USE PACT2C222
GO
SET ANSI_NULLS, QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spDOC_SetStatus]
	@STATUSID [int] = 0,
	@REMARKS [nvarchar](max),
	@DATE [datetime],
	@ISINVENTORY [bit],
	@DOCID [bigint],
	@COSTCENTERID [bigint],
	@WId [bigint],
	@InvDocidS [nvarchar](max),
	@isFromDOc [bit],
	@DocGUID [nvarchar](50),
	@CompanyGUID [nvarchar](50),
	@UserName [nvarchar](50),
	@UserID [bigint],
	@ROLEID [bigint],
	@LangID [int] = 1
WITH ENCRYPTION, EXECUTE AS CALLER
AS
BEGIN TRANSACTION      
BEGIN TRY      
SET NOCOUNT ON;     
	--Declaration Section    
	DECLARE @Dt FLOAT,@temp nvarchar(100),@VoucherNo nvarchar(200),@XML xml,@tempwid bigint,@I int,@cnt int,@GUID  NVARCHAR(50),@DocumentType INT
	Declare @Level int,@maxLevel INT,@IsLineWisePDC bit,@PDCDocument int,@tempstat bigint,@tempLevel int,@INVID BIGINT,@oldStatus int

	--SP Required Parameters Check    
	IF @STATUSID<0 OR @COSTCENTERID<0 OR @DOCID<0
	BEGIN    
		RAISERROR('-100',16,1)    
	END   

	set @tempwid=@WID
	set @tempstat=@STATUSID
	 
	if(@WID=0)
	BEGIN
		 if(@ISINVENTORY=1)
		 begin						
			select @INVID=InvDocdetailsid,@WID=WorkflowID,@tempLevel=WorkFlowLevel,@oldStatus=Statusid,@DocumentType=DocumentType FROM  [INV_DocDetails] a WITH(NOLOCK)
			WHERE a.CostCenterID=@CostCenterID AND DOCID=@DOCID and WorkflowID>0
		end
		else
		begin 			
			select @WID=WorkflowID,@tempLevel=WorkFlowLevel,@DocumentType=DocumentType FROM  [ACC_DocDetails] a WITH(NOLOCK)
			WHERE a.CostCenterID=@CostCenterID AND DOCID=@DOCID and WorkflowID>0
		end
	END
	ELSE
	BEGIN
	   if(@ISINVENTORY=1)
	   begin						
			select @INVID=InvDocdetailsid,@tempLevel=WorkFlowLevel,@oldStatus=Statusid,@DocumentType=DocumentType FROM  [INV_DocDetails] a WITH(NOLOCK)
			WHERE a.CostCenterID=@CostCenterID AND DOCID=@DOCID and WorkflowID>0
		end
		else
		begin 			
			select @tempLevel=WorkFlowLevel,@DocumentType=DocumentType FROM  [ACC_DocDetails] a WITH(NOLOCK)
			WHERE a.CostCenterID=@CostCenterID AND DOCID=@DOCID and WorkflowID>0
		end
	END
	
	select @GUID=[guid] from COm_DOcid with(nolock) where id=@DOCID
	
	if(@DocGUID<>'' and @GUID!=@DocGUID)
	BEGIN
		RAISERROR('-101',16,1)  
	END
		
	SET @GUID=NEWID()


	if (@DocumentType >= 51 AND @DocumentType <= 199 AND @DocumentType != 64) --IS PAYROLL DOCUMENT
	BEGIN
	--Check Whether the User Level is Payroll Employee Report Manager Level or Not
		SET @level=dbo.fnExt_GetRptMgrUserLevel(@INVID,@WID,@tempLevel,@UserName,@RoleID)
	END
	
	if(@level is null) 
		SELECT @level=LevelID FROM [COM_WorkFlow]   WITH(NOLOCK)   
		where WorkFlowID=@WID and UserID =@UserID and LevelID>@tempLevel
		order by LevelID desc

	if(@level is null)  
		SELECT @level=LevelID FROM [COM_WorkFlow]  WITH(NOLOCK)    
		where WorkFlowID=@WID and RoleID =@RoleID and LevelID>@tempLevel
		order by LevelID desc
		
	if(@level is null)       
		SELECT @level=LevelID FROM [COM_WorkFlow] W WITH(NOLOCK)
		JOIN COM_Groups G WITH(NOLOCK) on w.GroupID=g.GID     
		where g.UserID=@UserID and WorkFlowID=@WID and LevelID>@tempLevel
		order by LevelID desc
		
	if(@level is null)  
		SELECT @level=LevelID FROM [COM_WorkFlow] W WITH(NOLOCK)
		JOIN COM_Groups G WITH(NOLOCK) on w.GroupID=g.GID     
		where g.RoleID =@RoleID and WorkFlowID=@WID and LevelID>@tempLevel
		order by LevelID desc
			
	if(@STATUSID=369)
	BEGIN
		if not(@tempwid=0 and @isFromDOc=1 and @InvDocidS='')
		BEGIN	
			select @maxLevel=max(LevelID) from COM_WorkFlow WITH(NOLOCK) where WorkFlowID=@WID
			if(@level=1)
				set @STATUSID=371
			else if(@maxLevel is not null and @maxLevel>@level)
				set @STATUSID=441				
		END
	END
	
	if(@ISINVENTORY=0 and @STATUSID=369 
	and exists(select CostCenterID from ADM_DocumentTypes WITH(NOLOCK) where CostCenterID=@COSTCENTERID and DocumentType in(14,19)))
		set @STATUSID=370
    if(@ISINVENTORY=0 and @STATUSID=369 
	and exists(select PrefValue from com_documentpreferences WITH(NOLOCK) where CostCenterID=@COSTCENTERID and  PrefName='DonotupdateAccounts' and PrefValue='true'))
		set @STATUSID=377

	SET @Dt=CONVERT(FLOAT,GETDATE())      
    if(@WID>0 and (@InvDocidS is null or @InvDocidS=''))
	BEGIN
	   INSERT INTO COM_Approvals    
		  (CCID    
		  ,CCNODEID    
		  ,StatusID    
		  ,Date
		  ,Remarks 
		  ,UserID   
		  ,CompanyGUID    
		  ,GUID    
		  ,CreatedBy    
		  ,CreatedDate,WorkFlowLevel,DocDetID)      
		VALUES    
		  (@COSTCENTERID    
		  ,@DOCID    
		  ,@STATUSID    
		  ,CONVERT(FLOAT,@DATE)
		  ,@REMARKS
		  ,@UserID
		  ,@CompanyGUID    
		  ,newid()    
		  ,@UserName    
		  ,@Dt,isnull(@level,0),0)
      
		EXEC spCOM_SetNotifEvent @STATUSID,@COSTCENTERID,@DOCID,@CompanyGUID,@UserName,@UserID,-1
	END
    
    IF(@ISINVENTORY=1)
    BEGIN
		if(@InvDocidS<>'')
		BEGIN
			set @XML=@InvDocidS
			declare @tab table(ident int identity(1,1),id bigint,Remark NVARCHAR(MAX),wid int)
			insert into @tab
			select X.value('@ID','BIGINT'),X.value('@Remarks','NVARCHAR(MAX)') ,isnull(X.value('@WID','BIGINT'),0)        			
			FROM @XML.nodes('/XML/Row') as Data(X)    
			
			select @I=0,@cnt=COUNT(*) from @tab
			
			while(@I<@cnt)
			BEGIN
				set @I=@I+1
				
				select @INVID=id,@REMARKS=Remark,@tempwid=wid from @tab where ident=@I
				
				set @STATUSID=@tempstat
				
				select @WID=WorkflowID,@tempLevel=WorkFlowLevel FROM  [INV_DocDetails] a WITH(NOLOCK)
				WHERE InvDocDetailsID=@INVID
				set @level=null
				if (@DocumentType >= 51 AND @DocumentType <= 199 AND @DocumentType != 64) --IS PAYROLL DOCUMENT
				BEGIN
				--Check Whether the User Level is Payroll Employee Report Manager Level or Not
					SET @level=dbo.fnExt_GetRptMgrUserLevel(@INVID,@WID,@tempLevel,@UserName,@RoleID)
				END
				
				if(@level is null)  
					SELECT @level=LevelID FROM [COM_WorkFlow]   WITH(NOLOCK)   
					where WorkFlowID=@WID and UserID =@UserID and LevelID>@tempLevel
					order by LevelID desc
				
				if(@level is null)  
					SELECT @level=LevelID FROM [COM_WorkFlow]  WITH(NOLOCK)    
					where WorkFlowID=@WID and RoleID =@RoleID and LevelID>@tempLevel
					order by LevelID desc
					
				if(@level is null)       
					SELECT @level=LevelID FROM [COM_WorkFlow] W WITH(NOLOCK)
					JOIN COM_Groups G WITH(NOLOCK) on w.GroupID=g.GID     
					where g.UserID=@UserID and WorkFlowID=@WID and LevelID>@tempLevel
					order by LevelID desc
					
				if(@level is null)  
					SELECT @level=LevelID FROM [COM_WorkFlow] W WITH(NOLOCK)
					JOIN COM_Groups G WITH(NOLOCK) on w.GroupID=g.GID     
					where g.RoleID =@RoleID and WorkFlowID=@WID and LevelID>@tempLevel
					order by LevelID desc
		
			
				if(@STATUSID=369 and @tempwid>0)
				BEGIN
					select @maxLevel=max(LevelID) from COM_WorkFlow WITH(NOLOCK) where WorkFlowID=@WID
					if(@level=1)
						set @STATUSID=371
					else if(@maxLevel is not null and @maxLevel>@level)
						set @STATUSID=441	
				END
				
				
				UPDATE INV_DocDetails    
				SET StatusID=@STATUSID,WorkFlowLevel=@level,WorkFlowStatus=@STATUSID
				from @tab a
				WHERE InvDocDetailsID=@INVID
							
				UPDATE ACC_DocDetails    
				SET StatusID=@STATUSID,WorkFlowLevel=@level,WorkFlowStatus=@STATUSID
				from @tab a
				WHERE InvDocDetailsID=@INVID
								
				 
				INSERT INTO COM_Approvals    (CCID    ,CCNODEID    ,StatusID    ,Date,Remarks 
				,UserID   ,CompanyGUID    ,GUID    ,CreatedBy    ,CreatedDate,WorkFlowLevel,DocDetID)      
				values(@COSTCENTERID    ,@DOCID    ,@STATUSID    ,CONVERT(FLOAT,@DATE)
				,@REMARKS,@UserID,@CompanyGUID    ,newid()    ,@UserName    
				,@Dt,isnull(@level,0),@INVID)
				
			END
				
			EXEC spCOM_SetNotifEvent @STATUSID,@COSTCENTERID,@DOCID,@CompanyGUID,@UserName,@UserID,-1
			
			UPDATE COM_DOCID    
			SET GUID=@GUID
			WHERE ID=@DOCID
			
			select @VoucherNo=VoucherNo FROM  [INV_DocDetails] a WITH(NOLOCK)
			WHERE a.CostCenterID=@CostCenterID AND DOCID=@DOCID
			   
		END
		ELSE
		BEGIN
		
			if (exists(SELECT PrefValue from COM_DocumentPreferences with(nolock) where costcenterid=@COSTCENTERID and  PrefName='ApprOnComparitiveAnalysis'  and PrefValue='true')
			and @oldStatus<>369 and @STATUSID=369)
			   set @StatusID=441
			   
			UPDATE INV_DocDetails    
			SET StatusID=@STATUSID,WorkFlowLevel=@level,WorkFlowStatus=@STATUSID
			WHERE CostCenterID=@CostCenterID AND DOCID=@DOCID
			
			UPDATE COM_DOCID    
			SET GUID=@GUID
			WHERE ID=@DOCID
			
			UPDATE ACC_DocDetails    
			SET StatusID=@STATUSID,WorkFlowLevel=@level,WorkFlowStatus=@STATUSID
			WHERE InvDocDetailsID IS NOT NULL AND InvDocDetailsID IN(SELECT InvDocDetailsID FROM INV_DocDetails WITH(NOLOCK)
			WHERE CostCenterID=@CostCenterID AND DOCID=@DOCID)
						
			set @VoucherNo=(select top 1 VoucherNo FROM  [INV_DocDetails] a WITH(NOLOCK)
			WHERE a.CostCenterID=@CostCenterID AND DOCID=@DOCID)
			
			update COM_Billwise
			set StatusID=@STATUSID
			where DocNo=@VoucherNo
			
			if @STATUSID=369 and (exists(select PrefValue from COM_DocumentPreferences with(nolock) where
			CostCenterID=@CostCenterID and PrefName='DocDateasPostedDate' and PrefValue='true')
			or exists(select Value from ADM_GlobalPreferences with(nolock) where
			Name='DocDateasPostedDate' and Value='true'))
			BEGIN
					update inv_docdetails
					set docdate=convert(float,@DATE)
					where costcenterid=@CostCenterID and DocID=@DocID
					
					update acc_docdetails
					set docdate=convert(float,@DATE)
					from ACC_DocDetails a WITH(NOLOCK) 
					join INV_DocDetails b WITH(NOLOCK)  on a.InvDocDetailsID=b.InvDocDetailsID
					where b.CostCenterID=@CostCenterID and b.DocID=@DocID
					
					update COM_Billwise 
					set docdate=convert(float,@DATE)
					where DocNo=@VoucherNo
			END
		END
		
		if (@STATUSID in(372,369) and @documenttype=5 and exists(SELECT PrefValue FROM COM_DocumentPreferences WITH(NOLOCK) 
		where CostCenterID=@COSTCENTERID and PrefName='IsBudgetDocument' and (PrefValue='1' or PrefValue='true')))
		begin		
			exec [spDoc_UpdateBudget] @CostCenterID,@DOCID,@CompanyGUID,@UserName
		END
    END
    ELSE
    BEGIN
		
		
		set @IsLineWisePDC=0
		select @IsLineWisePDC=isnull(PrefValue,0) from COM_DocumentPreferences WITH(NOLOCK) where CostCenterID=@COSTCENTERID and PrefName='LineWisePDC'   	
		select @PDCDocument=isnull(PrefValue,0) from COM_DocumentPreferences WITH(NOLOCK) where CostCenterID=@COSTCENTERID and PrefName='PDCDocument'   
		if(@IsLineWisePDC=1 and @PDCDocument>1)
		BEGIN
			UPDATE ACC_DocDetails    
			SET StatusID=@STATUSID,WorkFlowLevel=@level,WorkFlowStatus=@STATUSID
			Where CostCenterID=@PDCDocument and  RefCCID=400 and RefNodeid in(
			select AccDocDetailsID  FROM ACC_DocDetails WITH(NOLOCK)
			WHERE CostCenterID=@CostCenterID AND DOCID=@DOCID)
			
			
			update c
			set StatusID=@STATUSID
			FROM  ACC_DocDetails a WITH(NOLOCK)
			join ACC_DocDetails b WITH(NOLOCK) on a.AccDocDetailsID=b.RefNodeid
			join COM_Billwise c on b.VoucherNo=c.DocNo
			WHERE a.CostCenterID=@CostCenterID AND a.DOCID=@DOCID and b.RefCCID=400
			and b.CostCenterID=@PDCDocument			
			
			if(@STATUSID=370)
				set @STATUSID=447			
			
			UPDATE ACC_DocDetails    
			SET StatusID=@STATUSID,WorkFlowLevel=@level,WorkFlowStatus=@STATUSID
			WHERE CostCenterID=@CostCenterID AND DOCID=@DOCID
			
			UPDATE COM_DOCID    
			SET GUID=@GUID
			WHERE ID=@DOCID
		END
		ELSE
		BEGIN
			UPDATE ACC_DocDetails    
			SET StatusID=@STATUSID,WorkFlowLevel=@level,WorkFlowStatus=@STATUSID
			WHERE CostCenterID=@CostCenterID AND DOCID=@DOCID
			
			UPDATE COM_DOCID    
			SET GUID=@GUID
			WHERE ID=@DOCID
			
			set @VoucherNo=(select top 1 VoucherNo FROM  ACC_DocDetails a WITH(NOLOCK)
			WHERE a.CostCenterID=@CostCenterID AND DOCID=@DOCID)
			
			update COM_Billwise
			set StatusID=@STATUSID
			where DocNo=@VoucherNo
		END
		
		if @STATUSID=369 and (exists(select PrefValue from COM_DocumentPreferences WITH(NOLOCK) where
			CostCenterID=@CostCenterID and PrefName='DocDateasPostedDate' and PrefValue='true')
			or exists(select Value from ADM_GlobalPreferences WITH(NOLOCK) where
			Name='DocDateasPostedDate' and Value='true'))
			BEGIN
					update ACC_DocDetails
					set docdate=convert(float,@DATE)
					where costcenterid=@CostCenterID and DocID=@DocID
					
					update COM_Billwise 
					set docdate=convert(float,@DATE)
					where DocNo=@VoucherNo
			END
		
		
		if (select count(PrefValue) from COM_DocumentPreferences where CostCenterID=@CostCenterID and PrefName in('AutoChequeonPost','AutoChequeNo') and PrefValue='true')=2
		and @StatusID in(369,370)					
		BEGIN
			declare @EndNo bigint,@ChequeBookNo nvarchar(max),@CurrentChequeNumber nvarchar(max),@Chequeno nvarchar(max),@accid bigint
			set @ChequeBookNo=''
			select @ChequeBookNo=ChequeBookNo,@accid=case when BankAccountID is not null and BankAccountID>0 then BankAccountID else creditaccount end
			,@Chequeno=ChequeNumber
			 from ACC_DocDetails a WITH(NOLOCK)
			WHERE a.CostCenterID=@CostCenterID AND DOCID=@DOCID
			select @CurrentChequeNumber=CurrentNo,@EndNo=EndNo 
			from ACC_ChequeBooks WITH(NOLOCK)  where BankAccountID=@accid and BookNo=@ChequeBookNo
			if(@Chequeno is null or @Chequeno='')
			BEGIN
				set @Chequeno=@CurrentChequeNumber
				
				UPDATE ACC_DocDetails    
				SET ChequeNumber=@Chequeno
				WHERE CostCenterID=@CostCenterID AND DOCID=@DOCID
				
				Update Acc_ChequeBooks Set CurrentNo=REPLACE(@Chequeno,CONVERT(BIGINT,@Chequeno),'')+CONVERT(NVARCHAR,(@Chequeno+1)) 
				where BankAccountID=@accid and BookNo=@ChequeBookNo 
			END
			
		END
    END
    
    declare @tempCode nvarchar(max)
    if(@WID is not null and @WID>0 and @StatusID=441)
	begin
		
		select @tempCode=SpName from ADM_DocFunctions a WITH(NOLOCK) where CostCenterID=@CostCenterID and Mode=12
		if(@tempCode<>'')
			exec @tempCode @CostCenterID,@DocID,@UserID,@LangID
	end
    
    if(@WID is not null and @WID>0 and @StatusID=372)
	begin
		select @tempCode=SpName from ADM_DocFunctions a WITH(NOLOCK) where CostCenterID=@CostCenterID and Mode=16
		if(@tempCode<>'')
			exec @tempCode @CostCenterID,@DocID,@UserID,@LangID
	end
	
    if exists(SELECT PrefValue from COM_DocumentPreferences with(nolock) where costcenterid=@COSTCENTERID and  PrefName='AuditTrial' and PrefValue='true')
	BEGIN 
		EXEC @I = [spDOC_SaveHistory]      
				@DocID =@DocID ,
				@HistoryStatus='Approval',
				@Ininv =@ISINVENTORY,
				@ReviseReason ='',
				@LangID =@LangID,
				@UserName=@UserName,
				@ModDate=@dt
	END
	
	if (exists(SELECT PrefValue from COM_DocumentPreferences with(nolock) where costcenterid=@COSTCENTERID and  PrefName='OnPosted' and PrefValue='true') and @StatusID=369)
	BEGIN
			
			declare @Dimesion int,@PrefValue nvarchar(max),@CCStatusID int,@ProductName nvarchar(max),@DimesionNodeID bigint
			select @PrefValue=''	
			select @PrefValue=PrefValue from COM_DocumentPreferences with(nolock) where costcenterid=@COSTCENTERID and  PrefName='DocumentLinkDimension'    

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
		
		
				declare @Codetemp table (prefix nvarchar(100),number bigint, suffix nvarchar(100), code nvarchar(200),IsManualCode bit)
		 
				set @CCStatusID = (select  statusid from com_status where costcenterid=@Dimesion and status = 'Active')
				
				SET @PrefValue=''    
				SELECT @PrefValue=PrefValue from COM_DocumentPreferences with(nolock) where costcenterid=@COSTCENTERID and  PrefName='AutoCode'    
				if(@PrefValue='true')
				BEGIN
						
						delete from @Codetemp
						insert into @Codetemp
						EXEC [spCOM_GetCodeData] @Dimesion,1,''  
						
						select @ProductName=code,@GUID= prefix, @level=number from @Codetemp
				END
				ELSE
				BEGIN
					set @ProductName=@VoucherNo
					set @GUID=''
					set @level=0
				END
				
				EXEC @DimesionNodeID = [dbo].[spCOM_SetCostCenter]
					@NodeID = 0,@SelectedNodeID = 1,@IsGroup = 0,
					@Code = @ProductName,
					@Name = @VoucherNo,
					@AliasName='',
					@PurchaseAccount=0,@SalesAccount=0,@StatusID=@CCStatusID,
					@CustomFieldsQuery=NULL,@AddressXML=NULL,@AttachmentsXML=NULL,
					@CustomCostCenterFieldsQuery=NULL,@ContactsXML=NULL,@NotesXML=NULL,
					@CostCenterID = @Dimesion,@CompanyGUID=@COMPANYGUID,@GUID='',@UserName=@UserName,@RoleID=1,@UserID=1,
					@CodePrefix=@GUID,@CodeNumber=@level,
					@CheckLink = 0,@IsOffline=0
				
				set @DimesionNodeID=0						
				select @PrefValue=tablename from ADM_Features with(nolock) where FeatureID=@Dimesion
				set @PrefValue='select @NodeID=NodeID from '+@PrefValue+' with(nolock) where Name='''+@VoucherNo+''''				
				EXEC sp_executesql @PrefValue,N'@NodeID bigint OUTPUT',@DimesionNodeID output				
		 
		
		if(@DimesionNodeID>0 or @DimesionNodeID<-10000)
		BEGIN
			set @CCStatusID = (select  statusid from com_status where costcenterid=@Dimesion and status = 'Active')
			select @PrefValue=tablename from ADM_Features with(nolock) where FeatureID=@Dimesion
			set @PrefValue='update '+@PrefValue+' set statusid='+convert(nvarchar(50),@CCStatusID)+' where NodeID='+convert(nvarchar(50),@DimesionNodeID)
			exec(@PrefValue)
				
			SET @PrefValue='UPDATE COM_DocCCData 
			SET dcCCNID'+CONVERT(NVARCHAR,(@Dimesion-50000))+'='+CONVERT(NVARCHAR,@DimesionNodeID)
			+' WHERE InvDocDetailsID IN (SELECT InvDocDetailsID FROM Inv_DocDetails with(nolock) 
			WHERE COSTCENTERID='+CONVERT(NVARCHAR,@CostCenterID)+' AND DOCID='+CONVERT(NVARCHAR,@DocID)+')'
			EXEC(@PrefValue)
				
			 if(@ISINVENTORY=1)
			 begin						
				select @INVID=InvDocDetailsID FROM  [INV_DocDetails] a WITH(NOLOCK)
				WHERE a.CostCenterID=@CostCenterID AND DOCID=@DOCID
			end
			else
			begin 			
				select @INVID=AccDocDetailsID FROM  [ACC_DocDetails] a WITH(NOLOCK)
				WHERE a.CostCenterID=@CostCenterID AND DOCID=@DOCID 
			end	
			
			Exec [spDOC_SetLinkDimension]
				@InvDocDetailsID=@INVID, 
				@Costcenterid=@CostCenterID,         
				@DimCCID=@Dimesion,
				@DimNodeID=@DimesionNodeID,
				@UserID=@UserID,    
				@LangID=@LangID    
		 END
   END
COMMIT TRANSACTION  
SET NOCOUNT OFF;    
 select @temp=ResourceData from COM_Status S WITH(NOLOCK)
 join COM_LanguageResources R WITH(NOLOCK) on R.ResourceID=S.ResourceID and R.LanguageID=@LangID
 where S.StatusID=@StatusID
 
SELECT   @temp status,ErrorMessage + '   ' + isnull(@VoucherNo,'voucherempty') +' ['+@temp+']'  as ErrorMessage,ErrorNumber FROM COM_ErrorMessages WITH(nolock)   
WHERE ErrorNumber=105 AND LanguageID=@LangID    
RETURN  1    
END TRY    
BEGIN CATCH      
 --Return exception info [Message,Number,ProcedureName,LineNumber]      
 IF ERROR_NUMBER()=50000    
 BEGIN       
  SELECT ErrorMessage,ErrorNumber FROM COM_ErrorMessages WITH(NOLOCK) WHERE ErrorNumber=ERROR_MESSAGE() AND LanguageID=@LangID    
 END    
 ELSE    
 BEGIN    
  SELECT ErrorMessage, ERROR_MESSAGE() AS ServerMessage,ERROR_NUMBER() as ErrorNumber, ERROR_PROCEDURE()as ProcedureName, ERROR_LINE() AS ErrorLine    
  FROM COM_ErrorMessages WITH(NOLOCK) WHERE ErrorNumber=-999 AND LanguageID=@LangID    
 END    
ROLLBACK TRANSACTION    
SET NOCOUNT OFF      
RETURN -999       
END CATCH    
    
GO

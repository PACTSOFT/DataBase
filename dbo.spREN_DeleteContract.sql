USE PACT2C222
GO
SET ANSI_NULLS, QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spREN_DeleteContract]
	@CostCenterID [bigint],
	@ContractID [bigint] = 0,
	@UserID [bigint] = 1,
	@RoleID [int] = 1,
	@LangID [int] = 1
WITH ENCRYPTION, EXECUTE AS CALLER
AS
BEGIN TRANSACTION  
BEGIN TRY    
SET NOCOUNT ON;    
  
	DECLARE @TBLCNT INT,@INCCNT INT,@DELETEDOCID BIGINT,@DELETECCID BIGINT,@DELETEISACC BIT    
	DECLARE @return_value int,@HasAccess BIT ,@tempCID BIGINT,@sql nvarchar(max),@ScheduleID bigint  
	DECLARE @AUDITSTATUS NVARCHAR(50)
 
	--User acces check
	SET @HasAccess=dbo.fnCOM_HasAccess(@RoleID,@CostCenterID,4)

	IF @HasAccess=0
	BEGIN
		RAISERROR('-105',16,1)
	END
	
	if exists(select * from REN_Contract where  parentContractID=@ContractID)
		RAISERROR('Delete child contracts',16,1)

	SET @DELETECCID = 0 

	DECLARE @lft bigint,@rgt bigint ,@Width bigint

	SELECT @lft = lft, @rgt = rgt, @Width = rgt - lft + 1
	FROM REN_CONTRACT WITH(NOLOCK) WHERE ContractID=@ContractID
	
	Declare @temp table(id int identity(1,1), NodeID bigint)  
	insert into @temp  
	select ContractID from REN_CONTRACT WITH(NOLOCK) WHERE lft >= @lft AND rgt <= @rgt  
    
	declare @i int, @cnt int
	DECLARE @NodeID bigint, @Dimesion bigint 
	select @i=1,@cnt=count(*) from @temp  
	while @i<=@cnt
	begin
		set @NodeID=0
		set @Dimesion=0
		select @tempCID=NodeID from @temp where id=@i  
		select  @NodeID = CCNodeID, @Dimesion=CCID from REN_CONTRACT WITH(NOLOCK) where ContractID=@tempCID  
 
		if (@Dimesion > 0 and @NodeID is not null and @NodeID>1)  
		begin  

			Update REN_CONTRACT set CCID=0, CCNodeID=0 where ContractID =@tempCID  

			set @sql='update com_docccdata  
			set dcccnid'+convert(nvarchar,(@Dimesion-50000))+'=1  
			from ACC_DocDetails a WITH(NOLOCK) 
			where com_docccdata.accdocdetailsid=a.accdocdetailsid  
			and a.refccid='+Convert(NVARCHAR,@CostCenterID)+' and a.refnodeid='+convert(nvarchar,@tempCID)     
			exec(@sql)  

			set @sql='update com_docccdata  
			set dcccnid'+convert(nvarchar,(@Dimesion-50000))+'=1  
			from INV_DocDetails a WITH(NOLOCK) 
			where com_docccdata.invdocdetailsid=a.invdocdetailsid  
			and a.refccid='+Convert(NVARCHAR,@CostCenterID)+' and a.refnodeid='+convert(nvarchar,@tempCID)  
			exec(@sql)  

			set @sql='update com_ccccdata  
			set ccnid'+convert(nvarchar,(@Dimesion-50000))+'=1  
			from REN_CONTRACT a WITH(NOLOCK) 
			where com_ccccdata.Nodeid=a.ContractID   and com_ccccdata.costcenterid='+Convert(NVARCHAR,@CostCenterID)+'
			and  com_ccccdata.ccnid'+convert(nvarchar,(@Dimesion-50000))+'='+convert(nvarchar,@NodeID)  
			exec(@sql)  

			SET @return_value = 0
			IF(@NodeID>1)
			BEGIN 
				EXEC @return_value = [dbo].[spCOM_DeleteCostCenter]
				@CostCenterID = @Dimesion,
				@NodeID = @NodeID,
				@RoleID=1,
				@UserID = @UserID,
				@LangID = @LangID,
				@CheckLink = 0
				--Deleting from Mapping Table
				Delete from com_docbridge WHERE CostCenterID = @CostCenterID AND RefDimensionNodeID = @NodeID AND RefDimensionID = @Dimesion	
			END			
		end
		set @i=@i+1
	end
				
	SET @AUDITSTATUS= 'DELETE'

	DECLARE  @tblListDEL TABLE(ID int identity(1,1),ContractID BIGINT , DocID BIGINT, COSTCENTERID BIGINT ,IsAccDoc BIT  )      

	INSERT INTO @tblListDEL    
	SELECT distinct ACC.REFNODEID , ACC.DocID , ACC.CostCenterID ,1
	FROM ACC_DOCDETAILS ACC WITH(NOLOCK)  	
	WHERE ACC.REFNODEID = @ContractID and acc.RefCCID=@CostCenterID
	and ACC.InvDocDetailsID is null
	INSERT INTO @tblListDEL    
	SELECT distinct ACC.REFNODEID , ACC.DocID , ACC.CostCenterID ,0
	FROM Inv_DOCDETAILS ACC WITH(NOLOCK)  	
	WHERE ACC.REFNODEID = @ContractID and acc.RefCCID=@CostCenterID
	
	SELECT @INCCNT = 1,@TBLCNT = COUNT(*) FROM @tblListDEL  

	WHILE(@INCCNT <= @TBLCNT)  
	BEGIN  
		SELECT @DELETEDOCID=DocID,@DELETECCID=CostCenterID,@DELETEISACC =IsAccDoc 
		FROM @tblListDEL WHERE ID = @INCCNT  

		IF(@DELETEISACC = 1)  
		BEGIN   
			IF (@DELETECCID > 0 )
				EXEC @return_value = [dbo].[spDOC_DeleteAccDocument]  
				 @CostCenterID = @DELETECCID,  
				 @DocPrefix =  '',  
				 @DocNumber = '',  
				 @DocID=@DELETEDOCID ,
				 @UserID = 1,  
				 @UserName = N'ADMIN',  
				 @LangID = 1,
				 @RoleID=1
		END   
		ELSE  
		BEGIN      
			IF (@DELETECCID > 0 ) 
			BEGIN 
				EXEC @return_value = [spDOC_DeleteInvDocument]  
				 @CostCenterID = @DELETECCID,  
				 @DocPrefix = '',  
				 @DocNumber = '',  
				 @DocID=@DELETEDOCID ,
				 @UserID = 1,  
				 @UserName = N'ADMIN',  
				 @LangID = 1,
				 @RoleID=1
				 
				 set @ScheduleID=0
				select @ScheduleID=ScheduleID from COM_CCSchedules WITH(NOLOCK)
				where CostCenterID=@DELETECCID and NodeID=@DELETEDOCID
			
				if(@ScheduleID>0)
				BEGIN
					delete from COM_CCSchedules
					where ScheduleID=@ScheduleID
					
					delete from COM_UserSchedules
					where ScheduleID=@ScheduleID
					
					delete from COM_SchEvents
					where ScheduleID=@ScheduleID
					
					delete from COM_Schedules
					where ScheduleID=@ScheduleID
				END
			END	 
		END  
		SET @INCCNT = @INCCNT + 1   
	END   

	DECLARE @AuditTrial BIT=0    
	SELECT @AuditTrial= CONVERT(BIT,VALUE) FROM [COM_COSTCENTERPreferences] WITH(NOLOCK)  
	WHERE CostCenterID=@CostCenterID  AND NAME='AllowAudit'  

	IF (@AuditTrial=1 )  
	BEGIN  

		INSERT INTO [REN_Contract_History]
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
			   ,[ExtendTill]
			  ,[CCNodeID]
			  ,[CCID]
			  ,[RefundDate]
			  ,[VacancyDate]
			  ,[BasedOn]
			  ,[RefContractID]
			  ,[RenewRefID]
			  ,[QuotationID]
			  ,[SRTAmount]
			  ,[RefundAmt]
			  ,[PDCRefund]
			  ,[Penalty]
			  ,[Amt]
			  ,[TermPayMode]
			  ,[TermChequeNo]
			  ,[TermChequeDate]
			  ,[TermRemarks]
			  ,[SecurityDeposit]
			  ,[WorkFlowID]
			  ,[WorkFlowLevel]
			  ,[RenewalAmount])
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
		  ,@AUDITSTATUS 
		  ,[ExtendTill]
		  ,[CCNodeID]
		  ,[CCID]
		  ,[RefundDate]
		  ,[VacancyDate]
		  ,[BasedOn]
		  ,[RefContractID]
		  ,[RenewRefID]
		  ,[QuotationID]
		  ,[SRTAmount]
		  ,[RefundAmt]
		  ,[PDCRefund]
		  ,[Penalty]
		  ,[Amt]
		  ,[TermPayMode]
		  ,[TermChequeNo]
		  ,[TermChequeDate]
		  ,[TermRemarks]
		  ,[SecurityDeposit]
		  ,[WorkFlowID]
		  ,[WorkFlowLevel]
		  ,[RenewalAmount]
		FROM [REN_Contract] WITH(NOLOCK) 
		WHERE  [ContractID]  = @ContractID AND COSTCENTERID = @CostCenterID


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
			   ,[IsRecurr],RentAmount,Discount)
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
		  ,[ModifiedBy]
		  ,[ModifiedDate]
		  ,[Sno]
		  ,[Narration]
		  ,[IsRecurr],RentAmount,Discount  
		FROM  [REN_ContractParticulars] WITH(NOLOCK) 
		WHERE  [ContractID] = @ContractID

		INSERT INTO  [REN_ContractPayTerms_History]
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
		  ,[ModifiedBy]
		  ,[ModifiedDate]
		  ,[Sno]
		  ,[Narration]
		FROM  [REN_ContractPayTerms] WITH(NOLOCK) 
		WHERE  [ContractID]  = @ContractID

		INSERT INTO  [REN_ContractExtended_History]
			   ( [NodeID]
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
	
	DELETE FROM COM_Files WHERE FEATUREID=@CostCenterID and  FeaturePK=@ContractID 
		
	DELETE FROM CRM_ACTIVITIES WHERE CostCenterID=@CostCenterID AND NodeID=@ContractID 
		    
	DELETE FROM REN_ContractDocMapping WHERE CONTRACTID = @CONTRACTID  
	DELETE FROM  [REN_ContractExtended] WHERE  [NodeID]  = @ContractID
	
	Delete from REN_ContractParticularsDetail where ContractID=@ContractID and Costcenterid=@CostCenterID
	
	delete from REN_ContractParticulars where ContractID=@ContractID    
	delete from REN_ContractPayTerms where ContractID=@ContractID  
	
	if exists(select * from REN_Contract WITH(NOLOCK) where  RefContractID=@ContractID)
	BEGIN
		delete from REN_Contract where  RefContractID=@ContractID  
		select @tempCID=unitid from REN_Contract WITH(NOLOCK) where  ContractID=@ContractID
		
		update REN_Contract 
		set unitid=1
		where  ContractID=@ContractID
		
		exec dbo.spREN_DeleteUnit @tempCID,1,1,1
	END
	
	IF exists(select * from REN_Contract WITH(NOLOCK) where ContractID=@ContractID AND parentContractID IS NOT NULL AND parentContractID>0)
	BEGIN
		select @tempCID=parentContractID from REN_Contract WITH(NOLOCK)
		where ContractID=@ContractID AND parentContractID IS NOT NULL AND parentContractID>0
		UPDATE [REN_Contract] SET NoOfContratcs=(NoOfContratcs-1)
		WHERE ContractID=@tempCID
	END
	
	delete from REN_Contract where  ContractID=@ContractID  

COMMIT TRANSACTION  
SET NOCOUNT OFF;    
SELECT ErrorMessage,ErrorNumber FROM COM_ErrorMessages WITH(nolock)   
WHERE ErrorNumber=102 AND LanguageID=@LangID  
  
RETURN 1  
END TRY  
BEGIN CATCH    
 --Return exception info [Message,Number,ProcedureName,LineNumber]
 
 if(@return_value=-999)
     return @return_value
 IF ERROR_NUMBER()=50000  
 BEGIN  
	IF ISNUMERIC(ERROR_MESSAGE())=1	
		SELECT ErrorMessage,ErrorNumber, ERROR_PROCEDURE()as ProcedureName, ERROR_LINE() AS ErrorLine FROM COM_ErrorMessages WITH(nolock) WHERE ErrorNumber=ERROR_MESSAGE() AND LanguageID=@LangID  
	else
		SELECT ERROR_MESSAGE() ErrorMessage	
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

USE PACT2C222
GO
SET ANSI_NULLS, QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spREN_CancelTermination]
	@ContractID [bigint],
	@SCostCenterID [bigint],
	@CompanyGUID [nvarchar](50),
	@UserName [nvarchar](50),
	@UserID [int] = 0,
	@LangID [int] = 1
WITH ENCRYPTION, EXECUTE AS CALLER
AS
BEGIN TRANSACTION      
BEGIN TRY        
SET NOCOUNT ON;  
	
	DECLARE @Dt float,@XML xml,@CNT bigint,@I BIGINT,@return_value int,@AUDITSTATUS NVARCHAR(50)
	DECLARE @OldStatus int, @DELETEDOCID BIGINT , @DELETECCID BIGINT , @DELETEISACC BIT,@AuditTrial BIT,@IsAccDoc BIT
	DECLARE @CostCenterID int,@PendingVchrs nvarchar(max),@DDXML nvarchar(max),@TermDate float,@STATUSID INT
	SET @Dt=convert(float,getdate())
	declare @tabvchrs table(vno nvarchar(200))
	select @OldStatus=STATUSID,@TermDate=TerminationDate from REN_CONTRACT WITH(NOLOCK) WHERE ContractID = @ContractID  
	
	SET @STATUSID=426
	IF((select RenewRefID from REN_CONTRACT WITH(NOLOCK) WHERE ContractID=@ContractID)>0)
		SET @STATUSID=427
		
	IF(@SCostCenterID=95 and @OldStatus=428)
	BEGIN
		set @DDXML='if exists(SELECT C2.ContractID FROM REN_Contract C1 with(nolock)
		LEFT JOIN REN_Contract C2 with(nolock) ON C2.UnitID=C1.UnitID AND C2.SNO > C1.SNO
		WHERE C1.ContractID='+CONVERT(NVARCHAR(MAX),@ContractID)+' AND C2.ContractID IS NOT NULL
		AND C1.EndDate BETWEEN C2.StartDate AND C2.EndDate )
		RAISERROR(''-520'',16,1)'	
		exec(@DDXML)
	END
	
	IF(@SCostCenterID=104 and @OldStatus=428)
	BEGIN
		set @DDXML='if exists(SELECT C2.ContractID FROM REN_Contract C1 with(nolock)
		LEFT JOIN REN_Contract C2 with(nolock) ON C2.PropertyID=C1.PropertyID AND C2.SNO > C1.SNO
		WHERE C1.ContractID='+CONVERT(NVARCHAR(MAX),@ContractID)+' AND C2.ContractID IS NOT NULL
		AND C1.EndDate BETWEEN C2.StartDate AND C2.EndDate )
		RAISERROR(''-520'',16,1)'	
		exec(@DDXML)
	END
	
	if(@OldStatus = 450)
		SET @AUDITSTATUS= 'Cancelrefund'  
	else	
		SET @AUDITSTATUS= 'CancelTERMINATE'  
	
	if(@OldStatus = 450)
		UPDATE REN_CONTRACT  
		SET STATUSID = @STATUSID ,VacancyDate =NULL , RefundDate = NULL  
		WHERE ContractID = @ContractID  or RefContractID=@ContractID
	else
		UPDATE REN_CONTRACT  
		SET STATUSID = @STATUSID ,TerminationDate =NULL , Reason = NULL  
		WHERE ContractID = @ContractID  or RefContractID=@ContractID
	
	update b
	set statusid=1
	from REN_ContractDocMapping DM WITH(NOLOCK)
	join COM_CCSchedules a WITH(NOLOCK) on DM.CostCenterID=a.CostCenterID
	join COM_SchEvents b WITH(NOLOCK) on a.ScheduleID=b.ScheduleID
	where a.NodeID=DM.DocID and DM.ContractID = @ContractID and b.statusid=3
	and (DM.TYPE = 1 OR DM.TYPE IS NULL) and (DM.isaccdoc = 0 OR DM.IsAccDoc  IS NULL )


	delete from [REN_TerminationParticulars]
	where contractID=@ContractID
		
	SET @AuditTrial=0      
	SELECT @AuditTrial= CONVERT(BIT,VALUE)  FROM [COM_COSTCENTERPreferences] WITH(NOLOCK)     
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
           ,[HistoryStatus])  
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
			  ,[CostCenterID] , @AUDITSTATUS   
		  FROM [REN_Contract]  WITH(NOLOCK) WHERE  [ContractID]  = @ContractID 
    
    
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
		  FROM  [REN_ContractParticulars] WITH(NOLOCK) WHERE  [ContractID]  = @ContractID  
		    
		    
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
			  ,@UserName  
			  ,@Dt  
			  ,[Sno]  
			  ,[Narration]  
		  FROM  [REN_ContractPayTerms] WITH(NOLOCK) WHERE  [ContractID]  = @ContractID  
		    
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
			  ,[alpha50], @AUDITSTATUS   
		  FROM  [REN_ContractExtended] WITH(NOLOCK) WHERE  [NodeID]  = @ContractID  
		  
		             
    
	END       
  
--------------------------Cancel  POSTINGS --------------------------  
      
IF( @SCostCenterID  = 95 OR @SCostCenterID  = 104)  
BEGIN    
      
    DECLARE  @tblXML TABLE(ID int identity(1,1),DOCID bigint,COSTCENTERID int,IsAccDoc bit,Stat int)
	
	if(@OldStatus = 450)
	BEGIN
		INSERT INTO @tblXML       
		select DocID,COSTCENTERID,IsAccDoc,0 from [REN_ContractDocMapping] WITH(NOLOCK) 
		where  [ContractID]=@ContractID and [Type]=101 and ContractCCID=@SCostCenterID
		ORDER BY DocID DESC
	END
	ELSE
	BEGIN
		INSERT INTO @tblXML       
		select DocID,COSTCENTERID,IsAccDoc,0 from [REN_ContractDocMapping]  WITH(NOLOCK)
		where  [ContractID]=@ContractID and [Type]<0 and ContractCCID=@SCostCenterID
		ORDER BY DocID DESC
	END
	
	set @I=0
	select @CNT=max(ID) from @tblXML
	WHILE(@I <  @CNT)      
	BEGIN                
		SET @I = @I+1  
		set @DELETEDOCID=0
		set @DELETECCID=0
		SELECT @DELETEDOCID = DOCID,@IsAccDoc=IsAccDoc FROM @tblXML WHERE ID = @I      
        
        if(@IsAccDoc=1) 
        BEGIN
			SELECT @DELETECCID = COSTCENTERID FROM dbo.ACC_DocDetails  WITH(NOLOCK)        
			WHERE DOCID = @DELETEDOCID      
			IF @DELETECCID IS NOT NULL and @DELETECCID>0 AND @DELETEDOCID IS NOT NULL and @DELETEDOCID>0
			BEGIN
			
				EXEC @return_value = [dbo].[spDOC_DeleteAccDocument]        
				@CostCenterID = @DELETECCID,        
				@DocPrefix = '',        
				@DocNumber = '',   
				@DOCID = @DELETEDOCID,
				@UserID = 1,        
				@UserName = N'ADMIN',        
				@LangID = 1,
				@RoleID = 1
			END
		END	
		ELSE
		BEGIN
			SELECT  @DELETECCID = COSTCENTERID FROM dbo.INV_DocDetails WITH(NOLOCK)         
			WHERE DOCID = @DELETEDOCID      
			IF @DELETECCID IS NOT NULL and @DELETECCID>0 AND @DELETEDOCID IS NOT NULL and @DELETEDOCID>0
			BEGIN
			
				EXEC @return_value = [dbo].[spDOC_DeleteInvDocument]        
				@CostCenterID = @DELETECCID,        
				@DocPrefix = '',        
				@DocNumber = '', 
				@DOCID = @DELETEDOCID,       
				@UserID = 1,        
				@UserName = N'ADMIN',        
				@LangID = 1,
				@RoleID =1
			END
		END       
    END
     
    if(@OldStatus = 450)
	BEGIN
	  DELETE from [REN_ContractDocMapping] 
	  where  [ContractID]=@ContractID and [Type]=101 and ContractCCID=@SCostCenterID   
	END
	ELSE
	BEGIN
	
		DELETE from [REN_ContractDocMapping] 
		where  [ContractID]=@ContractID and [Type]<0 and ContractCCID=@SCostCenterID
	    
		INSERT INTO @tblXML       
		select b.DocID,b.COSTCENTERID,IsAccDoc,StatusID from [REN_ContractDocMapping] a WITH(NOLOCK)
		join [ACC_DocDetails] b WITH(NOLOCK) on a.DocID=b.DocID 
		where  [ContractID]=@ContractID and [Type]>0 and ContractCCID=@SCostCenterID and IsAccDoc=1
		and b.StatusID in(376,452)	and documenttype in (14,19)
		
		select @I=min(ID),@CNT=max(ID) from @tblXML
		WHILE(@I < = @CNT)      
		BEGIN              
			SELECT @DELETEDOCID = DOCID,@CostCenterID=COSTCENTERID,@OldStatus=Stat FROM @tblXML WHERE ID = @I      
			
			update [ACC_DocDetails] 
			set StatusID=370,CancelledRemarks=NULL
			WHERE CostCenterID=@CostCenterID AND DOCID=@DELETEDOCID
			
			if(@OldStatus=376 and exists (select accountid from acc_accounts WITH(NOLOCK)
						where accountid =(select CreditAccount from [ACC_DocDetails] WITH(nolock)   where CostCenterID=@CostCenterID AND DOCID=@DELETEDOCID)
						and isbillwise=1))
			BEGIN
			INSERT INTO [COM_Billwise]    
		 ([DocNo]    
		 ,[DocDate]    
		 ,[DocDueDate]    
		   ,[DocSeqNo]    
		   ,[AccountID]    
		   ,[AdjAmount]    
		   ,[AdjCurrID]    
		   ,[AdjExchRT]    
		   ,[DocType]    
		   ,[IsNewReference]    
		   ,[RefDocNo]    
		   ,[RefDocSeqNo]    
		 ,[RefDocDate]    
		 ,[RefDocDueDate]    
		   ,[Narration]    
		   ,[IsDocPDC]    
		   ,[dcCCNID1]    
		   ,[dcCCNID2]    
		   ,[dcCCNID3]    
		   ,[dcCCNID4]    
		   ,[dcCCNID5]    
		   ,[dcCCNID6]    
		   ,[dcCCNID7]    
		   ,[dcCCNID8]    
		   ,[dcCCNID9]    
		   ,[dcCCNID10]    
		   ,[dcCCNID11]    
		   ,[dcCCNID12]    
		   ,[dcCCNID13]    
		   ,[dcCCNID14]    
		   ,[dcCCNID15]    
		   ,[dcCCNID16]    
		   ,[dcCCNID17]    
		   ,[dcCCNID18]    
		   ,[dcCCNID19]    
		   ,[dcCCNID20]    
		   ,[dcCCNID21]    
		   ,[dcCCNID22]    
		   ,[dcCCNID23]    
		   ,[dcCCNID24]    
		   ,[dcCCNID25]    
		   ,[dcCCNID26]    
		   ,[dcCCNID27]    
		   ,[dcCCNID28]    
		   ,[dcCCNID29]    
		   ,[dcCCNID30]    
		   ,[dcCCNID31]    
		   ,[dcCCNID32]    
		   ,[dcCCNID33]    
		   ,[dcCCNID34]    
		   ,[dcCCNID35]    
		   ,[dcCCNID36]    
		   ,[dcCCNID37]    
		   ,[dcCCNID38]    
		   ,[dcCCNID39]    
		   ,[dcCCNID40]    
		   ,[dcCCNID41]    
		   ,[dcCCNID42]    
		   ,[dcCCNID43]    
		   ,[dcCCNID44]    
		   ,[dcCCNID45]    
		   ,[dcCCNID46]    
		   ,[dcCCNID47]    
		   ,[dcCCNID48]    
		   ,[dcCCNID49]    
		   ,[dcCCNID50] , AmountFC)    
		 select VoucherNo    
		   , DocDate    
		   , DueDate    
		   , [DocSeqNo]    
		   , CreditAccount    
		   , Amount    
		   , [CurrencyID]    
		   , [ExchangeRate]
		   , [DocumentType]    
		   , 1    
		   , NULL    
		   ,NULL    
		   , NULL    
		   ,NULL    
		   , ''    
		   , 1
		   , d.dcCCNID1    
		   , d.dcCCNID2    
		   , d.dcCCNID3    
		   , d.dcCCNID4    
		   , d.dcCCNID5    
		   , d.dcCCNID6    
		   , d.dcCCNID7    
		   , d.dcCCNID8    
		   , d.dcCCNID9    
		   , d.dcCCNID10    
		   , d.dcCCNID11    
		   , d.dcCCNID12    
		   , d.dcCCNID13    
		   , d.dcCCNID14    
		   , d.dcCCNID15    
		   , d.dcCCNID16    
		   , d.dcCCNID17    
		   , d.dcCCNID18    
		   , d.dcCCNID19    
		   , d.dcCCNID20    
		   , d.dcCCNID21    
		   , d.dcCCNID22    
		   , d.dcCCNID23    
		   , d.dcCCNID24    
		   , d.dcCCNID25    
		   , d.dcCCNID26    
		   , d.dcCCNID27    
		   , d.dcCCNID28    
		   , d.dcCCNID29    
		   , d.dcCCNID30    
		   , d.dcCCNID31    
		   , d.dcCCNID32    
		   , d.dcCCNID33    
		   , d.dcCCNID34    
		   , d.dcCCNID35    
		   , d.dcCCNID36    
		   , d.dcCCNID37    
		   , d.dcCCNID38    
		   , d.dcCCNID39    
		   , d.dcCCNID40    
		   , d.dcCCNID41    
		   , d.dcCCNID42    
		   , d.dcCCNID43    
		   , d.dcCCNID44    
		   , d.dcCCNID45    
		   , d.dcCCNID46    
		   , d.dcCCNID47    
		   , d.dcCCNID48    
		   , d.dcCCNID49    
		   , d.dcCCNID50 , [AmountFC] 
		 from [ACC_DocDetails] a  WITH(NOLOCK)   
		 join [COM_DocCCData] d  WITH(NOLOCK)  on d.AccDocDetailsID=a.AccDocDetailsID 
		 where a.CostCenterID=@CostCenterID AND a.DOCID=@DELETEDOCID
			END
			SET @I = @I+1  
		END
		
		
		set @PendingVchrs=''
		
		select @PendingVchrs=@PendingVchrs+dbo.[fnDoc_GetPendingVouchers](VoucherNo) from ACC_DocDetails WITH(NOLOCK)
		where RefCCID=@SCostCenterID and RefNodeid=@ContractID and StatusID=429
		
		insert into @tabvchrs
		exec SPSplitString @PendingVchrs,','
		
		update ACC_DocDetails 
		set StatusID=370
		where StatusID=452 and VoucherNo in(select vno from @tabvchrs)
	END     
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

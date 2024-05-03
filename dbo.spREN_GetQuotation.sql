USE PACT2C222
GO
SET ANSI_NULLS, QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spREN_GetQuotation]
	@QuotationID [bigint] = 0,
	@RoleID [bigint],
	@UserID [bigint],
	@LangID [int] = 1
WITH ENCRYPTION, EXECUTE AS CALLER
AS
BEGIN TRANSACTION                        
BEGIN TRY                         
SET NOCOUNT ON 

	declare @ccid int,@ContractExists bit                      
	Declare @WID bigint,@Userlevel int,@StatusID int,@Level int,@canApprove bit,@canEdit bit,@Type int,@escDays int,@CreatedDate datetime

	set @ContractExists=0            
	SELECT @ccid=CostCenterID
	,@StatusID=StatusID, @WID=WorkFlowID,@Level=WorkFlowLevel,@CreatedDate=CONVERT(datetime,createdDate)
	 FROM  REN_Quotation WITH(NOLOCK) where QuotationID = @QuotationID

	if exists(SELECT ContractID FROM  REN_Contract WITH(NOLOCK) where QuotationID = @QuotationID)
		set @ContractExists=1

	if(@WID is not null and @WID>0)  
		BEGIN  
			SELECT @Userlevel=LevelID,@Type=type FROM [COM_WorkFlow]   WITH(NOLOCK)   
			where WorkFlowID=@WID and  UserID =@UserID

			if(@Userlevel is null )  
				SELECT @Userlevel=LevelID,@Type=type FROM [COM_WorkFlow]  WITH(NOLOCK)    
				where WorkFlowID=@WID and  RoleID =@RoleID

			if(@Userlevel is null )       
				SELECT @Userlevel=LevelID,@Type=type FROM [COM_WorkFlow] W WITH(NOLOCK)
				JOIN COM_Groups G WITH(NOLOCK) on w.GroupID=g.GID     
				where g.UserID=@UserID and WorkFlowID=@WID

			if(@Userlevel is null )  
				SELECT @Userlevel=LevelID,@Type=type FROM [COM_WorkFlow] W WITH(NOLOCK)
				JOIN COM_Groups G WITH(NOLOCK) on w.GroupID=g.GID     
				where g.RoleID =@RoleID and WorkFlowID=@WID
			
			if(@Userlevel is null )  	
				SELECT @Type=type FROM [COM_WorkFlow] WITH(NOLOCK) where WorkFlowID=@WID
		end 
     
		set @canEdit=1  
       
		if(@StatusID in(467,468,466))  
		begin  
			if(@Userlevel is not null and  @Level is not null and @Userlevel<@level)  
			begin  
				set @canEdit=0   
			end    
		end   
		ELSE if(@StatusID=470)
		BEGIN
		    if(@Userlevel is not null and  @Level is not null and @Userlevel<@level)  
			begin  
				set @canEdit=1
			end
			ELSE
				set @canEdit=0
		END
  
		if(@StatusID in(440,466))  
		begin    
			if(@Userlevel is not null and  @Level is not null and @Userlevel>@level)  
			begin
				if(@Type=1 or @Level+1=@Userlevel)
					set @canApprove=1   
				ELSE
				BEGIN
					if exists(select EscDays FROM [COM_WorkFlow] WITH(NOLOCK)
					where workflowid=@WID and ApprovalMandatory=1 and LevelID<@Userlevel and LevelID>@Level)
						set @canApprove=0
					ELSE
					BEGIN	
						select @escDays=sum(escdays) from (select max(escdays) escdays from [COM_WorkFlow] WITH(NOLOCK) 
						where workflowid=@WID and LevelID<@Userlevel and LevelID>@Level
						group by LevelID) as t
						 
						set @CreatedDate=dateadd("d",@escDays,@CreatedDate)
						
						select @escDays=sum(escdays) from (select max(eschours) escdays from [COM_WorkFlow] WITH(NOLOCK) 
						where workflowid=@WID and LevelID<@Userlevel and LevelID>@Level
						group by LevelID) as t
						
						set @CreatedDate=dateadd("HH",@escDays,@CreatedDate)
						
						if (@CreatedDate<getdate())
							set @canApprove=1   
						ELSE
							set @canApprove=0
					END	
				END	
			end
			else  
				set @canApprove= 0   
		end  
		else  
			set @canApprove= 0  
	
	DECLARE @Status NVARCHAR(MAX)
	
	SELECT @Status='['+CS.[Status]+']' FROM REN_Contract RC WITH(NOLOCK) 
	JOIN COM_Status CS WITH(NOLOCK) ON CS.StatusID=RC.StatusID
	WHERE RC.QuotationID= @QuotationID  
	
	SELECT @Status='['+CS.[Status]+']'+ISNULL(@Status,'') FROM REN_Quotation RQ WITH(NOLOCK) 
	JOIN COM_Status CS WITH(NOLOCK) ON CS.StatusID=RQ.StatusID
	WHERE RQ.QuotationID= @QuotationID 
			
	SELECT QuotationID ContractID, Prefix ContractPrefix, convert(datetime,Date) ContractDate,Number ContractNumber, StatusID, PropertyID, UnitID, TenantID, RentAccID,                      
	IncomeAccID, Purpose, convert(datetime,StartDate) StartDate,  convert(datetime,ExtendTill) ExtndTill,convert(datetime, EndDate) EndDate, TotalAmount, NonRecurAmount, RecurAmount,  [GUID], LocationID , DivisionID , CurrencyID ,TermsConditions , SalesmanID , AccountantID,LandlordID , Narration,
	BasedOn,SNO,@ContractExists ContractExists,RefQuotation,multiName,CostCenterID
	,@canEdit canEdit,@canApprove canApprove,WorkFlowID,WorkFlowLevel,@Userlevel Userlevel,NoOfUnits,RecurDuration,@Status [Status]
	 FROM  REN_Quotation WITH(NOLOCK) where QuotationID = @QuotationID
                   
	SELECT    DISTINCT  CP.NodeID, CP.QuotationID ContractID, CP.CCID, CP.CCNodeID, CP.CreditAccID, CP.ChequeNo, convert(datetime,CP.ChequeDate) ChequeDate, CP.PayeeBank,                      
	CP.DebitAccID, CP.Amount, CP.RentAmount RentAmount, CP.Discount DiscountAmount,CP.Narration
	,CP.InclChkGen,CP.vattype,CP.VatPer,CP.VatAmount, ACC.ACCOUNTNAME CREDITNAME , ACCD.ACCOUNTNAME  DEBITNAME ,CP.IsRecurr   ,0 Refund , 0  StatusID                   
	, '' VoucherNo ,'' DocPrefix ,'' DocNumber , 0  CostCenterID, ''  DocumentName ,0  DocID,cp.Detailsxml,cp.RecurInvoice,CP.Sqft,CP.Rate           
	FROM REN_QuotationParticulars  CP WITH(NOLOCK)  
	join REN_Quotation CNT WITH(NOLOCK) ON CP.QuotationID = CNT.QuotationID
	LEFT JOIN ACC_Accounts ACC WITH(NOLOCK) ON ACC.ACCOUNTID = CP.CreditAccID                         
	LEFT JOIN ACC_Accounts ACCD WITH(NOLOCK) ON ACCD.ACCOUNTID = CP.DebitAccID                           
	where  CP.QuotationID = @QuotationID                   
	
	if(@ccid=129)
		SELECT DISTINCT CDM.SNO, CP.NodeID,CP.ChequeNo, Convert(datetime,CP.ChequeDate) ChequeDate , CP.CustomerBank, CP.DebitAccID, CP.Amount ,  
		period,ACC.AccountName DebitAccName , CP.Narration , Sts.Status StatusID   , Doc.VoucherNo ,Doc.DocPrefix DocPrefix ,Doc.DocNumber DocNumber , doc.CostCenterID                       
		CostCenterID,  ADF.DocumentName DocumentName,Doc.DocID DocID , Doc.StatusID   DocStatusID,Doc.DocumentType  DocumentType
		FROM REN_quotationPayTerms CP WITH(NOLOCK)  
		LEFT JOIN ACC_Accounts ACC WITH(NOLOCK) ON ACC.ACCOUNTID = CP.DebitAccID                         
		LEFT JOIN REN_ContractDocMapping CDM WITH(NOLOCK) ON CP.QuotationID = CDM.ContractID AND CP.SNO = CDM.SNO  and CDM.ContractCCID =   129                 
		LEFT JOIN Acc_DocDetails Doc WITH(NOLOCK) on  CDM.DocID =  Doc.DocID                         
		LEFT join ADM_DocumentTypes ADF WITH(NOLOCK) on Doc.CostCenterID = ADF.CostCenterID                        
		LEFT JOIN Com_Status Sts WITH(NOLOCK) on Sts.StatusID =  Doc.StatusID                         
		where CP.QuotationID = @QuotationID
		order by CDM.SNO    
	ELSE
		SELECT DISTINCT  CP.NodeID,  CP.ChequeNo, Convert(datetime,CP.ChequeDate) ChequeDate , CP.CustomerBank, CP.DebitAccID, CP.Amount,                 
		period,ACC.AccountName DebitAccName , CP.Narration , ''  StatusID   , '' VoucherNo ,''  DocPrefix ,''  DocNumber , 0 CostCenterID,  ''  DocumentName,0 DocID                        
		FROM REN_quotationPayTerms CP WITH(NOLOCK)                       
		LEFT JOIN ACC_Accounts ACC WITH(NOLOCK) ON ACC.ACCOUNTID = CP.DebitAccID                         
		where CP.QuotationID = @QuotationID --and CDM.TYPE = 2                     
     
   
              
	--Getting data from Contract extended table                    
	SELECT * FROM  REN_QuotationExtended WITH(NOLOCK)                     
	WHERE QuotationID=@QuotationID                    
	          
	-- GETTING COSTCENTER DATA                     
	SELECT * FROM  COM_CCCCDATA WITH(NOLOCK)                     
	WHERE NodeID=@QuotationID and CostCenterID = @ccid  

	SELECT * FROM  COM_Files WITH(NOLOCK)   
	WHERE FeatureID=@ccid and  FeaturePK=@QuotationID 
	
	SELECT     NoteID, Note, FeatureID, FeaturePK, CompanyGUID, GUID, CreatedBy, convert(datetime,CreatedDate) as CreatedDate, 
	ModifiedBy, ModifiedDate, CostCenterID
	FROM COM_Notes WITH(NOLOCK) 
	WHERE FeatureID=@ccid and  FeaturePK=@QuotationID
	
	select 1 where 1<>1
	
	if exists(SELECT *	FROM  REN_Quotation WITH(NOLOCK) where RefQuotation = @QuotationID)
		SELECT UnitID,multiName uname
		FROM  REN_Quotation WITH(NOLOCK) where RefQuotation = @QuotationID or QuotationID = @QuotationID

	select 1 where 1<>1
	 
	IF @WID is not null and @WID>0
	begin
			SELECT CONVERT(DATETIME, A.CreatedDate) Date,A.WorkFlowLevel,
			(SELECT TOP 1 LevelName FROM COM_WorkFlow L with(nolock) WHERE L.WorkFlowID=@WID AND L.LevelID=A.WorkFlowLevel) LevelName,
			A.CreatedBy,A.StatusID,S.Status,A.Remarks,U.FirstName,U.LastName
			FROM COM_Approvals A with(nolock),COM_Status S with(nolock),ADM_Users U with(nolock)
			WHERE A.RowType=1 AND S.StatusID=A.StatusID AND CCID=@ccid AND CCNodeID=@QuotationID AND A.USERID=U.USERID
			ORDER BY A.CreatedDate
			
			select @WID WID,levelID,LevelName from COM_WorkFlow with(nolock) 
			where WorkFlowID=@WID
			group by levelID,LevelName
	end  
                     
COMMIT TRANSACTION                        
SET NOCOUNT OFF;                        
RETURN 1                        
END TRY                        
BEGIN CATCH                        
 --Return exception info [Message,Number,ProcedureName,LineNumber]                          
 IF ERROR_NUMBER()=50000                        
 BEGIN                        
  SELECT ErrorMessage,ErrorNumber FROM COM_ErrorMessages WITH(nolock) WHERE ErrorNumber=ERROR_MESSAGE() AND LanguageID=@LangID                        
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

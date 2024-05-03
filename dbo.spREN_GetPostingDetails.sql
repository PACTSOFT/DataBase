USE PACT2C222
GO
SET ANSI_NULLS, QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spREN_GetPostingDetails]
	@CostCenterID [int] = 95,
	@PropertyID [bigint],
	@UnitID [bigint],
	@TenantID [bigint],
	@RentAccID [bigint],
	@ContractID [bigint] = 0,
	@Mode [int],
	@VatNode [bigint],
	@depCCID [int],
	@invccid [int],
	@UserID [bigint],
	@LangID [int] = 1
WITH ENCRYPTION, EXECUTE AS CALLER
AS
BEGIN TRANSACTION                        
BEGIN TRY                         
SET NOCOUNT ON                        
                        
	declare @RenewRefID BIGINT,@PropertyNodeID BIGINT,@UnitNodeID BIGINT,@TenantNodeID BIGINT,@PRODUCTID BIGINT,@RentAccBillwise BIT,@unitDim int,@PostIncome bit
	declare @PickAcc nvarchar(50),@penAccID BIGINT,@VatAccID BIGINT,@PendingVchrs nvarchar(max),@AdvReceivableCloseAccID BIGINT,@AdvReceivableBillwise BIT

	Exec @PropertyNodeID=[dbo].[spREN_GetDimensionNodeID]
			 @NodeID  =@PropertyID,      
			 @CostcenterID = 92,   
			 @UserID =@UserID,      
			 @LangID =@LangID
			
	if(@UnitID>0)
	BEGIN		
		Exec @UnitNodeID=[dbo].[spREN_GetDimensionNodeID]
				 @NodeID  =@UnitID,      
				 @CostcenterID = 93,   
				 @UserID =@UserID,      
				 @LangID =@LangID 
	END
	ELSE			 		 
		set @UnitNodeID=1
		
	Exec @TenantNodeID=[dbo].[spREN_GetDimensionNodeID]
			 @NodeID  =@TenantID,      
			 @CostcenterID = 94,   
			 @UserID =@UserID,      
			 @LangID =@LangID 	
	
	exec [spDOC_GetNode] 3,'CONTRACT',0,0,'GUID','Admin',1,1,@PRODUCTID output
	
	SET @PickAcc=1
	
	if(@ContractID>0 and @Mode in(1,2))
	BEGIN
		select @PickAcc=ISNULL(Value,1) from COM_CostCenterPreferences WITH(nolock)  
		where CostCenterID=@CostCenterID and Name='PickACC'
				
		set @penAccID=0
		if(@PickAcc=1)
			select @penAccID=isnull(PenaltyAccountID,0)  from REN_Property p with(NOLOCK)
			join REN_Contract c with(NOLOCK) on p.NodeID=c.PropertyID
			where c.ContractID=@ContractID
		else
			select @penAccID=isnull(PenaltyAccountID,0)  from REN_Units u with(NOLOCK)
			join REN_Contract c with(NOLOCK) on u.UnitID=c.UnitID
			where c.ContractID=	@ContractID
	END
	
	set @VatAccID=0
	if(@VatNode>0)
	BEGIN
		
		SELECT  @VatAccID=CreditAccountID FROM REN_Particulars a WITH(NOLOCK)
		where UnitID = @UnitID and ParticularID=@VatNode
		
		if(@VatAccID=0)
			SELECT  @VatAccID=CreditAccountID FROM REN_Particulars a WITH(NOLOCK)			
			where PropertyID = @PropertyID and UnitID =0 and ParticularID=@VatNode			
	END
	
	if(@CostCenterID=129)
	BEGIN
		select @PickAcc=ISNULL(Value,1) from COM_CostCenterPreferences WITH(nolock)  
		where CostCenterID=95 and Name='PickACC'
		
		set @AdvReceivableCloseAccID=0
		if(@PickAcc=1)
			select @AdvReceivableCloseAccID=isnull(AdvReceivableCloseAccID,0)  from REN_Property with(NOLOCK)
			where NodeID=@PropertyID
		else
			select @AdvReceivableCloseAccID=isnull(AdvReceivableCloseAccID,0)  from REN_Units with(NOLOCK)
			where UnitID=@UnitID
		
		SELECT @AdvReceivableBillwise=IsBillwise from ACC_Accounts WITH(NOLOCK) WHERE AccountID=@AdvReceivableCloseAccID
	END
	
	SELECT @RentAccBillwise=IsBillwise from ACC_Accounts WITH(NOLOCK) WHERE AccountID=@RentAccID
	SELECT @PostIncome=PostIncome from Ren_units WITH(NOLOCK) WHERE UnitID=@UnitID

	select @RentAccBillwise IsBillwise,@PRODUCTID PRODUCTID,@PropertyNodeID PropertyID,@UnitNodeID UnitID,@TenantNodeID TenantID,@penAccID PenAccID
	,@AdvReceivableCloseAccID AdvReceivableCloseAccID,@AdvReceivableBillwise AdvReceivableBillwise,@VatAccID VatAccID,@PostIncome PostIncome

	if(@ContractID>0 and @Mode>0)
	BEGIN
		SELECT @RenewRefID=RenewRefID FROM REN_CONTRACT WITH(NOLOCK)                       
		where ContractID = @ContractID
		
		declare @tab table(CreditAccID BIGINT,DebitAccID BIGINT,Amount Float,VatType nvarchar(50),VatPer float,VatAmount float,TaxCategoryID BIGINT,TaxableAmt float,CCNodeID bigint)
		declare @tabvchrs table(vno nvarchar(200))

		while(@RenewRefID>0)
		BEGIN
			insert into @tab
			SELECT  CP.CreditAccID,CP.DebitAccID,CP.Amount,CP.VatType,VatPer,VatAmount,CP.TaxCategoryID,TaxableAmt,cp.CCNodeID  FROM REN_ContractParticulars  CP WITH(NOLOCK)   
			LEFT JOIN REN_CONTRACT CNT WITH(NOLOCK) ON CP.CONTRACTID = CNT.CONTRACTID 
			LEFT JOIN REN_Particulars PART WITH(NOLOCK) ON CP.CCNODEID = PART.ParticularID  and  PART.PropertyID = CNT.PropertyID AND PART.UNITID = CNT.UnitID
			LEFT JOIN REN_Particulars PARTP WITH(NOLOCK) ON CP.CCNODEID = PARTP.ParticularID  and  PARTP.PropertyID = CNT.PropertyID AND PARTP.UNITID = 0
			where  CP.ContractID = @RenewRefID and 
			((PART.Refund is not null and PART.Refund =1) or (PARTP.Refund is not null and PARTP.Refund =1) )
			
			if exists(select isnull(RenewRefID,0) from REN_Contract		
			where ContractID=@RenewRefID)
				select @RenewRefID=isnull(RenewRefID,0) from REN_Contract		
				where ContractID=@RenewRefID
			ELSE
				set @RenewRefID=0
		END 

		select * from @tab
		
		
		if exists(select ContractID FROM REN_CONTRACT WITH(NOLOCK)                       
		where RefContractID = @ContractID)
		BEGIN
		
			Select @unitDim=convert(int,value) from COM_CostCenterPreferences WITH(NOLOCK)
			where name = 'LinkDocument' AND COSTCENTERID = 93 and isnumeric(value)=1
			
			 set @PendingVchrs='SELECT convert(datetime,docdate) docdate,amount,Type,dcccnid'+convert(nvarchar(max),(@unitDim-50000))+' unitNodeID FROM REN_CONTRACTDOCMAPPING a WITH(NOLOCK)
			join acc_docdetails b WITH(NOLOCK) on a.docid=b.docid
			join com_docccdata c on c.accdocdetailsID=b.accdocdetailsID
			where doctype=5 and contractid='+convert(nvarchar(max),@ContractID) 
			print @PendingVchrs
			exec(@PendingVchrs)
		END
		ELSE
			SELECT convert(datetime,docdate) docdate,amount,Type FROM REN_CONTRACTDOCMAPPING a WITH(NOLOCK)
			join acc_docdetails b WITH(NOLOCK) on a.docid=b.docid
			where doctype=5 and contractid=@ContractID
		
		SELECT  ParticularID,CreditAccountID,DebitAccountID,DiscountAmount,DiscountPercentage,dr.AccountName DrAccName,cr.AccountName CrAccName,Vat 
		FROM REN_Particulars a WITH(NOLOCK)
		left join ACC_Accounts dr WITH(NOLOCK) on a.DebitAccountID=dr.AccountID
		left join ACC_Accounts cr WITH(NOLOCK) on a.CreditAccountID=cr.AccountID
		where PropertyID = @PropertyID and TypeID=4 and UnitID =0
		
		SELECT  ParticularID,CreditAccountID,DebitAccountID,DiscountAmount,DiscountPercentage,dr.AccountName DrAccName,cr.AccountName CrAccName,Vat 
		FROM REN_Particulars a WITH(NOLOCK)
		left join ACC_Accounts dr WITH(NOLOCK) on a.DebitAccountID=dr.AccountID
		left join ACC_Accounts cr WITH(NOLOCK) on a.CreditAccountID=cr.AccountID
		where UnitID = @UnitID and TypeID=4
		
		
		select VoucherNo,Amount,ChequeNumber,CONVERT(datetime,ChequeDate) ChequeDate,dbo.[fnDoc_GetPendingAmount](VoucherNo) PendingAmount 
		from ACC_DocDetails WITH(NOLOCK)
		where RefCCID=@CostCenterID and RefNodeid=@ContractID and StatusID=429
		
		set @PendingVchrs=''
		
		select @PendingVchrs=@PendingVchrs+dbo.[fnDoc_GetPendingVouchers](VoucherNo) 
		from ACC_DocDetails WITH(NOLOCK)
		where RefCCID=@CostCenterID and RefNodeid=@ContractID and StatusID=429
		
		insert into @tabvchrs
		exec SPSplitString @PendingVchrs,','
		
		select VoucherNo,Amount,ChequeNumber,CONVERT(datetime,ChequeDate) ChequeDate,DocID,ChequeBankName,CommonNarration Narration
		,CreditAccount,DebitAccount,CommonNarration,CurrencyID,ExchangeRate,CONVERT(datetime,ChequeMaturityDate) ChequeMaturityDate
		from ACC_DocDetails WITH(NOLOCK)
		where StatusID=370 and VoucherNo in(select vno from @tabvchrs)	
		
		if(@invccid>0)
		BEGIN
			set @depCCID=@depCCID-50000
			
			set @PendingVchrs='SELECT dcccnid'+convert(nvarchar,@depCCID)+' PartID'
			if(@unitDim is not null and @unitDim>50000)
				set @PendingVchrs=@PendingVchrs+',dcccnid'+convert(nvarchar,(@unitDim-50000))+' UnitID'
			set @PendingVchrs=@PendingVchrs+',sum(gross) TotInv
			FROM INV_DocDetails a with(nolock)
			join com_docccdata b on a.INVDocDetailsid=b.INVDocDetailsid
			where costcenterid='+convert(nvarchar,@invccid)+' and refccid='+convert(nvarchar,@CostCenterID)+' and refnodeid='+convert(nvarchar,@ContractID)+'
			group by dcccnid'+convert(nvarchar,@depCCID)
			if(@unitDim is not null and @unitDim>50000)
				set @PendingVchrs=@PendingVchrs+',dcccnid'+convert(nvarchar,(@unitDim-50000))
			print @PendingVchrs
			exec(@PendingVchrs)
		END
		
    END
                     
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

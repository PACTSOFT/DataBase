USE PACT2C222
GO
SET ANSI_NULLS, QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spREN_GetParticulars]
	@UnitID [bigint] = 0,
	@PropertyID [bigint] = 0,
	@ContractStartDate [datetime],
	@ContractType [int] = 0,
	@ContractEndDate [datetime],
	@ContractID [bigint],
	@MultiUnitIDs [nvarchar](max),
	@UserID [bigint],
	@LangID [int] = 1
WITH ENCRYPTION, EXECUTE AS CALLER
AS
BEGIN TRY                       
SET NOCOUNT ON                      
                   
                   
	declare @T1 nvarchar(100),@T2 nvarchar(100),@Sql nvarchar(max)   , @Rent FLOAT,@PropRRA BIGINT,@isvat bit
	
	if exists(select * from adm_globalpreferences with(nolock) where name ='VATVersion')	 
		set @isvat=1
	else
		set @isvat=0
		
	if(@MultiUnitIDs is not null and  @MultiUnitIDs<>'')
	BEGIN
		set @Sql =' SELECT @PropertyID=PropertyID FROM REN_Units with(nolock) WHERE UnitID in('+@MultiUnitIDs+')'
		EXEC sp_executesql @Sql,N'@PropertyID bigint OUTPUT',@PropertyID output
	END                       
	else IF @UnitID<> 0
	  SELECT @PropertyID=PropertyID,@Rent=Rent FROM REN_Units with(nolock) WHERE UnitID=@UnitID             
                       
	set @T1=(select TableName from adm_features with(nolock) where featureid=(select value from ADM_GlobalPreferences with(nolock) where  Name='DepositLinkDimension'))
	
	select @PropRRA=RentalReceivableAccountID from REN_Property WITH(NOLOCK) where NodeID=@PropertyID
         
    --Unit Particulars                   
	set @Sql =' select T1.NodeID,T1.Name as Particulars, PRT.PropertyID, PRT.UnitID, PRT.CreditAccountID CreditID, PRT.DebitAccountID DebitID, PRT.Refund, PRT.DiscountPercentage, PRT.DiscountAmount  ,                         
	ACC.AccountCode CreditCode, ACC.AccountNAME CreditName  ,ACCD.AccountCode DebitCode, ACCD.AccountNAME DebitName , '+ CONVERT(NVARCHAR,ISNULL(@PropertyID, 0)) +' ActualPropertyID   '
	
	if(@isvat=1)
		SET  @Sql  = @Sql + ',Tx.Name TaxCategory,PRT.TaxCategoryID,PRT.VatType,PRT.RecurInvoice'
	else
		SET  @Sql = @Sql + ',NULL TaxCategory,NULL TaxCategoryID,NULL VatType,NULL RecurInvoice'
				
	SET  @Sql  = @Sql + ',PostDebit,InclChkGen,VAT,AdvanceAccountID AdvanceAcc,UNT.RentalIncomeAccountID IncomeAccID , UNT.RentalReceivableAccountID RentRecAccID ,  UNT.AdvanceRentAccountID AdvRentAccID ,ACCAdvRec.AccountNAME ACCAdvRec                   
	,  UNT.BankAccount DebitAccID,Debit.AccountNAME DebitAcc , UNT.TermsConditions , PRT.TypeID Type ,UNT.AdvanceRentPaid AdvanceRentPaid , AdvRentP.AccountNAME AdvanceRentPaidName   from '+@T1 + ' AS T1 with(nolock) '

	SET  @Sql  = @Sql + ' LEFT JOIN REN_Particulars PRT with(nolock) ON T1.NodeID = PRT.PARTICULARID                        
	left JOIN REN_Units UNT with(nolock) ON  PRT.PropertyID = UNT.PropertyID '  
	
	if(@isvat=1)                   
		SET  @Sql  = @Sql + ' LEFT JOIN COM_CC50060 Tx WITH(NOLOCK) ON Tx.NodeID=PRT.TaxCategoryID '
	               
	SET  @Sql  = @Sql + 'LEFT JOIN ACC_Accounts ACC with(nolock) ON ACC.AccountID = PRT.CreditAccountID                        
	LEFT JOIN ACC_Accounts ACCAdvRec with(nolock) ON ACCAdvRec.AccountID = UNT.AdvanceRentAccountID 
	LEFT JOIN ACC_Accounts Debit with(nolock) ON Debit.AccountID = UNT.BankAccount            
	LEFT JOIN ACC_Accounts AdvRentP with(nolock) ON AdvRentP.AccountID = UNT.AdvanceRentPaid                    
	LEFT JOIN ACC_Accounts ACCD with(nolock) ON  ACCD.AccountID = PRT.DebitAccountID  WHERE PRT.PropertyID = ' + CONVERT(NVARCHAR, ISNULL(@PropertyID, 0))        
	
	if(@MultiUnitIDs is not null and  @MultiUnitIDs<>'')
		SET  @Sql = @Sql + ' AND PRT.UnitID in ('+@MultiUnitIDs+') AND UNT.UnitID in ('+@MultiUnitIDs+')'
	else
		SET  @Sql  = @Sql + ' AND PRT.UNITID = ' + CONVERT(NVARCHAR, @UnitID) + ' AND UNT.UNITID = ' + CONVERT(NVARCHAR, @UnitID)
		
	IF(@ContractType > 0)        
		SET  @Sql = @Sql + ' AND PRT.CONTRACTTYPE = ' + CONVERT(NVARCHAR, @ContractType)         
	   
	exec (@Sql)            
    
    --Property Particulars
	set @Sql =' select T1.NodeID,T1.Name as Particulars, PRT.PropertyID, PRT.UnitID, PRT.CreditAccountID CreditID, PRT.DebitAccountID DebitID, PRT.Refund, PRT.DiscountPercentage, PRT.DiscountAmount ,                          
	ACC.AccountCode CreditCode, ACC.AccountNAME CreditName  ,ACCD.AccountCode DebitCode, ACCD.AccountNAME DebitName , '+ CONVERT(NVARCHAR,ISNULL(@PropertyID, 0)) +' ActualPropertyID                       
    ,InclChkGen ,VAT,AdvanceAccountID AdvanceAcc,PRP.RentalIncomeAccountID IncomeAccID , PRP.RentalReceivableAccountID RentRecAccID ,  PRP.AdvanceRentAccountID AdvRentAccID,ACCAdvRec.AccountNAME ACCAdvRec '
    
	if(@isvat=1)                
		SET  @Sql = @Sql + ',Tx.Name TaxCategory,PRT.TaxCategoryID,PRT.VatType,PRT.RecurInvoice'
	else
		SET  @Sql = @Sql + ',NULL TaxCategory,NULL TaxCategoryID,NULL VatType,NULL RecurInvoice'
	
	SET  @Sql = @Sql + ',PostDebit,  PRP.BankAccount DebitAccID,Debit.AccountNAME DebitAcc , PRP.TermsConditions , PRT.TypeID Type  ,PRP.AdvanceRentPaid AdvanceRentPaid , AdvRentP.AccountNAME AdvanceRentPaidName   from '+@T1 + ' AS T1 with(nolock)  '                      
	SET  @Sql = @Sql + ' LEFT JOIN REN_Particulars PRT with(nolock) ON T1.NodeID = PRT.PARTICULARID                       
    JOIN REN_Property PRP with(nolock) ON PRT.PropertyID = PRP.NodeID                      
	LEFT JOIN ACC_Accounts ACC with(nolock) ON ACC.AccountID = PRT.CreditAccountID                        
	LEFT JOIN ACC_Accounts ACCAdvRec with(nolock) ON ACCAdvRec.AccountID = PRP.AdvanceRentAccountID                        
	LEFT JOIN ACC_Accounts Debit with(nolock) ON Debit.AccountID = PRP.BankAccount          '  
 
	if(@isvat=1)
		SET  @Sql = @Sql + ' LEFT JOIN COM_CC50060 Tx WITH(NOLOCK) ON Tx.NodeID=PRT.TaxCategoryID '
  
	SET  @Sql = @Sql + ' LEFT JOIN ACC_Accounts AdvRentP with(nolock)  ON AdvRentP.AccountID = PRP.AdvanceRentPaid                   
	LEFT JOIN ACC_Accounts ACCD with(nolock) ON ACCD.AccountID = PRT.DebitAccountID   
	WHERE PRT.PropertyID = ' + CONVERT(NVARCHAR, @PropertyID)  + ' AND PRT.UNITID = 0 ' 
	
	IF(@ContractType > 0)      
		SET  @Sql = @Sql + ' AND PRT.CONTRACTTYPE = ' + CONVERT(NVARCHAR, @ContractType)                    

	exec (@Sql)    
    
    if(@MultiUnitIDs is not null and  @MultiUnitIDs<>'')
    BEGIN
		set @Sql ='SELECT PropertyID,AnnualRent RENT,RentalIncomeAccountID,RentalReceivableAccountID,AdvanceRentAccountID
		,'+convert(nvarchar,isnull(@PropRRA,'0'))+' PropRentRecAccID FROM REN_Units with(nolock) WHERE UnitID in('+@MultiUnitIDs+')'
		print @Sql
		exec (@Sql) 
    END
    Else
		SELECT PropertyID,RentalReceivableAccountID,AnnualRent RENT,@PropRRA PropRentRecAccID FROM REN_Units with(nolock) WHERE UnitID = @UnitID                       
                      
	select value from ADM_GlobalPreferences with(nolock) where  Name='DepositLinkDimension'                      
                      
    if(@MultiUnitIDs is not null and  @MultiUnitIDs<>'')
    BEGIN                  
		set @Sql ='SELECT ContractID, ContractPrefix, ContractDate,convert(datetime,StartDate) StartDate,                   
					convert(datetime, EndDate) EndDate,  ContractNumber, StatusID                       
					FROM REN_Contract with(nolock)                      
					WHERE ( '''+convert(nvarchar,@ContractStartDate)+'''   between CONVERT(datetime, StartDate) and CONVERT(datetime, EndDate)      
					or       '''+convert(nvarchar,@ContractEndDate)+'''  between CONVERT(datetime, StartDate) and CONVERT(datetime, EndDate)  )             
					AND UnitID in('+@MultiUnitIDs+') and    StatusID <> 428   and    StatusID <> 451   
					and ContractID<>'+convert(nvarchar,@ContractID)+'and RefContractID<>'+convert(nvarchar,@ContractID)
		exec (@Sql) 
    END
    ELSE
		SELECT ContractID, ContractPrefix, ContractDate,convert(datetime,StartDate) StartDate,                   
							 convert(datetime, EndDate) EndDate,  ContractNumber, StatusID                       
		FROM REN_Contract with(nolock)                      
		WHERE (@ContractStartDate   between CONVERT(datetime, StartDate) and CONVERT(datetime, EndDate)      
		 or       @ContractEndDate   between CONVERT(datetime, StartDate) and CONVERT(datetime, EndDate)  )             
		  AND UnitID = @UnitID and    StatusID <> 428   and    StatusID <> 451   
		  and ContractID<>@ContractID            
                        
    if(@MultiUnitIDs is not null and  @MultiUnitIDs<>'')
    BEGIN 
		set @Sql ='SELECT  UnitID,RENT RENTAMT , ISNULL((CASE WHEN DISCOUNTPERCENTAGE = -100 THEN DISCOUNTAMOUNT ELSE (RENT  * DISCOUNTPERCENTAGE) / 100 END),0)  DICOUNT   
		, ISNULL(AnnualRent,0) RENT ,CONVERT(FLOAT,ISNULL(CASE WHEN RentableArea<>''0'' THEN RentableArea END,1)) RentableArea
		FROM REN_Units  with(nolock) WHERE UnitID in('+@MultiUnitIDs+')'  
		exec (@Sql) 
    END
    ELSE
    BEGIN        
		IF NOT EXISTS( SELECT UNITID FROM REN_UNITRATE WHERE UNITID  =@UnitID )       
		BEGIN  
			SELECT  RENT RENTAMT , CASE WHEN DISCOUNTPERCENTAGE = -100 THEN DISCOUNTAMOUNT ELSE (RENT  * DISCOUNTPERCENTAGE) / 100 END  DICOUNT   
			, AnnualRent RENT,CONVERT(FLOAT,ISNULL(CASE WHEN RentableArea<>'0' THEN RentableArea END,1)) RentableArea 
			FROM REN_Units  with(nolock) WHERE UNITID  = @UnitID    
		END
		ELSE   
		BEGIN  
			SELECT TOP 1 RUR.UnitID, RUR.Amount RENTAMT,RUR.Discount DICOUNT , RUR.AnnualRent  RENT ,CONVERT(FLOAT,ISNULL(CASE WHEN RentableArea<>'0' THEN RentableArea END,1)) RentableArea
			FROM REN_UNITRATE RUR with(nolock)
			LEFT JOIN REN_Units RU with(nolock) ON RU.UnitID=RUR.UNITID
			WHERE RUR.UNITID  =@UnitID  
			AND CONVERT(DATETIME,WITHEFFECTFROM) BETWEEN  @ContractStartDate and  @ContractEndDate  
		END      
    END
    
    set @Sql ='SELECT AccountantID,SalesmanID,LandlordID,BasedOn'
	if(@isvat=1)
		set @Sql =@Sql+',ccnid70,ccnid58,ccnid59,ccnid61,ccnid62 '
	else
		set @Sql =@Sql+',0 ccnid70,0 ccnid58,0 ccnid59,0 ccnid61,0 ccnid62 '
		
	set @Sql =@Sql+' FROM REN_Units a with(nolock) 
	join com_ccccdata  b with(nolock)  on a.unitid=b.nodeid'
		
    if(@MultiUnitIDs is not null and  @MultiUnitIDs<>'') 
		set @Sql =@Sql+' WHERE UnitID in('+@MultiUnitIDs+') and b.costcenterid=93'		
    ELSE
		set @Sql =@Sql+' WHERE UnitID='+convert(nvarchar,@UnitID)+' and b.costcenterid=93'
     exec (@Sql) 
                  
   
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
SET NOCOUNT OFF                        
RETURN -999                         
END CATCH     
GO

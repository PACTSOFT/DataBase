USE PACT2C222
GO
SET ANSI_NULLS, QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spAcc_SetAssetManagement]
	@AssetID [bigint],
	@AssetCode [nvarchar](50),
	@AssetName [nvarchar](max),
	@StatusID [bigint],
	@PurchaseValue [nvarchar](50),
	@ParentAssetID [bigint],
	@IsGroup [bit] = 0,
	@CodePrefix [nvarchar](200) = null,
	@CodeNumber [bigint] = 0,
	@Sno [nvarchar](50),
	@DetailXML [nvarchar](max) = null,
	@ChangeValueXML [nvarchar](max) = null,
	@CustomFieldsQuery [nvarchar](max) = null,
	@CustomCostCenterFieldsQuery [nvarchar](max) = null,
	@AssetDepreciationXML [nvarchar](max) = null,
	@HistoryXML [nvarchar](max) = null,
	@NotesXML [nvarchar](max) = null,
	@AttachmentsXML [nvarchar](max) = null,
	@CompanyGUID [varchar](50),
	@GUID [varchar](50),
	@CreatedBy [nvarchar](50),
	@UserID [int],
	@LangID [int] = 1
WITH ENCRYPTION, EXECUTE AS CALLER
AS
BEGIN TRANSACTION        
BEGIN TRY        
SET NOCOUNT ON;      
        
    DECLARE @ID int,@cnt int,@Dt FLOAT, @lft bigint,@rgt bigint,@TempGuid nvarchar(50),@Selectedlft bigint,@Selectedrgt bigint,@HasAccess bit,@IsDuplicateNameAllowed bit,@IsAssetCodeAutoGen bit  ,@IsIgnoreSpace bit  ,      
 @Depth int,@ParentID bigint,@SelectedIsGroup int , @XML XML,@ParentCode nvarchar(200),@UpdateSql nvarchar(max),@astID bigint,@DtXML xml , @DepXML XML  ,@AssetCCID bigint,@DeprStartValue float
       
  if(@ParentAssetID=0 and @AssetID=0)
	select @ParentAssetID=AssetID from acc_assets with(nolock) where parentid=0 and isgroup=1
       
 set @DtXML=@DetailXML      
      
  --GETTING PREFERENCE        
  SELECT @IsDuplicateNameAllowed=Value FROM COM_CostCenterPreferences WITH(nolock) WHERE COSTCENTERID=72 and  Name='DuplicateNameAllowed'        
  SELECT @IsAssetCodeAutoGen=IsEnable from COM_CostCenterCodeDef WITH(nolock) where CostCenterID=72 and IsGroupCode=@IsGroup and IsName=0  
  SELECT @IsIgnoreSpace=Value FROM COM_CostCenterPreferences  WITH(nolock) WHERE COSTCENTERID=72 and  Name='IgnoreSpaces'        
        
  --DUPLICATE CHECK        
  IF @IsDuplicateNameAllowed IS NOT NULL AND @IsDuplicateNameAllowed=0        
  BEGIN        
    IF @IsIgnoreSpace IS NOT NULL AND @IsIgnoreSpace=1        
   BEGIN        
    IF @AssetID=0        
    BEGIN        
     IF EXISTS (SELECT AssetID FROM ACC_Assets WITH(nolock) WHERE replace(AssetName,' ','')=replace(@AssetName,' ',''))        
     BEGIN        
      RAISERROR('-145',16,1)        
     END        
    END        
    ELSE        
    BEGIN   
  
     IF EXISTS (SELECT AssetID FROM ACC_Assets WITH(nolock) WHERE replace(AssetName,' ','')=replace(@AssetName,' ','') AND AssetID <> @AssetID)        
     BEGIN    
      RAISERROR('-145',16,1)             
     END        
    END        
   END        
   ELSE        
   BEGIN        
    IF @AssetID=0        
    BEGIN        
     IF EXISTS (SELECT AssetID FROM ACC_Assets WITH(nolock) WHERE AssetName=@AssetName)        
     BEGIN        
      RAISERROR('-145',16,1)        
     END        
    END        
    ELSE        
    BEGIN        
     IF EXISTS (SELECT AssetID FROM ACC_Assets WITH(nolock) WHERE AssetName=@AssetName AND AssetID <> @AssetID)        
     BEGIN        
      RAISERROR('-145',16,1)        
     END        
    END        
   END      
  END      
         
  
  SET @Dt=convert(float,getdate())--Setting Current Date        

  
 IF @AssetID = 0--------START INSERT RECORD-----------        
  BEGIN--CREATE Asset--        
     --To Set Left,Right And Depth of Record        
    SELECT @SelectedIsGroup=IsGroup,@Selectedlft =lft,@Selectedrgt=rgt,@ParentID=ParentID,@Depth=Depth        
    from ACC_Assets with(NOLOCK) where AssetId=@ParentAssetID        
            
    --IF No Record Selected or Record Doesn't Exist        
    if(@SelectedIsGroup is null)         
     select @SelectedIsGroup=IsGroup,@Selectedlft =lft,@Selectedrgt=rgt,@ParentID=ParentID,@Depth=Depth        
     from ACC_Assets with(NOLOCK) where ParentID =0        
                  
    if(@SelectedIsGroup = 1)--Adding Node Under the Group        
     BEGIN        
      UPDATE ACC_Assets SET rgt = rgt + 2 WHERE rgt > @Selectedlft;        
      UPDATE ACC_Assets SET lft = lft + 2 WHERE lft > @Selectedlft;        
      set @lft =  @Selectedlft + 1        
      set @rgt = @Selectedlft + 2        
      set @ParentID = @ParentAssetID        
      set @Depth = @Depth + 1        
     END        
    else if(@SelectedIsGroup = 0)--Adding Node at Same level        
     BEGIN        
      UPDATE ACC_Assets SET rgt = rgt + 2 WHERE rgt > @Selectedrgt;        
      UPDATE ACC_Assets SET lft = lft + 2 WHERE lft > @Selectedrgt;        
      set @lft =  @Selectedrgt + 1        
      set @rgt = @Selectedrgt + 2         
     END        
    else  --Adding Root        
     BEGIN        
      set @lft =  1        
      set @rgt = 2         
      set @Depth = 0        
      set @ParentID =0        
      set @IsGroup=1        
     END       
      
 --GENERATE CODE        
    IF @IsAssetCodeAutoGen IS NOT NULL AND @IsAssetCodeAutoGen=1 AND @AssetID=0 and @AssetCode=''
    BEGIN        
     SELECT @ParentCode=[AssetCode]  FROM ACC_Assets WITH(NOLOCK) WHERE AssetID=@ParentID          
        
     --CALL AUTOCODEGEN        
     EXEC [spCOM_SetCode] 72,@ParentCode,@AssetCode OUTPUT     
       -- select @AssetCode     
    END  
    
    IF @AssetCode IS NULL OR @AssetCode=''  
		SET @AssetCode=convert(nvarchar,IDENT_CURRENT('dbo.ACC_Assets')+1)
          
      if(@ParentAssetID =0 and @ParentID>0)
		set @ParentAssetID=@ParentID
      else if(@ParentID=0 and @ParentAssetID>0)
		set @ParentID=@ParentAssetID
      
     INSERT INTO ACC_Assets      
      (AssetCode      
      ,AssetName      
      ,StatusID      
      ,PurchaseValue      
      ,ParentAssetID      
      ,Description      
      ,SerialNo      
      ,DeprBookGroupID      
      ,ClassID      
      , LocationID      
      , EmployeeID       
      , PostingGroupID      
      , EstimateLife      
      , SalvageValueType       
      , SalvageValueName       
      , SalvageValue      
     -- , IsComponent      
      , PurchaseInvoiceNo      
      , SupplierAccountID      
     -- , AssetDepreciationJV   
    --  , AssetDisposalJV    
      , PurchaseDate      
      , DeprStartValue      
      , DeprStartDate      
      , DeprEndDate
      ,OriginalDeprStartDate
      , WarrantyNo      
      , WarrantyExpiryDate      
      , IsMainCovered      
      , MainVendorAccID       
      , NextServiceDate      
      , MaintStartDate      
      , MaintExpiryDate      
      , IsInsCovered      
      , InsVendorAccID      
      , InsPolicyNo      
      , InsType      
      , InsEffectiveDate       
      , InsExpiryDate      
      , InsPremium      
      , PolicyCoverage      
      --, InsNarration      
      , Period
      ,DepreciationMethod 
      ,AveragingMethod
      ,IsDeprSchedule
      ,PreviousDepreciation
      ,DeprBookID 
      ,PONo,PODate,GRNNo,GRNDate
      ,CapitalizationNo,CapitalizationDate,TotalQtyPurchase,UOM
      ,IncludeSalvageInDepr
      ,AcqnCostACCID,DeprExpenseACCID,AccumDeprACCID,AccumDeprDispACCID
      ,AcqnCostDispACCID,GainsDispACCID,LossDispACCID,MaintExpenseACCID
      ,CodePrefix,CodeNumber
      ,AssetNetValue
      ,IsGroup      
      ,Depth      
      ,ParentID      
      ,lft      
      ,rgt      
      ,CompanyGUID      
      ,GUID      
      ,CreatedBy      
      ,CreatedDate)      
      
     select @AssetCode      
      ,@AssetName      
      ,@StatusID      
      ,@PurchaseValue      
      ,@ParentAssetID      
      ,x.value('@Description','nvarchar(500)')      
      ,@Sno
      ,x.value('@deprBooks','nvarchar(50)')      
      ,x.value('@Class','INT')      
      ,x.value('@Location','INT')      
      ,x.value('@Employee','INT')      
      ,x.value('@PostingGroupID','INT')      
      ,x.value('@EstimateLife','nvarchar(50)')      
      ,x.value('@SalvageValueType','INT')      
      ,x.value('@SalvageValueName','nvarchar(50)')      
      ,x.value('@SalvageValue','nvarchar(50)')      
     -- ,x.value('@Component','INT')      
      ,x.value('@PurchaseInvoiceNo','nvarchar(50)')      
      ,CASE x.value('@SupplierAccountID','BIGINT') WHEN 0 THEN 1 ELSE x.value('@SupplierAccountID','BIGINT') END 
     -- ,x.value('@AssetDepreciationJV','INT')    
     -- ,x.value('@AssetDisposalJV','INT')      
      ,convert(float,x.value('@PurchaseDate','DateTime'))      
      ,isnull(x.value('@DeprStartValue','float'),0)
      ,convert(float,x.value('@DeprStartDate','DateTime'))      
      ,convert(float,x.value('@DeprEndDate','DateTime'))      
      ,convert(float,x.value('@OriginalDeprStartDate','DateTime'))
      ,x.value('@WarrantyNo','nvarchar(50)')      
      ,convert(float,x.value('@WarrantyExpiryDate','DateTime'))      
      ,x.value('@IsMainCovered','INT')      
      ,x.value('@MainVendorAccID','BIGINT')      
      ,convert(float,x.value('@NextServiceDate','DateTime'))      
      ,convert(float,x.value('@MaintStartDate','DateTime'))      
      ,convert(float,x.value('@MaintExpiryDate','DateTime'))      
      ,x.value('@IsInsCovered','INT')      
      ,x.value('@InsVendorAccID','BIGINT')      
     ,x.value('@InsPolicyNo','nvarchar(50)')      
      ,x.value('@InsType','nvarchar(50)')      
      ,convert(float,x.value('@InsEffectiveDate','DateTime'))      
      ,convert(float,x.value('@InsExpiryDate','DateTime'))      
      ,x.value('@InsPremium','nvarchar(50)')      
      ,x.value('@PolicyCoverage','nvarchar(50)')      
     -- ,x.value('@Narration','nvarchar(50)')      
      ,x.value('@Period','INT')          
      ,x.value('@DepreciationMethod','bigint')
      ,x.value('@AveragingMethod','bigint')        
      ,x.value('@IsDeprSchedule','int')          
      ,x.value('@PreviousDepreciation','Float')  
      ,isnull(x.value('@DeprBookID','bigint'),0)
      ,x.value('@PONo','nvarchar(50)'),convert(float,x.value('@PODate','DateTime')),x.value('@GRNNo','nvarchar(50)'),convert(float,x.value('@GRNDate','DateTime'))
      ,x.value('@CapitalizationNo','nvarchar(50)'),convert(float,x.value('@CapitalizationDate','DateTime')),x.value('@TotalQtyPurchase','float'),x.value('@UOM','bigint')
      ,isnull(x.value('@IncludeSalvageInDepr','bit'),0)
      ,x.value('@AcqnCostACCID','bigint'),x.value('@DeprExpenseACCID','bigint'),x.value('@AccumDeprACCID','bigint'),x.value('@AccumDeprDispACCID','bigint')
      ,x.value('@AcqnCostDispACCID','bigint'),x.value('@GainsDispACCID','bigint'),x.value('@LossDispACCID','bigint'),x.value('@MaintExpenseACCID','bigint')
      ,@CodePrefix,@CodeNumber
      ,isnull(x.value('@DeprStartValue','float'),0)
      , @IsGroup      
      ,@Depth      
      ,@ParentID      
      ,@lft      
      ,@rgt      
      ,@CompanyGUID      
      ,newid()      
      ,@CreatedBy      
      ,@Dt
   from @DtXML.nodes('/Row') as data(x)      
           
     SET @astID=SCOPE_IDENTITY()       
    
 --Handling of Extended Table        
    INSERT INTO ACC_AssetsExtended  ([AssetID],[CreatedBy],[CreatedDate])        
    VALUES(@astID, @CreatedBy, @Dt)       
      
       
    --Handling of CostCenter Costcenters Extrafields Table       
      
   INSERT INTO COM_CCCCDATA ([CostCenterID] ,[NodeID] ,[Guid],[CreatedBy],[CreatedDate])      
     VALUES(72,@astID,newid(),  @CreatedBy, @Dt)       
      
      
     IF (@AssetDepreciationXML IS NOT NULL AND @AssetDepreciationXML <> '')        
	 BEGIN
		  select @DeprStartValue=DeprStartValue from ACC_Assets with(nolock) where AssetID=@astID
		  SET @DepXML=@AssetDepreciationXML   
   		  INSERT INTO  [ACC_AssetDepSchedule]  
				   ([AssetID]  
				   ,[DeprStartDate]  
				   ,[DeprEndDate]  
				   ,[DepAmount]  
				   ,[AccDepreciation]  
				   ,[AssetNetValue]  
				   ,[PurchaseValue]  
				   ,[DocID]  
				   ,[VoucherNo]  
				   ,[DocDate]  
				   ,[StatusID]  
				   ,[CreatedBy]  
				   ,[CreatedDate]  
				   ,ActualDeprAmt
				   )  
		                
			SELECT @astID, convert(float,X.value('@From','datetime')) ,convert(float,X.value('@To','datetime')),X.value('@DepAmt','FLOAT'),
				 X.value('@AccDep','FLOAT'),X.value('@NetValue','FLOAT'),@DeprStartValue ,NULL,NULL,NULL,ISNULL(X.value('@StatusID','INT'), 0),
			@CreatedBy,@Dt,X.value('@ActDepAmt','FLOAT')
			FROM @DepXML.nodes('/XML/Row') as Data(X)    
		END  
	END --------END INSERT RECORD-----------        
	ELSE--UPDATE--      
	BEGIN--------START UPDATE RECORD----------      
		SELECT @TempGuid=[GUID] from ACC_Assets  WITH(NOLOCK)         
		WHERE AssetID=@AssetID      
                
		IF(@TempGuid!=@Guid)--IF RECORD ALREADY UPDATED BY SOME OTHER USER i.e DIRTY READ          
			RAISERROR('-101',16,1)         
	  
		update ACC_Assets set       
			AssetCode= @AssetCode      
			,AssetName=@AssetName      
			,StatusID=@StatusID      
			, PurchaseValue=@PurchaseValue      
			,ParentAssetID=@ParentAssetID      
			,IsGroup=@IsGroup      
		where AssetID=@AssetID      
	  
		if(@DetailXML is not null)      
		begin      
		   update ACC_Assets       
		   set      
			Description=x.value('@Description','nvarchar(max)')      
		   ,SerialNo=@Sno      
		   ,DeprBookGroupID=x.value('@deprBooks','nvarchar(50)')      
		   ,ClassID=x.value('@Class','INT')      
		   , LocationID=x.value('@Location','INT')      
		   , EmployeeID=x.value('@Employee','INT')      
		   , PostingGroupID=x.value('@PostingGroupID','INT')      
		   , EstimateLife=x.value('@EstimateLife','nvarchar(50)')      
		   , SalvageValueType=x.value('@SalvageValueType','INT')      
		   , SalvageValueName=x.value('@SalvageValueName','nvarchar(50)')      
		   , SalvageValue=x.value('@SalvageValue','nvarchar(50)') 
		   , PurchaseInvoiceNo=x.value('@PurchaseInvoiceNo','nvarchar(50)')      
		   , SupplierAccountID=x.value('@SupplierAccountID','INT')      
		   , PurchaseDate=convert(float,x.value('@PurchaseDate','DateTime'))      
		   , DeprStartValue=isnull(x.value('@DeprStartValue','float'),0)
		   , DeprStartDate=convert(float,x.value('@DeprStartDate','DateTime'))          
		   , DeprEndDate=convert(float,x.value('@DeprEndDate','DateTime')) 
		   ,OriginalDeprStartDate=convert(float,x.value('@OriginalDeprStartDate','DateTime')) 
		   , WarrantyNo= x.value('@WarrantyNo','nvarchar(50)')      
		   , WarrantyExpiryDate=convert(float,x.value('@WarrantyExpiryDate','DateTime'))        
		   , IsMainCovered=x.value('@IsMainCovered','INT')      
		   , MainVendorAccID= x.value('@MainVendorAccID','INT')      
		   , NextServiceDate=convert(float,x.value('@NextServiceDate','DateTime'))         
		   , MaintStartDate=convert(float,x.value('@MaintStartDate','DateTime'))          
		   , MaintExpiryDate=convert(float,x.value('@MaintExpiryDate','DateTime'))         
		   , IsInsCovered=x.value('@IsInsCovered','INT')      
		   , InsVendorAccID=x.value('@InsVendorAccID','INT')      
		   , InsPolicyNo= x.value('@InsPolicyNo','nvarchar(50)')      
		   , InsType=x.value('@InsType','nvarchar(50)')      
		   , InsEffectiveDate=convert(float,x.value('@InsEffectiveDate','DateTime'))         
		   , InsExpiryDate=convert(float,x.value('@InsExpiryDate','DateTime'))          
		   , InsPremium= x.value('@InsPremium','nvarchar(50)')      
		   , PolicyCoverage=x.value('@PolicyCoverage','nvarchar(50)') 
		   , Period=x.value('@Period','INT')   
		   , DepreciationMethod=x.value('@DepreciationMethod','BIGINT')      
		   , AveragingMethod=x.value('@AveragingMethod','INT')           
		   , IsDeprSchedule=x.value('@IsDeprSchedule','INT')             
		   , PreviousDepreciation=x.value('@PreviousDepreciation','Float')
		   ,DeprBookID=isnull(x.value('@DeprBookID','bigint'),0)
		   ,PONo=x.value('@PONo','nvarchar(50)'),PODate=convert(float,x.value('@PODate','DateTime')),GRNNo=x.value('@GRNNo','nvarchar(50)'),GRNDate=convert(float,x.value('@GRNDate','DateTime'))
		   ,CapitalizationNo=x.value('@CapitalizationNo','nvarchar(50)'),CapitalizationDate=convert(float,x.value('@CapitalizationDate','DateTime')),TotalQtyPurchase=x.value('@TotalQtyPurchase','float')
		   ,UOM=x.value('@UOM','bigint')
		   ,IncludeSalvageInDepr=isnull(x.value('@IncludeSalvageInDepr','bit'),0)
		   ,AcqnCostACCID=x.value('@AcqnCostACCID','bigint'),DeprExpenseACCID=x.value('@DeprExpenseACCID','bigint')
		   ,AccumDeprACCID=x.value('@AccumDeprACCID','bigint'),AccumDeprDispACCID=x.value('@AccumDeprDispACCID','bigint')
		   ,AcqnCostDispACCID=x.value('@AcqnCostDispACCID','bigint'),GainsDispACCID=x.value('@GainsDispACCID','bigint')
		   ,LossDispACCID=x.value('@LossDispACCID','bigint'),MaintExpenseACCID=x.value('@MaintExpenseACCID','bigint')
		   ,CodePrefix=@CodePrefix,CodeNumber=@CodeNumber
		   from @DtXML.nodes('/Row') as data(x)      
		   where AssetID=@AssetID      
		end      
		IF (@AssetDepreciationXML IS NOT NULL AND @AssetDepreciationXML <> '' AND NOT EXISTS(select ASSETID from ACC_AssetDepSchedule with(nolock) where ASSETID=@AssetID))        
		BEGIN
			select @DeprStartValue=DeprStartValue from ACC_Assets with(nolock) where AssetID=@AssetID
		
			SET @DepXML=@AssetDepreciationXML   
			DELETE  FROM [ACC_AssetDepSchedule] WHERE ASSETID = @AssetID AND DOCID IS NULL AND VOUCHERNO IS NULL AND STATUSID = 0 
			 
			INSERT INTO  [ACC_AssetDepSchedule]  
			   ([AssetID]  
			   ,[DeprStartDate]  
			   ,[DeprEndDate]  
			   ,[DepAmount]  
			   ,[AccDepreciation]  
			   ,[AssetNetValue]  
			   ,[PurchaseValue]  
			   ,[DocID]  
			   ,[VoucherNo]  
			   ,[DocDate]  
			   ,[StatusID]  
			   ,[CreatedBy]  
			   ,[CreatedDate]
			   ,ActualDeprAmt)  
			SELECT @AssetID, convert(float,X.value('@From','datetime')) ,convert(float,X.value('@To','datetime')) ,X.value('@DepAmt','FLOAT') ,   
				 X.value('@AccDep','FLOAT'),X.value('@NetValue','FLOAT'),@DeprStartValue ,NULL,NULL,NULL,ISNULL(X.value('@StatusID','INT'), 0),
			@CreatedBy,@Dt,X.value('@ActDepAmt','FLOAT')
			FROM @DepXML.nodes('/XML/Row') as Data(X)    
			
			 update ACC_Assets set IsDeprSchedule = 1 where AssetID=@AssetID 		   
		END 
		
		set @astID=@AssetID      
	END--------END UPDATE RECORD----------     
       
    set @UpdateSql='update ACC_AssetsExtended      
  SET '+@CustomFieldsQuery+' [ModifiedBy] ='''+ @CreatedBy      
    +''',[ModifiedDate] =' + convert(nvarchar,@Dt) +' WHERE AssetID = '+convert(nvarchar,@astID)     
  exec(@UpdateSql)              
           
    set @UpdateSql='update COM_CCCCDATA        
 SET '+@CustomCostCenterFieldsQuery+'[ModifiedBy] ='''+ @CreatedBy+''',[ModifiedDate] =' + convert(nvarchar,@Dt) +' WHERE NodeID = '+convert(nvarchar,@astID) + ' AND CostCenterID = 72'       
	exec(@UpdateSql)  
	      
  --Inserts Multiple Changes       
/*	IF (@ChangeValueXML IS NOT NULL AND @ChangeValueXML <> '')        
	BEGIN      
		SET @XML=@ChangeValueXML        
        
		if exists(select * from ACC_AssetChanges with(nolock) WHERE AssetID=@astID)    
		begin    
			DELETE FROM ACC_AssetChanges WHERE AssetID=@astID    
		end    
		--If Action is NEW then insert new Changes
	   INSERT INTO ACC_AssetChanges(AssetID,ChangeType,ChangeName,StatusID,ChangeDate,        
	   AssetOldValue,ChangeValue,AssetNewValue,        
	   LocationID,GUID,CreatedBy,CreatedDate)        
	   SELECT @astID,X.value('@ChangeType','int'),X.value('@ChangeName','NVARCHAR(50)'),        
	   X.value('@StatusID','bigint'),convert(float,X.value('@ChangeDate','datetime')),X.value('@AssetOldValue','Float'),        
	   X.value('@ChangeValue','nvarchar(50)'),X.value('@AssetNewValue','Float'),X.value('@LocationID','bigint'),        
	   newid(),@CreatedBy,@Dt        
	   FROM @XML.nodes('/ChangeValueXML/Row') as Data(X)       
  END  */

	IF (@HistoryXML IS NOT NULL AND @HistoryXML <> '')    
		EXEC spCOM_SetHistory 72,@astID,@HistoryXML,@CreatedBy  

 -- IF (@HistoryXML IS NOT NULL AND @HistoryXML <> '')        
 -- BEGIN     
  
 -- set @XML=@HistoryXML
 --   if exists(select * from ACC_AssetsHistory WHERE AssetManagementID=@astID)    
 --   begin    
	-- DELETE FROM ACC_AssetsHistory        
	-- WHERE AssetManagementID=@astID    
	--end  
	  
 --  --If Action is NEW then insert new Changes      
          
 --  INSERT INTO ACC_AssetsHistory(HistoryTypeID,AssetManagementID,[Date],Vender,VendorID,NextServiceDate,Remarks,Amount,DebitAccount,CreditAccount,PostJV,DocID,VoucherNo,GUID,CreatedBy,CreatedDate,CostCenterID,DocumentName,DocPrefix,DocNumber)        
 --  SELECT X.value('@HistoryType','bigint'),@astID,convert(float,X.value('@Date','datetime')) ,X.value('@Vendor','NVARCHAR(50)'),X.value('@VendorID','bigint'),     
 --  convert(float,X.value('@NextStartDate','datetime')),X.value('@Remarks','NVARCHAR(500)') ,X.value('@Amount','Float'),        
 --  X.value('@DebitAccount','bigint'),X.value('@CreditAccount','bigint'),X.value('@PostJV','bigint'), X.value('@DocID','bigint'),   X.value('@VoucherNo','NVARCHAR(50)'),          
 --  newid(),@CreatedBy,@Dt, X.value('@CostCenterID','bigint'), X.value('@DocumentName','nvarchar(50)') , X.value('@DocPrefix','nvarchar(50)'), X.value('@DocNumber','nvarchar(50)')       
 --  FROM @XML.nodes('/XML/MaintenanceGrid/Rows') as Data(X)
   
        
 --  INSERT INTO ACC_AssetsHistory(HistoryTypeID,AssetManagementID,Vender,VendorID,PolicyType,PolicyNumber,StartDate,EndDate,Coverage,GUID,CreatedBy,CreatedDate)        
 --  SELECT X.value('@HistoryType','bigint'),@astID,X.value('@Vendor','NVARCHAR(50)'),X.value('@VendorID','bigint'),     
 --  X.value('@PolicyType','bigint'),X.value('@PolicyNumber','NVARCHAR(50)'),convert(float,X.value('@StartDate','datetime')),
 --  convert(float,X.value('@EndDate','datetime')),X.value('@Coverage','NVARCHAR(50)'),        
 --  newid(),@CreatedBy,@Dt        
 --  FROM @XML.nodes('/XML/InsuranceGrid/Rows') as Data(X)   
   
 --  INSERT INTO ACC_AssetsHistory(HistoryTypeID,AssetManagementID,[Date],Amount,CurrentValue,Remarks,PostJV,DebitAccount,CreditAccount,GainAccount,LossAccount,DocID,VoucherNo,GUID,CreatedBy,CreatedDate,CostCenterID,DocumentName,DocPrefix,DocNumber)        
 --  SELECT X.value('@HistoryType','bigint'),@astID,convert(float,X.value('@Date','datetime')),X.value('@Amount','Float'),X.value('@CurrentValue','Float'),   
 --  X.value('@Remarks','NVARCHAR(500)'),X.value('@PostJV','bigint'), X.value('@DebitAccount','bigint'),X.value('@CreditAccount','bigint'),
 --   X.value('@GainAccount','bigint'),X.value('@LossAccount','bigint'), X.value('@DocID','bigint'),   X.value('@VoucherNo','NVARCHAR(50)'),newid(),@CreatedBy,@Dt, X.value('@CostCenterID','bigint'), X.value('@DocumentName','nvarchar(50)') , X.value('@DocPrefix','nvarchar(50)'), X.value('@DocNumber','nvarchar(50)')        
 --  FROM @XML.nodes('/XML/DisposeGrid/Rows') as Data(X)   
      
   
 -- END    
  
  --Inserts Multiple Notes  
  IF (@NotesXML IS NOT NULL AND @NotesXML <> '')  
  BEGIN  
   SET @XML=@NotesXML  
  
   --If Action is NEW then insert new Notes  
   INSERT INTO COM_Notes(FeatureID,CostCenterID,FeaturePK,Note,     
   GUID,CreatedBy,CreatedDate)  
   SELECT 72,72,@astID,Replace(X.value('@Note','NVARCHAR(MAX)'),'@~',''),  
   newid(),@CreatedBy,@Dt  
   FROM @XML.nodes('/NotesXML/Row') as Data(X)  
   WHERE X.value('@Action','NVARCHAR(10)')='NEW'  
  
   --If Action is MODIFY then update Notes  
   UPDATE COM_Notes  
   SET Note=Replace(X.value('@Note','NVARCHAR(MAX)'),'@~',''),  
    GUID=newid(),  
    ModifiedBy=@CreatedBy,  
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
  
  --Inserts Multiple Attachments  
  IF (@AttachmentsXML IS NOT NULL AND @AttachmentsXML <> '')  
  BEGIN  
   SET @XML=@AttachmentsXML  
  
   INSERT INTO COM_Files(FilePath,ActualFileName,RelativeFileName,
   FileExtension,FileDescription,IsProductImage,FeatureID,CostCenterID,FeaturePK,  
   GUID,CreatedBy,CreatedDate)  
   SELECT X.value('@FilePath','NVARCHAR(500)'),X.value('@ActualFileName','NVARCHAR(50)'),X.value('@RelativeFileName','NVARCHAR(50)'),  
   X.value('@FileExtension','NVARCHAR(50)'),X.value('@FileDescription','NVARCHAR(500)'),X.value('@IsProductImage','bit'),72,72,@astID,  
   X.value('@GUID','NVARCHAR(50)'),@CreatedBy,@Dt  
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
    GUID=X.value('@GUID','NVARCHAR(50)'),  
    ModifiedBy=@CreatedBy,  
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


	SELECT @AssetCCID=Convert(bigint,isnull(Value,0)) FROM COM_CostCenterPreferences  WITH(nolock) 
	WHERE COSTCENTERID=72 and  Name='AssetDimension'      
	if(@AssetCCID>50000)
	begin
		declare @CCStatusID bigint
		select top 1 @CCStatusID=statusid from com_status with(nolock) where costcenterid=@AssetCCID
	
		declare @NID bigint, @CCIDBom bigint
		select @NID = CCNodeID, @CCIDBom=CCID  from ACC_Assets with(nolock) where AssetID=@astID
		iF(@CCIDBom<>@AssetCCID)
		BEGIN
			if(@NID>0)
			begin 
			Update ACC_Assets set CCID=0, CCNodeID=0 where AssetID=@astID
			DECLARE @RET INT
				EXEC @RET = [dbo].[spCOM_DeleteCostCenter]
					@CostCenterID = @CCIDBom,
					@NodeID = @NID,
					@RoleID=1,
					@UserID = 1,
					@LangID = @LangID
			end	
			set @NID=0
			set @CCIDBom=0 
		END
		
		DECLARE @RefSelectedNodeID BIGINT
		SELECT @RefSelectedNodeID=RefDimensionNodeID FROM COM_DocBridge WITH(NOLOCK)
		WHERE CostCenterID=72 AND RefDimensionID=@AssetCCID AND NodeID=@ParentID 
		SET @RefSelectedNodeID=ISNULL(@RefSelectedNodeID,1)
				
		declare @return_value int
		if(@NID is null or @NID =0)
		begin 
			set @AssetCode = replace(@AssetCode,'''','''''') 
			set @AssetName = replace(@AssetName,'''','''''')   
			EXEC @return_value = [dbo].[spCOM_SetCostCenter]
			@NodeID = 0,@SelectedNodeID = @RefSelectedNodeID,@IsGroup = @IsGroup,
			@Code = @AssetCode,
			@Name = @AssetName,
			@AliasName=@AssetName,
			@PurchaseAccount=0,@SalesAccount=0,@StatusID=@CCStatusID,
			@CustomFieldsQuery=NULL,@AddressXML='',@AttachmentsXML=NULL,
			@CustomCostCenterFieldsQuery=NULL,@ContactsXML=null,@NotesXML=NULL,
			@CostCenterID = @AssetCCID,@CompanyGUID=@COMPANYGUID,@GUID='',@UserName='admin',@RoleID=1,@UserID=1 , @CheckLink = 0

			 -- Link Dimension Mapping
			INSERT INTO COM_DocBridge (CostCenterID, NodeID,InvDocID, AccDocID, RefDimensionID,RefDimensionNodeID,CompanyGUID, guid, Createdby, CreatedDate,Abbreviation)
			values(72, @astID,0,0,@AssetCCID,@return_value,'',newid(),@CreatedBy, @dt,'Asset') 
 		end
		else
		begin
			declare @Gid nvarchar(50) , @Table nvarchar(100), @CGid nvarchar(50)
			declare @NodeidXML nvarchar(max) 
			select @Table=Tablename from adm_features with(nolock) where featureid=@AssetCCID
			declare @str nvarchar(max) 
			set @str='@Gid nvarchar(50) output' 
			set @NodeidXML='set @Gid= (select GUID from '+convert(nvarchar,@Table)+' with(nolock) where NodeID='+convert(nvarchar,@NID)+')'
			exec sp_executesql @NodeidXML, @str, @Gid OUTPUT 
		  
			--select	@AssetName,@NID
			set @AssetCode = replace(@AssetCode,'''','''''') 
			set @AssetName = replace(@AssetName,'''','''''')   
			select @CCStatusID
			EXEC @return_value = [dbo].[spCOM_SetCostCenter]
			@NodeID = @NID,@SelectedNodeID = @RefSelectedNodeID,@IsGroup = @IsGroup,
			@Code = @AssetCode,
			@Name = @AssetName, 
			@AliasName=@AssetName,
			@PurchaseAccount=0,@SalesAccount=0,@StatusID=@CCStatusID,
			@CustomFieldsQuery=NULL,@AddressXML=null,@AttachmentsXML=NULL,
			@CustomCostCenterFieldsQuery=NULL,@ContactsXML=null,@NotesXML=NULL,
			@CostCenterID = @AssetCCID,@CompanyGUID=@CompanyGUID,@GUID=@Gid,@UserName='admin',@RoleID=1,@UserID=1, @CheckLink = 0 
 		end 
 		
 		--UPDATE LINK DATA
		if(@return_value>0 and @return_value<>'')
		begin
			Update ACC_Assets set CCID=@AssetCCID, CCNodeID=@return_value where AssetID=@astID
			DECLARE @CCMapSql nvarchar(max)
			set @CCMapSql='update COM_CCCCDATA  
			SET CCNID'+convert(nvarchar,(@AssetCCID-50000))+'='+CONVERT(NVARCHAR,@return_value)+'  WHERE NodeID = '+convert(nvarchar,@astID) + ' AND CostCenterID = 72' 
			EXEC (@CCMapSql)
		
			Exec [spDOC_SetLinkDimension]
				@InvDocDetailsID=@astID, 
				@Costcenterid=72,         
				@DimCCID=@AssetCCID,
				@DimNodeID=@return_value,
				@UserID=@UserID,    
				@LangID=@LangID  
		end 
		
	end
  
COMMIT TRANSACTION 
--ROLLBACK TRANSACTION         
SET NOCOUNT OFF;       
SELECT ErrorMessage,ErrorNumber FROM COM_ErrorMessages WITH(nolock)       
WHERE ErrorNumber=100 AND LanguageID=1        
RETURN @astID      
END TRY        
BEGIN CATCH        
 IF ERROR_NUMBER()=50000      
 BEGIN          
  SELECT ErrorMessage,ErrorNumber FROM COM_ErrorMessages WITH(NOLOCK) WHERE ErrorNumber=ERROR_MESSAGE() AND LanguageID=1      
 END      
 ELSE      
 BEGIN      
  SELECT ErrorMessage, ERROR_MESSAGE() AS ServerMessage,ERROR_NUMBER() AS ErrorNumber, ERROR_PROCEDURE()AS ProcedureName, ERROR_LINE() AS ErrorLine      
  FROM COM_ErrorMessages WITH(NOLOCK) WHERE ErrorNumber=-999 AND LanguageID=1      
 END      
 ROLLBACK TRANSACTION      
 SET NOCOUNT OFF        
 RETURN -999         
END CATCH
GO

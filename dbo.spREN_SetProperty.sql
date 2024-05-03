USE PACT2C222
GO
SET ANSI_NULLS, QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spREN_setProperty]
	@PropertyID [bigint] = 0,
	@Code [nvarchar](50),
	@Name [nvarchar](50),
	@Status [int],
	@IsGroup [bit],
	@SelectedNodeID [bigint],
	@DetailsXML [nvarchar](max) = null,
	@DepositXML [nvarchar](max) = null,
	@UnitXML [nvarchar](max) = null,
	@ParkingXML [nvarchar](max) = null,
	@CustomFieldsQuery [nvarchar](max) = null,
	@CustomCostCenterFieldsQuery [nvarchar](max) = null,
	@RoleXml [nvarchar](max) = null,
	@AttachmentsXML [nvarchar](max) = null,
	@ShareHolderXML [nvarchar](max) = null,
	@CompanyGUID [nvarchar](50),
	@GUID [nvarchar](50),
	@UserName [nvarchar](50),
	@UserID [int] = 0,
	@LangId [int] = 1,
	@RoleID [int] = 1
WITH ENCRYPTION, EXECUTE AS CALLER
AS
SET NOCOUNT ON     
BEGIN TRANSACTION    
BEGIN TRY    
      
	DECLARE @UpdateSql nvarchar(max),@Dt FLOAT, @lft bigint,@rgt bigint,@TempGuid nvarchar(50),@Selectedlft bigint,@Selectedrgt bigint,
	@HasAccess bit,@IsDuplicateNameAllowed bit,@IsLeadCodeAutoGen bit  ,@IsIgnoreSpace bit,    
	@Depth int,@ParentID bigint,@SelectedIsGroup int , @XML XML,@DXML XML,@UXML XML,@PXML XML,@ParentCode nvarchar(200)    
	DECLARE @return_value int,@TEMPxml NVARCHAR(500),@PrefValue NVARCHAR(500),@Dimesion bigint,@CCStatusID bigint,@UpdateLandLord bit 
	DECLARE @RefSelectedNodeID BIGINT
	
	set @XML=@DetailsXML    
	set @DXML=@DepositXML    
	set @UXML=@UnitXML    
	set @PXML=@ParkingXML    

	--GETTING PREFERENCE      
	SELECT @IsDuplicateNameAllowed=Value FROM COM_CostCenterPreferences WITH(nolock) WHERE COSTCENTERID=92 and  Name='DuplicateNameAllowed'      
	SELECT @IsLeadCodeAutoGen=Value FROM COM_CostCenterPreferences  WITH(nolock) WHERE COSTCENTERID=92 and  Name='CodeAutoGen'      
	SELECT @IsIgnoreSpace=Value FROM COM_CostCenterPreferences  WITH(nolock) WHERE COSTCENTERID=92 and  Name='IgnoreSpaces'      
	select @PrefValue = Value from COM_CostCenterPreferences   WITH(nolock)  where CostCenterID=92 and  Name = 'LinkDocument' 
	select @UpdateLandLord = Value from COM_CostCenterPreferences   WITH(nolock)  where CostCenterID=92 and  Name = 'UpdateLandLord'    
	--DUPLICATE CHECK      
	IF @IsDuplicateNameAllowed IS NOT NULL AND @IsDuplicateNameAllowed=0      
	BEGIN      
		IF @IsIgnoreSpace IS NOT NULL AND @IsIgnoreSpace=1      
		BEGIN      
			IF @PropertyID=0      
			BEGIN      
				IF EXISTS (SELECT NodeID FROM REN_Property WITH(nolock) WHERE replace(Name,' ','')=replace(@Name,' ',''))      
				BEGIN      
					RAISERROR('-112',16,1)      
				END      
			END      
			ELSE      
			BEGIN      
				IF EXISTS (SELECT NodeID FROM REN_Property WITH(nolock) WHERE replace(Name,' ','')=replace(@Name,' ','') AND NodeID<>@PropertyID)      
				BEGIN      
					RAISERROR('-112',16,1)           
				END      
			END      
		END      
		ELSE      
		BEGIN      
			IF @PropertyID=0      
			BEGIN      
				IF EXISTS (SELECT NodeID FROM REN_Property WITH(nolock) WHERE Name=@Name)      
				BEGIN      
					RAISERROR('-112',16,1)      
				END      
			END      
			ELSE      
			BEGIN      
				IF EXISTS (SELECT NodeID FROM REN_Property WITH(nolock) WHERE Name=@Name AND NodeID<>@PropertyID)      
				BEGIN      
					RAISERROR('-112',16,1)      
				END      
			END      
		END    
	END       
    
	--User acces check FOR Attachments    
	IF (@AttachmentsXML IS NOT NULL AND @AttachmentsXML <> '')    
	BEGIN    
		SET @HasAccess=dbo.fnCOM_HasAccess(@RoleID,2,12)    

		IF @HasAccess=0    
		BEGIN    
			RAISERROR('-105',16,1)    
		END    
	END    
    
	SET @Dt=convert(float,getdate())--Setting Current Date     
     
	IF @PropertyID= 0--------START INSERT RECORD-----------      
	BEGIN--CREATE Property     
	  
		 --To Set Left,Right And Depth of Record      
		SELECT @SelectedIsGroup=IsGroup,@Selectedlft =lft,@Selectedrgt=rgt,@ParentID=ParentID,@Depth=Depth      
		from REN_Property with(NOLOCK) where NodeID=@SelectedNodeID      
	          
		--IF No Record Selected or Record Doesn't Exist      
		if(@SelectedIsGroup is null)       
			select @SelectedNodeID=NodeID,@SelectedIsGroup=IsGroup,@Selectedlft =lft,@Selectedrgt=rgt,@ParentID=ParentID,@Depth=Depth      
			from REN_Property with(NOLOCK) where ParentID =0      
	                
		if(@SelectedIsGroup = 1)--Adding Node Under the Group      
		BEGIN      
			UPDATE REN_Property SET rgt = rgt + 2 WHERE rgt > @Selectedlft;      
			UPDATE REN_Property SET lft = lft + 2 WHERE lft > @Selectedlft;      
			set @lft =  @Selectedlft + 1      
			set @rgt = @Selectedlft + 2      
			set @ParentID = @SelectedNodeID      
			set @Depth = @Depth + 1      
		END      
		else if(@SelectedIsGroup = 0)--Adding Node at Same level      
		BEGIN      
			UPDATE REN_Property SET rgt = rgt + 2 WHERE rgt > @Selectedrgt;      
			UPDATE REN_Property SET lft = lft + 2 WHERE lft > @Selectedrgt;     
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
		IF @IsLeadCodeAutoGen IS NOT NULL AND @IsLeadCodeAutoGen=1 AND @PropertyID=0      
		BEGIN      
			SELECT @ParentCode=[Code]      
			FROM REN_Property WITH(NOLOCK) WHERE NodeID=@ParentID        

			--CALL AUTOCODEGEN      
			EXEC [spCOM_SetCode] 92,@ParentCode,@Code OUTPUT        
		END      
   
		--select * from REN_Property    

		if(@PrefValue is not null and @PrefValue<>'')    
		begin    
		   
			set @Dimesion=0    
			begin try    
				select @Dimesion=convert(BIGINT,@PrefValue)    
			end try    
			begin catch    
				set @Dimesion=0    
			end catch    
			if(@Dimesion>0)    
			begin  
				SELECT @RefSelectedNodeID=RefDimensionNodeID FROM COM_DocBridge WITH(NOLOCK)
				WHERE CostCenterID=92 AND RefDimensionID=@Dimesion AND NodeID=@SelectedNodeID 
				SET @RefSelectedNodeID=ISNULL(@RefSelectedNodeID,@SelectedNodeID)
				
				select @CCStatusID = statusid from com_status WITH(nolock) where costcenterid=@Dimesion and status = 'Active'  
				EXEC @return_value = [dbo].[spCOM_SetCostCenter]  
				@NodeID = 0,@SelectedNodeID =@RefSelectedNodeID,@IsGroup = @IsGroup,  
				@Code = @Code,  
				@Name = @Name,  
				@AliasName=@Name,  
				@PurchaseAccount=0,@SalesAccount=0,@StatusID=@CCStatusID,  
				@CustomFieldsQuery=NULL,@AddressXML=NULL,@AttachmentsXML=NULL,  
				@CustomCostCenterFieldsQuery=NULL,@ContactsXML=NULL,@NotesXML=NULL,  
				@CostCenterID = @Dimesion,@CompanyGUID=@COMPANYGUID,@GUID='',@UserName='admin',
				@RoleID=1,@UserID=1,@CheckLink = 0  

			end    
		end     
   
		insert into REN_Property(Code,Name,StatusID,PropertyTypeLookUpID,PlotArea,BuiltUpArea,LandLordLookUpID,Address1,Address2,    
		City,State,Zip,Country,BondNo,BondDate,BondTypeLookUpID,PropertyNo,PropertyPositionLookUpID,PropertyCategoryLookUpID,    
		Units,Parkings,Floors,RentalIncomeAccountID,ProvisionAccountID,RentalReceivableAccountID,PenaltyAccountID,AdvanceRentAccountID,BankAccount,BankLoanAccount
		,AdvanceReceivableAccountID,AdvReceivableCloseAccID ,   
		RentalAccount,RentPayableAccount,AdvanceRentPaid, TermsConditions ,SalesmanID , AccountantID , LandlordID,LocationID,   TOWERTYPE,GPS, 
		Depth,ParentID,lft,rgt,IsGroup,CompanyGUID,GUID,CreatedBy,CreatedDate,ModifiedBy,ModifiedDate ,CCNodeID,CCID)    
		select @Code,@Name,@Status,    
		X.value('@Type','INT'),    
		X.value('@PlotArea','FLOAT'),    
		X.value('@BuildUpArea','FLOAT'),    
		X.value('@Owner','INT'),    
		X.value('@Address1','nvarchar(500)'),    
		X.value('@Address2','nvarchar(500)'),    
		X.value('@City','nvarchar(200)'),    
		X.value('@State','nvarchar(200)'),    
		X.value('@Zip','nvarchar(50)'),    
		X.value('@Country','nvarchar(200)'),    
		X.value('@BondNo','nvarchar(200)'),    
		convert(float,X.value('@BondDate','DateTime')),    
		X.value('@BondType','INT'),    
		X.value('@PropertyNo','nvarchar(200)'),    
		X.value('@PropertyPosition','INT'),    
		X.value('@PropertyCategory','INT'),    
		X.value('@Units','Float'),    
		X.value('@Parkings','Float'),    
		X.value('@Floors','Float'),    
		X.value('@RentalIncomeAcc','BIGINT'), 
		X.value('@ProvisionAccountID','BIGINT'), 
		X.value('@RentalReceivableAcc','BIGINT'),
		X.value('@PenaltyAcc','BIGINT'),    
		X.value('@AdvanceRentAcc','BIGINT'),    
		X.value('@BankAcc','BIGINT'),    
		X.value('@BankLoanAcc','BIGINT'),
		X.value('@AdvanceReceivableAcc','BIGINT'),
		X.value('@AdvReceivableCloseAcc','BIGINT'), 
		X.value('@RentAcc','BIGINT'),    
		X.value('@RentPayableAcc','BIGINT'),    
		X.value('@AdvanceRentPaid','BIGINT'),
		X.value('@TermsConditions','nvarchar(500)'),     
		isnull(X.value('@Salesman','BIGINT'),1),    
		isnull(X.value('@Accountant','BIGINT'),1),    
		isnull(X.value('@Landlord','BIGINT'),1),      
		isnull(X.value('@LocationID','BIGINT'),1)  , X.value('@TowerType','BIGINT')  , X.value('@GPS','nvarchar(200)')  ,
		@Depth,@SelectedNodeID,@lft,@rgt,@IsGroup,@CompanyGUID,newid(),@UserName,@Dt,@UserName,@Dt  , @return_value ,@Dimesion  
		from @XML.nodes('Row') as data(X)    
      
		set @PropertyID=scope_identity()    
 
		insert into REN_Particulars(ParticularID,PropertyID,UnitID,CreditAccountID,DebitAccountID,AdvanceAccountID,Refund,vat,InclChkGen ,VatType,TaxCategoryID,RecurInvoice,PostDebit ,
		DiscountPercentage,DiscountAmount,TypeID,ContractType,CompanyGUID,GUID,CreatedBy,CreatedDate,ModifiedBy,ModifiedDate)    
		 select  X.value('@Particulars','BIGINT'),    
		@PropertyID,0,        
		X.value('@CreditAccount','BIGINT'),    
		X.value('@DebitAccount','BIGINT'), X.value('@AdvanceAccountID','BIGINT'),   
		X.value('@Refund','INT'),X.value('@Vat','FLOAT'),X.value('@InclChkGen','INT'),
		X.value('@VatType','Nvarchar(50)'),X.value('@TaxCategoryID','BIGINT'),   X.value('@RecurInvoice','BIT'),X.value('@PostDebit','BIT'),
		X.value('@Percentage','FLOAT'),    
		X.value('@Amount','FLOAT'),X.value('@TypeID','INT'),X.value('@ContractType','INT') ,@CompanyGUID,newid(),@UserName,@Dt,@UserName,@Dt    
		from @DXML.nodes('/XML/Row') as data(X)    
    
		insert into REN_PropertyUnits(PropertyID,Type,Numbers,Rent,UnitTypeCCID,UnitTypeNodeID,TypeID,
		CompanyGUID,GUID,CreatedBy,CreatedDate,ModifiedBy,ModifiedDate)    
		select  @PropertyID,    
		X.value('@Type','nvarchar(200)'),    
		X.value('@Numbers','INT'),    
		X.value('@Rent','FLOAT'),0,0,        
		X.value('@TypeID','INT'),@CompanyGUID,newid(),@UserName,@Dt,@UserName,@Dt    
		from @UXML.nodes('/XML/Row') as data(X)    
    
		insert into REN_PropertyUnits(PropertyID,Type,Numbers,Rent,UnitTypeCCID,UnitTypeNodeID,TypeID,
		CompanyGUID,GUID,CreatedBy,CreatedDate,ModifiedBy,ModifiedDate)    
		select  @PropertyID,    
		X.value('@Type','nvarchar(200)'),    
		X.value('@Numbers','INT'),    
		X.value('@Rent','FLOAT'),0,0,        
		X.value('@TypeID','INT'),@CompanyGUID,newid(),@UserName,@Dt,@UserName,@Dt    
		from @PXML.nodes('/XML/Row') as data(X)    
  
		--Handling of Extended Table      
		INSERT INTO REN_PropertyExtended([NodeID],[CreatedBy],[CreatedDate])      
		VALUES(@PropertyID, @UserName, @Dt)      
   
		-- Link Dimension Mapping   
		INSERT INTO COM_CCCCDATA ([CostCenterID] ,[NodeID] ,[Guid],[CreatedBy],[CreatedDate])    
		VALUES(92,@PropertyID,newid(),  @UserName, @Dt)     

		INSERT INTO COM_DocBridge (CostCenterID, NodeID,InvDocID, AccDocID, RefDimensionID  , RefDimensionNodeID ,  
		CompanyGUID, guid, Createdby, CreatedDate,Abbreviation)  
		values(92, @PropertyID,0,0,@Dimesion,@return_value,'',newid(),@UserName, @dt,'Property')  
    
	END --------END INSERT RECORD-----------      
	ELSE  --------START UPDATE RECORD-----------      
	BEGIN    
  
		SELECT @TempGuid=[GUID] from REN_Property  WITH(NOLOCK)       
		WHERE NodeID=@PropertyID    

		IF(@TempGuid!=@Guid)--IF RECORD ALREADY UPDATED BY SOME OTHER USER i.e DIRTY READ        
		BEGIN        
			RAISERROR('-101',16,1)       
		END        
		ELSE        
		BEGIN    
			DELETE FROM  COM_CCCCDATA WHERE NodeID=@PropertyID AND  CostCenterID = 92    

			--Handling of CostCenter Costcenters Extrafields Table      


			INSERT INTO COM_CCCCDATA ([CostCenterID] ,[NodeID] ,[CompanyGUID],[Guid],[CreatedBy],[CreatedDate])    
			VALUES(92,@PropertyID, @CompanyGUID,newid(),  @UserName, @Dt)   
			       
			IF ( @UpdateLandLord IS NOT NULL AND @UpdateLandLord=1)  
			BEGIN      		     
				  UPDATE REN_Units SET LandlordID=X.value('@Landlord','BIGINT')
				  FROM @XML.nodes('Row') as data(X)
				  WHERE PropertyID=@PropertyID      
			END 
			    
			--UPDATE   
			Update REN_Property set  Code=@Code,Name=@Name,StatusID=@Status,    
			PropertyTypeLookUpID=X.value('@Type','INT'),    
			PlotArea=X.value('@PlotArea','FLOAT'),    
			BuiltUpArea=X.value('@BuildUpArea','FLOAT'),    
			LandLordLookUpID=X.value('@Owner','INT'),    
			Address1=X.value('@Address1','nvarchar(500)'),    
			Address2=X.value('@Address2','nvarchar(500)'),    
			City=X.value('@City','nvarchar(200)'),    
			State=X.value('@State','nvarchar(200)'),    
			Zip=X.value('@Zip','nvarchar(50)'),    
			Country=X.value('@Country','nvarchar(200)'),    
			BondNo=X.value('@BondNo','nvarchar(200)'),    
			BondDate=convert(float,X.value('@BondDate','DateTime')),    
			BondTypeLookUpID=X.value('@BondType','INT'),    
			PropertyNo=X.value('@PropertyNo','nvarchar(200)'),    
			PropertyPositionLookUpID=X.value('@PropertyPosition','INT'),    
			PropertyCategoryLookUpID=X.value('@PropertyCategory','INT'),    
			Units=X.value('@Units','Float'),    
			Parkings=X.value('@Parkings','Float'),    
			Floors=X.value('@Floors','Float'),    
			RentalIncomeAccountID=X.value('@RentalIncomeAcc','BIGINT'),   
			ProvisionAccountID= X.value('@ProvisionAccountID','BIGINT'),  
			RentalReceivableAccountID=X.value('@RentalReceivableAcc','BIGINT'),
			PenaltyAccountID=X.value('@PenaltyAcc','BIGINT'),        
			AdvanceRentAccountID=X.value('@AdvanceRentAcc','BIGINT'),    
			BankAccount=X.value('@BankAcc','BIGINT'),    
			BankLoanAccount=X.value('@BankLoanAcc','BIGINT'),
			AdvanceReceivableAccountID=X.value('@AdvanceReceivableAcc','BIGINT'),
			AdvReceivableCloseAccID=X.value('@AdvReceivableCloseAcc','BIGINT'),    
			RentalAccount=X.value('@RentAcc','BIGINT'),    
			RentPayableAccount=X.value('@RentPayableAcc','BIGINT'),    
			AdvanceRentPaid=X.value('@AdvanceRentPaid','BIGINT'),    
			TermsConditions=X.value('@TermsConditions','nvarchar(500)'),    
			SalesmanID=X.value('@Salesman','BIGINT'),    
			AccountantID=X.value('@Accountant','BIGINT'),    
			LandlordID=X.value('@Landlord','BIGINT'),    
			LocationID=X.value('@LocationID','BIGINT')    ,
			TowerType=X.value('@TowerType','BIGINT')  ,  
			GPS=X.value('@GPS','nvarchar(500)')    
			from @XML.nodes('Row') as data(X)     
			where NodeID=@PropertyID     
    
    
			delete from REN_Particulars where PropertyID=@PropertyID and UnitID=0    
			delete from REN_PropertyUnits where PropertyID=@PropertyID    


			insert into REN_Particulars(ParticularID,PropertyID,UnitID,CreditAccountID,DebitAccountID,AdvanceAccountID,Refund,DiscountPercentage,VAT,InclChkGen
			,VatType,TaxCategoryID,RecurInvoice,PostDebit,DiscountAmount,TypeID,ContractType ,CompanyGUID,GUID,CreatedBy,CreatedDate,ModifiedBy,ModifiedDate)    
			 select  X.value('@Particulars','BIGINT'),    
			@PropertyID,0,       
			X.value('@CreditAccount','BIGINT'),    
			X.value('@DebitAccount','BIGINT'),  X.value('@AdvanceAccountID','BIGINT')  , 
			X.value('@Refund','INT'),    
			X.value('@Percentage','FLOAT'),X.value('@Vat','FLOAT'),  X.value('@InclChkGen','INT'), 
			X.value('@VatType','Nvarchar(50)'),X.value('@TaxCategoryID','BIGINT'), X.value('@RecurInvoice','BIT'), X.value('@PostDebit','BIT'),
			X.value('@Amount','FLOAT'),X.value('@TypeID','INT'),X.value('@ContractType','INT'),@CompanyGUID,newid(),@UserName,@Dt,@UserName,@Dt    
			from @DXML.nodes('/XML/Row') as data(X)    

			insert into REN_PropertyUnits(PropertyID,Type,Numbers,Rent,UnitTypeCCID,UnitTypeNodeID,TypeID,CompanyGUID
			,GUID,CreatedBy,CreatedDate,ModifiedBy,ModifiedDate)    
			select  @PropertyID,    
			X.value('@Type','nvarchar(200)'),    
			X.value('@Numbers','INT'),    
			X.value('@Rent','FLOAT'),0,0,       
			X.value('@TypeID','INT'),@CompanyGUID,newid(),@UserName,@Dt,@UserName,@Dt    
			from @UXML.nodes('/XML/Row') as data(X)    
   
   
			if(@PrefValue is not null and @PrefValue<>'')    
			begin  
				set @Dimesion=0    
				begin try    
					select @Dimesion=convert(BIGINT,@PrefValue)    
				end try    
				begin catch    
					set @Dimesion=0     
				end catch    

				declare @NID bigint, @CCIDAcc bigint  

				select @NID = CCNodeID, @CCIDAcc=CCID  from Ren_Property WITH(nolock) where NodeID=@PropertyID   

				if(@Dimesion>0 and @NID is not null and @NID <>'' )  
				begin    
					declare @Gid nvarchar(50) , @Table nvarchar(100), @CGid nvarchar(50)  
					declare @NodeidXML nvarchar(max)   
					select @Table=Tablename from adm_features WITH(nolock) where featureid=@Dimesion  
					declare @str nvarchar(max)   
					set @str='@Gid nvarchar(50) output'   
					set @NodeidXML='set @Gid= (select GUID from '+convert(nvarchar,@Table)+' WITH(nolock) where NodeID='+convert(nvarchar,@NID)+')'  

					exec sp_executesql @NodeidXML, @str, @Gid OUTPUT   

					select @CCStatusID = statusid from com_status WITH(nolock) where costcenterid=@Dimesion and status = 'Active'  

					if(@Gid is null	 and @NID >0)
						set @NID=0
					
					SELECT @RefSelectedNodeID=RefDimensionNodeID FROM COM_DocBridge WITH(NOLOCK)
					WHERE CostCenterID=92 AND RefDimensionID=@Dimesion AND NodeID=@SelectedNodeID 
					SET @RefSelectedNodeID=ISNULL(@RefSelectedNodeID,@SelectedNodeID)
				
					EXEC @return_value = [dbo].[spCOM_SetCostCenter]  
					@NodeID = @NID,@SelectedNodeID = @RefSelectedNodeID,@IsGroup = @IsGroup,  
					@Code = @Code,  
					@Name = @Name,  
					@AliasName=@Name,  
					@PurchaseAccount=0,@SalesAccount=0,@StatusID=@CCStatusID,  
					@CustomFieldsQuery=NULL,@AddressXML=NULL,@AttachmentsXML='',  
					@CustomCostCenterFieldsQuery=NULL,@ContactsXML=null,@NotesXML=NULL,  
					@CostCenterID = @Dimesion,@CompanyGUID=@CompanyGUID,@GUID=@Gid,@UserName='admin',@RoleID=1,@UserID=1 , @CheckLink = 0   
					  
					Update REN_PROPERTY set CCID=@Dimesion, CCNodeID=@return_value where NodeID=@PropertyID        
				END  
			END   
		END    
		--  DELETE FROM REN_Particulars WHERE PropertyID = @PropertyID  
		--insert into REN_Particulars(ParticularID,PropertyID,UnitID,CreditAccountID,DebitAccountID,Refund,DiscountPercentage,DiscountAmount,TypeID,ContractType ,
		--CompanyGUID,GUID,CreatedBy,CreatedDate,ModifiedBy,ModifiedDate)    
		--    select  X.value('@Particulars','BIGINT'),    
		--   @PropertyID,0,    
		--   -- X.value('@UnitID','BIGINT'),    
		--   X.value('@CreditAccount','BIGINT'),    
		--   X.value('@DebitAccount','BIGINT'),    
		--   X.value('@Refund','INT'),    
		--   X.value('@Percentage','FLOAT'),    
		--   X.value('@Amount','FLOAT'),X.value('@TypeID','INT'),X.value('@ContractType','INT') ,@CompanyGUID,newid(),@UserName,@Dt,@UserName,@Dt    
		--  from @DXML.nodes('/XML/Row') as data(X)    

		DELETE FROM REN_PropertyUnits WHERE PropertyID = @PropertyID 

		insert into REN_PropertyUnits(PropertyID,Type,Numbers,Rent,UnitTypeCCID,UnitTypeNodeID,TypeID
		,CompanyGUID,GUID,CreatedBy,CreatedDate,ModifiedBy,ModifiedDate)    
		select  @PropertyID,    
		X.value('@Type','nvarchar(200)'),    
		X.value('@Numbers','INT'),    
		X.value('@Rent','FLOAT'),0,0,    
		--X.value('@UnitTypeCCID','INT')    
		--X.value('@UnitTypeNodeID','INT')    
		X.value('@TypeID','INT'),@CompanyGUID,newid(),@UserName,@Dt,@UserName,@Dt    
		from @UXML.nodes('/XML/Row') as data(X)    

		insert into REN_PropertyUnits(PropertyID,Type,Numbers,Rent,UnitTypeCCID,UnitTypeNodeID,TypeID
		,CompanyGUID,GUID,CreatedBy,CreatedDate,ModifiedBy,ModifiedDate)    
		select  @PropertyID,    
		X.value('@Type','nvarchar(200)'),    
		X.value('@Numbers','INT'),    
		X.value('@Rent','FLOAT'),0,0,    
		--X.value('@UnitTypeCCID','INT')    
		--X.value('@UnitTypeNodeID','INT')    
		X.value('@TypeID','INT'),@CompanyGUID,newid(),@UserName,@Dt,@UserName,@Dt    
		from @PXML.nodes('/XML/Row') as data(X)    
	END     
        
         
	IF(@CustomFieldsQuery IS NOT NULL AND @CustomFieldsQuery <>'')    
	BEGIN    
		set @UpdateSql='update [REN_PropertyExtended]    
		SET '+@CustomFieldsQuery+' [ModifiedBy] ='''+ @UserName    
		+''',[ModifiedDate] =' + convert(nvarchar,@Dt) +' WHERE NodeID='+convert(nvarchar,@PropertyID)    
		select @UpdateSql    
		exec(@UpdateSql)    
	END    
         
	IF(@CustomCostCenterFieldsQuery IS NOT NULL AND @CustomCostCenterFieldsQuery <>'')    
	BEGIN  
		set @UpdateSql='update COM_CCCCDATA      
		SET '+@CustomCostCenterFieldsQuery+'[ModifiedBy] ='''+ @UserName+''',[ModifiedDate] =' + convert(nvarchar,@Dt) +' WHERE NodeID =      
		'+convert(nvarchar,@PropertyID) + ' AND CostCenterID = 92'     
		exec(@UpdateSql)      
	END 
	   
	IF (@RoleXml IS NOT NULL AND @RoleXml ='<XML></XML>')  
	BEGIN  
		INSERT INTO [ADM_PropertyUserRoleMap](    
		[PropertyID]    
		,UserID,RoleID,LocationID    
		,[CompanyGUID]    
		,[GUID]    
		,[CreatedBy]    
		,[CreatedDate])    
		 SELECT  @PropertyID ,@UserID ,@RoleID ,(SELECT LocationID FROM REN_Property WITH(NOLOCK) WHERE NodeID=@PropertyID) ,@CompanyGUID,NEWID(),@UserName,CONVERT(FLOAT,GETDATE())    
	END 
	ELSE IF(@RoleXml IS NOT NULL AND @RoleXml <>'')    
	BEGIN    
		DELETE from [ADM_PropertyUserRoleMap] where [PropertyID]=@PropertyID    
		    
		SET @XML=@RoleXml    

		INSERT INTO [ADM_PropertyUserRoleMap](    
		[PropertyID]    
		,UserID,RoleID,LocationID    
		,[CompanyGUID]    
		,[GUID]    
		,[CreatedBy]    
		,[CreatedDate])    
		SELECT  @PropertyID , X.value('@UserID','BIGINT'),X.value('@RoleID','BIGINT')
		,X.value('@LocationID','BIGINT')    
		,@CompanyGUID,NEWID(),@UserName,CONVERT(FLOAT,GETDATE())    
		from @XML.nodes('/XML/Row') as Data(X)   
	END    

    --Inserts Multiple Attachments    
	IF (@AttachmentsXML IS NOT NULL AND @AttachmentsXML <> '')    
	BEGIN    
		SET @XML=@AttachmentsXML    

		INSERT INTO COM_Files(FilePath,ActualFileName,RelativeFileName,  
		FileExtension,FileDescription,IsProductImage,FeatureID,CostCenterID,FeaturePK,    
		GUID,CreatedBy,CreatedDate)    
		SELECT X.value('@FilePath','NVARCHAR(500)'),X.value('@ActualFileName','NVARCHAR(50)'),X.value('@RelativeFileName','NVARCHAR(50)'),    
		X.value('@FileExtension','NVARCHAR(50)'),X.value('@FileDescription','NVARCHAR(500)'),X.value('@IsProductImage','bit'),92,92,@PropertyID,    
		X.value('@GUID','NVARCHAR(50)'),@UserName,@Dt    
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
   
    --Inserts Property Share holder
	IF (@ShareHolderXML IS NOT NULL AND @ShareHolderXML <> '')    
	BEGIN    
		SET @XML=@ShareHolderXML    
		delete from [REN_PropertyShareHolder] where PropertyID=@PropertyID

		INSERT INTO [REN_PropertyShareHolder]
		([PropertyID],[Account],[Income],[Expenses],[OpIncome],[OpExpenses],[CompanyGUID],[GUID],[CreatedBy],[CreatedDate])
		SELECT  @PropertyID,  X.value('@Account','NVARCHAR(500)'),X.value('@Income','float'),X.value('@Expenses','float'),    
		X.value('@OpIncome','float'),X.value('@OpExpenses','float'),'', NEWID(),@UserName,@Dt    
		FROM @XML.nodes('/XML/Row') as Data(X)      
	END 
	
	--UPDATE LINK DATA
	if(@return_value>0 and @return_value<>'')
	begin
		set @UpdateSql='update COM_CCCCDATA    
		SET CCNID'+convert(nvarchar,(@Dimesion-50000))+'='+CONVERT(NVARCHAR,@return_value)+'  WHERE NodeID = '+
		convert(nvarchar,@PropertyID) + ' AND CostCenterID = 92'   
		EXEC (@UpdateSql)  
		
		Exec [spDOC_SetLinkDimension]
			@InvDocDetailsID=@PropertyID, 
			@Costcenterid=92,         
			@DimCCID=@Dimesion,
			@DimNodeID=@return_value,
			@UserID=@UserID,    
			@LangID=@LangID  
	end   
   
 
COMMIT TRANSACTION    
SELECT ErrorMessage,ErrorNumber FROM COM_ErrorMessages WITH(nolock)       
WHERE ErrorNumber=100 AND LanguageID=@LangID      
SET NOCOUNT OFF;        
RETURN @PropertyID    
END TRY        
BEGIN CATCH        
	--Return exception info [Message,Number,ProcedureName,LineNumber]        
	IF ERROR_NUMBER()=50000      
	BEGIN      
		SELECT ErrorMessage,ErrorNumber FROM COM_ErrorMessages WITH(nolock)       
		WHERE ErrorNumber=ERROR_MESSAGE() AND LanguageID=@LangID      
	END      
	ELSE IF ERROR_NUMBER()=547      
	BEGIN      
		SELECT ErrorMessage, ERROR_MESSAGE() AS ServerMessage,ERROR_NUMBER() as ErrorNumber, ERROR_PROCEDURE()as ProcedureName, ERROR_LINE() AS ErrorLine 
		FROM COM_ErrorMessages WITH(nolock)      
		WHERE ErrorNumber=-110 AND LanguageID=@LangID      
	END      
	ELSE IF ERROR_NUMBER()=2627      
	BEGIN      
		SELECT ErrorMessage, ERROR_MESSAGE() AS ServerMessage,ERROR_NUMBER() as ErrorNumber, ERROR_PROCEDURE()as ProcedureName, ERROR_LINE() AS ErrorLine 
		FROM COM_ErrorMessages WITH(nolock)      
		WHERE ErrorNumber=-116 AND LanguageID=@LangID      
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

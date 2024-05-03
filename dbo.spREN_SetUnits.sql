USE PACT2C222
GO
SET ANSI_NULLS, QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spREN_SetUnits]
	@UNITID [bigint] = 0,
	@PROPERTYID [bigint] = 0,
	@CODE [nvarchar](max) = NULL,
	@NAME [nvarchar](max) = NULL,
	@STATUSID [bigint] = 0,
	@IsGroup [bit],
	@SelectedNodeID [bigint],
	@DETAILSXML [nvarchar](max) = NULL,
	@StaticFieldsQuery [nvarchar](max) = NULL,
	@CustomCostCenterFieldsQuery [nvarchar](max) = NULL,
	@CustomCCQuery [nvarchar](max) = NULL,
	@AttachmentsXML [nvarchar](max) = NULL,
	@UnitRateXML [nvarchar](max) = NULL,
	@HistoryXML [nvarchar](max) = NULL,
	@CompanyGUID [nvarchar](50),
	@GUID [nvarchar](50),
	@UserName [nvarchar](50),
	@WID [int] = 0,
	@RoleID [int] = 1,
	@UserID [int] = 0,
	@LangId [int] = 1
WITH ENCRYPTION, EXECUTE AS CALLER
AS
SET NOCOUNT ON     
BEGIN TRANSACTION    
BEGIN TRY  
   
    DECLARE @Dt FLOAT,@lft bigint,@rgt bigint,@TempGuid nvarchar(50),@Selectedlft bigint,@Selectedrgt bigint,@RefSelectedNodeID BIGINT,
    @HasAccess bit,@IsDuplicateNameAllowed bit,@IsLeadCodeAutoGen bit  ,@IsIgnoreSpace bit,@HistoryStatus nvarchar(50),
	@Depth int,@ParentID bigint,@CCID BIGINT,@DXML XML,@SelectedIsGroup int , @XML XML,@ParentCode nvarchar(MAX),@DetailContact int,    
	@LinkDim_NodeID int,@PrefValue NVARCHAR(500),@Dimesion bigint ,@CCStatusID bigint ,@DimensionPrefValue bigint 
  
	set @DXML=@DETAILSXML    
      
	--User access check     
	SET @HasAccess=dbo.fnCOM_HasAccess(@RoleID,93,1)    
	IF @HasAccess=0    
	BEGIN    
		RAISERROR('-105',16,1)    
	END    
    
    if(@UNITID=0)
		set @HistoryStatus='Add'
	else
		set @HistoryStatus='Update'
		
		
	--GETTING PREFERENCE      
	SELECT @IsLeadCodeAutoGen=Value FROM COM_CostCenterPreferences  WITH(nolock) WHERE COSTCENTERID=93 and  Name='CodeAutoGen'      
	SELECT @IsDuplicateNameAllowed=Value FROM COM_CostCenterPreferences WITH(nolock) WHERE COSTCENTERID=93 and  Name='DuplicateNameAllowed'      
	SELECT @IsIgnoreSpace=Value FROM COM_CostCenterPreferences WITH(nolock) WHERE COSTCENTERID=93 and  Name='IgnoreSpaces'      
	select @PrefValue = Value from COM_CostCenterPreferences WITH(nolock) where CostCenterID=93 and  Name = 'LinkDocument'  
	SELECT @CCID=Value FROM ADM_GlobalPreferences WITH(NOLOCK) WHERE Name='UnitLinkDimension' 
  
    --DUPLICATE CHECK      
	IF @IsDuplicateNameAllowed IS NOT NULL AND @IsDuplicateNameAllowed=0      
	BEGIN      
		IF @IsIgnoreSpace IS NOT NULL AND @IsIgnoreSpace=1      
		BEGIN      
			IF @UNITID=0      
			BEGIN      
				IF EXISTS (SELECT UnitID FROM REN_Units WITH(nolock) WHERE replace(Name,' ','')=replace(@Name,' ',''))      
				BEGIN      
					RAISERROR('-112',16,1)      
				END      
			END      
			ELSE      
			BEGIN      
				IF EXISTS (SELECT UnitID FROM REN_Units WITH(nolock) WHERE replace(Name,' ','')=replace(@Name,' ','') AND UnitID<>@UNITID)      
				BEGIN      
					RAISERROR('-112',16,1)           
				END      
			END      
		END      
		ELSE      
		BEGIN      
			IF @UNITID=0      
			BEGIN      
				IF EXISTS (SELECT UnitID FROM REN_Units WITH(nolock) WHERE Name=@Name)      
				BEGIN      
					RAISERROR('-112',16,1)      
				END      
			END      
			ELSE      
			BEGIN      
				IF EXISTS (SELECT UnitID FROM REN_Units WITH(nolock) WHERE Name=@Name AND UnitID<>@UNITID)      
				BEGIN      
					RAISERROR('-112',16,1)      
				END      
			END      
		END    
	END     
  
	--User acces check FOR Attachments  
	IF (@AttachmentsXML IS NOT NULL AND @AttachmentsXML <> '')  
	BEGIN  
		SET @HasAccess=dbo.fnCOM_HasAccess(@RoleID,93,12)  

		IF @HasAccess=0  
		BEGIN  
			RAISERROR('-105',16,1)  
		END  
	END      
  
	SET @Dt=convert(float,getdate())--Setting Current Date      

	IF @UNITID= 0--------START INSERT RECORD-----------      
	BEGIN--CREATE Case      
		 --To Set Left,Right And Depth of Record      
		SELECT @SelectedIsGroup=IsGroup,@Selectedlft =lft,@Selectedrgt=rgt,@ParentID=ParentID,@Depth=Depth      
		from REN_Units with(NOLOCK) where UnitID=@SelectedNodeID      
          
		--IF No Record Selected or Record Doesn't Exist      
		if(@SelectedIsGroup is null)       
			select @SelectedNodeID=UnitID,@SelectedIsGroup=IsGroup,@Selectedlft =lft,@Selectedrgt=rgt,@ParentID=ParentID,@Depth=Depth      
			from REN_Units with(NOLOCK) where ParentID =0      
                
		if(@SelectedIsGroup = 1)--Adding Node Under the Group      
		BEGIN      
			UPDATE REN_Units SET rgt = rgt + 2 WHERE rgt > @Selectedlft;      
			UPDATE REN_Units SET lft = lft + 2 WHERE lft > @Selectedlft;      
			set @lft = @Selectedlft + 1      
			set @rgt = @Selectedlft + 2      
			set @ParentID = @SelectedNodeID      
			set @Depth = @Depth + 1      
		END      
		else if(@SelectedIsGroup = 0)--Adding Node at Same level      
		BEGIN      
			UPDATE REN_Units SET rgt = rgt + 2 WHERE rgt > @Selectedrgt;      
			UPDATE REN_Units SET lft = lft + 2 WHERE lft > @Selectedrgt;      
			set @lft = @Selectedrgt + 1      
			set @rgt = @Selectedrgt + 2       
		END      
		else  --Adding Root      
		BEGIN      
			set @lft = 1      
			set @rgt = 2       
			set @Depth = 0      
			set @ParentID = 0      
			set @IsGroup = 1      
		END     
    
		--GENERATE CODE      
		IF @IsLeadCodeAutoGen IS NOT NULL AND @IsLeadCodeAutoGen=1 AND @UNITID=0      
		BEGIN      
			SELECT @ParentCode=Name      
			FROM REN_Units WITH(NOLOCK) WHERE UnitID=@ParentID        

			--CALL AUTOCODEGEN      
			EXEC [spCOM_SetCode] 93,@ParentCode,@CODE OUTPUT        
		END      
       
		--Map Dimension
		IF(@PrefValue is not null and @PrefValue<>'')  
		BEGIN  
			set @Dimesion=0  
			BEGIN try  
				select @Dimesion=convert(BIGINT,@PrefValue)  
			end try  
			BEGIN catch  
				set @Dimesion=0   
			end catch  
			if(@Dimesion>0)  
			BEGIN  
				SELECT @RefSelectedNodeID=RefDimensionNodeID FROM COM_DocBridge WITH(NOLOCK)
				WHERE CostCenterID=93 AND RefDimensionID=@Dimesion AND NodeID=@SelectedNodeID 
				SET @RefSelectedNodeID=ISNULL(@RefSelectedNodeID,@SelectedNodeID)
				
				select @CCStatusID = statusid from com_status WITH(NOLOCK) where costcenterid=@Dimesion and status = 'Active'
				EXEC @LinkDim_NodeID = [dbo].[spCOM_SetCostCenter]
				@NodeID = 0,@SelectedNodeID = @RefSelectedNodeID,@IsGroup = @IsGroup,
				@Code = @CODE,
				@Name = @NAME,
				@AliasName=@NAME,
				@PurchaseAccount=0,@SalesAccount=0,@StatusID=@CCStatusID,
				@CustomFieldsQuery=NULL,@AddressXML=NULL,@AttachmentsXML=NULL,
				@CustomCostCenterFieldsQuery=@CustomCCQuery,@ContactsXML=NULL,@NotesXML=NULL,
				@CostCenterID = @Dimesion,@CompanyGUID=@COMPANYGUID,@GUID='',
				@UserName=@UserName,@RoleID=@RoleID,@UserID=@UserID,@CheckLink = 0

			END  
		END 	

		INSERT INTO [REN_Units]([PropertyID],[Code],[Name],[Status],[Depth],[ParentID],[lft],[rgt],[IsGroup],[CompanyGUID],[GUID],[CreatedBy],[CreatedDate],CCID,CCNodeID,LinkCCID)    
		VALUES (@PROPERTYID,@CODE,@NAME,@STATUSID,@Depth,@SelectedNodeID,@lft,@rgt,@IsGroup,@CompanyGUID,newid(),@UserName,convert(float,@Dt),@CCID,@LinkDim_NodeID,@Dimesion)    
       
		SET @UNITID=SCOPE_IDENTITY()
		     
		--Handling of Extended Table        
		INSERT INTO REN_UnitsExtended(UnitID,[CreatedBy],[CreatedDate])        
		VALUES(@UNITID, @UserName, @Dt)       
        
		INSERT INTO COM_CCCCDATA ([CostCenterID] ,[NodeID] ,[Guid],[CreatedBy],[CreatedDate])  
		VALUES(93,@UNITID,newid(),  @UserName, @Dt)  
     
		--Link Dimension Mapping
		INSERT INTO COM_DocBridge (CostCenterID, NodeID,InvDocID, AccDocID, RefDimensionID  , RefDimensionNodeID ,  
		CompanyGUID, guid, Createdby, CreatedDate,Abbreviation)
		values(93, @UNITID,0,0,@Dimesion,@LinkDim_NodeID,'',newid(),@UserName, @dt,'Units')    
	END --------END INSERT RECORD-----------      
	ELSE  --------START UPDATE RECORD-----------      
	BEGIN    
		SELECT @TempGuid=[GUID] from [REN_Units]  WITH(NOLOCK)       
		WHERE UnitID=@UNITID    
         
		IF(@TempGuid!=@Guid)--IF RECORD ALREADY UPDATED BY SOME OTHER USER i.e DIRTY READ        
		BEGIN        
			RAISERROR('-101',16,1)       
		END        
		ELSE        
		BEGIN            
			UPDATE [REN_Units]    
			SET [PropertyID] = @PROPERTYID    
			,[Code] =  @CODE    
			,[Name] = @NAME    
			,[Status] = @STATUSID    
			,[CompanyGUID] = @CompanyGUID    
			,[GUID] = @Guid    
			,[ModifiedBy] = @UserName    
			,[ModifiedDate] =@Dt   
			,CCID=@CCID
			WHERE UnitID=@UNITID    
		     
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
				select @NID = CCNodeID, @CCIDAcc=LinkCCID  from Ren_Units WITH(NOLOCK) where UnitID=@UNITID 

				if(@Dimesion>0 and @NID is not null and @NID <>'' )
				begin  
					declare @Gid nvarchar(50) , @Table nvarchar(100), @CGid nvarchar(50)
					declare @NodeidXML nvarchar(max) 
					select @Table=Tablename from adm_features WITH(NOLOCK) where featureid=@Dimesion
					declare @str nvarchar(max) 
					set @str='@Gid nvarchar(50) output' 
					set @NodeidXML='set @Gid= (select GUID from '+convert(nvarchar,@Table)+' WITH(NOLOCK) where NodeID='+convert(nvarchar,@NID)+')'

					exec sp_executesql @NodeidXML, @str, @Gid OUTPUT 
					
					SELECT @RefSelectedNodeID=RefDimensionNodeID FROM COM_DocBridge WITH(NOLOCK)
					WHERE CostCenterID=93 AND RefDimensionID=@Dimesion AND NodeID=@SelectedNodeID 
					SET @RefSelectedNodeID=ISNULL(@RefSelectedNodeID,@SelectedNodeID)
				
					select @CCStatusID = statusid from com_status WITH(NOLOCK) where costcenterid=@Dimesion and status = 'Active'
					EXEC	@LinkDim_NodeID = [dbo].[spCOM_SetCostCenter]
					@NodeID = @NID,@SelectedNodeID = @RefSelectedNodeID,@IsGroup = @IsGroup,
					@Code = @CODE,
					@Name = @NAME,
					@AliasName=@NAME,
					@PurchaseAccount=0,@SalesAccount=0,@StatusID=@CCStatusID,
					@CustomFieldsQuery=NULL,@AddressXML=NULL,@AttachmentsXML=NULL,
					@CustomCostCenterFieldsQuery=@CustomCCQuery,@ContactsXML=null,@NotesXML=NULL,
					@CostCenterID = @Dimesion,@CompanyGUID=@CompanyGUID,@GUID=@Gid,
					@UserName=@UserName,@RoleID=@RoleID,@UserID=@UserID , @CheckLink = 0 

					Update Ren_Units set LinkCCID=@Dimesion, CCNodeID=@LinkDim_NodeID where UnitID=@UNITID 
				END
			END  
		END    
	END    
    
    --CHECK WORKFLOW
	EXEC spCOM_CheckCostCentetWF 93,@UNITID,@WID,@RoleID,@UserID,@UserName,@STATUSID output
	    
    DECLARE @UpdateSql NVARCHAR(MAX)   
    
	IF(@StaticFieldsQuery IS NOT NULL AND @StaticFieldsQuery <>'')  
	BEGIN
		set @UpdateSql='update [REN_Units] SET '+@StaticFieldsQuery+' [ModifiedBy] ='''+ @UserName  
		+''',[ModifiedDate] =' + convert(nvarchar,@Dt) +' WHERE UnitID='+convert(nvarchar,@UNITID)  
		exec(@UpdateSql)  
	END
	
	IF(@CustomCostCenterFieldsQuery IS NOT NULL AND @CustomCostCenterFieldsQuery <>'')  
	BEGIN        
		set @UpdateSql='update [REN_UnitsExtended] SET '+@CustomCostCenterFieldsQuery+'[ModifiedBy] ='''+ @UserName        
		+''',[ModifiedDate] =' + convert(nvarchar,@Dt) +' WHERE UnitID='+convert(nvarchar,@UNITID)        
	       
		exec(@UpdateSql)       
    END
    
	IF(@CustomCCQuery IS NOT NULL AND @CustomCCQuery <>'')  
	BEGIN  
		set @UpdateSql='update COM_CCCCDATA SET '+@CustomCCQuery+'[ModifiedBy] ='''+ @UserName+''',[ModifiedDate] =' + 
		convert(nvarchar,@Dt) +' WHERE NodeID = '+convert(nvarchar,@UNITID) + ' AND CostCenterID = 93'   
		    
		exec(@UpdateSql)    
	END   
    
    DELETE FROM REN_Particulars WHERE PropertyID=@PROPERTYID AND UnitID=@UNITID   
    insert into REN_Particulars(ParticularID,[PropertyID]    
           ,[UnitID]    
           ,[CreditAccountID]    
           ,[DebitAccountID] ,AdvanceAccountID   
           ,[Refund]    
           ,[DiscountPercentage],Vat,InclChkGen  ,VatType,TaxCategoryID,RecurInvoice ,PostDebit  
           ,[DiscountAmount] 
           ,[TypeID]
           ,[ContractType]
           ,[CompanyGUID]    
           ,[GUID]    
           ,[CreatedBy]    
           ,[CreatedDate])    
    select  X.value('@Particulars','BIGINT'),    
    @PROPERTYID,@UNITID,     
    ISNULL(X.value('@CreditAccount','BIGINT'),0),    
    ISNULL(X.value('@DebitAccount','BIGINT'),0),
    X.value('@AdvanceAccountID','BIGINT'),
    ISNULL(X.value('@Refund','INT'),0),    
    X.value('@Percentage','FLOAT'), X.value('@Vat','FLOAT'), X.value('@InclChkGen','INT'),
    X.value('@VatType','Nvarchar(50)'),X.value('@TaxCategoryID','BIGINT'),X.value('@RecurInvoice','BIT'),X.value('@PostDebit','BIT'),
    X.value('@Amount','FLOAT'),
    ISNULL(X.value('@TypeID','INT'),0),
    ISNULL(X.value('@ContractType','INT'),1),@CompanyGUID,newid(),@UserName,@Dt     
    from @DXML.nodes('/XML/Row') as data(X)    
      
   	IF (@HistoryXML IS NOT NULL AND @HistoryXML <> '')    
		EXEC spCOM_SetHistory 93,@UNITID,@HistoryXML,@UserName  
   
       
	--Inserts Multiple Attachments  
	IF (@AttachmentsXML IS NOT NULL AND @AttachmentsXML <> '')  
	BEGIN  
		SET @XML=@AttachmentsXML  
  
		INSERT INTO COM_Files(FilePath,ActualFileName,RelativeFileName,
		FileExtension,FileDescription,IsProductImage,FeatureID,CostCenterID,FeaturePK,  
		GUID,CreatedBy,CreatedDate)  
		SELECT X.value('@FilePath','NVARCHAR(500)'),X.value('@ActualFileName','NVARCHAR(50)'),X.value('@RelativeFileName','NVARCHAR(50)'),  
		X.value('@FileExtension','NVARCHAR(50)'),X.value('@FileDescription','NVARCHAR(500)'),X.value('@IsProductImage','bit'),93,93,@UNITID,  
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
   
	IF (@UnitRateXML IS NOT NULL AND @UnitRateXML <> '')  
	BEGIN  
		SET @XML=@UnitRateXML  

		INSERT INTO Ren_UnitRate(UnitID,Amount,Discount,
		AnnualRent,WithEffectFrom,CompanyGUID,  
		GUID,CreatedBy,CreatedDate)  

		SELECT @UNITID,X.value('@Amount','FLOAT'),X.value('@Discount','FLOAT'),X.value('@AnnualRent','FLOAT'),   
		CONVERT(FLOAT, X.value('@WithEffFrom','DATETIME')) , @CompanyGUID, 
		NEWID(),@UserName,@Dt  
		FROM @XML.nodes('/UnitRateXML/Row') as Data(X)    
		WHERE X.value('@Action','NVARCHAR(10)')='NEW'  

		--If Action is MODIFY then update Attachments  
		UPDATE Ren_UnitRate  
		SET Amount=X.value('@Amount','FLOAT'),  
		Discount=X.value('@Discount','FLOAT'), 
		AnnualRent=X.value('@AnnualRent','FLOAT'),   
		WithEffectFrom =CONVERT(FLOAT, X.value('@WithEffFrom','DATETIME')),   
		--    GUID=X.value('@GUID','NVARCHAR(50)'),  
		ModifiedBy=@UserName,  
		ModifiedDate=@Dt  

		FROM  @XML.nodes('/UnitRateXML/Row') as Data(X)    
		WHERE X.value('@Action','NVARCHAR(500)')='MODIFY'   AND UnitRateID = X.value('@UnitRateID','FLOAT')

		--If Action is DELETE then delete Attachments  
		DELETE FROM Ren_UnitRate  
		WHERE UnitRateID IN(SELECT X.value('@UnitRateID','bigint')  
		FROM @XML.nodes('/UnitRateXML/Row') as Data(X)  
		WHERE X.value('@Action','NVARCHAR(10)')='DELETE')  AND UNITID = @UNITID
	END  

	--UPDATE LINK DATA
	if(@LinkDim_NodeID>0)
	begin
		set @UpdateSql='update COM_CCCCDATA  
		SET CCNID'+convert(nvarchar,(@Dimesion-50000))+'='+CONVERT(NVARCHAR,@LinkDim_NodeID)+'  WHERE NodeID = '+
		convert(nvarchar,@UNITID) + ' AND CostCenterID = 93' 
		EXEC (@UpdateSql)

		Exec [spDOC_SetLinkDimension]
			@InvDocDetailsID=@UNITID, 
			@Costcenterid=93,         
			@DimCCID=@Dimesion,
			@DimNodeID=@LinkDim_NodeID,
			@UserID=@UserID,    
			@LangID=@LangID  
	end
	         
	INSERT INTO [REN_UnitsHistory]
	([UnitID],[PropertyID],[Code],[Name],[Status],[CCID],[NodeID],[RentableArea],[BuildUpArea],[FloorLookUpID],[ViewLookUpID]
	,[NoOfBathrooms],[NoOfParkings],[ElectricityCode],[ElectricityKW],[Rent],[RentTypeID],[DiscountPercentage],[DiscountAmount]
	,[AnnualRent],[MonthlyRent],[RentPerSQFT],[Depth],[ParentID],[lft],[rgt],[IsGroup],[CompanyGUID],[GUID],[CreatedBy],[CreatedDate]
	,[ModifiedBy],[ModifiedDate],[TermsConditions],[SalesmanID],[AccountantID],[LandlordID],[UnitStatus],[RentalIncomeAccountID],[RentalReceivableAccountID]
	,[AdvanceRentAccountID],[BankAccount],[BankLoanAccount],[CCNodeID],[LinkCCID],[RentalAccount],[RentPayableAccount],[AdvanceRentPaid]
	,[LocationID],[BasedOn],[ContractID],[PenaltyAccountID],[AdvanceReceivableAccountID],[AdvReceivableCloseAccID],[HistoryStatus])
	select [UnitID],[PropertyID],[Code],[Name],[Status],[CCID],[NodeID],[RentableArea],[BuildUpArea],[FloorLookUpID],[ViewLookUpID]
	,[NoOfBathrooms],[NoOfParkings],[ElectricityCode],[ElectricityKW],[Rent],[RentTypeID],[DiscountPercentage],[DiscountAmount]
	,[AnnualRent],[MonthlyRent],[RentPerSQFT],[Depth],[ParentID],[lft],[rgt],[IsGroup],[CompanyGUID],[GUID],[CreatedBy],[CreatedDate]
	,[ModifiedBy],[ModifiedDate],[TermsConditions],[SalesmanID],[AccountantID],[LandlordID],[UnitStatus],[RentalIncomeAccountID],[RentalReceivableAccountID]
	,[AdvanceRentAccountID],[BankAccount],[BankLoanAccount],[CCNodeID],[LinkCCID],[RentalAccount],[RentPayableAccount],[AdvanceRentPaid]
	,[LocationID],[BasedOn],[ContractID],[PenaltyAccountID],[AdvanceReceivableAccountID],[AdvReceivableCloseAccID],@HistoryStatus
	from ren_units with(nolock) where unitid=@UnitID

    --Insert into Account history  Extended  
   insert into REN_UnitsExtendedHistory  
   select *,@HistoryStatus from REN_UnitsExtended with(nolock) WHERE unitid=@UnitID
  

	         
COMMIT TRANSACTION    
--ROLLBACK TRANSACTION    
 
SELECT ErrorMessage,ErrorNumber FROM COM_ErrorMessages WITH(nolock)       
WHERE ErrorNumber=100 AND LanguageID=@LangID      
SET NOCOUNT OFF;        
RETURN @UNITID    
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
		FROM COM_ErrorMessages WITH(nolock) 
		WHERE ErrorNumber=-999 AND LanguageID=@LangID      
	END      
	ROLLBACK TRANSACTION      
	SET NOCOUNT OFF        
	RETURN -999         
END CATCH 
GO

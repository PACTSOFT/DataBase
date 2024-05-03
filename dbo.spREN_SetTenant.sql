USE PACT2C222
GO
SET ANSI_NULLS, QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spREN_SetTenant]
	@TenantID [bigint],
	@Code [nvarchar](200),
	@TypeID [int],
	@PositionID [int],
	@FirstName [nvarchar](200),
	@MiddleName [nvarchar](200) = null,
	@LastName [nvarchar](200) = null,
	@LeaseCatagory [nvarchar](200) = null,
	@ContactPerson [nvarchar](200) = null,
	@PostingID [bigint] = 0,
	@Phone1 [nvarchar](200) = null,
	@Phone2 [nvarchar](200) = null,
	@Email [nvarchar](200) = null,
	@Fax [nvarchar](200) = null,
	@IDNumber [nvarchar](200) = null,
	@Profession [nvarchar](200) = null,
	@TabsDetails [nvarchar](max) = null,
	@Description [nvarchar](500) = null,
	@SelectedNodeID [bigint],
	@IsGroup [bit],
	@CustomFieldsQuery [nvarchar](max) = null,
	@CustomCostCenterFieldsQuery [nvarchar](max) = null,
	@AttachmentsXML [nvarchar](max) = null,
	@ActivityXML [nvarchar](max) = '',
	@CompanyGUID [nvarchar](50),
	@UserName [nvarchar](50),
	@WID [int] = 0,
	@RoleID [int] = 1,
	@UserID [int] = 0,
	@LangID [int] = 1
WITH ENCRYPTION, EXECUTE AS CALLER
AS
BEGIN TRANSACTION      
BEGIN TRY      
	SET NOCOUNT ON;    
	--Declaration Section    
	DECLARE @Dt float,@XML xml,@TempGuid nvarchar(50),@return_value int,@CCStatusID bigint  
	DECLARE @ParentCode nvarchar(200),@CCCCCData XML  
	DECLARE @lft bigint,@rgt bigint,@Selectedlft bigint,@Selectedrgt bigint,@Depth int,@ParentID bigint    
	DECLARE @SelectedIsGroup bit,@HasAccess bit,@IsTenantCodeAutoGen bit    
	DECLARE @TEMPxml NVARCHAR(500),@PrefValue NVARCHAR(500),@Dimesion bigint,@HistoryStatus nvarchar(50)
	DECLARE @StatusID INT,@RefSelectedNodeID BIGINT
	
	select @StatusID=statusid from com_status WITH(NOLOCK) where costcenterid=94 and [Status]='Active'
	--User acces check FOR ACCOUNTS    
	IF @TenantID=0    
	BEGIN    
		SET @HasAccess=dbo.fnCOM_HasAccess(@RoleID,94,1)    
		set @HistoryStatus='Add'
	END    
	ELSE    
	BEGIN    
		SET @HasAccess=dbo.fnCOM_HasAccess(@RoleID,94,3)    
		set @HistoryStatus='Update'
	END    

	IF @HasAccess=0    
	BEGIN    
		RAISERROR('-105',16,1)    
	END    
    
	--GETTING PREFERENCE   
	SELECT @IsTenantCodeAutoGen=Value FROM COM_CostCenterPreferences  WITH(nolock) 
	WHERE COSTCENTERID=94 and Name='CodeAutoGen'    
	select @PrefValue=Value from COM_CostCenterPreferences WITH(nolock)  
	where CostCenterID=94 and Name = 'LinkDocument'  
	 
	--User acces check FOR Attachments    
	IF (@AttachmentsXML IS NOT NULL AND @AttachmentsXML <> '')    
	BEGIN    
		SET @HasAccess=dbo.fnCOM_HasAccess(@RoleID,94,12)    

		IF @HasAccess=0    
		BEGIN    
			RAISERROR('-105',16,1)    
		END    
	END    

	SET @Dt=convert(float,getdate())--Setting Current Date    

	IF @TenantID=0--------START INSERT RECORD-----------    
	BEGIN  
		--To Set Left,Right And Depth of Record    
		SELECT @SelectedIsGroup=IsGroup,@Selectedlft =lft,@Selectedrgt=rgt,@ParentID=ParentID,@Depth=Depth    
		from [REN_Tenant] with(NOLOCK) where TenantID=@SelectedNodeID    
     
		--IF No Record Selected or Record Doesn't Exist    
		if(@SelectedIsGroup is null)     
			select @SelectedNodeID=TenantID,@SelectedIsGroup=IsGroup,@Selectedlft =lft,@Selectedrgt=rgt,@ParentID=ParentID,@Depth=Depth    
			from [REN_Tenant] with(NOLOCK) where ParentID =0    
		   
		if(@SelectedIsGroup = 1)--Adding Node Under the Group    
		BEGIN    
			UPDATE REN_Tenant SET rgt = rgt + 2 WHERE rgt > @Selectedlft;    
			UPDATE REN_Tenant SET lft = lft + 2 WHERE lft > @Selectedlft;    
			set @lft =  @Selectedlft + 1    
			set @rgt = @Selectedlft + 2    
			set @ParentID = @SelectedNodeID    
			set @Depth = @Depth + 1    
		END    
		else if(@SelectedIsGroup = 0)--Adding Node at Same level    
		BEGIN    
			UPDATE REN_Tenant SET rgt = rgt + 2 WHERE rgt > @Selectedrgt;    
			UPDATE REN_Tenant SET lft = lft + 2 WHERE lft > @Selectedrgt;    
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
		IF @IsTenantCodeAutoGen IS NOT NULL AND @IsTenantCodeAutoGen=1 AND @TenantID=0    
		BEGIN    
			SELECT @ParentCode=[TenantCode]    
			FROM [REN_Tenant] WITH(NOLOCK) WHERE TenantID=@ParentID      

			--CALL AUTOCODEGEN    
			EXEC [spCOM_SetCode] 94,@ParentCode,@Code OUTPUT      
		END    

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
				WHERE CostCenterID=94 AND RefDimensionID=@Dimesion AND NodeID=@SelectedNodeID 
				SET @RefSelectedNodeID=ISNULL(@RefSelectedNodeID,@SelectedNodeID)
				
				select @CCStatusID = statusid from com_status with(nolock)where costcenterid=@Dimesion and status = 'Active'  
	
				EXEC @return_value = [dbo].[spCOM_SetCostCenter]  
				@NodeID = 0,@SelectedNodeID = @RefSelectedNodeID,@IsGroup = @IsGroup,  
				@Code = @Code,  
				@Name = @FirstName,  
				@AliasName=@FirstName,  
				@PurchaseAccount=0,@SalesAccount=0,@StatusID=@CCStatusID,  
				@CustomFieldsQuery=NULL,@AddressXML=NULL,@AttachmentsXML=NULL,  
				@CustomCostCenterFieldsQuery=NULL,@ContactsXML=NULL,@NotesXML=NULL,  
				@CostCenterID = @Dimesion,@CompanyGUID=@COMPANYGUID,@GUID='',
				@UserName=@UserName,@RoleID=@RoleID,@UserID=@UserID,@CheckLink = 0  

			end  
		end   

		-- Insert statements for procedure here    
		INSERT INTO [REN_Tenant]    
		([TenantCode],  
		[TypeID],  
		[PositionID],  
		[FirstName],  
		[MiddleName],  
		[LastName],  
		[LeaseSignatory],  
		[ContactPerson],  
		[Phone1],  
		[Phone2],  
		[Email],  
		[Fax],  
		[IDNumber],  
		[Profession],  
		[Depth],    
		[ParentID],    
		[lft],    
		[rgt],    
		[IsGroup],    
		[CompanyGUID],    
		[GUID],    
		[Description],    
		[CreatedBy],    
		[CreatedDate],  
		[PostingID],CCNodeID, CCID,StatusID)      
		VALUES    
		(@Code,   
		@TypeID ,  
		@PositionID,   
		@FirstName,   
		@MiddleName,   
		@LastName,   
		@LeaseCatagory,  
		@ContactPerson,  
		@Phone1,  
		@Phone2,   
		@Email,   
		@Fax,  
		@IDNumber,   
		@Profession,  
		@Depth,    
		@ParentID,    
		@lft,    
		@rgt,    
		@IsGroup,    
		@CompanyGUID,    
		newid(),    
		@Description,    
		@UserName,    
		@Dt,  
		@PostingID, @return_value ,@Dimesion ,@StatusID)    
		--To get inserted record primary key    
		SET @TenantID=SCOPE_IDENTITY()    
     
		--Handling of Extended Table    
		INSERT INTO [REN_TenantExtended]([TenantID],[CreatedBy],[CreatedDate])    
		VALUES(@TenantID,@UserName,@Dt)    

		INSERT INTO COM_CCCCDATA ([CostCenterID] ,[NodeID] ,[Guid],[CreatedBy],[CreatedDate])  
		VALUES(94,@TenantID,newid(),@UserName,@Dt)   

		-- Link Dimension Mapping  
		INSERT INTO COM_DocBridge (CostCenterID, NodeID,InvDocID, AccDocID, RefDimensionID  , RefDimensionNodeID ,  
		CompanyGUID, guid, Createdby, CreatedDate,Abbreviation)  
		values(94, @TenantID,0,0,@Dimesion,@return_value,'',newid(),@UserName, @dt,'Tenant')  
		--Handling of CostCenter Costcenters Extrafields Table    
	END--------END INSERT RECORD-----------    
	ELSE--------START UPDATE RECORD-----------    
	BEGIN     
    
		SELECT @TempGuid=[GUID] from [REN_Tenant]  WITH(NOLOCK)     
		WHERE TenantID=@TenantID 
		
		IF EXISTS(SELECT TenantID FROM REN_Tenant WHERE TenantID=@TenantID AND ParentID=0)    
		BEGIN    
			RAISERROR('-123',16,1)    
		END    

		UPDATE [REN_Tenant]    
		SET[TenantCode]     =@Code    
		,[TypeID]        =@TypeID    
		,[PositionID]    =@PositionID    
		,[FirstName]     =@FirstName    
		,[MiddleName] =@MiddleName    
		,[LastName]  =@LastName    
		,[LeaseSignatory]=@LeaseCatagory   
		,[ContactPerson] =@ContactPerson   
		,[Phone1]  =@Phone1   
		,[Phone2]  =@Phone2    
		,[Email]   =@Email    
		,[Fax]   =@Fax   
		,[IDNumber]  =@IDNumber    
		,[Profession] =@Profession   
		,[GUID]          = newid()    
		,[Description]   = @Description       
		,[ModifiedBy]    = @UserName    
		,[ModifiedDate]  = @Dt  
		,[PostingID]  =@PostingID  
		WHERE TenantID=@TenantID          
     
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
			select @NID = CCNodeID, @CCIDAcc=CCID  from [REN_Tenant] with(nolock) where TenantID=@TenantID  
  
			if(@Dimesion>0 and @NID is not null and @NID <>'' )      
			begin   
				declare @Gid nvarchar(50) , @Table nvarchar(100), @CGid nvarchar(50)  
				declare @NodeidXML nvarchar(max)   
				select @Table=Tablename from adm_features with(nolock) where featureid=@Dimesion  
				declare @str nvarchar(max)   
				set @str='@Gid nvarchar(50) output'   
				set @NodeidXML='set @Gid= (select GUID from '+convert(nvarchar,@Table)+' with(nolock) where NodeID='+convert(nvarchar,@NID)+')'  

				exec sp_executesql @NodeidXML, @str, @Gid OUTPUT   
				
				SELECT @RefSelectedNodeID=RefDimensionNodeID FROM COM_DocBridge WITH(NOLOCK)
				WHERE CostCenterID=94 AND RefDimensionID=@Dimesion AND NodeID=@SelectedNodeID 
				SET @RefSelectedNodeID=ISNULL(@RefSelectedNodeID,@SelectedNodeID)
				
				select @CCStatusID =  statusid from com_status with(nolock) where costcenterid=@Dimesion and [status] = 'Active'  
				EXEC @return_value = [dbo].[spCOM_SetCostCenter]  
				@NodeID = @NID,@SelectedNodeID = @RefSelectedNodeID,@IsGroup = @IsGroup,  
				@Code = @Code,  
				@Name = @FirstName,  
				@AliasName=@FirstName,  
				@PurchaseAccount=0,@SalesAccount=0,@StatusID=@CCStatusID,  
				@CustomFieldsQuery=NULL,@AddressXML=NULL,@AttachmentsXML=NULL,  
				@CustomCostCenterFieldsQuery=NULL,@ContactsXML=null,@NotesXML=NULL,  
				@CostCenterID = @Dimesion,@CompanyGUID=@CompanyGUID,@GUID=@Gid,
				@UserName=@UserName,@RoleID=@RoleID,@UserID=@UserID , @CheckLink = 0   

				Update [REN_Tenant] set CCID=@Dimesion, CCNodeID=@return_value where TenantID=@TenantID    
				
			END  
		END     
	END    

	IF(@Code IS NULL OR @Code='')    
	BEGIN    
		UPDATE  [REN_Tenant]    
		SET [TenantCode] = @TenantID    
		WHERE TenantID=@TenantID          
	END    
	
	DECLARE @UpdateSql nvarchar(max)  
    
	if(@TabsDetails is not null and @TabsDetails <>'')  
	begin  
		SET @UpdateSql=' UPDATE REN_Tenant SET '+@TabsDetails+' WHERE TenantID = '+CONVERT(nvarchar,@TenantID)  
		exec(@UpdateSql)  
	end  

    SELECT @StatusID=StatusID FROM REN_Tenant WITH(NOLOCK) WHERE TenantID=@TenantID
    --CHECK WORKFLOW
	EXEC spCOM_CheckCostCentetWF 94,@TenantID,@WID,@RoleID,@UserID,@UserName,@StatusID output
	
	--Update Extra fields    
	set @UpdateSql='update [REN_TenantExtended]  
	SET '+@CustomFieldsQuery+'[ModifiedBy] ='''+ @UserName    
	+''',[ModifiedDate] =' + convert(nvarchar,@Dt) +' WHERE TenantID='+convert(nvarchar,@TenantID)    
	exec(@UpdateSql)    
  
	set @UpdateSql='update COM_CCCCDATA  SET  
	'+@CustomCostCenterFieldsQuery+'[ModifiedBy] ='''+ @UserName+''',[ModifiedDate] =' + convert(nvarchar,@Dt) +' WHERE NodeID = '+
	convert(nvarchar,@TenantID) + ' AND CostCenterID = 94'   
	exec(@UpdateSql)    
     
	--Inserts Multiple Attachments    
	IF (@AttachmentsXML IS NOT NULL AND @AttachmentsXML <> '')    
	BEGIN    
		SET @XML=@AttachmentsXML    

		INSERT INTO COM_Files(FilePath,ActualFileName,RelativeFileName,  
		FileExtension,FileDescription,IsProductImage,IsDefaultImage,FeatureID,CostCenterID,FeaturePK,    
		GUID,CreatedBy,CreatedDate)    
		SELECT X.value('@FilePath','NVARCHAR(500)'),X.value('@ActualFileName','NVARCHAR(50)'),X.value('@RelativeFileName','NVARCHAR(50)'),    
		X.value('@FileExtension','NVARCHAR(50)'),X.value('@FileDescription','NVARCHAR(500)'),X.value('@IsProductImage','bit'),X.value('@IsDefaultImage','bit'),94,94,@TenantID,    
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
		IsDefaultImage=X.value('@IsDefaultImage','bit'),          
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
	
	if(@ActivityXml<>'')      
		exec spCom_SetActivitiesAndSchedules @ActivityXml,94,@TenantID,@CompanyGUID,'',@UserName,@dt,@LangID     
		
	--UPDATE LINK DATA
	if(@return_value>0 and @return_value<>'')
	begin
	
		set @UpdateSql='update COM_CCCCDATA    
		SET CCNID'+convert(nvarchar,(@Dimesion-50000))+'='+CONVERT(NVARCHAR,@return_value)+'  WHERE NodeID = '+
		convert(nvarchar,@TenantID) + ' AND CostCenterID = 94'   
		EXEC (@UpdateSql)  
			
		Exec [spDOC_SetLinkDimension]
			@InvDocDetailsID=@TenantID, 
			@Costcenterid=94,         
			@DimCCID=@Dimesion,
			@DimNodeID=@return_value,
			@UserID=@UserID,    
			@LangID=@LangID 
			
			DELETE FROM COM_Files    
			WHERE FeatureID=@Dimesion and FeaturePK=@return_value
			
			INSERT INTO COM_Files(FilePath,ActualFileName,RelativeFileName,FileExtension,FileDescription,
			IsProductImage,IsDefaultImage,FeatureID,CostCenterID,FeaturePK,[GUID],CreatedBy,CreatedDate)    
			select  FilePath,ActualFileName,RelativeFileName,FileExtension,FileDescription,
			IsProductImage,IsDefaultImage,@Dimesion,@Dimesion,@return_value,[GUID],CreatedBy,CreatedDate 
			from COM_Files with(nolock)
			where FeatureID=94 and FeaturePK=@TenantID
	end

	INSERT INTO [dbo].[REN_TenantHistory]
	([TenantID],[TenantCode],[TypeID],[PositionID],[FirstName],[MiddleName],[LastName],[LeaseSignatory],[ContactPerson],[PostingID]
	,[Phone1],[Phone2],[Email],[Fax],[IDNumber],[Profession],[Passport],[Nationality],[PassportIssueDate],[PassportExpiryDate]
	,[SponsorName],[SponsorPassport],[SponsorIssueDate],[SponsorExpiryDate],[License],[LicenseIssuedBy],[LicenseIssueDate]
	,[LicenseExpiryDate],[Description],[Depth],[ParentID],[lft],[rgt],[IsGroup],[CompanyGUID],[GUID],[CreatedBy],[CreatedDate]
	,[ModifiedBy],[ModifiedDate],[CCNodeID],[CCID],[UserName],[Password],[StatusID],[HistoryStatus])
	select 
	[TenantID],[TenantCode],[TypeID],[PositionID],[FirstName],[MiddleName],[LastName],[LeaseSignatory],[ContactPerson],[PostingID]
	,[Phone1],[Phone2],[Email],[Fax],[IDNumber],[Profession],[Passport],[Nationality],[PassportIssueDate],[PassportExpiryDate]
	,[SponsorName],[SponsorPassport],[SponsorIssueDate],[SponsorExpiryDate],[License],[LicenseIssuedBy],[LicenseIssueDate]
	,[LicenseExpiryDate],[Description],[Depth],[ParentID],[lft],[rgt],[IsGroup],[CompanyGUID],[GUID],[CreatedBy],[CreatedDate]
	,[ModifiedBy],[ModifiedDate],[CCNodeID],[CCID],[UserName],[Password],[StatusID],@HistoryStatus 
	from ren_tenant where TenantID=@TenantID
	
	INSERT INTO REN_TENANTEXTENDEDHISTORY
	SELECT  *,@HistoryStatus FROM [REN_TenantExtended] where TenantID=@TenantID

COMMIT TRANSACTION      
SELECT * FROM [REN_Tenant] WITH(nolock) WHERE TenantID=@TenantID    
SELECT ErrorMessage,ErrorNumber FROM COM_ErrorMessages WITH(nolock)     
WHERE ErrorNumber=100 AND LanguageID=@LangID    
SET NOCOUNT OFF;      
RETURN @TenantID      
END TRY      
BEGIN CATCH

	if(@return_value=-999)
		return -999
      
	--Return exception info [Message,Number,ProcedureName,LineNumber]      
	IF ERROR_NUMBER()=50000    
	BEGIN    
		SELECT * FROM [REN_Tenant] WITH(nolock) WHERE TenantID=@TenantID      
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

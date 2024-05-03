USE PACT2C222
GO
SET ANSI_NULLS, QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spPRD_SetEmployee]
	@ResourceID [bigint],
	@EmpCode [nvarchar](500),
	@EmpName [nvarchar](500),
	@StatusID [int],
	@IsGroup [bit],
	@CustomFieldsQuery [nvarchar](max),
	@CustomCostCenterFieldsQuery [nvarchar](max),
	@PrimaryContactQuery [nvarchar](max),
	@ContactsXML [nvarchar](max),
	@NotesXML [nvarchar](max),
	@AddressXML [nvarchar](max),
	@AttachmentsXML [nvarchar](max),
	@SelectedNodeID [int],
	@CompanyGUID [nvarchar](50),
	@GUID [nvarchar](50),
	@CreatedBy [nvarchar](50),
	@Description [nvarchar](max) = NULL,
	@UserName [nvarchar](50),
	@UserID [int] = 0,
	@RoleID [int] = 0,
	@LangId [int] = 1
WITH ENCRYPTION, EXECUTE AS CALLER
AS
BEGIN TRANSACTION 
BEGIN TRY
SET NOCOUNT ON;

	
	DECLARE @Dt float,@XML xml,@HasAccess bit,@UpdateSql nvarchar(max),@IsDuplicateNameAllowed bit,@IsResCodeAutoGen bit  ,@IsIgnoreSpace bit
    DECLARE @lft bigint,@rgt bigint,@Selectedlft bigint,@Selectedrgt bigint,@Depth int,@ParentID bigint,@SelectedIsGroup int,@ParentCode nvarchar(200)

	-- User acces check FOR Notes  
  IF (@NotesXML IS NOT NULL AND @NotesXML <> '')  
  BEGIN  
   SET @HasAccess=dbo.fnCOM_HasAccess(@RoleID,80,8)  
  
   IF @HasAccess=0  
   BEGIN  
    RAISERROR('-105',16,1)  
   END  
  END  
  
  --User acces check FOR Attachments  
  IF (@AttachmentsXML IS NOT NULL AND @AttachmentsXML <> '')  
  BEGIN  
   SET @HasAccess=dbo.fnCOM_HasAccess(@RoleID,80,12)  
  
   IF @HasAccess=0  
   BEGIN  
    RAISERROR('-105',16,1)  
   END  
  END  
  
  --User acces check FOR Contacts  
  IF (@ContactsXML IS NOT NULL AND @ContactsXML <> '')  
  BEGIN  
   SET @HasAccess=dbo.fnCOM_HasAccess(@RoleID,80,16)  
  
   IF @HasAccess=0  
   BEGIN  
    RAISERROR('-105',16,1)  
   END  
  END  

   SET @Dt=convert(float,getdate())

    --GETTING PREFERENCE  
  SELECT @IsDuplicateNameAllowed=Value FROM COM_CostCenterPreferences WITH(nolock) WHERE COSTCENTERID=80 and  Name='DuplicateNameAllowed'  
  SELECT @IsResCodeAutoGen=Value FROM COM_CostCenterPreferences  WITH(nolock) WHERE COSTCENTERID=80 and  Name='CodeAutoGen'  
  SELECT @IsIgnoreSpace=Value FROM COM_CostCenterPreferences  WITH(nolock) WHERE COSTCENTERID=80 and  Name='IgnoreSpaces'  
  
 -- DUPLICATE CHECK  
  IF @IsDuplicateNameAllowed IS NOT NULL AND @IsDuplicateNameAllowed=0  
  BEGIN  
    IF @IsIgnoreSpace IS NOT NULL AND @IsIgnoreSpace=1  
   BEGIN  
    IF @ResourceID=0  
    BEGIN  
     IF EXISTS (SELECT ResourceId FROM PRD_Resources WITH(nolock) WHERE replace(ResourceName,' ','')=replace(@EmpName,' ','') and Resourcetypeid=2)  
     BEGIN  
      RAISERROR('-349',16,1)  
     END  
    END  
    ELSE  
    BEGIN  
     IF EXISTS (SELECT ResourceId FROM PRD_Resources WITH(nolock) WHERE replace(ResourceName,' ','')=replace(@EmpName,' ','') AND ResourceId <> @ResourceID and Resourcetypeid=2)  
     BEGIN  
      RAISERROR('-349',16,1)       
     END  
    END  
   END  
   ELSE  
   BEGIN  
    IF @ResourceID=0  
    BEGIN  
     IF EXISTS (SELECT ResourceId FROM PRD_Resources WITH(nolock) WHERE replace(ResourceName,' ','')=replace(@EmpName,' ','') and Resourcetypeid=2)  
     BEGIN  
      RAISERROR('-349',16,1)  
     END  
    END  
    ELSE  
    BEGIN  
     IF EXISTS (SELECT ResourceId FROM PRD_Resources WITH(nolock) WHERE replace(ResourceName,' ','')=replace(@EmpName,' ','') AND ResourceId <> @ResourceID and Resourcetypeid=2)  
     BEGIN  
      RAISERROR('-349',16,1)       
     END  
    END  
   END  
  END

	IF(@ResourceID=0)
	---New Insert of record
	BEGIN
	  --To Set Left,Right And Depth of Record  
    SELECT @SelectedIsGroup=IsGroup,@Selectedlft =lft,@Selectedrgt=rgt,@ParentID=ParentID,@Depth=Depth  
    from PRD_Resources with(NOLOCK) where ResourceID=@SelectedNodeID  
   
    --IF No Record Selected or Record Doesn't Exist  
    if(@SelectedIsGroup is null)   
     select @SelectedNodeID=@ResourceID,@SelectedIsGroup=IsGroup,@Selectedlft =lft,@Selectedrgt=rgt,@ParentID=ParentID,@Depth=Depth  
     from PRD_Resources with(NOLOCK) where ParentID =0  
         
    if(@SelectedIsGroup = 1)--Adding Node Under the Group  
     BEGIN  
      UPDATE PRD_Resources SET rgt = rgt + 2 WHERE rgt > @Selectedlft;  
      UPDATE PRD_Resources SET lft = lft + 2 WHERE lft > @Selectedlft;  
      set @lft =  @Selectedlft + 1  
      set @rgt = @Selectedlft + 2  
      set @ParentID = @SelectedNodeID  
      set @Depth = @Depth + 1  
     END  
    else if(@SelectedIsGroup = 0)--Adding Node at Same level  
     BEGIN  
      UPDATE PRD_Resources SET rgt = rgt + 2 WHERE rgt > @Selectedrgt;  
      UPDATE PRD_Resources SET lft = lft + 2 WHERE lft > @Selectedrgt;  
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
					IF @IsResCodeAutoGen IS NOT NULL AND @IsResCodeAutoGen=1 AND @ResourceID=0  
				  BEGIN  
					 SELECT @ParentCode=[ResourceCode]  
					FROM [PRD_Resources] WITH(NOLOCK) WHERE ResourceID=@ParentID    
  
				  --  CALL AUTOCODEGEN  
					 EXEC [spCOM_SetCode] 80,@ParentCode,@EmpCode OUTPUT    
					END  
  end
	 	 if (@ResourceID=0)
		 BEGIN
		 INSERT INTO PRD_Resources(ResourceCode,ResourceName,StatusId,
				 ResourceTypeID,ResourceTypeName,Description, Depth,ParentID,lft,
				 rgt,IsGroup,CompanyGUID,GUID,CreatedBy,CreatedDate)
				 Values (@EmpCode,@EmpName,@StatusID,
				 2,'Person',@Description, @Depth,@SelectedNodeID,@lft,
				 @rgt,@IsGroup,@CompanyGUID,newid(),@CreatedBy,convert(float,getdate()))


				 --To get inserted record primary key  
				  SET @ResourceID=SCOPE_IDENTITY() 
			--Insert into Prd_resourcesExtended table
			INSERT INTO PRD_ResourceExtended(ResourceID,[CreatedBy],[CreatedDate])
				VALUES(@ResourceID, @CreatedBy, convert(float,getdate()))

			

				    --INSERT PRIMARY CONTACT  
				INSERT  [COM_Contacts]  ([AddressTypeID]  
				,[FeatureID]  
				,[FeaturePK]  
				,[CompanyGUID]  
				,[GUID]   
				,[CreatedBy]  
				,[CreatedDate]  
				)  
				VALUES  
				(1  
				,80  
				,@ResourceID  
				,@CompanyGUID  
				,NEWID()  
				,@UserName,@Dt  
				)  
		END
		---Update the PRD_Resource Table
		ELSE
			BEGIN
			Update PRD_Resources
			set ResourceCode =@EmpCode,
			ResourceName=@EmpName,
			StatusID=@StatusID,
			ResourceTypeID=2,
			ResourceTypeName='Person',
			[Description]=@Description,
			IsGroup=@IsGroup,
			ParentID=@SelectedNodeID,
			GUID=NEWID(),
			CreatedBy=@CreatedBy,
			CreatedDate=@Dt 		 
			WHERE ResourceID=@ResourceID
			 
			END
				--Update Extra fields
				set @UpdateSql='update PRD_ResourceExtended
				SET '+@CustomFieldsQuery+' [ModifiedBy] ='''+ @CreatedBy
				+''',[ModifiedDate] =' + convert(nvarchar,convert(float,getdate())) +' WHERE ResourceID='+convert(nvarchar,@ResourceID)
				exec(@UpdateSql)


				 -- , BEFORE MODIFIEDBY  REQUIRES A NULL CHECK OF @PrimaryContactQuery
  IF(@PrimaryContactQuery IS NOT NULL AND @PrimaryContactQuery<>'')
  BEGIN
 
  set @UpdateSql='update [COM_Contacts]  
  SET '+@PrimaryContactQuery+',[ModifiedBy] ='''+ @UserName  
    +''',[ModifiedDate] =' + convert(nvarchar,@Dt) +' WHERE [FeatureID]=80 AND [AddressTypeID] = 1 AND [FeaturePK]='+convert(nvarchar,@ResourceID)  
   
  exec(@UpdateSql) 
  END

    
  --Inserts Multiple Contacts  
  IF (@ContactsXML IS NOT NULL AND @ContactsXML <> '')  
  BEGIN  
   SET @XML=@ContactsXML  
  
   --If Action is NEW then insert new contacts  
   INSERT INTO COM_Contacts(AddressTypeID,FeatureID,FeaturePK,ContactName,CostCenterID,  
   Address1,Address2,Address3,  
   City,State,Zip,Country,  
   Phone1,Phone2,Fax,Email1,Email2,URL,  
   GUID,CreatedBy,CreatedDate)  
   SELECT X.value('@AddressTypeID','int'),80,@ResourceID,X.value('@ContactName','NVARCHAR(500)'),80,  
   X.value('@Address1','NVARCHAR(500)'),X.value('@Address2','NVARCHAR(500)'),X.value('@Address3','NVARCHAR(500)'),  
   X.value('@City','NVARCHAR(100)'),X.value('@State','NVARCHAR(100)'),X.value('@Zip','NVARCHAR(50)'),X.value('@Country','NVARCHAR(100)'),  
   X.value('@Phone1','NVARCHAR(50)'),X.value('@Phone2','NVARCHAR(50)'),X.value('@Fax','NVARCHAR(50)'),X.value('@Email1','NVARCHAR(50)'),X.value('@Email2','NVARCHAR(50)'),X.value('@URL','NVARCHAR(50)'),  
   newid(),@UserName,@Dt  
   FROM @XML.nodes('/ContactsXML/Row') as Data(X)  
   WHERE X.value('@Action','NVARCHAR(10)')='NEW'  
  
   --If Action is MODIFY then update contacts  
   UPDATE COM_Contacts  
   SET AddressTypeID=X.value('@AddressTypeID','int'),  
    ContactName=X.value('@ContactName','NVARCHAR(500)'),  
    Address1=X.value('@Address1','NVARCHAR(500)'),  
    Address2=X.value('@Address2','NVARCHAR(500)'),  
    Address3=X.value('@Address3','NVARCHAR(500)'),  
    City=X.value('@City','NVARCHAR(100)'),  
    State=X.value('@State','NVARCHAR(100)'),  
    Zip=X.value('@Zip','NVARCHAR(50)'),  
    Country=X.value('@Country','NVARCHAR(100)'),  
    Phone1=X.value('@Phone1','NVARCHAR(50)'),  
    Phone2=X.value('@Phone2','NVARCHAR(50)'),  
    Fax=X.value('@Fax','NVARCHAR(50)'),  
    Email1=X.value('@Email1','NVARCHAR(50)'),  
    Email2=X.value('@Email2','NVARCHAR(50)'),  
    URL=X.value('@URL','NVARCHAR(50)'),  
    GUID=newid(),  
    ModifiedBy=@UserName,  
    ModifiedDate=@Dt  
   FROM COM_Contacts C   
   INNER JOIN @XML.nodes('/ContactsXML/Row') as Data(X)    
   ON convert(bigint,X.value('@ContactID','bigint'))=C.ContactID  
   WHERE X.value('@Action','NVARCHAR(500)')='MODIFY'  
  
   --If Action is DELETE then delete contacts  
   DELETE FROM COM_Contacts  
   WHERE ContactID IN(SELECT X.value('@ContactID','bigint')  
    FROM @XML.nodes('/ContactsXML/Row') as Data(X)  
    WHERE X.value('@Action','NVARCHAR(10)')='DELETE')  
  END  
  
  	
  --Inserts Multiple Address  
  EXEC spCOM_SetAddress 80,@ResourceID,@AddressXML,@UserName  
  
  --Inserts Multiple Notes  
  IF (@NotesXML IS NOT NULL AND @NotesXML <> '')  
  BEGIN  
   SET @XML=@NotesXML  
  
   --If Action is NEW then insert new Notes  
   INSERT INTO COM_Notes(FeatureID,CostCenterID,FeaturePK,Note,     
   GUID,CreatedBy,CreatedDate)  
   SELECT 80,80,@ResourceID,Replace(X.value('@Note','NVARCHAR(MAX)'),'@~','
'),   
   newid(),@UserName,@Dt  
   FROM @XML.nodes('/NotesXML/Row') as Data(X)  
   WHERE X.value('@Action','NVARCHAR(10)')='NEW'  
  
   --If Action is MODIFY then update Notes  
   UPDATE COM_Notes  
   SET Note=Replace(X.value('@Note','NVARCHAR(MAX)'),'@~','
'),      GUID=newid(),  
    ModifiedBy=@UserName,  
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
   X.value('@FileExtension','NVARCHAR(50)'),X.value('@FileDescription','NVARCHAR(500)'),X.value('@IsProductImage','bit'),80,80,@ResourceID,  
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
  
  COMMIT TRANSACTION    
--SELECT * FROM [ACC_Accounts] WITH(nolock) WHERE AccountID=@AccountID  
SELECT ErrorMessage,ErrorNumber FROM COM_ErrorMessages WITH(nolock)   
WHERE ErrorNumber=100 AND LanguageID=@LangID  
SET NOCOUNT OFF;    
RETURN @ResourceID    
END TRY    
BEGIN CATCH    
-- Return exception info [Message,Number,ProcedureName,LineNumber]    
 IF ERROR_NUMBER()=50000  
 BEGIN  
 -- SELECT * FROM [ACC_Accounts] WITH(nolock) WHERE AccountID=@AccountID    
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
 SET NOCOUNT OFF    
 RETURN -999     
END CATCH  
   
  
GO

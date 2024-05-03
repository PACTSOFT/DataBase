USE PACT2C222
GO
SET ANSI_NULLS, QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spCRM_SetCampaign]
	@CampaignID [bigint],
	@CampaignCode [nvarchar](200),
	@CampaignName [nvarchar](500),
	@TypeID [int],
	@Venue [int],
	@StatusID [int],
	@VendorID [int] = 0,
	@SelectedNodeID [bigint],
	@ExpectedResponce [nvarchar](500) = null,
	@Offer [nvarchar](500) = null,
	@ProcuctXML [nvarchar](max) = null,
	@ResponseXML [nvarchar](max) = null,
	@CActivityXML [nvarchar](max) = null,
	@DemoKitXML [nvarchar](max) = null,
	@OrganizationXML [nvarchar](max) = null,
	@STAFFXML [nvarchar](max) = null,
	@ApprovalsXML [nvarchar](max) = null,
	@CustomCostCenterFieldsQuery [nvarchar](max) = null,
	@CustomFieldsQuery [nvarchar](max) = null,
	@TabDetails [nvarchar](max) = null,
	@IsGroup [bit],
	@Description [nvarchar](500) = null,
	@NotesXML [nvarchar](max) = NULL,
	@AttachmentsXML [nvarchar](max) = NULL,
	@SpeakersXML [nvarchar](max) = NULL,
	@ActivityXml [nvarchar](max) = null,
	@InvitesXML [nvarchar](max) = null,
	@EventsXml [nvarchar](max) = null,
	@CompanyGUID [varchar](50),
	@UserName [nvarchar](50),
	@RoleID [int] = 0,
	@LangID [int] = 1,
	@CodePrefix [nvarchar](200) = NULL,
	@CodeNumber [bigint] = 0,
	@IsCode [bit] = 0
WITH ENCRYPTION, EXECUTE AS CALLER
AS
BEGIN TRANSACTION    
BEGIN TRY    
SET NOCOUNT ON;  
  --Declaration Section  
  
  DECLARE @Dt float,@XML xml,@TempGuid nvarchar(50),@HasAccess bit,@IsDuplicateNameAllowed bit,@IsCodeAutoGen bit  
  DECLARE @UpdateSql nvarchar(max),@ParentCode nvarchar(200),@CCCCCData XML,@IsIgnoreSpace bit  
  DECLARE @lft bigint,@rgt bigint,@Selectedlft bigint,@Selectedrgt bigint,@Depth int,@ParentID bigint  
  DECLARE @SelectedIsGroup bit,@ResXML XML,@ActXML XML
    
  --User acces check FOR Campaign  
  IF @CampaignID=0  
  BEGIN  
   SET @HasAccess=dbo.fnCOM_HasAccess(@RoleID,88,1)  
  END  
  ELSE  
  BEGIN  
   SET @HasAccess=dbo.fnCOM_HasAccess(@RoleID,88,3)  
  END  
  
       --User acces check FOR Notes  
  IF (@NotesXML IS NOT NULL AND @NotesXML <> '')  
  BEGIN  
   SET @HasAccess=dbo.fnCOM_HasAccess(@RoleID,88,8)  
  
   IF @HasAccess=0  
   BEGIN  
    RAISERROR('-105',16,1)  
   END  
  END  
  
  --User acces check FOR Attachments  
  IF (@AttachmentsXML IS NOT NULL AND @AttachmentsXML <> '')  
  BEGIN  
   SET @HasAccess=dbo.fnCOM_HasAccess(@RoleID,88,12)  
  
   IF @HasAccess=0  
   BEGIN  
    RAISERROR('-105',16,1)  
   END  
  END  
 
 
--SELECT 'EFGH'
  IF EXISTS(SELECT StatusID FROM dbo.COM_Status  WHERE CostCenterID=88 AND Status='Active' AND StatusID=@StatusID )  
  BEGIN  
   SET @HasAccess=dbo.fnCOM_HasAccess(@RoleID,88,23)  
  
   IF @HasAccess=0  
   BEGIN  
    RAISERROR('-111',16,1)  
   END  
  END  
  
  IF EXISTS(SELECT StatusID FROM dbo.COM_Status  
  WHERE CostCenterID=88 AND Status='In Active' AND StatusID=@StatusID )  
  BEGIN  
   SET @HasAccess=dbo.fnCOM_HasAccess(@RoleID,88,24)  
  
   IF @HasAccess=0  
   BEGIN  
    RAISERROR('-113',16,1)  
   END  
  END  

  --GETTING PREFERENCE  
  SELECT @IsDuplicateNameAllowed=Value FROM COM_CostCenterPreferences WITH(nolock) WHERE COSTCENTERID=88 and  [Name]='DuplicateNameAllowed'  
  SELECT @IsCodeAutoGen=Value FROM COM_CostCenterPreferences  WITH(nolock) WHERE COSTCENTERID=88 and  [Name]='CodeAutoGen'  
  SELECT @IsIgnoreSpace=Value FROM COM_CostCenterPreferences  WITH(nolock) WHERE COSTCENTERID=88 and  [Name]='IgnoreSpaces'  
 SELECT @IsCode, @IsCodeAutoGen, @CampaignID,@CodePrefix
   IF @IsCode=1 and @IsCodeAutoGen IS NOT NULL AND @IsCodeAutoGen=1 AND @CampaignID=0 and @CodePrefix=''  
	BEGIN 
		--CALL AUTOCODEGEN 
		create table #temp1(prefix nvarchar(100),number bigint, suffix nvarchar(100), code nvarchar(200), IsManualcode bit)
		if(@SelectedNodeID is null)
		insert into #temp1
		EXEC [spCOM_GetCodeData] 88,1,''  
		else
		insert into #temp1
		EXEC [spCOM_GetCodeData] 88,@SelectedNodeID,''  
		--select * from #temp1
		select @CampaignCode=code,@CodePrefix= prefix, @CodeNumber=number from #temp1
		--select @AccountCode,@ParentID
	END	
  --DUPLICATE CHECK  
  IF @IsDuplicateNameAllowed IS NOT NULL AND @IsDuplicateNameAllowed=0  
  BEGIN  
    IF @IsIgnoreSpace IS NOT NULL AND @IsIgnoreSpace=1  
   BEGIN  
    IF @CampaignID=0  
    BEGIN  
     IF EXISTS (SELECT CampaignID FROM CRM_Campaigns WITH(nolock) WHERE replace([Name],' ','')=replace(@CampaignName,' ',''))  
     BEGIN  
      RAISERROR('-108',16,1)  
     END  
    END  
    ELSE  
    BEGIN  
     IF EXISTS (SELECT CampaignID FROM CRM_Campaigns WITH(nolock) WHERE replace([Name],' ','')=replace(@CampaignName,' ','') AND CampaignID <> @CampaignID)  
     BEGIN  
      RAISERROR('-108',16,1)       
     END  
    END  
   END  
   ELSE  
   BEGIN  
    IF @CampaignID=0  
    BEGIN  
     IF EXISTS (SELECT CampaignID FROM CRM_Campaigns WITH(nolock) WHERE [Name]=@CampaignName)  
     BEGIN  
      RAISERROR('-108',16,1)  
     END  
    END  
    ELSE  
    BEGIN  
     IF EXISTS (SELECT CampaignID FROM CRM_Campaigns WITH(nolock) WHERE  Name =@CampaignName AND CampaignID <> @CampaignID)  
     BEGIN  
      RAISERROR('-108',16,1)  
     END  
    END  
   END
  END  
 

  SET @Dt=convert(float,getdate())--Setting Current Date  
 
  IF @CampaignID=0--------START INSERT RECORD-----------  
  BEGIN--CREATE ACCOUNT--  
    --To Set Left,Right And Depth of Record  
    SELECT @SelectedIsGroup=IsGroup,@Selectedlft =lft,@Selectedrgt=rgt,@ParentID=ParentID,@Depth=Depth  
    from [CRM_Campaigns] with(NOLOCK) where CampaignID=@SelectedNodeID  
   
    --IF No Record Selected or Record Doesn't Exist  
    if(@SelectedIsGroup is null)   
     select @SelectedNodeID=CampaignID,@SelectedIsGroup=IsGroup,@Selectedlft =lft,@Selectedrgt=rgt,@ParentID=ParentID,@Depth=Depth  
     from [CRM_Campaigns] with(NOLOCK) where ParentID =0  
         
    if(@SelectedIsGroup = 1)--Adding Node Under the Group  
     BEGIN  
      UPDATE CRM_Campaigns SET rgt = rgt + 2 WHERE rgt > @Selectedlft;  
      UPDATE CRM_Campaigns SET lft = lft + 2 WHERE lft > @Selectedlft;  
      set @lft =  @Selectedlft + 1  
      set @rgt = @Selectedlft + 2  
      set @ParentID = @SelectedNodeID  
      set @Depth = @Depth + 1  
     END  
    else if(@SelectedIsGroup = 0)--Adding Node at Same level  
     BEGIN  
      UPDATE CRM_Campaigns SET rgt = rgt + 2 WHERE rgt > @Selectedrgt;  
      UPDATE CRM_Campaigns SET lft = lft + 2 WHERE lft > @Selectedrgt;  
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
    --IF @IsCodeAutoGen IS NOT NULL AND @IsCodeAutoGen=1 AND @CampaignID=0  
    --BEGIN  
    -- SELECT @ParentCode=[Code]  
    -- FROM [CRM_Campaigns] WITH(NOLOCK) WHERE CampaignID=@ParentID    
  
    -- --CALL AUTOCODEGEN  
    -- EXEC [spCOM_SetCode] 88,@ParentCode,@CampaignCode OUTPUT    
    --END  
  
  
			-- Insert statements for procedure here  
			INSERT INTO CRM_Campaigns  
				(CodePrefix,CodeNumber,Code,
			   [Name] ,   
			   [StatusID],
			   [CampaignTypeLookupID],
			   [ExpectedResponse],
			   [Offer], 
			   [VendorLookupID],  
			   [Description], 
			   [Depth],  
			   [ParentID],  
			   [lft],  
			   [rgt],  
			   [IsGroup],  
			   [CompanyGUID],
			   [GUID],
			   [CreatedBy],  
			   [CreatedDate],
			   Venue)
		   VALUES  
		    (@CodePrefix,@CodeNumber,@CampaignCode,--			   (@CampaignCode,  
			   @CampaignName,  
			   @StatusID,  
			   @TypeID,  
			   @ExpectedResponce,
			   @Offer, 
			   @VendorID,
			   @Description,  
			   @Depth,  
			   @ParentID,  
			   @lft,  
			   @rgt,  
			   @IsGroup,  
			   @CompanyGUID,
			   newid(),  
			   @UserName,  
			   @Dt,
			   @Venue)  

    --To get inserted record primary key  
    SET @CampaignID=SCOPE_IDENTITY()  
   
    --Handling of Extended Table  
    INSERT INTO [CRM_CampaignsExtended]([CampaignID],[CreatedBy],[CreatedDate])  
    VALUES(@CampaignID, @UserName, @Dt)  


  
      DELETE FROM  COM_CCCCDATA WHERE NodeID=@CampaignID AND  CostCenterID = 88
	--Handling of CostCenter Costcenters Extrafields Table  

		 	INSERT INTO COM_CCCCData ([NodeID],CostCenterID, [CreatedBy],[CreatedDate], [CompanyGUID],[GUID])
			 VALUES(@CampaignID,88, @UserName, @Dt, @CompanyGUID,newid())
			 
	   IF exists(select * from  dbo.ADM_FeatureActionrolemap with(nolock) where RoleID=@RoleID and FeatureActionID=4841)
		BEGIN  
		 	UPDATE CRM_Campaigns SET IsApproved=1, ApprovedDate=CONVERT(float,getdate()),ApprovedBy=@UserName
		 	 where [CampaignID]=@CampaignID 
		end
      
   END--------END INSERT RECORD-----------  
  ELSE--------START UPDATE RECORD-----------  
  BEGIN   
  
   IF EXISTS(SELECT CampaignID FROM CRM_Campaigns WHERE CampaignID=@CampaignID AND ParentID=0)  
   BEGIN  
    RAISERROR('-123',16,1)  
   END  
      
   SELECT @TempGuid=[GUID] from [CRM_Campaigns]  WITH(NOLOCK)   
   WHERE CampaignID=@CampaignID  
  
--   IF(@TempGuid!=@Guid)--IF RECORD ALREADY UPDATED BY SOME OTHER USER i.e DIRTY READ    
  -- BEGIN    
 --      RAISERROR('-101',16,1)   
  -- END    
--   ELSE    
   BEGIN   
 
   --Insert into Account history  Extended  
   --insert into CRM_CampaignsExtended 
   --select * from [CRM_CampaignsExtended] WHERE CampaignID=@CampaignID      
  
  
   --Handling of CostCenter Costcenters Extrafields Table  
   --INSERT INTO ACC_AccountCostCenterMap ([CampaignID],[CreatedBy],[CreatedDate], [CompanyGUID],[GUID])  
   --VALUES(@CampaignID, @UserName, @Dt, @CompanyGUID,newid())  
   
    UPDATE CRM_Campaigns  
    SET [Code] = @CampaignCode  
       ,[Name] = @CampaignName  
	   ,[StatusID] = @StatusID  
       ,[CampaignTypeLookupID] = @TypeID  
       ,[Venue] = @Venue
       ,[IsGroup] = @IsGroup  
       ,[ExpectedResponse]=@ExpectedResponce
	   ,[Offer]=@Offer 
	   ,[VendorLookupID]=@VendorID
	   ,[CompanyGUID]=@CompanyGUID
	   ,[GUID] =  newid()  
	   ,[Description] = @Description
	   ,[ModifiedBy] = @UserName  
       ,[ModifiedDate] = @Dt
    WHERE CampaignID=@CampaignID   
       

   END
   
   --Update CostCenter Extra Fields
		
 
 END
 
 set @UpdateSql='update COM_CCCCDATA 
		SET '+@CustomCostCenterFieldsQuery+' [ModifiedBy] ='''+ @UserName+''',[ModifiedDate] =' + convert(nvarchar,@Dt) +' WHERE NodeID = '+convert(nvarchar,@CampaignID)+ ' AND CostCenterID = 88 ' 
	
		exec(@UpdateSql)
		
 if(@TabDetails is not null and @TabDetails <>'')
   begin 
  SET @UpdateSql=' UPDATE CRM_Campaigns SET '+@TabDetails+' WHERE CampaignID = '+CONVERT(nvarchar,@CampaignID)

  exec(@UpdateSql)
  
   end
   
   		--Update Extra fields
		set @UpdateSql='update [CRM_CampaignsExtended]
		SET '+@CustomFieldsQuery+'[ModifiedBy] ='''+ @UserName
		  +''',[ModifiedDate] =' + convert(nvarchar,@Dt) +' WHERE CampaignID ='+convert(nvarchar,@CampaignID)
	
		exec(@UpdateSql)
   
   --SETTING CODE EQUALS CampaignID IF EMPTY  
 
  IF(@CampaignCode IS NULL OR @CampaignCode='')  
  BEGIN  
   UPDATE  CRM_Campaigns  
   SET [Code] = @CampaignID  
   WHERE CampaignID=@CampaignID   
   END
   
   
 	
			----If Action is MODIFY then update campaignproducts
			--UPDATE CRM_CampaignProducts
			--SET ProductID=X.value('@ProductID','INT'),
			--	UOMID=X.value('@UOMID','INT'),
			--	UnitPrice=X.value('@Price','FLOAT'),
			--	GUID=newid(),
			--	ModifiedBy=@UserName,
			--	ModifiedDate=@Dt
			--FROM CRM_CampaignProducts C 
			--INNER JOIN @XML.nodes('/XML/Row') as Data(X) 	
			--ON convert(bigint,X.value('@VendorID','bigint'))=C.CampaignProdID
			--WHERE X.value('@Action','NVARCHAR(500)')='UPDATE'

			--If Action is DELETE then delete campaignproducts
			--DELETE FROM CRM_CampaignProducts
			--WHERE CampaignProdID IN(SELECT X.value('@ProductID','bigint')
			--	FROM @XML.nodes('/ProcuctXML/Row') as Data(X)
			--	WHERE X.value('@Action','NVARCHAR(10)')='DELETE')
	
			--Inserts Multiple Notes  
  IF (@NotesXML IS NOT NULL AND @NotesXML <> '')  
  BEGIN  
   SET @XML=@NotesXML  
  
   --If Action is NEW then insert new Notes  
   INSERT INTO COM_Notes(FeatureID,CostCenterID,FeaturePK,Note,     
   GUID,CreatedBy,CreatedDate)  
   SELECT 88,88,@CampaignID,Replace(X.value('@Note','NVARCHAR(max)'),'@~','
'),  
   newid(),@UserName,@Dt  
   FROM @XML.nodes('/NotesXML/Row') as Data(X)  
   WHERE X.value('@Action','NVARCHAR(10)')='NEW'  
  
   --If Action is MODIFY then update Notes  
   UPDATE COM_Notes  
   SET Note=Replace(X.value('@Note','NVARCHAR(max)'),'@~','
'),   
    GUID=newid(),  
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
   X.value('@FileExtension','NVARCHAR(50)'),X.value('@FileDescription','NVARCHAR(500)'),X.value('@IsProductImage','bit'),88,88,@CampaignID,  
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

		 if(@ResponseXML is not null and @ResponseXML <> '')
		 begin
		 
		 	set @ResXML=@ResponseXML
		 	
			INSERT into CRM_CAMPAIGNRESPONSE(CampaignID,CampaignActivityID,ProductID,
			CampgnRespLookupID,ReceivedDate,[Description],CustomerID,CompanyName,ContactName,
			Phone,Email,Fax,ChannelLookupID,VendorLookupID,
			CompanyGUID,GUID,CreatedBy,CreatedDate,
			[FirstName],[MiddleName],[LastName],[JobTitle],[Department],[Address1],[Address2],[Address3],[City],[State]
			,[Zip],[Country],[Phone2],[Email2],[URL],[Alpha1],[Alpha2],[Alpha3],[Alpha4],[Alpha5],[Alpha6],[Alpha7]
			,[Alpha8],[Alpha9],[Alpha10],[Alpha11],[Alpha12],[Alpha13],[Alpha14],[Alpha15],[Alpha16],[Alpha17],[Alpha18]
			,[Alpha19],[Alpha20],[Alpha21],[Alpha22],[Alpha23],[Alpha24],[Alpha25],[Alpha26],[Alpha27],[Alpha28],[Alpha29]
			,[Alpha30],[Alpha31],[Alpha32],[Alpha33],[Alpha34],[Alpha35],[Alpha36],[Alpha37],[Alpha38],[Alpha39],[Alpha40]
			,[Alpha41],[Alpha42],[Alpha43],[Alpha44],[Alpha45],[Alpha46],[Alpha47],[Alpha48],[Alpha49],[Alpha50]
			,[CCNID1],[CCNID2],[CCNID3],[CCNID4],[CCNID5],[CCNID6],[CCNID7],[CCNID8],[CCNID9],[CCNID10],[CCNID11]
			,[CCNID12],[CCNID13],[CCNID14],[CCNID15],[CCNID16],[CCNID17],[CCNID18],[CCNID19],[CCNID20]
			,[CCNID21],[CCNID22],[CCNID23],[CCNID24],[CCNID25],[CCNID26],[CCNID27],[CCNID28],[CCNID29],[CCNID30]
			,[CCNID31],[CCNID32],[CCNID33],[CCNID34],[CCNID35],[CCNID36],[CCNID37],[CCNID38],[CCNID39],[CCNID40]
			,[CCNID41],[CCNID42],[CCNID43],[CCNID44],[CCNID45],[CCNID46],[CCNID47],[CCNID48],[CCNID49],[CCNID50])
			select @CampaignID,1,1,
			x.value('@ResponseID','BIGINT'),
			CONVERT(float,x.value('@Date','DateTime')),
			x.value('@Description','nvarchar(500)'),
			x.value('@CustomerID','bigint'),
			x.value('@CompanyName','nvarchar(500)'),
			x.value('@ContactName','nvarchar(500)'),
			x.value('@Phone','nvarchar(50)'),
			x.value('@Email','nvarchar(50)'),
			x.value('@Fax','nvarchar(50)'),
			x.value('@ChannelID','bigint'),
			x.value('@VendorID','bigint'),
			@CompanyGUID,
			newid(),
			@UserName,
			convert(float,@Dt),
			x.value('@FirstName','nvarchar(200)'),x.value('@MiddleName','nvarchar(200)'),x.value('@LastName','nvarchar(200)'),
			x.value('@JobTitle','nvarchar(200)'),x.value('@Department','nvarchar(200)'),x.value('@Address1','nvarchar(200)'),
			x.value('@Address2','nvarchar(200)'),x.value('@Address3','nvarchar(200)'),x.value('@City','nvarchar(200)'),x.value('@State','nvarchar(200)'),
			x.value('@Zip','nvarchar(200)'),x.value('@Country','nvarchar(200)'),x.value('@Phone2','nvarchar(200)'),x.value('@Email2','nvarchar(200)'),
			x.value('@URL','nvarchar(200)'), 
			x.value('@Alpha1','nvarchar(200)'),x.value('@Alpha2','nvarchar(MAX)'),x.value('@Alpha3','nvarchar(MAX)'),x.value('@Alpha4','nvarchar(MAX)'),x.value('@Alpha5','nvarchar(MAX)'),
			x.value('@Alpha6','nvarchar(MAX)'),x.value('@Alpha7','nvarchar(MAX)'),x.value('@Alpha8','nvarchar(MAX)'),x.value('@Alpha9','nvarchar(MAX)'),x.value('@Alpha10','nvarchar(MAX)'),
			x.value('@Alpha11','nvarchar(MAX)'),x.value('@Alpha12','nvarchar(MAX)'),x.value('@Alpha13','nvarchar(MAX)'),x.value('@Alpha14','nvarchar(MAX)'),x.value('@Alpha15','nvarchar(MAX)'),
			x.value('@Alpha16','nvarchar(MAX)'),x.value('@Alpha17','nvarchar(MAX)'),x.value('@Alpha18','nvarchar(MAX)'),x.value('@Alpha19','nvarchar(MAX)'),x.value('@Alpha20','nvarchar(MAX)'),
			x.value('@Alpha21','nvarchar(MAX)'),x.value('@Alpha22','nvarchar(MAX)'),x.value('@Alpha23','nvarchar(MAX)'),x.value('@Alpha24','nvarchar(MAX)'),x.value('@Alpha25','nvarchar(MAX)'),
			x.value('@Alpha26','nvarchar(MAX)'),x.value('@Alpha27','nvarchar(MAX)'),x.value('@Alpha28','nvarchar(MAX)'),x.value('@Alpha29','nvarchar(MAX)'),x.value('@Alpha30','nvarchar(MAX)'),
			x.value('@Alpha31','nvarchar(MAX)'),x.value('@Alpha32','nvarchar(MAX)'),x.value('@Alpha33','nvarchar(MAX)'),x.value('@Alpha34','nvarchar(MAX)'),x.value('@Alpha35','nvarchar(MAX)'),
			x.value('@Alpha36','nvarchar(MAX)'),x.value('@Alpha37','nvarchar(MAX)'),x.value('@Alpha38','nvarchar(MAX)'),x.value('@Alpha39','nvarchar(MAX)'),x.value('@Alpha40','nvarchar(MAX)'),
			x.value('@Alpha41','nvarchar(MAX)'),x.value('@Alpha42','nvarchar(MAX)'),x.value('@Alpha43','nvarchar(MAX)'),x.value('@Alpha44','nvarchar(MAX)'),x.value('@Alpha45','nvarchar(MAX)'),
			x.value('@Alpha46','nvarchar(MAX)'),x.value('@Alpha47','nvarchar(MAX)'),x.value('@Alpha48','nvarchar(MAX)'),x.value('@Alpha49','nvarchar(MAX)'),x.value('@Alpha50','nvarchar(MAX)')
			,x.value('@CCNID1','bigint'),x.value('@CCNID2','Bigint'),x.value('@CCNID3','Bigint'),x.value('@CCNID4','Bigint'),x.value('@CCNID5','Bigint'),
			x.value('@CCNID6','Bigint'),x.value('@CCNID7','Bigint'),x.value('@CCNID8','Bigint'),x.value('@CCNID9','Bigint'),x.value('@CCNID10','Bigint'),
			x.value('@CCNID11','Bigint'),x.value('@CCNID12','Bigint'),x.value('@CCNID13','Bigint'),x.value('@CCNID14','Bigint'),x.value('@CCNID15','Bigint'),
			x.value('@CCNID16','Bigint'),x.value('@CCNID17','Bigint'),x.value('@CCNID18','Bigint'),x.value('@CCNID19','Bigint'),x.value('@CCNID20','Bigint'),
			x.value('@CCNID21','Bigint'),x.value('@CCNID22','Bigint'),x.value('@CCNID23','Bigint'),x.value('@CCNID24','Bigint'),x.value('@CCNID25','Bigint'),
			x.value('@CCNID26','Bigint'),x.value('@CCNID27','Bigint'),x.value('@CCNID28','Bigint'),x.value('@CCNID29','Bigint'),x.value('@CCNID30','Bigint'),
			x.value('@CCNID31','Bigint'),x.value('@CCNID32','Bigint'),x.value('@CCNID33','Bigint'),x.value('@CCNID34','Bigint'),x.value('@CCNID35','Bigint'),
			x.value('@CCNID36','Bigint'),x.value('@CCNID37','Bigint'),x.value('@CCNID38','Bigint'),x.value('@CCNID39','Bigint'),x.value('@CCNID40','Bigint'),
			x.value('@CCNID41','Bigint'),x.value('@CCNID42','Bigint'),x.value('@CCNID43','Bigint'),x.value('@CCNID44','Bigint'),x.value('@CCNID45','Bigint'),
			x.value('@CCNID46','Bigint'),x.value('@CCNID47','Bigint'),x.value('@CCNID48','Bigint'),x.value('@CCNID49','Bigint'),x.value('@CCNID50','Bigint')
			   from @ResXML.nodes('XML/Row') as data(x)
			WHERE X.value('@Action','NVARCHAR(10)')='NEW'  
	    
   --If Action is MODIFY then update Notes  
			UPDATE CRM_CAMPAIGNRESPONSE  SET
			CampgnRespLookupID=x.value('@ResponseID','BIGINT'),ReceivedDate=CONVERT(float,x.value('@Date','DateTime')),[Description]=x.value('@Description','nvarchar(500)')
			,CustomerID=x.value('@CustomerID','bigint'),CompanyName=x.value('@CompanyName','nvarchar(500)'),ContactName=x.value('@ContactName','nvarchar(500)'),
			Phone=	x.value('@Phone','nvarchar(50)'),Email=	x.value('@Email','nvarchar(50)'),Fax=x.value('@Fax','nvarchar(50)'),ChannelLookupID=x.value('@ChannelID','bigint'),VendorLookupID=			x.value('@VendorID','bigint'),
			[FirstName]=x.value('@FirstName','nvarchar(200)'),[MiddleName]=x.value('@MiddleName','nvarchar(200)'),[LastName]=x.value('@LastName','nvarchar(200)'),[JobTitle]=x.value('@JobTitle','nvarchar(200)')
			,[Department]=x.value('@Department','nvarchar(200)'),[Address1]=x.value('@Address1','nvarchar(200)'),[Address2]=x.value('@Address2','nvarchar(200)'),[Address3]=x.value('@Address3','nvarchar(200)'),[City]=x.value('@City','nvarchar(200)')
			,[State]=x.value('@State','nvarchar(200)')
			,[Zip]=x.value('@Zip','nvarchar(200)'),[Country]=x.value('@Country','nvarchar(200)'),[Phone2]=x.value('@Phone2','nvarchar(200)'),[Email2]=x.value('@Email2','nvarchar(200)'),[URL]=x.value('@URL','nvarchar(200)')
			,[Alpha1]=x.value('@Alpha1','nvarchar(200)'),[Alpha2]=x.value('@Alpha2','nvarchar(200)'),[Alpha3]=x.value('@Alpha3','nvarchar(200)'),[Alpha4]=x.value('@Alpha4','nvarchar(200)'),[Alpha5]=x.value('@Alpha5','nvarchar(200)'),[Alpha6]=x.value('@Alpha6','nvarchar(200)'),[Alpha7]=x.value('@Alpha7','nvarchar(200)')
			,[Alpha8]=x.value('@Alpha8','nvarchar(200)'),[Alpha9]=x.value('@Alpha9','nvarchar(200)'),[Alpha10]=x.value('@Alpha10','nvarchar(200)'),[Alpha11]=x.value('@Alpha11','nvarchar(200)'),[Alpha12]=x.value('@Alpha12','nvarchar(200)'),[Alpha13]=x.value('@Alpha13','nvarchar(200)'),[Alpha14]=x.value('@Alpha14','nvarchar(200)'),[Alpha15]=x.value('@Alpha15','nvarchar(200)'),[Alpha16]=x.value('@Alpha16','nvarchar(200)'),[Alpha17]=x.value('@Alpha17','nvarchar(200)'),[Alpha18]=x.value('@Alpha18','nvarchar(200)')
			,[Alpha19]=x.value('@Alpha19','nvarchar(200)'),[Alpha20]=x.value('@Alpha20','nvarchar(200)'),[Alpha21]=x.value('@Alpha21','nvarchar(200)'),[Alpha22]=x.value('@Alpha22','nvarchar(200)'),[Alpha23]=x.value('@Alpha23','nvarchar(200)'),[Alpha24]=x.value('@Alpha24','nvarchar(200)'),[Alpha25]=x.value('@Alpha25','nvarchar(200)'),[Alpha26]=x.value('@Alpha26','nvarchar(200)'),[Alpha27]=x.value('@Alpha27','nvarchar(200)'),[Alpha28]=x.value('@Alpha28','nvarchar(200)'),[Alpha29]=x.value('@Alpha29','nvarchar(200)')
			,[Alpha30]=x.value('@Alpha30','nvarchar(200)'),[Alpha31]=x.value('@Alpha31','nvarchar(200)'),[Alpha32]=x.value('@Alpha32','nvarchar(200)'),[Alpha33]=x.value('@Alpha33','nvarchar(200)'),[Alpha34]=x.value('@Alpha34','nvarchar(200)'),[Alpha35]=x.value('@Alpha35','nvarchar(200)'),[Alpha36]=x.value('@Alpha36','nvarchar(200)'),[Alpha37]=x.value('@Alpha37','nvarchar(200)'),[Alpha38]=x.value('@Alpha38','nvarchar(200)'),[Alpha39]=x.value('@Alpha39','nvarchar(200)'),[Alpha40]=x.value('@Alpha40','nvarchar(200)')
			,[Alpha41]=x.value('@Alpha41','nvarchar(200)'),[Alpha42]=x.value('@Alpha42','nvarchar(200)'),[Alpha43]=x.value('@Alpha43','nvarchar(200)'),[Alpha44]=x.value('@Alpha44','nvarchar(200)'),[Alpha45]=x.value('@Alpha45','nvarchar(200)'),[Alpha46]=x.value('@Alpha46','nvarchar(200)'),[Alpha47]=x.value('@Alpha47','nvarchar(200)'),[Alpha48]=x.value('@Alpha48','nvarchar(200)'),[Alpha49]=x.value('@Alpha49','nvarchar(200)'),[Alpha50]=x.value('@Alpha50','nvarchar(200)')
			,[CCNID1]=x.value('@CCNID1','Bigint'),[CCNID2]=x.value('@CCNID2','Bigint'),[CCNID3]=x.value('@CCNID3','Bigint'),[CCNID4]=x.value('@CCNID4','Bigint'),[CCNID5]=x.value('@CCNID5','Bigint'),[CCNID6]=x.value('@CCNID6','Bigint'),[CCNID7]=x.value('@CCNID7','Bigint')
			,[CCNID8]=x.value('@CCNID8','Bigint'),[CCNID9]=x.value('@CCNID9','Bigint'),[CCNID10]=x.value('@CCNID10','Bigint'),[CCNID11]=x.value('@CCNID11','Bigint'),[CCNID12]=x.value('@CCNID12','Bigint'),[CCNID13]=x.value('@CCNID13','Bigint'),[CCNID14]=x.value('@CCNID14','Bigint'),[CCNID15]=x.value('@CCNID15','Bigint'),[CCNID16]=x.value('@CCNID16','Bigint'),[CCNID17]=x.value('@CCNID17','Bigint'),[CCNID18]=x.value('@CCNID18','Bigint')
			,[CCNID19]=x.value('@CCNID19','Bigint'),[CCNID20]=x.value('@CCNID20','Bigint'),[CCNID21]=x.value('@CCNID21','Bigint'),[CCNID22]=x.value('@CCNID22','Bigint'),[CCNID23]=x.value('@CCNID23','Bigint'),[CCNID24]=x.value('@CCNID24','Bigint'),[CCNID25]=x.value('@CCNID25','Bigint'),[CCNID26]=x.value('@CCNID26','Bigint'),[CCNID27]=x.value('@CCNID27','Bigint'),[CCNID28]=x.value('@CCNID28','Bigint'),[CCNID29]=x.value('@CCNID29','Bigint')
			,[CCNID30]=x.value('@CCNID30','Bigint'),[CCNID31]=x.value('@CCNID31','Bigint'),[CCNID32]=x.value('@CCNID32','Bigint'),[CCNID33]=x.value('@CCNID33','Bigint'),[CCNID34]=x.value('@CCNID34','Bigint'),[CCNID35]=x.value('@CCNID35','Bigint'),[CCNID36]=x.value('@CCNID36','Bigint'),[CCNID37]=x.value('@CCNID37','Bigint'),[CCNID38]=x.value('@CCNID38','Bigint'),[CCNID39]=x.value('@CCNID39','Bigint'),[CCNID40]=x.value('@CCNID40','Bigint')
			,[CCNID41]=x.value('@CCNID41','Bigint'),[CCNID42]=x.value('@CCNID42','Bigint'),[CCNID43]=x.value('@CCNID43','Bigint'),[CCNID44]=x.value('@CCNID44','Bigint'),[CCNID45]=x.value('@CCNID45','Bigint'),[CCNID46]=x.value('@CCNID46','Bigint'),[CCNID47]=x.value('@CCNID47','Bigint'),[CCNID48]=x.value('@CCNID48','Bigint'),[CCNID49]=x.value('@CCNID49','Bigint'),[CCNID50]=x.value('@CCNID50','Bigint'),
			GUID=newid(),  
			ModifiedBy=@UserName,  
			ModifiedDate=@Dt  
			FROM CRM_CAMPAIGNRESPONSE C   
			INNER JOIN @ResXML.nodes('XML/Row') as Data(X)    
			ON convert(bigint,X.value('@CampaignResponseID','bigint'))=C.CampaignResponseID  
			WHERE X.value('@Action','NVARCHAR(500)')='MODIFY'  

			--If Action is DELETE then delete Notes  
			DELETE FROM CRM_CAMPAIGNRESPONSE  
			WHERE CampaignResponseID IN(SELECT X.value('@CampaignResponseID','bigint')  
			FROM @ResXML.nodes('XML/Row') as Data(X)  
			WHERE X.value('@Action','NVARCHAR(10)')='DELETE')   
				--Delete from CRM_CAMPAIGNRESPONSE where CampaignID = @CampaignID  
			
		end


		if(@CActivityXML is not null and @CActivityXML <> '')
	   begin
	   set @ActXML=@CActivityXML
				Delete from CRM_CAMPAIGNACTIVITIES where CampaignID = @CampaignID 

				INSERT into CRM_CAMPAIGNACTIVITIES(CampaignID,Name,StatusID,
				ChannelLookupID,VendorLookupID,TypeLookupID,PriorityTypeLookupID,Description,StartDate,
				EndDate,BudgetedAmount,ActualCost,CurrencyID,
				   CompanyGUID,GUID,CreatedBy,CreatedDate,CompletionRate,WorkingHrs, CheckList, CloseStatus, CloseDate,ClosedRemarks)
				   select @CampaignID,
			       x.value('@Name','nvarchar(500)'),x.value('@StatusID','int'),x.value('@ChannelID','BIGINT'),
				   x.value('@VendorID','BIGINT'),x.value('@TypeID','BIGINT'),x.value('@PriorityID','BIGINT'),
				   x.value('@Description','nvarchar(500)'),CONVERT(float,x.value('@StartDate','DateTime')),
				   CONVERT(float,x.value('@EndDate','DateTime')),CONVERT(float,x.value('@BudgetAmount','INT')),
				   CONVERT(float,x.value('@ActualCost','INT')),x.value('@CurencyID','BIGINT'),@CompanyGUID,
				   newid(),@UserName,convert(float,@Dt),x.value('@CompletionRate','float'),x.value('@WorkingHrs','float'),
				   x.value('@CheckList','nvarchar(max)'),x.value('@CloseStatus','bit'),CONVERT(float,isnull(x.value('@CloseDate','DateTime'),0)),
				   x.value('@ClosedRemarks','nvarchar(500)')
				   from @ActXML.nodes('XML/Row') as data(x)
			
		end
		if(@STAFFXML is not null and @STAFFXML <> '')
	   begin
			 set @ActXML=@STAFFXML
				Delete from CRM_CampaignStaff where CampaignID = @CampaignID 

				INSERT into CRM_CampaignStaff(CampaignID,CustomerName,CustomerID,ContactID,
				StaffInitial,StaffTitle,StaffName,JobTitle,[Type],  
				   CompanyGUID,GUID,CreatedBy,CreatedDate)
				   select @CampaignID, x.value('@Customer','nvarchar(500)'),
			       x.value('@CustomerID','nvarchar(500)'),
				   x.value('@ContactID','nvarchar(500)'),
			       x.value('@StaffInitial','nvarchar(500)'),
				   x.value('@StaffTitle','nvarchar(500)'),
				   x.value('@StaffName','nvarchar(500)'),
				   x.value('@JobTitle','nvarchar(500)'),
				   x.value('@Type','nvarchar(500)'), 
				   @CompanyGUID,
				   newid(),
				   @UserName,
				   convert(float,@Dt) 
				 
				   from @ActXML.nodes('XML/Row') as data(x)
			
		end
		
	if(@OrganizationXML is not null and @OrganizationXML <> '')
		BEGIN
		DECLARE @OrXML XML
		SET @OrXML=@OrganizationXML 
			Delete from CRM_CampaignOrganization where CampaignNodeID = @CampaignID and CCID=88 
			INSERT into CRM_CampaignOrganization
			select 88,@CampaignID,
			x.value('@Customer','nvarchar(300)'), x.value('@ContactName','nvarchar(300)'), x.value('@JobTitle','nvarchar(300)'), x.value('@Department','nvarchar(300)'), x.value('@Country','nvarchar(300)'), 
			x.value('@City','nvarchar(300)'), x.value('@CytomedDivision','nvarchar(300)'), x.value('@Territory','nvarchar(300)'),  @UserName,convert(float,@Dt),x.value('@Alpha1','nvarchar(200)'),x.value('@Alpha2','nvarchar(MAX)'),x.value('@Alpha3','nvarchar(MAX)'),x.value('@Alpha4','nvarchar(MAX)'),x.value('@Alpha5','nvarchar(MAX)'),
			x.value('@Alpha6','nvarchar(MAX)'),x.value('@Alpha7','nvarchar(MAX)'),x.value('@Alpha8','nvarchar(MAX)'),x.value('@Alpha9','nvarchar(MAX)'),x.value('@Alpha10','nvarchar(MAX)'),
			x.value('@Alpha11','nvarchar(MAX)'),x.value('@Alpha12','nvarchar(MAX)'),x.value('@Alpha13','nvarchar(MAX)'),x.value('@Alpha14','nvarchar(MAX)'),x.value('@Alpha15','nvarchar(MAX)'),
			x.value('@Alpha16','nvarchar(MAX)'),x.value('@Alpha17','nvarchar(MAX)'),x.value('@Alpha18','nvarchar(MAX)'),x.value('@Alpha19','nvarchar(MAX)'),x.value('@Alpha20','nvarchar(MAX)'),
			x.value('@Alpha21','nvarchar(MAX)'),x.value('@Alpha22','nvarchar(MAX)'),x.value('@Alpha23','nvarchar(MAX)'),x.value('@Alpha24','nvarchar(MAX)'),x.value('@Alpha25','nvarchar(MAX)'),
			x.value('@Alpha26','nvarchar(MAX)'),x.value('@Alpha27','nvarchar(MAX)'),x.value('@Alpha28','nvarchar(MAX)'),x.value('@Alpha29','nvarchar(MAX)'),x.value('@Alpha30','nvarchar(MAX)'),
			x.value('@Alpha31','nvarchar(MAX)'),x.value('@Alpha32','nvarchar(MAX)'),x.value('@Alpha33','nvarchar(MAX)'),x.value('@Alpha34','nvarchar(MAX)'),x.value('@Alpha35','nvarchar(MAX)'),
			x.value('@Alpha36','nvarchar(MAX)'),x.value('@Alpha37','nvarchar(MAX)'),x.value('@Alpha38','nvarchar(MAX)'),x.value('@Alpha39','nvarchar(MAX)'),x.value('@Alpha40','nvarchar(MAX)'),
			x.value('@Alpha41','nvarchar(MAX)'),x.value('@Alpha42','nvarchar(MAX)'),x.value('@Alpha43','nvarchar(MAX)'),x.value('@Alpha44','nvarchar(MAX)'),x.value('@Alpha45','nvarchar(MAX)'),
			x.value('@Alpha46','nvarchar(MAX)'),x.value('@Alpha47','nvarchar(MAX)'),x.value('@Alpha48','nvarchar(MAX)'),x.value('@Alpha49','nvarchar(MAX)'),x.value('@Alpha50','nvarchar(MAX)')
			,x.value('@CCNID1','bigint'),x.value('@CCNID2','Bigint'),x.value('@CCNID3','Bigint'),x.value('@CCNID4','Bigint'),x.value('@CCNID5','Bigint'),
			x.value('@CCNID6','Bigint'),x.value('@CCNID7','Bigint'),x.value('@CCNID8','Bigint'),x.value('@CCNID9','Bigint'),x.value('@CCNID10','Bigint'),
			x.value('@CCNID11','Bigint'),x.value('@CCNID12','Bigint'),x.value('@CCNID13','Bigint'),x.value('@CCNID14','Bigint'),x.value('@CCNID15','Bigint'),
			x.value('@CCNID16','Bigint'),x.value('@CCNID17','Bigint'),x.value('@CCNID18','Bigint'),x.value('@CCNID19','Bigint'),x.value('@CCNID20','Bigint'),
			x.value('@CCNID21','Bigint'),x.value('@CCNID22','Bigint'),x.value('@CCNID23','Bigint'),x.value('@CCNID24','Bigint'),x.value('@CCNID25','Bigint'),
			x.value('@CCNID26','Bigint'),x.value('@CCNID27','Bigint'),x.value('@CCNID28','Bigint'),x.value('@CCNID29','Bigint'),x.value('@CCNID30','Bigint'),
			x.value('@CCNID31','Bigint'),x.value('@CCNID32','Bigint'),x.value('@CCNID33','Bigint'),x.value('@CCNID34','Bigint'),x.value('@CCNID35','Bigint'),
			x.value('@CCNID36','Bigint'),x.value('@CCNID37','Bigint'),x.value('@CCNID38','Bigint'),x.value('@CCNID39','Bigint'),x.value('@CCNID40','Bigint'),
			x.value('@CCNID41','Bigint'),x.value('@CCNID42','Bigint'),x.value('@CCNID43','Bigint'),x.value('@CCNID44','Bigint'),x.value('@CCNID45','Bigint'),
			x.value('@CCNID46','Bigint'),x.value('@CCNID47','Bigint'),x.value('@CCNID48','Bigint'),x.value('@CCNID49','Bigint'),x.value('@CCNID50','Bigint')
			,x.value('@ContactID','nvarchar(300)'), x.value('@CustomerID','nvarchar(300)'),x.value('@Salutation','Bigint') 
			from @OrXML.nodes('XML/Row') as data(x) 
		END

		if(@DemoKitXML is not null and @DemoKitXML <> '')
		BEGIN
		DECLARE @DemoKit XML
		SET @DemoKit=@DemoKitXML 
			Delete from CRM_CampaignDemoKit where CampaignNodeID = @CampaignID and CCID=88 
			INSERT into CRM_CampaignDemoKit
			select 88,@CampaignID,
			convert(float,x.value('@Date','datetime')),  @UserName,convert(float,@Dt),x.value('@Alpha1','nvarchar(200)'),x.value('@Alpha2','nvarchar(MAX)'),x.value('@Alpha3','nvarchar(MAX)'),x.value('@Alpha4','nvarchar(MAX)'),x.value('@Alpha5','nvarchar(MAX)'),
			x.value('@Alpha6','nvarchar(MAX)'),x.value('@Alpha7','nvarchar(MAX)'),x.value('@Alpha8','nvarchar(MAX)'),x.value('@Alpha9','nvarchar(MAX)'),x.value('@Alpha10','nvarchar(MAX)'),
			x.value('@Alpha11','nvarchar(MAX)'),x.value('@Alpha12','nvarchar(MAX)'),x.value('@Alpha13','nvarchar(MAX)'),x.value('@Alpha14','nvarchar(MAX)'),x.value('@Alpha15','nvarchar(MAX)'),
			x.value('@Alpha16','nvarchar(MAX)'),x.value('@Alpha17','nvarchar(MAX)'),x.value('@Alpha18','nvarchar(MAX)'),x.value('@Alpha19','nvarchar(MAX)'),x.value('@Alpha20','nvarchar(MAX)'),
			x.value('@Alpha21','nvarchar(MAX)'),x.value('@Alpha22','nvarchar(MAX)'),x.value('@Alpha23','nvarchar(MAX)'),x.value('@Alpha24','nvarchar(MAX)'),x.value('@Alpha25','nvarchar(MAX)'),
			x.value('@Alpha26','nvarchar(MAX)'),x.value('@Alpha27','nvarchar(MAX)'),x.value('@Alpha28','nvarchar(MAX)'),x.value('@Alpha29','nvarchar(MAX)'),x.value('@Alpha30','nvarchar(MAX)'),
			x.value('@Alpha31','nvarchar(MAX)'),x.value('@Alpha32','nvarchar(MAX)'),x.value('@Alpha33','nvarchar(MAX)'),x.value('@Alpha34','nvarchar(MAX)'),x.value('@Alpha35','nvarchar(MAX)'),
			x.value('@Alpha36','nvarchar(MAX)'),x.value('@Alpha37','nvarchar(MAX)'),x.value('@Alpha38','nvarchar(MAX)'),x.value('@Alpha39','nvarchar(MAX)'),x.value('@Alpha40','nvarchar(MAX)'),
			x.value('@Alpha41','nvarchar(MAX)'),x.value('@Alpha42','nvarchar(MAX)'),x.value('@Alpha43','nvarchar(MAX)'),x.value('@Alpha44','nvarchar(MAX)'),x.value('@Alpha45','nvarchar(MAX)'),
			x.value('@Alpha46','nvarchar(MAX)'),x.value('@Alpha47','nvarchar(MAX)'),x.value('@Alpha48','nvarchar(MAX)'),x.value('@Alpha49','nvarchar(MAX)'),x.value('@Alpha50','nvarchar(MAX)')
			,x.value('@CCNID1','bigint'),x.value('@CCNID2','Bigint'),x.value('@CCNID3','Bigint'),x.value('@CCNID4','Bigint'),x.value('@CCNID5','Bigint'),
			x.value('@CCNID6','Bigint'),x.value('@CCNID7','Bigint'),x.value('@CCNID8','Bigint'),x.value('@CCNID9','Bigint'),x.value('@CCNID10','Bigint'),
			x.value('@CCNID11','Bigint'),x.value('@CCNID12','Bigint'),x.value('@CCNID13','Bigint'),x.value('@CCNID14','Bigint'),x.value('@CCNID15','Bigint'),
			x.value('@CCNID16','Bigint'),x.value('@CCNID17','Bigint'),x.value('@CCNID18','Bigint'),x.value('@CCNID19','Bigint'),x.value('@CCNID20','Bigint'),
			x.value('@CCNID21','Bigint'),x.value('@CCNID22','Bigint'),x.value('@CCNID23','Bigint'),x.value('@CCNID24','Bigint'),x.value('@CCNID25','Bigint'),
			x.value('@CCNID26','Bigint'),x.value('@CCNID27','Bigint'),x.value('@CCNID28','Bigint'),x.value('@CCNID29','Bigint'),x.value('@CCNID30','Bigint'),
			x.value('@CCNID31','Bigint'),x.value('@CCNID32','Bigint'),x.value('@CCNID33','Bigint'),x.value('@CCNID34','Bigint'),x.value('@CCNID35','Bigint'),
			x.value('@CCNID36','Bigint'),x.value('@CCNID37','Bigint'),x.value('@CCNID38','Bigint'),x.value('@CCNID39','Bigint'),x.value('@CCNID40','Bigint'),
			x.value('@CCNID41','Bigint'),x.value('@CCNID42','Bigint'),x.value('@CCNID43','Bigint'),x.value('@CCNID44','Bigint'),x.value('@CCNID45','Bigint'),
			x.value('@CCNID46','Bigint'),x.value('@CCNID47','Bigint'),x.value('@CCNID48','Bigint'),x.value('@CCNID49','Bigint'),x.value('@CCNID50','Bigint')
			,x.value('@ProductID','Bigint'), x.value('@Quantity','FLOAT'), x.value('@UnitPrice','FLOAT'), x.value('@Value','FLOAT')
			from @DemoKit.nodes('XML/Row') as data(x) 
		END
		if(@InvitesXML is not null and @InvitesXML <> '')
		BEGIN
		DECLARE  @Invites XML
		SET @Invites=@InvitesXML 
			--Delete from CRM_CampaignInvites where CampaignNodeID = @CampaignID and CCID=88 
			INSERT into CRM_CampaignInvites
			select 88,@CampaignID,
			x.value('@Customer','nvarchar(300)'), x.value('@ContactName','nvarchar(300)'), x.value('@JobTitle','nvarchar(300)'), x.value('@Department','nvarchar(300)'), x.value('@Country','nvarchar(300)'), 
			x.value('@City','nvarchar(300)'), x.value('@CytomedDivision','nvarchar(300)'), x.value('@Territory','nvarchar(300)'),  @UserName,convert(float,@Dt),x.value('@Alpha1','nvarchar(200)'),x.value('@Alpha2','nvarchar(MAX)'),x.value('@Alpha3','nvarchar(MAX)'),x.value('@Alpha4','nvarchar(MAX)'),x.value('@Alpha5','nvarchar(MAX)'),
			x.value('@Alpha6','nvarchar(MAX)'),x.value('@Alpha7','nvarchar(MAX)'),x.value('@Alpha8','nvarchar(MAX)'),x.value('@Alpha9','nvarchar(MAX)'),x.value('@Alpha10','nvarchar(MAX)'),
			x.value('@Alpha11','nvarchar(MAX)'),x.value('@Alpha12','nvarchar(MAX)'),x.value('@Alpha13','nvarchar(MAX)'),x.value('@Alpha14','nvarchar(MAX)'),x.value('@Alpha15','nvarchar(MAX)'),
			x.value('@Alpha16','nvarchar(MAX)'),x.value('@Alpha17','nvarchar(MAX)'),x.value('@Alpha18','nvarchar(MAX)'),x.value('@Alpha19','nvarchar(MAX)'),x.value('@Alpha20','nvarchar(MAX)'),
			x.value('@Alpha21','nvarchar(MAX)'),x.value('@Alpha22','nvarchar(MAX)'),x.value('@Alpha23','nvarchar(MAX)'),x.value('@Alpha24','nvarchar(MAX)'),x.value('@Alpha25','nvarchar(MAX)'),
			x.value('@Alpha26','nvarchar(MAX)'),x.value('@Alpha27','nvarchar(MAX)'),x.value('@Alpha28','nvarchar(MAX)'),x.value('@Alpha29','nvarchar(MAX)'),x.value('@Alpha30','nvarchar(MAX)'),
			x.value('@Alpha31','nvarchar(MAX)'),x.value('@Alpha32','nvarchar(MAX)'),x.value('@Alpha33','nvarchar(MAX)'),x.value('@Alpha34','nvarchar(MAX)'),x.value('@Alpha35','nvarchar(MAX)'),
			x.value('@Alpha36','nvarchar(MAX)'),x.value('@Alpha37','nvarchar(MAX)'),x.value('@Alpha38','nvarchar(MAX)'),x.value('@Alpha39','nvarchar(MAX)'),x.value('@Alpha40','nvarchar(MAX)'),
			x.value('@Alpha41','nvarchar(MAX)'),x.value('@Alpha42','nvarchar(MAX)'),x.value('@Alpha43','nvarchar(MAX)'),x.value('@Alpha44','nvarchar(MAX)'),x.value('@Alpha45','nvarchar(MAX)'),
			x.value('@Alpha46','nvarchar(MAX)'),x.value('@Alpha47','nvarchar(MAX)'),x.value('@Alpha48','nvarchar(MAX)'),x.value('@Alpha49','nvarchar(MAX)'),x.value('@Alpha50','nvarchar(MAX)')
			,x.value('@CCNID1','bigint'),x.value('@CCNID2','Bigint'),x.value('@CCNID3','Bigint'),x.value('@CCNID4','Bigint'),x.value('@CCNID5','Bigint'),
			x.value('@CCNID6','Bigint'),x.value('@CCNID7','Bigint'),x.value('@CCNID8','Bigint'),x.value('@CCNID9','Bigint'),x.value('@CCNID10','Bigint'),
			x.value('@CCNID11','Bigint'),x.value('@CCNID12','Bigint'),x.value('@CCNID13','Bigint'),x.value('@CCNID14','Bigint'),x.value('@CCNID15','Bigint'),
			x.value('@CCNID16','Bigint'),x.value('@CCNID17','Bigint'),x.value('@CCNID18','Bigint'),x.value('@CCNID19','Bigint'),x.value('@CCNID20','Bigint'),
			x.value('@CCNID21','Bigint'),x.value('@CCNID22','Bigint'),x.value('@CCNID23','Bigint'),x.value('@CCNID24','Bigint'),x.value('@CCNID25','Bigint'),
			x.value('@CCNID26','Bigint'),x.value('@CCNID27','Bigint'),x.value('@CCNID28','Bigint'),x.value('@CCNID29','Bigint'),x.value('@CCNID30','Bigint'),
			x.value('@CCNID31','Bigint'),x.value('@CCNID32','Bigint'),x.value('@CCNID33','Bigint'),x.value('@CCNID34','Bigint'),x.value('@CCNID35','Bigint'),
			x.value('@CCNID36','Bigint'),x.value('@CCNID37','Bigint'),x.value('@CCNID38','Bigint'),x.value('@CCNID39','Bigint'),x.value('@CCNID40','Bigint'),
			x.value('@CCNID41','Bigint'),x.value('@CCNID42','Bigint'),x.value('@CCNID43','Bigint'),x.value('@CCNID44','Bigint'),x.value('@CCNID45','Bigint'),
			x.value('@CCNID46','Bigint'),x.value('@CCNID47','Bigint'),x.value('@CCNID48','Bigint'),x.value('@CCNID49','Bigint'),x.value('@CCNID50','Bigint')
			,x.value('@ContactID','nvarchar(300)'), x.value('@CustomerID','nvarchar(300)'),x.value('@Salutation','Bigint'),0,0 
			from @Invites.nodes('XML/Row') as data(x) 
			WHERE X.value('@Action','NVARCHAR(10)')='NEW'   
	    
   --If Action is MODIFY then update Notes  
			UPDATE CRM_CampaignInvites  SET
			Customer=x.value('@Customer','nvarchar(300)'), ContactName=x.value('@ContactName','nvarchar(300)'), JobTitle=x.value('@JobTitle','nvarchar(300)'), Department=x.value('@Department','nvarchar(300)'), Country=x.value('@Country','nvarchar(300)'), 
			City=x.value('@City','nvarchar(300)'),CytomedDivision= x.value('@CytomedDivision','nvarchar(300)'), Territory=x.value('@Territory','nvarchar(300)'),  
			Salutation=x.value('@Salutation','BIGINT'),CustomerID=x.value('@CustomerID','nvarchar(300)'), ContactID=x.value('@ContactID','nvarchar(300)') 
			,[Alpha1]=x.value('@Alpha1','nvarchar(200)'),[Alpha2]=x.value('@Alpha2','nvarchar(200)'),[Alpha3]=x.value('@Alpha3','nvarchar(200)'),[Alpha4]=x.value('@Alpha4','nvarchar(200)'),[Alpha5]=x.value('@Alpha5','nvarchar(200)'),[Alpha6]=x.value('@Alpha6','nvarchar(200)'),[Alpha7]=x.value('@Alpha7','nvarchar(200)')
			,[Alpha8]=x.value('@Alpha8','nvarchar(200)'),[Alpha9]=x.value('@Alpha9','nvarchar(200)'),[Alpha10]=x.value('@Alpha10','nvarchar(200)'),[Alpha11]=x.value('@Alpha11','nvarchar(200)'),[Alpha12]=x.value('@Alpha12','nvarchar(200)'),[Alpha13]=x.value('@Alpha13','nvarchar(200)'),[Alpha14]=x.value('@Alpha14','nvarchar(200)'),[Alpha15]=x.value('@Alpha15','nvarchar(200)'),[Alpha16]=x.value('@Alpha16','nvarchar(200)'),[Alpha17]=x.value('@Alpha17','nvarchar(200)'),[Alpha18]=x.value('@Alpha18','nvarchar(200)')
			,[Alpha19]=x.value('@Alpha19','nvarchar(200)'),[Alpha20]=x.value('@Alpha20','nvarchar(200)'),[Alpha21]=x.value('@Alpha21','nvarchar(200)'),[Alpha22]=x.value('@Alpha22','nvarchar(200)'),[Alpha23]=x.value('@Alpha23','nvarchar(200)'),[Alpha24]=x.value('@Alpha24','nvarchar(200)'),[Alpha25]=x.value('@Alpha25','nvarchar(200)'),[Alpha26]=x.value('@Alpha26','nvarchar(200)'),[Alpha27]=x.value('@Alpha27','nvarchar(200)'),[Alpha28]=x.value('@Alpha28','nvarchar(200)'),[Alpha29]=x.value('@Alpha29','nvarchar(200)')
			,[Alpha30]=x.value('@Alpha30','nvarchar(200)'),[Alpha31]=x.value('@Alpha31','nvarchar(200)'),[Alpha32]=x.value('@Alpha32','nvarchar(200)'),[Alpha33]=x.value('@Alpha33','nvarchar(200)'),[Alpha34]=x.value('@Alpha34','nvarchar(200)'),[Alpha35]=x.value('@Alpha35','nvarchar(200)'),[Alpha36]=x.value('@Alpha36','nvarchar(200)'),[Alpha37]=x.value('@Alpha37','nvarchar(200)'),[Alpha38]=x.value('@Alpha38','nvarchar(200)'),[Alpha39]=x.value('@Alpha39','nvarchar(200)'),[Alpha40]=x.value('@Alpha40','nvarchar(200)')
			,[Alpha41]=x.value('@Alpha41','nvarchar(200)'),[Alpha42]=x.value('@Alpha42','nvarchar(200)'),[Alpha43]=x.value('@Alpha43','nvarchar(200)'),[Alpha44]=x.value('@Alpha44','nvarchar(200)'),[Alpha45]=x.value('@Alpha45','nvarchar(200)'),[Alpha46]=x.value('@Alpha46','nvarchar(200)'),[Alpha47]=x.value('@Alpha47','nvarchar(200)'),[Alpha48]=x.value('@Alpha48','nvarchar(200)'),[Alpha49]=x.value('@Alpha49','nvarchar(200)'),[Alpha50]=x.value('@Alpha50','nvarchar(200)')
			,[CCNID1]=x.value('@CCNID1','Bigint'),[CCNID2]=x.value('@CCNID2','Bigint'),[CCNID3]=x.value('@CCNID3','Bigint'),[CCNID4]=x.value('@CCNID4','Bigint'),[CCNID5]=x.value('@CCNID5','Bigint'),[CCNID6]=x.value('@CCNID6','Bigint'),[CCNID7]=x.value('@CCNID7','Bigint')
			,[CCNID8]=x.value('@CCNID8','Bigint'),[CCNID9]=x.value('@CCNID9','Bigint'),[CCNID10]=x.value('@CCNID10','Bigint'),[CCNID11]=x.value('@CCNID11','Bigint'),[CCNID12]=x.value('@CCNID12','Bigint'),[CCNID13]=x.value('@CCNID13','Bigint'),[CCNID14]=x.value('@CCNID14','Bigint'),[CCNID15]=x.value('@CCNID15','Bigint'),[CCNID16]=x.value('@CCNID16','Bigint'),[CCNID17]=x.value('@CCNID17','Bigint'),[CCNID18]=x.value('@CCNID18','Bigint')
			,[CCNID19]=x.value('@CCNID19','Bigint'),[CCNID20]=x.value('@CCNID20','Bigint'),[CCNID21]=x.value('@CCNID21','Bigint'),[CCNID22]=x.value('@CCNID22','Bigint'),[CCNID23]=x.value('@CCNID23','Bigint'),[CCNID24]=x.value('@CCNID24','Bigint'),[CCNID25]=x.value('@CCNID25','Bigint'),[CCNID26]=x.value('@CCNID26','Bigint'),[CCNID27]=x.value('@CCNID27','Bigint'),[CCNID28]=x.value('@CCNID28','Bigint'),[CCNID29]=x.value('@CCNID29','Bigint')
			,[CCNID30]=x.value('@CCNID30','Bigint'),[CCNID31]=x.value('@CCNID31','Bigint'),[CCNID32]=x.value('@CCNID32','Bigint'),[CCNID33]=x.value('@CCNID33','Bigint'),[CCNID34]=x.value('@CCNID34','Bigint'),[CCNID35]=x.value('@CCNID35','Bigint'),[CCNID36]=x.value('@CCNID36','Bigint'),[CCNID37]=x.value('@CCNID37','Bigint'),[CCNID38]=x.value('@CCNID38','Bigint'),[CCNID39]=x.value('@CCNID39','Bigint'),[CCNID40]=x.value('@CCNID40','Bigint')
			,[CCNID41]=x.value('@CCNID41','Bigint'),[CCNID42]=x.value('@CCNID42','Bigint'),[CCNID43]=x.value('@CCNID43','Bigint'),[CCNID44]=x.value('@CCNID44','Bigint'),[CCNID45]=x.value('@CCNID45','Bigint'),[CCNID46]=x.value('@CCNID46','Bigint'),[CCNID47]=x.value('@CCNID47','Bigint'),[CCNID48]=x.value('@CCNID48','Bigint'),[CCNID49]=x.value('@CCNID49','Bigint'),[CCNID50]=x.value('@CCNID50','Bigint')
		   FROM CRM_CampaignInvites C   
			INNER JOIN @Invites.nodes('XML/Row') as Data(X)    
			ON convert(bigint,X.value('@NodeID','bigint'))=C.NodeID  
			WHERE X.value('@Action','NVARCHAR(500)')='MODIFY'  

			--If Action is DELETE then delete Notes  
			DELETE FROM CRM_CampaignInvites  
			WHERE NodeID IN(SELECT X.value('@NodeID','bigint')  
			FROM @Invites.nodes('XML/Row') as Data(X)  
			WHERE X.value('@Action','NVARCHAR(10)')='DELETE')   
				--Delete from CRM_CAMPAIGNRESPONSE where CampaignID = @CampaignID  
			
			
			
			
			
		END
		if(@SpeakersXML is not null and @SpeakersXML <> '')
		BEGIN
		DECLARE  @Speakers XML
		SET @Speakers=@SpeakersXML 
			Delete from CRM_CampaignSpeakers where CampaignNodeID = @CampaignID and CCID=88 
			INSERT into CRM_CampaignSpeakers
			select 88,@CampaignID,
			convert(float,x.value('@Date','datetime')),  @UserName,convert(float,@Dt),x.value('@Alpha1','nvarchar(200)'),x.value('@Alpha2','nvarchar(MAX)'),x.value('@Alpha3','nvarchar(MAX)'),x.value('@Alpha4','nvarchar(MAX)'),x.value('@Alpha5','nvarchar(MAX)'),
			x.value('@Alpha6','nvarchar(MAX)'),x.value('@Alpha7','nvarchar(MAX)'),x.value('@Alpha8','nvarchar(MAX)'),x.value('@Alpha9','nvarchar(MAX)'),x.value('@Alpha10','nvarchar(MAX)'),
			x.value('@Alpha11','nvarchar(MAX)'),x.value('@Alpha12','nvarchar(MAX)'),x.value('@Alpha13','nvarchar(MAX)'),x.value('@Alpha14','nvarchar(MAX)'),x.value('@Alpha15','nvarchar(MAX)'),
			x.value('@Alpha16','nvarchar(MAX)'),x.value('@Alpha17','nvarchar(MAX)'),x.value('@Alpha18','nvarchar(MAX)'),x.value('@Alpha19','nvarchar(MAX)'),x.value('@Alpha20','nvarchar(MAX)'),
			x.value('@Alpha21','nvarchar(MAX)'),x.value('@Alpha22','nvarchar(MAX)'),x.value('@Alpha23','nvarchar(MAX)'),x.value('@Alpha24','nvarchar(MAX)'),x.value('@Alpha25','nvarchar(MAX)'),
			x.value('@Alpha26','nvarchar(MAX)'),x.value('@Alpha27','nvarchar(MAX)'),x.value('@Alpha28','nvarchar(MAX)'),x.value('@Alpha29','nvarchar(MAX)'),x.value('@Alpha30','nvarchar(MAX)'),
			x.value('@Alpha31','nvarchar(MAX)'),x.value('@Alpha32','nvarchar(MAX)'),x.value('@Alpha33','nvarchar(MAX)'),x.value('@Alpha34','nvarchar(MAX)'),x.value('@Alpha35','nvarchar(MAX)'),
			x.value('@Alpha36','nvarchar(MAX)'),x.value('@Alpha37','nvarchar(MAX)'),x.value('@Alpha38','nvarchar(MAX)'),x.value('@Alpha39','nvarchar(MAX)'),x.value('@Alpha40','nvarchar(MAX)'),
			x.value('@Alpha41','nvarchar(MAX)'),x.value('@Alpha42','nvarchar(MAX)'),x.value('@Alpha43','nvarchar(MAX)'),x.value('@Alpha44','nvarchar(MAX)'),x.value('@Alpha45','nvarchar(MAX)'),
			x.value('@Alpha46','nvarchar(MAX)'),x.value('@Alpha47','nvarchar(MAX)'),x.value('@Alpha48','nvarchar(MAX)'),x.value('@Alpha49','nvarchar(MAX)'),x.value('@Alpha50','nvarchar(MAX)')
			,x.value('@CCNID1','bigint'),x.value('@CCNID2','Bigint'),x.value('@CCNID3','Bigint'),x.value('@CCNID4','Bigint'),x.value('@CCNID5','Bigint'),
			x.value('@CCNID6','Bigint'),x.value('@CCNID7','Bigint'),x.value('@CCNID8','Bigint'),x.value('@CCNID9','Bigint'),x.value('@CCNID10','Bigint'),
			x.value('@CCNID11','Bigint'),x.value('@CCNID12','Bigint'),x.value('@CCNID13','Bigint'),x.value('@CCNID14','Bigint'),x.value('@CCNID15','Bigint'),
			x.value('@CCNID16','Bigint'),x.value('@CCNID17','Bigint'),x.value('@CCNID18','Bigint'),x.value('@CCNID19','Bigint'),x.value('@CCNID20','Bigint'),
			x.value('@CCNID21','Bigint'),x.value('@CCNID22','Bigint'),x.value('@CCNID23','Bigint'),x.value('@CCNID24','Bigint'),x.value('@CCNID25','Bigint'),
			x.value('@CCNID26','Bigint'),x.value('@CCNID27','Bigint'),x.value('@CCNID28','Bigint'),x.value('@CCNID29','Bigint'),x.value('@CCNID30','Bigint'),
			x.value('@CCNID31','Bigint'),x.value('@CCNID32','Bigint'),x.value('@CCNID33','Bigint'),x.value('@CCNID34','Bigint'),x.value('@CCNID35','Bigint'),
			x.value('@CCNID36','Bigint'),x.value('@CCNID37','Bigint'),x.value('@CCNID38','Bigint'),x.value('@CCNID39','Bigint'),x.value('@CCNID40','Bigint'),
			x.value('@CCNID41','Bigint'),x.value('@CCNID42','Bigint'),x.value('@CCNID43','Bigint'),x.value('@CCNID44','Bigint'),x.value('@CCNID45','Bigint'),
			x.value('@CCNID46','Bigint'),x.value('@CCNID47','Bigint'),x.value('@CCNID48','Bigint'),x.value('@CCNID49','Bigint'),x.value('@CCNID50','Bigint')
			,x.value('@CustomerID','Bigint'),x.value('@ContactID','Bigint'),x.value('@Customer','nvarchar(200)'),x.value('@ContactName','nvarchar(200)')
			from @Speakers.nodes('XML/Row') as data(x) 
		END
		--Campaign Activities
		 exec spCom_SetActivitiesAndSchedules @ActivityXml,88,@CampaignID,@CompanyGUID,'',@UserName,@dt,@LangID 
		 --Events 
		 exec spCom_SetActivitiesAndSchedules @EventsXml,128,@CampaignID,@CompanyGUID,'',@UserName,@dt,@LangID 
		if(@ApprovalsXML is not null and @ApprovalsXML <> '')
		BEGIN
		DECLARE @Approvals  XML
		SET @Approvals=@ApprovalsXML 
			Delete from CRM_CampaignApprovals where CampaignNodeID = @CampaignID and CCID=88 
			INSERT into CRM_CampaignApprovals
			select 88,@CampaignID,
			convert(float,x.value('@Date','datetime')),  @UserName,convert(float,@Dt),
			x.value('@Alpha1','nvarchar(MAX)'),x.value('@Alpha2','nvarchar(MAX)'),x.value('@Alpha3','nvarchar(MAX)'),x.value('@Alpha4','nvarchar(MAX)'),x.value('@Alpha5','nvarchar(MAX)'),
			x.value('@Alpha6','nvarchar(MAX)'),x.value('@Alpha7','nvarchar(MAX)'),x.value('@Alpha8','nvarchar(MAX)'),x.value('@Alpha9','nvarchar(MAX)'),x.value('@Alpha10','nvarchar(MAX)'),
			x.value('@Alpha11','nvarchar(MAX)'),x.value('@Alpha12','nvarchar(MAX)'),x.value('@Alpha13','nvarchar(MAX)'),x.value('@Alpha14','nvarchar(MAX)'),x.value('@Alpha15','nvarchar(MAX)'),
			x.value('@Alpha16','nvarchar(MAX)'),x.value('@Alpha17','nvarchar(MAX)'),x.value('@Alpha18','nvarchar(MAX)'),x.value('@Alpha19','nvarchar(MAX)'),x.value('@Alpha20','nvarchar(MAX)'),
			x.value('@Alpha21','nvarchar(MAX)'),x.value('@Alpha22','nvarchar(MAX)'),x.value('@Alpha23','nvarchar(MAX)'),x.value('@Alpha24','nvarchar(MAX)'),x.value('@Alpha25','nvarchar(MAX)'),
			x.value('@Alpha26','nvarchar(MAX)'),x.value('@Alpha27','nvarchar(MAX)'),x.value('@Alpha28','nvarchar(MAX)'),x.value('@Alpha29','nvarchar(MAX)'),x.value('@Alpha30','nvarchar(MAX)'),
			x.value('@Alpha31','nvarchar(MAX)'),x.value('@Alpha32','nvarchar(MAX)'),x.value('@Alpha33','nvarchar(MAX)'),x.value('@Alpha34','nvarchar(MAX)'),x.value('@Alpha35','nvarchar(MAX)'),
			x.value('@Alpha36','nvarchar(MAX)'),x.value('@Alpha37','nvarchar(MAX)'),x.value('@Alpha38','nvarchar(MAX)'),x.value('@Alpha39','nvarchar(MAX)'),x.value('@Alpha40','nvarchar(MAX)'),
			x.value('@Alpha41','nvarchar(MAX)'),x.value('@Alpha42','nvarchar(MAX)'),x.value('@Alpha43','nvarchar(MAX)'),x.value('@Alpha44','nvarchar(MAX)'),x.value('@Alpha45','nvarchar(MAX)'),
			x.value('@Alpha46','nvarchar(MAX)'),x.value('@Alpha47','nvarchar(MAX)'),x.value('@Alpha48','nvarchar(MAX)'),x.value('@Alpha49','nvarchar(MAX)'),x.value('@Alpha50','nvarchar(MAX)')
			,x.value('@CCNID1','bigint'),x.value('@CCNID2','Bigint'),x.value('@CCNID3','Bigint'),x.value('@CCNID4','Bigint'),x.value('@CCNID5','Bigint'),
			x.value('@CCNID6','Bigint'),x.value('@CCNID7','Bigint'),x.value('@CCNID8','Bigint'),x.value('@CCNID9','Bigint'),x.value('@CCNID10','Bigint'),
			x.value('@CCNID11','Bigint'),x.value('@CCNID12','Bigint'),x.value('@CCNID13','Bigint'),x.value('@CCNID14','Bigint'),x.value('@CCNID15','Bigint'),
			x.value('@CCNID16','Bigint'),x.value('@CCNID17','Bigint'),x.value('@CCNID18','Bigint'),x.value('@CCNID19','Bigint'),x.value('@CCNID20','Bigint'),
			x.value('@CCNID21','Bigint'),x.value('@CCNID22','Bigint'),x.value('@CCNID23','Bigint'),x.value('@CCNID24','Bigint'),x.value('@CCNID25','Bigint'),
			x.value('@CCNID26','Bigint'),x.value('@CCNID27','Bigint'),x.value('@CCNID28','Bigint'),x.value('@CCNID29','Bigint'),x.value('@CCNID30','Bigint'),
			x.value('@CCNID31','Bigint'),x.value('@CCNID32','Bigint'),x.value('@CCNID33','Bigint'),x.value('@CCNID34','Bigint'),x.value('@CCNID35','Bigint'),
			x.value('@CCNID36','Bigint'),x.value('@CCNID37','Bigint'),x.value('@CCNID38','Bigint'),x.value('@CCNID39','Bigint'),x.value('@CCNID40','Bigint'),
			x.value('@CCNID41','Bigint'),x.value('@CCNID42','Bigint'),x.value('@CCNID43','Bigint'),x.value('@CCNID44','Bigint'),x.value('@CCNID45','Bigint'),
			x.value('@CCNID46','Bigint'),x.value('@CCNID47','Bigint'),x.value('@CCNID48','Bigint'),x.value('@CCNID49','Bigint'),x.value('@CCNID50','Bigint'),
			x.value('@FilePath','nvarchar(MAX)'),x.value('@ActualFileName','nvarchar(MAX)'),x.value('@FileExtension','nvarchar(MAX)') 
			,x.value('@GUID','nvarchar(MAX)') 
			from @Approvals.nodes('XML/Row') as data(x) 
		END
	 
		
		
		Delete from CRM_ProductMapping where CCNodeID = @CampaignID and CostCenterID=88
    if(@ProcuctXML is not null and @ProcuctXML <> '')
	   begin
				SET @XML=@ProcuctXML
			
				INSERT into CRM_ProductMapping(CCNodeID,CostCenterID,ProductID,CRMProduct,UOMID,Description,
				   Quantity,CurrencyID, Alpha1, Alpha2, Alpha3, Alpha4, Alpha5, Alpha6, Alpha7, Alpha8, Alpha9, Alpha10, Alpha11, Alpha12, Alpha13, Alpha14, Alpha15, Alpha16, Alpha17, Alpha18, Alpha19, Alpha20, Alpha21, Alpha22, Alpha23, Alpha24, Alpha25, Alpha26, Alpha27, Alpha28, Alpha29, Alpha30, Alpha31, Alpha32, Alpha33, Alpha34, Alpha35, Alpha36, Alpha37, Alpha38, Alpha39, Alpha40, Alpha41, Alpha42, Alpha43, Alpha44, Alpha45, Alpha46,
				    Alpha47, Alpha48, Alpha49, Alpha50, CCNID1, CCNID2, CCNID3, CCNID4, CCNID5, CCNID6, CCNID7, CCNID8, CCNID9, CCNID10, CCNID11, CCNID12, CCNID13, CCNID14, CCNID15, CCNID16, CCNID17, CCNID18, CCNID19, CCNID20, CCNID21, CCNID22, CCNID23, CCNID24, CCNID25, CCNID26, CCNID27, CCNID28, CCNID29, CCNID30, CCNID31, CCNID32, CCNID33, CCNID34, CCNID35, CCNID36, CCNID37, CCNID38, CCNID39, CCNID40, CCNID41, CCNID42, CCNID43, CCNID44, CCNID45, CCNID46,
				    CCNID47, CCNID48, CCNID49, CCNID50,CompanyGUID,GUID,CreatedBy,CreatedDate)
				   select @CampaignID,88,
			       x.value('@Product','BIGINT'), x.value('@CRMProduct','BIGINT'),
				   x.value('@UOM','bigint'), x.value('@Desc','nvarchar(MAX)'),
				   x.value('@Qty','float'),ISNULL(x.value('@Currency','INT'),1),
					 x.value('@Alpha1','nvarchar(MAX)'),x.value('@Alpha2','nvarchar(MAX)'),x.value('@Alpha3','nvarchar(MAX)'),x.value('@Alpha4','nvarchar(MAX)'),x.value('@Alpha5','nvarchar(MAX)'),
			       x.value('@Alpha6','nvarchar(MAX)'),x.value('@Alpha7','nvarchar(MAX)'),x.value('@Alpha8','nvarchar(MAX)'),x.value('@Alpha9','nvarchar(MAX)'),x.value('@Alpha10','nvarchar(MAX)'),
			       x.value('@Alpha11','nvarchar(MAX)'),x.value('@Alpha12','nvarchar(MAX)'),x.value('@Alpha13','nvarchar(MAX)'),x.value('@Alpha14','nvarchar(MAX)'),x.value('@Alpha15','nvarchar(MAX)'),
			       x.value('@Alpha16','nvarchar(MAX)'),x.value('@Alpha17','nvarchar(MAX)'),x.value('@Alpha18','nvarchar(MAX)'),x.value('@Alpha19','nvarchar(MAX)'),x.value('@Alpha20','nvarchar(MAX)'),
			       x.value('@Alpha21','nvarchar(MAX)'),x.value('@Alpha22','nvarchar(MAX)'),x.value('@Alpha23','nvarchar(MAX)'),x.value('@Alpha24','nvarchar(MAX)'),x.value('@Alpha25','nvarchar(MAX)'),
			       x.value('@Alpha26','nvarchar(MAX)'),x.value('@Alpha27','nvarchar(MAX)'),x.value('@Alpha28','nvarchar(MAX)'),x.value('@Alpha29','nvarchar(MAX)'),x.value('@Alpha30','nvarchar(MAX)'),
			       x.value('@Alpha31','nvarchar(MAX)'),x.value('@Alpha32','nvarchar(MAX)'),x.value('@Alpha33','nvarchar(MAX)'),x.value('@Alpha34','nvarchar(MAX)'),x.value('@Alpha35','nvarchar(MAX)'),
			       x.value('@Alpha36','nvarchar(MAX)'),x.value('@Alpha37','nvarchar(MAX)'),x.value('@Alpha38','nvarchar(MAX)'),x.value('@Alpha39','nvarchar(MAX)'),x.value('@Alpha40','nvarchar(MAX)'),
			       x.value('@Alpha41','nvarchar(MAX)'),x.value('@Alpha42','nvarchar(MAX)'),x.value('@Alpha43','nvarchar(MAX)'),x.value('@Alpha44','nvarchar(MAX)'),x.value('@Alpha45','nvarchar(MAX)'),
			       x.value('@Alpha46','nvarchar(MAX)'),x.value('@Alpha47','nvarchar(MAX)'),x.value('@Alpha48','nvarchar(MAX)'),x.value('@Alpha49','nvarchar(MAX)'),x.value('@Alpha50','nvarchar(MAX)'),
			       
			       x.value('@CCNID1','bigint'),x.value('@CCNID2','bigint'),x.value('@CCNID3','bigint'),x.value('@CCNID4','bigint'),x.value('@CCNID5','bigint'),
			       x.value('@CCNID6','bigint'),x.value('@CCNID7','bigint'),x.value('@CCNID8','bigint'),x.value('@CCNID9','bigint'),x.value('@CCNID10','bigint'),
			       x.value('@CCNID11','bigint'),x.value('@CCNID12','bigint'),x.value('@CCNID13','bigint'),x.value('@CCNID14','bigint'),x.value('@CCNID15','bigint'),
			       x.value('@CCNID16','bigint'),x.value('@CCNID17','bigint'),x.value('@CCNID18','bigint'),x.value('@CCNID19','bigint'),x.value('@CCNID20','bigint'),
			       x.value('@CCNID21','bigint'),x.value('@CCNID22','bigint'),x.value('@CCNID23','bigint'),x.value('@CCNID24','bigint'),x.value('@CCNID25','bigint'),
			       x.value('@CCNID26','bigint'),x.value('@CCNID27','bigint'),x.value('@CCNID28','bigint'),x.value('@CCNID29','bigint'),x.value('@CCNID30','bigint'),
			       x.value('@CCNID31','bigint'),x.value('@CCNID32','bigint'),x.value('@CCNID33','bigint'),x.value('@CCNID34','bigint'),x.value('@CCNID35','bigint'),
			       x.value('@CCNID36','bigint'),x.value('@CCNID37','bigint'),x.value('@CCNID38','bigint'),x.value('@CCNID39','bigint'),x.value('@CCNID40','bigint'),
			       x.value('@CCNID41','bigint'),x.value('@CCNID42','bigint'),x.value('@CCNID43','bigint'),x.value('@CCNID44','bigint'),x.value('@CCNID45','bigint'),
			       x.value('@CCNID46','bigint'),x.value('@CCNID47','bigint'),x.value('@CCNID48','bigint'),x.value('@CCNID49','bigint'),x.value('@CCNID50','bigint'),
		
				   @CompanyGUID,
				   newid(),
				   @UserName,
				   convert(float,@Dt)
				   from @XML.nodes('XML/Row') as data(x)
				   where  x.value('@Product','BIGINT')is not null and   x.value('@Product','BIGINT') <> ''
			
		end
		
		
 

COMMIT TRANSACTION    
SELECT * FROM CRM_Campaigns WITH (nolock) WHERE CampaignID=@CampaignID  
SELECT ErrorMessage,ErrorNumber FROM COM_ErrorMessages WITH(nolock)   
WHERE ErrorNumber=100 AND LanguageID=@LangID  
SET NOCOUNT OFF;    
RETURN @CampaignID    
END TRY    
BEGIN CATCH    
 --Return exception info [Message,Number,ProcedureName,LineNumber]    
 IF ERROR_NUMBER()=50000  
 BEGIN  
  SELECT * FROM CRM_Campaigns WITH(nolock) WHERE CampaignID=@CampaignID    
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

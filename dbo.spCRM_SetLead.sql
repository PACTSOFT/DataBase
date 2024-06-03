USE PACT2C222
GO
SET ANSI_NULLS, QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spCRM_SetLead]
	@LeadID [bigint] = 0,
	@LeadCode [nvarchar](200),
	@Company [nvarchar](200) = NULL,
	@Description [nvarchar](500) = NULL,
	@StatusID [int],
	@IsGroup [bit],
	@SelectedNodeID [bigint],
	@Date [datetime] = NULL,
	@Subject [nvarchar](500) = NULL,
	@CampaignID [bigint] = 1,
	@SourceID [bigint] = null,
	@RatingID [bigint] = null,
	@IndustryID [bigint] = null,
	@ContactID [bigint] = null,
	@DetailsXML [nvarchar](max) = null,
	@TabDetailsXML [nvarchar](max) = null,
	@CustomFieldsQuery [nvarchar](max) = null,
	@CustomCostCenterFieldsQuery [nvarchar](max) = null,
	@ActivityXml [nvarchar](max) = null,
	@NotesXML [nvarchar](max) = null,
	@AttachmentsXML [nvarchar](max) = null,
	@ProductXML [nvarchar](max) = null,
	@FeedbackXML [nvarchar](max) = null,
	@CVRXML [nvarchar](max) = null,
	@ContactsXML [nvarchar](max) = null,
	@PrimaryContactQuery [nvarchar](max) = NULL,
	@EmailAllow [bit] = 0,
	@BulkEmailAllow [bit] = 0,
	@MailAllow [bit] = 0,
	@PhoneAllow [bit] = 0,
	@FaxAllow [bit] = 0,
	@Mode [int] = 0,
	@SelectedModeID [int] = 0,
	@CompanyGUID [nvarchar](50),
	@GUID [nvarchar](50),
	@UserName [nvarchar](50),
	@UserID [int] = 0,
	@RoleID [int] = 0,
	@LangId [int] = 1,
	@CodePrefix [nvarchar](200) = NULL,
	@CodeNumber [bigint] = 0,
	@IsCode [bit] = 0
WITH ENCRYPTION, EXECUTE AS CALLER
AS
SET NOCOUNT ON 
BEGIN TRANSACTION
BEGIN TRY
  
	DECLARE @UpdateSql nvarchar(max),@Dt FLOAT, @TempGuid nvarchar(50),@HasAccess bit,@ActionType INT
	Declare @XML XML
	
	IF EXISTS(SELECT LeadID FROM CRM_Leads WITH(NOLOCK) WHERE LeadID=@LeadID AND ParentID=0)  
	BEGIN  
		RAISERROR('-123',16,1)  
	END  
	
	--User acces check FOR ACCOUNTS  
	IF @LeadID=0  
	BEGIN
		SET @ActionType=1
		SET @HasAccess=dbo.fnCOM_HasAccess(@RoleID,86,1)  
	END  
	ELSE  
	BEGIN  
		SET @ActionType=3
		SET @HasAccess=dbo.fnCOM_HasAccess(@RoleID,86,3)  
	END  

	IF @HasAccess=0  
	BEGIN  
		RAISERROR('-105',16,1)  
	END 
	
	--User acces check FOR Notes  
	IF (@NotesXML IS NOT NULL AND @NotesXML <> '')  
	BEGIN  
		SET @HasAccess=dbo.fnCOM_HasAccess(@RoleID,86,8)  

		IF @HasAccess=0  
		BEGIN  
			RAISERROR('-105',16,1)  
		END  
	END  

	--User acces check FOR Attachments  
	IF (@AttachmentsXML IS NOT NULL AND @AttachmentsXML <> '')  
	BEGIN  
		SET @HasAccess=dbo.fnCOM_HasAccess(@RoleID,86,12)  

		IF @HasAccess=0  
		BEGIN  
			RAISERROR('-105',16,1)  
		END  
	END   
	
	--GETTING PREFERENCE
	Declare @IsDuplicateNameAllowed bit,@IsIgnoreSpace bit,@AutoAssign bit  
	SELECT @IsDuplicateNameAllowed=Value FROM COM_CostCenterPreferences WITH(nolock) WHERE COSTCENTERID=86 and  Name='DuplicateNameAllowed'  
	SELECT @IsIgnoreSpace=Value FROM COM_CostCenterPreferences  WITH(nolock) WHERE COSTCENTERID=86 and  Name='IgnoreSpaces'  
	SELECT @AutoAssign=Value FROM COM_CostCenterPreferences  WITH(nolock) WHERE COSTCENTERID=86 and  Name='AutoAssign'  

    IF @IsCode=1 AND @LeadID=0 and @LeadCode='' and exists (SELECT * FROM COM_CostCenterCodeDef WITH(nolock)WHERE CostCenterID=86 and IsEnable=1 and IsName=0 and IsGroupCode=@IsGroup)
	BEGIN 
		--CALL AUTOCODEGEN 
		declare @temp1 table(prefix nvarchar(100),number bigint, suffix nvarchar(100), code nvarchar(200), IsManualcode bit)
		if(@SelectedNodeID is null)
			insert into @temp1
			EXEC [spCOM_GetCodeData] 86,1,''  
		else
			insert into @temp1
			EXEC [spCOM_GetCodeData] 86,@SelectedNodeID,''  
		select @LeadCode=code,@CodePrefix= prefix, @CodeNumber=number from @temp1	
	END	

	IF @MODE=0
	BEGIN
		--DUPLICATE CHECK  
		IF @IsDuplicateNameAllowed IS NOT NULL AND @IsDuplicateNameAllowed=0  
		BEGIN  
			IF @IsIgnoreSpace IS NOT NULL AND @IsIgnoreSpace=1  
			BEGIN  
				IF @LeadID=0  
				BEGIN  
					IF EXISTS (SELECT LeadID FROM CRM_Leads WITH(nolock) WHERE replace(Company,' ','')=replace(@Company,' ','') AND MODE=0)  
					BEGIN  
						RAISERROR('-112',16,1)  
					END  
				END  
				ELSE  
				BEGIN  
					IF EXISTS (SELECT LeadID FROM CRM_Leads WITH(nolock) WHERE replace(Company,' ','')=replace(@Company,' ','') AND MODE=0 AND LeadID <> @LeadID)  
					BEGIN  
						RAISERROR('-112',16,1)       
					END  
				END  
			END  
			ELSE  
			BEGIN  
				IF @LeadID=0  
				BEGIN  
					IF EXISTS (SELECT LeadID FROM CRM_Leads WITH(nolock) WHERE Company=@Company AND MODE=0)  
					BEGIN  
						RAISERROR('-112',16,1)  
					END  
				END  
				ELSE  
				BEGIN  
					IF EXISTS (SELECT LeadID FROM CRM_Leads WITH(nolock) WHERE Company=@Company AND MODE=0 AND LeadID <> @LeadID)  
					BEGIN  
						RAISERROR('-112',16,1)  
					END  
				END  
			END
		END   
	END

	SET @Dt=convert(float,getdate())--Setting Current Date  

	declare @detailtbl table(FirstName NVARCHAR(50),MiddleName NVARCHAR(50),LastName NVARCHAR(50),Salutation bigint,jobTitle NVARCHAR(50),
	Phone1 NVARCHAR(50),Phone2 NVARCHAR(50),Email NVARCHAR(50),Fax NVARCHAR(50),Department NVARCHAR(50),RoleID bigint)

	if(@DetailsXML is not null AND @DetailsXML<>'')
	begin
		set @XML =@DetailsXML
		insert into @detailtbl
		select x.value('@FirstName','NVARCHAR(50)'),x.value('@MiddleName','NVARCHAR(50)'),x.value('@LastName','NVARCHAR(50)'),x.value('@Salutation','bigint'),
		x.value('@JobTitle','NVARCHAR(50)'),x.value('@Phone1','NVARCHAR(50)'),x.value('@Phone2','NVARCHAR(50)'),x.value('@Email','NVARCHAR(50)'),x.value('@Fax','NVARCHAR(50)'),
		x.value('@Department','NVARCHAR(50)'),x.value('@Role','bigint') from  @XML.nodes('Row') as data(x)
	end
	 
	declare @tabdetailtbl table(Address1 NVARCHAR(50),Address2 NVARCHAR(50),Address3 NVARCHAR(50),City NVARCHAR(50),[State] NVARCHAR(50),
	Zip NVARCHAR(50),CountryID bigint,Gender NVARCHAR(50),Birthday FLOAT,Anniversary FLOAT,PreferredID bigint,PreferredName nvarchar(50))

	if(@TabDetailsXML is not null AND @TabDetailsXML<>'')
	begin
		set @XML =@TabDetailsXML
		insert into @tabdetailtbl
		select x.value('@Address1','NVARCHAR(50)'),x.value('@Address2','NVARCHAR(50)'),x.value('@Address3','NVARCHAR(50)'),
		x.value('@City','NVARCHAR(50)'),x.value('@State','NVARCHAR(50)'),x.value('@Zip','NVARCHAR(50)'),x.value('@Country','bigint'),x.value('@Gender','NVARCHAR(50)')
		,CONVERT(FLOAT,x.value('@Birthday','datetime')),CONVERT(FLOAT,x.value('@Anniversary','datetime')),x.value('@PreferredID','bigint') ,x.value('@PreferredName','NVARCHAR(50)') 
		from  @XML.nodes('Row') as data(x)
	end

	IF @LeadID= 0--------START INSERT RECORD-----------  
	BEGIN--CREATE Lead  
		DECLARE @lft bigint,@rgt bigint,@Depth int,@ParentID bigint,@SelectedIsGroup int,@Selectedlft bigint,@Selectedrgt bigint
		--To Set Left,Right And Depth of Record  
		SELECT @SelectedIsGroup=IsGroup,@Selectedlft =lft,@Selectedrgt=rgt,@ParentID=ParentID,@Depth=Depth  
		from CRM_Leads with(NOLOCK) where LeadID=@SelectedNodeID  

		--IF No Record Selected or Record Doesn't Exist  
		if(@SelectedIsGroup is null)   
		select @SelectedNodeID=LeadID,@SelectedIsGroup=IsGroup,@Selectedlft =lft,@Selectedrgt=rgt,@ParentID=ParentID,@Depth=Depth  
		from CRM_Leads with(NOLOCK) where ParentID =0  

		if(@SelectedIsGroup = 1)--Adding Node Under the Group  
		BEGIN  
			UPDATE CRM_Leads SET rgt = rgt + 2 WHERE rgt > @Selectedlft;  
			UPDATE CRM_Leads SET lft = lft + 2 WHERE lft > @Selectedlft;  
			set @lft =  @Selectedlft + 1  
			set @rgt = @Selectedlft + 2  
			set @ParentID = @SelectedNodeID  
			set @Depth = @Depth + 1  
		END  
		else if(@SelectedIsGroup = 0)--Adding Node at Same level  
		BEGIN  
			UPDATE CRM_Leads SET rgt = rgt + 2 WHERE rgt > @Selectedrgt;  
			UPDATE CRM_Leads SET lft = lft + 2 WHERE lft > @Selectedrgt;  
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
	  
		INSERT INTO CRM_Leads(CodePrefix,CodeNumber,Code,[Subject],[Date],StatusId,Company,SourceLookUpID
		,RatinglookupID,IndustryLookUpID,CampaignID,CampaignResponseID,CampaignActivityID,[Description]
		,Depth,ParentID,lft,rgt,IsGroup,CompanyGUID,[GUID],CreatedBy,CreatedDate,Mode,SelectedModeID,ContactID)
		Values (@CodePrefix,@CodeNumber,@LeadCode,@Subject,convert(float,@Date),@StatusID,@Company,@SourceID
		,@RatingID,@IndustryID,@CampaignID,1,1,@Description
		,@Depth,@ParentID,@lft,@rgt,@IsGroup,@CompanyGUID,newid(),@UserName,@Dt,@Mode,@SelectedModeID,@ContactID)

		SET @LeadID=SCOPE_IDENTITY() 

		insert into CRM_CONTACTS(FeatureID,FeaturePK,Company,StatusID,
			   FirstName,MiddleName,LastName,SalutationID,JobTitle,
			   Phone1,Phone2,Email1,Fax,Department,RoleLookUpID,
			   Address1,Address2,Address3,City,[State],Zip,Country,Gender,
			   Birthday,Anniversary,PreferredID,PreferredName,
			   IsEmailOn,IsBulkEmailOn,IsMailOn,IsPhoneOn,IsFaxOn,IsVisible,
			   [Description],Depth,ParentID,lft,rgt,IsGroup,CompanyGUID,[GUID],CreatedBy,CreatedDate)
			 SELECT 86,@LeadID,@Company,@StatusID,
			  FirstName,MiddleName,LastName,Salutation,jobTitle,
			  Phone1,Phone2,Email,Fax,Department,RoleID,
			  Address1,Address2,Address3,City,[State],Zip,CountryID,Gender,
			  Birthday,Anniversary,PreferredID,PreferredName,
			  @EmailAllow,@BulkEmailAllow,@MailAllow,@PhoneAllow,@FaxAllow,0,
			  @Description,@Depth,@ParentID,@lft,@rgt,@IsGroup,@CompanyGUID,newid(),@UserName,@Dt
			  from @detailtbl,@tabdetailtbl

		DECLARE @Str varchar(10), @a int, @val bigint,@cnt int, @DIMContact nvarchar(max),
		@DIMNotes nvarchar(max), @DIMAttachments nvarchar(max),@DimPrimaryContactQuery nvarchar(max)
		select @Str=isnull(value,'') from com_costcenterpreferences WITH(NOLOCK)
		where costcenterid=86 and name='CopyDimensionData'
				
		declare @temp table (id int identity(1,1), val int) 
		insert into @temp (val) 
		exec SPSplitString @Str,';'  
		
		set @a=1 
		select @cnt=count(*) from @temp 
		while @a<=@cnt
		begin
			set @val=null
			select @val=val from @temp where id=@a 
			if(@val is null)
				set @a=@a+1
			else if(@val=1)
			begin
				set @DIMContact=@ContactsXML
				set @DimPrimaryContactQuery=@PrimaryContactQuery
			end
			else if(@val=3)
				set @DIMNotes=@NotesXML
			else if(@val=4)
				set @DIMAttachments=@AttachmentsXML
			 set @a=@a+1
		end
			
		DECLARE @return_value int,@LinkCostCenterID INT
		SELECT @LinkCostCenterID=isnull([Value],0) FROM COM_CostCenterPreferences WITH(NOLOCK) 
		WHERE FeatureID=86 AND [Name]='LeadLinkDimension'
			
		IF @LinkCostCenterID>0  AND @IsGroup=0  
		BEGIN
			EXEC @return_value = [dbo].[spCOM_SetCostCenter]
				@NodeID = 0,@SelectedNodeID = 0,@IsGroup = 0,
				@Code = @LeadCode,
				@Name = @Company,
				@AliasName=@Company,
				@PurchaseAccount=0,@SalesAccount=0,@StatusID=@StatusID,
				@CustomFieldsQuery=NULL,@AddressXML=NULL,@AttachmentsXML=@DIMAttachments,
				@CustomCostCenterFieldsQuery=NULL,@ContactsXML=@DIMContact,@NotesXML=@DIMNotes,
				@PrimaryContactQuery=@DimPrimaryContactQuery,
				@CostCenterID =@LinkCostCenterID,@CompanyGUID=@COMPANYGUID,@GUID='GUID',
				@UserName=@USERNAME,@RoleID=1,@UserID=@USERID
				
			UPDATE CRM_Leads SET CCLeadID=@return_value
			WHERE LeadID=@LeadID  
		END  
			
		--Handling of Extended Table  
		INSERT INTO CRM_LeadsExtended([LeadID],[CreatedBy],[CreatedDate])  
		VALUES(@LeadID, @UserName, @Dt)  

  		--INSERT INTO ASSIGNED TABLE 
  		if(@AutoAssign=1)
  		begin
			DECLARE @TEAMNODEID BIGINT=0
			SELECT TOP(1) @TEAMNODEID =  ISNULL(TeamID,0) FROM CRM_Teams WITH(NOLOCK) 
			WHERE UserID=@UserID AND IsGroup=0 
			
			IF @TEAMNODEID>0
				EXEC spCRM_SetCRMAssignment 86,	@LeadID,@TEAMNODEID,@UserID,0,'','','',@CompanyGUID,@UserName,@LangId
			else if exists (select ParentNodeid from COM_CostCenterCostCenterMap WITH(NOLOCK) where Parentcostcenterid=7 and costcenterid=7 and Nodeid=@UserID)
			begin
				declare @TEMPUSERID BIGINT
				select @TEMPUSERID=ParentNodeid from COM_CostCenterCostCenterMap WITH(NOLOCK)
				where Parentcostcenterid=7 and costcenterid=7 and Nodeid=@UserID 
				EXEC spCRM_SetCRMAssignment 86,	@LeadID,0,@UserID,0,@TEMPUSERID,'','',@CompanyGUID,@UserName,@LangId
			end
		end
		ELSE if(@AutoAssign=0)
		BEGIN
			EXEC spCRM_SetCRMAssignment 86,	@LeadID,0,@UserID,0,@UserID,'','',@CompanyGUID,@UserName,@LangId
		END
		
		--Handling of CostCenter Costcenters Extrafields Table 
		INSERT INTO COM_CCCCDATA ([CostCenterID] ,[NodeID] ,[Guid],[CreatedBy],[CreatedDate])
		VALUES(86,@LeadID,newid(),  @UserName, @Dt) 

		--INSERT PRIMARY CONTACT  
		INSERT [COM_Contacts]([AddressTypeID],[FeatureID],[FeaturePK],[CompanyGUID],[GUID],[CreatedBy],[CreatedDate]  )  
		VALUES(1,86,@LeadID,@CompanyGUID,NEWID(),@UserName,@Dt)  
	    
		INSERT INTO COM_ContactsExtended(ContactID,[CreatedBy],[CreatedDate])
		VALUES(SCOPE_IDENTITY(), @UserName, convert(float,getdate()))

		IF exists(select * from  dbo.ADM_FeatureActionrolemap with(nolock) where RoleID=@RoleID and FeatureActionID=4830)
		BEGIN  
			UPDATE CRM_LEADS SET IsApproved=1, ApprovedDate=@Dt,ApprovedBy=@UserName
			where Leadid=@LeadID 
		end

	END --------END INSERT RECORD-----------  
	ELSE  --------START UPDATE RECORD-----------  
	BEGIN
		SELECT @TempGuid=[GUID] from CRM_Leads  WITH(NOLOCK)   
		WHERE LeadID=@LeadID

		IF(@TempGuid!=@Guid)--IF RECORD ALREADY UPDATED BY SOME OTHER USER i.e DIRTY READ    
		BEGIN    
			RAISERROR('-101',16,1)   
		END    
		ELSE    
		BEGIN  
			UPDATE CRM_Leads SET [Code]=@LeadCode
				,[Subject]= @Subject
				,[Date]=convert(float,@Date)
				,[Company]=@Company
				,SourceLookUpID=@SourceID
				,RatinglookupID=@RatingID
				,IndustryLookUpID=@IndustryID
				,CampaignID=@CampaignID
				,[StatusID] = @StatusID,ContactID=@ContactID
				,[Description] = @Description
				,[GUID] = @Guid
				,[ModifiedBy] = @UserName
				,[ModifiedDate] = @Dt,SelectedModeID=@SelectedModeID,Mode=@Mode
			WHERE LeadID = @LeadID

			if(@DetailsXML is not null AND @DetailsXML<>'' AND @TabdetailsXML is not null AND @TabdetailsXML<>'')
			begin
				
				if not exists (select * from CRM_CONTACTS with(nolock) where FeaturePK=@LeadID and Featureid=86 )
				begin
					insert into CRM_CONTACTS (FeaturePK,Featureid,guid,createdby,createddate) values(@LeadID,86,newid(),@UserName,@Dt)
				end
				
				Update CRM_CONTACTS set Company=@Company,
				   StatusID=@StatusID,
				   FirstName=T1.FirstName,
				   MiddleName=T1.MiddleName,
				   LastName=T1.LastName,
				   SalutationID=T1.Salutation,
				   JobTitle=T1.jobTitle,
				   Phone1=T1.Phone1,
				   Phone2=T1.Phone2,
				   Email1=T1.Email,
				   Fax=T1.Fax,
				   Department=T1.Department,
				   RoleLookUpID=T1.RoleID,
				   Address1=T2.Address1,
				   Address2=T2.Address2,
				   Address3=T2.Address3,
				   City=T2.City,
				   [State]=T2.[State],
				   Zip=T2.Zip,
				   Country=T2.CountryID,
				   Gender=T2.Gender,
				   Birthday=T2.Birthday,
				   Anniversary=T2.Anniversary,
				   PreferredID=T2.PreferredID,
				   PreferredName=T2.PreferredName,
				   IsEmailOn=@EmailAllow,
				   IsBulkEmailOn=@BulkEmailAllow,
				   IsMailOn=@MailAllow,
				   IsPhoneOn=@PhoneAllow,
				   IsFaxOn=@FaxAllow
				from @detailtbl T1,@tabdetailtbl T2
				where FeaturePK=@LeadID and Featureid=86 
			end
		END
	END 
  
    set @UpdateSql='update COM_CCCCDATA  SET '+@CustomCostCenterFieldsQuery+'[ModifiedBy] ='''+ @UserName+''',[ModifiedDate] =' + convert(nvarchar,@Dt) +' 
    WHERE NodeID = '+convert(nvarchar,@LeadID) + ' AND CostCenterID = 86' 
	exec(@UpdateSql)  
    
    --Update Extra fields
	set @UpdateSql='update [CRM_LeadsExtended] SET '+@CustomFieldsQuery+' [ModifiedBy] ='''+ @UserName
    +''',[ModifiedDate] =' + convert(nvarchar,@Dt) +' WHERE LeadID='+convert(nvarchar,@LeadID)
	exec(@UpdateSql) 
	
	--Duplicate Check
	exec [spCOM_CheckUniqueCostCenter] @CostCenterID=86,@NodeID =@LeadID,@LangID=@LangID
	
    --Series Check
	declare @retSeries bigint
	EXEC @retSeries=spCOM_ValidateCodeSeries 86,@LeadID,@LangId
	if @retSeries>0
	begin
		ROLLBACK TRANSACTION
		SET NOCOUNT OFF  
		RETURN -999
	end

	--ADDED CONDIDTION ON JAN 30 2013 BY HAFEEZ
	--TO SET LEAD LINK DIMENSION=@LeadID AND MAKE THAT COLUMN AS READONLY
	DECLARE @DIMID INT=0
	SELECT @DIMID=ISNULL(VALUE,0) FROM COM_COSTCENTERPREFERENCES WITH(NOLOCK) WHERE COSTCENTERID=86 AND NAME='LEADLINKDIMENSION'
	IF (@IsGroup=0 and @DIMID<>'' AND @DIMID>0)
	BEGIN
		SET @UpdateSql=' UPDATE COM_CCCCDATA SET CCNID'+CONVERT(NVARCHAR(30),(@DIMID-50000))+'=
		(SELECT CCLEADID FROM CRM_LEADS WITH(NOLOCK) WHERE LEADID='+convert(nvarchar,@LeadID) + ') 
						WHERE NodeID = '+convert(nvarchar,@LeadID) + ' AND CostCenterID = 86'
		  exec(@UpdateSql)  
	END				

    IF  @FeedbackXML IS NOT NULL AND @FeedbackXML<>''
	BEGIN
		SET @XML=@FeedbackXML
	
		Delete from CRM_FEEDBACK where CCNodeID = @LeadID and CCID=86
	 
		INSERT into CRM_FEEDBACK
		   select 86,@LeadID,
	       convert(float,x.value('@Date','datetime')),x.value('@FeedBack','nvarchar(MAX)'), @UserName,@Dt,x.value('@Alpha1','nvarchar(200)'),x.value('@Alpha2','nvarchar(MAX)'),x.value('@Alpha3','nvarchar(MAX)'),x.value('@Alpha4','nvarchar(MAX)'),x.value('@Alpha5','nvarchar(MAX)'),
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
	       x.value('@CCNID46','bigint'),x.value('@CCNID47','bigint'),x.value('@CCNID48','bigint'),x.value('@CCNID49','bigint'),x.value('@CCNID50','bigint')   
		   from @XML.nodes('XML/Row') as data(x)	    				   
	END
	
	IF  @CVRXML IS NOT NULL AND @CVRXML<>''
	BEGIN
		SET @XML=@CVRXML
	
		Delete from CRM_LeadCVRDetails where CCNodeID = @LeadID and CCID=86
	 
		INSERT into CRM_LeadCVRDetails
		   select 86,@LeadID,
	       convert(float,x.value('@Date','datetime')),x.value('@Product','Int'),x.value('@Technical','nvarchar(MAX)'),x.value('@Commercial','nvarchar(MAX)'), @UserName,@Dt,x.value('@Alpha1','nvarchar(200)'),x.value('@Alpha2','nvarchar(MAX)'),x.value('@Alpha3','nvarchar(MAX)'),x.value('@Alpha4','nvarchar(MAX)'),x.value('@Alpha5','nvarchar(MAX)'),
	       x.value('@Alpha6','nvarchar(MAX)'),x.value('@Alpha7','nvarchar(MAX)'),x.value('@Alpha8','nvarchar(MAX)'),x.value('@Alpha9','nvarchar(MAX)'),x.value('@Alpha10','nvarchar(MAX)'),
	       x.value('@Alpha11','nvarchar(MAX)'),x.value('@Alpha12','nvarchar(MAX)'),x.value('@Alpha13','nvarchar(MAX)'),x.value('@Alpha14','nvarchar(MAX)'),x.value('@Alpha15','nvarchar(MAX)'),
	       x.value('@Alpha16','nvarchar(MAX)'),x.value('@Alpha17','nvarchar(MAX)'),x.value('@Alpha18','nvarchar(MAX)'),x.value('@Alpha19','nvarchar(MAX)'),x.value('@Alpha20','nvarchar(MAX)'),
	       x.value('@Alpha21','nvarchar(MAX)'),x.value('@Alpha22','nvarchar(MAX)'),x.value('@Alpha23','nvarchar(MAX)'),x.value('@Alpha24','nvarchar(MAX)'),x.value('@Alpha25','nvarchar(MAX)'),
	       x.value('@Alpha26','nvarchar(MAX)'),x.value('@Alpha27','nvarchar(MAX)'),x.value('@Alpha28','nvarchar(MAX)'),x.value('@Alpha29','nvarchar(MAX)'),x.value('@Alpha30','nvarchar(MAX)'),
	       x.value('@Alpha31','nvarchar(MAX)'),x.value('@Alpha32','nvarchar(MAX)'),x.value('@Alpha33','nvarchar(MAX)'),x.value('@Alpha34','nvarchar(MAX)'),x.value('@Alpha35','nvarchar(MAX)'),
	       x.value('@Alpha36','nvarchar(MAX)'),x.value('@Alpha37','nvarchar(MAX)'),x.value('@Alpha38','nvarchar(MAX)'),x.value('@Alpha39','nvarchar(MAX)'),x.value('@Alpha40','nvarchar(MAX)'),
	       x.value('@Alpha41','nvarchar(MAX)'),x.value('@Alpha42','nvarchar(MAX)'),x.value('@Alpha43','nvarchar(MAX)'),x.value('@Alpha44','nvarchar(MAX)'),x.value('@Alpha45','nvarchar(MAX)'),
	       x.value('@Alpha46','nvarchar(MAX)'),x.value('@Alpha47','nvarchar(MAX)'),x.value('@Alpha48','nvarchar(MAX)'),x.value('@Alpha49','nvarchar(MAX)'),x.value('@Alpha50','nvarchar(MAX)')
		   from @XML.nodes('XML/Row') as data(x)	   
	END
  
	exec spCom_SetActivitiesAndSchedules @ActivityXml,86,@LeadID,@CompanyGUID,@Guid,@UserName,@dt,@LangID 

	IF(@PrimaryContactQuery IS NOT NULL AND @PrimaryContactQuery<>'')
	BEGIN  
		--CHANGES MADE IN PRIMARY CONTACT QUERY BY HAFEEZ ON DEC 20 2013,BECOZ CONTACT QUICK ADD SCREEN IS CUSTOMIZABLE
		EXEC spCOM_SetFeatureWiseContacts 86,@LeadID,1,@PrimaryContactQuery,@UserName,@Dt,@LangID
	END
  
	--Inserts Multiple Contacts  
	IF (@ContactsXML IS NOT NULL AND @ContactsXML <> '')  
	BEGIN  
		--CHANGES MADE IN PRIMARY CONTACT QUERY BY HAFEEZ ON DEC 20 2013,BECOZ CONTACT QUICK ADD SCREEN IS CUSTOMIZABLE
		EXEC @return_value =  spCOM_SetFeatureWiseContacts 86,@LeadID,2,@ContactsXML,@UserName,@Dt,@LangID  
		IF @return_value=-1000  
		BEGIN  
			RAISERROR('-500',16,1)  
		END   
	END  
	 
	--Inserts Multiple Notes  
	IF (@NotesXML IS NOT NULL AND @NotesXML <> '')  
	BEGIN  
		SET @XML=@NotesXML  

		--If Action is NEW then insert new Notes  
		INSERT INTO COM_Notes(FeatureID,CostCenterID,FeaturePK,Note,[GUID],CreatedBy,CreatedDate)  
		SELECT 86,86,@LeadID,Replace(X.value('@Note','NVARCHAR(MAX)'),'@~',''),newid(),@UserName,@Dt  
		FROM @XML.nodes('/NotesXML/Row') as Data(X)  
		WHERE X.value('@Action','NVARCHAR(10)')='NEW'  

		--If Action is MODIFY then update Notes  
		UPDATE COM_Notes SET Note=Replace(X.value('@Note','NVARCHAR(MAX)'),'@~','')
		,[GUID]=newid(),ModifiedBy=@UserName,ModifiedDate=@Dt  
		FROM COM_Notes C WITH(NOLOCK)  
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

		INSERT INTO COM_Files(FilePath,ActualFileName,RelativeFileName,FileExtension,FileDescription,
		IsProductImage,FeatureID,CostCenterID,FeaturePK,[GUID],CreatedBy,CreatedDate)  
		SELECT X.value('@FilePath','NVARCHAR(500)'),X.value('@ActualFileName','NVARCHAR(50)'),X.value('@RelativeFileName','NVARCHAR(50)'),  
		X.value('@FileExtension','NVARCHAR(50)'),X.value('@FileDescription','NVARCHAR(500)'),X.value('@IsProductImage','bit'),86,86,@LeadID,  
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
		[GUID]=X.value('@GUID','NVARCHAR(50)'),  
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
  
	
    if(@ProductXML is not null and @ProductXML <> '')
	begin	
		SET @XML=@ProductXML
		
		Delete from CRM_ProductMapping where CCNodeID = @LeadID and CostCenterID=86
			
		INSERT into CRM_ProductMapping(CCNodeID,CostCenterID,ProductID,CRMProduct,UOMID,[Description],
		   Quantity,CurrencyID, Alpha1, Alpha2, Alpha3, Alpha4, Alpha5, Alpha6, Alpha7, Alpha8, Alpha9, Alpha10, Alpha11, Alpha12, Alpha13, Alpha14, Alpha15, Alpha16, Alpha17, Alpha18, Alpha19, Alpha20, Alpha21, Alpha22, Alpha23, Alpha24, Alpha25, Alpha26, Alpha27, Alpha28, Alpha29, Alpha30, Alpha31, Alpha32, Alpha33, Alpha34, Alpha35, Alpha36, Alpha37, Alpha38, Alpha39, Alpha40, Alpha41, Alpha42, Alpha43, Alpha44, Alpha45, Alpha46,
		    Alpha47, Alpha48, Alpha49, Alpha50, CCNID1, CCNID2, CCNID3, CCNID4, CCNID5, CCNID6, CCNID7, CCNID8, CCNID9, CCNID10, CCNID11, CCNID12, CCNID13, CCNID14, CCNID15, CCNID16, CCNID17, CCNID18, CCNID19, CCNID20, CCNID21, CCNID22, CCNID23, CCNID24, CCNID25, CCNID26, CCNID27, CCNID28, CCNID29, CCNID30, CCNID31, CCNID32, CCNID33, CCNID34, CCNID35, CCNID36, CCNID37, CCNID38, CCNID39, CCNID40, CCNID41, CCNID42, CCNID43, CCNID44, CCNID45, CCNID46,
		    CCNID47, CCNID48, CCNID49, CCNID50,CompanyGUID,GUID,CreatedBy,CreatedDate)
		   select @LeadID,86,x.value('@Product','BIGINT'), x.value('@CRMProduct','BIGINT'),
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

		   @CompanyGUID,newid(),@UserName,convert(float,@Dt)
		   from @XML.nodes('XML/Row') as data(x)
		   where  x.value('@Product','BIGINT')is not null and   x.value('@Product','BIGINT') <> ''	
	end

	--Insert Notifications
	EXEC spCOM_SetNotifEvent @ActionType,86,@LeadID,@CompanyGUID,@UserName,@UserID,@RoleID
	
	IF @StatusID=416 --FOR CLOSED LEAD
	BEGIN
		EXEC spCOM_SetNotifEvent -1015,86,@LeadID,@CompanyGUID,@UserName,@UserID,@RoleID
	END
	 --ROLLBACK TRANSACTION
	
COMMIT TRANSACTION
 SELECT ErrorMessage,ErrorNumber FROM COM_ErrorMessages WITH(nolock)   
WHERE ErrorNumber=100 AND LanguageID=@LangID  
SET NOCOUNT OFF;    
RETURN @LeadID
END TRY    
BEGIN CATCH    
 --Return exception info [Message,Number,ProcedureName,LineNumber]    
    if @return_value=-999
		return -999;
	IF ERROR_NUMBER()=50000  
	BEGIN  
		IF ISNUMERIC(ERROR_MESSAGE())=1
		BEGIN
			SELECT ErrorMessage,ErrorNumber FROM COM_ErrorMessages WITH(nolock)   
			WHERE ErrorNumber=ERROR_MESSAGE() AND LanguageID=@LangID  
		END
		ELSE
			SELECT ERROR_MESSAGE() ErrorMessage
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

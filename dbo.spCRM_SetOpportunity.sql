USE PACT2C222
GO
SET ANSI_NULLS, QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spCRM_SetOpportunity]
	@OpportunityID [bigint] = 0,
	@Code [nvarchar](200) = null,
	@Subject [nvarchar](200) = NULL,
	@Description [nvarchar](500) = NULL,
	@StatusID [int],
	@IsGroup [bit],
	@SelectedNodeID [bigint],
	@ContactType [int] = 0,
	@Date [datetime] = null,
	@Leadid [int] = 0,
	@Contactid [int] = 0,
	@Campaignid [int] = 0,
	@Company [nvarchar](500),
	@EstimateRevenue [nvarchar](500) = NULL,
	@Currency [int] = 0,
	@EstimateCloseDate [datetime] = null,
	@Probabilityid [int] = 0,
	@Ratingid [int] = 0,
	@CloseDate [datetime] = null,
	@ProductXML [nvarchar](max) = null,
	@DocumentXML [nvarchar](max) = null,
	@ActivityXml [nvarchar](max) = null,
	@Details [nvarchar](max) = null,
	@Reasonid [int] = 0,
	@CustomFieldsQuery [nvarchar](max) = null,
	@CustomCostCenterFieldsQuery [nvarchar](max) = null,
	@NotesXML [nvarchar](max) = null,
	@AttachmentsXML [nvarchar](max) = null,
	@FeedbackXML [nvarchar](max) = null,
	@ContactsXML [nvarchar](max) = null,
	@PrimaryContactQuery [nvarchar](max),
	@Mode [int] = 0,
	@SelectedModeID [int] = 0,
	@tabdetails [nvarchar](max) = null,
	@CompanyGUID [nvarchar](50),
	@GUID [varchar](50),
	@UserName [nvarchar](50),
	@UserID [int] = 0,
	@LoginRoleID [int] = 0,
	@LangId [int] = 1,
	@CodePrefix [nvarchar](200) = NULL,
	@CodeNumber [bigint] = 0,
	@IsCode [bit] = 0
WITH ENCRYPTION, EXECUTE AS CALLER
AS
SET NOCOUNT ON 
	BEGIN TRANSACTION
	BEGIN TRY
	 
  select 'a'
    DECLARE @UpdateSql nvarchar(max),@Dt FLOAT, @lft bigint,@rgt bigint,@TempGuid nvarchar(50),@Selectedlft bigint,@Selectedrgt bigint,@HasAccess bit,@IsDuplicateNameAllowed bit,@IsOpportunityCodeAutoGen bit  ,@IsIgnoreSpace bit  ,
	@Depth int,@ParentID bigint,@SelectedIsGroup int ,@ActionType INT,  @XML XML,@DetailXML XML,@ParentCode nvarchar(200),@DetailContact int
	Declare @CostCenterID int
	declare @LocalXml XML ,@PRDXML XML,@DOCXML XML,@oppid int,@TabXML XML
	declare @ScheduleID int,@MaxCount int, @Count int, @stract nvarchar(max), @isRecur bit, @strsch nvarchar(max), @feq int
	set @CostCenterID=89
	
 set @TabXML =@tabdetails 
 set @DetailXML =@Details
  IF EXISTS(SELECT OpportunityID FROM CRM_Opportunities WITH(nolock) WHERE OpportunityID=@OpportunityID AND ParentID=0)  
   BEGIN  
    RAISERROR('-123',16,1)  
   END  
	 CREATE TABLE #tblActivities
			(rowno int ,ActivityID	bigint,ActivityTypeID	int,ScheduleID	int,CostCenterID	int,NodeID	int,
Status	int,Subject	nvarchar(MAX),Priority	int,PctComplete	float,Location	nvarchar(max),IsAllDayActivity	bit,
ActualCloseDate	float,ActualCloseTime	varchar(20),CustomerID	nvarchar(max),Remarks	nvarchar(MAX),AssignUserID	bigint,
AssignRoleID	bigint,AssignGroupID	bigint,Name	nvarchar(200),StatusID	int,
FreqType	int,FreqInterval	int,FreqSubdayType	int,FreqSubdayInterval	int,FreqRelativeInterval	int,
FreqRecurrenceFactor	int,StartDate	nvarchar(20),EndDate	nvarchar(20),StartTime	nvarchar(20),
EndTime	nvarchar(20),Message	nvarchar(MAX),isRecur bit)

  --GETTING PREFERENCE  
  SELECT @IsDuplicateNameAllowed=Value FROM COM_CostCenterPreferences WITH(nolock) WHERE COSTCENTERID=89 and  Name='DuplicateNameAllowed'  
  SELECT @IsOpportunityCodeAutoGen=Value FROM COM_CostCenterPreferences  WITH(nolock) WHERE COSTCENTERID=89 and  Name='CodeAutoGen'  
  SELECT @IsIgnoreSpace=Value FROM COM_CostCenterPreferences  WITH(nolock) WHERE COSTCENTERID=89 and  Name='IgnoreSpaces'  
    IF @IsCode=1 and @IsOpportunityCodeAutoGen IS NOT NULL AND @IsOpportunityCodeAutoGen=1 AND @OpportunityID=0 and @CodePrefix=''  
	BEGIN 
		--CALL AUTOCODEGEN 
		create table #temp1(prefix nvarchar(100),number bigint, suffix nvarchar(100), code nvarchar(200), IsManualcode bit)
		if(@SelectedNodeID is null)
		insert into #temp1
		EXEC [spCOM_GetCodeData] 89,1,''  
		else
		insert into #temp1
		EXEC [spCOM_GetCodeData] 89,@SelectedNodeID,''  
		--select * from #temp1
		select @Code=code,@CodePrefix= prefix, @CodeNumber=number from #temp1
		--select @AccountCode,@ParentID
	END	
	  --User acces check FOR ACCOUNTS  
  IF @OpportunityID=0  
  BEGIN
	SET @ActionType=1
   SET @HasAccess=dbo.fnCOM_HasAccess(@LoginRoleID,89,1)  
  END  
  ELSE  
  BEGIN  
	SET @ActionType=3
   SET @HasAccess=dbo.fnCOM_HasAccess(@LoginRoleID,89,3)  
  END  
  
  IF @HasAccess=0  
  BEGIN  
   RAISERROR('-105',16,1)  
  END  
  
  IF @MODE=0
  BEGIN
  --DUPLICATE CHECK  
  IF @IsDuplicateNameAllowed IS NOT NULL AND @IsDuplicateNameAllowed=0  
  BEGIN  
    IF @IsIgnoreSpace IS NOT NULL AND @IsIgnoreSpace=1  
   BEGIN  
    IF @OpportunityID=0  
    BEGIN  
     IF EXISTS (SELECT OpportunityID FROM CRM_Opportunities WITH(nolock) WHERE replace(Company,' ','')=replace(@Company,' ','') AND MODE=0)  
     BEGIN  
      RAISERROR('-112',16,1)  
     END  
    END  
    ELSE  
    BEGIN  
     IF EXISTS (SELECT OpportunityID FROM CRM_Opportunities WITH(nolock) WHERE replace(Company,' ','')=replace(@Company,' ','')  AND MODE=0 AND OpportunityID <> @OpportunityID)  
     BEGIN  
      RAISERROR('-112',16,1)       
     END  
    END  
   END  
   ELSE  
   BEGIN  
    IF @OpportunityID=0  
    BEGIN  
     IF EXISTS (SELECT OpportunityID FROM CRM_Opportunities WITH(nolock) WHERE Company=@Company AND MODE=0 )  
     BEGIN  
      RAISERROR('-112',16,1)  
     END  
    END  
    ELSE  
    BEGIN  
     IF EXISTS (SELECT OpportunityID FROM CRM_Opportunities WITH(nolock) WHERE Company=@Company  AND MODE=0 AND OpportunityID <> @OpportunityID)  
     BEGIN  
      RAISERROR('-112',16,1)  
     END  
    END  
   END
  END	  
END  
   --User acces check FOR Notes  
  IF (@NotesXML IS NOT NULL AND @NotesXML <> '')  
  BEGIN  
   SET @HasAccess=dbo.fnCOM_HasAccess(@LoginRoleID,89,8)  
  
   IF @HasAccess=0  
   BEGIN  
    RAISERROR('-105',16,1)  
   END  
  END  
  
  --User acces check FOR Attachments  
  IF (@AttachmentsXML IS NOT NULL AND @AttachmentsXML <> '')  
  BEGIN  
   SET @HasAccess=dbo.fnCOM_HasAccess(@LoginRoleID,89,12)  
  
   IF @HasAccess=0  
   BEGIN  
    RAISERROR('-105',16,1)  
   END  
  END  
  
	SET @Dt=convert(float,getdate())--Setting Current Date  

	set @PRDXML=@ProductXML
	set @DOCXML=@DocumentXML
	set @oppid=@OpportunityID


  declare 
 @FirstName NVARCHAR(50),
 @MiddleName NVARCHAR(50),
 @LastName NVARCHAR(50),
 @Salutation bigint,
 @jobTitle NVARCHAR(50),
 @Phone1 NVARCHAR(50),
 @Phone2 NVARCHAR(50),
 @Email NVARCHAR(50),
 @Fax NVARCHAR(50),
 @Department NVARCHAR(50),
 @RoleID bigint,
 @Address1 NVARCHAR(50),
 @Address2 NVARCHAR(50),
 @Address3 NVARCHAR(50),
 @City NVARCHAR(50),
 @State NVARCHAR(50),
 @Zip NVARCHAR(50),
 @CountryID bigint,
 @Gender NVARCHAR(50),
 @Birthday datetime,
 @Anniversary datetime,
 @PreferredID bigint,
 @PreferredName NVARCHAR(50)

 create table #detailtbl(
 FirstName NVARCHAR(50)  null,
 MiddleName NVARCHAR(50)  null,
 LastName NVARCHAR(50)  null,
 Salutation bigint  null,
 jobTitle NVARCHAR(50)  null,
 Phone1 NVARCHAR(50)  null,
 Phone2 NVARCHAR(50)  null,
 Email NVARCHAR(50)  null,
 Fax NVARCHAR(50)  null,
 Department NVARCHAR(50)  null,
 RoleID bigint  null)

 if(@DetailXML is not null)
 begin
 insert into #detailtbl
 select x.value('@FirstName','NVARCHAR(50)'),x.value('@MiddleName','NVARCHAR(50)'),x.value('@LastName','NVARCHAR(50)'),x.value('@Salutation','bigint'),
 x.value('@JobTitle','NVARCHAR(50)'),x.value('@Phone1','NVARCHAR(50)'),x.value('@Phone2','NVARCHAR(50)'),x.value('@Email','NVARCHAR(50)'),x.value('@Fax','NVARCHAR(50)'),
 x.value('@Department','NVARCHAR(50)'),x.value('@Role','bigint') from  @DetailXML.nodes('Row') as data(x)
 end
   create table #tabdetailtbl(
 Address1 NVARCHAR(50) null,
 Address2 NVARCHAR(50) null,
 Address3 NVARCHAR(50) null,
 City NVARCHAR(50) null,
 State NVARCHAR(50) null,
 Zip NVARCHAR(50) null,
 CountryID bigint null 
  )
 
 if(@TabXML is not null)
 begin
 insert into #tabdetailtbl
 select x.value('@Address1','NVARCHAR(50)'),x.value('@Address2','NVARCHAR(50)'),x.value('@Address3','NVARCHAR(50)'),
 x.value('@City','NVARCHAR(50)'),x.value('@State','NVARCHAR(50)'),x.value('@Zip','NVARCHAR(50)'),x.value('@Country','bigint') 
 from  @TabXML.nodes('Row') as data(x)
 end

 select @FirstName=FirstName,@MiddleName=MiddleName,@LastName=LastName,@Salutation=Salutation,@jobTitle=jobTitle,@Phone1=Phone1,@Phone2=Phone2,
 @Email=Email,@Fax=Fax,@Department=Department,@RoleID=RoleID from #detailtbl

  select @Address1=Address1,
 @Address2 =Address2,
 @Address3 =Address3,
 @City =City,
 @State =State,
 @Zip =Zip,
 @CountryID =CountryID 
  from #tabdetailtbl
 
IF @CountryID='' OR @CountryID IS NULL
 SET @CountryID=NULL

	 IF @OpportunityID= 0--------START INSERT RECORD-----------  
		BEGIN--CREATE Lead  
  	  --To Set Left,Right And Depth of Record  
				SELECT @SelectedIsGroup=IsGroup,@Selectedlft =lft,@Selectedrgt=rgt,@ParentID=ParentID,@Depth=Depth  
				from CRM_Opportunities with(NOLOCK) where OpportunityID=@SelectedNodeID  
			   
				--IF No Record Selected or Record Doesn't Exist  
				if(@SelectedIsGroup is null)   
				 select @SelectedNodeID=LeadID,@SelectedIsGroup=IsGroup,@Selectedlft =lft,@Selectedrgt=rgt,@ParentID=ParentID,@Depth=Depth  
				 from CRM_Opportunities with(NOLOCK) where ParentID =0  
			         
				if(@SelectedIsGroup = 1)--Adding Node Under the Group  
				 BEGIN  
				  UPDATE CRM_Opportunities SET rgt = rgt + 2 WHERE rgt > @Selectedlft;  
				  UPDATE CRM_Opportunities SET lft = lft + 2 WHERE lft > @Selectedlft;  
				  set @lft =  @Selectedlft + 1  
				  set @rgt = @Selectedlft + 2  
				  set @ParentID = @SelectedNodeID  
				  set @Depth = @Depth + 1  
				 END  
				else if(@SelectedIsGroup = 0)--Adding Node at Same level  
				 BEGIN  
				  UPDATE CRM_Opportunities SET rgt = rgt + 2 WHERE rgt > @Selectedrgt;  
				  UPDATE CRM_Opportunities SET lft = lft + 2 WHERE lft > @Selectedrgt;  
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
  
     
			if(@ContactType IS NOT NULL AND @ContactType <> '' AND @ContactType <> 53)
				begin
					set @DetailContact = 1
				end
	    	else
		    	begin
					set @DetailContact = 1
				end
									
					set @GUID= NEWID()
				
				 INSERT INTO CRM_Opportunities
						(DetailsContactID,
					     CodePrefix,CodeNumber,Code,
						 Subject,
						 StatusID,
						 Date,LeadID,CampaignID,Company,EstimatedRevenue,CurrencyID,EstimatedCloseDate,ProbabilityLookUpID,RatingLookUpID,
						 CloseDate,ReasonLookUpID,Description
						,Depth
						,ParentID
						,lft
						,rgt
						,IsGroup
						,CompanyGUID
						,GUID
						,CreatedBy
						,CreatedDate,Mode,SelectedModeID,ContactID)
				Values 
						(@DetailContact,
						@CodePrefix,@CodeNumber,@Code,
						@Subject,
						@StatusID,
						convert(float,@Date),
						@Leadid,
						@Campaignid,
						@Company,
						@EstimateRevenue,
						@Currency,
						convert(float,@EstimateCloseDate),
						@Probabilityid,
						@Ratingid,
						convert(float,@CloseDate),
						@Reasonid,
						@Description
						,@Depth
						,@ParentID
						,@lft
						,@rgt
						,@IsGroup
						,@CompanyGUID
						,newid()
						,@UserName
						,convert(float,@Dt),@Mode,@SelectedModeID,@ContactID)
				 
				 SET @OpportunityID=SCOPE_IDENTITY() 
				 
insert into CRM_CONTACTS
          (FeatureID,FeaturePK,
           FirstName,
           MiddleName,
           LastName,
           SalutationID,
           JobTitle,
           Company,
           StatusID,
           Phone1,
           Phone2,
           Email1,
           Fax,
           Department  
           ,CompanyGUID
           ,GUID
           ,CreatedBy
           ,CreatedDate, Address1,
           Address2,
           Address3,
           City,
           State,
           Zip,
           Country)
          values
          (89,@OpportunityID,
          @FirstName,
          @MiddleName,
          @LastName,
          @Salutation,
          @jobTitle,
          @Company,
          @StatusID,
          @Phone1,
          @Phone2,
          @Email,
          @Fax,
          @Department  
          ,@CompanyGUID
          ,newid()
          ,@UserName
          ,convert(float,@Dt),@Address1,
          @Address2,
          @Address3,
          @City,
          @State,
          @Zip,
          @CountryID)



				  --Handling of Extended Table  
    INSERT INTO CRM_OpportunitiesExtended(OpportunityID,[CreatedBy],[CreatedDate])  
    VALUES(@OpportunityID, @UserName, @Dt)  
  
    --Handling of CostCenter Costcenters Extrafields Table 

   INSERT INTO COM_CCCCDATA ([CostCenterID] ,[NodeID] ,[Guid],[CreatedBy],[CreatedDate])
     VALUES(89,@OpportunityID,newid(),  @UserName, @Dt) 

	        DECLARE @return_value int,@LinkCostCenterID INT
			SELECT @LinkCostCenterID=ISNULL([Value],0) FROM COM_CostCenterPreferences WITH(NOLOCK) 
			WHERE FeatureID=89 AND [Name]='OppLinkDimension'
		 
			IF @LinkCostCenterID>0 AND @IsGroup=0  
			BEGIN
			print @Company
			print @Code
				EXEC @return_value = [dbo].[spCOM_SetCostCenter]
					@NodeID = 0,@SelectedNodeID = 0,@IsGroup = 0,
					@Code = @Code,
					@Name = @Company,
					@AliasName=@Company,
					@PurchaseAccount=0,@SalesAccount=0,@StatusID=@StatusID,
					@CustomFieldsQuery=NULL,@AddressXML=NULL,@AttachmentsXML=NULL,
					@CustomCostCenterFieldsQuery=NULL,@ContactsXML=NULL,@NotesXML=NULL,
					@CostCenterID =@LinkCostCenterID,@CompanyGUID=@COMPANYGUID,@GUID='GUID',@UserName=@USERNAME,@RoleID=1,@UserID=@USERID
				 
					--@return_value
					UPDATE [CRM_Opportunities]
					SET CCOpportunityID=@return_value
					WHERE OpportunityID=@OpportunityID
			END
		
		 --INSERT PRIMARY CONTACT  
		INSERT  [COM_Contacts]  
		([AddressTypeID]  
		,[FeatureID]  
		,[FeaturePK]  
		,[CompanyGUID]  
		,[GUID]   
		,[CreatedBy]  
		,[CreatedDate]  
		)  
		VALUES  
		(1  
		,89  
		,@OpportunityID  
		,@CompanyGUID  
		,NEWID()  
		,@UserName,@Dt  
		)  
		INSERT INTO COM_ContactsExtended(ContactID,[CreatedBy],[CreatedDate])
			 		VALUES(SCOPE_IDENTITY(), @UserName, convert(float,getdate()))
				 	
				
		END --------END INSERT RECORD-----------  
	ELSE  --------START UPDATE RECORD----------- 	
		BEGIN
			 SELECT @TempGuid=[GUID] from CRM_Opportunities  WITH(NOLOCK)   
			   WHERE OpportunityID=@OpportunityID
			  
			   IF(@TempGuid!=@Guid)--IF RECORD ALREADY UPDATED BY SOME OTHER USER i.e DIRTY READ    
			   BEGIN    
				   RAISERROR('-101',16,1)   
			   END    
			   ELSE    
			   BEGIN  
  
						UPDATE CRM_Opportunities
					    SET [Code]=@Code,
						[Subject]=@Subject,
						StatusID=@StatusID,
						Date=convert(float,@Date),
						LeadID=@Leadid,ContactID=@ContactID,
						CampaignID=@Campaignid,
						Company=@Company,
						EstimatedRevenue=@EstimateRevenue,
						CurrencyID=@Currency,
						EstimatedCloseDate=convert(float,@EstimateCloseDate),
						ProbabilityLookUpID=@Probabilityid,
						RatingLookUpID=@Ratingid, [ModifiedBy] = @UserName
						,[ModifiedDate] = @Dt,
						CloseDate=convert(float,@CloseDate),SelectedModeID=@SelectedModeID,Mode=@Mode,
						ReasonLookUpID=@Reasonid
						WHERE OpportunityID = @OpportunityID
						
					       --Update Extra fields
			
					  
						 if( @DetailXML is not null)
						  begin
						  Update CRM_CONTACTS set 
						   FirstName=@FirstName,
						   MiddleName=@MiddleName,
						   LastName=@LastName,
						   SalutationID=@Salutation,
						   JobTitle=@jobTitle,
						   Company=@Company,
						   StatusID=@StatusID,
						   Phone1=@Phone1,
						   Phone2=@Phone2,
						   Email1=@Email,Address1=@Address1,
						   Address2=@Address2,
						   Address3=@Address3,
						   City=@City,
						   State=@State,
						   Zip=@Zip,
						   Country=@CountryID,
						   Fax=@Fax,
						   Department=@Department 
						   where FeaturePK=@OpportunityID and Featureid=89 
								end	 
			   END
		  END 
		  
	  		  set @UpdateSql='update [CRM_OpportunitiesExtended]
				  SET '+@CustomFieldsQuery+' [ModifiedBy] ='''+ @UserName
					+''',[ModifiedDate] =' + convert(nvarchar,@Dt) +' WHERE OpportunityID='+convert(nvarchar,@OpportunityID)
				 
				  exec(@UpdateSql)
					  
		      set @UpdateSql='update COM_CCCCDATA  
			 SET '+@CustomCostCenterFieldsQuery+'[ModifiedBy] ='''+ @UserName+''',[ModifiedDate] =' + convert(nvarchar,@Dt) +' WHERE NodeID = '+convert(nvarchar,@OpportunityID) + ' AND CostCenterID = 89' 
				 exec(@UpdateSql)  

	  --ADDED CONDIDTION ON JAN 30 2013 BY HAFEEZ
	  --TO SET OPPORTUNITY LINK DIMENSION=@@OpportunityID AND MAKE THAT COLUMN AS READONLY
	  IF(EXISTS(SELECT VALUE FROM COM_COSTCENTERPREFERENCES WHERE COSTCENTERID=89 AND NAME='OPPLINKDIMENSION'))
	  BEGIN
			DECLARE @DIMID BIGINT
			SET @DIMID=0
			SELECT @DIMID=VALUE-50000 FROM COM_COSTCENTERPREFERENCES WHERE COSTCENTERID=89 AND NAME='OPPLINKDIMENSION'
			IF(@DIMID>0)
			BEGIN
					SET @UpdateSql=' UPDATE COM_CCCCDATA SET CCNID'+CONVERT(NVARCHAR(30),@DIMID)+'=
					(SELECT CCOpportunityID FROM CRM_Opportunities WHERE OpportunityID='+convert(nvarchar,@OpportunityID) + ') 
									WHERE NodeID = '+convert(nvarchar,@OpportunityID) + ' AND CostCenterID = 89'
					  exec(@UpdateSql)  
			END
	  END				
		  
   IF  @FeedbackXML IS NOT NULL
	BEGIN
	DECLARE @DATAFEEDBACK XML
	SET @DATAFEEDBACK=@FeedbackXML
	
				Delete from CRM_FEEDBACK where CCNodeID = @OpportunityID and CCID=89
			 
					INSERT into CRM_FEEDBACK
				   select 89,@OpportunityID,
			       convert(float,x.value('@Date','datetime')),x.value('@FeedBack','nvarchar(200)'), @UserName,convert(float,@Dt),x.value('@Alpha1','nvarchar(200)'),x.value('@Alpha2','nvarchar(200)'),x.value('@Alpha3','nvarchar(200)'),x.value('@Alpha4','nvarchar(200)'),x.value('@Alpha5','nvarchar(200)'),
			       x.value('@Alpha6','nvarchar(200)'),x.value('@Alpha7','nvarchar(200)'),x.value('@Alpha8','nvarchar(200)'),x.value('@Alpha9','nvarchar(200)'),x.value('@Alpha10','nvarchar(200)'),
			       x.value('@Alpha11','nvarchar(200)'),x.value('@Alpha12','nvarchar(200)'),x.value('@Alpha13','nvarchar(200)'),x.value('@Alpha14','nvarchar(200)'),x.value('@Alpha15','nvarchar(200)'),
			       x.value('@Alpha16','nvarchar(200)'),x.value('@Alpha17','nvarchar(200)'),x.value('@Alpha18','nvarchar(200)'),x.value('@Alpha19','nvarchar(200)'),x.value('@Alpha20','nvarchar(200)'),
			       x.value('@Alpha21','nvarchar(200)'),x.value('@Alpha22','nvarchar(200)'),x.value('@Alpha23','nvarchar(200)'),x.value('@Alpha24','nvarchar(200)'),x.value('@Alpha25','nvarchar(200)'),
			       x.value('@Alpha26','nvarchar(200)'),x.value('@Alpha27','nvarchar(200)'),x.value('@Alpha28','nvarchar(200)'),x.value('@Alpha29','nvarchar(200)'),x.value('@Alpha30','nvarchar(200)'),
			       x.value('@Alpha31','nvarchar(200)'),x.value('@Alpha32','nvarchar(200)'),x.value('@Alpha33','nvarchar(200)'),x.value('@Alpha34','nvarchar(200)'),x.value('@Alpha35','nvarchar(200)'),
			       x.value('@Alpha36','nvarchar(200)'),x.value('@Alpha37','nvarchar(200)'),x.value('@Alpha38','nvarchar(200)'),x.value('@Alpha39','nvarchar(200)'),x.value('@Alpha40','nvarchar(200)'),
			       x.value('@Alpha41','nvarchar(200)'),x.value('@Alpha42','nvarchar(200)'),x.value('@Alpha43','nvarchar(200)'),x.value('@Alpha44','nvarchar(200)'),x.value('@Alpha45','nvarchar(200)'),
			       x.value('@Alpha46','nvarchar(200)'),x.value('@Alpha47','nvarchar(200)'),x.value('@Alpha48','nvarchar(200)'),x.value('@Alpha49','nvarchar(200)'),x.value('@Alpha50','nvarchar(200)'),
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
				   from @DATAFEEDBACK.nodes('XML/Row') as data(x)
				    
				   
	END

		  exec spCom_SetActivitiesAndSchedules @ActivityXml,@CostCenterID,@OpportunityID,@CompanyGUID,@Guid,@UserName,@dt,@LangID 
		  set @LocalXml=@ActivityXml
		  
		  Delete from CRM_ProductMapping where CCNodeID = @OpportunityID and CostCenterID=89
		   if(@ProductXML is not null and @ProductXML <> '')
		   begin
					 
								 
				   INSERT into CRM_ProductMapping(CCNodeID,CostCenterID,ProductID,CRMProduct,UOMID,Description,
				   Quantity,CurrencyID, Alpha1, Alpha2, Alpha3, Alpha4, Alpha5, Alpha6, Alpha7, Alpha8, Alpha9, Alpha10, Alpha11, Alpha12, Alpha13, Alpha14, Alpha15, Alpha16, Alpha17, Alpha18, Alpha19, Alpha20, Alpha21, Alpha22, Alpha23, Alpha24, Alpha25, Alpha26, Alpha27, Alpha28, Alpha29, Alpha30, Alpha31, Alpha32, Alpha33, Alpha34, Alpha35, Alpha36, Alpha37, Alpha38, Alpha39, Alpha40, Alpha41, Alpha42, Alpha43, Alpha44, Alpha45, Alpha46,
				    Alpha47, Alpha48, Alpha49, Alpha50, CCNID1, CCNID2, CCNID3, CCNID4, CCNID5, CCNID6, CCNID7, CCNID8, CCNID9, CCNID10, CCNID11, CCNID12, CCNID13, CCNID14, CCNID15, CCNID16, CCNID17, CCNID18, CCNID19, CCNID20, CCNID21, CCNID22, CCNID23, CCNID24, CCNID25, CCNID26, CCNID27, CCNID28, CCNID29, CCNID30, CCNID31, CCNID32, CCNID33, CCNID34, CCNID35, CCNID36, CCNID37, CCNID38, CCNID39, CCNID40, CCNID41, CCNID42, CCNID43, CCNID44, CCNID45, CCNID46,
				    CCNID47, CCNID48, CCNID49, CCNID50,CompanyGUID,GUID,CreatedBy,CreatedDate)
				   select @OpportunityID,89,
			       x.value('@Product','BIGINT'),  x.value('@CRMProduct','BIGINT'),
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
				   from @PRDXML.nodes('XML/Row') as data(x)
				   where  x.value('@Product','BIGINT')is not null and   x.value('@Product','BIGINT') <> ''				   
				    
				
			end

    	  if(@DocumentXML is not null and @DocumentXML <> '')
		begin
			insert into CRM_OpportunityDocMap(OpportunityID,DocID,CompanyGUID,GUID,CreatedBy,CreatedDate)
		    select @OpportunityID,
			       x.value('@DocID','BIGINT'),
				   @CompanyGUID,
				   newid(),
				   @UserName,
				   convert(float,@Dt) 
				   from @DOCXML.nodes('OppDocXML/Row') as data(x)
				   where  x.value('@Action','nvarchar(50)')='NEW'and @oppid=0
		
			update CRM_OpportunityDocMap set 
			DocID= x.value('@DocID','BIGINT')
			from @DOCXML.nodes('OppDocXML/Row') as data(x) 
			where OpportunityID = @OpportunityID and  x.value('@Action','nvarchar(50)')='MODIFY'and @oppid<>0

		end
	--Inserts Multiple Notes  
  IF (@NotesXML IS NOT NULL AND @NotesXML <> '')  
  BEGIN  
   SET @XML=@NotesXML  
  
   --If Action is NEW then insert new Notes  
   INSERT INTO COM_Notes(FeatureID,CostCenterID,FeaturePK,Note,     
   GUID,CreatedBy,CreatedDate)  
   SELECT 89,89,@OpportunityID,Replace(X.value('@Note','NVARCHAR(MAX)'),'@~','
'),  
   newid(),@UserName,@Dt  
   FROM @XML.nodes('/NotesXML/Row') as Data(X)  
   WHERE X.value('@Action','NVARCHAR(10)')='NEW'  
  
   --If Action is MODIFY then update Notes  
   UPDATE COM_Notes  
   SET Note=Replace(X.value('@Note','NVARCHAR(MAX)'),'@~','
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
   X.value('@FileExtension','NVARCHAR(50)'),X.value('@FileDescription','NVARCHAR(500)'),X.value('@IsProductImage','bit'),89,89,@OpportunityID,  
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
  
   -- , BEFORE MODIFIEDBY  REQUIRES A NULL CHECK OF @PrimaryContactQuery 
  IF(@PrimaryContactQuery IS NOT NULL AND @PrimaryContactQuery<>'')
  BEGIN  
		--CHANGES MADE IN PRIMARY CONTACT QUERY BY HAFEEZ ON DEC 20 2013,BECOZ CONTACT QUICK ADD SCREEN IS CUSTOMIZABLE
		EXEC spCOM_SetFeatureWiseContacts 89,@OpportunityID,1,@PrimaryContactQuery,@UserName,@Dt,@LangID
  END
  
  --Inserts Multiple Contacts  
  IF (@ContactsXML IS NOT NULL AND @ContactsXML <> '')  
  BEGIN  
		--CHANGES MADE IN PRIMARY CONTACT QUERY BY HAFEEZ ON DEC 20 2013,BECOZ CONTACT QUICK ADD SCREEN IS CUSTOMIZABLE 
		 declare @rValue int
		EXEC @rValue =  spCOM_SetFeatureWiseContacts 89,@OpportunityID,2,@ContactsXML,@UserName,@Dt,@LangID   
		 IF @rValue=-1000  
		  BEGIN  
			RAISERROR('-500',16,1)  
		  END   
  END  
  
  
  --Insert Notifications
	EXEC spCOM_SetNotifEvent @ActionType,89,@OpportunityID,@CompanyGUID,@UserName,@UserID,@LoginRoleID
	
	IF EXISTS (SELECT * FROM CRM_Opportunities WHERE OpportunityID=@OpportunityID AND CloseDate IS NOT NULL AND LEN(CLOSEDATE)>0)
	BEGIN
			EXEC spCOM_SetNotifEvent -1015,89,@OpportunityID,@CompanyGUID,@UserName,@UserID,@LoginRoleID
	END

	COMMIT TRANSACTION
	SELECT ErrorMessage,ErrorNumber FROM COM_ErrorMessages WITH(nolock)   
WHERE ErrorNumber=100 AND LanguageID=@LangID  
SET NOCOUNT OFF;    
RETURN @OpportunityID
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

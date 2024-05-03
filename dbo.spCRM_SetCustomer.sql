USE PACT2C222
GO
SET ANSI_NULLS, QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spCRM_SetCustomer]
	@CustomerID [bigint],
	@CustomerCode [nvarchar](200),
	@CustomerName [nvarchar](500),
	@AliasName [nvarchar](50) = null,
	@SelectedTypeId [int] = 0,
	@StatusID [int],
	@AccountID [int],
	@SelectedNodeID [bigint] = null,
	@IsGroup [bit] = null,
	@CreditDays [int] = 0,
	@CreditLimit [float] = 0,
	@CompanyGUID [varchar](50),
	@GUID [varchar](50),
	@Description [nvarchar](500) = null,
	@UserName [nvarchar](50),
	@CustomFieldsQuery [nvarchar](max) = null,
	@CustomCostCenterFieldsQuery [nvarchar](max) = null,
	@ContactsXML [nvarchar](max) = null,
	@AttachmentsXML [nvarchar](max) = null,
	@NotesXML [nvarchar](max) = null,
	@AddressXML [nvarchar](max) = null,
	@ActivityXml [nvarchar](max),
	@AssignCCCCData [nvarchar](max) = null,
	@FromImport [bit] = 0,
	@PrimaryContactQuery [nvarchar](max) = null,
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
		DECLARE @Dt float,@XML xml,@TempGuid nvarchar(50),@HasAccess bit,@IsDuplicateNameAllowed bit,@IsCodeAutoGen bit,@IsIgnoreSpace bit
		DECLARE @UpdateSql nvarchar(max),@ParentCode nvarchar(200)
		DECLARE @lft bigint,@rgt bigint,@Selectedlft bigint,@Selectedrgt bigint,@Depth int,@ParentID bigint
		DECLARE @SelectedIsGroup bit ,  @I INT, @COUNT INT ,@VCOUNT INT

		Declare @CostCenterID int
	declare @LocalXml XML 
	declare @ScheduleID int
 declare @MaxCount int
 
	declare @stract nvarchar(max)
	declare @isRecur bit
		declare @strsch nvarchar(max)
		declare @feq int
	set @CostCenterID=83


--	 CREATE TABLE #tblActivities
--			(rowno int ,ActivityID	bigint,ActivityTypeID	int,ScheduleID	int,CostCenterID	int,NodeID	int,
--Status	int,Subject	nvarchar(MAX),Priority	int,PctComplete	float,Location	nvarchar(max),IsAllDayActivity	bit,
--ActualCloseDate	float,ActualCloseTime	varchar(20),CustomerID	nvarchar(max),Remarks	nvarchar(MAX),AssignUserID	bigint,
--AssignRoleID	bigint,AssignGroupID	bigint,Name	nvarchar(200),StatusID	int,
--FreqType	int,FreqInterval	int,FreqSubdayType	int,FreqSubdayInterval	int,FreqRelativeInterval	int,
--FreqRecurrenceFactor	int,StartDate	nvarchar(20),EndDate	nvarchar(20),StartTime	nvarchar(20),
--EndTime	nvarchar(20),Message	nvarchar(MAX),isRecur bit)

		--User acces check FOR Customer 
		IF @CustomerID=0
		BEGIN
			SET @HasAccess=dbo.fnCOM_HasAccess(@RoleID,83,1)
		END
		ELSE
		BEGIN
			SET @HasAccess=dbo.fnCOM_HasAccess(@RoleID,83,3)
		END

		IF @HasAccess=0
		BEGIN
			RAISERROR('-105',16,1)
		END

		--User acces check FOR Notes
		IF (@NotesXML IS NOT NULL AND @NotesXML <> '')
		BEGIN
			SET @HasAccess=dbo.fnCOM_HasAccess(@RoleID,83,8)

			IF @HasAccess=0
			BEGIN
				RAISERROR('-105',16,1)
			END
		END

		--User acces check FOR Attachments
		IF (@AttachmentsXML IS NOT NULL AND @AttachmentsXML <> '')
		BEGIN
			SET @HasAccess=dbo.fnCOM_HasAccess(@RoleID,83,12)

			IF @HasAccess=0
			BEGIN
				RAISERROR('-105',16,1)
			END
		END

		--User acces check FOR Contacts
		IF (@ContactsXML IS NOT NULL AND @ContactsXML <> '')
		BEGIN
			SET @HasAccess=dbo.fnCOM_HasAccess(@RoleID,83,16)

			IF @HasAccess=0
			BEGIN
				RAISERROR('-105',16,1)
			END
		END


		--GETTING PREFERENCE
		SELECT @IsDuplicateNameAllowed=Value FROM COM_CostCenterPreferences WITH(nolock) WHERE CostCenterID=83 and  Name='DuplicateNameAllowed'
		SELECT @IsCodeAutoGen=Value FROM COM_CostCenterPreferences  WITH(nolock) WHERE CostCenterID=83 and  Name='CodeAutoGen'
		SELECT @IsIgnoreSpace=Value FROM COM_CostCenterPreferences  WITH(nolock) WHERE COSTCENTERID=83 and  Name='IgnoreSpaces'  
		IF @IsCode=1 and @IsCodeAutoGen IS NOT NULL AND @IsCodeAutoGen=1 AND @CustomerID=0 and @CodePrefix=''  
		BEGIN 
			--CALL AUTOCODEGEN 
			create table #temp1(prefix nvarchar(100),number bigint, suffix nvarchar(100), code nvarchar(200), IsManualcode bit)
			if(@SelectedNodeID is null)
			insert into #temp1
			EXEC [spCOM_GetCodeData] 83,1,''  
			else
			insert into #temp1
			EXEC [spCOM_GetCodeData] 83,@SelectedNodeID,''  
			
			--select * from #temp1
			select @CustomerCode=code,@CodePrefix= prefix, @CodeNumber=number from #temp1
			--select @AccountCode,@ParentID
		END	
		--DUPLICATE CHECK
		IF @IsDuplicateNameAllowed IS NOT NULL AND @IsDuplicateNameAllowed=0
		BEGIN
			IF @IsIgnoreSpace IS NOT NULL AND @IsIgnoreSpace=1  
			BEGIN  
				IF @CustomerID=0  
				BEGIN  
				 IF EXISTS (SELECT CustomerID FROM CRM_Customer WITH(nolock) WHERE replace(CustomerName,' ','')=replace(@CustomerName,' ',''))  
				  RAISERROR('-108',16,1)  
				END  
				ELSE  
				BEGIN  
				 IF EXISTS (SELECT CustomerID FROM CRM_Customer WITH(nolock) WHERE replace(CustomerName,' ','')=replace(@CustomerName,' ','') AND CustomerID <> @CustomerID)  
				  RAISERROR('-108',16,1)       
				END  
			END  
			ELSE  
			BEGIN
				IF @CustomerID=0
				BEGIN
					IF EXISTS (SELECT CustomerID FROM CRM_Customer WITH(nolock) WHERE CustomerName=@CustomerName)
					BEGIN
						RAISERROR('-345',16,1)
					END
				END
				ELSE
				BEGIN
					IF EXISTS (SELECT CustomerID FROM CRM_Customer WITH(nolock) WHERE CustomerName=@CustomerName AND CustomerID <> @CustomerID)
					BEGIN
						RAISERROR('-345',16,1)
					END
				END
			END
		END 
		
		
		IF @IsCodeAutoGen IS NOT NULL AND @IsCodeAutoGen=0
		BEGIN
			IF @CustomerID=0
			BEGIN
				IF EXISTS (SELECT CustomerID FROM CRM_Customer WITH(nolock) WHERE CustomerCode=@CustomerCode)
				BEGIN
					RAISERROR('-116',16,1)
				END
			END
			ELSE
			BEGIN
				IF EXISTS (SELECT CustomerID FROM CRM_Customer WITH(nolock) WHERE CustomerCode=@CustomerCode AND CustomerID <> @CustomerID)
				BEGIN
					RAISERROR('-116',16,1)
				END
			END
		END

		SET @Dt=convert(float,getdate())--Setting Current Date
		
		IF @CustomerID=0--------START INSERT RECORD-----------
		BEGIN--CREATE Customer--
				
				--To Set Left,Right And Depth of Record
				SELECT @SelectedIsGroup=IsGroup,@Selectedlft =lft,@Selectedrgt=rgt,@ParentID=ParentID,@Depth=Depth
				from [CRM_Customer] with(NOLOCK) where CustomerID=@SelectedNodeID
 
				--IF No Record Selected or Record Doesn't Exist
				if(@SelectedIsGroup is null) 
					select @SelectedNodeID=CustomerID,@SelectedIsGroup=IsGroup,@Selectedlft =lft,@Selectedrgt=rgt,@ParentID=ParentID,@Depth=Depth
					from [CRM_Customer] with(NOLOCK) where ParentID =0
							
				 
				if(@SelectedIsGroup = 1)--Adding Node Under the Group
					BEGIN
					 
						UPDATE CRM_Customer SET rgt = rgt + 2 WHERE rgt > @Selectedlft;
						UPDATE CRM_Customer SET lft = lft + 2 WHERE lft > @Selectedlft;
						set @lft =  @Selectedlft + 1
						set @rgt =	@Selectedlft + 2
						set @ParentID = @SelectedNodeID
						set @Depth = @Depth + 1
 
					END
				else if(@SelectedIsGroup = 0)--Adding Node at Same level
					BEGIN
						UPDATE CRM_Customer SET rgt = rgt + 2 WHERE rgt > @Selectedrgt;
						UPDATE CRM_Customer SET lft = lft + 2 WHERE lft > @Selectedrgt;
						set @lft =  @Selectedrgt + 1
						set @rgt =	@Selectedrgt + 2 
					END
				else  --Adding Root
					BEGIN
						set @lft =  1
						set @rgt =	2 
						set @Depth = 0
						set @ParentID =0
						set @IsGroup=1
					END
 

				-- Insert statements for procedure here
				INSERT INTO [CRM_Customer]
							(CodePrefix,CodeNumber,[CustomerCode],
							[CustomerName] ,
							[AliasName] ,
							[CustomerTypeID],
							[StatusID],
							[AccountID],
							[Depth],
							[ParentID],
							[lft],
							[rgt],
							[IsGroup], 
							[CreditDays], 
							[CreditLimit],
							[CompanyGUID],
							[GUID],
							[Description],
							[CreatedBy],
							[CreatedDate])
							VALUES
							(@CodePrefix,@CodeNumber,@CustomerCode,
							@CustomerName,
							@AliasName,
							@SelectedTypeId,
							@StatusID,
							@AccountID,
							@Depth,
							@ParentID,
							@lft,
							@rgt,
							@IsGroup,
							@CreditDays,
							@CreditLimit, 
							@CompanyGUID,
							newid(),
							@Description,
							@UserName,
							@Dt)
					
				--To get inserted record primary key
				SET @CustomerID=SCOPE_IDENTITY()
 
	
				--Handling of Extended Table
				INSERT INTO [CRM_CustomerExtended]([CustomerID],[CreatedBy],[CreatedDate])
				VALUES(@CustomerID, @UserName, @Dt)
 
			-- Handling of CostCenter Costcenters Extrafields Table
		 	INSERT INTO COM_CCCCData ([NodeID],CostCenterID, [CreatedBy],[CreatedDate], [CompanyGUID],[GUID])
			 VALUES(@CustomerID,83, @UserName, @Dt, @CompanyGUID,newid())

				 
				IF @FromImport=0
				BEGIN
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
				,83
				,@CustomerID
				,@CompanyGUID
				,NEWID()
				,@UserName,@Dt
				)
				INSERT INTO COM_ContactsExtended(ContactID,[CreatedBy],[CreatedDate])
			 	VALUES(SCOPE_IDENTITY(), @UserName, convert(float,getdate()))
			   END
				
 		END--------END INSERT RECORD-----------
		ELSE--------START UPDATE RECORD-----------
		BEGIN	
			print 'Update'	
			IF EXISTS(SELECT CustomerID FROM [CRM_Customer] WHERE CustomerID=@CustomerID AND ParentID=0)
			BEGIN
				RAISERROR('-123',16,1)
			END	  
			SELECT @TempGuid=[GUID] from [CRM_Customer]  WITH(NOLOCK) 
			WHERE CustomerID=@CustomerID

			--IF(@TempGuid!=@Guid)--IF RECORD ALREADY UPDATED BY SOME OTHER USER i.e DIRTY READ  
		--	BEGIN  
		--		   RAISERROR('-101',16,1)	
		--	END  
			--ELSE  
			BEGIN 

 
			 --Delete mapping if any
			 DELETE FROM  COM_CCCCData WHERE NodeID=@CustomerID and CostCenterID=83

			-- Handling of CostCenter Costcenters Extrafields Table
		 	INSERT INTO COM_CCCCData ([NodeID],CostCenterID, [CreatedBy],[CreatedDate], [CompanyGUID],[GUID])
			 VALUES(@CustomerID,83, @UserName, @Dt, @CompanyGUID,newid())

				UPDATE [CRM_Customer]
				   SET [CustomerCode] = @CustomerCode
					  ,[CustomerName] = @CustomerName
					  ,[AliasName] = @AliasName
					  ,[CustomerTypeID]=@SelectedTypeId
					  ,[StatusID] = @StatusID
					  ,[AccountID]=@AccountID
					  ,[IsGroup] = @IsGroup
					  ,[CreditDays] = @CreditDays
					  ,[CreditLimit] = @CreditLimit
					  ,[GUID] =  newid()
					  ,[Description] = @Description   
					  ,[ModifiedBy] = @UserName
					  ,[ModifiedDate] = @Dt
				 WHERE CustomerID=@CustomerID      
			END
	
END
				 --SETTING Customer CODE EQUALS CustomerID IF EMPTY
		IF(@CustomerCode IS NULL OR @CustomerCode='')
		BEGIN
		 
			UPDATE  [CRM_Customer]
			SET [CustomerCode] = @CustomerID
			WHERE CustomerID=@CustomerID   
		 
		END

  -- , BEFORE MODIFIEDBY  REQUIRES A NULL CHECK OF @PrimaryContactQuery 
  IF(@PrimaryContactQuery IS NOT NULL AND @PrimaryContactQuery<>'')
  BEGIN  
		--CHANGES MADE IN PRIMARY CONTACT QUERY BY HAFEEZ ON DEC 20 2013,BECOZ CONTACT QUICK ADD SCREEN IS CUSTOMIZABLE
		EXEC spCOM_SetFeatureWiseContacts 83,@CustomerID,1,@PrimaryContactQuery,@UserName,@Dt,@LangID
  END
  
		--Update Extra fields
		set @UpdateSql='update [CRM_CustomerExtended]
		SET '+@CustomFieldsQuery+'[ModifiedBy] ='''+ @UserName
		  +''',[ModifiedDate] =' + convert(nvarchar,@Dt) +' WHERE CustomerID ='+convert(nvarchar,@CustomerID)
	
		exec(@UpdateSql)
	
		
		--Update CostCenter Extra Fields
		set @UpdateSql='update COM_CCCCDATA 
		SET '+@CustomCostCenterFieldsQuery+' [ModifiedBy] ='''+ @UserName+''',[ModifiedDate] =' + convert(nvarchar,@Dt) +' WHERE NodeID = '+convert(nvarchar,@CustomerID)+ ' AND CostCenterID = 83 ' 
	
		exec(@UpdateSql)
 
	   --Inserts Multiple Contacts  
	  IF (@ContactsXML IS NOT NULL AND @ContactsXML <> '')  
	  BEGIN  
			--CHANGES MADE IN PRIMARY CONTACT QUERY BY HAFEEZ ON DEC 20 2013,BECOZ CONTACT QUICK ADD SCREEN IS CUSTOMIZABLE 
		 declare @rValue int
		EXEC @rValue =  spCOM_SetFeatureWiseContacts 83,@CustomerID,2,@ContactsXML,@UserName,@Dt,@LangID  
		 IF @rValue=-1000  
		  BEGIN  
			RAISERROR('-500',16,1)  
		  END   
	  END  
  

		--Inserts Multiple Address
		EXEC spCOM_SetAddress 83,@CustomerID,@AddressXML,@UserName  

		--Inserts Multiple Notes
		IF (@NotesXML IS NOT NULL AND @NotesXML <> '')
		BEGIN
			SET @XML=@NotesXML

			--If Action is NEW then insert new Notes
			INSERT INTO COM_Notes(FeatureID,CostCenterID,FeaturePK,Note,			
			GUID,CreatedBy,CreatedDate)
			SELECT 83,83,@CustomerID,Replace(X.value('@Note','NVARCHAR(max)'),'@~','
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
			FileExtension,FileDescription,IsProductImage,IsDefaultImage,FeatureID,CostCenterID,FeaturePK,
			GUID,CreatedBy,CreatedDate)
			SELECT X.value('@FilePath','NVARCHAR(500)'),X.value('@ActualFileName','NVARCHAR(50)'),X.value('@RelativeFileName','NVARCHAR(50)'),
			X.value('@FileExtension','NVARCHAR(50)'),X.value('@FileDescription','NVARCHAR(500)'),X.value('@IsProductImage','bit'),X.value('@IsDefaultImage','bit'),83,83,@CustomerID,
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



				--activites




					 
					 
END
IF @ActivityXml <>'' AND @ActivityXml IS NOT NULL
BEGIN 

exec spCom_SetActivitiesAndSchedules @ActivityXml,83,@CustomerID,@CompanyGUID,@Guid,@UserName,@dt,@LangID 

END	

  IF  (@AssignCCCCData IS NOT NULL AND @AssignCCCCData <> '')   
  BEGIN  
  DECLARE @CCCCCData XML
    SET @CCCCCData=@AssignCCCCData  
    EXEC [spCOM_SetCCCCMap] 83,@CustomerID,@CCCCCData,@UserName,@LangID  
  END  	 

COMMIT TRANSACTION  
SET NOCOUNT OFF;  
SELECT ErrorMessage,ErrorNumber FROM COM_ErrorMessages WITH(nolock) 
WHERE ErrorNumber=100 AND LanguageID=@LangID  
RETURN @CustomerID  
END TRY  
BEGIN CATCH  
	--Return exception info [Message,Number,ProcedureName,LineNumber]  
	IF ERROR_NUMBER()=50000
	BEGIN
		SELECT * FROM [CRM_Customer] WITH(nolock) WHERE CustomerID=@CustomerID  
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

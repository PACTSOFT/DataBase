USE PACT2C222
GO
SET ANSI_NULLS, QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spCRM_SetCases]
	@CaseID [bigint] = 0,
	@CaseNumber [nvarchar](200),
	@CaseDate [datetime] = null,
	@CUSTOMER [int] = 0,
	@StatusID [int],
	@IsGroup [bit],
	@SelectedNodeID [bigint],
	@CASETYPEID [int] = 0,
	@CASEORIGINID [int] = 0,
	@CASEPRIORITYID [int] = 0,
	@SVCCONTRACTID [bigint] = 0,
	@CONTRACTLINEID [bigint] = 0,
	@PRODUCTID [bigint] = 0,
	@SERIALNUMBER [nvarchar](300) = NULL,
	@BillingMethod [int] = 0,
	@SERVICELVLID [bigint] = 0,
	@Assigned [bigint] = 0,
	@DESCRIPTION [nvarchar](max) = NULL,
	@SERVICEXML [nvarchar](max) = NULL,
	@ActivityXml [nvarchar](max) = NULL,
	@NotesXML [nvarchar](max) = NULL,
	@AttachmentsXML [nvarchar](max) = NULL,
	@FeedbackXML [nvarchar](max) = NULL,
	@CustomCostCenterFieldsQuery [nvarchar](max) = NULL,
	@CustomCCQuery [nvarchar](max) = NULL,
	@WaveUser [bigint] = 0,
	@WAVEDATE [datetime] = NULL,
	@COMMENTS [nvarchar](max) = NULL,
	@ProductXML [nvarchar](max) = null,
	@mode [nvarchar](50) = null,
	@RefCCID [bigint],
	@RefNodeID [bigint],
	@ContactsXML [nvarchar](max) = NULL,
	@Subject [nvarchar](500) = null,
	@CompanyGUID [nvarchar](50),
	@GUID [nvarchar](50),
	@CustomerMode [int] = 1,
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
    
    
    DECLARE @Dt FLOAT, @lft bigint,@rgt bigint,@TempGuid nvarchar(50),@Selectedlft bigint,@Selectedrgt bigint,@HasAccess bit,@IsDuplicateNameAllowed bit,@IsLeadCodeAutoGen bit  ,@IsIgnoreSpace bit  ,  
 @Depth int,@ParentID bigint,@SelectedIsGroup int ,@ActionType INT, @XML XML,@ParentCode nvarchar(200),@DetailContact int  
 DECLARE @UpdateSql NVARCHAR(MAX)   , @AutoAssign bit
 Declare @CostCenterID int  
 declare @LocalXml XML   
 declare @ScheduleID int  
 declare @MaxCount int  
 declare @Count int  
 declare @stract nvarchar(max)  
 declare @isRecur bit  
  declare @strsch nvarchar(max)  
  declare @feq int  
 set @CostCenterID=73  
  
 IF @CaseID=0    
  BEGIN  
 SET @ActionType=1  
   SET @HasAccess=dbo.fnCOM_HasAccess(@RoleID,73,1)    
  END    
  ELSE    
  BEGIN    
 SET @ActionType=3  
   SET @HasAccess=dbo.fnCOM_HasAccess(@RoleID,73,3)    
  END    
    
 --User access check   
   
  IF @HasAccess=0  
  BEGIN  
   RAISERROR('-105',16,1)  
  END  
    
   
   
  
  
  --GETTING PREFERENCE    
  SELECT @IsDuplicateNameAllowed=Value FROM COM_CostCenterPreferences WITH(nolock) WHERE COSTCENTERID=73 and  Name='DuplicateNameAllowed'    
  SELECT @IsLeadCodeAutoGen=Value FROM COM_CostCenterPreferences  WITH(nolock) WHERE COSTCENTERID=73 and  Name='CodeAutoGen'    
  SELECT @IsIgnoreSpace=Value FROM COM_CostCenterPreferences  WITH(nolock) WHERE COSTCENTERID=73 and  Name='IgnoreSpaces'    
  SELECT @AutoAssign=Value FROM COM_CostCenterPreferences  WITH(nolock) WHERE COSTCENTERID=73 and  Name='AutoAssign'  
PRINT @AutoAssign
  --DUPLICATE CHECK    
  IF @IsDuplicateNameAllowed IS NOT NULL AND @IsDuplicateNameAllowed=0    
  BEGIN    
    IF @IsIgnoreSpace IS NOT NULL AND @IsIgnoreSpace=1    
   BEGIN    
    IF @CaseID=0    
    BEGIN    
     IF EXISTS (SELECT CaseNumber FROM CRM_Cases WITH(nolock) WHERE replace(CaseNumber,' ','')=replace(@CaseNumber,' ',''))    
     BEGIN    
      RAISERROR('-203',16,1)    
   END    
    END    
    ELSE    
    BEGIN    
     IF EXISTS (SELECT CaseNumber FROM CRM_Cases WITH(nolock) WHERE replace(CaseNumber,' ','')=replace(@CaseNumber,' ','') AND CaseID <> @CaseID)    
     BEGIN    
      RAISERROR('-203',16,1)         
     END    
    END    
   END    
   ELSE    
   BEGIN    
    IF @CaseID=0    
    BEGIN    
     IF EXISTS (SELECT CaseNumber FROM CRM_Cases WITH(nolock) WHERE CaseNumber=@CaseNumber)    
     BEGIN    
      RAISERROR('-203',16,1)    
     END    
    END    
    ELSE    
    BEGIN    
     IF EXISTS (SELECT CaseNumber FROM CRM_Cases WITH(nolock) WHERE CaseNumber=@CaseNumber AND CaseID <> @CaseID)    
     BEGIN    
      RAISERROR('-203',16,1)    
     END    
    END    
   END  
  END     
    
      --User acces check FOR Notes    
  IF (@NotesXML IS NOT NULL AND @NotesXML <> '')    
  BEGIN    
   SET @HasAccess=dbo.fnCOM_HasAccess(@RoleID,73,8)    
    
   IF @HasAccess=0    
   BEGIN    
    RAISERROR('-105',16,1)    
   END    
  END    
    
  --User acces check FOR Attachments    
  IF (@AttachmentsXML IS NOT NULL AND @AttachmentsXML <> '')    
  BEGIN    
   SET @HasAccess=dbo.fnCOM_HasAccess(@RoleID,73,12)    
    
   IF @HasAccess=0    
   BEGIN    
    RAISERROR('-105',16,1)    
   END    
  END    
  SET @Dt=convert(float,getdate())--Setting Current Date    
    
  IF @CaseID= 0--------START INSERT RECORD-----------    
  BEGIN--CREATE Case    
     --To Set Left,Right And Depth of Record    
    SELECT @SelectedIsGroup=IsGroup,@Selectedlft =lft,@Selectedrgt=rgt,@ParentID=ParentID,@Depth=Depth    
    from CRM_Cases with(NOLOCK) where CaseID=@SelectedNodeID    
        
    --IF No Record Selected or Record Doesn't Exist    
    if(@SelectedIsGroup is null)     
     select @SelectedNodeID=CaseID,@SelectedIsGroup=IsGroup,@Selectedlft =lft,@Selectedrgt=rgt,@ParentID=ParentID,@Depth=Depth    
     from CRM_Cases with(NOLOCK) where ParentID =0    
              
    if(@SelectedIsGroup = 1)--Adding Node Under the Group    
     BEGIN    
      UPDATE CRM_Cases SET rgt = rgt + 2 WHERE rgt > @Selectedlft;    
      UPDATE CRM_Cases SET lft = lft + 2 WHERE lft > @Selectedlft;    
      set @lft =  @Selectedlft + 1    
      set @rgt = @Selectedlft + 2    
      set @ParentID = @SelectedNodeID    
      set @Depth = @Depth + 1    
     END    
    else if(@SelectedIsGroup = 0)--Adding Node at Same level    
     BEGIN    
      UPDATE CRM_Cases SET rgt = rgt + 2 WHERE rgt > @Selectedrgt;    
      UPDATE CRM_Cases SET lft = lft + 2 WHERE lft > @Selectedrgt;    
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
  
    IF @IsCode=1 and @IsLeadCodeAutoGen IS NOT NULL AND @IsLeadCodeAutoGen=1 AND @CaseID=0 and @CodePrefix=''  
	BEGIN 
		--CALL AUTOCODEGEN 
		create table #temp1(prefix nvarchar(100),number bigint, suffix nvarchar(100), code nvarchar(200), IsManualcode bit)
		if(@SelectedNodeID is null)
		insert into #temp1
		EXEC [spCOM_GetCodeData] 73,1,''  
		else
		insert into #temp1
		EXEC [spCOM_GetCodeData] 73,@SelectedNodeID,''  
		--select * from #temp1
		select @CaseNumber=code,@CodePrefix= prefix, @CodeNumber=number from #temp1
		--select @AccountCode,@ParentID
	END	
	
 IF @CaseNumber='' OR @CaseNumber IS NULL  
 SELECT @CaseNumber=MAX(CASEID)+1 FROM CRM_Cases  
  INSERT INTO  [CRM_Cases]  
           (CodePrefix,CodeNumber,[CreateDate]    
           ,[CaseNumber]  
           ,[StatusID]  
           ,[CaseTypeLookupID]   
           ,[CaseOriginLookupID]   
           ,[CasePriorityLookupID]   
           ,[CustomerID]  
           ,[SvcContractID]  
           ,[ContractLineID]  
           ,[ProductID]  
           ,[SerialNumber]  
           ,[ServiceLvlLookupID]   
           ,[Description]  
           ,[Depth]  
           ,[ParentID]  
           ,[lft]  
           ,[rgt]  
           ,[IsGroup]  
           ,[CompanyGUID],AssignedTo  
           ,[GUID]  
           ,[CreatedBy]  
           ,[CreatedDate],BillingMethod,Mode,RefCCID,RefNodeID,CustomerMode  , subject
          )  
     VALUES  
           (@CodePrefix,@CodeNumber,convert(float,@CaseDate)  
           ,@CaseNumber  
           ,@StatusID  
           ,@CASETYPEID   
    ,@CASEORIGINID   
           ,@CASEPRIORITYID  
           ,@CUSTOMER  
           ,@SVCCONTRACTID  
           ,@CONTRACTLINEID  
           ,@PRODUCTID  
           ,@SERIALNUMBER  
           ,@SERVICELVLID  
           ,@DESCRIPTION  
           ,@Depth  
   ,@ParentID  
   ,@lft  
   ,@rgt  
   ,@IsGroup  
   ,@CompanyGUID,@Assigned  
   ,newid()  
           ,@UserName  
   ,convert(float,@Dt),@BillingMethod,@mode,@RefCCID,@RefNodeID,@CustomerMode ,@Subject
   )  
    SET @CaseID=SCOPE_IDENTITY()   
    
      
 --Handling of Extended Table      
    INSERT INTO CRM_CasesExtended(CaseID,[CreatedBy],[CreatedDate])      
    VALUES(@CaseID, @UserName, @Dt)     
      
  IF @Assigned>0  
  BEGIN   
   UPDATE [CRM_Cases] SET ASSIGNEDDATE=CONVERT(FLOAT,GETDATE()) WHERE CASEID=@CaseID  
  END  
    
   IF @BillingMethod=140  
    UPDATE CRM_Cases SET WaiveBy=@WaveUser,WaiveDate=CONVERT(FLOAT,@WAVEDATE),Comments=@COMMENTS WHERE CaseID=@CaseID  
      
 --INSERT INTO ASSIGNED TABLE   
	if(@AutoAssign=1)
	begin
select	@AutoAssign
		DECLARE @TEAMNODEID BIGINT  
		SET @TEAMNODEID=0  
		SELECT TOP(1) @TEAMNODEID =  ISNULL(TeamID,0) FROM CRM_Teams WHERE UserID=@Assigned AND IsGroup=0    
		EXEC spCRM_SetCRMAssignment 73, @CaseID,@TEAMNODEID,@Assigned,0,@Assigned,'','',@CompanyGUID,@UserName,@LangId  
	end
	
     INSERT INTO COM_CCCCDATA ([CostCenterID] ,[NodeID] ,[Guid],[CreatedBy],[CreatedDate])  
     VALUES(73,@CaseID,newid(),  @UserName, @Dt)    
      
   DECLARE @return_value int,@LinkCostCenterID INT  
   SELECT @LinkCostCenterID=isnull([Value],0) FROM COM_CostCenterPreferences WITH(NOLOCK)   
   WHERE FeatureID=73 AND [Name]='CasesLinkDimension'  
     
   IF @LinkCostCenterID>0  
   BEGIN  
    EXEC @return_value = [dbo].[spCOM_SetCostCenter]  
     @NodeID = 0,@SelectedNodeID = 0,@IsGroup = 0,  
     @Code = @CaseNumber,  
     @Name = @CaseNumber,  
     @AliasName=@CaseNumber,  
     @PurchaseAccount=0,@SalesAccount=0,@StatusID=@StatusID,  
     @CustomFieldsQuery=NULL,@AddressXML=NULL,@AttachmentsXML=NULL,  
     @CustomCostCenterFieldsQuery=NULL,@ContactsXML=NULL,@NotesXML=NULL,  
     @CostCenterID = @LinkCostCenterID,@CompanyGUID=@COMPANYGUID,@GUID='GUID',@UserName=@USERNAME,@RoleID=1,@UserID=@USERID  
     --@return_value  
     if(@return_value>0)  
     begin  
      UPDATE [CRM_Cases]  
      SET CCCaseID=@return_value  
      WHERE CASEID=@CaseID  
        
      IF(@RefCCID > 0 AND @RefNodeID>0)  
        BEGIN  
       SET @UpdateSql='UPDATE COM_DocCCData   
       SET dcCCNID'+CONVERT(NVARCHAR,(@LinkCostCenterID-50000))+'='+CONVERT(NVARCHAR,@return_value)  
       +' WHERE InvDocDetailsID IN (SELECT InvDocDetailsID FROM Inv_DocDetails   
       WHERE COSTCENTERID='+CONVERT(NVARCHAR,@RefCCID)+' AND DOCID='+CONVERT(NVARCHAR,@RefNodeID)+')'  
       EXEC(@UpdateSql)  
        END  
     END    
   END  
     
     
  
         
       
      
  END --------END INSERT RECORD-----------    
 ELSE  --------START UPDATE RECORD-----------    
  BEGIN  
    SELECT @TempGuid=[GUID] from CRM_Cases  WITH(NOLOCK)     
      WHERE CaseID=@CaseID  
       
      IF(@TempGuid!=@Guid)--IF RECORD ALREADY UPDATED BY SOME OTHER USER i.e DIRTY READ      
      BEGIN      
       RAISERROR('-101',16,1)     
      END      
      ELSE      
      BEGIN   
     UPDATE [CRM_Cases]  
        SET [CreateDate] =CONVERT(float, @CaseDate)  
        ,[CaseNumber] = @CaseNumber  
        ,[StatusID] = @StatusID  
        ,[CaseTypeLookupID] = @CASETYPEID  
        ,Mode=@mode  
        ,[CaseOriginLookupID] = @CASEORIGINID  
       ,AssignedTo =@Assigned  
        ,[CasePriorityLookupID] = @CASEPRIORITYID  
      ,BillingMethod=@BillingMethod  
        ,[CustomerID] = @CUSTOMER  
        ,[SvcContractID] = @SVCCONTRACTID  
        ,[ContractLineID] = @CONTRACTLINEID  
        ,[ProductID] = @PRODUCTID  
        ,[SerialNumber] = @SERIALNUMBER  
        ,[ServiceLvlLookupID] = @SERVICELVLID  
          
        ,[Description] = @DESCRIPTION   
        ,[Subject]=@Subject
        ,[GUID] = @Guid  
        ,[ModifiedBy] = @UserName  ,CustomerMode=@CustomerMode
        ,[ModifiedDate] = @Dt  
      WHERE CaseID=@CaseID  
         
     IF @BillingMethod=140  
     UPDATE CRM_Cases SET WaiveBy=@WaveUser,WaiveDate=CONVERT(FLOAT,@WAVEDATE),Comments=@COMMENTS WHERE CaseID=@CaseID  
         
      END  
  
  
     
      
    END  
      
     
  --Update Extra fields      
  set @UpdateSql='update [CRM_CasesExtended]      
  SET '+@CustomCostCenterFieldsQuery+'[ModifiedBy] ='''+ @UserName      
    +''',[ModifiedDate] =' + convert(nvarchar,@Dt) +' WHERE CaseID='+convert(nvarchar,@CaseID)      
     
  exec(@UpdateSql)      
    
   set @UpdateSql='update COM_CCCCDATA    
 SET '+@CustomCCQuery+'[ModifiedBy] ='''+ @UserName+''',[ModifiedDate] =' + convert(nvarchar,@Dt) +' WHERE NodeID = '+convert(nvarchar,@CaseID) + ' AND CostCenterID = 73 '   
      
  exec(@UpdateSql)    
    
    --ADDED CONDIDTION ON JAN 30 2013 BY HAFEEZ  
   --TO SET LEAD LINK DIMENSION=@LeadID AND MAKE THAT COLUMN AS READONLY  
   IF(EXISTS(SELECT VALUE FROM COM_COSTCENTERPREFERENCES WHERE COSTCENTERID=73 AND NAME='CASESLINKDIMENSION'))  
   BEGIN  
   DECLARE @DIMID BIGINT  
   SET @DIMID=0  
   SELECT @DIMID=VALUE-50000 FROM COM_COSTCENTERPREFERENCES WHERE COSTCENTERID=73 AND NAME='CASESLINKDIMENSION'  
   IF(@DIMID>0)  
   BEGIN  
     SET @UpdateSql=' UPDATE COM_CCCCDATA SET CCNID'+CONVERT(NVARCHAR(30),@DIMID)+'=  
     (SELECT CCCaseID FROM CRM_Cases WHERE CaseID='+convert(nvarchar,@CaseID) + ')   
         WHERE NodeID = '+convert(nvarchar,@CaseID) + ' AND CostCenterID = 73'  
       exec(@UpdateSql)    
   END  
   END      
     
     
 IF @CaseID>0  
 BEGIN  
 DELETE FROM CRM_CaseSvcTypeMap WHERE CASEID=@CaseID  
   
 DECLARE @DATA XML  
 SET @DATA=@SERVICEXML  
 INSERT INTO CRM_CaseSvcTypeMap  
 SELECT @CaseID,A.value('@SeviceType','Bigint'),A.value('@ServiceReasonID','bigint')   
 ,A.value('@VoiceOfCustomer','nvarchar(max)'),A.value('@NODEID','bigint'),A.value('@TechComments','nvarchar(max)'),   
 @UserName,CONVERT(float,getdate()) from @DATA.nodes('/XML/Row') as DATA(A)  
   
  
  
  
 IF  @FeedbackXML IS NOT NULL  
 BEGIN  
 DECLARE @DATAFEEDBACK XML  
 SET @DATAFEEDBACK=@FeedbackXML  
   
    Delete from CRM_FEEDBACK where CCNodeID = @CaseID and CCID=73  
      
     INSERT into CRM_FEEDBACK  
       select 73,@CaseID,  
          convert(float,x.value('@Date','datetime')),x.value('@FeedBack','nvarchar(200)'), @UserName,convert(float,@Dt),x.value('@Alpha1','nvarchar(200)'),x.value('@Alpha2','nvarchar(200)'),x.value('@Alpha3','nvarchar(200)'),x.value('@Alpha4','nvarchar(200)'),x.value('@Alpha5','nvarchar(200)'),  
          x.value('@Alpha6','nvarchar(200)'),x.value('@Alpha7','nvarchar(200)'),x.value('@Alpha8','nvarchar(200)'),x.value('@Alpha9','nvarchar(200)'),x.value('@Alpha10','nvarchar(200)'),  
          x.value('@Alpha11','nvarchar(200)'),x.value('@Alpha12','nvarchar(200)'),x.value('@Alpha13','nvarchar(200)'),x.value('@Alpha14','nvarchar(200)'),x.value('@Alpha15','nvarchar(200)'),  
          x.value('@Alpha16','nvarchar(200)'),x.value('@Alpha17','nvarchar(200)'),x.value('@Alpha18','nvarchar(200)'),x.value('@Alpha19','nvarchar(200)'),x.value('@Alpha20','nvarchar(200)'),  
          x.value('@Alpha21','nvarchar(200)'),x.value('@Alpha22','nvarchar(200)'),x.value('@Alpha23','nvarchar(200)'),x.value('@Alpha24','nvarchar(200)'),x.value('@Alpha25','nvarchar(200)'),  
          x.value('@Alpha26','nvarchar(200)'),x.value('@Alpha27','nvarchar(200)'),x.value('@Alpha28','nvarchar(200)'),x.value('@Alpha29','nvarchar(200)'),x.value('@Alpha30','nvarchar(200)'),  
          x.value('@Alpha31','nvarchar(200)'),x.value('@Alpha32','nvarchar(200)'),x.value('@Alpha33','nvarchar(200)'),x.value('@Alpha34','nvarchar(200)'),x.value('@Alpha35','nvarchar(200)'),  
          x.value('@Alpha36','nvarchar(200)'),x.value('@Alpha37','nvarchar(200)'),x.value('@Alpha38','nvarchar(200)'),x.value('@Alpha39','nvarchar(200)'),x.value('@Alpha40','nvarchar(200)'),  
          x.value('@Alpha41','nvarchar(200)'),x.value('@Alpha42','nvarchar(200)'),x.value('@Alpha43','nvarchar(200)'),x.value('@Alpha44','nvarchar(200)'),x.value('@Alpha45','nvarchar(200)'),  
          x.value('@Alpha46','nvarchar(200)'),x.value('@Alpha47','nvarchar(200)'),x.value('@Alpha48','nvarchar(200)'),x.value('@Alpha49','nvarchar(200)'),x.value('@Alpha50','nvarchar(200)')  ,
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
   
        
  
  
set @LocalXml=@ActivityXml  
  
 exec spCom_SetActivitiesAndSchedules @ActivityXml,73,@CaseID,@CompanyGUID,@Guid,@UserName,@Dt,@LangID   
     
  
   
 --Inserts Multiple Notes    
  IF (@NotesXML IS NOT NULL AND @NotesXML <> '')    
  BEGIN    
   SET @XML=@NotesXML    
    
   --If Action is NEW then insert new Notes    
   INSERT INTO COM_Notes(FeatureID,CostCenterID,FeaturePK,Note,       
   GUID,CreatedBy,CreatedDate)    
   SELECT 73,73,@CaseID,Replace(X.value('@Note','NVARCHAR(max)'),'@~','
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
   X.value('@FileExtension','NVARCHAR(50)'),X.value('@FileDescription','NVARCHAR(500)'),X.value('@IsProductImage','bit'),73,73,@CaseID,    
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
  
  
  
  if(@ProductXML is not null and @ProductXML <> '')  
    begin  
    DECLARE @PRDXML XML  
    SET @PRDXML=@ProductXML  
    Delete from CRM_ProductMapping where CCNodeID = @CaseID and CostCenterID=73  
          
       INSERT into CRM_ProductMapping(CCNodeID,CostCenterID,ProductID,CRMProduct,UOMID,Description,  
       Quantity,CurrencyID, Alpha1, Alpha2, Alpha3, Alpha4, Alpha5, Alpha6, Alpha7, Alpha8, Alpha9, Alpha10, Alpha11, Alpha12, Alpha13, Alpha14, Alpha15, Alpha16, Alpha17, Alpha18, Alpha19, Alpha20, Alpha21, Alpha22, Alpha23, Alpha24, Alpha25, Alpha26, Alpha27, Alpha28, Alpha29, Alpha30, Alpha31, Alpha32, Alpha33, Alpha34, Alpha35, Alpha36, Alpha37, Alpha38, Alpha39, Alpha40, Alpha41, Alpha42, Alpha43, Alpha44, Alpha45, Alpha46,  
        Alpha47, Alpha48, Alpha49, Alpha50, CCNID1, CCNID2, CCNID3, CCNID4, CCNID5, CCNID6, CCNID7, CCNID8, CCNID9, CCNID10, CCNID11, CCNID12, CCNID13, CCNID14, CCNID15, CCNID16, CCNID17, CCNID18, CCNID19, CCNID20, CCNID21, CCNID22, CCNID23, CCNID24, CCNID25, CCNID26, CCNID27, CCNID28, CCNID29, CCNID30, CCNID31, CCNID32, CCNID33, CCNID34, CCNID35, CCNID36, CCNID37, CCNID38, CCNID39, CCNID40, CCNID41, CCNID42, CCNID43, CCNID44, CCNID45, CCNID46,  
        CCNID47, CCNID48, CCNID49, CCNID50,CompanyGUID,GUID,CreatedBy,CreatedDate)  
       select @CaseID,73,  
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
       from @PRDXML.nodes('XML/Row') as data(x)  
       where  x.value('@Product','BIGINT')is not null and   x.value('@Product','BIGINT') <> ''  
         
     
  end   
  
 END     
   
     
     
     -- SAVING CASE CONTACTS
    
  IF (@ContactsXML IS NOT NULL AND @ContactsXML <> '')  
  BEGIN  
   SET @XML=@ContactsXML  
 
 
  
  
  DELETE FROM COM_Contacts 
  WHERE FeatureID = 73 AND FeaturePK = @CaseID
  
   --If Action is NEW then insert new contacts  
   INSERT INTO COM_Contacts(AddressTypeID,FeatureID,FeaturePK,ContactName ,FirstName,MiddleName,
   LastName,SalutationID,JobTitle,Company,Department,RoleLookupId,
   CostCenterID,  
   Address1,Address2,Address3,  
   City,State,Zip,Country,  
   Phone1,Phone2,Fax,Email1,Email2,URL,  
   GUID,CreatedBy,CreatedDate)  
   SELECT ISNULL( X.value('@AddressTypeID','int'),1),73,@CaseID,X.value('@ContactName','NVARCHAR(500)'),X.value('@FirstName','NVARCHAR(500)'),X.value('@MiddleName','NVARCHAR(500)'),X.value('@LastName','NVARCHAR(500)'),  
   X.value('@SalutationID','int'),X.value('@JobTitle','NVARCHAR(500)'),X.value('@Company','NVARCHAR(500)'),X.value('@Department','NVARCHAR(500)'),X.value('@RoleLookup','NVARCHAR(500)'),2,X.value('@Address1','NVARCHAR(500)'),X.value('@Address2','NVARCHAR(500)'),X.value('@Address3','NVARCHAR(500)'),  
   X.value('@City','NVARCHAR(100)'),X.value('@State','NVARCHAR(100)'),X.value('@Zip','NVARCHAR(50)'),X.value('@Country','NVARCHAR(100)'),  
   X.value('@Phone1','NVARCHAR(50)'),X.value('@Phone2','NVARCHAR(50)'),X.value('@Fax','NVARCHAR(50)'),X.value('@Email1','NVARCHAR(50)'),X.value('@Email2','NVARCHAR(50)'),X.value('@URL','NVARCHAR(50)'),  
   newid(),@UserName,@Dt  
   FROM @XML.nodes('/XML/Row') as Data(X)  
    
  
 --  --If Action is MODIFY then update contacts  
 --  UPDATE COM_Contacts  
 --  SET AddressTypeID= ISNULL(X.value('@AddressTypeID','int') ,1),  
	--FirstName=X.value('@FirstName','NVARCHAR(500)'),  
	--MiddleName=X.value('@MiddleName','NVARCHAR(500)'),  
	--LastName=X.value('@LastName','NVARCHAR(500)'),  
	--SalutationID=X.value('@SalutationID','int'),  
	--JobTitle=X.value('@JobTitle','NVARCHAR(500)'),RoleLookupId= X.value('@RoleLookup','NVARCHAR(500)'), Department= X.value('@Department','NVARCHAR(500)'),
	--Company=X.value('@Company','NVARCHAR(500)'),  
 --   Address1=X.value('@Address1','NVARCHAR(500)'),  
 --   Address2=X.value('@Address2','NVARCHAR(500)'),  
 --   Address3=X.value('@Address3','NVARCHAR(500)'),  
 --   City=X.value('@City','NVARCHAR(100)'),  
 --   State=X.value('@State','NVARCHAR(100)'),  
 --   Zip=X.value('@Zip','NVARCHAR(50)'),  
 --   Country=X.value('@Country','NVARCHAR(100)'),  
 --   Phone1=X.value('@Phone1','NVARCHAR(50)'),  
 --   Phone2=X.value('@Phone2','NVARCHAR(50)'),  
 --   Fax=X.value('@Fax','NVARCHAR(50)'),  
 --   Email1=X.value('@Email1','NVARCHAR(50)'),  
 --   Email2=X.value('@Email2','NVARCHAR(50)'),  
 --   URL=X.value('@URL','NVARCHAR(50)'),  
 --   GUID=newid(),  
 --   ModifiedBy=@UserName,  
 --   ModifiedDate=@Dt  
 --  FROM COM_Contacts C   
 --  INNER JOIN @XML.nodes('/XML/Row') as Data(X)    
 --  ON convert(bigint,X.value('@ContactID','bigint'))=C.ContactID  
 --  WHERE X.value('@Action','NVARCHAR(500)')='MODIFY'  
  
 --  --If Action is DELETE then delete contacts  
 --  DELETE FROM COM_Contacts  
 --  WHERE ContactID IN(SELECT X.value('@ContactID','bigint')  
 --   FROM @XML.nodes('/XML/Row') as Data(X)  
 --   WHERE X.value('@Action','NVARCHAR(10)')='DELETE')  
  END  
  
	 --Insert Notifications  
	 EXEC spCOM_SetNotifEvent @ActionType,73,@CaseID,@CompanyGUID,@UserName,@UserID,-1  
	IF @StatusID=1001 --FOR CLOSE CASE
	BEGIN
		EXEC spCOM_SetNotifEvent -1015,73,@CaseID,@CompanyGUID,@UserName,@UserID,-1 
	END 
   
 COMMIT TRANSACTION  
 SELECT ErrorMessage,ErrorNumber FROM COM_ErrorMessages WITH(nolock)     
WHERE ErrorNumber=100 AND LanguageID=@LangID    
SET NOCOUNT OFF;      
RETURN @CaseID  
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

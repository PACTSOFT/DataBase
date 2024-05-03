USE PACT2C222
GO
SET ANSI_NULLS, QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spCRM_ConvertOpportunity]
	@ACCOUNT [bit] = 0,
	@Customer [bit] = 0,
	@CustomerContacts [bit] = 0,
	@AccountContacts [bit] = 0,
	@OPPORTUNITYID [bigint],
	@CompanyGUID [nvarchar](100),
	@UserName [nvarchar](100),
	@UserID [bigint],
	@LangID [int] = 1
WITH ENCRYPTION, EXECUTE AS CALLER
AS
BEGIN TRANSACTION
BEGIN TRY 
SET NOCOUNT ON

  DECLARE @Dt float,@ParentCode nvarchar(200),@IsCodeAutoGen bit,@CodePrefix NVARCHAR(300),@CodeNumber BIGINT
  DECLARE @lft bigint,@rgt bigint,@Selectedlft bigint,@Selectedrgt bigint,@Depth int,@ParentID bigint
  DECLARE @SelectedIsGroup bit , @DetailContactID bigint,@SelectedNodeID INT,@IsGroup BIT
  DECLARE @LeadCode NVARCHAR(300),@Code NVARCHAR(300), @CustomerID BIGINT,@DetailContact BIGINT,@AccountID BIGINT
  DECLARE @CompanyName nvarchar(500),@Description nvarchar(500)
  	DECLARE @CONTACTSXML NVARCHAR(MAX) 
  CREATE TABLE #TBLCONTACTS(ID INT IDENTITY(1,1),CONTACTID BIGINT)
  SELECT @LeadCode=Code, @CompanyName=Company,@Description=Description  FROM CRM_Opportunities WITH(nolock) WHERE OpportunityID=@OPPORTUNITYID

 SET @Dt=convert(float,getdate())--Setting Current Date  
 DECLARE @return_value int,@LinkCostCenterID INT
 SET @SelectedNodeID=1
 CREATE TABLE #TBLTEMP(ID  INT IDENTITY(1,1),BASECOLUMN NVARCHAR(300),LINKCOLUMN NVARCHAR(300))
 DECLARE @ACOUNT INT,@I INT,@TotalCount bigint,@SOURCEDATA NVARCHAR(MAX),@DESTDATA NVARCHAR(MAX)
-------------INSERT INTO CUSTOMERS TABLE
 IF(@Customer=1)
	
 BEGIN
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
      set @rgt = @Selectedlft + 2
      set @ParentID = @SelectedNodeID
      set @Depth = @Depth + 1
 
     END
    else if(@SelectedIsGroup = 0)--Adding Node at Same level
     BEGIN
      UPDATE CRM_Customer SET rgt = rgt + 2 WHERE rgt > @Selectedrgt;
      UPDATE CRM_Customer SET lft = lft + 2 WHERE lft > @Selectedrgt;
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
 SET @IsGroup=0
 SELECT @IsCodeAutoGen=Value FROM COM_CostCenterPreferences  WITH(nolock) WHERE COSTCENTERID=83 and  Name='CodeAutoGen'  
    --GENERATE CODE
     IF @IsCodeAutoGen IS NOT NULL AND @IsCodeAutoGen=1  
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
		select @Code=code,@CodePrefix= prefix, @CodeNumber=number from #temp1
		--select @AccountCode,@ParentID 
     
    END  
    
      IF @CODE='' OR @CODE IS NULL 
	  begin
         SET @Code=@LeadCode
		 end
		 
	IF NOT EXISTS (SELECT * FROM COM_CostCenterCostCenterMap WITH(NOLOCK) WHERE CostCenterID=83 AND ParentCostCenterID=89 AND PARENTNODEID=@OPPORTUNITYID)  
	BEGIN  

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
       [CreatedDate],ConvertFromLeadID)
       VALUES
       (@CodePrefix,@CodeNumber,@CODE,
       @CompanyName,
       @CompanyName,
       146,
       393,
       @AccountID,
       @Depth,
       @ParentID,
       @lft,
       @rgt,
       @IsGroup,
       NULL,
       NULL, 
       @CompanyGUID,
       newid(),
       @Description,
       @UserName,
       @Dt,0)
     
    --To get inserted record primary key
    SET @CustomerID=SCOPE_IDENTITY()
	 --Handling of Extended Table
    INSERT INTO [CRM_CustomerExtended]([CustomerID],[CreatedBy],[CreatedDate])
    VALUES(@CustomerID, @UserName, @Dt)
    
    INSERT INTO COM_CostCenterCostCenterMap VALUES (89,@OPPORTUNITYID,0,83,@CustomerID,NEWID(),'','Admin',convert(float,getdate()),'',Null,0)
    
     IF @CustomerContacts=1
	 BEGIN 
	 truncate table #TBLCONTACTS
		INSERT INTO #TBLCONTACTS
		SELECT CONTACTID FROM  COM_CONTACTS WITH(nolock) WHERE FEATUREID=89 AND FEATUREPK=@OPPORTUNITYID --AND ADDRESSTYPEID=2
	 
		DECLARE @M INT,@CCOUNT INT,@CONTACTIDENTITY INT
		SELECT @M=1, @CCOUNT=COUNT(*) FROM #TBLCONTACTS 
		SET @CONTACTSXML=''
		WHILE @M<=@CCOUNT
		BEGIN
				INSERT INTO COM_CONTACTS([AddressTypeID],[FeatureID]        ,[FeaturePK]        ,[ContactName]        ,[Address1]        ,[Address2]        ,[Address3]        ,[City]        ,[State]        ,[Zip]        ,[Country]        ,[Phone1]        ,[Phone2]        ,[Fax]        ,[Email1]        ,[Email2]        ,[URL]        ,[CompanyGUID]        ,[GUID]        ,[Description]        ,[CreatedBy]        ,[CreatedDate]        ,[ModifiedBy]        ,[ModifiedDate]        ,[CostCenterID]        ,[ContactTypeID]        ,[FirstName]        ,[MiddleName]        ,[LastName]        ,[SalutationID]        ,[JobTitle]        ,[Company]        ,[StatusID]        ,[Department]        ,[RoleLookUpID]        ,[Gender]        ,[BirthDay]        ,[Anniversary]        ,[PreferredID]        ,[PreferredName]        ,[IsEmailOn]        ,[IsBulkEmailOn]        ,[IsMailOn]        ,[IsPhoneOn]        ,[IsFaxOn]        ,[IsVisible]        ,[Depth]        ,[ParentID]        ,[lft]        ,[rgt]        ,[IsGroup]        ,[ConvertFromLeadID])
				SELECT 2,83,@CustomerID,[ContactName] ,[Address1]        ,[Address2]        ,[Address3]        ,[City]        ,[State]        ,[Zip]        ,[Country]        ,[Phone1]        ,[Phone2]        ,[Fax]        ,[Email1]        ,[Email2]        ,[URL]        ,[CompanyGUID]        ,[GUID]        ,[Description]        ,[CreatedBy]        ,[CreatedDate]        ,[ModifiedBy]        ,[ModifiedDate]        ,89        ,[ContactTypeID]        ,[FirstName]        ,[MiddleName]        ,[LastName]        ,[SalutationID]        ,[JobTitle]        ,[Company]        ,[StatusID]        ,[Department]        ,[RoleLookUpID]        ,[Gender]        ,[BirthDay]        ,[Anniversary]        ,[PreferredID]        ,[PreferredName]        ,[IsEmailOn]        ,[IsBulkEmailOn]        ,[IsMailOn]        ,[IsPhoneOn]        ,[IsFaxOn]        ,[IsVisible]        ,[Depth]        ,[ParentID]        ,[lft]        ,[rgt]        ,[IsGroup]        ,[ConvertFromLeadID] FROM
				COM_CONTACTS WITH(nolock) WHERE CONTACTID IN (SELECT CONTACTID FROM   #TBLCONTACTS WHERE ID=@M)
				SET @CONTACTIDENTITY=SCOPE_IDENTITY()
				
				INSERT INTO [COM_ContactsExtended]([ContactID],[CreatedBy]        ,[CreatedDate]        ,[ModifiedBy]        ,[ModifiedDate]        ,[acAlpha1]        ,[acAlpha2]        ,[acAlpha3]        ,[acAlpha4]        ,[acAlpha5]        ,[acAlpha6]        ,[acAlpha7]        ,[acAlpha8]        ,[acAlpha9]        ,[acAlpha10]        ,[acAlpha11]        ,[acAlpha12]        ,[acAlpha13]        ,[acAlpha14]        ,[acAlpha15]        ,[acAlpha16]        ,[acAlpha17]        ,[acAlpha18]        ,[acAlpha19]        ,[acAlpha20]        ,[acAlpha21]        ,[acAlpha22]        ,[acAlpha23]        ,[acAlpha24]        ,[acAlpha25]        ,[acAlpha26]        ,[acAlpha27]        ,[acAlpha28]        ,[acAlpha29]        ,[acAlpha30]        ,[acAlpha31]        ,[acAlpha32]        ,[acAlpha33]        ,[acAlpha34]        ,[acAlpha35]        ,[acAlpha36]        ,[acAlpha37]        ,[acAlpha38]        ,[acAlpha39]        ,[acAlpha40]        ,[acAlpha41]        ,[acAlpha42]        ,[acAlpha43]        ,[acAlpha44]        ,[acAlpha45]        ,[acAlpha46]        ,[acAlpha47]        ,[acAlpha48]        ,[acAlpha49]        ,[acAlpha50])
				SELECT @CONTACTIDENTITY,[CreatedBy]        ,[CreatedDate]        ,[ModifiedBy]        ,[ModifiedDate]        ,[acAlpha1]        ,[acAlpha2]        ,[acAlpha3]        ,[acAlpha4]        ,[acAlpha5]        ,[acAlpha6]        ,[acAlpha7]        ,[acAlpha8]        ,[acAlpha9]        ,[acAlpha10]        ,[acAlpha11]        ,[acAlpha12]        ,[acAlpha13]        ,[acAlpha14]        ,[acAlpha15]        ,[acAlpha16]        ,[acAlpha17]        ,[acAlpha18]        ,[acAlpha19]        ,[acAlpha20]        ,[acAlpha21]        ,[acAlpha22]        ,[acAlpha23]        ,[acAlpha24]        ,[acAlpha25]        ,[acAlpha26]        ,[acAlpha27]        ,[acAlpha28]        ,[acAlpha29]        ,[acAlpha30]        ,[acAlpha31]        ,[acAlpha32]        ,[acAlpha33]        ,[acAlpha34]        ,[acAlpha35]        ,[acAlpha36]        ,[acAlpha37]        ,[acAlpha38]        ,[acAlpha39]        ,[acAlpha40]        ,[acAlpha41]        ,[acAlpha42]        ,[acAlpha43]        ,[acAlpha44]        ,[acAlpha45]        ,[acAlpha46]        ,[acAlpha47]        ,[acAlpha48]        ,[acAlpha49]        ,[acAlpha50]
				FROM [COM_ContactsExtended] WITH(nolock) WHERE CONTACTID IN (SELECT CONTACTID FROM   #TBLCONTACTS WHERE ID=@M)
				
				INSERT INTO COM_CCCCData([CostCenterID]        ,[NodeID]        ,[CCNodeID]        ,[CCNID1]        ,[CCNID2]        ,[CCNID3]        ,[CCNID4]        ,[CCNID5]        ,[CCNID6]        ,[CCNID7]        ,[CCNID8]        ,[CCNID9]        ,[CCNID10]        ,[CCNID11]        ,[CCNID12]        ,[CCNID13]        ,[CCNID14]        ,[CCNID15]        ,[CCNID16]        ,[CCNID17]        ,[CCNID18]        ,[CCNID19]        ,[CCNID20]        ,[CCNID21]        ,[CCNID22]        ,[CCNID23]        ,[CCNID24]        ,[CCNID25]        ,[CCNID26]        ,[CCNID27]        ,[CCNID28]        ,[CCNID29]        ,[CCNID30]        ,[CCNID31]        ,[CCNID32]        ,[CCNID33]        ,[CCNID34]        ,[CCNID35]        ,[CCNID36]        ,[CCNID37]        ,[CCNID38]        ,[CCNID39]        ,[CCNID40]        ,[CCNID41]        ,[CCNID42]        ,[CCNID43]        ,[CCNID44]        ,[CCNID45]        ,[CCNID46]        ,[CCNID47]        ,[CCNID48]        ,[CCNID49]        ,[CCNID50]        ,[CompanyGUID]        ,[GUID]        ,[Description]        ,[CreatedBy]        ,[CreatedDate]        ,[ModifiedBy]        ,[ModifiedDate]        ,[AccountID]        ,[ProductID])
				SELECT 65,@CONTACTIDENTITY,NULL,[CCNID1]        ,[CCNID2]        ,[CCNID3]        ,[CCNID4]        ,[CCNID5]        ,[CCNID6]        ,[CCNID7]        ,[CCNID8]        ,[CCNID9]        ,[CCNID10]        ,[CCNID11]        ,[CCNID12]        ,[CCNID13]        ,[CCNID14]        ,[CCNID15]        ,[CCNID16]        ,[CCNID17]        ,[CCNID18]        ,[CCNID19]        ,[CCNID20]        ,[CCNID21]        ,[CCNID22]        ,[CCNID23]        ,[CCNID24]        ,[CCNID25]        ,[CCNID26]        ,[CCNID27]        ,[CCNID28]        ,[CCNID29]        ,[CCNID30]        ,[CCNID31]        ,[CCNID32]        ,[CCNID33]        ,[CCNID34]        ,[CCNID35]        ,[CCNID36]        ,[CCNID37]        ,[CCNID38]        ,[CCNID39]        ,[CCNID40]        ,[CCNID41]        ,[CCNID42]        ,[CCNID43]        ,[CCNID44]        ,[CCNID45]        ,[CCNID46]        ,[CCNID47]        ,[CCNID48]        ,[CCNID49]        ,[CCNID50]        ,[CompanyGUID]        ,[GUID]        ,[Description]        ,[CreatedBy]        ,[CreatedDate]        ,[ModifiedBy]        ,[ModifiedDate]        ,[AccountID]        ,[ProductID] 
				FROM COM_CCCCData WITH(nolock) WHERE CostCenterID=65 AND NODEID   IN (SELECT CONTACTID FROM   #TBLCONTACTS WHERE ID=@M)
		
			SET @CONTACTSXML=''
			SET @M=@M+1
		END
	 END 
	END  

----------- INSERT INTO CONTACTS TABLE

   	
	         
  end
  
   
  -------------INSERT INTO ACCOUNTS TABLE
	 IF(@ACCOUNT=1)
	 BEGIN 
			IF  NOT EXISTS (SELECT * FROM COM_CostCenterCostCenterMap WITH(nolock) WHERE CostCenterID=2 AND ParentCostCenterID=89 AND PARENTNODEID=@OPPORTUNITYID)  
			BEGIN  
			  
			truncate table #TBLTEMP
			INSERT INTO #TBLTEMP
			 select 
			 l.SysColumnName, b.SysColumnName 
			 from COM_DocumentLinkDetails dl WITH(nolock)
			 left join ADM_CostCenterDef b WITH(nolock) on dl.CostCenterColIDBase=b.CostCenterColID
			 left join Com_LanguageResources C WITH(nolock) on C.ResourceID=b.ResourceID   AND C.LanguageID=1
			 left join ADM_CostCenterDef l WITH(nolock) on dl.CostCenterColIDLinked=l.CostCenterColID
			where DocumentLinkDeFID in (select DocumentLinkDeFID from COM_DocumentLinkDef WITH(nolock) where CostCenterIDBase=89   )
			and l.costcenterid=2
			
			 
			
			SELECT @I=1,@ACOUNT=COUNT(*) FROM #TBLTEMP
			
			IF (@ACOUNT>0)
			BEGIN
			SELECT @SelectedNodeID=isnull(VALUE,1) FROM COM_COSTCENTERPREFERENCES WITH(nolock) WHERE NAME='ConvertedAccountGroup' and costcenterid=86
				--To Set Left,Right And Depth of Record
			SELECT @SelectedIsGroup=IsGroup,@Selectedlft =lft,@Selectedrgt=rgt,@ParentID=isnull(ParentID,1),@Depth=isnull(Depth,1)
			from ACC_ACCOUNTS with(NOLOCK) where ACCOUNTID=@SelectedNodeID
			
	 
			--IF No Record Selected or Record Doesn't Exist
			if(@SelectedIsGroup is null) 
			select @SelectedNodeID=ACCOUNTID,@SelectedIsGroup=IsGroup,@Selectedlft =lft,@Selectedrgt=rgt,@ParentID=ParentID,@Depth=Depth
			from ACC_ACCOUNTS with(NOLOCK) where ParentID =0


			if(@SelectedIsGroup = 1)--Adding Node Under the Group
			BEGIN

			UPDATE ACC_ACCOUNTS SET rgt = rgt + 2 WHERE rgt > @Selectedlft;
			UPDATE ACC_ACCOUNTS SET lft = lft + 2 WHERE lft > @Selectedlft;
			set @lft =  @Selectedlft + 1
			set @rgt = @Selectedlft + 2
			set @ParentID = @SelectedNodeID
			set @Depth = @Depth + 1

			END
			else if(@SelectedIsGroup = 0)--Adding Node at Same level
			BEGIN
			UPDATE ACC_ACCOUNTS SET rgt = rgt + 2 WHERE rgt > @Selectedrgt;
			UPDATE ACC_ACCOUNTS SET lft = lft + 2 WHERE lft > @Selectedrgt;
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
			SET @IsGroup=0
			
			
			--FIRST INSERT INTO MAIN TABLE 
			SET @DESTDATA=''
			SET @SOURCEDATA=''
		
			SET @SOURCEDATA=' INSERT INTO ACC_ACCOUNTS (AccountTypeID,StatusID,ConvertFromLeadID,'
			SET @DESTDATA='(SELECT 7,33,0,'
			 
				WHILE @I<=@ACOUNT
				BEGIN
				
				IF( not exists (SELECT BASECOLUMN FROM #TBLTEMP WHERE ID=@I and BASECOLUMN likE '%acAlpha%'))
				begin
					SET @SOURCEDATA= @SOURCEDATA + (SELECT BASECOLUMN FROM #TBLTEMP WHERE ID=@I)+ ',' 
					
					IF((SELECT LINKCOLUMN FROM #TBLTEMP WHERE ID=@I)='Company')
						SET @DESTDATA =@DESTDATA + 'CRM_Opportunities.'+(SELECT LINKCOLUMN FROM #TBLTEMP WHERE ID=@I)+ ','    
					else
					   SET @DESTDATA= @DESTDATA + (SELECT LINKCOLUMN FROM #TBLTEMP WHERE ID=@I)+ ',' 
					   
					IF(@I<>@ACOUNT)
					BEGIN
						 SET @SOURCEDATA =@SOURCEDATA + ','
						 SET @DESTDATA =@DESTDATA + ',' 
					END
				end	  
				SET @I=@I+1
				END
				
				set @SOURCEDATA=@SOURCEDATA+ '[IsBillwise],[CreditDays],[CreditLimit],  [DebitDays],  [DebitLimit], [Depth], [ParentID],  [lft],  [rgt],  [IsGroup],[CompanyGUID],  [GUID],  [CreatedBy],  [CreatedDate] )'  		
				set @DESTDATA=@DESTDATA + + '1,0,0,0,0,' + CONVERT(NVARCHAR(300),@Depth) + ',' +CONVERT(NVARCHAR(300),@ParentID) + ',' +CONVERT(NVARCHAR(300),@lft)+ ',' + 
				CONVERT(NVARCHAR(300),@rgt) + ',' + CONVERT(NVARCHAR(300),@IsGroup) + ',''' + CONVERT(NVARCHAR(300),@CompanyGUID) + ''',' + 'newid()'
				+ ',CRM_Opportunities.CreatedBy' +  ', CRM_Opportunities.createddate' 
				
				SET  @SOURCEDATA=@SOURCEDATA +  @DESTDATA + ' FROM CRM_Opportunities WITH(nolock) LEFT JOIN crm_opportunitiesEXTENDED WITH(nolock) ON crm_opportunitiesEXTENDED.OpportunityID=CRM_Opportunities.OpportunityID 
				LEFT JOIN COM_Contacts WITH(nolock) ON COM_Contacts.FEATUREPK='+CONVERT(NVARCHAR(300),@OPPORTUNITYID)+' AND ADDRESSTYPEID=1 AND COM_Contacts.FEATUREID=89 WHERE CRM_Opportunities.OpportunityID='+CONVERT(NVARCHAR(300),@OPPORTUNITYID) + ')'
				 PRINT @SOURCEDATA
				DECLARE @tempsql nvarchar(max)
				set  @tempsql=' @AccountID int output'
				set @SOURCEDATA=@SOURCEDATA  + '  set @AccountID=SCOPE_IDENTITY()' 
				EXEC sp_executesql @SOURCEDATA, @tempsql,@AccountID OUTPUT  
			 
 				INSERT INTO COM_CostCenterCostCenterMap VALUES (89,@OPPORTUNITYID,0,2,@AccountID,NEWID(),'','Admin',convert(float,getdate()),'',Null,0)
				 
				IF(@AccountID IS NOT NULL)
				BEGIN
					--Check duplicate
					exec spACC_CheckDuplicate @AccountID
					
					--Handling of Extended Table  
					INSERT INTO [ACC_AccountsExtended]([AccountID],[CreatedBy],[CreatedDate])  
					VALUES(@AccountID, @UserName, @Dt)  

					SET @tempsql=''
					SELECT @tempsql=@tempsql+','+a.name
					FROM sys.columns a
					JOIN sys.columns b on a.name=b.name and b.object_id= object_id('ACC_Accounts')
					WHERE a.object_id= object_id('ACC_AccountsHistory')
					
					set @tempsql= 'insert into [ACC_AccountsHistory] (HistoryStatus'+@tempsql+') select ''Update'''+@tempsql+' from ACC_Accounts with(nolock) WHERE AccountID='+CONVERT(NVARCHAR,@AccountID)     
					EXEC (@tempsql)
						  
					--Insert into Account history  Extended  
					insert into ACC_AccountsExtendedHistory  
					select *,'Update' from [ACC_AccountsExtended] WITH(nolock) WHERE AccountID=@AccountID    
			    
						    
				    IF @AccountContacts=1
					 BEGIN 
							truncate table #TBLCONTACTS
							INSERT INTO #TBLCONTACTS
							SELECT CONTACTID FROM  COM_CONTACTS WITH(nolock) WHERE FEATUREID=89 AND FEATUREPK=@OPPORTUNITYID --AND ADDRESSTYPEID=2 
							SELECT @I=1, @ACOUNT=COUNT(*) FROM #TBLCONTACTS  
							WHILE @I<=@ACOUNT
							BEGIN
								 INSERT INTO COM_CONTACTS([AddressTypeID],[FeatureID]        ,[FeaturePK]        ,[ContactName]        ,[Address1]        ,[Address2]        ,[Address3]        ,[City]        ,[State]        ,[Zip]        ,[Country]        ,[Phone1]        ,[Phone2]        ,[Fax]        ,[Email1]        ,[Email2]        ,[URL]        ,[CompanyGUID]        ,[GUID]        ,[Description]        ,[CreatedBy]        ,[CreatedDate]        ,[ModifiedBy]        ,[ModifiedDate]        ,[CostCenterID]        ,[ContactTypeID]        ,[FirstName]        ,[MiddleName]        ,[LastName]        ,[SalutationID]        ,[JobTitle]        ,[Company]        ,[StatusID]        ,[Department]        ,[RoleLookUpID]        ,[Gender]        ,[BirthDay]        ,[Anniversary]        ,[PreferredID]        ,[PreferredName]        ,[IsEmailOn]        ,[IsBulkEmailOn]        ,[IsMailOn]        ,[IsPhoneOn]        ,[IsFaxOn]        ,[IsVisible]        ,[Depth]        ,[ParentID]        ,[lft]        ,[rgt]        ,[IsGroup]        ,[ConvertFromLeadID])
								SELECT AddressTypeID,2,@AccountID,[ContactName] ,[Address1]        ,[Address2]        ,[Address3]        ,[City]        ,[State]        ,[Zip]        ,[Country]        ,[Phone1]        ,[Phone2]        ,[Fax]        ,[Email1]        ,[Email2]        ,[URL]        ,[CompanyGUID]        ,[GUID]        ,[Description]        ,[CreatedBy]        ,[CreatedDate]        ,[ModifiedBy]        ,[ModifiedDate]        ,89        ,[ContactTypeID]        ,[FirstName]        ,[MiddleName]        ,[LastName]        ,[SalutationID]        ,[JobTitle]        ,[Company]        ,[StatusID]        ,[Department]        ,[RoleLookUpID]        ,[Gender]        ,[BirthDay]        ,[Anniversary]        ,[PreferredID]        ,[PreferredName]        ,[IsEmailOn]        ,[IsBulkEmailOn]        ,[IsMailOn]        ,[IsPhoneOn]        ,[IsFaxOn]        ,[IsVisible]        ,[Depth]        ,[ParentID]        ,[lft]        ,[rgt]        ,[IsGroup]        ,[ConvertFromLeadID] FROM
								COM_CONTACTS WITH(nolock) WHERE CONTACTID IN (SELECT CONTACTID FROM   #TBLCONTACTS WHERE ID=@I)
								SET @CONTACTIDENTITY=SCOPE_IDENTITY()
								
								 
								INSERT INTO [COM_ContactsExtended]([ContactID],[CreatedBy]        ,[CreatedDate]        ,[ModifiedBy]        ,[ModifiedDate]        ,[acAlpha1]        ,[acAlpha2]        ,[acAlpha3]        ,[acAlpha4]        ,[acAlpha5]        ,[acAlpha6]        ,[acAlpha7]        ,[acAlpha8]        ,[acAlpha9]        ,[acAlpha10]        ,[acAlpha11]        ,[acAlpha12]        ,[acAlpha13]        ,[acAlpha14]        ,[acAlpha15]        ,[acAlpha16]        ,[acAlpha17]        ,[acAlpha18]        ,[acAlpha19]        ,[acAlpha20]        ,[acAlpha21]        ,[acAlpha22]        ,[acAlpha23]        ,[acAlpha24]        ,[acAlpha25]        ,[acAlpha26]        ,[acAlpha27]        ,[acAlpha28]        ,[acAlpha29]        ,[acAlpha30]        ,[acAlpha31]        ,[acAlpha32]        ,[acAlpha33]        ,[acAlpha34]        ,[acAlpha35]        ,[acAlpha36]        ,[acAlpha37]        ,[acAlpha38]        ,[acAlpha39]        ,[acAlpha40]        ,[acAlpha41]        ,[acAlpha42]        ,[acAlpha43]        ,[acAlpha44]        ,[acAlpha45]        ,[acAlpha46]        ,[acAlpha47]        ,[acAlpha48]        ,[acAlpha49]        ,[acAlpha50])
								SELECT @CONTACTIDENTITY,[CreatedBy]        ,[CreatedDate]        ,[ModifiedBy]        ,[ModifiedDate]        ,[acAlpha1]        ,[acAlpha2]        ,[acAlpha3]        ,[acAlpha4]        ,[acAlpha5]        ,[acAlpha6]        ,[acAlpha7]        ,[acAlpha8]        ,[acAlpha9]        ,[acAlpha10]        ,[acAlpha11]        ,[acAlpha12]        ,[acAlpha13]        ,[acAlpha14]        ,[acAlpha15]        ,[acAlpha16]        ,[acAlpha17]        ,[acAlpha18]        ,[acAlpha19]        ,[acAlpha20]        ,[acAlpha21]        ,[acAlpha22]        ,[acAlpha23]        ,[acAlpha24]        ,[acAlpha25]        ,[acAlpha26]        ,[acAlpha27]        ,[acAlpha28]        ,[acAlpha29]        ,[acAlpha30]        ,[acAlpha31]        ,[acAlpha32]        ,[acAlpha33]        ,[acAlpha34]        ,[acAlpha35]        ,[acAlpha36]        ,[acAlpha37]        ,[acAlpha38]        ,[acAlpha39]        ,[acAlpha40]        ,[acAlpha41]        ,[acAlpha42]        ,[acAlpha43]        ,[acAlpha44]        ,[acAlpha45]        ,[acAlpha46]        ,[acAlpha47]        ,[acAlpha48]        ,[acAlpha49]        ,[acAlpha50]
								FROM [COM_ContactsExtended] WITH(nolock) WHERE CONTACTID IN (SELECT CONTACTID FROM   #TBLCONTACTS WHERE ID=@I)
								
								INSERT INTO COM_CCCCData([CostCenterID]        ,[NodeID]        ,[CCNodeID]        ,[CCNID1]        ,[CCNID2]        ,[CCNID3]        ,[CCNID4]        ,[CCNID5]        ,[CCNID6]        ,[CCNID7]        ,[CCNID8]        ,[CCNID9]        ,[CCNID10]        ,[CCNID11]        ,[CCNID12]        ,[CCNID13]        ,[CCNID14]        ,[CCNID15]        ,[CCNID16]        ,[CCNID17]        ,[CCNID18]        ,[CCNID19]        ,[CCNID20]        ,[CCNID21]        ,[CCNID22]        ,[CCNID23]        ,[CCNID24]        ,[CCNID25]        ,[CCNID26]        ,[CCNID27]        ,[CCNID28]        ,[CCNID29]        ,[CCNID30]        ,[CCNID31]        ,[CCNID32]        ,[CCNID33]        ,[CCNID34]        ,[CCNID35]        ,[CCNID36]        ,[CCNID37]        ,[CCNID38]        ,[CCNID39]        ,[CCNID40]        ,[CCNID41]        ,[CCNID42]        ,[CCNID43]        ,[CCNID44]        ,[CCNID45]        ,[CCNID46]        ,[CCNID47]        ,[CCNID48]        ,[CCNID49]        ,[CCNID50]        ,[CompanyGUID]        ,[GUID]        ,[Description]        ,[CreatedBy]        ,[CreatedDate]        ,[ModifiedBy]        ,[ModifiedDate]        ,[AccountID]        ,[ProductID])
								SELECT 65,@CONTACTIDENTITY,NULL,[CCNID1]        ,[CCNID2]        ,[CCNID3]        ,[CCNID4]        ,[CCNID5]        ,[CCNID6]        ,[CCNID7]        ,[CCNID8]        ,[CCNID9]        ,[CCNID10]        ,[CCNID11]        ,[CCNID12]        ,[CCNID13]        ,[CCNID14]        ,[CCNID15]        ,[CCNID16]        ,[CCNID17]        ,[CCNID18]        ,[CCNID19]        ,[CCNID20]        ,[CCNID21]        ,[CCNID22]        ,[CCNID23]        ,[CCNID24]        ,[CCNID25]        ,[CCNID26]        ,[CCNID27]        ,[CCNID28]        ,[CCNID29]        ,[CCNID30]        ,[CCNID31]        ,[CCNID32]        ,[CCNID33]        ,[CCNID34]        ,[CCNID35]        ,[CCNID36]        ,[CCNID37]        ,[CCNID38]        ,[CCNID39]        ,[CCNID40]        ,[CCNID41]        ,[CCNID42]        ,[CCNID43]        ,[CCNID44]        ,[CCNID45]        ,[CCNID46]        ,[CCNID47]        ,[CCNID48]        ,[CCNID49]        ,[CCNID50]        ,[CompanyGUID]        ,[GUID]        ,[Description]        ,[CreatedBy]        ,[CreatedDate]        ,[ModifiedBy]        ,[ModifiedDate]        ,[AccountID]        ,[ProductID] 
								FROM COM_CCCCData WITH(nolock) WHERE CostCenterID=65 AND NODEID   IN (SELECT CONTACTID FROM   #TBLCONTACTS WHERE ID=@I)
								SET @I=@I+1
							END
					 END
				END
				 
			END
		  END
	 END
	
	--set notification
	EXEC spCOM_SetNotifEvent -1001,89,@OPPORTUNITYID,@CompanyGUID,@UserName,@UserID,-1
	 
COMMIT TRANSACTION  
 
SET NOCOUNT OFF;   
SELECT ErrorMessage,ErrorNumber FROM COM_ErrorMessages WITH(nolock) 
WHERE ErrorNumber=103 AND LanguageID=@LangID 
RETURN 1
END TRY  
BEGIN CATCH  
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

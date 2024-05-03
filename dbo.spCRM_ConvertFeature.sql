USE PACT2C222
GO
SET ANSI_NULLS, QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spCRM_ConvertFeature]
	@CCID [int] = 0,
	@CCNodeID [int] = 0,
	@ACCOUNT [bit] = 0,
	@AccountContacts [bit] = 0,
	@AccountAddress [bit] = 0,
	@AccountAssign [bit] = 0,
	@PRODUCT [bit] = 0,
	@CompanyGUID [nvarchar](100),
	@UserName [nvarchar](100),
	@UserID [bigint],
	@LangID [int] = 1
WITH ENCRYPTION, EXECUTE AS CALLER
AS
BEGIN TRANSACTION
BEGIN TRY 
SET NOCOUNT ON		

	DECLARE @Dt float,@ParentCode nvarchar(200),@IsCodeAutoGen bit
	DECLARE @lft bigint,@rgt bigint,@Selectedlft bigint,@Selectedrgt bigint,@Depth int,@ParentID bigint
	DECLARE @SelectedIsGroup bit , @DetailContactID bigint,@SelectedNodeID INT,@IsGroup BIT
	DECLARE @LeadCode NVARCHAR(300),@Code NVARCHAR(300),@OpportunityID BIGINT,@CustomerID BIGINT,@DetailContact BIGINT,@AccountID BIGINT
	DECLARE @CompanyName nvarchar(500),@tempCode nvarchar(500),@TABLE nvarchar(500)
	
	set @Dt=CONVERT(float,getdate())
    --INSERT INTO ACCOUNTS TABLE
	IF(@ACCOUNT=1)
	BEGIN 
		IF  NOT EXISTS (SELECT ConvertFromCustomerID FROM ACC_ACCOUNTS WITH(nolock) WHERE ConvertFromCustomerID=@CCNodeID)  
		BEGIN  
			CREATE TABLE #TBLTEMP(ID  INT IDENTITY(1,1),BASECOLUMN NVARCHAR(300),LINKCOLUMN NVARCHAR(300))
			INSERT INTO #TBLTEMP
			select DISTINCT l.SysColumnName, b.SysColumnName 
			from COM_DocumentLinkDetails dl  WITH(nolock)
			left join ADM_CostCenterDef b WITH(nolock) on dl.CostCenterColIDBase=b.CostCenterColID
			left join Com_LanguageResources C WITH(nolock) on C.ResourceID=b.ResourceID   AND C.LanguageID=1
			left join ADM_CostCenterDef l WITH(nolock) on dl.CostCenterColIDLinked=l.CostCenterColID
			where DocumentLinkDeFID in (select DocumentLinkDeFID from COM_DocumentLinkDef  WITH(nolock) where CostCenterIDBase=83)
			and l.costcenterid=2
		
			DECLARE @ACOUNT INT,@I INT,@SOURCEDATA NVARCHAR(MAX),@DESTDATA NVARCHAR(MAX)
			
			SELECT @I=1,@ACOUNT=COUNT(*) FROM #TBLTEMP
			
			IF (@ACOUNT>0)
			BEGIN
				SELECT @SelectedNodeID=isnull(VALUE,1) FROM COM_COSTCENTERPREFERENCES WITH(nolock) 
				WHERE NAME='ConvertedAccountGroup' and costcenterid=83
				
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
		
				SET @SOURCEDATA=' INSERT INTO ACC_ACCOUNTS (AccountTypeID,StatusID,ConvertFromCustomerID,'
				SET @DESTDATA='(SELECT 7,33,'+CONVERT(NVARCHAR(300),@CCNodeID) +','
			
				WHILE @I<=@ACOUNT
				BEGIN
					IF(exists (SELECT BASECOLUMN FROM #TBLTEMP WHERE ID=@I and 
					(BASECOLUMN NOT likE '%CCNID%' AND BASECOLUMN NOT likE '%acAlpha%' AND
					LINKCOLUMN NOT likE '%CCNID%' AND LINKCOLUMN NOT likE '%cuAlpha%')))
					begin 
						SET @SOURCEDATA= @SOURCEDATA + (SELECT BASECOLUMN FROM #TBLTEMP WHERE ID=@I)
						
					
						IF((SELECT LINKCOLUMN FROM #TBLTEMP WHERE ID=@I)='Company')
							SET @DESTDATA =@DESTDATA + 'CRM_Customer.'+(SELECT LINKCOLUMN FROM #TBLTEMP WHERE ID=@I)   
						else
						   SET @DESTDATA= @DESTDATA + (SELECT LINKCOLUMN FROM #TBLTEMP WHERE ID=@I)
						
						BEGIN
							SET @SOURCEDATA =@SOURCEDATA + ','
							SET @DESTDATA =@DESTDATA + ','
						END 
					end	  
					SET @I=@I+1
				END
				
				IF(LEN(@SOURCEDATA)>0)
				BEGIN
					SET @SOURCEDATA=SUBSTRING(@SOURCEDATA,1,LEN(@SOURCEDATA)-1)	
					SET @DESTDATA=SUBSTRING(@DESTDATA,1,LEN(@DESTDATA)-1)	
				END 
				 
				set @SOURCEDATA=@SOURCEDATA+ ',[IsBillwise],[CreditDays],[CreditLimit],  [DebitDays],  [DebitLimit], [Depth], [ParentID],  [lft],  [rgt],  [IsGroup],[CompanyGUID],  [GUID],  [CreatedBy],  [CreatedDate] )'  		
				set @DESTDATA=@DESTDATA + + ',1,0,0,0,0,' + CONVERT(NVARCHAR(300),@Depth) + ',' +CONVERT(NVARCHAR(300),@ParentID) + ',' +CONVERT(NVARCHAR(300),@lft)+ ',' + 
				CONVERT(NVARCHAR(300),@rgt) + ',' + CONVERT(NVARCHAR(300),@IsGroup) + ',''' + CONVERT(NVARCHAR(300),@CompanyGUID) + ''',' + 'newid()'
				+ ',CRM_Customer.CreatedBy' +  ', CRM_Customer.createddate' 
				
				SET  @SOURCEDATA=@SOURCEDATA +  @DESTDATA + ' FROM CRM_Customer  WITH(nolock) LEFT JOIN CRM_CustomerExtended  WITH(nolock) ON CRM_CustomerExtended.CustomerID=CRM_Customer.CustomerID 
				LEFT JOIN COM_Contacts  WITH(nolock) ON COM_Contacts.FEATUREPK='+CONVERT(NVARCHAR(300),@CCNodeID)+' AND COM_Contacts.FEATUREID=83  AND COM_Contacts.AddressTypeID=1
				WHERE CRM_Customer.CustomerID='+CONVERT(NVARCHAR(300),@CCNodeID) + ')'
				PRINT @SOURCEDATA
				SELECT @DESTDATA
				EXEC (@SOURCEDATA) 
				
				declare @DATA NVARCHAR(MAX)
				SELECT @AccountID=ACCOUNTID FROM ACC_ACCOUNTS WITH(nolock) WHERE ConvertFromCustomerID=@CCNodeID
			 
				IF(@AccountID IS NOT NULL)
				BEGIN 
					--Check duplicate
					exec spACC_CheckDuplicate @AccountID
					
					--Handling of Extended Table  
					INSERT INTO [ACC_AccountsExtended]([AccountID],[CreatedBy],[CreatedDate])  
					VALUES(@AccountID, @UserName, @Dt)  
					SET @I=1 
					SELECT @ACOUNT=COUNT(*) FROM #TBLTEMP
					declare @alphacnt int
					select @alphacnt=COUNT(*) from #TBLTEMP where (BASECOLUMN likE '%acAlpha%' AND LINKCOLUMN  likE '%cuAlpha%')
					
					--Added by pranathi for mapping extra fields data of customer to account 
					if(@alphacnt>0)
					BEGIN
						set @DATA='update [ACC_AccountsExtended] set ' 
						SET @SOURCEDATA=''
						SET @DESTDATA=''
						WHILE @I<=@ACOUNT  
						BEGIN   
						 
							IF(exists (SELECT BASECOLUMN FROM #TBLTEMP WHERE ID=@I and 
							(BASECOLUMN likE '%acAlpha%' AND LINKCOLUMN  likE '%cuAlpha%')))
							BEGIN  
								SET @SOURCEDATA=''
								SET @DESTDATA=''
								SET @SOURCEDATA= @SOURCEDATA + (SELECT BASECOLUMN FROM #TBLTEMP WHERE ID=@I) 
								SET @DATA=@DATA+   @SOURCEDATA
								IF((SELECT LINKCOLUMN FROM #TBLTEMP WHERE ID=@I)='Company')
									SET @DESTDATA =@DESTDATA + 'CRM_Customer.'+(SELECT LINKCOLUMN FROM #TBLTEMP WHERE ID=@I)   
								 else
								   SET @DESTDATA= @DESTDATA + (SELECT LINKCOLUMN FROM #TBLTEMP WHERE ID=@I)
								  
								SET @DATA=@DATA+ '= cus.'+@DESTDATA  
								SET @DATA =@DATA + ','
								 
							END	  
							SET @I=@I+1
						END
				
					 
						set @DATA=@DATA+ 'modifiedby='''+@UserName+''' from ACC_Accounts acc  WITH(nolock) 
						JOIN ACC_AccountsExtended EXT WITH(nolock) ON ACC.ACCOUNTID=EXT.ACCOUNTID
						left join CRM_CustomerExtended cus WITH(nolock) on acc.ConvertFromCustomerID=cus.CustomerID
						WHERE ACC.ACCOUNTID='+CONVERT(NVARCHAR(100),@AccountID)+' AND ACC.ConvertFromCustomerID='+CONVERT(NVARCHAR(100),@CCNodeID)
						+' AND EXT.AccountID=ACC.ACCOUNTID'
						
						PRINT @DATA
						EXEC (@DATA)
					end  
					DECLARE @tempsql nvarchar(max)
					--Insert into Account history   
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
			   
						INSERT INTO COM_CCCCData(CostCenterID,NodeID,CCNodeID,CCNID1,CCNID2,CCNID3,CCNID4,CCNID5,CCNID6,CCNID7,CCNID8,CCNID9,CCNID10
						,CCNID11,CCNID12,CCNID13,CCNID14,CCNID15,CCNID16,CCNID17,CCNID18,CCNID19,CCNID20
						,CCNID21,CCNID22,CCNID23,CCNID24,CCNID25,CCNID26,CCNID27,CCNID28,CCNID29,CCNID30
						,CCNID31,CCNID32,CCNID33,CCNID34,CCNID35,CCNID36,CCNID37,CCNID38,CCNID39,CCNID40
						,CCNID41,CCNID42,CCNID43,CCNID44,CCNID45,CCNID46,CCNID47,CCNID48,CCNID49,CCNID50
						,GUID,CreatedBy,CreatedDate)
						select 2,@AccountID, CCNodeID,CCNID1,CCNID2,CCNID3,CCNID4,CCNID5,CCNID6,CCNID7,CCNID8,CCNID9,CCNID10
						,CCNID11,CCNID12,CCNID13,CCNID14,CCNID15,CCNID16,CCNID17,CCNID18,CCNID19,CCNID20
						,CCNID21,CCNID22,CCNID23,CCNID24,CCNID25,CCNID26,CCNID27,CCNID28,CCNID29,CCNID30
						,CCNID31,CCNID32,CCNID33,CCNID34,CCNID35,CCNID36,CCNID37,CCNID38,CCNID39,CCNID40
						,CCNID41,CCNID42,CCNID43,CCNID44,CCNID45,CCNID46,CCNID47,CCNID48,CCNID49,CCNID50
						,newid(), @UserName, @Dt from COM_CCCCDATA WITH(nolock) where [CostCenterID]=83
					    and [NodeID]=@CCNodeID
					
						IF @AccountContacts=1
						BEGIN 
							DECLARE @M INT,@CCOUNT INT,@CONTACTIDENTITY INT
							CREATE TABLE #TBLCONTACTS(ID INT IDENTITY(1,1),CONTACTID BIGINT) 
							INSERT INTO #TBLCONTACTS
							SELECT CONTACTID FROM  COM_CONTACTS WITH(nolock) WHERE FEATUREID=83 AND FEATUREPK=@CCNodeID --AND ADDRESSTYPEID=2
							
							SELECT @M=1, @CCOUNT=COUNT(*) FROM #TBLCONTACTS 			
							WHILE @M<=@CCOUNT
							BEGIN 
								INSERT INTO COM_CONTACTS([AddressTypeID],[FeatureID]        ,[FeaturePK]        ,[ContactName]        ,[Address1]        ,[Address2]        ,[Address3]        ,[City]        ,[State]        ,[Zip]        ,[Country]        ,[Phone1]        ,[Phone2]        ,[Fax]        ,[Email1]        ,[Email2]        ,[URL]        ,[CompanyGUID]        ,[GUID]        ,[Description]        ,[CreatedBy]        ,[CreatedDate]        ,[ModifiedBy]        ,[ModifiedDate]        ,[CostCenterID]        ,[ContactTypeID]        ,[FirstName]        ,[MiddleName]        ,[LastName]        ,[SalutationID]        ,[JobTitle]        ,[Company]        ,[StatusID]        ,[Department]        ,[RoleLookUpID]        ,[Gender]        ,[BirthDay]        ,[Anniversary]        ,[PreferredID]        ,[PreferredName]        ,[IsEmailOn]        ,[IsBulkEmailOn]        ,[IsMailOn]        ,[IsPhoneOn]        ,[IsFaxOn]        ,[IsVisible]        ,[Depth]        ,[ParentID]        ,[lft]        ,[rgt]        ,[IsGroup]        ,[ConvertFromLeadID])
								SELECT ADDRESSTYPEID,2,@AccountID,[ContactName] ,[Address1]        ,[Address2]        ,[Address3]        ,[City]        ,[State]        ,[Zip]        ,[Country]        ,[Phone1]        ,[Phone2]        ,[Fax]        ,[Email1]        ,[Email2]        ,[URL]        ,[CompanyGUID]        ,[GUID]        ,[Description]        ,[CreatedBy]        ,[CreatedDate]        ,[ModifiedBy]        ,[ModifiedDate]        ,89        ,[ContactTypeID]        ,[FirstName]        ,[MiddleName]        ,[LastName]        ,[SalutationID]        ,[JobTitle]        ,[Company]        ,[StatusID]        ,[Department]        ,[RoleLookUpID]        ,[Gender]        ,[BirthDay]        ,[Anniversary]        ,[PreferredID]        ,[PreferredName]        ,[IsEmailOn]        ,[IsBulkEmailOn]        ,[IsMailOn]        ,[IsPhoneOn]        ,[IsFaxOn]        ,[IsVisible]        ,[Depth]        ,[ParentID]        ,[lft]        ,[rgt]        ,[IsGroup]        ,[ConvertFromLeadID] FROM
								COM_CONTACTS WITH(nolock) WHERE CONTACTID IN (SELECT CONTACTID FROM   #TBLCONTACTS WHERE ID=@M)
								SET @CONTACTIDENTITY=SCOPE_IDENTITY()
								
								INSERT INTO [COM_ContactsExtended]([ContactID],[CreatedBy]        ,[CreatedDate]        ,[ModifiedBy]        ,[ModifiedDate]        ,[acAlpha1]        ,[acAlpha2]        ,[acAlpha3]        ,[acAlpha4]        ,[acAlpha5]        ,[acAlpha6]        ,[acAlpha7]        ,[acAlpha8]        ,[acAlpha9]        ,[acAlpha10]        ,[acAlpha11]        ,[acAlpha12]        ,[acAlpha13]        ,[acAlpha14]        ,[acAlpha15]        ,[acAlpha16]        ,[acAlpha17]        ,[acAlpha18]        ,[acAlpha19]        ,[acAlpha20]        ,[acAlpha21]        ,[acAlpha22]        ,[acAlpha23]        ,[acAlpha24]        ,[acAlpha25]        ,[acAlpha26]        ,[acAlpha27]        ,[acAlpha28]        ,[acAlpha29]        ,[acAlpha30]        ,[acAlpha31]        ,[acAlpha32]        ,[acAlpha33]        ,[acAlpha34]        ,[acAlpha35]        ,[acAlpha36]        ,[acAlpha37]        ,[acAlpha38]        ,[acAlpha39]        ,[acAlpha40]        ,[acAlpha41]        ,[acAlpha42]        ,[acAlpha43]        ,[acAlpha44]        ,[acAlpha45]        ,[acAlpha46]        ,[acAlpha47]        ,[acAlpha48]        ,[acAlpha49]        ,[acAlpha50])
								SELECT @CONTACTIDENTITY,[CreatedBy]        ,[CreatedDate]        ,[ModifiedBy]        ,[ModifiedDate]        ,[acAlpha1]        ,[acAlpha2]        ,[acAlpha3]        ,[acAlpha4]        ,[acAlpha5]        ,[acAlpha6]        ,[acAlpha7]        ,[acAlpha8]        ,[acAlpha9]        ,[acAlpha10]        ,[acAlpha11]        ,[acAlpha12]        ,[acAlpha13]        ,[acAlpha14]        ,[acAlpha15]        ,[acAlpha16]        ,[acAlpha17]        ,[acAlpha18]        ,[acAlpha19]        ,[acAlpha20]        ,[acAlpha21]        ,[acAlpha22]        ,[acAlpha23]        ,[acAlpha24]        ,[acAlpha25]        ,[acAlpha26]        ,[acAlpha27]        ,[acAlpha28]        ,[acAlpha29]        ,[acAlpha30]        ,[acAlpha31]        ,[acAlpha32]        ,[acAlpha33]        ,[acAlpha34]        ,[acAlpha35]        ,[acAlpha36]        ,[acAlpha37]        ,[acAlpha38]        ,[acAlpha39]        ,[acAlpha40]        ,[acAlpha41]        ,[acAlpha42]        ,[acAlpha43]        ,[acAlpha44]        ,[acAlpha45]        ,[acAlpha46]        ,[acAlpha47]        ,[acAlpha48]        ,[acAlpha49]        ,[acAlpha50]
								FROM [COM_ContactsExtended] WITH(nolock) WHERE CONTACTID IN (SELECT CONTACTID FROM   #TBLCONTACTS WHERE ID=@M)
								
								INSERT INTO COM_CCCCData([CostCenterID]        ,[NodeID]        ,[CCNodeID]        ,[CCNID1]        ,[CCNID2]        ,[CCNID3]        ,[CCNID4]        ,[CCNID5]        ,[CCNID6]        ,[CCNID7]        ,[CCNID8]        ,[CCNID9]        ,[CCNID10]        ,[CCNID11]        ,[CCNID12]        ,[CCNID13]        ,[CCNID14]        ,[CCNID15]        ,[CCNID16]        ,[CCNID17]        ,[CCNID18]        ,[CCNID19]        ,[CCNID20]        ,[CCNID21]        ,[CCNID22]        ,[CCNID23]        ,[CCNID24]        ,[CCNID25]        ,[CCNID26]        ,[CCNID27]        ,[CCNID28]        ,[CCNID29]        ,[CCNID30]        ,[CCNID31]        ,[CCNID32]        ,[CCNID33]        ,[CCNID34]        ,[CCNID35]        ,[CCNID36]        ,[CCNID37]        ,[CCNID38]        ,[CCNID39]        ,[CCNID40]        ,[CCNID41]        ,[CCNID42]        ,[CCNID43]        ,[CCNID44]        ,[CCNID45]        ,[CCNID46]        ,[CCNID47]        ,[CCNID48]        ,[CCNID49]        ,[CCNID50]        ,[CompanyGUID]        ,[GUID]        ,[Description]        ,[CreatedBy]        ,[CreatedDate]        ,[ModifiedBy]        ,[ModifiedDate]        ,[AccountID]        ,[ProductID])
								SELECT 65,@CONTACTIDENTITY,NULL,[CCNID1]        ,[CCNID2]        ,[CCNID3]        ,[CCNID4]        ,[CCNID5]        ,[CCNID6]        ,[CCNID7]        ,[CCNID8]        ,[CCNID9]        ,[CCNID10]        ,[CCNID11]        ,[CCNID12]        ,[CCNID13]        ,[CCNID14]        ,[CCNID15]        ,[CCNID16]        ,[CCNID17]        ,[CCNID18]        ,[CCNID19]        ,[CCNID20]        ,[CCNID21]        ,[CCNID22]        ,[CCNID23]        ,[CCNID24]        ,[CCNID25]        ,[CCNID26]        ,[CCNID27]        ,[CCNID28]        ,[CCNID29]        ,[CCNID30]        ,[CCNID31]        ,[CCNID32]        ,[CCNID33]        ,[CCNID34]        ,[CCNID35]        ,[CCNID36]        ,[CCNID37]        ,[CCNID38]        ,[CCNID39]        ,[CCNID40]        ,[CCNID41]        ,[CCNID42]        ,[CCNID43]        ,[CCNID44]        ,[CCNID45]        ,[CCNID46]        ,[CCNID47]        ,[CCNID48]        ,[CCNID49]        ,[CCNID50]        ,[CompanyGUID]        ,[GUID]        ,[Description]        ,[CreatedBy]        ,[CreatedDate]        ,[ModifiedBy]        ,[ModifiedDate]        ,[AccountID]        ,[ProductID] 
								FROM COM_CCCCData WITH(nolock) WHERE CostCenterID=65 AND NODEID   IN (SELECT CONTACTID FROM   #TBLCONTACTS WHERE ID=@M)
								 
								 SET @M=@M+1
							END
							drop table #TBLCONTACTS
							
						END 
						
						IF @AccountAddress=1
						BEGIN 
							DECLARE @M1 INT,@CCOUNT1 INT,@ADDRESSIDENTITY INT
							CREATE TABLE #TBLAddress(ID INT IDENTITY(1,1),AddressID BIGINT) 
							INSERT INTO #TBLAddress
							SELECT AddressID FROM  COM_Address WITH(nolock) WHERE FEATUREID=83 AND FEATUREPK=@CCNodeID --AND ADDRESSTYPEID=2
							
							SELECT @M1=1, @CCOUNT1=COUNT(*) FROM #TBLAddress 			
							WHILE @M1<=@CCOUNT1
							BEGIN 
								INSERT INTO [COM_Address] ([ContactPerson],[AddressTypeID],[FeatureID],[FeaturePK],[Address1],[Address2],[Address3],[City],[State],[Zip],[Country],[Phone1],[Phone2],[Fax],[Email1],[Email2],[URL],[CompanyGUID],[GUID],[Description],[CreatedBy],[CreatedDate],[ModifiedBy],[ModifiedDate],[CostCenterID],[AddressName]
								,[Alpha1],[CCNID1],[Alpha2],[CCNID2],[Alpha3],[CCNID3],[Alpha4],[CCNID4],[Alpha5],[CCNID5],[Alpha6],[CCNID6],[Alpha7],[CCNID7],[Alpha8],[CCNID8],[Alpha9],[CCNID9],[Alpha10],[CCNID10],[Alpha11],[CCNID11],[Alpha12],[CCNID12],[Alpha13],[CCNID13],[Alpha14],[CCNID14],[Alpha15]
								,[CCNID15],[Alpha16],[CCNID16],[Alpha17],[CCNID17],[Alpha18],[CCNID18],[Alpha19],[CCNID19],[Alpha20],[CCNID20],[Alpha21],[CCNID21],[Alpha22],[CCNID22],[Alpha23],[CCNID23],[Alpha24],[CCNID24],[Alpha25],[CCNID25],[Alpha26],[CCNID26],[Alpha27],[CCNID27]
								,[Alpha28],[CCNID28],[Alpha29],[CCNID29],[Alpha30],[CCNID30],[Alpha31],[CCNID31],[Alpha32],[CCNID32],[Alpha33],[CCNID33],[Alpha34],[CCNID34],[Alpha35],[CCNID35],[Alpha36],[CCNID36],[Alpha37],[CCNID37],[Alpha38],[CCNID38],[Alpha39],[CCNID39],[Alpha40],[CCNID40],[Alpha41]
								,[CCNID41],[Alpha42],[CCNID42],[Alpha43],[CCNID43],[Alpha44],[CCNID44],[Alpha45],[CCNID45],[Alpha46],[CCNID46],[Alpha47],[CCNID47],[Alpha48],[CCNID48],[Alpha49],[CCNID49],[Alpha50],[CCNID50])
								SELECT ContactPerson,AddressTypeID,2,@AccountID,[Address1],[Address2],[Address3],[City],[State],[Zip],[Country],[Phone1],[Phone2],[Fax],[Email1],[Email2],[URL],[CompanyGUID],[GUID],[Description],[CreatedBy],[CreatedDate],[ModifiedBy],[ModifiedDate],[CostCenterID],[AddressName]
								,[Alpha1],[CCNID1],[Alpha2],[CCNID2],[Alpha3],[CCNID3],[Alpha4],[CCNID4],[Alpha5],[CCNID5],[Alpha6],[CCNID6],[Alpha7],[CCNID7],[Alpha8],[CCNID8],[Alpha9],[CCNID9],[Alpha10],[CCNID10],[Alpha11],[CCNID11],[Alpha12],[CCNID12],[Alpha13],[CCNID13],[Alpha14],[CCNID14],[Alpha15]
								,[CCNID15],[Alpha16],[CCNID16],[Alpha17],[CCNID17],[Alpha18],[CCNID18],[Alpha19],[CCNID19],[Alpha20],[CCNID20],[Alpha21],[CCNID21],[Alpha22],[CCNID22],[Alpha23],[CCNID23],[Alpha24],[CCNID24],[Alpha25],[CCNID25],[Alpha26],[CCNID26],[Alpha27],[CCNID27]
								,[Alpha28],[CCNID28],[Alpha29],[CCNID29],[Alpha30],[CCNID30],[Alpha31],[CCNID31],[Alpha32],[CCNID32],[Alpha33],[CCNID33],[Alpha34],[CCNID34],[Alpha35],[CCNID35],[Alpha36],[CCNID36],[Alpha37],[CCNID37],[Alpha38],[CCNID38],[Alpha39],[CCNID39],[Alpha40],[CCNID40],[Alpha41]
								,[CCNID41],[Alpha42],[CCNID42],[Alpha43],[CCNID43],[Alpha44],[CCNID44],[Alpha45],[CCNID45],[Alpha46],[CCNID46],[Alpha47],[CCNID47],[Alpha48],[CCNID48],[Alpha49],[CCNID49],[Alpha50],[CCNID50]
								FROM COM_Address WITH(nolock) WHERE AddressID IN (SELECT AddressID FROM   #TBLAddress WHERE ID=@M1)
								SET @ADDRESSIDENTITY=SCOPE_IDENTITY()								
								
								INSERT INTO [COM_Address_History]
								([AddressID],[ContactPerson],[AddressTypeID],[FeatureID],[FeaturePK],[Address1],[Address2],[Address3],[City],[State],[Zip],[Country],[Phone1],[Phone2],[Fax],[Email1],[Email2],[URL],[CompanyGUID],[GUID],[Description],[CreatedBy],[CreatedDate],[ModifiedBy],[ModifiedDate],[CostCenterID],[AddressName],
								[Alpha1],[CCNID1],[Alpha2],[CCNID2],[Alpha3],[CCNID3],[Alpha4],[CCNID4],[Alpha5],[CCNID5],[Alpha6],[CCNID6],[Alpha7],[CCNID7],[Alpha8],[CCNID8],[Alpha9],[CCNID9],[Alpha10],[CCNID10],[Alpha11],[CCNID11],[Alpha12],[CCNID12]
								,[Alpha13],[CCNID13],[Alpha14],[CCNID14],[Alpha15],[CCNID15],[Alpha16],[CCNID16],[Alpha17],[CCNID17],[Alpha18],[CCNID18],[Alpha19],[CCNID19],[Alpha20],[CCNID20],[Alpha21],[CCNID21],[Alpha22],[CCNID22],[Alpha23],[CCNID23]
								,[Alpha24],[CCNID24],[Alpha25],[CCNID25],[Alpha26],[CCNID26],[Alpha27],[CCNID27],[Alpha28],[CCNID28],[Alpha29],[CCNID29],[Alpha30],[CCNID30],[Alpha31],[CCNID31],[Alpha32],[CCNID32],[Alpha33],[CCNID33],[Alpha34],[CCNID34]
								,[Alpha35],[CCNID35],[Alpha36],[CCNID36],[Alpha37],[CCNID37],[Alpha38],[CCNID38],[Alpha39],[CCNID39],[Alpha40],[CCNID40],[Alpha41],[CCNID41],[Alpha42],[CCNID42],[Alpha43],[CCNID43],[Alpha44],[CCNID44],[Alpha45],[CCNID45],[Alpha46],[CCNID46],[Alpha47],[CCNID47],[Alpha48],[CCNID48],[Alpha49],[CCNID49],[Alpha50],[CCNID50])
								SELECT @ADDRESSIDENTITY,ContactPerson,AddressTypeID,2,@AccountID,[Address1],[Address2],[Address3],[City],[State],[Zip],[Country],[Phone1],[Phone2],[Fax],[Email1],[Email2],[URL],[CompanyGUID],[GUID],[Description],[CreatedBy],[CreatedDate],[ModifiedBy],[ModifiedDate],[CostCenterID],[AddressName]
								,[Alpha1],[CCNID1],[Alpha2],[CCNID2],[Alpha3],[CCNID3],[Alpha4],[CCNID4],[Alpha5],[CCNID5],[Alpha6],[CCNID6],[Alpha7],[CCNID7],[Alpha8],[CCNID8],[Alpha9],[CCNID9],[Alpha10],[CCNID10],[Alpha11],[CCNID11],[Alpha12],[CCNID12],[Alpha13],[CCNID13],[Alpha14],[CCNID14],[Alpha15]
								,[CCNID15],[Alpha16],[CCNID16],[Alpha17],[CCNID17],[Alpha18],[CCNID18],[Alpha19],[CCNID19],[Alpha20],[CCNID20],[Alpha21],[CCNID21],[Alpha22],[CCNID22],[Alpha23],[CCNID23],[Alpha24],[CCNID24],[Alpha25],[CCNID25],[Alpha26],[CCNID26],[Alpha27],[CCNID27]
								,[Alpha28],[CCNID28],[Alpha29],[CCNID29],[Alpha30],[CCNID30],[Alpha31],[CCNID31],[Alpha32],[CCNID32],[Alpha33],[CCNID33],[Alpha34],[CCNID34],[Alpha35],[CCNID35],[Alpha36],[CCNID36],[Alpha37],[CCNID37],[Alpha38],[CCNID38],[Alpha39],[CCNID39],[Alpha40],[CCNID40],[Alpha41]
								,[CCNID41],[Alpha42],[CCNID42],[Alpha43],[CCNID43],[Alpha44],[CCNID44],[Alpha45],[CCNID45],[Alpha46],[CCNID46],[Alpha47],[CCNID47],[Alpha48],[CCNID48],[Alpha49],[CCNID49],[Alpha50],[CCNID50]
								FROM COM_Address WITH(nolock) WHERE AddressID IN (SELECT AddressID FROM   #TBLAddress WHERE ID=@M1)
								
								 SET @M1=@M1+1
							END
							drop table #TBLAddress
							
						END
						
						IF @AccountAssign=1
						BEGIN 
							DECLARE @M2 INT,@CCOUNT2 INT,@ASSIGNDENTITY INT
							CREATE TABLE #TBLAssign(ID INT IDENTITY(1,1),CCCCMapID BIGINT) 
							INSERT INTO #TBLAssign
							SELECT CCCCMapID FROM  COM_CostCenterCostCenterMap WITH(nolock) WHERE ParentCostCenterID=83 AND ParentNodeID=@CCNodeID --AND ADDRESSTYPEID=2
							
							SELECT @M2=1, @CCOUNT2=COUNT(*) FROM #TBLAssign 			
							WHILE @M2<=@CCOUNT2
							BEGIN 
								INSERT INTO [COM_CostCenterCostCenterMap] ([ParentCostCenterID],[ParentNodeID],[CostCenterColID],[CostCenterID],[NodeID],[GUID],[Description],[CreatedBy],[CreatedDate],[ModifiedBy],[ModifiedDate],[CompanyGuid])
								SELECT 2,@AccountID,NULL,[CostCenterID],[NodeID],[GUID],[Description],[CreatedBy],[CreatedDate],[ModifiedBy],
								[ModifiedDate],[CompanyGuid] FROM COM_CostCenterCostCenterMap WHERE CCCCMapID IN (SELECT CCCCMapID FROM #TBLAssign WHERE ID=@M2)
								 
								SET @M2=@M2+1
							END
							drop table #TBLAssign
							
						END
						--TEST
						UPDATE CRM_Customer SET [STATUSID]=442  WHERE CustomerID=@CCNodeID
					END
				END
			END
		END
	-------------INSERT INTO PRODUCT TABLE
	IF(@PRODUCT=1)
	BEGIN
		IF  NOT EXISTS (SELECT ConvertedCRMProduct FROM INV_Product WITH(nolock) WHERE ConvertedCRMProduct=@CCNodeID)  
		BEGIN  
			SELECT 	@TABLE=TABLENAME FROM ADM_FEATURES WITH(nolock) WHERE FEATUREID=@CCID
			
			DECLARE @SQL NVARCHAR(MAX)
			SET @tempCode=' @CODE NVARCHAR(300) OUTPUT'  
			SET @SQL=' select @CODE=CODE  from '+@Table+' WITH(nolock) WHERE NODEID='+CONVERT(NVARCHAR(300),@CCNodeID)
			EXEC sp_executesql @SQL, @tempCode,@CODE OUTPUT  
			
			SET @tempCode=' @CompanyName NVARCHAR(300) OUTPUT'  
			SET @SQL=' select @CompanyName=NAME  from '+@Table+' WITH(nolock) WHERE NODEID='+CONVERT(NVARCHAR(300),@CCNodeID)
			EXEC sp_executesql @SQL, @tempCode,@CompanyName OUTPUT  
			
			SELECT @SelectedNodeID=isnull(VALUE,1) FROM COM_COSTCENTERPREFERENCES WITH(nolock) 
			WHERE NAME='ConvertedProductGroup' and costcenterid=145    
			
			declare @UOM bigint
			select @UOM=isnull(userdefaultvalue,1) from adm_costcenterdef WITH(nolock) 
			where costcentercolid=268
			
			IF @SelectedNodeID=0 OR @SelectedNodeID=NULL
				SET @SelectedNodeID=1
			
			DECLARE @return_value BIGINT
			EXEC @return_value = [dbo].[spINV_SetProduct]
				@ProductID = 0,
				@ProductCode = @Code,
				@ProductName = @CompanyName,
				@AliasName=@CompanyName,
				@ProductTypeID=1,
				@StatusID =31,  	
				@UOMID=@UOM,
				@Description=@CompanyName,
				@SelectedNodeID = @SelectedNodeID,
				@IsGroup = 0,
				@CustomCostCenterFieldsQuery=NULL,
				@ContactsXML =NULL,
				@NotesXML =NULL,
				@AttachmentsXML =NULL,
				@BarcodeID =0,
				@CompanyGUID=@COMPANYGUID,@GUID='GUID',@UserName=@USERNAME,@UserID=@USERID
				--@return_value					
				UPDATE INV_Product
				SET ConvertedCRMProduct=@CCNodeID
				WHERE PRODUCTID=@return_value 
		END
	END
	 
	 
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

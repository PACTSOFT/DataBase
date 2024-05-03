USE PACT2C222
GO
SET ANSI_NULLS, QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spCRM_ConvertLead]
	@LEADID [int] = 0,
	@Opportunity [bit] = 0,
	@Contact [bit] = 0,
	@Customer [bit] = 0,
	@ACCOUNT [bit] = 0,
	@CustomerContacts [bit] = 0,
	@AccountContacts [bit] = 0,
	@LeadAddressDetails [bit] = 0,
	@CompanyGUID [nvarchar](100),
	@UserName [nvarchar](100),
	@UserID [bigint],
	@LangID [int] = 1
WITH ENCRYPTION, EXECUTE AS CALLER
AS
BEGIN TRANSACTION
BEGIN TRY 
SET NOCOUNT ON
	create table #temp1(prefix nvarchar(100),number bigint, suffix nvarchar(100), code nvarchar(200), IsManualcode bit)
	DECLARE @Dt float,@ParentCode nvarchar(200),@IsCodeAutoGen bit,@CodePrefix NVARCHAR(300),@CodeNumber BIGINT
	DECLARE @lft bigint,@rgt bigint,@Selectedlft bigint,@Selectedrgt bigint,@Depth int,@ParentID bigint
	DECLARE @SelectedIsGroup bit , @DetailContactID bigint,@SelectedNodeID INT,@IsGroup BIT
	DECLARE @LeadCode NVARCHAR(300),@Code NVARCHAR(300),@OpportunityID BIGINT,@CustomerID BIGINT,@AccountID BIGINT
	DECLARE @CompanyName nvarchar(500),@Description nvarchar(500)
	DECLARE @CONTACTSXML NVARCHAR(MAX) 
	CREATE TABLE #TBLTEMP(ID  INT IDENTITY(1,1),BASECOLUMN NVARCHAR(300),LINKCOLUMN NVARCHAR(300))
	CREATE TABLE #TBLCONTACTS(ID INT IDENTITY(1,1),CONTACTID BIGINT)
	
	SELECT @LeadCode=Code,@DetailContactID=ContactID,@CompanyName=Company,@Description=[Description]  
	FROM CRM_Leads WITH(nolock)  WHERE LeadID=@LEADID

	SET @Dt=convert(float,getdate())--Setting Current Date  

	SET @SelectedNodeID=1

	------------INSERT INTO OPPORTUNITY TABLE
	IF (@Opportunity = 1)
	BEGIN
  
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
		
		SET @IsGroup=0 
		SELECT @IsCodeAutoGen=Value FROM COM_CostCenterPreferences  WITH(nolock) 
		WHERE COSTCENTERID=89 and  Name='CodeAutoGen'  

		--GENERATE CODE  
		IF @IsCodeAutoGen IS NOT NULL AND @IsCodeAutoGen=1  
		BEGIN   
 
			--CALL AUTOCODEGEN 
			if(@SelectedNodeID is null)
			insert into #temp1
			EXEC [spCOM_GetCodeData] 89,1,''  
			else
			insert into #temp1
			EXEC [spCOM_GetCodeData] 89,@SelectedNodeID,''  
			select @Code=code,@CodePrefix= prefix, @CodeNumber=number from #temp1

		END  
    
		---CHECKING AUTO GENERATE CODE
		IF @Code='' OR @Code IS NULL 
		begin
			SET @Code=@LeadCode
		end
 
		IF NOT EXISTS (SELECT ConvertFromLeadID FROM CRM_Opportunities WITH(nolock) WHERE ConvertFromLeadID=@LEADID)  
		BEGIN  
		
		
			INSERT INTO #TBLTEMP
			select l.SysColumnName, b.SysColumnName 
			from COM_DocumentLinkDetails dl WITH(nolock)
			left join ADM_CostCenterDef b WITH(nolock) on dl.CostCenterColIDBase=b.CostCenterColID
			left join Com_LanguageResources C WITH(nolock) on C.ResourceID=b.ResourceID   AND C.LanguageID=1
			left join ADM_CostCenterDef l WITH(nolock) on dl.CostCenterColIDLinked=l.CostCenterColID
			where DocumentLinkDeFID in (select DocumentLinkDeFID from COM_DocumentLinkDef WITH(nolock) where CostCenterIDBase=86   )
			and l.costcenterid=89
			
			DECLARE @ACOUNT INT,@I INT,@TotalCount bigint,@SOURCEDATA NVARCHAR(MAX),@DESTDATA NVARCHAR(MAX),@OPPSTATUSID INT
			
			IF(EXISTS (SELECT * FROM COM_Lookup WITH(NOLOCK) WHERE LookupType=56 AND IsDefault=1))
				SELECT @OPPSTATUSID=NODEID FROM COM_Lookup WITH(NOLOCK) WHERE LookupType=56 AND IsDefault=1
			ELSE
				SET @OPPSTATUSID=(SELECT TOP 1 NODEID FROM COM_Lookup WITH(NOLOCK) WHERE LookupType=56 ORDER BY NodeID)
				
			select @TotalCount=COUNT(*) FROM #TBLTEMP    
		 	
			DELETE FROM #TBLTEMP WHERE LINKCOLUMN IN ('FirstName','Code','StatusID','MiddleName','LastName','JobTitle','Phone1','Phone2','Email1','Fax','Department','SalutationID')
			alter table #TBLTEMP drop column id
			alter table #TBLTEMP Add  ID int identity(1,1)
			SELECT @I=1,@ACOUNT=COUNT(*) FROM #TBLTEMP   
			IF (@OPPSTATUSID IS NULL OR @OPPSTATUSID=0)
				SET @OPPSTATUSID=1
			--FIRST INSERT INTO MAIN TABLE 
			SET @DESTDATA=''
			SET @SOURCEDATA=''
			SET @OpportunityID=0
			SET @SOURCEDATA=' INSERT INTO crm_opportunities (DetailsContactID,ConvertFromLeadID,CodePrefix,CodeNumber,Code,StatusID,' 
			SET @DESTDATA='(SELECT 1,'+CONVERT(NVARCHAR(300),@LEADID) +','''+isnull(@CodePrefix,'')+''','+CONVERT(NVARCHAR(300),isnull(@CodeNumber,0)) +','''+@Code+''','+CONVERT(NVARCHAR(300),@OPPSTATUSID)+','  
			--MAIN TABLE  
			WHILE @I<=@ACOUNT
			BEGIN
		
				IF(  exists (SELECT * FROM #TBLTEMP WHERE ID=@I and (BASECOLUMN NOT likE '%CCNID%' AND BASECOLUMN NOT likE '%opAlpha%' AND
				LINKCOLUMN NOT likE '%CCNID%' AND LINKCOLUMN NOT likE '%LDAlpha%')))
				begin 
					SET @SOURCEDATA= @SOURCEDATA + (SELECT BASECOLUMN FROM #TBLTEMP WHERE ID=@I) 				 
					IF((SELECT LINKCOLUMN FROM #TBLTEMP WHERE ID=@I)='Company')
						 SET @DESTDATA =@DESTDATA + 'CRM_LEADS.'+(SELECT LINKCOLUMN FROM #TBLTEMP WHERE ID=@I)   
					 else
					   SET @DESTDATA= @DESTDATA + (SELECT LINKCOLUMN FROM #TBLTEMP WHERE ID=@I)
					   
					--IF(@I<>@ACOUNT)
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
				 
				set @SOURCEDATA=@SOURCEDATA+ ',[Depth], [ParentID],  [lft],  [rgt],  [IsGroup],[CompanyGUID],  [GUID],  [CreatedBy],  [CreatedDate] )'  		
				set @DESTDATA=@DESTDATA + + ',' + CONVERT(NVARCHAR(300),@Depth) + ',' +CONVERT(NVARCHAR(300),@ParentID) + ',' +CONVERT(NVARCHAR(300),@lft)+ ',' + 
				CONVERT(NVARCHAR(300),@rgt) + ',' + CONVERT(NVARCHAR(300),@IsGroup) + ',''' + CONVERT(NVARCHAR(300),@CompanyGUID) + ''',' + 'newid()'
				+ ',CRM_LEADS.CreatedBy' +  ', CRM_LEADS.createddate' 
				
				SET  @SOURCEDATA=@SOURCEDATA +  @DESTDATA + ' FROM CRM_LEADS WITH(nolock)   
				WHERE CRM_LEADS.LEADID='+CONVERT(NVARCHAR(300),@LEADID) + ')'
				PRINT @SOURCEDATA
				 
				EXEC (@SOURCEDATA) 
			    SELECT @OpportunityID=OpportunityID,@Code=Code,@CompanyName=Company FROM crm_opportunities WITH(nolock) WHERE ConvertFromLeadID=@LEADID
			     
				INSERT INTO COM_CCCCDATA ([CostCenterID] ,[NodeID] ,[Guid],[CreatedBy],[CreatedDate])
				VALUES(89,@OpportunityID,newid(),  @USERNAME, @Dt) 
				  
				SET @SOURCEDATA=''
				SET @DESTDATA=''
				SET @ACOUNT=0
				 
				SELECT @I=1,@ACOUNT=COUNT(*) FROM #TBLTEMP 
				 
				SET @SOURCEDATA=' INSERT INTO crm_opportunitiesEXTENDED (OpportunityID,'
				SET @DESTDATA='(SELECT '+CONVERT(NVARCHAR(300),@OpportunityID) +','
				--EXTENDED TABLE
				WHILE @I<=@TotalCount
				BEGIN 
				IF( exists (SELECT * FROM #TBLTEMP WHERE ID=@I and (BASECOLUMN likE '%opAlpha%' AND LINKCOLUMN  likE '%LDAlpha%')))
				begin
			 
					SET @SOURCEDATA= @SOURCEDATA + (SELECT BASECOLUMN FROM #TBLTEMP WHERE ID=@I) 				 
				    SET @DESTDATA= @DESTDATA + (SELECT LINKCOLUMN FROM #TBLTEMP WHERE ID=@I)  
					BEGIN
						 SET @SOURCEDATA =@SOURCEDATA + ','
						 SET @DESTDATA =@DESTDATA + ',' 
					END
				end	  
				else IF( exists (SELECT * FROM #TBLTEMP WHERE ID=@I and (BASECOLUMN likE '%opAlpha%'
				 AND (LINKCOLUMN not likE '%LDAlpha%' or LINKCOLUMN not likE '%CCNID%'))))
				begin 
					SET @SOURCEDATA= @SOURCEDATA + (SELECT BASECOLUMN FROM #TBLTEMP WHERE ID=@I) 				 
				    SET @DESTDATA= @DESTDATA + ' L.'+ (SELECT LINKCOLUMN FROM #TBLTEMP WHERE ID=@I)  
					BEGIN
						 SET @SOURCEDATA =@SOURCEDATA + ','
						 SET @DESTDATA =@DESTDATA + ',' 
					END
				end	   
				SET @I=@I+1
				END
				
				--IF(LEN(@SOURCEDATA)>0)
				BEGIN
					 SET @SOURCEDATA=SUBSTRING(@SOURCEDATA,1,LEN(@SOURCEDATA)-1)	
					 SET @DESTDATA=SUBSTRING(@DESTDATA,1,LEN(@DESTDATA)-1)	
				END 
				 
				set @SOURCEDATA=@SOURCEDATA+ ',[CreatedBy],  [CreatedDate] )'  		
				set @DESTDATA=@DESTDATA + + ',CRM_LEADSEXTENDED.CreatedBy' +  ', CRM_LEADSEXTENDED.createddate' 
				
				SET  @SOURCEDATA=@SOURCEDATA +  @DESTDATA + ' FROM CRM_LEADSEXTENDED WITH(nolock)   
				JOIN CRM_LEADS L WITH(NOLOCK) ON CRM_LEADSEXTENDED.LEADID=L.LEADID
				WHERE CRM_LEADSEXTENDED.LEADID='+CONVERT(NVARCHAR(300),@LEADID) + ')'
				PRINT @SOURCEDATA	
		        EXEC(@SOURCEDATA)
		       
		        SET @SOURCEDATA=''
				SET @DESTDATA=''
				SET @ACOUNT=0
				 
				SELECT @I=1,@ACOUNT=COUNT(*) FROM #TBLTEMP  
				 
				--CCDATA TABLE
				WHILE @I<=@TotalCount
				BEGIN 
			 
					IF( exists (SELECT * FROM #TBLTEMP WHERE ID=@I and  (BASECOLUMN likE '%CCNID%' AND LINKCOLUMN likE '%CCNID%') ))
					begin
						SET @SOURCEDATA= 'UPDATE COM_CCCCDATA SET '+(SELECT BASECOLUMN FROM #TBLTEMP WHERE ID=@I)+'=(
						SELECT '+(SELECT LINKCOLUMN FROM #TBLTEMP WHERE ID=@I)+' FROM COM_CCCCDATA WITH(nolock) WHERE COSTCENTERID=86 AND 
						NODEID='+CONVERT(NVARCHAR,@LEADID) +') WHERE COSTCENTERID=89 AND [NodeID]='+CONVERT(NVARCHAR,@OpportunityID)  
						EXEC(@SOURCEDATA)
					    
						SET @SOURCEDATA=''
					end	  
					SET @I=@I+1
				END
				 
		       
				DECLARE @return_value int,@LinkCostCenterID INT
	  			IF(@OpportunityID>0)
				BEGIN
					DECLARE @TBLPREF TABLE(ID INT IDENTITY(1,1),VALUE NVARCHAR(300))
					DECLARE @FILTER NVARCHAR(300),@FILTERVALUE NVARCHAR(300),@PREFVALUE NVARCHAR(300) 
					SELECT @PREFVALUE=VALUE FROM COM_COSTCENTERPREFERENCES WITH(nolock) 
					WHERE COSTCENTERID=86 AND NAME='QualifyProductsBasedon'
			
					INSERT INTO @TBLPREF (VALUE)
					EXEC SPSPLITSTRING @PREFVALUE ,';'
			
					SELECT @FILTER=ISNULL(SYSCOLUMNNAME,'') FROM   ADM_CostCenterDef WITH(NOLOCK) WHERE CostCenterID=115 AND COSTCENTERCOLID
					IN (SELECT VALUE FROM @TBLPREF WHERE ID=1)
					SELECT @FILTERVALUE=VALUE FROM @TBLPREF WHERE ID=2
			
			
					CREATE TABLE #TBLPRO (ID INT IDENTITY(1,1),DCOLUMN NVARCHAR(300),SCOLUMN NVARCHAR(300))
					INSERT INTO #TBLPRO
					select l.SysColumnName, b.SysColumnName 
					from COM_DocumentLinkDetails dl WITH(nolock)
					left join ADM_CostCenterDef b WITH(nolock) on dl.CostCenterColIDBase=b.CostCenterColID
					left join Com_LanguageResources C WITH(nolock) on C.ResourceID=b.ResourceID   AND C.LanguageID=1
					left join ADM_CostCenterDef l WITH(nolock) on dl.CostCenterColIDLinked=l.CostCenterColID
					where DocumentLinkDeFID in (select DocumentLinkDeFID from COM_DocumentLinkDef WITH(nolock) where CostCenterIDBase=86   )
					and l.costcenterid=154
			
			DECLARE @k int,@tcount int,@sData nvarchar(max),@dData nvarchar(max)
			select @k=1,@tcount=COUNT(*) from #TBLPRO
			set @sData=''
			set @dData=''
			while @k<=@tcount
			begin
			 SET @sData= @sData + (SELECT SCOLUMN FROM #TBLPRO WHERE ID=@k)
			 SET @dData= @dData + (SELECT DCOLUMN FROM #TBLPRO WHERE ID=@k)
			
			IF(@k<>@tcount)
			BEGIN
				SET @sData=@sData + ','
				SET @dData=@dData + ','
			END
				
			set @k=@k+1
			end
			
			
			IF((SELECT COUNT(*) FROM #TBLPRO)=0)
			BEGIN
				SET @sData='Alpha1, Alpha2, Alpha3, Alpha4, Alpha5, Alpha6, Alpha7, Alpha8, Alpha9, Alpha10, Alpha11, Alpha12, Alpha13, Alpha14, Alpha15, Alpha16, Alpha17, Alpha18, Alpha19, Alpha20, Alpha21, Alpha22, Alpha23, Alpha24, Alpha25, Alpha26, Alpha27, Alpha28, Alpha29, Alpha30, Alpha31, Alpha32, Alpha33, Alpha34, Alpha35, Alpha36, Alpha37, Alpha38, Alpha39, Alpha40, Alpha41, Alpha42, Alpha43, Alpha44, Alpha45, Alpha46,  
				Alpha47, Alpha48, Alpha49, Alpha50'
				SET @dData='Alpha1, Alpha2, Alpha3, Alpha4, Alpha5, Alpha6, Alpha7, Alpha8, Alpha9, Alpha10, Alpha11, Alpha12, Alpha13, Alpha14, Alpha15, Alpha16, Alpha17, Alpha18, Alpha19, Alpha20, Alpha21, Alpha22, Alpha23, Alpha24, Alpha25, Alpha26, Alpha27, Alpha28, Alpha29, Alpha30, Alpha31, Alpha32, Alpha33, Alpha34, Alpha35, Alpha36, Alpha37, Alpha38, Alpha39, Alpha40, Alpha41, Alpha42, Alpha43, Alpha44, Alpha45, Alpha46,  
				Alpha47, Alpha48, Alpha49, Alpha50'
			END
			DROP TABLE #TBLPRO
			IF(@FILTER<>'' AND @FILTER IS NOT NULL)
			BEGIN
				set @SOURCEDATA=''
				set @SOURCEDATA='INSERT into CRM_ProductMapping(CCNodeID,CostCenterID,CRMProduct, ProductID,UOMID,CurrencyID,Description,
				Quantity, '+@dData+', CCNID1, CCNID2, CCNID3, CCNID4, CCNID5, CCNID6, CCNID7, CCNID8, CCNID9, CCNID10, CCNID11, CCNID12, CCNID13, CCNID14, CCNID15, CCNID16, CCNID17, CCNID18, CCNID19, CCNID20, CCNID21, CCNID22, CCNID23, CCNID24, CCNID25, CCNID26, CCNID27, CCNID28, CCNID29, CCNID30, CCNID31, CCNID32, CCNID33, CCNID34, CCNID35, CCNID36, CCNID37, CCNID38, CCNID39, CCNID40, CCNID41, CCNID42, CCNID43, CCNID44, CCNID45, CCNID46,
				CCNID47, CCNID48, CCNID49, CCNID50,CompanyGUID,GUID,CreatedBy,CreatedDate)
				select '+CONVERT(nvarchar(300),@OpportunityID)+',89,CRMProduct,ProductID,UOMID,CurrencyID,Description,
				Quantity, '+@sData+', CCNID1, CCNID2, CCNID3, CCNID4, CCNID5, CCNID6, CCNID7, CCNID8, CCNID9, CCNID10, CCNID11, CCNID12, CCNID13, CCNID14, CCNID15, CCNID16, CCNID17, CCNID18, CCNID19, CCNID20, CCNID21, CCNID22, CCNID23, CCNID24, CCNID25, CCNID26, CCNID27, CCNID28, CCNID29, CCNID30, CCNID31, CCNID32, CCNID33, CCNID34, CCNID35, CCNID36, CCNID37, CCNID38, CCNID39, CCNID40, CCNID41, CCNID42, CCNID43, CCNID44, CCNID45, CCNID46,
				CCNID47, CCNID48, CCNID49, CCNID50,CompanyGUID,GUID,CreatedBy,CreatedDate
				FROM CRM_ProductMapping WITH(nolock) WHERE 	CostCenterID=86 AND CCNodeID='+CONVERT(nvarchar(300),@LEADID)+' and '+convert(nvarchar(300),@FILTER)+'='''+convert(nvarchar(300),@FILTERVALUE)+''''
				exec (@SOURCEDATA)
			END
			ELSE
			BEGIN
				set @SOURCEDATA=''
				set @SOURCEDATA='
				INSERT into CRM_ProductMapping(CCNodeID,CostCenterID,CRMProduct, ProductID,UOMID,CurrencyID,Description,
				Quantity, '+@dData+', CCNID1, CCNID2, CCNID3, CCNID4, CCNID5, CCNID6, CCNID7, CCNID8, CCNID9, CCNID10, CCNID11, CCNID12, CCNID13, CCNID14, CCNID15, CCNID16, CCNID17, CCNID18, CCNID19, CCNID20, CCNID21, CCNID22, CCNID23, CCNID24, CCNID25, CCNID26, CCNID27, CCNID28, CCNID29, CCNID30, CCNID31, CCNID32, CCNID33, CCNID34, CCNID35, CCNID36, CCNID37, CCNID38, CCNID39, CCNID40, CCNID41, CCNID42, CCNID43, CCNID44, CCNID45, CCNID46,
				CCNID47, CCNID48, CCNID49, CCNID50,CompanyGUID,GUID,CreatedBy,CreatedDate)
				select '+CONVERT(nvarchar(300),@OpportunityID)+',89,CRMProduct,ProductID,UOMID,CurrencyID,Description,
				Quantity, '+@sData+', CCNID1, CCNID2, CCNID3, CCNID4, CCNID5, CCNID6, CCNID7, CCNID8, CCNID9, CCNID10, CCNID11, CCNID12, CCNID13, CCNID14, CCNID15, CCNID16, CCNID17, CCNID18, CCNID19, CCNID20, CCNID21, CCNID22, CCNID23, CCNID24, CCNID25, CCNID26, CCNID27, CCNID28, CCNID29, CCNID30, CCNID31, CCNID32, CCNID33, CCNID34, CCNID35, CCNID36, CCNID37, CCNID38, CCNID39, CCNID40, CCNID41, CCNID42, CCNID43, CCNID44, CCNID45, CCNID46,
				CCNID47, CCNID48, CCNID49, CCNID50,CompanyGUID,GUID,CreatedBy,CreatedDate
				FROM CRM_ProductMapping WITH(nolock) WHERE 	CostCenterID=86 AND CCNodeID='+CONVERT(nvarchar(300),@LEADID)+''
				exec (@SOURCEDATA)
		    END
		    
			IF @LeadAddressDetails=0
			BEGIN
				insert into CRM_CONTACTS
			  (FeatureID,FeaturePK,FirstName,MiddleName,LastName,SalutationID,JobTitle,Company,StatusID,Phone1,
			   Phone2,Email1,Fax,Department  ,CompanyGUID,GUID,CreatedBy,CreatedDate)
			   SELECT 89,@OpportunityID, FirstName,MiddleName,LastName,SalutationID, JobTitle,Company,StatusID,
			   Phone1,Phone2,Email1,Fax,Department  ,CompanyGUID,GUID,CreatedBy,CreatedDate FROM CRM_CONTACTS WITH(nolock) WHERE FeatureID=86 AND FeaturePK=@LEADID 
			END
			ELSE IF @LeadAddressDetails=1
			BEGIN
				insert into CRM_CONTACTS
			  (FeatureID,FeaturePK,FirstName,MiddleName,LastName,SalutationID,JobTitle,Company,StatusID,Phone1,
			   Phone2,Email1,Fax,Department  ,CompanyGUID,GUID,CreatedBy,CreatedDate, Address1,
           Address2,Address3,City,State,Zip,Country)
			   SELECT 89,@OpportunityID, FirstName,MiddleName,LastName,SalutationID, JobTitle,Company,StatusID,
			   Phone1,Phone2,Email1,Fax,Department  ,CompanyGUID,GUID,CreatedBy,CreatedDate, Address1,
           Address2,Address3,City,State,Zip,Country FROM CRM_CONTACTS WITH(nolock) WHERE FeatureID=86 AND FeaturePK=@LEADID 
           truncate table #TBLCONTACTS
           INSERT INTO #TBLCONTACTS
		   SELECT CONTACTID FROM  COM_CONTACTS WITH(nolock) WHERE FEATUREID=86 AND FEATUREPK=@LEADID --AND ADDRESSTYPEID=2
	 
			DECLARE @M INT,@CCOUNT INT,@CONTACTIDENTITY INT
			SELECT @M=1, @CCOUNT=COUNT(*) FROM #TBLCONTACTS 
			SET @CONTACTSXML=''
			
			WHILE @M<=@CCOUNT
			BEGIN
			
			
				INSERT INTO COM_CONTACTS([AddressTypeID],[FeatureID]        ,[FeaturePK]        ,[ContactName]        ,[Address1]        ,[Address2]        ,[Address3]        ,[City]        ,[State]        ,[Zip]        ,[Country]        ,[Phone1]        ,[Phone2]        ,[Fax]        ,[Email1]        ,[Email2]        ,[URL]        ,[CompanyGUID]        ,[GUID]        ,[Description]        ,[CreatedBy]        ,[CreatedDate]        ,[ModifiedBy]        ,[ModifiedDate]        ,[CostCenterID]        ,[ContactTypeID]        ,[FirstName]        ,[MiddleName]        ,[LastName]        ,[SalutationID]        ,[JobTitle]        ,[Company]        ,[StatusID]        ,[Department]        ,[RoleLookUpID]        ,[Gender]        ,[BirthDay]        ,[Anniversary]        ,[PreferredID]        ,[PreferredName]        ,[IsEmailOn]        ,[IsBulkEmailOn]        ,[IsMailOn]        ,[IsPhoneOn]        ,[IsFaxOn]        ,[IsVisible]        ,[Depth]        ,[ParentID]        ,[lft]        ,[rgt]        ,[IsGroup]        ,[ConvertFromLeadID])
				SELECT ADDRESSTYPEID,89,@OpportunityID,[ContactName] ,[Address1]        ,[Address2]        ,[Address3]        ,[City]        ,[State]        ,[Zip]        ,[Country]        ,[Phone1]        ,[Phone2]        ,[Fax]        ,[Email1]        ,[Email2]        ,[URL]        ,[CompanyGUID]        ,[GUID]        ,[Description]        ,[CreatedBy]        ,[CreatedDate]        ,[ModifiedBy]        ,[ModifiedDate]        ,89        ,[ContactTypeID]        ,[FirstName]        ,[MiddleName]        ,[LastName]        ,[SalutationID]        ,[JobTitle]        ,[Company]        ,[StatusID]        ,[Department]        ,[RoleLookUpID]        ,[Gender]        ,[BirthDay]        ,[Anniversary]        ,[PreferredID]        ,[PreferredName]        ,[IsEmailOn]        ,[IsBulkEmailOn]        ,[IsMailOn]        ,[IsPhoneOn]        ,[IsFaxOn]        ,[IsVisible]        ,[Depth]        ,[ParentID]        ,[lft]        ,[rgt]        ,[IsGroup]        ,[ConvertFromLeadID] FROM
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
           
           
           
			END
			
			 update CRM_Leads set StatusID=417 where LeadID=@LEADID
	         update crm_opportunities set Mode=4,Leadid=@LEADID,ConvertFromLeadid=@LEADID where OpportunityID=@OpportunityID
	         
          
			SELECT @LinkCostCenterID=isnull([Value],0) FROM COM_CostCenterPreferences WITH(NOLOCK) 
			WHERE FeatureID=89 AND [Name]='OppLinkDimension'
 
			IF @LinkCostCenterID>0
			BEGIN
				EXEC @return_value = [dbo].[spCOM_SetCostCenter]
					@NodeID = 0,@SelectedNodeID = 0,@IsGroup = 0,
					@Code = @Code,
					@Name = @CompanyName,
					@AliasName=@CompanyName,
					@PurchaseAccount=0,@SalesAccount=0,@StatusID=417,
					@CustomFieldsQuery=NULL,@AddressXML=NULL,@AttachmentsXML=NULL,
					@CustomCostCenterFieldsQuery=NULL,@ContactsXML=NULL,@NotesXML=NULL,
					@CostCenterID =@LinkCostCenterID,@CompanyGUID=@COMPANYGUID,@GUID='GUID',@UserName=@USERNAME,@RoleID=1,@UserID=@USERID
					--@return_value
					UPDATE [CRM_Opportunities]
					SET CCOpportunityID=@return_value
					WHERE OpportunityID=@OpportunityID
					
					  
					
					  
					  IF(EXISTS(SELECT VALUE FROM COM_COSTCENTERPREFERENCES WITH(nolock) WHERE COSTCENTERID=89 AND NAME='OPPLINKDIMENSION'))
					  BEGIN
							DECLARE @DIMID BIGINT,@UpdateSql NVARCHAR(MAX)
							SET @DIMID=0
							SELECT @DIMID=VALUE-50000 FROM COM_COSTCENTERPREFERENCES WITH(nolock) WHERE COSTCENTERID=89 AND NAME='OPPLINKDIMENSION'
							IF(@DIMID>0)
							BEGIN
									SET @UpdateSql=' UPDATE COM_CCCCDATA SET CCNID'+CONVERT(NVARCHAR(30),@DIMID)+'=
									(SELECT CCOpportunityID FROM CRM_Opportunities WITH(nolock) WHERE OpportunityID='+convert(nvarchar,@OpportunityID) + ') 
													WHERE NodeID = '+convert(nvarchar,@OpportunityID) + ' AND CostCenterID = 89'
									  exec(@UpdateSql)  
							END
					  END		
					  
					
			END
			
			END
		END
   END

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
     
	if(@SelectedNodeID is null)
		insert into #temp1
		EXEC [spCOM_GetCodeData] 83,1,''  
		else
		insert into #temp1
		EXEC [spCOM_GetCodeData] 83,@SelectedNodeID,''  
		--select * from #temp1
		select @Code=code,@CodePrefix= prefix, @CodeNumber=number from #temp1
		 
    END
      IF @CODE='' OR @CODE IS NULL 
	  begin
         SET @Code=@LeadCode
		 end
		 
  if exists(select value from [com_costcenterpreferences] WITH(nolock) where Name = 'ConvertLead') 
    Begin
     select @AccountID  = value from [com_costcenterpreferences] WITH(nolock) where Name = 'ConvertLead'
     
	IF NOT EXISTS (SELECT ConvertFromLeadID FROM [CRM_Customer] WITH(nolock) WHERE ConvertFromLeadID=@LEADID)  
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
       @Dt,@LEADID)
     
    --To get inserted record primary key
    SET @CustomerID=SCOPE_IDENTITY()
	 --Handling of Extended Table
    INSERT INTO [CRM_CustomerExtended]([CustomerID],[CreatedBy],[CreatedDate])
    VALUES(@CustomerID, @UserName, @Dt)
    
     IF @CustomerContacts=1
	 BEGIN 
		truncate table #TBLCONTACTS
		INSERT INTO #TBLCONTACTS
		SELECT CONTACTID FROM  COM_CONTACTS WHERE FEATUREID=86 AND FEATUREPK=@LEADID-- AND ADDRESSTYPEID=2
	 
			SELECT @M=1, @CCOUNT=COUNT(*) FROM #TBLCONTACTS 			
			WHILE @M<=@CCOUNT
			BEGIN
			
				INSERT INTO COM_CONTACTS([AddressTypeID],[FeatureID]        ,[FeaturePK]        ,[ContactName]        ,[Address1]        ,[Address2]        ,[Address3]        ,[City]        ,[State]        ,[Zip]        ,[Country]        ,[Phone1]        ,[Phone2]        ,[Fax]        ,[Email1]        ,[Email2]        ,[URL]        ,[CompanyGUID]        ,[GUID]        ,[Description]        ,[CreatedBy]        ,[CreatedDate]        ,[ModifiedBy]        ,[ModifiedDate]        ,[CostCenterID]        ,[ContactTypeID]        ,[FirstName]        ,[MiddleName]        ,[LastName]        ,[SalutationID]        ,[JobTitle]        ,[Company]        ,[StatusID]        ,[Department]        ,[RoleLookUpID]        ,[Gender]        ,[BirthDay]        ,[Anniversary]        ,[PreferredID]        ,[PreferredName]        ,[IsEmailOn]        ,[IsBulkEmailOn]        ,[IsMailOn]        ,[IsPhoneOn]        ,[IsFaxOn]        ,[IsVisible]        ,[Depth]        ,[ParentID]        ,[lft]        ,[rgt]        ,[IsGroup]        ,[ConvertFromLeadID])
				SELECT ADDRESSTYPEID,83,@CustomerID,[ContactName] ,[Address1]        ,[Address2]        ,[Address3]        ,[City]        ,[State]        ,[Zip]        ,[Country]        ,[Phone1]        ,[Phone2]        ,[Fax]        ,[Email1]        ,[Email2]        ,[URL]        ,[CompanyGUID]        ,[GUID]        ,[Description]        ,[CreatedBy]        ,[CreatedDate]        ,[ModifiedBy]        ,[ModifiedDate]        ,89        ,[ContactTypeID]        ,[FirstName]        ,[MiddleName]        ,[LastName]        ,[SalutationID]        ,[JobTitle]        ,[Company]        ,[StatusID]        ,[Department]        ,[RoleLookUpID]        ,[Gender]        ,[BirthDay]        ,[Anniversary]        ,[PreferredID]        ,[PreferredName]        ,[IsEmailOn]        ,[IsBulkEmailOn]        ,[IsMailOn]        ,[IsPhoneOn]        ,[IsFaxOn]        ,[IsVisible]        ,[Depth]        ,[ParentID]        ,[lft]        ,[rgt]        ,[IsGroup]        ,[ConvertFromLeadID] FROM
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
           
		 
	 END 
	END   
	 
 end
----------- INSERT INTO CONTACTS TABLE

   	
	         
  end
  
  IF (@Contact=1)
	BEGIN
	   --To Set Left,Right And Depth of Record  
		SELECT @SelectedIsGroup=IsGroup,@Selectedlft =lft,@Selectedrgt=rgt,@ParentID=ParentID,@Depth=Depth  
		from COM_CONTACTS with(NOLOCK) where ContactID=@SelectedNodeID  
	   
		--IF No Record Selected or Record Doesn't Exist  
		if(@SelectedIsGroup is null)   
		 select @SelectedNodeID=@DetailContactID,@SelectedIsGroup=IsGroup,@Selectedlft =lft,@Selectedrgt=rgt,@ParentID=ParentID,@Depth=Depth  
		 from COM_CONTACTS with(NOLOCK) where ParentID =0  
	         
		if(@SelectedIsGroup = 1)--Adding Node Under the Group  
		 BEGIN  
		  UPDATE COM_CONTACTS SET rgt = rgt + 2 WHERE rgt > @Selectedlft;  
		  UPDATE COM_CONTACTS SET lft = lft + 2 WHERE lft > @Selectedlft;  
		  set @lft =  @Selectedlft + 1  
		  set @rgt = @Selectedlft + 2  
		  set @ParentID = @SelectedNodeID  
		  set @Depth = @Depth + 1  
		 END  
		else if(@SelectedIsGroup = 0)--Adding Node at Same level  
		 BEGIN  
		  UPDATE COM_CONTACTS SET rgt = rgt + 2 WHERE rgt > @Selectedrgt;  
		  UPDATE COM_CONTACTS SET lft = lft + 2 WHERE lft > @Selectedrgt;  
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

    IF  NOT EXISTS (SELECT ConvertFromLeadID FROM COM_CONTACTS WITH(nolock) WHERE ConvertFromLeadID=@LEADID)  
	BEGIN  


	   insert into COM_CONTACTS
				 (ContactTypeID,
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
				  Department,
				  RoleLookUpID,
				  Address1,
				  Address2,
				  Address3,
				  City,
				  State,
				  Zip,
				  Country,
				  Gender,
				  Birthday,
				  Anniversary,
				  PreferredID,
				  PreferredName,
				  IsEmailOn,
				  IsBulkEmailOn,
				  IsMailOn,
				  IsPhoneOn,
				  IsFaxOn,
				  IsVisible,
				  Description,
				  Depth,
				  ParentID,
				  lft,
				  rgt,
				  IsGroup,
				  CompanyGUID,
				  GUID,
				  CreatedBy,
				  CreatedDate, ConvertFromLeadID,AddressTypeid,Featureid,featurepk)

		   select 53,
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
				  Department,
				  RoleLookUpID,
				  Address1,
				  Address2,
				  Address3,
				  City,
				  State,
				  Zip,
				  Country,
				  Gender,
				  Birthday,
				  Anniversary,
				  PreferredID,
				  PreferredName,
				  IsEmailOn,
				  IsBulkEmailOn,
				  IsMailOn,
				  IsPhoneOn,
				  IsFaxOn,
				  IsVisible,
				 @Description,
				 @Depth,
				 @ParentID,
				 @lft,
				 @rgt,
				 @IsGroup,
				 @CompanyGUID,
				 newid(),
				 @UserName,
				 convert(float,@Dt),@LEADID,2,65,0 from CRM_CONTACTS WITH(nolock) 
				 where featureid=86 and featurepk=@LeadID and featurepk in (select Leadid from CRM_Leads WITH(nolock) where mode IN (0,1))
			set @DetailContactID=scope_identity()
			
	END
 END
  -------------INSERT INTO ACCOUNTS TABLE
	 IF(@ACCOUNT=1)
	 BEGIN 
			IF  NOT EXISTS (SELECT ConvertFromLeadID FROM ACC_ACCOUNTS WITH(nolock) WHERE ConvertFromLeadID=@LEADID)  
			BEGIN  		 
			 truncate table   #TBLTEMP 
			 alter table #TBLTEMP add bSysTableName nvarchar(100)
			 alter table #TBLTEMP add lSysTableName nvarchar(100) 
			INSERT INTO #TBLTEMP (BASECOLUMN, LINKCOLUMN, bSysTableName, lSysTableName)
				 select l.SysColumnName, b.SysColumnName, l.SysTableName , b.SysTableName  
			 from COM_DocumentLinkDetails dl WITH(nolock)
			 left join ADM_CostCenterDef b WITH(nolock) on dl.CostCenterColIDBase=b.CostCenterColID
			 left join Com_LanguageResources C WITH(nolock) on C.ResourceID=b.ResourceID   AND C.LanguageID=1
			 left join ADM_CostCenterDef l WITH(nolock) on dl.CostCenterColIDLinked=l.CostCenterColID
			 JOIN COM_DocumentLinkDef D WITH(nolock) ON DL.DocumentLinkDeFID=D.DocumentLinkDeFID
			where D.CostCenterIDBase=86  AND D.COSTCENTERIDLINKED=2
			
			 
			
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
			SET @DESTDATA='(SELECT 7,33,'+CONVERT(NVARCHAR(300),@LEADID) +','
			 
				WHILE @I<=@ACOUNT
				BEGIN 
				IF( not exists (SELECT BASECOLUMN FROM #TBLTEMP WHERE ID=@I    and (BASECOLUMN likE '%acAlpha%' 
				OR bSysTableName LIKE 'COM_Contacts' or  LOWER(bSYSTABLENAME)='com_address')))
				begin
					SET @SOURCEDATA= @SOURCEDATA + (SELECT BASECOLUMN FROM #TBLTEMP WHERE ID=@I)
					
					IF((SELECT LINKCOLUMN FROM #TBLTEMP WHERE ID=@I)='Company')
							SET @DESTDATA =@DESTDATA + 'CRM_LEADS.'+(SELECT LINKCOLUMN FROM #TBLTEMP WHERE ID=@I)   
					 else
					   SET @DESTDATA= @DESTDATA + (SELECT LINKCOLUMN FROM #TBLTEMP WHERE ID=@I)
					   
					--IF(@I<>@ACOUNT)
					--BEGIN
						 SET @SOURCEDATA =@SOURCEDATA + ','
						 SET @DESTDATA =@DESTDATA + ',' 
					--END
				end	  
				SET @I=@I+1
				END
				if(len(@SOURCEDATA)>0)
					SET @SOURCEDATA=SUBSTRING(@SOURCEDATA,1,LEN(@SOURCEDATA)-1)	
				IF(LEN(@DESTDATA)>0)
					SET @DESTDATA=SUBSTRING(@DESTDATA,1,LEN(@DESTDATA)-1)	
				  
				
				set @SOURCEDATA=@SOURCEDATA+ ',[IsBillwise],[CreditDays],[CreditLimit],  [DebitDays],  [DebitLimit], [Depth], [ParentID],  [lft],  [rgt],  [IsGroup],[CompanyGUID],  [GUID],  [CreatedBy],  [CreatedDate] )'  		
				set @DESTDATA=@DESTDATA + + ',1,0,0,0,0,' + CONVERT(NVARCHAR(300),@Depth) + ',' +CONVERT(NVARCHAR(300),@ParentID) + ',' +CONVERT(NVARCHAR(300),@lft)+ ',' + 
				CONVERT(NVARCHAR(300),@rgt) + ',' + CONVERT(NVARCHAR(300),@IsGroup) + ',''' + CONVERT(NVARCHAR(300),@CompanyGUID) + ''',' + 'newid()'
				+ ',CRM_LEADS.CreatedBy' +  ', CRM_LEADS.createddate' 
				
				SET  @SOURCEDATA=@SOURCEDATA +  @DESTDATA + ' FROM CRM_LEADS LEFT JOIN CRM_LeadsExtended ON CRM_LeadsExtended.LEADID=CRM_LEADS.LEADID 
				LEFT JOIN COM_Contacts ON COM_Contacts.FEATUREPK='+CONVERT(NVARCHAR(300),@LEADID)+' AND ADDRESSTYPEID=1 AND COM_Contacts.FEATUREID=86 WHERE CRM_LEADS.LEADID='+CONVERT(NVARCHAR(300),@LEADID) + ')'
				 PRINT @SOURCEDATA
				 
				EXEC (@SOURCEDATA) 
				 
			
				SELECT @AccountID=ACCOUNTID FROM ACC_ACCOUNTS WITH(nolock) WHERE ConvertFromLeadID=@LEADID
				
				 
				IF(@AccountID IS NOT NULL)
				BEGIN
					--Check duplicate
					exec spACC_CheckDuplicate @AccountID
					
					--Handling of Extended Table  
					INSERT INTO [ACC_AccountsExtended]([AccountID],[CreatedBy],[CreatedDate])  
					VALUES(@AccountID, @UserName, @Dt)  
				
					--INSERT INTO COM_CCCCDATA ([CostCenterID] ,[NodeID] ,[Guid],[CreatedBy],[CreatedDate])
					--VALUES(2,@AccountID,newid(),  @USERNAME, @Dt) 
					
					
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
						,newid(), @UserName, @Dt from COM_CCCCDATA where [CostCenterID]=86 and [NodeID]=@LEADID
						
					declare @PrimaryAddressID bigint
					 DECLARE @tempsql nvarchar(max)
				--	select * from #TBLTEMP WHERE ID=@I
					set @SOURCEDATA=''
					set @I=1
					WHILE @I<=@ACOUNT
					begin 
						IF( exists (SELECT * FROM #TBLTEMP WHERE ID=@I and LOWER(LSYSTABLENAME)<>'com_address' and (BASECOLUMN likE '%Alpha%' AND LINKCOLUMN likE '%Alpha%') ))
						begin 
							SET @SOURCEDATA= 'UPDATE [ACC_AccountsExtended] SET '+(SELECT BASECOLUMN FROM #TBLTEMP WHERE ID=@I)+'=(
							SELECT '+(SELECT LINKCOLUMN FROM #TBLTEMP WHERE ID=@I)+' FROM CRM_LeadsExtended WITH(nolock) WHERE  
							LeadID='+CONVERT(NVARCHAR,@LEADID) +') WHERE  [ACCOUNTID]='+CONVERT(NVARCHAR,@AccountID) + ''
							print @SOURCEDATA
							EXEC(@SOURCEDATA) 
							SET @SOURCEDATA='' 
						end	  
						set @I=@I+1
					 end
					 
					 SET @tempsql=''
					SELECT @tempsql=@tempsql+','+a.name
					FROM sys.columns a
					JOIN sys.columns b on a.name=b.name and b.object_id= object_id('ACC_Accounts')
					WHERE a.object_id= object_id('ACC_AccountsHistory')
					
					  --Insert into Account history   
					  set @tempsql= 'insert into [ACC_AccountsHistory] (HistoryStatus'+@tempsql+') select ''Update'''+@tempsql+' from ACC_Accounts with(nolock) WHERE AccountID='+CONVERT(NVARCHAR,@AccountID)     
					EXEC (@tempsql)  
					PRINT(@tempsql)
						  
						--Insert into Account history  Extended  
						insert into ACC_AccountsExtendedHistory  
						select *,'Update' from [ACC_AccountsExtended] WITH(nolock) WHERE AccountID=@AccountID    
			    
				     
				    IF @AccountContacts=1
					BEGIN 
							truncate table #TBLCONTACTS
							INSERT INTO #TBLCONTACTS
							SELECT CONTACTID FROM  COM_CONTACTS WHERE FEATUREID=86 AND FEATUREPK=@LEADID --AND ADDRESSTYPEID=2
							
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
					 END 
					 
				 	set @SOURCEDATA=''
					set @I=1
					declare @AddressID bigint
						INSERT INTO COM_Address(AddressTypeID,FeatureID,FeaturePK,[CompanyGUID],[GUID],[CreatedBy],[CreatedDate])
						VALUES (1,2,@AccountID,NEWID(),NEWID(),@UserName,@Dt)
						SET @AddressID=SCOPE_IDENTITY()
					
					WHILE @I<=@ACOUNT
					begin
						--select * from #TBLTEMP WHERE ID=@I 
						IF( exists (SELECT * FROM #TBLTEMP WHERE ID=@I and  (LOWER(bSYSTABLENAME)='com_address'
						 AND LOWER(lSYSTABLENAME)='crm_contacts' )))
						begin  
							SET @SOURCEDATA= 'UPDATE [COM_Address] SET '+(SELECT BASECOLUMN FROM #TBLTEMP WHERE ID=@I)+'=(
							SELECT '+(SELECT LINKCOLUMN FROM #TBLTEMP WHERE ID=@I)+' FROM crm_contacts WITH(nolock) WHERE  
							featurepk='+CONVERT(NVARCHAR,@LEADID) +' and featureid=86 and addresstypeid=1) 
							WHERE  [AddressID]='+CONVERT(NVARCHAR,@AddressID) + '' 
							print @SOURCEDATA
							EXEC(@SOURCEDATA) 
							SET @SOURCEDATA='' 
						end  
						else IF( exists (SELECT * FROM #TBLTEMP WHERE ID=@I and  (LOWER(bSYSTABLENAME)='com_address'
						 AND LINKCOLUMN LIKE '%Alpha%' ))) 
						begin  
							SET @SOURCEDATA= 'UPDATE [COM_Address] SET '+(SELECT BASECOLUMN FROM #TBLTEMP WHERE ID=@I)+'=(
							SELECT '+(SELECT LINKCOLUMN FROM #TBLTEMP WHERE ID=@I)+' FROM CRM_LeadsExtended WITH(nolock) WHERE  
							LeadID='+CONVERT(NVARCHAR,@LEADID) +') 
							WHERE  [AddressID]='+CONVERT(NVARCHAR,@AddressID) + '' 
							print @SOURCEDATA
							EXEC(@SOURCEDATA) 
							SET @SOURCEDATA='' 
						end  
						else
						IF( exists (SELECT * FROM #TBLTEMP WHERE ID=@I and  (LSYSTABLENAME='CRM_Contacts' AND BASECOLUMN likE '%Alpha%') ))
						begin 
						SET @SOURCEDATA= 'UPDATE [ACC_AccountsExtended] SET '+(SELECT BASECOLUMN FROM #TBLTEMP WHERE ID=@I)+'=(
							SELECT '+(SELECT LINKCOLUMN FROM #TBLTEMP WHERE ID=@I)+' FROM crm_contacts WITH(nolock) WHERE  
							featurepk='+CONVERT(NVARCHAR,@LEADID) +' and featureid=86)   
							WHERE  [ACCOUNTID]='+CONVERT(NVARCHAR,@AccountID) + ''
							print @SOURCEDATA
							EXEC(@SOURCEDATA) 
							SET @SOURCEDATA='' 
						end  
						
						
						set @I=@I+1
					 end 
				END
				 
			END
		  END
	 END
	
	--set notification
	EXEC spCOM_SetNotifEvent -1001,86,@LEADID,@CompanyGUID,@UserName,@UserID,-1
	
 
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

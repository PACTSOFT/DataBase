USE PACT2C222
GO
SET ANSI_NULLS, QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spSVC_SetCustomer]
	@CustomerID [bigint],
	@CustomerCode [nvarchar](200),
	@CustomerName [nvarchar](500),
	@FirstName [nvarchar](500),
	@LastName [nvarchar](500),
	@AliasName [nvarchar](50),
	@Salutation [bigint],
	@CustomerTypeID [int],
	@StatusID [int],
	@SelectedNodeID [bigint],
	@IsGroup [bit],
	@CreditDays [int],
	@CreditLimit [float],
	@Currency [int],
	@Location [bigint],
	@AccountName [bigint],
	@InsuranceId [bigint],
	@PolicyNo [nvarchar](50),
	@ExpiryDate [datetime],
	@LoyaltyCard [bigint],
	@LoyaltyCardExpDate [datetime],
	@ExtendedWarranty [bigint],
	@ExtWarrantyExpDate [datetime],
	@CompanyGUID [varchar](50),
	@GUID [varchar](50),
	@Description [nvarchar](500),
	@UserName [nvarchar](50),
	@CustomFieldsQuery [nvarchar](max),
	@CustomCostCenterFieldsQuery [nvarchar](max),
	@ContactsXML [nvarchar](max),
	@AttachmentsXML [nvarchar](max),
	@NotesXML [nvarchar](max),
	@AddressXML [nvarchar](max),
	@CustomerVehicleXML [nvarchar](max),
	@PrimaryContactQuery [nvarchar](max),
	@CustomerFamilyDetXML [nvarchar](max),
	@UserID [int] = 0,
	@LangID [int] = 1,
	@RoleID [int] = 1
WITH ENCRYPTION, EXECUTE AS CALLER
AS
BEGIN TRANSACTION  
BEGIN TRY  
SET NOCOUNT ON;
		--Declaration Section
		DECLARE @Dt float,@XML xml,@TempGuid nvarchar(50),@HasAccess bit,@IsDuplicateNameAllowed bit,@IsCustomerCodeAutoGen bit,@CV_ID bigint
		DECLARE @UpdateSql nvarchar(max),@ParentCode nvarchar(200)
		DECLARE @lft bigint,@rgt bigint,@Selectedlft bigint,@Selectedrgt bigint,@Depth int,@ParentID bigint
		DECLARE @SelectedIsGroup bit , @VehicleID int, @I INT, @COUNT INT ,@VCOUNT INT, @Color int, @Fuel INT, @FuelDelivery INT, @EngineType int, @Cylinders int
		DECLARE @MakeID int, @ModelID int, @Year int, @VariantID int, @SegmentID int, @PlateNo nvarchar(100)
		--User acces check FOR Customer 
		IF @CustomerID=0
		BEGIN
			SET @HasAccess=dbo.fnCOM_HasAccess(@RoleID,51,1)
		END
		ELSE
		BEGIN
			SET @HasAccess=dbo.fnCOM_HasAccess(@RoleID,51,3)
		END

		IF @HasAccess=0
		BEGIN
			RAISERROR('-105',16,1)
		END

		--User acces check FOR Notes
		IF (@NotesXML IS NOT NULL AND @NotesXML <> '')
		BEGIN
			SET @HasAccess=dbo.fnCOM_HasAccess(@RoleID,51,8)

			IF @HasAccess=0
			BEGIN
				RAISERROR('-105',16,1)
			END
		END

		--User acces check FOR Attachments
		IF (@AttachmentsXML IS NOT NULL AND @AttachmentsXML <> '')
		BEGIN
			SET @HasAccess=dbo.fnCOM_HasAccess(@RoleID,51,12)

			IF @HasAccess=0
			BEGIN
				RAISERROR('-105',16,1)
			END
		END  
		
		--User acces check FOR Contacts
		IF (@ContactsXML IS NOT NULL AND @ContactsXML <> '')
		BEGIN
			SET @HasAccess=dbo.fnCOM_HasAccess(@RoleID,51,16)

			IF @HasAccess=0
			BEGIN
				RAISERROR('-105',16,1)
			END
		END

		IF EXISTS(SELECT StatusID FROM dbo.COM_Status
		WHERE CostCenterID=51 AND Status='Active' AND StatusID=@StatusID )
		BEGIN
			SET @HasAccess=dbo.fnCOM_HasAccess(@RoleID,51,23)

			IF @HasAccess=0
			BEGIN
				RAISERROR('-111',16,1)
			END
		END

		IF EXISTS(SELECT StatusID FROM dbo.COM_Status
		WHERE CostCenterID=51 AND Status='In Active' AND StatusID=@StatusID )
		BEGIN
			SET @HasAccess=dbo.fnCOM_HasAccess(@RoleID,51,24)

			IF @HasAccess=0
			BEGIN
				RAISERROR('-113',16,1)
			END
		END

		--GETTING PREFERENCE
		SELECT @IsDuplicateNameAllowed=Value FROM COM_CostCenterPreferences WITH(nolock) WHERE CostCenterID=51 and  Name='DuplicateNameAllowed'
		SELECT @IsCustomerCodeAutoGen=Value FROM COM_CostCenterPreferences  WITH(nolock) WHERE CostCenterID=51 and  Name='CustomerCodeAutoGen'

		--DUPLICATE CHECK
		IF @IsDuplicateNameAllowed IS NOT NULL AND @IsDuplicateNameAllowed=0
		BEGIN
			IF @CustomerID=0
			BEGIN
				IF EXISTS (SELECT CustomerID FROM SVC_Customers WITH(nolock) WHERE CustomerName=@CustomerName)
				BEGIN
					RAISERROR('-345',16,1)
				END
			END
			ELSE
			BEGIN
				IF EXISTS (SELECT CustomerID FROM SVC_Customers WITH(nolock) WHERE CustomerName=@CustomerName AND CustomerID <> @CustomerID)
				BEGIN
					RAISERROR('-345',16,1)
				END
			END
		END


		SET @Dt=convert(float,getdate())--Setting Current Date
		
		if @AccountName=0 or @AccountName=101
		begin
			set @AccountName=null
		end
		if @Location=0
		begin
			set @Location=null
		end

		if @InsuranceId=0
		begin
			set @InsuranceId=null
		end
		
		IF @CustomerID=0--------START INSERT RECORD-----------
		BEGIN--CREATE Customer--
				
				--To Set Left,Right And Depth of Record
				SELECT @SelectedIsGroup=IsGroup,@Selectedlft =lft,@Selectedrgt=rgt,@ParentID=ParentID,@Depth=Depth
				from [SVC_Customers] with(NOLOCK) where CustomerID=@SelectedNodeID
 
				--IF No Record Selected or Record Doesn't Exist
				if(@SelectedIsGroup is null) 
					select @SelectedNodeID=CustomerID,@SelectedIsGroup=IsGroup,@Selectedlft =lft,@Selectedrgt=rgt,@ParentID=ParentID,@Depth=Depth
					from [SVC_Customers] with(NOLOCK) where ParentID =0
							
				 
				if(@SelectedIsGroup = 1)--Adding Node Under the Group
					BEGIN
					 
						UPDATE SVC_Customers SET rgt = rgt + 2 WHERE rgt > @Selectedlft;
						UPDATE SVC_Customers SET lft = lft + 2 WHERE lft > @Selectedlft;
						set @lft =  @Selectedlft + 1
						set @rgt =	@Selectedlft + 2
						set @ParentID = @SelectedNodeID
						set @Depth = @Depth + 1
 
					END
				else if(@SelectedIsGroup = 0)--Adding Node at Same level
					BEGIN
						UPDATE SVC_Customers SET rgt = rgt + 2 WHERE rgt > @Selectedrgt;
						UPDATE SVC_Customers SET lft = lft + 2 WHERE lft > @Selectedrgt;
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
 
				--GENERATE CODE
				IF @IsCustomerCodeAutoGen IS NOT NULL AND @IsCustomerCodeAutoGen=1 AND @CustomerID=0
				BEGIN
					SELECT @ParentCode=[CustomerCode]
					FROM [SVC_Customers] WITH(NOLOCK) WHERE CustomerID=@ParentID  

					--CALL AUTOCODEGEN
					EXEC [spCOM_SetCode] 51,@ParentCode,@CustomerCode OUTPUT		
				END

				-- Insert statements for procedure here
				INSERT INTO [SVC_Customers]
							([CustomerCode],
							[CustomerName] ,
							[AliasName] ,
							Salutation,
							[CustomerTypeID],
							[StatusID],
							[Depth],
							[ParentID],
							[lft],
							[rgt],
							[IsGroup], 
							[CreditDays], 
							[CreditLimit],
							[Location],
							[AccountName],
							[Insurance],
							[PolicyNo],
							[ExpiryDate],
							[LoyaltyCard],
							[LoyaltyCardExpDate],
							[ExtendedWarranty],
							[ExtWarrantyExpDate],
							[CompanyGUID],
							[GUID],
							[Description],
							[CreatedBy],
							[CreatedDate],Currency, FirstName, LastName)
							VALUES
							(@CustomerCode,
							@CustomerName,
							@AliasName,
							@Salutation,
							@CustomerTypeID,
							@StatusID,
							@Depth,
							@ParentID,
							@lft,
							@rgt,
							@IsGroup,
							@CreditDays,
							@CreditLimit, 
							@Location,
						    @AccountName,
							@InsuranceId, @PolicyNo,  
							convert(float,@ExpiryDate),
							convert(float,@LoyaltyCard),	
							convert(float,@LoyaltyCardExpDate),
							@ExtendedWarranty,
							convert(float,@ExtWarrantyExpDate),
						 	@CompanyGUID,
							newid(),
							@Description,
							@UserName,
							@Dt,@Currency, @FirstName, @LastName)
					
				--To get inserted record primary key
				SET @CustomerID=SCOPE_IDENTITY()
 
		
				--Handling of Extended Table
				INSERT INTO [SVC_CustomersExtended]([CustomerID],[CreatedBy],[CreatedDate])
				VALUES(@CustomerID, @UserName, @Dt)

				--Handling of CostCenter Costcenters Extrafields Table
				INSERT INTO SVC_CustomerCostCenterMap ([CustomerID],[CreatedBy],[CreatedDate], [CompanyGUID],[GUID])
				VALUES(@CustomerID, @UserName, @Dt, @CompanyGUID,newid())

			   --Update CostCenter Extra Fields
				set @UpdateSql='update SVC_CustomerCostCenterMap
				SET '+@CustomCostCenterFieldsQuery+' [ModifiedBy] ='''+ @UserName+''',[ModifiedDate] =' + convert(nvarchar,@Dt) +' WHERE CustomerID='+convert(nvarchar,@CustomerID)
				
				exec(@UpdateSql)
				 
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
				,51
				,@CustomerID
				,@CompanyGUID
				,NEWID()
				,@UserName,@Dt
				)
				INSERT INTO COM_ContactsExtended(ContactID,[CreatedBy],[CreatedDate])
			 	VALUES(SCOPE_IDENTITY(), @UserName, convert(float,getdate()))
				 
 		END--------END INSERT RECORD-----------
		ELSE--------START UPDATE RECORD-----------
		BEGIN	
			print 'Update'	
			IF EXISTS(SELECT CustomerID FROM [SVC_Customers] WHERE CustomerID=@CustomerID AND ParentID=0)
			BEGIN
				RAISERROR('-123',16,1)
			END	  
			SELECT @TempGuid=[GUID] from [SVC_Customers]  WITH(NOLOCK) 
			WHERE CustomerID=@CustomerID

			IF(@TempGuid!=@Guid)--IF RECORD ALREADY UPDATED BY SOME OTHER USER i.e DIRTY READ  
			BEGIN  
				   RAISERROR('-101',16,1)	
			END  
			ELSE  
			BEGIN 

 
			--Delete mapping if any
			DELETE FROM  SVC_CustomerCostCenterMap WHERE CustomerID=@CustomerID    

			--Handling of CostCenter Costcenters Extrafields Table
			INSERT INTO SVC_CustomerCostCenterMap ([CustomerID],[CreatedBy],[CreatedDate], [CompanyGUID],[GUID])
			VALUES(@CustomerID, @UserName, @Dt, @CompanyGUID,newid())

				UPDATE [SVC_Customers]
				   SET [CustomerCode] = @CustomerCode
					  ,[CustomerName] = @CustomerName
					  ,[FirstName] = @FirstName
					  ,[LastName] = @LastName
					  ,[AliasName] = @AliasName
					  ,Salutation=@Salutation
					  ,[CustomerTypeID] = @CustomerTypeID
					  ,[StatusID] = @StatusID
					  ,[IsGroup] = @IsGroup
					  ,[CreditDays] = @CreditDays
					  ,[CreditLimit] = @CreditLimit
				      ,[Location] = @Location
				      ,[AccountName] = @AccountName
					  ,[Insurance]=@InsuranceId
					  ,[PolicyNo]=@PolicyNo
					  ,[LoyaltyCard]=@LoyaltyCard
					  ,[ExtendedWarranty]=@ExtendedWarranty
					  ,[GUID] =  newid()
					  ,[Description] = @Description   
					  ,[ModifiedBy] = @UserName
					  ,[ModifiedDate] = @Dt,Currency=@Currency
				 WHERE CustomerID=@CustomerID      
				
					IF @ExpiryDate='1/1/1900 12:00:00 AM'
					BEGIN
						UPDATE [SVC_Customers] SET  [ExpiryDate]=NULL
						 WHERE CustomerID=@CustomerID     
					END
					ELSE
					BEGIN
						UPDATE [SVC_Customers] SET  [ExpiryDate]=convert(float,@ExpiryDate)
						 WHERE CustomerID=@CustomerID     
				 	END
					IF @LoyaltyCardExpDate='1/1/1900 12:00:00 AM'
					BEGIN
						UPDATE [SVC_Customers] SET  [LoyaltyCardExpDate]=NULL
						 WHERE CustomerID=@CustomerID     
					END
					ELSE
					BEGIN
						UPDATE [SVC_Customers] SET  [LoyaltyCardExpDate]=convert(float,@LoyaltyCardExpDate)
						 WHERE CustomerID=@CustomerID     
				 	END
					IF @ExtWarrantyExpDate='1/1/1900 12:00:00 AM'
					BEGIN
						UPDATE [SVC_Customers] SET  [ExtWarrantyExpDate]=NULL
						 WHERE CustomerID=@CustomerID     
					END
					ELSE
					BEGIN
						UPDATE [SVC_Customers] SET  [ExtWarrantyExpDate]=convert(float,@ExtWarrantyExpDate)
						 WHERE CustomerID=@CustomerID     
				 	END
				 
			END
		END

	 
		--SETTING Customer CODE EQUALS CustomerID IF EMPTY
		IF(@CustomerCode IS NULL OR @CustomerCode='')
		BEGIN
		 
			UPDATE  [SVC_Customers]
			SET [CustomerCode] = @CustomerID
			WHERE CustomerID=@CustomerID   
		 
		END
	  -- , BEFORE MODIFIEDBY  REQUIRES A NULL CHECK OF @PrimaryContactQuery 
  IF(@PrimaryContactQuery IS NOT NULL AND @PrimaryContactQuery<>'')
  BEGIN  
   set @UpdateSql='update [COM_Contacts]  
  SET '+@PrimaryContactQuery+',[ModifiedBy] ='''+ @UserName  
    +''',[ModifiedDate] =' + convert(nvarchar,@Dt) +' WHERE [FeatureID]=51 AND [AddressTypeID] = 1 AND [FeaturePK]='+convert(nvarchar,@CustomerID)  
   
  exec(@UpdateSql)  
  END

		--Update Extra fields
		set @UpdateSql='update [SVC_CustomersExtended]
		SET '+@CustomFieldsQuery+' [ModifiedBy] ='''+ @UserName
		  +''',[ModifiedDate] =' + convert(nvarchar,@Dt) +' WHERE CustomerID='+convert(nvarchar,@CustomerID)
	
		exec(@UpdateSql)
	 
        --Update CostCenter Extra Fields
		set @UpdateSql='update SVC_CustomerCostCenterMap
		SET '+@CustomCostCenterFieldsQuery+' [ModifiedBy] ='''+ @UserName+''',[ModifiedDate] =' + convert(nvarchar,@Dt) +' WHERE CustomerID='+convert(nvarchar,@CustomerID)
	
		exec(@UpdateSql)
 
		--Inserts Multiple Contacts
		  IF (@ContactsXML IS NOT NULL AND @ContactsXML <> '')  
		  BEGIN  
				--CHANGES MADE IN PRIMARY CONTACT QUERY BY HAFEEZ ON DEC 20 2013,BECOZ CONTACT QUICK ADD SCREEN IS CUSTOMIZABLE
				 declare @rValue int				
				EXEC @rValue =  spCOM_SetFeatureWiseContacts 51,@CustomerID,2,@ContactsXML,@UserName,@Dt,@LangID   
				 IF @rValue=-1000  
				  BEGIN  
					RAISERROR('-500',16,1)  
				  END   
		  END  

		--Inserts Multiple Address
		EXEC spCOM_SetAddress 51,@CustomerID,@AddressXML,@UserName  

	 	-- Insert Customer Vehicle Details
		IF (@CustomerVehicleXML IS NOT NULL AND @CustomerVehicleXML <> '')
		BEGIN
		SET @XML=@CustomerVehicleXML 
			
			Update SVC_CustomersVehicle set StatusID=358
			from @XML.nodes('CustomerVehicleXML/Row') as DATA(X)
			WHERE PlateNumber = X.value('@PlateNo','NVARCHAR(300)') 
			and (X.value('@CustomerID','NVARCHAR(300)')<>@CustomerID )--and X.value('@CustomerID','NVARCHAR(300)')<>0)
			and X.value('@Action','NVARCHAR(10)')='NEW'	
		
		--If Action is NEW then insert new Address
		INSERT INTO SVC_CustomersVehicle(CustomerID,VehicleID,PlateNumber,Color,
		FuelDelivery,EngineType,Cylinders,  CompanyGUID, GUID, Createdby, CreatedDate, Insurance,
		InsuranceExpiryDate,LoyaltyCard, CardNumber, CardExpDate, PolicyNumber,
		InsuranceName, StatusID,Year , PlateFormat, ChasisNumber)
		SELECT  @CustomerID,X.value('@VehicleID','bigint'), 
		 X.value('@PlateNo','NVARCHAR(300)'),
		 X.value('@Color','bigint'),
		 X.value('@FuelDelivery','bigint'), 
		 X.value('@EngineType','bigint'), 
		 X.value('@Cylinders','bigint'),@CompanyGUID,newid(),@UserName,@Dt,
		  X.value('@InsuranceId','bigint'),
		 X.value('@InsuranceExpiryDate','NVARCHAR(50)'), 
		 X.value('@LoyaltyCard','int'), 
		 X.value('@CardNo','nvarchar(50)'),
		 X.value('@LoyaltyExpDate','nvarchar(50)'),
		 X.value('@PolicyNo','nvarchar(100)'),
		 X.value('@Insurance','nvarchar(500)'),357 ,
		  X.value('@Year','nvarchar(100)'),X.value('@PlateFormat','NVARCHAR(10)')
		  ,X.value('@ChasisNumber','NVARCHAR(10)')
		 from @XML.nodes('CustomerVehicleXML/Row') as DATA(X) 
		 WHERE X.value('@Action','NVARCHAR(10)')='NEW'	
				 
			
		--If Action is MODIFY then Update  Address
			UPDATE SVC_CustomersVehicle
			SET COLOR=X.value('@Color','bigint'), FuelDelivery=X.value('@FuelDelivery','bigint'), 
			Cylinders=X.value('@Cylinders','bigint'), EngineType=X.value('@EngineType','bigint')
			,VehicleID=X.value('@VehicleID','bigint'),PlateNumber=X.value('@PlateNo','NVARCHAR(300)') ,
			InsuranceName= X.value('@Insurance','nvarchar(500)'), 
			InsuranceExpiryDate= X.value('@InsuranceExpiryDate','NVARCHAR(100)'), 
			LoyaltyCard= X.value('@LoyaltyCard','int'), 
			CardNumber=	 X.value('@CardNo','nvarchar(50)'),
			CardExpDate=  X.value('@LoyaltyExpDate','nvarchar(50)'),
			PolicyNumber=  X.value('@PolicyNo','nvarchar(100)'),
			ChasisNumber=  X.value('@ChasisNumber','nvarchar(100)'),
			Year=X.value('@Year','nvarchar(100)'),
			Insurance=  X.value('@InsuranceId','bigint'),
			PlateFormat=  X.value('@PlateFormat','bigint')
			from @XML.nodes('CustomerVehicleXML/Row') as DATA(X)
			WHERE CV_ID = X.value('@CustomerVehicleID','BIGINT') and X.value('@Action','NVARCHAR(10)')='MODIFY'	
			
			
		--If Action is DELETE then delete  Address
			DELETE FROM SVC_CustomersVehicle
			WHERE CV_ID in(select X.value('@CustomerVehicleID','BIGINT')
			FROM @XML.nodes('/CustomerVehicleXML/Row') as Data(X)
			WHERE X.value('@Action','NVARCHAR(10)')='DELETE')
			
			--region nodeid update of registration number
			declare @ci int, @ccnt int
			create table #temp (id bigint identity(1,1), platenumber nvarchar(100), cvid bigint, regnumbernodeid bigint)
			insert into #temp
			select platenumber, cv_id, regnumbernodeid from SVC_CustomersVehicle where customerid=@CustomerID
			set @ci=1
			select @ccnt=count(*) from #temp
			declare @regno nvarchar(100), @regnodeid bigint, @cvid bigint
			while @ci<=@ccnt
			begin
				select @regno=platenumber, @regnodeid=regnumbernodeid, @cvid=cvid from #temp where id=@ci
				if(@cvid>0)
				begin
					declare  @regnum nvarchar(100), @CCMAPXML nvarchar(500)
					select @regnodeid= regnumbernodeid, @regnum=replace(replace(platenumber,' ',''),'-','') from svc_customersvehicle WITH(NOLOCK)  where cv_id=@cvid
					DECLARE	@return_value int,@LinkRegCCID BIGINT, @SID INT 
					SELECT @LinkRegCCID=[Value] FROM COM_CostCenterPreferences WITH(NOLOCK) WHERE FeatureID=51 AND [Name]='VehicleRegNumberLink' 
					SELECT @SID=STATUSID FROM COM_STATUS WITH(NOLOCK) WHERE COSTCENTERID=@LinkRegCCID  and Status='Active'
					declare  @Table nvarchar(100) , @NID int
					declare @NodeidXML nvarchar(max) 
					select @Table=Tablename from adm_features where featureid=@LinkRegCCID 
					declare @str nvarchar(max)  
					set @str='@NID int output'  
					set @NodeidXML='set @NID= (select top 1 NodeID from '+convert(nvarchar,@Table)+' where name='''+@regnum+''')' 
					exec sp_executesql @NodeidXML, @str, @NID OUTPUT 
					if(@NID is null)
						set @NID=0
					if(@Location>0)
						SET @CCMAPXML='<XML><Row  CostCenterId="50002" NodeID="'+CONVERT(NVARCHAR,@Location)+'"/></XML>'
					else
						SET @CCMAPXML=''
					if(@NID>0)
						update svc_customersvehicle set regnumbernodeid=@NID, RegCCID=@LinkRegCCID  where cv_id=@CVID 
					else if(@regnodeid is null and @NID=0)
					begin  
							
						EXEC	@return_value = [dbo].[spCOM_SetCostCenter]
						@NodeID = 0,@SelectedNodeID = 0,@IsGroup = 0,
						@Code = @regnum,
						@Name = @regnum,
						@AliasName=@regnum,
						@PurchaseAccount=0,@SalesAccount=0,@StatusID=@SID,
						@CustomFieldsQuery=NULL,@AddressXML=NULL,@AttachmentsXML=NULL,
						@CustomCostCenterFieldsQuery=NULL,@ContactsXML=NULL,@NotesXML=NULL, @CostCenterRoleXML=@CCMAPXML,
						@CostCenterID = @LinkRegCCID,@CompanyGUID='dddd',@GUID='GUID',
						@UserName='admin',@RoleID=1,@UserID=1  , @CheckLink = 0
						update svc_customersvehicle set regnumbernodeid=@return_value, RegCCID=@LinkRegCCID  where cv_id=@CVID 
					end
					else if(@regnodeid > 0 and @NID=0)
					begin  
						declare @Gid nvarchar(50)  
						set @str='@Gid nvarchar(50) output' 
						set @NodeidXML='set @Gid= (select GUID from '+convert(nvarchar,@Table)+' where NodeID='+convert(nvarchar,@regnodeid)+')' 
						exec sp_executesql @NodeidXML, @str, @Gid OUTPUT  
						
						EXEC	@return_value = [dbo].[spCOM_SetCostCenter]
						@NodeID = @regnodeid,@SelectedNodeID = 0,@IsGroup = 0,
						@Code = @regnum,
						@Name = @regnum,
						@AliasName=@regnum,
						@PurchaseAccount=0,@SalesAccount=0,@StatusID=@SID,
						@CustomFieldsQuery=NULL,@AddressXML=NULL,@AttachmentsXML=NULL,
						@CustomCostCenterFieldsQuery=NULL,@ContactsXML=NULL,@NotesXML=NULL,@CostCenterRoleXML=@CCMAPXML, 
						@CostCenterID = @LinkRegCCID,@CompanyGUID='dddd',@GUID=@Gid,
						@UserName='admin',@RoleID=1,@UserID=1  , @CheckLink = 0
					end
					declare @accid bigint, @ccdata nvarchar(max), @CCCCCData xml
					select @regnodeid=regnumbernodeid     from svc_customersvehicle WITH(NOLOCK)  where cv_id=@CVID 
					select @accid=isnull(Accountname,'1')   from svc_customers WITH(NOLOCK)  where customerid=@CustomerID 
					if(@accid is not null and @accid <>'' and @accid>1)
					begin			
						DELETE FROM COM_CostCenterCostCenterMap WHERE ParentCostCenterID=2 AND costcenterid=@LinkRegCCID and NodeID=@regnodeid
 						INSERT INTO  COM_CostCenterCostCenterMap (ParentCostCenterID,ParentNodeID,CostCenterID,
						NodeID,GUID,CreatedBy,CreatedDate)
						SELECT 2,@accid,@LinkRegCCID,@regnodeid,NEWID(),'',convert(float,getdate()) --from @CCCCCData.nodes('/XML/Row') as DATA(A)  
					end
				end
				set @ci=@ci+1
			end 
			select * from #temp
			drop table #temp
			 
		END


  
		--Inserts Multiple Notes
		IF (@NotesXML IS NOT NULL AND @NotesXML <> '')
		BEGIN
			SET @XML=@NotesXML

			--If Action is NEW then insert new Notes
			INSERT INTO COM_Notes(FeatureID,CostCenterID,FeaturePK,Note,			
			GUID,CreatedBy,CreatedDate)
			SELECT 51,51,@CustomerID,Replace(X.value('@Note','NVARCHAR(MAX)'),'@~','
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
			X.value('@FileExtension','NVARCHAR(50)'),X.value('@FileDescription','NVARCHAR(500)'),X.value('@IsProductImage','bit'),51,51,@CustomerID,
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
		--Customer Family Details XML
		IF (@CustomerFamilyDetXML IS NOT NULL AND @CustomerFamilyDetXML <> '')
		BEGIN
			SET @XML=@CustomerFamilyDetXML 
			INSERT INTO svc_Customerfamilydetails(CustomerID,Relation, Name, Phone)
			SELECT @CustomerID, X.value('@FRelation','NVARCHAR(500)'),
			X.value('@FName','NVARCHAR(500)'),
			X.value('@FPhone','NVARCHAR(50)') 
			FROM @XML.nodes('/FamilyXML/Row') as Data(X) 	
			WHERE X.value('@Action','NVARCHAR(10)')='NEW'

			--If Action is MODIFY then update Attachments
			UPDATE SVC_CustomerFamilyDetails
			SET Relation=X.value('@FRelation','NVARCHAR(50)'),
				Name=X.value('@FName','NVARCHAR(500)'),
				Phone=X.value('@FPhone','NVARCHAR(50)')  
			FROM svc_Customerfamilydetails C 
			INNER JOIN @XML.nodes('/FamilyXML/Row') as Data(X) 	
			ON convert(bigint,X.value('@FamilyID','bigint'))=C.CustomerFamilyID
			WHERE X.value('@Action','NVARCHAR(500)')='MODIFY'

			--If Action is DELETE then delete Attachments
			DELETE FROM svc_CustomerFamilyDetails
			WHERE CustomerFamilyID IN (SELECT X.value('@FamilyID','bigint')
				FROM @XML.nodes('/FamilyXML/Row') as Data(X)
				WHERE X.value('@Action','NVARCHAR(10)')='DELETE')
		END

	
	update svc_appointment
	set Location=@Location
	Where CustomerVehicleID in (select CV_ID from SVC_CustomersVehicle where CustomerID=@CustomerID)

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
		SELECT * FROM [SVC_Customers] WITH(nolock) WHERE CustomerID=@CustomerID  
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

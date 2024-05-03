USE PACT2C222
GO
SET ANSI_NULLS, QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spADM_SetImportDataToPartsCatalog]
	@XML [nvarchar](max),
	@COSTCENTERID [bigint],
	@IsDuplicateNameAllowed [bit],
	@IsCodeAutoGen [bit],
	@IsOnlyName [bit],
	@CompanyGUID [nvarchar](50),
	@UserName [nvarchar](50),
	@UserID [bigint],
	@LangID [int] = 1
WITH ENCRYPTION, EXECUTE AS CALLER
AS
BEGIN TRANSACTION
BEGIN TRY
SET NOCOUNT ON	
		--Declaration Section
			DECLARE	@return_value int,@failCount int,@Dt float
			declare @NodeID bigint, @Table NVARCHAR(50),@SQL NVARCHAR(max)
			declare @GUID nvarchar(max)
			DECLARE @tempCode NVARCHAR(max),@DUPLICATECODE NVARCHAR(300),@DUPNODENO INT,@PARENTCODE NVARCHAR(max)
			DECLARE @TempGuid NVARCHAR(max),@HasAccess BIT,@DATA XML,@Cnt INT,@I INT, @CCID INT
			SET @DATA=@XML
			SET @Dt=CONVERT(FLOAT,GETDATE())--Setting Current Date  
		
		--SP Required Parameters Check
		IF @CompanyGUID IS NULL OR @CompanyGUID=''
		BEGIN
			RAISERROR('-100',16,1)
		END

		SELECT Top 1 @Table=SysTableName FROM ADM_CostCenterDef WITH(NOLOCK) WHERE CostCenterID=@CostCenterId

 
		-- Create Temp Table
		CREATE TABLE #tblList2(
				ID				int identity(1,1),
				Category		nvarchar(max),
				SubCategory		nvarchar(max),
				GroupName		nvarchar(max),
				ProductCode		nvarchar(max),
				ProductName		nvarchar(max),
				Manufacturer	nvarchar(max),
				[Make]			nvarchar(max),
				[Model]			nvarchar(max),
				[Year]			nvarchar(max),
				[Variant]		nvarchar(max),
				[Segment]		nvarchar(max),
				LabourHrs		int,
				SkillLevel		nvarchar(max))
		
		INSERT INTO #tblList2--(Category,SubCategory,GroupName,Product,Manufacturer,[Make],[Model],[Year],[Variant],[Segment],LabourHrs,SkillLevel)	

		SELECT
			X.value('@Category','nvarchar(max)'),
			X.value('@SubCategory','nvarchar(max)'),
			X.value('@GroupName','nvarchar(max)'),
			X.value('@ProductCode','nvarchar(max)'),
			X.value('@ProductName','nvarchar(max)'),
			X.value('@Manufacturer','nvarchar(max)'),
			X.value('@Make','nvarchar(max)'),
			X.value('@Model','nvarchar(max)'),
			X.value('@Year','nvarchar(max)'),
			X.value('@Variant','nvarchar(max)'),
			X.value('@Segment','nvarchar(max)'),
			X.value('@LabourHours','int'),
			X.value('@SkillLevel','nvarchar(max)')
 		from @DATA.nodes('/XML/Row') as Data(X)
		

		DECLARE @Cat nvarchar(max),@SubCat nvarchar(max),@Group nvarchar(max)
		DECLARE @ProdCode nvarchar(max),@ProdName nvarchar(max),@Manf nvarchar(max),@Skl nvarchar(max),@LabHrs int
		DECLARE @Mk nvarchar(max),@Md nvarchar(max),@Var nvarchar(max) ,@Seg nvarchar(max),@Yr nvarchar(10)
		DECLARE @CatId int,@SubCatId int,@ProdId int,@ManfId int,@SklId int
		DECLARE @MkId int,@MdId int,@VarId int ,@SegId int,@VehId int
		SELECT @I=1, @Cnt=count(ID) FROM #tblList2 

		SET @failCount=0
			WHILE(@I<=@Cnt)  
			BEGIN
				BEGIN TRY	
					
					SET @CatId=0 SET @SubCatId=0 SET @ProdId=0 SET @ManfId=0 SET @SklId=0 SET @VehId=0
					SET @Cat='' SET @SubCat='' SET @Group='' SET @ProdCode='' SET @ProdName='' SET @Manf='' SET @Skl='' SET @LabHrs=0 
					SET @MkId=0 SET @MdId=0 SET @VarId=0 SET @SegId=0
					SET @Mk='' SET @Md='' SET @Var='' SET @Seg='' SET @Yr='' 

					SELECT	@Cat=Category,@SubCat=SubCategory,@Group=GroupName,@ProdCode=ProductCode,@ProdName=ProductName,@Manf=Manufacturer,
							@Mk=[Make],@Md=[Model],@Var=[Variant],@Seg=[Segment],@Yr=[Year],@LabHrs=LabourHrs,@Skl=SkillLevel
							FROM #tblList2 WHERE ID=@I

					--------------------------------------------------------------------------------------------
					IF EXISTS (SELECT CategoryName FROM SVC_PartCategory where CategoryName=@Cat)
						SELECT @CatId= CategoryId FROM SVC_PartCategory where CategoryName=@Cat GROUP BY CategoryId
					ELSE 
						SELECT  @CatId= ISNULL(MAX(CategoryId),0)+1 FROM SVC_PartCategory
					--------------------------------------------------------------------------------------------
					IF EXISTS (SELECT SubCategoryName FROM SVC_PartCategory where SubCategoryName=@SubCat)
						SELECT @SubCatId= SubCategoryId FROM SVC_PartCategory where SubCategoryName=@SubCat GROUP BY SubCategoryId
					ELSE 
						SELECT  @SubCatId= ISNULL(MAX(SubCategoryId),0)+1 FROM SVC_PartCategory
					--------------------------------------------------------------------------------------------

					---------------------------- PRODUCT VERIFY ----------------------------
					IF NOT EXISTS (SELECT ProductID FROM INV_Product WHERE ProductName=@ProdName)
					BEGIN
							---- INSERT PRODUCT
							DECLARE	@ProdReturn_value int

							EXEC	@ProdReturn_value = [dbo].[spINV_SetProduct]
									@ProductId = 0,@ProductCode = @ProdCode,@ProductName = @ProdName,@AliasName = @ProdName,@ProductTypeID = 1,
									@StatusID = 31,@UOMID = 0,@BarcodeID = 0,@Description = @ProdName,@CustomCostCenterFieldsQuery=N'',
									@ContactsXML=N'',@NotesXML=N'',@AttachmentsXML=N'',@SelectedNodeID = 1,@IsGroup = 0,@MatrixSeqno = 0,
									@HasSubItem = 0,@CompanyGUID = @CompanyGUID,@GUID =N'GUID',@UserName = @UserName,@UserID = @UserID,@LangID = @LangID

							SELECT	@ProdId = @ProdReturn_value
							---- END INSERT PRODUCT

					END
					ELSE
					BEGIN
							SELECT @ProdId= ProductID FROM INV_Product WHERE ProductName=@ProdName
					END
					---------------------------- END PRODUCT VERIFY ----------------------------

					---------------------------- MANUFACTURER VERIFY ----------------------------
					IF NOT EXISTS (SELECT NodeID FROM COM_CC50023 WHERE [Name]=@Manf)
					BEGIN
							---- INSERT MANUFACTURER
							DECLARE	@ManfReturn_value int

							EXEC	@ManfReturn_value = [dbo].[spCOM_SetCostCenter]
									@NodeID = 0,@SelectedNodeID = 1,@IsGroup = 0,@Code = @Manf,@Name = @Manf,@AliasName = @Manf,@PurchaseAccount = 0,
									@SalesAccount = 0,@CreditLimit = 0,@CreditDays = 0,@DebitLimit = 0,@DebitDays = 0,@StatusID = 117,@CustomFieldsQuery = N'',
									@CustomCostCenterFieldsQuery = N'',@ContactsXML = N'',@AttachmentsXML = N'',@NotesXML = N'',@PrimaryContactQuery = N'',
									@CostCenterID = 50023,@CompanyGUID = @CompanyGUID,@GUID = N'GUID',@UserName = @UserName,@UserID = @UserID,@LangID = @LangID

							SELECT	@ManfId = @ManfReturn_value
							---- END INSERT MANUFACTURER

					END
					ELSE
					BEGIN
							SELECT @ManfId= NodeID FROM COM_CC50023 WHERE [Name]=@Manf
					END
					---------------------------- END MANUFACTURER VERIFY ----------------------------
				
					---------------------------- SKILL-LEVEL VERIFY ----------------------------
					IF NOT EXISTS (SELECT NodeID FROM COM_CC50018 WHERE [Name]=@Skl)
					BEGIN
							---- INSERT SKILL-LEVEL
							DECLARE	@SklReturn_value int

							EXEC	@SklReturn_value = [dbo].[spCOM_SetCostCenter]
									@NodeID = 0,@SelectedNodeID = 1,@IsGroup = 0,@Code = @Skl,@Name = @Skl,@AliasName = @Skl,@PurchaseAccount = 0,
									@SalesAccount = 0,@CreditLimit = 0,@CreditDays = 0,@DebitLimit = 0,@DebitDays = 0,@StatusID = 107,@CustomFieldsQuery = N'',
									@CustomCostCenterFieldsQuery = N'',@ContactsXML = N'',@AttachmentsXML = N'',@NotesXML = N'',@PrimaryContactQuery = N'',
									@CostCenterID = 50018,@CompanyGUID = @CompanyGUID,@GUID = N'GUID',@UserName = @UserName,@UserID = @UserID,@LangID = @LangID

							SELECT	@SklId = @SklReturn_value
							---- END INSERT SKILL-LEVEL

					END
					ELSE
					BEGIN
							SELECT @SklId= NodeID FROM COM_CC50018 WHERE [Name]=@Skl
					END
					---------------------------- END SKILL-LEVEL VERIFY ----------------------------
					
					---------------------------- VEHICLE VERIFY ----------------------------
					IF NOT EXISTS (SELECT VehicleID FROM SVC_Vehicle WHERE Make=@Mk AND Model=@Md  AND Variant=@Var AND Segment=@Seg)--AND [Year]=@Yr
					BEGIN					
						-----INSERT INTO VEHICLE
						--------------------------------------------------------------------------------------------
						IF EXISTS(SELECT Make FROM SVC_Vehicle where Make=@Mk)
							SELECT @MkId= MakeId FROM SVC_Vehicle where Make=@Mk GROUP BY MakeId
						ELSE 
							SELECT  @MkId= ISNULL(MAX(MakeId),0)+1 FROM SVC_Vehicle
						--------------------------------------------------------------------------------------------
						IF EXISTS(SELECT Model FROM SVC_Vehicle where Model=@Md)
							SELECT @MdId= ModelId FROM SVC_Vehicle where Model=@Md GROUP BY ModelId
						ELSE 
							SELECT  @MdId= ISNULL(MAX(ModelId),0)+1 FROM SVC_Vehicle
						--------------------------------------------------------------------------------------------
						IF EXISTS(SELECT Variant FROM SVC_Vehicle where Variant=@Var)
							SELECT @VarId= VariantId FROM SVC_Vehicle where Variant=@Var GROUP BY VariantId
						ELSE 
							SELECT  @VarId= ISNULL(MAX(VariantId),0)+1 FROM SVC_Vehicle
						--------------------------------------------------------------------------------------------
						IF EXISTS(SELECT Segment FROM SVC_Vehicle where Segment=@Seg)
							SELECT @SegId= SegmentId FROM SVC_Vehicle where Segment=@Seg GROUP BY SegmentId
						ELSE 
							SELECT  @SegId= ISNULL(MAX(SegmentId),0)+1 FROM SVC_Vehicle
						--------------------------------------------------------------------------------------------
						
						INSERT INTO SVC_Vehicle(MakeID, Make, ModelID, Model,  VariantID, Variant, SegmentID, Segment, IsEnabled, IsVisible, CompanyGUID, GUID, CreatedBy, CreatedDate, ModifiedBy, ModifiedDate)
						SELECT @MkId,@Mk,@MdId,@Md,@VarId,@Var,@SegId,@Seg,'True','True',@CompanyGUID,newid(),@UserName, @Dt,@UserName, @Dt

						-----END  INSERT INTO VEHICLE
					END
					ELSE
					BEGIN
						SELECT TOP 1  @VehId= VehicleID FROM SVC_Vehicle 
						WHERE Make=@Mk AND Model=@Md AND Variant=@Var AND Segment=@Seg group by VehicleID
					END
					---------------------------- END VEHICLE VERIFY ----------------------------
					
					DECLARE @PartCategoryID BIGINT,@PartCategoryMapID BIGINT
					------************** INSERT INTO SVC_PARTCATEGORY **********---------------------
					IF NOT EXISTS (SELECT [GroupName] FROM [SVC_PartCategory] WHERE [CategoryName]=@Cat AND [SubCategoryName]=@SubCat AND [GroupName]=@Group)
					BEGIN
						INSERT INTO  [SVC_PartCategory]([CategoryID] ,[CategoryName],[SubCategoryID],[SubCategoryName],[GroupName] ,[CompanyGUID],[GUID],[CreatedBy],[CreateDate])
						VALUES(@CatId,@Cat,@SubCatId,@SubCat,@Group,@CompanyGUID,NEWID(),@UserName,@Dt) 
						SET @PartCategoryID=SCOPE_IDENTITY()
					END
					ELSE 
						SELECT @PartCategoryID = PartCategoryID FROM [SVC_PartCategory] WHERE [CategoryName]=@Cat AND [SubCategoryName]=@SubCat AND [GroupName]=@Group

					INSERT INTO SVC_PartCategoryMap 
					SELECT @PartCategoryID,@ProdId,@ManfId
					SET @PartCategoryMapID=SCOPE_IDENTITY()	

					INSERT INTO SVC_PartVehicle 
					SELECT @PartCategoryMapID,@VehId,@SklId,@LabHrs

					------************** END INSERT INTO SVC_PARTCATEGORY **********---------------------

				END TRY
				BEGIN CATCH
					SET @failCount=@failCount+1
				END CATCH
				SET @I=@I+1

			END

COMMIT TRANSACTION  
--ROLLBACK TRANSACTION  
SELECT ErrorMessage,ErrorNumber FROM COM_ErrorMessages WITH(nolock) 
WHERE ErrorNumber=100 AND LanguageID=@LangID
SET NOCOUNT OFF;  
RETURN @failCount  
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

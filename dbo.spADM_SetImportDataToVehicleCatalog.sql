USE PACT2C222
GO
SET ANSI_NULLS, QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spADM_SetImportDataToVehicleCatalog]
	@XML [nvarchar](max),
	@COSTCENTERID [bigint],
	@IsDuplicateNameAllowed [bit],
	@IsCodeAutoGen [bit],
	@IsOnlyName [bit],
	@CompanyGUID [nvarchar](50),
	@UserName [nvarchar](50),
	@UserID [bigint],
	@RoleID [int] = 1,
	@LangID [int] = 1
WITH ENCRYPTION, EXECUTE AS CALLER
AS
BEGIN TRANSACTION
BEGIN TRY
SET NOCOUNT ON	
		--Declaration Section
			DECLARE	@return_value int,@failCount int,@Dt float,@vehicleid bigint
			declare @NodeID bigint, @Table NVARCHAR(50),@SQL NVARCHAR(max)
			declare @GUID nvarchar(max),@ExtraFields nvarchar(max)
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
		CREATE TABLE #tblList1(
				ID int identity(1,1),
				[Make] nvarchar(max),
				[Model] nvarchar(max),
				[SYear] int,
				EYEAR int,
				[Variant] nvarchar(max),
				[Segment] nvarchar(max),
				[IsEnabled] bit,
				[IsVisible] bit,ExtraFields nvarchar(max))
		
		INSERT INTO #tblList1([Make],[Model],[SYear],EYEAR,[Variant],[Segment],ExtraFields)

		SELECT
			X.value('@Make','nvarchar(max)'),
			X.value('@Model','nvarchar(max)'),
			X.value('@StartYear','int'),
			X.value('@EndYear','int'),
			X.value('@Variant','nvarchar(max)'),
			X.value('@Segment','nvarchar(max)'),
			X.value('@ExtraFields','nvarchar(max)')
 		from @DATA.nodes('/XML/Row') as Data(X)
		

		DECLARE @Mk nvarchar(max),@TEMPxml NVARCHAR(MAX),@Md nvarchar(max),@Var nvarchar(max) ,@Seg nvarchar(max),@Yr int,@EYr int
		DECLARE @MkId int,@MdId int,@VarId int ,@SegId int 
		SELECT @I=1, @Cnt=count(ID) FROM #tblList1 
		SET @failCount=0
			WHILE(@I<=@Cnt)  
			BEGIN
				BEGIN TRY	
				 
					SET @MkId=0 SET @MdId=0 SET @VarId=0 SET @SegId=0
					SET @Mk='' SET @Md='' SET @Var='' SET @Seg='' SET @Yr=0 SET @EYr=0
					
					SELECT @Mk=[Make],@Md=[Model],@Var=[Variant],@Seg=[Segment],@Yr=[SYear],@EYr=EYEAR,@ExtraFields=ExtraFields FROM #tblList1 WHERE ID=@I
					--------------------------------------------------------------------------------------------
					IF(SELECT COUNT(Make) FROM SVC_Vehicle where Make=@Mk) > 0
						SELECT @MkId= MakeId FROM SVC_Vehicle where Make=@Mk GROUP BY MakeId
					ELSE 
						SELECT  @MkId= ISNULL(MAX(MakeId),0)+1 FROM SVC_Vehicle
					--------------------------------------------------------------------------------------------
					IF(SELECT COUNT(Model) FROM SVC_Vehicle where Model=@Md) > 0
						SELECT @MdId= ModelId FROM SVC_Vehicle where Model=@Md GROUP BY ModelId
					ELSE 
						SELECT  @MdId= ISNULL(MAX(ModelId),0)+1 FROM SVC_Vehicle
					--------------------------------------------------------------------------------------------
					IF(SELECT COUNT(Variant) FROM SVC_Vehicle where Variant=@Var) > 0
						SELECT @VarId= VariantId FROM SVC_Vehicle where Variant=@Var GROUP BY VariantId
					ELSE 
						SELECT  @VarId= ISNULL(MAX(VariantId),0)+1 FROM SVC_Vehicle
					--------------------------------------------------------------------------------------------
					IF(SELECT ISNULL(COUNT(*),0) FROM COM_CC50024 where CODE=RTRIM(LTRIM(@Seg))) > 0
						SELECT @SegId= NODEID FROM COM_CC50024 where CODE=RTRIM(LTRIM(@Seg))
					ELSE 
					BEGIN
						BEGIN TRANSACTION
						SET @TEMPxml='<XML><Row  AccountCode ="'+replace(@Seg,'&','&amp;')+'" AccountName ="'+replace(@Seg,'&','&amp;')+'"  ></Row></XML>'

						EXEC	@return_value = [dbo].[spADM_SetImportData]
							@XML = @TEMPxml,
							@COSTCENTERID = 50024,
							@IsDuplicateNameAllowed = 1,
							@IsCodeAutoGen = 0,
							@IsOnlyName = 1,
							@CompanyGUID = @CompanyGUID,
							@UserName = @UserName ,
							@UserID = @UserID,
							@RoleID=@RoleID,
							@LangID = @LangID 
						SELECT  @SegId= ISNULL(MAX(NODEID),0) FROM COM_CC50024 WHERE CODE=@Seg
						COMMIT TRANSACTION
					END 
					--------------------------------------------------------------------------------------------
					
					INSERT INTO SVC_Vehicle(MakeID, Make, ModelID, Model, StartYear , EndYear, VariantID, Variant, SegmentID, Segment, IsEnabled, IsVisible, CompanyGUID, GUID, CreatedBy, CreatedDate, ModifiedBy, ModifiedDate)
					SELECT @MkId,@Mk,@MdId,@Md,@Yr,@EYr,@VarId,@Var,@SegId,@Seg,'True','True',@CompanyGUID,newid(),@UserName, @Dt,@UserName, @Dt

					set @vehicleid=@@IDENTITY
					if(@ExtraFields is not null and @ExtraFields<>'')
					begin
						set @SQL='update SVC_Vehicle set '+@ExtraFields+
						'CreatedBy='''+ @UserName+''' where VehicleID='+convert(nvarchar,@vehicleid)
						exec(@SQL)
					end

				END TRY
				BEGIN CATCH
					SET @failCount=@failCount+1
				END CATCH
				SET @I=@I+1

			END

COMMIT TRANSACTION  
DROP TABLE #tblList1
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

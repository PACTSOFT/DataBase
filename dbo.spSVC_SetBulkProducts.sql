USE PACT2C222
GO
SET ANSI_NULLS, QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spSVC_SetBulkProducts]
	@ProductsXML [nvarchar](max) = null,
	@CompanyGUID [nvarchar](50) = null,
	@UserName [nvarchar](50),
	@UserID [bigint],
	@LangID [int] = 1
WITH ENCRYPTION, EXECUTE AS CALLER
AS
BEGIN TRANSACTION  
BEGIN TRY  
SET NOCOUNT ON;
		--Declaration Section  
		DECLARE @Dt FLOAT ,@HasAccess BIT		
		DECLARE @Tbl TABLE(ID INT IDENTITY(1,1),ProdID BIGINT,TempProdID INT, [Name] NVARCHAR(50),Part BIGINT,Cat BIGINT,SubCat BIGINT,UOM BIGINT,MFG BIGINT,PRate FLOAT,SRate FLOAT,Vehicles NVARCHAR(MAX),Extra NVARCHAR(MAX))
		DECLARE @ProductCode NVARCHAR(200),@CodeNUMBER BIGINT
		DECLARE @ProdID BIGINT,@TempProdID INT, @Name NVARCHAR(50),@Part BIGINT,@Cat BIGINT,@SubCat BIGINT,@UOM BIGINT,@MFG BIGINT,@PRate FLOAT,@SRate FLOAT,@Vehicles NVARCHAR(MAX),@Extra NVARCHAR(MAX),@CustomCostCenterFieldsQuery NVARCHAR(MAX)
		DECLARE @I INT,@Count INT,@XML XML
		
		
		--SP Required Parameters Check
		IF @CompanyGUID IS NULL OR @CompanyGUID=''
		BEGIN
			RAISERROR('-100',16,1)
		END
		
		SET @XML=@ProductsXML
		
		INSERT INTO @Tbl(ProdID,TempProdID,[Name],Part,
						Cat,SubCat,UOM,MFG,
						PRate,SRate,Vehicles,Extra)
		SELECT  0,X.value('@TempProdID','INT'),X.value('@Name','NVARCHAR(MAX)'),X.value('@Part','BIGINT'),
				X.value('@Cat','BIGINT'),X.value('@SubCat','BIGINT'),X.value('@UOM','BIGINT'),X.value('@MFG','BIGINT'),
				X.value('@PRate','FLOAT'),X.value('@SRate','FLOAT'),X.value('@Vehicles','NVARCHAR(MAX)'),X.value('@Extra','NVARCHAR(MAX)')
		FROM @XML.nodes('/XML/Row') as Data(X)

		SELECT @I=1, @Count=COUNT(*) FROM @Tbl


		WHILE(@I<=@Count)
		BEGIN
			SELECT  @ProdID=0,@TempProdID=TempProdID,@Name=[Name],@Part=Part,@Cat=Cat,
					@SubCat=SubCat,@UOM=UOM,@MFG=MFG,@PRate=PRate,@SRate=SRate,@Vehicles=Vehicles,@Extra=Extra
			FROM @Tbl WHERE ID=@I

			SET @CustomCostCenterFieldsQuery='CCNID29='+CONVERT(NVARCHAR,@Part)
						+',CCNID30='+CONVERT(NVARCHAR,@SubCat)+',CCNID23='+CONVERT(NVARCHAR,@MFG)+','

			EXEC [spCOM_GetCode] 3,'',@ProductCode OUTPUT,@CodeNUMBER OUTPUT
			
			---- INSERT PRODUCT
			EXEC	@ProdID = [dbo].[spINV_SetProduct]
					@ProductId = 0,@ProductCode =@ProductCode,@ProductName=@ProductCode,@AliasName = @Name,@ProductTypeID = 1,
					@StatusID = 31,@UOMID = @UOM,@BarcodeID = 0,@Description = @Name,
					@CustomFieldsQuery=@Extra, @CustomCostCenterFieldsQuery=@CustomCostCenterFieldsQuery,@ProductVehicleXML=@Vehicles,
					@ContactsXML=N'',@NotesXML=N'',@AttachmentsXML=N'',@SelectedNodeID = 1,@IsGroup = 0,@MatrixSeqno = 0,
					@HasSubItem = 0,@CompanyGUID = @CompanyGUID,@GUID =N'GUID',@UserName = @UserName,@UserID = @UserID,@LangID = @LangID
			UPDATE	INV_Product SET	PurchaseRate = @PRate,SellingRate = @SRate WHERE ProductID=@ProdID
			---- END INSERT PRODUCT

			UPDATE @Tbl
			SET ProdID=@ProdID
			WHERE ID=@I
			
			SET @I=@I+1
		END

--SELECT * FROM SVC_ProductVehicle

COMMIT TRANSACTION  
--ROLLBACK TRANSACTION

SELECT ProdID,TempProdID FROM @Tbl

SELECT ErrorMessage,ErrorNumber FROM COM_ErrorMessages WITH(nolock) 
WHERE ErrorNumber=100 AND LanguageID=@LangID     


SET NOCOUNT OFF;  
RETURN 1
END TRY
BEGIN CATCH  
	--Return exception info [Message,Number,ProcedureName,LineNumber]  
	IF ERROR_NUMBER()=50000
	BEGIN
		SELECT ErrorMessage,ErrorNumber FROM COM_ErrorMessages WITH(NOLOCK) WHERE ErrorNumber=ERROR_MESSAGE() AND LanguageID=@LangID
	END
	ELSE
	BEGIN
		SELECT ErrorMessage, ERROR_MESSAGE() AS ServerMessage,ERROR_NUMBER() as ErrorNumber, ERROR_PROCEDURE()as ProcedureName, ERROR_LINE() AS ErrorLine
		FROM COM_ErrorMessages WITH(NOLOCK) WHERE ErrorNumber=-999 AND LanguageID=@LangID
	END

	BEGIN TRY	
		ROLLBACK TRANSACTION
	END TRY
	BEGIN CATCH
		
	END CATCH

SET NOCOUNT OFF  
RETURN -999   
END CATCH
GO

USE PACT2C222
GO
SET ANSI_NULLS, QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spSVC_SetServiceCategoryData]
	@CATEGORYID [bigint],
	@SUBCATEGORYID [bigint],
	@CATEGORYNAME [nvarchar](300),
	@SUBCATEGORYNAME [nvarchar](300),
	@GROUPNAME [nvarchar](300),
	@PartCategoryID [bigint],
	@PARTSDATA [nvarchar](max) = NULL,
	@VEHICLEDATA [nvarchar](max) = NULL,
	@CompanyGUID [nvarchar](50),
	@UserName [nvarchar](50),
	@UserID [bigint] = 0,
	@LangID [int] = 1
WITH ENCRYPTION, EXECUTE AS CALLER
AS
BEGIN TRANSACTION
SET NOCOUNT ON
BEGIN TRY
		--Declaration Section
		DECLARE @TempGuid NVARCHAR(50),@Dt FLOAT, @HasAccess BIT,@DATA XML,@DATA1 XML
		DECLARE @COUNT INT,@I INT,@J INT,@TCOUNT INT,@PartCategoryMapID BIGINT
		SET @DATA=@PARTSDATA
		SET @DATA1=@VEHICLEDATA
		SET @Dt=CONVERT(FLOAT,GETDATE()) 
		--SP Required Parameters Check
		IF @CompanyGUID IS NULL OR @CompanyGUID=''
		BEGIN
			RAISERROR('-100',16,1)
		END
		
		IF @PARTCATEGORYID=0
		BEGIN
			 IF @CATEGORYID=0
			 BEGIN
					SELECT @CategoryID=ISNULL(MAX(CategoryID),0) FROM dbo.SVC_PartCategory WITH(NOLOCK)
					SET @CategoryID=@CategoryID+1
             END
			 IF @SUBCATEGORYID=0	
			 BEGIN
				SELECT @SUBCATEGORYID=ISNULL(MAX([SubCategoryID]),0) FROM dbo.SVC_PartCategory WITH(NOLOCK)
				SET @SUBCATEGORYID=@SUBCATEGORYID+1
		     END

			 INSERT INTO  [SVC_PartCategory]([CategoryID] ,[CategoryName],[SubCategoryID],[SubCategoryName],[GroupName] ,[CompanyGUID],[GUID],[CreatedBy]
				,[CreateDate])
				VALUES((@CATEGORYID),@CATEGORYNAME,(@SUBCATEGORYID),@SUBCATEGORYNAME,@GROUPNAME,@CompanyGUID,NEWID(),@UserName,@Dt) 
			SET @PartCategoryID=SCOPE_IDENTITY()
		END
		ELSE
		BEGIN
		   UPDATE [SVC_PartCategory] SET [GroupName]=@GROUPNAME,MODIFIEDBY=@UserName,MODIFIEDDATE=@Dt WHERE PartCategoryID=@PartCategoryID
		END
 	
		CREATE TABLE #TBLTEMP(ID INT IDENTITY(1,1), PRODUCTID BIGINT,Manufacturer BIGINT)
		CREATE TABLE #TBLTEMP1(ID INT IDENTITY(1,1), VEHICLEID BIGINT,SKILLLEVEL NVARCHAR(300),LOBOURHRS NVARCHAR(300))

		INSERT INTO #TBLTEMP
		SELECT A.value('@ProductKey','BIGINT'),A.value('@Manufacturer','BIGINT') FROM @DATA.nodes('/Data/Row') AS DATA(A) WHERE A.value('@MapAction','NVARCHAR(500)')='NEW'
			
		--If MapAction is UPDATE then UPDATE  	
		UPDATE SVC_PartCategoryMap
		SET  ProductID=A.value('@ProductKey','NVARCHAR(300)'),Manufacturer=A.value('@Manufacturer','NVARCHAR(300)')  
		FROM SVC_PartCategoryMap U
		INNER JOIN @DATA.nodes('/Data/Row') AS DATA(A)
		ON CONVERT(BIGINT,A.value('@PrimaryKey','BIGINT'))=U.PartCategoryMapID
		WHERE A.value('@MapAction','NVARCHAR(500)')='UPDATE'
		
		--If MapAction is DELETE then delete  		
		DELETE FROM SVC_PartCategoryMap
		WHERE PartCategoryMapID IN(SELECT A.value('@PrimaryKey','BIGINT')
		FROM @DATA.nodes('/Data/Row') as Data(A)
		WHERE A.value('@MapAction','NVARCHAR(10)')='DELETE')




		INSERT INTO #TBLTEMP1
		SELECT A.value('@VehicleID','INT'),A.value('@SkillLevel','INT'), A.value('@LabourHrs','NVARCHAR(300)') 
		FROM @DATA1.nodes('/Data/Row') AS DATA(A) WHERE A.value('@MapAction','NVARCHAR(500)')='NEW'
		
		SELECT @I=1,@COUNT=COUNT(*) FROM #TBLTEMP
		SELECT @J=1,@TCOUNT=COUNT(*) FROM #TBLTEMP1
		WHILE @I<=@COUNT
		BEGIN
--			TRUNCATE TABLE [SVC_PartCategory]
			INSERT INTO SVC_PartCategoryMap 
			SELECT @PartCategoryID,PRODUCTID,Manufacturer FROM #TBLTEMP WHERE ID=@I
			SET @PartCategoryMapID=SCOPE_IDENTITY()		

				WHILE @J<=@TCOUNT
				BEGIN
				INSERT INTO SVC_PartVehicle 
				SELECT @PartCategoryMapID,VEHICLEID,SKILLLEVEL,LOBOURHRS FROM #TBLTEMP1 WHERE ID=@J
				 
				SET @J=@J+1
				END
				SET @J=1

		SET @I=@I+1
		END 
		--If MapAction is UPDATE then UPDATE  	
		UPDATE SVC_PartVehicle
		SET  SKILLLEVEL=A.value('@SkillLevel','NVARCHAR(300)'),SkillHours=A.value('@LabourHrs','NVARCHAR(300)')  
		FROM SVC_PartVehicle U
		INNER JOIN @DATA1.nodes('/Data/Row') AS DATA(A)
		ON CONVERT(BIGINT,A.value('@PrimaryKey','BIGINT'))=U.PartVehicleID
		WHERE A.value('@MapAction','NVARCHAR(500)')='UPDATE'
		
		--If MapAction is DELETE then delete  		
		DELETE FROM SVC_PartVehicle
		WHERE PartVehicleID IN(SELECT A.value('@PrimaryKey','BIGINT')
		FROM @DATA1.nodes('/Data/Row') as Data(A)
		WHERE A.value('@MapAction','NVARCHAR(10)')='DELETE')
		
COMMIT TRANSACTION  
SELECT ErrorMessage,ErrorNumber FROM COM_ErrorMessages WITH(nolock) 
WHERE ErrorNumber=100 AND LanguageID=@LangID     
SET NOCOUNT OFF;  
RETURN @PartCategoryID  
END TRY  
BEGIN CATCH  
	--Return exception info [Message,Number,ProcedureName,LineNumber]  
	IF ERROR_NUMBER()=50000
	BEGIN 
		SELECT ErrorMessage,ErrorNumber FROM COM_ErrorMessages WITH(nolock) WHERE ErrorNumber=ERROR_MESSAGE() AND LanguageID=@LangID
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

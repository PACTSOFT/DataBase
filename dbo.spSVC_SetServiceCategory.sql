USE PACT2C222
GO
SET ANSI_NULLS, QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spSVC_SetServiceCategory]
	@CategoryID [bigint] = 0,
	@CategoryName [nvarchar](300) = NULL,
	@SubCategoryID [bigint] = 0,
	@SubCategoryName [nvarchar](300) = NULL,
	@FLAG [int],
	@CompanyGUID [nvarchar](50),
	@UserName [nvarchar](50),
	@UserID [bigint],
	@LangID [int] = 1,
	@RoleID [int] = 1
WITH ENCRYPTION, EXECUTE AS CALLER
AS
BEGIN TRANSACTION
SET NOCOUNT ON
BEGIN TRY
		--Declaration Section
		DECLARE @TempGuid NVARCHAR(50),@Dt FLOAT, @HasAccess BIT,@PartCategoryID BIGINT
		SET @Dt=CONVERT(FLOAT,GETDATE()) 
		--SP Required Parameters Check
		IF @CompanyGUID IS NULL OR @CompanyGUID=''
		BEGIN
			RAISERROR('-100',16,1)
		END
		
		--User acces check
		IF @CategoryID=0
		BEGIN
			SET @HasAccess=dbo.fnCOM_HasAccess(@RoleID,55,1)
		END
		ELSE
		BEGIN
			SET @HasAccess=dbo.fnCOM_HasAccess(@RoleID,55,3)
		END
		IF @HasAccess=0
		BEGIN
			RAISERROR('-105',16,1)
		END

		IF @CategoryID=0
			SELECT @CategoryID=ISNULL(MAX(CategoryID),0) FROM dbo.SVC_PartCategory WITH(NOLOCK)

		IF @FLAG=0 --IF FLAG IS ZERO THEN ADD CATEGORY
		BEGIN
			INSERT INTO  [SVC_PartCategory]([CategoryID] ,[CategoryName],[SubCategoryID],[SubCategoryName],[GroupName] ,[CompanyGUID],[GUID],[CreatedBy]
			,[CreateDate])
			VALUES((@CategoryID+1),@CategoryName,0,'','-100',@CompanyGUID,NEWID(),@UserName,@Dt)
		END
		ELSE IF @FLAG=1--ADD SUBCATEGORY
		BEGIN
			IF @SubCategoryID=0
				SELECT @SubCategoryID=ISNULL(MAX([SubCategoryID]),0) FROM dbo.SVC_PartCategory WITH(NOLOCK) 

		    INSERT INTO  [SVC_PartCategory]([CategoryID] ,[CategoryName],[SubCategoryID],[SubCategoryName],[GroupName] ,[CompanyGUID],[GUID],[CreatedBy]
			,[CreateDate])
			VALUES(@CategoryID,@CategoryName,(@SubCategoryID+1),@SubCategoryName,'-100',@CompanyGUID,NEWID(),@UserName,@Dt) 
		END
		ELSE IF @FLAG=-1 --UPDATE CATEGORY
		BEGIN
			UPDATE [SVC_PartCategory] SET [CategoryName]=@CategoryName,MODIFIEDBY=@UserName,MODIFIEDDATE=@Dt WHERE [CategoryID]=@CategoryID
		END
		ELSE IF @FLAG=-2 --UPDATE SUBCATEGORY
		BEGIN
			UPDATE [SVC_PartCategory] SET [SubCategoryName]=@SubCategoryName,MODIFIEDBY=@UserName,MODIFIEDDATE=@Dt
			WHERE [SubCategoryID]=@SubCategoryID AND [CategoryID]=@CategoryID
		END
		
	

COMMIT TRANSACTION  
SELECT ErrorMessage,ErrorNumber FROM COM_ErrorMessages WITH(nolock) 
WHERE ErrorNumber=100 AND LanguageID=@LangID     
SET NOCOUNT OFF;  
RETURN @CategoryID  
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

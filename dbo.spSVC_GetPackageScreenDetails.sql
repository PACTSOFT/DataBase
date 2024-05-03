USE PACT2C222
GO
SET ANSI_NULLS, QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spSVC_GetPackageScreenDetails]
	@PackageID [bigint] = 0,
	@RoleID [bigint],
	@LangID [int] = 1
WITH ENCRYPTION, EXECUTE AS CALLER
AS
BEGIN TRANSACTION
BEGIN TRY	
SET NOCOUNT ON

		--Declaration Section
		DECLARE @HasAccess bit 
		
		--User acces check
		SET @HasAccess=dbo.fnCOM_HasAccess(@RoleID,62,1)
		IF @HasAccess=0
		BEGIN
			RAISERROR('-105',16,1)
		END

		IF @PackageID >0
		BEGIN
			SELECT * FROM SVC_Package with(nolock) WHERE PackageID=@PackageID
            SELECT * FROM SVC_PackagesCCMap with(nolock) WHERE PackageID=@PackageID
			SELECT * FROM SVC_PackageParts with(nolock) WHERE PackageID=@PackageID
		END
		ELSE
		BEGIN
			SELECT * FROM SVC_Package with(nolock) WHERE ENDDATETIME>CONVERT(FLOAT,GETDATE())
			SELECT * FROM SVC_Package with(nolock) WHERE ENDDATETIME<CONVERT(FLOAT,GETDATE())
		END
		 


COMMIT TRANSACTION
SET NOCOUNT OFF;
RETURN 1
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

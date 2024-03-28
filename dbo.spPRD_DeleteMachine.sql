USE PACT2C222
GO
SET ANSI_NULLS, QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spPRD_DeleteMachine]
	@ResourceID [bigint] = 0,
	@UserID [bigint],
	@LangID [int] = 1
WITH ENCRYPTION, EXECUTE AS CALLER
AS
BEGIN TRANSACTION
BEGIN TRY  
SET NOCOUNT ON;  
		--Declaration Section
		DECLARE @HasAccess bit,@RowsDeleted bigint,@lft bigint,@rgt bigint,@Width bigint

		--SP Required Parameters Check
		if(@ResourceID=0)
		BEGIN
			RAISERROR('-100',16,1)
		END

		IF EXISTS(SELECT ResourceName FROM PRD_Resources WHERE ResourceID=@ResourceID AND ResourceID=1)
		BEGIN
			RAISERROR('-115',16,1)
		END

		--Fetch left, right extent of Node along with width.
		SELECT @lft = lft, @rgt = rgt, @Width = rgt - lft + 1
		FROM PRD_Resources WITH(NOLOCK) WHERE ResourceID=@ResourceID

			--Delete from exteneded table
		DELETE FROM PRD_ResourceExtended WHERE ResourceID in
		(select ResourceID from PRD_Resources  WHERE lft >= @lft AND rgt <= @rgt)

		--Delete from main table
		DELETE FROM PRD_Resources WHERE lft >= @lft AND rgt <= @rgt
		--DELETE FROM PRD_Resources WHERE RESOURCEID=@ResourceID

		SET @RowsDeleted=@@rowcount


		--Delete from Contacts
		DELETE FROM  COM_Contacts 
		WHERE FeatureID=71 and  FeaturePK=@ResourceID

		--Delete from Notes
		DELETE FROM  COM_Notes 
		WHERE FeatureID=71 and  FeaturePK=@ResourceID

		--Delete from Files
		DELETE FROM  COM_Files  
		WHERE FeatureID=71 and  FeaturePK=@ResourceID

	

		--Update left and right extent to set the tree
		UPDATE PRD_Resources SET rgt = rgt - @Width WHERE rgt > @rgt;
		UPDATE PRD_Resources SET lft = lft - @Width WHERE lft > @rgt;
	

COMMIT TRANSACTION
SET NOCOUNT OFF;  
SELECT ErrorMessage,ErrorNumber FROM COM_ErrorMessages WITH(nolock) 
WHERE ErrorNumber=102 AND LanguageID=@LangID

RETURN @RowsDeleted
END TRY
BEGIN CATCH  
	--Return exception info [Message,Number,ProcedureName,LineNumber]  
	IF ERROR_NUMBER()=50000
	BEGIN
		SELECT ErrorMessage,ErrorNumber FROM COM_ErrorMessages WITH(nolock) WHERE ErrorNumber=ERROR_MESSAGE() AND LanguageID=@LangID
	END
	ELSE IF ERROR_NUMBER()=547
	BEGIN
		SELECT ErrorMessage, ERROR_MESSAGE() AS ServerMessage,ERROR_NUMBER() as ErrorNumber, ERROR_PROCEDURE()as ProcedureName, ERROR_LINE() AS ErrorLine FROM COM_ErrorMessages WITH(nolock)
		WHERE ErrorNumber=-110 AND LanguageID=@LangID
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

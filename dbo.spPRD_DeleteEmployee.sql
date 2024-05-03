﻿USE PACT2C222
GO
SET ANSI_NULLS, QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spPRD_DeleteEmployee]
	@EmpID [bigint] = 0,
	@RoleID [int],
	@LangID [int] = 1
WITH ENCRYPTION, EXECUTE AS CALLER
AS
BEGIN TRANSACTION
BEGIN TRY  
SET NOCOUNT ON;  

		--Declaration Section
		DECLARE @HasAccess bit,@RowsDeleted bigint,@lft bigint,@rgt bigint,@Width bigint

		--User acces check
		SET @HasAccess=dbo.fnCOM_HasAccess(@RoleID,80,4)
		IF @HasAccess=0
		BEGIN
			RAISERROR('-105',16,1)
		END
		
		IF EXISTS(SELECT ResourceID FROM PRD_Resources WHERE ResourceID=@EmpID AND ParentID=0)
		BEGIN
			RAISERROR('-115',16,1)
		END
			--SP Required Parameters Check
		if(@EmpID=0)
		BEGIN
			RAISERROR('-100',16,1)
		END

		--Fetch left, right extent of Node along with width.
		SELECT @lft = lft, @rgt = rgt, @Width = rgt - lft + 1
		FROM PRD_Resources WITH(NOLOCK) WHERE ResourceID=@EmpID
  
		--Delete from main table
		delete from PRD_Resources	where ResourceID=@EmpID

		SET @RowsDeleted=@@rowcount 

	 
	 	--Update left and right extent to set the tree
		UPDATE PRD_Resources SET rgt = rgt - @Width WHERE rgt > @rgt;
		UPDATE PRD_Resources SET lft = lft - @Width WHERE lft > @rgt;
	

		
		DELETE FROM [PRD_ResourceExtended] WHERE ResourceID=@EmpID
		
		DELETE FROM  COM_ContactsExtended
		WHERE ContactID IN (SELECT CONTACTID FROM COM_CONTACTS WITH(NOLOCK) WHERE FeatureID=2 and  FeaturePK=@EmpID)
		DELETE FROM  COM_Contacts 
		WHERE FeatureID=71 and  FeaturePK=@EmpID

		--Delete from Notes
		DELETE FROM  COM_Notes 
		WHERE FeatureID=71 and  FeaturePK=@EmpID

		--Delete from Files
		DELETE FROM  COM_Files  
		WHERE FeatureID=71 and  FeaturePK=@EmpID
		
		DELETE FROM COM_CCCCDATA WHERE CostCenterID=71 and NodeID=@EmpID	
		
		delete from PRD_Resources	where ResourceID=@EmpID
		SET @RowsDeleted=@@rowcount
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

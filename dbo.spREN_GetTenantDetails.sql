USE PACT2C222
GO
SET ANSI_NULLS, QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spREN_GetTenantDetails]
	@TenantID [bigint] = 0,
	@UserID [bigint],
	@LangID [int] = 1,
	@RoleID [int] = 0
WITH ENCRYPTION, EXECUTE AS CALLER
AS
BEGIN TRANSACTION
BEGIN TRY	
SET NOCOUNT ON
		
	SELECT * FROM REN_Tenant  WITH(NOLOCK) 
	WHERE TenantID=@TenantID
	
	--Getting data from Tenant extended table
	SELECT * FROM  REN_TenantExtended WITH(NOLOCK) 
	WHERE TenantID=@TenantID

	SELECT * FROM COM_CCCCDATA  WITH(NOLOCK)
	WHERE NodeID = @TenantID AND CostCenterID  = 94 
	
	SELECT * FROM COM_Notes WITH(NOLOCK)   
	WHERE FeatureID = 94 AND FeaturePK  = @TenantID
	
	EXEC [spCOM_GetAttachments] 94,@TenantID,@UserID
	
	--WorkFlow
	EXEC spCOM_CheckCostCentetWFApprove 94,@TenantID,@UserID,@RoleID
	
	IF(EXISTS(SELECT * FROM CRM_Activities WHERE CostCenterID=94 AND NodeID=@TenantID))
		EXEC spCRM_GetFeatureByActvities @TenantID,94,'',@UserID,@LangID  
	ELSE
		SELECT 1 WHERE 1<>1

	--8 Getting Contacts  
	EXEC [spCom_GetFeatureWiseContacts] 94,@TenantID,2,1,1

	--9 Getting Contacts  
	EXEC [spCom_GetFeatureWiseContacts] 94,@TenantID,1,1,1
	
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

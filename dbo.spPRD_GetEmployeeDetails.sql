USE PACT2C222
GO
SET ANSI_NULLS, QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spPRD_GetEmployeeDetails]
	@ResourceID [bigint] = 0,
	@UserID [bigint],
	@LangID [int] = 1
WITH ENCRYPTION, EXECUTE AS CALLER
AS
BEGIN TRY	
SET NOCOUNT ON

		--Declaration Section
		DECLARE @HasAccess bit

		--SP Required Parameters Check
		IF (@ResourceID < 1)
		BEGIN
			RAISERROR('-100',16,1)
		END

		--Getting Resources
		SELECT * FROM PRD_Resources WITH(NOLOCK) 	
		WHERE ResourceID=@ResourceID and resourcetypeid=2

		--Getting Contacts
		SELECT c.*, l.name as Salutation FROM  COM_Contacts c WITH(NOLOCK) 
		left join com_lookup l WITH(NOLOCK) on l.Nodeid=c.SalutationID
		WHERE FeatureID=80 and  FeaturePK=@ResourceID AND AddressTypeID=2

		--Getting Notes
		SELECT * FROM  COM_Notes WITH(NOLOCK) 
		WHERE FeatureID=80 and  FeaturePK=@ResourceID

		--Getting Files
		SELECT * FROM  COM_Files WITH(NOLOCK) 
		WHERE FeatureID=80 and  FeaturePK=@ResourceID

		--Getting ADDRESS 
		EXEC spCom_GetAddress 80,@ResourceID,1,1

		--Getting Contacts
		SELECT * FROM  COM_Contacts WITH(NOLOCK) 
		WHERE FeatureID=80 and  FeaturePK=@ResourceID AND AddressTypeID=1

			--Getting data from Resource extended table
		SELECT * FROM  PRD_ResourceExtended WITH(NOLOCK) 
		WHERE ResourceID=@ResourceID
		
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
SET NOCOUNT OFF  
RETURN -999   
END CATCH  
GO

﻿USE PACT2C222
GO
SET ANSI_NULLS, QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spINV_GetSubstitueGroups]
	@UserID [bigint],
	@LangID [int] = 1
WITH ENCRYPTION, EXECUTE AS CALLER
AS
BEGIN TRANSACTION
BEGIN TRY  
SET NOCOUNT ON;  
 
		--Declaration Section
		 
		BEGIN
			SELECT DISTINCT productid,productname
			FROM INV_Product S WITH(NOLOCK) where isgroup=1
			
			SELECT DISTINCT SubstituteGroupID,SubstituteGroupName FROM INV_ProductSubstitutes WITH(NOLOCK) 
			SELECT SubstituteGroupID,SubstituteGroupName,P.PRODUCTNAME,P.PRODUCTID,P.ProductCode FROM INV_ProductSubstitutes S WITH(NOLOCK) 
			LEFT JOIN INV_PRODUCT P ON P.PRODUCTID=S.PRODUCTID
			 
		END
COMMIT TRANSACTION
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
		SELECT ErrorMessage, ERROR_MESSAGE() AS ServerMessage,ERROR_NUMBER() AS ErrorNumber, ERROR_PROCEDURE()AS ProcedureName, ERROR_LINE() AS ErrorLine
		FROM COM_ErrorMessages WITH(NOLOCK) WHERE ErrorNumber=-999 AND LanguageID=@LangID
	END
ROLLBACK TRANSACTION
SET NOCOUNT OFF  
RETURN -999   
END CATCH  

GO

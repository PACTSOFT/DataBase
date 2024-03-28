﻿USE PACT2C222
GO
SET ANSI_NULLS, QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spADM_GetDocumentFields]
	@CCID [int],
	@UserID [bigint],
	@LangID [int] = 1
WITH ENCRYPTION, EXECUTE AS CALLER
AS
BEGIN TRANSACTION
BEGIN TRY	
SET NOCOUNT ON

	SELECT Case when C.SysColumnName like 'dcCalcNumFC%' then R.ResourceData+'-Calculated FC'
			when C.SysColumnName like 'dcCalcNum%' then R.ResourceData+'-Calculated'
			 when C.SysColumnName like 'dcCurrID%' then R.ResourceData+'-Currency'
			 when C.SysColumnName like 'dcExchRT%' then R.ResourceData+'-Exchange Rate' 
			 else R.ResourceData end UserColumnName ,C.CostCenterID,C.CostCenterName,C.SysTableName,C.SysColumnName,C.CostCenterColID,upper(C.ColumnDataType) ColumnDataType
	FROM ADM_CostCenterDef C,COM_LanguageResources R WITH(NOLOCK)
	WHERE  C.ResourceID=R.ResourceID AND R.LanguageID=@LangID AND C.CostCenterID=@CCID and C.IsColumnInUse=1
	 
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

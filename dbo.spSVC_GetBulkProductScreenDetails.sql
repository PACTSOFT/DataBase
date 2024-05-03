USE PACT2C222
GO
SET ANSI_NULLS, QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spSVC_GetBulkProductScreenDetails]
	@Type [int],
	@ID [bigint],
	@UserID [bigint],
	@LangID [int] = 1
WITH ENCRYPTION, EXECUTE AS CALLER
AS
BEGIN TRY  
SET NOCOUNT ON;
   
	--Declaration Section
	DECLARE @HasAccess BIT

	IF @Type=0 /*TO GET SCREEN DETAILS*/
	BEGIN
		SELECT C.CostCenterColID,R.ResourceData,C.UserColumnName,C.ResourceID,C.SysColumnName,C.UserColumnType,C.ColumnDataType,      
			C.UserDefaultValue,C.UserProbableValues,C.IsMandatory,C.IsEditable,C.IsVisible,C.ColumnCCListViewTypeID,      
			C.IsCostCenterUserDefined,C.IsColumnUserDefined,C.ColumnCostCenterID,C.FetchMaxRows,C.SectionID,C.SectionName      
		FROM ADM_CostCenterDef C WITH(NOLOCK)      
			LEFT JOIN COM_LanguageResources R WITH(NOLOCK) ON R.ResourceID=C.ResourceID AND R.LanguageID=1      
		WHERE C.CostCenterID = 3 AND C.IsColumnInUse=1 AND C.IsColumnUserDefined=1 AND C.UserColumnType IN ('TEXT','NUMERIC') --AND C.IsCostCenterUserDefined=0
			--AND (C.IsColumnUserDefined=1 AND C.IsColumnInUse=1 AND C.ISCOLUMNDELETED=0 AND C.IsCostCenterUserDefined=0)
		ORDER BY C.CostCenterColID

	END
	ELSE IF @Type=1 /*TO GET CATEGORIES INFO*/
	BEGIN
		DECLARE @CatID BIGINT,@SubCategory BIGINT

		SELECT @SubCategory=CCNID30 
		FROM COM_CCCCData WITH(NOLOCK)
		WHERE CostCenterID=50029 AND NodeID=@ID

		SELECT  CCNID6 CID,(SELECT TOP 1 Name FROM COM_Category WITH(NOLOCK) WHERE NodeID=CCNID6) Category,
				@SubCategory SCID,(SELECT TOP 1 Name FROM COM_CC50030 WITH(NOLOCK) WHERE NodeID=@SubCategory) [SubCategory] 
		FROM COM_CCCCData WITH(NOLOCK) 
		WHERE CostCenterID=50030 AND NodeID=@SubCategory

	END
	
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
SET NOCOUNT OFF  
RETURN -999   
END CATCH  

GO

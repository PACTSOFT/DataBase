USE PACT2C222
GO
SET ANSI_NULLS, QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[SPCRM_GetActivitiesCustomFields]
	@ParentCCCID [bigint],
	@NodeID [bigint],
	@UserName [nvarchar](50),
	@UserID [bigint],
	@LangID [int] = 1
WITH ENCRYPTION, EXECUTE AS CALLER
AS
BEGIN TRANSACTION
BEGIN TRY	
SET NOCOUNT ON;

	SELECT  C.CostCenterColID,R.ResourceData,C.UserColumnName,C.ResourceID,C.SysColumnName,C.UserColumnType,C.ColumnDataType,
	C.UserDefaultValue,C.UserProbableValues,isnull(C.IsMandatory,0) IsMandatory,isnull(C.IsEditable,1) IsEditable,isnull(C.IsVisible,0) IsVisible,C.ColumnCCListViewTypeID,      
	C.IsCostCenterUserDefined,C.IsColumnUserDefined,C.ColumnCostCenterID,C.FetchMaxRows,C.SectionID,C.SectionName , C.RowNo,C.ColumnNo, C.ColumnSpan,C.TextFormat,C.Iscolumninuse   
	FROM ADM_CostCenterDef C WITH(NOLOCK)      
	LEFT JOIN COM_LanguageResources R WITH(NOLOCK) ON R.ResourceID=C.ResourceID AND R.LanguageID=@LangID  
	WHERE C.CostCenterID = 144 and C.localreference = @ParentCCCID and C.IsColumnUserDefined=1
	AND (((C.IsColumnUserDefined=1 OR C.IsCostCenterUserDefined=1) AND C.IsColumnInUse=1 AND C.ISCOLUMNDELETED=0) OR C.IsColumnUserDefined=0)  
	ORDER BY C.SectionID,C.SectionSeqNumber   

	--cost center fields
	SELECT CostCenterColID,REPLACE(SysColumnName,'dc','') SysColumnName FROM ADM_COSTCENTERDEF C WITH(NOLOCK)    
	WHERE COSTCENTERID=@ParentCCCID AND (SysColumnName LIKE '%CCNID%' OR SysColumnName LIKE '%DCCCNID%') AND 
	((C.IsColumnUserDefined=1 OR C.IsCostCenterUserDefined=1) AND C.IsColumnInUse=1 AND C.ISCOLUMNDELETED=0) 

	SELECT CostCenterColIDBase,CostCenterColIDLinked FROM COM_DocumentLinkDetails with(nolock) WHERE   
	DocumentLinkDeFID IN (SELECT DocumentLinkDeFID FROM [COM_DocumentLinkDef]  with(nolock)
	WHERE CostCenterIDLinked=@ParentCCCID AND CostCenterIDBase=144)   

	if(@ParentCCCID>0)
	BEGIN
		if(@ParentCCCID between 40000 and 50000)
			select prefvalue Value,prefname Name from com_Documentpreferences  WITH(NOLOCK)
			where prefname in ('ActivityAsPopup','ActivityFields')  and costcenterid=@ParentCCCID
		else
			select Value,Name from com_costcenterpreferences  WITH(NOLOCK)
			where name in ('ActivityAsPopup','DisableDimensionsatActivities','UseActivityQuickAdd')  and costcenterid=@ParentCCCID
	END	
	else
		select '' Value,'' Name
	
	SELECT  C.CostCenterColID,R.ResourceData,C.UserColumnName,C.ResourceID,C.SysColumnName,C.UserColumnType,C.ColumnDataType,
	C.UserDefaultValue,C.UserProbableValues,isnull(C.IsMandatory,0) IsMandatory,isnull(C.IsEditable,1) IsEditable,isnull(C.IsVisible,0) IsVisible,C.ColumnCCListViewTypeID,      
	C.IsCostCenterUserDefined,C.IsColumnUserDefined,C.ColumnCostCenterID,C.FetchMaxRows,C.SectionID,C.SectionName,C.RowNo,C.ColumnNo,C.ColumnSpan,C.TextFormat,C.Iscolumninuse  
	,C.ShowInQuickAdd,C.QuickAddOrder 
	FROM ADM_CostCenterDef C WITH(NOLOCK)      
	LEFT JOIN COM_LanguageResources R WITH(NOLOCK) ON R.ResourceID=C.ResourceID AND R.LanguageID=@LangID  
	WHERE C.CostCenterID = 144 and C.localreference = @ParentCCCID AND C.IsColumnInUse=1 
	and C.ShowInQuickAdd=1
	ORDER BY C.QuickAddOrder
	
	
	if(@NodeID>0)	
		EXEC spCRM_GetFeatureByActvities @NodeID,@ParentCCCID,'',@UserID,@LangID	
	
COMMIT TRANSACTION
SET NOCOUNT OFF;
RETURN 1
END TRY
BEGIN CATCH  
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

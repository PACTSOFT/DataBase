USE PACT2C222
GO
SET ANSI_NULLS, QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spSVC_GetTicketIndentsQty]
	@Type [int],
	@TicketsID [bigint],
	@CCTicketsID [bigint],
	@UserID [int],
	@LangID [int]
WITH ENCRYPTION, EXECUTE AS CALLER
AS
BEGIN TRY  
SET NOCOUNT ON;  

	DECLARE @CCLink INT,@SQL NVARCHAR(MAX)
		,@IndentDocument NVARCHAR(10),@ReturnRequestDocument NVARCHAR(10),@MaterialIssueDocument NVARCHAR(10),@MaterialReturnDocument NVARCHAR(10)

	SELECT @CCLink=Value FROM COM_CostCenterPreferences WITH(NOLOCK) WHERE FeatureID=59 AND Name = 'ServiceTicketLinkCostCenter'
	IF @CCLink=0
	BEGIN
		SELECT 1 WHERE 1<>1
		ROLLBACK TRANSACTION
		RETURN 1
		--RAISERROR('-105',16,1) 
	END
	
	SET @CCLink=@CCLink-50000 
	
	SELECT @IndentDocument=Value FROM COM_CostCenterPreferences WITH(NOLOCK) WHERE FeatureID=59 AND Name = 'ServiceIndentDocument'
	SELECT @ReturnRequestDocument=Value FROM COM_CostCenterPreferences WITH(NOLOCK) WHERE FeatureID=59 AND Name = 'ServiceReturnRequestDocument'
	SELECT @MaterialIssueDocument=Value FROM COM_CostCenterPreferences WITH(NOLOCK) WHERE FeatureID=59 AND Name = 'ServiceMaterialIssueDocument'
	SELECT @MaterialReturnDocument=Value FROM COM_CostCenterPreferences WITH(NOLOCK) WHERE FeatureID=59 AND Name = 'ServiceMaterialReturnDocument'
	
	IF @Type=1
	BEGIN
		SET @SQL='SELECT ProductID,SUM(Quantity) ReqQty, C.DCCCNID29 PartID FROM INV_DocDetails T WITH(NOLOCK)
		INNER JOIN COM_DocCCData C WITH(NOLOCK) ON T.InvDocDetailsID=C.InvDocDetailsID 
		WHERE CostCenterID='+@IndentDocument+'
		AND dcCCNID'+CONVERT(NVARCHAR,@CCLink)+'='+CONVERT(NVARCHAR,@CCTicketsID)+' GROUP BY ProductID, C.DCCCNID29'
		EXEC(@SQL)
		
		SET @SQL='SELECT ProductID,SUM(Quantity) RetReqQty, C.DCCCNID29 PartID FROM INV_DocDetails T WITH(NOLOCK)
		INNER JOIN COM_DocCCData C WITH(NOLOCK) ON T.InvDocDetailsID=C.InvDocDetailsID
		WHERE CostCenterID='+@ReturnRequestDocument+'
		AND dcCCNID'+CONVERT(NVARCHAR,@CCLink)+'='+CONVERT(NVARCHAR,@CCTicketsID)+' GROUP BY ProductID, C.DCCCNID29'
		EXEC(@SQL)
		
		SET @SQL='SELECT ProductID,SUM(Quantity) IssueQty, C.DCCCNID29 PartID FROM INV_DocDetails T WITH(NOLOCK)
		INNER JOIN COM_DocCCData C WITH(NOLOCK) ON T.InvDocDetailsID=C.InvDocDetailsID
		WHERE CostCenterID='+@MaterialIssueDocument+'
		AND dcCCNID'+CONVERT(NVARCHAR,@CCLink)+'='+CONVERT(NVARCHAR,@CCTicketsID)+' GROUP BY ProductID, C.DCCCNID29'
		EXEC(@SQL)

		SET @SQL='SELECT ProductID,SUM(Quantity) RetQty , C.DCCCNID29 PartID FROM INV_DocDetails T WITH(NOLOCK)
		INNER JOIN COM_DocCCData C WITH(NOLOCK) ON T.InvDocDetailsID=C.InvDocDetailsID
		WHERE CostCenterID='+@MaterialReturnDocument+'
		AND dcCCNID'+CONVERT(NVARCHAR,@CCLink)+'='+CONVERT(NVARCHAR,@CCTicketsID)+' GROUP BY ProductID, C.DCCCNID29'
		EXEC(@SQL)
	END
	ELSE IF @Type=2
	BEGIN	 
		SET @SQL='SELECT T.VoucherNo,CONVERT(DATETIME,T.CreatedDate) ''Date'', Quantity IssReq,NULL Issued,NULL ReturnReq,NULL Returned, C.DCCCNID29 PartID
	 	FROM INV_DocDetails T WITH(NOLOCK)
		INNER JOIN COM_DocCCData C WITH(NOLOCK) ON T.InvDocDetailsID=C.InvDocDetailsID
		WHERE CostCenterID='+@IndentDocument+'
		AND dcCCNID'+CONVERT(NVARCHAR,@CCLink)+'='+CONVERT(NVARCHAR,@CCTicketsID)+' AND ProductID='+CONVERT(NVARCHAR,@TicketsID)+'
		UNION ALL
		SELECT T.VoucherNo,CONVERT(DATETIME,T.CreatedDate) ''Date'',NULL,NULL,Quantity,NULL , C.DCCCNID29 PartID
 		FROM INV_DocDetails T WITH(NOLOCK)
		INNER JOIN COM_DocCCData C WITH(NOLOCK) ON T.InvDocDetailsID=C.InvDocDetailsID
		WHERE CostCenterID='+@ReturnRequestDocument+'
		AND dcCCNID'+CONVERT(NVARCHAR,@CCLink)+'='+CONVERT(NVARCHAR,@CCTicketsID)+' AND ProductID='+CONVERT(NVARCHAR,@TicketsID)+'
		UNION ALL
		SELECT T.VoucherNo,CONVERT(DATETIME,T.CreatedDate) ''Date'', NULL,Quantity,NULL,NULL, C.DCCCNID29 PartID
 		FROM INV_DocDetails T WITH(NOLOCK)
		INNER JOIN COM_DocCCData C WITH(NOLOCK) ON T.InvDocDetailsID=C.InvDocDetailsID
		WHERE CostCenterID='+@MaterialIssueDocument+'
		AND dcCCNID'+CONVERT(NVARCHAR,@CCLink)+'='+CONVERT(NVARCHAR,@CCTicketsID)+' AND ProductID='+CONVERT(NVARCHAR,@TicketsID)+'
		UNION ALL
		SELECT T.VoucherNo,CONVERT(DATETIME,T.CreatedDate) ''Date'',NULL,NULL,NULL,Quantity , C.DCCCNID29 PartID
 		FROM INV_DocDetails T WITH(NOLOCK)
		INNER JOIN COM_DocCCData C WITH(NOLOCK) ON T.InvDocDetailsID=C.InvDocDetailsID
		WHERE CostCenterID='+@MaterialReturnDocument+'
		AND dcCCNID'+CONVERT(NVARCHAR,@CCLink)+'='+CONVERT(NVARCHAR,@CCTicketsID)+' AND ProductID='+CONVERT(NVARCHAR,@TicketsID)+'
		ORDER BY Date'
		--PRINT @SQL
		EXEC(@SQL)
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
		SELECT ErrorMessage, ERROR_MESSAGE() AS ServerMessage,ERROR_NUMBER() AS ErrorNumber, ERROR_PROCEDURE()AS ProcedureName, ERROR_LINE() AS ErrorLine
		FROM COM_ErrorMessages WITH(NOLOCK) WHERE ErrorNumber=-999 AND LanguageID=@LangID
	END
 
SET NOCOUNT OFF  
RETURN -999
END CATCH
GO

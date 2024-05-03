USE PACT2C222
GO
SET ANSI_NULLS, QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spCRM_GetOpportunityDocuments]
	@OpportunityID [bigint] = 0,
	@DocumentID [bigint] = 0,
	@UserID [bigint],
	@LangID [int] = 1
WITH ENCRYPTION, EXECUTE AS CALLER
AS
BEGIN TRANSACTION
BEGIN TRY  
SET NOCOUNT ON;    


--SELECT     I.DocID, I.CostCenterID, I.VoucherNo, CONVERT(DATETIME, I.DocDate) AS DocDate, D.DocumentName, I.DocPrefix, I.DocNumber,I.Gross as Amount,C.Name,S.Status
--FROM         INV_DocDetails AS I INNER JOIN
--                      ADM_DocumentTypes AS D ON I.DocumentTypeID = D.DocumentTypeID INNER JOIN
--					  COM_Currency As C On I.CurrencyID=C.CurrencyID INNER JOIN 
--					  COM_Status As S ON I.StatusID=S.StatusID
--GROUP BY I.DocDate, I.VoucherNo, D.DocumentName, I.DocPrefix, I.DocNumber, I.DocID, I.CostCenterID,I.Gross,C.Name,S.Status

		
	IF @DOCUMENTID=0
	BEGIN	
       CREATE TABLE #TBL(ID INT IDENTITY(1,1),DOCID BIGINT,DOCNAME NVARCHAR(MAX))
		DECLARE @DATA NVARCHAR(MAX),@DOCID BIGINT,@DOCNAME NVARCHAR(300)

		SET @DATA=(SELECT Value FROM COM_CostCenterPreferences WITH(NOLOCK) WHERE Name='DocumentTypes' and CostCenterID=89) 

		INSERT INTO #TBL(DOCID)
		EXEC SPSPLITSTRING @DATA,';'

		DECLARE @I INT,@COUNT INT
		SELECT @COUNT=COUNT(*) FROM #TBL
		SET @I=1
		WHILE @I<=@COUNT
		BEGIN
			SELECT @DOCID=DOCID FROM #TBL WHERE ID=@I 
			SELECT @DOCNAME=DocumentName FROM ADM_DocumentTypes WITH(NOLOCK) WHERE CostCenterID=@DOCID 
			UPDATE #TBL SET DOCNAME=@DOCNAME
			WHERE DOCID=@DOCID
			SET @I=@I+1
		END

		SELECT * FROM #TBL
		DROP TABLE #TBL 
	END
	ELSE
	BEGIN

    DECLARE @INDEXID BIGINT, @CCID BIGINT,@SQL NVARCHAR(MAX),@TABLENAME NVARCHAR(300)
	SELECT @CCID=Value FROM  COM_CostCenterPreferences WHERE FeatureID=89 AND Name='OppLinkDimension'
	SET @INDEXID=@CCID-50000
	 SELECT @TABLENAME=TABLENAME FROM ADM_Features WHERE FEATUREID=@CCID
	 SET @SQL='
	 SELECT     I.DocID, I.CostCenterID, I.VoucherNo, CONVERT(DATETIME, I.DocDate) AS DocDate, D.DocumentName, I.DocPrefix, I.DocNumber,I.Gross as Amount,C.Name,S.Status
	 FROM         INV_DocDetails AS I INNER JOIN
						  ADM_DocumentTypes AS D ON I.DocumentTypeID = D.DocumentTypeID INNER JOIN
						  COM_Currency As C On I.CurrencyID=C.CurrencyID INNER JOIN 
						  COM_Status As S ON I.StatusID=S.StatusID
						  LEFT JOIN INV_Product P ON P.ProductID=I.ProductID 
						  LEFT JOIN COM_DocCCData CC ON CC.InvDocDetailsID=I.InvDocDetailsID
						  LEFT JOIN '+@TABLENAME+' E ON E.NODEID=CC.dcCCNID'+CONVERT(VARCHAR,@INDEXID)+'
	WHERE D.CostCenterID='+CONVERT(VARCHAR,@DOCUMENTID)+ '
    AND E.NODEID IN (SELECT CCOpportunityID FROM CRM_Opportunities WHERE OpportunityID = '''+Convert(nvarchar,@OpportunityID)+''') '	
	EXEC (@SQL)
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

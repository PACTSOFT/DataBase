USE PACT2C222
GO
SET ANSI_NULLS, QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spRPT_TechnicianJobs]
	@FromDate [datetime],
	@ToDate [datetime],
	@CCWHERE [nvarchar](max),
	@LangID [int]
WITH ENCRYPTION, EXECUTE AS CALLER
AS
BEGIN TRY  
SET NOCOUNT ON;  

	DECLARE @SQL NVARCHAR(MAX),@JOBCOLUMN NVARCHAR(MAX)
	DECLARE	@From NVARCHAR(20),@To NVARCHAR(20)
	DECLARE @SQL1 NVARCHAR(MAX),@SQL2 NVARCHAR(MAX),@UnAppSQL NVARCHAR(MAX),@strPDCWhere NVARCHAR(MAX),@strOpeningPDCWhere NVARCHAR(MAX)
	DECLARE @ParticularCr NVARCHAR(350), @ParticularDr NVARCHAR(350)
	DECLARE @DimColumn NVARCHAR(50),@DimColAlias1 NVARCHAR(50),@DimColAlias2 NVARCHAR(50),@DimJoin NVARCHAR(100),@DimOrderBy NVARCHAR(50)
	
	SET @From=CONVERT(NVARCHAR,CONVERT(FLOAT,@FromDate))
	SET @To=CONVERT(NVARCHAR,CONVERT(FLOAT,@ToDate))
	--<Run FontWeight="Bold"></Run>CONVERT(DATETIME,108
	SET @JOBCOLUMN='''<FlowDocument><Paragraph>JobNo : ''+Job.Name+''</Paragraph><Run>Customer Name : ''+CUST.AccountName+''</Run>
	<Run>Location : ''+L.Name+''</Run>
	<Run>Sub-Location : ''+SL.Name+''</Run>
	<Run>Start Time : ''+ISNULL(CONVERT(NVARCHAR,CONVERT(DATETIME,TXT.dcAlpha11),108),'''')+''</Run>
	<Run>End Time : ''+ISNULL(CONVERT(NVARCHAR,CONVERT(DATETIME,TXT.dcAlpha8),108),'''')+''</Run>
	</FlowDocument>'''
	
	SET @SQL='	
	SELECT TXT.InvDocDetailsID,INV.VoucherNo, Tech.Name Technician,Job.Name JobNo,CUST.AccountName Customer
	,L.Name Location,SL.Name SubLocation,CONVERT(DATETIME,TXT.dcAlpha8) WS_ST,CONVERT(DATETIME,TXT.dcAlpha11) WS_ET
	,'+@JOBCOLUMN+'	JOB1
	FROM INV_DocDetails INV with(nolock)
	,COM_DocCCData DCC with(nolock)
	,COM_CC50024 Tech with(nolock)
	,COM_CC50009 Job with(nolock)
	,ACC_Accounts CUST with(nolock)
	,COM_Location L with(nolock)
	,COM_CC50011 SL with(nolock)
	,COM_DocTextData TXT with(nolock)
	WHERE INV.DocDate>='+@From+' AND INV.DocDate<='+@To+'
	AND INV.CostCenterID=41107 AND INV.InvDocDetailsID=DCC.InvDocDetailsID
	AND DCC.dcCCNID24=Tech.NodeID
	AND DCC.dcCCNID9=Job.NodeID
	AND INV.DebitAccount=CUST.AccountID
	AND DCC.dcCCNID2=L.NodeID
	AND DCC.dcCCNID11=SL.NodeID
	AND INV.INVDOCDETAILSID=TXT.INVDOCDETAILSID
	'+@CCWHERE+'
	ORDER BY Tech.Name,WS_ST DESC'--Job.NodeID 

	PRINT(@SQL)
	EXEC(@SQL)

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

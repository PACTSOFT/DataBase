﻿USE PACT2C222
GO
SET ANSI_NULLS, QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spDOC_GetBarcodeDocumentsData]
	@DocumentID [bigint],
	@DocumentSeqNo [nvarchar](max),
	@GroupNodeExists [bit],
	@SelectedColsQuery [nvarchar](max),
	@JoinsQuery [nvarchar](max),
	@UserID [bigint],
	@UserName [nvarchar](50),
	@LangID [int] = 1
WITH ENCRYPTION, EXECUTE AS CALLER
AS
BEGIN TRY  
SET NOCOUNT ON;

	--Declaration Section
	DECLARE @SQL NVARCHAR(MAX),@GTPQuery nvarchar(max),@GTPWhere nvarchar(max)
	DECLARE @SELECTSQL NVARCHAR(MAX), @FROMSQL NVARCHAR(MAX)
	
	SET @SELECTSQL=@SelectedColsQuery
	SET @FROMSQL=@JoinsQuery
	
	IF LEN(@SELECTSQL)>0
		SET @SELECTSQL= @SELECTSQL+','
		
IF(@DocumentID>40000 and @DocumentID<50000)
BEGIN
	if @FROMSQL not like '%INV_Product%'
		set @FROMSQL=' LEFT JOIN INV_Product P WITH(NOLOCK) ON P.ProductID=D.ProductID'+@FROMSQL

	SET @SQL='SELECT CASE WHEN D.DynamicInvDocDetailsID IS NULL THEN D.DocSeqNo ELSE (SELECT TOP 1 DocSeqNo FROM INV_DocDetails WITH(NOLOCK) WHERE InvDocDetailsID=D.DynamicInvDocDetailsID) END SeqNo,
	'+@SELECTSQL+'
	D.DocID,D.ProductID,D.DynamicInvDocDetailsID,D.BillNo,D.VoucherNo,D.VoucherType,D.DebitAccount,D.CreditAccount,
	CONVERT(DATETIME,D.DocDate) DocDate,D.DocAbbr,D.DocPrefix [Doc Prefix],D.DocNumber [Doc Serial No],
	CONVERT(DATETIME,D.DueDate) DueDate,
	D.Quantity,D.Rate,D.HoldQuantity,D.AverageRate,D.Gross,D.CommonNarration,D.LineNarration,
	D.CreatedBy,CONVERT(DATETIME,D.CreatedDate) CreatedDate,
	D.ModifiedBy,CONVERT(DATETIME,D.ModifiedDate) ModifiedDate,
	(select voucherno from inv_docdetails WITH(NOLOCK) where InvDocDetailsID=D.LinkedInvDocDetailsID) [RefNo],
	C.Name CurrencyID,S.Status,D.ExchangeRate [ExchangeRate],
	LD.VoucherNo LinkDocNo,CONVERT(DATETIME,LD.DocDate) LinkDocDate,LD.DocAbbr LinkDocAbbr,LD.DocPrefix LinkDocPrefix,LD.DocNumber LinkDocSerialNo,LD.CommonNarration LinkCommonNarration,LD.LineNarration LinkLineNarration,
	LD.DocPrefix+''-''+LD.DocNumber as LinkSerialNoWithPrefix,
	LDR.AccountCode LinkDrAccountCode,LDR.AccountName LinkDrAccountName,LDR.AliasName LinkDrAccountAlias,
	LCR.AccountCode LinkCrAccountCode,LCR.AccountName LinkCrAccountName,LCR.AliasName LinkCrAccountAlias,
	T.*,N.*,UOM.BaseName Unit,
	B.BatchNumber Batch_No, B.BatchCode Batch_Code,CONVERT(DATETIME,B.MfgDate) Batch_MfgDate,CONVERT(DATETIME,B.ExpiryDate) Batch_ExpDate
	FROM INV_DocDetails D WITH(NOLOCK) LEFT JOIN
	INV_DocDetails LD WITH(NOLOCK) ON LD.InvDocDetailsID=D.LinkedInvDocDetailsID LEFT JOIN 	
	COM_DocCCData WITH(NOLOCK) ON COM_DocCCData.InvDocDetailsID=D.InvDocDetailsID LEFT JOIN 
	ACC_Accounts LDR WITH(NOLOCK) ON LDR.AccountID=LD.DebitAccount LEFT JOIN
	ACC_Accounts LCR WITH(NOLOCK) ON LCR.AccountID=LD.CreditAccount LEFT JOIN				
	COM_DocTextData T WITH(NOLOCK) ON T.InvDocDetailsID=D.InvDocDetailsID LEFT JOIN
	COM_DocNumData N WITH(NOLOCK) ON N.InvDocDetailsID=D.InvDocDetailsID LEFT JOIN
	INV_Batches AS B with(nolock) ON D.BatchID = B.BatchID LEFT JOIN 
	COM_Currency C WITH(NOLOCK) ON C.CurrencyID=D.CurrencyID LEFT JOIN
	COM_Status S WITH(NOLOCK) ON S.StatusID=D.StatusID LEFT JOIN 
	COM_UOM UOM WITH(NOLOCK) on D.Unit=UOM.UOMID'+@FROMSQL+'	
	WHERE P.ManufacturerBarcode<>1'
	if @DocumentSeqNo like '%,%'
		SET @SQL=@SQL+' AND D.DocID IN('+@DocumentSeqNo+')'
	else
		SET @SQL=@SQL+' AND D.DocID='+@DocumentSeqNo

	SET @SQL=@SQL+' AND D.DynamicInvDocDetailsID IS NULL'
	
	if(@SELECTSQL like '%PCK.label PCKLabel%')
	begin
		set @SQL=replace(@SQL,'PCK.label PCKLabel','PCK.label PCKLabel,case when isnumeric(PCK.label)=1 then convert(int,PCK.label) else 0 end PKLblOrd')
		set @SQL=@SQL+' ORDER BY PKLblOrd,PCKLabel'
	end
	else
		SET @SQL=@SQL+' ORDER BY D.DocID,D.DocSeqNo,D.InvDocDetailsID'
END
ELSE IF (@DocumentID=3)
BEGIN
	if @GroupNodeExists=1
	begin
		set @GTPWhere='P.ProductID=GTP.GTID AND P.IsGroup=0'
        if @DocumentSeqNo like '%,%'
			set @GTPQuery=',(select T.ProductID GTID from INV_Product T with(nolock),INV_Product GT1 with(nolock) where T.lft BETWEEN GT1.lft AND GT1.rgt AND GT1.ProductID IN ('+@DocumentSeqNo+') group by T.ProductID) AS GTP '
		else
			set @GTPQuery=',(select T.ProductID GTID from INV_Product T with(nolock),INV_Product GT1 with(nolock) where T.lft BETWEEN GT1.lft AND GT1.rgt AND GT1.ProductID='+@DocumentSeqNo+' group by T.ProductID) AS GTP '
	end
	else
    begin
		set @GTPQuery=''
		if @DocumentSeqNo like '%,%'
			set @GTPWhere='P.ProductID IN ('+@DocumentSeqNo+')'
        else
			set @GTPWhere='P.ProductID='+@DocumentSeqNo
	end
	
	SET @SQL='SELECT '+@SELECTSQL+'P.*
	FROM INV_Product P WITH(NOLOCK) 
	LEFT JOIN COM_CCCCData as COM_DocCCData WITH(NOLOCK) on COM_DocCCData.CostCenterID=3 AND COM_DocCCData.NodeID=P.ProductID
	'
	SET @SQL=@SQL+@FROMSQL+@GTPQuery
	SET @SQL=@SQL+' WHERE P.ManufacturerBarcode<>1 AND '+@GTPWhere	
END
ELSE IF (@DocumentID=2)
BEGIN	
	if @GroupNodeExists=1
	begin
		set @GTPWhere='A.AccountID=GTP.GTID AND A.IsGroup=0'
        if @DocumentSeqNo like '%,%'
			set @GTPQuery=',(select T.AccountID GTID from ACC_Accounts T with(nolock),ACC_Accounts GT1 with(nolock) where T.lft BETWEEN GT1.lft AND GT1.rgt AND GT1.AccountID IN ('+@DocumentSeqNo+') group by T.AccountID) AS GTP '
		else
			set @GTPQuery=',(select T.AccountID GTID from ACC_Accounts T with(nolock),ACC_Accounts GT1 with(nolock) where T.lft BETWEEN GT1.lft AND GT1.rgt AND GT1.AccountID='+@DocumentSeqNo+' group by T.AccountID) AS GTP '
	end
	else
    begin
		set @GTPQuery=''
		if @DocumentSeqNo like '%,%'
			set @GTPWhere='A.AccountID IN ('+@DocumentSeqNo+')'
        else
			set @GTPWhere='A.AccountID='+@DocumentSeqNo
	end
	
	SET @SQL='SELECT '+@SELECTSQL+'A.*
	FROM ACC_ACCOUNTS A WITH(NOLOCK) 
	LEFT JOIN COM_CCCCData as COM_DocCCData WITH(NOLOCK) on COM_DocCCData.CostCenterID=2 AND COM_DocCCData.NodeID=A.AccountID '
	SET @SQL=@SQL+@FROMSQL+@GTPQuery
	SET @SQL=@SQL+' WHERE '+@GTPWhere
END
ELSE IF (@DocumentID=72 or @DocumentID>=50001)
BEGIN
	DECLARE @TblName NVARCHAR(50),@PK NVARCHAR(10)
	SELECT @TblName=TableName,@PK=PrimaryKey FROM ADM_Features with(nolock) WHERE FeatureID=@DocumentID
	if @GroupNodeExists=1
	begin
		set @GTPWhere='A.'+@PK+'=GTP.GTID AND A.IsGroup=0'
        if @DocumentSeqNo like '%,%'
			set @GTPQuery=',(select T.'+@PK+' GTID from '+@TblName+' T with(nolock),'+@TblName+' GT1 with(nolock) where T.lft BETWEEN GT1.lft AND GT1.rgt AND GT1.'+@PK+' IN ('+@DocumentSeqNo+') group by T.'+@PK+') AS GTP '
		else
			set @GTPQuery=',(select T.'+@PK+' GTID from '+@TblName+' T with(nolock),'+@TblName+' GT1 with(nolock) where T.lft BETWEEN GT1.lft AND GT1.rgt AND GT1.'+@PK+'='+@DocumentSeqNo+' group by T.'+@PK+') AS GTP '
	end
	else
    begin
		set @GTPQuery=''
		if @DocumentSeqNo like '%,%'
			set @GTPWhere='A.'+@PK+' IN ('+@DocumentSeqNo+')'
        else
			set @GTPWhere='A.'+@PK+'='+@DocumentSeqNo
	end
	
	SET @SQL='SELECT '+@SELECTSQL+'A.*
	FROM '+@TblName+' A WITH(NOLOCK) 
	LEFT JOIN COM_CCCCData as COM_DocCCData WITH(NOLOCK) on COM_DocCCData.CostCenterID='+convert(nvarchar,@DocumentID)+' AND COM_DocCCData.NodeID=A.'+@PK
	SET @SQL=@SQL+@FROMSQL+@GTPQuery
	SET @SQL=@SQL+' WHERE '+@GTPWhere
END

PRINT(@SQL)
EXEC(@SQL)


	
		

IF @DocumentID>40000 and @DocumentID<50000
BEGIN
	--SERIAL NOS
	SELECT D.InvDocDetailsID,S.SerialNumber Product_SerialNumbers,S.*
	FROM INV_SerialStockProduct AS S with(nolock) 
	INNER JOIN Inv_DocDetails D with(nolock) ON D.InvDocDetailsID=S.InvDocDetailsID
	WHERE D.DocID=@DocumentSeqNo
	order by S.SerialProductID
	
	
	--CHECK AUDIT TRIAL ALLOWED AND INSERTING AUDIT TRIAL DATA
	DECLARE @AuditTrial BIT
	SET @AuditTrial=0
	SELECT @AuditTrial=CONVERT(BIT,PrefValue)  FROM [COM_DocumentPreferences] WITH(NOLOCK)
	WHERE CostCenterID=@DocumentID AND PrefName='AuditTrial'

	IF @AuditTrial=1
	BEGIN
		SET @SQL='INSERT INTO INV_DocDetails_History_ATUser(DocType,DocID,VoucherNo,ActionType,ActionTypeID,UserID,CreatedBy,CreatedDate)
		SELECT '+convert(nvarchar,@DocumentID)+',DocID,VoucherNo,''Barcode'',2,'+convert(nvarchar,@UserID)+','''+@UserName+''',CONVERT(FLOAT,GETDATE())
		 FROM INV_DocDetails WITH(NOLOCK) WHERE DocID IN ('+@DocumentSeqNo+')'
		EXEC(@SQL)
	END
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

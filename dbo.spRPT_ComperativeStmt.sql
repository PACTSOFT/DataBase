USE PACT2C222
GO
SET ANSI_NULLS, QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spRPT_ComperativeStmt]
	@EnquiryVoucher [nvarchar](max),
	@EnquirySELECT [nvarchar](max),
	@EnquiryFROM [nvarchar](max),
	@EnqWHERE [nvarchar](max),
	@QuotationDocument [int],
	@QTNComparisonDocument [int],
	@PODocument [int],
	@QtnSELECT [nvarchar](max),
	@QtnFROM [nvarchar](max),
	@QtnCompQty [nvarchar](30),
	@QtnCompStatus [nvarchar](30),
	@strExtraFields [nvarchar](max),
	@CalcAvgRate [nvarchar](max),
	@LocationWHERE [nvarchar](max) = NULL,
	@LinkedInvDocDetailsIDs [nvarchar](max),
	@ShowQtnAddOn [bit],
	@LangID [int]
WITH ENCRYPTION, EXECUTE AS CALLER
AS
BEGIN TRY  
SET NOCOUNT ON;  

	DECLARE @SQL NVARCHAR(MAX),@DetailsIDs NVARCHAR(MAX)
	DECLARE @TblProd AS TABLE(ID INT NOT NULL IDENTITY(1,1), ProductID BIGINT,AvgRate FLOAT)
	DECLARE @I INT,@CNT INT,@ProductID BIGINT,@BalQty FLOAT,@AvgRate FLOAT,@BalValue FLOAT,@COGS FLOAT,@Dt DATETIME
	
	IF (@LinkedInvDocDetailsIDs<>'')
	BEGIN
		DECLARE @TblDocs AS TABLE(ID INT NOT NULL IDENTITY(1,1), CostCenterID INT,VoucherNo nvarchar(50),ParentVoucherNo nvarchar(50),DetailsID bigint,LinkedDetailsID bigint)
		SET @SQL='select D.CostCenterID,D.VoucherNo,P.VoucherNo,D.InvDocDetailsID,D.LinkedInvDocDetailsID
		FROM INV_DocDetails D with(nolock) 
		LEFT JOIN INV_DocDetails P with(nolock) ON P.InvDocDetailsID=D.LinkedInvDocDetailsID
		WHERE D.InvDocDetailsID IN ('+@LinkedInvDocDetailsIDs+')'
		
		INSERT INTO @TblDocs(CostCenterID,VoucherNo,ParentVoucherNo,DetailsID,LinkedDetailsID)
		EXEC (@SQL)
		
		SET @I=0
			
		WHILE(1=1)
		BEGIN		
			SET @CNT=(SELECT Count(*) FROM @TblDocs)
			
			INSERT INTO @TblDocs(CostCenterID,VoucherNo,ParentVoucherNo,DetailsID,LinkedDetailsID)
			select D.CostCenterID,D.VoucherNo,P.VoucherNo,D.InvDocDetailsID,D.LinkedInvDocDetailsID
			FROM INV_DocDetails D with(nolock) 
			INNER JOIN @TblDocs T on T.LinkedDetailsID=D.InvDocDetailsID AND T.ID>@I
			LEFT JOIN INV_DocDetails P with(nolock) ON P.InvDocDetailsID=D.LinkedInvDocDetailsID
			LEFT JOIN @TblDocs TD on TD.VoucherNo=D.VoucherNo AND TD.ParentVoucherNo=P.VoucherNo
			WHERE T.ParentVoucherNo!='-1' and TD.VoucherNo IS NULL and D.CostCenterID>0
			
			IF @CNT=(SELECT Count(*) FROM @TblDocs)
				BREAK			
			SET @I=@CNT
		END

		SET @I=0
		WHILE(1=1)
		BEGIN		
			SET @CNT=(SELECT Count(*) FROM @TblDocs)
			
			IF @I=0
				INSERT INTO @TblDocs(CostCenterID,VoucherNo,ParentVoucherNo,DetailsID,LinkedDetailsID)
				SELECT distinct INV.CostCenterID,INV.VoucherNo,TINV.VoucherNo,INV.InvDocDetailsID,INV.LinkedInvDocDetailsID
				FROM INV_DocDetails INV with(nolock) 
				INNER JOIN INV_DocDetails TINV with(nolock) on TINV.InvDocDetailsID=INV.LinkedInvDocDetailsID
				INNER JOIN @TblDocs T ON TINV.VoucherNo=T.VoucherNo AND ID>@I and ID=1
				LEFT JOIN @TblDocs TD on TD.DetailsID=INV.LinkedInvDocDetailsID AND TD.ParentVoucherNo=TINV.VoucherNo
				where TD.VoucherNo IS NULL and INV.CostCenterID>0
			ELSE
				INSERT INTO @TblDocs(CostCenterID,VoucherNo,ParentVoucherNo,DetailsID,LinkedDetailsID)
				SELECT distinct INV.CostCenterID,INV.VoucherNo,TINV.VoucherNo,INV.InvDocDetailsID,INV.LinkedInvDocDetailsID
				FROM INV_DocDetails INV with(nolock) 
				INNER JOIN INV_DocDetails TINV with(nolock) on TINV.InvDocDetailsID=INV.LinkedInvDocDetailsID
				INNER JOIN @TblDocs T ON TINV.VoucherNo=T.VoucherNo AND ID>@I and ID<=@CNT
				LEFT JOIN @TblDocs TD on TD.DetailsID=INV.LinkedInvDocDetailsID AND TD.ParentVoucherNo=TINV.VoucherNo
				where TD.VoucherNo IS NULL and INV.CostCenterID>0
			
			IF @CNT=(SELECT Count(*) FROM @TblDocs)
				BREAK			
			SET @I=@CNT
		END
		
		SET @DetailsIDs=STUFF((SELECT ','+CONVERT(NVARCHAR,DetailsID)
		FROM @TblDocs WHERE VoucherNo IN (REPLACE(@EnquiryVoucher,'''',''))
		FOR XML PATH('')),1,1,'') 
	END
	
	SET @SQL=' SELECT D.InvDocDetailsID,D.VoucherNo,CONVERT(DATETIME,D.DocDate) DocDate,P.ProductID,docid,costcenterid,
P.ProductCode,P.ProductName,U.UnitName Units,D.Quantity,D.Rate,D.[Gross],dbo.fnRPT_ExeQtyByDoc(D.CostCenterID,D.InvDocDetailsID,'+convert(nvarchar,@PODocument)+',null,0) ExeQty'+@EnquirySELECT+'
FROM INV_DocDetails D with(nolock)
INNER JOIN INV_Product P with(nolock) ON P.ProductID = D.ProductID
LEFT JOIN COM_UOM U with(nolock) ON U.UOMID = D.Unit '+@EnquiryFROM

	if CHARINDEX('DCC.dcCCNID',@EnqWHERE)>0 and CHARINDEX('COM_DocCCData DCC', @EnquiryFROM)=0
	begin
		SET @SQL=@SQL+' INNER JOIN COM_DocCCData DCC WITH(NOLOCK) ON DCC.InvDocDetailsID=D.InvDocDetailsID'
	end 

	SET @SQL=@SQL+' WHERE D.VoucherNo IN ('+@EnquiryVoucher+')'+@EnqWHERE
	
	if(@DetailsIDs IS NOT NULL AND @DetailsIDs<>'')
		SET @SQL=@SQL+' AND D.InvDocDetailsID IN ('+@DetailsIDs+')'
		
	EXEC(@SQL)
--	print(@SQL)

select @QtnSELECT=@QtnSELECT+',(select Name from com_lookup with(nolock) where NodeID=T.'+sysColumnName+') '+sysColumnName
from adm_costcenterdef where costcenterid=@QuotationDocument and ColumnCostCenterID=44 and IsColumnInUse=1 and SysTableName='COM_DocTextData'


	SET @SQL=' 
DECLARE @I INT,@CNT INT
DECLARE @Tbl AS TABLE(ID INT NOT NULL IDENTITY(1,1), DetailsID BIGINT,CostCenterID INT,LinkedInvDocDetailsID BIGINT,QDocID BIGINT)
INSERT INTO @Tbl(DetailsID,CostCenterID,LinkedInvDocDetailsID,QDocID)
SELECT D.[InvDocDetailsID],D.CostCenterID,NULL,D.DocID FROM [INV_DocDetails] D with(nolock)'
	if CHARINDEX('DCC.dcCCNID',@EnqWHERE)>0
	begin
		SET @SQL=@SQL+' INNER JOIN COM_DocCCData DCC WITH(NOLOCK) ON DCC.InvDocDetailsID=D.InvDocDetailsID'
	end 

	SET @SQL=@SQL+' WHERE D.VoucherNo IN ('+@EnquiryVoucher+')'+@EnqWHERE
	
	if(@DetailsIDs IS NOT NULL AND @DetailsIDs<>'')
		SET @SQL=@SQL+' AND D.InvDocDetailsID IN ('+@DetailsIDs+')'
		
SET @SQL=@SQL+' SET @I=0
WHILE(1=1)
BEGIN
	SET @CNT=(SELECT Count(*) FROM @Tbl)
	INSERT INTO @Tbl(DetailsID,CostCenterID,LinkedInvDocDetailsID,QDocID)
	SELECT INV.InvDocDetailsID,INV.CostCenterID,CASE WHEN T.LinkedInvDocDetailsID IS NULL THEN INV.LinkedInvDocDetailsID ELSE T.LinkedInvDocDetailsID END,INV.DocID
	FROM INV_DocDetails INV with(nolock) INNER JOIN @Tbl T ON INV.LinkedInvDocDetailsID=T.DetailsID AND ID>@I
	
	IF @CNT=(SELECT Count(*) FROM @Tbl)
		BREAK
	SET @I=@CNT
END

SELECT D.CostCenterID, D.InvDocDetailsID,TBL.LinkedInvDocDetailsID,D.VoucherNo,CONVERT(DATETIME,D.DocDate) DocDate,P.ProductID,P.ProductName,U.UnitName
,D.Quantity,D.Rate,D.Gross,D.CreditAccount,Cr.AccountName CreditAccountName,D.DocID'
if(@QTNComparisonDocument>0)
	SET @SQL=@SQL+',dbo.fnRPT_ExeQtyByDoc(D.CostCenterID,D.InvDocDetailsID,'+convert(nvarchar,@QTNComparisonDocument)+',null,0) ExeQty'
SET @SQL=@SQL+@QtnSELECT+',N.*,T.*
FROM [INV_DocDetails] D with(nolock)'
if @ShowQtnAddOn=1
begin
	SET @SQL=@SQL+' LEFT '
end
SET @SQL=@SQL+'JOIN @Tbl TBL ON TBL.DetailsID=D.InvDocDetailsID AND TBL.CostCenterID='+convert(nvarchar,@QuotationDocument)+@QtnFROM+'
INNER JOIN INV_Product P with(nolock) ON P.ProductID = D.ProductID
INNER JOIN ACC_Accounts CR with(nolock) ON CR.AccountID = D.CreditAccount
LEFT JOIN COM_UOM U with(nolock) ON U.UOMID = D.Unit
INNER JOIN COM_DocNumData N with(nolock) ON N.InvDocDetailsID= D.InvDocDetailsID
INNER JOIN COM_DocTextData T with(nolock) ON T.InvDocDetailsID= D.InvDocDetailsID'
if @ShowQtnAddOn=1
begin
	SET @SQL=@SQL+'
WHERE D.DocID IN (select QDocID from @Tbl where CostCenterID='+convert(nvarchar,@QuotationDocument)+')'
end
SET @SQL=@SQL+'
ORDER BY D.DocNumber
'
if(@QTNComparisonDocument>0)
begin
	set @SQL=@SQL+' select D.InvDocDetailsID,DocID,VoucherNo,D.StatusID,D.LinkedInvDocDetailsID,dbo.fnRPT_ExeQtyByDoc(D.CostCenterID,D.InvDocDetailsID,'+convert(nvarchar,@PODocument)+',null,0) POQty'+@QtnCompQty
	--if @QtnCompStatus like '%dcAlpha%'
	--	set @SQL=@SQL+','+@QtnCompStatus+' SelectedStatus'
	
	set @SQL=@SQL+' from INV_DocDetails D with(nolock)'
	if @QtnCompQty like '%dcNum%'
		set @SQL=@SQL+' INNER JOIN COM_DocNumData N  with(nolock) ON N.InvDocDetailsID=D.InvDocDetailsID'
	if @QtnCompStatus like '%dcAlpha%'
		set @SQL=@SQL+' INNER JOIN COM_DocTextData TXT  with(nolock) ON TXT.InvDocDetailsID=D.InvDocDetailsID'
	set @SQL=@SQL+' INNER JOIN @Tbl TBL ON TBL.DetailsID=D.InvDocDetailsID AND TBL.CostCenterID='+convert(nvarchar,@QTNComparisonDocument)
	--if @QtnCompStatus like '%dcAlpha%'
	--	set @SQL=@SQL+' WHERE '+@QtnCompStatus+'=''SELECTED'''
	--else
	--	set @SQL=@SQL+' WHERE 1!=1'
end
else
begin
	SET @SQL=@SQL+' select 1 ''Comparison'' where 1!=1'
end
print(@SQL)
EXEC(@SQL)

	
	SET @SQL=' SELECT UserColumnName ,C.SysColumnName--,C.CostCenterColID	 
FROM ADM_CostCenterDef C with(nolock)
WHERE C.CostCenterID='+convert(nvarchar,@QuotationDocument)+' AND C.SysColumnName IN ('+@strExtraFields+')'
	EXEC(@SQL)
	
	
	IF @CalcAvgRate=1
	BEGIN		
		INSERT INTO @TblProd(ProductID)
		SELECT D.ProductID
		FROM INV_DocDetails D with(nolock)
		WHERE D.VoucherNo IN (REPLACE(@EnquiryVoucher,'''',''))
		GROUP BY D.ProductID
	
		SET @Dt=getdate()
		SELECT @I=1,@CNT=COUNT(*) FROM @TblProd
		WHILE(@I<=@CNT)
		BEGIN
			SELECT @ProductID=ProductID FROM @TblProd WHERE ID=@I
		
			--TO GET BALANCE DATA
			EXEC [spRPT_AvgRate] 0,@ProductID,@LocationWHERE,'',@Dt,@Dt,0,0,0,0,'',0,@BalQty OUTPUT,@AvgRate OUTPUT,@BalValue OUTPUT,@COGS OUTPUT
			
			UPDATE @TblProd
			SET AvgRate=@AvgRate
			WHERE ID=@I
			
			SET @I=@I+1
		END
		
		select * from @TblProd
	END
	ELSE
	BEGIN
		select 1 AvgRate where 1!=1
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

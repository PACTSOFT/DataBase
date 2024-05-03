USE PACT2C222
GO
SET ANSI_NULLS, QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spSVC_GetTempPartsInfo]
	@FromDate [datetime],
	@ToDate [datetime],
	@Location [nvarchar](max) = null,
	@UserID [bigint],
	@LangID [int] = 1
WITH ENCRYPTION, EXECUTE AS CALLER
AS
BEGIN TRANSACTION
BEGIN TRY	
SET NOCOUNT ON
--select * from INV_DOCDETAILS
   DECLARE @SQL NVARCHAR(MAX) , @CCID NVARCHAR(MAX)
   SELECT @CCID=VALUE FROM   COM_CostCenterPreferences WHERE costcenterid = 3 AND NAME  = 'TempPartDocuments'
     
 set @SQL='	SELECT INVDOC.VoucherNo DocNo, convert(datetime,INVDOC.DocDate) DocDate ,DOCCC.dcCCNID2 LocationID,  loc.Name   Location 
	, INVDOC.CreatedBy CreatedBy ,  convert(datetime,INVDOC.CreatedDate) CreatedDate  , ''View Vehicle'' Vehicle   , INVDOC.DebitAccount VendorID , Acc.AccountName Vendor
	,p.name as ''part'',DOCCC.dcCCNID29,INVDOC.INVDOCDETAILSID
	 FROM INV_DOCDETAILS INVDOC
	 JOIN COM_DOCCCDATA DOCCC ON INVDOC.INVDOCDETAILSID = DOCCC.INVDOCDETAILSID 
	 left JOIN COM_Location loc ON DOCCC.dcCCNID2 = loc.NodeID 
	 left JOIN COM_CC50029 P ON DOCCC.dcCCNID29 = P.NodeID  
	  JOIN Acc_Accounts Acc ON INVDOC.DebitAccount  = Acc.AccountID 
	WHERE PRODUCTID IN (SELECT VALUE FROM COM_CostCenterPreferences
	WHERE costcenterid = 3 AND NAME  = ''TempPartProduct'' ) 
	and INVDOC.DocDate between '+convert(nvarchar(400),convert(float,@FromDate))+' and '+convert(nvarchar(400),convert(float,@ToDate))+'
	  and COSTCENTERID IN ('+REPLACE(@CCID,';',',')+')	 '
	IF(@Location IS NOT NULL AND @Location <>'' AND @Location <> '0' )
	BEGIN
		SET @SQL = @SQL  + ' and  loc.NodeID in ('+ @Location +')   '
	END
	
	set @SQL= @SQL  + '	order by INVDOC.DocDate desc'
	
	print @SQL
	exec(@SQL) 
		SELECT T.*,p.name as partName, M.Name as mfg, P.Code as PartCode FROM [INV_TempInfo] T WITH(NOLOCK)
		left JOIN COM_CC50029 P ON T.part= P.NodeID 
		left JOIN COM_CC50023 M ON T.manufacturer  = M.NodeID 
		WHERE T.InvDocDetailsID IN (SELECT InvDocDetailsID FROM  [INV_DocDetails] WITH(NOLOCK)
		WHERE PRODUCTID IN (SELECT VALUE FROM COM_CostCenterPreferences
		WHERE costcenterid = 3 AND NAME  = 'TempPartProduct' )) 
	 
		
		
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


--  SELECT T.*,p.name as partName,M.Name as mfg FROM [INV_TempInfo] T WITH(NOLOCK)
--	left JOIN COM_CC50029 P ON T.part= P.NodeID 
--	left JOIN COM_CC50023 M ON T.manufacturer  = M.NodeID 
--	WHERE T.InvDocDetailsID IN (SELECT InvDocDetailsID FROM  [INV_DocDetails] WITH(NOLOCK)
--	WHERE PRODUCTID IN (SELECT VALUE FROM COM_CostCenterPreferences
--	WHERE costcenterid = 3 AND NAME  = 'TempPartProduct' )) 
GO

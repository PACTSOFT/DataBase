USE PACT2C222
GO
SET ANSI_NULLS, QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spPAY_Util]
	@Type [int] = 0,
	@Param1 [bigint],
	@Param2 [nvarchar](max) = NULL,
	@Param3 [nvarchar](max) = NULL
WITH ENCRYPTION, EXECUTE AS CALLER
AS
BEGIN TRY  
SET NOCOUNT ON;
	declare @UserID int,@SQL nvarchar(max),@EmpID bigint,@DocDate float,@DueDate float,@DocID bigint,@EffectFrom float

	IF @Type=1
	BEGIN
		SELECT C.CostCenterID, Case when C.SysColumnName like 'dcCalcNumFC%' then R.ResourceData+'_FCCalculated'
		when C.SysColumnName like 'dcCalcNum%' then R.ResourceData+'_Calculated'
		when C.SysColumnName like 'dcCurrID%' then R.ResourceData+'_Currency'
		when C.SysColumnName like 'dcExchRT%' then R.ResourceData+'_ExchangeRate' 
		else R.ResourceData END ResourceData,
		C.UserColumnName,C.SysColumnName,C.SysTableName,C.UserColumnType,C.ColumnDataType,			
		C.IsColumnUserDefined,C.ColumnCostCenterID, Doc.IsInventory,Doc.DocumentType
		FROM ADM_CostCenterDef C WITH(NOLOCK)
		LEFT JOIN ADM_DocumentTypes Doc WITH(NOLOCK) ON C.CostCenterID = Doc.CostCenterID
		LEFT JOIN COM_LanguageResources R WITH(NOLOCK) ON R.ResourceID=C.ResourceID AND R.LanguageID=1
		LEFT JOIN ADM_DocumentDef DD WITH(NOLOCK) ON DD.CostCenterColID=C.CostCenterColID 
		WHERE C.CostCenterID IN (40072) 
		AND ((C.IsColumnUserDefined=1 AND C.IsColumnInUse=1) OR C.IsColumnUserDefined=0)
		AND ((C.SysTableName not like 'COM_DocCCData'))
		UNION
		SELECT C.CostCenterID, R.ResourceData+'_Remarks' ResourceData,
		C.UserColumnName,'dcRemarksNum'+REPLACE(SysColumnName, 'dcNum', ''),C.SysTableName,'','',			
		C.IsColumnUserDefined,C.ColumnCostCenterID, Doc.IsInventory,Doc.DocumentType
		FROM ADM_CostCenterDef C WITH(NOLOCK)
		LEFT JOIN ADM_DocumentTypes Doc WITH(NOLOCK) ON C.CostCenterID = Doc.CostCenterID
		LEFT JOIN COM_LanguageResources R WITH(NOLOCK) ON R.ResourceID=C.ResourceID AND R.LanguageID=1
		LEFT JOIN ADM_DocumentDef DD WITH(NOLOCK) ON DD.CostCenterColID=C.CostCenterColID 
		WHERE C.CostCenterID IN (40072)  AND (IsColumnInUse = 1) AND (SysColumnName LIKE 'dcNum%') AND  Doc.IsInventory=1 and C.SectionID=4
		AND ((C.SysTableName not like 'COM_DocCCData'))
		ORDER BY ResourceData
	END
	ELSE IF @Type=2
	BEGIN
		select @EmpID=DCC.dcCCNID51 from INV_DocDetails D with(nolock) 
		join COM_DocCCDATA DCC with(nolock) on D.InvDocDetailsID=DCC.InvDocDetailsID
		where D.VoucherNo=@Param2
		
		--To get latest document
		set @Type=null
		select top 1 @Type=DocID from INV_DocDetails D with(nolock) 
		join COM_DocCCDATA DCC with(nolock) on D.InvDocDetailsID=DCC.InvDocDetailsID
		join COM_DocTextDATA TXT with(nolock) on D.InvDocDetailsID=TXT.InvDocDetailsID
		where CostCenterID=@Param1 and DCC.dcCCNID51=@EmpID
		order by convert(datetime,TXT.dcAlpha3) desc

		SELECT  CASE WHEN D.DynamicInvDocDetailsID IS NULL THEN D.DocSeqNo ELSE (SELECT TOP 1 DocSeqNo FROM INV_DocDetails with(nolock) WHERE InvDocDetailsID=D.DynamicInvDocDetailsID) END SeqNo,
		D.BillNo,D.VoucherNo,CONVERT(DATETIME,D.DocDate) DocDate,D.DocAbbr,D.DocPrefix [Doc Prefix],CONVERT(DATETIME,D.DueDate) DueDate,CONVERT(DATETIME,D.BillDate) BillDate,
		D.Gross,D.GrossFC,D.CommonNarration,D.LineNarration,
		D.CreatedBy,CONVERT(DATETIME,D.CreatedDate) CreatedDate,
		D.ModifiedBy,CONVERT(DATETIME,D.ModifiedDate) ModifiedDate,
		(select voucherno from inv_docdetails WITH(NOLOCK) where InvDocDetailsID=D.LinkedInvDocDetailsID) [RefNo],
		D.CurrencyID CURRENCY_ID,C.Name CurrencyID,C.Symbol CurrencySymbol,S.Status,D.ExchangeRate [ExchangeRate],
		D.LinkedInvDocDetailsID,LD.VoucherNo LinkDocNo,CONVERT(DATETIME,LD.DocDate) LinkDocDate,LD.DocAbbr LinkDocAbbr,LD.DocPrefix LinkDocPrefix,LD.DocNumber LinkDocSerialNo,LD.CommonNarration LinkCommonNarration,LD.LineNarration LinkLineNarration,
		T.*,N.*
		FROM INV_DocDetails D WITH(NOLOCK) LEFT JOIN
		INV_DocDetails LD WITH(NOLOCK) ON LD.InvDocDetailsID=D.LinkedInvDocDetailsID LEFT JOIN
		COM_DocTextData T WITH(NOLOCK) ON T.InvDocDetailsID=D.InvDocDetailsID LEFT JOIN
		COM_DocNumData N WITH(NOLOCK) ON N.InvDocDetailsID=D.InvDocDetailsID LEFT JOIN
		COM_Currency C WITH(NOLOCK) ON C.CurrencyID=D.CurrencyID LEFT JOIN
		COM_Status S WITH(NOLOCK) ON S.StatusID=D.StatusID 
		where D.CostCenterID=@Param1 and D.DocID=@Type
	END
	ELSE IF @Type=3
	BEGIN
		select @EmpID=DCC.dcCCNID51,@DocDate=D.DocDate,@DueDate=D.DueDate from INV_DocDetails D with(nolock) 
		join COM_DocCCDATA DCC with(nolock) on D.InvDocDetailsID=DCC.InvDocDetailsID
		where D.VoucherNo=@Param2
		
		--To get latest document
		set @Type=null
		select top 1 @DocID=DocID from INV_DocDetails D with(nolock) 
		join COM_DocCCDATA DCC with(nolock) on D.InvDocDetailsID=DCC.InvDocDetailsID
		join COM_DocTextDATA TXT with(nolock) on D.InvDocDetailsID=TXT.InvDocDetailsID
		where CostCenterID=@Param1 and DCC.dcCCNID51=@EmpID and D.DueDate<=@DocDate
		order by D.DueDate desc
		
		--0
		SELECT D.VoucherType,N.*,convert(float,T.dcAlpha1) BasicMonthly,convert(float,T.dcAlpha3) NetSalary,T.*
		FROM INV_DocDetails D WITH(NOLOCK) LEFT JOIN
		INV_DocDetails LD WITH(NOLOCK) ON LD.InvDocDetailsID=D.LinkedInvDocDetailsID LEFT JOIN
		COM_DocTextData T WITH(NOLOCK) ON T.InvDocDetailsID=D.InvDocDetailsID LEFT JOIN
		PAY_DocNumData N WITH(NOLOCK) ON N.InvDocDetailsID=D.InvDocDetailsID LEFT JOIN
		COM_Currency C WITH(NOLOCK) ON C.CurrencyID=D.CurrencyID LEFT JOIN
		COM_Status S WITH(NOLOCK) ON S.StatusID=D.StatusID 
		where D.CostCenterID=@Param1 and D.DocID=@DocID
		
		--1
		SELECT top 1 @EffectFrom=EffectFrom FROM PAY_EmpPay WITH(NOLOCK)
		where EmployeeID=@EmpID and EffectFrom<=@DocDate
		order by EffectFrom desc
		
		SELECT *,0.0 EmptyData FROM PAY_EmpPay D WITH(NOLOCK)
		where D.EmployeeID=@EmpID and EffectFrom=@EffectFrom

		--2
		DECLARE @sCols NVARCHAR(MAX),@sQ NVARCHAR(MAX),@CurFYr DATETIME
		declare @FM INT,@TM INT,@YR INT,@d DATETIME
		SET @FM=CONVERT(INT,@Param3)
		SET @d=CONVERT(DATETIME,@DueDate)
		SELECT @TM=MONTH(@d)
		IF(@FM<=@TM)
		set @YR=YEAR(@d)
		ELSE
		set @YR=YEAR(@d)-1
 
		SET @CurFYr=CONVERT(DATETIME,('01-'+DATENAME(mm,(DATEADD(mm,@FM-1,0)))+'-'+convert(varchar,@YR)))
		 print @CurFYr
		SELECT @sCols=stuff((select ',SUM(ISNULL('+NAME+',0)) as '+REPLACE(NAME,'DCCALCNUM','dcCalcNumYTD')+''  from SYS.COLUMNS WHERE OBJECT_ID IN(SELECT OBJECT_ID FROM SYS.TABLES WHERE NAME='PAY_DOCNUMDATA')
		AND NAME LIKE 'DCCALCNUM%' AND NAME NOT LIKE 'DCCALCNUMFC%' FOR XML PATH('')),1,1,'')
		print @sCols

		SET @sQ='Select a.VoucherType,'+@sCols +' 
					FROM INV_DocDetails a WITH(NOLOCK) 
					JOIN COM_DOCCCData b WITH(NOLOCK) on a.INVDocDetailsID=b.INVDocDetailsID
					JOIN PAY_DOCNUMData c WITH(NOLOCK) ON c.INVDocDetailsID=b.INVDocDetailsID
					WHERE a.CostCenterID=40054 AND a.StatusID=369 AND a.VoucherType=11
					AND b.dcCCNID51='+CONVERT(VARCHAR,@EmpID)+'
					AND DATEDIFF(DAY,a.DueDate,'''+CONVERT(VARCHAR,@CurFYr)+''')<=0 AND DATEDIFF(DAY,a.DueDate,'''+CONVERT(VARCHAR,@d)+''')>=0
					GROUP BY a.VoucherType

					UNION ALL

					Select a.VoucherType,'+@sCols +' 
					FROM INV_DocDetails a WITH(NOLOCK) 
					JOIN COM_DOCCCData b WITH(NOLOCK) on a.INVDocDetailsID=b.INVDocDetailsID
					JOIN PAY_DOCNUMData c WITH(NOLOCK) ON c.INVDocDetailsID=b.INVDocDetailsID
					WHERE a.CostCenterID=40054 AND a.StatusID=369 AND a.VoucherType=12
					AND b.dcCCNID51='+CONVERT(VARCHAR,@EmpID)+'
					AND DATEDIFF(DAY,a.DueDate,'''+CONVERT(VARCHAR,@CurFYr)+''')<=0 AND DATEDIFF(DAY,a.DueDate,'''+CONVERT(VARCHAR,@d)+''')>=0
					GROUP BY a.VoucherType
					'
		print @sQ
		EXEC(@sQ)

		
	END
	ELSE IF @Type=4
	BEGIN

		SELECT @EmpID=DCC.dcCCNID51,@DocDate=D.DocDate,@DueDate=D.DueDate from INV_DocDetails D with(nolock) 
		join COM_DocCCDATA DCC with(nolock) on D.InvDocDetailsID=DCC.InvDocDetailsID
		WHERE D.VoucherNo=@Param2

		SELECT D.*,CONVERT(DATETIME,EffectFrom) as cEffectFrom,CONVERT(DATETIME,ApplyFrom) as cApplyFrom,
		ISNULL(L.Name,'') as cAppraisalType,0.0 EmptyData 
		FROM PAY_EmpPay D WITH(NOLOCK) 
		LEFT JOIN COM_Lookup L WITH(NOLOCK) ON L.NodeID=D.AppraisalType
		WHERE D.EmployeeID=@EmpID
		ORDER BY EffectFrom DESC 
	END
	
	
SET NOCOUNT OFF;
RETURN 1
END TRY
BEGIN CATCH  
		--Return exception info [Message,Number,ProcedureName,LineNumber]  
		IF ERROR_NUMBER()=50000
		BEGIN
			SELECT ErrorMessage,ErrorNumber FROM COM_ErrorMessages WITH(NOLOCK) WHERE ErrorNumber=ERROR_MESSAGE() AND LanguageID=1
		END
		ELSE
		BEGIN
			SELECT ErrorMessage, ERROR_MESSAGE() AS ServerMessage,ERROR_NUMBER() as ErrorNumber, ERROR_PROCEDURE()as ProcedureName, ERROR_LINE() AS ErrorLine
			FROM COM_ErrorMessages WITH(NOLOCK) WHERE ErrorNumber=-999 AND LanguageID=1
		END
SET NOCOUNT OFF  
RETURN -999   
END CATCH

GO

USE PACT2C222
GO
SET ANSI_NULLS, QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spRPT_PayReports]
	@FromDate [datetime],
	@ToDate [datetime],
	@ReportID [int],
	@Select [nvarchar](max) = null,
	@SelectAlias [nvarchar](max) = null,
	@strCCJoin [nvarchar](max) = null,
	@strCCWhere [nvarchar](max) = null,
	@OptionsXML [nvarchar](max) = null,
	@LangID [int] = 1
WITH ENCRYPTION, EXECUTE AS CALLER
AS
BEGIN TRY      
SET NOCOUNT ON;
  
DECLARE @SQL NVARCHAR(MAX)   
DECLARE @From FLOAT,@To FLOAT

SET @From=CONVERT(FLOAT,@FromDate)  
SET @To=CONVERT(FLOAT,@ToDate)  

IF (@ReportID=288)
BEGIN
SET @SQL='
SELECT CONVERT(DATETIME,D.DueDate) as PayrollMonth,D.VoucherType
,isnull(sum(CONVERT(FLOAT,TXT.dcAlpha25)),0) GrossSalary
,sum(CONVERT(FLOAT,TXT.dcAlpha3)) NetSalary
,isnull(sum(CONVERT(FLOAT,TXT.dcAlpha26)),0)-isnull(sum(CONVERT(FLOAT,TXT.dcAlpha29)),0) as Arears--,TXT.*
FROM INV_DocDetails D WITH(NOLOCK)   
JOIN COM_DocCCData DCC WITH(NOLOCK) ON DCC.INVDOCDETAILSID=D.INVDOCDETAILSID
JOIN PAY_DocNumData NUM ON NUM.INVDOCDETAILSID=D.INVDOCDETAILSID
JOIN COM_DocTextData TXT WITH(NOLOCK) ON TXT.INVDOCDETAILSID=D.INVDOCDETAILSID
WHERE D.CostCenterID=40054 AND D.StatusID=369 and (D.VoucherType=11 or D.VoucherType=12)
--AND DCC.dcCCNID51=443
AND (D.DueDate='+convert(nvarchar,@From)+' or D.DueDate='+convert(nvarchar,@To)+')
'+@strCCWhere+'
group by D.DueDate,D.VoucherType
order by D.DueDate

declare @Tbl as Table(EmpID bigint primary key)

insert into @Tbl
select EmpID
from
(
SELECT E.NodeID EmpID,E.Code,CONVERT(DATETIME,D.DueDate) as PayrollMonth,D.VoucherType,case when D.DueDate='+convert(nvarchar,@To)+' then 1 else -1 end IsCurrentMonth
,CONVERT(FLOAT,TXT.dcAlpha3) NetSalary
,isnull(CONVERT(FLOAT,TXT.dcAlpha25),0) GrossSalary
,isnull(CONVERT(FLOAT,TXT.dcAlpha26),0)-isnull(CONVERT(FLOAT,TXT.dcAlpha29),0) as Arrears
,isnull(CONVERT(FLOAT,TXT.dcAlpha29),0) ArrearDudctions--,TXT.*
FROM INV_DocDetails D WITH(NOLOCK)   
JOIN COM_DocCCData DCC WITH(NOLOCK) ON DCC.INVDOCDETAILSID=D.INVDOCDETAILSID
JOIN PAY_DocNumData NUM ON NUM.INVDOCDETAILSID=D.INVDOCDETAILSID
JOIN COM_DocTextData TXT WITH(NOLOCK) ON TXT.INVDOCDETAILSID=D.INVDOCDETAILSID
JOIN COM_CC50051 E with(nolock) on E.NodeID=DCC.dcCCNID51
WHERE D.CostCenterID=40054 AND D.StatusID=369 and (D.VoucherType=11 or D.VoucherType=12)
--AND DCC.dcCCNID51=443
AND (D.DueDate='+convert(nvarchar,@From)+' or D.DueDate='+convert(nvarchar,@To)+')
'+@strCCWhere+'
--group by D.DueDate,D.VoucherType,DCC.dcCCNID51
) AS T
group by EmpID
having (sum(NetSalary*IsCurrentMonth)!=0 or sum(Arrears*IsCurrentMonth)!=0 or sum(GrossSalary*IsCurrentMonth)!=0)

SELECT E.NodeID EmpID,E.Code,CONVERT(DATETIME,D.DueDate) as PayrollMonth,D.VoucherType,case when D.DueDate='+convert(nvarchar,@To)+' then 1 else -1 end IsCurrentMonth
,CONVERT(FLOAT,TXT.dcAlpha3) NetSalary
,isnull(CONVERT(FLOAT,TXT.dcAlpha25),0) GrossSalary
,isnull(CONVERT(FLOAT,TXT.dcAlpha26),0)-isnull(CONVERT(FLOAT,TXT.dcAlpha29),0) as Arrears
,isnull(CONVERT(FLOAT,TXT.dcAlpha29),0) ArrearDudctions
,NUM.*,TXT.*
FROM INV_DocDetails D WITH(NOLOCK)   
JOIN COM_DocCCData DCC WITH(NOLOCK) ON DCC.INVDOCDETAILSID=D.INVDOCDETAILSID
JOIN PAY_DocNumData NUM ON NUM.INVDOCDETAILSID=D.INVDOCDETAILSID
JOIN COM_DocTextData TXT WITH(NOLOCK) ON TXT.INVDOCDETAILSID=D.INVDOCDETAILSID
JOIN COM_CC50051 E with(nolock) on E.NodeID=DCC.dcCCNID51
JOIN @Tbl T on E.NodeID=T.EmpID
WHERE D.CostCenterID=40054 AND D.StatusID=369 and (D.VoucherType=11 or D.VoucherType=12)
--AND DCC.dcCCNID51=443
AND (D.DueDate='+convert(nvarchar,@From)+' or D.DueDate='+convert(nvarchar,@To)+')


select EmpSeqNo,convert(datetime,ArrearsCalcMonths) ArrearsCalcMonths from PAY_EmpMonthlyArrears with(nolock) where PayrollMonth='+convert(nvarchar,@To)+'
'
	--EXEC (@SQL)  


	SET @SQL='
SELECT CONVERT(DATETIME,D.DueDate) as PayrollMonth,D.VoucherType
,isnull(sum(CONVERT(FLOAT,TXT.dcAlpha25)),0) GrossSalary
,sum(CONVERT(FLOAT,TXT.dcAlpha3)) NetSalary
FROM INV_DocDetails D WITH(NOLOCK)   
JOIN COM_DocCCData DCC WITH(NOLOCK) ON DCC.INVDOCDETAILSID=D.INVDOCDETAILSID
JOIN PAY_DocNumData NUM ON NUM.INVDOCDETAILSID=D.INVDOCDETAILSID
JOIN COM_DocTextData TXT WITH(NOLOCK) ON TXT.INVDOCDETAILSID=D.INVDOCDETAILSID
WHERE D.CostCenterID=40054 AND D.StatusID=369 and D.VoucherType=11
AND (D.DueDate='+convert(nvarchar,@From)+' or D.DueDate='+convert(nvarchar,@To)+')
'+@strCCWhere+'
group by D.DueDate,D.VoucherType
order by D.DueDate

select EmpID,Code,VoucherType
,sum(NetSalary*IsCurrentMonth) NetSalary
,sum(GrossSalary*IsCurrentMonth) GrossSalary
,sum(Arrears*IsCurrentMonth) Arrears
,sum(ArrearDudctions*IsCurrentMonth) ArrearDudctions
,sum(Adjustments*IsCurrentMonth) Adjustments
,sum(IsCurrentMonth) IsCurrentMonth'+@SelectAlias+'
from
(
SELECT E.NodeID EmpID,E.Code,CONVERT(DATETIME,D.DueDate) as PayrollMonth,D.VoucherType,case when D.DueDate='+convert(nvarchar,@To)+' then 1 else -1 end IsCurrentMonth
,CONVERT(FLOAT,TXT.dcAlpha3) NetSalary
,isnull(CONVERT(FLOAT,TXT.dcAlpha25),0) GrossSalary
,isnull(CONVERT(FLOAT,TXT.dcAlpha26),0)-isnull(CONVERT(FLOAT,TXT.dcAlpha29),0) as Arrears
,isnull(CONVERT(FLOAT,TXT.dcAlpha27),0)-isnull(CONVERT(FLOAT,TXT.dcAlpha30),0) as Adjustments
,isnull(CONVERT(FLOAT,TXT.dcAlpha29),0) ArrearDudctions'+@Select+'
FROM INV_DocDetails D WITH(NOLOCK)   
JOIN COM_DocCCData DCC WITH(NOLOCK) ON DCC.INVDOCDETAILSID=D.INVDOCDETAILSID
JOIN PAY_DocNumData NUM ON NUM.INVDOCDETAILSID=D.INVDOCDETAILSID
JOIN COM_DocTextData TXT WITH(NOLOCK) ON TXT.INVDOCDETAILSID=D.INVDOCDETAILSID
JOIN COM_CC50051 E with(nolock) on E.NodeID=DCC.dcCCNID51
WHERE D.CostCenterID=40054 AND D.StatusID=369 and (D.VoucherType=11 or D.VoucherType=12)
--AND DCC.dcCCNID51=443
AND (D.DueDate='+convert(nvarchar,@From)+' or D.DueDate='+convert(nvarchar,@To)+')
'+@strCCWhere+'
--group by D.DueDate,D.VoucherType,DCC.dcCCNID51
) AS T
group by EmpID,Code,VoucherType
having (sum(NetSalary*IsCurrentMonth)!=0 or sum(Arrears*IsCurrentMonth)!=0 or sum(GrossSalary*IsCurrentMonth)!=0 or sum(Adjustments*IsCurrentMonth)!=0)
order by Code

select EmpSeqNo,convert(datetime,ArrearsCalcMonths) ArrearsCalcMonths from PAY_EmpMonthlyArrears with(nolock) where PayrollMonth='+convert(nvarchar,@To)+'

select EmpSeqNo,convert(datetime,AdjMonth) AdjMonth, Days from PAY_EmpMonthlyAdjustments with(nolock) where PayrollMonth='+convert(nvarchar,@To)+'

select NodeID from COM_CC50051 with(nolock) where DOResign>='+convert(nvarchar,@From)+' and DOResign<='+convert(nvarchar,convert(float,dateadd(month,1,@ToDate)))+'

'
print (@SQL) 
	EXEC (@SQL)  
	
END
ELSE IF (@ReportID=289)
BEGIN
	SET @SQL='
select 1 Type,count(*) Value from COM_CC50051 E with(nolock)'+@strCCJoin+'
where E.StatusID=250 and E.IsGroup=0 and E.DOJ<'+convert(nvarchar,@From)+' and (E.DORelieve is null or E.DORelieve>'+convert(nvarchar,@From)+')
'+@strCCWhere+'
union all
select 2 Type,count(*) Value from COM_CC50051 E with(nolock)'+@strCCJoin+'
where E.StatusID=250 and E.IsGroup=0 and (E.DOJ between '+convert(nvarchar,@From)+' and '+convert(nvarchar,@To)+')
'+@strCCWhere+'
union all
select 3 Type,count(*) Value from COM_CC50051 E with(nolock)'+@strCCJoin+'
where E.StatusID=250 and E.IsGroup=0 and (E.DORelieve between '+convert(nvarchar,@From)+' and '+convert(nvarchar,@To)+')
'+@strCCWhere
/*
SELECT E.Code ECode,E.Name EName,CONVERT(DATETIME,E.DOJ) DOJ,CONVERT(DATETIME,E.DORelieve) DOR,T2.Name Department,T5.Name Designation,E.Name'+@Select+'
FROM COM_CC50051 E with(nolock),COM_CCCCDATA ECCMAP with(nolock),COM_Department T2 with(nolock),COM_CC50069 T5 with(nolock)
'+@strCCJoin+'
WHERE E.IsGroup=0 and E.StatusID=250 and E.NodeID=ECCMAP.NodeID AND ECCMAP.CostCenterID=50051 AND ECCMAP.CCNID4=T2.NodeID AND ECCMAP.CCNID69=T5.NodeID
and (E.DOJ between '+convert(nvarchar,@From)+' and '+convert(nvarchar,@To)+' or E.DORelieve between '+convert(nvarchar,@From)+' and '+convert(nvarchar,@To)+')
'+@strCCWhere
*/
--print (@SQL) 
	EXEC (@SQL)  
	
END
ELSE IF (@ReportID=300)
BEGIN
	SET @SQL='SELECT DISTINCT a.VoucherNo,a.CostCenterID,a.DocID,
DCC.dcCCNID51 as EmpSeqNo,c51.Code as EmpCode,c51.Name as EmpName,
CONVERT(DATETIME,d.dcAlpha2) as FromDate,CONVERT(DATETIME,d.dcAlpha3) as ToDate,CONVERT(FLOAT,d.dcAlpha4) as NoOfDays
FROM INV_DocDetails a WITH(NOLOCK) 
JOIN COM_DocCCData DCC WITH(NOLOCK) ON DCC.InvDocDetailsID=a.InvDocDetailsID
JOIN COM_DocTextData d WITH(NOLOCK) ON d.InvDocDetailsID=a.InvDocDetailsID
JOIN COM_CC50051 c51 WITH(NOLOCK) ON c51.NodeID=DCC.dcCCNID51
WHERE a.CostCenterID=40072 and a.StatusID=369
AND ISNULL(d.dcAlpha16,'''')=''NO'' AND ISNULL(d.dcAlpha17,'''')=''NO''
and (convert(float,CONVERT(DATETIME,d.dcAlpha2)) between '+convert(nvarchar,@From)+' and '+convert(nvarchar,@To)+'
or convert(float,CONVERT(DATETIME,d.dcAlpha3)) between '+convert(nvarchar,@From)+' and '+convert(nvarchar,@To)+'
or '+convert(nvarchar,@From)+' between convert(float,CONVERT(DATETIME,d.dcAlpha2)) and convert(float,CONVERT(DATETIME,d.dcAlpha3)))
AND ISDATE(d.dcAlpha2)=1 AND ISDATE(d.dcAlpha3)=1'+@strCCWhere+'
ORDER BY c51.Code,CONVERT(DATETIME,d.dcAlpha2)'
--print (@SQL) 
	EXEC (@SQL)  
	
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

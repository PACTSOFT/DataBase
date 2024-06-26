﻿USE PACT2C222
GO
SET ANSI_NULLS, QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spSVC_GetPartOrderStatusReport]
	@FromDt [datetime],
	@ToDt [datetime],
	@LocationWhere [nvarchar](max),
	@UserID [bigint] = 1,
	@LangID [int] = 1
WITH ENCRYPTION, EXECUTE AS CALLER
AS
BEGIN TRY  
SET NOCOUNT ON;  
 
 DECLARE @From FLOAT,@To FLOAT

    SET @From=CONVERT(FLOAT,@FromDt)
    SET @To=CONVERT(FLOAT,@ToDt)
    
    set @LocationWhere=replace(@LocationWhere,'AND MRCC.dcCCNID2 IN (','')
    set @LocationWhere=replace(@LocationWhere,')','')
     
create table #loc(id bigint) 
insert into #loc
EXEC SPSplitString @LocationWhere,','

if not exists(select id from #loc)
insert into #loc
select Nodeid from com_location

--MATERIAL REQUISITION TEMP TABLE
CREATE TABLE #MRDET1(COSTCENTERID BIGINT, INVDOCDETAILSID BIGINT, LINKEDINVDOCDETAILSID BIGINT, DOCUMENTTYPE BIGINT, VoucherNo NVARCHAR(max), DOCDATE DATETIME,
CCNID40Name NVARCHAR(200),dcAlpha3 NVARCHAR(200),dcAlpha6 NVARCHAR(200), dcAlpha7 NVARCHAR(200), dcAlpha8 NVARCHAR(200),
dcAlpha9  NVARCHAR(200),ProductCode NVARCHAR(200), ProductName NVARCHAR(200), CCNID23Name NVARCHAR(200),CCNID2Name NVARCHAR(200), 
vehicleid bigint, STATUSID BIGINT,PRODUCTID BIGINT, REGID BIGINT )
  
INSERT INTO #MRDET1 (COSTCENTERID, INVDOCDETAILSID, LINKEDINVDOCDETAILSID, DOCUMENTTYPE, VOUCHERNO, DOCDATE,
dcAlpha3 ,dcAlpha6 , dcAlpha7 , dcAlpha8 ,dcAlpha9,ProductCode, ProductName, CCNID40Name , CCNID23Name ,
CCNID2Name, VEHICLEID,STATUSID,PRODUCTID, REGID) 

SELECT MR.CostCenterID, MR.InvDocDetailsID, LinkedInvDocDetailsID, DocumentType ,VOUCHERNO, CONVERT(DATETIME, DOCDATE),
MRA.dcAlpha3,--MRA.dcAlpha6 ,MRA.dcAlpha7, MRA.dcAlpha8 ,MRA.dcAlpha9 ,
case when costcenterid=40025 then MRA.dcalpha6 else MRA.dcalpha5 end make,
case when costcenterid=40025 then MRA.dcAlpha7 else MRA.dcalpha2 end Model,
case when costcenterid=40025 then MRA.dcAlpha8 else MRA.dcalpha3 end Variant,
case when costcenterid=40025 then MRA.dcAlpha9 else MRA.dcAlpha4 end Year,
MRP.ProductCode, Part.Name ,
MRJob.Name, MRMan.Name , MRLoc.Name  ,MRCC.VehicleID, MR.STATUSID ,MR.PRODUCTID, mrcc.dcCCNID43
FROM INV_DocDetails MR with(nolock)
join com_doctextdata MRA with(nolock) on MR.InvDocdetailsid=MRA.InvDocdetailsid
join com_docccdata MRCC with(nolock)  on MR.InvDocdetailsid= MRCC.InvDocdetailsid  
join inv_product MRP  with(nolock) on MR.ProductID=MRP.PRoductID 
LEFT join COM_CC50023 MRMan with(nolock) on MRCC.dcccnid23= MRMan.NodeID 
LEFT join COM_CC50029 Part with(nolock) on MRCC.dcccnid29= Part.NodeID
LEFT join COM_Location MRLoc with(nolock) on MRCC.dcccnid2 = MRLoc.NodeID 
LEFT join COM_CC50042 MRJob with(nolock) on MRCC.dcccnid42= MRJob.NodeID 
--left JOIN COM_CC50043 MRREG with(nolock) on mrcc.dcCCNID43= MRREG.NodeID
WHERE MR.CostCenterID in (40025,41009)  AND  MR.DocDate BETWEEN   CONVERT(FLOAT,@From) AND CONVERT(FLOAT,@To)    AND MRCC.DCCCNID2 IN (select id from #loc)
 
 --MATERIAL REQUISITION CANCELLATION
CREATE TABLE #MRDCAN(COSTCENTERID BIGINT, INVDOCDETAILSID BIGINT, LINKEDINVDOCDETAILSID BIGINT, DOCUMENTTYPE BIGINT, 
VoucherNo NVARCHAR(max), DOCDATE DATETIME,PRODUCTID BIGINT  )

INSERT INTO #MRDCAN (COSTCENTERID , INVDOCDETAILSID , LINKEDINVDOCDETAILSID , DOCUMENTTYPE ,VOUCHERNO, DOCDATE,PRODUCTID)
SELECT MRC.CostCenterID, MRC.InvDocDetailsID, MRC.LinkedInvDocDetailsID, MRC.DocumentType ,MRC.VOUCHERNO, 
CONVERT(DATETIME, MRC.DOCDATE),MRC.PRODUCTID  
FROM INV_DocDetails MRC with(nolock)
left join #MRDET1 mr1 on MRC.LinkedInvDocDetailsID=mr1.INVDOCDETAILSID
WHERE MRC.CostCenterID IN (41016)
AND MRC.PRODUCTID=MR1.PRODUCTID


--PURCHASE ORDER
CREATE TABLE #MRDET2(COSTCENTERID BIGINT, INVDOCDETAILSID BIGINT, LINKEDINVDOCDETAILSID BIGINT, DOCUMENTTYPE BIGINT, VoucherNo NVARCHAR(max), DOCDATE DATETIME,
Quantity FLOAT, RATE FLOAT, STOCKVALUE FLOAT,
VENDOR NVARCHAR(500),dcalpha17 NVARCHAR(500),dcalpha16 NVARCHAR(500),
 dcalpha3 NVARCHAR(500),PRODUCTID BIGINT, dcalpha30 nvarchar(500), REGID BIGINT )

INSERT INTO #MRDET2 (COSTCENTERID , INVDOCDETAILSID , LINKEDINVDOCDETAILSID , DOCUMENTTYPE ,VOUCHERNO, DOCDATE,
Quantity,RATE,STOCKVALUE, 
VENDOR ,dcalpha17 ,dcalpha16 , dcalpha3 ,PRODUCTID,dcalpha30, REGID)
SELECT PO.CostCenterID, PO.InvDocDetailsID, PO.LinkedInvDocDetailsID, PO.DocumentType ,PO.VOUCHERNO, 
CONVERT(DATETIME, po.DOCDATE),PO.Quantity,PO.RATE,PO.STOCKVALUE,
POV.ACCOUNTNAME,--POA.dcalpha17 ,POA.dcalpha16 , POA.dcalpha3   ,PO.PRODUCTID,POA.dcAlpha30,POCC.DCCCNID43

case when PO.CostCenterID=40002 then POA.dcalpha17 else '' end BillToCity,  
case when PO.CostCenterID=40002 then POA.dcalpha16 else '' end ShipToCity,
case when PO.CostCenterID=40002 then POA.dcalpha3 else POA.dcalpha13 end CreditTerms,
PO.PRODUCTID,case when PO.CostCenterID=40002 then POA.dcAlpha30 else POA.dcAlpha26 end CashTransferStatus,POCC.DCCCNID43
FROM INV_DocDetails PO with(nolock)
left join #MRDET1 mr1 on PO.LinkedInvDocDetailsID=mr1.INVDOCDETAILSID 
left join acc_accounts POV with(nolock) on PO.CreditAccount=POV.AccountID
left join com_doctextdata POA with(nolock) on PO.InvDocdetailsid=POA.InvDocdetailsid
LEFT JOIN COM_DOCCCDATA POCC WITH(NOLOCK) ON PO.InvDocdetailsid=POCC.INVDOCDETAILSID
WHERE  PO.CostCenterID IN (40002,41015) AND PO.PRODUCTID=MR1.PRODUCTID


--PURCHASE ORDER CANCELLATION
CREATE TABLE #POCAN(COSTCENTERID BIGINT, INVDOCDETAILSID BIGINT, LINKEDINVDOCDETAILSID BIGINT, DOCUMENTTYPE BIGINT, VoucherNo NVARCHAR(max), 
DOCDATE DATETIME, quantity float,PRODUCTID BIGINT  )

INSERT INTO #POCAN (COSTCENTERID , INVDOCDETAILSID , LINKEDINVDOCDETAILSID , DOCUMENTTYPE ,VOUCHERNO, DOCDATE, quantity,PRODUCTID)
SELECT POC.CostCenterID, POC.InvDocDetailsID, POC.LinkedInvDocDetailsID, POC.DocumentType ,POC.VOUCHERNO, CONVERT(DATETIME, POC.DOCDATE), POC.quantity,
 POC.PRODUCTID
FROM INV_DocDetails POC with(nolock)
LEFT JOIN #MRDET2 MR2 ON POC.LinkedInvDocDetailsID=MR2.INVDOCDETAILSID
WHERE POC.CostCenterID IN (41001) AND POC.PRODUCTID=MR2.PRODUCTID
 

--GOOD RECEIVED
CREATE TABLE #MRDET3(COSTCENTERID BIGINT, INVDOCDETAILSID BIGINT, LINKEDINVDOCDETAILSID BIGINT, DOCUMENTTYPE BIGINT, VoucherNo NVARCHAR(max), 
DOCDATE DATETIME,Quantity FLOAT, RATE FLOAT, STOCKVALUE FLOAT,
dcalpha14  NVARCHAR(500),dcAlpha18 NVARCHAR(500), dcAlpha19 NVARCHAR(500), dcCalcNum2 FLOAT,
vehicleregno NVARCHAR(max), PRODUCTID BIGINT, REGID BIGINT )

INSERT INTO #MRDET3 (COSTCENTERID, INVDOCDETAILSID, LINKEDINVDOCDETAILSID, DOCUMENTTYPE, VOUCHERNO, DOCDATE, Quantity,RATE,STOCKVALUE,
dcalpha14,dcAlpha18,dcAlpha19 , dcCalcNum2,vehicleregno   , PRODUCTID ,REGID)
SELECT GR.CostCenterID, GR.InvDocDetailsID, GR.LinkedInvDocDetailsID, GR.DocumentType ,GR.VOUCHERNO, 
CONVERT(DATETIME, GR.DOCDATE),GR.Quantity,GR.RATE,GR.STOCKVALUE,
--GRA.dcalpha14,GRA.dcAlpha18,GRA.dcAlpha19 , GRN.dcCalcNum2,GRA.DCALPHA6, GR.PRODUCTID,GRCC.DCCCNID43
case when GR.CostCenterID=40004 then  GRA.dcalpha14 else GRA.dcAlpha21 end TransportName,
case when GR.CostCenterID=40004 then  GRA.dcAlpha18 else GRA.dcAlpha11 end LRNO,
case when GR.CostCenterID=40004 then  GRA.dcAlpha19 else GRA.dcAlpha17 end ShipmentDate,  GRN.dcCalcNum2,GRA.DCALPHA6, GR.PRODUCTID,GRCC.DCCCNID43
FROM INV_DocDetails GR with(nolock)
LEFT JOIN #MRDET2 MR2 ON GR.LinkedInvDocDetailsID=MR2.INVDOCDETAILSID
left join com_doctextdata GRA with(nolock) on GR.InvDocdetailsid=GRA.InvDocdetailsid 
left join com_docCCdata GRCC with(nolock) on GR.InvDocdetailsid=GRCC.InvDocdetailsid 
left join com_docnumdata GRN with(nolock) on GR.InvDocdetailsid=GRN.InvDocdetailsid
WHERE  GR.CostCenterID IN (40004,41013) AND GR.PRODUCTID=MR2.PRODUCTID

--PURCHASE INVOICE
CREATE TABLE #MRDET4(COSTCENTERID BIGINT, INVDOCDETAILSID BIGINT, LINKEDINVDOCDETAILSID BIGINT, DOCUMENTTYPE BIGINT, VoucherNo NVARCHAR(max), DOCDATE DATETIME, 
BILLNO NVARCHAR(200), BILLDATE DATETIME, PIVRATE FLOAT, PIVVALUE FLOAT, PIVDUEDATE DATETIME,PRODUCTID BIGINT )

INSERT INTO #MRDET4 (COSTCENTERID , INVDOCDETAILSID , LINKEDINVDOCDETAILSID , DOCUMENTTYPE , VoucherNo , DOCDATE , 
BILLNO , BILLDATE , PIVRATE , PIVVALUE , PIVDUEDATE ,PRODUCTID)
SELECT D.CostCenterID, D.InvDocDetailsID, D.LinkedInvDocDetailsID, D.DocumentType, D.VOUCHERNO, CONVERT(DATETIME, D.DOCDATE),
D.BILLNO, D.BILLDATE, D.RATE, D.STOCKVALUE, CONVERT(DATETIME,D.DUEDATE),D.PRODUCTID
FROM INV_DocDetails D with(nolock) 
LEFT JOIN #MRDET3 MR3 ON D.LinkedInvDocDetailsID= MR3.InvDocDetailsID
WHERE D.CostCenterID IN (40001,41004,41008) AND D.PRODUCTID=MR3.PRODUCTID
 
 
--PURCHASE INVOICE CANCELLATION (Purchase Return)
CREATE TABLE #PIVCAN(COSTCENTERID BIGINT, INVDOCDETAILSID BIGINT, LINKEDINVDOCDETAILSID BIGINT, DOCUMENTTYPE BIGINT,
 VoucherNo NVARCHAR(max), DOCDATE DATETIME,quantity float,PRODUCTID BIGINT  )

INSERT INTO #PIVCAN(COSTCENTERID , INVDOCDETAILSID , LINKEDINVDOCDETAILSID , DOCUMENTTYPE ,VOUCHERNO, DOCDATE,quantity,PRODUCTID)
SELECT POC.CostCenterID, POC.InvDocDetailsID, POC.LinkedInvDocDetailsID, POC.DocumentType ,POC.VOUCHERNO, CONVERT(DATETIME, POC.DOCDATE),POC.Quantity,
POC.PRODUCTID
FROM INV_DocDetails POC with(nolock) 
LEFT JOIN #MRDET4 MR4 ON POC.LinkedInvDocDetailsID=MR4.InvDocDetailsID
WHERE POC.CostCenterID IN (40010,41010) AND POC.PRODUCTID=MR4.PRODUCTID
 

--GOODS RECEIVED RETURN
CREATE TABLE #MRDET5(COSTCENTERID BIGINT, INVDOCDETAILSID BIGINT, LINKEDINVDOCDETAILSID BIGINT, DOCUMENTTYPE BIGINT,VoucherNo NVARCHAR(max), DOCDATE DATETIME,
ReceivedBy NVARCHAR(200), RETURNDATE DATETIME ,dcalpha14 NVARCHAR(500), quantity float,PRODUCTID BIGINT  ) 

INSERT INTO #MRDET5 (COSTCENTERID, INVDOCDETAILSID, LINKEDINVDOCDETAILSID, DOCUMENTTYPE,VoucherNo  , DOCDATE ,
ReceivedBy , RETURNDATE  ,dcalpha14, quantity,PRODUCTID)
SELECT GRR.CostCenterID, GRR.InvDocDetailsID, GRR.LinkedInvDocDetailsID, GRR.DocumentType, GRR.VOUCHERNO, CONVERT(DATETIME, GRR.DOCDATE) ,
(SELECT TOP 1 CREATEDBY  FROM COM_APPROVALS  GRRAPP with(nolock) WHERE GRR.DocID=GRRApp.CCNodeID and GRRApp.CCID=41005 and GRRApp.Statusid=441) ,
(SELECT TOP 1 Convert(datetime, CREATEDDATE ) FROM COM_APPROVALS   GRRAPP with(nolock) WHERE GRR.DocID=GRRApp.CCNodeID and GRRApp.CCID=41005 and GRRApp.Statusid=441) ,
grra.dcalpha14, GRR.quantity,GRR.PRODUCTID
FROM INV_DocDetails GRR with(nolock)
LEFT JOIN #MRDET3 MR3 ON GRR.LinkedInvDocDetailsID=MR3.InvDocDetailsID
left join com_doctextdata GRRA with(nolock) on GRR.InvDocdetailsid=GRrA.InvDocdetailsid 
WHERE GRR.CostCenterID IN (41005) AND GRR.PRODUCTID=MR3.PRODUCTID


--STOCK TRANSFER 
CREATE TABLE #ST(COSTCENTERID BIGINT, INVDOCDETAILSID BIGINT, LINKEDINVDOCDETAILSID BIGINT, DOCUMENTTYPE BIGINT, VoucherNo NVARCHAR(max),
 DOCDATE DATETIME, QUANTITY FLOAT,VEHICLEREGNO NVARCHAR(max), tolocation nvarchar(200),PRODUCTID BIGINT, REGID BIGINT )

INSERT INTO #ST (COSTCENTERID, INVDOCDETAILSID , LINKEDINVDOCDETAILSID , DOCUMENTTYPE , VoucherNo , DOCDATE , QUANTITY, 
VEHICLEREGNO, tolocation,PRODUCTID, REGID)
SELECT D.CostCenterID,  D.InvDocDetailsID, D.LinkedInvDocDetailsID, D.DocumentType, D.VOUCHERNO, CONVERT(DATETIME, D.DOCDATE),
D.QUANTITY , T.DCALPHA1,
(select Name from com_location where nodeid in (select dcccnid2 from COM_DocccData where invdocdetailsid in
(select invdocdetailsid from inv_docdetails i where i.productid=d.productid and vouchertype=1 and i.voucherno=d.voucherno))),D.PRODUCTID,
cc.dcCCNID43
FROM INV_DocDetails  D  with(nolock)  
LEFT JOIN COM_DocTextData  T  with(nolock)  ON  D.invdocdetailsid=T.invdocdetailsid 
LEFT JOIN COM_DocccData  CC  with(nolock)  ON  D.invdocdetailsid=CC.invdocdetailsid 
LEFT JOIN COM_LOCATION L  with(nolock) ON L.NODEID=CC.DCCCNID2 
WHERE D.InvDocDetailsID IN 
(SELECT InvDocDetailsID FROM COM_DocTextData  with(nolock) where dcalpha1  COLLATE DATABASE_DEFAULT in (select dcAlpha3 from #MRDET1))
 and d.productid in (select productid from #mrdet3)
AND CostCenterID IN (40005) AND VOUCHERTYPE=-1
--GROUP BY CostCenterID,  D.InvDocDetailsID, LinkedInvDocDetailsID, DocumentType, VOUCHERNO,  DOCDATE , T.DCALPHA1
  
 
--MATERIAL ISSUE INVOICE
CREATE TABLE #MATISSUE(COSTCENTERID BIGINT, INVDOCDETAILSID BIGINT, LINKEDINVDOCDETAILSID BIGINT, 
DOCUMENTTYPE BIGINT, VoucherNo NVARCHAR(max), DOCDATE DATETIME, QUANTITY FLOAT,VEHICLEREGNO NVARCHAR(max),
PRODUCTID BIGINT, REGID BIGINT ) 

INSERT INTO #MATISSUE (COSTCENTERID , INVDOCDETAILSID , LINKEDINVDOCDETAILSID , DOCUMENTTYPE , VoucherNo , DOCDATE , QUANTITY, VEHICLEREGNO, PRODUCTID, REGID)
SELECT D.CostCenterID,  D.InvDocDetailsID, D.LinkedInvDocDetailsID, D.DocumentType, D.VOUCHERNO, CONVERT(DATETIME, D.DOCDATE),D.QUANTITY , T.DCALPHA3,d.ProductID, cc.dcCCNID43
FROM INV_DocDetails  D  with(nolock) 
LEFT JOIN COM_DocTextData  T with(nolock)  ON  D.invdocdetailsid=T.invdocdetailsid 
LEFT JOIN COM_DocCCData  cc with(nolock)  ON  D.invdocdetailsid=cc.invdocdetailsid 
--left join #MRDET3 GRD ON T.dcAlpha3 COLLATE DATABASE_DEFAULT =GRD.vehicleregno AND D.ProductID=GRD.PRODUCTID
WHERE cc.dcCCNID43 in (select REGID from #MRDET3 a where a.PRODUCTID=d.ProductID)
AND D.CostCenterID IN (41002,41006)
--D.InvDocDetailsID IN 
--(SELECT InvDocDetailsID FROM COM_DocCCData  with(nolock) where dcalpha3  COLLATE DATABASE_DEFAULT in
--(select vehicleregno from #MRDET3 a where a.PRODUCTID=d.ProductID))

--GROUP BY CostCenterID,  D.InvDocDetailsID, LinkedInvDocDetailsID, DocumentType, VOUCHERNO,  DOCDATE , T.DCALPHA3
  
 
--MATERIAL RETURN INVOICE
CREATE TABLE #MATRETURN(COSTCENTERID BIGINT, INVDOCDETAILSID BIGINT, LINKEDINVDOCDETAILSID BIGINT, DOCUMENTTYPE BIGINT, 
VoucherNo NVARCHAR(max), DOCDATE DATETIME, QUANTITY FLOAT,PRODUCTID BIGINT )

INSERT INTO #MATRETURN (COSTCENTERID , INVDOCDETAILSID , LINKEDINVDOCDETAILSID , DOCUMENTTYPE , VoucherNo , DOCDATE , QUANTITY,PRODUCTID)
SELECT D.CostCenterID, D.InvDocDetailsID, D.LinkedInvDocDetailsID, D.DocumentType, D.VOUCHERNO, CONVERT(DATETIME, D.DOCDATE),D.QUANTITY,D.PRODUCTID
FROM INV_DocDetails D with(nolock) 
LEFT JOIN #MATISSUE MISSUE ON MISSUE.LinkedInvDocDetailsID=d.InvDocDetailsID
WHERE  d.CostCenterID IN (41017) AND d.PRODUCTID=MISSUE.PRODUCTID
--GROUP BY CostCenterID, InvDocDetailsID, LinkedInvDocDetailsID, DocumentType, VOUCHERNO,  DOCDATE
  
--SALES INVOICE
CREATE TABLE #SINVOICE(COSTCENTERID BIGINT, INVDOCDETAILSID BIGINT, LINKEDINVDOCDETAILSID BIGINT, DOCUMENTTYPE BIGINT, 
VoucherNo NVARCHAR(max), DOCDATE DATETIME, QUANTITY FLOAT, rate FLOAT,PRODUCTID BIGINT, REGID BIGINT) 

INSERT INTO #SINVOICE (COSTCENTERID , INVDOCDETAILSID , LINKEDINVDOCDETAILSID , DOCUMENTTYPE , VoucherNo , DOCDATE , QUANTITY, rate,PRODUCTID,REGID)
SELECT D.CostCenterID, D.InvDocDetailsID, D.LinkedInvDocDetailsID, D.DocumentType, D.VOUCHERNO, CONVERT(DATETIME, D.DOCDATE),
D.QUANTITY, D.Rate,D.PRODUCTID, cc.dcCCNID43
FROM INV_DocDetails D with(nolock) 
LEFT JOIN COM_DocCCData  cc with(nolock)  ON  D.invdocdetailsid=cc.invdocdetailsid 
LEFT JOIN #MATISSUE MISSUE ON MISSUE.LinkedInvDocDetailsID=D.InvDocDetailsID
WHERE   D.CostCenterID IN (40011,41011) AND D.PRODUCTID=MISSUE.PRODUCTID
--GROUP BY CostCenterID, InvDocDetailsID, LinkedInvDocDetailsID, DocumentType, VOUCHERNO,  DOCDATE,rate
 
 
SELECT --t1.COSTCENTERID, INVDOCDETAILSID, LINKEDINVDOCDETAILSID, DOCUMENTTYPE,
t1.VOUCHERNO AS DocNo, t1.DOCDATE as DocDate, CASE WHEN (T1.STATUSID=372) THEN T1.VOUCHERNO END MRREJECTEDNO, 
CASE WHEN (T1.STATUSID=372) THEN T1.DOCDATE END MRREJECTEDDATE, t1.INVDOCDETAILSID,
--t1.dcAlpha3 as VEHICLEREGNO,
regno.Name as VEHICLEREGNO,
v.Make MAKE, V.Model MODEL, V.Variant VARIANT, ISNULL(V.StartYear,'') +'-'+ISNULL(V.EndYear,'-') YEAR,
 --t1.dcAlpha6 MAKE, t1.dcAlpha7 MODEL,t1.dcAlpha8 VARIANT,t1.dcAlpha9 as YEAR,
t1.ProductCode as PartNo, t1.ProductName as ProductName, t1.CCNID40Name  JobCardNo, t1.CCNID23Name Manufacturer,t1.CCNID2Name Location , 
t1c.VoucherNo MRDCDOCNO, t1c.DocDate MRDCDOCDATE, 
t2.VOUCHERNO as PONo, t2.DOCDATE as PODate, 
t2c.VoucherNo POCDOCNO, t2c.DocDate POCDOCDATE,t2c.quantity POCancelledQty,
t2.Quantity as OrderQty,t2.RATE as POUnitPrice,t2.STOCKVALUE as POValue, 
t2.VENDOR VendorName,t2.dcalpha17 as BillTo,t2.dcalpha16 as ShipTo , t2.dcalpha3 as CreditDays, 
t3.VOUCHERNO as GRNo, t3.DOCDATE as GRDate,t3.quantity grqty,
t3.Quantity as QtyReceived,t3.RATE,t3.STOCKVALUE,
t3.dcalpha14 as TransportName,t3.dcAlpha18 as LRNo,t3.dcAlpha19 as ShipmentDate, t3.dcCalcNum2    as FreightAmount, 
t5.VoucherNo GRRDOCNO, t5.DOCDATE GRRDOCDATE, t5.quantity GoodsReturnedQty,
t4.VoucherNo PInvNo, t4.DOCDATE PInvDate, ST.VOUCHERNO STOCKTRANSFERNO, ST.DOCDATE STOCKTRANSFERDATE,
t4.BILLNO BillNo, t4.BILLDATE BillDate, t4.PIVRATE PIUnitPrice , t4.PIVVALUE PIValue, t4.PIVDUEDATE DueDate, 
t4c.VoucherNo PIVCDOCNO, t4c.DocDate PIVCDOCDATE,  PIVRET.VOUCHERNO PurchaseReturnNo,
PIVRET.DOCDATE PurchaseReturnDate,pivret.quantity PurchaseReturnQty,
st.voucherno StockTransferNo, st.docdate StockTransferDate, st.quantity StockTransferQty, st.tolocation StockTransferLocation,
t5.VoucherNo, t5.DOCDATE ,
t5.ReceivedBy CreatedBy, t5.RETURNDATE RejectedDate, t5.dcalpha14 GRTransportDetails  , 
t4MISSUE.VoucherNo MATISSUEDOCNO, t4MISSUE.DOCDATE MATISSUEDOCDATE, t4MISSUE.QUANTITY MATISSUEQUANTITY, 
isnull(t3.quantity,0)-isnull(t4MISSUE.QUANTITY,0) PendingIssueQty,
tRETURN.VoucherNo MATRETURNEDDOCNO, tRETURN.DOCDATE MATRETURNEDDOCDATE,tRETURN.QUANTITY MATRETURNQUANTITY,
SINVOICE.VoucherNo SALESISSUEDOCNO, SINVOICE.DOCDATE SALESISSUEDOCDATE , t4.PIVRATE PurchasePrice,
SINVOICE.rate SalesPrice, (SINVOICE.rate-t4.PIVRATE)/t4.PIVRATE*100 Margin,t2.dcalpha30 CheckedStatus
FROM #MRDET1 t1  
left join SVC_Vehicle  v with(nolock)  on t1.VehicleID=v.vehicleid
left join COM_CC50043 regno with(nolock) on t1.REGID= regno.NodeID
left join #MRDCAN t1c on t1.invdocdetailsid=t1c.linkedinvdocdetailsid
left join #MRDET2 t2 on t1.invdocdetailsid=t2.linkedinvdocdetailsid
left join #POCAN t2c on t2.invdocdetailsid=t2c.linkedinvdocdetailsid
left join #MRDET3 t3 on t2.invdocdetailsid=t3.linkedinvdocdetailsid
left join #MRDET4 t4 on t3.invdocdetailsid=t4.linkedinvdocdetailsid
left join #PIVCAN PIVRET on t4.invdocdetailsid=PIVRET.linkedinvdocdetailsid
left join #MRDET4 t4c on t4.invdocdetailsid=t4c.linkedinvdocdetailsid
left join #MRDET5 t5 on t3.invdocdetailsid=t5.linkedinvdocdetailsid
LEFT JOIN #ST ST ON ST.REGID=T3.REGID
left join #MATISSUE t4MISSUE on t4MISSUE.REGID =t3.REGID and t4MISSUE.PRODUCTID=t3.PRODUCTID
left join #MATRETURN tRETURN on t4MISSUE.invdocdetailsid=tRETURN.linkedinvdocdetailsid
left join #SINVOICE  SINVOICE on t4MISSUE.invdocdetailsid=SINVOICE.linkedinvdocdetailsid



DROP TABLE #MRDET1 
DROP TABLE #MRDET2
DROP TABLE #MRDET3
DROP TABLE #MRDET4
DROP TABLE #MRDET5
DROP TABLE #MRDCAN
DROP TABLE #POCAN
DROP TABLE #PIVCAN
DROP TABLE #MATISSUE
DROP TABLE #MATRETURN
DROP TABLE #SINVOICE 
DROP TABLE #ST
DROP TABLE #loc
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

USE PACT2C222
GO
SET ANSI_NULLS, QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spRPT_Services]
	@FromDate [datetime],
	@ToDate [datetime],
	@LocationWHERE [nvarchar](max) = NULL,
	@ReportID [int],
	@GID [bigint],
	@GCondition [nvarchar](max) = null,
	@LangID [int] = 1
WITH ENCRYPTION, EXECUTE AS CALLER
AS
BEGIN TRY      
SET NOCOUNT ON;      
  DECLARE @SQL NVARCHAR(MAX)   
  
 DECLARE @From FLOAT,@To FLOAT  
  
 SET @From=CONVERT(FLOAT,@FromDate)  
 SET @To=CONVERT(FLOAT,@ToDate)  
   
  if(@ReportID=129)  
  begin    
 set @SQL='select row_number() over (order by T.ARRIVALDATETIME) SLNO,    
   convert(datetime, ArrivalDateTime) as DATE, '''' RONO,  
   cv.platenumber as VEHICLENO,  
   CONVERT(NVARCHAR, T.Odometerin ) +''-''+CONVERT(NVARCHAR,T.OdometerOut) as MAILAGE,  
   C.CUSTOMERNAME AS CUSTOMERNAME,   
   CON.ADDRESS1+'', '' + CON.ADDRESS2+'', '' +CON.ADDRESS3+'', '' +CON.CITY+'', ''+CON.STATE +'', ''+ CON.ZIP AS ADDRESS,  
   con.phone1 as PHONENO,   
   ST.SERVICENAME TYPEOFSERVICE,  
   (SELECT  SUM(isnull(ESTIMATEAMT,0)) FROM SVC_SERVICETICKETBILL WITH(NOLOCK) WHERE SERVICETICKETID=t.serviceticketid) AS ESTIMATEAMOUNT,  
   Convert(datetime,t.estimateDatetime) as PROMISEDDATEOfDELIVERY,  
   Convert(datetime,t.deliveryDatetime) as VEHICLEREADYDATE,  
   (SELECT TOP 1 VOUCHERNO FROM INV_DOCDETAILS WITH(NOLOCK) WHERE RefNodeid=t.CCTicketID and refCCID=59  
   and costcenterid in (select value from com_costcenterpreferences WITH(NOLOCK)  where costcenterid=59 and name =''ServiceInvoiceDocument'')) AS INVOICENO,  
   (SELECT SUM(GROSS) FROM INV_DOCDETAILS WITH(NOLOCK) WHERE RefNodeid=t.CCTicketID and refCCID=59  
   and costcenterid in (select value from com_costcenterpreferences WITH(NOLOCK) where costcenterid=59 and name =''ServiceInvoiceDocument'')) AS INVOICEAMT,  
   '''' as GATEPASSNO,  
   Convert(datetime,t.ACTUALDELIVERYDATETIME) AS DATEOFDELIVERY,  
   '''' REMARKS  
   from svc_serviceticket t  WITH(NOLOCK) 
   LEFT JOIN SVC_SERVICETICKETBILL TB WITH(NOLOCK) ON T.SERVICETICKETID= TB.SERVICETICKETID  
   left JOIN SVC_ServiceDetails SD WITH(NOLOCK) ON T.ServiceTicketID= SD.ServiceTicketID  
   LEFT JOIN SVC_ServiceTypes ST WITH(NOLOCK) ON SD.SERVICETYPEID=ST.SERVICETYPEID   
   left join svc_customersvehicle cv WITH(NOLOCK) on t.customervehicleid=cv.cv_id  
   LEFT JOIN SVC_CUSTOMERS C WITH(NOLOCK) ON CV.CUSTOMERID=C.CUSTOMERID  
   LEFT JOIN COM_CONTACTS CON WITH(NOLOCK) ON C.CUSTOMERID=CON.FEATUREPK AND CON.FEATUREID=51  
   where t.ArrivalDateTime BETWEEN '+CONVERT(NVARCHAR,@From)+' AND '+CONVERT(NVARCHAR,@To)+' '+ @LocationWhere +'  
   ORDER BY T.ARRIVALDATETIME   
   '  
   
 -- print (@SQL)  
  exec(@SQL)  
  end  
  else  if(@ReportID = 130)  
   BEGIN   
     
    
     
  SET @SQL='SELECT COUNT(ServiceTicketID) AS  NO_OF_VEHICLES_RECEIVED ,CONVERT(NVARCHAR(12), CONVERT(DATETIME, ArrivalDateTime)) RecievedDate 
   FROM  SVC_ServiceTicket   WITH(NOLOCK) 
   WHERE ArrivalDateTime IS NOT NULL AND ArrivalDateTime <>'''' and     ArrivalDateTime  >= '''+ CONVERT(NVARCHAR, convert(float,@FromDate)) +''' AND   ArrivalDateTime <= '''+ CONVERT(NVARCHAR, convert(float,@ToDate))   +''' '   
     
   IF @LocationWHERE<>''  
   BEGIN  
   SET @SQL = @SQL + ' and LocationID  IN ('+ @LocationWHERE +') GROUP BY ArrivalDateTime;'  
   END  
   ELSE  
   BEGIN  
   SET @SQL = @SQL + ' GROUP BY ArrivalDateTime;'   
   END   
   
   
   
   SET @SQL = @SQL + ' SELECT COUNT(ServiceTicketID) AS  NO_OF_VEHICLES_DELIVERED ,CONVERT(NVARCHAR(12), CONVERT(DATETIME, ActualDeliveryDateTime)) DeliveryDate  FROM  SVC_ServiceTicket   WITH(NOLOCK) 
   WHERE ActualDeliveryDateTime IS NOT NULL AND ActualDeliveryDateTime <>'''' and     ActualDeliveryDateTime  >= '''+ CONVERT(NVARCHAR, convert(float,@FromDate)) +''' AND   ActualDeliveryDateTime <= '''+ CONVERT(NVARCHAR, convert(float,@ToDate))   +'''  AND ServiceTicketTypeID = 4 '  
     
   IF @LocationWHERE<>''  
   BEGIN  
    SET @SQL = @SQL + ' and LocationID  IN ('+ @LocationWHERE +') GROUP BY ActualDeliveryDateTime;'  
   END  
   ELSE  
   BEGIN  
    SET @SQL = @SQL + ' GROUP BY ActualDeliveryDateTime;'   
   END   
 
   SET @SQL = @SQL + ' SELECT COUNT(ServiceTicketID) AS  NO_OF_VEHICLES_PENDING,CONVERT(NVARCHAR(12), CONVERT(DATETIME, DeliveryDateTime)) DeliveryPending  FROM  SVC_ServiceTicket   WITH(NOLOCK) 
   WHERE DeliveryDateTime IS NOT NULL AND DeliveryDateTime <>'''' and     DeliveryDateTime  >= '''+ CONVERT(NVARCHAR, convert(float,@FromDate)) +''' AND   DeliveryDateTime <= '''+ CONVERT(NVARCHAR, convert(float,@ToDate))   +'''  AND (ActualDeliveryDateTime IS  NULL or ActualDeliveryDateTime ='''') AND ServiceTicketTypeID <> 4 '   
     
   IF @LocationWHERE<>''  
   BEGIN  
    SET @SQL = @SQL + ' and LocationID  IN ('+ @LocationWHERE +') GROUP BY DeliveryDateTime;'  
   END  
   ELSE  
   BEGIN  
    SET @SQL = @SQL + ' GROUP BY DeliveryDateTime;'   
   END   
  
   SET @SQL = @SQL + ' SELECT distinct CONVERT(NVARCHAR(12), CONVERT(DATETIME, A.ArrivalDateTime)) AS DATE  , 0 AS NO_OF_VEHICLES_RECEIVED , 0  AS NO_OF_VEHICLES_DELIVERED  
                 ,  0 AS NO_OF_VEHICLES_PENDING , SUM(B.LABORCHARGE+B.LABORDISCOUNT+B.SHOPSUPPLIESAMT+B.FINALINSUREDAMT+B.DCCALCNUM5+B.DCCALCNUM7+B.DCCALCNUM6+B.DCCALCNUM8) AS LABOUR_BILLING , SUM(B.VALUE+B.DCCALCNUM2+B.SHOPSUPPLIESAMT+B.FINALINSUREDAMT)
 AS PARTS_BILLING ,   
                SUM(B.LABORCHARGE+B.LABORDISCOUNT+B.SHOPSUPPLIESAMT+B.FINALINSUREDAMT+B.DCCALCNUM5+B.DCCALCNUM7+B.DCCALCNUM6+B.DCCALCNUM8) + SUM(B.VALUE+B.DCCALCNUM2) AS TOTAL_BILL  FROM SVC_ServiceTicket A   WITH(NOLOCK) 
   JOIN SVC_ServicePartsInfo B WITH(NOLOCK) ON A.ServiceTicketID = B.ServiceTicketID WHERE A.ArrivalDateTime IS NOT NULL AND A.ArrivalDateTime <>'''' and  A.ArrivalDateTime  >= '''+ CONVERT(NVARCHAR, convert(float,@FromDate)) +''' AND   A.ArrivalDateTime <= '''+ CONVERT(NVARCHAR, convert(float,@ToDate))   +''''  
     
   IF @LocationWHERE<>''  
   BEGIN  
    SET @SQL = @SQL + ' and A.LocationID  IN ('+ @LocationWHERE +')  GROUP BY CONVERT(NVARCHAR(12), CONVERT(DATETIME, A.ArrivalDateTime)) ; '  
   END 
   ELSE 
    BEGIN  
    SET @SQL = @SQL + ' GROUP BY CONVERT(NVARCHAR(12), CONVERT(DATETIME, A.ArrivalDateTime))  '   
   END  
     
-- SELECT @SQL  
  EXEC(@SQL)   
   END  
   ELSE IF (@ReportID = 131)  
   BEGIN   
  SET @SQL='SELECT  distinct  row_number() over (order by TCKT.ARRIVALDATETIME) SNO, convert(varchar(12), convert(datetime,TCKT.ArrivalDateTime)) as  ArrivalDate, '''' RO_NO ,custVeh.PlateNumber VehicleNo  
  ,  ST.ServiceName ServiceType,  TCKT.CustomerVehicleID ,L.NAME AS ReasonDelay ,'''' Remarks,TCKT.ArrivalDateTime FROM   
  dbo.SVC_ServiceTicketDatesComm D  WITH(NOLOCK) 
  LEFT JOIN COM_LOOKUP L WITH(NOLOCK) ON L.NODEID=D.DATECHANGEREASON  
  LEFT JOIN SVC_ServiceTicket TCKT WITH(NOLOCK) ON D.ServiceTicketID  =TCKT.ServiceTicketID  
  LEFT JOIN SVC_ServiceDetails SD WITH(NOLOCK) ON SD.ServiceTicketID  =TCKT.ServiceTicketID  
  LEFT JOIN SVC_ServiceTypes ST WITH(NOLOCK) ON SD.SERVICETYPEID= ST.SERVICETYPEID  
  LEFT JOIN SVC_CustomersVehicle custVeh WITH(NOLOCK) on custVeh.CV_ID = TCKT.CustomerVehicleID   
  WHERE DATECHANGEREASON > 0  AND  TCKT.ArrivalDateTime  >= ''' + CONVERT(NVARCHAR, convert(float,@FromDate)) + '''  AND     TCKT.ArrivalDateTime <= '''+ CONVERT(NVARCHAR, convert(float,@ToDate))+  ''''  
  IF @LocationWHERE<>''  
  BEGIN  
   SET @SQL = @SQL + ' and A.LocationID  IN ('+ @LocationWHERE +')  group by convert(varchar(12), convert(datetime,TCKT.ArrivalDateTime)), TCKT.ArrivalDateTime   
   ,convert(varchar(12), convert(datetime, D.createdDate)) ,L.NAME , TCKT.CustomerVehicleID ,custVeh.PlateNumber, ST.ServiceName  order by  TCKT.ArrivalDateTime  '  
  END  
  BEGIN  
   SET @SQL = @SQL + ' group by convert(varchar(12), convert(datetime,TCKT.ArrivalDateTime)) , TCKT.ArrivalDateTime  
   ,convert(varchar(12), convert(datetime, D.createdDate)) ,L.NAME , TCKT.CustomerVehicleID ,custVeh.PlateNumber, ST.ServiceName order by  TCKT.ArrivalDateTime   '   
  END  
       
    
  EXEC(@SQL)   
   END  
   ELSE IF (@ReportID=133)  
   BEGIN  
  SET @SQL='select row_number() over (order by T.ARRIVALDATETIME)  SLNO,  
  convert(nvarchar(12), convert(datetime, t.arrivaldatetime)) as DATE,  
   '''' RONO,   
   REPLACE(CV.PLATENUMBER,''-'','''') VEHICLENO,  
   st.servicename TYPEOFSERVICE,  
   C.CUSTOMERNAME,  
   CON.PHONE1 AS PHONENO ,  
   CONVERT(DATETIME, ESTIMATEDATETIME) AS PROMISEDDATETIMEOFDELIVERY,   
   '''' REPAIRESTIMATION,  
   CONVERT(DATETIME, ACTUALDELIVERYDATETIME) ACTUALDATETIMEOFDELIVEY,  
   (SELECT SUM(GROSS) FROM SVC_SERVICEPARTSINFO  WITH(NOLOCK) WHERE SERVICETICKETID=T.SERVICETICKETID)    BILLAMOUNT,  
   '''' REMARKS  
   from svc_serviceticket t  WITH(NOLOCK) 
   LEFT JOIN SVC_SERVICEDETAILS SD WITH(NOLOCK) ON SD.SERVICETICKETID= T.SERVICETICKETID  
   LEFT JOIN SVC_SERVICETYPES ST WITH(NOLOCK) ON SD.SERVICETYPEID=ST.SERVICETYPEID  
   LEFT JOIN SVC_CUSTOMERSVEHICLE CV WITH(NOLOCK) ON T.CUSTOMERVEHICLEID= CV.CV_ID  
   LEFT JOIN SVC_CUSTOMERS C WITH(NOLOCK) ON CV.CUSTOMERID=C.CUSTOMERID  
   LEFT JOIN COM_CONTACTS CON WITH(NOLOCK) ON C.CUSTOMERID=CON.FEATUREPK AND CON.FEATUREID=51  
   where t.ArrivalDateTime BETWEEN '+CONVERT(NVARCHAR,@From)+' AND '+CONVERT(NVARCHAR,@To)+' '+ @LocationWhere +'  
   order by t.serviceticketid '  
   PRINT @SQL  
   EXEC(@SQL)   
   END  
    ELSE IF (@ReportID=134)  
   BEGIN  
  SET @SQL=' SELECT  row_number() over (order by SrvTckt.ArrivalDateTime  ) SNO ,     
   '''' RO_NO , custVeh.PlateNumber VehicleNo  
  ,     SrvTckt.CustomerVehicleID  ,'''' Remarks,  (Veh.Make+''-''+Veh.Model) AS MakeModel  ,  
   (InvPrd.ProductCode+''-''+InvPrd.ProductName) PART_DISCRIPTION ,   
   DocText.dcAlpha12 EXPECTEDDATEOFRECEIPT , '''' Remarks  
  ,InvDoc.InvDocDetailsID ,SrvTckt.ArrivalDateTime  FROM SVC_ServiceTicket SrvTckt   WITH(NOLOCK) 
  LEFT JOIN SVC_CustomersVehicle custVeh WITH(NOLOCK) on custVeh.CV_ID = SrvTckt.CustomerVehicleID   
  LEFT JOIN SVC_ServicePartsinfo PartsInfo WITH(NOLOCK) on PartsInfo.ServiceTicketID = SrvTckt.ServiceTicketID   
  LEFT JOIN INV_Product InvPrd WITH(NOLOCK) on InvPrd.Productid = PartsInfo.Productid  
  LEFT JOIN  SVC_Vehicle Veh WITH(NOLOCK) on   Veh.VehicleID  = SrvTckt.VehicleID   
  LEFT JOIN INV_DOCDETAILS InvDoc WITH(NOLOCK) on InvDoc.RefNodeID = SrvTckt.CCTICKETID and refccid = 59  AND InvDoc.COSTCENTERID in (SELECT value FROM COM_COSTCENTERPREFERENCES  WITH(NOLOCK) WHERE COSTCENTERID = 59 AND NAME = ''MaterialProcureDocument'')  
  JOIN COM_DocTextData DocText WITH(NOLOCK) on DocText.InvDocDetailsID = InvDoc.InvDocDetailsID  where SrvTckt.ArrivalDateTime  >= ''' + CONVERT(NVARCHAR, convert(float,@FromDate)) + '''  AND     SrvTckt.ArrivalDateTime <= '''+ CONVERT(NVARCHAR, convert(float,@ToDate
))+  ''''  
  IF @LocationWHERE<>''  
  BEGIN  
   SET @SQL = @SQL + ' and SrvTckt.LocationID  IN ('+ @LocationWHERE +')     order by SrvTckt.ArrivalDateTime ; '  
  END  
  ELSE  
  BEGIN  
   SET @SQL = @SQL + '   order by SrvTckt.ArrivalDateTime ; '  
  END   
  -- SELECT @SQL  
  print @SQL  
   EXEC(@SQL)   
   END  
   ELSE IF (@ReportID=135)  
   BEGIN  
  SET @SQL='select row_number() over (order by T.ARRIVALDATETIME)  SLNO,  
  convert(nvarchar(12), convert(datetime, t.arrivaldatetime)) as DATE,  
   '''' RONO,   
   REPLACE(CV.PLATENUMBER,''-'','''') VEHICLENO,  
   st.servicename TYPEOFSERVICE,  
   CONVERT(DATETIME, ESTIMATEDATETIME) AS PROMISEDDATETIMEOFDELIVERY,   
   '''' REPAIRESTIMATION,  
   CONVERT(DATETIME, DELIVERYDATETIME) VEHICLEREADYTIME,  
    '''' REMARKS  
   from svc_serviceticket t  WITH(NOLOCK) 
   LEFT JOIN SVC_SERVICEDETAILS SD WITH(NOLOCK) ON SD.SERVICETICKETID= T.SERVICETICKETID  
   LEFT JOIN SVC_SERVICETYPES ST WITH(NOLOCK) ON SD.SERVICETYPEID=ST.SERVICETYPEID  
   LEFT JOIN SVC_CUSTOMERSVEHICLE CV WITH(NOLOCK) ON T.CUSTOMERVEHICLEID= CV.CV_ID  
   LEFT JOIN SVC_CUSTOMERS C WITH(NOLOCK) ON CV.CUSTOMERID=C.CUSTOMERID  
   LEFT JOIN COM_CONTACTS CON WITH(NOLOCK) ON C.CUSTOMERID=CON.FEATUREPK AND CON.FEATUREID=51  
   where t.ArrivalDateTime BETWEEN '+CONVERT(NVARCHAR,@From)+' AND '+CONVERT(NVARCHAR,@To)+' '+ @LocationWhere +'  
   order by t.serviceticketid '  
   PRINT @SQL  
   EXEC(@SQL)   
   END  
   ELSE IF (@ReportID=136)  
   BEGIN  
  SET @SQL='select row_number() over (order by T.ARRIVALDATETIME)  SLNO,   
   '''' RONO,   
   REPLACE(CV.PLATENUMBER,''-'','''') VEHICLENO,  
   st.servicename TYPEOFSERVICE,  
   '''' DEMANDEDREPAIRS ,  
   '''' MECHANICAL ,  
   '''' ELECTRICAL ,  
   '''' DOORS ,  
   '''' WASHING ,  
   '''' ROADTEST ,  
    '''' REMARKS  
   from svc_serviceticket t  WITH(NOLOCK) 
   LEFT JOIN SVC_SERVICEDETAILS SD WITH(NOLOCK) ON SD.SERVICETICKETID= T.SERVICETICKETID  
   LEFT JOIN SVC_SERVICETYPES ST WITH(NOLOCK) ON SD.SERVICETYPEID=ST.SERVICETYPEID  
   LEFT JOIN SVC_CUSTOMERSVEHICLE CV WITH(NOLOCK)  ON T.CUSTOMERVEHICLEID= CV.CV_ID  
   LEFT JOIN SVC_CUSTOMERS C WITH(NOLOCK) ON CV.CUSTOMERID=C.CUSTOMERID  
   LEFT JOIN COM_CONTACTS CON WITH(NOLOCK) ON C.CUSTOMERID=CON.FEATUREPK AND CON.FEATUREID=51  
   where t.ArrivalDateTime BETWEEN '+CONVERT(NVARCHAR,@From)+' AND '+CONVERT(NVARCHAR,@To)+' '+ @LocationWhere +'  
   order by t.serviceticketid '  
   PRINT @SQL  
   EXEC(@SQL)   
   END  
    ELSE IF (@ReportID=137)  
   BEGIN  
  SET @SQL='select row_number() over (order by T.ARRIVALDATETIME)  SLNO,   
   convert(datetime, ArrivalDateTime) as DATE ,  
   custVeh.PlateNumber VehicleNo,   
   Veh.Model  AS  Model  ,   
   C.CUSTOMERNAME  +'' & ''+ con.phone1 as CUSTOMERNAMECONTACTNO,   
  (InvPrd.ProductCode+''-''+InvPrd.ProductName) PART_DESCRIPTION ,   
  --invdoc.Voucherno as ORDERNO,    
  T.SERVICETICKETNUMBER AS ORDERNO,  
  CONVERT(NVARCHAR(12),CONVERT(DATETIME, INVDOC.DOCDATE)) AS ORDERDATE,  
  CONVERT(NVARCHAR(12),CONVERT(DATETIME, INVDOCGR.DOCDATE)) AS PARTRECEIVEDDATE,   
  '''' PARTSMANAGERSIGN,  
  CONVERT(NVARCHAR(12),CONVERT(DATETIME, T.deliverydatetime)) CUSTOMERINFORMEDDATE ,  
  '''' VEHICLEATTENDEDDATEAFTERRECEIPTOFPART,  
  '''' FACILITYMANAGERSIGN    
  --,InvDoc.InvDocDetailsID ,SrvTckt.ArrivalDateTime    
  FROM SVC_ServiceTicket T   WITH(NOLOCK) 
  LEFT JOIN SVC_CustomersVehicle custVeh WITH(NOLOCK) on custVeh.CV_ID = t.CustomerVehicleID   
  LEFT JOIN SVC_CUSTOMERS C WITH(NOLOCK) ON custVeh.CUSTOMERID=C.CUSTOMERID  
  LEFT JOIN COM_CONTACTS CON WITH(NOLOCK) ON C.CUSTOMERID=CON.FEATUREPK AND CON.FEATUREID=51  
  LEFT JOIN SVC_ServicePartsinfo PartsInfo WITH(NOLOCK) on PartsInfo.ServiceTicketID = t.ServiceTicketID   
  LEFT JOIN INV_Product InvPrd WITH(NOLOCK) on InvPrd.Productid = PartsInfo.Productid  
  LEFT JOIN  SVC_Vehicle Veh WITH(NOLOCK) on   Veh.VehicleID  = t.VehicleID   
  LEFT JOIN INV_DOCDETAILS InvDoc WITH(NOLOCK) on InvDoc.RefNodeID = t.CCTICKETID and refccid = 59    
  and InvDoc.costcenterid in (select value from com_costcenterpreferences WITH(NOLOCK) where costcenterid=59 and name =''MaterialProcureDocument'')  
  LEFT JOIN COM_DocTextData DocText WITH(NOLOCK) on DocText.InvDocDetailsID = InvDoc.InvDocDetailsID    
  LEFT JOIN INV_DOCDETAILS InvDocGR WITH(NOLOCK) on InvDoc.invdocdetailsid = InvDocGR.Linkedinvdocdetailsid and InvDocGR.refccid = 59  AND InvDocGR.DocumentType = 4   
   where t.ArrivalDateTime BETWEEN '+CONVERT(NVARCHAR,@From)+' AND '+CONVERT(NVARCHAR,@To)+' '+ @LocationWhere +'  
   order by t.serviceticketid '  
   PRINT @SQL  
   EXEC(@SQL)   
   END   
   ELSE IF (@ReportID=138)  
   BEGIN  
	  SET @SQL='SELECT  row_number() over (order by SrvTckt.ArrivalDateTime  ) SNO , CONVERT(NVARCHAR(12),CONVERT(DATETIME, SrvTckt.ArrivalDateTime )) AS Date  
	   , custVeh.PlateNumber VehicleNo,   '''' RO_NO ,  (Veh.Make+''-''+Veh.Model) AS MakeModel ,  ST.ServiceName ServiceType, ''''  ApprovalRecievedDate  
	   , (InvPrd.ProductCode+''-''+InvPrd.ProductName) PartsDetails , CONVERT(NVARCHAR(12),CONVERT(DATETIME,InvPur.DocDate))   OrderedDate ,     SrvTckt.CustomerVehicleID  ,'''' Remarks  
	   ,InvPur.InvDocDetailsID  FROM SVC_ServiceTicket SrvTckt   WITH(NOLOCK) 
	   LEFT JOIN SVC_CustomersVehicle custVeh WITH(NOLOCK) on custVeh.CV_ID = SrvTckt.CustomerVehicleID   
	   LEFT JOIN SVC_ServiceDetails SD WITH(NOLOCK) ON SD.ServiceTicketID  =SrvTckt.ServiceTicketID  
	   LEFT JOIN SVC_ServiceTypes ST WITH(NOLOCK) ON SD.SERVICETYPEID= ST.SERVICETYPEID  
	   LEFT JOIN SVC_ServicePartsinfo PartsInfo WITH(NOLOCK) on PartsInfo.ServiceTicketID = SrvTckt.ServiceTicketID   
	   LEFT JOIN INV_Product InvPrd WITH(NOLOCK) on InvPrd.Productid = PartsInfo.Productid  
	   LEFT JOIN  SVC_Vehicle Veh WITH(NOLOCK) on   Veh.VehicleID  = SrvTckt.VehicleID   
	   LEFT JOIN INV_DOCDETAILS InvDoc WITH(NOLOCK) on InvDoc.RefNodeID = SrvTckt.CCTICKETID and InvDoc.refccid = 59  AND DocumentType = 4  
	   LEFT JOIN INV_DOCDETAILS InvPur WITH(NOLOCK)  on InvPur.RefNodeID = SrvTckt.CCTICKETID and InvPur.refccid = 59  AND   InvPur.COSTCENTERID in (SELECT value FROM COM_COSTCENTERPREFERENCES  WHERE COSTCENTERID = 59 AND NAME = ''MaterialProcureDocument'')  
	   JOIN COM_DocTextData DocText WITH(NOLOCK) on DocText.InvDocDetailsID = InvPur.InvDocDetailsID where SrvTckt.ArrivalDateTime  >= ''' + CONVERT(NVARCHAR, convert(float,@FromDate)) + '''  AND     SrvTckt.ArrivalDateTime <= '''+ CONVERT(NVARCHAR, convert(float,@ToDate)
	)+  ''''  
	   IF @LocationWHERE<>''  
	   BEGIN  
		SET @SQL = @SQL + ' and SrvTckt.LocationID  IN ('+ @LocationWHERE +')     order by SrvTckt.ArrivalDateTime ; '  
	   END  
	   ELSE  
	   BEGIN  
		SET @SQL = @SQL + '   order by SrvTckt.ArrivalDateTime ; '  
	   END   
	   EXEC(@SQL)   
   END  
   ELSE IF (@ReportID=139)
   BEGIN
    SET @SQL='select row_number() over (order by T.SERVICETICKETID)  SLNO,   
		C.CUSTOMERNAME, CON.PHONE1 AS PHONE, V.MAKE,
		V.MODEL, V.VARIANT,  CV.YEAR  ,
		REPLACE(CV.PLATENUMBER,''-'','''') REGISTRATIONNUMBER, L.NAME AS LOCATION,
		CONVERT(NVARCHAR(12),CONVERT(DATETIME, T.ArrivalDateTime )) AS DATE,
		P.PRODUCTCODE +''-''+ P.PRODUCTNAME AS PARTDETAILS,
		TPARTS.GROSS AS GRANDTOTAL
		FROM
		SVC_SERVICETICKET T WITH(NOLOCK) 
		LEFT JOIN SVC_CUSTOMERSVEHICLE CV WITH(NOLOCK) ON T.CUSTOMERVEHICLEID=CV.CV_ID
		LEFT JOIN SVC_Customers C WITH(NOLOCK) ON CV.CUSTOMERID=C.CUSTOMERID
		LEFT JOIN COM_Contacts CON WITH(NOLOCK) ON C.CustomerID= CON.FEATUREPK AND CON.FEATUREID=51
		LEFT JOIN SVC_Vehicle V WITH(NOLOCK) ON CV.VehicleID=V.VehicleID
		LEFT JOIN COM_LOCATION L WITH(NOLOCK) ON T.LOCATIONID=L.NODEID
		LEFT JOIN SVC_SERVICEPARTSINFO TPARTS WITH(NOLOCK) ON T.SERVICETICKETID=TPARTS.SERVICETICKETID
		LEFT JOIN INV_PRODUCT P WITH(NOLOCK) ON TPARTS.PRODUCTID=P.ProductID
		where t.ArrivalDateTime BETWEEN '+CONVERT(NVARCHAR,@From)+' AND '+CONVERT(NVARCHAR,@To)+' '+ @LocationWhere +'  
		order by t.serviceticketid, T.ARRIVALDATETIME '  
	   PRINT @SQL  
	EXEC(@SQL)  
   
   END 
   ELSE IF (@ReportID=143)
   BEGIN
		declare @GColumn nvarchar(100), @GGroup nvarchar(100)
		if(@GID=2)
		begin
			set @GColumn = ',POV.AccountName as G1'
			set @GGroup='POV.AccountName,'
		end
		else if (@GID=3)
		begin
			set @GColumn = ',(Select ProductName from inv_product WITH(NOLOCK) where productid=PO.ProductID) as   G1'
			set @GGroup='PO.ProductID,'
		end
		else if (@GID=50002)
		begin
			set @GColumn = ',POLoc.Name as G1'
			set @GGroup='POLoc.Name,'
			end
		else if (@GID=61)
		begin
			set @GColumn = ',isnull(POVehicle.Make,'''')+''-''+isnull(POVehicle.Model,'''')+''-''+isnull(POVehicle.Variant,'''') as   G1'
			set @GGroup='POVehicle.Make,POVehicle.Model,POVehicle.Variant,'
		end
		
			
		set @SQL='	select POV.AccountName as VendorName,  POLoc.Name as Location,
		PO.VoucherNo as PONo, convert(datetime,PO.DocDate) as PODate,
		PInv.VoucherNo as PInvNo, convert(datetime,PInv.DocDate) as PInvDate,
		PInv.Billno as BillNo, Convert(datetime, PInv.BillDate) as BillDate,
		sum(PO.Quantity) as OrderQty,sum(PInv.Quantity) as QtyReceived,
		sum(PO.Quantity)-sum(PInv.Quantity) as QtyBalance,
		sum(PO.StockValue) as POValue, sum(PInv.Stockvalue) as PIValue,	
		sum(PO.StockValue)-sum(PInv.StockValue) as VarianceAmt,
		(sum(PO.StockValue)-sum(PInv.StockValue))/sum(PO.StockValue)*100 as VariancePercentage    ,
		 datediff(day,convert(datetime,PInv.BillDate) , convert(datetime,PInv.DocDate))  as PIEntryDelay,
		Bill.DocNo as AdjustedBillNo, bill.AdjAmount '+@GColumn+'
		from  inv_docdetails PO  WITH(NOLOCK) 
		left join acc_accounts POV WITH(NOLOCK) on PO.CreditAccount=POV.AccountID
		left join com_docccdata POCC WITH(NOLOCK) on PO.InvDocdetailsid= POCC.InvDocdetailsid   
		left join COM_Location POLoc WITH(NOLOCK) on POCC.dcccnid2 = POLoc.NodeID 
		left join SVC_Vehicle POVehicle WITH(NOLOCK) on POCC.VehicleID = POVehicle.VehicleID 
		left join inv_docdetails GR WITH(NOLOCK) on PO.Invdocdetailsid=GR.LinkedInvDocDetailsID AND GR.COSTCENTERID=40004
		left join inv_docdetails PInv WITH(NOLOCK) on GR.Invdocdetailsid=PInv.LinkedInvDocDetailsID AND PInv.COSTCENTERID=40001
		left join com_billwise bill WITH(NOLOCK) on PInv.VoucherNo=Bill.RefDocNo
		where PO.costcenterid=40002  and 
		PO.DocDate BETWEEN '+CONVERT(NVARCHAR,@From)+' AND '+CONVERT(NVARCHAR,@To)+' '+ @LocationWhere+'
		 Group by '+@GGroup+'PO.VoucherNo,PO.DocDate,POV.AccountName, POLoc.Name,
		 PInv.VoucherNo,PInv.DocDate,PInv.Billno,PInv.BillDate,Bill.DocNo,bill.AdjAmount'
	--	print (@SQL) 
		EXEC (@SQL)   
   END
   ELSE IF (@ReportID=145)
   BEGIN  	
		set @SQL='SELECT T0.ServiceTicketNumber AS ServiceTicketNumber,
		T1.PlateNumber AS PlateNumber,
		CONVERT(DATETIME,T0.ArrivalDateTime) AS ArrivalDateTime,
		CONVERT(DATETIME,T0.ActualDeliveryDateTime) AS ActualDeliveryDate,
		CONVERT(DATETIME,T0.ArrivalDateTime) AS A1 ,
		L1.NAME AS LOCATION
		 FROM SVC_ServiceTicket T0 with(nolock),SVC_CustomersVehicle T1 with(nolock), COM_LOCATION L1 WITH(NOLOCK)
		 WHERE T0.CustomerVehicleID=T1.CV_ID AND  T0.LOCATIONID=L1.NODEID AND
		T0.ArrivalDateTime BETWEEN '+CONVERT(NVARCHAR,@From)+' AND '+CONVERT(NVARCHAR,@To)+' '+ @LocationWhere+'
		GROUP BY L1.NAME ,T0.ServiceTicketNumber,T1.PlateNumber,T0.ArrivalDateTime,T0.ActualDeliveryDateTime' 
	--	print (@SQL) 
		EXEC (@SQL)   
   END 
   ELSE IF (@ReportID=152)
   BEGIN  	
		set @LocationWhere=replace(@LocationWhere,'AND T.LocationID IN (','')
		set @LocationWhere=replace(@LocationWhere,')','')
	 
		create table #loc(id bigint) 
		insert into #loc
		EXEC SPSplitString @LocationWhere,','

		if not exists(select id from #loc)
		insert into #loc
		select Nodeid from com_location	
			
		--GOOD RECEIVED
		CREATE TABLE #GRD(COSTCENTERID BIGINT,  VoucherNo NVARCHAR(100), DOCDATE DATETIME,PRODUCTCODE NVARCHAR(200), PRODUCTNAME NVARCHAR(500),
		Quantity FLOAT,  Rate FLOAT,vehicleregno NVARCHAR(100))

		INSERT INTO #GRD (COSTCENTERID, VOUCHERNO, DOCDATE, P.PRODUCTCODE, P.PRODUCTNAME ,Quantity,Rate,vehicleregno)
		SELECT GR.CostCenterID, VOUCHERNO, CONVERT(DATETIME, DOCDATE),P.PRODUCTCODE, part.Name,
		GR.Quantity,   GR.Rate,		GRA.DCALPHA6
		FROM INV_DocDetails GR with(nolock)
		left join com_doctextdata GRA with(nolock) on GR.InvDocdetailsid=GRA.InvDocdetailsid 
		left join com_docnumdata GRN with(nolock) on GR.InvDocdetailsid=GRN.InvDocdetailsid
		left join com_docccdata GRCC WITH(NOLOCK) on GR.InvDocdetailsid= GRCC.InvDocdetailsid   
		left join COM_Location GRLOC WITH(NOLOCK) on GRCC.dcccnid2 = GRLOC.NodeID 
		left join com_cc50029 part WITH(NOLOCK) on GRCC.dcccnid29 = part.NodeID 
		join inv_product p on gr.productid=p.productid
		WHERE  GR.CostCenterID IN (40004) and  DOCDATE BETWEEN @From AND @To AND GRCC.dcCCNID2 IN (SELECT ID FROM #LOC)
		 
		--SALES INVOICE
		CREATE TABLE #SINVOICE(COSTCENTERID BIGINT, VoucherNo NVARCHAR(100), DOCDATE DATETIME,PRODUCTCODE NVARCHAR(200), PRODUCTNAME NVARCHAR(500),
		Quantity FLOAT, Rate FLOAT,vehicleregno NVARCHAR(100))

		INSERT INTO #SINVOICE (COSTCENTERID,VOUCHERNO, DOCDATE, P.PRODUCTCODE, P.PRODUCTNAME, Quantity,Rate,
		vehicleregno	)
		SELECT SIV.CostCenterID,  VOUCHERNO, CONVERT(DATETIME, DOCDATE), P.PRODUCTCODE,part.Name,
		SIV.Quantity,   SIV.rate, SIVA.DCALPHA5
		FROM INV_DocDetails SIV with(nolock)
		left join com_doctextdata SIVA with(nolock) on SIV.InvDocdetailsid=SIVA.InvDocdetailsid 
		left join com_docnumdata SIVN with(nolock) on SIV.InvDocdetailsid=SIVN.InvDocdetailsid
		left join com_docccdata SIVCC WITH(NOLOCK) on SIV.InvDocdetailsid= SIVCC.InvDocdetailsid   
		left join COM_Location SIVLOC WITH(NOLOCK) on SIVCC.dcccnid2 = SIVLOC.NodeID 
		left join com_cc50029 part WITH(NOLOCK) on SIVCC.dcccnid29 = part.NodeID 
		join inv_product p on SIV.productid=p.productid
		WHERE CostCenterID IN (40011) and DOCDATE BETWEEN @From AND @To AND SIVCC.dcCCNID2 IN (SELECT ID FROM #LOC)
		 
		SELECT G.COSTCENTERID, G.VOUCHERNO AS GRDDOCNO,G.PRODUCTCODE, G.PRODUCTNAME, G.DOCDATE GRDDOCDATE, 
		G.Quantity GRDQTY,G.Rate GRDVALUE,G.vehicleregno GRDREGNO,
		S.COSTCENTERID,S.VOUCHERNO SIVDOCNO, S.DOCDATE SIVDOCDATE, S.Quantity SIVQTY,S.Rate SIVVALUE,S.vehicleregno SIVREGNO,
		G.QUANTITY-S.QUANTITY PENDINGQTY  ,  (S.RATE-G.RATE)/G.RATE*100  AS MARGIN
		FROM #GRD G
		LEFT JOIN #SINVOICE S ON G.VEHICLEREGNO=S.VEHICLEREGNO AND G.PRODUCTCODE=S.PRODUCTCODE
		WHERE G.VEHICLEREGNO IS NOT NULL
		
		DROP TABLE #GRD
		DROP TABLE #SINVOICE
   END
   ELSE IF (@ReportID=153)
   BEGIN  	
		set @LocationWhere=replace(@LocationWhere,'AND T.LocationID IN (','')
		set @LocationWhere=replace(@LocationWhere,')','')
	 
		create table #location(id bigint) 
		insert into #location
		EXEC SPSplitString @LocationWhere,','

		if not exists(select id from #location)
		insert into #location
		select Nodeid from com_location	
			
 		--GOOD RECEIVED
		CREATE TABLE #GOODSRECEIVED(COSTCENTERID BIGINT,  VoucherNo NVARCHAR(100), DOCDATE DATETIME,PRODUCTCODE NVARCHAR(200), PRODUCTNAME NVARCHAR(500),
		Quantity FLOAT,  Rate FLOAT,PRICENONBILLABLE FLOAT, PRICEOUTSOURCED FLOAT, PRICEBILLABLE FLOAT,	vehicleregno NVARCHAR(100),
		LOCATION NVARCHAR(100), JOBCARDNO NVARCHAR(100))

		INSERT INTO #GOODSRECEIVED (COSTCENTERID, VOUCHERNO, DOCDATE, P.PRODUCTCODE, P.PRODUCTNAME , Quantity, Rate,
		PRICENONBILLABLE, PRICEOUTSOURCED, PRICEBILLABLE,vehicleregno,LOCATION,JOBCARDNO)
		SELECT GR.CostCenterID, VOUCHERNO, CONVERT(DATETIME, DOCDATE),P.PRODUCTCODE, P.PRODUCTNAME,
		GR.Quantity,   GR.Rate,	
		CASE WHEN (PE.ptAlpha1='N') THEN (GR.Rate) ELSE (0) END PRICENONBILLABLE, 
		CASE WHEN (P.PARENTID=7531) THEN (GR.Rate) ELSE (0) END PRICEOUTSOURCED,
		CASE WHEN (PE.ptAlpha1='Y') THEN (GR.Rate) ELSE (0) END PRICEBILLABLE, GRA.DCALPHA6 ,GRLOC.NAME, J.NAME
		FROM INV_DocDetails GR with(nolock)
		left join com_doctextdata GRA with(nolock) on GR.InvDocdetailsid=GRA.InvDocdetailsid 
		left join com_docnumdata GRN with(nolock) on GR.InvDocdetailsid=GRN.InvDocdetailsid
		left join com_docccdata GRCC WITH(NOLOCK) on GR.InvDocdetailsid= GRCC.InvDocdetailsid   
		left join COM_Location GRLOC WITH(NOLOCK) on GRCC.dcccnid2 = GRLOC.NodeID 
		join inv_product p WITH(NOLOCK) on gr.productid=p.productid
		LEFT JOIN COM_CC50040 J WITH(NOLOCK) ON GRCC.DCCCNID40=J.NODEID
		JOIN INV_PRODUCTEXTENDED PE WITH(NOLOCK) ON P.PRODUCTID=PE.PRODUCTID
		WHERE  GR.CostCenterID IN (40004) and  DOCDATE BETWEEN @From AND @To AND GRCC.dcCCNID2 IN (SELECT ID FROM #location)
		 
		--SALES INVOICE
		CREATE TABLE #SALESINVOICE(COSTCENTERID BIGINT, VoucherNo NVARCHAR(100), DOCDATE DATETIME,PRODUCTCODE NVARCHAR(200), PRODUCTNAME NVARCHAR(500),
		Quantity FLOAT,  Rate FLOAT,PRICENONBILLABLE FLOAT, PRICEOUTSOURCED FLOAT, PRICEBILLABLE FLOAT,SHOPSUPPLIES FLOAT,PRICEPAINTS FLOAT,
			vehicleregno NVARCHAR(100),LOCATION NVARCHAR(100), JOBCARDNO NVARCHAR(100))

		INSERT INTO #SALESINVOICE (COSTCENTERID,VOUCHERNO, DOCDATE, P.PRODUCTCODE, P.PRODUCTNAME, Quantity,Rate,
		PRICENONBILLABLE, PRICEOUTSOURCED, PRICEBILLABLE,SHOPSUPPLIES,PRICEPAINTS, vehicleregno,LOCATION,JOBCARDNO)
		
		SELECT SIV.CostCenterID,  VOUCHERNO, CONVERT(DATETIME, DOCDATE), P.PRODUCTCODE, P.PRODUCTNAME,
		SIV.Quantity,   SIV.rate, 
		CASE WHEN (PE.ptAlpha1='N' and P.PARENTID <>7532 AND P.PARENTID<>7531) THEN (SIV.Rate) ELSE (0) END PRICENONBILLABLE, 
		CASE WHEN (P.PARENTID=7531) THEN (SIV.Rate) ELSE (0) END PRICEOUTSOURCED,
		CASE WHEN (PE.ptAlpha1='Y' and P.PARENTID <>7532 AND P.PARENTID<>7531) THEN (SIV.Rate) ELSE (0) END PRICEBILLABLE, 0 SHOPSUPPLIES,
		CASE WHEN (P.PARENTID=7532) THEN (SIV.Rate) ELSE (0) END PRICEPAINTS,
		SIVA.DCALPHA5, SIVLOC.NAME, J.NAME
		FROM INV_DocDetails SIV with(nolock)
		left join com_doctextdata SIVA with(nolock) on SIV.InvDocdetailsid=SIVA.InvDocdetailsid 
		left join com_docnumdata SIVN with(nolock) on SIV.InvDocdetailsid=SIVN.InvDocdetailsid
		left join com_docccdata SIVCC WITH(NOLOCK) on SIV.InvDocdetailsid= SIVCC.InvDocdetailsid   
		left join COM_Location SIVLOC WITH(NOLOCK) on SIVCC.dcccnid2 = SIVLOC.NodeID 
		LEFT JOIN COM_CC50040 J WITH(NOLOCK) ON SIVCC.DCCCNID40=J.NODEID
		join inv_product p on SIV.productid=p.productid
		JOIN INV_PRODUCTEXTENDED PE ON P.PRODUCTID=PE.PRODUCTID
		WHERE CostCenterID IN (40011) and DOCDATE BETWEEN @From AND @To AND SIVCC.dcCCNID2 IN (SELECT ID FROM #location)
		 
		SELECT G.COSTCENTERID, G.VOUCHERNO AS GRDDOCNO,G.PRODUCTCODE, G.PRODUCTNAME, G.DOCDATE GRDDOCDATE, G.Quantity GRDQTY,G.Rate GRDVALUE,
		G.vehicleregno GRDREGNO,G.LOCATION, G.JOBCARDNO,
		G.PRICENONBILLABLE GRDPRICENONBILLABLE, G.PRICEOUTSOURCED GRDPRICEOUTSOURCED,g.PRICEBILLABLE GRDPRICEBILLABLE,
		G.PRICENONBILLABLE+G.PRICEOUTSOURCED+G.PRICEBILLABLE TOTALPURCHASE,
		S.PRICENONBILLABLE SINVOICEPRICENONBILLABLE, S.PRICEOUTSOURCED SINVOICEPRICEOUTSOURCED,S.PRICEBILLABLE SINVOICEPRICEBILLABLE,
		S.PRICEPAINTS SINVOICEPRICEPAINTS, S.SHOPSUPPLIES, S.PRICENONBILLABLE+S.PRICEOUTSOURCED+S.PRICEBILLABLE+S.SHOPSUPPLIES+S.PRICEPAINTS TOTALSALES,
		S.COSTCENTERID,S.VOUCHERNO SIVDOCNO, S.DOCDATE SIVDOCDATE, 
		S.Quantity SIVQTY,S.Rate SIVVALUE,S.vehicleregno SIVREGNO, 
		G.QUANTITY-S.QUANTITY PENDINGQTY ,
		((((S.PRICENONBILLABLE+S.PRICEOUTSOURCED+S.PRICEBILLABLE+S.SHOPSUPPLIES+S.PRICEPAINTS)-(G.PRICENONBILLABLE+G.PRICEOUTSOURCED+G.PRICEBILLABLE))
		/(G.PRICENONBILLABLE+G.PRICEOUTSOURCED+G.PRICEBILLABLE))*100) MARGIN
		FROM #GOODSRECEIVED G
		LEFT JOIN #SALESINVOICE S ON G.VEHICLEREGNO=S.VEHICLEREGNO  AND G.PRODUCTCODE=S.PRODUCTCODE
		WHERE G.VEHICLEREGNO IS NOT NULL
		 
		DROP TABLE #GOODSRECEIVED
		DROP TABLE #SALESINVOICE
		DROP TABLE #location
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

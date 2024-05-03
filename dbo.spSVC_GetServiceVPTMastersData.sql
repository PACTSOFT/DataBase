USE PACT2C222
GO
SET ANSI_NULLS, QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spSVC_GetServiceVPTMastersData]
	@DocumentID [bigint],
	@DocumentSeqNo [bigint],
	@ExtendedDataQuery [nvarchar](max),
	@UserID [bigint],
	@UserName [nvarchar](50),
	@LangID [int] = 1
WITH ENCRYPTION, EXECUTE AS CALLER
AS
BEGIN TRY  
SET NOCOUNT ON;

	--Declaration Section
	DECLARE @HasAccess BIT, @SQL NVARCHAR(MAX),@TableName NVARCHAR(300)
	DECLARE @code NVARCHAR(200),@no BIGINT, @IsInventoryDoc BIT
	DECLARE @VoucherNo NVARCHAR(100),@VoucherType INT

	IF @DocumentID=59--SERVICE TICKET
	BEGIN			
		declare @BillNo nvarchar(200), @BillDate float
		select @BillNo=VoucherNo, @BillDate=Docdate  FROM INV_DocDetails AS DOC with(nolock)
		where RefNodeid in (select CCTicketid from svc_serviceticket where serviceticketid=@DocumentSeqNo) and refCCID=59 
		and costcenterid in (select value from com_costcenterpreferences where costcenterid=59 and name ='ServiceInvoiceDocument')
	
	CREATE TABLE [dbo].#temp(	id bigint IDENTITY(1,1) NOT NULL,	[ServicePartsInfoID] [bigint], 	[ServiceTicketID] [bigint] NOT NULL,
	[SerialNumber] [int] NOT NULL,	[ProductID] [bigint] NOT NULL,	[PartVehicleID] [bigint] NOT NULL,	[PackageID] [bigint] NOT NULL,
	[IsRequired] [bit] NOT NULL,	[Quantity] [float] NOT NULL,	[UOMID] [bigint] NOT NULL,	[Rate] [float] NOT NULL,
	[Value] [float] NOT NULL,	[LaborCharge] [float] NOT NULL,	[PartDiscount] [float] NOT NULL,	[LaborDiscount] [float] NOT NULL,
	[Gross] [float] NOT NULL,	[IsDeclined] [bit] NOT NULL,	 
	[dcNum1] [float] NOT NULL,	[dcCalcNum1] [float] NULL,	[dcNum2] [float] NOT NULL,	[dcCalcNum2] [float] NOT NULL,	[dcNum3] [float] NOT NULL,
	[dcCalcNum3] [float] NOT NULL,	[dcNum4] [float] NOT NULL,	[dcCalcNum4] [float] NOT NULL,	[dcNum5] [float] NOT NULL,	[dcCalcNum5] [float] NOT NULL,
	[dcNum6] [float] NOT NULL,	[dcCalcNum6] [float] NOT NULL,	[dcNum7] [float] NOT NULL,	[dcCalcNum7] [float] NOT NULL,	[dcNum8] [float] NOT NULL,
	[dcCalcNum8] [float] NOT NULL,	[dcNum9] [float] NOT NULL,	[dcCalcNum9] [float] NOT NULL,	[dcNum10] [float] NOT NULL,	[dcCalcNum10] [float] NOT NULL,
	[dcNum11] [float] NOT NULL,	[dcCalcNum11] [float] NOT NULL,	[dcNum12] [float] NOT NULL,	[dcCalcNum12] [float] NOT NULL,	[dcNum13] [float] NOT NULL,
	[dcCalcNum13] [float] NOT NULL,	[dcNum14] [float] NOT NULL,	[dcCalcNum14] [float] NOT NULL,	[dcNum15] [float] NOT NULL,	[dcCalcNum15] [float] NOT NULL,
	[dcNum16] [float] NOT NULL,	[dcCalcNum16] [float] NOT NULL,	[dcNum17] [float] NOT NULL,	[dcCalcNum17] [float] NOT NULL,	[dcNum18] [float] NOT NULL,
	[dcCalcNum18] [float] NOT NULL,	[dcNum19] [float] NOT NULL,	[dcCalcNum19] [float] NOT NULL,	[dcNum20] [float] NOT NULL,	[dcCalcNum20] [float] NOT NULL,
	[EstimatedQty] [float] NOT NULL,	[Link] [int] NULL,	[Parent] [int] NULL,	[SuppPartAmt] [float] NOT NULL,	[ShopSuppliesPercent] [float] NOT NULL,
	[SSLabAmt] [float] NOT NULL,	[SSLabPercent] [float] NOT NULL,	[ShopSuppliesAmt] [float] NOT NULL,	[InsPartAmount] [float] NOT NULL,
	[InsPartPercentage] [float] NOT NULL,	[InsLabAmount] [float] NOT NULL,	[InsLabPercentage] [float] NOT NULL,	[InsuredAmt] [float] NOT NULL,
	[JobOwner] [bigint] NOT NULL,	[JobAmount] [bigint] NOT NULL,	[FinalInsuredAmt] [float] NOT NULL,	[PartID] [bigint] NULL,	[Billable] [nvarchar](1) NULL,
	[UOMConversion] [float] NULL,	[UOMConversionQty] [float] NULL,	[PValue] [float] NULL,	[LValue] [float] NULL, IsPart bit, Freight float, CalcFreight float)
 
 insert into  #temp ( ServicePartsInfoID , 	ServiceTicketID , SerialNumber ,	ProductID ,	PartVehicleID ,	PackageID ,
	IsRequired ,	Quantity ,	UOMID ,	Rate ,value,	LaborCharge  ,	PartDiscount ,	LaborDiscount ,
	Gross ,	IsDeclined , dcNum1 ,	dcCalcNum1 ,	dcNum2 ,	dcCalcNum2 ,	dcNum3 ,dcCalcNum3 ,	dcNum4 ,	dcCalcNum4 ,	dcNum5 ,	dcCalcNum5 ,
	dcNum6 ,	dcCalcNum6 ,	dcNum7 ,	dcCalcNum7 ,	dcNum8 ,dcCalcNum8 ,	dcNum9 ,	dcCalcNum9 ,	dcNum10 ,	dcCalcNum10 ,dcNum11 ,	dcCalcNum11 ,	dcNum12 ,	dcCalcNum12 ,	dcNum13 ,
	dcCalcNum13 ,	dcNum14 ,	dcCalcNum14 ,	dcNum15 ,	dcCalcNum15 ,dcNum16 ,	dcCalcNum16 ,	dcNum17 ,	dcCalcNum17 ,	dcNum18 ,
	dcCalcNum18 ,	dcNum19 ,	dcCalcNum19 ,	dcNum20 ,	dcCalcNum20 ,EstimatedQty ,	Link ,	Parent ,	SuppPartAmt ,	ShopSuppliesPercent ,
	SSLabAmt ,	SSLabPercent ,	ShopSuppliesAmt ,	InsPartAmount ,InsPartPercentage ,	InsLabAmount ,	InsLabPercentage ,	InsuredAmt ,
	JobOwner ,	JobAmount ,	FinalInsuredAmt ,	PartID ,	Billable ,UOMConversion ,	UOMConversionQty ,	PValue ,	LValue  ,IsPart, Freight, CalcFreight)
 select 
  	 ServicePartsInfoID , 	ServiceTicketID , SerialNumber ,	ProductID ,	PartVehicleID ,	PackageID ,
	IsRequired ,	Quantity ,	UOMID ,	Rate ,value,	LaborCharge+dcCalcNum12 +CalcFreight,	PartDiscount ,	LaborDiscount ,
	Gross ,	IsDeclined , dcNum1 ,	dcCalcNum1 ,	dcNum2 ,	dcCalcNum2 ,	dcNum3 ,dcCalcNum3 ,	dcNum4 ,	dcCalcNum4 ,	dcNum5 ,	dcCalcNum5 ,
	dcNum6 ,	dcCalcNum6 ,	dcNum7 ,	dcCalcNum7 ,	dcNum8 ,dcCalcNum8 ,	dcNum9 ,	dcCalcNum9 ,	dcNum10 ,	dcCalcNum10 ,dcNum11 ,	dcCalcNum11 ,	dcNum12 ,	dcCalcNum12 ,	dcNum13 ,
	dcCalcNum13 ,	dcNum14 ,	dcCalcNum14 ,	dcNum15 ,	dcCalcNum15 ,dcNum16 ,	dcCalcNum16 ,	dcNum17 ,	dcCalcNum17 ,	dcNum18 ,
	dcCalcNum18 ,	dcNum19 ,	dcCalcNum19 ,	dcNum20 ,	dcCalcNum20 ,EstimatedQty ,	Link ,	Parent ,	SuppPartAmt ,	ShopSuppliesPercent ,
	SSLabAmt ,	SSLabPercent ,	ShopSuppliesAmt ,	InsPartAmount ,InsPartPercentage ,	InsLabAmount ,	InsLabPercentage ,	InsuredAmt ,
	JobOwner ,	JobAmount ,	FinalInsuredAmt ,	PartID ,	Billable ,UOMConversion ,	UOMConversionQty ,	PValue ,	LValue   ,null, Freight, CalcFreight
	from svc_servicepartsinfo WITH(NOLOCK)
 where  pvalue=0 and  lvalue=0 and serviceticketid=@DocumentSeqNo   and Billable='Y'
 
 
 insert into  #temp ( ServicePartsInfoID , 	ServiceTicketID , SerialNumber ,	ProductID ,	PartVehicleID ,	PackageID ,
	IsRequired ,	Quantity ,	UOMID ,	Rate ,value,	LaborCharge ,	PartDiscount ,	LaborDiscount ,
	Gross ,	IsDeclined , dcNum1 ,	dcCalcNum1 ,	dcNum2 ,	dcCalcNum2 ,	dcNum3 ,dcCalcNum3 ,	dcNum4 ,	dcCalcNum4 ,	dcNum5 ,	dcCalcNum5 ,
	dcNum6 ,	dcCalcNum6 ,	dcNum7 ,	dcCalcNum7 ,	dcNum8 ,dcCalcNum8 ,	dcNum9 ,	dcCalcNum9 ,	dcNum10 ,	dcCalcNum10 ,dcNum11 ,	dcCalcNum11 ,	dcNum12 ,	dcCalcNum12 ,	dcNum13 ,
	dcCalcNum13 ,	dcNum14 ,	dcCalcNum14 ,	dcNum15 ,	dcCalcNum15 ,dcNum16 ,	dcCalcNum16 ,	dcNum17 ,	dcCalcNum17 ,	dcNum18 ,
	dcCalcNum18 ,	dcNum19 ,	dcCalcNum19 ,	dcNum20 ,	dcCalcNum20 ,EstimatedQty ,	Link ,	Parent ,	SuppPartAmt ,	ShopSuppliesPercent ,
	SSLabAmt ,	SSLabPercent ,	ShopSuppliesAmt ,	InsPartAmount ,InsPartPercentage ,	InsLabAmount ,	InsLabPercentage ,	InsuredAmt ,
	JobOwner ,	JobAmount ,	FinalInsuredAmt ,	PartID ,	Billable ,UOMConversion ,	UOMConversionQty ,	PValue ,	LValue  ,IsPart, Freight, CalcFreight)
 select 
  	ServicePartsInfoID , 	ServiceTicketID , SerialNumber ,	ProductID ,	PartVehicleID ,	PackageID ,
	IsRequired ,	Quantity ,	UOMID ,	LaborCharge*(Pvalue/100) ,LaborCharge*(Pvalue/100)+dcCalcNum12,--+CalcFreight,	
	0 ,	PartDiscount ,	0 ,
	(LaborCharge*(Pvalue/100))+dcCalcNum1 ,	IsDeclined ,    dcNum1 ,	dcCalcNum1 ,
	0	dcNum2 ,0	dcCalcNum2 ,0	dcNum3 ,
0	dcCalcNum3 ,0	dcNum4 ,0	dcCalcNum4 ,0	dcNum5 ,0	dcCalcNum5 ,
	0 dcNum6 ,0	dcCalcNum6 ,0	dcNum7 ,0	dcCalcNum7 ,0	dcNum8 ,
0	dcCalcNum8 ,0	dcNum9 ,0	dcCalcNum9 ,0	dcNum10 ,0	dcCalcNum10 ,
0	dcNum11 ,0	dcCalcNum11 ,0	dcNum12 ,0	dcCalcNum12 ,0	dcNum13 ,
0	dcCalcNum13 ,	0 dcNum14 ,0	dcCalcNum14 ,0	dcNum15 ,0	dcCalcNum15 ,
0	dcNum16 ,0	dcCalcNum16 ,0	dcNum17 ,0	dcCalcNum17 ,0	dcNum18 ,
0	dcCalcNum18 ,0	dcNum19 ,0	dcCalcNum19 ,0	dcNum20 ,0	dcCalcNum20 ,
	EstimatedQty ,	Link ,	Parent ,0	SuppPartAmt ,	0ShopSuppliesPercent ,
	0 SSLabAmt ,0	SSLabPercent ,0	ShopSuppliesAmt ,0	InsPartAmount ,0
	InsPartPercentage ,0	InsLabAmount ,0	InsLabPercentage ,0	InsuredAmt ,
	JobOwner ,0	JobAmount ,0	FinalInsuredAmt ,	PartID ,	Billable ,
	UOMConversion ,	UOMConversionQty ,	PValue ,	LValue  ,1 ,0 Freight,0 CalcFreight
	from svc_servicepartsinfo WITH(NOLOCK)
 where  pvalue>0 and  lvalue>0 and serviceticketid=@DocumentSeqNo  and Billable='Y'

  
 insert into  #temp ( ServicePartsInfoID , 	ServiceTicketID , SerialNumber ,	ProductID ,	PartVehicleID ,	PackageID ,
	IsRequired ,	Quantity ,	UOMID ,	Rate ,value,	LaborCharge ,	PartDiscount ,	LaborDiscount ,
	Gross ,	IsDeclined , dcNum1 ,	dcCalcNum1 ,	dcNum2 ,	dcCalcNum2 ,	dcNum3 ,dcCalcNum3 ,	dcNum4 ,	dcCalcNum4 ,	dcNum5 ,	dcCalcNum5 ,
	dcNum6 ,	dcCalcNum6 ,	dcNum7 ,	dcCalcNum7 ,	dcNum8 ,dcCalcNum8 ,	dcNum9 ,	dcCalcNum9 ,	dcNum10 ,	dcCalcNum10 ,dcNum11 ,	dcCalcNum11 ,	dcNum12 ,	dcCalcNum12 ,	dcNum13 ,
	dcCalcNum13 ,	dcNum14 ,	dcCalcNum14 ,	dcNum15 ,	dcCalcNum15 ,dcNum16 ,	dcCalcNum16 ,	dcNum17 ,	dcCalcNum17 ,	dcNum18 ,
	dcCalcNum18 ,	dcNum19 ,	dcCalcNum19 ,	dcNum20 ,	dcCalcNum20 ,EstimatedQty ,	Link ,	Parent ,	SuppPartAmt ,	ShopSuppliesPercent ,
	SSLabAmt ,	SSLabPercent ,	ShopSuppliesAmt ,	InsPartAmount ,InsPartPercentage ,	InsLabAmount ,	InsLabPercentage ,	InsuredAmt ,
	JobOwner ,	JobAmount ,	FinalInsuredAmt ,	PartID ,	Billable ,UOMConversion ,	UOMConversionQty ,	PValue ,	LValue  ,IsPart, Freight, CalcFreight)
 select 
  	ServicePartsInfoID , 	ServiceTicketID , SerialNumber ,	ProductID ,	PartVehicleID ,	PackageID ,
	IsRequired ,	Quantity ,	UOMID ,	Rate , Value ,	LaborCharge*(Lvalue/100)+dcCalcNum12+CalcFreight ,	PartDiscount ,	LaborDiscount ,
	(LaborCharge*(Lvalue/100)) +dcCalcNum2+dcCalcNum3 +dcCalcNum4+dcCalcNum5+dcCalcNum14+CalcFreight+ShopSuppliesAmt,	IsDeclined ,
	 0 dcNum1 ,0	dcCalcNum1 ,	dcNum2 ,	dcCalcNum2 ,	dcNum3 ,
	dcCalcNum3 ,	dcNum4 ,	dcCalcNum4 ,	dcNum5 ,	dcCalcNum5 ,
	dcNum6 ,	dcCalcNum6 ,	dcNum7 ,	dcCalcNum7 ,	dcNum8 ,
	dcCalcNum8 ,	dcNum9 ,	dcCalcNum9 ,	dcNum10 ,	dcCalcNum10 ,
	dcNum11 ,	dcCalcNum11 ,	dcNum12 ,	dcCalcNum12 ,	dcNum13 ,
	dcCalcNum13 ,	dcNum14 ,	dcCalcNum14 ,	dcNum15 ,	dcCalcNum15 ,
	dcNum16 ,	dcCalcNum16 ,	dcNum17 ,	dcCalcNum17 ,	dcNum18 ,
	dcCalcNum18 ,	dcNum19 ,	dcCalcNum19 ,	dcNum20 ,	dcCalcNum20 ,
	EstimatedQty ,	Link ,	Parent ,	SuppPartAmt ,	ShopSuppliesPercent ,
	SSLabAmt ,	SSLabPercent ,	ShopSuppliesAmt ,	InsPartAmount ,
	InsPartPercentage ,	InsLabAmount ,	InsLabPercentage ,	InsuredAmt ,
	JobOwner ,	JobAmount ,	FinalInsuredAmt ,	PartID ,	Billable ,
	UOMConversion ,	UOMConversionQty ,	PValue ,	LValue ,0, Freight, CalcFreight from svc_servicepartsinfo WITH(NOLOCK)
 where  pvalue>0 and  lvalue>0 and serviceticketid=@DocumentSeqNo  and Billable='Y'
 --for non billable products
 insert into  #temp ( ServicePartsInfoID , 	ServiceTicketID , SerialNumber ,	ProductID ,	PartVehicleID ,	PackageID ,
	IsRequired ,	Quantity ,	UOMID ,	Rate ,value,	LaborCharge ,	PartDiscount ,	LaborDiscount ,
	Gross ,	IsDeclined , dcNum1 ,	dcCalcNum1 ,	dcNum2 ,	dcCalcNum2 ,	dcNum3 ,dcCalcNum3 ,	dcNum4 ,	dcCalcNum4 ,	dcNum5 ,	dcCalcNum5 ,
	dcNum6 ,	dcCalcNum6 ,	dcNum7 ,	dcCalcNum7 ,	dcNum8 ,dcCalcNum8 ,	dcNum9 ,	dcCalcNum9 ,	dcNum10 ,	dcCalcNum10 ,dcNum11 ,	dcCalcNum11 ,	dcNum12 ,	dcCalcNum12 ,	dcNum13 ,
	dcCalcNum13 ,	dcNum14 ,	dcCalcNum14 ,	dcNum15 ,	dcCalcNum15 ,dcNum16 ,	dcCalcNum16 ,	dcNum17 ,	dcCalcNum17 ,	dcNum18 ,
	dcCalcNum18 ,	dcNum19 ,	dcCalcNum19 ,	dcNum20 ,	dcCalcNum20 ,EstimatedQty ,	Link ,	Parent ,	SuppPartAmt ,	ShopSuppliesPercent ,
	SSLabAmt ,	SSLabPercent ,	ShopSuppliesAmt ,	InsPartAmount ,InsPartPercentage ,	InsLabAmount ,	InsLabPercentage ,	InsuredAmt ,
	JobOwner ,	JobAmount ,	FinalInsuredAmt ,	PartID ,	Billable ,UOMConversion ,	UOMConversionQty ,	PValue ,	LValue  ,IsPart, Freight, CalcFreight)
 select 
  	ServicePartsInfoID , 	ServiceTicketID , SerialNumber ,	ProductID ,	PartVehicleID ,	PackageID ,
	IsRequired ,	Quantity ,	UOMID ,	Rate , 0 ,	0 ,	PartDiscount ,	LaborDiscount ,
	0,	IsDeclined ,  dcNum1 ,0	dcCalcNum1 ,	dcNum2 ,0	dcCalcNum2 ,	dcNum3 , 0 dcCalcNum3 ,	dcNum4 ,0	dcCalcNum4 ,	dcNum5 ,0	dcCalcNum5 ,
	dcNum6 ,0	dcCalcNum6 ,	dcNum7 ,0	dcCalcNum7 ,	dcNum8 ,0 dcCalcNum8 ,	dcNum9 ,0	dcCalcNum9 ,	dcNum10 ,0	dcCalcNum10 ,
	dcNum11 ,0	dcCalcNum11 ,	dcNum12 ,	0 dcCalcNum12 ,	dcNum13 ,0	dcCalcNum13 ,	dcNum14 ,0	dcCalcNum14 ,	dcNum15 ,0	dcCalcNum15 ,
	dcNum16 ,0	dcCalcNum16 ,	dcNum17 ,0	dcCalcNum17 ,	dcNum18 ,0	dcCalcNum18 ,	dcNum19 ,0	dcCalcNum19 ,	dcNum20 ,	dcCalcNum20 ,
	EstimatedQty ,	Link ,	Parent ,0	SuppPartAmt ,0	ShopSuppliesPercent ,0	SSLabAmt ,	SSLabPercent ,0	ShopSuppliesAmt ,0	InsPartAmount ,
	InsPartPercentage ,0	InsLabAmount ,	InsLabPercentage ,0	InsuredAmt ,JobOwner ,0	JobAmount ,0	FinalInsuredAmt ,	PartID ,	Billable ,
	UOMConversion ,	UOMConversionQty ,	PValue ,	LValue ,0, Freight,0 CalcFreight from svc_servicepartsinfo WITH(NOLOCK)
 where serviceticketid=@DocumentSeqNo and Billable='N'
 
		
		SELECT L.Name Location,cat.Name Category,	P.value+P.LaborCharge+P.LaborDiscount+p.ShopSuppliesAmt as SubTotal, 
		(SELECT TOP 1 ResourceData FROM COM_LanguageResources WITH(NOLOCK) WHERE LanguageID=@LangID AND ResourceID=(SELECT ResourceID FROM COM_Lookup WITH(NOLOCK) WHERE NodeID=T.CustomerStatusID)) CustomerStatusID, 
		(SELECT TOP 1 ResourceData FROM COM_LanguageResources WITH(NOLOCK) WHERE LanguageID=@LangID AND ResourceID=(SELECT ResourceID FROM COM_Lookup WITH(NOLOCK) WHERE NodeID=T.ArrivalStatusID)) ArrivalStatusID, 
		CONVERT(DATETIME,T.ArrivalDateTime) ArrivalDateTime,
		CONVERT(DATETIME,T.EstimateDateTime) EstimateDateTime,
		CONVERT(DATETIME,T.DeliveryDateTime) DeliveryDateTime, 
		CONVERT(DATETIME,T.ActualDeliveryDateTime) ActualDeliveryDateTime,
		c.CustomerName as Name,CON.Phone1 as PhoneNo,   
		convert(nvarchar(10),cv.Year)+'-'+v.Make+'-'+v.Model+'-'+v.Variant as Vehicle,  convert(nvarchar(10),cv.Year) as Year,v.Make,v.Model,v.Variant,
		case when cv.PlateNumber is null or cv.PlateNumber = '' then '-' else cv.PlateNumber end as PlateNo, 
		case when cv.ChasisNumber is null or cv.ChasisNumber = '' then '-' else cv.ChasisNumber end as ChasisNumber,
		cv.OdometerIn +'-'+cv.OdometerOut as Odometer, 
		T.OdometerIn, T.OdometerOut,T.Suggestion,
		Color.Name as Color, Fuel.Name as Fuel,
		T.CreatedBy,CONVERT(DATETIME,T.CreatedDate) CreatedDate,
		T.ModifiedBy,CONVERT(DATETIME,T.ModifiedDate) ModifiedDate,
		T.*, p.ServicePartsInfoID,p.ServiceTicketID,p.SerialNumber,p.ProductID,p.PartVehicleID,p.PackageID
		,p.IsRequired,p.Quantity,p.UOMID,p.Rate,p.Value,p.LaborCharge,p.PartDiscount,p.LaborDiscount
		,p.Gross,p.IsDeclined,--p.CompanyGUID,p.GUID,p.CreatedBy,p.CreatedDate,p.ModifiedBy,p.ModifiedDate,
		p.dcNum1,p.dcCalcNum1,p.dcNum2,p.dcCalcNum2,p.dcNum3,p.dcCalcNum3,p.dcNum4,p.dcCalcNum4
		,p.dcNum5,p.dcCalcNum5,p.dcNum6,p.dcCalcNum6,p.dcNum7,p.dcCalcNum7,p.dcNum8,p.dcCalcNum8
		,p.dcNum9,p.dcCalcNum9,p.dcNum10,p.dcCalcNum10,p.dcNum11,p.dcCalcNum11,p.dcNum12,p.dcCalcNum12
		,p.dcNum13,p.dcCalcNum13,p.dcNum14,p.dcCalcNum14,p.dcNum15,p.dcCalcNum15,p.dcNum16,p.dcCalcNum16
		,p.dcNum17,p.dcCalcNum17,p.dcNum18,p.dcCalcNum18,p.dcNum19,p.dcCalcNum19,p.dcNum20,p.dcCalcNum20
		,p.EstimatedQty,p.Link,p.Parent,p.SuppPartAmt,p.ShopSuppliesPercent,p.SSLabAmt,p.SSLabPercent,p.ShopSuppliesAmt
		,p.InsPartAmount,p.InsPartPercentage,p.InsLabAmount,p.InsLabPercentage,p.InsuredAmt,p.JobOwner,p.JobAmount
		,p.FinalInsuredAmt,p.PartID,p.Billable,p.UOMConversion,p.UOMConversionQty,p.PValue,p.LValue, P.ShopSuppliesAmt as SuppAmt, 
		PRO.ProductCode, Pro.ProductName, T.CreatedBy,CONVERT(DATETIME,T.CreatedDate) CreatedDate,
		case when (Parts.Nodeid>1) then Parts.Name else '-' end as Parts  
		,ISNULL(P.Freight,0) Freight,ISNULL(P.CalcFreight,0) CalcFreight,
		t1.Name AS Technician, cat.NodeID as Category_Key, 
		(SELECT  TOP 1 REORDERLEVEL FROM COM_CCPrices WHERE CCNID6 =CAT.NodeID AND WEF IN
		(SELECT MAX(WEF) FROM COM_CCPrices WHERE CCNID6=Cat.NodeID)) ExpectedHrs, cf.Name as Relation_Name, cf.Phone as Relation_Phone,
		(select sum(PaymentAmount) from SVC_ServiceTicketBillPayment WITH(NOLOCK) where serviceticketid=T.ServiceTicketID and paymenttypeid=1)  CashAmount,
		(select sum(PaymentAmount) from SVC_ServiceTicketBillPayment WITH(NOLOCK) where serviceticketid=T.ServiceTicketID and paymenttypeid=2)  ChequeAmount,
		(select sum(PaymentAmount) from SVC_ServiceTicketBillPayment WITH(NOLOCK) where serviceticketid=T.ServiceTicketID and paymenttypeid=3)  CardAmount,
		(select sum(PaymentAmount) from SVC_ServiceTicketBillPayment WITH(NOLOCK) where serviceticketid=T.ServiceTicketID and paymenttypeid=9)  InsuranceAmount 
		,@BillNo BillNo,CASE WHEN (@BillDate>0) THEN CONVERT(datetime,@BillDate) END BillDate,0 IsExtra
		FROM SVC_ServiceTicket T WITH(NOLOCK)
		INNER JOIN #temp P WITH(NOLOCK) ON P.ServiceTicketID=T.ServiceTicketID 
		LEFT JOIN COM_Location L WITH(NOLOCK) ON L.NodeID=T.LocationID
		LEFT JOIN SVC_CustomersVehicle CV WITH(NOLOCK) on T.CustomerVehicleID=CV.CV_ID  
		LEFT JOIN SVC_Customers C WITH(NOLOCK) on CV.CustomerID=C.CustomerID   
		LEFT JOIN COM_Contacts CON WITH(NOLOCK) on CON.FeaturePK=C.CustomerID and CON.FeatureID=51
		LEFT JOIN SVC_Vehicle V WITH(NOLOCK) on CV.VehicleID=V.VehicleID	
		LEFT JOIN COM_CC50013 Color with(nolock) on cv.color=Color.nodeid
		LEFT JOIN COM_CC50014 Fuel with(nolock) on v.Fuel=Fuel.nodeid
		LEFT JOIN INV_PRODUCT PRO WITH(NOLOCK) on p.productid=pro.productid
		left join com_ccccdata cc WITH(NOLOCK) on p.ProductID=cc.NodeID and cc.costcenterid=3 
		LEFT JOIN COM_Category Cat WITH(NOLOCK) ON Cat.NodeID in (select   ccnid6 from   COM_CCCCData where CostCenterID=50029 and NodeID=P.PartID)
		left join SVC_ServiceJobsInfo j WITH(NOLOCK) on p.ServiceTicketID=j.serviceticketid and cat.Nodeid=j.PartCategoryID 
		LEFT JOIN COM_CC50019 T1 WITH(NOLOCK) ON T1.NodeID=TechnicianPrimary
		LEFT JOIN COM_CC50029 Parts with(nolock) on p.PartID=Parts.nodeid
		LEFT JOIN svc_Customerfamilydetails cf WITH(NOLOCK) ON T.FAMILYID=CF.CustomerFamilyID 
		WHERE T.ServiceTicketID=@DocumentSeqNo and P.ISDECLINED=0

		SELECT p.ServicePartsInfoID,C.Name CategoryID , p.ServiceTicketID,p.SerialNumber,  
		case when  (p.ispart is null or p.ispart=0) then INV_Product.ProductName   
		when (p.ispart=1) then	(COM_CC50029.Name+'-Paint Material')--+ (select Name from  COM_CC50029 c29 WITH(NOLOCK) where c29.nodeid =COM_CC50029.Parentid))
		end	ProductName, p.ispart,
		case when  ((p.ispart is null or p.ispart=0) and  INV_Product.ProductTypeID<>6)   then ''   
		when (p.ispart=1) then	(COM_CC50029.Name+'-'+ (select Name from  COM_CC50029 c29 WITH(NOLOCK) where c29.nodeid =COM_CC50029.Parentid))
		when (INV_Product.ProductTypeID =6) then	INV_Product.ProductCode
		end	ProductCode,
		case when (p.ispart is null or p.ispart=0) then INV_Product.ProductTypeID   
		when (p.ispart=1) then	1 end ProductTypeID,
		case when (p.ispart is null or p.ispart=0) then INV_ProductTypes.ProductType     
		when (p.ispart=1) then	'General' end ProductType, 
		p.ProductID,p.PartVehicleID,p.PackageID
		,p.IsRequired,p.Quantity,p.UOMID,p.Rate,p.Value,p.LaborCharge,p.PartDiscount,p.LaborDiscount
		,p.Gross,p.IsDeclined,--p.CompanyGUID,p.GUID,p.CreatedBy,p.CreatedDate,p.ModifiedBy,p.ModifiedDate,
		p.dcNum1,p.dcCalcNum1,p.dcNum2,p.dcCalcNum2,p.dcNum3,p.dcCalcNum3,p.dcNum4,p.dcCalcNum4
		,p.dcNum5,p.dcCalcNum5,p.dcNum6,p.dcCalcNum6,p.dcNum7,p.dcCalcNum7,p.dcNum8,p.dcCalcNum8
		,p.dcNum9,p.dcCalcNum9,p.dcNum10,p.dcCalcNum10,p.dcNum11,p.dcCalcNum11,p.dcNum12,p.dcCalcNum12
		,p.dcNum13,p.dcCalcNum13,p.dcNum14,p.dcCalcNum14,p.dcNum15,p.dcCalcNum15,p.dcNum16,p.dcCalcNum16
		,p.dcNum17,p.dcCalcNum17,p.dcNum18,p.dcCalcNum18,p.dcNum19,p.dcCalcNum19,p.dcNum20,p.dcCalcNum20
		,p.EstimatedQty,p.Link,p.Parent,p.SuppPartAmt,p.ShopSuppliesPercent,p.SSLabAmt,p.SSLabPercent,p.ShopSuppliesAmt
		,p.InsPartAmount,p.InsPartPercentage,p.InsLabAmount,p.InsLabPercentage,p.InsuredAmt,p.JobOwner,p.JobAmount
		,p.FinalInsuredAmt,p.PartID,p.Billable,p.UOMConversion,p.UOMConversionQty,p.PValue,p.LValue, P.value+P.LaborCharge+P.LaborDiscount+p.ShopSuppliesAmt as SubTotal,
		--case when (INV_Product.producttypeid=6) then INV_Product.ProductCode else '' end ProductCode, 
		p.ispart, 
		COM_CC50029.NodeID as Part_Key,	COM_CC50029.Name as PartName, 
		COM_UOM.BaseName UOM,C.NodeID Category_key,  
		case when (COM_CC50023.NodeID=1) then '-' else COM_CC50023.Code end AS Manufacturer,
		 Com_CC50023.NodeID as Manufacturer_Key,
		P.Link,P.Parent,A.Name as JobOwner, A.Nodeid as JobOwner_Key, JobAmount, t1.Name AS Technician,
		case when SB.Nodeid >1 then SB.Name else '' end AS CCNID30 ,
		case when COM_CC50029.Nodeid >1 then COM_CC50029.Name else '' end as PartName ,0 IsExtra
		FROM #temp P WITH(NOLOCK) 
		LEFT JOIN INV_Product WITH(NOLOCK) ON INV_Product.ProductID=P.ProductID
		LEFT JOIN INV_ProductExtended PE WITH(NOLOCK) ON INV_Product.ProductID=PE.ProductID
		LEFT JOIN INV_ProductTypes WITH(NOLOCK) ON INV_ProductTypes.ProductTypeID=INV_Product.ProductTypeID
		LEFT JOIN COM_UOM WITH(NOLOCK) ON COM_UOM.UOMID=P.UOMID
		LEFT JOIN COM_Category C WITH(NOLOCK) ON C.NodeID in (select   ccnid6 from   COM_CCCCData where CostCenterID=50029 and NodeID=P.PartID)
		left join SVC_ServiceJobsInfo j WITH(NOLOCK) on p.ServiceTicketID=j.serviceticketid and c.Nodeid=j.PartCategoryID 
		LEFT JOIN COM_CCCCDATA WITH(NOLOCK) ON COM_CCCCDATA.NodeID=P.ProductID and COM_CCCCDATA.CostCenterID = 3
		LEFT JOIN COM_CC50023 WITH(NOLOCK) ON COM_CC50023.NODEID=COM_CCCCDATA.CCNID23 and COM_CCCCDATA.CostCenterID = 3
		LEFT JOIN COM_CC50029 WITH(NOLOCK) ON COM_CC50029.NODEID=P.PartID
		LEFT JOIN COM_CC50030 SB with(nolock) on SB.nodeid  in (select   ccnid30 from   COM_CCCCData where CostCenterID=50029 and NodeID=P.PartID)
		LEFT JOIN COM_CC50019 T1 WITH(NOLOCK) ON T1.NodeID=TechnicianPrimary
		LEFT JOIN COM_CC50050 A with(NOLOCK) on A.NodeID=JobOwner 
		where P.ServiceTicketID=@DocumentSeqNo and P.isdeclined=0 
		

		select L.*, LocationAddress.* from com_Location L  WITH(NOLOCK)
		LEFT JOIN com_address  LocationAddress WITH(NOLOCK) ON L.NodeID=LocationAddress.FeaturePK and LocationAddress.featureid=50002
		where nodeid in (select LocationID from  SVC_ServiceTicket WITH(NOLOCK) WHERE ServiceTicketID=@DocumentSeqNo)
		
		select C.*, A.* from SVC_Customers C WITH(NOLOCK) left JOIN
		com_contacts A WITH(NOLOCK) ON C.CustomerID=A.FeaturePK and A.featureid=51 
		where CustomerID in (select CustomerID from SVC_ServiceTicket WITH(NOLOCK) WHERE  ServiceTicketID=@DocumentSeqNo)
 		
		SELECT L.Name Options from SVC_ServiceDetailsOptions O WITH(NOLOCK) 
		INNER JOIN COM_Lookup L WITH(NOLOCK) ON O.OptionID=L.NodeID
		where O.ServiceTicketID=@DocumentSeqNo
		
			/****** SERVICE DETAILS ******/
		SELECT D.SerialNumber,D.ServiceTypeID,S.ServiceName,D.LocationID,
		l.Name as Location, 
		D.ReasonID,r.Name as Reasons, F.ActualFileName,
		D.VoiceofCustomer as Complaint
		FROM SVC_ServiceDetails D WITH(NOLOCK)
		INNER JOIN SVC_ServiceTypes S WITH(NOLOCK) ON S.ServiceTypeID=D.ServiceTypeID
		left join com_lookup l WITH(NOLOCK) on D.LocationiD=l.NodeID
		left join com_lookup r WITH(NOLOCK) on D.Reasonid=r.NodeID
		LEFT join Com_files F WITH(NOLOCK) on S.AttachmentID=F.FileId
		WHERE D.ServiceTicketID=@DocumentSeqNo
		--select * from SVC_ServiceTicketFollowUp 
		
		select  S.serviceticketfollowupID,S.ServiceTicketID,L.Name as  CommunicationType,ss.Status as StatusID,S.Remarks,LL.Name as Response,
		convert(Datetime,S.CallTime) as CallTime
		from SVC_ServiceTicketFollowUp S with(nolock)
		left Join COM_LookUp L WITH(NOLOCK) on L.NodeID=S.CommunicationType
		left Join COM_LookUp LL WITH(NOLOCK) on LL.NodeID=S.Response
		left Join Com_Status ss WITH(NOLOCK) on ss.StatusID=S.StatusID
		where S.ServiceTicketID=@DocumentSeqNo 
		
		SELECT  INV_Product.ProductCode +'-'+ INV_Product.ProductName  DeclinedParts 
	 	FROM SVC_ServicePartsInfo P WITH(NOLOCK) 
		LEFT JOIN INV_Product WITH(NOLOCK) ON INV_Product.ProductID=P.ProductID
		where P.ServiceTicketID=@DocumentSeqNo and P.isdeclined=1 
			
		drop table  #temp
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

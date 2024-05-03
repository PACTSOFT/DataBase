USE PACT2C222
GO
SET ANSI_NULLS, QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spSVC_GetTicket]
	@TicketID [bigint],
	@RoleID [int],
	@LANGID [int]
WITH ENCRYPTION, EXECUTE AS CALLER
AS
BEGIN TRY  
SET NOCOUNT ON;
		--Declaration Section  	
		DECLARE @HasAccess BIT
		DECLARE @IsEdit BIT

		--User access check 
		SET @HasAccess=dbo.fnCOM_HasAccess(@RoleID,59,3)
		IF @HasAccess=0
		BEGIN
			RAISERROR('-105',16,1)
		END


		IF @TicketID=0
			SET @IsEdit=0
		ELSE
			SET @IsEdit=1

		SELECT T.ServiceTicketNumber,T.ServiceTicketTypeID,T.LocationID,
		T.CustomerVehicleID,T.StatusID,T.CustomerStatusID,T.ArrivalStatusID,
		CONVERT(DATETIME,T.ArrivalDateTime) ArrivalDateTime,
		CONVERT(DATETIME,T.EstimateDateTime) EstimateDateTime,
		CONVERT(DATETIME,T.DeliveryDateTime) DeliveryDateTime,
		T.Department,T.ServiceEngineer,T.Feeback,T.Suggestion,T.OtherRequests, T.FeedbackRemarks,
		T.OdometerIn,T.OdometerOut,T.InsuranceExists,InsuranceID,InsuranceNo,
		CV.CustomerID,T.CCTicketID,CV.PlateNumber,CV.FuelDelivery,CV.Cylinders,
		CV.EngineType,CV.Color, CV.ChasisNumber, InsRemarks, c.AccountName, cv.VehicleID, 
		v.Make, v.Model, v.Variant, cv.Year,v.MakeID, v.ModelID, v.VariantID, v.SegmentID,
		CASe when (Fuel.NodeID=1) then ('-') else Fuel.Name end  Fuel,
		CASe when (Color.NodeID=1) then ('-') else Color.Name end  Color,
		CASe when (Insurance.NodeID=1) then ('-') else Insurance.Name end  Insurance,
		Insurance.Nodeid as InsuranceID,
		v.make +' - '+v.model+' - '+v.variant +
		case when (cv.Year is null ) then ('') else ( ' - ' +convert(nvarchar,cv.Year)) end as Vehicle,
		T.SignOff, CONVERT(DATETIME,T.SignOffDate) SignOffDate, T.SignOffBy, T.WRID,
		case when (cc.ccnid49=0) then (1) else (cc.ccnid49) end as Sponsor, T.GUID, cv.RegCCID, cv.RegNumberNodeID,
		CON.Phone1, CON.Phone2,convert(datetime,invoicedate) InvoiceDate
		FROM SVC_ServiceTicket T WITH(NOLOCK)
		LEFT JOIN SVC_CustomersVehicle CV WITH(NOLOCK) ON CV.CV_ID=T.CustomerVehicleID
		LEFT JOIN SVC_VEHICLE V WITH(NOLOCK) ON CV.VehicleID=V.VehicleID
		LEFT JOIN SVC_Customers c WITH(NOLOCK) on CV.Customerid=C.CustomerID
		LEFT JOIN COM_CONTACTS CON WITH(NOLOCK) ON C.CustomerID=CON.FeaturePK AND CON.FeatureID=51
		left join dbo.SVC_CustomerCostCenterMap  cc WITH(NOLOCK) on cc.CustomerID=C.CustomerID
		LEFT JOIN COM_CC50014 Fuel WITH(NOLOCK) on V.Fuel=Fuel.NodeID
		LEFT JOIN COM_CC50013 Color WITH(NOLOCK) on CV.Color=Color.NodeID
		LEFT JOIN COM_CC50025 Insurance WITH(NOLOCK) on CV.Insurance=Insurance.NodeID
		WHERE T.ServiceTicketID=@TicketID
	
		/****** SERVICE DETAILS ******/
		SELECT D.SerialNumber,D.ServiceTypeID,S.ServiceName,D.LocationID,D.ReasonID,F.ActualFileName,
		D.VoiceofCustomer
		FROM SVC_ServiceDetails D WITH(NOLOCK)
		INNER JOIN SVC_ServiceTypes S WITH(NOLOCK) ON S.ServiceTypeID=D.ServiceTypeID
		LEFT join Com_files F WITH(NOLOCK) on S.AttachmentID=F.FileId
		WHERE D.ServiceTicketID=@TicketID
		
		/****** OPTIONS ******/
		SELECT OptionID 
		FROM SVC_ServiceDetailsOptions WITH(NOLOCK) 
		WHERE ServiceTicketID=@TicketID

		/****** SERVICE PARTS INFO ******/
  			SELECT P.SerialNumber,P.ProductID,P.PartVehicleID,P.PackageID,
			P.IsRequired,P.Quantity,P.EstimatedQty,P.UOMID,P.Rate,P.Value,
			P.LaborCharge,P.PartDiscount,P.LaborDiscount,P.Gross,P.IsDeclined, 
			P.SuppPartAmt ,P.ShopSuppliesPercent ,P.SSLabAmt ,SSLabPercent ,P.ShopSuppliesAmt,P.Billable,
			P.InsPartAmount ,P.InsPartPercentage ,P.InsLabAmount ,P.InsLabPercentage ,P.InsuredAmt , P.FinalInsuredAmt,P.UOMConversion, P.UOMConversionQty, 
			INV_Product.ProductName,INV_Product.ProductCode,INV_Product.ProductTypeID,
			INV_Product.PurchaseRate,
		case when (partid=0) then 1 else COM_CC50029.NodeID end  Part_Key,	COM_CC50029.Name as PartName,
			ISNULL((SELECT Top 1 ResourceData FROM COM_LanguageResources WITH(NOLOCK) WHERE ResourceID=INV_ProductTypes.ResourceID AND LanguageID=@LangID),INV_ProductTypes.ProductType) ProductType,
			COM_UOM.UnitName UOM,C.NodeID Category_key,C.Name Category,
			P.[dcNum1],P.[dcCalcNum1],P.[dcNum2],P.[dcCalcNum2],
			P.[dcNum3],P.[dcCalcNum3],P.[dcNum4],P.[dcCalcNum4],
			P.[dcNum5],P.[dcCalcNum5],P.[dcNum6],P.[dcCalcNum6],
			P.[dcNum7],P.[dcCalcNum7],P.[dcNum8],P.[dcCalcNum8],
			P.[dcNum9],P.[dcCalcNum9],P.[dcNum10],P.[dcCalcNum10],
			P.[dcNum11],P.[dcCalcNum11],P.[dcNum12],P.[dcCalcNum12],
			P.[dcNum13],P.[dcCalcNum13],P.[dcNum14],P.[dcCalcNum14],
			P.[dcNum15],P.[dcCalcNum15],P.[dcNum16],P.[dcCalcNum16],
			P.[dcNum17],P.[dcCalcNum17],P.[dcNum18],P.[dcCalcNum18],
			P.[dcNum19],P.[dcCalcNum19],P.[dcNum20],P.[dcCalcNum20] ,
	   COM_CC50029.[ccAlpha1] ,COM_CC50029.[ccAlpha2],COM_CC50029.[ccAlpha3],COM_CC50029.[ccAlpha4],COM_CC50029.[ccAlpha5],
	   COM_CC50029.[ccAlpha6],COM_CC50029.[ccAlpha7], COM_CC50029.[ccAlpha8],COM_CC50029.[ccAlpha9],COM_CC50029.[ccAlpha10]
      ,COM_CC50029.[ccAlpha11],COM_CC50029.[ccAlpha12],COM_CC50029.[ccAlpha13],COM_CC50029.[ccAlpha14],COM_CC50029.[ccAlpha15]
      ,COM_CC50029.[ccAlpha16],COM_CC50029.[ccAlpha17],COM_CC50029.[ccAlpha18],COM_CC50029.[ccAlpha19],COM_CC50029.[ccAlpha20]
      ,COM_CC50029.[ccAlpha21],COM_CC50029.[ccAlpha22],COM_CC50029.[ccAlpha23],COM_CC50029.[ccAlpha24],COM_CC50029.[ccAlpha25]
      ,COM_CC50029.[ccAlpha26],COM_CC50029.[ccAlpha27],COM_CC50029.[ccAlpha28],COM_CC50029.[ccAlpha29],COM_CC50029.[ccAlpha30]
      ,COM_CC50029.[ccAlpha31],COM_CC50029.[ccAlpha32],COM_CC50029.[ccAlpha33],COM_CC50029.[ccAlpha34],COM_CC50029.[ccAlpha35]
      ,COM_CC50029.[ccAlpha36],COM_CC50029.[ccAlpha37],COM_CC50029.[ccAlpha38],COM_CC50029.[ccAlpha39],COM_CC50029.[ccAlpha40]
      ,COM_CC50029.[ccAlpha41],COM_CC50029.[ccAlpha42],COM_CC50029.[ccAlpha43],COM_CC50029.[ccAlpha44],COM_CC50029.[ccAlpha45]
      ,COM_CC50029.[ccAlpha46],COM_CC50029.[ccAlpha47],COM_CC50029.[ccAlpha48],COM_CC50029.[ccAlpha49],COM_CC50029.[ccAlpha50] , 
				--COM_CCCCDATA.CCCCDataID ProductCostCenterMapID,
			case when (COM_CC50023.NodeID=1) then '-' else COM_CC50023.Code end AS Manufacturer, Com_CC50023.NodeID as Manufacturer_Key,
					P.Link,P.Parent,A.Name as JobOwner, A.Nodeid as JobOwner_Key, JobAmount, PValue, LValue, Freight, CalcFreight, isnull(P.UpdatedPrice, P.Rate) UpdatedPrice
			FROM SVC_ServicePartsInfo P WITH(NOLOCK) 
			  JOIN INV_Product WITH(NOLOCK) ON INV_Product.ProductID=P.ProductID
			  JOIN INV_ProductExtended PE WITH(NOLOCK) ON INV_Product.ProductID=PE.ProductID
			  JOIN INV_ProductTypes WITH(NOLOCK) ON INV_ProductTypes.ProductTypeID=INV_Product.ProductTypeID
			LEFT JOIN COM_UOM WITH(NOLOCK) ON COM_UOM.UOMID=P.UOMID
			LEFT JOIN COM_Category C WITH(NOLOCK) ON C.NodeID in (select   ccnid6 from   COM_CCCCData where CostCenterID=50029 and NodeID=P.PartID)
			LEFT JOIN COM_CCCCDATA WITH(NOLOCK) ON COM_CCCCDATA.NodeID=P.ProductID and COM_CCCCDATA.CostCenterID = 3
			LEFT JOIN COM_CC50023 WITH(NOLOCK) ON COM_CC50023.NODEID=COM_CCCCDATA.CCNID23 and COM_CCCCDATA.CostCenterID = 3
			LEFT JOIN COM_CC50029 WITH(NOLOCK) ON COM_CC50029.NODEID=P.PartID
			LEFT JOIN COM_CC50050 A with(NOLOCK) on A.NodeID=JobOwner 
			WHERE P.ServiceTicketID=@TicketID  ORDER BY P.SerialNumber 
			
		 
		/****** SERVICE JOBS INFO ******/
		SELECT SerialNumber,PartCategoryID,
				PartsAmount,PartsDiscount,LaborCharge,LaborDiscount,
				IsInsuranceCovered,InsuranceCoveredAmount,ShopSupplies,ShopSuppliesPercent,ShopSuppliesDiscount,
				TechnicianPrimary,TechnicianSecondary,IsDeclined,T1.Name TechPrim,T2.Name TechSec,
				 A.Name as Owner, A.NodeID as Owner_Key,
				 ShopSuppliesAmt, SSLabAmt, SSLabPercent, Status
		FROM SVC_ServiceJobsInfo WITH(NOLOCK)
		LEFT JOIN COM_CC50019 T1 WITH(NOLOCK) ON T1.NodeID=TechnicianPrimary
		LEFT JOIN COM_CC50019 T2 WITH(NOLOCK) ON T2.NodeID=TechnicianSecondary
		 LEFT JOIN COM_CC50050 A with(NOLOCK) on A.NodeID=Owner
		WHERE ServiceTicketID=@TicketID
		
		/****** SERVICE TICKET BILL ******/
		SELECT PartsAmount,PartsDiscount,LaborAmount,LaborDiscount,
				SuppliesAmount,SuppliesDiscount,SubTotal,
				OverallDiscount,TaxProfileID,Total,Balance, InsuredAmt, PrivilegeAmt,EstimateAmt
		FROM SVC_ServiceTicketBill WITH(NOLOCK)
		WHERE ServiceTicketID=@TicketID

		/****** SERVICE TICKET PAYMENTS ******/
		--SELECT * FROM SVC_ServiceTicketBillPayment WHERE ServiceTicketID=@TicketID
		SELECT P.Name Type, PaymentTypeID Type_Key,PaymentMode MODE,'' Date,CONVERT(DATETIME,PaymentDate) Date_Key,
			PaymentAmount Amount,
			InsuranceClaimNo INS1,
			CreditCardTypeID CC1,CreditCardNumber CC2,CreditCardExpiryDate CC3,CreditCardSecurityCode CC4,
			b.ChequeNumber CQ1,CONVERT(DATETIME,b.ChequeDate) CQ2,b.ChequeBankName CQ3,b.ChequeBankRountingNumber CQ4,
			GiftCoupanNumber GC1,GiftCoupanType GC2,  a.DebitAccount, docdetailsid, a.VoucherNo, b.IsAdvance, a.DocID, A.AccDocDetailsID
		FROM SVC_ServiceTicketBillPayment b WITH(NOLOCK)
		INNER JOIN COM_PaymentModes P WITH(NOLOCK) ON P.NodeID=PaymentTypeID
		left join acc_docdetails a WITH(NOLOCK) on b.docdetailsid=a.docid and b.paymentAmount=a.amount and a.DebitAccount >0  and b.docdetailsid>0
		WHERE ServiceTicketID=@TicketID

		/****** SERVICE TICKET INSURANCE CLAIMS ******/
		SELECT Sno,ClaimID,ClaimNo,CONVERT(DATETIME,ClaimDate) ClaimDate,ClaimAmount,
			ApprovalMode,AppAmount,AppDoc,CONVERT(DATETIME,AppDate) AppDate,SurveyorID, COM_CC50021.Name Surveyor,ClaimNumber
		FROM SVC_ServiceTicketClaims T WITH(NOLOCK)
		LEFT JOIN COM_CC50021 WITH(NOLOCK) ON COM_CC50021.NodeID=T.SurveyorID
		WHERE ServiceTicketID=@TicketID


		/****** SERVICE TICKET TAXES ******/
		SELECT * FROM SVC_ServiceTicketTaxes WITH(NOLOCK) WHERE ServiceTicketID=@TicketID

		/****** SERVICE TICKET ATTACHMENTS ******/
		SELECT * FROM  COM_Files WITH(NOLOCK) 
		WHERE FeatureID=59 and  FeaturePK=@TicketID

		/****** VEHICLE CHECKOUT ******/
		SELECT CheckoutID 
		FROM SVC_VehicleCheckout WITH(NOLOCK) 
		WHERE ServiceTicketID=@TicketID
		  
		declare @CCTicketid bigint, @invccid bigint, @estccid bigint, @woccid bigint
		select @CCTicketid=CCTicketid from svc_serviceticket with(nolock) where serviceticketid=@TicketID
		select @invccid=value from com_costcenterpreferences WITH(NOLOCK) where costcenterid=59 and name ='ServiceInvoiceDocument'
		select @estccid=value from com_costcenterpreferences WITH(NOLOCK) where costcenterid=59 and name ='ServiceEstimateDoc'
		select @woccid=value  from com_costcenterpreferences WITH(NOLOCK) where costcenterid=59 and name ='ServiceWorkOrderDoc'
		
		SELECT    DOC.DocID, DOC.DocPrefix, DOC.DocNumber, 
		DOC.INVDocDetailsID, DOC.ProductID, DOC.DocSeqNo, costcenterid, Statusid, Doc.StockValue, 
		CONVERT(DATETIME,DOC.DOCDATE) DOCDATE, GUID, Doc.VoucherNo
		FROM INV_DocDetails AS DOC WITH(NOLOCK)
		where RefNodeid =@CCTicketid and refCCID=59
		and costcenterid in (@woccid,@invccid,@estccid)
		  
		SELECT    DISTINCT(DOC.DocID), DOC.DocPrefix, DOC.DocNumber , 
		DOC.AccDocDetailsID, DOC.CostCenterID, DOC.DebitAccount, Doc.Amount, Doc.VoucherNo
		FROM ACC_DocDetails AS DOC WITH(NOLOCK)
		left join COM_CostCenterPreferences cp WITH(NOLOCK) on doc.costcenterid= Convert(bigint,cp.value)
		where RefNodeid =@CCTicketid and refCCID=59 and  cp.name like 'ServiceAccDoc%' and cp.value >0
	 	
		select CustomerFamilyID as FamilyID, cf.Name as FName,
		L.NodeID as FRelation,  L.Name as Relation, Phone as FPhone
		from svc_Customerfamilydetails cf  WITH(NOLOCK)
		left join com_lookup L WITH(NOLOCK) on L.NodeID=cf.Relation
		where cf.CustomerFamilyID in (SELECT FAMILYID FROM SVC_ServiceTicket WITH(NOLOCK) WHERE ServiceTicketID=@TicketID)
		
		select  SysColumnName, UserColumnName from adm_Costcenterdef WITH(NOLOCK) where costcenterid=50029 and (usercolumnname ='Billable' or usercolumnname ='Bill')
		
		/****** Feedback ******/
		SELECT FeedbackID 
		FROM SVC_Feedback WITH(NOLOCK) 
		WHERE ServiceTicketID=@TicketID
		
		select S.ServiceTicketFollowUpId as ID,S.Remarks,L.Name as CommunicationType from svc_serviceticketfollowup S with(nolock) 
		left join com_lookup L WITH(NOLOCK) on S.CommunicationType=L.NodeID 
		where ServiceTicketID=@TicketID

SET NOCOUNT OFF;  
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

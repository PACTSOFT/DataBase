USE PACT2C222
GO
SET ANSI_NULLS, QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spSVC_GetCustomerDetails]
	@CustomerID [bigint] = 0,
	@UserID [bigint],
	@LangID [int] = 1
WITH ENCRYPTION, EXECUTE AS CALLER
AS
BEGIN TRANSACTION
BEGIN TRY	
SET NOCOUNT ON

		--Declaration Section
		DECLARE @HasAccess bit

		--SP Required Parameters Check
		IF (@CustomerID < 1)
		BEGIN
			RAISERROR('-100',16,1)
		END
		
		--Getting data from Accounts main table
	SELECT [CustomerID]
      ,[CustomerCode]
      ,[CustomerName]
      ,FirstName
      ,LastName
      ,[AliasName]
	  ,[Salutation]
      ,[CustomerTypeID]
      ,[StatusID]
      ,[Depth]
      ,[ParentID]
      ,[lft]
      ,[rgt]
      ,[IsGroup]
      ,[Location]
      ,[AccountName]
      ,[CreditDays]
      ,[CreditLimit]
      ,[Currency]
      ,[Insurance]
      ,[PolicyNo]
      ,convert(datetime,[ExpiryDate]) as ExpiryDate
      ,[LoyaltyCard]
      ,convert(datetime,[LoyaltyCardExpDate]) as LoyaltyCardExpDate
      ,[ExtendedWarranty]
      ,convert(datetime,[ExtWarrantyExpDate]) as ExtWarrantyExpDate
      ,[ExtWarrantyExpDate]
      ,[IsUserDefined]
      ,[CompanyGUID]
      ,[GUID]
      ,[Description]
      ,[CreatedBy]
      ,[CreatedDate]
      ,[ModifiedBy]
      ,[ModifiedDate]
      
  FROM  [dbo].[SVC_Customers] WITH(NOLOCK) 	
		WHERE CustomerID=@CustomerID
		
		--Getting data from Accounts extended table
		SELECT * FROM  SVC_CustomersExtended WITH(NOLOCK) 
		WHERE CustomerID=@CustomerID

		--Getting Contacts
		EXEC [spCom_GetFeatureWiseContacts] 51,@CustomerID,2,1,1

		--Getting Notes
		SELECT     NoteID, Note, FeatureID, FeaturePK, CompanyGUID, GUID, CreatedBy, convert(datetime,CreatedDate) as CreatedDate, ModifiedBy, ModifiedDate, CostCenterID
		FROM         COM_Notes WITH(NOLOCK) 
		WHERE FeatureID=51 and  FeaturePK=@CustomerID

	 
		--Getting CostCenterMap
		SELECT * FROM  SVC_CustomerCostCenterMap WITH(NOLOCK) 
		WHERE CustomerID=@CustomerID

	 
		--Getting ADDRESS 
		EXEC spCom_GetAddress 51,@CustomerID,1,1

		--Getting Contacts
		  SELECT c.*, l.name as Salutation FROM  COM_Contacts c WITH(NOLOCK)   
		  left join com_lookup l WITH(NOLOCK) on l.Nodeid=c.SalutationID  
		  WHERE FeatureID=51 and  FeaturePK=@CustomerID AND AddressTypeID=1  

		--Getting Customer Vehicle details
		SELECT cv_ID,CV.VehicleID, V.MakeID, V.Make, V.ModelID, V.Model, CV.Year,CV.PlateFormat,
		V.StartYear, V.EndYear, V.Variant, V.VariantID, 
		COM_CC50024.Name as Segment,V.SegmentID, CV.PlateNumber as PlateNo, CV.Cylinders as CylinderID, 
		C.NODEID AS ColorID, 
		case when (C.NodeID=1 or C.NodeID=0) then '-' else C.NAME end AS Color,
		FD.NODEID AS FuelDeliveryID, 
		case when (FD.Nodeid=1 or FD.Nodeid=0) then '-' else FD.NAME end AS FuelDelivery, 
		E.NODEID AS EngineTypeID, 
		case when (E.NodeID=1 or e.NodeID=0) then '-' else E.NAME end AS EngineType, 
		case when (COM_CC50022.NodeID=1 or COM_CC50022.NodeID=0) then '-' else COM_CC50022.NAME end AS Cylinders, 
		Specification  Specification_key,
		case when (COM_CC50031.NodeID=1 or COM_CC50031.NodeID=0) then '-' else COM_CC50031.NAME end AS Specification, 
		EuroBSType  EuroBSType_key,
		case when (COM_CC50032.NodeID=1 or COM_CC50032.NodeID=0) then '-' else COM_CC50032.NAME end AS EuroBSType, 
		Transmission Transmission_key,
		case when (COM_CC50033.NodeID=1 or COM_CC50033.NodeID=0) then '-' else COM_CC50033.NAME end AS Transmission, 
		CC CC_key,
		case when (COM_CC50034.NodeID=1 or COM_CC50034.NodeID=0) then '-' else COM_CC50034.NAME end AS CC, 
	 	WheelDrive WheelDrive_key,
	 	case when (COM_CC50035.NodeID=1 or COM_CC50035.NodeID=0) then '-' else COM_CC50035.NAME end AS WheelDrive, 
		SeatCapacity SeatCapacity_key,
		case when (COM_CC50036.NodeID=1 or COM_CC50036.NodeID=0) then '-' else COM_CC50036.NAME end AS SeatCapacity, 
		v.Fuel FuelID,
		case when (COM_CC50014.NodeID=1 or COM_CC50014.NodeID=0) then '-' else COM_CC50014.NAME end AS Fuel, 
		COM_CC50025.NODEID Insurance,
		case when (COM_CC50025.NodeID=1 or COM_CC50025.NodeID=0) then '-' else COM_CC50025.NAME end AS InsuranceName, 
		COM_CC50027.NODEID LOYALTYCARDID,
		case when (COM_CC50027.NodeID=1 or COM_CC50027.NodeID=0) then '-' else COM_CC50027.NAME end AS LOYALTYCARD, 
		COM_CC50027.NAME LOYALTYCARD,
		CV.InsuranceExpiryDate,CV.CardNumber, 
		CV.CardExpDate,CV.PolicyNumber, CV.StatusID,S.Status, CV.ChasisNumber
		FROM  SVC_CustomersVehicle  CV WITH(NOLOCK)
		JOIN SVC_VEHICLE V WITH(NOLOCK) ON CV.VEHICLEID= V.VEHICLEID  
		LEFT  JOIN COM_CC50013  C WITH(NOLOCK) ON C.NodeID=CV.COLOR 
		LEFT JOIN COM_CC50031 WITH(NOLOCK) ON COM_CC50031.NODEID=V.Specification
		LEFT JOIN COM_CC50032 WITH(NOLOCK) ON COM_CC50032.NODEID=V.EuroBSType
		LEFT JOIN COM_CC50033 WITH(NOLOCK) ON COM_CC50033.NODEID=V.Transmission
		LEFT JOIN COM_CC50034 WITH(NOLOCK) ON COM_CC50034.NODEID=V.CC
		LEFT JOIN COM_CC50035 WITH(NOLOCK) ON COM_CC50035.NODEID=V.WheelDrive
		LEFT JOIN COM_CC50036 WITH(NOLOCK) ON COM_CC50036.NODEID=V.SeatCapacity
		LEFT JOIN COM_CC50014 WITH(NOLOCK) ON COM_CC50014.NODEID=V.Fuel
		LEFT JOIN COM_CC50015  FD WITH(NOLOCK) ON FD.NodeID=CV.FUELDELIVERY 
		LEFT JOIN COM_CC50017  E WITH(NOLOCK) ON E.NodeID=CV.ENGINETYPE 
		LEFT JOIN COM_CC50022 WITH(NOLOCK) ON COM_CC50022.NODEID=CV.Cylinders
		LEFT JOIN COM_CC50024 WITH(NOLOCK) ON COM_CC50024.NODEID=V.SegmentID
		LEFT JOIN COM_CC50025 WITH(NOLOCK) ON COM_CC50025.NODEID=CV.INSURANCE
		LEFT JOIN COM_CC50027 WITH(NOLOCK) ON COM_CC50027.NODEID=CV.LOYALTYCARD
		LEFT JOIN com_status s WITH(NOLOCK) ON s.StatusID=CV.StatusID
		WHERE CustomerID=@CustomerID
		
		--Getting Files
		SELECT * FROM  COM_Files WITH(NOLOCK) 
		WHERE FeatureID=51 and  FeaturePK=@CustomerID

		--Getting TicketsInformataion
		select   
			 sv.ServiceTicketNumber as Ticket,  
			 c.CustomerName as Customer ,  
			 v.Make+'-'+v.Model+'-'+v.Variant+'-'+convert(nvarchar,cv.year) as Vehicle ,
			 case when cv.PlateNumber is null or cv.PlateNumber = '' then '-' else Replace(cv.PlateNumber,'-','') end as PlateNo,
			 convert(datetime,sv.ArrivalDateTime) Arrival,   
			 convert(datetime,sv.DeliveryDateTime) Delivery,   
			 stb.Total as Amount,L.Name as Location,
			 s.Status as Status, o.Name as Relation, cf.Name as ConcernName
			 from SVC_ServiceTicket sv with(nolock) 
		   LEFT JOIN SVC_ServiceTicketBill STB WITH(NOLOCK) ON SV.ServiceTicketID=stb.ServiceTicketID		 
		   LEFT join COM_Location l WITH(NOLOCK) on sv.LocationID=l.NodeID  
		   LEFT join COM_Status s WITH(NOLOCK) on sv.StatusID=s.StatusID  
		   LEFT join SVC_CustomersVehicle cv WITH(NOLOCK) on sv.CustomerVehicleID=cv.CV_ID  
		   LEFT join SVC_Customers c WITH(NOLOCK) on cv.CustomerID=c.CustomerID   
		    left join SVC_CustomerFamilyDetails cf WITH(NOLOCK) on c.customerid=cf.customerid 
		   left join com_lookup o WITH(NOLOCK) on cf.relation=o.NodeID
		   LEFT join SVC_Vehicle v WITH(NOLOCK) on cv.VehicleID=v.VehicleID
			WHERE C.CUSTOMERID=@CustomerID
 
			select CustomerFamilyID as FamilyID, cf.Name as FName,
			L.NodeID as FRelation,  L.Name as Relation, Phone as FPhone
			from svc_Customerfamilydetails cf WITH(NOLOCK)
			join SVC_Customers c WITH(NOLOCK) on c.CustomerID=cf.CustomerID
			left join com_lookup L WITH(NOLOCK) on L.NodeID=cf.Relation
			where c.customerid=@CustomerID

			select S.ServiceTicketFollowUpId as ID,S.Remarks,L.Name as CommunicationType from svc_serviceticketfollowup S with(nolock) 
			left join com_lookup L WITH(NOLOCK) on S.CommunicationType=L.NodeID 
			where CustomerID=@CustomerID
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
GO

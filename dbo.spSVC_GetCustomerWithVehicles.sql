USE PACT2C222
GO
SET ANSI_NULLS, QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spSVC_GetCustomerWithVehicles]
	@CustomerID [bigint] = 0,
	@UserID [bigint],
	@LangID [int] = 1
WITH ENCRYPTION, EXECUTE AS CALLER
AS
BEGIN TRY  
SET NOCOUNT ON;
	 
		--Declaration Section
		DECLARE @HasAccess BIT,@ColorTable NVARCHAR(20),@RegTable nvarchar(30), @EngineTable NVARCHAR(20),@FuelTable NVARCHAR(20),@SQL NVARCHAR(MAX)

		--SP Required Parameters Check
		IF @CustomerID=0 
		BEGIN
			RAISERROR('-100',16,1)
		END

--		--User access check 
--		SET @HasAccess=dbo.fnCOM_IsUserActionAllowed(@UserID,@CostCenterID,2)
--
--		IF @HasAccess=0
--		BEGIN
--			RAISERROR('-105',16,1)
--		END

		--To get costcenter table name
		SELECT C.CustomerID,C.CustomerCode, CON.*, A.AccountName Account,
		A.AccountCode AccountCode,
		C.Insurance,C.PolicyNo,CONVERT(DATETIME,C.ExpiryDate) InsExpiryDate,
		a.AccountID, case when (C.Salutation is null or c.Salutation =0) then C.CustomerName else l.Name+C.CustomerName end CustomerName, 
		case when (cc.CCNID49=0) then (1) else (cc.CCNID49) end Sponsor  ,
		case when (cc.CCNID49=0) then (1) else	s.SalesAccount end SponsorSalesAccount, 
		case when (cc.CCNID49=0) then (1) else	s.PurchaseAccount end SponsorPurchaseAccount    
		FROM SVC_Customers C WITH(NOLOCK) 
		LEFT JOIN COM_Contacts CON WITH(NOLOCK) ON CON.FeaturePK=@CustomerID AND CON.FeatureID=51
		LEFT JOIN ACC_Accounts A WITH(NOLOCK) ON C.AccountName=A.AccountID
		left join dbo.SVC_CustomerCostCenterMap  cc  WITH(NOLOCK) on cc.CustomerID=C.CustomerID
		left join com_lookup l  WITH(NOLOCK) on c.Salutation=l.NodeID
		LEFT JOIN COM_CC50049 s WITH(NOLOCK) ON Cc.CCNID49=s.NodeID
		WHERE C.CustomerID=@CustomerID    
		declare @RegCostCenterID bigint
		select @RegCostCenterID= value  from com_costcenterpreferences where costcenterid=51 and Name='VehicleRegNumberLink'
		
--		SELECT CV.CV_ID, V.VehicleID,V.Year+' '+V.Make+' '+V.Model+' '+V.Variant Vehicle,
--			CV.PlateNumber,CV.Color,V.Segment,CV.EngineType,CV.Fuel,CV.Cylinders,
--			CV.OdometerIn,CV.OdometerOut
--		FROM SVC_CustomersVehicle CV WITH(NOLOCK)
--		LEFT JOIN SVC_Vehicle V WITH(NOLOCK) ON CV.VehicleID=V.VehicleID
--		WHERE CV.CustomerID=@CustomerID

 
	 	
		
		SELECT TOP 1 @ColorTable='COM_CC'+CONVERT(VARCHAR,CostCenterID)
		FROM SVC_CostCenter WITH(NOLOCK) WHERE FeatureName='Color'	

		SELECT TOP 1 @FuelTable='COM_CC'+CONVERT(VARCHAR,CostCenterID)
		FROM SVC_CostCenter WITH(NOLOCK) WHERE FeatureName='Fuel Delivery'	

		SELECT TOP 1 @EngineTable='COM_CC'+CONVERT(VARCHAR,CostCenterID)
		FROM SVC_CostCenter WITH(NOLOCK) WHERE FeatureName='EngineType'	

		SET @SQL='SELECT CV.CV_ID,V.MakeID,V.ModelID,CV.Year,V.VariantID,V.VehicleID,V.Make+''-''+V.Model+''-''+V.Variant Vehicle,
			CV.Year,CV.PlateNumber,
		case when ('+@ColorTable+'.NodeID=1 or '+@ColorTable+'.Nodeid=0) then ''-'' else '+@ColorTable+'.Name end Color,CV.Color ColorID,
		case when (COM_CC50024.Nodeid=1 or COM_CC50024.Nodeid=0) then (''-'') else (COM_CC50024.name) end as Segment,
		COM_CC50024.Name as Segment,
		case when ('+@EngineTable+'.NodeID=1 or '+@EngineTable+'.Nodeid=0) then ''-'' else '+@EngineTable+'.Name end EngineType, CV.EngineType EngineTypeID,
		case when ('+@FuelTable+'.NodeID=1 or '+@FuelTable+'.Nodeid=0) then ''-'' else '+@FuelTable+'.Name end FuelDelivery, CV.FuelDelivery FuelDeliveryID,
		CV.Cylinders, CV.OdometerIn, CV.OdometerOut,
		case when (COM_CC50014.Nodeid=1 or COM_CC50014.Nodeid=0) then (''-'') else (COM_CC50014.name) end as Fuel,
		case when (COM_CC50031.Nodeid=1 or COM_CC50031.Nodeid=0) then (''-'') else (COM_CC50031.name) end as Specification,
	    case when (COM_CC50033.Nodeid=1 or COM_CC50033.Nodeid=0) then (''-'') else (COM_CC50033.name) end as Transmission,
		case when (COM_CC50034.Nodeid=1 or COM_CC50034.Nodeid=0) then (''-'') else (COM_CC50034.name) end as CC,
		case when (COM_CC50035.Nodeid=1 or COM_CC50035.Nodeid=0) then (''-'') else (COM_CC50035.name) end as WheelDrive,
		case when (COM_CC50036.Nodeid=1 or COM_CC50036.Nodeid=0) then (''-'') else (COM_CC50036.name) end as SeatCapacity,
	 	case when (COM_CC50032.Nodeid=1 or COM_CC50032.Nodeid=0) then (''-'') else (COM_CC50032.name) end as EuroBSType,
	   	CV.EngineType EngineTypeID,CV.RegNumberNodeID,'+Convert(nvarchar(10),@RegCostCenterID)+' as RegCCID,
		case when (COM_CC50025.Nodeid=0 or Insurance =null) then (''-'') else (COM_CC50025.name) end as Insurance,
		CV.ChasisNumber, COM_CC50024.NodeID as SegmentID,CV.PlateFormat,
		CV.StatusID, CV.Insurance as InsuranceID, CV.CardNumber, CV.CardExpDate, CV.PolicyNumber, cv.InsuranceExpiryDate
		FROM SVC_CustomersVehicle CV WITH(NOLOCK)
		LEFT JOIN SVC_Vehicle V WITH(NOLOCK) ON CV.VehicleID=V.VehicleID
		LEFT JOIN COM_CC50014  WITH(NOLOCK) ON COM_CC50014.NODEID=V.Fuel
		LEFT JOIN COM_CC50025  WITH(NOLOCK) ON COM_CC50025.NODEID=CV.Insurance
		LEFT JOIN COM_CC50031  WITH(NOLOCK) ON COM_CC50031.NODEID=V.Specification
		LEFT JOIN COM_CC50033 WITH(NOLOCK)  ON COM_CC50033.NODEID=V.Transmission
		LEFT JOIN COM_CC50034  WITH(NOLOCK) ON COM_CC50034.NODEID=V.CC
		LEFT JOIN COM_CC50035  WITH(NOLOCK) ON COM_CC50035.NODEID=V.WheelDrive 
		LEFT JOIN COM_CC50036  WITH(NOLOCK) ON COM_CC50036.NODEID=V.SeatCapacity
		LEFT JOIN COM_CC50024  WITH(NOLOCK) ON COM_CC50024.NODEID=V.SegmentID
		LEFT JOIN COM_CC50032  WITH(NOLOCK) ON COM_CC50032.NODEID=V.EuroBSType
 		LEFT JOIN '+@ColorTable+' WITH(NOLOCK) ON '+@ColorTable+'.NodeID=CV.Color
		LEFT JOIN '+@EngineTable+' WITH(NOLOCK) ON '+@EngineTable+'.NodeID=CV.EngineType
		LEFT JOIN '+@FuelTable+' WITH(NOLOCK) ON '+@FuelTable+'.NodeID=CV.FuelDelivery
		WHERE CV.CustomerID='+CONVERT(NVARCHAR,@CustomerID) --+' and CV.StatusID=357'

		EXEC(@SQL)
			
			select CustomerFamilyID as FamilyID, cf.Name as FName,
			L.NodeID as FRelation,  L.Name as Relation, Phone as FPhone
			from svc_Customerfamilydetails cf  WITH(NOLOCK) 
			join SVC_Customers c  WITH(NOLOCK) on c.CustomerID=cf.CustomerID
			left join com_lookup L  WITH(NOLOCK) on L.NodeID=cf.Relation
			where c.customerid=@CustomerID


 
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

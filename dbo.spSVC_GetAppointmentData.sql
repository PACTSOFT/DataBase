USE PACT2C222
GO
SET ANSI_NULLS, QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spSVC_GetAppointmentData]
	@CustomerID [bigint],
	@AppointmentID [bigint],
	@UserID [bigint],
	@LangID [int] = 1
WITH ENCRYPTION, EXECUTE AS CALLER
AS
BEGIN TRANSACTION
BEGIN TRY	
SET NOCOUNT ON
 
	BEGIN
	    IF @CustomerID=0 AND  @AppointmentID = 0
			BEGIN
				SELECT CustomerName, CustomerID from SVC_Customers where IsGroup=0
				SELECT Name, NodeID from COM_Location where IsGroup=0
			END
		ELSE IF @CustomerID > 0 AND  @AppointmentID = 0
			BEGIN
				--Getting Customer Vehicle details
				SELECT CV.VehicleID, V.MakeID, V.Make, V.ModelID, V.Model, CV.Year, V.Variant, V.VariantID, 
				V.Segment,V.SegmentID, CV.PlateNumber as PlateNo, CV.Cylinders, C.NODEID AS ColorID, C.NAME AS Color,
				 FD.NODEID AS FuelDeliveryID, FD.NAME AS FuelDelivery, 
				E.NODEID AS EngineTypeID, E.NAME AS EngineType, CV.CV_ID AS CustomerVehicleID, Cus.CustomerName
				FROM  SVC_CustomersVehicle  CV 
				JOIN SVC_VEHICLE V ON CV.VEHICLEID= V.VEHICLEID  
				LEFT  JOIN COM_CC50013  C ON C.NodeID=CV.COLOR 
				
				 LEFT JOIN COM_CC50015  FD ON FD.NodeID=CV.FUELDELIVERY 
				LEFT JOIN COM_CC50017  E ON E.NodeID=CV.ENGINETYPE 
				LEFT JOIN SVC_CUSTOMERS Cus ON Cus.CUSTOMERID=CV.CUSTOMERID
				WHERE cv.CustomerID=@CustomerID
			END
		 ELSE IF @AppointmentID > 0 
			BEGIN
				--Getting Appointment details
				SELECT L.NodeID as Location, C.CUSTOMERNAME AS CustomerName,convert(datetime, A.AppDate) as AppDate,FromTime,
				ToTime, A.Remarks,  V.MAKE  + '-' + V.MODEL  + '-' + CONVERT(NVARCHAR,CV.YEAR) + '-' + V.VARIANT AS VEHICLENAME, v.VEHICLEID, C.CustomerID,A.GUID, CV.CV_ID
				FROM SVC_APPOINTMENT A LEFT JOIN SVC_CUSTOMERSVEHICLE CV ON A.CUSTOMERVEHICLEID=CV.CV_ID
				LEFT JOIN SVC_VEHICLE V ON V.VehicleID=CV.VEHICLEID LEFT JOIN SVC_CUSTOMERS C
				ON CV.CUSTOMERID=C.CUSTOMERID LEFT JOIN COM_LOCATION L ON A.LOCATION=L.NODEID 
				WHERE APPOINTMENTID=@AppointmentID

				SET @CustomerID=(SELECT C.CUSTOMERID FROM SVC_APPOINTMENT A 
				LEFT JOIN SVC_CUSTOMERSVEHICLE CV ON A.CUSTOMERVEHICLEID=CV.CV_ID 
				LEFT JOIN SVC_CUSTOMERS C ON CV.CUSTOMERID=C.CUSTOMERID WHERE A.APPOINTMENTID=@AppointmentID)
				
			    SELECT CV.VehicleID, V.MakeID, V.Make, V.ModelID, V.Model, CV.Year, V.Variant, V.VariantID, 
				V.Segment,V.SegmentID, CV.PlateNumber as PlateNo, CV.Cylinders, C.NODEID AS ColorID, C.NAME AS Color,
				 FD.NODEID AS FuelDeliveryID, FD.NAME AS FuelDelivery, 
				E.NODEID AS EngineTypeID, E.NAME AS EngineType, CV.CV_ID AS CustomerVehicleID
				FROM  SVC_CustomersVehicle  CV 
				JOIN SVC_VEHICLE V ON CV.VEHICLEID= V.VEHICLEID  
				LEFT  JOIN COM_CC50013  C ON C.NodeID=CV.COLOR 
				 LEFT JOIN COM_CC50015  FD ON FD.NodeID=CV.FUELDELIVERY 
				LEFT JOIN COM_CC50017  E ON E.NodeID=CV.ENGINETYPE 
				WHERE CustomerID=@CustomerID

					Select ASD.ServiceTypeID,ST.SERVICENAME, ASD.LOCATIONID,ASD.REASONID, F.ACTUALFILENAME,F.FILEPATH
				FROM SVC_AppointmentServiceDetails ASD
JOIN SVC_ServiceTypes ST ON ASD.ServiceTypeID=ST.ServiceTypeID 
LEFT JOIN COM_FILES F ON ST.ATTACHMENTID=F.FILEID
				WHERE ASD.AppointmentID=@AppointmentID
			END 
	END

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

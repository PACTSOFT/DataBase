USE PACT2C222
GO
SET ANSI_NULLS, QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spSVC_GetCalendarData]
	@AppointmentID [bigint],
	@LocationID [bigint],
	@SDate [datetime],
	@TDate [datetime],
	@TicketFDate [datetime],
	@TicketTDate [datetime],
	@UserID [bigint],
	@LangID [int] = 1
WITH ENCRYPTION, EXECUTE AS CALLER
AS
BEGIN TRANSACTION
BEGIN TRY	
SET NOCOUNT ON
 
	BEGIN
	    IF @AppointmentID=0 and @LocationID=0 and @SDate != ''
			BEGIN
				SELECT Name, NodeID from COM_Location where IsGroup=0

			END
		ELSE IF @LocationID > 0 
			BEGIN
				SELECT CV.VehicleID,convert(DATETIME, A.APPDATE), A.FromTime, A.ToTime, C.CUSTOMERNAME as Customer,convert(nvarchar,CV.Year)+'-'+ V.MAKE  + '-' + V.MODEL  +  '-' + V.VARIANT AS VEHICLENAME, A.AppointmentID, A.GUID   
				FROM SVC_Appointment A LEFT JOIN SVC_CUSTOMERSVEHICLE CV ON A.CUSTOMERVEHICLEID=CV.CV_ID
				LEFT JOIN SVC_VEHICLE V ON V.VehicleID=CV.VEHICLEID LEFT JOIN SVC_CUSTOMERS C
				ON CV.CUSTOMERID=C.CUSTOMERID WHERE A.LOCATION=@LocationID and a.AppDate >= convert(float,@Sdate) and A.AppDate < CONVERT(FLOAT, @TDate) ORDER BY A.AppDATE

				select   
				sv.ServiceTicketNumber as Ticket,  
				c.CustomerName as Customer ,  
				convert(nvarchar,CV.Year)+'-'+v.Make+'-'+v.Model+'-'+v.Variant as Vehicle,  
				case when cv.PlateNumber is null or cv.PlateNumber = '' then '-' else cv.PlateNumber end as PlateNo,
				convert(datetime,sv.ArrivalDateTime) Arrival,   
				convert(datetime,sv.DeliveryDateTime) Delivery,   
				stb.Total as Amount,
				CASE WHEN (SV.SERVICETICKETTYPEID=1) THEN ('Estimate') else
				 (case when (sv.servicetickettypeid=2) then ('Work-Order') else 
				 (case when (sv.servicetickettypeid=3) then ('Invoice') else ('Delivered') end) end) END  AS Status
			 	--s.Status as Status
				from SVC_ServiceTicket sv with(nolock) 
				LEFT JOIN SVC_ServiceTicketBill STB ON SV.ServiceTicketID=stb.ServiceTicketID		 
				LEFT join COM_Location l on sv.LocationID=l.NodeID  
				LEFT join COM_Status s on sv.StatusID=s.StatusID  
				LEFT join SVC_CustomersVehicle cv on sv.CustomerVehicleID=cv.CV_ID  
				LEFT join SVC_Customers c on cv.CustomerID=c.CustomerID   
				LEFT join SVC_Vehicle v on cv.VehicleID=v.VehicleID
				WHERE SV.ARRIVALDATETIME >= (CONVERT(FLOAT,@TicketFDate)) and
				 SV.ARRIVALDATETIME <=(CONVERT(FLOAT,@TickettDate)) and sv.LocationID=@LocationID
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

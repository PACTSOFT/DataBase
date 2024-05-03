USE PACT2C222
GO
SET ANSI_NULLS, QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spSVC_GetTicketInfo]
	@TicketFDate [datetime],
	@TicketTDate [datetime],
	@Location [bigint],
	@UserID [bigint],
	@LangID [int] = 1
WITH ENCRYPTION, EXECUTE AS CALLER
AS
BEGIN TRY	
SET NOCOUNT ON
 

	select   
	 sv.ServiceTicketNumber as Ticket,  
	 c.CustomerName as Customer , v.Make+'-'+v.Model+'-'+v.Variant as Vehicle,  
	 case when cv.PlateNumber is null or cv.PlateNumber = '' then '-' else cv.PlateNumber end as PlateNo,
	 convert(datetime,sv.ArrivalDateTime) Arrival,   
	 convert(datetime,sv.DeliveryDateTime) Delivery,   
	 stb.Total as Amount,
	 CASE WHEN (SV.SERVICETICKETTYPEID=1) THEN ('Estimate') else
	 (case when (sv.servicetickettypeid=2) then ('Work-Order') else 
	 (case when (sv.servicetickettypeid=3) then ('Invoice') else ('Delivered') end) end) END  AS Status
	-- s.Status as Status  ,sv.locationid  
	 from SVC_ServiceTicket sv with(nolock) 
   LEFT JOIN SVC_ServiceTicketBill STB with(nolock) ON SV.ServiceTicketID=stb.ServiceTicketID		 
   LEFT join COM_Location l with(nolock) on sv.LocationID=l.NodeID  
  -- LEFT join COM_Status s with(nolock) on sv.StatusID=s.StatusID  
   LEFT join SVC_CustomersVehicle cv with(nolock) on sv.CustomerVehicleID=cv.CV_ID  
   LEFT join SVC_Customers c with(nolock) on cv.CustomerID=c.CustomerID   
   LEFT join SVC_Vehicle v with(nolock) on cv.VehicleID=v.VehicleID
   WHERE SV.ARRIVALDATETIME >= (CONVERT(FLOAT,@TicketFDate)) and SV.ARRIVALDATETIME <=(CONVERT(FLOAT,@TickettDate))
   and sv.locationid=@Location
			

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
SET NOCOUNT OFF  
RETURN -999   
END CATCH  

GO

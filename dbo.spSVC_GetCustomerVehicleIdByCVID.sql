USE PACT2C222
GO
SET ANSI_NULLS, QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spSVC_GetCustomerVehicleIdByCVID]
	@CV_ID [bigint] = 0,
	@UserID [bigint],
	@LangID [int] = 1
WITH ENCRYPTION, EXECUTE AS CALLER
AS
BEGIN TRANSACTION  
BEGIN TRY  
SET NOCOUNT ON;
	 
		--Declaration Section
		DECLARE @HasAccess BIT,@ColorTable NVARCHAR(20),@EngineTable NVARCHAR(20),@FuelTable NVARCHAR(20),@SQL NVARCHAR(MAX)
		--SP Required Parameters Check
		IF @CV_ID=0 
		BEGIN
			RAISERROR('-100',16,1)
		END

		--To get costcenter table name
		SELECT CustomerID,VehicleID
		FROM SVC_CustomersVehicle
		WHERE CV_ID=@CV_ID
		
		
		--Getting TicketsInformataion
		select   
		 sv.ServiceTicketNumber as Ticket,  
		 c.CustomerName as Customer ,  
		 v.Make+'-'+v.Model+'-'+v.Variant+'-'+convert(nvarchar,cv.year) as Vehicle ,
		 case when cv.PlateNumber is null or cv.PlateNumber = '' then '-' else cv.PlateNumber end as PlateNo,
		 convert(datetime,sv.ArrivalDateTime) Arrival,   
		 convert(datetime,sv.DeliveryDateTime) Delivery,   
		 stb.Total as Amount,L.Name as Location,
		 s.Status as Status, o.Name as Relation ,  cf.Name as ConcernName
		 from SVC_ServiceTicket sv with(nolock) 
		LEFT JOIN SVC_ServiceTicketBill STB with(nolock) ON SV.ServiceTicketID=stb.ServiceTicketID		 
		LEFT join COM_Location l with(nolock) on sv.LocationID=l.NodeID  
		LEFT join COM_Status s with(nolock) on sv.StatusID=s.StatusID  
		LEFT join SVC_CustomersVehicle cv with(nolock) on sv.CustomerVehicleID=cv.CV_ID  
		LEFT join SVC_Customers c with(nolock) on cv.CustomerID=c.CustomerID  
		left join SVC_CustomerFamilyDetails cf with(nolock) on c.customerid=cf.customerid 
		left join com_lookup o with(nolock) on cf.relation=o.NodeID
		LEFT join SVC_Vehicle v with(nolock) on cv.VehicleID=v.VehicleID
		WHERE sv.CustomerVehicleID=@CV_ID
 
 
COMMIT TRANSACTION 
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
ROLLBACK TRANSACTION
SET NOCOUNT OFF  
RETURN -999   
END CATCH
GO

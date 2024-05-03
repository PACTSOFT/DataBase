USE PACT2C222
GO
SET ANSI_NULLS, QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spSVC_GetBreakDownTicket]
	@IncidentID [int] = 0
WITH ENCRYPTION, EXECUTE AS CALLER
AS
BEGIN TRANSACTION  
BEGIN TRY  
SET NOCOUNT ON;
  
if(@IncidentID=0)
	begin

	   Select bd.Incident_ID,
			  bd.BreakDownTicketNumber as Ticket,
		      bd.CallReceivedDateTime as Date,
              c.CustomerName as Name, 
			  v.Make+'-'+v.Model+'-'+v.Variant as Vehicle,
              -- cv.PlateNumber as Plate,
              case when cv.PlateNumber is null or cv.PlateNumber = '' then '-' else cv.PlateNumber end as Plate,
			  l.Name as Location,
              s.Status as Status
			from SVC_BreakDownTicket bd with(nolock)
			 join COM_Location l on bd.Location=l.NodeID  
			 join COM_Status s on bd.StatusID=s.StatusID
             join SVC_CustomersVehicle cv on bd.CustomerVehicleID=cv.CV_ID
			 join SVC_Customers c on cv.CustomerID=c.CustomerID 
			  left join SVC_Vehicle v on cv.VehicleID=v.VehicleID
			
	end		 
else
	begin

	Select bd.Incident_ID,
			  bd.BreakDownTicketNumber as Ticket,
		      bd.CallReceivedDateTime as Date,
              c.CustomerName as Name, 
			  v.Make+'-'+v.Model+'-'+v.Variant as Vehicle,c.AccountName,
             -- cv.PlateNumber as Plate,
             case when cv.PlateNumber is null or cv.PlateNumber = '' then '-' else cv.PlateNumber end as Plate,
			  l.Name as Location,
              s.Status as Status
			from SVC_BreakDownTicket bd with(nolock)
			 join COM_Location l on bd.Location=l.NodeID  
			 join COM_Status s on bd.StatusID=s.StatusID
             join SVC_CustomersVehicle cv on bd.CustomerVehicleID=cv.CV_ID
			 join SVC_Customers c on cv.CustomerID=c.CustomerID 
			 left join SVC_Vehicle v on cv.VehicleID=v.VehicleID where Incident_ID=@IncidentID


	select Incident_ID,CustomerVehicleID,BreakDownTicketBillPayment,TechnicianID,StartDateTime,EndDateTime,StatusID,TowerID,BreakDownTicketNumber,Location,Landmark,ComplaintNotes,Remarks,
          convert(datetime,CallReceivedDateTime) as CallReceivedDateTime,	
			convert(datetime,TeamReachedDate) as TeamReachedDate,
			convert(datetime,TeamDepartDate)as TeamDepartDate from
		 SVC_BreakDownTicket 
		where Incident_ID=@IncidentID;  --BreakDownTicket

    select a.CV_ID,b.Make+'-'+Model+'-'+Variant Vehicle from SVC_CustomersVehicle a
join dbo.SVC_Vehicle b on a.VehicleID=b.VehicleID 
	  where CustomerID = ( select CustomerID  from    dbo.SVC_CustomersVehicle 
where CV_ID=(select CustomerVehicleID from SVC_BreakDownTicket where Incident_ID=@IncidentID));


	select * from SVC_Customers where CustomerID=( select CustomerID from SVC_CustomersVehicle  where 
                            CV_ID=(select CustomerVehicleID from SVC_BreakDownTicket 
                                             where Incident_ID=@IncidentID))  --Customer

	select * from COM_Contacts where FeaturePK=( select CustomerID from SVC_CustomersVehicle  where 
                            CV_ID=(select CustomerVehicleID from SVC_BreakDownTicket 
                                             where Incident_ID=@IncidentID)) and FeatureID=54  --Contacts

 

	select * from SVC_BreakDownTicketBillPayment where BreakDownTicketBillPaymentID=(select BreakDownTicketBillPayment from SVC_BreakDownTicket 
                                             where Incident_ID=@IncidentID);  --BreakDownTicketBillPayment
	End	


COMMIT TRANSACTION	
SET NOCOUNT OFF;
RETURN 1
END TRY
BEGIN CATCH  
		--Return exception info [Message,Number,ProcedureName,LineNumber]  
		IF ERROR_NUMBER()=50000
		BEGIN
			SELECT ErrorMessage,ErrorNumber FROM COM_ErrorMessages WITH(NOLOCK) WHERE ErrorNumber=ERROR_MESSAGE() AND LanguageID=1
		END
		ELSE
		BEGIN
			SELECT ErrorMessage, ERROR_MESSAGE() AS ServerMessage,ERROR_NUMBER() as ErrorNumber, ERROR_PROCEDURE()as ProcedureName, ERROR_LINE() AS ErrorLine
			FROM COM_ErrorMessages WITH(NOLOCK) WHERE ErrorNumber=-999 AND LanguageID=1
		END
ROLLBACK TRANSACTION
SET NOCOUNT OFF  
RETURN -999   
END CATCH




GO

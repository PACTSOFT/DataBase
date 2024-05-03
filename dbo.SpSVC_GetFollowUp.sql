USE PACT2C222
GO
SET ANSI_NULLS, QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[SpSVC_GetFollowUp]
	@TicketID [nvarchar](50) = null,
	@TicketSequenceNO [int] = 0,
	@Type [int]
WITH ENCRYPTION, EXECUTE AS CALLER
AS
BEGIN TRANSACTION  
BEGIN TRY  
SET NOCOUNT ON;
 
 if(@Type=0)
 BEGIN 
	select fu.ServiceTicketFollowUpID as ServiceTicketFollowUpID,fu.ServiceTicketID as ServiceTicketID,lu.Name as CommunicationType,fu.Response,fu.Remarks,convert(datetime,fu.CallTime) CallTime,fu.Time,fu.IsCreateEvent  as CreateEvent
	from SVC_ServiceTicketFollowUp fu 
	join COM_Lookup lu on fu.CommunicationType=lu.NodeID
	where fu.ServiceTicketID=@TicketID;

	select StatusID,CommunicationType,Response,Remarks,convert(Datetime,CallTime) as CallTime,Time,IsCreateEvent as CreateEvent from SVC_ServiceTicketFollowUp where ServiceTicketID=@TicketID and ServiceTicketFollowUpID=@TicketSequenceNO
 END
 ELSE
 BEGIN
	select StatusID,CommunicationType,Response,Remarks,convert(Datetime,CallTime) as CallTime,Time,IsCreateEvent as CreateEvent from SVC_ServiceTicketFollowUp where ServiceTicketFollowUpID=@TicketSequenceNO
 END	

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

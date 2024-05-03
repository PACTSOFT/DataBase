USE PACT2C222
GO
SET ANSI_NULLS, QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spSVC_GetEditTicketDatesInfo]
	@TicketID [bigint] = 0,
	@isEstimate [bit],
	@UserID [bigint],
	@LangID [int] = 1
WITH ENCRYPTION, EXECUTE AS CALLER
AS
BEGIN TRY	
SET NOCOUNT ON
 
 
 
BEGIN 
if(@isEstimate=1)
	SELECT Convert(datetime,[EstimateDateTime]) as [EstimateDateTime],[DateChangeReason] as Relation_Key,L.Name as Relation, Remarks,
	d.Createdby as Userid, U.UserName as UserName, convert(datetime,d.CreatedDate) as CreatedDate
	FROM SVC_ServiceTicketDatesComm d  WITH(NOLOCK) 
			left join com_lookup L  WITH(NOLOCK) on L.NodeID=d.DateChangeReason
			lEFT JOIN ADM_USERS U  WITH(NOLOCK) ON u.UserID=D.Createdby
			where d.ServiceTicketID=@TicketID and [DeliveryDateTime] is null
			
else
	SELECT Convert(datetime,[DeliveryDateTime]) as [DeliveryDateTime],[DateChangeReason] as Relation_Key,L.Name as Relation, Remarks,  
	d.Createdby as Userid, U.UserName as UserName, convert(datetime,d.CreatedDate) as CreatedDate
	FROM SVC_ServiceTicketDatesComm d  WITH(NOLOCK) 
			left join com_lookup L  WITH(NOLOCK) on L.NodeID=d.DateChangeReason
			lEFT JOIN ADM_USERS U  WITH(NOLOCK) ON u.UserID=D.Createdby
			where d.ServiceTicketID=@TicketID and [EstimateDateTime] is null

END
 

 
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

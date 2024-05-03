USE PACT2C222
GO
SET ANSI_NULLS, QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spSVC_SetConfigureFollowUp]
	@PostService [int],
	@DeclinedJob [int],
	@FollowUp [int]
WITH ENCRYPTION, EXECUTE AS CALLER
AS
BEGIN TRANSACTION  
BEGIN TRY  
SET NOCOUNT ON;

update dbo.ADM_GridView set SearchFilter='sv.DeliveryDateTime <= convert(float,getdate()-'+convert(nvarchar,@Postservice)+') AND sv.DeliveryDateTime > convert(float,getdate()-'+convert(nvarchar,@Postservice+1)+')   AND (fu.ServiceTicketFollowUpID is null or  fu.ServiceTicketID   not in  (select ServiceTicketID from SVC_ServiceTicketFollowUp where  statusid=367))',FilterXml=@Postservice where GridViewID=156 and FeatureID=143;
update dbo.ADM_GridView set SearchFilter='sj.IsDeclined = 1 AND sv.DeliveryDateTime <= convert(float,getdate()-'+convert(nvarchar,@DeclinedJob)+') AND sv.DeliveryDateTime > convert(float,getdate()-'+convert(nvarchar,@DeclinedJob+1)+')  AND (fu.ServiceTicketFollowUpID is null or  fu.ServiceTicketID   not in  (select ServiceTicketID from SVC_ServiceTicketFollowUp where  statusid=367))',FilterXml=@DeclinedJob where GridViewID=157 and FeatureID=143;
update dbo.ADM_GridView set SearchFilter='sv.DeliveryDateTime <= convert(float,getdate()-'+convert(nvarchar,@FollowUp)+') AND sv.DeliveryDateTime > convert(float,getdate()-'+convert(nvarchar,@FollowUp+1)+')  AND (fu.ServiceTicketFollowUpID is null or  fu.ServiceTicketID   not in  (select ServiceTicketID from SVC_ServiceTicketFollowUp where  statusid=367))',FilterXml=@FollowUp  where GridViewID=158 and FeatureID=143;

COMMIT TRANSACTION    
SET NOCOUNT OFF; 
SELECT ErrorMessage,ErrorNumber FROM COM_ErrorMessages WITH(nolock) 
WHERE ErrorNumber=100 AND LanguageID=1  
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
		SELECT ErrorMessage, ERROR_MESSAGE() AS ServerMessage,ERROR_NUMBER() AS ErrorNumber, ERROR_PROCEDURE()AS ProcedureName, ERROR_LINE() AS ErrorLine
		FROM COM_ErrorMessages WITH(NOLOCK) WHERE ErrorNumber=-999 AND LanguageID=1
	END
	ROLLBACK TRANSACTION
	SET NOCOUNT OFF  
	RETURN -999   
END CATCH 

GO

USE PACT2C222
GO
SET ANSI_NULLS, QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[SpSVC_SaveEstimateDetails]
	@TicketId [bigint] = 0,
	@EstimateDueDate [datetime] = null,
	@DeliveryDateTime [datetime] = null,
	@RelationID [bigint] = 0,
	@Remarks [nvarchar](max) = null,
	@COMPANYGUID [nvarchar](50),
	@USERNAME [nvarchar](50),
	@USERID [int],
	@LANGID [int]
WITH ENCRYPTION, EXECUTE AS CALLER
AS
BEGIN TRANSACTION  
BEGIN TRY  
SET NOCOUNT ON;
		--Declaration Section 
		declare @CreatedDate float
		
		declare @ServiceTicketTypeID int , @ArrivalStatusID int, @ArrivalDateTime float 
		set @CreatedDate= convert(float,getdate())
		
		select @ServiceTicketTypeID=ServiceTicketTypeID, @ArrivalStatusID=ArrivalStatusID,@ArrivalDateTime=ArrivalDateTime  from svc_serviceticket where 
		serviceticketid=@TicketId
		
		--INSERT DATE CHANGE NOTIFICATION
		if(@EstimateDueDate<>'')
			INSERT INTO [SVC_ServiceTicketDatesComm]([ServiceTicketID],[ServiceTicketType],[ArrivalStatusID],[ArrivalDateTime]
							,[EstimateDateTime],[CommTemplateID],[CommType],[CommSentDate],[DateChangeReason]
							,[CompanyGUID],[CreatedBy],[CreatedDate], [Remarks])
				VALUES(@TicketID,@ServiceTicketTypeID,@ArrivalStatusID,@ArrivalDateTime,
						  ROUND(CONVERT(FLOAT,@EstimateDueDate),6),0,0,0,@RelationID,
						@COMPANYGUID,@USERID,@CreatedDate, @Remarks)
		else if(@DeliveryDateTime<>'')
			INSERT INTO [SVC_ServiceTicketDatesComm]([ServiceTicketID],[ServiceTicketType],[ArrivalStatusID],[ArrivalDateTime]
							,[DeliveryDateTime],[CommTemplateID],[CommType],[CommSentDate],[DateChangeReason]
							,[CompanyGUID],[CreatedBy],[CreatedDate], [Remarks])
				VALUES(@TicketID,@ServiceTicketTypeID,@ArrivalStatusID,@ArrivalDateTime
						, ROUND(CONVERT(FLOAT,@DeliveryDateTime),6) ,0,0,0,@RelationID,
						@COMPANYGUID,@USERID,@CreatedDate, @Remarks)
						
   
COMMIT TRANSACTION    
SET NOCOUNT OFF; 
SELECT ErrorMessage,ErrorNumber FROM COM_ErrorMessages WITH(nolock) 
WHERE ErrorNumber=100 AND LanguageID=@LangID  
RETURN @TicketId
END TRY  
BEGIN CATCH  
	--Return exception info [Message,Number,ProcedureName,LineNumber]  
	IF ERROR_NUMBER()=50000
	BEGIN		  
		SELECT ErrorMessage,ErrorNumber FROM COM_ErrorMessages WITH(NOLOCK) WHERE ErrorNumber=ERROR_MESSAGE() AND LanguageID=@LangID
	END
	ELSE
	BEGIN
		SELECT ErrorMessage, ERROR_MESSAGE() AS ServerMessage,ERROR_NUMBER() AS ErrorNumber, ERROR_PROCEDURE()AS ProcedureName, ERROR_LINE() AS ErrorLine
		FROM COM_ErrorMessages WITH(NOLOCK) WHERE ErrorNumber=-999 AND LanguageID=@LangID
	END
	ROLLBACK TRANSACTION
	SET NOCOUNT OFF  
	RETURN -999   
END CATCH 







GO

USE PACT2C222
GO
SET ANSI_NULLS, QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spSVC_SaveFeedbackDetails]
	@TicketID [bigint],
	@FeedbackXML [nvarchar](max),
	@COMPANYGUID [nvarchar](50),
	@USERNAME [nvarchar](50),
	@RoleID [int],
	@LANGID [int]
WITH ENCRYPTION, EXECUTE AS CALLER
AS
BEGIN TRANSACTION  
BEGIN TRY  
SET NOCOUNT ON;
		--Declaration Section  	
		DECLARE @HasAccess BIT
		DECLARE @CreatedDate FLOAT,@XML XML,@IsEdit BIT

		--User access check 
		SET @HasAccess=dbo.fnCOM_HasAccess(@RoleID,59,134)
		IF @HasAccess=0
		BEGIN
			RAISERROR('-105',16,1)
		END 

		SET @CreatedDate=CONVERT(FLOAT,getdate())
		  SET @XML=@FeedbackXML    
	 	DELETE FROM SVC_Feedback WHERE ServiceTicketID=@TicketID
		
		INSERT INTO SVC_Feedback(ServiceTicketID,FeedbackID,GUID,CreatedBy,CreatedDate)
		SELECT @TicketID,A.value('@ID','INT'),NEWID(),@USERNAME,@CreatedDate
		FROM @XML.nodes('/Feedback/row') AS DATA(A)
		print @FeedbackXML
		declare @FeedbackRemarks nvarchar(max)
		
		set @FeedbackRemarks =	(select top 1 A.value('@FeedbackRemarks','nvarchar(max)')
		from @XML.nodes('/Feedback/row') AS DATA(A))
		print @FeedbackRemarks
		update svc_serviceticket
		set  FeedbackRemarks= @FeedbackRemarks
		where ServiceTicketID=@TicketID
  

COMMIT TRANSACTION
--ROLLBACK TRANSACTION
SET NOCOUNT OFF; 
SELECT ErrorMessage,ErrorNumber FROM COM_ErrorMessages WITH(nolock) 
WHERE ErrorNumber=100 AND LanguageID=@LangID    
RETURN @TicketID
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
	BEGIN TRY
		ROLLBACK TRANSACTION
	END TRY  
	BEGIN CATCH 
	END CATCH

	SET NOCOUNT OFF  
	RETURN -999   
END CATCH






GO

USE PACT2C222
GO
SET ANSI_NULLS, QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spSVC_SetTicketDiscountInfo]
	@TicketID [nvarchar](max),
	@BillAmt [float],
	@DiscPer [float],
	@DiscAmt [float],
	@Reason [int],
	@Remarks [nvarchar](max),
	@CompanuGUID [nvarchar](50),
	@UserName [nvarchar](50),
	@USERID [int],
	@LANGID [int]
WITH ENCRYPTION, EXECUTE AS CALLER
AS
BEGIN TRANSACTION  
BEGIN TRY  
SET NOCOUNT ON;
		--Declaration Section  	 
		DECLARE @XML xml  , @Createddt float
		set @Createddt=CONVERT(float,getdate())
		
		delete from SVC_ServiceTicketDiscDetails where serviceticketid=@TicketID
		INSERT INTO [SVC_ServiceTicketDiscDetails]
		   ( [ServiceTicketID],[BillAmt],[DiscPercentage],[DiscAmt],[Reason],[Remarks],
		   [CompanyGUID],[GUID],[Createdby],[CreatedDate])
		VALUES
		   ( @TicketID, @BillAmt, @DiscPer, @DiscAmt, @Reason, @Remarks, 
		   @CompanuGUID,newid(),@UserName,CONVERT(float,getdate())) 
		 
 

COMMIT TRANSACTION    
--ROLLBACK TRANSACTION
SET NOCOUNT OFF; 
SELECT ErrorMessage,ErrorNumber FROM COM_ErrorMessages WITH(nolock) 
WHERE ErrorNumber=100 AND LanguageID=@LangID  
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
		SELECT ErrorMessage, ERROR_MESSAGE() AS ServerMessage,ERROR_NUMBER() AS ErrorNumber, ERROR_PROCEDURE()AS ProcedureName, ERROR_LINE() AS ErrorLine
		FROM COM_ErrorMessages WITH(NOLOCK) WHERE ErrorNumber=-999 AND LanguageID=@LangID
	END
	ROLLBACK TRANSACTION
	SET NOCOUNT OFF  
	RETURN -999   
END CATCH 

 
GO

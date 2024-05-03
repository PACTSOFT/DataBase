USE PACT2C222
GO
SET ANSI_NULLS, QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spSVC_DeleteBreakDownTicket]
	@TicketNo [nvarchar](50)
WITH ENCRYPTION, EXECUTE AS CALLER
AS
BEGIN TRANSACTION
BEGIN TRY  
SET NOCOUNT ON;  
		--Declaration Section
		DECLARE @RowsDeleted bigint

		--SP Required Parameters Check
		if(@TicketNo is null)
		BEGIN
			RAISERROR('-100',16,1)
		END


		--Delete From SVC_BreakDownTicket--
			Delete from SVC_BreakDownTicket where BreakDownTicketNumber=@TicketNo;

		--Delete from SVC_CustomersVehicle--
			delete from SVC_CustomersVehicle where CV_ID=(select CustomerVehicleID from SVC_BreakDownTicket 
                                             where BreakDownTicketNumber=@TicketNo);
		--Delete from SVC_Customers--
			delete from SVC_Customers where CustomerID=( select CustomerID from SVC_CustomersVehicle  where 
                            CV_ID=(select CustomerVehicleID from SVC_BreakDownTicket 
                                             where BreakDownTicketNumber=@TicketNo));
		--Delete from COM_Contacts--
			delete from COM_Contacts where FeaturePK=( select CustomerID from SVC_CustomersVehicle  where 
                            CV_ID=(select CustomerVehicleID from SVC_BreakDownTicket 
                                             where BreakDownTicketNumber=@TicketNo)) and FeatureID=54
		--Delete from SVC_Vehicle--
			Delete from SVC_Vehicle where VehicleID=(select VehicleID from SVC_CustomersVehicle  where 
                            CV_ID=(select CustomerVehicleID from SVC_BreakDownTicket 
                                             where BreakDownTicketNumber=@TicketNo));
		--Delete from SVC_BreakDownTicketBillPayment--
			Delete from SVC_BreakDownTicketBillPayment where BreakDownTicketBillPaymentID=(select BreakDownTicketBillPayment from SVC_BreakDownTicket 
                                             where BreakDownTicketNumber=@TicketNo);

    SET @RowsDeleted=@@rowcount
COMMIT TRANSACTION
SET NOCOUNT OFF;  
SELECT ErrorMessage,ErrorNumber FROM COM_ErrorMessages WITH(nolock) 
WHERE ErrorNumber=102 AND LanguageID=1

RETURN 1
END TRY
BEGIN CATCH  
	--Return exception info [Message,Number,ProcedureName,LineNumber]  
	IF ERROR_NUMBER()=50000
	BEGIN
		SELECT ErrorMessage,ErrorNumber FROM COM_ErrorMessages WITH(nolock) WHERE ErrorNumber=ERROR_MESSAGE() AND LanguageID=1
	END
	ELSE IF ERROR_NUMBER()=547
	BEGIN
		SELECT ErrorMessage, ERROR_MESSAGE() AS ServerMessage,ERROR_NUMBER() as ErrorNumber, ERROR_PROCEDURE()as ProcedureName, ERROR_LINE() AS ErrorLine FROM COM_ErrorMessages WITH(nolock)
		WHERE ErrorNumber=-110 AND LanguageID=1
	END
	ELSE 
	BEGIN
		SELECT ErrorMessage, ERROR_MESSAGE() AS ServerMessage,ERROR_NUMBER() as ErrorNumber, ERROR_PROCEDURE()as ProcedureName, ERROR_LINE() AS ErrorLine
		FROM COM_ErrorMessages WITH(nolock) WHERE ErrorNumber=-999 AND LanguageID=1
	END
ROLLBACK TRANSACTION
SET NOCOUNT OFF  
RETURN -999   
END CATCH





GO

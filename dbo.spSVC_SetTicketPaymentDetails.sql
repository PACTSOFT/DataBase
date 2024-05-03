USE PACT2C222
GO
SET ANSI_NULLS, QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spSVC_SetTicketPaymentDetails]
	@TicketID [bigint],
	@PaymentsXML [nvarchar](max),
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
		DECLARE @HasAccess BIT
		DECLARE @CreatedDate FLOAT,@XML XML,@IsEdit BIT


		SET @CreatedDate=CONVERT(FLOAT,getdate())
  SET @XML=@PaymentsXML    
		delete from SVC_ServiceTicketBillPayment where ServiceTicketID=@TicketID and DocDetailsID in
		(select A.value('@DocDetailsID','BIGINT')  FROM @XML.nodes('/Payments/row') AS DATA(A))
		/****** SERVICE TICKET PAYMENTS ******/
		
		INSERT INTO SVC_ServiceTicketBillPayment(ServiceTicketID,PaymentTypeID,PaymentMode,
				PaymentDate,CurrencyID,PaymentAmount,
				InsuranceClaimNo,
				CreditCardTypeID,CreditCardNumber,CreditCardExpiryDate,CreditCardSecurityCode,
				ChequeNumber,ChequeDate,ChequeBankName,ChequeBankRountingNumber,
				GiftCoupanNumber,GiftCoupanType,
				COMPANYGUID,GUID,CreatedBy,CreatedDate,DocDetailsID ,IsAdvance)
		SELECT @TicketID,A.value('@TypeID','INT'),A.value('@Mode','NVARCHAR(20)'),
				CONVERT(FLOAT,A.value('@Date','DATETIME')),A.value('@Currency','INT'),A.value('@Amount','FLOAT'),
				A.value('@INS1','NVARCHAR(50)'),
				A.value('@CC1','INT'),A.value('@CC2','nvarchar(50)'),A.value('@CC3','nvarchar(20)'),A.value('@CC4','nvarchar(50)'),
				A.value('@CQ1','nvarchar(20)'),CONVERT(FLOAT,A.value('@CQ2','DATETIME')),A.value('@CQ3','nvarchar(200)'),A.value('@CQ4','nvarchar(50)'),
				A.value('@GC1','nvarchar(50)'),A.value('@GC2','INT'),			
				@COMPANYGUID,NEWID(),@USERNAME,@CreatedDate,A.value('@DocDetailsID','BIGINT'), A.value('@IsAdvance','BIT')
		FROM @XML.nodes('/Payments/row') AS DATA(A)

  

COMMIT TRANSACTION
--ROLLBACK TRANSACTION
SET NOCOUNT OFF; 
SELECT ErrorMessage,ErrorNumber FROM COM_ErrorMessages WITH(nolock) 
WHERE ErrorNumber=100 AND LanguageID=@LangID  

select VoucherNo from acc_docdetails 
where DocID in (select A.value('@DocDetailsID','BIGINT')  FROM @XML.nodes('/Payments/row') AS DATA(A)) and docid>0

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

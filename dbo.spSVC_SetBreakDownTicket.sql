USE PACT2C222
GO
SET ANSI_NULLS, QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spSVC_SetBreakDownTicket]
	@NodeID [bigint] = 0,
	@Name [nvarchar](500),
	@Address1 [nvarchar](500) = NULL,
	@Address2 [nvarchar](500) = NULL,
	@Address3 [nvarchar](500) = NULL,
	@Phone1 [nvarchar](50) = NULL,
	@Phone2 [nvarchar](50) = NULL,
	@Email [nvarchar](50) = NULL,
	@AccNo [bigint] = 0,
	@CV_ID [bigint],
	@Plate [nvarchar](50) = NULL,
	@Color [bigint] = 0,
	@OdometerIn [nvarchar](50) = NULL,
	@OdometerOut [nvarchar](50) = NULL,
	@CallReceivedDateTime [datetime],
	@TechnicianID [bigint] = 0,
	@TeamReachedDate [datetime],
	@TeamDepartDate [datetime],
	@StartDateTime [nvarchar](50) = NULL,
	@EndDateTime [nvarchar](50) = NULL,
	@StatusID [bigint] = 0,
	@Tower [bigint] = 0,
	@BreakDownTicketID [varchar](50) = NULL,
	@Location [bigint] = 0,
	@Landmark [nvarchar](50) = NULL,
	@Remarks [nvarchar](max) = NULL,
	@ComplaintNote [nvarchar](max) = NULL,
	@PaymentTypeID [bigint] = 0,
	@PaymentAmount [float] = 0.0,
	@ChequeBankName [nvarchar](200) = NULL,
	@ChequeNumber [nvarchar](20) = NULL,
	@ChequeDate [datetime] = 0,
	@ChequeBankRountingNumber [nvarchar](50) = NULL,
	@CreditCardTypeID [bigint] = 0,
	@CreditCardNumber [nvarchar](20) = NULL,
	@CreditCardExpiryDate [datetime],
	@CreditCardSecurityCode [nvarchar](20) = NULL,
	@GiftCoupanNumber [nvarchar](50) = NULL,
	@GiftCoupanType [bigint] = 0,
	@CompanyGUID [nvarchar](50) = NULL,
	@UserName [nvarchar](50) = NULL,
	@LangID [int] = 1
WITH ENCRYPTION, EXECUTE AS CALLER
AS
BEGIN TRANSACTION  
BEGIN TRY  
SET NOCOUNT ON;
		--Declaration Section  	
		DECLARE @CreatedDate FLOAT,
                @CustomerVehicleID bigint,
                @CustomerID bigint,
              --  @CV_ID bigint,
                @IncidentID bigint,
			------	@VehicleID bigint,
				@Cylindername varchar(50),
				@PaymentAmountID bigint;
		SET @CreatedDate=CONVERT(FLOAT,getdate())
		

			if(@CV_ID >0)
			begin
				update SVC_CustomersVehicle set PlateNumber=@Plate,
												Color=@Color,
												OdometerIn=@OdometerIn,
												OdometerOut=@OdometerOut  where CV_ID=@CV_ID
--												EngineType=@Engine,
--												FuelDelivery=@FuelDelivery,
--												Cylinders=@Cylinder,
--												Insurance=@Insurance where CV_ID=@CV_ID
			end


if(@NodeID=0)
	begin
		EXEC [spCOM_SetCode] 54,'',@BreakDownTicketID OUTPUT
		if(@Name is null)
		begin
			raiserror('-116',16,1)
		end
			 --Inserting Into Customer--
			Insert into SVC_Customers([CustomerCode],[CustomerName] ,[CustomerTypeID],[StatusID],[Depth],[ParentID],[lft],[rgt],
								[IsGroup],[AccountName],[IsUserDefined],[CompanyGUID],[GUID],[CreatedBy],[CreatedDate])
						Values('BDV-'+convert(nvarchar(50),{fn NOW()}),@Name,1,357,1,1,0,0,
								0,@AccNo,1,@CompanyGUID,newid(),@UserName,@CreatedDate)
									   
			set @CustomerID=SCOPE_IDENTITY()
	 
			--Insert Primary Contact--
			INSERT  [COM_Contacts]([AddressTypeID],[FeatureID],[FeaturePK],[Address1],[Address2],[Address3]
					,[Phone1],[Phone2],[Email1],[CompanyGUID],[GUID] ,[CreatedBy],[CreatedDate])
					VALUES(1,54,@CustomerID,@Address1,@Address2,@Address3
					,@Phone1,@Phone2,@Email,@CompanyGUID,NEWID(),@UserName,@CreatedDate)
		 

			--Inserting into BreakDownTicketBillPayment--
			  insert into SVC_BreakDownTicketBillPayment(PaymentTypeID,CurrencyID,PaymentAmount,InsuranceCompanyID,
											InsuranceCardNumber,InsuranceAuthNumber,InsurancePONumber,CreditCardTypeID,
											CreditCardNumber,CreditCardExpiryDate,CreditCardSecurityCode,ChequeBankName,
											ChequeNumber,ChequeDate,ChequeBankRountingNumber,GiftCoupanNumber,GiftCoupanType,
											CompanyGUID,GUID,CreatedBy,CreatedDate)
								values(@PaymentTypeID ,1 ,@PaymentAmount ,0 ,
										null,null,null,@CreditCardTypeID ,
										@CreditCardNumber,convert(float,@CreditCardExpiryDate) ,@CreditCardSecurityCode,@ChequeBankName,
										@ChequeNumber,convert(float,@ChequeDate) ,@ChequeBankRountingNumber,@GiftCoupanNumber,@GiftCoupanType,
										@CompanyGUID,NEWID(),@UserName,@CreatedDate)
				set @PaymentAmountID=scope_identity()

			--Inserting into INCIDENT---
	      
			insert into SVC_BreakDownTicket(CustomerVehicleID,BreakDownTicketBillPayment,CallReceivedDateTime,TechnicianID,
						TeamReachedDate,StartDateTime,TeamDepartDate,EndDateTime,StatusID,TowerID,BreakDownTicketNumber,
						Location,Landmark,ComplaintNotes,Remarks,CompanyGUID,GUID,CreatedBy,CreatedDate)
									 values(@CV_ID,@PaymentAmountID,convert(float,@CallReceivedDateTime),@TechnicianID,
						convert(float,@TeamReachedDate),@StartDateTime,convert(float,@TeamDepartDate),@EndDateTime,@StatusID,@Tower,
						@BreakDownTicketID,@Location,@Landmark,@ComplaintNote,@Remarks,@CompanyGUID,NEWID(),@UserName,@CreatedDate)
		set @NodeID=scope_identity()

	end
else
	begin
--		declare @cvid bigint,@custoid bigint,@vehid bigint,@bdtbid bigint
--		set @custoid=(select top 1 CustomerID from SVC_CustomersVehicle where CV_ID=@cvid)
--		set @vehid=(select top 1 VehicleID from SVC_CustomersVehicle where CV_ID=@cvid)

	-----UPDATING 	SVC_BreakDownTicket------
		update SVC_BreakDownTicket set  CustomerVehicleID=@CV_ID,
										CallReceivedDateTime=convert(float,@CallReceivedDateTime),
										TechnicianID=@TechnicianID,
										TeamReachedDate=convert(float,@TeamReachedDate),
										StartDateTime=@StartDateTime ,			   
										TeamDepartDate=convert(float,@TeamDepartDate),			   
										EndDateTime=@EndDateTime,
										StatusID=@StatusID,
										TowerID=@Tower,
										BreakDownTicketNumber=@BreakDownTicketID,
										Location=@Location,
										Landmark=@Landmark,
										ComplaintNotes=@ComplaintNote,
										Remarks=@Remarks where Incident_ID=@NodeID;
--set @cvid=(select top 1 CustomerVehicleID from SVC_BreakDownTicket where Incident_ID=@NodeID)
--set @bdtbid=(select top 1 BreakDownTicketBillPayment from SVC_BreakDownTicket where Incident_ID=@NodeID)
	-----UPDATING  SVC_BreakDownTicketBillPayment------
		update SVC_BreakDownTicketBillPayment set 	
											PaymentTypeID=@PaymentTypeID,    
											CurrencyID=1,
											PaymentAmount=@PaymentAmount,
	--										InsuranceCompanyID=@InsuranceCompanyID,
	--										InsuranceCardNumber=@InsuranceCardNumber,
	--										InsuranceAuthNumber=@InsuranceAuthNumber,
	--										InsurancePONumber=@InsurancePONumber,		   
											CreditCardTypeID=@CreditCardTypeID,
											CreditCardNumber=@CreditCardNumber,
											CreditCardExpiryDate=convert(float,@CreditCardExpiryDate),
											CreditCardSecurityCode=@CreditCardSecurityCode,
											ChequeBankName=@ChequeBankName,			   
											ChequeNumber=@ChequeNumber,			   
											ChequeDate=convert(float,@ChequeDate),				   
											ChequeBankRountingNumber=@ChequeBankRountingNumber,  
											GiftCoupanNumber=@GiftCoupanNumber,
											GiftCoupanType=@GiftCoupanType where BreakDownTicketBillPaymentID=(select top 1 BreakDownTicketBillPayment from SVC_BreakDownTicket where Incident_ID=@NodeID);


	----UPDATING SVC_Customers-------------
		update SVC_Customers set CustomerName=@Name,AccountName=@AccNo where CustomerID = (select top 1 CustomerID from SVC_CustomersVehicle where CV_ID=@CV_ID);

	---UpDATING COM_Contacts--------------
		update COM_Contacts set 
						Address1=@Address1,
						Address2=@Address2,
						Address3=@Address3,
						Phone1=@Phone1,
						Phone2=@Phone2,
						Email1=@Email where FeaturePK=(select top 1 VehicleID from SVC_CustomersVehicle where CV_ID=@CV_ID) and FeatureID=54;
	end

COMMIT TRANSACTION    
SET NOCOUNT OFF; 
SELECT ErrorMessage,ErrorNumber FROM COM_ErrorMessages WITH(nolock) 
WHERE ErrorNumber=100 AND LanguageID=@LangID  
RETURN @NodeID
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

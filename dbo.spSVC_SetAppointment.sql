USE PACT2C222
GO
SET ANSI_NULLS, QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spSVC_SetAppointment]
	@AppointmentID [int],
	@AppDate [datetime],
	@FromTime [nvarchar](50),
	@ToTime [nvarchar](50),
	@CVehicleID [int],
	@Location [int],
	@Comments [nvarchar](max) = null,
	@AppServiceXML [nvarchar](max),
	@CompanyGUID [nvarchar](100),
	@GUID [nvarchar](100),
	@UserName [nvarchar](50),
	@UserID [int] = 0,
	@LangID [int] = 1
WITH ENCRYPTION, EXECUTE AS CALLER
AS
BEGIN TRANSACTION
BEGIN TRY    
SET NOCOUNT ON   
			--Declaration Section
			declare @Dt float,@XML xml
			SET @Dt=convert(float,getdate())--Setting Current Date
			IF @Location=0
				BEGIN
				SET @Location=NULL
				END
			IF (@AppointmentID=0) --select * from SVC_Appointment
			BEGIN	
				INSERT INTO SVC_Appointment(AppDate, FromTime, ToTime,  CustomerVehicleID, Location, Remarks, COMPANYGUID, GUID,CreatedBy,CreatedDate)
					VALUES( convert(float, @AppDate),@FromTime, @ToTime, @CVehicleID, @Location, @Comments , @CompanyGUID, @GUID, @UserName,convert(float,getdate()))
				SET @AppointmentID=(SELECT MAX(AppointmentID) FROM SVC_Appointment)
			END			
			ELSE IF (@AppointmentID >0)
			BEGIN
				UPDATE SVC_Appointment SET	
					AppDate=convert(float, @AppDate),
					FromTime=@FromTime,
					ToTime=@ToTime,
					CustomerVehicleID=@CVehicleID,
					Location=@Location,
					Remarks=@Comments,
					ModifiedBy = @UserName,
					ModifiedDate = @Dt 
				 WHERE AppointmentID=@AppointmentID  

			END
			/****** SERVICE DETAILS INSERT ******/
			if(@AppServiceXML<>'')
			begin
						set @XML=@AppServiceXML
						delete from dbo.SVC_AppointmentServiceDetails where AppointmentID=@AppointmentID
						insert into SVC_AppointmentServiceDetails(AppointmentID,SerialNumber,ServiceTypeID,LocationID,ReasonID,COMPANYGUID,GUID,CreatedBy,CreatedDate)
						SELECT @AppointmentID,A.value('@Sno','INT'),A.value('@Type','INT'),A.value('@Loc','INT'),A.value('@Reason','INT'),@COMPANYGUID,NEWID(),@USERNAME,convert(float,getdate())
						FROM @XML.nodes('/Service/row') AS DATA(A) 
						--set @AppointmentID=scope_identity()
			end
			
COMMIT TRANSACTION
SELECT ErrorMessage,ErrorNumber FROM COM_ErrorMessages WITH(nolock) 
WHERE ErrorNumber=100 AND LanguageID=@LangID
SET NOCOUNT OFF;  
RETURN @AppointmentID
END TRY
BEGIN CATCH  
		--Return exception info [Message,Number,ProcedureName,LineNumber]  
		IF ERROR_NUMBER()=50000
			BEGIN
				SELECT ErrorMessage,ErrorNumber FROM COM_ErrorMessages WITH(NOLOCK) WHERE ErrorNumber=ERROR_MESSAGE() AND LanguageID=@LangID
			END
		ELSE
			BEGIN
				SELECT ErrorMessage, ERROR_MESSAGE() AS ServerMessage,ERROR_NUMBER() as ErrorNumber, ERROR_PROCEDURE()as ProcedureName, ERROR_LINE() AS ErrorLine
				FROM COM_ErrorMessages WITH(NOLOCK) WHERE ErrorNumber=-999 AND LanguageID=@LangID
			END
ROLLBACK TRANSACTION
SET NOCOUNT OFF  
RETURN -999   
END CATCH      

GO

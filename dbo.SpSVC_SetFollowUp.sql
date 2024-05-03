USE PACT2C222
GO
SET ANSI_NULLS, QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[SpSVC_SetFollowUp]
	@TicketSequenceID [int] = 0,
	@FollowUpTypeID [bigint],
	@ServiceTicketID [varchar](50),
	@CommunicationType [bigint],
	@StatusID [bigint],
	@Response [bigint],
	@Remarks [nvarchar](max),
	@CallTime [datetime],
	@Time [nvarchar](50),
	@EndTime [nvarchar](50),
	@CreateEvent [bit],
	@CustomerID [bigint],
	@TypeID [bigint],
	@CompanyGUID [nvarchar](50),
	@UserName [nvarchar](50),
	@UserID [bigint],
	@LangID [int] = 1,
	@LocationID [int] = 1
WITH ENCRYPTION, EXECUTE AS CALLER
AS
BEGIN TRANSACTION  
BEGIN TRY  
SET NOCOUNT ON;
		--Declaration Section 
		declare @T nvarchar(50),@ET nvarchar(50),@CreatedDate float ,@ActID bigint,@ActivityXml nvarchar(max),@CommunicationTypeName nvarchar(50),@CustomerName nvarchar(50),@LID bigint,@Location nvarchar(100),@CVehicleID bigint
		
		set @T=substring(@Time,0,6)
		set @ET=substring(@EndTime,0,6)
		set @CustomerName= (select CustomerName from svc_customers  where CustomerID=(select CustomerID from svc_customersvehicle where CV_ID=(select CustomerVehicleID from SVC_ServiceTicket where ServiceTicketID=@ServiceTicketID)))
		set @Location=(select Name from Com_Location where Nodeid=(select LocationID from SVC_ServiceTicket where ServiceTicketID=@ServiceTicketID))
		set @CommunicationTypeName=(select Name from com_lookup where NodeID=@CommunicationType)
		set @CreatedDate=convert(float,getdate())
		
if(@TypeID=0)
BEGIN	
		if(@TicketSequenceID =0)
		begin
			set @ActID=0;
		end
		else
		begin
			set @actID=(select ActivityID from CRM_ACTIVITIES where CostCenterID=122 and NodeID=@TicketSequenceID)
		end
		
	
		set @CVehicleID=(select CustomerVehicleID from SVC_ServiceTicket where ServiceTicketID=@ServiceTicketID)	
		set @LID=(select LocationID from SVC_ServiceTicket where ServiceTicketID=@ServiceTicketID)
		
		
		if(@TicketSequenceID=0)
		begin

			---Inserting into SVC_ServiceTicketFollowUp--
				insert into SVC_ServiceTicketFollowUp (ServiceTicketID,FollowUpTypeID,CommunicationType,StatusID,Response,Remarks,CallTime,CompanyGUID,GUID,CreatedBy,CreatedDate,CustomerID,TypeID,Time,IsCreateEvent)
							values(@ServiceTicketID,@FollowUpTypeID,@CommunicationType,@StatusID,@Response,@Remarks,Convert(float,@CallTime),@CompanyGUID,newid(),@UserName,@CreatedDate,0,@TypeID,@Time,@CreateEvent)
							set @TicketSequenceID=scope_identity()
							
							if(@CreateEvent='True')
							BEGIN
								--EXEC spCOM_SetNotifEvent -1005,59,@ServiceTicketID,@CompanyGUID,@UserName,1,-1,122,@TicketSequenceID
								
								EXEC spSVC_SetAppointment 0,@CallTime,@T,@ET,@CVehicleID,@LID,@Remarks,null,@CompanyGUID,'GUID',@UserName,@UserID,@LangID
							END
		End	
			---Updating Status in SVC_ServiceTicket--
		else
		begin
			update SVC_ServiceTicketFollowUp set CommunicationType=@CommunicationType,StatusID=@StatusID,Remarks=@Remarks,CallTime=Convert(float,@CallTime),Time=@Time,IsCreateEvent=@CreateEvent where ServiceTicketID=@ServiceTicketID and ServiceTicketFollowUpID=@TicketSequenceID
			
			--if(@CreateEvent=1)
			--BEGIN
				--EXEC spCOM_SetNotifEvent -1006,59,@ServiceTicketID,@CompanyGUID,@UserName,1,-1,122,@TicketSequenceID
			--END
		End
		--	Update SVC_ServiceTicket set StatusID=@StatusID where ServiceTicketNumber=@ServiceTicketID;
		
		
		set @ActivityXml= '<ScheduleActivityXml> 
			<Row  rowno="1"  ActivityID="'+convert(nvarchar,@actID)+'" ScheduleID="" Status="" FreqType="" FreqInterval="" FreqSubdayType="" FreqSubdayInterval="" FreqRelativeInterval="" FreqRecurrenceFactor=""
			CStartDate="" CEndDate="" StartTime="" isRecu="0" ActivityTypeID="1" CostCenterID="122" NodeID="'+convert(nvarchar,@TicketSequenceID)+'" StatusID="412" 
			Subject="'+@CommunicationTypeName+'" Priority="2" PctComplete="0" Location="'+@Location+'" IsAllDayActivity="0" ActualCloseDate="" ActualCloseTime=""
			CustomerID="'+@CustomerName+'" Remarks="'+@Remarks+'" AssignGroupID="1" AssignRoleID="1" AssignUserID="1"
			ActStartDate="'+convert(nvarchar,@CallTime)+'" ActEndDate="'+convert(nvarchar,@CallTime)+'" ActStartTime="'+@Time+'" ActEndTime="'+@Time+'"
			UsersXML="" RolesXML="" GroupXML="" TeamNodeID="" UserID="" isTeam="" 
			ExtraUserDefinedFields =""  isEdited="0"/>
			</ScheduleActivityXml>'
			
		 exec spCom_SetActivitiesAndSchedules @ActivityXml,122,@TicketSequenceID,@CompanyGUID,'GUID',@UserName,@CreatedDate,@LangID 
		 
END
Else
BEGIN

		set @CVehicleID=(select top(1) CV_ID from SVC_CustomersVehicle where CustomerID=@CustomerID)
		set @LID=(select Location from svc_customers where CustomerID=@CustomerID)

		if(@LID is null or @LID = '')
		BEGIN
			declare @Value nvarchar(50)
			set @Value=(select value from adm_globalpreferences where Name='EnableLocationWise')
			
			if(@Value='True')
			BEGIN
				set @LID=@LocationID
			END
			else
			Begin
				set @LID=1
			END
			
		END

		if(@TicketSequenceID=0)
		begin
				insert into SVC_ServiceTicketFollowUp (ServiceTicketID,FollowUpTypeID,CommunicationType,StatusID,Response,Remarks,CallTime,CompanyGUID,GUID,CreatedBy,CreatedDate,CustomerID,TypeID,Time,IsCreateEvent)
							values(0,0,@CommunicationType,@StatusID,@Response,@Remarks,Convert(float,@CallTime),@CompanyGUID,newid(),@UserName,@CreatedDate,@CustomerID,@TypeID,@Time,@CreateEvent)
							set @TicketSequenceID=scope_identity()
							--EXEC spCOM_SetNotifEvent -1005,59,@ServiceTicketID,@CompanyGUID,@UserName,1,-1,122,@TicketSequenceID

				if(@CreateEvent='True')
				BEGIN
					EXEC spSVC_SetAppointment 0,@CallTime,@T,@ET,@CVehicleID,@LID,@Remarks,null,@CompanyGUID,'GUID',@UserName,@UserID,@LangID
				END
		End
		else
		begin
			update SVC_ServiceTicketFollowUp set CommunicationType=@CommunicationType,StatusID=@StatusID,Remarks=@Remarks,CallTime=Convert(float,@CallTime),Time=@Time,IsCreateEvent=@CreateEvent where CustomerID=@CustomerID and ServiceTicketFollowUpID=@TicketSequenceID
			--EXEC spCOM_SetNotifEvent -1006,59,@ServiceTicketID,@CompanyGUID,@UserName,1,-1,122,@TicketSequenceID
		End
END    
		  
   
COMMIT TRANSACTION    
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

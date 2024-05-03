USE PACT2C222
GO
SET ANSI_NULLS, QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spSVC_DeleteTicket]
	@TicketID [bigint],
	@UserName [nvarchar](50),
	@USERID [int],
	@LANGID [int],
	@RoleID [int]
WITH ENCRYPTION, EXECUTE AS CALLER
AS
BEGIN TRANSACTION  
BEGIN TRY  
SET NOCOUNT ON;
		--Declaration Section  	
		DECLARE @HasAccess BIT,@RowsDeleted INT
		DECLARE @IsEdit BIT

		--User access check 
		SET @HasAccess=dbo.fnCOM_HasAccess(@RoleID,59,4)
		IF @HasAccess=0
		BEGIN
			RAISERROR('-105',16,1)
		END
		
		declare @i int, @cnt int, @costcenterid int, @acnt int, @accdocid bigint , @invdocid bigint
		create table #tempdocdetails(id int identity(1,1), invdocid bigint, accdocid bigint,costcenterid bigint)
		insert into #tempdocdetails (invdocid, costcenterid, accdocid)
		select docid, costcenterid, 0 from inv_docdetails where RefCCID=59 and 
		RefNodeid in (select ccticketid from svc_serviceticket where serviceticketid=@TicketID)
	  	 
		insert into #tempdocdetails (invdocid, costcenterid, accdocid)
		select 0, costcenterid,docid from acc_docdetails where RefCCID=59 and 
		RefNodeid in (select ccticketid from svc_serviceticket where serviceticketid=@TicketID)
	  	set @i=1
	  	select @cnt=count(*) from  #tempdocdetails
	  	select * from #tempdocdetails
		while @i<=@cnt
		begin
			select @accdocid =accdocid, @invdocid =invdocid, @costcenterid=Costcenterid from #tempdocdetails where id=@i 
			if @accdocid>0
			BEGIN
			DECLARE @return_value INT
					EXEC @return_value = [dbo].[spDOC_DeleteAccDocument]  
					 @CostCenterID = @costcenterid,  @DocPrefix = '',  @DocNumber = '',  
					 @DocID=@accdocid, @UserID = @UserID, @UserName = @UserName,  
					 @LangID = @LangID,
					 @RoleID=@RoleID
			END
			else
			BEGIN
				EXEC	@return_value =  spDOC_DeleteInvDocument
					@CostCenterID = @costcenterid,
					@DocPrefix = '',
					@DocNumber = '',  
					@DocID =  @invdocid,
					@UserID = @userid,
					@UserName = @username,
					@LangID = @LangId,
					@RoleID=@RoleID
			END
			if(@return_value>0)
			delete from COM_DocBridge where NodeID=@TicketID and costcenterid=59 and invdocid=@invdocid and accdocid=@accdocid
		--	select @accdocid, @invDocid, @costcenterid 
			set @i=@i+1
		end  
		
		 

		/****** SERVICE TICKET ******/
		DELETE FROM SVC_ServiceTicket
		WHERE ServiceTicketID=@TicketID
		SET @RowsDeleted=@@rowcount

		/****** SERVICE DETAILS ******/
		DELETE FROM SVC_ServiceDetails
		WHERE ServiceTicketID=@TicketID
		
		/****** OPTIONS ******/
		DELETE FROM SVC_ServiceDetailsOptions
		WHERE ServiceTicketID=@TicketID

		/****** SERVICE PARTS INFO ******/
		DELETE FROM SVC_ServicePartsInfo
		WHERE ServiceTicketID=@TicketID
		
		/****** SERVICE JOBS INFO ******/
		DELETE FROM SVC_ServiceJobsInfo
		WHERE ServiceTicketID=@TicketID
		
		/****** SERVICE TICKET BILL ******/
		DELETE FROM SVC_ServiceTicketBill
		WHERE ServiceTicketID=@TicketID

		/****** SERVICE TICKET PAYMENTS ******/
		DELETE FROM SVC_ServiceTicketBillPayment
		WHERE ServiceTicketID=@TicketID

		/****** SERVICE TICKET TAXES ******/
		DELETE FROM SVC_ServiceTicketTaxes
		WHERE ServiceTicketID=@TicketID
		
		/****** SERVICE TICKET VEHICLE CHECKOUT ******/
		DELETE FROM SVC_VehicleCheckout 
		WHERE ServiceTicketID=@TicketID
		
		/****** SERVICE TICKET CLAIMS ******/
		DELETE FROM SVC_ServiceTicketClaims 
		WHERE ServiceTicketID=@TicketID 
		 	
		 /****** SERVICE TICKET CLAIMS ******/
		DELETE FROM SVC_ServiceTicketDatesComm 
		WHERE ServiceTicketID=@TicketID

		DELETE FROM SVC_ServiceTicketHistory 
		WHERE ServiceTicketID=@TicketID
 		 
		DELETE FROM SVC_ServiceDetailsHistory 
		WHERE ServiceTicketID=@TicketID
			
		DELETE FROM SVC_ServicePartsInfoHistory 
		WHERE ServiceTicketID=@TicketID
	
		DELETE FROM SVC_ServiceJobsInfoHistory 
		WHERE ServiceTicketID=@TicketID  
		
		 
	 
COMMIT TRANSACTION
SET NOCOUNT OFF; 
SELECT ErrorMessage,ErrorNumber FROM COM_ErrorMessages WITH(nolock) 
WHERE ErrorNumber=102 AND LanguageID=@LangID

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
	ROLLBACK TRANSACTION
	SET NOCOUNT OFF  
	RETURN -999   
END CATCH  

 
GO

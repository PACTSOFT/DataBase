USE PACT2C222
GO
SET ANSI_NULLS, QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spSVC_DeleteTicketInvDocuments]
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

		declare @i int, @cnt int, @costcenterid int, @acnt int, @accdocid bigint , @invdocid bigint
		
		create table #tempdocdetails(id int identity(1,1), invdocid bigint, accdocid bigint,costcenterid bigint)
		
		insert into #tempdocdetails (invdocid, costcenterid, accdocid)
		select docid, costcenterid, 0 from inv_docdetails where RefCCID=59 and 
		RefNodeid in (select ccticketid from svc_serviceticket where serviceticketid=@TicketID)
	  	and costcenterid in (select value from com_costcenterpreferences where costcenterid=59 and name ='ServiceInvoiceDocument')
		
		
		insert into #tempdocdetails (invdocid, costcenterid, accdocid)
		select 0, costcenterid,docid 
		from acc_docdetails a
		left join svc_serviceticket st on a.refccid=59 and a.refnodeid=st.ccticketid
		left join SVC_ServiceTicketBillPayment b on st.serviceticketid=b.serviceticketid and a.docid=b.docdetailsid
		where RefCCID=59 and 
		RefNodeid in (select ccticketid from svc_serviceticket where serviceticketid=@TicketID) and b.isadvance=0
		  
	  	set @i=1
	  	select @cnt=count(*) from  #tempdocdetails
	  	select * from #tempdocdetails
		while @i<=@cnt
		begin
			select @accdocid =accdocid, @invdocid =invdocid, @costcenterid=Costcenterid from #tempdocdetails where id=@i 
			DECLARE @return_value INT	
			if @accdocid>0
			BEGIN
					EXEC @return_value = [dbo].[spDOC_DeleteAccDocument]  
					 @CostCenterID = @costcenterid,  @DocPrefix = '',  @DocNumber = '',  
					 @DocID=@accdocid, @UserID = @UserID, @UserName = @UserName,  
					 @LangID = @LangID,
					 @RoleID=@RoleID
			END
			else
			BEGIN
				select @costcenterid, @invdocid
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

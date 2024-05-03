USE PACT2C222
GO
SET ANSI_NULLS, QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spSVC_SaveTicketTempProduct]
	@TicketId [bigint],
	@PartID [bigint],
	@ProductID [bigint],
	@SerialNumber [int],
	@Rate [float],
	@CCTicketID [bigint],
	@USERID [int],
	@LANGID [int]
WITH ENCRYPTION, EXECUTE AS CALLER
AS
BEGIN TRANSACTION  
BEGIN TRY  
SET NOCOUNT ON;
	 
		declare @pid bigint
		select @pid=Value from com_costcenterpreferences with(nolock) where costcenterid=3 and Name like 'TempPartProduct'  
		if(@Rate=0)
			select @Rate=sellingrate from inv_product with(nolock) where productid=@ProductID
		
		update svc_servicepartsinfo set productid=@ProductID,   UpdatedPrice=@Rate 
		where productid=@pid and serviceticketid=@TicketId and serialnumber=@SerialNumber  and partid=@PartID
		
		update svc_servicepartsinfo set parent=@ProductID where 
		serviceticketid=@TicketId and partid=@PartID and Link in (1,2) and parent=@pid	
		
		UPDATE INV_DOCDETAILS
		SET PRODUCTID=@ProductID
		WHERE INVDOCDETAILSID IN (
		SELECT i.INVDOCDETAILSID 
		FROM INV_DOCDETAILS	I WITH(NOLOCK) 
		JOIN COM_DOCCCDATA CC WITH(NOLOCK) ON I.INVDOCDETAILSID=CC.INVDOCDETAILSID
		WHERE CC.dcCCNID29=@PartID and I.REFNODEID=@CCTicketID and i.refccid=59 AND I.PRODUCTID=@pid)
				 
				
COMMIT TRANSACTION    
SET NOCOUNT OFF;  
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

USE PACT2C222
GO
SET ANSI_NULLS, QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spSVC_SetTicketDocRef]
	@TicketID [bigint],
	@DocID [bigint],
	@IsInv [bit],
	@USERNAME [nvarchar](50),
	@USERID [int],
	@LANGID [int]
WITH ENCRYPTION, EXECUTE AS CALLER
AS
BEGIN TRANSACTION  
BEGIN TRY  
SET NOCOUNT ON;
		--Declaration Section  	
		
		DECLARE @HasAccess bit
		 DECLARE @Dt float

		 set @Dt=convert(float,getdate())
		
		if @IsInv=1 and   not exists(select NodeID from dbo.COM_DocBridge WHERE NodeID=@TicketID and CostCenterID=59 and InvDocID=@DocID)    
		begin 
		
			INSERT INTO dbo.COM_DocBridge (CostCenterID, NodeID,InvDocID, AccDocID, CompanyGUID, guid, Createdby, CreatedDate,Abbreviation)
			values(59, @TicketID,@DocID,0,'',newid(),@UserName, @dt,'Service')
		end
		else if @IsInv=0 and not exists(select NodeID from dbo.COM_DocBridge WHERE NodeID=@TicketID and CostCenterID=59 and AccDocID=@DocID)   
		begin 
			INSERT INTO dbo.COM_DocBridge (CostCenterID, NodeID,InvDocID, AccDocID, CompanyGUID, guid, Createdby, CreatedDate,Abbreviation)
			values(59, @TicketID,0,@DocID,'',newid(),@UserName, @dt,'Service')
		end
 

COMMIT TRANSACTION
--ROLLBACK TRANSACTION
SET NOCOUNT OFF; 
SELECT ErrorMessage,ErrorNumber FROM COM_ErrorMessages WITH(nolock) 
WHERE ErrorNumber=100 AND LanguageID=@LangID  

SELECT * FROM COM_DocBridge WHERE Nodeid=@TicketID and CostCenterid=59

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

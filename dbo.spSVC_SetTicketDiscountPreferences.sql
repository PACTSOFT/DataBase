USE PACT2C222
GO
SET ANSI_NULLS, QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spSVC_SetTicketDiscountPreferences]
	@DiscountXML [nvarchar](max),
	@MarginXML [nvarchar](max),
	@UserName [nvarchar](50),
	@USERID [int],
	@LANGID [int]
WITH ENCRYPTION, EXECUTE AS CALLER
AS
BEGIN TRANSACTION  
BEGIN TRY  
SET NOCOUNT ON;
		--Declaration Section  	 
		DECLARE @XML xml  , @Createddt float, @MXML xml
		set @Createddt=CONVERT(float,getdate())
		
		SET @XML=@DiscountXML
		set @MXML=@MarginXML
		select @DiscountXML
		delete from  [SVC_TicketDiscPreferences]
		
		INSERT INTO  [SVC_TicketDiscPreferences]
           ([RoleID],[Percentage],[LocationID],[CostCenterID],[Createdby],[CreatedDate]) 
		SELECT  X.value('@RoleID','INT'),
		X.value('@Percentage','INT'), X.value('@LocationID','BIGINT'), 59, @UserName, @Createddt 
		from @XML.nodes('/XML/Row') as Data(X)
		
		
		update SVC_PriceMargin set Minimum=X.value('@Minimum ','float'), 
		Maximum =X.value('@Maximum ','float')
		from @MXML.nodes('/XML/Row') as Data(X) where Margin=X.value('@Margin','nvarchar(50)')
 

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

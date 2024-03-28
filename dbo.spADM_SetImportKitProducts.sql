USE PACT2C222
GO
SET ANSI_NULLS, QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spADM_SetImportKitProducts]
	@KitXML [nvarchar](max),
	@AccountName [nvarchar](max) = null,
	@AccountCode [nvarchar](max) = null,
	@IsCode [bit] = NULL,
	@CompanyGUID [nvarchar](50),
	@UserName [nvarchar](50),
	@UserID [bigint],
	@RoleID [int] = 1,
	@LangID [int] = 1
WITH ENCRYPTION, EXECUTE AS CALLER
AS
BEGIN TRANSACTION  
BEGIN TRY  
SET NOCOUNT ON;
		--Declaration Section  
		DECLARE @Dt FLOAT ,@XML XML,@TSQL NVARCHAR(MAX),@SQL NVARCHAR(MAX),@TABLEname NVARCHAR(300),@return_value INT
		DECLARE @NodeID bigint,@BINID INT,@LOCATIONID INT,@BIN NVARCHAR(300),@DIVISIONID INT,@I INT,@COUNT INT,@CCID BIGINT,@LOCATIONNAME NVARCHAR(300),@DIVISIONNAME NVARCHAR(300)
		DECLARE @TABLE TABLE(ID INT IDENTITY(1,1),BIN NVARCHAR(300),LOCATION NVARCHAR(300), DIVISION NVARCHAR(300))
		SET @Dt=CONVERT(FLOAT,GETDATE())
		----DELETE FROM [INV_ProductBins]
		----WHERE CostcenterID=3 and NodeID=@NodeID
		
		if(@IsCode=1)
			select @NodeID=ProductID from INV_Product with(nolock) where ProductCode=@AccountCode
		else
 			select @NodeID=ProductID from INV_Product with(nolock) where ProductName=@AccountName
 		--	SELECT @NodeID
		if(@NodeID is null)
		begin
				declare @TEMPxml NVARCHAR(500)
				SET @TEMPxml='<XML><Row AccountName ="'+replace(@AccountName,'&','&amp;')+'" 
						AccountCode ="'+replace(@AccountCode,'&','&amp;')+'" TypeID ="3" ></Row></XML>'       
				EXEC @NodeID = [dbo].[spADM_SetImportData]      
				@XML = @TEMPxml,      
				@COSTCENTERID = 3,      
				@IsDuplicateNameAllowed = 0,      
				@IsCodeAutoGen = 0,      
				@IsOnlyName = 0,      
				@CompanyGUID = @CompanyGUID,      
				@UserName = @UserName ,      
				@UserID = @UserID, 
				@RoleID=@RoleID,     
				@LangID = @LangID   
			if(@IsCode=1)
				select @NodeID=ProductID from INV_Product with(nolock) where ProductCode=@AccountCode
			else
 				select @NodeID=ProductID from INV_Product with(nolock) where ProductName=@AccountName
 	
		end	
		 	
		if(@NodeID>0)  
			EXEC [spINV_SetProductBundle] @KitXML,@NodeID,@CompanyGUID,@UserName,@UserID,@LangID 


	  
COMMIT TRANSACTION  
--ROLLBACK TRANSACTION
SELECT ErrorMessage,ErrorNumber FROM COM_ErrorMessages WITH(nolock) 
WHERE ErrorNumber=100 AND LanguageID=@LangID     
SET NOCOUNT OFF;  
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
		SELECT ErrorMessage, ERROR_MESSAGE() AS ServerMessage,ERROR_NUMBER() as ErrorNumber, ERROR_PROCEDURE()as ProcedureName, ERROR_LINE() AS ErrorLine
		FROM COM_ErrorMessages WITH(NOLOCK) WHERE ErrorNumber=-999 AND LanguageID=@LangID
	END
ROLLBACK TRANSACTION
SET NOCOUNT OFF  
RETURN -999   
END CATCH


GO

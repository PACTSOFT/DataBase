USE PACT2C222
GO
SET ANSI_NULLS, QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spINV_SetProductSubstitutes]
	@SUBSTITUTEGROUPID [int] = 0,
	@SUBSTITUTEGROUPNAME [nvarchar](300) = NULL,
	@DATA [nvarchar](max) = NULL,
	@CompanyGUID [nvarchar](50),
	@UserName [nvarchar](50),
	@UserID [bigint],
	@LangID [int] = 1
WITH ENCRYPTION, EXECUTE AS CALLER
AS
BEGIN TRANSACTION  
BEGIN TRY  
SET NOCOUNT ON; 

		--Declaration Section  
		DECLARE @Dt FLOAT ,@HasAccess BIT ,@XML xml
		SET @Dt=CONVERT(float,GETDATE())--Setting Current Date  
  
		SET @XML=@DATA 
  
		IF @SUBSTITUTEGROUPID=0 --FOR NEW SUBSTITUTE
		BEGIN 
			SELECT @SUBSTITUTEGROUPID=ISNULL(MAX(SubstituteGroupID),0)+1 FROM [INV_ProductSubstitutes] 
			IF EXISTS (SELECT SubstituteGroupName FROM [INV_ProductSubstitutes] WITH(NOLOCK) 
			WHERE SubstituteGroupName=@SUBSTITUTEGROUPNAME)
			BEGIN
				RAISERROR('-116',16,1)
			END
		END
		ELSE
		BEGIN
			--DELETE SUBTITUTE PRODUCTS
			DELETE FROM [INV_ProductSubstitutes]
			WHERE SubstituteGroupID=@SUBSTITUTEGROUPID AND ProductID IN
			(SELECT X.value('@ProductID','BIGINT')
			from @XML.nodes('/Data/Row') as Data(X)
			WHERE X.value('@MapAction','nvarchar(10)') ='Delink')
		END 
		
		--INSERT SUBTITUTE PRODUCTS
		INSERT INTO [INV_ProductSubstitutes]  
		(SubstituteGroupID,
		 SubstituteGroupName   
		,[ProductID]  
		,[SProductID]
		,[GUID]   
		,[CreatedBy]  
		,[CreatedDate],CompanyGUID)  			  
		SELECT @SUBSTITUTEGROUPID,@SUBSTITUTEGROUPNAME,X.value('@ProductID','BIGINT'),0,NEWID()
		,@UserName,@Dt,@CompanyGUID
		from @XML.nodes('/Data/Row') as Data(X)
		WHERE X.value('@MapAction','nvarchar(10)') ='Link'


COMMIT TRANSACTION  
SELECT * FROM [INV_ProductSubstitutes] WITH(NOLOCK) WHERE SubstituteGroupID=@SUBSTITUTEGROUPID
SELECT ErrorMessage,ErrorNumber FROM COM_ErrorMessages WITH(nolock) 
WHERE ErrorNumber=100 AND LanguageID=@LangID   
SET NOCOUNT OFF;  
RETURN @SUBSTITUTEGROUPID  
END TRY  
BEGIN CATCH  
	--Return exception info [Message,Number,ProcedureName,LineNumber]  
	IF ERROR_NUMBER()=50000
	BEGIN
		SELECT * FROM [INV_ProductSubstitutes] WITH(NOLOCK) WHERE SubstituteGroupID=@SUBSTITUTEGROUPID    
		SELECT ErrorMessage,ErrorNumber FROM COM_ErrorMessages WITH(nolock) WHERE ErrorNumber=ERROR_MESSAGE() AND LanguageID=@LangID
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
  
 -- spINV_SetProductSubstitutes 
 --'-100'
 --,'GROUP1'
 --,'<Data><Row ProductID=''2408'' MapAction=''Link'' /><Row ProductID=''2407'' MapAction=''Link'' /><Row ProductID=''2406'' MapAction=''Link'' /></Data>'
 --,'830b4366-ab3c-4150-aefe-f5acaddc7089'
 --,'admin'
 --,1
 --,1   
  





GO

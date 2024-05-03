USE PACT2C222
GO
SET ANSI_NULLS, QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[SpSVC_SetFamily]
	@FamilyId [bigint] = 0,
	@CustomerID [bigint] = 0,
	@ReleationID [bigint] = 0,
	@Name [nvarchar](300) = null,
	@Phone [nvarchar](300) = null,
	@LangID [int] = 0
WITH ENCRYPTION, EXECUTE AS CALLER
AS
BEGIN TRANSACTION  
BEGIN TRY  
SET NOCOUNT ON;
		--Declaration Section 
		declare @CreatedDate float
		
		IF @FamilyId=0
		BEGIN
		INSERT INTO  [SVC_CustomerFamilyDetails]
           ([CustomerID]
           ,[Relation]
           ,[Phone]
           ,[Name])
		 VALUES
           (@CustomerID
           ,@ReleationID
           ,@Phone
           ,@Name)
            SET @FamilyId=SCOPE_IDENTITY()
          END         
		ELSE
		BEGIN
			 UPDATE [SVC_CustomerFamilyDetails] SET CustomerID=@CustomerID,Relation=@ReleationID,Name=@Name,Phone=@Phone
			 WHERE CustomerFamilyID=@FamilyId
		END
   
COMMIT TRANSACTION    
SET NOCOUNT OFF; 
SELECT ErrorMessage,ErrorNumber FROM COM_ErrorMessages WITH(nolock) 
WHERE ErrorNumber=100 AND LanguageID=@LangID  
RETURN @FamilyId
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

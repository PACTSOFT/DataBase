USE PACT2C222
GO
SET ANSI_NULLS, QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spINV_DeleteAttribute]
	@NodeID [bigint],
	@UserID [bigint],
	@LangID [int] = 1
WITH ENCRYPTION, EXECUTE AS CALLER
AS
BEGIN TRANSACTION
BEGIN TRY  
SET NOCOUNT ON;  
		--Declaration Section  
		DECLARE @lft BIGINT,@rgt BIGINT,@Width int,@RowsDeleted BIGINT  	  
		DECLARE @HasAccess bit

		--SP Required Parameters Check
		IF(@NodeID<1)
		BEGIN
			RAISERROR('-100',16,1)
		END

		IF((SELECT PARENTID FROM COM_Attributes WITH(NOLOCK) WHERE NodeID=@NodeID)=0)
		BEGIN
			RAISERROR('-117',16,1)
		END
		--Fetch left, right extent of Node along with width.  
		SELECT @lft = lft, @rgt = rgt, @Width = rgt - lft + 1  
		FROM COM_Attributes WITH(NOLOCK) WHERE NodeID=@NodeID  
	 
		--Delete from main table  
		DELETE FROM COM_Attributes WHERE lft >= @lft AND rgt <= @rgt  
		SET @RowsDeleted=@@rowcount

		--Update left and right extent to set the tree  
		UPDATE COM_Attributes SET rgt = rgt - @Width WHERE rgt > @rgt;  
		UPDATE COM_Attributes SET lft = lft - @Width WHERE lft > @rgt;  
    
  
COMMIT TRANSACTION
SET NOCOUNT OFF;  

SELECT ErrorMessage,ErrorNumber FROM COM_ErrorMessages WITH(nolock) 
WHERE ErrorNumber=102 AND LanguageID=@LangID  
RETURN @RowsDeleted
END TRY
BEGIN CATCH  
	--Return exception info [Message,Number,ProcedureName,LineNumber]  
	IF ERROR_NUMBER()=50000
	BEGIN
		SELECT ErrorMessage,ErrorNumber FROM COM_ErrorMessages WITH(nolock) WHERE ErrorNumber=ERROR_MESSAGE() AND LanguageID=@LangID
	END
	ELSE IF ERROR_NUMBER()=547
	BEGIN
		SELECT ErrorMessage, ERROR_MESSAGE() AS ServerMessage,ERROR_NUMBER() as ErrorNumber, ERROR_PROCEDURE()as ProcedureName, ERROR_LINE() AS ErrorLine FROM COM_ErrorMessages WITH(nolock)
		WHERE ErrorNumber=-110 AND LanguageID=@LangID
	END
	ELSE
	BEGIN
		SELECT ErrorMessage, ERROR_MESSAGE() AS ServerMessage,ERROR_NUMBER() as ErrorNumber, ERROR_PROCEDURE()as ProcedureName, ERROR_LINE() AS ErrorLine
		FROM COM_ErrorMessages WITH(nolock) WHERE ErrorNumber=-999 AND LanguageID=@LangID
	END
ROLLBACK TRANSACTION
SET NOCOUNT OFF  
RETURN -999   
END CATCH

  
  
  
  
  
  

 











GO

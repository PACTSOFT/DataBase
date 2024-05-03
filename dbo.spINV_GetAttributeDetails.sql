USE PACT2C222
GO
SET ANSI_NULLS, QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spINV_GetAttributeDetails]
	@NodeID [bigint] = 0,
	@CostCenterColID [int] = null,
	@UserID [bigint],
	@LangID [int] = 1
WITH ENCRYPTION, EXECUTE AS CALLER
AS
BEGIN TRANSACTION
BEGIN TRY  
SET NOCOUNT ON;   

		--Declaration Section
		DECLARE @HasAccess bit,@ColumnName varchar(20),@SQL NVARCHAR(MAX)

			SELECT @ColumnName=SYSCOLUMNNAME FROM ADM_COSTCENTERDEF WHERE COSTCENTERColID=@CostCenterColID
			IF(@ColumnName IS NULL)
				SET @ColumnName='attAlpha1' 
			SET @SQL='SELECT NodeID,'+@ColumnName +' Value,StatusID,ParentID,isGroup
				  ,[GUID]
				  ,[Description]
				  ,[CreatedBy]
				  ,[CreatedDate]
				  ,[ModifiedBy]
				  ,[ModifiedDate]
			  FROM [COM_Attributes] WHERE NodeID='+CAST(@NodeID AS VARCHAR)
			 EXEC(@SQL)
 

				SELECT * FROM ADM_COSTCENTERDEF WHERE COSTCENTERID=31 AND SYSCOLUMNNAME LIKE 'ATTALPHA%'
		
			
--			select @ColumnName	
			--Getting Product Groups.
				SET @SQL='SELECT NodeID,'+@ColumnName +'
				FROM COM_Attributes WITH(NOLOCK)
				WHERE IsGroup = 1 AND '+@ColumnName+' IS NOT NULL'
--				print @SQL
				 EXEC(@SQL)
  
  
COMMIT TRANSACTION
SET NOCOUNT OFF;  
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

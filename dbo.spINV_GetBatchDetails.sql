USE PACT2C222
GO
SET ANSI_NULLS, QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spINV_GetBatchDetails]
	@BatchID [bigint] = 0,
	@RoleID [int],
	@LangID [int] = 1
WITH ENCRYPTION, EXECUTE AS CALLER
AS
BEGIN TRANSACTION
BEGIN TRY  
SET NOCOUNT ON;   

		--Declaration Section
		DECLARE @HasAccess bit,@SQL NVARCHAR(MAX)

	    --Check for manadatory paramters  
		IF(@BatchID < 1)  
		BEGIN   
			RAISERROR('-100',16,1)   
		END  
		--User acces check
		SET @HasAccess=dbo.fnCOM_HasAccess(@RoleID,16,2)

		IF @HasAccess=0
		BEGIN
			RAISERROR('-105',16,1)
		END 
		
		SET @SQL='SELECT [BatchID]'
		SELECT @SQL=@SQL+','+CASE WHEN a.name IN ('MfgDate','ExpiryDate','RetestDate') THEN 'CONVERT(DATETIME,['+a.name+'])' ELSE '' END+'['+a.name+']'
		FROM sys.columns a
		JOIN sys.tables b on a.object_id=b.object_id
		WHERE b.name='INV_Batches' AND a.name<>'BatchID'
		
		SET @SQL=@SQL+' FROM [INV_Batches] WITH(NOLOCK) WHERE BatchID='+CONVERT(NVARCHAR(MAX),@BatchID)
		EXEC (@SQL)	
			
		--Getting data from Products extended table  
	    SELECT * FROM  INV_ProductExtended WITH(NOLOCK)   
	    WHERE ProductID=@BatchID 

		--Getting Contacts
		EXEC [spCom_GetFeatureWiseContacts] 16,@BatchID,2,1,1 

		--Getting Notes
		SELECT  NoteID, Note, FeatureID, FeaturePK, CompanyGUID, GUID, CreatedBy, convert(datetime,CreatedDate) as CreatedDate, 
		ModifiedBy, ModifiedDate, CostCenterID
		FROM COM_Notes WITH(NOLOCK) 
		WHERE FeatureID=16 and  FeaturePK=@BatchID

		--Getting Files
		SELECT * FROM  COM_Files WITH(NOLOCK) 
		WHERE FeatureID=16 and  FeaturePK=@BatchID

		 SELECT  *   FROM COM_CCCCData   WITH(NOLOCK) 
		WHERE  CostCenterID=16 AND  NODEID=@BatchID 
  
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

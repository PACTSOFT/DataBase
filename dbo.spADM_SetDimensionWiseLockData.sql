USE PACT2C222
GO
SET ANSI_NULLS, QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spADM_SetDimensionWiseLockData]
	@MODE [int],
	@DimensionWiseLock [nvarchar](max),
	@RoleID [bigint] = 1,
	@UserName [nvarchar](50),
	@UserID [bigint] = 1
WITH ENCRYPTION, EXECUTE AS CALLER
AS
BEGIN TRANSACTION  
BEGIN TRY    
	SET NOCOUNT ON;    
	declare @XML xml,@NodeID bigint=0
	IF (@MODE=0)
	BEGIN
		set @xml=@DimensionWiseLock

		if(@DimensionWiseLock is not null and @DimensionWiseLock <> '')
		begin
			INSERT INTO [dbo].[ADM_DimensionWiseLockData]
			   ([FromDate]
			   ,[ToDate]
			   ,[AccountID]
			   ,[ProductID]
			   ,[CCNID1]
			   ,[CCNID2]
			   ,[CCNID3]
			   ,[CCNID4]
			   ,[CCNID5]
			   ,[CCNID6]
			   ,[CCNID7]
			   ,[CCNID8]
			   ,[CCNID9]
			   ,[CCNID10]
			   ,[CCNID11]
			   ,[CCNID12]
			   ,[CCNID13]
			   ,[CCNID14]
			   ,[CCNID15]
			   ,[CCNID16]
			   ,[CCNID17]
			   ,[CCNID18]
			   ,[CCNID19]
			   ,[CCNID20]
			   ,[CCNID21]
			   ,[CCNID22]
			   ,[CCNID23]
			   ,[CCNID24]
			   ,[CCNID25]
			   ,[CCNID26]
			   ,[CCNID27]
			   ,[CCNID28]
			   ,[CCNID29]
			   ,[CCNID30]
			   ,[CCNID31]
			   ,[CCNID32]
			   ,[CCNID33]
			   ,[CCNID34]
			   ,[CCNID35]
			   ,[CCNID36]
			   ,[CCNID37]
			   ,[CCNID38]
			   ,[CCNID39]
			   ,[CCNID40]
			   ,[CCNID41]
			   ,[CCNID42]
			   ,[CCNID43]
			   ,[CCNID44]
			   ,[CCNID45]
			   ,[CCNID46]
			   ,[CCNID47]
			   ,[CCNID48]
			   ,[CCNID49]
			   ,[CCNID50]
			   ,[CompanyGUID]
			   ,[GUID]
			   ,[Description]
			   ,[CreatedBy]
			   ,[CreatedDate]
			   ,[DocumentID]
			   ,[isEnable])
		 SELECT Convert(float,X.value('@FromDate','Datetime'))
			   ,Convert(float,X.value('@ToDate','Datetime'))
			   ,isnull(X.value('@AccountID','bigint'),0)
			   ,isnull(X.value('@ProductID','bigint'),0)
			   ,isnull(X.value('@CCNID1','bigint'),0)
			   ,isnull(X.value('@CCNID2','bigint'),0)
			   ,isnull(X.value('@CCNID3','bigint'),0)
			   ,isnull(X.value('@CCNID4','bigint'),0)
			   ,isnull(X.value('@CCNID5','bigint'),0)
			   ,isnull(X.value('@CCNID6','bigint'),0)
			   ,isnull(X.value('@CCNID7','bigint'),0)
			   ,isnull(X.value('@CCNID8','bigint'),0)
			   ,isnull(X.value('@CCNID9','bigint'),0)
			   ,isnull(X.value('@CCNID10','bigint'),0)
			   ,isnull(X.value('@CCNID11','bigint'),0)
			   ,isnull(X.value('@CCNID12','bigint'),0)
			   ,isnull(X.value('@CCNID13','bigint'),0)
			   ,isnull(X.value('@CCNID14','bigint'),0)
			   ,isnull(X.value('@CCNID15','bigint'),0)
			   ,isnull(X.value('@CCNID16','bigint'),0)
			   ,isnull(X.value('@CCNID17','bigint'),0)
			   ,isnull(X.value('@CCNID18','bigint'),0)
			   ,isnull(X.value('@CCNID19','bigint'),0)
			   ,isnull(X.value('@CCNID20','bigint'),0)
			   ,isnull(X.value('@CCNID21','bigint'),0)
			   ,isnull(X.value('@CCNID22','bigint'),0)
			   ,isnull(X.value('@CCNID23','bigint'),0)
			   ,isnull(X.value('@CCNID24','bigint'),0)
			   ,isnull(X.value('@CCNID25','bigint'),0)
			   ,isnull(X.value('@CCNID26','bigint'),0)
			   ,isnull(X.value('@CCNID27','bigint'),0)
			   ,isnull(X.value('@CCNID28','bigint'),0)
			   ,isnull(X.value('@CCNID29','bigint'),0)
			   ,isnull(X.value('@CCNID30','bigint'),0)
			   ,isnull(X.value('@CCNID31','bigint'),0)
			   ,isnull(X.value('@CCNID32','bigint'),0)
			   ,isnull(X.value('@CCNID33','bigint'),0)
			   ,isnull(X.value('@CCNID34','bigint'),0)
			   ,isnull(X.value('@CCNID35','bigint'),0)
			   ,isnull(X.value('@CCNID36','bigint'),0)
			   ,isnull(X.value('@CCNID37','bigint'),0)
			   ,isnull(X.value('@CCNID38','bigint'),0)
			   ,isnull(X.value('@CCNID39','bigint'),0)
			   ,isnull(X.value('@CCNID40','bigint'),0)
			   ,isnull(X.value('@CCNID41','bigint'),0)
			   ,isnull(X.value('@CCNID42','bigint'),0)
			   ,isnull(X.value('@CCNID43','bigint'),0)
			   ,isnull(X.value('@CCNID44','bigint'),0)
			   ,isnull(X.value('@CCNID45','bigint'),0)
			   ,isnull(X.value('@CCNID46','bigint'),0)
			   ,isnull(X.value('@CCNID47','bigint'),0)
			   ,isnull(X.value('@CCNID48','bigint'),0)
			   ,isnull(X.value('@CCNID49','bigint'),0)
			   ,isnull(X.value('@CCNID50','bigint'),0)
			   ,NEWID()
			   ,NEWID()
			   ,NULL
			   ,@UserName
			   ,convert(float,getdate())
			   ,isnull(X.value('@DocumentID','bigint'),1)
			   ,isnull(X.value('@isEnable','bit'),1)
			   from @xml.nodes('/DimensionWiseLockXML/Rows') as data(x)
			  
			set @NodeID=@@IDENTITY 
			
			SELECT ErrorMessage,ErrorNumber FROM COM_ErrorMessages WITH(nolock)   
			WHERE ErrorNumber=100 AND LanguageID=1 
		end
	END
	ELSE IF(@MODE=1)
	BEGIN
		DECLARE @SQL NVARCHAR(MAX)
		SET @SQL='SELECT *,convert(datetime,FromDate) FromDate_Key,convert(datetime,ToDate) ToDate_Key 
		FROM ADM_DimensionWiseLockData WITH(NOLOCK)'
		
		IF @UserID<>1
		BEGIN
			SET @SQL=@SQL+' WHERE (DocumentID=1 OR DocumentID IN (SELECT DISTINCT FA.FeatureID FROM ADM_FeatureAction FA WITH(NOLOCK)
						LEFT JOIN ADM_FeatureActionRoleMap FAM WITH(NOLOCK) ON FAM.FeatureActionID=FA.FeatureActionID
						WHERE FA.FeatureID BETWEEN 40001 AND 49999 AND FA.FeatureActionTypeID IN (1,2,3,4) AND FAM.RoleID='+CONVERT(NVARCHAR,@RoleID)+'))'
			
			DECLARE @ISDIMWISE BIT
			SELECT @ISDIMWISE=Value FROM ADM_GlobalPreferences WITH(NOLOCK) WHERE Name='EnableDivisionWise'
			IF @ISDIMWISE=1
				SET @SQL=@SQL+' AND (CCNID1=1 OR CCNID1 IN (SELECT DISTINCT NodeID FROM COM_CostCenterCostCenterMap WITH(NOLOCK)
						 WHERE ((ParentCostCenterID=6 AND ParentNodeID='+CONVERT(NVARCHAR,@RoleID)+') OR (ParentCostCenterID=7 AND ParentNodeID='+CONVERT(NVARCHAR,@UserID)+')) 
						 AND CostCenterID=50001))'
			
			SELECT @ISDIMWISE=Value FROM ADM_GlobalPreferences WITH(NOLOCK) WHERE Name='EnableLocationWise'
			IF @ISDIMWISE=1
				SET @SQL=@SQL+' AND (CCNID2=1 OR CCNID2 IN (SELECT DISTINCT NodeID FROM COM_CostCenterCostCenterMap WITH(NOLOCK)
						 WHERE ((ParentCostCenterID=6 AND ParentNodeID='+CONVERT(NVARCHAR,@RoleID)+') OR (ParentCostCenterID=7 AND ParentNodeID='+CONVERT(NVARCHAR,@UserID)+')) 
						 AND CostCenterID=50002))'
		END
		SET @SQL=@SQL+' ORDER BY NodeID'
		EXEC(@SQL)
		
		SELECT CostCenterID,DocumentName FROM dbo.ADM_DocumentTypes WITH(NOLOCK)
		WHERE CostCenterID IN (SELECT DISTINCT FA.FeatureID FROM ADM_FeatureAction FA WITH(NOLOCK)
					LEFT JOIN ADM_FeatureActionRoleMap FAM WITH(NOLOCK) ON FAM.FeatureActionID=FA.FeatureActionID
					WHERE FA.FeatureID BETWEEN 40001 AND 49999 AND FA.FeatureActionTypeID IN (1,2,3,4) AND FAM.RoleID=@RoleID)
					ORDER BY DocumentName
			
	END
	IF (@MODE=2)
	BEGIN
		set @xml=@DimensionWiseLock

		if(@DimensionWiseLock is not null and @DimensionWiseLock <> '')
		begin
			
			UPDATE [ADM_DimensionWiseLockData] SET
			   [FromDate]=Convert(float,X.value('@FromDate','Datetime'))
			   ,[ToDate]=Convert(float,X.value('@ToDate','Datetime'))
			   ,[AccountID]=isnull(X.value('@AccountID','bigint'),0)
			   ,[ProductID]=isnull(X.value('@ProductID','bigint'),0)
			   ,[CCNID1]=isnull(X.value('@CCNID1','bigint'),0)
			   ,[CCNID2]=isnull(X.value('@CCNID2','bigint'),0)
			   ,[CCNID3]=isnull(X.value('@CCNID3','bigint'),0)
			   ,[CCNID4]=isnull(X.value('@CCNID4','bigint'),0)
			   ,[CCNID5]=isnull(X.value('@CCNID5','bigint'),0)
			   ,[CCNID6]=isnull(X.value('@CCNID6','bigint'),0)
			   ,[CCNID7]=isnull(X.value('@CCNID7','bigint'),0)
			   ,[CCNID8]=isnull(X.value('@CCNID8','bigint'),0)
			   ,[CCNID9]=isnull(X.value('@CCNID9','bigint'),0)
			   ,[CCNID10]=isnull(X.value('@CCNID10','bigint'),0)
			   ,[CCNID11]=isnull(X.value('@CCNID11','bigint'),0)
			   ,[CCNID12]=isnull(X.value('@CCNID12','bigint'),0)
			   ,[CCNID13]=isnull(X.value('@CCNID13','bigint'),0)
			   ,[CCNID14]=isnull(X.value('@CCNID14','bigint'),0)
			   ,[CCNID15]=isnull(X.value('@CCNID15','bigint'),0)
			   ,[CCNID16]=isnull(X.value('@CCNID16','bigint'),0)
			   ,[CCNID17]=isnull(X.value('@CCNID17','bigint'),0)
			   ,[CCNID18]=isnull(X.value('@CCNID18','bigint'),0)
			   ,[CCNID19]=isnull(X.value('@CCNID19','bigint'),0)
			   ,[CCNID20]=isnull(X.value('@CCNID20','bigint'),0)
			   ,[CCNID21]=isnull(X.value('@CCNID21','bigint'),0)
			   ,[CCNID22]=isnull(X.value('@CCNID22','bigint'),0)
			   ,[CCNID23]=isnull(X.value('@CCNID23','bigint'),0)
			   ,[CCNID24]=isnull(X.value('@CCNID24','bigint'),0)
			   ,[CCNID25]=isnull(X.value('@CCNID25','bigint'),0)
			   ,[CCNID26]=isnull(X.value('@CCNID26','bigint'),0)
			   ,[CCNID27]=isnull(X.value('@CCNID27','bigint'),0)
			   ,[CCNID28]=isnull(X.value('@CCNID28','bigint'),0)
			   ,[CCNID29]=isnull(X.value('@CCNID29','bigint'),0)
			   ,[CCNID30]=isnull(X.value('@CCNID30','bigint'),0)
			   ,[CCNID31]=isnull(X.value('@CCNID31','bigint'),0)
			   ,[CCNID32]=isnull(X.value('@CCNID32','bigint'),0)
			   ,[CCNID33]=isnull(X.value('@CCNID33','bigint'),0)
			   ,[CCNID34]=isnull(X.value('@CCNID34','bigint'),0)
			   ,[CCNID35]=isnull(X.value('@CCNID35','bigint'),0)
			   ,[CCNID36]=isnull(X.value('@CCNID36','bigint'),0)
			   ,[CCNID37]=isnull(X.value('@CCNID37','bigint'),0)
			   ,[CCNID38]=isnull(X.value('@CCNID38','bigint'),0)
			   ,[CCNID39]=isnull(X.value('@CCNID39','bigint'),0)
			   ,[CCNID40]=isnull(X.value('@CCNID40','bigint'),0)
			   ,[CCNID41]=isnull(X.value('@CCNID41','bigint'),0)
			   ,[CCNID42]=isnull(X.value('@CCNID42','bigint'),0)
			   ,[CCNID43]=isnull(X.value('@CCNID43','bigint'),0)
			   ,[CCNID44]=isnull(X.value('@CCNID44','bigint'),0)
			   ,[CCNID45]=isnull(X.value('@CCNID45','bigint'),0)
			   ,[CCNID46]=isnull(X.value('@CCNID46','bigint'),0)
			   ,[CCNID47]=isnull(X.value('@CCNID47','bigint'),0)
			   ,[CCNID48]=isnull(X.value('@CCNID48','bigint'),0)
			   ,[CCNID49]=isnull(X.value('@CCNID49','bigint'),0)
			   ,[CCNID50]=isnull(X.value('@CCNID50','bigint'),0)
			   ,[CompanyGUID]=NEWID()
			   ,[GUID]=NEWID()
			   ,[Description]=NULL
			   ,[ModifiedBy]=@UserName
			   ,[ModifiedDate]=convert(float,getdate())
			   ,[DocumentID]=isnull(X.value('@DocumentID','bigint'),1)
			   ,[isEnable]=isnull(X.value('@isEnable','bit'),1)
			   from @xml.nodes('/DimensionWiseLockXML/Rows') as data(x)
			   WHERE NodeID=isnull(X.value('@NodeID','bigint'),0)
			SELECT @NodeID=isnull(X.value('@NodeID','bigint'),0)  from @xml.nodes('/DimensionWiseLockXML/Rows') as data(x) 
			SELECT ErrorMessage,ErrorNumber FROM COM_ErrorMessages WITH(nolock)   
			WHERE ErrorNumber=100 AND LanguageID=1 
		end
	END
	ELSE IF(@MODE=3)
	BEGIN
		set @NodeID=CONVERT(INT,@DimensionWiseLock)
		DELETE FROM ADM_DimensionWiseLockData WHERE NodeID=@NodeID
		
		SELECT ErrorMessage,ErrorNumber FROM COM_ErrorMessages WITH(nolock)   
		WHERE ErrorNumber=102 AND LanguageID=1 	
	END
	
	if(@MODE<>1)
		exec [spADM_SetPriceTaxUsedCC] 3,0,1
		
	COMMIT TRANSACTION  
	SET NOCOUNT OFF;    
	RETURN @NodeID 
END TRY  
BEGIN CATCH    
	--Return exception info [Message,Number,ProcedureName,LineNumber]    
	IF ERROR_NUMBER()=50000  
	BEGIN  
		SELECT ErrorMessage,ErrorNumber FROM COM_ErrorMessages WITH(nolock) WHERE ErrorNumber=ERROR_MESSAGE() AND LanguageID=1  
	END  
	ELSE IF ERROR_NUMBER()=547  
	BEGIN  
		SELECT ErrorMessage, ERROR_MESSAGE() AS ServerMessage,ERROR_NUMBER() as ErrorNumber, ERROR_PROCEDURE()as ProcedureName, ERROR_LINE() AS ErrorLine 
		FROM COM_ErrorMessages WITH(nolock)  
		WHERE ErrorNumber=-110 AND LanguageID=1  
	END  
	ELSE   
	BEGIN  
		SELECT ErrorMessage, ERROR_MESSAGE() AS ServerMessage,ERROR_NUMBER() as ErrorNumber, ERROR_PROCEDURE()as ProcedureName, ERROR_LINE() AS ErrorLine  
		FROM COM_ErrorMessages WITH(nolock) 
		WHERE ErrorNumber=-999 AND LanguageID=1  
	END  
ROLLBACK TRANSACTION  
SET NOCOUNT OFF    
RETURN -999     
END CATCH  
  
  
  
  
  
GO

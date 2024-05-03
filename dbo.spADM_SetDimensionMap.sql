USE PACT2C222
GO
SET ANSI_NULLS, QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spADM_SetDimensionMap]
	@ProfileID [bigint],
	@ProfileName [nvarchar](200),
	@DataXml [nvarchar](max),
	@DefXml [nvarchar](max),
	@DepXml [nvarchar](max) = '',
	@CompanyGUID [nvarchar](50),
	@UserName [nvarchar](200),
	@UserID [bigint],
	@LangID [int] = 1
WITH ENCRYPTION, EXECUTE AS CALLER
AS
BEGIN TRANSACTION    
BEGIN TRY    
SET NOCOUNT ON;  
	
	DECLARE @ErrorNumber INT
	IF(@ProfileID<>0 AND @ProfileName='Delete')
	BEGIN
		SET @ErrorNumber=102
		DECLARE @I INT,@CNT INT,@CostCenterID BIGINT,@PrefValue nvarchar(MAX)
		declare @table table(ID INT IDENTITY(1,1) PRIMARY KEY,CostCenterID BIGINT,PrefValue nvarchar(MAX))  
		insert into @table  
		SELECT CostCenterID,PrefValue FROM COM_DocumentPreferences WITH(NOLOCK) 
		WHERE PrefName='DefaultProfileID' AND PrefValue IS NOT NULL AND  PrefValue<>'' 
		
		SELECT @I=1,@CNT=COUNT(*) FROM @table
		WHILE @I<=@CNT
		BEGIN
			
			SELECT @CostCenterID=CostCenterID,@PrefValue=PrefValue FROM @table WHERE ID=@I
			DELETE FROM @table WHERE ID=@I
			
			insert into @table(PrefValue) 
			exec SPSplitString @PrefValue,',' 
			
			UPDATE @table SET CostCenterID=@CostCenterID WHERE CostCenterID IS NULL
			
			SET @I=@I+1
		END
		
		IF exists (SELECT * FROM @table where PrefValue=convert(nvarchar,@ProfileID))
		BEGIN
			select TOP 1 @PrefValue='Profile used in Document Definition of "'+DocumentName+'"' from adm_documenttypes with(nolock) 
			where CostcenterID IN (SELECT CostcenterID FROM @table where PrefValue=convert(nvarchar,@ProfileID))
			RAISERROR(@PrefValue,16,1)
		END 
		ELSE
		BEGIN
			delete from [COM_DimensionMappings]	 
			where [ProfileID]=@ProfileID
		END
	END
	ELSE
	BEGIN
		SET @ErrorNumber=100
		Declare @XML XML,@dt float,@sql nvarchar(max)
	  --SP Required Parameters Check  
		set @dt=CONVERT(float,getdate())

		SET @XML=@DataXml
		IF(@ProfileID=0)
		BEGIN
			SELECT @ProfileID=ISNULL(MAX(ProfileID),0) +1 FROM [COM_DimensionMappings] WITH(NOLOCK)
		END
		ELSE
		BEGIN
			delete from [COM_DimensionMappings]	 
			where [ProfileID]=@ProfileID and
			DimensionMappingsID not in (select X.value('@DimMapID','BIGINT') 
			from @XML.nodes('/XML/Row') as Data(X)  
			where X.value('@DimMapID','BIGINT')>0)
		END
	  	 
		set @sql='INSERT INTO [COM_DimensionMappings]
			   ([ProfileID]
			   ,[ProfileName]
			   ,[ProductID]
			   ,[AccountID]'
	           
		select @sql=@sql+','+name from sys.columns
		where object_id=object_id('COM_DimensionMappings')
		and name like 'CCNID%'
		  
		select @sql=@sql+'   
			   ,[alpha1]
			   ,[alpha2]
			   ,[alpha3]
			   ,[alpha4]
			   ,[alpha5]
			   ,[DefXml]
			   ,[CompanyGUID]
			   ,[GUID]           
			   ,[CreatedBy]
			   ,[CreatedDate]
			   ,[VehicleID]
			   ,[DepXml]) select '+convert(nvarchar,@ProfileID)+','''+@ProfileName+''' ,isnull(X.value(''@ProductID'',''BIGINT''),1)
			   ,isnull(X.value(''@AccountID'',''BIGINT''),1)'
	    
		select @sql=@sql+',isnull(X.value(''@'+name+''',''BIGINT''),1)' from sys.columns
		where object_id=object_id('COM_DimensionMappings')
		and name like 'CCNID%' 
	  		
   		set @sql=@sql+'   
			   ,X.value(''@alpha1'',''nvarchar(max)'')
			   ,X.value(''@alpha2'',''nvarchar(max)'')
			   ,X.value(''@alpha3'',''nvarchar(max)'')
			   ,X.value(''@alpha4'',''nvarchar(max)'')
			   ,X.value(''@alpha5'',''nvarchar(max)'')
			   ,'''+@DefXml+'''
			   ,'''+@CompanyGUID+'''
			   ,NEWID()           
			   ,'''+@UserName+'''
			   ,'+convert(nvarchar(max),@dt)+'
			   ,isnull(X.value(''@VehicleID'',''BIGINT''),1)
			   ,'''+@DepXml+'''           
				from @XML.nodes(''/XML/Row'') as Data(X)  
				where X.value(''@DimMapID'',''BIGINT'')=0  
	  
	  UPDATE [COM_DimensionMappings]
	   SET [ProfileName] = '''+@ProfileName+'''
		  ,[ProductID] = isnull(X.value(''@ProductID'',''BIGINT''),1)
		  ,[AccountID] =isnull(X.value(''@AccountID'',''BIGINT''),1)'
	     
		 select @sql=@sql+','+name+'=isnull(X.value(''@'+name+''',''BIGINT''),1)' from sys.columns
		where object_id=object_id('COM_DimensionMappings')
		and name like 'CCNID%'  
	      
		   select @sql=@sql+'
		  ,[alpha1] = X.value(''@alpha1'',''nvarchar(max)'')
		  ,[alpha2] = X.value(''@alpha2'',''nvarchar(max)'')
		  ,[alpha3] = X.value(''@alpha3'',''nvarchar(max)'')
		  ,[alpha4] = X.value(''@alpha4'',''nvarchar(max)'')
		  ,[alpha5] = X.value(''@alpha5'',''nvarchar(max)'')
		  ,[DefXml] = '''+@DefXml+'''
		  ,[VehicleID] = isnull(X.value(''@VehicleID'',''BIGINT''),1)
		  ,[DepXml]='''+@DepXml+'''
		  from @XML.nodes(''/XML/Row'') as Data(X) 
		  WHERE DimensionMappingsID=X.value(''@DimMapID'',''BIGINT'')
		  and X.value(''@DimMapID'',''BIGINT'')>0'
		  select @sql
		  exec sp_executesql @sql,N'@XML xml',@XML
	END

COMMIT TRANSACTION   
SET NOCOUNT OFF;  
SELECT ErrorMessage,ErrorNumber FROM COM_ErrorMessages WITH(nolock)   
WHERE ErrorNumber=@ErrorNumber AND LanguageID=@LangID 
RETURN @ProfileID
END TRY  
BEGIN CATCH    
	--Return exception info [Message,Number,ProcedureName,LineNumber]    
	IF ERROR_NUMBER()=50000  
	BEGIN  
		if isnumeric(ERROR_MESSAGE())=1
			SELECT ErrorMessage,ErrorNumber FROM COM_ErrorMessages WITH(nolock) WHERE ErrorNumber=ERROR_MESSAGE() AND LanguageID=@LangID
		else
			SELECT ERROR_MESSAGE() ErrorMessage,-1 ErrorNumber
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

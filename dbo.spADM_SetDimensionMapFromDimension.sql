USE PACT2C222
GO
SET ANSI_NULLS, QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spADM_SetDimensionMapFromDimension]
	@ProfileID [bigint],
	@CCID [bigint] = 0,
	@CCNODEID [bigint] = 0,
	@DataXml [nvarchar](max),
	@CompanyGUID [nvarchar](50),
	@UserName [nvarchar](200),
	@UserID [bigint],
	@LangID [int] = 1
WITH ENCRYPTION, EXECUTE AS CALLER
AS
BEGIN TRANSACTION    
BEGIN TRY    
SET NOCOUNT ON;  
   
	Declare @XML XML,@dt float,@ProfileName NVARCHAR(300),@DefXml NVARCHAR(MAX)
	
	SELECT @ProfileName=PROFILENAME,@DefXml=[DefXml] FROM COM_DimensionMappings WITH(NOLOCK) WHERE ProfileID=@ProfileID
  --SP Required Parameters Check  
	set @dt=CONVERT(float,getdate())

  SET @XML=@DataXml 
  
	INSERT INTO [COM_DimensionMappings]
           ([ProfileID]
           ,[ProfileName]
           ,[ProductID]
           ,[AccountID]
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
           ,[VehicleID])
     select
           @ProfileID
           ,@ProfileName
           ,isnull(X.value('@ProductID','BIGINT'),1)
           ,isnull(X.value('@AccountID','BIGINT'),1)
           ,isnull(X.value('@CCNID1','BIGINT'),1)
           ,isnull(X.value('@CCNID2','BIGINT'),1)
           ,isnull(X.value('@CCNID3','BIGINT'),1)
           ,isnull(X.value('@CCNID4','BIGINT'),1)
           ,isnull(X.value('@CCNID5','BIGINT'),1)
           ,isnull(X.value('@CCNID6','BIGINT'),1)
           ,isnull(X.value('@CCNID7','BIGINT'),1)
           ,isnull(X.value('@CCNID8','BIGINT'),1)
           ,isnull(X.value('@CCNID9','BIGINT'),1)
           ,isnull(X.value('@CCNID10','BIGINT'),1)
           ,isnull(X.value('@CCNID11','BIGINT'),1)
           ,isnull(X.value('@CCNID12','BIGINT'),1)
           ,isnull(X.value('@CCNID13','BIGINT'),1)
           ,isnull(X.value('@CCNID14','BIGINT'),1)
           ,isnull(X.value('@CCNID15','BIGINT'),1)
           ,isnull(X.value('@CCNID16','BIGINT'),1)
           ,isnull(X.value('@CCNID17','BIGINT'),1)
           ,isnull(X.value('@CCNID18','BIGINT'),1)
           ,isnull(X.value('@CCNID19','BIGINT'),1)
           ,isnull(X.value('@CCNID20','BIGINT'),1)
           ,isnull(X.value('@CCNID21','BIGINT'),1)
           ,isnull(X.value('@CCNID22','BIGINT'),1)
           ,isnull(X.value('@CCNID23','BIGINT'),1)
           ,isnull(X.value('@CCNID24','BIGINT'),1)
           ,isnull(X.value('@CCNID25','BIGINT'),1)
           ,isnull(X.value('@CCNID26','BIGINT'),1)
           ,isnull(X.value('@CCNID27','BIGINT'),1)
           ,isnull(X.value('@CCNID28','BIGINT'),1)
           ,isnull(X.value('@CCNID29','BIGINT'),1)
           ,isnull(X.value('@CCNID30','BIGINT'),1)
           ,isnull(X.value('@CCNID31','BIGINT'),1)
           ,isnull(X.value('@CCNID32','BIGINT'),1)
           ,isnull(X.value('@CCNID33','BIGINT'),1)
           ,isnull(X.value('@CCNID34','BIGINT'),1)
           ,isnull(X.value('@CCNID35','BIGINT'),1)
           ,isnull(X.value('@CCNID36','BIGINT'),1)
           ,isnull(X.value('@CCNID37','BIGINT'),1)
           ,isnull(X.value('@CCNID38','BIGINT'),1)
           ,isnull(X.value('@CCNID39','BIGINT'),1)
           ,isnull(X.value('@CCNID40','BIGINT'),1)
           ,isnull(X.value('@CCNID41','BIGINT'),1)
           ,isnull(X.value('@CCNID42','BIGINT'),1)
           ,isnull(X.value('@CCNID43','BIGINT'),1)
           ,isnull(X.value('@CCNID44','BIGINT'),1)
           ,isnull(X.value('@CCNID45','BIGINT'),1)
           ,isnull(X.value('@CCNID46','BIGINT'),1)
           ,isnull(X.value('@CCNID47','BIGINT'),1)
           ,isnull(X.value('@CCNID48','BIGINT'),1)
           ,isnull(X.value('@CCNID49','BIGINT'),1)
           ,isnull(X.value('@CCNID50','BIGINT'),1)
           ,X.value('@alpha1','nvarchar(max)')
           ,X.value('@alpha2','nvarchar(max)')
           ,X.value('@alpha3','nvarchar(max)')
           ,X.value('@alpha4','nvarchar(max)')
           ,X.value('@alpha5','nvarchar(max)')
           ,@DefXml
           ,@CompanyGUID
           ,NEWID()           
           ,@UserName
           ,@dt
           ,isnull(X.value('@VehicleID','BIGINT'),1)
			from @XML.nodes('/XML/Row') as Data(X)  
			where X.value('@DimMapID','BIGINT')=0
			and X.value('@Action','NVARCHAR(300)')='NEW'
			
		
			
  UPDATE [COM_DimensionMappings]
   SET [ProfileName] = @ProfileName
      ,[ProductID] = isnull(X.value('@ProductID','BIGINT'),1)
      ,[AccountID] =isnull(X.value('@AccountID','BIGINT'),1)
      ,[CCNID1] = isnull(X.value('@CCNID1','BIGINT'),1)
      ,[CCNID2] = isnull(X.value('@CCNID2','BIGINT'),1)
      ,[CCNID3] = isnull(X.value('@CCNID3','BIGINT'),1)
      ,[CCNID4] = isnull(X.value('@CCNID4','BIGINT'),1)
      ,[CCNID5] = isnull(X.value('@CCNID5','BIGINT'),1)
      ,[CCNID6] = isnull(X.value('@CCNID6','BIGINT'),1)
      ,[CCNID7] = isnull(X.value('@CCNID7','BIGINT'),1)
      ,[CCNID8] = isnull(X.value('@CCNID8','BIGINT'),1)
      ,[CCNID9] = isnull(X.value('@CCNID9','BIGINT'),1)
      ,[CCNID10] =isnull(X.value('@CCNID10','BIGINT'),1)
      ,[CCNID11] =isnull(X.value('@CCNID11','BIGINT'),1)
      ,[CCNID12] =isnull(X.value('@CCNID12','BIGINT'),1)
      ,[CCNID13] =isnull(X.value('@CCNID13','BIGINT'),1)
      ,[CCNID14] =isnull(X.value('@CCNID14','BIGINT'),1)
      ,[CCNID15] =isnull(X.value('@CCNID15','BIGINT'),1)
      ,[CCNID16] =isnull(X.value('@CCNID16','BIGINT'),1)
      ,[CCNID17] =isnull(X.value('@CCNID17','BIGINT'),1)
      ,[CCNID18] =isnull(X.value('@CCNID18','BIGINT'),1)
      ,[CCNID19] =isnull(X.value('@CCNID19','BIGINT'),1)
      ,[CCNID20] =isnull(X.value('@CCNID20','BIGINT'),1)
      ,[CCNID21] =isnull(X.value('@CCNID21','BIGINT'),1)
      ,[CCNID22] =isnull(X.value('@CCNID22','BIGINT'),1)
      ,[CCNID23] =isnull(X.value('@CCNID23','BIGINT'),1)
      ,[CCNID24] =isnull(X.value('@CCNID24','BIGINT'),1)
      ,[CCNID25] =isnull(X.value('@CCNID25','BIGINT'),1)
      ,[CCNID26] =isnull(X.value('@CCNID26','BIGINT'),1)
      ,[CCNID27] =isnull(X.value('@CCNID27','BIGINT'),1)
      ,[CCNID28] =isnull(X.value('@CCNID28','BIGINT'),1)
      ,[CCNID29] =isnull(X.value('@CCNID29','BIGINT'),1)
      ,[CCNID30] =isnull(X.value('@CCNID30','BIGINT'),1)
      ,[CCNID31] =isnull(X.value('@CCNID31','BIGINT'),1)
      ,[CCNID32] =isnull(X.value('@CCNID32','BIGINT'),1)
      ,[CCNID33] =isnull(X.value('@CCNID33','BIGINT'),1)
      ,[CCNID34] =isnull(X.value('@CCNID34','BIGINT'),1)
      ,[CCNID35] =isnull(X.value('@CCNID35','BIGINT'),1)
      ,[CCNID36] =isnull(X.value('@CCNID36','BIGINT'),1)
      ,[CCNID37] =isnull(X.value('@CCNID37','BIGINT'),1)
      ,[CCNID38] =isnull(X.value('@CCNID38','BIGINT'),1)
      ,[CCNID39] =isnull(X.value('@CCNID39','BIGINT'),1)
      ,[CCNID40] =isnull(X.value('@CCNID40','BIGINT'),1)
      ,[CCNID41] =isnull(X.value('@CCNID41','BIGINT'),1)
      ,[CCNID42] =isnull(X.value('@CCNID42','BIGINT'),1)
      ,[CCNID43] =isnull(X.value('@CCNID43','BIGINT'),1)
      ,[CCNID44] =isnull(X.value('@CCNID44','BIGINT'),1)
      ,[CCNID45] =isnull(X.value('@CCNID45','BIGINT'),1)
      ,[CCNID46] =isnull(X.value('@CCNID46','BIGINT'),1)
      ,[CCNID47] =isnull(X.value('@CCNID47','BIGINT'),1)
      ,[CCNID48] =isnull(X.value('@CCNID48','BIGINT'),1)
      ,[CCNID49] =isnull(X.value('@CCNID49','BIGINT'),1)
      ,[CCNID50] =isnull(X.value('@CCNID50','BIGINT'),1)
      ,[alpha1] = X.value('@alpha1','nvarchar(max)')
      ,[alpha2] = X.value('@alpha2','nvarchar(max)')
      ,[alpha3] = X.value('@alpha3','nvarchar(max)')
      ,[alpha4] = X.value('@alpha4','nvarchar(max)')
      ,[alpha5] = X.value('@alpha5','nvarchar(max)')
      ,[DefXml] = @DefXml            
      ,[VehicleID] = isnull(X.value('@VehicleID','BIGINT'),1)
	  from @XML.nodes('/XML/Row') as Data(X) 
	  WHERE DimensionMappingsID=X.value('@DimMapID','BIGINT')
	  and X.value('@DimMapID','BIGINT')>0 	  and X.value('@Action','NVARCHAR(300)')='UPDATE'
  
	DELETE FROM [COM_DimensionMappings]  
	WHERE DimensionMappingsID IN(SELECT X.value('@DimMapID','bigint')  
	FROM @XML.nodes('/XML/Row') as Data(X)  
	WHERE X.value('@Action','NVARCHAR(10)')='DELETE')    
	
COMMIT TRANSACTION   
SET NOCOUNT OFF;  
SELECT ErrorMessage,ErrorNumber FROM COM_ErrorMessages WITH(nolock)   
WHERE ErrorNumber=100 AND LanguageID=@LangID 
RETURN @ProfileID
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

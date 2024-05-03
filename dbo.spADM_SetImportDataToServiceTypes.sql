USE PACT2C222
GO
SET ANSI_NULLS, QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spADM_SetImportDataToServiceTypes]
	@XML [nvarchar](max),
	@COSTCENTERID [bigint],
	@IsDuplicateNameAllowed [bit],
	@IsCodeAutoGen [bit],
	@IsOnlyName [bit],
	@CompanyGUID [nvarchar](50),
	@UserName [nvarchar](50),
	@UserID [bigint],
	@LangID [int] = 1
WITH ENCRYPTION, EXECUTE AS CALLER
AS
BEGIN TRANSACTION
BEGIN TRY
SET NOCOUNT ON	
		--Declaration Section
			DECLARE	@return_value int,@failCount int,@Dt float
			declare @NodeID bigint, @Table NVARCHAR(50),@SQL NVARCHAR(max)
			declare @GUID nvarchar(max)
			DECLARE @tempCode NVARCHAR(max),@DUPLICATECODE NVARCHAR(300),@DUPNODENO INT,@PARENTCODE NVARCHAR(max)
			DECLARE @TempGuid NVARCHAR(max),@HasAccess BIT,@DATA XML,@Cnt INT,@I INT, @CCID INT
			SET @DATA=@XML
			SET @Dt=CONVERT(FLOAT,GETDATE())--Setting Current Date  
		    SET @GUID=NEWID()
		--SP Required Parameters Check
		IF @CompanyGUID IS NULL OR @CompanyGUID=''
		BEGIN
			RAISERROR('-100',16,1)
		END

		 

 
		-- Create Temp Table
		CREATE TABLE #tblList1(
				ID int identity(1,1),
				[F1] nvarchar(max),
				[F2] nvarchar(max),
				[F3] nvarchar(max),
				[F4] nvarchar(max)) 
				 
		
		INSERT INTO #tblList1(F1,F2,F3,F4)

		SELECT
			X.value('@F1','nvarchar(max)'),
			X.value('@F2','nvarchar(max)'),
			X.value('@F3','nvarchar(max)'),
			X.value('@F4','nvarchar(max)')  
 		from @DATA.nodes('/XML/Row') as Data(X)
		 

		DECLARE @SERVICENM nvarchar(max),@TEMPxml NVARCHAR(MAX),@SERVICEDESC nvarchar(max),@REASON nvarchar(max) ,@REASONDESC nvarchar(max) 
		DECLARE @SERVICEId int,@MdId int,@VarId int ,@SegId int 
		SELECT @I=1, @Cnt=count(ID) FROM #tblList1 
		SET @failCount=0
--			WHILE(@I<=@Cnt)  
--			BEGIN
				BEGIN TRY	
					
					SET @SERVICEId=0 
					SET @SERVICENM='' SET @SERVICEDESC='' SET @REASON='' SET @REASONDESC=''   
					
					SELECT @SERVICENM=[F1],@SERVICEDESC=[F2],@REASON=[F3],@REASONDESC=[F4] FROM #tblList1 WHERE ID=1
					 
					--------------------------------------------------------------------------------------------
					IF(SELECT COUNT(SERVICENAME) FROM SVC_ServiceTypes where ServiceName=LTRIM(RTRIM(@SERVICENM))) > 0
					BEGIN
						SELECT @SERVICEId= ServiceTypeID FROM SVC_ServiceTypes where ServiceName=LTRIM(RTRIM(@SERVICENM)) GROUP BY ServiceTypeID
						UPDATE SVC_ServiceTypes SET Description=@SERVICEDESC,MODIFIEDBY=@UserName,ModifiedDate=convert(float,getdate()) WHERE ServiceName=LTRIM(RTRIM(@SERVICENM))
					END
					ELSE 
					BEGIN 
						INSERT INTO SVC_ServiceTypes(ServiceName,StatusID,Description,COMPANYGUID, GUID,CreatedBy,CreatedDate)
						VALUES(@SERVICENM,357,@SERVICEDESC,@CompanyGUID, @GUID, @UserName,convert(float,getdate()))
						SET @SERVICEId=SCOPE_IDENTITY()
						
				    END 
					--------------------------------------------------------------------------------------------
					--------------------------------------------------------------------------------------------					
					IF ((SELECT COUNT(*) FROM SVC_ServicesReasons WHERE ServiceTypeID=@SERVICEId AND Reason=LTRIM(RTRIM(@REASON)))>0)
					BEGIN
						UPDATE SVC_ServicesReasons SET Description=@REASONDESC,MODIFIEDBY=@UserName,ModifiedDate=convert(float,getdate())
						WHERE ServiceTypeID=@SERVICEId AND Reason=LTRIM(RTRIM(@REASON))
					END
					ELSE
					BEGIN
						INSERT INTO SVC_ServicesReasons(ServiceTypeID,Reason, Description, COMPANYGUID, GUID,CreatedBy,CreatedDate)
						VALUES( @SERVICEId, @REASON,@REASONDESC,@CompanyGUID, @GUID, @UserName,convert(float,getdate())) 
					END
 					-------------------------------------------------------------------------------------------- 
				END TRY
				BEGIN CATCH 
					SET @failCount=@failCount+1
				END CATCH
--				SET @I=@I+1
--
--			END

COMMIT TRANSACTION  
DROP TABLE #tblList1
SELECT ErrorMessage,ErrorNumber FROM COM_ErrorMessages WITH(nolock) 
WHERE ErrorNumber=100 AND LanguageID=@LangID
SET NOCOUNT OFF;  
RETURN @failCount  
END TRY  
BEGIN CATCH  
	--Return exception info [Message,Number,ProcedureName,LineNumber]  
	IF ERROR_NUMBER()=50000
	BEGIN
		SELECT ErrorMessage,ErrorNumber FROM COM_ErrorMessages WITH(nolock) 
		WHERE ErrorNumber=ERROR_MESSAGE() AND LanguageID=@LangID
	END
	ELSE IF ERROR_NUMBER()=547
	BEGIN
		SELECT ErrorMessage, ERROR_MESSAGE() AS ServerMessage,ERROR_NUMBER() as ErrorNumber, ERROR_PROCEDURE()as ProcedureName, ERROR_LINE() AS ErrorLine FROM COM_ErrorMessages WITH(nolock)
		WHERE ErrorNumber=-110 AND LanguageID=@LangID
	END
	ELSE IF ERROR_NUMBER()=2627
	BEGIN
		SELECT ErrorMessage, ERROR_MESSAGE() AS ServerMessage,ERROR_NUMBER() as ErrorNumber, ERROR_PROCEDURE()as ProcedureName, ERROR_LINE() AS ErrorLine FROM COM_ErrorMessages WITH(nolock)
		WHERE ErrorNumber=-116 AND LanguageID=@LangID
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

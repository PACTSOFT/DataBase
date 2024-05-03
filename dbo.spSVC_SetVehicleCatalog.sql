USE PACT2C222
GO
SET ANSI_NULLS, QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spSVC_SetVehicleCatalog]
	@XML [nvarchar](max),
	@FLAG [int],
	@COMPANYGUID [nvarchar](50),
	@USERNAME [nvarchar](50),
	@USERID [int],
	@LANGID [int]
WITH ENCRYPTION, EXECUTE AS CALLER
AS
BEGIN TRANSACTION  
BEGIN TRY  
SET NOCOUNT ON;
		--Declaration Section  	
		DECLARE @UOMID BIGINT,@DT FLOAT,@DATA XML,@I INT,@COUNT INT,@ISENABLED BIT,@ISVISIBLE BIT,@VARIANT NVARCHAR(300),@SEGMENT NVARCHAR(300), 
				@SEGID int,@VID int,@MAKE BIGINT,@MAKENAME NVARCHAR(300),@MODELNAME NVARCHAR(300),@MODEL BIGINT,@SYEAR int,@EYEAR int, @MapAction NVARCHAR(20)
		DECLARE @Trans BIGINT,@Spec BIGINT,@bst BIGINT,@fuel BIGINT,@cc BIGINT,@WD BIGINT,@SC BIGINT

		SET @DATA=@XML
		DECLARE @HasAccess BIT,@DuplicateBaseID BIGINT

		DECLARE @TEMP TABLE  (ID INT IDENTITY(1,1),VEHICLEID BIGINT,VARIANT NVARCHAR(300),SEGMENT NVARCHAR(300),VID INT,SEGID INT,ISENABLED BIT,ISVISIBLE BIT,
							MAKE BIGINT,MODEL BIGINT,MAKETEXT NVARCHAR(300),MODELTEXT NVARCHAR(300),[SYEAR] int,EYear int,MAPACTION NVARCHAR(300)
							,Trans BIGINT,Spec BIGINT,bst BIGINT,fuel BIGINT,cc BIGINT,WD BIGINT,SC BIGINT)
		
	
	    SET @DT=CONVERT(FLOAT,GETDATE())
		
			--INSERT INTO TEMPORARY TABLE
			INSERT INTO @TEMP (VID,VARIANT,SEGID,ISENABLED,ISVISIBLE,MAKE,MODEL,[SYEAR],EYear,MAKETEXT,MODELTEXT,MAPACTION,VEHICLEID,Trans ,Spec ,bst ,fuel ,cc ,WD ,SC )
			SELECT A.value('@VariantID','BIGINT'),A.value('@Variant','nvarchar(300)'),A.value('@SegmentID','BIGINT'),A.value('@IsEnabled','BIT'),A.value('@IsVisible','BIT')
			,A.value('@Make','BIGINT'),A.value('@Model','BIGINT'),A.value('@StartYear','int'),A.value('@EndYear','int')
			,A.value('@MakeText','nvarchar(300)'),A.value('@ModelText','nvarchar(300)'),A.value('@MapAction','nvarchar(300)'),A.value('@Primarykey','BIGINT')
			,A.value('@Transmission','BIGINT')
			,A.value('@Specification','BIGINT')
			,A.value('@EuroBSType','BIGINT')
			,A.value('@Fuel','BIGINT')
			,A.value('@CC','BIGINT')
			,A.value('@WheelDrive','BIGINT')
			,A.value('@SeatCapacity','BIGINT')
			FROM @DATA.nodes('/Data/Row') AS DATA(A) -- WHERE A.value('@MapAction','nvarchar(500)')='NEW' 
			ORDER BY A.value('@Year','nvarchar(300)')
			
			DECLARE @VEHICLEID BIGINT 
			SELECT @I=1,@COUNT=COUNT(*) FROM @TEMP  
			 
			--INSERT INTO VEHICLE IF NEW RECORDS ARE FOUND
			WHILE @I<=@COUNT  
			BEGIN  	
				 
				  SELECT @MAKE=MAKE,@MODEL=MODEL,@MAKENAME=MAKETEXT,@MODELNAME=MODELTEXT,@SYEAR=[SYEAR],@EYEAR=[EYEAR],
						 @VARIANT=VARIANT,@VID=VID,@SEGID=SEGID,@ISENABLED=ISENABLED,
						 @ISVISIBLE=ISVISIBLE,@MAPACTION=MAPACTION,@VEHICLEID=VEHICLEID,@Trans =Trans,@Spec =Spec,@bst =bst,@fuel =fuel,@cc =cc,@WD =WD,@SC=SC
			      FROM @TEMP WHERE ID=@I
			       
				  
				if exists(select MAKEID from [SVC_Vehicle] with(nolock) where [Make]=@MAKENAME)
					select @MAKE=MAKEID from [SVC_Vehicle] with(nolock) where [Make]=@MAKENAME order by Make
				else
					SELECT  @MAKE=ISNULL(MAX(MAKEID),0)+1 FROM [SVC_Vehicle] with(nolock) 

				if exists(select MODELID from [SVC_Vehicle] with(nolock) where [Model]=@MODELNAME)
					select @MODEL= MODELID from [SVC_Vehicle] with(nolock) where [Model]=@MODELNAME order by MODELID
				else
					SELECT  @MODEL=ISNULL(MAX(MODELID),0)+1 FROM [SVC_Vehicle] with(nolock) 
				 
 
				-- IF @VID<>-200
				 BEGIN
					 IF (SELECT ISNULL(COUNT(*),0) FROM  [SVC_Vehicle] WHERE VARIANT=LTRIM(RTRIM(@VARIANT)))=0
						 SELECT  @VID=ISNULL(MAX(VARIANTID),0)+1 FROM [SVC_Vehicle]
					 ELSE
						 SELECT  @VID=VARIANTID FROM [SVC_Vehicle] WHERE VARIANT=LTRIM(RTRIM(@VARIANT))
				 END
			 
				--IF @SEGID<>-200
--				BEGIN
--					IF (SELECT ISNULL(COUNT(*),0) FROM  [SVC_Vehicle] WHERE SEGMENT=LTRIM(RTRIM(@SEGMENT)))=0
--						 SELECT  @SEGID=ISNULL(MAX(SegmentID),0)+1 FROM [SVC_Vehicle]
--					 ELSE
--						 SELECT  @SEGID=SegmentID FROM [SVC_Vehicle] WHERE SEGMENT=LTRIM(RTRIM(@SEGMENT))
--                END

				IF @MAPACTION='NEW'
					INSERT INTO  [SVC_Vehicle]([MakeID],[Make],[ModelID],[Model],[StartYear],ENDYEAR,[VariantID],[Variant],[SegmentID],[IsEnabled],[IsVisible],[CompanyGUID]
				   ,[GUID],[CreatedBy],[CreatedDate],Transmission,Specification,EuroBSType,Fuel,CC,WheelDrive,SeatCapacity)
					VALUES(@MAKE,@MAKENAME,@MODEL,@MODELNAME,@SYEAR,@EYEAR,@VID,@VARIANT
				   ,@SEGID,@ISENABLED,@ISVISIBLE,@COMPANYGUID,NEWID()
				   ,@USERNAME,@DT,@Trans ,@Spec ,@bst ,@fuel ,@cc ,@WD ,@SC)
			    ELSE IF @MAPACTION='UPDATE'
			        UPDATE [SVC_Vehicle] SET [VariantID]=@VID,[Variant]=@VARIANT,[SegmentID]=@SEGID,[StartYear]=@SYEAR,ENDYEAR=@EYEAR,
					[IsEnabled]=@ISENABLED,[IsVisible]=@ISVISIBLE,MODIFIEDBY=@USERNAME,MODIFIEDDATE=CONVERT(FLOAT,GETDATE())
					,Transmission=@Trans,Specification=@Spec,EuroBSType=@bst,Fuel=@fuel,CC=@cc,WheelDrive=@WD,SeatCapacity=@SC			 
				    WHERE VehicleID=@VEHICLEID
	 			 UPDATE @TEMP SET MAKE=@MAKE,MODEL=@MODEL
				SET @I=@I+1 
			END		 

		  

COMMIT TRANSACTION    
SET NOCOUNT OFF; 
SELECT ErrorMessage,ErrorNumber FROM COM_ErrorMessages WITH(nolock) 
WHERE ErrorNumber=100 AND LanguageID=@LangID  
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

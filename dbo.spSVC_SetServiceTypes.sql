﻿USE PACT2C222
GO
SET ANSI_NULLS, QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spSVC_SetServiceTypes]
	@CostCenterID [int],
	@ServiceTypeID [int],
	@ServiceName [nvarchar](200),
	@Description [nvarchar](max),
	@StatusID [int],
	@AttachmentsXML [nvarchar](max),
	@ReasonsXML [nvarchar](max),
	@LocationsXML [nvarchar](max),
	@CompanyGUID [nvarchar](100),
	@GUID [nvarchar](100),
	@UserName [nvarchar](50),
	@UserID [int] = 0,
	@LangID [int] = 1
WITH ENCRYPTION, EXECUTE AS CALLER
AS
BEGIN TRANSACTION
BEGIN TRY    
SET NOCOUNT ON   
		--Declaration Section
			DECLARE @AttachmentID int, @XML xml, @RXML xml,@LXML xml, @Dt float, @Name nvarchar(100)				

			IF (@ServiceTypeID=0) 
			BEGIN
			set @Name=''
			select @Name=ServiceName  from SVC_ServiceTypes where ServiceName =@ServiceName 
			if (@Name =@ServiceName)
			BEGIN
				RAISERROR('-112',16,1)
			END
			ELSE
			BEGIN	
				INSERT INTO SVC_ServiceTypes(ServiceName,StatusID, COMPANYGUID, GUID,CreatedBy,CreatedDate)
				VALUES(@ServiceName,357,@CompanyGUID, @GUID, @UserName,convert(float,getdate()))
				SET @ServiceTypeID=SCOPE_IDENTITY()
			END			
			END
			ELSE IF(@ServiceTypeID >0)
			BEGIN
				SET @Dt=convert(float,getdate())
				-- Inserts file into Com_Files table
					SET @XML=@AttachmentsXML
					set @AttachmentID=0
				IF (@AttachmentsXML IS NOT NULL AND @AttachmentsXML <> '')
				BEGIN

					
					SET @AttachmentID=(Select COUNT(fileid) from COM_Files where FeatureID=56 and FeaturePK=@ServiceTypeID)


				
IF @AttachmentID=0 
					BEGIN
						INSERT INTO COM_Files(FilePath,ActualFileName,RelativeFileName,
						FileExtension,IsProductImage,FeatureID,FeaturePK,
						GUID,CreatedBy,CreatedDate)
						SELECT X.value('@FilePath','NVARCHAR(500)'),
						X.value('@ActualFileName','NVARCHAR(50)'),
						X.value('@RelativeFileName','NVARCHAR(50)'),
						X.value('@FileExtension','NVARCHAR(50)'),
						0,56,@ServiceTypeID,
						X.value('@GUID','NVARCHAR(50)'),
						@UserName,@Dt
						FROM @XML.nodes('/AttachmentsXML/Row') as Data(X) 	
						WHERE X.value('@Action','NVARCHAR(10)')='NEW'
						
						SET @AttachmentID=(Select TOP 1 fileid from COM_Files where FeatureID=56 and FeaturePK=@ServiceTypeID)
					END
					ELSE IF @AttachmentID >0

					BEGIN	

						--If Action is MODIFY then update Attachments
					UPDATE COM_Files
					SET FilePath=X.value('@FilePath','NVARCHAR(500)'),
						ActualFileName=X.value('@ActualFileName','NVARCHAR(50)'),
						RelativeFileName=X.value('@RelativeFileName','NVARCHAR(50)'),
						FileExtension=X.value('@FileExtension','NVARCHAR(50)'),
						IsProductImage=X.value('@IsProductImage','bit'),						
						GUID=X.value('@GUID','NVARCHAR(50)'),
						ModifiedBy=@UserName,
						ModifiedDate=@Dt
					FROM COM_Files C 
					INNER JOIN @XML.nodes('/AttachmentsXML/Row') as Data(X) 	
					ON convert(bigint,X.value('@AttachmentID','bigint'))=C.FileID
					END
				SET @AttachmentID=(Select TOP 1 fileid from COM_Files where FeatureID=56 and FeaturePK=@ServiceTypeID)
				END



				-- Update Type of Service Data
				UPDATE SVC_ServiceTypes SET	StatusID=@StatusID, Description=@Description, AttachmentID=@AttachmentID
				WHERE ServiceTypeID=@ServiceTypeID

				-- Insert into Reasons Table
				set @RXML=@ReasonsXML
				DELETE FROM SVC_ServicesReasons WHERE SERVICETYPEID=@ServiceTypeID
				INSERT INTO SVC_ServicesReasons(ServiceTypeID,Reason, Description, COMPANYGUID, GUID,CreatedBy,CreatedDate)
				SELECT @ServiceTypeID,
					X.value('@Reason','NVARCHAR(100)'),
					X.value('@RDescription','NVARCHAR(50)'),
					'CompanyGUID', 
					X.value('@GUID','NVARCHAR(50)'),
					@UserName,@Dt
					FROM @RXML.nodes('XML/Row') as Data(X)
				
			 

				set @LXML=@LocationsXML
				DELETE FROM SVC_SERVICECOSTCENTERMAP WHERE SERVICETYPEID=@ServiceTypeID
				INSERT INTO SVC_ServiceCostCenterMap(ServiceTypeID,CostCenterID, NodeID, COMPANYGUID, GUID,CreatedBy,CreatedDate)
				SELECT @ServiceTypeID,56,
					X.value('@NodeID','BIGINT'),
					'CompanyGUID', 
					X.value('@GUID','NVARCHAR(50)'),
					@UserName,@Dt
					FROM @LXML.nodes('XML/Row') as Data(X) 
				

			END
			 


COMMIT TRANSACTION
SELECT ErrorMessage,ErrorNumber FROM COM_ErrorMessages WITH(nolock) 
WHERE ErrorNumber=100 AND LanguageID=@LangID
SET NOCOUNT OFF;  
RETURN @ServiceTypeID
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

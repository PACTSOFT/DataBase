USE PACT2C222
GO
SET ANSI_NULLS, QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spCRM_SetActivity]
	@ActivityTypeID [int],
	@ScheduleID [int] = 0,
	@CCID [int] = 0,
	@STATUS [int],
	@SUBJECT [nvarchar](300) = NULL,
	@PRIORITY [int] = 0,
	@LOCATION [nvarchar](300) = NULL,
	@IsAllDayActivity [bit] = 0,
	@CUSTOMERID [nvarchar](300) = NULL,
	@CUSTOMERSELECTED [int] = NULL,
	@CUSTOMERTYPE [nvarchar](300) = NULL,
	@REMARKS [nvarchar](max) = NULL,
	@STARTDATE [datetime] = NULL,
	@ENDDATE [datetime] = NULL,
	@CLOSEDATE [datetime] = NULL,
	@CLOSETIME [nvarchar](300) = NULL,
	@STARTTIME [nvarchar](300) = NULL,
	@ENDTIME [nvarchar](300) = NULL,
	@IsReschedule [int] = NULL,
	@AssignedUser [int] = NULL,
	@EXTRAFIELDSQUERY [nvarchar](max) = NULL,
	@AttachmentData [nvarchar](max) = null,
	@ACTIVIYID [bigint] = 0,
	@SchID [bigint] = 0,
	@FreqType [int] = 0,
	@FreqInterval [int] = 0,
	@FreqSubdayType [int] = 0,
	@FreqSubdayInterval [int] = 0,
	@FreqRelativeInterval [int] = 0,
	@FreqRecurrenceFactor [int] = 0,
	@FirstPostingDate [nvarchar](100) = null,
	@RStartingTime [nvarchar](100) = null,
	@REndDate [nvarchar](100) = null,
	@REndingTime [nvarchar](100) = null,
	@ContactID [bigint] = null,
	@CompanyGUID [nvarchar](50),
	@UserName [nvarchar](50),
	@UserID [int] = 0,
	@LangId [int] = 1
WITH ENCRYPTION, EXECUTE AS CALLER
AS
SET NOCOUNT ON 
	BEGIN TRANSACTION
	BEGIN TRY
	 IF @CCID=-100
	 SET @CCID=1000
   
   Declare @NID bigint , @Tempactid bigint
   set @NID=0
   select @NID=NodeID from CRM_Activities WHERE ACTIVITYID=@ACTIVIYID
   IF @IsReschedule<>-1
   BEGIN 
		UPDATE CRM_Activities SET StatusID=413,
		ActualCloseDate=CONVERT(FLOAT,@CLOSEDATE),ActualCloseTime=@CLOSETIME 
		,Remarks=@REMARKS
		WHERE ACTIVITYID=@ACTIVIYID
		set @Tempactid=@ACTIVIYID
		SET @ACTIVIYID=0
		SET @STATUS=414
   END
   
   IF @AssignedUser IS NULL OR @AssignedUser=0
   SET @AssignedUser=@UserID
   
   IF @ACTIVIYID=0
   BEGIN
		INSERT INTO CRM_Activities( ActivityTypeID, ScheduleID, CostCenterID, NodeID, StatusID, Subject, Priority,  
		Location, IsAllDayActivity,  
		  CustomerID, Remarks,  ActualCloseDate,ActualCloseTime, StartDate,EndDate,StartTime,EndTime, CompanyGUID, GUID,  CreatedBy, CreatedDate,CustomerType,AssignUserID)
		VALUES (@ActivityTypeID,@ScheduleID,@CCID,@NID,@STATUS,@SUBJECT,@PRIORITY,@LOCATION,@IsAllDayActivity,@CUSTOMERID,@REMARKS
		,CONVERT(FLOAT,@CLOSEDATE),@CLOSETIME,CONVERT(FLOAT,@STARTDATE),CONVERT(FLOAT,@ENDDATE),@STARTTIME,@ENDTIME,@CompanyGUID,NEWID(),@UserName,CONVERT(FLOAT,GETDATE()),@CUSTOMERTYPE,@AssignedUser)
		 set @ACTIVIYID=scope_identity()  
		 
		 if(@SchID>0 and not exists (select ScheduleID from com_schedules where ScheduleID=@SchID))
		 begin
			INSERT INTO COM_Schedules(Name,StatusID,FreqType,FreqInterval,FreqSubdayType,FreqSubdayInterval,
							FreqRelativeInterval,FreqRecurrenceFactor,StartDate,EndDate,StartTime,EndTime,
							CompanyGUID,GUID,CreatedBy,CreatedDate)
						values('Recurrence',1,@FreqType,@FreqInterval,
							@FreqSubdayType,@FreqSubdayInterval,
							@FreqRelativeInterval,@FreqRecurrenceFactor,
							@FirstPostingDate,@REndDate,@RStartingTime,@REndingTime,
							@CompanyGUID,newid(),@UserName,convert(float,getdate()))
			set @SchID=SCOPE_IDENTITY();
			update CRM_Activities set ScheduleID=@SchID where ActivityID=@ACTIVIYID
		 end
		 else if(@SchID>0 and exists (select ScheduleID from com_schedules where ScheduleID=@SchID))
		 	update CRM_Activities set ScheduleID=@SchID where ActivityID=@ACTIVIYID 
		   
		  EXEC spCOM_SetNotifEvent -1002,@CCID,@NID,@CompanyGUID,@UserName,@UserID,-1,144,@ACTIVIYID
	END
	ELSE
	BEGIN				
			UPDATE CRM_Activities SET 
					ActivityTypeID=@ActivityTypeID, ScheduleID=@ScheduleID,   StatusID=@STATUS, Subject=@SUBJECT
					, Priority=@PRIORITY, ActualCloseDate=CONVERT(FLOAT,@CLOSEDATE),ActualCloseTime=@CLOSETIME ,
					Location=@LOCATION, IsAllDayActivity=@IsAllDayActivity,  CustomerType=@CUSTOMERTYPE,AssignUserID=@AssignedUser,
					CustomerID=@CUSTOMERID, Remarks=@REMARKS,   StartDate=CONVERT(FLOAT,@STARTDATE)
					,EndDate=CONVERT(FLOAT,@ENDDATE),StartTime=@STARTTIME,EndTime=@ENDTIME, CompanyGUID=@CompanyGUID, GUID=NEWID()
				WHERE ACTIVITYID=@ACTIVIYID
				
				declare @NodeID bigint
				select @NodeID=NodeID from CRM_Activities with(nolock)  WHERE ACTIVITYID=@ACTIVIYID
				
				
		  IF @STATUS=413
			EXEC spCOM_SetNotifEvent -1004,@CCID,@NID,@CompanyGUID,@UserName,@UserID,-1,144,@ACTIVIYID
		 ELSE				--Insert Notifications
			EXEC spCOM_SetNotifEvent -1003,@CCID,@NodeID,@CompanyGUID,@UserName,@UserID,-1,144,@ACTIVIYID
	END
	  if(@ContactID <>'' or @ContactID is not null )
			update CRM_Activities set ContactID=@ContactID where ActivityID=@ACTIVIYID 
	 IF @CCID=1000
		 UPDATE CRM_Activities SET ACCOUNTID=@CUSTOMERSELECTED WHERE ACTIVITYID=@ACTIVIYID
			
	if(@IsReschedule<>-1)
	begin
		insert into CRM_Assignment ([CCID],[CCNODEID],[TeamNodeID],[IsTeam],[CompanyGUID],[GUID],[Description],[CreatedBy],[CreatedDate]
		,[ModifiedBy],[ModifiedDate],[UserID],[IsGroup],[IsRole],IsFromActivity)
		(SELECT [CCID],[CCNODEID],[TeamNodeID],[IsTeam],[CompanyGUID],[GUID],[Description],[CreatedBy],[CreatedDate]
		,[ModifiedBy],[ModifiedDate],[UserID],[IsGroup],[IsRole],@ACTIVIYID
		 FROM  [CRM_Assignment] where IsFromActivity = @Tempactid)
	end
	
	IF(@EXTRAFIELDSQUERY IS NOT NULL AND @EXTRAFIELDSQUERY<>'')
	BEGIN
		DECLARE @SQL NVARCHAR(MAX)
		SET @SQL=' UPDATE CRM_Activities SET '+@EXTRAFIELDSQUERY+' WHERE ACTIVITYID='+CONVERT(NVARCHAR(50),@ACTIVIYID)
		print @SQL
		EXEC(@SQL)
	END		
	
	
	 --Inserts Multiple Attachments  
		IF (@AttachmentData IS NOT NULL AND @AttachmentData <> '')  
		BEGIN  
			declare @AttachXml xml
			set @AttachXml=@AttachmentData 
			INSERT INTO COM_Files(FilePath,ActualFileName,RelativeFileName,
			FileExtension,FileDescription,IsProductImage,FeatureID,CostCenterID,FeaturePK,  
			GUID,CreatedBy,CreatedDate)  
			SELECT X.value('@FilePath','NVARCHAR(500)'),X.value('@ActualFileName','NVARCHAR(50)'),X.value('@RelativeFileName','NVARCHAR(50)'),  
			X.value('@FileExtension','NVARCHAR(50)'),X.value('@FileDescription','NVARCHAR(500)'),X.value('@IsProductImage','bit'),144,144,@ACTIVIYID,  
			X.value('@GUID','NVARCHAR(50)'),@UserName,CONVERT(float,getdate())  
			FROM @AttachXml.nodes('/AttachmentsXML/Row') as Data(X)    
			WHERE X.value('@Action','NVARCHAR(10)')='NEW'  

			--If Action is MODIFY then update Attachments  
			UPDATE COM_Files  
			SET FilePath=X.value('@FilePath','NVARCHAR(500)'),  
			ActualFileName=X.value('@ActualFileName','NVARCHAR(50)'),  
			RelativeFileName=X.value('@RelativeFileName','NVARCHAR(50)'),  
			FileExtension=X.value('@FileExtension','NVARCHAR(50)'),  
			FileDescription=X.value('@FileDescription','NVARCHAR(500)'),  
			IsProductImage=X.value('@IsProductImage','bit'),        
			GUID=X.value('@GUID','NVARCHAR(50)'),  
			ModifiedBy=@UserName,  
			ModifiedDate=CONVERT(float,getdate())  
			FROM COM_Files C   
			INNER JOIN @AttachXml.nodes('/AttachmentsXML/Row') as Data(X)    
			ON convert(bigint,X.value('@AttachmentID','bigint'))=C.FileID  
			WHERE X.value('@Action','NVARCHAR(500)')='MODIFY'  

			--If Action is DELETE then delete Attachments  
			DELETE FROM COM_Files  
			WHERE FileID IN(SELECT X.value('@AttachmentID','bigint')  
			FROM @AttachXml.nodes('/AttachmentsXML/Row') as Data(X)  
			WHERE X.value('@Action','NVARCHAR(10)')='DELETE')  
		END  
		
				
		   
	COMMIT TRANSACTION
    SELECT ErrorMessage,ErrorNumber FROM COM_ErrorMessages WITH(nolock)   
WHERE ErrorNumber=100 AND LanguageID=@LangID  
SET NOCOUNT OFF;    
RETURN 1
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

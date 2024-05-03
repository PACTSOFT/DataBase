USE PACT2C222
GO
SET ANSI_NULLS, QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spCRM_SetProductEmailTemplates]
	@CCID [int] = 0,
	@CCNODEID [int] = 0,
	@TemplatesID [nvarchar](max) = null,
	@FilterXML [nvarchar](max) = null,
	@CompanyGUID [nvarchar](100),
	@UserName [nvarchar](100),
	@UserID [bigint],
	@RoleID [int],
	@LangID [int] = 1
WITH ENCRYPTION, EXECUTE AS CALLER
AS
BEGIN TRANSACTION
BEGIN TRY 
SET NOCOUNT ON

DECLARE @HasAccess bit

		--SP Required Parameters Check
		IF(@CCID=0)
		BEGIN
			RAISERROR('-100',16,1)
		END
	
		DECLARE @NotifGUID NVARCHAR(50),@Dt FLOAT
		SET @Dt=CONVERT(FLOAT,GETDATE())
		SET @NotifGUID=newid()	
		
		CREATE TABLE #TBL(ID INT IDENTITY(1,1),TEMPLATEID INT)
		INSERT INTO  #TBL
		EXEC SPSPLITSTRING @TemplatesID ,','
		
		DECLARE @I INT,@COUNT INT,@TID BIGINT
		set @I=1
		select @COUNT=count(*) from #TBL

		WHILE @I<=@COUNT
		BEGIN
			SELECT @TID=TEMPLATEID FROM #TBL WHERE ID=@I
				INSERT INTO COM_SchEvents(CostCenterID,NodeID,TemplateID,StatusID,EventTime,ScheduleID,StartFlag,StartDate,EndDate,CompanyGUID,GUID,
				CreatedBy,CreatedDate,SUBCostCenterID,SUBNodeID,FilterXML)
				SELECT @CCID,@CCNODEID,N.TemplateID,1,@Dt,0,0,@Dt,@Dt,@CompanyGUID,@NotifGUID,@UserName,@Dt,0,0,@FilterXML
				FROM COM_NotifTemplate N WITH(NOLOCK)
				WHERE N.TemplateType=1 AND N.TemplateID=@TID AND CostCenterID=@CCID AND StatusID=383
				AND N.TemplateID IN (SELECT NotificationID FROM COM_NotifTemplateUserMap WITH(NOLOCK)
				WHERE UserID=@UserID OR RoleID=@RoleID OR GroupID IN (select GID from COM_Groups WITH(nolock) where UserID=@UserID or RoleID=@RoleID))
		
			SET @I=@I+1
		END
		
	 	DROP TABLE #TBL

COMMIT TRANSACTION  

 SELECT ErrorMessage,ErrorNumber FROM COM_ErrorMessages WITH(nolock)   
WHERE ErrorNumber=100 AND LanguageID=@LangID  
SET NOCOUNT OFF;   
RETURN 1
END TRY  
BEGIN CATCH  
 IF ERROR_NUMBER()=50000
 BEGIN
  SELECT ErrorMessage,ErrorNumber FROM COM_ErrorMessages WITH(nolock) 
  WHERE ErrorNumber=ERROR_MESSAGE() AND LanguageID=@LangID
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

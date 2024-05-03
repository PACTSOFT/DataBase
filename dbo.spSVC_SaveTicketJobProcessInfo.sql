USE PACT2C222
GO
SET ANSI_NULLS, QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spSVC_SaveTicketJobProcessInfo]
	@TicketID [bigint],
	@sno [int],
	@Categoryid [int],
	@Technician [bigint],
	@Action [nvarchar](50),
	@Reason [int] = 0,
	@Remarks [nvarchar](max) = null,
	@CompanyGUID [nvarchar](50),
	@UserName [nvarchar](50),
	@USERID [int],
	@LANGID [int]
WITH ENCRYPTION, EXECUTE AS CALLER
AS
BEGIN TRANSACTION  
BEGIN TRY  
SET NOCOUNT ON;
		--Declaration Section  	 
		DECLARE  @Createddt float, @RowID bigint
		set @Createddt=CONVERT(float,getdate())
		
		 INSERT INTO [SVC_ServiceJobProcess]
			   ([ServiceTicketID],[SerialNumber],[PartCategoryID],[Technician],[Action]
			   ,[Reason],[Remarks],[CompanyGUID],[GUID],[Creastedby],[CreatedDate])
		 VALUES
			   (@TicketID ,@sno ,@Categoryid, @Technician, @Action, @Reason, @Remarks
			   ,@CompanyGUID ,newid(), @UserName,@Createddt)
		 SET @RowID=SCOPE_IDENTITY()
		 
		 if exists( select count(*) from SVC_ServiceJobsInfo with(nolock) where  [ServiceTicketID]=@TicketID and SerialNumber=@sno and PartCategoryID=@Categoryid)
			 update SVC_ServiceJobsInfo set  TechnicianPrimary=@Technician, Status=@Action 
			 where [ServiceTicketID]=@TicketID and SerialNumber=@sno and PartCategoryID=@Categoryid
			 
COMMIT TRANSACTION    
--ROLLBACK TRANSACTION
SET NOCOUNT OFF; 
return @RowID;
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

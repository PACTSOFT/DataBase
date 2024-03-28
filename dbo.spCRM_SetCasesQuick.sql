USE PACT2C222
GO
SET ANSI_NULLS, QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spCRM_SetCasesQuick]
	@CaseID [bigint] = 0,
	@CaseNumber [nvarchar](200),
	@CaseDate [datetime] = null,
	@CUSTOMER [int] = 0,
	@StatusID [int],
	@IsGroup [bit],
	@SelectedNodeID [bigint],
	@ActivityXml [nvarchar](max) = NULL,
	@CompanyGUID [varchar](50),
	@GUID [varchar](50),
	@UserName [nvarchar](50),
	@UserID [int] = 0,
	@LangID [int] = 1
WITH ENCRYPTION, EXECUTE AS CALLER
AS
BEGIN TRANSACTION    
BEGIN TRY    
SET NOCOUNT ON;  
  --Declaration Section  
  DECLARE @Dt float,@TempGuid nvarchar(50),@HasAccess bit
  DECLARE @IsDuplicateNameAllowed bit,@IsAccountCodeAutoGen bit,@IsIgnoreSpace bit  
  
  
  SET @Dt=convert(float,getdate())--Setting Current Date  
  

    SELECT @TempGuid=[GUID] from CRM_Cases  WITH(NOLOCK)   
			   WHERE CaseID=@CaseID
  
   IF(@TempGuid!=@Guid)--IF RECORD ALREADY UPDATED BY SOME OTHER USER i.e DIRTY READ    
   BEGIN    
       RAISERROR('-101',16,1)   
   END    
   ELSE    
   BEGIN
					 UPDATE [CRM_Cases]
					   SET [CreateDate] =CONVERT(float, @CaseDate)
						  ,[CaseNumber] = @CaseNumber
						  ,[StatusID] = @StatusID 
						  ,[CustomerID] = @CUSTOMER 
						   ,[GUID] = @Guid
						  ,[ModifiedBy] = @UserName
						  ,[ModifiedDate] = @Dt
					 WHERE CaseID=@CaseID  
   END  
	if(@ActivityXml<>'')
	begin
		declare @LocalXml xml
		set @LocalXml=@ActivityXml  

		exec spCom_SetActivitiesAndSchedules @ActivityXml,73,@CaseID,@CompanyGUID,@Guid,@UserName,@Dt,@LangID   
	end
COMMIT TRANSACTION    
 
SELECT ErrorMessage,ErrorNumber FROM COM_ErrorMessages WITH(nolock)   
WHERE ErrorNumber=100 AND LanguageID=@LangID  
SET NOCOUNT OFF;    
RETURN @CaseID    
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

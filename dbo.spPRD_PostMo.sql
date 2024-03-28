﻿USE PACT2C222
GO
SET ANSI_NULLS, QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spPRD_PostMo]
	@IssXML [nvarchar](max),
	@ExpXML [nvarchar](max),
	@ResXML [nvarchar](max),
	@date [datetime],
	@WONO [nvarchar](500),
	@LocationID [bigint],
	@DivisionID [bigint],
	@MFGOrderID [bigint],
	@RoleID [bigint],
	@CompanyGUID [nvarchar](50),
	@UserName [nvarchar](50),
	@UserID [int] = 0,
	@LangID [int] = 1
WITH ENCRYPTION, EXECUTE AS CALLER
AS
BEGIN TRANSACTION    
BEGIN TRY    
SET NOCOUNT ON;  
  --Declaration Section  
  Declare @IssCCID bigint,@ExpCCID bigint,@RcrsCCID bigint,@return_value int,@PrefValue nvarchar(200)
  
  if(@ResXML is not null and @ResXML<>'')
  begin
		select @RcrsCCID=CONVERT(int,Value) from COM_CostCenterPreferences WITH(nolock)
		where CostCenterID=78 and Name='ResourcesJV'
	
		EXEC	@return_value = [dbo].[spDOC_SettempAccDocument]
		@CostCenterID = @RcrsCCID,
		@DocID = 0,
		@DocPrefix = N'',
		@DocNumber = N'',
		@DocDate = @date,
		@DueDate = NULL,
		@BillNo = N'',
		@InvDocXML = @ResXML,
		@NotesXML = N'',
		@AttachmentsXML = N'',
		@ActivityXML = N'',
		@IsImport = 0,
		@LocationID = @LocationID,
		@DivisionID = @DivisionID,
		@WID = 0,
		@RoleID = @RoleID,
		@RefCCID =78,
		@RefNodeid  =@MFGOrderID,
		@CompanyGUID = @CompanyGUID,
		@UserName = @UserName,
		@UserID = @UserID,
		@LangID = @LangID
		INSERT INTO [PRD_MFGDocRef]([MFGOrderID],[AccDocID],[InvDocID])
		values(@MFGOrderID,@return_value,NULL)
     
  end
  
  if(@ExpXML is not null and @ExpXML<>'')
  begin
		select @ExpCCID=CONVERT(int,Value) from COM_CostCenterPreferences WITH(nolock)
		where CostCenterID=78 and Name='ExpensesJV'
	
		EXEC	@return_value = [dbo].[spDOC_SettempAccDocument]
		@CostCenterID = @ExpCCID,
		@DocID = 0,
		@DocPrefix = N'',
		@DocNumber = N'',
		@DocDate = @date,
		@DueDate = NULL,
		@BillNo = N'',
		@InvDocXML = @ExpXML,
		@NotesXML = N'',
		@AttachmentsXML = N'',
		@ActivityXML = N'',
		@IsImport = 0,
		@LocationID = @LocationID,
		@DivisionID = @DivisionID,
		@WID = 0,
		@RoleID = @RoleID,
		@RefCCID =78,
		@RefNodeid  =@MFGOrderID,
		@CompanyGUID = @CompanyGUID,
		@UserName = @UserName,
		@UserID = @UserID,
		@LangID = @LangID
		INSERT INTO [PRD_MFGDocRef]([MFGOrderID],[AccDocID],[InvDocID])
		values(@MFGOrderID,@return_value,NULL)
  end
  set @return_value=0
  if(@IssXML is not null and @IssXML<>'')
  begin
		select @IssCCID=CONVERT(int,Value) from COM_CostCenterPreferences WITH(nolock)
		where CostCenterID=78 and Name='DocIssue'
	
	  EXEC	@return_value = [dbo].[spDOC_SetTempInvDoc]
			@CostCenterID = @IssCCID,
			@DocID = 0,
			@DocPrefix = N'',
			@DocNumber = N'',
			@DocDate = @date,
			@DueDate = NULL,
			@BillNo = @wono,
			@InvDocXML = @IssXML,
			@BillWiseXML = N'',
			@NotesXML = N'',
			@AttachmentsXML = N'',
			@ActivityXML = N'',
			@IsImport = 0,
			@LocationID = @LocationID,
			@DivisionID = @DivisionID ,
			@WID = 0,
			@RoleID = @RoleID,			
			@DocAddress = N'',
			@RefCCID =78,
			@RefNodeid  =@MFGOrderID,
			@CompanyGUID = @CompanyGUID,
			@UserName = @UserName,
			@UserID = @UserID,
			@LangID = @LangID 
			
			INSERT INTO [PRD_MFGDocRef]([MFGOrderID],[AccDocID],[InvDocID])
			values(@MFGOrderID,NULL,@return_value)
  end
  
  
	
COMMIT TRANSACTION
SET NOCOUNT OFF;    
RETURN @return_value  
END TRY    
BEGIN CATCH    
if(@return_value=-999)
return -999
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

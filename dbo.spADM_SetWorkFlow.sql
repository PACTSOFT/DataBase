USE PACT2C222
GO
SET ANSI_NULLS, QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spADM_SetWorkFlow]
	@WorkFlowId [bigint],
	@WorkFlowName [nvarchar](500),
	@WorkflowXML [nvarchar](max),
	@Type [int],
	@CompanyGUID [nvarchar](50),
	@CreatedBy [nvarchar](50),
	@UserID [int],
	@LangId [int] = 1
WITH ENCRYPTION, EXECUTE AS CALLER
AS
BEGIN TRANSACTION    
BEGIN TRY    
SET NOCOUNT ON;  
		IF EXISTS (SELECT * FROM COM_WorkFlow WITH(NOLOCK) WHERE [WorkFlowName]=@WorkFlowName and WorkFlowId<>@WorkFlowId)
		BEGIN  
			RAISERROR('-112',16,1)  
		END  
		
		DECLARE @CreatedDate FLOAT ,@XML XML,@IsNew bit
		SET @CreatedDate=CONVERT(FLOAT,getdate())
		SET @XML=@WorkflowXML
		
		if(@WorkFlowId =0)
		BEGIN
			set @IsNew=1
			select @WorkFlowId=isnull(max(WorkFlowId),0)+1 from COM_WorkFlow WITH(NOLOCK) 
		END
		ELSE
		BEGIN
			DELETE FROM COM_WorkFlow WHERE WorkFlowId=@WorkFlowId
		END
		
		INSERT INTO [COM_WorkFlow]([WorkFlowID],[WorkFlowName],[LevelID],[LevelName],[LevelOrder]
           ,[GroupID],[RoleID],[UserID],[CompanyGUID],[GUID],[CreatedBy],[CreatedDate]
           ,[Type],EscDays,EscHours,ApprovalMandatory)
		SELECT @WorkFlowId,@WorkFlowName,X.value('@Seq','int'),X.value('@LevelName','nvarchar(500)'),X.value('@Seq','int')
		,X.value('@GroupID','int'),X.value('@RoleID','int'),X.value('@UserID','int'),@CompanyGUID,NEWID(),@CreatedBy,@CreatedDate
		,@Type,isnull(X.value('@EscDays','int'),0),isnull(X.value('@EscHours','int'),0),isnull(X.value('@APPMand','BIT'),0)
		from @XML.nodes('XML/Row') as Data(X)
		
		IF @IsNew=1
		BEGIN
			INSERT INTO ADM_Assign(CostCenterID,NodeID,UserID,RoleID,GroupID,CreatedBy,CreatedDate)
			VALUES(100,@WorkFlowId,@UserID,0,0,@CreatedBy,@CreatedDate)			
		END

COMMIT TRANSACTION    
SELECT * FROM [COM_WorkFlow] WITH(nolock) WHERE [WorkFlowID]=@WorkFlowId  
SELECT ErrorMessage,ErrorNumber FROM COM_ErrorMessages WITH(nolock)   
WHERE ErrorNumber=100 AND LanguageID=@LangID  
SET NOCOUNT OFF;    
RETURN @WorkFlowId
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

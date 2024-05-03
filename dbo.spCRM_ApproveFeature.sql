USE PACT2C222
GO
SET ANSI_NULLS, QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spCRM_ApproveFeature]
	@CCID [int] = 0,
	@CCNodeID [int] = 0,
	@STATUS [int] = 0,
	@DATE [datetime] = 0,
	@CompanyGUID [nvarchar](100),
	@UserName [nvarchar](100),
	@RoleID [int],
	@LangID [int] = 1
WITH ENCRYPTION, EXECUTE AS CALLER
AS
BEGIN TRANSACTION
BEGIN TRY 
SET NOCOUNT ON

DECLARE @HasAccess bit

	--SP Required Parameters Check
		if(@CCNodeID=0)
		BEGIN
			RAISERROR('-100',16,1)
		END
		
		
			--User acces check
		SET @HasAccess=dbo.fnCOM_HasAccess(@RoleID,@CCID,132)

		IF @HasAccess=0
		BEGIN
			RAISERROR('-105',16,1)
		END
		


 IF @CCID=86--IF IT IS LEAD
 BEGIN 
	UPDATE CRM_LEADS SET IsApproved=@STATUS, ApprovedDate=CONVERT(float,@DATE),ApprovedBy=@UserName where Leadid=@CCNodeID
 END
 ELSE IF @CCID=88--IF IT IS CAMPAIGN
 BEGIN 
	UPDATE CRM_Campaigns SET IsApproved=@STATUS, ApprovedDate=CONVERT(float,@DATE),ApprovedBy=@UserName where CampaignID=@CCNodeID
 END
	 
COMMIT TRANSACTION  

SET NOCOUNT OFF;   
SELECT ErrorMessage,ErrorNumber FROM COM_ErrorMessages WITH(nolock) 
WHERE ErrorNumber=100 AND LanguageID=@LangID 
RETURN 1
END TRY  
BEGIN CATCH  
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

﻿USE PACT2C222
GO
SET ANSI_NULLS, QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spDOC_GetVPTPrintCopies]
	@Type [int],
	@CostCenterID [bigint],
	@DocumentSeqNo [bigint],
	@LayoutID [bigint],
	@CompanyGUID [nvarchar](max),
	@UserName [nvarchar](50),
	@LangID [int]
WITH ENCRYPTION, EXECUTE AS CALLER
AS
BEGIN TRANSACTION  
BEGIN TRY  
SET NOCOUNT ON;

	IF @Type=0
	BEGIN
		SELECT Copies FROM COM_DocPrints WITH(NOLOCK) WHERE CostCenterID=@CostCenterID AND NodeID=@DocumentSeqNo AND TemplateID=@LayoutID
	END
	ELSE IF @Type=1
	BEGIN
		IF (SELECT COUNT(*) FROM COM_DocPrints WITH(NOLOCK) WHERE CostCenterID=@CostCenterID AND NodeID=@DocumentSeqNo AND TemplateID=@LayoutID)=0
		BEGIN 
			INSERT INTO COM_DocPrints(CostCenterID,NodeID,Copies,TemplateID,CompanyGUID,GUID,CreatedBy,CreatedDate)
			VALUES(@CostCenterID,@DocumentSeqNo,1,@LayoutID,@CompanyGUID,NEWID(),@UserName,CONVERT(FLOAT,getdate()))
		END
		ELSE
		BEGIN 
			UPDATE COM_DocPrints
			SET Copies=Copies+1,GUID=NEWID(),
				ModifiedBy=@UserName,ModifiedDate=CONVERT(FLOAT,getdate())
			WHERE CostCenterID=@CostCenterID AND NodeID=@DocumentSeqNo AND TemplateID=@LayoutID
		END
	END
	ELSE IF @Type=2
	BEGIN
		INSERT INTO COM_DocPrints(CostCenterID,NodeID,Copies,TemplateID,CompanyGUID,GUID,CreatedBy,CreatedDate)
		VALUES(@CostCenterID,@DocumentSeqNo,1,@LayoutID,substring(@CompanyGUID,1,charindex('~',@CompanyGUID)-1),substring(@CompanyGUID,charindex('~',@CompanyGUID)+1,len(@CompanyGUID)),@UserName,CONVERT(FLOAT,getdate()))
	END
COMMIT TRANSACTION 
SET NOCOUNT OFF;
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
			SELECT ErrorMessage, ERROR_MESSAGE() AS ServerMessage,ERROR_NUMBER() as ErrorNumber, ERROR_PROCEDURE()as ProcedureName, ERROR_LINE() AS ErrorLine
			FROM COM_ErrorMessages WITH(NOLOCK) WHERE ErrorNumber=-999 AND LanguageID=@LangID
		END
ROLLBACK TRANSACTION
SET NOCOUNT OFF  
RETURN -999   
END CATCH
GO

﻿USE PACT2C222
GO
SET ANSI_NULLS, QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spCOM_GetDocDraft]
	@DraftID [bigint],
	@CostCenterID [bigint],
	@Status [int],
	@IsReport [bit],
	@UserID [bigint],
	@UserName [nvarchar](100),
	@LangID [int] = 1
WITH ENCRYPTION, EXECUTE AS CALLER
AS
BEGIN TRY  
SET NOCOUNT ON;    
	DECLARE @SQL NVARCHAR(MAX)
	IF @DraftID=0
	BEGIN
		if(@CostCenterID>0)
		begin
			iF(@CostCenterID=95 OR @CostCenterID=103 OR @CostCenterID=104 OR @CostCenterID=129)
			BEGIN
				SET @SQL='SELECT quotationid DraftID,'''' DocName,0 NoOfProducts,0 NetValue, D.CostCenterID,case when ModifiedDate is null then CONVERT(DATETIME,createdDate) else CONVERT(DATETIME,ModifiedDate) end AS [Date],
				CASE WHEN '+CONVERT(NVARCHAR,@CostCenterID)+'=95 THEN ''Contract'' WHEN '+CONVERT(NVARCHAR,@CostCenterID)+'=103 THEN ''Quotation'' WHEN '+CONVERT(NVARCHAR,@CostCenterID)+'=104 THEN ''Purchase Contract'' WHEN '+CONVERT(NVARCHAR,@CostCenterID)+'=129 THEN ''Reservation'' ELSE '''' END Type,null HoldDate
				FROM ren_quotation D WITH(NOLOCK) 
				WHERE D.costcenterid='+CONVERT(NVARCHAR,@CostCenterID)+' and D.CreatedBy='''+@UserName+''' and D.StatusID=430 and (D.RefQuotation IS NULL OR D.RefQuotation=0)
				ORDER BY ModifiedDate DESC'
				EXEC (@SQL)
			END
			ELSE if(@IsReport is not null and @IsReport =1) 
				SELECT D.DraftID,DocName,NoOfProducts,NetValue, D.CostCenterID,CONVERT(DATETIME,ModifiedDate) AS [Date],(SELECT Top 1 DocumentName FROM ADM_DocumentTypes WITH(NOLOCK) WHERE CostCenterID=D.CostCenterID) Type,CONVERT(DATETIME,HoldDocDate) HoldDate
				FROM COM_DocDraft D WITH(NOLOCK) 
				WHERE Status=@Status and costcenterid=@CostCenterID
				ORDER BY ModifiedDate DESC
			else
			begin
				DECLARE @DocumentType INT
				SELECT @DocumentType=DocumentType FROM ADM_DocumentTypes WITH(NOLOCK) WHERE CostCenterID=@CostCenterID
				
				IF (@DocumentType=38 OR @DocumentType=39)
					SELECT D.DraftID,DocName,NoOfProducts,NetValue, D.CostCenterID,CONVERT(DATETIME,ModifiedDate) AS [Date],(SELECT Top 1 DocumentName FROM ADM_DocumentTypes WITH(NOLOCK) WHERE CostCenterID=D.CostCenterID) Type,CONVERT(DATETIME,HoldDocDate) HoldDate
					FROM COM_DocDraft D WITH(NOLOCK) 
					WHERE RegisterID=@UserID and Status=@Status and costcenterid=@CostCenterID 
					ORDER BY ModifiedDate DESC
				ELSE
					SELECT D.DraftID,DocName,NoOfProducts,NetValue, D.CostCenterID,CONVERT(DATETIME,ModifiedDate) AS [Date],(SELECT Top 1 DocumentName FROM ADM_DocumentTypes WITH(NOLOCK) WHERE CostCenterID=D.CostCenterID) Type,CONVERT(DATETIME,HoldDocDate) HoldDate
					FROM COM_DocDraft D WITH(NOLOCK) 
					WHERE UserID=@UserID and Status=@Status and costcenterid=@CostCenterID 
					ORDER BY ModifiedDate DESC
			end
		end
		else
		begin
			if(@IsReport is not null and @IsReport =1) 
				SELECT D.DraftID,DocName,NoOfProducts,NetValue, D.CostCenterID,CONVERT(DATETIME,ModifiedDate) AS [Date],
				(SELECT Top 1 DocumentName FROM ADM_DocumentTypes WITH(NOLOCK) WHERE CostCenterID=D.CostCenterID) Type,CONVERT(DATETIME,HoldDocDate) HoldDate 
				FROM COM_DocDraft D WITH(NOLOCK) 
				WHERE Status=@Status
				ORDER BY ModifiedDate DESC
			else 
				SELECT D.DraftID,DocName,NoOfProducts,NetValue, D.CostCenterID,CONVERT(DATETIME,ModifiedDate) AS [Date],
				(SELECT Top 1 DocumentName FROM ADM_DocumentTypes WITH(NOLOCK) WHERE CostCenterID=D.CostCenterID) Type,CONVERT(DATETIME,HoldDocDate) HoldDate
				FROM COM_DocDraft D WITH(NOLOCK) 
				WHERE UserID=@UserID and Status=@Status
				ORDER BY ModifiedDate DESC
		end
	END
	ELSE
	BEGIN
		SELECT *,CONVERT(DATETIME,HoldDocDate) HoldDate FROM COM_DocDraft WITH(NOLOCK) WHERE UserID=@UserID AND DraftID=@DraftID
	END
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
			SELECT ErrorMessage, ERROR_MESSAGE() AS ServerMessage,ERROR_NUMBER() AS ErrorNumber, ERROR_PROCEDURE()AS ProcedureName, ERROR_LINE() AS ErrorLine  
			FROM COM_ErrorMessages WITH(NOLOCK) WHERE ErrorNumber=-999 AND LanguageID=@LangID  
		END  
  SET NOCOUNT OFF    
 RETURN -999     
END CATCH   

GO

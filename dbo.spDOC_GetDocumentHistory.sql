USE PACT2C222
GO
SET ANSI_NULLS, QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spDOC_GetDocumentHistory]
	@CostCenterID [int],
	@DocID [bigint],
	@UserID [int] = 0,
	@RoleID [bigint] = 0,
	@UserName [nvarchar](50),
	@LangID [int] = 1
WITH ENCRYPTION, EXECUTE AS CALLER
AS
BEGIN TRY	
SET NOCOUNT ON

		--Declaration Section
		DECLARE @IsInventory bit
		
		--SP Required Parameters Check
		IF (@CostCenterID < 40000)
		BEGIN
			RAISERROR('-100',16,1)
		END
		
		select @IsInventory=IsInventory From adm_documentTypes WITH(NOLOCK)
		Where CostCenterID=@CostCenterID

		if(@IsInventory=1)
		BEGIN
			SElect distinct ModifiedBy,convert(datetime,ModifiedDate) ModifiedDate,max(InvDocDetailsHistoryID) maxid from INV_DocDetails_History WITH(NOLOCK)
			where CostCenterID=@CostCenterID and DocID=@DocID
			group by ModifiedBy,convert(datetime,ModifiedDate)
		END
		ELSE
		BEGIN
			SElect distinct ModifiedBy,convert(datetime,ModifiedDate) ModifiedDate,max(AccDocDetailsHistoryID) maxid from ACC_DocDetails_History WITH(NOLOCK)
			where CostCenterID=@CostCenterID and DocID=@DocID
			group by ModifiedBy,convert(datetime,ModifiedDate)
		END 
			
SET NOCOUNT OFF;
RETURN 1
END TRY
BEGIN CATCH  
	--Return exception info [Message,Number,ProcedureName,LineNumber]  
	IF ERROR_NUMBER()=50000
	BEGIN
		SELECT ErrorMessage,ErrorNumber FROM COM_ErrorMessages WITH(nolock) WHERE ErrorNumber=ERROR_MESSAGE() AND LanguageID=@LangID
	END
	ELSE
	BEGIN
		SELECT ErrorMessage, ERROR_MESSAGE() AS ServerMessage,ERROR_NUMBER() as ErrorNumber, ERROR_PROCEDURE()as ProcedureName, ERROR_LINE() AS ErrorLine
		FROM COM_ErrorMessages WITH(nolock) WHERE ErrorNumber=-999 AND LanguageID=@LangID
	END
SET NOCOUNT OFF  
RETURN -999   
END CATCH  
GO

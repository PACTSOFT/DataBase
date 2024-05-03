USE PACT2C222
GO
SET ANSI_NULLS, QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spDOC_GetStatusHistory]
	@CostCenterID [bigint],
	@DocID [bigint],
	@IsInvDoc [bit],
	@UserID [bigint],
	@LangID [int] = 1
WITH ENCRYPTION, EXECUTE AS CALLER
AS
BEGIN TRY  
SET NOCOUNT ON;    

	DECLARE @WorkFlowID INT
	IF @IsInvDoc=1
		SELECT @WorkFlowID=WorkFlowID FROM Inv_Docdetails with(nolock) WHERE CostCenterID=@CostCenterID AND DocID=@DocID
	ELSE
		SELECT @WorkFlowID=WorkFlowID FROM Acc_Docdetails with(nolock) WHERE CostCenterID=@CostCenterID AND DocID=@DocID
	
	SELECT CONVERT(DATETIME, A.CreatedDate) Date,A.WorkFlowLevel,
	(SELECT TOP 1 LevelName FROM COM_WorkFlow L with(nolock) WHERE L.WorkFlowID=@WorkFlowID AND L.LevelID=A.WorkFlowLevel) LevelName,
	A.CreatedBy,A.StatusID,S.Status,A.Remarks,U.FirstName,U.LastName,u.Email1 
	FROM COM_Approvals A with(nolock),COM_Status S with(nolock),ADM_Users U with(nolock)
	WHERE A.RowType=1 AND S.StatusID=A.StatusID AND CCID=@CostCenterID AND CCNodeID=@DocID AND A.USERID=U.USERID
	ORDER BY A.CreatedDate
	
	select levelID,LevelName,@WorkFlowID WID from COM_WorkFlow with(nolock) 
	where WorkFlowID=@WorkFlowID
	group by levelID,LevelName	
	
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

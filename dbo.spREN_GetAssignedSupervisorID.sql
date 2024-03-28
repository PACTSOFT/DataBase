USE PACT2c253
GO
SET ANSI_NULLS, QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[spREN_GetAssignedSupervisorID]
	@p1 [nvarchar](max),
	@p2 [nvarchar](max),
	@p3 [nvarchar](max),
	@p4 [nvarchar](max),
	@p5 [nvarchar](max),
	@p7 [nvarchar](max),
	@p8 [nvarchar](max),
	@p9 [nvarchar](max),
	@UserID [int] = 0,
	@LangID [int] = 0
WITH ENCRYPTION, EXECUTE AS CALLER
AS
BEGIN TRY

SET NOCOUNT ON

			if @LangID=0
				set @p8=@p7
select ParentNodeID SupervisorID from COM_CostCenterCostCenterMap with(nolock) 
where ParentCostCenterID=50158 and CostCenterID=50009 and convert(nvarchar,NodeID)=@p3 and ParentNodeID in (

select ParentNodeID from COM_CostCenterCostCenterMap with(nolock) 
where ParentCostCenterID=50158 and CostCenterID=50156 and convert(nvarchar,NodeID)=@p8)



 
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

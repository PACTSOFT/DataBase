USE PACT2C222
GO
SET ANSI_NULLS, QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spSVC_GetCategoryofParts]
	@Parts [nvarchar](max),
	@UserID [bigint],
	@LangID [int] = 1
WITH ENCRYPTION, EXECUTE AS CALLER
AS
BEGIN TRANSACTION
BEGIN TRY	
SET NOCOUNT ON
 
	Declare @sql nvarchar(max)
	
	set @sql='select P.NodeID PartID,cc.CCNID6,cc.CCNID30,C.Name Category,S.Name Subcategory ,
		cc.CCNID37, G.Name Grp
		from COM_CC50029 P WITH(nolock)
		join COM_CCCCData cc WITH(nolock) on P.NodeID=cc.NodeID and CC.CostCenterID=50029
		left join COM_Category C WITH(nolock) on C.NodeID=cc.CCNID6 and cc.CCNID6 <>1
		left join COM_CC50030 S WITH(nolock) on S.NodeID=cc.CCNID30 and cc.CCNID30 <>1
		left join COM_CC50037 G WITH(nolock) on G.NodeID=cc.CCNID37 and cc.CCNID37 <>1
		where P.NodeID in('+@Parts+')'
	exec(@sql)
	
COMMIT TRANSACTION
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
ROLLBACK TRANSACTION
SET NOCOUNT OFF  
RETURN -999   
END CATCH  


GO

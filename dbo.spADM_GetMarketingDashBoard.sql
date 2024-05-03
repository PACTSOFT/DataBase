USE PACT2C222
GO
SET ANSI_NULLS, QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spADM_GetMarketingDashBoard]
	@CreatedBy [nvarchar](300) = -100,
	@UserID [bigint],
	@LangID [int] = 1
WITH ENCRYPTION, EXECUTE AS CALLER
AS
BEGIN TRANSACTION
BEGIN TRY	
SET NOCOUNT ON
	
	EXEC spADM_GetUserNamebyOwner @UserID,@LangID
	DECLARE @SQL NVARCHAR(MAX),@WHERE NVARCHAR(300)
	--LEAD
	SET @WHERE=''
	IF @CreatedBy<>'-100'
	BEGIN
		SET @WHERE=' WHERE CRM_LEADS.CREATEDBY='''+convert(nvarchar,@CreatedBy)+''''
	END
	 
	-- SELECT COUNT(*) [SUM],isnull(ST.STATUS,''Empty'') STATUS FROM CRM_LEADS WITH(NOLOCK)
	--LEFT JOIN COM_Status ST ON ST.STATUSID=CRM_LEADS.STATUSID  '+@WHERE+'
	--GROUP BY CRM_LEADS.STATUSID,STATUS 
	
	SET @SQL='
	SELECT COUNT(*) [SUM],case LR.LanguageID when 2 then isnull(LR.ResourceData,''Empty'') else isnull(ST.STATUS,''Empty'')  end as STATUS FROM CRM_LEADS WITH(NOLOCK)
	LEFT JOIN COM_Status ST ON ST.STATUSID=CRM_LEADS.STATUSID 
	 LEFT JOIN COM_LanguageResources LR WITH(nolock) ON LR.RESOURCEID=ST.RESOURCEID  and LR.LanguageID='''+ convert(varchar,@LangID) +''''
	SET @SQL=@SQL + @WHERE
	SET @SQL=@SQL +'GROUP BY CRM_LEADS.STATUSID,STATUS,LR.ResourceData,LR.LanguageID
	UNION 
	SELECT COUNT(*),''All'' FROM CRM_LEADS '+@WHERE+''  
	print @SQL
	exec(@SQL)
	
	--OPPORTUNITY
	SET @WHERE=''
	SET @SQL=''
	IF @CreatedBy<>'-100'
	BEGIN
		SET @WHERE=' WHERE CRM_Opportunities.CREATEDBY='''+convert(nvarchar,@CreatedBy)+''''
	END
	 
	 
	-- SELECT COUNT(*) [SUM],isnull(ST.STATUS,''Empty'') STATUS FROM CRM_Opportunities WITH(NOLOCK)
	--LEFT JOIN COM_Status ST ON ST.STATUSID=CRM_Opportunities.STATUSID  '+@WHERE+'
	--GROUP BY CRM_Opportunities.STATUSID,STATUS 
	SET @SQL='
	SELECT COUNT(*) [SUM],case LR.LanguageID when 2 then isnull(LR.ResourceData,''Empty'') else isnull(ST.STATUS,''Empty'')  end as STATUS FROM CRM_Opportunities WITH(NOLOCK)
	LEFT JOIN COM_Status ST ON ST.STATUSID=CRM_Opportunities.STATUSID  
	 LEFT JOIN COM_LanguageResources LR WITH(nolock) ON LR.RESOURCEID=ST.RESOURCEID  and LR.LanguageID='''+ convert(varchar,@LangID) +''''
	SET @SQL=@SQL + @WHERE
	SET @SQL=@SQL +'GROUP BY CRM_Opportunities.STATUSID,STATUS,LR.ResourceData,LR.LanguageID 
	UNION 
	SELECT COUNT(*),''All'' FROM CRM_Opportunities '+@WHERE+''  
	print @SQL
	exec(@SQL)
	
	 


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

USE PACT2C222
GO
SET ANSI_NULLS, QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spREN_GetParticularsScreenDetails]
	@CCID [bigint] = 0,
	@CCNodeID [bigint] = 0,
	@UserID [bigint],
	@LangID [int] = 1
WITH ENCRYPTION, EXECUTE AS CALLER
AS
BEGIN TRANSACTION
BEGIN TRY	
SET NOCOUNT ON

	declare @T1 nvarchar(100),@T2 nvarchar(100),@Sql nvarchar(max)

	select @T1=TableName from adm_features WITH(NOLOCK) 
	where featureid in (select value from ADM_GlobalPreferences WITH(NOLOCK) 
					where  Name='DepositLinkDimension')
	select @T2=TableName from adm_features WITH(NOLOCK) 
	where featureid in (select value from ADM_GlobalPreferences WITH(NOLOCK) 
					where  Name='UnitLinkDimension')

	set @Sql ='select NodeID,Name as Particulars from '+@T1+' WITH(NOLOCK)'
	exec (@Sql)

	set @Sql ='select NodeID,Name as Type from '+@T2+' WITH(NOLOCK)'
	exec (@Sql)

	select value from ADM_GlobalPreferences WITH(NOLOCK)
	where Name='DepositLinkDimension'
	
	SELECT Name,Value FROM [COM_CostCenterPreferences] WITH(NOLOCK)
	where (Name='CrAccListview' OR Name='DrAccListview') AND [CostCenterID]=92

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

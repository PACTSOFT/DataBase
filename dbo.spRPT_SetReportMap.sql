USE PACT2C222
GO
SET ANSI_NULLS, QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spRPT_SetReportMap]
	@Type [int],
	@ReportID [bigint],
	@MapXML [nvarchar](max),
	@RowColumnMapXML [nvarchar](max) = null,
	@DocMapXML [nvarchar](max) = null,
	@UserName [nvarchar](50),
	@LangID [int] = 1
WITH ENCRYPTION, EXECUTE AS CALLER
AS
BEGIN TRANSACTION  
BEGIN TRY  
SET NOCOUNT ON;
	--Declaration Section
	DECLARE @Dt float,@XML xml
	
	IF @Type=0
	BEGIN
		set @XML=@MapXML
		set @Dt=CONVERT(float,getdate())
		
		delete from ADM_ReportsMap where ParentReportID=@ReportID
		
		insert into ADM_ReportsMap(Sno,ParentReportID,ChildReportID
			,ShowTitle,ReportTitle
			,ShowColumns,ShowTotals
			,MapXML
			,CreatedBy,CreatedDate)
		select X.value('@Sno','int'),@ReportID,X.value('@ReportID','bigint') 
			,X.value('@ShowTitle','bit'),X.value('@ReportTitle','nvarchar(500)')
			,X.value('@ShowColumns','bit'),X.value('@ShowTotals','bit')
			,X.value('@MapXML','nvarchar(max)')
			,@UserName,@Dt
		from @XML.nodes('/XML/Row') as Data(X)
		
		update ADM_RevenUReports
		set RowColumnReportsMap=@RowColumnMapXML,DocMapXML=@DocMapXML
		where ReportID=@ReportID
	END
	ELSE IF @Type=1
	BEGIN
		select M.*,R.ReportName,R.ReportDefnXML,R.StaticReportType
		from ADM_ReportsMap M with(nolock) 
		inner join ADM_RevenUReports R with(nolock) on M.ChildReportID=R.ReportID
		where ParentReportID=@ReportID
		order by Sno
		
		select RowColumnReportsMap ,DocMapXML 
		FROM ADM_RevenUReports with(nolock)
		where ReportID=@ReportID
		
		select DocumentName,CostCenterID from ADM_DocumentTypes WITH(NOLOCK)
		
	END
	ELSE IF @Type=2
	BEGIN
		select R.ReportDefnXML,R.StaticReportType
		from ADM_RevenUReports R with(nolock)
		where ReportID=@ReportID
	END
	ELSE IF @Type=3
	BEGIN
		select Sno,R.ReportName,R.ReportDefnXML,R.ReportID
		from ADM_ReportsMap M with(nolock) 
		inner join ADM_RevenUReports R with(nolock) on M.ChildReportID=R.ReportID
		where ParentReportID=@ReportID
		order by Sno		
	END
	ELSE IF @Type=4
	BEGIN
		update ADM_DocumentTypes set WebReportID=0
		
		if @MapXML!=''
		begin
			set @XML=@MapXML
			
			update D set WebReportID=X.value('@R','int')
			from ADM_DocumentTypes D
			join @XML.nodes('/XML/Row') as Data(X) on D.CostCenterID=X.value('@D','int')
		end
	END
		
COMMIT TRANSACTION  
SELECT ErrorMessage,ErrorNumber FROM COM_ErrorMessages WITH(nolock) 
WHERE ErrorNumber=100 AND LanguageID=@LangID
SET NOCOUNT OFF;  
RETURN @ReportID  
END TRY  
BEGIN CATCH  
	--Return exception info [Message,Number,ProcedureName,LineNumber]  
	IF ERROR_NUMBER()=50000
	BEGIN
		SELECT ErrorMessage,ErrorNumber FROM COM_ErrorMessages WITH(nolock) 
		WHERE ErrorNumber=ERROR_MESSAGE() AND LanguageID=@LangID
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

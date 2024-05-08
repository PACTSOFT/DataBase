USE PACT2C222
GO
SET ANSI_NULLS, QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spPAY_GetEmpDimensionsAsOnDate]
	@AsOnDate [datetime],
	@EmpFilter [nvarchar](max) = '',
	@DimFilter [nvarchar](max) = ''
WITH ENCRYPTION, EXECUTE AS CALLER
AS
DECLARE @SQL NVARCHAR(MAX),@SysColName NVARCHAR(100),@FType NVARCHAR(100)

DECLARE @ShowDefaultEmployee Varchar(5)
SELECT @ShowDefaultEmployee=ISNULL(VALUE,'False') FROM ADM_GlobalPreferences WITH(NOLOCK) WHERE Name='ShowDefaultEmployee'

SET @AsOnDate=GETDATE()
SET @SQL =''

SET @SQL=' SELECT * FROM (SELECT aa.NodeID as EmpSeqNo,aa.Code as EmpCode,aa.Name as EmpName,aa.IsGroup'

DECLARE CUR CURSOR FOR 
Select SysColumnName,Case When (ISNULL(UserProbableValues,'')='H' OR ISNULL(UserProbableValues,'')='History' OR ISNULL(UserProbableValues,'')='HP2') THEN 'HISTORY' ELSE 'LISTBOX' END
From ADM_CostCenterDef Where CostCenterID=50051 and SysColumnName Like 'CCNID%' and IsColumnInUse=1
OPEN CUR
FETCH NEXT FROM CUR INTO @SysColName,@FType
WHILE @@FETCH_STATUS=0
BEGIN
	IF(LEN(@SQL)>0)
		SET @SQL=@SQL+','
	
	IF(@FType='HISTORY')
	BEGIN
		SET @SQL=@SQL+'
						ISNULL((SELECT TOP 1 HistoryNodeID FROM COM_HistoryDetails WITH(NOLOCK) 
						Where CostCenterID=50051 AND NodeID=aa.NodeID AND HistoryCCID='+ CONVERT(NVARCHAR,(50000+ CONVERT(INT,(REPLACE(@SysColName,'CCNID',''))))) +' 
						AND CONVERT(DATETIME,FromDate)<=CONVERT(DATETIME,'''+CONVERT(NVARCHAR,@AsOnDate,106)+''') 
						ORDER BY FromDate DESC ),1) as '+@SysColName
	END
	ELSE
	BEGIN
		SET @SQL=@SQL+ 'EMPCCD.'+@SysColName
	END

FETCH NEXT FROM CUR INTO @SysColName,@FType
END
CLOSE CUR
DEALLOCATE CUR

SET @SQL =@SQL+'
FROM COM_CC50051 aa WITH(NOLOCK)
LEFT JOIN COM_CCCCDATA EMPCCD WITH(NOLOCK) ON EMPCCD.CostCenterID=50051 AND EMPCCD.NodeID=aa.NodeID
WHERE 1=1 '

IF(LEN(@EmpFilter)>0)
BEGIN
	SET @SQL =@SQL+' AND ((aa.IsGroup=1) OR ('+REPLACE(@EmpFilter,'a.','aa.')+'))'

IF @ShowDefaultEmployee='True'
BEGIN
	SET @SQL =@SQL+'  OR (aa.NodeID=1)'
END

END

SET @SQL =@SQL+') as tbl WHERE 1=1 ' 

IF(LEN(@DimFilter)>0)
BEGIN
	SET @SQL =@SQL+' AND ((tbl.IsGroup=1) OR ('+REPLACE(@DimFilter,'CCNID','tbl.CCNID')+'))'
	
IF @ShowDefaultEmployee='True'
BEGIN
	SET @SQL =@SQL+'  OR (tbl.EmpSeqNo=1)'
END

END

--PRINT @SQL
EXEC sp_executesql @SQL

SELECT @SQL


SET @SQL='select stuff(('+REPLACE(@SQL,'SELECT *','SELECT '',''+convert(nvarchar,EmpSeqNo)')+' for xml path ('''')),1,1,'''')'
--PRINT @SQL
EXEC sp_executesql @SQL
GO

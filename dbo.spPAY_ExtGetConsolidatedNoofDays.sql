﻿USE PACT2C222
GO
SET ANSI_NULLS, QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spPAY_ExtGetConsolidatedNoofDays]
	@FromDate [varchar](20) = null,
	@ToDate [varchar](20) = null,
	@EmployeeID [int] = 0,
	@LeaveType [int] = 0,
	@Session [varchar](20) = null,
	@UserID [int] = 1,
	@LangID [int] = 1,
	@NoOfDaysOP [decimal](9, 2) OUTPUT,
	@AtATimeOP [int] OUTPUT,
	@MaxLeavesOP [int] OUTPUT
WITH ENCRYPTION, EXECUTE AS CALLER
AS
BEGIN TRY
SET NOCOUNT ON;
DECLARE @NOOFHOLIDAYS INT,@WEEKLYOFFCOUNT INT,@GRADE INT,@INCREXC VARCHAR(50),@ATATIME INT,@EMPDOJ DATETIME,@MAXLEAVES DECIMAL(9,2),@CurrYearLeavestaken DECIMAL(9,2)
DECLARE @Year INT,@ALStartMonth INT,@ALStartMonthYear DATETIME,@ALEndMonthYear DATETIME,@EXSTAPPLIEDENCASHDAYS DECIMAL(9,2),@PayrollDate DATETIME

SET @PayrollDate=DATEADD(MONTH,DATEDIFF(MONTH,0,CONVERT(DATETIME,@FromDate)),0)
--START:FOR START DATE AND END DATE OF LEAVE YEAR	
EXEC [spPAY_EXTGetLeaveyearDates] @FromDate,@ALStartMonthYear OUTPUT,@ALEndMonthYear OUTPUT
	
--EMPLOYEE DATE OF JOINING
	SELECT @EMPDOJ=CONVERT(DATETIME,DOJ) FROM COM_CC50051 WITH(NOLOCK) WHERE NODEID=@EmployeeID
	
--FOR Grade

DECLARE @IsGradeWiseMP BIT
SELECT @IsGradeWiseMP=CONVERT(BIT,Value) FROM ADM_GlobalPreferences WITH(NOLOCK) WHERE Name='GradeWiseMonthlyPayroll'
IF @IsGradeWiseMP=1
BEGIN
	IF((SELECT COUNT(CostCenterID) FROM ADM_CostCenterDef WITH(NOLOCK) WHERE CostCenterID=50051 and SysColumnName ='CCNID53' and IsColumnInUse=1 and UserProbableValues='H')>0)
	BEGIN
		SELECT @Grade=ISNULL(HistoryNodeID,0) FROM COM_HistoryDetails WITH(NOLOCK) WHERE NodeID=@EmployeeID AND CostCenterID=50051 AND HistoryCCID=50053 AND (FromDate<=CONVERT(FLOAT,CONVERT(DATETIME,@PayrollDate))) AND (ToDate>=CONVERT(FLOAT,CONVERT(DATETIME,@PayrollDate)) OR ToDate IS NULL)
		IF(CONVERT(DATETIME,@EMPDOJ)>CONVERT(DATETIME,@PayrollDate) AND ISNULL(@Grade,0)=0)
			SELECT @Grade=ISNULL(HistoryNodeID,0) FROM COM_HistoryDetails WITH(NOLOCK) WHERE NodeID=@EmployeeID AND CostCenterID=50051 AND HistoryCCID=50053 AND (FromDate<=CONVERT(FLOAT,CONVERT(DATETIME,@EMPDOJ))) AND (ToDate>=CONVERT(FLOAT,CONVERT(DATETIME,@EMPDOJ)) OR ToDate IS NULL)
	END
	ELSE
		SELECT @Grade=ISNULL(CCNID53,0) FROM COM_CCCCDATA WITH(NOLOCK) WHERE COSTCENTERID=50051 AND NODEID=@EmployeeID
END
ELSE
BEGIN
	SET @Grade=1
END


--FOR CHECKING EXISTING LEAVES WITH CURRENT FROMDATE AND TODATE
IF ((SELECT COUNT(DocID) FROM INV_DOCDETAILS ID WITH(NOLOCK) 
INNER JOIN COM_DocTextData TD WITH(NOLOCK) ON ID.INVDOCDETAILSID=TD.INVDOCDETAILSID 
INNER JOIN COM_DocCCData DC WITH(NOLOCK) ON ID.INVDOCDETAILSID=DC.INVDOCDETAILSID
	 WHERE  TD.tDocumentType=62 AND DC.dcCCNID51=@EmployeeID AND DC.dcCCNID52=@LeaveType AND ID.STATUSID NOT IN (372,376) AND ISDATE(TD.dcAlpha4)=1 AND ISDATE(TD.dcAlpha5)=1 AND
		    (
		     CONVERT(DATETIME,dcAlpha4) between CONVERT(DATETIME,@FromDate) and CONVERT(DATETIME,@ToDate)
			 or CONVERT(DATETIME,dcAlpha5) between CONVERT(DATETIME,@FromDate) and CONVERT(DATETIME,@ToDate)
			 or CONVERT(DATETIME,@FromDate) between CONVERT(DATETIME,dcAlpha4) and CONVERT(DATETIME,dcAlpha5)
			 or CONVERT(DATETIME,@ToDate) between CONVERT(DATETIME,dcAlpha4) and CONVERT(DATETIME,dcAlpha4)) )<=0)					 
BEGIN
--INCLUDE OR EXCLUDE HOLIDAYS, ATATIME,MAXLEAVES AND WEEKLYOFFS
SELECT @INCREXC=ISNULL(INCLUDEREXCLUDE,''),@ATATIME=ISNULL(ATATIME,0),@MAXLEAVES=ISNULL(MAXLEAVES,0) FROM COM_CC50054 WITH(NOLOCK)
WHERE  GRADEID=@GRADE AND COMPONENTID=@LeaveType AND PAYROLLDATE=(SELECT MAX(PAYROLLDATE) FROM COM_CC50054  WITH(NOLOCK) WHERE CONVERT(DATETIME,PAYROLLDATE)<=CONVERT(DATETIME,@PayrollDate) AND GradeID=@Grade)	 

	IF(@FromDate is not null and @ToDate is not null and isnull(@Session,'Both')='Both')
	BEGIN			
		
		--FOR CHECKING CURRENT YEAR LEAVES TAKEN, HOLIDAYS AND WEEKLYOFFS
		EXEC [spPAY_GetCurrYearLeavesInfo] @FromDate,@ToDate,@EmployeeID,@LeaveType,@userid,@langid,@FromDate,0,@CurrYearLeavestaken OUTPUT,@NOOFHOLIDAYS OUTPUT,@WEEKLYOFFCOUNT OUTPUT,@EXSTAPPLIEDENCASHDAYS OUTPUT
		PRINT @CurrYearLeavestaken
		PRINT @NOOFHOLIDAYS
		PRINT @WEEKLYOFFCOUNT
		
		IF ISNULL(@MAXLEAVES,0)>0
			SET @MAXLEAVES=ISNULL(@MAXLEAVES,0)-(ISNULL(@CurrYearLeavestaken,0)+ISNULL(@EXSTAPPLIEDENCASHDAYS,0))
		
		--SELECTING THE DAYS BASED ON INCLUDE/EXCLUDE TYPE
		IF ISNULL(@INCREXC,'')='IncludeHolidays' OR ISNULL(@INCREXC,'')='ExcludeWeeklyOffs'
		BEGIN
			SELECT @NoOfDaysOP=(DATEDIFF("d",convert(varchar,@FromDate,101),convert(varchar,@ToDate,101))-ISNULL(@WEEKLYOFFCOUNT,0))+1 ,@AtATimeOP=@ATATIME,@MaxLeavesOP=@MAXLEAVES
		END
		ELSE IF ISNULL(@INCREXC,'')='IncludeWeeklyOffs' OR ISNULL(@INCREXC,'')='ExcludeHolidays'
		BEGIN
			SELECT @NoOfDaysOP=(DATEDIFF("d",convert(varchar,@FromDate,101),convert(varchar,@ToDate,101))-ISNULL(@NOOFHOLIDAYS,0))+1 ,@AtATimeOP=@ATATIME,@MaxLeavesOP=@MAXLEAVES
		END
		ELSE IF ISNULL(@INCREXC,'')='ExcludeBoth'
		BEGIN
			SELECT @NoOfDaysOP=(DATEDIFF("d",convert(varchar,@FromDate,101),convert(varchar,@ToDate,101))-ISNULL(@NOOFHOLIDAYS,0)-ISNULL(@WEEKLYOFFCOUNT,0))+1 ,@AtATimeOP=@ATATIME,@MaxLeavesOP=@MAXLEAVES
		END
		ELSE IF ISNULL(@INCREXC,'')='IncludeBoth'
		BEGIN
			SELECT @NoOfDaysOP=(DATEDIFF("d",convert(varchar,@FromDate,101),convert(varchar,@ToDate,101)))+1 ,@AtATimeOP=@ATATIME,@MaxLeavesOP=@MAXLEAVES
		END
	END	
	ELSE IF ISNULL(@Session,'')='Session1' OR ISNULL(@Session,'')='Session2'--FOR HALF DAY LEAVE
	BEGIN
		SELECT @NoOfDaysOP=0.5,@AtATimeOP=@ATATIME,@MaxLeavesOP=@MAXLEAVES
	END--FROMDATE AND TODATE
END--SELECTED DATES NOT EXIST
ELSE
BEGIN
	SELECT @NoOfDaysOP=-1,@AtATimeOP=0,@MaxLeavesOP=0
END
	
SET NOCOUNT OFF;  
--RETURN 1  
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
SET NOCOUNT OFF    
RETURN -999     
END CATCH
GO

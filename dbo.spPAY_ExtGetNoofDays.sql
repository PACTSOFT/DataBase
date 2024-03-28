﻿USE PACT2C222
GO
SET ANSI_NULLS, QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spPAY_ExtGetNoofDays]
	@FromDate [varchar](20) = null,
	@ToDate [varchar](20) = null,
	@EmployeeID [int] = 0,
	@LeaveType [int] = 0,
	@Session [varchar](20) = null,
	@DocID [int] = 0,
	@userid [int] = 1,
	@langid [int] = 1
WITH ENCRYPTION, EXECUTE AS CALLER
AS
BEGIN TRY
	SET NOCOUNT ON;
	DECLARE @NOOFHOLIDAYS INT,@WEEKLYOFFCOUNT INT,@GRADE INT,@INCREXC VARCHAR(50),@ATATIME INT,@MAXLEAVES DECIMAL(9,2),@CurrYearLeavestaken DECIMAL(9,2),@CurrMonthOpeningBalance DECIMAL(9,2)
	DECLARE @Year INT,@EMPDOJ DATETIME,@ALStartMonth INT,@ALStartMonthYear DATETIME,@ALEndMonthYear DATETIME,@EXSTAPPLIEDENCASHDAYS DECIMAL(9,2),@PayrollDate DATETIME,@EDITABLE INT,@DOCIDNOOFDAYS FLOAT
	DECLARE @PayrollDate1 DATETIME,@PayrollStart DATETIME,@PayrollEnd DATETIME
	DECLARE @MONTHTAB TABLE(ID INT IDENTITY(1,1),STDATE DATETIME,EDDATE DATETIME)
	
	EXEC spPAY_GetPayrollDate @FROMDATE,@PayrollDate1 OUTPUT,@PayrollStart OUTPUT, @PayrollEnd OUTPUT 

	--SET TO FIRST DAY FOR THE GIVEN DATE
	SET @PayrollDate=DATEADD(MONTH,DATEDIFF(MONTH,0,CONVERT(DATETIME,@FromDate)),0)
	
	--START:FOR START DATE AND END DATE OF LEAVE YEAR
	EXEC [spPAY_EXTGetLeaveyearDates] @FromDate,@ALStartMonthYear OUTPUT,@ALEndMonthYear OUTPUT
		
	--FOR GRADE
	--EMPLOYEE DATE OF JOINING
	SELECT @EMPDOJ=CONVERT(DATETIME,DOJ) FROM COM_CC50051 WITH(NOLOCK) WHERE NODEID=@EmployeeID
	
	--FOR Grade
			DECLARE @IsGradeWiseMP BIT
SELECT @IsGradeWiseMP=CONVERT(BIT,Value) FROM ADM_GlobalPreferences WITH(NOLOCK) WHERE Name='GradeWiseMonthlyPayroll'
IF @IsGradeWiseMP=1
BEGIN
	IF((SELECT COUNT(*) FROM ADM_CostCenterDef WITH(NOLOCK) WHERE CostCenterID=50051 and SysColumnName ='CCNID53' and IsColumnInUse=1 and UserProbableValues='H')>0)
	BEGIN
		SELECT @Grade=ISNULL(HistoryNodeID,0) FROM COM_HistoryDetails WITH(NOLOCK) WHERE NodeID=@EmployeeID AND CostCenterID=50051 AND HistoryCCID=50053 AND (CONVERT(DATETIME,FromDate)<=CONVERT(DATETIME,@PayrollDate)) AND (CONVERT(DATETIME,ToDate)>=CONVERT(DATETIME,@PayrollDate) OR ToDate IS NULL)
		IF(CONVERT(DATETIME,@EMPDOJ)>CONVERT(DATETIME,@PayrollDate) AND ISNULL(@Grade,0)=0)
			SELECT @Grade=ISNULL(HistoryNodeID,0) FROM COM_HistoryDetails WITH(NOLOCK) WHERE NodeID=@EmployeeID AND CostCenterID=50051 AND HistoryCCID=50053 AND (CONVERT(DATETIME,FromDate)<=CONVERT(DATETIME,@EMPDOJ)) AND (CONVERT(DATETIME,ToDate)>=CONVERT(DATETIME,@EMPDOJ) OR ToDate IS NULL)
	END
	ELSE
		SELECT @Grade=ISNULL(CCNID53,0) FROM COM_CCCCDATA WITH(NOLOCK) WHERE COSTCENTERID=50051 AND NODEID=@EmployeeID
END
ELSE
BEGIN
SET @Grade=1
END
	--IF((SELECT COUNT(*) FROM ADM_CostCenterDef WITH(NOLOCK) WHERE CostCenterID=50051 and SysColumnName ='CCNID53' and IsColumnInUse=1 and UserProbableValues='H')>0)
	--	SELECT @GRADE=HistoryNodeID FROM COM_HistoryDetails WITH(NOLOCK) WHERE NodeID=@EmployeeID AND CostCenterID=50051 AND HistoryCCID=50053 AND (CONVERT(DATETIME,FromDate)<=CONVERT(DATETIME,@PayrollDate)) AND (CONVERT(DATETIME,ToDate)>=CONVERT(DATETIME,@PayrollDate) OR ToDate IS NULL)
	--ELSE
	--	SELECT @GRADE=ISNULL(CCNID53,0) FROM COM_CCCCDATA WITH(NOLOCK) WHERE COSTCENTERID=50051 AND NODEID=@EmployeeID
	
	----DOCID = 0
	SET @EDITABLE=0
	IF (ISNULL(@DOCID,0)=0)
	BEGIN
		IF ((SELECT COUNT(*) FROM INV_DOCDETAILS ID WITH(NOLOCK) INNER JOIN COM_DocTextData TD WITH(NOLOCK) ON ID.INVDOCDETAILSID=TD.INVDOCDETAILSID INNER JOIN COM_DocCCData DC WITH(NOLOCK) ON ID.INVDOCDETAILSID=DC.INVDOCDETAILSID
			 WHERE  ID.DocumentType=62 AND DC.dcCCNID51=@EmployeeID AND ID.STATUSID NOT IN (372,376) AND ISDATE(TD.dcAlpha4)=1 AND ISDATE(TD.dcAlpha5)=1 AND
				(
			     CONVERT(DATETIME,dcAlpha4) between CONVERT(DATETIME,@FromDate) and CONVERT(DATETIME,@ToDate)
				 or CONVERT(DATETIME,dcAlpha5) between CONVERT(DATETIME,@FromDate) and CONVERT(DATETIME,@ToDate)
				 or CONVERT(DATETIME,@FromDate) between CONVERT(DATETIME,dcAlpha4) and CONVERT(DATETIME,dcAlpha5)
				 or CONVERT(DATETIME,@ToDate) between CONVERT(DATETIME,dcAlpha4) and CONVERT(DATETIME,dcAlpha4)) )<=0)
		BEGIN
			SET @EDITABLE=0
		END
		ELSE
		BEGIN
		   SET @EDITABLE=1
		END
	END
	----DOCID = 0
	----DOCID > 0
	ELSE IF ISNULL(@DOCID,0)>0
	BEGIN
		--START: LOADING DATES BASED ON DATERANGE
	   	DECLARE @DATESCOUNT TABLE (SNO INT IDENTITY(1,1),ID INT ,DATE1 DATETIME,DAYNAME VARCHAR(50),WEEKNO INT,COUNT INT)
	   	DECLARE @STARTDATE1 DATETIME,@ENDATE1 DATETIME
	   	DECLARE @MRC AS INT,@MC AS INT,@MID INT
	   	SET @STARTDATE1=CONVERT(DATETIME,@FromDate)
	   	SET @ENDATE1=CONVERT(DATETIME,@ToDate)
	   	
	   		;WITH DATERANGE AS
			(
			SELECT @STARTDATE1 AS DT,1 AS ID
			UNION ALL
			SELECT DATEADD(DD,1,DT),DATERANGE.ID+1 FROM DATERANGE WHERE ID<=DATEDIFF("d",convert(varchar,@STARTDATE1,101),convert(varchar,@ENDATE1,101))
			)
			
		INSERT INTO @DATESCOUNT
		SELECT ROW_NUMBER() OVER (ORDER BY DT) AS ID,DT AS WEEKDATE,DATENAME(DW,DT) AS DAY,0,0 FROM DATERANGE
	   	--SELECT * FROM @DATESCOUNT
	   	--END: LOADING DATES BASED ON DATERANGE
	   	
	   	--START: LOADING DATA FROM GIVEN DOCID AND OTHER DOCID DATA OF SAME EMPLOYEE 
		DECLARE @DATESAPPLIEDCOUNT TABLE (DOCID INT,DID INT,FDATE DATETIME,TDATE DATETIME,STODATE DATETIME,EODATE DATETIME,ISEDITABLE INT,EXSTLEAVETYPE INT,CURRLEAVETYPE INT,CURDOC INT)
			   
		INSERT INTO @DATESAPPLIEDCOUNT
		SELECT ID.DOCID,ID.INVDOCDETAILSID,CONVERT(DATETIME,dcAlpha4),CONVERT(DATETIME,dcAlpha5),CONVERT(DATETIME,@FromDate),CONVERT(DATETIME,@ToDate),
		  	   ISNULL(TD.DCALPHA10,0),DC.DCCCNID52,@LeaveType,1 
		FROM   INV_DOCDETAILS ID WITH(NOLOCK) INNER JOIN COM_DocTextData TD WITH(NOLOCK) ON ID.INVDOCDETAILSID=TD.INVDOCDETAILSID INNER JOIN COM_DocCCData DC WITH(NOLOCK) ON ID.INVDOCDETAILSID=DC.INVDOCDETAILSID
		WHERE  ID.DocumentType=62 AND DC.DCCCNID51=@EmployeeID AND ID.DOCID=@DOCID AND ISNULL(TD.DCALPHA10,0)=2 AND ID.STATUSID NOT IN (372,376)
	    UNION
	    SELECT ID.DOCID,ID.INVDOCDETAILSID,CONVERT(DATETIME,dcAlpha4),CONVERT(DATETIME,dcAlpha5),CONVERT(DATETIME,@FromDate),CONVERT(DATETIME,@ToDate),
	           ISNULL(TD.DCALPHA10,0),0,DC.DCCCNID52,0 
	    FROM   INV_DOCDETAILS ID WITH(NOLOCK) INNER JOIN COM_DocTextData TD WITH(NOLOCK) ON ID.INVDOCDETAILSID=TD.INVDOCDETAILSID INNER JOIN COM_DocCCData DC WITH(NOLOCK) ON ID.INVDOCDETAILSID=DC.INVDOCDETAILSID
		WHERE  ID.DocumentType=62 AND DC.DCCCNID51=@EmployeeID AND ID.DOCID<>@DOCID AND ID.STATUSID NOT IN (372,376)
	    --SELECT * FROM @DATESAPPLIEDCOUNT
		--END: LOADING DATA FROM GIVEN DOCID AND OTHER DOCID DATA OF SAME EMPLOYEE 
		    
		--START: UPDATING @DATESCOUNT TABLE 'COUNT' COLUMN TO 1 FROM LIST OF @DATESAPPLIEDCOUNT TABLE
		DECLARE @RC AS INT,@IC AS INT,@TRC AS INT,@DTT AS DATETIME,@RECCOUNT INT
		SET @IC=1
		SELECT @TRC=COUNT(*) FROM @DATESCOUNT
		WHILE(@IC<=@TRC)
		BEGIN
			SELECT @DTT=DATE1 FROM @DATESCOUNT WHERE SNO=@IC
		    
		    SELECT @RC=COUNT(*) FROM @DATESAPPLIEDCOUNT WHERE CONVERT(DATETIME,@DTT) BETWEEN CONVERT(DATETIME,FDATE) AND CONVERT(DATETIME,TDATE) AND CURRLEAVETYPE<>EXSTLEAVETYPE AND CURDOC=0
  		    UPDATE @DATESCOUNT SET count=ISNULL(@RC,0) WHERE CONVERT(DATETIME,DATE1)=CONVERT(DATETIME,@DTT)
		SET @IC=@IC+1
		END
		--SELECT * FROM @DATESCOUNT
		--END: UPDATING @DATESCOUNT TABLE 'COUNT' COLUMN TO 1 FROM LIST OF @DATESAPPLIEDCOUNT TABLE
		 SELECT @RECCOUNT=COUNT(*) FROM @DATESCOUNT WHERE count=1
		 IF ISNULL(@RECCOUNT,0)=0
			SET @EDITABLE=0
		 ELSE
		 	SET @EDITABLE=1
	END
	----DOCID > 0

		---------
DECLARE @LeaveTaken INT
IF (SELECT COUNT(*) FROM INV_DocDetails I WITH(NOLOCK)
		JOIN COM_DocCCData C WITH(NOLOCK) ON C.INVDOCDETAILSID=I.INVDOCDETAILSID
		JOIN COM_DocTextData T WITH(NOLOCK) ON T.InvDocDetailsID=I.InvDocDetailsID
		WHERE CostCenterID=40062  AND C.dcCCNID51=@EmployeeID AND ISDATE(T.dcAlpha4)=1 AND ISDATE(T.dcAlpha5)=1
		AND (CONVERT(DATETIME,dcAlpha4) between CONVERT(DATETIME,@PayrollStart) and CONVERT(DATETIME,@PayrollEnd)
				 or CONVERT(DATETIME,dcAlpha5) between CONVERT(DATETIME,@PayrollStart) and CONVERT(DATETIME,@PayrollEnd)
				 or CONVERT(DATETIME,@PayrollStart) between CONVERT(DATETIME,dcAlpha4) and CONVERT(DATETIME,dcAlpha5)
				 or CONVERT(DATETIME,@PayrollEnd) between CONVERT(DATETIME,dcAlpha4) and CONVERT(DATETIME,dcAlpha4)))>0
BEGIN
	SET @LeaveTaken=1
END
ELSE
BEGIN
	SET @LeaveTaken=0
END
	---------
	 	
	--IF  DATEDIFF(D,CONVERT(DATETIME,@FromDate),CONVERT(DATETIME,@ToDate))<=100
	--BEGIN		
		IF ((@EDITABLE)<=0)
		BEGIN
			IF(@FromDate is not null and @ToDate is not null and isnull(@Session,'Both')='Both')--FOR DAYS
			BEGIN			
				--INCLUDE OR EXCLUDE HOLIDAYS, ATATIME,MAXLEAVES AND WEEKLYOFFS
				SELECT @INCREXC=ISNULL(INCLUDEREXCLUDE,''),@ATATIME=ISNULL(ATATIME,0),@MAXLEAVES=ISNULL(MAXLEAVES,0) FROM COM_CC50054 WITH(NOLOCK) 
				WHERE  GRADEID=@GRADE AND COMPONENTID=@LeaveType AND PAYROLLDATE=(SELECT MAX(PAYROLLDATE) FROM COM_CC50054  WITH(NOLOCK) WHERE CONVERT(DATETIME,PAYROLLDATE)<=CONVERT(DATETIME,@PayrollDate) AND GradeID=@Grade)	 
								
				--FOR LEAVES TAKEN,HOLIDAYS AND WEEKLYOFFS IN A YEAR
				--select @FromDate,@ToDate,@EmployeeID,@LeaveType,@userid,@langid,@FromDate,0
				EXEC [spPAY_GetCurrYearLeavesInfo] @FromDate,@ToDate,@EmployeeID,@LeaveType,@userid,@langid,@FromDate,0,@CurrYearLeavestaken OUTPUT,@NOOFHOLIDAYS OUTPUT,@WEEKLYOFFCOUNT OUTPUT,@EXSTAPPLIEDENCASHDAYS OUTPUT
				PRINT @CurrYearLeavestaken
				print'was'
				PRINT @NOOFHOLIDAYS
				PRINT @WEEKLYOFFCOUNT
				
				IF ISNULL(@MAXLEAVES,0)>0
				BEGIN
					--READING APPLIED LEAVES
					IF ISNULL(@DocID,0)>0
					BEGIN
						SET @DOCIDNOOFDAYS=0
						SELECT @DOCIDNOOFDAYS=ISNULL(TD.dcAlpha7,0) FROM INV_DOCDETAILS ID WITH(NOLOCK) JOIN COM_DocCCData DC WITH(NOLOCK) ON ID.INVDOCDETAILSID=DC.INVDOCDETAILSID
							   JOIN COM_DocNumData DN WITH(NOLOCK) ON ID.INVDOCDETAILSID=DN.INVDOCDETAILSID JOIN COM_DocTextData TD WITH(NOLOCK) ON ID.INVDOCDETAILSID=TD.INVDOCDETAILSID
						WHERE  ISDATE(TD.DCALPHA4)=1 and id.DocumentType=62 AND DC.DCCCNID51=@EmployeeID AND DC.DCCCNID52=@LeaveType AND ID.DOCID=@DocID
					END
					PRINT @DOCIDNOOFDAYS
					SET @MAXLEAVES=ISNULL(@MAXLEAVES,0)-(ISNULL(@CurrYearLeavestaken,0)+ISNULL(@EXSTAPPLIEDENCASHDAYS,0))
					SET @MAXLEAVES=ISNULL(@MAXLEAVES,0)-ISNULL(@DOCIDNOOFDAYS,0)
				END
				--SELECTING THE DAYS BASED ON INCLUDE/EXCLUDE TYPE
				IF ISNULL(@INCREXC,'')='IncludeWeeklyOffs' OR ISNULL(@INCREXC,'')='ExcludeHolidays'
				BEGIN
					SELECT (DATEDIFF("d",convert(varchar,@FromDate,101),convert(varchar,@ToDate,101))-ISNULL(@NOOFHOLIDAYS,0))+1 as NoOfDays ,CONVERT(DATETIME,@FromDate) as FromDate,CONVERT(DATETIME,@ToDate) as ToDate,@ATATIME AS AtATIME,@MAXLEAVES AS MAXLEAVES,ISNULL(@LeaveTaken,0) LeaveTaken,ISNULL(@WEEKLYOFFCOUNT,0)WEEKLYOFFCOUNT,ISNULL(@NOOFHOLIDAYS,0)NOOFHOLIDAYS
				END
				ELSE IF ISNULL(@INCREXC,'')='ExcludeWeeklyOffs' OR ISNULL(@INCREXC,'')='IncludeHolidays'
				BEGIN
					SELECT (DATEDIFF("d",convert(varchar,@FromDate,101),convert(varchar,@ToDate,101))-ISNULL(@WEEKLYOFFCOUNT,0))+1 as NoOfDays ,CONVERT(DATETIME,@FromDate) as FromDate,CONVERT(DATETIME,@ToDate) as ToDate,@ATATIME AS AtATIME,@MAXLEAVES AS MAXLEAVES,ISNULL(@LeaveTaken,0) LeaveTaken,ISNULL(@WEEKLYOFFCOUNT,0)WEEKLYOFFCOUNT,ISNULL(@NOOFHOLIDAYS,0)NOOFHOLIDAYS
				END
				ELSE IF ISNULL(@INCREXC,'')='ExcludeBoth'
				BEGIN
					SELECT (DATEDIFF("d",convert(varchar,@FromDate,101),convert(varchar,@ToDate,101))-ISNULL(@NOOFHOLIDAYS,0)-ISNULL(@WEEKLYOFFCOUNT,0))+1 as NoOfDays ,CONVERT(DATETIME,@FromDate) as FromDate,CONVERT(DATETIME,@ToDate) as ToDate,@ATATIME AS AtATIME,@MAXLEAVES AS MAXLEAVES,ISNULL(@LeaveTaken,0) LeaveTaken,ISNULL(@WEEKLYOFFCOUNT,0)WEEKLYOFFCOUNT,ISNULL(@NOOFHOLIDAYS,0)NOOFHOLIDAYS
				END
				ELSE IF ISNULL(@INCREXC,'')='IncludeBoth'
				BEGIN
					SELECT (DATEDIFF("d",convert(varchar,@FromDate,101),convert(varchar,@ToDate,101)))+1 as NoOfDays ,CONVERT(DATETIME,@FromDate) as FromDate,CONVERT(DATETIME,@ToDate) as ToDate,@ATATIME AS AtATIME,@MAXLEAVES AS MAXLEAVES,ISNULL(@LeaveTaken,0) LeaveTaken,ISNULL(@WEEKLYOFFCOUNT,0)WEEKLYOFFCOUNT,ISNULL(@NOOFHOLIDAYS,0)NOOFHOLIDAYS
				END
			END	
			ELSE IF ISNULL(@Session,'')='Session1' OR ISNULL(@Session,'')='Session2'--FOR HALF DAY LEAVE
			BEGIN
				SELECT @INCREXC=ISNULL(INCLUDEREXCLUDE,''),@ATATIME=ISNULL(ATATIME,0),@MAXLEAVES=ISNULL(MAXLEAVES,0) FROM COM_CC50054 WITH(NOLOCK) 
				WHERE  GRADEID=@GRADE AND COMPONENTID=@LeaveType AND PAYROLLDATE=(SELECT MAX(PAYROLLDATE) FROM COM_CC50054  WITH(NOLOCK) WHERE CONVERT(DATETIME,PAYROLLDATE)<=CONVERT(DATETIME,@PayrollDate) AND GradeID=@Grade)	 

				SET @ToDate=@FromDate
				EXEC [spPAY_GetCurrYearLeavesInfo] @FromDate,@ToDate,@EmployeeID,@LeaveType,@userid,@langid,@FromDate,0,@CurrYearLeavestaken OUTPUT,@NOOFHOLIDAYS OUTPUT,@WEEKLYOFFCOUNT OUTPUT,@EXSTAPPLIEDENCASHDAYS OUTPUT
				
				IF ISNULL(@INCREXC,'')='IncludeWeeklyOffs' OR ISNULL(@INCREXC,'')='ExcludeHolidays'
				BEGIN
					SELECT CASE WHEN (ISNULL(@NOOFHOLIDAYS,0)>0) THEN 0 ELSE 0.5 END as NoOfDays ,CONVERT(DATETIME,@FromDate) as FromDate,CONVERT(DATETIME,@ToDate) as ToDate,@ATATIME AS AtATIME,@MAXLEAVES AS MAXLEAVES,ISNULL(@LeaveTaken,0) LeaveTaken,ISNULL(@WEEKLYOFFCOUNT,0)WEEKLYOFFCOUNT,ISNULL(@NOOFHOLIDAYS,0)NOOFHOLIDAYS
				END
				ELSE IF ISNULL(@INCREXC,'')='ExcludeWeeklyOffs' OR ISNULL(@INCREXC,'')='IncludeHolidays'
				BEGIN
					SELECT CASE WHEN (ISNULL(@WEEKLYOFFCOUNT,0)>0) THEN 0 ELSE 0.5 END as NoOfDays ,CONVERT(DATETIME,@FromDate) as FromDate,CONVERT(DATETIME,@ToDate) as ToDate,@ATATIME AS AtATIME,@MAXLEAVES AS MAXLEAVES,ISNULL(@LeaveTaken,0) LeaveTaken,ISNULL(@WEEKLYOFFCOUNT,0)WEEKLYOFFCOUNT,ISNULL(@NOOFHOLIDAYS,0)NOOFHOLIDAYS
				END
				ELSE IF ISNULL(@INCREXC,'')='ExcludeBoth'
				BEGIN
					SELECT CASE WHEN (ISNULL(@NOOFHOLIDAYS,0)>0 or ISNULL(@WEEKLYOFFCOUNT,0)>0) THEN 0 ELSE 0.5 END as NoOfDays ,CONVERT(DATETIME,@FromDate) as FromDate,CONVERT(DATETIME,@ToDate) as ToDate,@ATATIME AS AtATIME,@MAXLEAVES AS MAXLEAVES,ISNULL(@LeaveTaken,0) LeaveTaken,ISNULL(@WEEKLYOFFCOUNT,0)WEEKLYOFFCOUNT,ISNULL(@NOOFHOLIDAYS,0)NOOFHOLIDAYS
				END
				ELSE IF ISNULL(@INCREXC,'')='IncludeBoth'
				BEGIN
					SELECT 0.5 as NoOfDays ,CONVERT(DATETIME,@FromDate) as FromDate,CONVERT(DATETIME,@ToDate) as ToDate,@ATATIME AS AtATIME,@MAXLEAVES AS MAXLEAVES,ISNULL(@LeaveTaken,0) LeaveTaken,ISNULL(@WEEKLYOFFCOUNT,0)WEEKLYOFFCOUNT,ISNULL(@NOOFHOLIDAYS,0)NOOFHOLIDAYS
				END
			END
		END
		ELSE
		BEGIN--DATES ALREADY APPLIED (-1)
			SELECT -1 AS NoOfDays,CONVERT(DATETIME,@FromDate) as FromDate,CONVERT(DATETIME,@ToDate) as ToDate,0 AS AtATIME,0 AS MAXLEAVES,ISNULL(@LeaveTaken,0) LeaveTaken,ISNULL(@WEEKLYOFFCOUNT,0)WEEKLYOFFCOUNT,ISNULL(@NOOFHOLIDAYS,0)NOOFHOLIDAYS
		END
	 --END
	 --ELSE
	 --BEGIN--FROMDATE AND TODATE VALIDATION
		--   SELECT -1 AS NoOfDays,CONVERT(DATETIME,@FromDate) as FromDate,CONVERT(DATETIME,@ToDate) as ToDate,0 AS AtATIME,0 AS MAXLEAVES,ISNULL(@WEEKLYOFFCOUNT,0)WEEKLYOFFCOUNT,ISNULL(@NOOFHOLIDAYS,0)NOOFHOLIDAYS
	 --END
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

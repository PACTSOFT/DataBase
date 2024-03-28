﻿USE PACT2C222
GO
SET ANSI_NULLS, QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spPAY_GetRemainingVacationDays3]
	@Date [datetime],
	@Empnode [int],
	@Flag [int] = 0,
	@UserID [int] = 1,
	@LangID [int] = 1
WITH ENCRYPTION, EXECUTE AS CALLER
AS
Begin
SET NOCOUNT ON;
Declare @Rc Int,@Trc int,@LeaveType Int,@AvblblLeaves Float
Declare @DimVacDays float,@BelowSixMonthsDays float,@BelowOneYearDays float,@CalculateVacDayforVacationPeriod Varchar(3)
Declare @ExcludeWeeklyoffsasVacation Varchar(3),@ExcludeHolidaysasVacation Varchar(3),@ConsiderLOPwhilecalculatingCreditdays Varchar(3),@ConsiderExcessdaysasLOP Varchar(3)
Declare @Perdaysalarycalculations Varchar(50),@GradewiseVacationPref Varchar(5),@TotalDays float,@CalcVacdaysuptoLastMonth Varchar(5)
Declare @Grade Int,@OPLeavesAsOn DateTime,@OpVacDays float,@AssingedDimVacDays Int,@PayrollDate DATETIME,@AssingedLeaveType INT,@ActDOJ DateTime 
Declare @COMPONENTID Int,@COMPONENTIDSNO Int,@DCNUMFILED Varchar(10),@SYCOLNAME Varchar(15),@STRQRY Varchar(MAX)
Declare @OPVACATIONDAYS FLOAT,@OPVACATIONSALARY FLOAT,@decVal float,@DocMonth DateTime,@AccrueVacationDaysPref nvarchar(5)
Declare @DOJ DateTime,@DORJ DateTime,@VacationMonthsDiff float,@VACATIONPERIOD Varchar(20),@VACDAYSPERMONTH float,@VACDAYSPERIOD Varchar(20),@TMONTHS Int,@MonthlyNoofDays float,@VACATIONSTARTMONTH DateTime
Declare @CreditDaysCalculation Int
DECLARE @LEAVESTAKEN FLOAT,@LeavesTakenEncash FLOAT,@LeavesTakenEncashSUM FLOAT

--VMDD
DECLARE @VacMgmtDocID INT, @IsDefineDaysExists BIT
CREATE TABLE #VMDD(FromMonth INT,ToMonth INT,DaysPerMonth FLOAT,ApplyToPrevMonths NVARCHAR(50))
CREATE TABLE #VacMonthWiseAllotedDays(ID INT Identity(1,1),VacMonth DateTime,AllotedDays FLOAT,Yearly FLOAT)
--VMDD


SET @LeavesTakenEncashSUM=0.0

Create Table #VACDAYTAB (VACDAYS float)
Declare @GetAvlblLeaves TABLE(Id Int Identity(1,1),AssignedLeaves INT,AvailableLeaves DECIMAL(9,2),FDate DateTime,TDate DateTime,MaxEncashLeaves Float,MaxLeaves Float,ActualAvailableLeaves float)
Declare @TabLeaveTypes Table(Sno Int Identity(1,1),LeaveTypeNode Int,AvlblLeaves Float)
Declare @MonthDays TABLE(ID INT Identity(1,1),FDATE DateTime,TDATE DateTime,TOTALDAYS FLOAT,ACTUALDAYS FLOAT,DAYS float,LEAVESTAKEN FLOAT,LOPDAYS FLOAT)

--SET TO FIRST DAY FOR THE GIVEN DATE
SET @PayrollDate=DATEADD(MONTH,DATEDIFF(MONTH,0,CONVERT(DATETIME,@Date)),0)

--START:LOADING PREFERENCES
SELECT @GradewiseVacationPref=ISNULL(VALUE,'False') FROM ADM_GlobalPreferences WITH(NOLOCK) WHERE NAME='GradeWiseVacation'
SELECT @CalcVacDaysuptoLastMonth=ISNULL(VALUE,'False') FROM ADM_GlobalPreferences WITH(NOLOCK) WHERE Name='CalcVacDaysuptolastmonth'
SELECT @AccrueVacationDaysPref=ISNULL(VALUE,'False') FROM ADM_GlobalPreferences WITH(NOLOCK) WHERE Name='AccrueVacationDays'

IF(@Flag=1 OR @Flag=2)
	SET @CalcVacDaysuptoLastMonth='False'


IF (@GRADEWISEVACATIONPREF='True')
BEGIN
	IF((SELECT COUNT(*) FROM ADM_CostCenterDef WITH(NOLOCK) WHERE CostCenterID=50051 and SysColumnName ='CCNID53' and IsColumnInUse=1 and UserProbableValues='H')>0)
		SELECT @GRADE=ISNULL(HistoryNodeID,0) FROM COM_HistoryDetails WITH(NOLOCK) WHERE NodeID=@Empnode AND CostCenterID=50051 AND HistoryCCID=50053 AND (CONVERT(DATETIME,FromDate)<=CONVERT(DATETIME,@PayrollDate)) AND (CONVERT(DATETIME,ToDate)>=CONVERT(DATETIME,@PayrollDate) OR ToDate IS NULL)
	ELSE
		SELECT @GRADE=ISNULL(CCNID53,0) FROM COM_CCCCDATA WITH(NOLOCK) WHERE COSTCENTERID=50051 AND NODEID=@Empnode
END

IF ISNULL(@GRADE,0)=0
	SET @GRADE=1
	
SELECT @BelowSixMonthsDays=ISNULL(TD.DCALPHA3,'0'), @BelowOneYearDays=ISNULL(TD.DCALPHA4,'0'), @CalculateVacDayforVacationPeriod=ISNULL(TD.DCALPHA9,'NO'), 
	   @ConsiderLOPwhilecalculatingCreditdays=ISNULL(TD.DCALPHA8,'NO'),@ConsiderExcessdaysasLOP=ISNULL(TD.DCALPHA15,'NO'),@PERDAYSALARYCALCULATIONS=ISNULL(TD.DCALPHA16,'(FIELD/30)') ,@AssingedDimVacDays=ISNULL(dcAlpha5,0),@AssingedLeaveType=ISNULL(dcAlpha1,0),
	   @CreditDaysCalculation=ISNULL(TD.DCALPHA18,'1'),
	   @VacMgmtDocID=ID.DocID
FROM   INV_DOCDETAILS ID WITH(NOLOCK) JOIN COM_DOCTEXTDATA TD WITH(NOLOCK) ON ID.INVDOCDETAILSID=TD.INVDOCDETAILSID JOIN COM_DOCCCDATA CC WITH(NOLOCK) ON ID.INVDOCDETAILSID=CC.INVDOCDETAILSID
WHERE  CC.DCCCNID53=@Grade AND ID.COSTCENTERID=40061	
--END:LOADING PREFERENCES BASED ON GRADE

--START :GET DOJ,VACATIONPERIOD AND VACATION DAYS,OPLeavesAsOn,OpVacationDays FROM EMPLOYEE
SELECT @OPLeavesAsOn=CONVERT(DateTime,OPLeavesAsOn),@OpVacDays=isnull(OpVacationDays,0),@DOJ=CONVERT(DateTime,DOJ),@VACATIONPERIOD=VACATIONPERIOD,@VACDAYSPERMONTH=ISNULL(VACDAYSPERMONTH,0),@VACDAYSPERIOD=VACDAYSPERIOD FROM COM_CC50051 WHERE NODEID=@EmpNode
SET @ActDOJ=@Doj
IF(CONVERT(DateTime,@OPLeavesAsOn)<>'Jan  1 1900 12:00AM')
	SET @DOJ=@OPLeavesAsOn


--VMDD
SET @IsDefineDaysExists=0
IF EXISTS (SELECT SeqNo FROM PAY_VacManageDefineDays WITH(NOLOCK) WHERE VMDocID=@VacMgmtDocID)
BEGIN
	SET @IsDefineDaysExists=1
	INSERT INTO #VMDD
	SELECT FromMonth,ToMonth,DaysPerMonth,ApplyToPrevMonths 
	FROM PAY_VacManageDefineDays WITH(NOLOCK) WHERE VMDocID=@VacMgmtDocID

	declare @dtt1 datetime,@dtt2 datetime,@TotMon INT,@AllotedDays FLOAT,@MNo INT,@APM NVARCHAR(50),@YearlyVD FLOAT
	set @dtt1=dateadd(day,-datepart(day,@ActDOJ)+1,@ActDOJ)
	set @dtt2=dateadd(day,-datepart(day,@Date)+1,@Date)
	set @dtt2=DATEADD(year,1,@dtt2) -- adding extra 1 year to know the yearly vacation days
	SET @MNo=0
	WHILE(@dtt1<=@dtt2)
	BEGIN
		SET @MNo=@MNo+1
			
		SELECT @AllotedDays=DaysPerMonth,@APM=ApplyToPrevMonths FROM #VMDD WHERE @MNo BETWEEN FromMonth AND ToMonth
		INSERT INTO #VacMonthWiseAllotedDays
		SELECT @dtt1,@AllotedDays,-1

		IF(@APM='Yes')
			UPDATE #VacMonthWiseAllotedDays SET AllotedDays=@AllotedDays

		IF(@MNo%12)=0
		BEGIN
			SELECT @YearlyVD=SUM(AllotedDays) FROM #VacMonthWiseAllotedDays WHERE Yearly=-1
				
			IF(@APM='Yes')
				UPDATE #VacMonthWiseAllotedDays SET Yearly=@YearlyVD
			ELSE
				UPDATE #VacMonthWiseAllotedDays SET Yearly=@YearlyVD WHERE Yearly=-1

		END

		SET @dtt1=DATEADD(month,1,@dtt1)
	END

END
--SELECT * FROM #VacMonthWiseAllotedDays
--VMDD


	


DECLARE @TMP INT
set @TMP=0
--START : CHECKING THE PREVIOUS VACATION DETAILS OF EMPLOYEE IF NO RECORD FOUND THEN SELECT DOJ
IF ((SELECT count(*)  FROM INV_DOCDETAILS ID WITH(NOLOCK) JOIN COM_DOCTEXTDATA TD WITH(NOLOCK) ON ID.INVDOCDETAILSID=TD.INVDOCDETAILSID JOIN COM_DOCCCDATA CC  WITH(NOLOCK) ON ID.INVDOCDETAILSID=CC.INVDOCDETAILSID
	 WHERE  CC.DCCCNID51=@EmpNode AND ID.COSTCENTERID=40072 AND ISNULL(TD.DCALPHA2,'')<>'' AND ISNULL(TD.DCALPHA3,'')<>'' AND ISNULL(TD.DCALPHA1,'')<>'')>0)
BEGIN
	--DATE OF REJOING
	--SELECT @VACATIONSTARTMONTH=CONVERT(DateTime,TD.DCALPHA1) FROM INV_DOCDETAILS ID WITH(NOLOCK) JOIN COM_DOCTEXTDATA TD WITH(NOLOCK) ON ID.INVDOCDETAILSID=TD.INVDOCDETAILSID JOIN COM_DOCCCDATA CC  WITH(NOLOCK) ON ID.INVDOCDETAILSID=CC.INVDOCDETAILSID
	--WHERE  CC.DCCCNID51=@EmpNode AND ID.COSTCENTERID=40072 AND ISNULL(TD.DCALPHA2,'')<>'' AND ISNULL(TD.DCALPHA3,'')<>'' AND ISNULL(TD.DCALPHA1,'')<>'' ORDER BY CONVERT(DateTime,ID.DOCDATE) DESC
	
	SET   @VACATIONSTARTMONTH=@DOJ
	set @TMP=1
	
	IF (@CalcVacDaysuptoLastMonth='False')
		SET @VacationStartMonth=CONVERT(DATETIME,@VacationStartMonth)
	ELSE
		SET @VacationStartMonth=CONVERT(DATETIME,DATEADD(MONTH,DATEDIFF(MONTH,-1,CONVERT(DATETIME,@VacationStartMonth))-2,0))	
	
	--VACATION MONTHS DIFFERENCE
	SET @VacationMonthsDiff=DATEDIFF(MONTH,@VACATIONSTARTMONTH,DATEADD(DAY,0,@DATE))		
	--select @VacationMonthsDiff
	--GET VACDAYS COMPONENT FROM MONTHLY PAYROLL
	select @COMPONENTIDSNO=SNO from COM_CC50054 WITH(NOLOCK) WHERE COMPONENTID=@AssingedDimVacDays AND GRADEID=@Grade 
	SET @DCNUMFILED='dcNum'+convert(Varchar,@COMPONENTIDSNO)
	
	SELECT @SYCOLNAME=SYSCOLUMNNAME FROM  adm_costcenterdef where costcenterid=40054 AND USERCOLUMNNAME =@DCNUMFILED
	SET @SYCOLNAME=REPLACE(@SYCOLNAME,'dcNum','dcCalcNum')
	
	SET @STRQRY='INSERT INTO #VACDAYTAB 
					SELECT  SUM('+ @SYCOLNAME +')  FROM INV_DOCDETAILS ID WITH(NOLOCK) JOIN PAY_DOCNUMDATA DN WITH(NOLOCK) ON ID.INVDOCDETAILSID=DN.INVDOCDETAILSID JOIN COM_DOCCCDATA CC  WITH(NOLOCK) ON ID.INVDOCDETAILSID=CC.INVDOCDETAILSID
					WHERE   CC.DCCCNID51='+ CONVERT(Varchar,@EmpNode) +' AND ID.COSTCENTERID=40054 AND CONVERT(DateTime,ID.DOCDATE) BETWEEN '''+ convert(Varchar,@VACATIONSTARTMONTH) +''' and '''+ convert(Varchar,@DATE)+''''
--	PRINT (@STRQRY)
	EXEC sp_executesql @STRQRY
	
	SELECT @DimVacDays=ISNULL(VACDAYS,0) FROM #VACDAYTAB
	DROP TABLE #VACDAYTAB
	
	--
	--IF @DimVacDays>0
	--BEGIN
	--	SET @MonthlyNoofDays= ROUND((CAST(@DimVacDays AS FLOAT)/ CAST(12 AS FLOAT)),2,1)
	--END

	declare @VMD FLOAT,@VSM DATETIME
	SET @VSM=@ActDOJ
	--VACATION MONTHS DIFFERENCE
	SET @VMD=DATEDIFF(MONTH,@VSM,DATEADD(DAY,0,@DATE))

	IF ISNULL(@DimVacDays,0)>0
	BEGIN
		SET @MonthlyNoofDays= ROUND((CAST(@DimVacDays AS FLOAT)/ CAST(12 AS FLOAT)),2,1)
	END
	ELSE IF ISNULL(@DimVacDays,0)=0 AND @VMD<=6
	BEGIN
		SET @MonthlyNoofDays=@BelowSixmonthsDays
	END
	ELSE IF ISNULL(@DimVacDays,0)=0 AND @VMD>6 And @VMD<=12 
	BEGIN
		SET @MonthlyNoofDays=@BelowOneyearDays
	END
	ELSE
	BEGIN
		IF @VACDAYSPERIOD='Yearly'
		BEGIN
			SET @TMONTHS=12
		END
		ELSE
		BEGIN
			SET @TMONTHS=1
		END
		SET @MonthlyNoofDays= ROUND((CAST(@VACDAYSPERMONTH AS FLOAT)/CAST(@TMONTHS AS FLOAT)),2,1)
	END							
END
ELSE
BEGIN
	--DATE OF JOINING
	print 'DOJ'
	SET   @VACATIONSTARTMONTH=@ActDOJ
	SET @TMP=0
	--VACATION MONTHS DIFFERENCE
	SET @VacationMonthsDiff=DATEDIFF(MONTH,@VACATIONSTARTMONTH,DATEADD(DAY,0,@DATE))
	
	--GET VACDAYS FROM MONTHLY PAYROLL
	select @COMPONENTIDSNO=SNO from COM_CC50054 WHERE COMPONENTID=@AssingedDimVacDays AND GRADEID=@Grade 
	SET @DCNUMFILED='dcNum'+convert(Varchar,@COMPONENTIDSNO)

	SELECT @SYCOLNAME=SYSCOLUMNNAME FROM  adm_costcenterdef where costcenterid=40054 AND USERCOLUMNNAME =@DCNUMFILED
	SET @SYCOLNAME=REPLACE(@SYCOLNAME,'dcNum','dcCalcNum')

	SET @STRQRY='INSERT INTO #VACDAYTAB 
						SELECT  SUM('+ @SYCOLNAME +')  FROM INV_DOCDETAILS ID WITH(NOLOCK) JOIN PAY_DOCNUMDATA DN WITH(NOLOCK) ON ID.INVDOCDETAILSID=DN.INVDOCDETAILSID JOIN COM_DOCCCDATA CC  WITH(NOLOCK) ON ID.INVDOCDETAILSID=CC.INVDOCDETAILSID
						WHERE   CC.DCCCNID51='+ CONVERT(Varchar,@EmpNode) +' AND ID.COSTCENTERID=40054 AND CONVERT(DateTime,ID.DOCDATE) BETWEEN '''+ convert(Varchar,@VACATIONSTARTMONTH) +''' and '''+ convert(Varchar,@DATE)+''''
	PRINT (@STRQRY)
	EXEC sp_executesql @STRQRY
	SELECT @DimVacDays=ISNULL(VACDAYS,0) FROM #VACDAYTAB
	DROP TABLE #VACDAYTAB
	PRINT @DimVacDays
	
	PRINT @VACDAYSPERMONTH
	--PICKING THE PERMONTH VACDAYS FROM PREFERENCES
	IF @DimVacDays>0
	BEGIN
		SET @MonthlyNoofDays= ROUND((CAST(@DimVacDays AS FLOAT)/CAST(12 AS FLOAT)),2,1)
	END
	ELSE IF @VacationMonthsDiff<=6
	BEGIN
		SET @MonthlyNoofDays=@BelowSixMonthsDays
	END
	ELSE IF @VacationMonthsDiff>6 And @VacationMonthsDiff<=12 
	BEGIN
		SET @MonthlyNoofDays=@BelowOneYearDays
	END
	ELSE
	BEGIN
		IF @VACDAYSPERIOD='Yearly'
		BEGIN
			SET @TMONTHS=12
		END
		ELSE
		BEGIN
			SET @TMONTHS=1
		END
		SET @MonthlyNoofDays=@VACDAYSPERMONTH/@TMONTHS
	END
END							
--END : CHECKING THE PREVIOUS VACATION DETAILS OF EMPLOYEE IF NO RECORD FOUND THEN SELECT DOJ	

	IF(CONVERT(DateTime,@OPLeavesAsOn)<>'Jan  1 1900 12:00AM' AND @TMP=0 )
		SET @VacationStartMonth=@DOJ

	SET @VacationMonthsDiff=DATEDIFF(MONTH,@VACATIONSTARTMONTH,DATEADD(DAY,0,@DATE))

--START : CALCULATING PER MONTH DAYS
Declare @RC1 Int,@MONT1 DateTime,@MONT2 DateTime,@ActualVacDate DateTime 
--SET @ActualVacDate=(SELECT TOP 1 CONVERT(DATETIME,TD.DCALPHA2) FROM INV_DOCDETAILS ID WITH(NOLOCK) JOIN COM_DOCTEXTDATA TD WITH(NOLOCK) ON ID.INVDOCDETAILSID=TD.INVDOCDETAILSID JOIN COM_DOCCCDATA CC  WITH(NOLOCK) ON ID.INVDOCDETAILSID=CC.INVDOCDETAILSID
--					WHERE  CC.DCCCNID51=@EmpNode AND ID.COSTCENTERID=40072 AND ID.STATUSID NOT IN (372,376) AND ISDATE(TD.DCALPHA2)=1 AND CONVERT(DATETIME,TD.DCALPHA2)>=CONVERT(DATETIME,@DATE))
--select @ActualVacDate
IF (ISNULL(@ActualVacDate,'')='')
	SET @ActualVacDate=DATEADD(D,-1,@DATE)--CONVERT(DATETIME,@DATE)


	SELECT a.InvDocDetailsID,d.dcAlpha2,d.dcAlpha3,b.dcCCNID51 INTO #TBL3
				FROM INV_DocDetails a WITH(NOLOCK) 
				JOIN COM_DocCCData b WITH(NOLOCK) ON b.InvDocDetailsID=a.InvDocDetailsID
				JOIN COM_DocTextData d WITH(NOLOCK) ON d.InvDocDetailsID=a.InvDocDetailsID
				WHERE  a.CostCenterID=40072 and a.StatusID=369

PRINT 'AD'
PRINT @ActualVacDate
PRINT @VACATIONSTARTMONTH
PRINT @VacationMonthsDiff
DECLARE @LOPDAYS FLOAT
DECLARE @VACPERIODDAYS FLOAT
SET @RC1=0
WHILE(@RC1<=@VacationMonthsDiff)
BEGIN
	IF (@RC1=0)
	BEGIN
		SET @MONT1=DATEADD(MONTH,@RC1,@VACATIONSTARTMONTH)
		IF (@AccrueVacationDaysPref='False')
		BEGIN
			IF (@VacationMonthsDiff=0)
			BEGIN
				SET @MONT2=DATEADD(D,-1,@VACATIONSTARTMONTH)
				IF(@MONT2<@MONT1)
					SET @MONT2=DATEADD(D,0,DATEADD(D,-1,DATEADD(MM,DATEDIFF(M,0,@VacationStartMonth)+1,0)))
			END
			ELSE
				SET @MONT2=DATEADD(D,0,DATEADD(D,-1,DATEADD(MM,DATEDIFF(M,0,@VacationStartMonth)+1,0)))
		END					
		ELSE
		BEGIN
			SET @MONT2=DATEADD(D,0,DATEADD(D,-1,DATEADD(MM,DATEDIFF(M,0,@MONT1)+1,0)))
		END

		--select @VACATIONSTARTMONTH,@MONT1,@MONT2

	END
	ELSE IF (@RC1=@VacationMonthsDiff)
	BEGIN
		SET @MONT1=DATEADD(MONTH,@RC1,DATEADD(M,DATEDIFF(M,0,@VACATIONSTARTMONTH),0))
		IF (@AccrueVacationDaysPref='False')
		BEGIN
			IF(CONVERT(DATETIME,@ActualVacDate)<CONVERT(DATETIME,@DATE))
			BEGIN
				IF(@Flag=1 OR @Flag=2)
				SET @MONT2=@DATE
				ELSE
				SET @MONT2=DATEADD(D,-1,@DATE)
			END
			ELSE
			BEGIN
			SET @MONT2=DATEADD(D,-1,@ActualVacDate)
			END
		END
		ELSE
		BEGIN
			SET @MONT2=DATEADD(D,0,DATEADD(D,-1,DATEADD(MM,DATEDIFF(M,0,@ActualVacDate)+1,0)))

		END
	END
	ELSE
	BEGIN

		SET @MONT1=DATEADD(MONTH,@RC1,DATEADD(M,DATEDIFF(M,0,@VACATIONSTARTMONTH),0))
		IF (@AccrueVacationDaysPref='False')
			SET @MONT2=DATEADD(D,-1,DATEADD(MM,DATEDIFF(M,0,@MONT1)+1,0))
		ELSE
			SET @MONT2=DATEADD(D,0,DATEADD(D,-1,DATEADD(MM,DATEDIFF(M,0,@MONT1)+1,0)))
			

	END

	
---------------------------------------------------

	IF EXISTS ( 
				SELECT InvDocDetailsID
				FROM #TBL3
				WHERE  dcCCNID51=@Empnode 
				AND ISDATE(dcAlpha2)=1 AND ISDATE(dcAlpha3)=1 
				--AND LEN(ISNULL(d.dcAlpha2,''))<=30 AND LEN(ISNULL(d.dcAlpha3,''))<=30
				AND ( @MONT1 BETWEEN CONVERT(DATETIME,dcAlpha2) AND CONVERT(DATETIME,dcAlpha3) OR 
						@MONT2 BETWEEN CONVERT(DATETIME,dcAlpha2) AND CONVERT(DATETIME,dcAlpha3) OR 
						CONVERT(DATETIME,dcAlpha2) BETWEEN  @MONT1 AND  @MONT2 OR 
						CONVERT(DATETIME,dcAlpha3) BETWEEN  @MONT1 AND  @MONT2 
					)
				)
				BEGIN
				
					--if(MONTH(@MONT1)=2 AND YEAR(@MONT1)=2020)
					--select @MONT1,@MONT2,@Empnode,1,1,0
					EXEC spPAY_GetVacationLeavesInfoNew @MONT1,@MONT2,@Empnode,1,1,0,@LEAVESTAKEN OUTPUT,@LeavesTakenEncash OUTPUT
				END
				ELSE
				BEGIN
					SET @LEAVESTAKEN=0 SET @LeavesTakenEncash=0
				END
				
				SET @LeavesTakenEncashSUM=@LeavesTakenEncashSUM+@LeavesTakenEncash
				
---------------------------------------------------
	SET @LOPDAYS=0
	IF(@ConsiderLOPwhilecalculatingCreditdays='Yes')
	BEGIN
		SELECT @LOPDAYS=ISNULL(TD.DCALPHA9,'0')  FROM INV_DOCDETAILS ID WITH(NOLOCK) JOIN COM_DOCTEXTDATA TD WITH(NOLOCK) ON ID.INVDOCDETAILSID=TD.INVDOCDETAILSID
			JOIN COM_DOCCCDATA CC ON ID.INVDOCDETAILSID=CC.INVDOCDETAILSID
			WHERE COSTCENTERID=40054 AND ID.VOUCHERTYPE=11 AND CC.DCCCNID51=@Empnode AND ISDATE(DCALPHA17)=1 AND CONVERT(DATETIME,DCALPHA17)=CONVERT(DATETIME,@MONT1) AND ISDATE(DCALPHA18)=1 AND CONVERT(DATETIME,DCALPHA18)=CONVERT(DATETIME,@MONT2) 
	END
 
	IF(@CalculateVacDayforVacationPeriod='Yes')
		INSERT INTO @MonthDays VALUES(@MONT1,@MONT2,DATEDIFF(D,DATEADD(MONTH,0,DATEADD(M,DATEDIFF(M,0,@MONT1),0)),DATEADD(D,-1,DATEADD(MM,DATEDIFF(M,0,@MONT2)+1,0)))+1,((DATEDIFF(D,@MONT1,@MONT2)+1)-ISNULL(@LOPDAYS,0)),0,ISNULL(@LEAVESTAKEN,0),ISNULL(@LOPDAYS,0))
	ELSE
		INSERT INTO @MonthDays VALUES(@MONT1,@MONT2,DATEDIFF(D,DATEADD(MONTH,0,DATEADD(M,DATEDIFF(M,0,@MONT1),0)),DATEADD(D,-1,DATEADD(MM,DATEDIFF(M,0,@MONT2)+1,0)))+1,(((DATEDIFF(D,@MONT1,@MONT2)+1)-ISNULL(@LOPDAYS,0))-ISNULL(@LEAVESTAKEN,0)),0,ISNULL(@LEAVESTAKEN,0),ISNULL(@LOPDAYS,0))
		
SET @RC1=@RC1+1
END


IF(@CreditDaysCalculation=1)
BEGIN
	--((VacDaysPerMonth*MonthDaysToConsider)/TotalMonthDays)
	IF(@IsDefineDaysExists=1)
	BEGIN
		UPDATE @MonthDays 
		SET Days= ROUND((( CAST((Select ISNULL(AllotedDays,0) From #VacMonthWiseAllotedDays WHERE MONTH(VacMonth)=MONTH(FDATE) AND YEAR(VacMonth)=YEAR(FDATE)) AS FLOAT) * CAST(ACTUALDAYS AS FLOAT) )/ CAST(TOTALDAYS AS FLOAT) ),2,1)		
		WHERE TOTALDAYS>0
	END
	ELSE
	BEGIN		
		UPDATE @MonthDays SET Days= (( CAST(ACTUALDAYS AS FLOAT) * CAST(@MonthlyNoofDays AS FLOAT) )/ CAST(TOTALDAYS AS FLOAT) ) where TOTALDAYS>0
	END
END
ELSE
BEGIN
	--((VacDaysPerYear/365)*MonthDaysToConsider)
	IF(@IsDefineDaysExists=1)
	BEGIN
		UPDATE @MonthDays SET Days=(( CAST((Select ISNULL(Yearly,0) From #VacMonthWiseAllotedDays WHERE MONTH(VacMonth)=MONTH(FDATE) AND YEAR(VacMonth)=YEAR(FDATE)) AS FLOAT) / CAST(365 AS FLOAT) )* CAST(ACTUALDAYS AS FLOAT) )
	END
	ELSE
	BEGIN
		UPDATE @MonthDays SET Days=(( CAST(@VacDaysPerMonth AS FLOAT) / CAST(365 AS FLOAT) )* CAST(ACTUALDAYS AS FLOAT) )
	END
END


--CHECKING PREFERENCE VACATION DAYS UPTO LAST MONTH
IF (@CALCVACDAYSUPTOLASTMONTH='False')
	SELECT  @TotalDays=SUM(Days-LeavesTaken) FROM @MonthDays
ELSE
	SELECT  @TotalDays=SUM(Days-LeavesTaken) FROM @MonthDays WHERE CONVERT(DateTime,FDATE)<DATEADD(MONTH,DATEDIFF(MONTH,0,CONVERT(DateTime,@DATE)),0)--CONVERT(DateTime,FDATE)<>CONVERT(DateTime,@DATE)
--END : CALCULATING PER MONTH DAYS

--START:CHECKING FOR VACATION APPLIED DAYS AND RETURN FROM VACATION
IF ((SELECT count(*)  FROM INV_DOCDETAILS ID WITH(NOLOCK) JOIN COM_DOCTEXTDATA TD WITH(NOLOCK) ON ID.INVDOCDETAILSID=TD.INVDOCDETAILSID JOIN COM_DOCCCDATA CC  WITH(NOLOCK) ON ID.INVDOCDETAILSID=CC.INVDOCDETAILSID
	 WHERE  CC.DCCCNID51=@EmpNode AND ID.COSTCENTERID=40072 AND isnull(TD.DCALPHA16,'')='No' AND ISNULL(TD.DCALPHA2,'')<>'' AND ISNULL(TD.DCALPHA3,'')<>'' AND ISNULL(TD.DCALPHA1,'')<>'')>0)
BEGIN
	 SELECT top 1 @DocMonth=convert(datetime,dcAlpha2) FROM INV_DOCDETAILS ID WITH(NOLOCK) JOIN COM_DOCTEXTDATA TD WITH(NOLOCK) ON ID.INVDOCDETAILSID=TD.INVDOCDETAILSID JOIN COM_DOCCCDATA CC  WITH(NOLOCK) ON ID.INVDOCDETAILSID=CC.INVDOCDETAILSID
	 WHERE  CC.DCCCNID51=@EmpNode AND ID.COSTCENTERID=40072 AND isnull(TD.DCALPHA16,'')='No' AND ISNULL(TD.DCALPHA2,'')<>'' AND ISNULL(TD.DCALPHA3,'')<>'' AND ISNULL(TD.DCALPHA1,'')<>''	 AND ID.DOCID = (SELECT TOP 1 DOCID FROM INV_DOCDETAILS INV WITH(NOLOCK) JOIN COM_DOCCCDATA DC  WITH(NOLOCK) ON INV.INVDOCDETAILSID=DC.INVDOCDETAILSID WHERE INV.COSTCENTERID=40072 AND DC.DCCCNID51=@EmpNode ORDER BY INV.DOCID)
	 PRINT 'DM'
	 PRINT @DocMonth
	 IF(@DocMonth=@DATE)
	 BEGIN
		--SELECT TOP 1 @OPVACATIONDAYS=CONVERT(FLOAT,ISNULL(dcAlpha22,0))+CONVERT(FLOAT,ISNULL(dcAlpha7,0)),@OPVACATIONSALARY=0 FROM INV_DOCDETAILS ID WITH(NOLOCK) JOIN COM_DOCTEXTDATA TD WITH(NOLOCK) ON ID.INVDOCDETAILSID=TD.INVDOCDETAILSID JOIN COM_DOCCCDATA CC  WITH(NOLOCK) ON ID.INVDOCDETAILSID=CC.INVDOCDETAILSID
		--WHERE  CC.DCCCNID51=@EmpNode AND ID.COSTCENTERID=40072 AND ISNULL(TD.DCALPHA2,'')<>'' AND ISNULL(TD.DCALPHA3,'')<>'' AND ISNULL(TD.DCALPHA1,'')<>'' 
		--ORDER BY CONVERT(DateTime,ID.DOCDATE) DESC
			SELECT @OPVACATIONDAYS=ISNULL(OPVACATIONDAYS,0),@OPVACATIONSALARY=0 FROM COM_CC50051 WITH(NOLOCK) WHERE NODEID=@EmpNode

	 END
	 ELSE
	 BEGIN
		--SELECT TOP 1 @OPVACATIONDAYS=ISNULL(dcAlpha12,0),@OPVACATIONSALARY=0 FROM INV_DOCDETAILS ID WITH(NOLOCK) JOIN COM_DOCTEXTDATA TD WITH(NOLOCK) ON ID.INVDOCDETAILSID=TD.INVDOCDETAILSID JOIN COM_DOCCCDATA CC  WITH(NOLOCK) ON ID.INVDOCDETAILSID=CC.INVDOCDETAILSID
		--WHERE  CC.DCCCNID51=@EmpNode AND ID.COSTCENTERID=40072 AND ISNULL(TD.DCALPHA2,'')<>'' AND ISNULL(TD.DCALPHA3,'')<>'' AND ISNULL(TD.DCALPHA1,'')<>'' 
		--ORDER BY CONVERT(DateTime,ID.DOCDATE) DESC
		SELECT @OPVACATIONDAYS=ISNULL(OPVACATIONDAYS,0),@OPVACATIONSALARY=0 FROM COM_CC50051 WITH(NOLOCK) WHERE NODEID=@EmpNode
	END
END
--CHECKING FOR VACATION APPLIED AS ENCASH
ELSE IF ((SELECT count(*)  FROM INV_DOCDETAILS ID WITH(NOLOCK) JOIN COM_DOCTEXTDATA TD WITH(NOLOCK) ON ID.INVDOCDETAILSID=TD.INVDOCDETAILSID JOIN COM_DOCCCDATA CC  WITH(NOLOCK) ON ID.INVDOCDETAILSID=CC.INVDOCDETAILSID
		  WHERE  CC.DCCCNID51=@EmpNode AND ID.COSTCENTERID=40072 AND isnull(TD.DCALPHA16,'')='Yes')>0)
BEGIN
--@OPVACATIONDAYS=isnull((convert(decimal(9,2),dcAlpha12)-convert(decimal(9,2),dcAlpha14)),0) 
	--SELECT TOP 1 @OPVACATIONSALARY=0 FROM INV_DOCDETAILS ID WITH(NOLOCK) JOIN COM_DOCTEXTDATA TD WITH(NOLOCK) ON ID.INVDOCDETAILSID=TD.INVDOCDETAILSID JOIN COM_DOCCCDATA CC  WITH(NOLOCK) ON ID.INVDOCDETAILSID=CC.INVDOCDETAILSID
	--WHERE  CC.DCCCNID51=@EmpNode AND ID.COSTCENTERID=40072 AND isnull(TD.DCALPHA16,'')='Yes' ORDER BY CONVERT(DateTime,ID.DOCDATE) DESC
	SELECT @OPVACATIONDAYS=ISNULL(OPVACATIONDAYS,0), @OPVACATIONSALARY=0 FROM COM_CC50051 WITH(NOLOCK) WHERE NODEID=@EmpNode
END
ELSE
BEGIN
	SELECT @OPVACATIONDAYS=ISNULL(OPVACATIONDAYS,0),@OPVACATIONSALARY=ISNULL(OPVACATIONSALARY,0) FROM COM_CC50051 WITH(NOLOCK) WHERE NODEID=@EmpNode
END	 	
PRINT 'OPVACATIONDAYS'
PRINT @OPVACATIONDAYS
--END:CHECKING FOR VACATION APPLIED DAYS AND RETURN FROM VACATION

--SELECT LeaveTypeNode as LeaveType,0 as CreditedDays,0 as OPBalOrRemainingDays,0 as EncashedDays,AvlblLeaves as AvlblDays from @TabLeaveTypes
--UNION
--SELECT @AssingedLeaveType as LeaveType,Round(isnull(@TotalDays,0),2) CreditedDays,ISNULL(@OPVACATIONDAYS,0) as OPBalOrRemainingDays,@LeavesTakenEncashSUM, Round(ISNULL(@OPVACATIONDAYS,0)+isnull(@TotalDays,0)-isnull(@LeavesTakenEncashSUM,0),2) AS AvlblDays

	SELECT FDATE,TDATE,TOTALDAYS,ACTUALDAYS,DAYS,LEAVESTAKEN,LOPDAYS,@LeavesTakenEncashSUM LeavesTakenEncashSUM FROM @MonthDays

DROP TABLE #VMDD
DROP TABLE #VacMonthWiseAllotedDays
DROP TABLE #TBL3

SET NOCOUNT OFF;
END
GO
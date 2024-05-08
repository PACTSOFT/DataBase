﻿USE PACT2C222
GO
SET ANSI_NULLS, QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spPAY_ExtGetCompensatoryLeaveDates]
	@FromDate [nvarchar](25) = null,
	@EmployeeID [int] = 0,
	@userid [int] = 1,
	@langid [int] = 1
WITH ENCRYPTION, EXECUTE AS CALLER
AS
BEGIN
SET NOCOUNT ON;
DECLARE @NOOFHOLIDAYS INT,@WEEKLYOFFCOUNT INT
DECLARE @CurrYearLeavestaken DECIMAL(9,2),@LEAVETYPEGP INT,@LEAVETYPENAMEGP VARCHAR(50),@LEAVETYPENODEIDGP VARCHAR(50)
DECLARE @LocID INT,@PayrollDate DATETIME,@Compensatoryanyday VARCHAR(5)

	DECLARE @FDATE DATETIME,@TDATE DATETIME,@ToDate DATETIME

	DECLARE @MONTH111 DATETIME,@MONTH222 DATETIME
	DECLARE @MONTH13 DATETIME,@MONTH14 DATETIME

	DECLARE @MONTH1 DATETIME,@MONTH2 DATETIME,@MONTH3 DATETIME,@MONTH4 DATETIME,@MONTH5 DATETIME,@MONTH6 DATETIME
	DECLARE @MONTH7 DATETIME,@MONTH8 DATETIME,@MONTH9 DATETIME,@MONTH10 DATETIME,@MONTH11 DATETIME,@MONTH12 DATETIME
	DECLARE @YEARDIFF INT,@YC INT
	DECLARE @Year INT,@ALStartMonth INT
	DECLARE @ALStartMonthYear DATETIME,@ALEndMonthYear DATETIME
	DECLARE @MONTHTAB TABLE(ID INT IDENTITY(1,1),STDATE DATETIME,EDDATE DATETIME)

--SET TO FIRST DAY FOR THE GIVEN DATE
SET @PayrollDate=DATEADD(MONTH,DATEDIFF(MONTH,0,CONVERT(DATETIME,@FromDate)),0)
IF((SELECT COUNT(CostCenterID) FROM ADM_CostCenterDef WITH(NOLOCK) WHERE CostCenterID=50051 and SysColumnName ='CCNID2' and IsColumnInUse=1 and UserProbableValues='H')>0)
	SELECT @LocID=HistoryNodeID FROM COM_HistoryDetails WITH(NOLOCK) WHERE NodeID=@EmployeeID AND CostCenterID=50051 AND HistoryCCID=50002 AND (FromDate<=CONVERT(FLOAT,CONVERT(DATETIME,@PayrollDate))) AND (ToDate>=CONVERT(FLOAT,CONVERT(DATETIME,@PayrollDate)) OR ToDate IS NULL)
ELSE
	SELECT @LocID=ISNULL(CC.CCNID2,1) FROM COM_CC50051 C51 WITH(NOLOCK),COM_CCCCDATA CC  WITH(NOLOCK) WHERE C51.NODEID=CC.NODEID AND C51.NODEID=@EmployeeID

	SET @ToDate=DATEADD(d,0,@FromDate)
	SELECT @YEARDIFF=DATEDIFF(yyyy,@FromDate,@ToDate)
	SET @YC=0
	
	--START:FOR START DATE AND END DATE OF LEAVE YEAR
	EXEC [spPAY_EXTGetLeaveyearDates] @FromDate,@ALStartMonthYear OUTPUT,@ALEndMonthYear OUTPUT

		IF ISNULL(@YEARDIFF,0)>2
		BEGIN
			SET @FDATE=@FromDate
			--START : LOADING MONTHS BASED ON GIVEN YEAR RANGE FROM FROMDATE AND TODATE
			WHILE(@YC<=@YEARDIFF)
			BEGIN
				SET @MONTH111 =dateadd(m,-2,@FDATE)
				SET @MONTH222 =DATEADD(D,-1,DATEADD(MM,DATEDIFF(M,0,@FDATE),0))
				----
				SET @MONTH1 =@FDATE
				SET @MONTH2 =DATEADD(D,-1,DATEADD(MM,DATEDIFF(M,0,@FDATE)+2,0))
				SET @MONTH3 = DATEADD(d,1,DATEADD(D,-1,DATEADD(MM,DATEDIFF(M,0,@FDATE)+2,0)))
				SET @MONTH4 =DATEADD(D,-1,DATEADD(MM,DATEDIFF(M,0,@FDATE)+4,0))
				SET @MONTH5 = DATEADD(d,1,DATEADD(D,-1,DATEADD(MM,DATEDIFF(M,0,@FDATE)+4,0)))
				SET @MONTH6 = DATEADD(D,-1,DATEADD(MM,DATEDIFF(M,0,@FDATE)+6,0))
				SET @MONTH7 = DATEADD(d,1,DATEADD(D,-1,DATEADD(MM,DATEDIFF(M,0,@FDATE)+6,0)))
				SET @MONTH8 = DATEADD(D,-1,DATEADD(MM,DATEDIFF(M,0,@FDATE)+8,0))
				SET @MONTH9 = DATEADD(d,1,DATEADD(D,-1,DATEADD(MM,DATEDIFF(M,0,@FDATE)+8,0)))
				SET @MONTH10 = DATEADD(D,-1,DATEADD(MM,DATEDIFF(M,0,@FDATE)+10,0))
				SET @MONTH11 = DATEADD(d,1,DATEADD(D,-1,DATEADD(MM,DATEDIFF(M,0,@FDATE)+10,0)))
				SET @MONTH12 = DATEADD(D,-1,DATEADD(MM,DATEDIFF(M,0,@FDATE)+12,0))

				SET @MONTH13 = DATEADD(d,1,DATEADD(D,-1,DATEADD(MM,DATEDIFF(M,0,@FDATE)+12,0)))
				SET @MONTH14 = DATEADD(D,-1,DATEADD(MM,DATEDIFF(M,0,@FDATE)+14,0))
				

				INSERT INTO @MONTHTAB VALUES(@MONTH111,@MONTH222)

				INSERT INTO @MONTHTAB VALUES(@MONTH1,@MONTH2)
				INSERT INTO @MONTHTAB VALUES(@MONTH3,@MONTH4)
				INSERT INTO @MONTHTAB VALUES(@MONTH5,@MONTH6)
				INSERT INTO @MONTHTAB VALUES(@MONTH7,@MONTH8)
				INSERT INTO @MONTHTAB VALUES(@MONTH9,@MONTH10)
				INSERT INTO @MONTHTAB VALUES(@MONTH11,@MONTH12)
				
				INSERT INTO @MONTHTAB VALUES(@MONTH13,@MONTH14)

				SET @FDATE=DATEADD(YY,1,@FDATE)
			SET @YC=@YC+1
			END
			--END : LOADING MONTHS BASED ON GIVEN YEAR RANGE FROM FROMDATE AND TODATE
		END
		ELSE
		BEGIN
				--START : LOADING MONTHS BASED ON GIVEN DATE RANGE FROM FROMDATE AND TODATE

				SET @MONTH111 =dateadd(m,-2,@ALStartMonthYear)
				SET @MONTH222 =DATEADD(D,-1,DATEADD(MM,DATEDIFF(M,0,@ALStartMonthYear),0))

				SET @MONTH1 =@ALStartMonthYear
				SET @MONTH2 =DATEADD(D,-1,DATEADD(MM,DATEDIFF(M,0,@ALStartMonthYear)+2,0))
				SET @MONTH3 = DATEADD(d,1,DATEADD(D,-1,DATEADD(MM,DATEDIFF(M,0,@ALStartMonthYear)+2,0)))
				SET @MONTH4 =DATEADD(D,-1,DATEADD(MM,DATEDIFF(M,0,@ALStartMonthYear)+4,0))
				SET @MONTH5 = DATEADD(d,1,DATEADD(D,-1,DATEADD(MM,DATEDIFF(M,0,@ALStartMonthYear)+4,0)))
				SET @MONTH6 = DATEADD(D,-1,DATEADD(MM,DATEDIFF(M,0,@ALStartMonthYear)+6,0))
				SET @MONTH7 = DATEADD(d,1,DATEADD(D,-1,DATEADD(MM,DATEDIFF(M,0,@ALStartMonthYear)+6,0)))
				SET @MONTH8 = DATEADD(D,-1,DATEADD(MM,DATEDIFF(M,0,@ALStartMonthYear)+8,0))
				SET @MONTH9 = DATEADD(d,1,DATEADD(D,-1,DATEADD(MM,DATEDIFF(M,0,@ALStartMonthYear)+8,0)))
				SET @MONTH10 = DATEADD(D,-1,DATEADD(MM,DATEDIFF(M,0,@ALStartMonthYear)+10,0))
				SET @MONTH11 = DATEADD(d,1,DATEADD(D,-1,DATEADD(MM,DATEDIFF(M,0,@ALStartMonthYear)+10,0)))
				SET @MONTH12 = DATEADD(D,-1,DATEADD(MM,DATEDIFF(M,0,@ALStartMonthYear)+12,0))

				SET @MONTH13 = DATEADD(d,1,DATEADD(D,-1,DATEADD(MM,DATEDIFF(M,0,@ALStartMonthYear)+12,0)))
				SET @MONTH14 = DATEADD(D,-1,DATEADD(MM,DATEDIFF(M,0,@ALStartMonthYear)+14,0))
				
				INSERT INTO @MONTHTAB VALUES(@MONTH111,@MONTH222)

				INSERT INTO @MONTHTAB VALUES(@MONTH1,@MONTH2)
				INSERT INTO @MONTHTAB VALUES(@MONTH3,@MONTH4)
				INSERT INTO @MONTHTAB VALUES(@MONTH5,@MONTH6)
				INSERT INTO @MONTHTAB VALUES(@MONTH7,@MONTH8)
				INSERT INTO @MONTHTAB VALUES(@MONTH9,@MONTH10)
				INSERT INTO @MONTHTAB VALUES(@MONTH11,@MONTH12)

				INSERT INTO @MONTHTAB VALUES(@MONTH13,@MONTH14)
				--END : LOADING MONTHS BASED ON GIVEN DATE RANGE FROM FROMDATE AND TODATE
		END


--SELECT @LocID=ISNULL(CC.CCNID2,1) FROM COM_CC50051 C51 WITH(NOLOCK),COM_CCCCDATA CC  WITH(NOLOCK) WHERE C51.NODEID=CC.NODEID AND C51.NODEID=@EmployeeID
SELECT @Compensatoryanyday=ISNULL(VALUE,'') FROM ADM_GlobalPreferences WITH(NOLOCK) WHERE NAME='AllowCompensatoryonanyday'
SELECT @LEAVETYPEGP=ISNULL(VALUE,12) FROM ADM_GlobalPreferences WITH(NOLOCK) WHERE NAME='CompensatoryLeaveType'
SELECT @LEAVETYPENODEIDGP=NODEID,@LEAVETYPENAMEGP=NAME FROM COM_CC50052 WITH(NOLOCK) WHERE NODEID=@LEAVETYPEGP
IF (@Compensatoryanyday='True')
BEGIN
	SELECT 3 AS ISVALIDDAY,@LEAVETYPENAMEGP as DCCCNID52,@LEAVETYPENODEIDGP AS DCCCNID52_KEY	
END
ELSE
BEGIN
	IF(@FromDate is not null)
	BEGIN			
		--START WEEKLYOFF COUNT
		--LOADING WEEKLYOFF INFORMATION OF EMPLOYEE
		DECLARE @EMPWEEKLYOFF TABLE (WK11 varchar(50),WK12 varchar(50),WK21 varchar(50),WK22 varchar(50), WK31 varchar(50),
								   WK32 varchar(50),WK41 varchar(50),WK42 varchar(50),WK51 varchar(50),WK52 varchar(50))
		DECLARE @WEEKLYOFF TABLE (WEEKLYWEEKOFFNO int,DAYNAME varchar(100))										   
								   
		--LOADING DATA FROM WEEKLYOFF MASTER											   
		INSERT INTO @EMPWEEKLYOFF 
		SELECT TOP 1 TD.dcAlpha2 WK11,TD.dcAlpha3 WK12,TD.dcAlpha4 WK21,TD.dcAlpha5 WK22,TD.dcAlpha6 WK31,TD.dcAlpha7 WK32,TD.dcAlpha8 WK41,TD.dcAlpha9 WK42,
			         TD.dcAlpha10 WK51,TD.dcAlpha11 WK52	FROM COM_DocCCData DC WITH(NOLOCK),INV_DOCDETAILS ID WITH(NOLOCK),COM_DocTextData TD WITH(NOLOCK)
 		WHERE        DC.INVDOCDETAILSID=ID.INVDOCDETAILSID AND TD.INVDOCDETAILSID=ID.INVDOCDETAILSID AND ID.COSTCENTERID=40053 AND DC.dcCCNID51=@EmployeeID AND	
		  		     CONVERT(DATETIME,ID.DUEDATE)<=CONVERT(DATETIME,@FromDate)											
		ORDER BY     CONVERT(DATETIME,ID.DUEDATE) DESC
		
		--CHECKING FOR EMPLOYEE WEEKLY OFF COUNT FROM WEEKLYOFF MASTER IF NO DATA FOUND
		--LOADING DATA FROM EMPLOYEE MASTER
		IF (SELECT COUNT(*) FROM @EMPWEEKLYOFF)<=0
		BEGIN
			INSERT INTO @EMPWEEKLYOFF 
			SELECT WeeklyOff1,WeeklyOff2,WeeklyOff1,WeeklyOff2,WeeklyOff1,WeeklyOff2,WeeklyOff1,WeeklyOff2,
			       WeeklyOff1,WeeklyOff2	FROM COM_CC50051 WITH(NOLOCK)
			WHERE  NODEID=@EmployeeID
			DELETE FROM @EMPWEEKLYOFF WHERE ISNULL(WK11,'None')='None' OR ISNULL(WK11,'0')='0'
		END
		--CHECKING FOR EMPLOYEE WEEKLY OFF COUNT FROM EMPLOYEE MASTER IF NO DATA FOUND
		--LOADING DATA FROM PREFERENCES
		IF (SELECT COUNT(*) FROM @EMPWEEKLYOFF)<=0
		BEGIN
			INSERT INTO @WEEKLYOFF 
			SELECT case isnull(VALUE,'') when '' then 0 else 1 end,VALUE	FROM ADM_GlobalPreferences WITH(NOLOCK)  WHERE NAME='WeeklyOff1'
			UNION ALL
			SELECT case isnull(VALUE,'') when '' then 0 else 1 end,VALUE	FROM ADM_GlobalPreferences  WITH(NOLOCK) WHERE NAME='WeeklyOff2'
			UNION ALL
			SELECT case isnull(VALUE,'') when '' then 0 else 2 end,VALUE	FROM ADM_GlobalPreferences WITH(NOLOCK) WHERE NAME='WeeklyOff1'
			UNION ALL
			SELECT case isnull(VALUE,'') when '' then 0 else 2 end,VALUE	FROM ADM_GlobalPreferences WITH(NOLOCK) WHERE NAME='WeeklyOff2'					  
			UNION ALL
			SELECT case isnull(VALUE,'') when '' then 0 else 3 end,VALUE	FROM ADM_GlobalPreferences WITH(NOLOCK) WHERE NAME='WeeklyOff1'
			UNION ALL
			SELECT case isnull(VALUE,'') when '' then 0 else 3 end,VALUE	FROM ADM_GlobalPreferences WITH(NOLOCK) WHERE NAME='WeeklyOff2'					  
			UNION ALL
			SELECT case isnull(VALUE,'') when '' then 0 else 4 end,VALUE	FROM ADM_GlobalPreferences WITH(NOLOCK) WHERE NAME='WeeklyOff1'
			UNION ALL
			SELECT case isnull(VALUE,'') when '' then 0 else 4 end,VALUE	FROM ADM_GlobalPreferences WITH(NOLOCK) WHERE NAME='WeeklyOff2'					  
			UNION ALL
			SELECT case isnull(VALUE,'') when '' then 0 else 5 end,VALUE	FROM ADM_GlobalPreferences WITH(NOLOCK) WHERE NAME='WeeklyOff1'
			UNION ALL
			SELECT case isnull(VALUE,'') when '' then 0 else 5 end,VALUE	FROM ADM_GlobalPreferences WITH(NOLOCK) WHERE NAME='WeeklyOff2'		
		END
		--LOADING WEEKNO AND DAYNAME INTO ROWS FROM @EMPWEEKLYOFF TABLE (WEEKLYOFF AND EMPLOYEE MASTER)
		IF (SELECT COUNT(*) FROM @WEEKLYOFF)<=0
		BEGIN
			INSERT INTO @WEEKLYOFF
				select case isnull(WK11,'') when '' then 0 else 1 end,case isnull(WK11,'') when '' then '' else WK11 end FROM @EMPWEEKLYOFF
			UNION ALL
				select case isnull(WK12,'') when '' then 0 else 1 end,case isnull(WK12,'') when '' then '' else WK12 end FROM @EMPWEEKLYOFF
			UNION ALL
				select case isnull(WK21,'') when '' then 0 else 2 end,case isnull(WK21,'') when '' then '' else WK21 end FROM @EMPWEEKLYOFF
			UNION ALL
				select case isnull(WK22,'') when '' then 0 else 2 end,case isnull(WK22,'') when '' then '' else WK22 end FROM @EMPWEEKLYOFF
			UNION ALL
				select case isnull(WK31,'') when '' then 0 else 3 end,case isnull(WK31,'') when '' then '' else WK31 end FROM @EMPWEEKLYOFF
			UNION ALL
				select case isnull(WK32,'') when '' then 0 else 3 end,case isnull(WK32,'') when '' then '' else WK32 end FROM @EMPWEEKLYOFF
			UNION ALL
				select case isnull(WK41,'') when '' then 0 else 4 end,case isnull(WK41,'') when '' then '' else WK41 end FROM @EMPWEEKLYOFF
			UNION ALL
				select case isnull(WK42,'') when '' then 0 else 4 end,case isnull(WK42,'') when '' then '' else WK42 end FROM @EMPWEEKLYOFF
			UNION ALL
				select case isnull(WK51,'') when '' then 0 else 5 end,case isnull(WK51,'') when '' then '' else WK51 end FROM @EMPWEEKLYOFF
			UNION ALL
				select case isnull(WK52,'') when '' then 0 else 5 end,case isnull(WK52,'') when '' then '' else WK52 end FROM @EMPWEEKLYOFF
		END
		--START : LOADING WEEKDATE,DAYNAME AND WEEKNO FOR SELECTED DATERANGE
					DECLARE @WEEKOFFCOUNT TABLE (ID INT ,WEEKDATE DATETIME,DAYNAME VARCHAR(50),WEEKNO INT,ISVALIDDAY INT,REMARKS VARCHAR(1000))
				   	DECLARE @STARTDATE1 DATETIME,@ENDATE1 DATETIME
				   	DECLARE @MRC AS INT,@MC AS INT,@MID INT
				   	
				   	SET @MC=1
				   	SELECT @MRC=COUNT(*) FROM @MONTHTAB
					
				   	WHILE (@MC<=@MRC)
				   	BEGIN
				   		SELECT @STARTDATE1=CONVERT(DATETIME,STDATE),@ENDATE1=CONVERT(DATETIME,EDDATE) FROM @MONTHTAB WHERE ID=@MC	
						;WITH DATERANGE AS
						(
						SELECT @STARTDATE1 AS DT,1 AS ID
						UNION ALL
						SELECT DATEADD(DD,1,DT),DATERANGE.ID+1 FROM DATERANGE WHERE ID<=DATEDIFF("d",convert(datetime,@STARTDATE1),convert(datetime,@ENDATE1))
						)
			
						INSERT INTO @WEEKOFFCOUNT
						SELECT ROW_NUMBER() OVER (ORDER BY DT) AS ID,DT AS WEEKDATE,DATENAME(DW,DT) AS DAY,0,0,'' FROM DATERANGE	--WHERE (DATEPART(DW,DT)=1 OR DATEPART(DW,DT)=7)
						SET @MC=@MC+1
				   	END
		--END : LOADING WEEKDATE,DAYNAME AND WEEKNO FOR SELECTED DATERANGE	
		
		--START : UPDATING ISVALIDDAY FOR WEEKLYOFF AND HOLIDAY
			--UPDATING WEEKNO IN WEEKOFFCOUNT TABLE BASED ON WEEKDATE OF MONTH
			--UPDATE @WEEKOFFCOUNT SET WEEKNO=((datepart(day,WEEKDATE)-1)/7)+1
									--------------------
						declare @PMS int,@PME int
						select @PMS=Value From ADM_GlobalPreferences where name='PayDayStart'
						select @PME=Value From ADM_GlobalPreferences where name='PayDayEnd'

						declare @PS INT,@PE INT
						declare @wd datetime,@TSwd datetime,@TEwd datetime,@dme datetime
						declare @wno int
						set @wno=0
						select @TSwd=MIN(Weekdate),@TEwd=MAX(Weekdate) FROM @WEEKOFFCOUNT
						--SET @TSwd='01-Nov-2019' SET @TEwd='01-Dec-2019'
						WHILE(@TSwd<=@TEwd)
						BEGIN
							IF(DAY(@TSwd)=@PMS)
							BEGIN
								set @wno=1
								Update @WEEKOFFCOUNT SET WEEKNo=@wno WHERE WeekDate=@TSwd
								set @dme=dateadd(day,-1,dateadd(m,1,@TSwd))
								
								Update @WEEKOFFCOUNT SET WEEKNo=@wno 
								where WeekDate between @TSwd AND DATEADD(day,6,@TSwd)
								
								SET @TSwd=DATEADD(day,7,@TSwd)
								set @wno=@wno+1
							END
							ELSE
							BEGIN
								if(@wno=0)
									SET @TSwd=DATEADD(day,1,@TSwd)
								else
								begin
									IF(DAY(DATEADD(day,6,@TSwd))<=@PME)
									begin
										Update @WEEKOFFCOUNT SET WEEKNo=@wno 
										where WeekDate between @TSwd AND DATEADD(day,6,@TSwd)
										SET @TSwd=DATEADD(day,7,@TSwd)
										set @wno=@wno+1

										if(DATEADD(day,6,@TSwd)>@dme)
										BEGIN
											Update @WEEKOFFCOUNT SET WEEKNo=@wno 
											where WeekDate between @TSwd AND @dme
											SET @TSwd=DATEADD(day,1,@dme)
										END
										
									end
									else 
									begin
										Update @WEEKOFFCOUNT SET WEEKNo=@wno 
										where WeekDate between @TSwd AND @dme
										SET @TSwd=DATEADD(day,1,@dme)
									end
									
								end
							END	
							
						END 

						--------------------------
			
			--UPDATING ISVALIDDAY TO 1 IF WEEKNO AND DAYNAME IS WEEKLYOFF
			UPDATE WEEKOFFCOUNT SET WEEKOFFCOUNT.ISVALIDDAY=1,WEEKOFFCOUNT.REMARKS='Weeklyoff' FROM @WEEKOFFCOUNT WEEKOFFCOUNT inner join @WEEKLYOFF WEEKLYOFF on WEEKLYOFF.WEEKLYWEEKOFFNO=WEEKOFFCOUNT.WEEKNO AND upper(WEEKLYOFF.DAYNAME)=upper(WEEKOFFCOUNT.DAYNAME)
			--SELECT * FROM @WEEKOFFCOUNT
			--UPDATING ISVALIDDAY TO 2 IF DATEAPPLIEDRANGE DATE IS Holiday
			DECLARE @HOLIDAY TABLE(INVDOCDETAILID INT,DCALPHA1 DATETIME)
			IF EXISTS(SELECT SYSCOLUMNNAME FROM ADM_COSTCENTERDEF WITH(NOLOCK) WHERE COSTCENTERID=40051 AND ISCOLUMNINUSE=1 AND SYSCOLUMNNAME ='DCCCNID2')
			BEGIN
				INSERT INTO @HOLIDAY 
				SELECT TD.INVDOCDETAILSID,CONVERT(DATETIME,TD.DCALPHA1) FROM INV_DOCDETAILS ID WITH(NOLOCK) INNER JOIN COM_DocTextData TD WITH(NOLOCK) ON ID.INVDOCDETAILSID=TD.INVDOCDETAILSID
					   INNER JOIN COM_DocCCData CC WITH(NOLOCK) ON ID.INVDOCDETAILSID=CC.INVDOCDETAILSID
				WHERE  TD.tCostCenterID=40051 AND CC.DCCCNID2=@LocID AND ID.STATUSID=369
			END
			ELSE
			BEGIN
				INSERT INTO @HOLIDAY 
				SELECT TD.INVDOCDETAILSID,CONVERT(DATETIME,TD.DCALPHA1) FROM COM_DocTextData TD WITH(NOLOCK),INV_DOCDETAILS ID WITH(NOLOCK)
				WHERE  ID.INVDOCDETAILSID=TD.INVDOCDETAILSID AND TD.tCostCenterID=40051 AND ID.STATUSID=369
			END

			 UPDATE WEEKOFFCOUNT SET WEEKOFFCOUNT.ISVALIDDAY=2,WEEKOFFCOUNT.REMARKS='Holiday' FROM   @WEEKOFFCOUNT WEEKOFFCOUNT INNER JOIN @HOLIDAY HD on CONVERT(DATETIME,WEEKOFFCOUNT.WEEKDATE)=CONVERT(DATETIME,HD.DCALPHA1) AND CONVERT(DATETIME,@FromDate) = CONVERT(DATETIME,HD.DCALPHA1)
		 --END : UPDATING ISVALIDDAY FOR WEEKLYOFF AND HOLIDAY  	
		
				
		IF((SELECT COUNT(DocID) FROM COM_DOCTEXTDATA TD WITH(NOLOCK) JOIN INV_DOCDETAILS ID WITH(NOLOCK) ON ID.INVDOCDETAILSID=TD.INVDOCDETAILSID JOIN COM_DOCCCDATA DC WITH(NOLOCK) ON ID.INVDOCDETAILSID=DC.INVDOCDETAILSID
		WHERE TD.tCostCenterID=40059 AND  DC.DCCCNID51=@EmployeeID AND  ISDATE(TD.DCALPHA1)=1 and CONVERT(DATETIME,TD.DCALPHA1)=CONVERT(DATETIME,@FromDate))>0)
			SELECT 0 AS ISVALIDDAY,@LEAVETYPENAMEGP as DCCCNID52,@LEAVETYPENODEIDGP AS DCCCNID52_KEY from @WEEKOFFCOUNT
		ELSE
			SELECT ISNULL(ISVALIDDAY,0) AS ISVALIDDAY,@LEAVETYPENAMEGP as DCCCNID52,@LEAVETYPENODEIDGP AS DCCCNID52_KEY from @WEEKOFFCOUNT WHERE CONVERT(DATETIME,WEEKDATE)=CONVERT(DATETIME,@FromDate)
	END	
END
SET NOCOUNT OFF;		
END

----spPAY_ExtGetCompensatoryLeaveDates 
-- '11/Jul/2020'
-- ,'497'
-- ,1
-- ,1

--select * from COM_CC50051 where code='14-ps'
GO

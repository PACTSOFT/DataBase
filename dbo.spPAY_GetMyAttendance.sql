﻿USE PACT2C222
GO
SET ANSI_NULLS, QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spPAY_GetMyAttendance]
	@FROMDATE [datetime],
	@TODATE [datetime],
	@EmployeeID [int],
	@CostCenterID [int]
WITH ENCRYPTION, EXECUTE AS CALLER
AS
BEGIN
DECLARE @WEEKLYOFFCOUNT INT,@LocID INT,@DOJ DateTime,@ConsiderLOPBasedOn NVARCHAR(200),@LatesConfigBasedOn NVARCHAR(200)
DECLARE @ALStartMonthYear DATETIME,@ALEndMonthYear DATETIME,@PayrollDate DATETIME
DECLARE @DATESCOUNT TABLE (SNO INT IDENTITY(1,1),ID INT ,DATE1 DATETIME,DAYNAME VARCHAR(50),WEEKNO INT,COUNT INT,NOOFDAYS DECIMAL(9,2),FLAG INT,IncExc varchar(5),AttendanceType nvarchar(25),ColorName nvarchar(15),CHECKIN NVARCHAR(50),CHECKOUT NVARCHAR(50),TOTALTIME NVARCHAR(50),LATECHECKIN NVARCHAR(20),EARLYCHECKOUT NVARCHAR(20),InLocDetails nvarchar(max),OutLocDetails nvarchar(max))
DECLARE @RC INT,@TRC INT,@LEAVETYPE INT

SELECT @DOJ=CONVERT(DateTime,DOJ) FROM COM_CC50051 WHERE NODEID=@EmployeeID
SELECT @ConsiderLOPBasedOn=ISNULL(VALUE,'') FROM ADM_GlobalPreferences WITH(NOLOCK) WHERE Name='ConsiderLOPBasedOn'

EXEC [spPAY_EXTGetLeaveyearDates] @FROMDATE,@ALStartMonthYear OUTPUT,@ALEndMonthYear OUTPUT
SET @PayrollDate=DATEADD(MONTH,DATEDIFF(MONTH,0,CONVERT(DATETIME,@FROMDATE)),0)
IF((SELECT COUNT(*) FROM ADM_CostCenterDef WITH(NOLOCK) WHERE CostCenterID=50051 and SysColumnName ='CCNID2' and IsColumnInUse=1 and UserProbableValues='H')>0)
BEGIN
--SET  @LocID=(SELECT TOP 1 HistoryNodeID FROM COM_HistoryDetails WITH(NOLOCK) 
--						Where CostCenterID=50051 AND NodeID=718 AND HistoryCCID=50002
--						AND CONVERT(DATETIME,FromDate)<=CONVERT(DATETIME,@PayrollDate)
--						ORDER BY FromDate DESC )
	SELECT @LocID=HistoryNodeID FROM COM_HistoryDetails WITH(NOLOCK) WHERE NodeID=@EmployeeID AND CostCenterID=50051 AND HistoryCCID=50002 AND (CONVERT(DATETIME,FromDate)<=CONVERT(DATETIME,@PayrollDate)) AND (CONVERT(DATETIME,ToDate)>=CONVERT(DATETIME,@PayrollDate) OR ToDate IS NULL)
END	
IF(ISNULL(@LocID,'')='')
BEGIN
	SELECT @LocID=ISNULL(CC.CCNID2,1) FROM COM_CC50051 C51 WITH(NOLOCK),COM_CCCCDATA CC  WITH(NOLOCK) WHERE C51.NODEID=CC.NODEID AND C51.NODEID=@EmployeeID
END
--ELSE
--BEGIN
--	SELECT @LocID=ISNULL(CC.CCNID2,1) FROM COM_CC50051 C51 WITH(NOLOCK),COM_CCCCDATA CC  WITH(NOLOCK) WHERE C51.NODEID=CC.NODEID AND C51.NODEID=@EmployeeID
--END

			;WITH DATERANGE AS
			(
			SELECT @FROMDATE AS DT,1 AS ID
			UNION ALL
			SELECT DATEADD(DD,1,DT),DATERANGE.ID+1 FROM DATERANGE WHERE ID<=DATEDIFF("d",convert(varchar,@FROMDATE,101),convert(varchar,@TODATE,101))
			)
			
			INSERT INTO @DATESCOUNT
			SELECT ROW_NUMBER() OVER (ORDER BY DT) AS ID,DT AS WEEKDATE,DATENAME(DW,DT) AS DAY,0,0,0,0,'','Absent','','00:00','00:00','0','','','','' FROM DATERANGE	--WHERE (DATEPART(DW,DT)=1 OR DATEPART(DW,DT)=7)
			
		
			--FOR WEEKLYOFF
			DECLARE @STRQUERY NVARCHAR(MAX),@I INT,@J INT,@COLNAME VARCHAR(15)
			CREATE TABLE #EMPWEEKLYOFF (WK11 varchar(50),WK12 varchar(50),WK21 varchar(50),WK22 varchar(50), WK31 varchar(50),
									   WK32 varchar(50),WK41 varchar(50),WK42 varchar(50),WK51 varchar(50),WK52 varchar(50),WEFDATE DATETIME)
			CREATE TABLE #EMPWEEKLYOFF1 (WK11 varchar(50),WK12 varchar(50),WK21 varchar(50),WK22 varchar(50), WK31 varchar(50),
									   WK32 varchar(50),WK41 varchar(50),WK42 varchar(50),WK51 varchar(50),WK52 varchar(50),WEFDATE DATETIME)											   
			CREATE TABLE #WEEKLYOFF  (WEEKLYWEEKOFFNO int,DAYNAME varchar(100),WeekNo INT,WkDate DATETIME,WEFDATE DATETIME)										   
			CREATE TABLE #WEEKLYOFF1  (WEEKLYWEEKOFFNO int,DAYNAME varchar(100),WeekNo INT,WkDate DATETIME,WEFDATE DATETIME)										   
			SET @STRQUERY=''	   
									   
			INSERT INTO #EMPWEEKLYOFF 
			SELECT TOP 1 TD.dcAlpha2 WK11,TD.dcAlpha3 WK12,TD.dcAlpha4 WK21,TD.dcAlpha5 WK22,TD.dcAlpha6 WK31,TD.dcAlpha7 WK32,TD.dcAlpha8 WK41,TD.dcAlpha9 WK42,
				         TD.dcAlpha10 WK51,TD.dcAlpha11 WK52,CONVERT(DATETIME,ID.DUEDATE)	FROM COM_DocCCData DC WITH(NOLOCK),INV_DOCDETAILS ID WITH(NOLOCK),COM_DocTextData TD WITH(NOLOCK)
			WHERE        DC.INVDOCDETAILSID=ID.INVDOCDETAILSID AND TD.INVDOCDETAILSID=ID.INVDOCDETAILSID AND ID.COSTCENTERID=40053 AND DC.dcCCNID51=@EmployeeID	AND
			             --CONVERT(DATETIME,ID.DUEDATE)<=CONVERT(DATETIME,@FromDate)
			             CONVERT(DATETIME,ID.DUEDATE)>=CONVERT(DATETIME,@ALStartMonthYear) and CONVERT(DATETIME,ID.DUEDATE)<=CONVERT(DATETIME,@ALEndMonthYear)											
			ORDER BY     CONVERT(DATETIME,ID.DUEDATE) DESC
			
			IF (SELECT COUNT(*) FROM #EMPWEEKLYOFF)<=0
			BEGIN
				INSERT INTO #EMPWEEKLYOFF 
				SELECT WeeklyOff1,WeeklyOff2,WeeklyOff1,WeeklyOff2,WeeklyOff1,WeeklyOff2,WeeklyOff1,WeeklyOff2,
				       WeeklyOff1,WeeklyOff2,'01-01-1900'	FROM COM_CC50051 WITH(NOLOCK)
				WHERE  NODEID=@EmployeeID
				DELETE FROM #EMPWEEKLYOFF WHERE ISNULL(WK11,'None')='None' OR ISNULL(WK11,'0')='0'
				SET @I=1
				SET @STRQUERY=''
				WHILE(@I<=5)
				BEGIN
					SET @J=1
					WHILE(@J<=2)
					BEGIN
						SET @COLNAME='WK'+CONVERT(VARCHAR,@I)+CONVERT(VARCHAR,@J)
						SET @STRQUERY=@STRQUERY+' UPDATE #EMPWEEKLYOFF SET '+ @COLNAME +'='''' where '+ @COLNAME +'=''None'''
						
					SET @J=@J+1
					END
				SET @I=@I+1
				END
				EXEC sp_executesql @STRQUERY
			END
			ELSE
			BEGIN
				INSERT INTO #EMPWEEKLYOFF1  SELECT * FROM #EMPWEEKLYOFF
				IF (SELECT COUNT(*) FROM #EMPWEEKLYOFF1)>0
				BEGIN
					SET @I=1
					SET @STRQUERY=''
					WHILE(@I<=5)
					BEGIN
						SET @J=1
						WHILE(@J<=2)
						BEGIN
							SET @COLNAME='WK'+CONVERT(VARCHAR,@I)+CONVERT(VARCHAR,@J)
							SET @STRQUERY=@STRQUERY+' update #EMPWEEKLYOFF1 set '+ @COLNAME +'='''' where '+ @COLNAME +'=''None'''
							
						SET @J=@J+1
						END
					SET @I=@I+1
					END
					EXEC sp_executesql @STRQUERY
				END
				
				IF((SELECT COUNT(*) FROM COM_CC50051 WHERE NODEID=@EmployeeID AND (ISNULL(WeeklyOff1,'')<>'' AND ISNULL(WeeklyOff1,'None')<>'None') AND (ISNULL(WeeklyOff2,'')<>'' AND ISNULL(WeeklyOff2,'None')<>'None'))>0)
				BEGIN
					SET @I=1
					SET @STRQUERY=''
					WHILE(@I<=5)
					BEGIN
						SET @J=1
						WHILE(@J<=2)
						BEGIN
							SET @COLNAME='WK'+CONVERT(VARCHAR,@I)+CONVERT(VARCHAR,@J)
							SET @STRQUERY=@STRQUERY+' UPDATE #EMPWEEKLYOFF1 SET '+ @COLNAME +'=WeeklyOff'+CONVERT(VARCHAR,@J)+' FROM COM_CC50051 WITH(NOLOCK)	WHERE  NODEID='+CONVERT(VARCHAR,@EmployeeID) +' AND ISNULL('+ @COLNAME +','''')=''''  AND ISNULL(WeeklyOff'+CONVERT(VARCHAR,@J)+',''None'')<>''None'''
						SET @J=@J+1
						END
					SET @I=@I+1
					END
					EXEC sp_executesql @STRQUERY
				END
				ELSE
				BEGIN
					SET @I=1
					SET @STRQUERY=''
					WHILE(@I<=5)
					BEGIN
						SET @J=1
						WHILE(@J<=2)
						BEGIN
							SET @COLNAME='WK'+CONVERT(VARCHAR,@I)+CONVERT(VARCHAR,@J)
							SET @STRQUERY=@STRQUERY+' UPDATE #EMPWEEKLYOFF1 SET '+ @COLNAME +'=isnull(VALUE,'''') FROM ADM_GlobalPreferences WITH(NOLOCK)	WHERE  NAME=''WeeklyOff'+CONVERT(VARCHAR,@J)+''' AND ISNULL('+ @COLNAME +','''')=''''  AND ISNULL(VALUE,''None'')<>''None'''
						SET @J=@J+1
						END
					SET @I=@I+1
					END
					EXEC sp_executesql @STRQUERY
				END
			END
			
			IF (SELECT COUNT(*) FROM #EMPWEEKLYOFF)<=0
			BEGIN
				INSERT INTO #WEEKLYOFF 
				SELECT case isnull(VALUE,'') when '' then 0 else 1 end,VALUE, 0, null,'01-01-1900' FROM ADM_GlobalPreferences  WHERE NAME='WeeklyOff1'
				UNION ALL
				SELECT case isnull(VALUE,'') when '' then 0 else 1 end,VALUE, 0, null,'01-01-1900'	FROM ADM_GlobalPreferences  WHERE NAME='WeeklyOff2'
				UNION ALL
				SELECT case isnull(VALUE,'') when '' then 0 else 2 end,VALUE, 0, null,'01-01-1900'	FROM ADM_GlobalPreferences  WHERE NAME='WeeklyOff1'
				UNION ALL
				SELECT case isnull(VALUE,'') when '' then 0 else 2 end,VALUE, 0, null,'01-01-1900'	FROM ADM_GlobalPreferences  WHERE NAME='WeeklyOff2'					  
				UNION ALL
				SELECT case isnull(VALUE,'') when '' then 0 else 3 end,VALUE, 0, null,'01-01-1900'	FROM ADM_GlobalPreferences  WHERE NAME='WeeklyOff1'
				UNION ALL
				SELECT case isnull(VALUE,'') when '' then 0 else 3 end,VALUE, 0, null,'01-01-1900'	FROM ADM_GlobalPreferences  WHERE NAME='WeeklyOff2'					  
				UNION ALL
				SELECT case isnull(VALUE,'') when '' then 0 else 4 end,VALUE, 0, null,'01-01-1900'	FROM ADM_GlobalPreferences  WHERE NAME='WeeklyOff1'
				UNION ALL
				SELECT case isnull(VALUE,'') when '' then 0 else 4 end,VALUE, 0, null,'01-01-1900'	FROM ADM_GlobalPreferences  WHERE NAME='WeeklyOff2'					  
				UNION ALL
				SELECT case isnull(VALUE,'') when '' then 0 else 5 end,VALUE, 0, null,'01-01-1900'	FROM ADM_GlobalPreferences  WHERE NAME='WeeklyOff1'
				UNION ALL
				SELECT case isnull(VALUE,'') when '' then 0 else 5 end,VALUE, 0, null,'01-01-1900'	FROM ADM_GlobalPreferences  WHERE NAME='WeeklyOff2'		
			END
							
			IF (SELECT COUNT(*) FROM #WEEKLYOFF)<=0
			BEGIN
				INSERT INTO #WEEKLYOFF
					select case isnull(WK11,'') when '' then 0 else 1 end,case isnull(WK11,'') when '' then '' else WK11 end, 0, null,convert(Datetime,WEFDATE) FROM #EMPWEEKLYOFF 
				UNION ALL
					select case isnull(WK12,'') when '' then 0 else 1 end,case isnull(WK12,'') when '' then '' else WK12 end, 0, null,convert(Datetime,WEFDATE) FROM #EMPWEEKLYOFF 
				UNION ALL
					select case isnull(WK21,'') when '' then 0 else 2 end,case isnull(WK21,'') when '' then '' else WK21 end, 0, null,convert(Datetime,WEFDATE) FROM #EMPWEEKLYOFF 
				UNION ALL
					select case isnull(WK22,'') when '' then 0 else 2 end,case isnull(WK22,'') when '' then '' else WK22 end, 0, null,convert(Datetime,WEFDATE) FROM #EMPWEEKLYOFF 
				UNION ALL
					select case isnull(WK31,'') when '' then 0 else 3 end,case isnull(WK31,'') when '' then '' else WK31 end, 0, null,convert(Datetime,WEFDATE) FROM #EMPWEEKLYOFF 
				UNION ALL
					select case isnull(WK32,'') when '' then 0 else 3 end,case isnull(WK32,'') when '' then '' else WK32 end, 0, null,convert(Datetime,WEFDATE) FROM #EMPWEEKLYOFF 
				UNION ALL
					select case isnull(WK41,'') when '' then 0 else 4 end,case isnull(WK41,'') when '' then '' else WK41 end, 0, null,convert(Datetime,WEFDATE) FROM #EMPWEEKLYOFF 
				UNION ALL
					select case isnull(WK42,'') when '' then 0 else 4 end,case isnull(WK42,'') when '' then '' else WK42 end, 0, null,convert(Datetime,WEFDATE) FROM #EMPWEEKLYOFF 
				UNION ALL
					select case isnull(WK51,'') when '' then 0 else 5 end,case isnull(WK51,'') when '' then '' else WK51 end, 0, null,convert(Datetime,WEFDATE) FROM #EMPWEEKLYOFF 
				UNION ALL
					select case isnull(WK52,'') when '' then 0 else 5 end,case isnull(WK52,'') when '' then '' else WK52 end, 0, null,convert(Datetime,WEFDATE) FROM #EMPWEEKLYOFF 
			END
			IF((SELECT COUNT(*) FROM #EMPWEEKLYOFF1)>0)
			BEGIN	
				INSERT INTO #WEEKLYOFF1
					select case isnull(WK11,'') when '' then 0 else 1 end,case isnull(WK11,'') when '' then '' else WK11 end, 0, null,convert(Datetime,WEFDATE) FROM #EMPWEEKLYOFF1 
				UNION ALL
					select case isnull(WK12,'') when '' then 0 else 1 end,case isnull(WK12,'') when '' then '' else WK12 end, 0, null,convert(Datetime,WEFDATE) FROM #EMPWEEKLYOFF1
				UNION ALL
					select case isnull(WK21,'') when '' then 0 else 2 end,case isnull(WK21,'') when '' then '' else WK21 end, 0, null,convert(Datetime,WEFDATE) FROM #EMPWEEKLYOFF1 
				UNION ALL
					select case isnull(WK22,'') when '' then 0 else 2 end,case isnull(WK22,'') when '' then '' else WK22 end, 0, null,convert(Datetime,WEFDATE) FROM #EMPWEEKLYOFF1 
				UNION ALL
					select case isnull(WK31,'') when '' then 0 else 3 end,case isnull(WK31,'') when '' then '' else WK31 end, 0, null,convert(Datetime,WEFDATE) FROM #EMPWEEKLYOFF1 
				UNION ALL
					select case isnull(WK32,'') when '' then 0 else 3 end,case isnull(WK32,'') when '' then '' else WK32 end, 0, null,convert(Datetime,WEFDATE) FROM #EMPWEEKLYOFF1 
				UNION ALL
					select case isnull(WK41,'') when '' then 0 else 4 end,case isnull(WK41,'') when '' then '' else WK41 end, 0, null,convert(Datetime,WEFDATE) FROM #EMPWEEKLYOFF1 
				UNION ALL
					select case isnull(WK42,'') when '' then 0 else 4 end,case isnull(WK42,'') when '' then '' else WK42 end, 0, null,convert(Datetime,WEFDATE) FROM #EMPWEEKLYOFF1 
				UNION ALL
					select case isnull(WK51,'') when '' then 0 else 5 end,case isnull(WK51,'') when '' then '' else WK51 end, 0, null,convert(Datetime,WEFDATE) FROM #EMPWEEKLYOFF1 
				UNION ALL
					select case isnull(WK52,'') when '' then 0 else 5 end,case isnull(WK52,'') when '' then '' else WK52 end, 0, null,convert(Datetime,WEFDATE) FROM #EMPWEEKLYOFF1 
			END
			
			DECLARE @WEEKOFFCOUNT TABLE (ID INT ,WEEKDATE DATETIME,DAYNAME VARCHAR(50),WEEKNO INT,COUNT INT,WEEKNOMANUAL INT)
			DECLARE @STARTDATE DATETIME,@STARTDATE2 DATETIME,@ENDATE2 DATETIME
			DECLARE @MRC2 AS INT,@MC2 AS INT,@MID2 INT
			
				;WITH DATERANGE AS
				(
				SELECT @FROMDATE AS DT,1 AS ID
				UNION ALL
				SELECT DATEADD(DD,1,DT),DATERANGE.ID+1 FROM DATERANGE WHERE ID<=DATEDIFF("d",convert(varchar,@FROMDATE,101),convert(varchar,@TODATE,101))
				)
				
				INSERT INTO @WEEKOFFCOUNT
				SELECT ROW_NUMBER() OVER (ORDER BY DT) AS ID,DT AS WEEKDATE,DATENAME(DW,DT) AS DAY,0,0,0 FROM DATERANGE	--WHERE (DATEPART(DW,DT)=1 OR DATEPART(DW,DT)=7)
				
				UPDATE @WEEKOFFCOUNT SET WEEKNO=((datepart(day,WEEKDATE)-1)/7)+1
				
				UPDATE WEEKOFFCOUNT SET WEEKOFFCOUNT.count=1 FROM @WEEKOFFCOUNT WEEKOFFCOUNT inner join #WEEKLYOFF WEEKLYOFF on WEEKLYOFF.WEEKLYWEEKOFFNO=WEEKOFFCOUNT.WEEKNO AND upper(WEEKLYOFF.DAYNAME)=upper(WEEKOFFCOUNT.DAYNAME)
				 
				IF((select COUNT(*) from #WEEKLYOFF1)>0)
				BEGIN
					UPDATE WEEKOFFCOUNT SET WEEKOFFCOUNT.count=1 FROM @WEEKOFFCOUNT WEEKOFFCOUNT inner join #WEEKLYOFF1 WEEKLYOFF on WEEKLYOFF.WEEKLYWEEKOFFNO=WEEKOFFCOUNT.WEEKNO AND upper(WEEKLYOFF.DAYNAME)=upper(WEEKOFFCOUNT.DAYNAME)
						   AND convert(datetime,WEEKOFFCOUNT.weekdate)<=CONVERT(DATETIME,WEFDATE)
				END	
					 
			SELECT @WEEKLYOFFCOUNT=COUNT(*) FROM @WEEKOFFCOUNT WHERE COUNT=1 and convert(DATETIME,WEEKDATE) between CONVERT(DATETIME,@FROMDATE) and CONVERT(DATETIME,@TODATE)

			UPDATE DATESCOUNT SET DATESCOUNT.count=3,DATESCOUNT.AttendanceType='Weekly Off' FROM @WEEKOFFCOUNT WEEKOFFCOUNT inner join @DATESCOUNT DATESCOUNT on CONVERT(DATETIME,DATESCOUNT.date1)= CONVERT(DATETIME,WEEKOFFCOUNT.weekdate) and WEEKOFFCOUNT.count=1
			--FOR WEEKLYOFF
			
			--FOR HOLIDAYS
			IF EXISTS(SELECT SYSCOLUMNNAME FROM ADM_COSTCENTERDEF WITH(NOLOCK) WHERE COSTCENTERID=40051 AND ISCOLUMNINUSE=1 AND SYSCOLUMNNAME ='DCCCNID2')
			BEGIN
				UPDATE DATESCOUNT SET DATESCOUNT.count=4,DATESCOUNT.AttendanceType='Holiday' FROM @DATESCOUNT DATESCOUNT inner join COM_DocTextData TD on CONVERT(DATETIME,DATESCOUNT.DATE1)=CONVERT(DATETIME,TD.dcAlpha1)
				inner join INV_DOCDETAILS ID  on  ID.INVDOCDETAILSID=TD.INVDOCDETAILSID inner join COM_DocCCData CC  on  ID.INVDOCDETAILSID=CC.INVDOCDETAILSID
				and ISDATE(TD.dcAlpha1)=1 AND CC.DCCCNID2=@LocID AND ID.STATUSID=369 AND CONVERT(DATETIME,DATE1) = CONVERT(DATETIME,TD.dcAlpha1) AND ID.COSTCENTERID=40051
			END
			ELSE
			BEGIN
				 UPDATE DATESCOUNT SET DATESCOUNT.count=4,DATESCOUNT.AttendanceType='Holiday' FROM @DATESCOUNT DATESCOUNT inner join COM_DocTextData TD on CONVERT(DATETIME,DATESCOUNT.DATE1)=CONVERT(DATETIME,TD.dcAlpha1)
				 inner join INV_DOCDETAILS ID  on  ID.INVDOCDETAILSID=TD.INVDOCDETAILSID and ISDATE(TD.dcAlpha1)=1 AND ID.STATUSID=369 AND CONVERT(DATETIME,DATE1) = CONVERT(DATETIME,TD.dcAlpha1) AND ID.COSTCENTERID=40051
			END		
			--FOR HOLIDAYS
			
			--FOR PRESENT,ABSENT AND SINGLE PUNCH
			IF(@CostCenterID=40089)
			BEGIN
				DECLARE @TABATTENDANCE TABLE(ID INT IDENTITY(1,1),CHECKINDATE DATETIME,CHECKIN NVARCHAR(15),CHECKINTIME NVARCHAR(50),CHECKOUTDATE DATETIME,CHECKOUT NVARCHAR(15),CHECKOUTTIME NVARCHAR(50),AttendanceType NVARCHAR(25),MonthDate DATETIME,TOTALTIME NVARCHAR(50),InLocDetails nvarchar(max),OutLocDetails nvarchar(max))
				INSERT INTO @TABATTENDANCE
						SELECT CONVERT(DATETIME,DCALPHA1) CHECKINDATE,CASE ISNULL(TD.DCALPHA1,'') WHEN '' THEN 'No Check-In' else 'Present' END CHECKIN,ISNULL(CAST(TD.DCALPHA2 AS TIME),''),
							   CONVERT(DATETIME,DCALPHA3) CHECKOUTDATE,CASE ISNULL(TD.DCALPHA3,'') WHEN '' THEN 'No Check-Out' else 'Present' END CHECKOUT,ISNULL(CAST(TD.DCALPHA4 AS TIME),''),
							   '','',ISNULL(TD.DCALPHA5,'0.0'),
							   ISNULL(TD.DCALPHA6,'')+'~'+ISNULL(TD.DCALPHA7,'')+'~'+ISNULL(TD.DCALPHA8,'')+'~'+ISNULL(TD.DCALPHA9,'')+'~'+ISNULL(TD.DCALPHA10,'')+'~'+ISNULL(TD.DCALPHA11,'')+'~'+ISNULL(TD.DCALPHA12,'')+'~'+ISNULL(TD.DCALPHA13,'')+'~'+ISNULL(TD.DCALPHA14,'')+'~'+ISNULL(TD.DCALPHA15,''),
							   ISNULL(TD.DCALPHA16,'')+'~'+ISNULL(TD.DCALPHA17,'')+'~'+ISNULL(TD.DCALPHA18,'')+'~'+ISNULL(TD.DCALPHA19,'')+'~'+ISNULL(TD.DCALPHA20,'')+'~'+ISNULL(TD.DCALPHA21,'')+'~'+ISNULL(TD.DCALPHA22,'')+'~'+ISNULL(TD.DCALPHA23,'')+'~'+ISNULL(TD.DCALPHA24,'')+'~'+ISNULL(TD.DCALPHA25,'')
						FROM INV_DOCDETAILS ID JOIN COM_DOCCCDATA CC ON CC.INVDOCDETAILSID=ID.INVDOCDETAILSID JOIN COM_DOCTEXTDATA TD ON TD.INVDOCDETAILSID=ID.INVDOCDETAILSID  WHERE ID.COSTCENTERID=40089 AND ID.STATUSID NOT IN (372,376) AND CC.DCCCNID51=@EmployeeID AND 
							((ISDATE(TD.DCALPHA1)=1 AND CONVERT(DATETIME,TD.DCALPHA1) BETWEEN CONVERT(DATETIME,@FROMDATE) AND CONVERT(DATETIME,@TODATE))
							  OR
							 (ISDATE(TD.DCALPHA3)=1 AND CONVERT(DATETIME,TD.DCALPHA3) BETWEEN CONVERT(DATETIME,@FROMDATE) AND CONVERT(DATETIME,@TODATE))
							)

				UPDATE @TABATTENDANCE SET AttendanceType='Present',MonthDate=CASE ISNULL(CHECKINDATE,'') WHEN '' THEN  CONVERT(DATETIME,CHECKOUTDATE) else  CONVERT(DATETIME,CHECKINDATE) END WHERE ISNULL(CHECKIN,'')='Present' AND ISNULL(CHECKOUT,'')='Present'
				UPDATE @TABATTENDANCE SET AttendanceType='Single Punch',MonthDate=CASE ISNULL(CHECKINDATE,'') WHEN '' THEN  CONVERT(DATETIME,CHECKOUTDATE) else  CONVERT(DATETIME,CHECKINDATE) END  WHERE ISNULL(CHECKIN,'')='No Check-In' AND ISNULL(CHECKOUT,'')='Present'
				UPDATE @TABATTENDANCE SET AttendanceType='Single Punch',MonthDate=CASE ISNULL(CHECKINDATE,'') WHEN '' THEN  CONVERT(DATETIME,CHECKOUTDATE) else  CONVERT(DATETIME,CHECKINDATE) END  WHERE ISNULL(CHECKIN,'')='Present' AND ISNULL(CHECKOUT,'')='No Check-Out'
				UPDATE 	DATESCOUNT  SET AttendanceType=TABATTENDANCE.AttendanceType,CHECKIN=TABATTENDANCE.CHECKINTIME,CHECKOUT=TABATTENDANCE.CHECKOUTTIME,TOTALTIME=TABATTENDANCE.TOTALTIME,InLocDetails=TABATTENDANCE.InLocDetails,OutLocDetails=TABATTENDANCE.OutLocDetails from @DATESCOUNT DATESCOUNT,@TABATTENDANCE TABATTENDANCE WHERE CONVERT(DATETIME,MonthDate)= CONVERT(DATETIME,DATE1)
			END
			UPDATE 	@DATESCOUNT  SET AttendanceType='-' from @DATESCOUNT WHERE AttendanceType='Absent' AND CONVERT(DATETIME,DATE1)>= CONVERT(DATETIME,GETDATE())
			--FOR PRESENT,ABSENT AND SINGLE PUNCH
			
			--FOR UNPAID DAYS
			--IF(@CostCenterID=40089)
			--BEGIN
				UPDATE 	@DATESCOUNT  SET AttendanceType='UnPaid' WHERE CONVERT(DATETIME,DATE1)<= CONVERT(DATETIME,@DOJ)
			--END
			--FOR UNPAID DAYS
			
			--FOR LEAVES AND LOP
			DECLARE @TABLEAVES TABLE(ID INT IDENTITY(1,1),FROMDATE DATETIME,TODATE DATETIME,LEAVTTYPE NVARCHAR(20))
			--FOR APPLIED LEAVES
			INSERT INTO @TABLEAVES
			SELECT CONVERT(DATETIME,DCALPHA4),CONVERT(DATETIME,DCALPHA5),'REGULAR'
                                    FROM INV_DOCDETAILS ID JOIN COM_DOCCCDATA CC ON CC.INVDOCDETAILSID=ID.INVDOCDETAILSID JOIN COM_DOCTEXTDATA TD ON TD.INVDOCDETAILSID=ID.INVDOCDETAILSID
                                    WHERE ID.COSTCENTERID=40062 AND ID.STATUSID NOT IN (372,376) AND CC.DCCCNID51=@EmployeeID  AND 
	                                       (CONVERT(DATETIME,dcAlpha4) between CONVERT(DATETIME,@FROMDATE) and CONVERT(DATETIME,@TODATE)
											or CONVERT(DATETIME,dcAlpha5) between CONVERT(DATETIME,@FROMDATE) and CONVERT(DATETIME,@TODATE)
											or CONVERT(DATETIME,@FROMDATE) between CONVERT(DATETIME,dcAlpha4) and CONVERT(DATETIME,dcAlpha5)
											or CONVERT(DATETIME,@TODATE) between CONVERT(DATETIME,dcAlpha4) and CONVERT(DATETIME,dcAlpha4)) 
			--FOR APPLIED LEAVES											
			
			--FOR LOP BASED LEAVETYPES LEAVES
			IF(ISNULL(@ConsiderLOPBasedOn,'')<>'')
			BEGIN		
				DECLARE @TABLOPLEAVES TABLE(ID INT IDENTITY(1,1),LEAVETYPEID INT)									
				INSERT INTO @TABLOPLEAVES EXEC SPSplitString @ConsiderLOPBasedOn,','						
				SET @RC=1
				SET @TRC=(SELECT COUNT(*) FROM @TABLOPLEAVES)
				WHILE (@RC<=@TRC)
				BEGIN
					SELECT @LEAVETYPE=LEAVETYPEID FROM @TABLOPLEAVES WHERE ID=@RC
					INSERT INTO @TABLEAVES
					SELECT CONVERT(DATETIME,DCALPHA4),CONVERT(DATETIME,DCALPHA5),'LOP'
                                    FROM INV_DOCDETAILS ID JOIN COM_DOCCCDATA CC ON CC.INVDOCDETAILSID=ID.INVDOCDETAILSID JOIN COM_DOCTEXTDATA TD ON TD.INVDOCDETAILSID=ID.INVDOCDETAILSID
                                    WHERE ID.COSTCENTERID=40062 AND ID.STATUSID NOT IN (372,376) AND CC.DCCCNID51=@EmployeeID  AND CC.DCCCNID52=@LEAVETYPE AND 
	                                       (CONVERT(DATETIME,dcAlpha4) between CONVERT(DATETIME,@FROMDATE) and CONVERT(DATETIME,@TODATE)
											or CONVERT(DATETIME,dcAlpha5) between CONVERT(DATETIME,@FROMDATE) and CONVERT(DATETIME,@TODATE)
											or CONVERT(DATETIME,@FROMDATE) between CONVERT(DATETIME,dcAlpha4) and CONVERT(DATETIME,dcAlpha5)
											or CONVERT(DATETIME,@TODATE) between CONVERT(DATETIME,dcAlpha4) and CONVERT(DATETIME,dcAlpha4)) 
				SET @RC=@RC+1
				END				
			END
	        --FOR LOP BASED LEAVETYPES LEAVES                         
			
			--FOR LEAVES
			SET @RC=1
			SET @TRC=(SELECT COUNT(*) FROM @TABLEAVES)
			WHILE (@RC<=@TRC)
			BEGIN
				UPDATE 	DATESCOUNT  SET AttendanceType='OnLeave' from @DATESCOUNT DATESCOUNT,@TABLEAVES TABLEAVES WHERE CONVERT(DATETIME,DATE1) between CONVERT(DATETIME,TABLEAVES.FROMDATE) and CONVERT(DATETIME,TABLEAVES.TODATE) and LEAVTTYPE='REGULAR'
				UPDATE 	DATESCOUNT  SET AttendanceType='LOP' from @DATESCOUNT DATESCOUNT,@TABLEAVES TABLEAVES WHERE CONVERT(DATETIME,DATE1) between CONVERT(DATETIME,TABLEAVES.FROMDATE) and CONVERT(DATETIME,TABLEAVES.TODATE) and LEAVTTYPE='LOP'
			SET @RC=@RC+1
			END
			--FOR LEAVES
			
			--FOR LEAVES AND LOP
			IF(@CostCenterID=40089)
			BEGIN
				--FOR SHIFT TIME AND LATE CHECKIN/EARLY CHECKOUT
				DECLARE @SHIFTSTART DATETIME,@SHIFTEND DATETIME
				IF((Select count(*) from  INV_DOCDETAILS ID,COM_DOCTEXTDATA TD,COM_DOCCCDATA cc where ID.InvDocDetailsID=TD.InvDocDetailsID and ID.InvDocDetailsID=cc.InvDocDetailsID 
											and ID.CostCenterID=40092 and ID.StatusID Not IN (372,376) and isdate(TD.dcAlpha5)=1 and isdate(TD.dcAlpha6)=1 and CONVERT(DATETIME,@FROMDATE) between convert(datetime,TD.dcAlpha5) and convert(datetime,TD.dcAlpha6) and cc.dcCCNID51=@EmployeeID)>0)
				BEGIN 
					Select @SHIFTSTART=ISNULL(ccAlpha2,'00:00:00') ,@SHIFTEND=ISNULL(ccAlpha3,'00:00:00') from com_cc50073 where NodeID=(Select cc.dcCCNID73 from  INV_DOCDETAILS ID,COM_DOCTEXTDATA TD,COM_DOCCCDATA cc 
					where  ID.InvDocDetailsID=TD.InvDocDetailsID and ID.InvDocDetailsID=cc.InvDocDetailsID and ID.CostCenterID=40092 and ID.StatusID Not IN (372,376) and isdate(TD.dcAlpha5)=1 and isdate(TD.dcAlpha6)=1 and CONVERT(DATETIME,@FROMDATE) between convert(datetime,TD.dcAlpha5) and convert(datetime,TD.dcAlpha6) and cc.dcCCNID51=@EmployeeID)
				END
				ELSE IF((Select count(*) from  INV_DOCDETAILS ID,COM_DOCTEXTDATA TD,COM_DOCCCDATA cc where ID.InvDocDetailsID=TD.InvDocDetailsID and ID.InvDocDetailsID=cc.InvDocDetailsID 
				and ID.CostCenterID=40092 and ID.StatusID Not IN (372,376)  and isdate(TD.dcAlpha5)=1 and isdate(TD.dcAlpha6)=1 and CONVERT(DATETIME,@FROMDATE) between convert(datetime,TD.dcAlpha5) and convert(datetime,TD.dcAlpha6) and cc.dcCCNID51=1)>0) 
				BEGIN 
					Select @SHIFTSTART=ISNULL(ccAlpha2,'00:00:00'),@SHIFTEND=ISNULL(ccAlpha3,'00:00:00') from com_cc50073 where NodeID=(Select cc.dcCCNID73 from  INV_DOCDETAILS ID,COM_DOCTEXTDATA TD,COM_DOCCCDATA cc 
					where ID.InvDocDetailsID=TD.InvDocDetailsID and ID.InvDocDetailsID=cc.InvDocDetailsID and  ID.CostCenterID=40092 and ID.StatusID Not IN (372,376) and isdate(TD.dcAlpha5)=1 and isdate(TD.dcAlpha6)=1 and CONVERT(DATETIME,@FROMDATE) between convert(datetime,TD.dcAlpha5) and convert(datetime,TD.dcAlpha6) and cc.dcCCNID51=1) 
				END
				ELSE
				BEGIN
					Select @SHIFTSTART=ISNULL(ccAlpha2,'00:00:00'),@SHIFTEND=ISNULL(ccAlpha3,'00:00:00') from com_cc50073 where NodeID=1 
				END
	            
				IF(ISNULL(@SHIFTSTART,'')<>'' AND ISNULL(@SHIFTEND,'')<>'')
				BEGIN
					UPDATE 	@DATESCOUNT  SET LATECHECKIN='Late Check-In' where AttendanceType='Present' and CAST(CHECKIN AS TIME)>CAST(@SHIFTSTART AS TIME)
					--UPDATE 	@DATESCOUNT  SET LATECHECKIN='Early Check-In' where AttendanceType='Present' and CAST(CHECKIN AS TIME)<CAST(@SHIFTSTART AS TIME)
					UPDATE 	@DATESCOUNT  SET EARLYCHECKOUT='Early Check-Out' where AttendanceType='Present' and CAST(CHECKOUT AS TIME)<CAST(@SHIFTEND AS TIME)
					--UPDATE 	@DATESCOUNT  SET EARLYCHECKOUT='Late Check-Out' where AttendanceType='Present' and CAST(CHECKOUT AS TIME)>CAST(@SHIFTEND AS TIME)
				END
				--FOR SHIFT TIME AND LATE CHECKIN/EARLY CHECKOUT
			END
			
			UPDATE 	@DATESCOUNT  SET ColorName=CASE ISNULL(AttendanceType,'') 
											   WHEN 'Absent' THEN '#F26155' 
											   WHEN 'Present' THEN '#22B14C'
											   WHEN 'Weekly Off' THEN '#B49263' 
											   WHEN 'Holiday' THEN '#E7CC61' 
											   WHEN 'UnPaid' THEN '#3999C8' 
											   WHEN 'OnLeave' THEN '#EC1D24' 
											   WHEN 'LOP' THEN '#F3E182' 
											   ELSE '#C3C3C3' END
			UPDATE 	@DATESCOUNT  SET ColorName='#D3D3D3' where ISNULL(AttendanceType,'')='Absent' AND CONVERT(DATETIME,GETDATE())<CONVERT(DATETIME,DATE1)
			
			--SELECT * FROM @TABATTENDANCE	
			IF(@CostCenterID=40089)
			BEGIN
				SELECT DATE1 AttendanceDate,REPLACE(CONVERT(VARCHAR(12),DATE1,106),' ','/') AttDate,DAYNAME DayName,LEFT(DATENAME(WEEKDAY,DATE1),3) DName,
				   CONVERT(VARCHAR(8),CHECKIN,108) InTime,CONVERT(VARCHAR(8),CHECKOUT,108) OutTime,TOTALTIME TotalTime,
				   AttendanceType,ColorName,
			       LateCheckIn CheckIn,EarlyCheckOut CheckOut,
			       InLocDetails,OutLocDetails,@SHIFTSTART ShiftStart,@SHIFTEND ShiftEnd from @DATESCOUNT           
			END
			ELSE IF(@CostCenterID=40090)
			BEGIN
				SELECT DATE1 TSDate,REPLACE(CONVERT(VARCHAR(12),DATE1,106),' ','/') TimeSheetDate,DAYNAME DayName,LEFT(DATENAME(WEEKDAY,DATE1),3) DName,
				   AttendanceType TimeSheetType,ColorName,InLocDetails,OutLocDetails from @DATESCOUNT           
			END
	        ELSE
			BEGIN
				SELECT DATE1 ADate,REPLACE(CONVERT(VARCHAR(12),DATE1,106),' ','/') ALDate,DAYNAME DayName,LEFT(DATENAME(WEEKDAY,DATE1),3) DName,AttendanceType DayType from @DATESCOUNT           
			END                 
			
			DROP TABLE #EMPWEEKLYOFF
			DROP TABLE #EMPWEEKLYOFF1
			DROP TABLE #WEEKLYOFF
			DROP TABLE #WEEKLYOFF1
END
GO

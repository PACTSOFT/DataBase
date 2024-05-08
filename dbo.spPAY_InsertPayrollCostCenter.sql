﻿USE PACT2C222
GO
SET ANSI_NULLS, QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spPAY_InsertPayrollCostCenter]
	@CostCenterID [int],
	@NodeID [int],
	@UserID [int] = 1,
	@LangID [int] = 1
WITH ENCRYPTION, EXECUTE AS CALLER
AS
BEGIN
SET NOCOUNT ON;
DECLARE @DOCID INT, @INVDOCDETAILSID INT,@INVDOCDETAILSIDLAST INT,@DOCSEQNO INT,@LEAVES FLOAT,@DOCUMENTID INT,@AccrualInProbation NVARCHAR(50),@DOC DATETIME,@LeaveOthFeatures NVARCHAR(500)
DECLARE @ALSTARTMONTH INT,@ALStartMonthYear DATETIME,@ALEndMonthYear DATETIME,@Date DATETIME
DECLARE @EMP INT,@GRADE INT,@LEAVETYPE INT,@EMPGRADE INT,@I INT,@TRC INT,@MonthNo INT,@ACTUALLEAVES FLOAT,@DECVAL FLOAT,@J INT,@RC INT,@FROMDATE DATETIME
CREATE TABLE #TAB(ID INT IDENTITY(1,1),dcID INT,dcCCNID51_Key INT,dcCCNID53_Key INT,dcCCNID52_Key INT,
				   PrevYearAlloted INT,dcNum3 float,PrevYearBalanceOB INT,CurrYearConsumed DECIMAL(9,2),Balance DECIMAL(9,2))	
CREATE TABLE #TAB1 (ID INT IDENTITY(1,1),dcID INT,dcCCNID51_Key INT,dcCCNID53_Key INT,dcCCNID52_Key INT,
				   PrevYearAlloted INT,dcNum3 float,PrevYearBalanceOB INT,CurrYearConsumed DECIMAL(9,2),Balance DECIMAL(9,2))	
DECLARE @TABDOCID TABLE(ID INT IDENTITY(1,1),DOCID INT,FROMDATE DATETIME)					

IF(@CostCenterID=50051)
	SELECT @Date=CONVERT(DATETIME,DOJ),@DOC=CONVERT(DATETIME,DOConfirmation) FROM COM_CC50051 WITH(NOLOCK) WHERE NODEID=@NodeID

IF (ISNULL(@Date,'')='')
	SET @Date=CONVERT(DATETIME,GETDATE())

----FOR START DATE AND END DATE OF LEAVE YEAR	
EXEC [spPAY_EXTGetLeaveyearDates] @Date,@ALStartMonthYear OUTPUT,@ALEndMonthYear OUTPUT

--CHECKING DOCID EXIST FOR CURRENT YEAR
--IF((SELECT COUNT(*) FROM  INV_DOCDETAILS ID WITH(NOLOCK),COM_DOCTEXTDATA TD WITH(NOLOCK)
--    WHERE ID.INVDOCDETAILSID=TD.INVDOCDETAILSID AND ID.COSTCENTERID=40081 AND ISDATE(TD.DCALPHA3)=1 AND CONVERT(DATETIME,TD.DCALPHA3) BETWEEN CONVERT(DATETIME,@ALSTARTMONTHYEAR) AND CONVERT(DATETIME,@ALENDMONTHYEAR))>0)
--	BEGIN
		INSERT INTO @TABDOCID
				SELECT DISTINCT DOCID,CONVERT(DATETIME,TD.DCALPHA3) FROM INV_DOCDETAILS ID WITH(NOLOCK),COM_DOCTEXTDATA TD WITH(NOLOCK) WHERE ID.INVDOCDETAILSID=TD.INVDOCDETAILSID AND TD.tCostCenterID=40081 AND ISDATE(TD.DCALPHA3)=1 AND YEAR(CONVERT(DATETIME,TD.DCALPHA3))>=YEAR(CONVERT(DATETIME,@ALSTARTMONTHYEAR))
				ORDER BY CONVERT(DATETIME,TD.DCALPHA3)

		SET @J=1
		SELECT @RC=COUNT(*) FROM @TABDOCID
		WHILE(@J<=@RC)
		BEGIN	
			SET @DOCID=0
			TRUNCATE TABLE #TAB		   
			SELECT @DOCID=DOCID,@FROMDATE=FROMDATE FROM @TABDOCID WHERE ID=@J
			IF(@COSTCENTERID=50053)--GRADE
			BEGIN
			--CHECKING GRADE NODEID						
			IF((SELECT COUNT(ID.DocID) FROM  INV_DOCDETAILS ID WITH(NOLOCK),COM_DOCCCDATA CC WITH(NOLOCK)
			WHERE ID.INVDOCDETAILSID=CC.INVDOCDETAILSID AND ID.COSTCENTERID=40081 AND ID.DOCID=@DOCID AND CC.DCCCNID53=@NodeID)<=0)
			BEGIN
				INSERT INTO #TAB 
				--LOADING GRADES
				SELECT 0,1 EmpNode,C53.NODEID,C52.NODEID,0,0,0,0,0 FROM COM_CC50053 C53 WITH(NOLOCK) 
				CROSS JOIN COM_CC50052 C52 WITH(NOLOCK) 
				WHERE c53.nodeid=@NodeID AND C52.PARENTID=5 AND C52.ISGROUP=0 
				UNION
				--LOADING EMPLOYEES
				SELECT 0,C51.NODEID EMPNODE,C53.NODEID GRADENODE,C52.NODEID,0,0,0,0,0 FROM COM_CC50051 C51 WITH(NOLOCK) 
				inner join COM_CCCCData cc WITH(NOLOCK) on cc.nodeid=c51.nodeid and cc.costcenterid=50051 and isnull(cc.ccnid53,'')<>''
				inner JOIN COM_CC50053 C53 WITH(NOLOCK) on cc.ccnid53=c53.nodeid
				CROSS JOIN COM_CC50052 C52 WITH(NOLOCK) 
				WHERE  c53.nodeid=@NodeID and C52.PARENTID=5 AND C52.ISGROUP=0 AND C51.ISGROUP=0 AND C51.StatusID=250 AND ISNULL(CONVERT(DATETIME,C51.DORelieve),'01-Jan-9000')='01-Jan-9000'
			END
			END			
			ELSE IF(@COSTCENTERID=50051)--EMPLOYEE
			BEGIN
			--CHECKING EMPLOYEE NODEID											
			IF((SELECT COUNT(ID.DocID) FROM  INV_DOCDETAILS ID WITH(NOLOCK),COM_DOCCCDATA CC WITH(NOLOCK)
			WHERE ID.INVDOCDETAILSID=CC.INVDOCDETAILSID AND ID.COSTCENTERID=40081 AND ID.DOCID=@DOCID AND CC.DCCCNID51=@NodeID)<=0)
			BEGIN
				SELECT @EMPGRADE=CC.CCNID53 FROM COM_CC50051 EMP WITH(NOLOCK),COM_CCCCDATA CC WITH(NOLOCK) WHERE EMP.NODEID=CC.NODEID AND CC.COSTCENTERID=50051 AND EMP.NODEID=@NodeID
				IF(ISNULL(@EMPGRADE,0)=0)
					SET @EMPGRADE=1
					
				--CHECKING GRADE NODEID	FOR DEFAULT EMPLOYEE 1						
				IF((SELECT COUNT(ID.DocID) FROM  INV_DOCDETAILS ID WITH(NOLOCK),COM_DOCCCDATA CC WITH(NOLOCK)
				WHERE ID.INVDOCDETAILSID=CC.INVDOCDETAILSID AND ID.COSTCENTERID=40081 AND ID.DOCID=@DOCID AND CC.DCCCNID53=@EMPGRADE AND CC.DCCCNID51=1)>0)
				BEGIN
					INSERT INTO #TAB 
					--LOADING EMPLOYEES
					SELECT 0,C51.NODEID EMPNODE,C53.NODEID GRADENODE,C52.NODEID,0,0,0,0,0 FROM COM_CC50051 C51 WITH(NOLOCK) 
					inner join COM_CCCCData cc WITH(NOLOCK) on cc.nodeid=c51.nodeid and cc.costcenterid=50051 and isnull(cc.ccnid53,'')<>''
					inner JOIN COM_CC50053 C53 WITH(NOLOCK) on cc.ccnid53=c53.nodeid
					CROSS JOIN COM_CC50052 C52 WITH(NOLOCK) 
					WHERE  C53.NODEID=@EMPGRADE AND C51.NODEID=@NodeID and C52.PARENTID=5 AND C52.ISGROUP=0 AND C51.ISGROUP=0 AND C51.StatusID=250 AND ISNULL(CONVERT(DATETIME,C51.DORelieve),'01-Jan-9000')='01-Jan-9000'
				END
				ELSE
				BEGIN
					INSERT INTO #TAB 
					--LOADING GRADES
					SELECT 0,1 EmpNode,C53.NODEID,C52.NODEID,0,0,0,0,0 FROM COM_CC50053 C53 WITH(NOLOCK) 
					CROSS JOIN COM_CC50052 C52 WITH(NOLOCK) 
					WHERE C52.PARENTID=5 AND C53.NODEID=@EMPGRADE AND C52.ISGROUP=0 
					UNION
					--LOADING EMPLOYEES
					SELECT 0,C51.NODEID EMPNODE,C53.NODEID GRADENODE,C52.NODEID,0,0,0,0,0 FROM COM_CC50051 C51 WITH(NOLOCK) 
					inner join COM_CCCCData cc WITH(NOLOCK) on cc.nodeid=c51.nodeid and cc.costcenterid=50051 and isnull(cc.ccnid53,'')<>''
					inner JOIN COM_CC50053 C53 WITH(NOLOCK) on cc.ccnid53=c53.nodeid
					CROSS JOIN COM_CC50052 C52 WITH(NOLOCK) 
					WHERE  C53.NODEID=@EMPGRADE AND C51.NODEID=@NodeID and C52.PARENTID=5 AND C52.ISGROUP=0 AND C51.ISGROUP=0 AND C51.StatusID=250 AND ISNULL(CONVERT(DATETIME,C51.DORelieve),'01-Jan-9000')='01-Jan-9000'
				END	
			END
			END		

			--EXCLUDING VACATION COMPONENTS
			TRUNCATE TABLE #TAB1
			INSERT INTO #TAB1	
			SELECT dcID,dcCCNID51_Key,dcCCNID53_Key,dcCCNID52_Key,PrevYearAlloted,dcNum3,PrevYearBalanceOB,CurrYearConsumed,Balance FROM #TAB WHERE CONVERT(VARCHAR,DCCCNID52_KEY)  NOT IN (SELECT ISNULL(TD.DCALPHA1,'0') FROM COM_DOCTEXTDATA TD WITH(NOLOCK),INV_DOCDETAILS ID WITH(NOLOCK) WHERE ID.INVDOCDETAILSID=TD.INVDOCDETAILSID AND ID.COSTCENTERID=40061)
			SET @DOCSEQNO=0
			SET @INVDOCDETAILSIDLAST=0
			SET @INVDOCDETAILSID=0
			SET @DOCUMENTID=0
			SELECT @INVDOCDETAILSIDLAST=MAX(INVDOCDETAILSID) FROM INV_DOCDETAILS  WITH(NOLOCK) WHERE DOCID=@DOCID
			SELECT @DOCSEQNO=MAX(DOCSEQNO) FROM INV_DOCDETAILS  WITH(NOLOCK) WHERE DOCID=@DOCID
			
			SET @I=1
			SET @TRC=0
			SELECT @TRC=COUNT(*) FROM #TAB1
			WHILE(@I<=@TRC)
			BEGIN
				SET @LEAVES=0
				SET @ACTUALLEAVES=0
				SET @MonthNo=0
				SELECT @EMP=DCCCNID51_KEY,@GRADE=DCCCNID53_KEY,@LEAVETYPE=DCCCNID52_KEY FROM #TAB1 WHERE ID=@I
				SELECT TOP 1 @LEAVES=ISNULL(DN.DCNUM3,0) FROM INV_DOCDETAILS ID WITH(NOLOCK) INNER JOIN COM_DOCCCDATA CC WITH(NOLOCK) ON ID.INVDOCDETAILSID=CC.INVDOCDETAILSID
								   INNER JOIN COM_DOCNUMDATA DN WITH(NOLOCK) ON ID.INVDOCDETAILSID=DN.INVDOCDETAILSID
							WHERE  ID.COSTCENTERID=40081 AND ID.DOCID=@DOCID AND CC.DCCCNID53=@GRADE AND CC.DCCCNID52=@LEAVETYPE AND CC.DCCCNID51=1

				SELECT @AccrualInProbation=ISNULL(AccrualInProbation,'Yes'),@LeaveOthFeatures=LeaveOthFeatures FROM COM_CC50054 C54 WITH(NOLOCK) WHERE ComponentID=@LEAVETYPE AND GradeID=@GRADE AND PayrollDate=(SELECT MAX(PayrollDate) FROM COM_CC50054 WITH(NOLOCK) WHERE GradeID=@GRADE )
							
				IF(@CostCenterID=50051)
				BEGIN
					IF (CONVERT(DATETIME,@ALStartMonthYear)=CONVERT(DATETIME,@FROMDATE))
					BEGIN
						IF(@AccrualInProbation='Yes')
							SET @MonthNo=DATEDIFF(m,CONVERT(DATETIME,@FROMDATE),CONVERT(DATETIME,@Date))	
						ELSE
							SET @MonthNo=DATEDIFF(m,CONVERT(DATETIME,@FROMDATE),CONVERT(DATETIME,@DOC))	
					END	
						
					IF(isnull(@MonthNo,0)>0)
						SET @MonthNo=12-ISNULL(@MonthNo,0)
					
					IF(ISNULL(@LEAVES,0)>0  AND ISNULL(@MonthNo,0)>0)
						SET @ACTUALLEAVES=ISNULL(@LEAVES,0)/12
					ELSE
						SET @ACTUALLEAVES=ISNULL(@LEAVES,0)

					IF(@LeaveOthFeatures LIKE '%#NonProRated#%')
					BEGIN
						SET @ACTUALLEAVES=ISNULL(@LEAVES,0)
						SET @MonthNo=1
					END
							
					IF(ISNULL(@ACTUALLEAVES,0)>0 AND ISNULL(@MonthNo,0)>0)
					BEGIN
						SET @ACTUALLEAVES=ISNULL(@ACTUALLEAVES,0)*ISNULL(@MonthNo,0)		
						--SET @DECVAL=0
						--SET @DECVAL=ISNULL(@ACTUALLEAVES,0)-CONVERT(INT,ISNULL(@ACTUALLEAVES,0))
						--IF(@DECVAL>=.50)
						--	SET @ACTUALLEAVES=CONVERT(INT,@ACTUALLEAVES)+.50
						--ELSE
						--	SET @ACTUALLEAVES=CONVERT(INT,@ACTUALLEAVES)
	   						
					END
				END
				
				SET @DOCSEQNO=@DOCSEQNO+1
				
				INSERT INTO INV_DOCDETAILS ([ACCDOCDETAILSID],[DOCID],[COSTCENTERID],[DOCUMENTTYPE],[VOUCHERTYPE],[VOUCHERNO],[VERSIONNO],[DOCABBR],[DOCPREFIX],[DOCNUMBER],[DOCDATE],[DUEDATE],[STATUSID],[BILLNO],[BILLDATE],[LINKEDINVDOCDETAILSID],[LINKEDFIELDNAME],[LINKEDFIELDVALUE]
					,[COMMONNARRATION],[LINENARRATION],[DEBITACCOUNT],[CREDITACCOUNT],[DOCSEQNO],[PRODUCTID],[QUANTITY],[UNIT],[HOLDQUANTITY],[RELEASEQUANTITY],[ISQTYIGNORED],[ISQTYFREEOFFER],[RATE],[AVERAGERATE],[GROSS]
					,[STOCKVALUE],[CURRENCYID],[EXCHANGERATE],[DESCRIPTION],[CREATEDBY],[CREATEDDATE],[MODIFIEDBY],[MODIFIEDDATE],[STOCKVALUEFC],[GROSSFC],[UOMCONVERSION],[UOMCONVERTEDQTY],[WORKFLOWID]
					,[WORKFLOWSTATUS],[WORKFLOWLEVEL],[DOCORDER],[DYNAMICINVDOCDETAILSID],[RESERVEQUANTITY],[REFCCID],[REFNODEID],[LINKSTATUSID],[CANCELLEDREMARKS],[LINKSTATUSREMARKS],[PARENTSCHEMEID],[REFNO],[BATCHID],[BATCHHOLD],[REFINVDOCDETAILSID],[ACTDOCDATE])
				SELECT [ACCDOCDETAILSID],[DOCID],[COSTCENTERID],[DOCUMENTTYPE],[VOUCHERTYPE],[VOUCHERNO],[VERSIONNO],[DOCABBR],[DOCPREFIX],[DOCNUMBER],[DOCDATE],[DUEDATE],[STATUSID],[BILLNO],[BILLDATE],[LINKEDINVDOCDETAILSID],[LINKEDFIELDNAME],[LINKEDFIELDVALUE]
					,[COMMONNARRATION],[LINENARRATION],[DEBITACCOUNT],[CREDITACCOUNT],@DOCSEQNO,[PRODUCTID],[QUANTITY],[UNIT],[HOLDQUANTITY],[RELEASEQUANTITY],[ISQTYIGNORED],[ISQTYFREEOFFER],[RATE],[AVERAGERATE],[GROSS]
					,[STOCKVALUE],[CURRENCYID],[EXCHANGERATE],[DESCRIPTION],[CREATEDBY],CONVERT(FLOAT,GETDATE()),[MODIFIEDBY],CONVERT(FLOAT,GETDATE()),[STOCKVALUEFC],[GROSSFC],[UOMCONVERSION],[UOMCONVERTEDQTY],[WORKFLOWID]
					,[WORKFLOWSTATUS],[WORKFLOWLEVEL],[DOCORDER],[DYNAMICINVDOCDETAILSID],[RESERVEQUANTITY],[REFCCID],[REFNODEID],[LINKSTATUSID],[CANCELLEDREMARKS],[LINKSTATUSREMARKS],[PARENTSCHEMEID],[REFNO],[BATCHID],[BATCHHOLD],[REFINVDOCDETAILSID],[ACTDOCDATE]
				FROM INV_DOCDETAILS WITH(NOLOCK) WHERE INVDOCDETAILSID=@INVDOCDETAILSIDLAST
				
				SET @INVDOCDETAILSID=@@IDENTITY  
				
				INSERT INTO COM_DOCTEXTDATA (INVDOCDETAILSID,[DCALPHA2],[DCALPHA3],[DCALPHA4],[DCALPHA5]) 
				SELECT @INVDOCDETAILSID,DCALPHA2,DCALPHA3,DCALPHA4,DCALPHA5  FROM COM_DOCTEXTDATA  WITH(NOLOCK) WHERE INVDOCDETAILSID=@INVDOCDETAILSIDLAST

				INSERT INTO COM_DOCNUMDATA ([INVDOCDETAILSID],[DCNUM3],[DCCALCNUM3])  
				SELECT @INVDOCDETAILSID,ISNULL(@ACTUALLEAVES,0),ISNULL(@ACTUALLEAVES,0)
				INSERT INTO COM_DOCCCDATA ([INVDOCDETAILSID],[DCCCNID51],[DCCCNID52],[DCCCNID53])  SELECT @INVDOCDETAILSID,@EMP,ISNULL(@LEAVETYPE,0),@GRADE
					
			SET @I=@I+1
			END
			IF(@CostCenterID=50051)
			BEGIN
				SET @DOCUMENTID=(SELECT TOP 1 DOCID FROM INV_DOCDETAILS WITH(NOLOCK) WHERE INVDOCDETAILSID=@INVDOCDETAILSID)
				IF (ISNULL(@EMP,0)>1)
					EXEC spPAY_InsertEmployeeLeaveDetails @DOCUMENTID,@EMP,@UserID,@LangID,1
			END

		
		SET @J=@J+1						
		END
DROP TABLE #TAB
DROP TABLE #TAB1		
		--INSERING EMPLOYEE RECORDS INTO ASSIGN LEAVES DOCUMENT
--END--CHECKING DOCID EXIST FOR CURRENT YEAR
END
GO

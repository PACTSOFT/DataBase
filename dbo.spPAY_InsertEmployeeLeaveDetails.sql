﻿USE PACT2C222
GO
SET ANSI_NULLS, QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spPAY_InsertEmployeeLeaveDetails]
	@DOCID [int],
	@EMPNODE [int],
	@UserID [int] = 1,
	@LangID [int] = 1,
	@MODE [int] = 0
WITH ENCRYPTION, EXECUTE AS CALLER
AS
BEGIN TRY        
SET NOCOUNT ON;

DECLARE @ALStartMonthYear DATETIME,@ALEndMonthYear DATETIME,@FROMDATE DATETIME,@LEAVETYPE INT,@OPBALANCE FLOAT,@LEAVES FLOAT,@ASSIGNEDLEAVES FLOAT,@LEAVETYPENAME VARCHAR(100)
DECLARE @I INT ,@TRC INT,@EMPLOYEEID INT,@ICOUNT INT,@RCOUNT INT

CREATE TABLE #TABEMP(ID INT IDENTITY(1,1),EMPNODE INT)


IF((SELECT COUNT(DocID) FROM INV_DOCDETAILS WITH(NOLOCK) WHERE DOCID=@DOCID AND STATUSID=369)>0)
BEGIN
	IF(ISNULL(@MODE,0)=0)
		INSERT INTO #TABEMP SELECT distinct CC.DCCCNID51  FROM  INV_DOCDETAILS ID WITH(NOLOCK),COM_DOCCCDATA CC WITH(NOLOCK) WHERE ID.INVDOCDETAILSID=CC.INVDOCDETAILSID AND  ID.DOCID=@DOCID AND ID.STATUSID=369	
	ELSE IF(ISNULL(@MODE,0)=1)
		INSERT INTO #TABEMP SELECT @EMPNODE
		
	SELECT @TRC=COUNT(*) FROM #TABEMP	
	SET @I=1
	WHILE(@I<=@TRC)
	BEGIN
		PRINT @EMPLOYEEID
		
		CREATE TABLE #TABAL(ID INT IDENTITY(1,1),EMPNODE INT,LEAVETYPE INT,LEAVETYPENAME VARCHAR(100),LEAVES FLOAT)
		CREATE TABLE #TABTOPUP (ID INT IDENTITY(1,1),EMPNODE INT,LEAVETYPE INT,LEAVETYPENAME VARCHAR(100),LEAVES FLOAT)
		CREATE TABLE #TABPAL(EMPSEQNO INT,LeaveType VARCHAR(100),OPBALANCE FLOAT,Deducted FLOAT,Balance FLOAT)
		CREATE TABLE #TEMPEMPLOYEELEAVEDETAILS(EmployeeID INT,LeaveTypeID INT,LeaveYear datetime,DeductedLeaves float,BalanceLeaves float)
		
		SELECT @EMPLOYEEID=EMPNODE FROM #TABEMP WHERE ID=@I
		SET @FROMDATE=(SELECT TOP 1 CONVERT(DATETIME,TD.dcAlpha4) FROM   INV_DOCDETAILS ID WITH(NOLOCK) INNER JOIN COM_DocTextData TD WITH(NOLOCK) ON ID.INVDOCDETAILSID=TD.INVDOCDETAILSID WHERE ID.STATUSID=369 AND ID.DOCID=@DOCID)
		
		EXEC [spPAY_EXTGetLeaveyearDates] @FROMDATE,@ALStartMonthYear OUTPUT,@ALEndMonthYear OUTPUT
		
		--LOADING PREVIOUS YEAR ASSIGNED BALANCE LEAVES
		INSERT INTO #TABPAL
		EXEC spPAY_GetLeavesOpeningBalance @EMPLOYEEID,@FROMDATE,@UserID,@LangID
		
		--LOADING CURRENT YEAR ASSIGNED LEAVES
		--TOP UP LEAVES							
		INSERT INTO #TABTOPUP
		SELECT CC.DCCCNID51,CC.DCCCNID52,C52.NAME,SUM(ISNULL(DN.DCNUM3,0))
		FROM   INV_DOCDETAILS ID WITH(NOLOCK) INNER JOIN COM_DocTextData TD WITH(NOLOCK) ON ID.INVDOCDETAILSID=TD.INVDOCDETAILSID
			   INNER JOIN COM_DOCCCDATA CC WITH(NOLOCK) ON ID.INVDOCDETAILSID=CC.INVDOCDETAILSID
		       INNER JOIN COM_DOCNUMDATA DN WITH(NOLOCK) ON ID.INVDOCDETAILSID=DN.INVDOCDETAILSID
		       INNER JOIN COM_CC50052 C52 WITH(NOLOCK) ON C52.NODEID=CC.DCCCNID52
		WHERE TD.tCostCenterID=40060 AND CC.DCCCNID51=@EMPLOYEEID AND ID.STATUSID=369 AND  ISDATE(TD.dcAlpha3)=1 AND CONVERT(DATETIME,TD.dcAlpha3) between CONVERT(DATETIME,@ALStartMonthYear) and CONVERT(DATETIME,@ALEndMonthYear)
		AND ISNULL(ID.CommonNarration,'')<>'#Opening#' and ISNULL(ID.CommonNarration,'')<>'#CarryForward#'
		GROUP BY CC.DCCCNID51,CC.DCCCNID52,C52.NAME

		INSERT INTO #TABAL
		SELECT CC.DCCCNID51,CC.DCCCNID52,C52.NAME,SUM(ISNULL(DN.DCNUM3,0))
		FROM   INV_DOCDETAILS ID WITH(NOLOCK) INNER JOIN COM_DocTextData TD WITH(NOLOCK) ON ID.INVDOCDETAILSID=TD.INVDOCDETAILSID
			   INNER JOIN COM_DOCCCDATA CC WITH(NOLOCK) ON ID.INVDOCDETAILSID=CC.INVDOCDETAILSID
		       INNER JOIN COM_DOCNUMDATA DN WITH(NOLOCK) ON ID.INVDOCDETAILSID=DN.INVDOCDETAILSID
		       INNER JOIN COM_CC50052 C52 WITH(NOLOCK) ON C52.NODEID=CC.DCCCNID52
		WHERE TD.tCostCenterID=40060 AND CC.DCCCNID51=@EMPLOYEEID AND ID.STATUSID=369 AND  ISDATE(TD.dcAlpha3)=1 AND CONVERT(DATETIME,TD.dcAlpha3) between CONVERT(DATETIME,@ALStartMonthYear) and CONVERT(DATETIME,@ALEndMonthYear)
		AND (ID.CommonNarration='#Opening#' OR ID.CommonNarration='#CarryForward#')
		GROUP BY CC.DCCCNID51,CC.DCCCNID52,C52.NAME

		--ASSIGN LEAVES
		INSERT INTO #TABAL
		SELECT CC.DCCCNID51,CC.DCCCNID52,C52.NAME,SUM(ISNULL(DN.DCNUM3,0))
		FROM   INV_DOCDETAILS ID WITH(NOLOCK) INNER JOIN COM_DocTextData TD WITH(NOLOCK) ON ID.INVDOCDETAILSID=TD.INVDOCDETAILSID
			   INNER JOIN COM_DOCCCDATA CC WITH(NOLOCK) ON ID.INVDOCDETAILSID=CC.INVDOCDETAILSID
		       INNER JOIN COM_DOCNUMDATA DN WITH(NOLOCK) ON ID.INVDOCDETAILSID=DN.INVDOCDETAILSID
		       INNER JOIN COM_CC50052 C52 WITH(NOLOCK) ON C52.NODEID=CC.DCCCNID52
		WHERE TD.tCostCenterID=40081 AND CC.DCCCNID51=@EMPLOYEEID AND CC.DCCCNID51<>1  AND ID.STATUSID=369 AND  ISDATE(TD.dcAlpha3)=1 AND CONVERT(DATETIME,TD.dcAlpha3) between CONVERT(DATETIME,@ALStartMonthYear) and CONVERT(DATETIME,@ALEndMonthYear)
		GROUP BY CC.DCCCNID51,CC.DCCCNID52,C52.NAME

		UPDATE T SET T.LEAVES=ISNULL(T.LEAVES,0)+ISNULL(T1.LEAVES,0) FROM #TABAL T,#TABTOPUP T1 WHERE T.EMPNODE=T1.EMPNODE AND T.LEAVETYPE=T1.LEAVETYPE
		--LOADING CURRENT YEAR ASSIGNED LEAVES
					 
		INSERT INTO #TEMPEmployeeLeaveDetails SELECT EmployeeID,LeaveTypeID,LeaveYear,DeductedLeaves,BalanceLeaves FROM PAY_EmployeeLeaveDetails with(nolock) WHERE CONVERT(DATETIME,LeaveYear)=CONVERT(DATETIME,@ALStartMonthYear) AND EMPLOYEEID=@EMPLOYEEID
		  
		DELETE FROM PAY_EmployeeLeaveDetails WHERE CONVERT(DATETIME,LeaveYear)=CONVERT(DATETIME,@ALStartMonthYear) AND EMPLOYEEID=@EMPLOYEEID
		
		SELECT @RCOUNT =COUNT(*) FROM #TABAL
		SET @ICOUNT=1
		WHILE(@ICOUNT<=@RCOUNT)
		BEGIN
			SELECT @EMPNODE=EMPNODE,@LEAVETYPE=LEAVETYPE,@LEAVES=LEAVES,@LEAVETYPENAME=LEAVETYPENAME FROM #TABAL WHERE ID=@ICOUNT
			SET @EMPNODE=@EMPLOYEEID

			SET @OPBALANCE=0
			SELECT @OPBALANCE=ISNULL(OPBALANCE,0) FROM #TABPAL WHERE EMPSEQNO=@EMPNODE AND LeaveType=@LEAVETYPENAME
			
			IF((SELECT COUNT(*) FROM #TEMPEmployeeLeaveDetails WHERE EMPLOYEEID=@EMPNODE AND LEAVETYPEID=@LEAVETYPE AND CONVERT(DATETIME,LeaveYear)=CONVERT(DATETIME,@ALStartMonthYear))>0)
			BEGIN		
				INSERT INTO PAY_EmployeeLeaveDetails (EmployeeID,LeaveTypeID,LeaveYear,OpeningBalance,AssignedLeaves,DeductedLeaves,BalanceLeaves,CreatedBy,CreatedDate,ModifiedBy,ModifiedDate)
				SELECT @EMPNODE,@LEAVETYPE,CONVERT(DATETIME,@ALStartMonthYear),@OPBALANCE,@LEAVES,[DeductedLeaves],@OPBALANCE+@LEAVES-[DeductedLeaves],'Admin',convert(datetime,getdate()),N'',NULL
				FROM #TEMPEMPLOYEELEAVEDETAILS WHERE EMPLOYEEID=@EMPNODE AND LEAVETYPEID=@LEAVETYPE AND CONVERT(DATETIME,LeaveYear)=CONVERT(DATETIME,@ALStartMonthYear)
			END
			ELSE
			BEGIN
				INSERT INTO PAY_EmployeeLeaveDetails (EmployeeID,LeaveTypeID,LeaveYear,OpeningBalance,AssignedLeaves,DeductedLeaves,BalanceLeaves,CreatedBy,CreatedDate,ModifiedBy,ModifiedDate)
				VALUES (@EMPNODE,@LEAVETYPE,CONVERT(DATETIME,@ALStartMonthYear),@OPBALANCE,@LEAVES,0,@OPBALANCE+@LEAVES,'Admin',convert(datetime,getdate()),N'',NULL)
			END
		SET @ICOUNT=@ICOUNT+1
		END
		DROP TABLE #TABAL
		DROP TABLE #TABTOPUP 
		DROP TABLE #TABPAL
		DROP TABLE #TEMPEmployeeLeaveDetails
	SET @I=@I+1					
	END				
END
DROP TABLE #TABEMP

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

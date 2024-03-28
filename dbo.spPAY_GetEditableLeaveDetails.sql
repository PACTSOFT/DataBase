﻿USE PACT2C222
GO
SET ANSI_NULLS, QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spPAY_GetEditableLeaveDetails]
	@CostCenterID [int],
	@DocID [int],
	@DocType [int]
WITH ENCRYPTION, EXECUTE AS CALLER
AS
BEGIN
SET NOCOUNT ON;
DECLARE @EmployeeID INT,@LeaveType INT,@RCOUNT INT,@DocDate DATETIME,@FD DATETIME,@CCID INT
DECLARE @ALStartMonthYear DATETIME,@ALEndMonthYear DATETIME,@I INT,@TC INT
DECLARE @TABLEAVES TABLE(ID INT IDENTITY(1,1),CostCenterID INT,DOCID INT,INVDOCDETAILSID INT,EMPID INT,LEAVETYPE INT,
						 ISEDITABLE INT,LEAVECOUNT INT,FROMDATE DATETIME,TODATE DATETIME,CURRDOC INT,STATUSID INT)

----FOR START DATE AND END DATE OF LEAVEYEAR	
SELECT @DocDate=CONVERT(DATETIME,DOCDATE) FROM INV_DOCDETAILS WITH(NOLOCK) WHERE DOCID=@DocID
EXEC [spPAY_EXTGetLeaveyearDates] @DocDate,@ALStartMonthYear OUTPUT,@ALEndMonthYear OUTPUT

SET @EmployeeID=(SELECT TOP 1 A.DCCCNID51 FROM  [COM_DocCCData] A WITH(NOLOCK) join [INV_DocDetails] D WITH(NOLOCK) on A.InvDocDetailsID=D.InvDocDetailsID WHERE CostCenterID=@COSTCENTERID AND DocID=@DOCID)
IF(@DocType=62)--APPLY LEAVE
BEGIN
	INSERT INTO @TABLEAVES
	SELECT D.COSTCENTERID,D.DOCID,A.InvDocDetailsID,A.DCCCNID51,A.DCCCNID52,0,0,CONVERT(DATETIME,T.dcAlpha4),CONVERT(DATETIME,T.dcAlpha5),0,D.STATUSID  FROM [COM_DOCCCDATA] A WITH(NOLOCK)  
		   JOIN [INV_DOCDETAILS] D WITH(NOLOCK) ON A.INVDOCDETAILSID=D.INVDOCDETAILSID     
		   JOIN [COM_DOCTEXTDATA] T WITH(NOLOCK) ON A.INVDOCDETAILSID=T.INVDOCDETAILSID AND D.INVDOCDETAILSID=T.INVDOCDETAILSID     
	WHERE  COSTCENTERID=@COSTCENTERID AND DOCID NOT IN (@DOCID) AND A.DCCCNID51=@EmployeeID AND D.STATUSID NOT IN (372,376)
		   AND CONVERT(DATETIME,D.DOCDATE) between CONVERT(DATETIME,@ALStartMonthYear) and CONVERT(DATETIME,@ALEndMonthYear) 
	UNION
	SELECT D.COSTCENTERID,D.DOCID,A.InvDocDetailsID,A.DCCCNID51,A.DCCCNID52,0,0,CONVERT(DATETIME,T.dcAlpha4),CONVERT(DATETIME,T.dcAlpha5),1,D.STATUSID  FROM [COM_DOCCCDATA] A WITH(NOLOCK)  
		   JOIN [INV_DOCDETAILS] D WITH(NOLOCK) ON A.INVDOCDETAILSID=D.INVDOCDETAILSID     
	       JOIN [COM_DOCTEXTDATA] T WITH(NOLOCK) ON A.INVDOCDETAILSID=T.INVDOCDETAILSID AND D.INVDOCDETAILSID=T.INVDOCDETAILSID     
	WHERE  COSTCENTERID=@COSTCENTERID AND DOCID IN (@DOCID) AND D.STATUSID NOT IN (372,376)
	       AND CONVERT(DATETIME,D.DOCDATE) between CONVERT(DATETIME,@ALStartMonthYear) and CONVERT(DATETIME,@ALEndMonthYear) 
	 
END
ELSE IF(@DocType=58)--LEAVE ENCASHMENT
BEGIN
	INSERT INTO @TABLEAVES
	SELECT D.COSTCENTERID,D.DOCID,A.InvDocDetailsID,A.DCCCNID51,A.DCCCNID52,0,0,D.DOCDATE,D.DOCDATE,0,D.STATUSID  FROM [COM_DOCCCDATA] A WITH(NOLOCK)  
	       JOIN [INV_DOCDETAILS] D WITH(NOLOCK) ON A.INVDOCDETAILSID=D.INVDOCDETAILSID JOIN [COM_DOCTEXTDATA] T WITH(NOLOCK) ON A.INVDOCDETAILSID=T.INVDOCDETAILSID AND D.INVDOCDETAILSID=T.INVDOCDETAILSID     
	WHERE  COSTCENTERID=@COSTCENTERID AND DOCID NOT IN (@DOCID) AND A.DCCCNID51=@EmployeeID AND D.STATUSID NOT IN (372,376)
	       AND CONVERT(DATETIME,D.DOCDATE) between CONVERT(DATETIME,@ALStartMonthYear) and CONVERT(DATETIME,@ALEndMonthYear) 
	UNION
	SELECT D.COSTCENTERID,D.DOCID,A.InvDocDetailsID,A.DCCCNID51,A.DCCCNID52,0,0,CONVERT(DATETIME,T.dcAlpha4),CONVERT(DATETIME,T.dcAlpha5),0,D.STATUSID  FROM [COM_DOCCCDATA] A WITH(NOLOCK)  
	       JOIN [INV_DOCDETAILS] D WITH(NOLOCK) ON A.INVDOCDETAILSID=D.INVDOCDETAILSID JOIN [COM_DOCTEXTDATA] T WITH(NOLOCK) ON A.INVDOCDETAILSID=T.INVDOCDETAILSID AND D.INVDOCDETAILSID=T.INVDOCDETAILSID     
	WHERE  COSTCENTERID=40062 AND A.DCCCNID51=@EmployeeID AND D.STATUSID NOT IN (372,376)
	       AND CONVERT(DATETIME,D.DOCDATE) between CONVERT(DATETIME,@ALStartMonthYear) and CONVERT(DATETIME,@ALEndMonthYear) 
	UNION
	SELECT D.COSTCENTERID,D.DOCID,A.InvDocDetailsID,A.DCCCNID51,A.DCCCNID52,0,0,D.DOCDATE,D.DOCDATE,1,D.STATUSID  FROM [COM_DOCCCDATA] A WITH(NOLOCK)  
	       JOIN [INV_DOCDETAILS] D WITH(NOLOCK) ON A.INVDOCDETAILSID=D.INVDOCDETAILSID JOIN [COM_DOCTEXTDATA] T WITH(NOLOCK) ON A.INVDOCDETAILSID=T.INVDOCDETAILSID AND D.INVDOCDETAILSID=T.INVDOCDETAILSID     
	WHERE  COSTCENTERID=@COSTCENTERID AND DOCID IN (@DOCID) AND A.DCCCNID51=@EmployeeID AND D.STATUSID NOT IN (372,376)
	       AND CONVERT(DATETIME,D.DOCDATE) between CONVERT(DATETIME,@ALStartMonthYear) and CONVERT(DATETIME,@ALEndMonthYear) 
END
--UPDATING STATUS FIELD 'DCALPHA10' AS STATUS FOR EXISTING RECORDDS
-- NEW EMPLOYEE LEAVE DOCUMENT DEFAULT=0	
-- EXISTING EMPLOYEE LEAVE DOCUMENT=2
-- EXISTING EMPLOYEE LEAVE DOCUMENTS AND POSTED DOCUMENTS=1
SELECT @TC=COUNT(*) FROM @TABLEAVES
SET @I=1
WHILE(@I<=@TC)
BEGIN
	SET @RCOUNT=0
	SET @EmployeeID=0
	SET @CCID=0
	SELECT @EmployeeID=EMPID,@LeaveType=LEAVETYPE,@FD=CONVERT(DATETIME,FROMDATE),@CCID=COSTCENTERID FROM @TABLEAVES WHERE ID=@I AND CURRDOC=1
	
	SELECT @RCOUNT=COUNT(*)	FROM   INV_DOCDETAILS ID WITH(NOLOCK) JOIN COM_DocCCData DC WITH(NOLOCK) ON ID.INVDOCDETAILSID=DC.INVDOCDETAILSID JOIN COM_DocNumData DN WITH(NOLOCK) ON ID.INVDOCDETAILSID=DN.INVDOCDETAILSID JOIN COM_DocTextData TD WITH(NOLOCK) ON ID.INVDOCDETAILSID=TD.INVDOCDETAILSID
	WHERE  ID.STATUSID NOT IN (372,376)	AND ID.COSTCENTERID=@CCID AND CONVERT(DATETIME,@FD) between CONVERT(DATETIME,@ALStartMonthYear) and CONVERT(DATETIME,@ALEndMonthYear) 
		   AND DC.DCCCNID51=@EmployeeID AND DC.DCCCNID52=@LeaveType AND DocID<>@DocID
							       
	UPDATE 	@TABLEAVES SET ISEDITABLE=1,LEAVECOUNT=@RCOUNT WHERE ISNULL(@RCOUNT,0)>0 AND EMPID=@EmployeeID AND LEAVETYPE=@LeaveType
SET @I=@I+1
END

UPDATE 	@TABLEAVES SET ISEDITABLE=1 WHERE ISNULL(STATUSID,0)=369 AND CostCenterID=40062
UPDATE 	@TABLEAVES SET ISEDITABLE=2 WHERE ISNULL(STATUSID,0)<>369 AND CostCenterID=40058
UPDATE 	@TABLEAVES SET ISEDITABLE=2 WHERE ISNULL(ISEDITABLE,0)=0

IF(@DocType=62)--APPLY LEAVE
	UPDATE TD SET TD.dcAlpha10=ISNULL(T.ISEDITABLE,0)  FROM COM_DocTextData TD INNER JOIN @TABLEAVES T ON T.INVDOCDETAILSID=TD.INVDOCDETAILSID
ELSE IF(@DocType=58)--LEAVE ENCASHMENT
	UPDATE TD SET TD.dcAlpha6=ISNULL(T.ISEDITABLE,0)  FROM COM_DocTextData TD INNER JOIN @TABLEAVES T ON T.INVDOCDETAILSID=TD.INVDOCDETAILSID

SET NOCOUNT OFF;
END
GO

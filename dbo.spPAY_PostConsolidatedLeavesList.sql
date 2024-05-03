﻿USE PACT2C222
GO
SET ANSI_NULLS, QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spPAY_PostConsolidatedLeavesList]
	@DocID [int] = null,
	@PayrollMonth [datetime] = NULL,
	@UserId [int] = 1,
	@LangId [int] = 1
WITH ENCRYPTION, EXECUTE AS CALLER
AS
BEGIN TRY
SET NOCOUNT ON;
DECLARE @PayrollProduct INT,@CrACC INT,@DbAcc INT,@CCID INT,@strQuery varchar(max),@RMKS VARCHAR(200)=''
DECLARE @Days DECIMAL(9,2),@EmpNode INT,@LeaveType INT,@FDate DATETIME,@TDate DATETIME,@AvlblLeaves DECIMAL(9,2)
DECLARE @RCount INT,@I INT,@EmpName VARCHAR(500),@LeaveTypeName VARCHAR(100),@NoOfDaysOP DECIMAL(9,2),@AtATimeOP INT,@MaxLeavesOP INT,@SESSION VARCHAR(20)
DECLARE @strResult VARCHAR(100),@ICOUNT INT,@TRCOUNT INT,@REMARKCOUNT INT,@dcAlpha1 VARCHAR(10),@dcAlpha2 VARCHAR(10),@dcAlpha3 VARCHAR(10),@dcAlpha4 DATETIME
DECLARE @dcAlpha5 DATETIME,@dcAlpha6 VARCHAR(10),@dcAlpha7 VARCHAR(10),@dcAlpha8 VARCHAR(10),@dcAlpha9 VARCHAR(10),@dcAlpha10 VARCHAR(10),@dcCCNID51 INT,@dcCCNID52 INT,@dcAlpha14 VARCHAR(10)
DECLARE @INVDOCDETAILSID INT,@INVDOCDETAILSIDNEW INT,@NewDocID bigint,@ALStartMonthYear DATETIME,@ALEndMonthYear DATETIME,@ActualAvailableLeaves FLOAT,@ConsiderLOPBasedOn NVARCHAR(200)

DECLARE @TAB TABLE(ID BIGINT IDENTITY(1,1),INVDOCDETAILSID INT,EMPNODE INT,EMPNAME VARCHAR(500),GRADENODE INT,LEAVETYPENODE INT,LEAVETYPENAME VARCHAR(100),
				   DAYS DECIMAL(9,2),FROMDATE DATETIME,TODATE DATETIME,SESSION VARCHAR(10),ATATIME INT,MAXLEAVES INT,ASSIGNEDLEAVES DECIMAL(9,2),AVLBLLEAVES DECIMAL(9,2),AVLBLLEAVESREM DECIMAL(9,2),REMARKS VARCHAR(200))
DECLARE @TABLOPLEAVES TABLE(ID BIGINT IDENTITY(1,1),LEAVETYPEID INT)
				   
IF((SELECT COUNT(*) FROM INV_DOCDETAILS WITH(NOLOCK) WHERE DOCID=@DOCID AND STATUSID=369)>0)--POSTED
BEGIN
	----FOR START DATE AND END DATE OF LEAVE YEAR	
	EXEC [spPAY_EXTGetLeaveyearDates] @PayrollMonth,@ALStartMonthYear OUTPUT,@ALEndMonthYear OUTPUT
	SELECT @ConsiderLOPBasedOn=ISNULL(VALUE,'') FROM ADM_GlobalPreferences WITH(NOLOCK) WHERE Name='ConsiderLOPBasedOn'
	
	SELECT @PayrollProduct=ISNULL(VALUE,2) FROM ADM_GlobalPreferences WITH(NOLOCK) WHERE NAME='payrollproduct'
	SET @CCID=(SELECT TOP 1 COSTCENTERID FROM INV_DOCDETAILS WITH(NOLOCK) WHERE DOCID=@DocID)
	SELECT @CrACC=ISNULL(UserDefaultValue,2) FROM ADM_COSTCENTERDEF WHERE COSTCENTERID=@CCID AND SYSCOLUMNNAME='CreditAccount'
	SELECT @DbAcc=ISNULL(UserDefaultValue,2) FROM ADM_COSTCENTERDEF WHERE COSTCENTERID=@CCID AND SYSCOLUMNNAME='DebitAccount'
	
	INSERT INTO @TAB
	SELECT  ID.INVDOCDETAILSID,C51.DCCCNID51,EMP.NAME,CASE ISNULL(CC.CCNID53,'0') WHEN 0 THEN C53.DCCCNID53 ELSE CC.CCNID53 END,
		    C52.DCCCNID52,LT.NAME,ISNULL(DN.dcNum1,0) Days,CONVERT(DATETIME,TD.dcAlpha4),CONVERT(DATETIME,TD.dcAlpha5),TD.dcAlpha6,0,0,
		    CONVERT(FLOAT,ISNULL(TD.dcAlpha2,0)),CONVERT(FLOAT,ISNULL(TD.dcAlpha3,0)),0,''
	FROM    INV_DOCDETAILS ID WITH(NOLOCK)
			INNER JOIN COM_DocCCData C51 WITH(NOLOCK) ON C51.INVDOCDETAILSID=ID.INVDOCDETAILSID INNER JOIN COM_DocCCData C53 WITH(NOLOCK) ON C53.INVDOCDETAILSID=ID.INVDOCDETAILSID
			INNER JOIN COM_DocCCData C52 WITH(NOLOCK) ON C52.INVDOCDETAILSID=ID.INVDOCDETAILSID INNER JOIN COM_DocNumData DN WITH(NOLOCK) ON DN.INVDOCDETAILSID=ID.INVDOCDETAILSID
			INNER JOIN COM_DocTextData TD WITH(NOLOCK) ON TD.INVDOCDETAILSID=ID.INVDOCDETAILSID INNER JOIN COM_CCCCDATA CC WITH(NOLOCK) ON C51.DCCCNID51=CC.NODEID AND CC.COSTCENTERID=50051
			INNER JOIN COM_CC50051 EMP WITH(NOLOCK) ON EMP.NODEID=C51.DCCCNID51 AND EMP.NODEID=CC.NODEID INNER JOIN COM_CC50052 LT WITH(NOLOCK) ON LT.NODEID=C52.DCCCNID52
	WHERE   ID.DOCID=@DocID AND ID.COSTCENTERID=40063 AND ISNUMERIC(TD.dcAlpha2)=1 AND ISNUMERIC(TD.dcAlpha3)=1 ORDER BY C51.DCCCNID51,C52.DCCCNID52,ISNULL(DN.dcNum1,0)

	IF(ISNULL(@ConsiderLOPBasedOn,'')<>'')
	BEGIN									
		INSERT INTO @TABLOPLEAVES EXEC SPSplitString @ConsiderLOPBasedOn,','						
	END
	
	SET @I=1
	SELECT @RCount=COUNT(*) FROM @TAB
	WHILE(@I<=@RCount)
	BEGIN
		SET @NoOfDaysOP=0
		SET @AtATimeOP=0
		SET @MaxLeavesOP=0
		SELECT @EmpNode=EMPNODE,@LeaveType=LEAVETYPENODE,@FDate=CONVERT(DATETIME,FROMDATE),@TDate=CONVERT(DATETIME,TODATE),@SESSION=SESSION,
			   @Days=DAYS,@EmpName=EMPNAME,@LeaveTypeName=LEAVETYPENAME,@AvlblLeaves=AVLBLLEAVES FROM @TAB WHERE ID=@I
		IF (@Days<=@AvlblLeaves OR (SELECT COUNT(*) FROM @TABLOPLEAVES WHERE LEAVETYPEID=@LeaveType)>0)
		BEGIN
			Exec spPAY_ExtGetConsolidatedNoofDays @FDate,@TDate,@EmpNode,@LeaveType,@SESSION,@UserId,@LangId,@NoOfDaysOP output,@AtATimeOP output,@MaxLeavesOP output
			PRINT @NoOfDaysOP
			IF ISNULL(@NoOfDaysOP,0)<=0
			BEGIN
				UPDATE @TAB SET REMARKS='Dates already applied | Selected dates between Holidays/Weeklyoffs (Employee: ' + CONVERT(VARCHAR,UPPER(@EmpName)) +' | Leavetype: ' + CONVERT(VARCHAR,UPPER(@LeaveTypeName)) +')'  WHERE EMPNODE=@EmpNode and LEAVETYPENODE=@LeaveType AND ID=@I
			END
			ELSE IF ISNULL(@NoOfDaysOP,0)>ISNULL(@AtATimeOP,0)
			BEGIN
				UPDATE @TAB SET ATATIME=@AtATimeOP,MAXLEAVES=@MaxLeavesOP,AVLBLLEAVESREM=@AvlblLeaves-@NoOfDaysOP,REMARKS='Cannot apply leaves more than AtATime leaves (Employee: ' + CONVERT(VARCHAR,UPPER(@EmpName)) +' | Leavetype: ' + CONVERT(VARCHAR,UPPER(@LeaveTypeName)) +'  | AtATime: ' + CONVERT(VARCHAR,@AtATimeOP) +'  | Days: ' + CONVERT(VARCHAR,@NoOfDaysOP) +')' WHERE EMPNODE=@EmpNode and LEAVETYPENODE=@LeaveType AND ID=@I
				IF ISNULL(@Days,0)>ISNULL(@MaxLeavesOP,0)
				BEGIN
					UPDATE @TAB SET ATATIME=@AtATimeOP,MAXLEAVES=@MaxLeavesOP,AVLBLLEAVESREM=@AvlblLeaves-@NoOfDaysOP,REMARKS='Cannot apply leaves more than Max leaves (Employee: ' + CONVERT(VARCHAR,UPPER(@EmpName)) +' | Leavetype: ' + CONVERT(VARCHAR,UPPER(@LeaveTypeName)) +'  | AtATime: ' + CONVERT(VARCHAR,@MaxLeavesOP) +'  | Days: ' + CONVERT(VARCHAR,@NoOfDaysOP) +')' WHERE EMPNODE=@EmpNode and LEAVETYPENODE=@LeaveType AND ID=@I
				END
			END
			ELSE
			BEGIN
				UPDATE @TAB SET ATATIME=@AtATimeOP,MAXLEAVES=@MaxLeavesOP,AVLBLLEAVESREM=@AvlblLeaves-@NoOfDaysOP WHERE EMPNODE=@EmpNode and LEAVETYPENODE=@LeaveType AND ID=@I
			END
		END
		ELSE
		BEGIN
			UPDATE @TAB SET REMARKS='No leaves available for specified month (Employee: ' + CONVERT(VARCHAR,UPPER(@EmpName)) +' | Leavetype: ' + CONVERT(VARCHAR,UPPER(@LeaveTypeName)) +')'  WHERE EMPNODE=@EmpNode and LEAVETYPENODE=@LeaveType AND ID=@I
		END
	SET @I=@I+1
	END

	--SELECT * FROM @TAB
	--Generate Xml for Apply leave
	SELECT @TRCOUNT=COUNT(*) FROM @TAB
	SELECT @REMARKCOUNT=COUNT(*)  FROM @TAB  WHERE ISNULL(REMARKS,'')<>''
	SET @ICOUNT=1
	set @strQuery=''
	IF ISNULL(@REMARKCOUNT,0)=0--APPLY LEAVE
	BEGIN
		WHILE(@ICOUNT<=@TRCOUNT)
		BEGIN
			SET @dcAlpha1=''
			SET @dcAlpha2=''
			SET @dcAlpha3=''
			SET @dcAlpha4=''
			SET @dcAlpha5=''
			SET @dcAlpha6=''
			SET @dcAlpha7=''
			SET @dcAlpha8=''
			SET @dcAlpha9=''
			SET @dcAlpha10='0'
			SET @dcAlpha14='0'
			SET @INVDOCDETAILSID=0
			
			
			
			SELECT @dcAlpha1=null,@dcAlpha2=ASSIGNEDLEAVES,@dcAlpha3=AVLBLLEAVES,@dcAlpha4=FROMDATE,@dcAlpha5=TODATE,@dcAlpha6=SESSION,@dcAlpha7=DAYS,
			@dcAlpha8=ATATIME,@dcAlpha9=MAXLEAVES,@dcCCNID51=EMPNODE,@dcCCNID52=LEAVETYPENODE,@INVDOCDETAILSID=INVDOCDETAILSID FROM @TAB  WHERE ID=@ICOUNT
			
			--FOR OPENING BALANCE LEAVES
			SET @ActualAvailableLeaves=0
			SELECT @ActualAvailableLeaves=ISNULL(BalanceLeaves,0) FROM PAY_EMPLOYEELEAVEDETAILS WITH(NOLOCK) WHERE CONVERT(DATETIME,LEAVEYEAR)=CONVERT(DATETIME,@ALStartMonthYear) AND EmployeeID=@dcCCNID51 AND LeaveTypeID=@dcCCNID52
			SET @dcAlpha14=@ActualAvailableLeaves
			
			set @strQuery=''
			set @strQuery='<Row>'
			set @strQuery=@strQuery+'<AccountsXML></AccountsXML>'
			set @strQuery=@strQuery+'<Transactions DocSeqNo="1"  DocDetailsID="0" LinkedInvDocDetailsID="0" LinkedFieldName="" LineNarration="" '
			set	@strQuery=@strQuery+' ProductID="'+ CONVERT(VARCHAR,@PayrollProduct) +'" '
			set @strQuery=@strQuery+' IsScheme="" Quantity="1" Unit="1" UOMConversion="1" UOMConvertedQty="1" Rate="0" Gross="" RefNO=""  IsQtyIgnored="1" AverageRate="0" StockValue="0" StockValueFC="0" CurrencyID="1" ExchangeRate="1.0"  '
			set @strQuery=@strQuery+' DebitAccount="'+ CONVERT(VARCHAR,@DbAcc) +'" '
			set @strQuery=@strQuery+' CreditAccount="'+ CONVERT(VARCHAR,@CrACC) +'" '
			set @strQuery=@strQuery+' ></Transactions>'
			
			set @strQuery=@strQuery+'<Numeric Query="" ></Numeric>'
			set @strQuery=@strQuery+'<Alpha Query="dcAlpha2=N'''+ @dcAlpha2  +''','
			set @strQuery=@strQuery+' dcAlpha3=N'''+ @dcAlpha3  +''','
			set @strQuery=@strQuery+' dcAlpha4=N'''+ CONVERT(VARCHAR,@dcAlpha4) +''','
			set @strQuery=@strQuery+' dcAlpha5=N'''+ CONVERT(VARCHAR,@dcAlpha5) +''','
			set @strQuery=@strQuery+' dcAlpha6=N'''+ @dcAlpha6  +''','
			set @strQuery=@strQuery+' dcAlpha7=N'''+ @dcAlpha7  +''','
			set @strQuery=@strQuery+' dcAlpha8=N'''+ @dcAlpha8  +''','
			set @strQuery=@strQuery+' dcAlpha9=N'''+ @dcAlpha9  +''','
			set @strQuery=@strQuery+' dcAlpha10=N'''+ @dcAlpha10  +''','
			set @strQuery=@strQuery+' dcAlpha14=N'''+ @dcAlpha14  +''', "></Alpha>'
			
			set @strQuery=@strQuery+'<CostCenters Query="dcCCNID52='+ CONVERT(VARCHAR,@dcCCNID52) +','
			set @strQuery=@strQuery+' dcCCNID51='+ CONVERT(VARCHAR,@dcCCNID51) +', " ></CostCenters>'									
			set @strQuery=@strQuery+'<EXTRAXML></EXTRAXML></Row>'									
			PRINT 	(@strQuery)

			set @strResult=''
			EXEC @strResult=spDOC_SetTempInvDoc 40062,0,'','',@PayrollMonth,'','',@strQuery ,'','','','','false',0,0,0,1,'',0,0,'admin','admin',1,1,False
			if(ISNULL(@strResult,'')<>'')
			begin
				SELECT @INVDOCDETAILSIDNEW=INVDOCDETAILSID FROM INV_DOCDETAILS WHERE DOCID=CONVERT(BIGINT,@strResult)

				--UPDATE INV_DOCDETAILS SET LinkedInvDocDetailsID=@INVDOCDETAILSIDNEW WHERE INVDOCDETAILSID=@INVDOCDETAILSID
				UPDATE INV_DOCDETAILS SET STATUSID=369,REFCCID=300,REFNODEID=@INVDOCDETAILSID,LINKSTATUSID=369 WHERE DOCID=CONVERT(BIGINT,@strResult)
				SET @NewDocID=CONVERT(BIGINT,@strResult)
				EXEC spPAY_PostApplyLeaves @NewDocID,@UserId,@LangId
			end
		SET @ICOUNT=@ICOUNT+1	
		END
	END
	ELSE
	BEGIN
		SET @strResult='No Leaves Applied for the employee, Check the consolidated leaves list'
		UPDATE INV_DOCDETAILS SET STATUSID=448 WHERE DOCID=@DocID
		SELECT @strResult AS ExternalFuncErrorMessage
	END--APPLY LEAVE
END--POSTED

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

﻿USE PACT2C222
GO
SET ANSI_NULLS, QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spPAY_PostCompensatoryLeaves]
	@DOCID [bigint] = NULL,
	@UserID [int] = 1,
	@LangID [int] = 1
WITH ENCRYPTION, EXECUTE AS CALLER
AS
BEGIN TRANSACTION
Begin Try
SET NOCOUNT ON;
DECLARE @FROMDATE DATETIME,@EMPNODE INT,@STATUSID INT,@PayrollProduct INT,@CrACC INT,@DbAcc INT,@CCID INT
DECLARE @TAB2 TABLE (ID BIGINT IDENTITY(1,1),DOCDATE DATETIME,INVDOCDETAILSID BIGINT,FROMDATE DATETIME,EMPNODE INT,LEAVETYPE INT,CURRYEARLEAVEALLOTED DECIMAL(9,2),LINKEDINVDOCDETAILSID BIGINT)
	
IF ISNULL(@DOCID,0)>0
BEGIN
	SET @CCID=(SELECT TOP 1 COSTCENTERID FROM INV_DOCDETAILS WITH(NOLOCK) WHERE DOCID=@DocID)
	SELECT @CrACC=ISNULL(UserDefaultValue,2) FROM ADM_COSTCENTERDEF WHERE COSTCENTERID=@CCID AND SYSCOLUMNNAME='CreditAccount'
	SELECT @DbAcc=ISNULL(UserDefaultValue,2) FROM ADM_COSTCENTERDEF WHERE COSTCENTERID=@CCID AND SYSCOLUMNNAME='DebitAccount'
		 
	SELECT @STATUSID=ISNULL(STATUSID,0) FROM INV_DOCDETAILS WITH(NOLOCK) WHERE DOCID=@DOCID AND ISNULL(LINKEDINVDOCDETAILSID,0)=0 
	PRINT @STATUSID
	IF (@STATUSID=369)
	BEGIN
		INSERT INTO @TAB2
		SELECT CONVERT(DATETIME,ID.DOCDATE),ID.INVDOCDETAILSID,CONVERT(DATETIME,TD.dcAlpha1,106),ISNULL(CC.DCCCNID51,0),ISNULL(CC.DCCCNID52,0),
		CASE ISNULL(TD.dcAlpha2,'Both') WHEN 'Both' THEN 1 ELSE 0.5 END,ISNULL(LINKEDINVDOCDETAILSID,0)
		FROM   INV_DOCDETAILS ID WITH(NOLOCK),COM_DocTextData TD WITH(NOLOCK),COM_DOCCCDATA CC WITH(NOLOCK)
		WHERE  ID.INVDOCDETAILSID=TD.INVDOCDETAILSID  AND ID.INVDOCDETAILSID=CC.INVDOCDETAILSID AND TD.INVDOCDETAILSID=CC.INVDOCDETAILSID
		       AND ID.DOCID=@DOCID AND ID.INVDOCDETAILSID NOT IN (SELECT Isnull(REFNODEID,0) FROM  INV_DOCDETAILS WITH(NOLOCK) WHERE COSTCENTERID=40060 AND STATUSID=369)
	END
	
	IF((SELECT COUNT(*) FROM @TAB2)=0)
	BEGIN
		DECLARE @DCID BIGINT,@EMID BIGINT
		IF((SELECT COUNT(*) FROM INV_DOCDETAILS WHERE COSTCENTERID=40060 AND REFNODEID IN (SELECT INVDOCDETAILSID FROM INV_DOCDETAILS ID WITH(NOLOCK) WHERE ID.DOCID=@DOCID))>0)
		BEGIN
			SELECT TOP 1 @DCID=INV.DOCID,@EMID=CC.DCCCNID51 FROM   INV_DOCDETAILS INV WITH(NOLOCK),COM_DOCCCDATA CC WITH(NOLOCK) WHERE  INV.INVDOCDETAILSID=CC.INVDOCDETAILSID AND INV.REFNODEID IN (SELECT ID.INVDOCDETAILSID FROM INV_DOCDETAILS ID WITH(NOLOCK) WHERE ID.DOCID=@DOCID)
			
			IF((SELECT COUNT(*) FROM INV_DOCDETAILS ID WITH(NOLOCK),COM_DocTextData TD WITH(NOLOCK)
					WHERE  ID.INVDOCDETAILSID=TD.INVDOCDETAILSID  AND ID.DOCID=@DOCID AND ISNULL(TD.dcAlpha2,'')='Both')>0)
			BEGIN
				UPDATE DN SET DN.DCNUM3=1 FROM INV_DOCDETAILS INV WITH(NOLOCK),COM_DOCNUMDATA DN WITH(NOLOCK) WHERE 
				       INV.INVDOCDETAILSID=DN.INVDOCDETAILSID AND INV.COSTCENTERID=40060 AND INV.REFNODEID IN (SELECT ID.INVDOCDETAILSID FROM INV_DOCDETAILS ID WITH(NOLOCK) WHERE ID.DOCID=@DOCID)
			END
			ELSE IF((SELECT COUNT(*) FROM INV_DOCDETAILS ID WITH(NOLOCK),COM_DocTextData TD WITH(NOLOCK)
					WHERE  ID.INVDOCDETAILSID=TD.INVDOCDETAILSID  AND ID.DOCID=@DOCID AND ISNULL(TD.dcAlpha2,'')<>'Both')>0)
			BEGIN
				UPDATE DN SET DN.DCNUM3=.5 FROM INV_DOCDETAILS INV WITH(NOLOCK),COM_DOCNUMDATA DN WITH(NOLOCK) WHERE 
				       INV.INVDOCDETAILSID=DN.INVDOCDETAILSID AND INV.COSTCENTERID=40060 AND INV.REFNODEID IN (SELECT ID.INVDOCDETAILSID FROM INV_DOCDETAILS ID WITH(NOLOCK) WHERE ID.DOCID=@DOCID)
			END
			Exec spPAY_InsertEmployeeLeaveDetails @DCID, @EMID
		END
	END
		
SELECT @PayrollProduct=ISNULL(VALUE,2) FROM ADM_GlobalPreferences WITH(NOLOCK) WHERE NAME='payrollproduct'		
--Generate Xml for assign leave
DECLARE @strQuery varchar(max)
DECLARE @strResult VARCHAR(100)
DECLARE @ICOUNT INT,@TRCOUNT INT
DECLARE @ALStartMonthYear DATETIME,@ALEndMonthYear DATETIME
DECLARE @dcnum3 decimal(9,2),@dcAlpha3 datetime,@dcAlpha4 DATETIME,@DOCDATE DATETIME,@dcCCNID51 INT,@dcCCNID52 INT,@dcCCNID53 INT
DECLARE @INVDOCDETAILSID INT,@INVDOCDETAILSIDNEW INT,@LINKEDINVDOCDETAILSID INT,@NewdcCCNID51 INT
SELECT @TRCOUNT=COUNT(*) FROM @TAB2

SET @ICOUNT=1
set @strQuery=''

		WHILE(@ICOUNT<=@TRCOUNT)
		BEGIN
				
				SET @dcAlpha3=''
				SET @dcAlpha4=''
				SET @INVDOCDETAILSID=0
				
				SELECT @dcAlpha3=FROMDATE,@dcAlpha4=FROMDATE,@dcnum3=CURRYEARLEAVEALLOTED,@DOCDATE=DOCDATE,@LINKEDINVDOCDETAILSID=LINKEDINVDOCDETAILSID,
				       @dcCCNID51=EMPNODE,@dcCCNID52=LEAVETYPE,@INVDOCDETAILSID=INVDOCDETAILSID FROM @TAB2  WHERE ID=@ICOUNT
				
				SELECT @dcCCNID53=ISNULL(CCNID53,0) FROM COM_CCCCDATA WHERE COSTCENTERID=50051 AND NODEID=@dcCCNID51
				
				----FOR START DATE AND END DATE OF LEAVEYEAR	
				EXEC [spPAY_EXTGetLeaveyearDates] @dcAlpha3,@ALStartMonthYear OUTPUT,@ALEndMonthYear OUTPUT
				set @dcAlpha3=DATEADD(month,datediff(month,0,@dcAlpha3),0)
				
				set @strQuery=''
				set @strQuery='<Row>'
				set @strQuery=@strQuery+'<AccountsXML></AccountsXML>'
				IF ISNULL(@LINKEDINVDOCDETAILSID,0)>0
				BEGIN
					set	@strQuery=@strQuery+'<Transactions DocSeqNo="1"  DocDetailsID="'+ CONVERT(VARCHAR,@LINKEDINVDOCDETAILSID) +'" LinkedInvDocDetailsID="0" LinkedFieldName="" LineNarration="" '
					set	@strQuery=@strQuery+' ProductID="'+ CONVERT(VARCHAR,@PayrollProduct) +'" '
					set	@strQuery=@strQuery+' IsScheme="" Quantity="1" Unit="1" UOMConversion="1" UOMConvertedQty="1" Rate="0" Gross="" RefNO=""  IsQtyIgnored="1" AverageRate="0" StockValue="0" StockValueFC="0" CurrencyID="1" ExchangeRate="1.0" '
					set @strQuery=@strQuery+' DebitAccount="'+ CONVERT(VARCHAR,@DbAcc) +'" '
					set @strQuery=@strQuery+' CreditAccount="'+ CONVERT(VARCHAR,@CrACC) +'" '
					set @strQuery=@strQuery+' ></Transactions>'
				END
				ELSE
				BEGIN
					set	@strQuery=@strQuery+'<Transactions DocSeqNo="1"  DocDetailsID="0" LinkedInvDocDetailsID="0" LinkedFieldName="" LineNarration="" '
					set	@strQuery=@strQuery+' ProductID="'+ CONVERT(VARCHAR,@PayrollProduct) +'" '
					set	@strQuery=@strQuery+' IsScheme="" Quantity="1" Unit="1" UOMConversion="1" UOMConvertedQty="1" Rate="0" Gross="" RefNO=""  IsQtyIgnored="1" AverageRate="0" StockValue="0" StockValueFC="0" CurrencyID="1" ExchangeRate="1.0"  '
					set @strQuery=@strQuery+' DebitAccount="'+ CONVERT(VARCHAR,@DbAcc) +'" '
					set @strQuery=@strQuery+' CreditAccount="'+ CONVERT(VARCHAR,@CrACC) +'" '
					set @strQuery=@strQuery+' ></Transactions>'
				END
				set @strQuery=@strQuery+'<Numeric Query="dcNum3=N'''+ CONVERT(VARCHAR,@dcnum3) +''', " ></Numeric>'
				set @strQuery=@strQuery+'<Alpha Query="dcAlpha3=N'''+ CONVERT(varchar,@dcAlpha3)  +''','
				set @strQuery=@strQuery+' dcAlpha4=N'''+ CONVERT(varchar,@ALEndMonthYear) +''', "></Alpha>'
				
				
				set @strQuery=@strQuery+'<CostCenters Query="dcCCNID52='+ CONVERT(VARCHAR,@dcCCNID52) +','
				set @strQuery=@strQuery+' dcCCNID53='+ CONVERT(VARCHAR,@dcCCNID53) +','
				set @strQuery=@strQuery+' dcCCNID51='+ CONVERT(VARCHAR,@dcCCNID51) +', " ></CostCenters>'									
				set @strQuery=@strQuery+'<EXTRAXML></EXTRAXML></Row>'									
				PRINT 	(@strQuery)

				set @strResult=''
				EXEC @strResult=spDOC_SetTempInvDoc 40060,0,'','',@DOCDATE,'','',@strQuery ,'','','','','false',0,0,0,1,'',0,0,'admin','admin',1,1,False
				IF(ISNULL(@strResult,'')<>'')
				BEGIN
					SELECT @INVDOCDETAILSIDNEW=INVDOCDETAILSID FROM INV_DOCDETAILS WITH(NOLOCK) WHERE DOCID=CONVERT(BIGINT,@strResult)
					UPDATE INV_DOCDETAILS SET STATUSID=369,REFCCID=300,REFNODEID=@INVDOCDETAILSID,LINKSTATUSID=369 WHERE DOCID=CONVERT(BIGINT,@strResult)
					Exec spPAY_InsertEmployeeLeaveDetails @strResult, @dcCCNID51
					SELECT @strResult +' Saved Successfully' AS ErrorMessage
				END
		SET @ICOUNT=@ICOUNT+1	
		END

		UPDATE INV_DOCDETAILS SET STATUSID=369 WHERE DOCID=@DocID
END
COMMIT TRANSACTION
SET NOCOUNT OFF;	
End Try
Begin Catch
   IF ERROR_NUMBER()=50000  
	BEGIN  
		SELECT * FROM COM_CC50051 WITH(NOLOCK) WHERE NodeID=@EmpNode    
		SELECT ErrorMessage,ErrorNumber FROM COM_ErrorMessages WITH(NOLOCK)   
		WHERE ErrorNumber=ERROR_MESSAGE() AND LanguageID=@LangID  
	END  
	ELSE IF ERROR_NUMBER()=547  
	BEGIN  
		SELECT ErrorMessage, ERROR_MESSAGE() AS ServerMessage,ERROR_NUMBER() AS ErrorNumber, ERROR_PROCEDURE()as ProcedureName, ERROR_LINE() AS ErrorLine FROM COM_ErrorMessages WITH(NOLOCK)  
		WHERE ErrorNumber=-110 AND LanguageID=@LangID  
	END   
	ELSE  
	BEGIN  
		SELECT ErrorMessage, ERROR_MESSAGE() AS ServerMessage,ERROR_NUMBER() AS ErrorNumber, ERROR_PROCEDURE()as ProcedureName, ERROR_LINE() AS ErrorLine  
		FROM COM_ErrorMessages WITH(NOLOCK) WHERE ErrorNumber=-999 AND LanguageID=@LangID  
	END  
	ROLLBACK TRANSACTION  
	SET NOCOUNT OFF    
	RETURN -999     
End Catch


GO

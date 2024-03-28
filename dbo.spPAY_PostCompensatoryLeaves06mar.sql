﻿USE PACT2C222
GO
SET ANSI_NULLS, QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spPAY_PostCompensatoryLeaves06mar]
	@DOCID [int] = NULL,
	@UserID [int] = 1,
	@LangID [int] = 1
WITH ENCRYPTION, EXECUTE AS CALLER
AS
BEGIN
SET NOCOUNT ON;
DECLARE @FROMDATE DATETIME,@EMPNODE INT,@STATUSID INT
DECLARE @TAB2 TABLE (ID INT IDENTITY(1,1),INVDOCDETAILSID INT,FROMDATE DATETIME,EMPNODE INT)
DECLARE @ICOUNT INT,@RCOUNT INT

SET @ICOUNT=1
	IF ISNULL(@DOCID,0)>0
	BEGIN
		SELECT @STATUSID=ISNULL(STATUSID,0) FROM INV_DOCDETAILS WITH(NOLOCK) WHERE DOCID=@DOCID
		IF @STATUSID=369 
		BEGIN
			INSERT INTO @TAB2
			SELECT ID.INVDOCDETAILSID,CONVERT(DATETIME,TD.dcAlpha1,106),ISNULL(CC.DCCCNID51,0)
			FROM   INV_DOCDETAILS ID WITH(NOLOCK),COM_DocTextData TD WITH(NOLOCK),COM_DOCCCDATA CC WITH(NOLOCK)
			WHERE  ID.INVDOCDETAILSID=TD.INVDOCDETAILSID  AND ID.INVDOCDETAILSID=CC.INVDOCDETAILSID AND TD.INVDOCDETAILSID=CC.INVDOCDETAILSID
			AND ID.DOCID=@DOCID

					SELECT @RCOUNT =COUNT(*) FROM @TAB2
				  	WHILE(@ICOUNT<=@RCOUNT)
					BEGIN
						SELECT @FROMDATE=CONVERT(DATETIME,FROMDATE,106),@EMPNODE=EMPNODE FROM @TAB2 WHERE ID=@ICOUNT
						EXEC spPAY_UpdateCompensatoryLeavetoAssignLeaves @FROMDATE,@EMPNODE
						SET @ICOUNT=@ICOUNT+1	
					END
		END
	END
SET NOCOUNT OFF;	
END
GO
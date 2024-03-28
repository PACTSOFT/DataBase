﻿USE PACT2C222
GO
SET ANSI_NULLS, QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spPAY_GetEmployeeLeaveSummary]
	@EmployeeID [int],
	@LeaveType [int] = NULL,
	@Date [datetime],
	@Flag [int]
WITH ENCRYPTION, EXECUTE AS CALLER
AS
SET NOCOUNT ON
BEGIN TRY
	IF(@Flag=0)
	BEGIN
		SELECT LT.Name LeaveType, LT.NodeID LeaveTypeID,LD.OpeningBalance,LD.AssignedLeaves,LD.DeductedLeaves,LD.BalanceLeaves
			FROM   Pay_EmployeeLeaveDetails LD WITH(NOLOCK) 
				INNER JOIN COM_CC50052 LT WITH(NOLOCK) ON LT.NodeID =LD.LeaveTypeID
			WHERE  EmployeeID = @EmployeeID 
				AND LeaveYear =@Date
	END
	ELSE 
	BEGIN
		SELECT ID.DOCID,ID.INVDOCDETAILSID,CONVERT(NVARCHAR(12),CONVERT(DATETIME,TD.DCALPHA4),106) FROMDATE,CONVERT(NVARCHAR(12),CONVERT(DATETIME,TD.DCALPHA5),106) TODATE,
		TD.DCALPHA7 NOOFDAYS,ID.STATUSID,ID.LINENARRATION,'Leave' TYPE,LT.NAME,ID.DOCNUMBER
		FROM COM_CC50052 LT WITH(NOLOCK),Inv_DocDetails ID WITH(NOLOCK) 
		JOIN COM_DocTextData TD WITH(NOLOCK) ON ID.INVDOCDETAILSID=TD.INVDOCDETAILSID 
		JOIN COM_DocccData DC WITH(NOLOCK) ON ID.INVDOCDETAILSID=DC.INVDOCDETAILSID
		WHERE  ID.DocumentType=62 AND ID.STATUSID NOT IN (372,376) AND LT.NODEID=DC.DCCCNID52 AND DC.DCCCNID51=@EmployeeID AND DC.DCCCNID52=@LeaveType
		UNION
		SELECT ID.DOCID,ID.INVDOCDETAILSID,CONVERT(NVARCHAR(12),CONVERT(DATETIME,ID.DOCDATE),106) DOCDATE,CONVERT(NVARCHAR(12),CONVERT(DATETIME,ID.DOCDATE),106)DOCDATE,
		TD.DCALPHA3 NOOFDAYS,ID.STATUSID,ID.LINENARRATION,'Encashment' TYPE,LT.NAME,ID.DOCNUMBER
		FROM COM_CC50052 LT WITH(NOLOCK),Inv_DocDetails ID WITH(NOLOCK) 
		JOIN COM_DocTextData TD WITH(NOLOCK) ON ID.INVDOCDETAILSID=TD.INVDOCDETAILSID JOIN COM_DocCCData DC WITH(NOLOCK) ON ID.INVDOCDETAILSID=DC.INVDOCDETAILSID
		WHERE LT.NODEID=DC.DCCCNID52 AND ID.COSTCENTERID=40058 AND ID.STATUSID NOT IN (372,376) AND LT.NODEID=@LeaveType AND DC.DCCCNID51=@EmployeeID	  	
	END
END TRY	
BEGIN CATCH
END CATCH
SET NOCOUNT OFF
GO

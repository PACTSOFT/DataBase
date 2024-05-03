USE PACT2C222
GO
SET ANSI_NULLS, QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spCOM_GetScheduleEvents]
	@DimWhere [nvarchar](max) = '',
	@RoleID [int],
	@UserID [bigint] = 0,
	@LangID [int] = 1
WITH ENCRYPTION, EXECUTE AS CALLER
AS
BEGIN TRY  
SET NOCOUNT ON;

		declare @PrefValue NVARCHAR(MAX)='',@SQL NVARCHAR(MAX)
		declare @Users table(UserID BIGINT)
		select  @PrefValue = Value from COM_CostCenterPreferences with(nolock)  
		where CostCenterID=95 and  Name = 'DistributeAssignedUsers' 
		if(@PrefValue is not null and @PrefValue<>'')
		begin
			insert into @Users  
			exec SPSplitString @PrefValue,','
		end

		declare @nextdays int
		select @nextdays=value from adm_globalpreferences with(nolock)
		where name = 'Post Events For Next' and isnumeric(value)=1
		if(@nextdays is null or @nextdays=0)
			set @nextdays=365
	    
	    create table #tab(ID INT IDENTITY(1,1) PRIMARY KEY,ScheduleID BIGINT,NodeID BIGINT,VoucherNo NVARCHAR(MAX),EventTime DATETIME,FreqType NVARCHAR(50),
			[Status] INT,CostCenterID BIGINT,SchEventID BIGINT,SubCostCenterID BIGINT,TrackingNO BIGINT,AttachmentID BIGINT,RecurMethod TINYINT)
	    
	    INSERT INTO #tab
		SELECT S.ScheduleID,CC.NodeID,D.DocNo,CONVERT(DATETIME, E.EventTime) AS EventTime, CONVERT(NVARCHAR, S.FreqType) AS FreqType,
			E.StatusID AS Status, CC.CostCenterID,E.SchEventID,E.SubCostCenterID,E.NODEID TrackingNO,AttachmentID,S.RecurMethod
		FROM COM_SchEvents E with(nolock)
		INNER JOIN COM_Schedules S with(nolock) ON E.ScheduleID=S.ScheduleID
		INNER JOIN COM_CCSchedules CC with(nolock) ON S.ScheduleID=CC.ScheduleID
		INNER JOIN COM_DocID AS D on D.ID=CC.NodeID
		WHERE E.StatusID=1 AND CC.CostCenterID>=40001 AND CC.CostCenterID<= 50000
			and (S.FreqType<>0 or (CONVERT(DATETIME, E.EventTime)<=getdate()+@nextdays))
		AND (@RoleID=1 OR S.ScheduleID IN (select ScheduleID from COM_UserSchedules with(nolock) WHERE UserID=@UserID OR RoleID=@RoleID OR GroupID IN (SELECT GID FROM COM_Groups with(nolock) WHERE UserID=@UserID OR RoleID=@RoleID)))
		
		if @DimWhere!=''
		begin
			set @SQL='delete T
		from #tab T
		join ACC_DocDetails D with(nolock) on D.VoucherNo=T.VoucherNo
		join ADM_DocumentTypes DT with(nolock) on D.CostCenterID=DT.CostCenterID
		left join COM_DocCCData DCC with(nolock) on DCC.AccDocDetailsID=D.AccDocDetailsID'+@DimWhere+'
		where DT.IsInventory=0 and DCC.AccDocDetailsID is null'
			exec(@SQL)
			
			set @SQL='delete T
		from #tab T
		join INV_DocDetails D with(nolock) on D.VoucherNo=T.VoucherNo
		join ADM_DocumentTypes DT with(nolock) on D.CostCenterID=DT.CostCenterID
		left join COM_DocCCData DCC with(nolock) on DCC.InvDocDetailsID=D.InvDocDetailsID'+@DimWhere+'
		where DT.IsInventory=1 and DCC.InvDocDetailsID is null'
			exec(@SQL)
		end
		
		
		IF EXISTS (SELECT * FROM @Users WHERE UserID=@UserID)
		BEGIN
			SELECT ScheduleID,NodeID,VoucherNo,EventTime,FreqType,[Status],CostCenterID,SchEventID,SubCostCenterID,TrackingNO,AttachmentID,RecurMethod
			FROM #tab
			UNION
			SELECT S.ScheduleID,CC.NodeID,D.VoucherNo,CONVERT(DATETIME, E.EventTime) AS EventTime, CONVERT(NVARCHAR, S.FreqType) AS FreqType,
				E.StatusID AS Status, D.CostCenterID,E.SchEventID,E.SubCostCenterID,E.NODEID TrackingNO,AttachmentID,S.RecurMethod
			FROM COM_SchEvents E with(nolock)
			INNER JOIN COM_Schedules S with(nolock) ON E.ScheduleID=S.ScheduleID
			INNER JOIN COM_CCSchedules CC with(nolock) ON S.ScheduleID=CC.ScheduleID
			INNER JOIN (SELECT DocID,VoucherNo,CostCenterID
						FROM ACC_DocDetails with(nolock)
						GROUP BY DocID,VoucherNo,CostCenterID
						HAVING DocID>0
						UNION
						SELECT DocID,VoucherNo,CostCenterID
						FROM INV_DocDetails with(nolock)
						GROUP BY DocID, VoucherNo, CostCenterID
						HAVING DocID>0) AS D ON D.CostCenterID=CC.CostCenterID AND D.DocID=CC.NodeID
			WHERE E.StatusID=1 AND CC.CostCenterID>=40001 AND CC.CostCenterID<= 50000
				and (S.FreqType<>0 or (CONVERT(DATETIME, E.EventTime)<=getdate()+@nextdays))
			AND E.NODEID>0 AND E.CostCenterID IS NULL
			ORDER BY EventTime DESC
		END
		ELSE
		BEGIN
			SELECT ScheduleID,NodeID,VoucherNo,EventTime,FreqType,[Status],CostCenterID,SchEventID,SubCostCenterID,TrackingNO,AttachmentID,RecurMethod 
			FROM #tab
			ORDER BY EventTime DESC
		END
		drop table #tab

--select * from COM_UserSchedules
--select * from COM_Schedules
--select * from COM_SchEvents

SET NOCOUNT OFF;  

RETURN 1  
END TRY  
BEGIN CATCH  
	--Return exception info [Message,Number,ProcedureName,LineNumber]  
	IF ERROR_NUMBER()=50000
	BEGIN
		SELECT ErrorMessage,ErrorNumber FROM COM_ErrorMessages WITH(nolock) 
		WHERE ErrorNumber=ERROR_MESSAGE() AND LanguageID=@LangID
	END
	ELSE
	BEGIN
		SELECT ErrorMessage, ERROR_MESSAGE() AS ServerMessage,ERROR_NUMBER() as ErrorNumber, ERROR_PROCEDURE()as ProcedureName, ERROR_LINE() AS ErrorLine
		FROM COM_ErrorMessages WITH(nolock) WHERE ErrorNumber=-999 AND LanguageID=@LangID
	END
	SET NOCOUNT OFF  
	RETURN -999   
END CATCH
GO

USE PACT2C222
GO
SET ANSI_NULLS, QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spSVC_GetDeclinedJobs]
	@CV_ID [bigint] = 0,
	@TicketID [bigint] = 0,
	@UserID [bigint],
	@LangID [int] = 1
WITH ENCRYPTION, EXECUTE AS CALLER
AS
BEGIN TRY  
SET NOCOUNT ON;

		DECLARE @I INT,@COUNT INT,@tktID BIGINT,@jobID BIGINT,@CntTemp INT
		DECLARE @Tbl AS TABLE(ID INT IDENTITY(1,1),TicketID BIGINT,JobID BIGINT)

		INSERT INTO @Tbl(TicketID,JobID)
		SELECT J.ServiceTicketID,J.PartCategoryID
		FROM SVC_ServiceJobsInfo J   WITH(NOLOCK) 
		INNER JOIN SVC_ServiceTicket T  WITH(NOLOCK)  ON T.ServiceTicketID=J.ServiceTicketID AND T.CustomerVehicleID=@CV_ID
		WHERE J.IsDeclined=1 AND J.DeclinedUsed=0 AND J.ServiceTicketID<>0  and j.partcategoryid>0
--		ORDER BY J.ServiceTicketID,J.PartCategoryID
 -- select * from @Tbl
		SELECT @I=1,@COUNT=COUNT(*) FROM @Tbl

		WHILE(@I<=@COUNT)
		BEGIN
			SELECT @tktID=TicketID,@jobID=JobID FROM @Tbl WHERE ID=@I

			--SET @CntTemp=0
			SELECT @CntTemp=COUNT(*)
			FROM SVC_ServiceJobsInfo J
			INNER JOIN SVC_ServiceTicket T  WITH(NOLOCK)  ON T.ServiceTicketID=J.ServiceTicketID AND T.CustomerVehicleID=@CV_ID
			WHERE J.IsDeclined=0 AND J.ServiceTicketID>@tktID AND J.PartCategoryID=@jobID
			
			IF @CntTemp>0
				DELETE FROM @Tbl WHERE ID=@I
			SET @I=@I+1		
		END

		--To get costcenter table name
		SELECT  T.ServiceTicketID,T.ServiceTicketNumber TicketID,Convert(DateTime, T.ArrivalDateTime) as Date,
		J.ServicePartsJobsInfoID,
			J.PartCategoryID,C.Code Category, Prod.ProductName, prod.ProductCode,
			 prod.productid, part.Name as part, part.NodeID as PartID, P.Rate , T.Serviceticketnumber as JobCardNo  
		FROM SVC_ServiceJobsInfo J	 WITH(NOLOCK) 	
		INNER JOIN SVC_ServiceTicket T  WITH(NOLOCK) ON T.ServiceTicketID=J.ServiceTicketID AND T.CustomerVehicleID=@CV_ID
		inner join svc_ServicePartsInfo p  WITH(NOLOCK) on t.serviceticketid=p.ServiceTicketID and p.link=0
		INNER JOIN @Tbl Tbl ON Tbl.TicketID=J.ServiceTicketID AND Tbl.JobID=J.PartCategoryID 
		inner join COM_CC50029 part  WITH(NOLOCK) on p.partid=part.NodeID
		inner join inv_PRoduct prod   WITH(NOLOCK) on p.ProductID=prod.ProductID 
		inner JOIN COM_Category C WITH(NOLOCK) ON J.PartCategoryID=C.NodeID 
		and c.nodeid in (select ccnid6 from com_ccccdata  WITH(NOLOCK) where CostCenterID=50029 and NodeID=p.PartID)
		WHERE J.IsDeclined=1 AND J.DeclinedUsed=0 
		ORDER BY T.ServiceTicketID,J.PartCategoryID
		 
		 

 
SET NOCOUNT OFF;
RETURN 1
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

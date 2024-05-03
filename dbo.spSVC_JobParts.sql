USE PACT2C222
GO
SET ANSI_NULLS, QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spSVC_JobParts]
	@JobID [bigint] = 0,
	@TicketID [bigint],
	@UserID [bigint],
	@LangID [int] = 1
WITH ENCRYPTION, EXECUTE AS CALLER
AS
BEGIN TRANSACTION  
BEGIN TRY  
SET NOCOUNT ON;

		SELECT P.ProductID ProductName_Key,P.Quantity Qty, P.*, INV_Product.ProductName as ProductName, part.NodeID as Product_Key
		FROM SVC_ServicePartsInfo P
		INNER JOIN INV_Product ON INV_Product.ProductID=P.ProductID 
		inner join SVC_ServiceJobsInfo j on j.PartCategoryID=@JobID and j.ServiceTicketID=@TicketID and j.IsDeclined=1
		inner join COM_Category c on c.NodeID in (select ccnid6 from COM_CCCCData where CostCenterID=50029 and NodeID=p.PartID)
		inner join COM_CC50029 part on part.NodeID=p.PartID and p.IsDeclined=1
		WHERE p.ServiceTicketID=@TicketID and P.Link=0
		--WHERE
	 
	 select * from SVC_ServicePartsInfo
		--To get costcenter table name
--		SELECT T.ServiceTicketID,T.ServiceTicketNumber TicketID,J.ServicePartsJobsInfoID,
--			J.PartCategoryID,C.Code Category
--		FROM SVC_ServiceJobsInfo J
--		INNER JOIN SVC_ServiceTicket T ON T.ServiceTicketID=J.ServiceTicketID AND T.CustomerVehicleID=@CV_ID
--		LEFT JOIN COM_Category C WITH(NOLOCK) ON J.PartCategoryID=C.NodeID
--		WHERE J.IsDeclined=1 AND J.DeclinedUsed=0
--		ORDER BY T.ServiceTicketID,J.PartCategoryID

COMMIT TRANSACTION 
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
ROLLBACK TRANSACTION
SET NOCOUNT OFF  
RETURN -999   
END CATCH
GO

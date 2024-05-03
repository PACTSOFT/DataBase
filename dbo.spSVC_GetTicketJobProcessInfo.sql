USE PACT2C222
GO
SET ANSI_NULLS, QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spSVC_GetTicketJobProcessInfo]
	@TicketID [bigint],
	@sno [int],
	@Categoryid [int],
	@UserID [bigint],
	@LangID [int] = 1
WITH ENCRYPTION, EXECUTE AS CALLER
AS
BEGIN TRANSACTION
BEGIN TRY	
SET NOCOUNT ON
  
 
BEGIN 
 
	 select T.Name as Technician, T.Nodeid as TechID, Action, convert(datetime,j.CreatedDate) as CreatedDate,  
	 L.Name Reason  
	 from [SVC_ServiceJobProcess] j
	 left join com_cc50019 T on T.Nodeid=j.Technician
	 left join com_lookup L on j.Reason=L.Nodeid 
	 where j.ServiceTicketID=@TicketID and 
	 j.serialnumber=@sno and j.PartCategoryID=@Categoryid  ORDER BY j.CreatedDate  

	 select * from com_lookup
	
	Declare @StartDatetime datetime, @Enddatetime datetime
	
	select @StartDatetime=convert(datetime,j.CreatedDate) 
	 from [SVC_ServiceJobProcess] j
	 where  j.ServiceTicketID=@TicketID and 
	 j.serialnumber=@sno and j.PartCategoryID=@Categoryid  and action='Start'
	  
	  select @Enddatetime=convert(datetime,j.CreatedDate) from [SVC_ServiceJobProcess] j where  j.ServiceTicketID=@TicketID and 
	 j.serialnumber=@sno and j.PartCategoryID=@Categoryid  and action='Complete'
	 
	  
	 select ProductID, ReorderLevel, CCNID2 as Location, CCNID6 as Category, Convert(Datetime,wef) as WEF 
	 from com_ccprices where CCNID6=@Categoryid and reorderlevel >0 and WEF in 
	 (select Max(wef)
	 from com_ccprices where CCNID6=@Categoryid and reorderlevel >0)

	 
	 
	 --select @Enddatetime, @StartDatetime
	 if(@Enddatetime<>'' and @StartDatetime<>'') 
		SELECT CONVERT(VARCHAR,DATEDIFF(HOUR,@StartDatetime,@Enddatetime))  
	
END
 

COMMIT TRANSACTION
SET NOCOUNT OFF;
RETURN 1
END TRY
BEGIN CATCH  
	--Return exception info [Message,Number,ProcedureName,LineNumber]  
	IF ERROR_NUMBER()=50000
	BEGIN
		SELECT ErrorMessage,ErrorNumber FROM COM_ErrorMessages WITH(nolock) WHERE ErrorNumber=ERROR_MESSAGE() AND LanguageID=@LangID
	END
	ELSE
	BEGIN
		SELECT ErrorMessage, ERROR_MESSAGE() AS ServerMessage,ERROR_NUMBER() as ErrorNumber, ERROR_PROCEDURE()as ProcedureName, ERROR_LINE() AS ErrorLine
		FROM COM_ErrorMessages WITH(nolock) WHERE ErrorNumber=-999 AND LanguageID=@LangID
	END
ROLLBACK TRANSACTION
SET NOCOUNT OFF  
RETURN -999   
END CATCH  


GO

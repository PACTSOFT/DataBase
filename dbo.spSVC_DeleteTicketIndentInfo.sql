USE PACT2C222
GO
SET ANSI_NULLS, QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spSVC_DeleteTicketIndentInfo]
	@ProductID [bigint],
	@CCTicketID [bigint],
	@UserName [nvarchar](50),
	@USERID [int],
	@LANGID [int],
	@RoleID [int] = 1
WITH ENCRYPTION, EXECUTE AS CALLER
AS
BEGIN TRANSACTION  
BEGIN TRY  
SET NOCOUNT ON;
		--Declaration Section  	
		DECLARE @HasAccess BIT,@RowsDeleted INT
		DECLARE @IsEdit BIT

		--User access check 
		SET @HasAccess=dbo.fnCOM_HasAccess(@RoleID,59,4)
		IF @HasAccess=0
		BEGIN
			RAISERROR('-105',16,1)
		END 
		create table #tempdocdetails(id int identity(1,1), invdocid bigint, costcenterid bigint)
		insert into #tempdocdetails (invdocid, costcenterid) 
		SELECT T.DocID, T.CostcenterID
	 	FROM INV_DocDetails T WITH(NOLOCK)
		LEFT JOIN COM_DocCCData C ON T.InvDocDetailsID=C.InvDocDetailsID
		WHERE CostCenterID IN (SELECT Value FROM COM_CostCenterPreferences WITH(NOLOCK) WHERE COM_CostCenterPreferences.FeatureID=59 AND Name = 'ServiceIndentDocument')
		AND dcCCNID42=@CCTicketID AND ProductID=@ProductID
	  
		declare @i int, @cnt int, @costcenterid int, @acnt int, @accdocid bigint , @invdocid bigint
	   	
	   	set @i=1
	   	select @cnt=count(*) from #tempdocdetails 
		while @i<=@cnt
		begin
			select  @invdocid =invdocid, @costcenterid=Costcenterid from #tempdocdetails where id=@i 
	 		DECLARE @return_value INT
	 		BEGIN
				select @costcenterid, @invdocid 
					EXEC	@return_value =  spDOC_DeleteInvDocument
					@CostCenterID = @costcenterid,
					@DocPrefix = '',
					@DocNumber = '',  
					@DocID =  @invdocid,
					@UserID = @userid,
					@UserName = @username,
					@LangID = @LangId,
					@RoleID=@RoleID
			END  
			set @i=@i+1
		end    
   		drop table #tempdocdetails
   		
COMMIT TRANSACTION
SET NOCOUNT OFF; 
SELECT ErrorMessage,ErrorNumber FROM COM_ErrorMessages WITH(nolock) 
WHERE ErrorNumber=102 AND LanguageID=@LangID 
RETURN @CCTicketID  
END TRY  
BEGIN CATCH  
	--Return exception info [Message,Number,ProcedureName,LineNumber]  
	IF ERROR_NUMBER()=50000
	BEGIN		  
		SELECT ErrorMessage,ErrorNumber FROM COM_ErrorMessages WITH(NOLOCK) WHERE ErrorNumber=ERROR_MESSAGE() AND LanguageID=@LangID
	END
	ELSE
	BEGIN
		SELECT ErrorMessage, ERROR_MESSAGE() AS ServerMessage,ERROR_NUMBER() AS ErrorNumber, ERROR_PROCEDURE()AS ProcedureName, ERROR_LINE() AS ErrorLine
		FROM COM_ErrorMessages WITH(NOLOCK) WHERE ErrorNumber=-999 AND LanguageID=@LangID
	END
	ROLLBACK TRANSACTION
	SET NOCOUNT OFF  
	RETURN -999   
END CATCH   
GO

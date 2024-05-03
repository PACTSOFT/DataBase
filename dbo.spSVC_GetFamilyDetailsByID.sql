USE PACT2C222
GO
SET ANSI_NULLS, QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spSVC_GetFamilyDetailsByID]
	@FamilyID [bigint] = 0,
	@CustomerID [bigint] = 0,
	@UserID [bigint],
	@LangID [int] = 1
WITH ENCRYPTION, EXECUTE AS CALLER
AS
BEGIN TRY	
SET NOCOUNT ON
 
 
 
BEGIN 
			 select CustomerFamilyID as FamilyID, cf.Name as FName,
			L.NodeID as FRelation,  L.Name as Relation, Phone as FPhone
			from svc_Customerfamilydetails cf   WITH(NOLOCK) 
			left join com_lookup L  WITH(NOLOCK) on L.NodeID=cf.Relation
			where cf.CustomerFamilyID=@FamilyID
			
				 select CustomerFamilyID as FamilyID, cf.Name as FName,
			L.NodeID as FRelation,  L.Name as Relation, Phone as FPhone
			from svc_Customerfamilydetails cf   WITH(NOLOCK) 
			left join com_lookup L  WITH(NOLOCK) on L.NodeID=cf.Relation
			where cf.customerid=@CustomerID
			
END
 
 
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
 SET NOCOUNT OFF  
RETURN -999   
END CATCH  


GO

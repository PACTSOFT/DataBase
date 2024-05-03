USE PACT2C222
GO
SET ANSI_NULLS, QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spSVC_DeleteCustomer]
	@CustomerID [bigint] = 0,
	@RoleID [bigint],
	@LangID [int] = 1
WITH ENCRYPTION, EXECUTE AS CALLER
AS
BEGIN TRANSACTION
BEGIN TRY  
SET NOCOUNT ON;  
		--Declaration Section
		DECLARE @HasAccess bit,@RowsDeleted bigint,@lft bigint,@rgt bigint,@Width bigint

		--SP Required Parameters Check
		if(@CustomerID=0)
		BEGIN
			RAISERROR('-100',16,1)
		END

		--User acces check
		SET @HasAccess=dbo.fnCOM_HasAccess(@RoleID,51,4)

		IF @HasAccess=0
		BEGIN
			RAISERROR('-105',16,1)
		END

		IF EXISTS(SELECT CustomerID FROM SVC_Customers WHERE CustomerID=@CustomerID AND ParentID=0)
		BEGIN
			RAISERROR('-115',16,1)
		END

		--Fetch left, right extent of Node along with width.
		SELECT @lft = lft, @rgt = rgt, @Width = rgt - lft + 1
		FROM SVC_Customers WITH(NOLOCK) WHERE CustomerID=@CustomerID

	 
		 
		--Delete from exteneded table
		DELETE FROM SVC_CustomersExtended WHERE CustomerID in
		(select CustomerID from SVC_Customers  WHERE lft >= @lft AND rgt <= @rgt)
	
		--Delete from CustomerCostCenter
		DELETE FROM SVC_CustomerCostCenterMap WHERE CustomerID=@CustomerID

	   --Delete From CustomerVehicle
		delete from SVC_CustomersVehicle
		where CustomerID=@CustomerID
	
		--Delete from Family Details
		DELETE FROM SVC_CustomerFamilyDetails WHERE CustomerID=@CustomerID

		--Delete from main table
		DELETE FROM SVC_Customers WHERE lft >= @lft AND rgt <= @rgt

		SET @RowsDeleted=@@rowcount 

	 

		--Delete from Contacts
		 DELETE FROM  COM_ContactsExtended
		WHERE ContactID IN (SELECT CONTACTID FROM COM_CONTACTS WITH(NOLOCK) WHERE FeatureID=51and  FeaturePK=@CustomerID)
		DELETE FROM  COM_Contacts 
		WHERE FeatureID=51 and  FeaturePK=@CustomerID

		--Delete from Notes
		DELETE FROM  COM_Notes 
		WHERE FEATUREID=51 and  FeaturePK=@CustomerID

		--Delete from Files
		DELETE FROM  COM_Files  
		WHERE FEATUREID=51 and  FeaturePK=@CustomerID

		DELETE FROM  COM_Address  
		WHERE FEATUREID=51 and  FeaturePK=@CustomerID

		--Delete from CostCenter Mapping
		DELETE FROM SVC_CustomerCostCenterMap WHERE CostCenterID=51 and NodeID=@CustomerID


		--Update left and right extent to set the tree
		UPDATE SVC_Customers SET rgt = rgt - @Width WHERE rgt > @rgt;
		UPDATE SVC_Customers SET lft = lft - @Width WHERE lft > @rgt;
	

COMMIT TRANSACTION
SET NOCOUNT OFF;  
SELECT ErrorMessage,ErrorNumber FROM COM_ErrorMessages WITH(nolock) 
WHERE ErrorNumber=102 AND LanguageID=@LangID

RETURN @RowsDeleted
END TRY
BEGIN CATCH  
	--Return exception info [Message,Number,ProcedureName,LineNumber]  
	IF ERROR_NUMBER()=50000
	BEGIN
		SELECT ErrorMessage,ErrorNumber FROM COM_ErrorMessages WITH(nolock) WHERE ErrorNumber=ERROR_MESSAGE() AND LanguageID=@LangID
	END
	ELSE IF ERROR_NUMBER()=547
	BEGIN
		SELECT ErrorMessage, ERROR_MESSAGE() AS ServerMessage,ERROR_NUMBER() as ErrorNumber, ERROR_PROCEDURE()as ProcedureName, ERROR_LINE() AS ErrorLine FROM COM_ErrorMessages WITH(nolock)
		WHERE ErrorNumber=-110 AND LanguageID=@LangID
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

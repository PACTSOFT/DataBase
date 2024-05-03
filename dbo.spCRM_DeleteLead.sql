USE PACT2C222
GO
SET ANSI_NULLS, QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spCRM_DeleteLead]
	@LeadID [bigint] = 0,
	@RoleID [int] = 1,
	@LangID [int] = 1
WITH ENCRYPTION, EXECUTE AS CALLER
AS
BEGIN TRANSACTION
BEGIN TRY  
SET NOCOUNT ON;  

		--Declaration Section
		DECLARE @HasAccess bit,@RowsDeleted bigint,@lft bigint,@rgt bigint,@Width bigint

		--SP Required Parameters Check
		if(@LeadID=0)
		BEGIN
			RAISERROR('-100',16,1)
		END
		
			--User acces check
		SET @HasAccess=dbo.fnCOM_HasAccess(@RoleID,86,4)

		IF @HasAccess=0
		BEGIN
			RAISERROR('-105',16,1)
		END
		

		IF((SELECT ParentID FROM CRM_Leads WITH(NOLOCK) WHERE LeadID=@LeadID)=0)
		BEGIN
			RAISERROR('-117',16,1)
		END
		
		--Fetch left, right extent of Node along with width.
		SELECT @lft = lft, @rgt = rgt, @Width = rgt - lft + 1
		FROM CRM_Leads WITH(NOLOCK) WHERE LeadID=@LeadID
		
		
		declare @Tbl as table(id int identity(1,1),LeadID bigint)
		insert into @Tbl(LeadID)
		select LeadID  from CRM_Leads with(nolock) WHERE lft >= @lft AND rgt <= @rgt and IsGroup=0
	  
		IF(EXISTS(SELECT * FROM [INV_DocDetails] WITH(NOLOCK) WHERE RefCCID=86 AND RefNodeid in (select leadid from @Tbl)))
		BEGIN
			RAISERROR('-110',16,1)
		END
		
		IF(EXISTS(SELECT * FROM [ACC_DocDetails] WITH(NOLOCK) WHERE RefCCID=86 AND RefNodeid in (select leadid from @Tbl)))
		BEGIN
			RAISERROR('-110',16,1)
		END
		 
		IF(EXISTS(SELECT * FROM CRM_Opportunities WITH(NOLOCK) WHERE  ConvertFromLeadID in (select leadid from @Tbl)))
		BEGIN
			RAISERROR('-110',16,1)
		END 
		
		IF(EXISTS(SELECT * FROM CRM_Customer WITH(NOLOCK) WHERE  ConvertFromLeadID in (select leadid from @Tbl)))
		BEGIN
			RAISERROR('-110',16,1)
		END
		
		 IF(EXISTS(SELECT VALUE FROM COM_COSTCENTERPREFERENCES WITH(NOLOCK) WHERE COSTCENTERID=86 AND NAME='LEADLINKDIMENSION'))
		 BEGIN
			DECLARE @DIMID BIGINT,@CCID BIGINT
			SET @DIMID=0
			SELECT @DIMID=VALUE FROM COM_COSTCENTERPREFERENCES WITH(NOLOCK) WHERE COSTCENTERID=86 AND NAME='LEADLINKDIMENSION'
			IF(@DIMID>=50000)
			BEGIN
				SELECT @CCID=CCLEADID FROM CRM_LEADS WITH(NOLOCK) WHERE LEADID=@LeadID	
				IF 	@CCID>0	 
				EXEC [spCOM_DeleteCostCenter] @DIMID,@CCID,1,1,1,0
			END
			
		 END	
		 
		
		  
		--Delete from exteneded table
		DELETE FROM CRM_LeadsExtended WHERE LeadID in
		(select LeadID from CRM_Leads  WHERE lft >= @lft AND rgt <= @rgt)
		
			--Delete from CostCenter Mapping
		DELETE FROM COM_CCCCDATA WHERE CostCenterID=86 and NodeID=@LeadID

		--Delete from main table
		DELETE FROM CRM_Leads WHERE lft >= @lft AND rgt <= @rgt

		SET @RowsDeleted=@@rowcount
 

	

		--Update left and right extent to set the tree
		UPDATE CRM_Leads SET rgt = rgt - @Width WHERE rgt > @rgt;
		UPDATE CRM_Leads SET lft = lft - @Width WHERE lft > @rgt;
		
		DELETE FROM crm_assignment WHERE CCID=86 AND CCNODEID IN
		(select LeadID from CRM_Leads  WHERE lft >= @lft AND rgt <= @rgt)
		
		DELETE FROM CRM_ACTIVITIES WHERE CostCenterID=86 AND NodeID IN 
		(select LeadID from CRM_Leads  WHERE lft >= @lft AND rgt <= @rgt)
		
		Delete from CRM_Contacts where featurepk=@LeadID and featureid=86
		Delete From CRM_Leads where LeadID=@LeadID
		DELETE FROM  COM_ContactsExtended
		WHERE ContactID IN (SELECT CONTACTID FROM COM_CONTACTS WITH(NOLOCK) WHERE FeatureID=86 and  FeaturePK=@LeadID)
		Delete from COM_Contacts where featurepk=@LeadID and featureid=86
		Delete From CRM_ProductMapping where costcenterid=86 and ccnodeid=@LeadID
		Delete From CRM_LeadCVRDetails where CCID=86 and ccnodeid=@LeadID
		Delete From CRM_Feedback where CCID=86 and ccnodeid=@LeadID
		update   CRM_CampaignResponse set  ConvertedLeadID=0 where ConvertedLeadID=@LeadID
		update  CRM_CampaignInvites set ConvertedLeadID=0 where ConvertedLeadID=@LeadID
		
		
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

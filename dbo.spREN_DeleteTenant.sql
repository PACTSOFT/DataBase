USE PACT2C222
GO
SET ANSI_NULLS, QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spREN_DeleteTenant]
	@TenantID [bigint] = 0,
	@UserID [bigint] = 0,
	@RoleID [int] = 0,
	@LangID [int] = 1
WITH ENCRYPTION, EXECUTE AS CALLER
AS
BEGIN TRANSACTION
BEGIN TRY  
SET NOCOUNT ON;  
		--Declaration Section
		DECLARE @HasAccess bit,@lft bigint,@rgt bigint,@Width bigint

		--SP Required Parameters Check
		if(@TenantID=0)
		BEGIN
			RAISERROR('-100',16,1)
		END

		--User acces check
		SET @HasAccess=dbo.fnCOM_HasAccess(@RoleID,94,4)

		IF @HasAccess=0
		BEGIN
			RAISERROR('-105',16,1)
		END

		IF EXISTS(SELECT [FirstName] FROM REN_Tenant with(nolock) WHERE TenantID=@TenantID AND TenantID=1)
		BEGIN
			RAISERROR('-115',16,1)
		END

		--Fetch left, right extent of Node along with width.
		SELECT @lft = lft, @rgt = rgt, @Width = rgt - lft + 1
		FROM REN_Tenant WITH(NOLOCK) WHERE TenantID=@TenantID
		
		declare @temp table(id int identity(1,1), TenantID bigint)
		
		insert into @temp
		select DISTINCT TenantID  from REN_Tenant with(nolock) WHERE lft >= @lft AND rgt <= @rgt
		
		declare @i int, @cnt int
		DECLARE @NodeID bigint, @Dimesion bigint 
		set @i=1
		select @cnt=count(*) from @temp
		 
		while @i<=@cnt
		begin
			set @NodeID=0
			set @Dimesion=0
			select  @NodeID = CCNodeID, @Dimesion=CCID from REN_Tenant with(nolock) 
			where TenantID  IN (select TenantID from @temp where id=@i)
			delete from com_ccccdata where costcenterid=94 and nodeid  IN (select TenantID from @temp where id=@i)

			if (@NodeID is not null and @NodeID>0)
			begin
				Update REN_Tenant set CCID=0, CCNodeID=0 where TenantID in
				(select TenantID from @temp where id=@i)
				declare @return_value bigint
			  
				EXEC @return_value = [dbo].[spCOM_DeleteCostCenter]
					@CostCenterID = @Dimesion,
					@NodeID = @NodeID,
					@RoleID=1,
					@UserID = @UserID,
					@LangID = @LangID,
					@CheckLink = 0
				 
				--Deleting from Mapping Table
				Delete from com_docbridge WHERE CostCenterID = 94 AND RefDimensionNodeID = @NodeID AND RefDimensionID = 	@Dimesion					
			end
			set @i=@i+1
		end

		INSERT INTO [dbo].[REN_TenantHistory]
		([TenantID],[TenantCode],[TypeID],[PositionID],[FirstName],[MiddleName],[LastName],[LeaseSignatory],[ContactPerson],[PostingID]
		,[Phone1],[Phone2],[Email],[Fax],[IDNumber],[Profession],[Passport],[Nationality],[PassportIssueDate],[PassportExpiryDate]
		,[SponsorName],[SponsorPassport],[SponsorIssueDate],[SponsorExpiryDate],[License],[LicenseIssuedBy],[LicenseIssueDate]
		,[LicenseExpiryDate],[Description],[Depth],[ParentID],[lft],[rgt],[IsGroup],[CompanyGUID],[GUID],[CreatedBy],[CreatedDate]
		,[ModifiedBy],[ModifiedDate],[CCNodeID],[CCID],[UserName],[Password],[StatusID],[HistoryStatus])
		select 
		[TenantID],[TenantCode],[TypeID],[PositionID],[FirstName],[MiddleName],[LastName],[LeaseSignatory],[ContactPerson],[PostingID]
		,[Phone1],[Phone2],[Email],[Fax],[IDNumber],[Profession],[Passport],[Nationality],[PassportIssueDate],[PassportExpiryDate]
		,[SponsorName],[SponsorPassport],[SponsorIssueDate],[SponsorExpiryDate],[License],[LicenseIssuedBy],[LicenseIssueDate]
		,[LicenseExpiryDate],[Description],[Depth],[ParentID],[lft],[rgt],[IsGroup],[CompanyGUID],[GUID],[CreatedBy],[CreatedDate]
		,[ModifiedBy],[ModifiedDate],[CCNodeID],[CCID],[UserName],[Password],[StatusID],'Deleted'
		from ren_tenant with(nolock) WHERE lft >= @lft AND rgt <= @rgt
	
		insert into Ren_TenantExtendedHistory
		select *,'Deleted' from REN_TenantExtended WHERE Tenantid IN
		(select Tenantid from REN_Tenant with(nolock) WHERE lft >= @lft AND rgt <= @rgt)
		
		DELETE FROM  COM_Files  
		WHERE FEATUREID=94 and  FeaturePK in
		(select TenantID from REN_Tenant with(nolock) WHERE lft >= @lft AND rgt <= @rgt)
		
		DELETE FROM CRM_ACTIVITIES WHERE CostCenterID=94 AND NodeID in
		(select TenantID from REN_Tenant with(nolock) WHERE lft >= @lft AND rgt <= @rgt)
		
		---Delete from Extended Table
     	DELETE FROM REN_TenantExtended WHERE TenantID in
		(select TenantID from REN_Tenant with(nolock) WHERE lft >= @lft AND rgt <= @rgt)
		
		--Delete from main table
		DELETE FROM REN_Tenant WHERE lft >= @lft AND rgt <= @rgt

		--Update left and right extent to set the tree
		UPDATE REN_Tenant SET rgt = rgt - @Width WHERE rgt > @rgt;
		UPDATE REN_Tenant SET lft = lft - @Width WHERE lft > @rgt;
	
		

COMMIT TRANSACTION
SET NOCOUNT OFF;  
SELECT ErrorMessage,ErrorNumber FROM COM_ErrorMessages WITH(nolock) 
WHERE ErrorNumber=102 AND LanguageID=@LangID

RETURN 1
END TRY
BEGIN CATCH 
	if(@return_value=-999)
		return 
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

USE PACT2C222
GO
SET ANSI_NULLS, QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spREN_DeleteUnit]
	@UnitID [bigint] = 0,
	@UserID [bigint] = 1,
	@RoleID [int],
	@LangID [int] = 1
WITH ENCRYPTION, EXECUTE AS CALLER
AS
BEGIN TRANSACTION  
BEGIN TRY    
SET NOCOUNT ON;    
  
	DECLARE @HasAccess bit,@lft bigint,@rgt bigint,@Width bigint  

	--SP Required Parameters Check  
	if(@UnitID=0)  
	BEGIN  
		RAISERROR('-100',16,1)  
	END  

	--User acces check  
	SET @HasAccess=dbo.fnCOM_HasAccess(@RoleID,93,4)  

	IF @HasAccess=0  
	BEGIN  
		RAISERROR('-105',16,1)  
	END  

	IF((SELECT ParentID FROM REN_UNITS WITH(NOLOCK) WHERE UNITID=@UnitID)=0)  
	BEGIN  
		RAISERROR('-117',16,1)  
	END  
  
     
	--Fetch left, right extent of Node along with width.  
	SELECT @lft = lft, @rgt = rgt, @Width = rgt - lft + 1  
	FROM REN_UNITS WITH(NOLOCK) WHERE UNITID=@UnitID    

	declare @tempUnit table(id int identity(1,1), UNITID bigint)  

	insert into @tempUnit  
	select UNITID from REN_UNITS WITH(NOLOCK) WHERE lft >= @lft AND rgt <= @rgt  

	declare @i int, @cnt int  
	DECLARE @CCNodeID bigint, @CCDimesion bigint   
	select @i=1,@cnt=count(*) from @tempUnit  
	 
	while @i<=@cnt  
	begin  
		set @CCNodeID=0  
		set @CCDimesion=0  
		select @CCNodeID = CCNodeID, @CCDimesion=LinkCCID from REN_UNITS WITH(NOLOCK) 
		where UNITID IN (select UNITID from @tempUnit where id=@i)  

		if (@CCNodeID is not null and @CCNodeID>0)  
		begin
		  
			Update REN_UNITS set LinkCCID=0, CCNodeID=0 where UNITID in (select UNITID from @tempUnit where id=@i)
			  
			select @CCNodeID,@CCDimesion
			-- select @NodeID, @Dimesion  
			declare @return_value bigint  
			EXEC @return_value = [dbo].[spCOM_DeleteCostCenter]  
			@CostCenterID = @CCDimesion,  
			@NodeID = @CCNodeID,  
			@RoleID=1,
			@UserID = @UserID,  
			@LangID = @LangID,  
			@CheckLink = 0  
	      
			--Deleting from Mapping Table  
			Delete from com_docbridge WHERE CostCenterID = 93 AND RefDimensionNodeID = @CCNodeID AND RefDimensionID =  @CCDimesion       
		end  
		set @i=@i+1  
	end  
  
    INSERT INTO [REN_UnitsHistory]
	([UnitID],[PropertyID],[Code],[Name],[Status],[CCID],[NodeID],[RentableArea],[BuildUpArea],[FloorLookUpID],[ViewLookUpID]
	,[NoOfBathrooms],[NoOfParkings],[ElectricityCode],[ElectricityKW],[Rent],[RentTypeID],[DiscountPercentage],[DiscountAmount]
	,[AnnualRent],[MonthlyRent],[RentPerSQFT],[Depth],[ParentID],[lft],[rgt],[IsGroup],[CompanyGUID],[GUID],[CreatedBy],[CreatedDate]
	,[ModifiedBy],[ModifiedDate],[TermsConditions],[SalesmanID],[AccountantID],[LandlordID],[UnitStatus],[RentalIncomeAccountID],[RentalReceivableAccountID]
	,[AdvanceRentAccountID],[BankAccount],[BankLoanAccount],[CCNodeID],[LinkCCID],[RentalAccount],[RentPayableAccount],[AdvanceRentPaid]
	,[LocationID],[BasedOn],[ContractID],[PenaltyAccountID],[AdvanceReceivableAccountID],[HistoryStatus])
	select [UnitID],[PropertyID],[Code],[Name],[Status],[CCID],[NodeID],[RentableArea],[BuildUpArea],[FloorLookUpID],[ViewLookUpID]
	,[NoOfBathrooms],[NoOfParkings],[ElectricityCode],[ElectricityKW],[Rent],[RentTypeID],[DiscountPercentage],[DiscountAmount]
	,[AnnualRent],[MonthlyRent],[RentPerSQFT],[Depth],[ParentID],[lft],[rgt],[IsGroup],[CompanyGUID],[GUID],[CreatedBy],[CreatedDate]
	,[ModifiedBy],[ModifiedDate],[TermsConditions],[SalesmanID],[AccountantID],[LandlordID],[UnitStatus],[RentalIncomeAccountID],[RentalReceivableAccountID]
	,[AdvanceRentAccountID],[BankAccount],[BankLoanAccount],[CCNodeID],[LinkCCID],[RentalAccount],[RentPayableAccount],[AdvanceRentPaid]
	,[LocationID],[BasedOn],[ContractID],[PenaltyAccountID],[AdvanceReceivableAccountID],'Deleted'
	from ren_units with(nolock)  WHERE lft >= @lft AND rgt <= @rgt  

	-- --Insert into Units history  Extended  
	--insert into REN_UnitsExtendedHistory  
	--select *,'Deleted' from REN_UnitsExtended WHERE unitid in
	-- (select UnitID REN_UNITS WHERE lft >= @lft AND rgt <= @rgt  )

	delete from REN_UnitsExtended where UNITID IN (SELECT UNITID  FROM REN_UNITS with(nolock) WHERE lft >= @lft AND rgt <= @rgt)  
	delete from com_ccccdata where costcenterid=93 and NodeID IN (SELECT UNITID  FROM REN_UNITS with(nolock) WHERE lft >= @lft AND rgt <= @rgt)  
	
	--Delete from main table  
	DELETE FROM REN_UNITS WHERE lft >= @lft AND rgt <= @rgt  

	--Update left and right extent to set the tree  
	UPDATE REN_UNITS SET rgt = rgt - @Width WHERE rgt > @rgt;  
	UPDATE REN_UNITS SET lft = lft - @Width WHERE lft > @rgt;  

	delete from REN_Particulars where PropertyID=  
	(SELECT PropertyID FROM REN_UNITS WITH(NOLOCK) WHERE UNITID=@UnitID) and UnitID=@UnitID  

	--Delete From CRM_Cases where CASEID=@CASEID  
	Delete from com_docbridge WHERE CostCenterID = 93 AND NodeID = @UnitID  
   
   	Delete from COM_HistoryDetails WHERE CostCenterID = 93 AND NodeID = @UnitID  
 
COMMIT TRANSACTION  
SET NOCOUNT OFF;    
SELECT ErrorMessage,ErrorNumber FROM COM_ErrorMessages WITH(nolock)   
WHERE ErrorNumber=102 AND LanguageID=@LangID  
  
RETURN 1  
END TRY  
BEGIN CATCH    
if(@return_value=-999)
	return -999
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

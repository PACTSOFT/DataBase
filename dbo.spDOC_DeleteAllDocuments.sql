USE PACT2C222
GO
SET ANSI_NULLS, QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spDOC_DeleteAllDocuments]
	@DeletePrefix [bit] = 1,
	@UserID [int] = 0,
	@RoleID [int] = 0,
	@LangID [int] = 1
WITH ENCRYPTION, EXECUTE AS CALLER
AS
BEGIN TRANSACTION      
BEGIN TRY      
SET NOCOUNT ON;    
	--Declaration Section    
	DECLARE @HasAccess bit,@DocID INT,@PrefValue NVARCHAR(500)
	DECLARE @sql nvarchar(max),@tablename nvarchar(200),@CurrentNo INT,@return_value int
	declare @AccDocID INT,@DELETECCID INT    

  
	DECLARE @CostCenterID INT,@I INT,@CNT INT,@Dimesion INT,@VoucherNo NVARCHAR(80),@J INT,@JCNT INT,@NodeID INT
	DECLARE @TblLink As TABLE(ID INT IDENTITY(1,1),CostCenterID INT,LinkDimension INT)
	DECLARE @TblLinkData As TABLE(ID INT IDENTITY(1,1),VoucherNo NVARCHAR(50))
	
	INSERT INTO @TblLink
	select CostCenterID,PrefValue from COM_DocumentPreferences with(nolock)
	where PrefName='DocumentLinkDimension' and PrefValue is not null and PrefValue<>'' and ISNUMERIC(PrefValue)=1 and CONVERT(int,PrefValue)>50000
	
	select @J=1,@I=1,@CNT=COUNT(*) from @TblLink
	
	--select * from @TblLink
	
	while(@I<=@CNT)
	begin
		select @CostCenterID=CostCenterID,@Dimesion=LinkDimension from @TblLink where ID=@I

		select @tablename=tablename from ADM_Features with(nolock) where FeatureID=@CostCenterID
		
		INSERT INTO @TblLinkData
		select VoucherNo FROM INV_DocDetails with(nolock) WHERE CostCenterID=@CostCenterID GROUP BY VoucherNo
		
		--select * from @TblLinkData
		
		SET @sql='UPDATE a SET dcCCNID'+CONVERT(NVARCHAR,(@Dimesion-50000))+'=1 FROM COM_DocCCData a WITH(NOLOCK) '
		EXEC sp_executesql @sql
		
		select @tablename=tablename from ADM_Features with(nolock) where FeatureID=@Dimesion
		
		select @JCNT=ISNULL(MAX(ID),0) from @TblLinkData
		
		while(@J<=@JCNT)
		begin
			select @VoucherNo=VoucherNo from @TblLinkData where ID=@J
			set @sql='select @NodeID=NodeID from '+@tablename+' with(nolock) where Name='''+@VoucherNo+''''
			--print(@sql)
			SET @NodeID=NULL
			EXEC sp_executesql @sql,N'@NodeID INT OUTPUT',@NodeID output			 
			--select @Dimesion,@NodeID
			--select @VoucherNo
			if(@NodeID IS NOT NULL AND @NodeID>1)
			begin
				--select @Dimesion,@NodeID
				EXEC @return_value = dbo.spCOM_DeleteCostCenter
					@CostCenterID = @Dimesion,
					@NodeID = @NodeID,
					@RoleID=1,
					@UserID = @UserID,
					@LangID = @LangID
				--select * from COM_Area
			end
			set @J=@J+1
		end
		delete from @TblLinkData
		set @I=@I+1
	end
	
	DELETE a FROM COM_Notes a WITH(NOLOCK) WHERE FeatureID between 40000 and 50000
	DELETE a FROM COM_Files a WITH(NOLOCK) WHERE FeatureID between 40000 and 50000
	
	if exists (select * from sys.tables with(nolock) where name='CRM_Activities')
	begin
		SET @sql='DELETE a FROM CRM_Activities a WITH(NOLOCK) WHERE CostCenterID between 40000 and 50000' 
		EXEC sp_executesql @sql
	end
	
	--TRUNCATE TABLE COM_DocAddressData
	--TRUNCATE TABLE COM_LCBills
	--TRUNCATE TABLE COM_DocDenominations
	--TRUNCATE TABLE COM_ChequeReturn

	exec sp_MSforeachtable
	@command1='TRUNCATE TABLE ?',
	@whereand=' and object_id IN(Select object_Id from sys.Tables where Name IN(
	''COM_DocAddressData'',''COM_LCBills'',''COM_DocDenominations'',''COM_ChequeReturn'',''REN_ContractDocMapping''))'


	--if exists (select * from sys.tables with(nolock) where name='REN_ContractDocMapping')
	--begin
	--	SET @sql='TRUNCATE TABLE REN_ContractDocMapping' 
	--	EXEC sp_executesql @sql
	--end
	
	--CASE DELETE
	if exists (select * from sys.tables with(nolock) where name='CRM_Cases')
	begin
		SET @sql='declare @Tblcase table(ID int identity(1,1),CaseID INT)
		INSERT INTO @Tblcase(CaseID)
		select CaseID FROM CRM_Cases with(nolock) where SvcContractID IS NOT NULL AND SvcContractID>0
		declare @I int,@CNT int,@NodeID int
		select @I=1,@CNT=count(*) FROM @Tblcase
		WHILE(@I<=@CNT)
		BEGIN
			SELECT @NodeID=CaseID FROM @Tblcase WHERE ID=@I
			exec spCRM_DeleteCase @CASEID=@NodeID,@USERID=1,@LangID=1,@RoleID=1
			SET @I=@I+1
		END'
		EXEC sp_executesql @sql
	end
	
	if (@DeletePrefix is not null and @DeletePrefix=1)	
	BEGIN
		update a 
		set CurrentCodeNumber= (case when CodeNumberRoot>0 then CodeNumberRoot-1 else 0 end)
		FROM COM_CostCenterCodeDef  a WITH(NOLOCK)
		where CostCenterID between 40000 and 50000
		
		delete a 
		from COM_CostCenterCodeDef a WITH(NOLOCK)
		where CostCenterID between 40000 and 50000 and codeprefix<>''
	END
	
	/*

	TRUNCATE TABLE COM_DocCCData
	TRUNCATE TABLE COM_DocNumData
	if exists(select * from sys.tables where name='PAY_DocNumData')
	BEGIN
		set @sql=' TRUNCATE TABLE PAY_DocNumData '
		EXEC sp_executesql @sql
	END	
	TRUNCATE TABLE COM_DocTextData
	TRUNCATE TABLE COM_DocPayTerms
	TRUNCATE TABLE COM_Approvals
	TRUNCATE TABLE com_pospaymodes
	TRUNCATE TABLE INV_SerialStockProduct
	DELETE FROM INV_BatchDetails WHERE InvDocDetailsID>0
	TRUNCATE TABLE INV_TempInfo  
	TRUNCATE TABLE INV_BinDetails   
	TRUNCATE TABLE INV_DocExtraDetails  
	TRUNCATE TABLE COM_Billwise
	TRUNCATE TABLE COM_BillWiseNonAcc  


	--AUDTI DATA
	TRUNCATE TABLE ACC_DocDetails_History_ATUser
	TRUNCATE TABLE INV_DocDetails_History_ATUser
	
	TRUNCATE TABLE COM_DocCCData_History
	TRUNCATE TABLE COM_DocNumData_History
	TRUNCATE TABLE COM_DocTextData_History
	TRUNCATE TABLE ACC_DocDetails_History
	TRUNCATE TABLE INV_DocDetails_History
	
	TRUNCATE TABLE COM_BillwiseHistory
	
	--MAIN TABLES
	TRUNCATE TABLE COM_DocID

	--DELETE FROM ACC_DocDetails WHERE InvDocDetailsID=0
	--DELETE FROM INV_DocDetails WHERE InvDocDetailsID=0
	DELETE FROM ACC_DocDetails
	--TRUNCATE TABLE ACC_DocDetails
	
	DELETE FROM INV_DocDetails
	--TRUNCATE TABLE INV_DocDetails 

	*/

	exec sp_MSforeachtable
	@command1='TRUNCATE TABLE ?',
	@whereand=' and object_id IN(Select object_Id from sys.Tables where Name IN(
	''COM_DocCCData'',''COM_DocNumData'',''PAY_DocNumData'',''COM_DocTextData'',''COM_DocPayTerms''
	,''COM_Approvals'',''com_pospaymodes'',''INV_SerialStockProduct'',''INV_TempInfo'',''INV_BinDetails'',''INV_DocExtraDetails'',''COM_Billwise'',''COM_BillWiseNonAcc''
	,''ACC_DocDetails_History_ATUser'',''INV_DocDetails_History_ATUser'',''COM_DocCCData_History'',''COM_DocNumData_History''
	,''COM_DocTextData_History'',''ACC_DocDetails_History'',''INV_DocDetails_History'',''COM_BillwiseHistory''
	,''COM_DocID'',''ACC_DocDetails'',''INV_DocDetails''))'

	DELETE a FROM INV_BatchDetails a WITH(NOLOCK) WHERE InvDocDetailsID>0
		 
COMMIT TRANSACTION
--ROLLBACK TRANSACTION

SET NOCOUNT OFF;  
SELECT ErrorMessage,ErrorNumber FROM COM_ErrorMessages WITH(nolock) 
WHERE ErrorNumber=102 AND LanguageID=@LangID  
RETURN 1
END TRY
BEGIN CATCH  
	if(@return_value=-999)
	return -999
	--Return exception info Message,Number,ProcedureName,LineNumber  
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

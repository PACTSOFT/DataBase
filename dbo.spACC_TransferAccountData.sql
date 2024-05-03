USE PACT2C222
GO
SET ANSI_NULLS, QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spACC_TransferAccountData]
	@FromID [bigint],
	@ToID [bigint],
	@CostCenterID [bigint],
	@Assign [bit],
	@Contacts [bit],
	@Adress [bit],
	@Notes [bit],
	@Attachments [bit],
	@Activities [bit],
	@WHERE [nvarchar](max),
	@UserID [bigint],
	@RoleID [int],
	@LangID [int] = 1
WITH ENCRYPTION, EXECUTE AS CALLER
AS
BEGIN TRANSACTION
BEGIN TRY  
SET NOCOUNT ON; 
 
	--Declaration Section  
	DECLARE @lft BIGINT,@rgt BIGINT,@Width INT,@Selectedlft BIGINT,@Selectedrgt BIGINT,@SelectedDepth INT,@Depth INT,@ParentID BIGINT  
	DECLARE @Temp TABLE (ID BIGINT) 
	DECLARE @HasAccess BIT,@SelectedIsGroup BIT,@SQL nvarchar(max)
	

	--Check for manadatory paramters  
	IF(@FromID=0 OR @ToID=0)
	BEGIN  
		RAISERROR('-100',16,1)   
	END
	IF(@CostCenterID =2)
	BEGIN
			--User acces check
			SET @HasAccess=dbo.fnCOM_HasAccess(@RoleID,2,6)
			
			IF @HasAccess=0
			BEGIN
				RAISERROR('-105',16,1)
			END
			
			if(@WHERE!='')
			begin
				--For Accounting Vouchers
				set @SQL='update B set B.AccountID='+convert(nvarchar(max),@FromID)+'
				from Acc_DocDetails D 
				join com_docccdata DCC on D.AccDocDetailsID=DCC.AccDocDetailsID
				join COM_Billwise B on B.DocNo=D.VoucherNo
				WHERE D.InvDocDetailsID is null and B.AccountID='+convert(nvarchar,@FromID)+replace(@WHERE,'DCC.dc','B.dc')
				EXEC(@SQL)
				
				set @SQL='UPDATE D set D.DebitAccount='+convert(nvarchar(max),@ToID)+'
				from Acc_DocDetails D 
				join com_docccdata DCC on D.AccDocDetailsID=DCC.AccDocDetailsID
				WHERE D.InvDocDetailsID is null and D.DebitAccount='+convert(nvarchar,@FromID)+@WHERE
				EXEC(@SQL)
				
				set @SQL='UPDATE D set D.CreditAccount='+convert(nvarchar(max),@ToID)+'
				from Acc_DocDetails D 
				join com_docccdata DCC on D.AccDocDetailsID=DCC.AccDocDetailsID
				WHERE D.InvDocDetailsID is null and D.CreditAccount='+convert(nvarchar,@FromID)+@WHERE
				EXEC(@SQL)
				
				set @SQL='UPDATE D set D.BankAccountID='+convert(nvarchar(max),@ToID)+'
				from Acc_DocDetails D 
				join com_docccdata DCC on D.AccDocDetailsID=DCC.AccDocDetailsID
				WHERE D.InvDocDetailsID is null and D.BankAccountID='+convert(nvarchar,@FromID)+@WHERE
				EXEC(@SQL)

				
				--Inventory Vouchers
				set @SQL='UPDATE N set N.remarks=replace(convert(nvarchar(max),remarks),''DebitAccount="'+convert(nvarchar(max),@FromID)+'"'',''DebitAccount="'+convert(nvarchar(max),@ToID)+'"'')
				from Acc_DocDetails D 
				join com_docccdata DCC on D.InvDocDetailsID=DCC.InvDocDetailsID
				join com_docnumdata N on D.InvDocDetailsID=N.InvDocDetailsID
				WHERE D.InvDocDetailsID is not null and DebitAccount='+convert(nvarchar,@FromID)+@WHERE +' and N.remarks is not null and convert(nvarchar(max),N.remarks)<>'''''
				EXEC(@SQL)
				
				set @SQL='UPDATE N set N.remarks=replace(convert(nvarchar(max),remarks),''CreditAccount="'+convert(nvarchar(max),@FromID)+'"'',''CreditAccount="'+convert(nvarchar(max),@ToID)+'"'')
				from Acc_DocDetails D 
				join com_docccdata DCC on D.InvDocDetailsID=DCC.InvDocDetailsID
				join com_docnumdata N on D.InvDocDetailsID=N.InvDocDetailsID
				WHERE D.InvDocDetailsID is not null and CreditAccount='+convert(nvarchar,@FromID)+@WHERE +' and N.remarks is not null and convert(nvarchar(max),N.remarks)<>'''''
				EXEC(@SQL)
				
				set @SQL='update B set B.AccountID='+convert(nvarchar(max),@FromID)+'
				from Acc_DocDetails D 
				join com_docccdata DCC on D.InvDocDetailsID=DCC.InvDocDetailsID
				join COM_Billwise B on B.DocNo=D.VoucherNo
				WHERE D.InvDocDetailsID is not null and B.AccountID='+convert(nvarchar,@FromID)+replace(@WHERE,'DCC.dc','B.dc')
				EXEC(@SQL)
				
				set @SQL='UPDATE D set D.DebitAccount='+convert(nvarchar(max),@ToID)+'
				from Acc_DocDetails D 
				join com_docccdata DCC on D.InvDocDetailsID=DCC.InvDocDetailsID
				WHERE D.InvDocDetailsID is not null and D.DebitAccount='+convert(nvarchar,@FromID)+@WHERE
				print(@SQL)
				EXEC(@SQL)
				
				set @SQL='UPDATE D set D.CreditAccount='+convert(nvarchar(max),@ToID)+'
				from Acc_DocDetails D 
				join com_docccdata DCC on D.InvDocDetailsID=DCC.InvDocDetailsID
				WHERE D.InvDocDetailsID is not null and D.CreditAccount='+convert(nvarchar,@FromID)+@WHERE
				print(@SQL)
				EXEC(@SQL)
				
				set @SQL='UPDATE D set D.DebitAccount='+convert(nvarchar(max),@ToID)+'
				from INV_DocDetails D 
				join com_docccdata DCC on D.InvDocDetailsID=DCC.InvDocDetailsID
				WHERE D.DebitAccount='+convert(nvarchar,@FromID)+@WHERE
				EXEC(@SQL)
				
				set @SQL='UPDATE D set D.CreditAccount='+convert(nvarchar(max),@ToID)+'
				from INV_DocDetails D 
				join com_docccdata DCC on D.InvDocDetailsID=DCC.InvDocDetailsID
				WHERE D.CreditAccount='+convert(nvarchar,@FromID)+@WHERE
				EXEC(@SQL)
				
				--UPDATE REN_Contract SET RentAccID=@ToID WHERE RentAccID=@FromID
				
				--UPDATE REN_Contract SET IncomeAccID=@ToID WHERE IncomeAccID=@FromID
				
				--UPDATE REN_ContractParticulars SET DebitAccID=@ToID WHERE DebitAccID=@FromID
				
				--UPDATE REN_ContractParticulars SET CreditAccID=@ToID WHERE CreditAccID=@FromID

				--UPDATE REN_ContractParticulars SET CreditAccID=@ToID WHERE CreditAccID=@FromID
				
				--UPDATE REN_ContractPayTerms SET DebitAccID=@ToID WHERE DebitAccID=@FromID

				--For Inventory Vouchers
	
				--UPDATE COM_Billwise SET DiscAccountID=@ToID WHERE DiscAccountID=@FromID
				
				--update SVC_Customers SET AccountName =@ToID WHERE AccountName=@FromID
			end
			else
			begin
				--For Accounting Vouchers
				UPDATE Acc_DocDetails SET DebitAccount=@ToID WHERE DebitAccount=@FromID
				
				UPDATE Acc_DocDetails SET CreditAccount=@ToID WHERE CreditAccount=@FromID
				
				UPDATE Acc_DocDetails SET BankAccountID=@ToID WHERE BankAccountID=@FromID
				
				UPDATE REN_Contract SET RentAccID=@ToID WHERE RentAccID=@FromID
				
				UPDATE REN_Contract SET IncomeAccID=@ToID WHERE IncomeAccID=@FromID
				
				UPDATE REN_ContractParticulars SET DebitAccID=@ToID WHERE DebitAccID=@FromID
				
				UPDATE REN_ContractParticulars SET CreditAccID=@ToID WHERE CreditAccID=@FromID

				UPDATE REN_ContractParticulars SET CreditAccID=@ToID WHERE CreditAccID=@FromID
				
				UPDATE REN_ContractPayTerms SET DebitAccID=@ToID WHERE DebitAccID=@FromID

				--For Inventory Vouchers
				UPDATE Inv_DocDetails SET DebitAccount=@ToID WHERE DebitAccount=@FromID

				UPDATE Inv_DocDetails SET CreditAccount=@ToID WHERE CreditAccount=@FromID

				--For BillWise
				UPDATE COM_Billwise SET AccountID=@ToID WHERE AccountID=@FromID

				UPDATE COM_Billwise SET DiscAccountID=@ToID WHERE DiscAccountID=@FromID
				
				update SVC_Customers SET AccountName =@ToID WHERE AccountName=@FromID
				
				update com_docnumdata
				set remarks=replace(convert(nvarchar(max),remarks),'DebitAccount="'+convert(nvarchar(max),@FromID)+'"','DebitAccount="'+convert(nvarchar(max),@ToID)+'"')
				where remarks is not null and convert(nvarchar(max),remarks)<>''
				
				update com_docnumdata
				set remarks=replace(convert(nvarchar(max),remarks),'CreditAcount="'+convert(nvarchar(max),@FromID)+'"','CreditAcount="'+convert(nvarchar(max),@ToID)+'"')
				where remarks is not null and convert(nvarchar(max),remarks)<>''
			end

	END
	IF(@CostCenterID =3)
	BEGIN
			--User acces check
			SET @HasAccess=dbo.fnCOM_HasAccess(@RoleID,3,6)
			
			IF @HasAccess=0
			BEGIN
				RAISERROR('-105',16,1)
			END 

			--For Inventory Vouchers 
			UPDATE Inv_DocDetails SET ProductID=@ToID WHERE ProductID=@FromID 
	 	
			UPDATE INV_Batches SET ProductID=@ToID WHERE ProductID=@FromID  
		  	
			UPDATE PRD_BillOfMaterial SET ProductID=@ToID WHERE ProductID=@FromID 
		  	 
			UPDATE PRD_BOMProducts  SET ProductID=@ToID WHERE  ProductID=@FromID
			
			UPDATE PRD_JobOuputProducts  SET ProductID=@ToID WHERE  ProductID=@FromID
		  	
			UPDATE CRM_Cases SET ProductID=@ToID WHERE ProductID=@FromID
			
			UPDATE CRM_CampaignProducts SET ProductID=@ToID WHERE ProductID=@FromID 

			UPDATE CRM_CampaignResponse SET ProductID=@ToID WHERE ProductID=@FromID
		  	
			UPDATE CRM_LeadCVRDetails SET Product=@ToID WHERE Product=@FromID 
			
			UPDATE CRM_ProductMapping SET ProductID=@ToID WHERE ProductID=@FromID 
			   
			UPDATE SVC_ServicePartsInfo SET ProductID=@ToID WHERE ProductID=@FromID
			
			UPDATE SVC_ServicePartsInfoHistory SET ProductID=@ToID WHERE ProductID=@FromID
  		 
	END
	ELSE IF(@CostCenterID=50051)
	BEGIN
			--User acces check
			SET @HasAccess=dbo.fnCOM_HasAccess(@RoleID,@CostCenterID,6)
			IF @HasAccess=0
			BEGIN
				RAISERROR('-105',16,1)
			END
			
			UPDATE COM_DOCCCDATA SET dcCCNID51=@ToID WHERE dcCCNID51=@FromID
			
			UPDATE COM_HISTORYDETAILS SET NodeID=@ToID WHERE NodeID=@FromID AND CostCenterID=50051
			
			UPDATE COM_CCCCData SET NodeID=@ToID WHERE NodeID=@FromID AND CostCenterID=50051
			
			UPDATE PAY_EmpDetail SET EmployeeID=@ToID WHERE EmployeeID=@FromID
			
			UPDATE pay_empaccountslinking SET EmpSeqNo=@ToID WHERE EmpSeqNo=@FromID
			
			UPDATE pay_employeeLeaveDetails SET EmployeeID=@ToID WHERE EmployeeID=@FromID
			
			UPDATE PAY_EmpMonthlyAdjustments SET EmpSeqNo=@ToID WHERE EmpSeqNo=@FromID
			
			UPDATE PAY_EmpMonthlyArrears SET EmpSeqNo=@ToID WHERE EmpSeqNo=@FromID
			
			UPDATE PAY_EmpMonthlyDues SET EmpSeqNo=@ToID WHERE EmpSeqNo=@FromID
			
			UPDATE PAY_EmpPay SET EmployeeID=@ToID WHERE EmployeeID=@FromID
			
			UPDATE PAY_EmpTaxComputation SET EmpNode=@ToID WHERE EmpNode=@FromID
			
			UPDATE PAY_EmpTaxDeclaration SET EmpNode=@ToID WHERE EmpNode=@FromID
			
			UPDATE PAY_EmpTaxHRAInfo SET EmpNode=@ToID WHERE EmpNode=@FromID
			
			UPDATE PAY_FinalSettlement SET EmpSeqNo=@ToID WHERE EmpSeqNo=@FromID
			
			UPDATE PAY_LoanGuarantees SET GEmpSeqNo=@ToID WHERE GEmpSeqNo=@FromID
			
			
	END
	ELSE IF(@CostCenterID>50000)
	BEGIN
			--User acces check
			SET @HasAccess=dbo.fnCOM_HasAccess(@RoleID,@CostCenterID,6)
			
			IF @HasAccess=0
			BEGIN
				RAISERROR('-105',16,1)
			END
			declare @DSQL nvarchar(max), @CCName nvarchar(50)
			set @CCName= 'CCNID'+CONVERT(nvarchar,@CostCenterID-50000) 
				
			--For Dimension Data 
			set @DSQL='UPDATE COM_CCCCData SET '+@CCName+'='+Convert(nvarchar,@ToID)+' WHERE '+@CCName+'='+Convert(nvarchar,@FromID)+''
			--print (@DSQL)
			exec (@DSQL)
			set @DSQL=''
			
			set @CCName= 'dcCCNID'+CONVERT(nvarchar,@CostCenterID-50000) 
			--For Dimension Document data
			set @DSQL='UPDATE COM_DocCCData SET '+@CCName+'='+Convert(nvarchar,@ToID)+' WHERE '+@CCName+'='+Convert(nvarchar,@FromID)+''
			--print (@DSQL)
			exec (@DSQL)
			set @DSQL=''
			
			--For BillWise
			set @DSQL='UPDATE COM_Billwise SET '+@CCName+'='+Convert(nvarchar,@ToID)+' WHERE '+@CCName+'='+Convert(nvarchar,@FromID)+''
			--print (@DSQL)
			exec (@DSQL)
			
			IF(@CostCenterID = 50068)
			BEGIN
			
			UPDATE COM_CC50051 SET iBank=@ToID WHERE iBank=@FromID
			
			UPDATE COM_DOCTEXTDATA SET dcAlpha15=Convert(nvarchar,@ToID) 
			FROM COM_DOCTEXTDATA T JOIN INV_DOCDETAILS I ON I.INVDOCDETAILSID=T.INVDOCDETAILSID
			WHERE dcAlpha15=Convert(nvarchar,@FromID) AND I.COSTCENTERID=40054
			
			END
			
			UPDATE COM_HISTORYDETAILS SET HistoryNodeID=@ToID WHERE HistoryNodeID=@FromID AND HistoryCCID=@CostCenterID AND CostCenterID=50051
			
	END
	ELSE IF(@CostCenterID =83)
	BEGIN
		--For Dimension Document data
		UPDATE COM_DocCCData SET CustomerID=@ToID WHERE CustomerID=@FromID
	END

	if(@Assign=1)
	begin
		if(@CostCenterID=7)
		begin
			IF NOT EXISTS (SELECT ParentNodeID FROM COM_CostCenterCostCenterMap WITH(NOLOCK) 
			WHERE ParentCostCenterID=@CostCenterID and ParentNodeID=@ToID)
				INSERT INTO [COM_CostCenterCostCenterMap]([ParentCostCenterID],[ParentNodeID],[CostCenterColID],[CostCenterID],[NodeID],[GUID],[Description],[CreatedBy],[CreatedDate],[CompanyGuid])
				SELECT [ParentCostCenterID],@ToID,[CostCenterColID],[CostCenterID],[NodeID],[GUID],[Description],[CreatedBy],CONVERT(FLOAT,GETDATE()),'Clone'
				FROM COM_CostCenterCostCenterMap WITH(NOLOCK) 
				WHERE ParentCostCenterID=@CostCenterID and ParentNodeID=@FromID
			
			IF NOT EXISTS (SELECT NodeID FROM COM_CostCenterCostCenterMap WITH(NOLOCK) 
			WHERE CostCenterID=@CostCenterID and NodeID=@ToID)
				INSERT INTO [COM_CostCenterCostCenterMap]([ParentCostCenterID],[ParentNodeID],[CostCenterColID],[CostCenterID],[NodeID],[GUID],[Description],[CreatedBy],[CreatedDate],[CompanyGuid])
				SELECT [ParentCostCenterID],[ParentNodeID],[CostCenterColID],[CostCenterID],@ToID,[GUID],[Description],[CreatedBy],CONVERT(FLOAT,GETDATE()),'Clone'
				FROM COM_CostCenterCostCenterMap WITH(NOLOCK) 
				WHERE CostCenterID=@CostCenterID and NodeID=@FromID
		end 
		else
		begin
			DELETE CCMP1 from COM_CostCenterCostCenterMap CCMP WITH(NOLOCK)
			JOIN COM_CostCenterCostCenterMap CCMP1 WITH(NOLOCK) 
			ON CCMP1.ParentCostCenterID=CCMP.ParentCostCenterID AND CCMP1.CostCenterID=CCMP.CostCenterID AND CCMP1.NodeID=CCMP.NodeID
			where CCMP.ParentCostCenterID=@CostCenterID  and CCMP.ParentNodeID=@ToID and CCMP1.ParentNodeID=@FromID

			DELETE CCMP1 from COM_CostCenterCostCenterMap CCMP WITH(NOLOCK)
			JOIN COM_CostCenterCostCenterMap CCMP1 WITH(NOLOCK) 
			ON CCMP1.ParentCostCenterID=CCMP.ParentCostCenterID AND CCMP1.CostCenterID=CCMP.CostCenterID AND CCMP1.ParentNodeID=CCMP.ParentNodeID
			where CCMP.CostCenterID=@CostCenterID  and CCMP.NodeID=@ToID and CCMP1.NodeID=@FromID
		
			update COM_CostCenterCostCenterMap 
			set ParentNodeID=@ToID
			where ParentCostCenterID=@CostCenterID and ParentNodeID=@FromID
			
			update COM_CostCenterCostCenterMap 
			set NodeID=@ToID
			where CostCenterID=@CostCenterID and NodeID=@FromID 
		end
	
	end
	
	if(@Contacts=1)
	begin
		if(select count(*) from COM_Contacts where FeatureID=@CostCenterID and FeaturePK=@ToID)>0
		begin
			update COM_Contacts 
			set AddressTypeID=2,FeaturePK=@ToID
			where FeatureID=@CostCenterID and FeaturePK=@FromID
		end
		else
		begin
			update COM_Contacts 
			set FeaturePK=@ToID
			where FeatureID=@CostCenterID and FeaturePK=@FromID
		end
	end
	
	if(@Adress=1)
	begin
		if(select count(*) from COM_Address where FeatureID=@CostCenterID and FeaturePK=@ToID)>0
		begin
			update COM_Address 
			set AddressTypeID=2,FeaturePK=@ToID
			where FeatureID=@CostCenterID and FeaturePK=@FromID
		end
		else
		begin
			update COM_Address 
			set FeaturePK=@ToID
			where FeatureID=@CostCenterID and FeaturePK=@FromID
		end
	end
	
	if(@Notes=1)
	begin
		update COM_Notes 
		set FeaturePK=@ToID
		where FeatureID=@CostCenterID and FeaturePK=@FromID
	end
	
	if(@Attachments=1)
	begin
		update COM_Files 
		set FeaturePK=@ToID
		where FeatureID=@CostCenterID and FeaturePK=@FromID
	end
	
	if(@Activities=1)
	begin
		update CRM_Activities 
		set NodeID=@ToID
		where CostCenterID=@CostCenterID and NodeID=@FromID
	end
	
		
COMMIT TRANSACTION
--ROLLBACK TRANSACTION
SET NOCOUNT OFF;
SELECT ErrorMessage,ErrorNumber FROM COM_ErrorMessages WITH(nolock) 
WHERE ErrorNumber=106 AND LanguageID=@LangID
RETURN 1
END TRY
BEGIN CATCH  
	--Return exception info [Message,Number,ProcedureName,LineNumber]  
	IF ERROR_NUMBER()=50000
	BEGIN
		 SELECT ErrorMessage, ERROR_MESSAGE() AS ServerMessage,ERROR_NUMBER() as ErrorNumber, ERROR_PROCEDURE()as ProcedureName, ERROR_LINE() AS ErrorLine
		 FROM COM_ErrorMessages WITH(nolock) WHERE ErrorNumber=ERROR_MESSAGE() AND LanguageID=@LangID
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

USE PACT2C222
GO
SET ANSI_NULLS, QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spPRD_GetBOMDetails]
	@BOMID [bigint] = 0,
	@UserID [bigint],
	@LangID [int] = 1,
	@RoleID [int] = 0
WITH ENCRYPTION, EXECUTE AS CALLER
AS
BEGIN TRY	
SET NOCOUNT ON

		SELECT *,convert(datetime,BOMDate) as 'Date' 
		FROM PRD_BillOfMaterial WITH(NOLOCK) 	
		WHERE BOMID=@BOMID

		SELECT BP.*,P.ProductName,P.ProductCOde,U.BaseName, U.UnitName UOM,P.StatusID
		FROM  [PRD_BOMProducts] BP with(nolock) 
		join INV_Product P with(nolock) on BP.ProductID=P.ProductID
		left join COM_UOM U WITH(NOLOCK) on BP.UOMID=U.UOMID
		WHERE BP.BOMID=@BOMID and BP.ProductUse=1 
		
		SELECT BE.*,c.AccountName CRAccountName,d.AccountName DRAccountName 
		FROM  [PRD_Expenses] BE with(nolock)
		left join Acc_Accounts c WITH(NOLOCK) on BE.CreditAccountID=c.AccountID	
		left join Acc_Accounts d WITH(NOLOCK) on BE.DebitAccountID=d.AccountID	
		WHERE BE.BOMID=@BOMID
		
		--SELECT BR.*,M.ResourceName,M.CreditAccount,M.DebitAccount
		--FROM  [PRD_BOMResources] BR  with(nolock)
		--join PRD_Resources M WITH(NOLOCK) on BR.ResourceID=M.ResourceID				
		--WHERE BR.BOMID=@BOMID		
		declare @MachineDim nvarchar(max)
		select @MachineDim=Value from COM_CostCenterPreferences with(nolock) where Name='MachineDimension'
		if(LEN(@MachineDim)>0 and ISNUMERIC(@MachineDim)=1 and convert(int,@MachineDim)>50000)
		begin
			select @MachineDim=TableName from ADM_Features with(nolock) where FeatureID=convert(int,@MachineDim)
			set @MachineDim='SELECT BR.*,D.Name ResourceName,d.purchaseaccount DebitAccount,d.salesaccount CreditAccount
			FROM  [PRD_BOMResources] BR with(nolock)
			INNER JOIN '+@MachineDim+' D with(nolock) ON BR.ResourceID=D.NodeID
			WHERE BR.BOMID='+convert(nvarchar,@BOMID)			
			exec(@MachineDim)
		end
		else
		begin
			SELECT BR.*,'' ResourceName
			FROM  [PRD_BOMResources] BR  with(nolock)
			WHERE BR.BOMID=@BOMID
		end
		
		
		select * from PRD_BillOfMaterial with(nolock) where isgroup=1

		SELECT BP.*,P.ProductName ,U.BaseName,U.UnitName,P.ProductCode,P.StatusID,BS.lft 
		FROM  [PRD_BOMProducts] BP with(nolock)
		join INV_Product P WITH(NOLOCK) on BP.ProductID=P.ProductID 
		join PRD_BOMStages BS with(nolock) on BS.BOMID=BP.BOMID AND BS.StageID=BP.StageID 
		left join COM_UOM U WITH(NOLOCK) on BP.UOMID=U.UOMID
		WHERE BP.BOMID=@BOMID and BP.ProductUse=2

		--Getting data from BOM extended table
		SELECT * FROM  PRD_BillOfMaterialExtended WITH(NOLOCK) 
		WHERE BOMID=@BOMID
		
		SELECT * FROM COM_CCCCDATA  with(nolock)
		WHERE NodeID = @BOMID AND CostCenterID=76 

		select * from PRD_ProductionMethod with(nolock)
		where BOMID=@BOMID and MOID is null order by SequenceNo
		
		declare @StageDim nvarchar(max)
		select @StageDim=Value from COM_CostCenterPreferences with(nolock) where Name='StageDimension'
		if(LEN(@StageDim)>0 and ISNUMERIC(@StageDim)=1 and convert(int,@StageDim)>50000)
		begin
			select @StageDim=TableName from ADM_Features with(nolock) where FeatureID=convert(int,@StageDim)
			set @StageDim='SELECT S.*,D.Code,D.Name FROM PRD_BOMStages S with(nolock)
			INNER JOIN '+@StageDim+' D with(nolock) ON S.StageNodeID=D.NodeID
			WHERE BOMID='+convert(nvarchar,@BOMID)+' ORDER BY S.lft'
			print(@StageDim)
			exec(@StageDim)
		end
		else
		begin
			SELECT * FROM PRD_BOMStages with(nolock)
			WHERE BOMID=@BOMID
			ORDER BY lft
		end
		
		--WorkFlow
		EXEC spCOM_CheckCostCentetWFApprove 76,@BOMID,@UserID,@RoleID
		
SET NOCOUNT OFF
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

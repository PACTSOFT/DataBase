USE PACT2C222
GO
SET ANSI_NULLS, QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spSVC_GetTaxFileds]
	@UserID [bigint],
	@LangID [int] = 1
WITH ENCRYPTION, EXECUTE AS CALLER
AS
BEGIN TRANSACTION  
BEGIN TRY  
SET NOCOUNT ON;

--		SELECT *,UserColumnName ResourceData--(SELECT TOP 1 ResourceName FROM COM_LanguageResources)
--		FROM ADM_CostCenterDef WITH(NOLOCK)
--		WHERE CostCenterID=59 AND SysColumnName LIKE 'dcNum%'
	

		--Getting Costcenter Fields  
		SELECT  C.CostCenterColID,R.ResourceData,R.ResourceData as UserColumnName,C.ResourceID,C.SysColumnName,C.UserColumnType,C.ColumnDataType,C.RowNo,C.ColumnNo,C.ColumnSpan,
				C.UserDefaultValue,C.UserProbableValues,C.IsMandatory,C.IsEditable,C.IsVisible,C.ColumnCCListViewTypeID,
				C.IsCostCenterUserDefined,isnull(C.UIwidth,100) UIWidth,C.IsColumnUserDefined,C.ColumnCostCenterID,C.FetchMaxRows,C.SectionID,C.SectionName,C.SectionSeqNumber,
				DD.DebitAccount, DA.AccountName as DebitAccountName,
				DD.CreditAccount, CA.AccountName as CreditAccountName,
				DD.Formula,DD.PostingType,DD.RoundOff,
				DD.IsRoundOffEnabled,DD.IsDrAccountDisplayed,DD.IsCrAccountDisplayed,DD.IsDistributionEnabled,DD.DistributionColID,
				C.IsEditable  ,DV.NumFieldEditOptionID,DV.IsVisible,DV.TabOptionID,DV.ActionOptionID,DD.IsCalculate
		FROM ADM_CostCenterDef C WITH(NOLOCK)
		LEFT JOIN COM_LanguageResources R ON R.ResourceID=C.ResourceID AND R.LanguageID=@LangID
		INNER JOIN ADM_DocumentDef DD ON DD.CostCenterColID=C.CostCenterColID 
		LEFT JOIN ADM_DocumentViewDef DV ON DV.CostCenterColID=C.CostCenterColID 
		LEFT JOIN ACC_accounts CA on dd.CreditAccount=ca.Accountid
		LEFT JOIN ACC_accounts DA on dd.DebitAccount=da.Accountid
		WHERE C.CostCenterID  =59 AND C.SysColumnName LIKE 'dcNum%' and c.IsColumninUse=1
			--AND ((C.IsColumnUserDefined=1 AND C.IsColumnInUse=1))

		--Getting Costcenter Fields  
		SELECT  C.CostCenterColID
		FROM ADM_CostCenterDef C WITH(NOLOCK)
		WHERE C.CostCenterID  =59 
		AND C.SysColumnName LIKE 'dcNum%'
			AND C.CostCenterColID NOT IN (SELECT CostCenterColID FROM ADM_DocumentDef WHERE CostCenterID=59)
		--ORDER BY C.SectionID,C.SectionSeqNumber
		
		-- Getting details of costcenters in adm_Costcenterdef
		select distinct A.CostCenterID,A.CostCenterColID,f.Name as CostCenterName,C.ResourceData as UserColumnName, A.SysColumnName, A.ColumnCostCenterID
		from ADM_CostCenterDef A 
		 join Com_LanguageResources C on C.ResourceID=A.ResourceID and C.LanguageID=1
		 join adm_features f on f.featureid=a.costcenterid
		where costcenterid=59 and (columncostcenterid in (2,3,51) or columncostcenterid between 50000 and 50050)
		
	 	 --Getting Details of All Costcenter account fields  from Adm_CostCenterDef
		 select distinct A.CostCenterID,A.CostCenterColID,f.Name as CostCenterName,C.ResourceData as UserColumnName, A.SysColumnName
		 from ADM_CostCenterDef A 
		 join Com_LanguageResources C on C.ResourceID=A.ResourceID and C.LanguageID=1
		 join adm_features f on f.featureid=a.costcenterid
		 where  (IsColumnInUse=1) 
		  and ((CostCenterID between 50000 and 50050) or CostCenterID in (2,3,51))  
		 and CostCenterID in (select columncostcenterid from adm_Costcenterdef where costcenterid=59)
		 and columncostcenterid=2
		 order by CostCenterID
	 

COMMIT TRANSACTION 
SET NOCOUNT OFF;
RETURN 1
END TRY
BEGIN CATCH  
		--Return exception info [Message,Number,ProcedureName,LineNumber]  
		IF ERROR_NUMBER()=50000
		BEGIN
			SELECT ErrorMessage,ErrorNumber FROM COM_ErrorMessages WITH(NOLOCK) WHERE ErrorNumber=ERROR_MESSAGE() AND LanguageID=@LangID
		END
		ELSE
		BEGIN
			SELECT ErrorMessage, ERROR_MESSAGE() AS ServerMessage,ERROR_NUMBER() as ErrorNumber, ERROR_PROCEDURE()as ProcedureName, ERROR_LINE() AS ErrorLine
			FROM COM_ErrorMessages WITH(NOLOCK) WHERE ErrorNumber=-999 AND LanguageID=@LangID
		END
ROLLBACK TRANSACTION
SET NOCOUNT OFF  
RETURN -999   
END CATCH


GO

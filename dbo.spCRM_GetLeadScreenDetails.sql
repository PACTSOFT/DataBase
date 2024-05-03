USE PACT2C222
GO
SET ANSI_NULLS, QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spCRM_GetLeadScreenDetails]
	@COSTCENTERID [bigint] = 0,
	@UserID [bigint],
	@LangID [int] = 1
WITH ENCRYPTION, EXECUTE AS CALLER
AS
BEGIN TRANSACTION
BEGIN TRY	
SET NOCOUNT ON
		
		DECLARE @PREFVALUE NVARCHAR(300),@cID bigint
		IF @COSTCENTERID=86
		BEGIN
			SET @PREFVALUE='LEADLINKDIMENSION'
			set @cID=115
		END	
		ELSE IF @COSTCENTERID=89
		BEGIN
		 SET @PREFVALUE='OPPLINKDIMENSION'		 			
		 set @cID=154
		END	
		ELSE IF @COSTCENTERID=73
		BEGIN
		 SET @PREFVALUE='CasesLINKDIMENSION'
		 set @cID=156
		END 
		declare @n nvarchar(50)
		select @n=NAME FROM ADM_FEATURES WHERE FEATUREID =(SELECT ISNULL(VALUE,0) FROM    COM_COSTCENTERPREFERENCES WHERE CostCenterID=@COSTCENTERID AND Name=@PREFVALUE)
		
		--Getting Service ticket fields 
		select C.CostCenterColID,R.ResourceData,R.ResourceData as UserColumnName,C.ResourceID,C.SysColumnName,C.UserColumnType,C.ColumnDataType,C.RowNo,C.ColumnNo,C.ColumnSpan,
				C.UserDefaultValue,C.UserProbableValues,C.IsMandatory,C.IsEditable,C.IsVisible,C.ColumnCCListViewTypeID,
				C.IsCostCenterUserDefined
		FROM ADM_CostCenterDef C WITH(NOLOCK) 
		LEFT JOIN COM_LanguageResources R ON R.ResourceID=C.ResourceID AND R.LanguageID=@LangID
		where C.CostCenterID in (@COSTCENTERID,@cID) and C.IsColumninUse=1
		UNION 
		select C.CostCenterColID,
		CASE WHEN (C.COSTCENTERID=@cID) THEN  'Product_'+@n else @n end,
		 CASE WHEN (C.COSTCENTERID=@cID) THEN  'Product_'+@n else @n end  UserColumnName,
		  C.ResourceID,C.SysColumnName,C.UserColumnType,C.ColumnDataType,C.RowNo,C.ColumnNo,C.ColumnSpan,
				C.UserDefaultValue,C.UserProbableValues,C.IsMandatory,C.IsEditable,C.IsVisible,C.ColumnCCListViewTypeID,
				C.IsCostCenterUserDefined
		FROM ADM_CostCenterDef C WITH(NOLOCK) 
		LEFT JOIN COM_LanguageResources R ON R.ResourceID=C.ResourceID AND R.LanguageID=@LangID
		where C.CostCenterID in (@COSTCENTERID,@cID)  AND C.IsColumninUse=0
		and SYSCOLUMNNAME = 
		(SELECT 'CCNID'+CONVERT(VARCHAR,VALUE-50000) FROM COM_COSTCENTERPREFERENCES WHERE CostCenterID=@COSTCENTERID AND Name=@PREFVALUE)
		 
		
		EXEC [spCRM_GetPreferencesatCRM] @COSTCENTERID,@UserID,@LangID
		--SELECT     CostCenterID, DocumentName, IsInventory, DocumentType FROM ADM_DocumentTypes where IsInventory=1 and Costcenterid in 
		--(select convert(bigint,Value) from com_costcenterpreferences where costcenterid=59 and Value <> 'False' and Value <>'0')
		
		 --Getting Details of All Documents from Adm_CostCenterDef
		 select distinct A.CostCenterID,A.CostCenterColID,A.CostCenterName,C.ResourceData as UserColumnName, A.SysColumnName
		 from ADM_CostCenterDef A 
		 join Com_LanguageResources C on C.ResourceID=A.ResourceID   AND C.LanguageID=@LangID
		 where  (IsColumnUserDefined=0  or IsColumnInUse=1) and
		  SysColumnName NOT LIKE '%dcCurrID%' and SysColumnName NOT LIKE '%dcExchRT%'  
		  and  SysColumnName NOT LIKE '%dcCalcNum%' and SysColumnName NOT LIKE '%dcCalcNum%' 
		  and SysColumnName NOT LIKE '%dcCalcNum%' and SysColumnName <> 'UOMConversion'   AND SysColumnName <> 'UOMConvertedQty' 
		  OR  (SysColumnName LIKE '%acAlpha%' and SysColumnName LIKE '%CCNID%' )
		   OR  (SysColumnName LIKE '%opAlpha%' and SysColumnName LIKE '%CCNID%' )
		  and CostCenterID between 40000 and 50000 or (CostCenterID=89 AND IsColumnInUse=1) or(CostCenterID=2 AND IsColumnInUse=1) or (CostCenterID=83 AND IsColumnInUse=1)
		
		 union
		  select 0 CostCenterID,0 CostCenterColID,'' CostCenterName,''  UserColumnName,'' SysColumnName
		  order by CostCenterID
		 
		  
		 --Getting details of Mapped voucher
		 select * from COM_DocumentLinkDef where CostCenterIDBase=@COSTCENTERID

		select dl.DocumentLinkDeFID, dl.CostCenterColIDBase, C.ResourceData  as BUserColumnName,
		 b.SysColumnName as BSysColumnName, dl.CostCenterColIDLinked, l.UserColumnName as LUserColumnName,
		 l.SysColumnName as LSysColumnName,
		 D.CostCenterIDLinked Costcenterid,b.Costcenterid BCostcenterid,D.Mode
		 from COM_DocumentLinkDetails dl
		 left join ADM_CostCenterDef b on dl.CostCenterColIDBase=b.CostCenterColID
		 left join Com_LanguageResources C on C.ResourceID=b.ResourceID   AND C.LanguageID=@LangID
		 left join ADM_CostCenterDef l on dl.CostCenterColIDLinked=l.CostCenterColID
		 join COM_DocumentLinkDef D on dl.DocumentLinkDeFID=d.DocumentLinkDeFID		 
		where d.CostCenterIDBase=@COSTCENTERID
		
		
			--Getting Costcenter Fields  
		SELECT  C.CostCenterColID,R.ResourceData,R.ResourceData as UserColumnName,C.ResourceID,C.SysColumnName,C.UserColumnType,C.ColumnDataType,C.RowNo,C.ColumnNo,C.ColumnSpan,
				C.UserDefaultValue,C.UserProbableValues,C.IsMandatory,C.IsEditable,C.IsVisible,C.ColumnCCListViewTypeID,
				C.IsCostCenterUserDefined,isnull(C.UIwidth,100) UIWidth,C.IsColumnUserDefined,C.ColumnCostCenterID,C.FetchMaxRows,C.SectionID,C.SectionName,C.SectionSeqNumber,
				DD.DebitAccount,DD.CreditAccount,DD.Formula,DD.PostingType,DD.RoundOff,
				DD.IsRoundOffEnabled,DD.IsDrAccountDisplayed,DD.IsCrAccountDisplayed,DD.IsDistributionEnabled,DD.DistributionColID,
				DV.IsReadonly,DV.NumFieldEditOptionID,DV.IsVisible,DV.TabOptionID,DV.ActionOptionID,DD.IsCalculate
		FROM ADM_CostCenterDef C WITH(NOLOCK)
		LEFT JOIN COM_LanguageResources R ON R.ResourceID=C.ResourceID AND R.LanguageID=@LangID
		INNER JOIN ADM_DocumentDef DD ON DD.CostCenterColID=C.CostCenterColID 
		LEFT JOIN ADM_DocumentViewDef DV ON DV.CostCenterColID=C.CostCenterColID 
		WHERE C.CostCenterID  =@COSTCENTERID AND C.SysColumnName LIKE 'dcNum%' and c.IsColumninUse=1
			--AND ((C.IsColumnUserDefined=1 AND C.IsColumnInUse=1))

		--Getting Costcenter Fields  
		SELECT  C.CostCenterColID
		FROM ADM_CostCenterDef C WITH(NOLOCK)
		WHERE C.CostCenterID  =@COSTCENTERID 
		AND C.SysColumnName LIKE 'dcNum%'
			AND C.CostCenterColID NOT IN (SELECT CostCenterColID FROM ADM_DocumentDef WHERE CostCenterID=@COSTCENTERID)
		--ORDER BY C.SectionID,C.SectionSeqNumber
		
		
		 
		
COMMIT TRANSACTION
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
ROLLBACK TRANSACTION
SET NOCOUNT OFF  
RETURN -999   
END CATCH  

GO

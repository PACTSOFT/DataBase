USE PACT2C222
GO
SET ANSI_NULLS, QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spSVC_GetTicketFieldsData]
	@UserID [bigint],
	@LangID [int] = 1
WITH ENCRYPTION, EXECUTE AS CALLER
AS
BEGIN TRANSACTION  
BEGIN TRY  
SET NOCOUNT ON;
 
		--Getting Service ticket fields 
		select C.CostCenterColID,R.ResourceData,R.ResourceData as UserColumnName,C.ResourceID,C.SysColumnName,C.UserColumnType,C.ColumnDataType,C.RowNo,C.ColumnNo,C.ColumnSpan,
				C.UserDefaultValue,C.UserProbableValues,C.IsMandatory,C.IsEditable,C.IsVisible,C.ColumnCCListViewTypeID,
				C.IsCostCenterUserDefined, d.DistributionColID, d.IsDistributionEnabled
		FROM ADM_CostCenterDef C WITH(NOLOCK) 
		left join ADM_DocumentDef d with(nolock) on c.CostCenterColID=d.CostCenterColID
		LEFT JOIN COM_LanguageResources R ON R.ResourceID=C.ResourceID AND R.LanguageID=@LangID
		where C.CostCenterID=59 and C.IsColumninUse=1 and  SysColumnName NOT LIKE '%dcCalcNum%'

		SELECT     CostCenterID, DocumentName, IsInventory, DocumentType FROM ADM_DocumentTypes where IsInventory=1 and Costcenterid in 
		(select convert(bigint,value) from com_costcenterpreferences where costcenterid=59 and value >0 and name <> 'DuplicateProduct_IncrementQuantity' 
		and name <> 'Canchangestatus' and name<>'DonotallowpartswithZeroValue' and name <>'FreightPer'
		and name<>'ThresholdCheckonJobStop' and name <>'ReadonlyColumnColor' and name <>'EnableFreight') 
		  
		
		 --Getting Details of All Documents from Adm_CostCenterDef
		 select distinct A.CostCenterID,A.CostCenterColID,A.CostCenterName,C.ResourceData as UserColumnName, A.SysColumnName
		 from ADM_CostCenterDef A 
		 join Com_LanguageResources C on C.ResourceID=A.ResourceID and C.LanguageID=@LangID
		 where  (IsColumnUserDefined=0  or IsColumnInUse=1) and
		  SysColumnName NOT LIKE '%dcCurrID%' and SysColumnName NOT LIKE '%dcExchRT%' 
		  and  SysColumnName NOT LIKE '%dcCalcNum%' and SysColumnName NOT LIKE '%dcCalcNum%' 
		  and SysColumnName NOT LIKE '%dcCalcNum%' and SysColumnName <> 'UOMConversion'   AND SysColumnName <> 'UOMConvertedQty' 
		  and CostCenterID between 40000 and 50000 
		 order by CostCenterID

		 --Getting details of Mapped voucher
		 select * from COM_DocumentLinkDef where CostCenterIDBase=59

		select DocumentLinkDeFID, CostCenterColIDBase, C.ResourceData  as BUserColumnName,
		 b.SysColumnName as BSysColumnName, CostCenterColIDLinked, l.UserColumnName as LUserColumnName,
		 l.SysColumnName as LSysColumnName,l.Costcenterid
		 from COM_DocumentLinkDetails dl
		  join ADM_CostCenterDef b on dl.CostCenterColIDBase=b.CostCenterColID
		  join Com_LanguageResources C on C.ResourceID=b.ResourceID and C.LanguageID=@LangID
		  join ADM_CostCenterDef l on dl.CostCenterColIDLinked=l.CostCenterColID
		where DocumentLinkDeFID in (select DocumentLinkDeFID from COM_DocumentLinkDef where CostCenterIDBase=59)


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

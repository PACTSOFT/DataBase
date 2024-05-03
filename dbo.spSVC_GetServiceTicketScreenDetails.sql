USE PACT2C222
GO
SET ANSI_NULLS, QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spSVC_GetServiceTicketScreenDetails]
	@Type [int],
	@UserID [int],
	@LangID [int]
WITH ENCRYPTION, EXECUTE AS CALLER
AS
BEGIN TRY  
SET NOCOUNT ON;  
 
	IF @Type=0
	BEGIN
		SELECT L.NodeID,L.LookupType,L.Name,R.ResourceName, L.IsDefault 
		FROM COM_Lookup L WITH(NOLOCK) 
			LEFT JOIN COM_LanguageResources R WITH(NOLOCK) ON R.ResourceID=L.ResourceID AND R.LanguageID=@LangID
		WHERE LookupType IN (1,2,3,4,5,7,8,10,58) AND Status=1

		SELECT P.NodeID,Name,R.ResourceName,P.PaymentType 
		FROM COM_PaymentModes P WITH(NOLOCK)
		LEFT JOIN COM_LanguageResources R WITH(NOLOCK) ON R.ResourceID=P.ResourceID AND R.LanguageID=@LangID
		WHERE P.Status=1

		SELECT S.ServiceTypeID ID,S.ServiceName Name,F.ActualFileName CheckList,F.FilePath
		FROM SVC_ServiceTypes S WITH(NOLOCK)
		LEFT JOIN COM_Files F WITH(NOLOCK) ON S.AttachmentID=F.FileID
		WHERE S.StatusID<>358

		SELECT ServiceTypeID Type,ServiceReasonID ID,Reason Name FROM SVC_ServicesReasons WITH(NOLOCK)

		/* TO GET PAYMENT MODES */
		SELECT P.NodeID,Name,R.ResourceName,P.PaymentType 
		FROM COM_PaymentModes P WITH(NOLOCK)
			LEFT JOIN COM_LanguageResources R WITH(NOLOCK) ON R.ResourceID=P.ResourceID AND R.LanguageID=@LangID
		WHERE P.Status=1 and NodeID <> 9

		/* TO GET TAX FIELDS INFO */
		SELECT  C.CostCenterColID,R.ResourceData,C.UserColumnName,C.ResourceID,C.SysColumnName,C.UserColumnType,C.ColumnDataType,C.RowNo,C.ColumnNo,C.ColumnSpan,
				C.UserDefaultValue,C.UserProbableValues,C.IsMandatory,C.IsEditable,C.IsVisible,C.ColumnCCListViewTypeID,
				C.IsCostCenterUserDefined,isnull(C.UIwidth,100) UIWidth,C.IsColumnUserDefined,C.ColumnCostCenterID,C.FetchMaxRows,C.SectionID,C.SectionName,C.SectionSeqNumber,
				DD.DebitAccount,DD.CreditAccount,DD.Formula,DD.PostingType,DD.RoundOff,
				DD.IsRoundOffEnabled,DD.IsDrAccountDisplayed,DD.IsCrAccountDisplayed,DD.IsDistributionEnabled,DD.DistributionColID,
				DV.IsReadonly,DV.NumFieldEditOptionID,DV.IsVisible,DV.TabOptionID,DV.ActionOptionID,DD.IsCalculate
				,DD.CrRefID, dd.CrRefColID, DD.DrRefID, DD.DrRefColID 
		FROM ADM_CostCenterDef C WITH(NOLOCK)
		LEFT JOIN COM_LanguageResources R WITH(NOLOCK) ON R.ResourceID=C.ResourceID AND R.LanguageID=@LangID
		INNER JOIN ADM_DocumentDef DD WITH(NOLOCK) ON DD.CostCenterColID=C.CostCenterColID 
		LEFT JOIN ADM_DocumentViewDef DV WITH(NOLOCK) ON DV.CostCenterColID=C.CostCenterColID  
		WHERE C.CostCenterID  =59 AND C.SysColumnName LIKE 'dcNum%' 
		order by SectionSeqNumber

		/* TO USER LOCATION */ 
		SELECT TOP 1 NodeID FROM COM_CostCenterCostCenterMap WITH(NOLOCK)
		WHERE ParentCostCenterID=7 AND ParentNodeID=@UserID AND CostCenterID=50002
		 

		SELECT     P.Name, D.CostCenterID, code.CodePrefix, code.Location, code.CodeDelimiter
		FROM         COM_CostCenterPreferences AS P WITH (NOLOCK) LEFT JOIN
		COM_CostCenterCodeDef AS code WITH (NOLOCK) ON P.Value =CONVERT(nvarchar, code.CostCenterID) INNER JOIN
		ADM_DocumentTypes AS D WITH (NOLOCK) ON P.Value = CONVERT(nvarchar,D.CostCenterID)
		WHERE     (P.FeatureID = 59)

		SELECT P.Name,P.Value
		FROM COM_CostCenterPreferences P WITH(NOLOCK)		
		WHERE P.FeatureID=59  
		
		-- Get DocPrefix based on Documents
		SELECT   distinct( a.DocPrefixID), a.DocumentTypeID, ISNULL(C.CostCenterID,a.CCID) AS CCID, a.CCID AS ColID, 
		C.SysColumnName, b.Name, a.Length, a.Delimiter, a.PrefixOrder,d.costcenterid, d.GUID
		FROM         COM_DocPrefix AS a WITH(NOLOCK) LEFT OUTER JOIN
		ADM_CostCenterDef AS C WITH(NOLOCK) ON a.CCID = C.CostCenterColID LEFT OUTER JOIN
		ADM_Features AS b WITH (NOLOCK) ON C.CostCenterID = b.FeatureID AND C.CostCenterID > 50000 
		join adm_documenttypes d WITH(NOLOCK) on a.DocumentTypeid=d.Documenttypeid 
		left join Com_costcenterpreferences cp WITH(NOLOCK) on d.costcenterid=convert(bigint,cp.value)
		WHERE a.DocumentTypeID =d.DocumentTypeID and D.CostCenterID=convert(bigint,cp.value) and
		cp.costcenterid=59 and cp.value >0 and cp.name <> 'DuplicateProduct_IncrementQuantity' 
		and cp.name <> 'Canchangestatus' and cp.name<>'DonotallowpartswithZeroValue' 
		and cp.name<>'ThresholdCheckonJobStop' and cp.name <>'ReadonlyColumnColor'
		 and cp.name <>'FreightPer' and cp.name <>'EnableFreight'  
		ORDER BY a.PrefixOrder
		
		select * from COM_DocumentPreferences dp WITH(NOLOCK)
		left join Com_costcenterpreferences cp WITH(NOLOCK) on dp.costcenterid=convert(bigint,cp.value)
		where  dp.CostCenterID =convert(bigint,cp.value)
		and cp.costcenterid=59 and cp.value >0 and cp.name <> 'DuplicateProduct_IncrementQuantity' and 
		cp.name <> 'Canchangestatus' and cp.name<>'DonotallowpartswithZeroValue'
		 and cp.name<>'ThresholdCheckonJobStop' and cp.name <>'ReadonlyColumnColor' 
		  and cp.name <>'FreightPer' and cp.name <>'EnableFreight' 
		and PrefName='DonotupdateInventory'	
		
		select  Name, NodeID from COM_CC50050 WITH(NOLOCK) where Nodeid in (select case  when  (value=0) then (1) else (Value)  end as value from com_costcenterpreferences where name like 'DefaultOwner')
		
		select SysColumnName, UserDefaultValue, d.CostCenterID  from adm_Costcenterdef d WITH(NOLOCK)
		left join Com_costcenterpreferences cp WITH(NOLOCK) on d.costcenterid=convert(bigint,cp.value) 
		 where  d.syscolumnname like '%Account'
		and cp.costcenterid=59 and cp.value >0 and cp.name <> 'DuplicateProduct_IncrementQuantity' and 
		cp.name <> 'Canchangestatus' and cp.name<>'DonotallowpartswithZeroValue'
		and cp.name<>'ThresholdCheckonJobStop' and cp.name <>'ReadonlyColumnColor'  
		 and cp.name <>'FreightPer' and cp.name <>'EnableFreight' 
		
		SELECT  C.CostCenterColID ,DD.CrRefID, dd.CrRefColID, DD.DrRefID, DD.DrRefColID,
		c.ColumnCostCenterID
		FROM ADM_CostCenterDef C WITH(NOLOCK)
		inner JOIN ADM_DocumentDef DD  WITH(NOLOCK) ON DD.CrRefID=C.CostCenterColID 
		WHERE C.CostCenterID  =59  
		order by SectionSeqNumber
		
		select * from SVC_PRICEMARGIN WITH(NOLOCK)
		
		select value from com_costcenterpreferences WITH(NOLOCK) 
		where costcenterid=3 and Name like 'TempPartProduct'
		
	END

 
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
		SELECT ErrorMessage, ERROR_MESSAGE() AS ServerMessage,ERROR_NUMBER() AS ErrorNumber, ERROR_PROCEDURE()AS ProcedureName, ERROR_LINE() AS ErrorLine
		FROM COM_ErrorMessages WITH(NOLOCK) WHERE ErrorNumber=-999 AND LanguageID=@LangID
	END
 
SET NOCOUNT OFF  
RETURN -999   
END CATCH  


GO

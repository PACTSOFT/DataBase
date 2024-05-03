USE PACT2C222
GO
SET ANSI_NULLS, QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spRPT_GetReportFields]
	@CCID [int],
	@ColID [bigint],
	@UserID [bigint],
	@LangID [int] = 1
WITH ENCRYPTION, EXECUTE AS CALLER
AS
BEGIN TRY	
SET NOCOUNT ON

	set @LangID=1

	IF @CCID=0
	BEGIN
		SELECT TOP 1 @CCID=CostCenterID FROM ADM_CostCenterDef WITH(NOLOCK) WHERE CostCenterColID=@ColID
	END
	
	DECLARE @Tbl AS TABLE(UserColumnName NVARCHAR(300),CostCenterID INT,
		CostCenterName NVARCHAR(50),SysTableName NVARCHAR(50),SysColumnName NVARCHAR(50),
		CostCenterColID INT,ColumnDataType NVARCHAR(50),IsForeignKey BIT,
		ParentCostCenterID INT,ParentCostCenterSysName NVARCHAR(50),
		ParentCostCenterColSysName NVARCHAR(50),ParentCCDefaultColID BIGINT,
		ColumnCostCenterID INT,ColumnCCListViewTypeID INT,ResourceID bigint,UserClumnName NVARCHAR(300))
		
	IF @CCID=144--FOR ACTIVITY
	BEGIN
		INSERT INTO @Tbl
		SELECT isnull((select Name+' - ' from ADM_Features AF WITH(NOLOCK) where AF.FeatureID=C.LocalReference),'')+ R.ResourceData as UserColumnName ,C.CostCenterID,C.CostCenterName,C.SysTableName,C.SysColumnName,C.CostCenterColID,
			 CASE WHEN UserColumnType='Date' OR UserColumnType='DateTime' OR UserColumnType='Time' THEN 'DATE' ELSE upper(C.ColumnDataType) END ColumnDataType,--upper(C.ColumnDataType) ColumnDataType,
		C.IsForeignKey,C.ParentCostCenterID,--case when SysColumnName like 'Alpha%' then C.LocalReference else C.ParentCostCenterID end ParentCostCenterID,--
		C.ParentCostCenterSysName,C.ParentCostCenterColSysName,C.ParentCCDefaultColID,C.ColumnCostCenterID,C.ColumnCCListViewTypeID,C.ResourceID,''
		FROM ADM_CostCenterDef C WITH(NOLOCK),COM_LanguageResources R WITH(NOLOCK)
		WHERE C.CostCenterID=@CCID AND C.ResourceID=R.ResourceID AND R.LanguageID=@LangID 
			AND IsValidReportBuilderCol=1 AND IsColumnInUse=1
	END
	ELSE IF @CCID  IN(405,406,407,408)
	BEGIN
		INSERT INTO @Tbl
		SELECT     C.UserColumnName, @CCID AS CostCenterID, CostCenterName, C.SysTableName, C.SysColumnName, 
						  C.CostCenterColID, upper(C.ColumnDataType) ColumnDataType, C.IsForeignKey, C.ParentCostCenterID,
						  C.ParentCostCenterSysName, C.ParentCostCenterColSysName, C.ParentCCDefaultColID, C.ColumnCostCenterID,C.ColumnCCListViewTypeID,C.ResourceID,''
		FROM         ADM_CostCenterDef AS C WITH(NOLOCK) 
		WHERE C.CostCenterID = @CCID AND C.IsColumnInUse=1
		
		IF @CCID IN (405,406) and exists (select Name from ADM_GlobalPreferences with(nolock) where Name='ShowEarngDeductionTypeLookUpFldsInMnthlyPayroll' and Value='True')
		begin
			declare @SQL nvarchar(max)
			if @CCID=405
				set @SQL='EarningType'
			else if @CCID=406
				set @SQL='DeductionType'
			INSERT INTO @Tbl
			SELECT C.UserColumnName+' '+@SQL, @CCID AS CostCenterID, CostCenterName, C.SysTableName,'x'+@SQL+convert(nvarchar,PC.NodeID), 
				999900000+PC.NodeID,'' ColumnDataType, C.IsForeignKey, C.ParentCostCenterID,
				C.ParentCostCenterSysName, C.ParentCostCenterColSysName, C.ParentCCDefaultColID, C.ColumnCostCenterID,C.ColumnCCListViewTypeID,C.ResourceID,''
			FROM ADM_CostCenterDef AS C WITH(NOLOCK) 
			join com_cc50052 PC with(nolock) on PC.Name=C.UserColumnName
			WHERE C.CostCenterID = @CCID AND C.IsColumnInUse=1 and C.SysColumnName like 'dcCalcNum%'
		end
	END
	ELSE IF @CCID NOT IN(402)
	BEGIN
		INSERT INTO @Tbl
		SELECT Case when C.SysColumnName like 'dcCalcNumFC%' then R.ResourceData+'-Calculated FC'
			when C.SysColumnName like 'dcCalcNum%' then R.ResourceData+'-Calculated'
			 when C.SysColumnName like 'dcCurrID%' then R.ResourceData+'-Currency'
			 when C.SysColumnName like 'dcExchRT%' then R.ResourceData+'-Exchange Rate' 
			 else R.ResourceData end as UserColumnName ,C.CostCenterID,C.CostCenterName,C.SysTableName,C.SysColumnName,C.CostCenterColID,
			 CASE WHEN UserColumnType='Date' OR UserColumnType='DateTime' OR UserColumnType='Time' THEN 'DATE' 
			 WHEN  C.SysColumnName like 'dcAlpha%' and (UserColumnType='Numeric' AND ColumnDataType='TEXT') THEN 'FLOAT' 
			 ELSE upper(C.ColumnDataType) END,			 
		C.IsForeignKey,C.ParentCostCenterID,
		C.ParentCostCenterSysName,C.ParentCostCenterColSysName,C.ParentCCDefaultColID,C.ColumnCostCenterID,C.ColumnCCListViewTypeID,C.ResourceID,''
		FROM ADM_CostCenterDef C WITH(NOLOCK),COM_LanguageResources R WITH(NOLOCK)
		WHERE C.CostCenterID=@CCID AND C.ResourceID=R.ResourceID AND R.LanguageID=@LangID 
			AND IsValidReportBuilderCol=1 AND IsColumnInUse=1 
	END


	IF @CCID=400
	BEGIN
		INSERT INTO @Tbl
		SELECT     ADM_Features.Name AS UserColumnName, 400 AS CostCenterID, 'Documents' AS CostCenterName, C.SysTableName, C.SysColumnName, 
						  -C.CostCenterColID, upper(C.ColumnDataType) ColumnDataType, C.IsForeignKey, C.ParentCostCenterID,
						  C.ParentCostCenterSysName, C.ParentCostCenterColSysName, C.ParentCCDefaultColID, ADM_Features.FeatureID ColumnCostCenterID,C.ColumnCCListViewTypeID,0,''
		FROM         ADM_CostCenterDef AS C WITH(NOLOCK) 
		INNER JOIN COM_LanguageResources AS R WITH (NOLOCK) ON C.ResourceID = R.ResourceID AND R.LanguageID=@LangID 
		INNER JOIN ADM_Features WITH(NOLOCK) ON C.ParentCostCenterID = ADM_Features.FeatureID
		WHERE     (C.IsValidReportBuilderCol = 1) AND (C.CostCenterID = 40001) AND (C.SysColumnName LIKE N'dcCCNID%' or C.SysColumnName='VehicleID' or C.SysColumnName='ContactID') AND (ADM_Features.IsEnabled = 1)
	END
	ELSE IF @CCID=401
	BEGIN
		INSERT INTO @Tbl
		SELECT     substring(C.SysColumnName,3,len(C.SysColumnName)-2) AS UserColumnName, 401 AS CostCenterID, 'Numeric Fields' AS CostCenterName, C.SysTableName, C.SysColumnName, 
						  -C.CostCenterColID, upper(C.ColumnDataType) ColumnDataType, C.IsForeignKey, C.ParentCostCenterID,
						  C.ParentCostCenterSysName, C.ParentCostCenterColSysName, C.ParentCCDefaultColID, C.ColumnCostCenterID,C.ColumnCCListViewTypeID,C.ResourceID,''
		FROM         ADM_CostCenterDef AS C WITH(NOLOCK) 
		WHERE (C.CostCenterID = 40001) and SysTableName='COM_DocNumData'
	END
	ELSE IF @CCID=402
	BEGIN
		INSERT INTO @Tbl
		SELECT     substring(C.SysColumnName,3,len(C.SysColumnName)-2) AS UserColumnName, 402 AS CostCenterID, 'Text Fields' AS CostCenterName, C.SysTableName, C.SysColumnName, 
						  -C.CostCenterColID,'TEXT' ColumnDataType,0 IsForeignKey,0 ParentCostCenterID,
						  null ParentCostCenterSysName,null ParentCostCenterColSysName,null ParentCCDefaultColID,0 ColumnCostCenterID,0 ColumnCCListViewTypeID,C.ResourceID,''
		FROM         ADM_CostCenterDef AS C WITH(NOLOCK) 
		WHERE (C.CostCenterID = 40001) and SysTableName='COM_DocTextData'
		and (replace(C.SysColumnName,'dcAlpha','')<=50 or replace(C.SysColumnName,'dcAlpha','')>=130)
		union all
		SELECT substring(C.SysColumnName,3,len(C.SysColumnName)-2) AS UserColumnName,402 AS CostCenterID, 'Text Fields' AS CostCenterName
		,'COM_DocTextData' SysTableName
		, C.SysColumnName
		,-1000-convert(int,replace(C.SysColumnName,'dcAlpha','')) CostCenterColID
		,'TEXT' ColumnDataType,0,null,null,null,null,0,0,0,''
		FROM ADM_CostCenterDef AS C WITH(NOLOCK) 
		WHERE C.CostCenterID>40000 and C.CostCenterID<50000 and SysTableName='COM_DocTextData' and SysColumnName like 'dcAlpha%'
		and replace(C.SysColumnName,'dcAlpha','')>50 and replace(C.SysColumnName,'dcAlpha','')<130
		group by C.SysColumnName
		order by SysColumnName
	END
	ELSE IF @CCID=45
	BEGIN
		INSERT INTO @Tbl

		SELECT     ADM_Features.Name AS UserColumnName, 45 AS CostCenterID, 'Tax Chart' AS CostCenterName, 'COM_CCTaxes' AS SysTableName, 
                      C.SysColumnName, -C.CostCenterColID, upper(C.ColumnDataType) ColumnDataType, C.IsForeignKey, C.ParentCostCenterID, 
                      C.ParentCostCenterSysName, C.ParentCostCenterColSysName, C.ParentCCDefaultColID, 
                      ADM_Features.FeatureID AS ColumnCostCenterID,C.ColumnCCListViewTypeID,0,''
		FROM         ADM_CostCenterDef AS C WITH(NOLOCK)
			INNER JOIN COM_LanguageResources AS R WITH (NOLOCK) ON C.ResourceID = R.ResourceID AND R.LanguageID=@LangID 
			INNER JOIN  ADM_Features WITH(NOLOCK) ON C.ParentCostCenterID = ADM_Features.FeatureID
		WHERE     (C.IsValidReportBuilderCol = 1) AND (C.CostCenterID = 40011) AND (C.SysColumnName LIKE N'DCCCNID%') AND (ADM_Features.IsEnabled = 1)
	END
	ELSE IF @CCID=40
	BEGIN
		INSERT INTO @Tbl
		SELECT    ADM_Features.Name AS UserColumnName, 40 AS CostCenterID, 'Price Chart' AS CostCenterName, 'COM_CCPrices' AS SysTableName, 
				  C.SysColumnName, -C.CostCenterColID, upper(C.ColumnDataType) ColumnDataType, C.IsForeignKey, C.ParentCostCenterID,
				  C.ParentCostCenterSysName, C.ParentCostCenterColSysName, C.ParentCCDefaultColID, 
				  ADM_Features.FeatureID AS ColumnCostCenterID,C.ColumnCCListViewTypeID,0,''
		FROM      ADM_CostCenterDef AS C  WITH(NOLOCK) 
				INNER JOIN COM_LanguageResources AS R WITH (NOLOCK) ON C.ResourceID = R.ResourceID AND R.LanguageID=@LangID  
				INNER JOIN ADM_Features WITH(NOLOCK) ON C.ParentCostCenterID = ADM_Features.FeatureID
		WHERE     (C.IsValidReportBuilderCol = 1) AND (C.CostCenterID = 3) AND (C.SysColumnName LIKE N'CCNID%') AND (ADM_Features.IsEnabled = 1)
		
		INSERT INTO @Tbl
		 SELECT  'UOM'  UserColumnName, 40 AS CostCenterID, 'Price Chart' AS CostCenterName, 'COM_CCPrices' AS SysTableName, 
				  C.SysColumnName, -C.CostCenterColID CostCenterColID, upper(C.ColumnDataType) ColumnDataType, C.IsForeignKey, C.ParentCostCenterID,
				  C.ParentCostCenterSysName, C.ParentCostCenterColSysName, C.ParentCCDefaultColID, 
				   ColumnCostCenterID,C.ColumnCCListViewTypeID,C.ResourceID,''
		FROM      ADM_CostCenterDef AS C  WITH(NOLOCK)  
		WHERE     (C.IsValidReportBuilderCol = 1) AND (C.CostCenterID = 3) AND (C.SysColumnName = 'UOMID')  
		
	END
	ELSE IF @CCID=101
	BEGIN
		INSERT INTO @Tbl
		SELECT     ADM_Features.Name AS UserColumnName, 101 AS CostCenterID, 'Budget' AS CostCenterName,'COM_BudgetAlloc' SysTableName, substring(C.SysColumnName,3,len(C.SysColumnName)-2), 
						  -C.CostCenterColID, upper(C.ColumnDataType) ColumnDataType, C.IsForeignKey, C.ParentCostCenterID,
						  C.ParentCostCenterSysName, C.ParentCostCenterColSysName, C.ParentCCDefaultColID, ADM_Features.FeatureID ColumnCostCenterID,C.ColumnCCListViewTypeID,0,''
		FROM         ADM_CostCenterDef AS C WITH(NOLOCK) INNER JOIN
							  COM_LanguageResources AS R WITH (NOLOCK) ON C.ResourceID = R.ResourceID AND R.LanguageID=@LangID  INNER JOIN
							  ADM_Features WITH(NOLOCK) ON C.ParentCostCenterID = ADM_Features.FeatureID
		WHERE     (C.IsValidReportBuilderCol = 1) AND (C.CostCenterID = 40001) AND (C.SysColumnName LIKE N'dcCCNID%') AND (ADM_Features.IsEnabled = 1)
		UNION
		SELECT 'Account',101,'Budget','COM_BudgetAlloc','AccountID','-1976','LISTBOX',1,2,'ACC_Accounts','AccountID',239,2,0,0,''
		UNION
		SELECT 'Product',101,'Budget','COM_BudgetAlloc','ProductID','-1984','LISTBOX',1,3,'INV_Product','ProductID',262,2,0,0,''
	END
	ELSE IF @CCID=151
	BEGIN
		INSERT INTO @Tbl
		SELECT    ADM_Features.Name AS UserColumnName,@CCID, 'Schemes & Discounts' AS CostCenterName, 'ADM_SchemesDiscounts' AS SysTableName, 
				  C.SysColumnName, -C.CostCenterColID, upper(C.ColumnDataType) ColumnDataType, C.IsForeignKey, C.ParentCostCenterID,
				  C.ParentCostCenterSysName, C.ParentCostCenterColSysName, C.ParentCCDefaultColID, 
				  ADM_Features.FeatureID AS ColumnCostCenterID,C.ColumnCCListViewTypeID,0,''
		FROM      ADM_CostCenterDef AS C  WITH(NOLOCK) 
				INNER JOIN COM_LanguageResources AS R WITH (NOLOCK) ON C.ResourceID = R.ResourceID AND R.LanguageID=@LangID  
				INNER JOIN ADM_Features WITH(NOLOCK) ON C.ParentCostCenterID = ADM_Features.FeatureID
		WHERE     (C.IsValidReportBuilderCol = 1) AND (C.CostCenterID = 3) AND (C.SysColumnName LIKE N'CCNID%') AND (ADM_Features.IsEnabled = 1)
	END
	
	
/*	IF @CCID=2 or @CCID=3 or @CCID>50000
		INSERT INTO @Tbl
		SELECT  R.ResourceData+' Assigned' UserColumnName,C.CostCenterID,C.CostCenterName,C.SysTableName,C.SysColumnName,-C.CostCenterColID CostCenterColID,
		C.ColumnDataType,			 
		C.IsForeignKey,C.ParentCostCenterID,
		C.ParentCostCenterSysName,C.ParentCostCenterColSysName,C.ParentCCDefaultColID,C.ColumnCostCenterID,C.ColumnCCListViewTypeID
		FROM ADM_CostCenterDef C WITH(NOLOCK),COM_LanguageResources R WITH(NOLOCK)
		,ADM_Features F with(nolock),COM_LanguageResources RF WITH(NOLOCK)
		WHERE C.CostCenterID=@CCID AND C.ResourceID=R.ResourceID AND R.LanguageID=@LangID 
		and F.FeatureID=C.ParentCostCenterID and F.IsEnabled=1
		and F.ResourceID=RF.ResourceID and RF.LanguageID=@LangID 
		and SysTableName='COM_CCCCData' and C.SysColumnName like 'CCNID%'*/ 
	
	
	INSERT INTO @Tbl
	SELECT R.ResourceData UserColumnName ,C.CostCenterID,C.CostCenterName,C.SysTableName,C.SysColumnName,C.CostCenterColID,upper(C.ColumnDataType) ColumnDataType,
	C.IsForeignKey,C.ParentCostCenterID,
	C.ParentCostCenterSysName,C.ParentCostCenterColSysName,C.ParentCCDefaultColID,C.ColumnCostCenterID,C.ColumnCCListViewTypeID,C.ResourceID,''
	FROM ADM_CostCenterDef C WITH(NOLOCK),COM_LanguageResources R WITH(NOLOCK)
	WHERE C.CostCenterColID IN (SELECT ParentCCDefaultColID FROM @Tbl WHERE IsForeignKey=1)
		AND C.CostCenterID<>@CCID 
		AND C.ResourceID=R.ResourceID AND R.LanguageID=@LangID 		
	
	IF (SELECT count(*) FROM @Tbl WHERE IsForeignKey=1 and ParentCostCenterID=8)>0
	BEGIN
		INSERT INTO @Tbl
		SELECT F.Name UserColumnName,8 CostCenterID,'Assigned' CostCenterName,'COM_CostCenterCostCenterMap' SysTableName
		,'Name' SysColumnName--case when F.FeatureID=7 then 'UserName' else 'Name' end SysColumnName
		,F.FeatureID CostCenterColID,'' ColumnDataType,
		0 IsForeignKey,F.FeatureID ParentCostCenterID,
		F.TableName ParentCostCenterSysName,'Name' ParentCostCenterColSysName,50002 ParentCCDefaultColID,F.FeatureID ColumnCostCenterID,0 ColumnCCListViewTypeID,0,''
		FROM ADM_Features F WITH(NOLOCK)
		WHERE F.FeatureID=7 or (F.FeatureID>50000 and F.FeatureID<=50050 and F.IsEnabled=1)
	END
	
	IF @CCID=2 or @CCID=3 or @CCID=73 or @CCID=89 or @CCID=400 or @CCID>40000
	BEGIN
		INSERT INTO @Tbl
		SELECT R.ResourceData UserColumnName ,C.CostCenterID,C.CostCenterName,C.SysTableName,C.SysColumnName,C.CostCenterColID,upper(C.ColumnDataType) ColumnDataType,
		C.IsForeignKey,C.ParentCostCenterID,
		C.ParentCostCenterSysName,C.ParentCostCenterColSysName,C.ParentCCDefaultColID,C.ColumnCostCenterID,C.ColumnCCListViewTypeID,C.ResourceID,''
		FROM ADM_CostCenterDef C WITH(NOLOCK),COM_LanguageResources R WITH(NOLOCK)
		WHERE C.CostCenterColID=22898 AND C.ResourceID=R.ResourceID AND R.LanguageID=@LangID
	END
	
	IF (@LangID=2)
	BEGIN
		UPDATE @tbl SET UserClumnName=UserColumnName
		UPDATE T SET T.UserColumnName=R.Resourcedata FROM @tbl T INNER JOIN Com_Languageresources R on T.ResourceID=R.ResourceID and R.LanguageID=@LangID AND T.ResourceID>0
		UPDATE T SET T.UserColumnName=R.Resourcedata FROM @tbl T INNER JOIN Com_Languageresources R on R.ResourceName=T.UserClumnName and R.LanguageID=@LangID AND isnull(T.ResourceID,0)=0
		UPDATE T SET T.Costcentername=R.Resourcedata FROM @tbl T INNER JOIN Adm_Features F on F.FeatureID=T.CostcenterID 
		 			 INNER JOIN Com_Languageresources R on F.ResourceID=R.ResourceID and R.LanguageID=@LangID 
	END	
			
	
	SELECT * FROM @Tbl
	ORDER BY UserColumnName
	
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
SET NOCOUNT OFF  
RETURN -999   
END CATCH  
GO

﻿USE PACT2C222
GO
SET ANSI_NULLS, QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spCOM_GetDimensionTabGridData]
	@CCID [bigint] = 0,
	@ChildCCID [bigint] = 0,
	@UserID [bigint],
	@LangID [int] = 1
WITH ENCRYPTION, EXECUTE AS CALLER
AS
BEGIN TRANSACTION
BEGIN TRY	
SET NOCOUNT ON 
		--Getting the main data from customers table
		
  SELECT FeatureID,Name FROM ADM_Features WITH(NOLOCK)  
  WHERE IsEnabled=1
--WHERE FeatureID IN (2,50,95) OR ((FeatureID > 40000) AND (FeatureID < 50000))--(IsEnabled = 1) AND (AllowCustomization = 1 OR (FeatureID > 40000) AND (FeatureID < 50000))  
  ORDER BY Name  

	CREATE TABLE #TBLTEMP(ID INT IDENTITY(1,1),ResourceData nvarchar(300),SysColumnName nvarchar(300),
	Width nvarchar(300),Visible bit, GridOrder int, ColumnCostCenterID bigint)

			    insert into #TBLTEMP
			    SELECT  R.ResourceData,C.SysColumnName,0,0, ISNULL(c.sectionseqnumber,0),c.ColumnCostCenterID
	        	FROM ADM_CostCenterDef C WITH(NOLOCK)
	        	LEFT JOIN COM_LanguageResources R ON R.ResourceID=C.ResourceID AND R.LanguageID=@LangID
	        	WHERE C.CostCenterID=@ChildCCID AND C.IsColumnInUse=1 AND C.ISCOLUMNDELETED=0	        	
				and CostCenterColID not in (27176,27169,27178,26946,24376,50522)
			  DECLARE @COUNT INT,@I INT,@SYSCOLUMN NVARCHAR(300),@WIDTH NVARCHAR(300),@VISIBLE BIT , @GOrder int, @ColumnCostCenterID bigint
			  SELECT @COUNT=COUNT(*) FROM #TBLTEMP
			  SET @I=1 
			  WHILE @I<=@COUNT
			  BEGIN
			  SELECT @SYSCOLUMN=LTRIM(RTRIM(SysColumnName)) FROM #TBLTEMP WHERE ID=@I
			  IF(EXISTS(SELECT * FROM [COM_TabGridCustomize] WHERE PARENTCOSTCENTER=@CCID AND ChildCostCenter=@ChildCCID AND SYSCOLUMNNAME=@SYSCOLUMN AND VISIBLE=1))
			  BEGIN
				
					SELECT @WIDTH=WIDTH,@VISIBLE=Visible,@GOrder=GridOrder FROM [COM_TabGridCustomize] WHERE PARENTCOSTCENTER=@CCID AND SYSCOLUMNNAME=@SYSCOLUMN and ChildCostCenter=@ChildCCID
					UPDATE  #TBLTEMP SET WIDTH=@WIDTH,Visible=@VISIBLE, GridOrder=@GOrder WHERE ID=@I
					
			  END  
			  SET @I=@I+1
			  END
			 SELECT * FROM #TBLTEMP order by GridOrder
			 DROP TABLE #TBLTEMP
			   
			 SELECT SYSCOLUMNNAME,USERCOLUMNNAME,WIDTH, GRIDORDER FROM COM_TabGridCustomize WITH(NOLOCK) WHERE ParentCostCenter=@CCID	
			 AND ChildCostCenter=@ChildCCID
			 AND VISIBLE=1 ORDER BY GRIDORDER
   
			SELECT  R.ResourceData,C.SysColumnName,0,0, ISNULL(c.sectionseqnumber,0),c.UserColumnType,
			c.ColumnCostCenterID, C.ParentCostCenterID
        	FROM ADM_CostCenterDef C WITH(NOLOCK)
        	LEFT JOIN COM_LanguageResources R WITH(NOLOCK) ON R.ResourceID=C.ResourceID AND R.LanguageID=1
        	  join COM_TabGridCustomize t WITH(NOLOCK) on c.SysColumnName=t.SysColumnName and ChildCostCenter=@ChildCCID and ParentCostCenter=@CCID
        	WHERE C.CostCenterID=@ChildCCID
	 
		  
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

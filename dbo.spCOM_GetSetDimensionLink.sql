USE PACT2C222
GO
SET ANSI_NULLS, QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spCOM_GetSetDimensionLink]
	@CallType [int],
	@BaseCCID [bigint] = 0,
	@LinkCCID [bigint] = 0,
	@LinkXML [nvarchar](max),
	@CompanyGUID [nvarchar](50),
	@UserName [nvarchar](50),
	@LANGID [int]
WITH ENCRYPTION, EXECUTE AS CALLER
AS
BEGIN TRANSACTION  
BEGIN TRY  
SET NOCOUNT ON;
	--Declaration Section  	
	DECLARE @XML xml,@I INT,@Cnt INT,@LinkDefID int,@linkedCCID bigint
	DECLARE @tabTrans table(id int identity(1,1),ccid bigint)
		 
	IF @CallType=0
	BEGIN
		IF(@BaseCCID=72)
		BEGIN
			SELECT distinct C.CostCenterColID CostCenterColID,isnull(R.ResourceData,C.UserColumnName) UserColumnName--,C.SysColumnName
			FROM ADM_CostCenterDef C with(nolock)
			LEFT JOIN COM_LanguageResources R with(nolock) on R.ResourceID=C.ResourceID and R.LanguageID=@LANGID
			WHERE C.CostCenterID=@BaseCCID and C.IsColumnInUse=1 and   C.SysColumnName!=''
			ORDER BY UserColumnName
			
			select 0 CostCenterColID,'' UserColumnName
			union
			SELECT C.CostCenterColID CostCenterColID,isnull(R.ResourceData,C.UserColumnName) UserColumnName--,C.SysColumnName
			FROM ADM_CostCenterDef C with(nolock)
			LEFT JOIN COM_LanguageResources R with(nolock) on R.ResourceID=C.ResourceID and R.LanguageID=@LANGID
			WHERE C.CostCenterID=@LinkCCID and C.IsColumnInUse=1 and   C.SysColumnName!=''
			ORDER BY UserColumnName
		END
		ELSE
		BEGIN
			IF((@BaseCCID=2 OR @BaseCCID=94)AND @LinkCCID=0)
			BEGIN
				SELECT distinct C.CostCenterColID CostCenterColID,isnull(R.ResourceData,C.UserColumnName) UserColumnName--,C.SysColumnName
				FROM ADM_CostCenterDef C with(nolock)
				LEFT JOIN COM_LanguageResources R with(nolock) on R.ResourceID=C.ResourceID and R.LanguageID=@LANGID
				WHERE C.CostCenterID=@BaseCCID and C.IsColumnInUse=1 and C.SysColumnName!=''
				ORDER BY UserColumnName
			END
			ELSE
			BEGIN
				SELECT distinct C.CostCenterColID CostCenterColID,isnull(R.ResourceData,C.UserColumnName) UserColumnName--,C.SysColumnName
				FROM ADM_CostCenterDef C with(nolock)
				LEFT JOIN COM_LanguageResources R with(nolock) on R.ResourceID=C.ResourceID and R.LanguageID=@LANGID
				WHERE C.CostCenterID=@BaseCCID and C.IsColumnInUse=1 and C.SysColumnName not like 'CCNID%' and C.SysColumnName!=''
				ORDER BY UserColumnName
			END
			
			select 0 CostCenterColID,'' UserColumnName
			union
			SELECT C.CostCenterColID CostCenterColID,isnull(R.ResourceData,C.UserColumnName) UserColumnName--,C.SysColumnName
			FROM ADM_CostCenterDef C with(nolock)
			LEFT JOIN COM_LanguageResources R with(nolock) on R.ResourceID=C.ResourceID and R.LanguageID=@LANGID
			WHERE C.CostCenterID=@LinkCCID and C.IsColumnInUse=1 and C.SysColumnName not like 'CCNID%' and C.SysColumnName!=''
			ORDER BY UserColumnName 
		END
		
		SELECT L.BaseColID,L.LinkColID FROM COM_DimensionLinkDetails L with(nolock)
		WHERE L.BaseCCID=@BaseCCID and L.LinkCCID=@LinkCCID
		
		if(@BaseCCID=2 OR @BaseCCID=94)
		BEGIN
			if(@BaseCCID=2)
				SELECT @XML=[Value] FROM [adm_GLOBALPREFERENCES] WITH(NOLOCK) WHERE [Name]='ACCEIDMapping'  
			ELSE IF (@BaseCCID=94)
				SELECT @XML=[Value] FROM [adm_GLOBALPREFERENCES] WITH(NOLOCK) WHERE [Name]='EIDMapping'           
	          
			if(@XML IS NOT NULL)              
			BEGIN   
				select X.value('@ColID','bigint') ColID,X.value('@MapFieldName','NVARCHAR(50)') MapFieldName
				from @XML.nodes('/Xml/Row') as Data(X)			
			END
		END
	END
	ELSE IF @CallType=1
	BEGIN
		SET @XML=@LinkXML              
	          
		DELETE FROM COM_DimensionLinkDetails where BaseCCID=@BaseCCID and [Type]='DIMENSION'
    
		if(@LinkXML IS NOT NULL AND @LinkXML <>'')              
		BEGIN              
			insert into COM_DimensionLinkDetails(BaseCCID,LinkCCID,BaseColID,LinkColID,[Type],CompanyGUID,GUID,CreatedBy,CreatedDate)
			select @BaseCCID,@LinkCCID,X.value('@BaseColID','bigint'),X.value('@LinkColID','bigint'),'DIMENSION',@CompanyGUID,NEWID(),@UserName,CONVERT(FLOAT,GETDATE())
			from @XML.nodes('/Xml/Row') as Data(X)			
		END
		SELECT ErrorMessage,ErrorNumber FROM COM_ErrorMessages WITH(nolock) 
		WHERE ErrorNumber=100 AND LanguageID=@LangID  
	END

COMMIT TRANSACTION    
--ROLLBACK TRANSACTION
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
	ROLLBACK TRANSACTION
	SET NOCOUNT OFF  
	RETURN -999   
END CATCH 
GO

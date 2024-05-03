USE PACT2C222
GO
SET ANSI_NULLS, QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spCOM_ActivateCostCenter]
	@FeatureID [bigint],
	@Name [nvarchar](300),
	@RibbonGroup [nvarchar](100),
	@Options [nvarchar](max),
	@CompanyGUID [nvarchar](50),
	@GUID [nvarchar](50),
	@UserName [nvarchar](50),
	@UserID [bigint],
	@RoleID [int],
	@LangID [int] = 1
WITH ENCRYPTION, EXECUTE AS CALLER
AS
BEGIN TRANSACTION  
BEGIN TRY  
SET NOCOUNT ON;
		 
		--Declaration Section 
		DECLARE @HasAccess bit,@ColumnName VARCHAR(200),@SQL NVARCHAR(MAX),@GridViewID BIGINT,@PrevName nvarchar(max),@ActualName nvarchar(max),@TableName varchar(100),@XML xml,@XML2 xml

		DECLARE @RTId INT,@RGId INT,@RCnt INT,@GResId INT
		
					
		SET @HasAccess=dbo.fnCOM_HasAccess(@RoleID,8,1)
		IF @HasAccess=0
		BEGIN
			RAISERROR('-105',16,1)
		END	 
		
		SELECT Top 1 @ActualName=Isnull(NAME,'') FROM ADM_FEATURES WITH(NOLOCK) WHERE Name=@Name AND FeatureID>50000 AND FeatureID<60000 AND FeatureID<>@FeatureID
		IF Isnull(@ActualName,'')<>''
		BEGIN
			RAISERROR('-112',16,1)
		END

		SELECT @TableName=TableName,@PrevName=NAME FROM ADM_FEATURES WITH(NOLOCK) WHERE FeatureID=@FeatureID 

		IF(SELECT COUNT(*) FROM ADM_FEATURES WITH(NOLOCK) WHERE FeatureID=@FeatureID AND IsEnabled=0)>0
		BEGIN--ACTIVATE COSTCENTER TO MENU
			--CREATE COSCENTER IN MENU			
			EXEC spCOM_CreateCostCenterMenu @FeatureID,@Name,@UserName ,@UserID,@CompanyGUID
			
			UPDATE ADM_FEATURES SET NAME=@Name,IsEnabled=1,ISUSERDEFINED=0 WHERE FeatureID=@FeatureID
			
			insert into ADM_FeatureActionRoleMap(RoleID,FeatureActionID,Status,CreatedBy,CreatedDate)  
			SELECT 1,b.FeatureActionID,1,@UserName,CONVERT(float,getdate()) FROM ADM_FEATURES a WITH(NOLOCK)
			join adm_featureaction b WITH(NOLOCK) on a.featureid=b.featureid
			left join adm_featureactionRoleMap m WITH(NOLOCK) on m.featureactionid=b.featureactionid and m.roleid=1
			WHERE  a.featureid=@FeatureID  and FeatureActiontypeid<>213 and m.Roleid is null
		END
		ELSE--FOR UPDATING FEATURENAME
		BEGIN
			UPDATE ADM_FEATURES SET NAME=@Name WHERE FeatureID=@FeatureID
			
			UPDATE  [COM_LanguageResources] set ResourceName=replace(ResourceName,@PrevName,@Name)
									,ResourceData=replace(ResourceData,@PrevName,@Name) 
			WHERE    (RESOURCEID IN (SELECT FEATUREACTIONRESOURCEID FROM ADM_RIBBONVIEW WITH(NOLOCK) WHERE FEATUREID=@FeatureID)
				   OR RESOURCEID IN (SELECT ScreenResourceID FROM ADM_RIBBONVIEW WITH(NOLOCK) WHERE FEATUREID=@FeatureID)
				   OR RESOURCEID IN (SELECT ToolTipTitleResourceID FROM ADM_RIBBONVIEW WITH(NOLOCK) WHERE FEATUREID=@FeatureID)
				   OR RESOURCEID IN (SELECT GroupResourceID FROM ADM_RIBBONVIEW WITH(NOLOCK) WHERE FEATUREID=@FeatureID)
				   OR RESOURCEID IN (SELECT ToolTipDescResourceID FROM ADM_RIBBONVIEW WITH(NOLOCK) WHERE FEATUREID=@FeatureID))
			
			--update ADM_RIBBONVIEW set SCREENNAME=replace(SCREENNAME,@PrevName,@Name) WHERE FEATUREID=@FeatureID

			SELECT @RTId=TabID,@RGId=GroupID,@GResId=GroupResourceID FROM ADM_RIBBONVIEW WITH(NOLOCK) WHERE FEATUREID=@FeatureID 
			SELECT @RCnt=COUNT(RibbonViewID) FROM ADM_RIBBONVIEW WITH(NOLOCK) WHERE TabID=@RTId AND GroupName=@RibbonGroup
			IF(@RCnt=0)
			BEGIN
				SELECT @RGId=MAX(GroupID)+1 FROM ADM_RIBBONVIEW WITH(NOLOCK)
				
				SELECT @GResId=MAX(ResourceID)+1 FROM COM_LanguageResources WITH(NOLOCK)
				INSERT INTO COM_LanguageResources
				SELECT @GResId,@RibbonGroup,1,'English',@RibbonGroup,NULL,NULL,NULL,NULL,NULL,NULL,'Others'
			END
			ELSE
			BEGIN
				SELECT @RGId=GroupID,@GResId=GroupResourceID FROM ADM_RIBBONVIEW WITH(NOLOCK) WHERE TabID=@RTId AND GroupName=@RibbonGroup
			END

			update ADM_RIBBONVIEW set SCREENNAME=replace(SCREENNAME,@PrevName,@Name),GroupID=@RGId,GroupName=@RibbonGroup,GroupResourceID=@GResId WHERE FEATUREID=@FeatureID and TabID=7
		END
		
		UPDATE ADM_GridView SET ViewName=@Name WHERE FeatureID=@FeatureID AND CostCenterID=@FeatureID
		
		UPDATE [COM_LanguageResources] set ResourceName=replace(ResourceName,@PrevName,@Name)
								,ResourceData=replace(ResourceData,@PrevName,@Name) 
		WHERE RESOURCEID IN (SELECT RESOURCEID FROM ADM_FEATUREACTION WITH(NOLOCK) WHERE FEATUREID=@FeatureID)
		
		UPDATE [COM_LanguageResources] set ResourceData=@Name
		WHERE RESOURCEID in (SELECT RESOURCEID FROM ADM_FEATURES WITH(NOLOCK) WHERE FeatureID=@FeatureID)
		
		UPDATE [COM_LanguageResources] set ResourceData=@Name
		WHERE RESOURCEID in (SELECT RESOURCEID FROM ADM_GridView WITH(NOLOCK) WHERE FeatureID=@FeatureID)
		
		UPDATE ADM_ListView SET ListViewName=REPLACE(ListViewName,@PrevName,@Name) WHERE FeatureID=@FeatureID AND CostCenterID=@FeatureID
		SET @SQL='UPDATE '+@TableName+' SET CODE='''+@Name+''' , NAME='''+@Name+''' WHERE PARENTID=0 or nodeid=1'
		EXEC(@SQL)
		
		SET @XML=@Options
		
		update ADM_CostCenterTab 
		set IsVisible=isnull((SELECT X.value('@Assign','int') FROM @XML.nodes('/Options/Tabs') as Data(X)),1)
		where CostCenterID=@FeatureID and IsTabUserDefined=0 and CCTabName='Assign'
		
		update ADM_CostCenterTab 
		set IsVisible=isnull((SELECT X.value('@Contacts','int') FROM @XML.nodes('/Options/Tabs') as Data(X)),1)
		where CostCenterID=@FeatureID and IsTabUserDefined=0 and CCTabName='Contacts'
		
		update ADM_CostCenterTab 
		set IsVisible=isnull((SELECT X.value('@Address','int') FROM @XML.nodes('/Options/Tabs') as Data(X)),1)
		where CostCenterID=@FeatureID and IsTabUserDefined=0 and CCTabName='Address'
		
		update ADM_CostCenterTab 
		set IsVisible=isnull((SELECT X.value('@Notes','int') FROM @XML.nodes('/Options/Tabs') as Data(X)),1)
		where CostCenterID=@FeatureID and IsTabUserDefined=0 and CCTabName='Notes'
		
		update ADM_CostCenterTab 
		set IsVisible=isnull((SELECT X.value('@Attachments','int') FROM @XML.nodes('/Options/Tabs') as Data(X)),1)
		where CostCenterID=@FeatureID and IsTabUserDefined=0 and CCTabName='Attachments'
		
		update ADM_CostCenterTab 
		set IsVisible=isnull((SELECT X.value('@General','int') FROM @XML.nodes('/Options/Tabs') as Data(X)),1)
		where CostCenterID=@FeatureID and IsTabUserDefined=0 and CCTabName='General'
		
		
		if(isnull((SELECT X.value('@Type','int') FROM @XML.nodes('/Options') as Data(X)),1)=1)
		begin
			update ADM_CostCenterDef 
			set IsVisible=0
			where CostCenterID=@FeatureID and SysColumnName IN ('CreditDays','CreditLimit','PurchaseAccount','SalesAccount'
			,'DebitDays','DebitLimit')
			
			select @SQL=Value from COM_CostCenterPreferences with(nolock) where CostCenterID=@FeatureID and Name='ImageDimensions'
			SET @XML2=@SQL
			set @SQL='RowSpan="'+isnull((SELECT X.value('@RowSpan','nvarchar(20)') FROM @XML2.nodes('/XML') as Data(X)),'1')+'"'
			set @SQL+=' ColumnSpan="'+isnull((SELECT X.value('@ColumnSpan','nvarchar(20)') FROM @XML2.nodes('/XML') as Data(X)),'1')+'"'			
			set @SQL+=' ShowImage="'+isnull((SELECT X.value('@Image','nvarchar(20)') FROM @XML.nodes('/Options/Tabs') as Data(X)),'1')+'"'
			set @SQL='<XML '+@SQL+'/>'			
			update COM_CostCenterPreferences
			set Value=@SQL
			where CostCenterID=@FeatureID and Name='ImageDimensions'
		end
		else
		begin
			update ADM_CostCenterDef 
			set IsVisible=1
			where CostCenterID=@FeatureID and SysColumnName IN ('CreditDays','CreditLimit','PurchaseAccount','SalesAccount'
			,'DebitDays','DebitLimit')
		end	
		
		--select * from ADM_CostCenterDef where CostCenterID=@FeatureID
	--	select * from ADM_CostCenterTab where CostCenterID=@FeatureID and IsTabUserDefined=0 
			
COMMIT TRANSACTION
SELECT * FROM ADM_FEATURES WITH(NOLOCK) WHERE FeatureID=@FeatureID       
SELECT ErrorMessage,ErrorNumber FROM COM_ErrorMessages WITH(nolock) 
WHERE ErrorNumber=100 AND LanguageID=@LangID    
SET NOCOUNT OFF;  
RETURN 1  
END TRY
BEGIN CATCH  
	--Return exception info [Message,Number,ProcedureName,LineNumber]  
	IF ERROR_NUMBER()=50000
	BEGIN
		SELECT * FROM ADM_COStCENTERDEF WITH(NOLOCK) WHERE COSTCENTERID=31    
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

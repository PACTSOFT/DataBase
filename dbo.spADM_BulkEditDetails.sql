USE PACT2C222
GO
SET ANSI_NULLS, QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spADM_BulkEditDetails]
	@Type [int],
	@ID [bigint],
	@CostCenterID [int],
	@Name [nvarchar](100),
	@FieldXML [nvarchar](max),
	@FilterXML [nvarchar](max),
	@Options [nvarchar](max),
	@UserName [nvarchar](50),
	@UserID [int],
	@RoleID [int],
	@LangID [int] = 1
WITH ENCRYPTION, EXECUTE AS CALLER
AS
BEGIN TRANSACTION      
BEGIN TRY      
SET NOCOUNT ON;    
	
	DECLARE @RETVALUE INT,@TblName NVARCHAR(50)
	DECLARE @AuditTrial BIT,@return_value bigint,@DocID bigint,@isinv bit,@ModDate float

	SET @RETVALUE=1
	IF @Type=1
	BEGIN
		--Docs
		SELECT CostCenterID,DocumentName Name,IsInventory FROM ADM_DocumentTypes with(nolock)
		UNION ALL
		SELECT FeatureID,Name,null IsInventory FROM ADM_Features with(nolock) WHERE (FeatureID in(2,3,47,48,95,92,93,94,16) or FeatureID>50000) and IsEnabled=1 
		order by Name
	END
	ELSE IF @Type=2
	BEGIN
		--Fields
		/*SELECT C.CostCenterColID,R.ResourceData Name,C.SysColumnName,*
		FROM ADM_CostCenterDef C WITH(NOLOCK) LEFT JOIN 
		COM_LanguageResources R WITH(NOLOCK) ON R.ResourceID=C.ResourceID AND R.LanguageID=@LangID
		WHERE C.CostCenterID=@CostCenterID  AND IsColumnInUse = 1 and SysColumnName!=''*/
		IF @CostCenterID>40000 and @CostCenterID<50000
		BEGIN			
			SELECT @TblName=TableName FROM ADM_Features WITH(NOLOCK) WHERE FeatureID=@CostCenterID
			
			SELECT C.CostCenterColID,R.ResourceData as UserColumnName ,C.CostCenterID,C.CostCenterName,C.SysTableName,C.SysColumnName,
			 CASE WHEN C.UserColumnType='Date' OR C.UserColumnType='DateTime' OR C.UserColumnType='Time' THEN 'DATE' 
			 WHEN  C.SysColumnName like 'dcAlpha%' and (C.UserColumnType='Numeric' AND C.ColumnDataType='TEXT') THEN 'FLOAT' 
			 ELSE upper(C.ColumnDataType) END ColumnDataType,
			C.IsForeignKey,C.ParentCostCenterID,C.ParentCostCenterSysName,C.ParentCostCenterColSysName,C.ParentCCDefaultColID,
			C.ColumnCostCenterID,C.ColumnCCListViewTypeID,C.UserProbableValues,C.UserColumnType,C.IsColumnUserDefined,C.Decimal--,FC.SysColumnName
			FROM ADM_CostCenterDef C WITH(NOLOCK)
			--LEFT JOIN ADM_CostCenterDef FC WITH(NOLOCK) ON FC.CostCenterColID=C.ParentCCDefaultColID
			,COM_LanguageResources R WITH(NOLOCK)
			WHERE C.CostCenterID=@CostCenterID AND C.ResourceID=R.ResourceID AND R.LanguageID=@LangID 
				AND (C.IsValidReportBuilderCol=1 or C.ParentCostCenterID=2 or C.ParentCostCenterID=3) AND C.IsColumnInUse=1 AND (C.SysColumnName not like 'dcNum%' and C.SysColumnName not like 'dcCalcNumFC%' and C.SysColumnName not like 'dcCurrID%' and C.SysColumnName not like 'dcExchRT%')
			UNION ALL
			SELECT -1,'Status' UserColumnName ,@CostCenterID,'' CostCenterName,@TblName SysTableName,'StatusID' SysColumnName,'' ColumnDataType,
			1 IsForeignKey,113 ParentCostCenterID,'COM_Status' ParentCostCenterSysName,'StatusID' ParentCostCenterColSysName,22872 ParentCCDefaultColID,
			113 ColumnCostCenterID,0 ColumnCCListViewTypeID,null UserProbableValues,null UserColumnType,0 IsColumnUserDefined,null Decimal
			ORDER BY UserColumnName
						
			SELECT D.CostCenterColID,D.Formula,C.UserColumnName,C.SysColumnName FROM ADM_DocumentDef D WITH(NOLOCK) 
			INNER JOIN ADM_CostCenterDef C WITH(NOLOCK) ON D.CostCenterColID=C.CostCenterColID
			WHERE D.CostCenterID=@CostCenterID AND D.Formula IS NOT NULL AND D.Formula!='' AND C.IsColumnInUse=1
			
			select StatusID ID,Status Name from COM_Status with(nolock) WHERE CostCenterID=400
			
			select prefname,prefvalue from com_documentpreferences with(nolock) where CostCenterID=@CostCenterID and prefname='AppDate' order by prefname
		END
		ELSE
		BEGIN		
			SELECT C.CostCenterColID,R.ResourceData as UserColumnName ,C.CostCenterID,C.CostCenterName,C.SysTableName,C.SysColumnName,
			 CASE WHEN C.UserColumnType='Date' OR C.UserColumnType='DateTime' OR C.UserColumnType='Time' THEN 'DATE' 
			 WHEN  C.SysColumnName like 'dcAlpha%' and (C.UserColumnType='Numeric' AND C.ColumnDataType='TEXT') THEN 'FLOAT' 
			 ELSE upper(C.ColumnDataType) END ColumnDataType,
			C.IsForeignKey,C.ParentCostCenterID,C.ParentCostCenterSysName,C.ParentCostCenterColSysName,C.ParentCCDefaultColID,
			C.ColumnCostCenterID,C.ColumnCCListViewTypeID,C.UserProbableValues,C.UserColumnType,C.IsColumnUserDefined,C.Decimal--,FC.SysColumnName
			FROM ADM_CostCenterDef C WITH(NOLOCK)
			--LEFT JOIN ADM_CostCenterDef FC WITH(NOLOCK) ON FC.CostCenterColID=C.ParentCCDefaultColID
			,COM_LanguageResources R WITH(NOLOCK)
			WHERE C.CostCenterID=@CostCenterID AND C.ResourceID=R.ResourceID AND R.LanguageID=@LangID 
				AND C.IsValidReportBuilderCol=1 AND C.IsColumnInUse=1 
			ORDER BY UserColumnName
			
			if(@CostCenterID=2 or @CostCenterID=3 or (@CostCenterID>=50001 and @CostCenterID<=50050))
				select StatusID ID,Status Name from COM_Status with(nolock) WHERE CostCenterID=@CostCenterID or featureid=1
			else
				select StatusID ID,Status Name from COM_Status with(nolock) WHERE CostCenterID=@CostCenterID

			SELECT * FROM COM_CostCenterCodeDef with(nolock) where CostCenterID=@CostCenterID

			if @CostCenterID=2
			begin
				SELECT Name,Value FROM COM_CostCenterPreferences with(nolock) WHERE CostCenterID=@CostCenterID and Name='AccountCodeAutoGen'

				select AccountTypeID,AccountType from acc_accounttypes with(nolock)
			end
			else if @CostCenterID=3
			begin
				SELECT Name,Value FROM COM_CostCenterPreferences with(nolock) WHERE CostCenterID=@CostCenterID and Name='ProductCodeAutoGen'

				select ProductTypeID,ProductType from inv_producttypes with(nolock)
			end
			else
			begin
				SELECT Name,Value FROM COM_CostCenterPreferences with(nolock) WHERE CostCenterID=@CostCenterID and Name='CodeAutoGen'
			end
			
		END
	
	END
	ELSE IF @Type=3
	BEGIN
		SELECT B.*
		FROM ADM_BulkEditTemplate B WITH(NOLOCK)
		WHERE B.ID=@ID 
	END
	ELSE IF @Type=4
	BEGIN
		IF EXISTS (SELECT * FROM ADM_BulkEditTemplate WITH(NOLOCK) WHERE Name=@Name AND ID<>@ID)
	    BEGIN
			RAISERROR('-408',16,1)  
	    END
	    
		IF @ID=0
		BEGIN
			INSERT INTO ADM_BulkEditTemplate(Name,CostCenterID,FieldsXML,FilterXML,Options,GUID,CreatedDate,CreatedBy)
			VALUES(@Name,@CostCenterID,@FieldXML,@FilterXML,@Options,newID(),convert(float,getdate()),@UserName)
			SET @ID=SCOPE_IDENTITY()			
		END
		ELSE
		BEGIN
			UPDATE ADM_BulkEditTemplate
			SET Name=@Name,
				FieldsXML=@FieldXML,
				FilterXML=@FilterXML,
				Options=@Options,
				ModifiedDate=convert(float,getdate()),
				ModifiedBy=@UserName
			WHERE ID=@ID
		END
		SET @RETVALUE=@ID
	END
	ELSE IF @Type=5
	BEGIN
		DELETE FROM ADM_BulkEditTemplate
		WHERE ID=@ID
	END
	ELSE IF @Type=6
	BEGIN
		SELECT B.*
		FROM ADM_BulkEditTemplate B WITH(NOLOCK)
		WHERE B.ID=@ID 
		
		SELECT @CostCenterID=CostCenterID
		FROM ADM_BulkEditTemplate B WITH(NOLOCK)
		WHERE B.ID=@ID
		
		SELECT Name,TableName FROM ADM_Features F WITH(NOLOCK)
		WHERE FeatureID=@CostCenterID
		
		if(@CostCenterID>4000 and @CostCenterID<50000)
			SELECT top 1 convert(int,IsLineWise) IsLineWise FROM COM_WorkFlowDef a WITH(nolock) 
			WHERE a.CostCenterID=@CostCenterId
			order by IsLineWise desc
		else
			SELECT 0 IsLineWise WHERE 1<>1
		
		/*if(@CostCenterID>40000 and @CostCenterID<50000)
		begin
			SELECT D.CostCenterColID,D.Formula,C.UserColumnName,C.SysColumnName FROM ADM_DocumentDef D WITH(NOLOCK) 
			INNER JOIN ADM_CostCenterDef C WITH(NOLOCK) ON D.CostCenterColID=C.CostCenterColID
			WHERE D.CostCenterID=@CostCenterID AND D.Formula IS NOT NULL AND D.Formula!='' AND C.IsColumnInUse=1
		end
		else
		begin
			 SELECT 1 UnUsed2 WHERE 1<>1
		end*/
	END
	ELSE IF @Type=7
	BEGIN
		--DECLARE @XML xml
		--SELECT @TblName=TableName FROM ADM_Features WITH(NOLOCK) WHERE FeatureID=@CostCenterID
		
		--SET @XML=@FieldXML
		
		--UPDATE COM_DocTextData
		EXEC(@FieldXML)
		if(@FilterXML is not null and @FilterXML<>'')
		BEGIN
			SET @AuditTrial=0
			SELECT @AuditTrial=CONVERT(BIT,PrefValue) FROM COM_DocumentPreferences with(nolock) 			
			WHERE CostCenterID=@CostCenterID and PrefName='AuditTrial'
			
			SELECT @isinv=isinventory FROM adm_documenttypes with(nolock) 			
			WHERE CostCenterID=@CostCenterID
	
			if @isinv=1
				select @CostCenterID=CostCenterID,@DocID=DocID from INV_DocDetails with(nolock) where VoucherNo=@FilterXML
			else
				select @CostCenterID=CostCenterID,@DocID=DocID from ACC_DocDetails with(nolock) where VoucherNo=@FilterXML

			if exists(select A.* from com_notifTemplate T with(nolock) join COM_NotifTemplateAction A with(nolock) on A.TemplateID=T.TemplateID
					where CostCenterID=@CostCenterID and A.ActionID=-3)
			begin
				if not exists (select * from com_schevents with(nolock) where CostCenterID=@CostCenterID and NodeID=@DocID and CompanyGUID=@Name)
					EXEC spCOM_SetNotifEvent -3,@CostCenterID,@DocID,@Name,@UserName,@UserID,@RoleID
			end
			
			IF (@AuditTrial=1)  
			BEGIN				
				set @ModDate=convert(float,getdate())
				 EXEC @return_value = [spDOC_SaveHistory]      
					@DocID =@DocID ,
					@HistoryStatus='Bulk Edit',
					@Ininv=@isinv,
					@ReviseReason ='',
					@LangID =@LangID,
					@UserName=@UserName,
					@ModDate=@ModDate
			END
		END
	END
	ELSE IF @Type=8
	BEGIN
		DECLARE @SQL NVARCHAR(MAX),@TableName NVARCHAR(30),@PrimaryKey NVARCHAR(30)
		SELECT @TableName=TableName,@PrimaryKey=PrimaryKey FROM ADM_Features WITH(NOLOCK) 
		WHERE FeatureID=@CostCenterID 
		SET @SQL='SELECT GUID FROM '+@TableName +' WITH(NOLOCK) WHERE '+@PrimaryKey+'='+CONVERT(NVARCHAR,@ID)
		EXEC(@SQL)
	END
	ELSE IF @Type=9
	BEGIN
		--CHECK AUDIT TRIAL ALLOWED AND INSERTING AUDIT TRIAL DATA    
		SET @AuditTrial=0
		if @ID=1
			select @CostCenterID=CostCenterID,@DocID=DocID from INV_DocDetails with(nolock) where VoucherNo=@Name
		else
			select @CostCenterID=CostCenterID,@DocID=DocID from ACC_DocDetails with(nolock) where VoucherNo=@Name
		SELECT @AuditTrial=CONVERT(BIT,PrefValue) FROM COM_DocumentPreferences with(nolock) WHERE CostCenterID=@CostCenterID and PrefName='AuditTrial'
		select @AuditTrial AuditTrial
		IF (@AuditTrial=1)  
		BEGIN
			set @ModDate=convert(float,getdate())
			 EXEC @return_value = [spDOC_SaveHistory]      
				@DocID =@DocID ,
				@HistoryStatus='Bulk Edit',
				@Ininv=@ID,
				@ReviseReason ='',
				@LangID =@LangID,
				@ModDate=@ModDate
		END   
	END
	ELSE IF @Type=10
	BEGIN
		select ID,Name from ADM_BulkEditTemplate with(nolock)
		where ID IN (SELECT R.ID FROM ADM_Assign M with(nolock) inner join ADM_BulkEditTemplate R with(nolock) on R.ID=M.NodeID
			WHERE M.CostCenterID=49 and UserID=@ID OR RoleID=@CostCenterID OR GroupID IN (SELECT GID FROM COM_Groups with(nolock) WHERE UserID=@ID or RoleID=@CostCenterID)
			GROUP BY R.ID)
		order by Name
	END
	
	
COMMIT TRANSACTION     
SET NOCOUNT OFF;       
RETURN @RETVALUE
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

USE PACT2C222
GO
SET ANSI_NULLS, QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spCRM_SetImportDataToLeadProducts]
	@PRODUCTXML [nvarchar](max),
	@AccountName [nvarchar](max) = null,
	@AccountCode [nvarchar](max) = null,
	@IsCode [bit] = NULL,
	@CompanyGUID [nvarchar](50),
	@UserName [nvarchar](50),
	@UserID [int],
	@RoleID [int],
	@LangID [int] = 1
WITH ENCRYPTION, EXECUTE AS CALLER
AS
BEGIN TRANSACTION  
BEGIN TRY  
SET NOCOUNT ON;
		--Declaration Section  
		DECLARE @Dt FLOAT ,@XML XML,@LeadID INT,@Qty float,@UOMID INT,@SQL NVARCHAR(MAX), @return_value INT
		DECLARE @NodeID INT,@BINID INT,@ExtraFields NVARCHAR(MAX),@tempCode NVARCHAR(300),@PRODUCTID INT,@BIN NVARCHAR(300), @I INT,@COUNT INT,@CCID INT,
		@PRODUCTNAME NVARCHAR(300),@CRMPRODUCTNAME NVARCHAR(300),@DESCR NVARCHAR(300),  @TableName nvarchar(300),@CostCenterId INT
		SET @Dt=CONVERT(FLOAT,GETDATE())
		
		SELECT @CostCenterId=ISNULL(VALUE,'0') FROM ADM_GLOBALPREFERENCES WITH(NOLOCK) WHERE NAME='CRM-Products'
		
		SET @XML=@PRODUCTXML
		DECLARE @TABLE TABLE(ID INT IDENTITY(1,1),PRODUCT NVARCHAR(300),CRMPRODUCT NVARCHAR(300),QUANTITY NVARCHAR(300),DESCP NVARCHAR(300)
		,Extra NVARCHAR(300))
		SELECT Top 1 @TableName=SysTableName FROM ADM_CostCenterDef WITH(NOLOCK) WHERE CostCenterID=@CostCenterId  
		
		 if @IsCode=0
			SELECT @LeadID=LEADID FROM CRM_LEADS WITH(NOLOCK) WHERE Company=LTRIM(RTRIM(@AccountName))
	    else 
			SELECT @LeadID=LEADID FROM CRM_LEADS WITH(NOLOCK) WHERE Code=LTRIM(RTRIM(@AccountCode))
	  
		INSERT INTO @TABLE
		SELECT
			X.value('@Product','nvarchar(500)')
           ,X.value('@CRMProduct','nvarchar(max)')
			,X.value('@Quantity','nvarchar(max)')
			,X.value('@Description','nvarchar(max)')
			,X.value('@ExtraFields','nvarchar(max)')
	  	from @XML.nodes('/XML/Row') as Data(X)
	  	
	  	SELECT @I=1,@COUNT=COUNT(*) FROM @TABLE
	  	WHILE @I<=@COUNT
	  	BEGIN
	  	
	  	 SELECT @PRODUCTNAME=LTRIM(RTRIM(PRODUCT)),@ExtraFields=LTRIM(RTRIM(Extra)),
	  	 @DESCR=LTRIM(RTRIM(DESCP)),@Qty=QUANTITY,@CRMPRODUCTNAME=LTRIM(RTRIM(CRMPRODUCT)) FROM @TABLE WHERE ID=@I
	  	 
	  	 IF(@CostCenterId=0)
	  	 BEGIN
	  		 IF @IsCode=1
	  			 SELECT @PRODUCTID =PRODUCTID,@UOMID=UOMID FROM INV_PRODUCT WITH(NOLOCK) WHERE PRODUCTNAME=@PRODUCTNAME
			 ELSE 
				 SELECT @PRODUCTID =PRODUCTID,@UOMID=UOMID FROM INV_PRODUCT WITH(NOLOCK) WHERE PRODUCTCODE=@PRODUCTNAME
		 END
		 ELSE
		 BEGIN 
			 
			 SELECT @PRODUCTID=ISNULL(VALUE,1) FROM COM_COSTCENTERPREFERENCES WITH(NOLOCK) WHERE FEATUREID=3 
			  and Name='TempPartProduct'
			 SELECT @UOMID=UOMID FROM INV_PRODUCT WITH(NOLOCK) WHERE PRODUCTID=@PRODUCTID 
			 
		 END	 
	  		SET @tempCode=' @return_value INT OUTPUT'
	  	 
	  	    SET @SQL=' select @return_value=NodeID  from '+@TableName+' WITH(NOLOCK) WHERE replace(NAME,'' '','''')=replace('''+@CRMPRODUCTNAME+''' ,'' '','''')'  
	  	    EXEC sp_executesql @SQL, @tempCode,@return_value OUTPUT  
	  	    
	  	    
	  	    IF (@return_value=0 OR @return_value='' OR @return_value IS NULL)
	  	    AND @CostCenterId>0
	  	    BEGIN
	  				
	  				EXEC @return_value = [dbo].[spCOM_SetCostCenter]
					@NodeID = 0,@SelectedNodeID = 0,@IsGroup = 0,
					@Code = @CRMPRODUCTNAME,
					@Name = @CRMPRODUCTNAME,
					@AliasName=@CRMPRODUCTNAME,@STATUSID=87,
					@PurchaseAccount=0,@SalesAccount=0, 
					@CustomFieldsQuery=NULL,@AddressXML=NULL,@AttachmentsXML=NULL,
					@CustomCostCenterFieldsQuery=NULL,@ContactsXML=NULL,@NotesXML=NULL,
					@CostCenterID =@CostCenterId,@CompanyGUID=@CompanyGUID,@GUID='GUID',@UserName=@UserName,@RoleID=@RoleID,@UserID=@UserID
				
	  	    END
	  	    IF @PRODUCTID IS NULL OR @PRODUCTID=''
	  		BEGIN	
	  			SET @PRODUCTID=1
	  			SET @UOMID=NULL
	  		END
			 
			 IF @return_value=NULL OR @return_value=''
				SET @return_value=0
				
		 
	  		INSERT into CRM_ProductMapping(CCNodeID,CostCenterID,ProductID,CRMProduct,Quantity,UOMID,Description,CompanyGUID,GUID,CreatedBy,CreatedDate)
	  		VALUES (@LeadID,86,@PRODUCTID,@return_value,@Qty,@UOMID,@DESCR,@CompanyGUID,NEWID(),@UserName,@Dt)
	  		SET @NodeID=SCOPE_IDENTITY()
	  		
	  		IF @ExtraFields<>'' AND @ExtraFields IS NOT NULL
	  		BEGIN
	  			 SET @ExtraFields	 =SUBSTRING(@ExtraFields,1,LEN(@ExtraFields)-1)	
	  			SET @SQL=' UPDATE CRM_ProductMapping SET '+@ExtraFields+' where PRODUCTMAPID='+CONVERT(NVARCHAR,@NodeID)
	  			EXEC (@SQL)
	  		END
	  		
	  set @PRODUCTNAME=''
	  set @ExtraFields=''
	  set @DESCR=''
	  set @Qty=''
	  set @CRMPRODUCTNAME=''
	  set @return_value=0
	  
	  	SET @I=@I+1
	  	END
	  
COMMIT TRANSACTION  
--ROLLBACK TRANSACTION
SELECT ErrorMessage,ErrorNumber FROM COM_ErrorMessages WITH(nolock) 
WHERE ErrorNumber=100 AND LanguageID=@LangID     
SET NOCOUNT OFF;  
RETURN @NodeID
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

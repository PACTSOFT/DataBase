﻿USE PACT2C222
GO
SET ANSI_NULLS, QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spDOC_GetImportLinkRefData]
	@COSTCENTERCOlID [int],
	@DOCUMENTID [bigint],
	@UserID [int] = 0,
	@LangID [int] = 1
WITH ENCRYPTION, EXECUTE AS CALLER
AS
BEGIN TRY    
SET NOCOUNT ON;  

	DECLARE @TABLE NVARCHAR(50),@QUERY NVARCHAR(MAX),   @COLUMN NVARCHAR(200),  @TableName NVARCHAR(100),
	 @COSTCENTERID BIGINT ,@ID BIGINT , @Name nvarchar(200)
	 
	SELECT @COSTCENTERID= CostCenterID,@COLUMN=SYSCOLUMNNAME
	from ADM_CostCenterDef WITH(NOLOCK)  where CostCenterColID=@COSTCENTERCOlID
	 
	declare @cctable table(CCID nvarchar(50)) 
	SELECT @TableName=TABLENAME, @Name=Name FROM ADM_FEATURES WITH(NOLOCK)  WHERE FEATUREID =  @COSTCENTERID  
	
	select @COSTCENTERID COSTCENTERID, @Name Feature
	
	IF(@COSTCENTERID=2)
		SET @QUERY= 'SELECT ACCOUNTNAME NAME,AccountCode CODE,AccountID NodeID, isnull('+@COLUMN+',1) AccountID  from acc_accounts with(nolock) ' 
	else if (@COSTCENTERID=3)
	begin
		if(@COLUMN like '%ptAlpha%')
			SET @QUERY='SELECT PRODUCTNAME NAME, PRODUCTCODE CODE,P.ProductID NodeID,  ACCOUNTNAME, isnull(E.'+@COLUMN+',1) AccountID FROM INV_PRODUCT P WITH(NOLOCK)
			join INV_PRODUCTEXTENDED E WITH(NOLOCK) ON E.PRODUCTID=P.PRODUCTID
			LEFT JOIN ACC_ACCOUNTS A  WITH(NOLOCK) ON isnull(E.'+@COLUMN+',1)=A.ACCOUNTID'
		else
			SET @QUERY='SELECT PRODUCTNAME NAME, PRODUCTCODE CODE,ProductID NodeID,  ACCOUNTNAME, isnull(P.'+@COLUMN+',1) AccountID FROM INV_PRODUCT P WITH(NOLOCK)
			LEFT JOIN ACC_ACCOUNTS A  WITH(NOLOCK) ON isnull(P.'+@COLUMN+',1)=A.ACCOUNTID'
	end
	ELSE IF(@COSTCENTERID>50000)
	  SET @QUERY='SELECT NAME, CODE,NodeID ,ACCOUNTNAME,isnull(P.'+@COLUMN+',1) AccountID FROM '+@TableName+' P WITH(NOLOCK)
	  LEFT JOIN ACC_ACCOUNTS A  WITH(NOLOCK) ON P.'+@COLUMN+'=A.ACCOUNTID'
	print (@QUERY)
	EXEC(@QUERY)
	
	
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
		SELECT ErrorMessage, ERROR_MESSAGE() AS ServerMessage,ERROR_NUMBER() as ErrorNumber, ERROR_PROCEDURE()as ProcedureName,
		ERROR_LINE() AS ErrorLine
		FROM COM_ErrorMessages WITH(nolock) WHERE ErrorNumber=-999 AND LanguageID=@LangID
	END
 SET NOCOUNT OFF  
RETURN -999   
END CATCH  

GO
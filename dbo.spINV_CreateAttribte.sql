USE PACT2C222
GO
SET ANSI_NULLS, QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spINV_CreateAttribte]
	@CosCenterColID [bigint],
	@Name [varchar](300),
	@CompanyGUID [nvarchar](50),
	@GUID [nvarchar](50),
	@UserName [nvarchar](50),
	@UserID [bigint],
	@LangID [int] = 1
WITH ENCRYPTION, EXECUTE AS CALLER
AS
BEGIN TRANSACTION  
BEGIN TRY  
SET NOCOUNT ON;
		 
		--Declaration Section 
		DECLARE @HasAccess bit,@ColumnName VARCHAR(200) ,@SQL NVARCHAR(MAX),@GridViewID BIGINT
					
		
			UPDATE COM_LanguageResources SET ResourceData=@Name   
				WHERE ResourceID IN (SELECT ResourceID from ADM_COSTCENTERDEF  WHERE COSTCENTERCOLID=@CosCenterColID)

			SELECT @COLUMNNAME=SysColumnName from ADM_CostcenterDef where CostcenterColID=@CosCenterColID

			IF ( SELECT count(*) FROM  ADM_CostcenterDef WHERE  CosTCenterColID=@CosCenterColID and ISCOLUMNINUSE=0)>0
			BEGIN		
			UPDATE ADM_COSTCENTERDEF SET USERCOLUMNNAME=@Name , ISCOLUMNINUSE=1 WHERE COSTCENTERCOLID=@CosCenterColID
			SET @SQL='INSERT intO COM_Attributes  
					('+@COLUMNNAME +' 
					,[AttributeID]			
					,[StatusID] 		
					,[Depth]  
					,[ParentID]  
					,[lft]  
					,[rgt]  
					,[IsGroup]   
					,[GUID]  			 
					,[CreatedBy]  
					,[CreatedDate],CompanyGUID)  
			VALUES  
					('''+@Name  +''' 	
					,'+cast (@CosCenterColID as varchar)+'	 	   
					,0   			
					 ,1,0,1,2,1,NEWID()   
					,'''+@UserName  +'''
					,'+CAST (CONVERT(FLOAT,GETDATE()) AS VARCHAR)+
					','''+@CompanyGUID+''')'  
					--print @SQL
			EXEC(@SQL)

		INSERT INTO ADM_GridView(FeatureID,CostCenterID,ViewName,SearchFilter,UserID,RoleID,IsUserDefined,GUID,CreatedBy,CreatedDate)    
			VALUES(31,31,@Name,'A.'+@ColumnName+' IS NOT NULL',@UserID,1,0,NEWID(),@UserName,CONVERT(FLOAT,GETDATE())) 
		SET @GridViewID=SCOPE_IDENTITY()   
		
			--Insert costcenter gridview columns definition  
			INSERT INTO ADM_GridViewColumns(GridViewID,CostCenterColID,ColumnOrder,ColumnWidth,CreatedBy,CreatedDate)    
			VALUES(@GridViewID,@CosCenterColID,0,200,@UserName,CONVERT(FLOAT,GETDATE()))  
END
ELSE 
	BEGIN
				SET @SQL='UPDATE [COM_Attributes]  
			SET '+@ColumnName+' = '''+@Name+'''  			
			,[GUID]=newid()  
			,[ModifiedBy] = '''+@UserName+'''  
			,[ModifiedDate] = '+CAST(CONVERT(FLOAT,GETDATE()) AS VARCHAR)+'  
			WHERE ParentID=0 AND '+@ColumnName+' IS NOT NULL'
 		 
			 EXEC(@SQL) 

			SELECT @GridViewID=GridViewID FROM ADM_GridViewColumns WHERE CostCenterColID=@CosCenterColID
			UPDATE ADM_GridView SET ViewName=@Name WHERE  GridViewID=@GridViewID
	END

	 

COMMIT TRANSACTION
SELECT * FROM ADM_COStCENTERDEF WITH(NOLOCK) WHERE COSTCENTERID=31         
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

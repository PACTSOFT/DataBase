USE PACT2C222
GO
SET ANSI_NULLS, QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spCOM_SaveHistory]
	@CostCenterID [int],
	@NodeID [bigint],
	@HistoryStatus [nvarchar](32),
	@UserName [nvarchar](50) = '',
	@LangID [int] = 1
WITH ENCRYPTION, EXECUTE AS CALLER
AS
BEGIN TRANSACTION      
BEGIN TRY        
SET NOCOUNT ON;  
  
	DECLARE @UpdateSql NVARCHAR(MAX),@TableName NVARCHAR(32),@HistoryTableName NVARCHAR(48),@PrimaryKey NVARCHAR(32)       
 

	SELECT @TableName=TableName,@PrimaryKey=PrimaryKey FROM ADM_Features WITH(NOLOCK) WHERE FeatureID=@CostCenterID
	
	if exists(select name from sys.tables where name=@TableName+'_History')
		set @HistoryTableName=@TableName+'_History'
	else if exists(select name from sys.tables where name=@TableName+'History')
		set @HistoryTableName=@TableName+'History'
				 
	SET @UpdateSql=''
	SELECT @UpdateSql=@UpdateSql+','+a.name
	FROM sys.columns a
	JOIN sys.columns b on a.name=b.name and b.object_id= object_id(@TableName)
	WHERE a.object_id= object_id(@HistoryTableName) and a.name<>'ModifiedBy'
	
	set @UpdateSql= 'insert into '+@HistoryTableName+' (HistoryStatus,ModifiedBy'+@UpdateSql+') 
	select '''+@HistoryStatus+''','''+@UserName+''''+@UpdateSql+' from '+@TableName+' with(nolock) 
	WHERE '+@PrimaryKey+'='+CONVERT(NVARCHAR,@NodeID)     
	EXEC (@UpdateSql)
	
	
	if exists(select name from sys.tables where name=@TableName+'Extended')
	begin
		set @TableName=@TableName+'Extended'
		
		if exists(select name from sys.tables where name=@TableName+'_History')
			set @HistoryTableName=@TableName+'_History'
		else if exists(select name from sys.tables where name=@TableName+'History')
			set @HistoryTableName=@TableName+'History' 
			
		SET @UpdateSql=''
		SELECT @UpdateSql=@UpdateSql+','+a.name
		FROM sys.columns a
		JOIN sys.columns b on a.name=b.name and b.object_id= object_id(@TableName)
		WHERE a.object_id= object_id(@HistoryTableName) and a.name<>'ModifiedBy'
		
		set @UpdateSql= 'insert into '+@HistoryTableName+' (HistoryStatus,ModifiedBy'+@UpdateSql+') 
		select '''+@HistoryStatus+''','''+@UserName+''''+@UpdateSql+' from '+@TableName+' with(nolock) 
		WHERE '+@PrimaryKey+'='+CONVERT(NVARCHAR,@NodeID)     
		EXEC (@UpdateSql)	
    end
		

COMMIT TRANSACTION
SET NOCOUNT OFF;        
RETURN @NodeID
END TRY        
BEGIN CATCH  
  
  SELECT ErrorMessage, ERROR_MESSAGE() AS ServerMessage,ERROR_NUMBER() as ErrorNumber, ERROR_PROCEDURE()as ProcedureName, ERROR_LINE() AS ErrorLine      
  FROM COM_ErrorMessages WITH(nolock) WHERE ErrorNumber=-999 AND LanguageID=@LangID      
      
 
 ROLLBACK TRANSACTION      
 SET NOCOUNT OFF        
 RETURN -999         
    
    
END CATCH
GO

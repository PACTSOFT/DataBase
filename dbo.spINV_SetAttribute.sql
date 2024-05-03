USE PACT2C222
GO
SET ANSI_NULLS, QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spINV_SetAttribute]
	@AttributeID [bigint],
	@NodeID [bigint],
	@Value [nvarchar](200),
	@SelectedNodeID [bigint],
	@IsGroup [bit],
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
			
		DECLARE @Dt FLOAT,@XML xml  
		DECLARE @TempGuid NVARCHAR(50) 
		DECLARE @lft BIGINT,@rgt BIGINT,@Selectedlft BIGINT,@Selectedrgt BIGINT,@Depth INT,@ParentID BIGINT  
		DECLARE @SelectedIsGroup BIT, @ParentCode NVARCHAR(MAX),@UpdateSql NVARCHAR(MAX)
		DECLARE @HasAccess bit,@ColumnName VARCHAR(200) ,@SQL NVARCHAR(MAX)
		 SET @Dt=CONVERT(FLOAT,GETDATE())--Setting Current Date   

		--User acces check
		--IF @NodeID=0
		--BEGIN
		--	SET @HasAccess=dbo.fnCOM_HasAccess(@UserID,31,1)
		--END
		--ELSE
		--BEGIN
		--	SET @HasAccess=dbo.fnCOM_HasAccess(@UserID,31,3)
		--END
		--IF @HasAccess=0
		--BEGIN
		--	RAISERROR('-105',16,1)
		--END
			
			SELECT @COLUMNNAME=SysColumnName from ADM_CostcenterDef where CostcenterColID=@AttributeID
			--To SET Left,Right And Depth of Record  
			SELECT @SelectedIsGroup=IsGroup,@Selectedlft =lft,@Selectedrgt=rgt,@ParentID=ParentID,@Depth=Depth  
			FROM [COM_Attributes] WITH(NOLOCK) WHERE NodeID=@SelectedNodeID  
		  
			--IF No Record Selected or Record Doesn't Exist  
			IF(@SelectedIsGroup is null)   
			BEGIN
				SELECT @SelectedNodeID=NodeID,@SelectedIsGroup=IsGroup,@Selectedlft =lft,@Selectedrgt=rgt,@ParentID=ParentID,@Depth=Depth  
				FROM [COM_Attributes] WITH(NOLOCK) WHERE ParentID =0  and AttributeID=@AttributeID
		    END
		      
			IF(@SelectedIsGroup = 1)--Adding Node Under the Group  
			BEGIN  
				  UPDATE [COM_Attributes] SET rgt = rgt + 2 WHERE rgt > @Selectedlft and AttributeID=@AttributeID;  
				  UPDATE [COM_Attributes] SET lft = lft + 2 WHERE lft > @Selectedlft and AttributeID=@AttributeID;  
				  SET @lft =  @Selectedlft + 1  
				  SET @rgt = @Selectedlft + 2  
				  SET @ParentID = @SelectedNodeID  
				  SET @Depth = @Depth + 1  
			END  
			ELSE IF(@SelectedIsGroup = 0)--Adding Node at Same level  
			BEGIN  
				  UPDATE [COM_Attributes] SET rgt = rgt + 2 WHERE rgt > @Selectedrgt and AttributeID=@AttributeID;  
				  UPDATE [COM_Attributes] SET lft = lft + 2 WHERE lft > @Selectedrgt and AttributeID=@AttributeID;  
				  SET @lft =  @Selectedrgt + 1  
				  SET @rgt = @Selectedrgt + 2   
			END  
			ELSE  --Adding Root  
			BEGIN  
				  SET @lft =  1  
				  SET @rgt = 2   
				  SET @Depth = 0  
				  SET @ParentID =0  
				  SET @IsGroup=1  
			END  

		IF (@NodeID=0)--NodeID will be 0 in Create Process--  
		BEGIN--CREATE --  
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
			('''+@Value  +''' 	
			,'+cast (@AttributeID as varchar)+'	   
			,0   			
			 ,'+CAST (@Depth AS VARCHAR)+  
			 ','+CAST (@ParentID AS VARCHAR)+ 
			 ','+CAST (@lft AS VARCHAR) + 
			 ','+CAST (@rgt AS VARCHAR) +
			 ','+CAST (@IsGroup AS VARCHAR)+  
			',NEWID()   
			,'''+@UserName  +'''
			,'+CAST (@Dt AS VARCHAR)+
			','''+@CompanyGUID+''')'  
			--print @SQL
			EXEC(@SQL)
			SET @NodeID=SCOPE_IDENTITY()--Getting the NodeID  

		END  
		ELSE --UPDATE --  
		BEGIN  
			 
			SELECT @TempGuid=[GUID] FROM [COM_Attributes]  WITH(NOLOCK)   
			WHERE NodeID=@NodeID  

			IF(@TempGuid!=@Guid)  
			BEGIN  
				 RAISERROR('105',16,1) -- Need to Get Data From Error Table To return Error Message by Language 			 		 
			END  

			SET @SQL='UPDATE [COM_Attributes]  
			SET '+@COLUMNNAME+' = '''+@Value+'''  			
			,[GUID]=newid()  
			,[ModifiedBy] = '''+@UserName+'''  
			,[ModifiedDate] = '+CAST(@Dt AS VARCHAR)+'  
			WHERE NodeID='+CAST (@NodeID  AS VARCHAR)
			PRINT @SQL
			EXEC(@SQL) 
		END  

COMMIT TRANSACTION
SELECT * FROM [COM_Attributes] WITH(NOLOCK) WHERE NodeID=@NodeID         
SELECT ErrorMessage,ErrorNumber FROM COM_ErrorMessages WITH(nolock) 
WHERE ErrorNumber=100 AND LanguageID=@LangID    
SET NOCOUNT OFF;  
RETURN 1  
END TRY
BEGIN CATCH  
	--Return exception info [Message,Number,ProcedureName,LineNumber]  
	IF ERROR_NUMBER()=50000
	BEGIN
		SELECT * FROM [COM_Attributes] WITH(NOLOCK) WHERE NodeID=@NodeID
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

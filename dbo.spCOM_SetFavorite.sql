USE PACT2C222
GO
SET ANSI_NULLS, QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spCOM_SetFavorite]
	@Data [nvarchar](max) = null,
	@FavID [bigint] = 0,
	@FavName [nvarchar](100),
	@IsDefault [bit],
	@OptionsXML [nvarchar](max),
	@UserName [nvarchar](50),
	@UserID [bigint],
	@LangID [int] = 1
WITH ENCRYPTION, EXECUTE AS CALLER
AS
BEGIN TRANSACTION    
BEGIN TRY  
SET NOCOUNT ON;    
   
	--SP Required Parameters Check  
	IF @UserID IS NULL OR @UserID=''  
	BEGIN  
		RAISERROR('-100',16,1)  
	END
	
	declare @Dt float
	set @Dt=CONVERT(FLOAT,GETDATE())
--    select @FavID
	if @FavID>0
	begin
		update COM_Favourite set OptionsXML=@OptionsXML WHERE ID=@FavID
		DELETE FROM COM_Favourite WHERE FavID=@FavID and (TypeID=2 or TypeID=0)
	end
	else
	begin
		if exists (select top 1 FavName from COM_Favourite where FavName=@FavName)
		BEGIN  
			RAISERROR('-112',16,1)  
		END
		
		insert into COM_Favourite(TypeID,FavID,FavName,FeatureID,FeatureactionID,IsReport,DisplayName,RowNo,ColumnNo,ShortCutKey,CreatedBy,CreatedDt,OptionsXML)
		values(1,0,@FavName,0,0,0,'',null,null,null,@UserName,@Dt,@OptionsXML)
		set @FavID=SCOPE_IDENTITY()

		insert into ADM_Assign(CostCenterID,NodeID,UserID,RoleID,GroupID,CreatedBy,CreatedDate)
		select 69,@FavID,@UserID,0,0,@UserName,@Dt
	end
	
	DECLARE @XML XML,@COUNT INT,@I INT ,@R INT,@C INT   
	SET @XML=@Data  
   
	INSERT INTO COM_Favourite(TypeID,FavID,FeatureactionID,DisplayName,RowNo,ColumnNo,IsReport,ShortCutKey,FavName,
	CreatedBy,CreatedDt,FeatureID,Link,Category)  
	SELECT 2,@FavID,A.value('@FeatureActionID','BIGINT'),  
	A.value('@DisplayName','nvarchar(300)'),  
	A.value('@R','int'),  
	A.value('@ColumnNo','int'),  
	A.value('@isReport','int'),  
	A.value('@ShortcutKey','nvarchar(300)'),  
	@FavName,--A.value('@FavoriteName','nvarchar(300)'),  
	@UserName,@Dt
	,A.value('@FeatureID','BIGINT')
	,A.value('@Link','nvarchar(max)')
	,A.value('@Category','nvarchar(100)')
	FROM @XML.nodes('/XML/Row') as Data(A) 
	order by A.value('@RowNo','INT') ,  
	A.value('@ColumnNo','INT')
	
	if(@IsDefault=1)
	begin
		declare @DefaultFavID bigint
		select @DefaultFavID=FavID from COM_Favourite with(nolock) where TypeID=3 and FeatureactionID=@UserID
		if @DefaultFavID is null
			insert into COM_Favourite(TypeID,FavID,FavName,FeatureID,FeatureactionID,IsReport,DisplayName,RowNo,ColumnNo,ShortCutKey,CreatedBy,CreatedDt)
			values(3,@FavID,null,0,@UserID,0,'',null,null,null,@UserName,@Dt)
		else
			update COM_Favourite set FavID=@FavID WHERE TypeID=3 and FeatureactionID=@UserID
	end
	
	select * from COM_Favourite where FavID=@FavID

COMMIT TRANSACTION    
--ROLLBACK TRANSACTION  
 SET NOCOUNT OFF;    
 SELECT ErrorMessage,ErrorNumber FROM COM_ErrorMessages WITH(nolock)     
WHERE ErrorNumber=100 AND LanguageID=@LangID      
RETURN @FavID
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

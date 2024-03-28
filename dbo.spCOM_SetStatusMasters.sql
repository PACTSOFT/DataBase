USE PACT2C222
GO
SET ANSI_NULLS, QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spCOM_SetStatusMasters]
	@COSTCENTERID [int],
	@NODEID [int],
	@IsApprove [bit],
	@REMARKS [nvarchar](max),
	@CCGUID [nvarchar](50),
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
	DECLARE @temp nvarchar(100),@GUID  NVARCHAR(50),@Name nvarchar(100),@Level int,@maxLevel INT,@tempLevel int,
	@WID INT,@oldStatusID int,@STATUSID INT,@SQL nvarchar(max),@CStatusID INT, @Assigned INT=0

	--SP Required Parameters Check    
	IF @COSTCENTERID<0 OR @NODEID<0
	BEGIN    
		RAISERROR('-100',16,1)    
	END  
	
 

	  if(@CostCenterID=2)
		BEGIN
			select  @WID=WFID,@tempLevel=WFLevel,@GUID=[guid],@oldStatusID=Statusid 
	    	FROM ACC_Accounts WITH(NOLOCK) WHERE AccountID=@NODEID and WFID>0
		END
   ELSE if(@CostCenterID=3)
		BEGIN
			select  @WID=WFID,@tempLevel=WFLevel,@GUID=[guid],@oldStatusID=Statusid 
	    	FROM INV_Product WITH(NOLOCK) WHERE ProductID=@NODEID and WFID>0
		END

		ELSE if(@CostCenterID>=50001 and @CostCenterID<=50008)
		BEGIN
		 	declare @sqlSelect nvarchar(max)
			declare @TableName1 varchar(1000)
			select @TableName1 = TableName from ADM_Features  WITH(NOLOCK) where FeatureID=@CostCenterID
			 

			set @sqlSelect=' SELECT @WID=WFID,@tempLevel=WFLevel,@GUID=[guid],@oldStatusID=Statusid 
		FROM  '+@TableName1+' WITH(NOLOCK) where  NodeId='+ convert(nvarchar,@NodeID) +' '
			print (@sqlSelect)
				EXEC sp_executesql @sqlSelect,N'@WID int output,@tempLevel int output,@GUID NVARCHAR(50) output,@oldStatusID int output', @WID output,@tempLevel output,@GUID output ,@oldStatusID output

		END


	if(@CCGUID<>'' and @GUID!=@CCGUID)
	BEGIN
		RAISERROR('-101',16,1)  
	END
		
	SET @GUID=NEWID()

	if(@level is null) 
		SELECT @level=LevelID FROM [COM_WorkFlow]   WITH(NOLOCK)   
		where WorkFlowID=@WID and UserID =@UserID and LevelID>@tempLevel
		order by LevelID desc

	if(@level is null)  
		SELECT @level=LevelID FROM [COM_WorkFlow]  WITH(NOLOCK)    
		where WorkFlowID=@WID and RoleID =@RoleID and LevelID>@tempLevel
		order by LevelID desc
		
	if(@level is null)       
		SELECT @level=LevelID FROM [COM_WorkFlow] W WITH(NOLOCK)
		JOIN COM_Groups G WITH(NOLOCK) on w.GroupID=g.GID     
		where g.UserID=@UserID and WorkFlowID=@WID and LevelID>@tempLevel
		order by LevelID desc
		
	if(@level is null)  
		SELECT @level=LevelID FROM [COM_WorkFlow] W WITH(NOLOCK)
		JOIN COM_Groups G WITH(NOLOCK) on w.GroupID=g.GID     
		where g.RoleID =@RoleID and WorkFlowID=@WID and LevelID>@tempLevel
		order by LevelID desc
			
	select @maxLevel=max(LevelID) from COM_WorkFlow WITH(NOLOCK) where WorkFlowID=@WID
	if(@level is not null and  @maxLevel is not null and @maxLevel>@level)
	begin	
		IF(@level=1)
			set @StatusID=1001
		ELSE
		begin
			if @IsApprove=1
				set @StatusID=1002
			else
				set @StatusID=1003
		end
	END
	else if @IsApprove=1
	begin
	  if(@CostCenterID=2)
			BEGIN

				select @StatusID=1002
				select @CStatusID=NodeID from com_lookup with(nolock) where lookuptype=60 and IsDefault=1
				--set @CStatusID = (select top 1 statusid from com_status with(nolock) where costcenterid=@CostCenterID)
			
				if @CStatusID is null
					set @CStatusID=33
			END

		ELSE if(@CostCenterID>=50001 and @CostCenterID <=50008)
			BEGIN

				select @StatusID=1002
				select @CStatusID=NodeID from com_lookup with(nolock) where lookuptype=60 and IsDefault=1
			
				if @CStatusID is null
					set @CStatusID=43
			END
		else
			select @StatusID=StatusID from COM_Status with(nolock) where CostCenterID=@CostCenterID and [Status]='Active'
			--select * from COM_Status where CostCenterID=50001
	end
	else
		set @StatusID=1003



		
	if @oldStatusID!=@StatusID OR @Level!=@tempLevel
	begin 
		if(@WID>0)
		BEGIN
		   INSERT INTO COM_Approvals    
			  (CCID    
			  ,CCNODEID    
			  ,StatusID    
			  ,[Date]
			  ,Remarks 
			  ,UserID   
			  ,CompanyGUID,[GUID]    
			  ,CreatedBy,CreatedDate,WorkFlowLevel,DocDetID)      
			VALUES    
			  (@COSTCENTERID    
			  ,@NODEID 
			  ,@STATUSID    
			  ,CONVERT(FLOAT,GETDATE())
			  ,@REMARKS
			  ,@UserID
			  ,@CompanyGUID,newid()    
			  ,@UserName,CONVERT(FLOAT,GETDATE()),isnull(@level,0),0)
	      
			if @StatusID=1001 OR @StatusID=1002 OR @StatusID=1003 --UnApp,Rejected
				EXEC spCOM_SetNotifEvent @StatusID,@CostCenterID,@NodeID,'CompanyGUID',@UserName,@UserID,@RoleID
			else
				EXEC spCOM_SetNotifEvent -2000,@CostCenterID,@NodeID,'CompanyGUID',@UserName,@UserID,@RoleID
		END
	    
		 if(@CostCenterID=3 or @CostCenterID=2 )
		begin
		
			select @SQL='update '+TableName+' set StatusID='+convert(nvarchar,CASE  WHEN @CostCenterID=@CostCenterID THEN ISNULL(@CStatusID,@StatusID)  ELSE @StatusID END)+',WFLevel='+convert(nvarchar,@level)+' 
			where '+PrimaryKey+'='+convert(nvarchar,@NodeID)
			from ADM_Features with(nolock) where FeatureID=@CostCenterID
		end
		else  if(@CostCenterID>=50001 and @CostCenterID<=50008)
		begin
		PRINT '@CStatusID'
		PRINT @CStatusID
			select @SQL='update '+TableName+' set StatusID='+convert(nvarchar,CASE  WHEN @CostCenterID=@CostCenterID THEN ISNULL(@CStatusID,@StatusID)  ELSE @StatusID END)+',WFLevel='+convert(nvarchar,@level)+' 
			where '+PrimaryKey+'='+convert(nvarchar,@NodeID)
			from ADM_Features with(nolock) where FeatureID=@CostCenterID
		end
		print @SQL
		exec(@SQL)
			PRINT '@CStatusID'
		PRINT @CStatusID
		
			PRINT '@@CostCenterID'
		PRINT @CostCenterID
	 
	 
		
		IF @oldStatusID!=@StatusID AND EXISTS (SELECT * FROM COM_DocBridge WITH(NOLOCK) WHERE CostCenterID=50001 AND NodeID=@NodeID)
		BEGIN
			SELECT @CostCenterID=RefDimensionID,@NodeID=RefDimensionNodeID FROM COM_DocBridge WITH(NOLOCK) 
			WHERE CostCenterID=@CostCenterID AND NodeID=@NodeID
			
			if @CostCenterID>=50001
			begin
				IF(@StatusID<>1001 AND @StatusID<>1002 AND @StatusID<>1003)
					select @StatusID=StatusID from COM_Status with(nolock) where CostCenterID=@CostCenterID and [Status]='Active'
				select @SQL='update '+TableName+' set StatusID='+convert(nvarchar,@StatusID)+' where '+PrimaryKey+'='+convert(nvarchar,@NodeID)
				from ADM_Features with(nolock) where FeatureID=@CostCenterID
				exec(@SQL)
			end
		END
	END
COMMIT TRANSACTION  
SET NOCOUNT OFF;    
IF(@CStatusID IS NOT NULL  AND @CostCenterID IN(2,3) OR  (@CostCenterID>=50001 and @CostCenterID<=50008))
BEGIN
	select @temp=isnull(ResourceData,'') from COM_Status S WITH(NOLOCK)
	 join COM_LanguageResources R WITH(NOLOCK) on R.ResourceID=S.ResourceID and R.LanguageID=@LangID
	 where S.StatusID=@CStatusID
END
ELSE
BEGIN
	 select @temp=isnull(ResourceData,'') from COM_Status S WITH(NOLOCK)
	 join COM_LanguageResources R WITH(NOLOCK) on R.ResourceID=S.ResourceID and R.LanguageID=@LangID
	 where S.StatusID=@StatusID
END 
SELECT   @temp status,ErrorMessage + '   ' + isnull(@Name,'') +case when @temp<>'' then ' ['+@temp+']' else '' end  as ErrorMessage,ErrorNumber 
FROM COM_ErrorMessages WITH(nolock)   
WHERE ErrorNumber=105 AND LanguageID=@LangID    
RETURN  1    
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

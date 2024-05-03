USE PACT2C222
GO
SET ANSI_NULLS, QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spADM_DeletingSelectedData]
	@CostCenterID [bigint] = 0,
	@NodeID [nvarchar](max) = null,
	@Type [bigint] = 0,
	@UserName [nvarchar](max) = null,
	@UserID [bigint] = 1,
	@LangID [int] = 1,
	@RoleID [int] = 1
WITH ENCRYPTION, EXECUTE AS CALLER
AS
BEGIN TRANSACTION
BEGIN TRY  
SET NOCOUNT ON;  

	declare @IsInventory bit,@IsDocument Bit,@Schedule bigint,@return_value int,@sql nvarchar(max)
	declare @i bigint,@cnt bigint,@value bigint
	create TABLE #TblCC (ID INT IDENTITY(1,1) PRIMARY KEY,CC nvarchar(100))  
	select @IsInventory=IsInventory from ADM_DocumentTypes with(nolock) where CostCenterID=@CostCenterID

	set @IsDocument=(case when @CostCenterID between 40000 and 50000 then 1 else 0 end)
	
	IF(@Type=1)
	BEGIN
		if(@CostCenterID=95)	
		begin
			insert into #TblCC(CC) 
			exec [SPSplitString] @NodeID,','
			
			set @sql='insert into #TblCC(CC) 
			select T.CC from #TblCC T with(nolock)
			JOIN REN_Contract RC WITH(NOLOCK) ON RC.ContractID=CONVERT(BIGINT,T.CC)
			WHERE RC.ParentContractID>0'
			
			exec (@sql)
			
			insert into #TblCC(CC) 
			SELECT CC FROM #TblCC with(nolock)
			GROUP BY CC
			HAVING COUNT(*)=1
			
			select @i=(count(*)/2)+1,@cnt=count(*) from #TblCC with(nolock)
			
			while(@i<=@cnt)
			BEGIN	
				select @value=cc from #TblCC with(nolock) where id=@i
				
				EXEC @return_value = [dbo].spREN_DeleteContract 
					 @CostCenterID = @CostCenterID,  
					 @ContractID=@value,
					 @UserID = @UserID,  
					 @RoleID=@RoleID,
					 @LangID = @LangID
				set @i=@i+1
			END
		end
		else 
		begin
			insert into #TblCC(CC) 
			exec [SPSplitString] @NodeID,','

			select @i=1,@cnt=count(*) from #TblCC with(nolock)
			
			while(@i<=@cnt)
			BEGIN	
				select @value=cc from #TblCC with(nolock) where id=@i
				if(@IsInventory=1)
				BEGIN		
					EXEC @return_value = [dbo].spDOC_DeleteInvDocument  
						 @CostCenterID = @CostCenterID,  
						 @DocPrefix = '',  
						 @DocNumber = '',  
						 @DOCID=@value,
						 @UserID = @UserID,  
						 @UserName = @UserName,  
						 @LangID = @LangID,
						 @RoleID=@RoleID
				END
				ELSE
				BEGIN
					EXEC @return_value = [dbo].spDOC_DeleteAccDocument  
						 @CostCenterID = @CostCenterID,  
						 @DocPrefix = '',  
						 @DocNumber = '',  
						 @DOCID=@value,
						 @UserID = @UserID,  
						 @UserName = @UserName,  
						 @LangID = @LangID,
						 @RoleID=@RoleID
				END
				set @i=@i+1
			END
		end
	END
	ELSE IF(@Type=2)
	BEGIN
		insert into #TblCC(CC) 
		exec [SPSplitString] @NodeID,','

		select @i=1,@cnt=count(*) from #TblCC with(nolock)
		
		while(@i<=@cnt)
		BEGIN
			select @value=cc from #TblCC with(nolock) where id=@i
			
			DELETE FROM COM_Schedules 
			where @Schedule=@value
			set @i=@i+1
		END
		
		DELETE FROM COM_CCSCHEDULES 
		where CostCenterID=@CostCenterID AND convert(nvarchar,NodeID) in (@NodeID)
		
		DELETE FROM  CRM_Activities 
		WHERE CostCenterID=@CostCenterID AND convert(nvarchar,NodeID) in (@NodeID)
	END
	ELSE IF(@Type=3)
	BEGIN
		if(@IsDocument=1)
		BEGIN
			if(@IsInventory=1)
			BEGIN
				DELETE FROM COM_Files 
				WHERE FeatureID=@CostCenterID AND FeaturePK IN (SELECT DocID FROM  [INV_DocDetails] with(nolock)
				WHERE CostCenterID=@CostCenterID AND convert(nvarchar,DocID) in (@NodeID))
			END
			BEGIN
				DELETE FROM COM_Files 
				WHERE FeatureID=@CostCenterID AND FeaturePK IN (SELECT DocID FROM  [ACC_DocDetails] with(nolock)
				WHERE CostCenterID=@CostCenterID AND convert(nvarchar,DocID) in (@NodeID))
			END
		END
	END
	ELSE IF(@Type=4)
	BEGIN
		if(@IsDocument=1)
		BEGIN
			if(@IsInventory=1)
			BEGIN
				DELETE FROM COM_Notes 
				WHERE FeatureID=@CostCenterID AND FeaturePK IN (SELECT DocID FROM  [INV_DocDetails] with(nolock)
				WHERE CostCenterID=@CostCenterID AND convert(nvarchar,DocID) in (@NodeID))
			END
			BEGIN
				DELETE FROM COM_Notes 
				WHERE FeatureID=@CostCenterID AND FeaturePK IN (SELECT DocID FROM  [ACC_DocDetails] with(nolock)
				WHERE CostCenterID=@CostCenterID AND convert(nvarchar,DocID) in (@NodeID))
			END
		END
	END
	
	drop TABLE #TblCC
		
COMMIT TRANSACTION
SET NOCOUNT OFF;  
SELECT ErrorMessage,ErrorNumber FROM COM_ErrorMessages WITH(nolock) 
WHERE ErrorNumber=102 AND LanguageID=@LangID

RETURN 1
END TRY
BEGIN CATCH  
	--Return exception info [Message,Number,ProcedureName,LineNumber]  
	IF ERROR_NUMBER()=50000
	BEGIN
		SELECT ErrorMessage,ErrorNumber FROM COM_ErrorMessages WITH(nolock) WHERE ErrorNumber=ERROR_MESSAGE() AND LanguageID=@LangID
	END
	ELSE IF ERROR_NUMBER()=547
	BEGIN
		SELECT ErrorMessage, ERROR_MESSAGE() AS ServerMessage,ERROR_NUMBER() as ErrorNumber, ERROR_PROCEDURE()as ProcedureName, ERROR_LINE() AS ErrorLine FROM COM_ErrorMessages WITH(nolock)
		WHERE ErrorNumber=-110 AND LanguageID=@LangID
	END
	ELSE IF ERROR_NUMBER()<>266
	BEGIN
		SELECT ErrorMessage, ERROR_MESSAGE() AS ServerMessage,ERROR_NUMBER() as ErrorNumber, ERROR_PROCEDURE()as ProcedureName, ERROR_LINE() AS ErrorLine
		FROM COM_ErrorMessages WITH(nolock) WHERE ErrorNumber=-999 AND LanguageID=@LangID
	END
	BEGIN TRY
		ROLLBACK TRANSACTION
	END TRY
	BEGIN CATCH  
	END CATCH
SET NOCOUNT OFF  
RETURN -999   
END CATCH
GO

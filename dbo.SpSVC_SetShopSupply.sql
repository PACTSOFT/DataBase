USE PACT2C222
GO
SET ANSI_NULLS, QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[SpSVC_SetShopSupply]
	@NodeID [bigint] = 0,
	@Category [bigint],
	@Location [bigint],
	@WEF [datetime],
	@Type [bigint],
	@Value [float],
	@LabType [bigint],
	@LValue [float],
	@CompanyGUID [nvarchar](50),
	@UserName [nvarchar](50),
	@LangID [int] = 1
WITH ENCRYPTION, EXECUTE AS CALLER
AS
BEGIN TRANSACTION  
BEGIN TRY  
SET NOCOUNT ON;
		--Declaration Section  	
		DECLARE @CreatedDate FLOAT,@TempGuid varchar(50),@wefc float
	--	DECLARE @lft bigint,@rgt bigint,@Depth bigint,@ParentID bigint,@IsGroup bigint
		declare @Per FLOAT,@Amt FLOAT, @LPer float, @LAmt float
		SET @CreatedDate=CONVERT(FLOAT,getdate())
		set @wefc=convert(float,@WEF)

        
        --set @NodeID=(select NodeID from SVC_ShopSupplies where category=@Category and WEF=@WEF)
		
		IF(@Type=0)
		BEGIN
			IF(@Value>0) 
			BEGIN
			SET @Value =ROUND(@Value,2)
			END
			if(@Value >100 AND LEN(@Value)<=5)
			begin
				raiserror('-344',16,1)
			end
			SET @Per=@Value
			SET @Amt=0
		END
		ELSE
		BEGIN
			SET @Per=0
			SET @Amt=@Value
		END
		IF(@LabType=0)
		BEGIN
			IF(@LValue>0) 
			BEGIN
			SET @LValue =ROUND(@LValue,2)
			END
			if(@LValue >100 AND LEN(@LValue)<=5)
			begin
				raiserror('-344',16,1)
			end
			SET @LPer=@LValue
			SET @LAmt=0
		END
		ELSE
		BEGIN
			SET @LPer=0
			SET @LAmt=@LValue
		END
	   
		IF @NodeID=0
		BEGIN
			if ((select count(*) from SVC_ShopSupplies where category=@Category and Location=@Location and WEF=@wefc)>0)
			BEGIN
				RAISERROR('-343',16,1)
			END
			insert into SVC_ShopSupplies(category,Location,WEF,Type,ProductPercentage,ProductAmount,
				CompanyGUID,GUID,CreatedBy,CreatedDate,LabType,LabPercentage, LabAmt)
			values(@Category,@Location,@wefc,@Type,@Per,@Amt,
				@CompanyGUID,newid(),@UserName,@CreatedDate, @LabType, @LPer, @LAmt)

			set @NodeID=Scope_identity()
		END
		ELSE
		BEGIN
			UPDATE SVC_ShopSupplies
			SET Category=@Category,Location=@Location,WEF=@wefc,Type=@Type,
			ProductPercentage=@Per,ProductAmount=@Amt,
			LabType=@LabType, LabPercentage= @LPer, LabAmt=@LAmt,
				GUID=NEWID(),ModifiedBy=@UserName,ModifiedDate=@CreatedDate
			WHERE NodeID=@NodeID
		END

COMMIT TRANSACTION    
SET NOCOUNT OFF; 
SELECT ErrorMessage,ErrorNumber FROM COM_ErrorMessages WITH(nolock) 
WHERE ErrorNumber=100 AND LanguageID=@LangID  
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
		SELECT ErrorMessage, ERROR_MESSAGE() AS ServerMessage,ERROR_NUMBER() AS ErrorNumber, ERROR_PROCEDURE()AS ProcedureName, ERROR_LINE() AS ErrorLine
		FROM COM_ErrorMessages WITH(NOLOCK) WHERE ErrorNumber=-999 AND LanguageID=@LangID
	END
	ROLLBACK TRANSACTION
	SET NOCOUNT OFF  
	RETURN -999   
END CATCH 



GO

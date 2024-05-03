USE PACT2C222
GO
SET ANSI_NULLS, QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spADM_SetPriceTaxUsedCC]
	@Type [int],
	@ProfileID [int],
	@LangID [int] = 1
WITH ENCRYPTION, EXECUTE AS CALLER
AS
BEGIN TRANSACTION  
BEGIN TRY  
SET NOCOUNT ON;
	
	--To Set Used CostCenters with Group Check
	declare @Cnt int,@i int,@IsGroupExists int,@DefnTbl nvarchar(50),@TblName nvarchar(50),@SQL nvarchar(max),@strType nvarchar(10),@ProfileWhere nvarchar(50)
	
	if(@Type=1)
		set @DefnTbl='COM_CCPrices'	
	ELSE if(@Type=3)
		set @DefnTbl='ADM_DimensionWiseLockData'
	else
	BEGIN
		set @DefnTbl='COM_CCTaxes'	
			
		update adm_costcenterdef
		set IsReEvaluate=1
		from adm_costcenterdef a
		join COM_CCTaxes b on a.CostCenterColID=b.[ColID]


		update adm_costcenterdef
		set IsReEvaluate=0 
		from adm_costcenterdef a
		left join COM_CCTaxes b on a.CostCenterColID=b.[ColID]
		where a.IsReEvaluate=1 and a.costcenterid between 40000 and 50000 and  b.[ColID] is null
		
	END
	
	if @ProfileID>0
		set @ProfileWhere=' AND ProfileID='+convert(nvarchar,@ProfileID)
	ELSE
		set @ProfileWhere=''
		
	set @strType=convert(nvarchar,@Type)
	
	delete from COM_CCPriceTaxCCDefn where DefType=@Type and ProfileID=@ProfileID
	
	set @SQL='if(select count(*) from '+@DefnTbl+' with(nolock) where AccountID>0'+@ProfileWhere+')>0
		begin
			declare @IsGroupExists int
			select @IsGroupExists=count(*) 
			from '+@DefnTbl+' P with(nolock) inner join ACC_Accounts D with(nolock) ON P.AccountID=D.AccountID
			where P.AccountID>0'+@ProfileWhere+' AND D.IsGroup=1
			
			insert into COM_CCPriceTaxCCDefn
			values('+@strType+','+convert(nvarchar,@ProfileID)+',2,@IsGroupExists)
		end'
	EXEC(@SQL)
		
	set @SQL='if(select count(*) from '+@DefnTbl+' with(nolock) where ProductID>0'+@ProfileWhere+')>0
		begin
			declare @IsGroupExists int
			select @IsGroupExists=count(*) 
			from '+@DefnTbl+' P with(nolock) inner join INV_Product D with(nolock) ON P.ProductID=D.ProductID
			where P.ProductID>0'+@ProfileWhere+' AND D.IsGroup=1
			
			insert into COM_CCPriceTaxCCDefn
			values('+@strType+','+convert(nvarchar,@ProfileID)+',3,@IsGroupExists)
		end'
		print(@SQL)
	EXEC(@SQL)
		
	if(@Type=1)
	begin
		if (select count(*) from COM_CCPrices with(nolock) where UOMID>0 and ProfileID=@ProfileID)>0
		begin
			insert into COM_CCPriceTaxCCDefn
			values(@Type,@ProfileID,11,0)
		end
		if (select count(*) from COM_CCPrices with(nolock) where CurrencyID>0 and ProfileID=@ProfileID)>0
		begin
			insert into COM_CCPriceTaxCCDefn
			values(@Type,@ProfileID,12,0)
		end
	end
	
	set @i=50001
	while(@i<=50100)
	begin
		set @TblName=''
		select @TblName=TableName from ADM_Features with(nolock) where FeatureID=@i
		if @TblName is not null and @TblName<>'' and @i not in (50051,50052,50053,50054) and not (@i>50050 and @Type=3)
			and exists (select name from sys.columns with(nolock) where object_id=object_id(@DefnTbl) and Name='CCNID'+convert(nvarchar,@i-50000))
		begin
			set @SQL='if(select count(*) from '+@DefnTbl+' with(nolock) where CCNID'+convert(nvarchar,(@i-50000))+'>0 '+@ProfileWhere+')>0
		begin
			declare @IsGroupExists int
			select @IsGroupExists=count(*) 
			from '+@DefnTbl+' P with(nolock) inner join '+@TblName+' D with(nolock) ON P.CCNID'+convert(nvarchar,(@i-50000))+'=D.NodeID
			where P.CCNID'+convert(nvarchar,(@i-50000))+' is not null and P.CCNID'+convert(nvarchar,(@i-50000))+'>0 '+@ProfileWhere+' AND D.IsGroup=1
			
			insert into COM_CCPriceTaxCCDefn
			values('+@strType+','+convert(nvarchar,@ProfileID)+','+convert(nvarchar,@i)+',@IsGroupExists)
		end'
			print(@SQL)
			exec(@SQL)
		end
		set @i=@i+1
	end
	
	if(@Type<>3)
	BEGIN
		set @SQL='if(select count(*) from '+@DefnTbl+' with(nolock) where VehicleID>0'+@ProfileWhere+')>0
			begin
				insert into COM_CCPriceTaxCCDefn
				values('+@strType+','+convert(nvarchar,@ProfileID)+',61,0)
			end'
		EXEC(@SQL)
	
		--All Used Dimensions in all profiles
		delete from COM_CCPriceTaxCCDefn where DefType=@Type and ProfileID=0
		
		insert into COM_CCPriceTaxCCDefn
		select @Type,0,CostCenterID,max(convert(int,IsGroupExists))
		from COM_CCPriceTaxCCDefn with(nolock)
		where DefType=@Type
		group by CostCenterID
	
	END
	
--	select * from COM_CCPriceTaxCCDefn with(nolock) where DefType=@Type and ProfileID=@ProfileID

COMMIT TRANSACTION 
SET NOCOUNT OFF;   
RETURN 1
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

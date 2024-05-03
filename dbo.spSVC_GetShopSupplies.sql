USE PACT2C222
GO
SET ANSI_NULLS, QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spSVC_GetShopSupplies]
	@NodeID [int] = 0
WITH ENCRYPTION, EXECUTE AS CALLER
AS
BEGIN TRANSACTION  
BEGIN TRY  
SET NOCOUNT ON;
  

if(@NodeID=0)
	begin
		Select ca.NODEID,c.Name as Category,l.Name as Location,convert(varchar(50),WEF,106) as WEF,
		ProductPercentage,ProductAmount, LabPercentage, LabAmt
--		case when ProductPercentage is null or ProductPercentage='' then 0 else ProductPercentage end as ProductPercentage,
--		case when ProductAmount is null or ProductAmount='' then 0 else ProductAmount end as ProductAmount 
		from SVC_ShopSupplies ca with(nolock)
		join COM_Category c on ca.Category=c.NodeID
		join COM_Location l on ca.Location=l.NodeID
	end		 
else
	begin
		declare @node bigint, @LabType bigint
		set @node=(select Type from SVC_ShopSupplies where NodeID=@NodeID)
        if(@node=0)
			begin
				select Category,Location,convert(datetime,WEF) as WEF,Type,ProductPercentage from SVC_ShopSupplies with(nolock) where  NodeID=@NodeID
			end
		else
			begin
				select Category,Location,convert(datetime,WEF) as WEF,Type,ProductAmount from SVC_ShopSupplies with(nolock) where  NodeID=@NodeID
			End
			
		set @LabType=(select LabType from SVC_ShopSupplies where NodeID=@NodeID)
		if(@LabType=0)
			begin
				select Category,Location,convert(datetime,WEF) as WEF,LabType, LabPercentage from SVC_ShopSupplies with(nolock) where  NodeID=@NodeID
			end
		else
			begin
				select Category,Location,convert(datetime,WEF) as WEF,LabType, LabAmt from SVC_ShopSupplies with(nolock) where  NodeID=@NodeID
			End
	end


COMMIT TRANSACTION	
SET NOCOUNT OFF;
RETURN 1
END TRY
BEGIN CATCH  
		--Return exception info [Message,Number,ProcedureName,LineNumber]  
		IF ERROR_NUMBER()=50000
		BEGIN
			SELECT ErrorMessage,ErrorNumber FROM COM_ErrorMessages WITH(NOLOCK) WHERE ErrorNumber=ERROR_MESSAGE() AND LanguageID=1
		END
		ELSE
		BEGIN
			SELECT ErrorMessage, ERROR_MESSAGE() AS ServerMessage,ERROR_NUMBER() as ErrorNumber, ERROR_PROCEDURE()as ProcedureName, ERROR_LINE() AS ErrorLine
			FROM COM_ErrorMessages WITH(NOLOCK) WHERE ErrorNumber=-999 AND LanguageID=1
		END
ROLLBACK TRANSACTION
SET NOCOUNT OFF  
RETURN -999   
END CATCH  

GO

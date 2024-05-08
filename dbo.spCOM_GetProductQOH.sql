USE PACT2C222
GO
SET ANSI_NULLS, QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spCOM_GetProductQOH]
	@ProductIDs [nvarchar](max),
	@DocDate [datetime],
	@QtyWhere [nvarchar](max),
	@UserID [int],
	@LangID [int] = 1
WITH ENCRYPTION, EXECUTE AS CALLER
AS
BEGIN TRANSACTION        
BEGIN TRY        
SET NOCOUNT ON;      
	declare @sql nvarchar(max)
	  
	set @sql='SELECT isnull(sum(UOMConvertedQty*VoucherType),0) QOH,D.ProductID FROM INV_DocDetails D WITH(NOLOCK)      
	INNER JOIN COM_DocCCData DCC WITH(NOLOCK) ON DCC.InvDocDetailsID=D.InvDocDetailsID'+
	' WHERE D.ProductID in('+convert(nvarchar(max),@ProductIDs)+') '+isnull(@QtyWhere,'')+' and statusid=369 AND IsQtyIgnored=0 AND D.DocDate<='+convert(nvarchar,convert(float,@DocDate))+' and (VoucherType=-1 or VoucherType=1)
	 group by D.ProductID'
		
    exec sp_executesql @sql
    
    
    
 
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

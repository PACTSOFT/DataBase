USE PACT2C222
GO
SET ANSI_NULLS, QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spDOC_GetBOE]
	@ProductID [bigint] = 0,
	@date [datetime],
	@InvDocDetID [bigint],
	@UserID [int] = 0,
	@LangID [int] = 1
WITH ENCRYPTION, EXECUTE AS CALLER
AS
BEGIN TRY        
SET NOCOUNT ON        
          
    select a.InvDocDetailsID,a.Quantity+isnull(sum(b.Quantity*c.VoucherType),0) Qty 
    from INV_DocDetails a WITH(NOLOCK)
    left join INV_DocExtraDetails b  WITH(NOLOCK) on a.InvDocDetailsID=b.RefID and b.Type=1  and b.InvDocDetailsID<>@InvDocDetID
    left join INV_DocDetails c on c.InvDocDetailsID=b.InvDocDetailsID and c.IsQtyIgnored=0
    where a.IsQtyIgnored=0 and a.VoucherType=1 and a.ProductID=@ProductID and a.DocDate<=CONVERT(float,@date)
    group by a.InvDocDetailsID,a.Quantity,a.DocDate,a.VoucherNo
    having (a.Quantity+isnull(sum(b.Quantity*c.VoucherType),0))>0
    order by a.DocDate,a.VoucherNo
   
  
SET NOCOUNT OFF;        
RETURN 1        
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
 SET NOCOUNT OFF
RETURN -999
END CATCH
GO

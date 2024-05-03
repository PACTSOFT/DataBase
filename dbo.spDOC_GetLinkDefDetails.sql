USE PACT2C222
GO
SET ANSI_NULLS, QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spDOC_GetLinkDefDetails]
	@CostcenterID [bigint],
	@LinkCostCenterID [bigint],
	@Vouchers [nvarchar](max),
	@productids [nvarchar](max),
	@UserID [int] = 0,
	@RoleID [int] = 0,
	@LangID [int] = 1
WITH ENCRYPTION, EXECUTE AS CALLER
AS
BEGIN TRY     
SET NOCOUNT ON  
    
    if(@Vouchers='')
    BEGIN
	   --Getting Linking Fields    
	   SELECT B.SysColumnName BASECOL,L.SysColumnName LINKCOL ,A.[VIEW],A.CostCenterColIDLinked  
	   FROM COM_DocumentLinkDetails A WITH(NOLOCK) 
	   JOIN ADM_CostCenterDef B WITH(NOLOCK) ON B.CostCenterColID=A.CostCenterColIDBase    
	   left JOIN ADM_CostCenterDef L WITH(NOLOCK)  ON L.CostCenterColID=A.CostCenterColIDLinked    
	   WHERE b.CostCenterID=@LinkCostCenterID and L.CostCenterID=@CostcenterID  and A.CostCenterColIDLinked<>0  
	   
	   SELECT distinct [WorkFlowDefID],[CostCenterID],[Action],[Expression],a.WorkFlowID
	   FROM [COM_WorkFlowDef]  a   WITH(NOLOCK)
	   join COM_WorkFlow b WITH(NOLOCK) on a.WorkFlowID=b.WorkFlowID  and a.LevelID=b.LevelID
	   LEFT JOIN COM_Groups G with(nolock) on b.GroupID=G.GID
	   where [CostCenterID]=@LinkCostCenterID and IsEnabled=1  
	   and (b.UserID =@UserID or b.RoleID=@RoleID or G.UserID=@UserID or G.RoleID=@RoleID ) 
	   
	   
	    select a.CostCenterColID,a.SysColumnName from ADM_CostCenterDef a WITH(NOLOCK)  
		left join COM_DocumentLinkDetails b WITH(NOLOCK) on a.CostCenterColID=b.CostCenterColIDBase  
		where a.[CostCenterID]=@LinkCostCenterID and (SysColumnName='ProductID' or (  
		linkData is not null and (LinkData =26585 or LinkData =54306 or LinkData =54307 or LinkData =53529 or LinkData =53589 or LinkData =53530)  
		and (b.CostCenterColIDBase is null or b.CostCenterColIDlinked=0)))  
    
	  SELECT  C.CostCenterColID,C.ResourceID,C.SysColumnName,C.ColumnCostCenterID,C.LinkData,C.LocalReference
	  FROM ADM_CostCenterDef C WITH(NOLOCK)    WHERE C.CostCenterID = @LinkCostCenterID     
	  AND ((C.IsColumnUserDefined=1 AND C.IsColumnInUse=1) OR C.IsColumnUserDefined=0) 
	  AND   	  (C.SysColumnName NOT LIKE '%dcCalcNum%')  AND (C.SysColumnName NOT LIKE '%dcExchRT%') 
	  AND (C.SysColumnName NOT LIKE '%dcCurrID%') AND (C.SysColumnName NOT LIKE 'dcPOSRemarksNum%')  
	  AND (C.SysColumnName <> 'UOMConversion')   AND (C.SysColumnName <> 'UOMConvertedQty')  
    END
    ELSE
    BEGIN
		declare @sql nvarchar(max)
		set @sql='select InvDocDetailsID,ProductID,VoucherNo,CostCenterID 
		from INV_DocDetails where VoucherNo in('+@Vouchers+') and ProductID in('+@productids+')'
		
		exec(@sql)
		
		set @sql='select CostCenterIDLinked,b.SysColumnName from COM_DocumentLinkDef a
		join ADM_CostCenterDef b on a.CostCenterColIDBase=b.CostCenterColID
		where CostCenterIDBase='+CONVERT(nvarchar,@LinkCostCenterID)+' 
		and CostCenterIDLinked iN(select CostCenterID from INV_DocDetails where VoucherNo in('+@Vouchers+') and ProductID in('+@productids+'))'
		
		exec(@sql)
    END
         
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

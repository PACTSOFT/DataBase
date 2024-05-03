USE PACT2C222
GO
SET ANSI_NULLS, QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spDOC_GetPosPoints]
	@LoyaltyOn [int],
	@AccountId [bigint],
	@DOcID [bigint],
	@Dim [int],
	@docdate [datetime],
	@UserID [int] = 0,
	@LangID [int] = 1
WITH ENCRYPTION, EXECUTE AS CALLER
AS
BEGIN TRY      
SET NOCOUNT ON      
      
		DECLARE @SQL NVARCHAR(MAX),@nodeid BIGINT,@tablename nvarchar(200)
		
		 
		set @SQL='select @nodeid=CCNID'+convert(nvarchar,(@Dim-50000))+' from COM_CCCCData WITH(NOLOCK) where NodeID='+convert(nvarchar,@AccountId)+' and CostCenterID='+CONVERT(nvarchar,@LoyaltyOn)
		
		exec sp_executesql  @SQL,N'@nodeid BIGINT OUTPUT',@nodeid output
		
		if(@nodeid>0)
		BEGIN	
			select @tablename=TableName from ADM_Features where FeatureID=@Dim
			
			set @SQL='select ccAlpha49,ccAlpha50 from '+@tablename+' WITH(NOLOCK)
			where ISDATE(ccAlpha47)=1 and ISDATE(ccAlpha48)=1 
			and  convert(datetime,'''+convert(nvarchar(max),@docdate)+''') between convert(datetime,ccAlpha47) and convert(datetime,ccAlpha48)
			and NodeID='+convert(nvarchar,@nodeid)
			print @SQL
			 exec(@SQL)
		END
		ELSE	
			select 1 where 1<>1
		
		select isnull(SUM(Quantity),0) points from INV_DocExtraDetails WITH(NOLOCK)
		where Type=5 and fld1 is not null and isnumeric(Fld1)=1 and CONVERT(bigint,fld1)=@AccountId and RefID<>@DOcID
		

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

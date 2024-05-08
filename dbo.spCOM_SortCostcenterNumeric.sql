USE PACT2C222
GO
SET ANSI_NULLS, QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spCOM_SortCostcenterNumeric]
	@CCNodeID [int],
	@CostcenterID [int],
	@ColumnName [nvarchar](200),
	@sOrder [nvarchar](10) = 'ASC',
	@UserID [int],
	@LangID [int] = 1
WITH ENCRYPTION, EXECUTE AS CALLER
AS
BEGIN TRANSACTION    
BEGIN TRY    
SET NOCOUNT ON;  
	declare @i INT,@cnt INT,@nodeid INT,@val nvarchar(max)  
	declare @PrimKey nvarchar(200),@TableName nvarchar(200),@sql nvarchar(max),@ColumnText nvarchar(max)  
	declare @ii INT,@ccnt INT
	

	set @PrimKey='NodeID'  
	if(@CostcenterID=2)  
		set @PrimKey='AccountID'  
	else if(@CostcenterID=3)  
		set @PrimKey='ProductID'  
	else if(@CostcenterID=94)  
		set @PrimKey='TenantID' 
	else if(@CostcenterID=93)  
		set @PrimKey='UnitID' 
   else if(@CostcenterID=83)  
	   set @PrimKey='CustomerID' 
   else if(@CostcenterID=65)  
		set @PrimKey='ContactID' 
	   else if(@CostcenterID=86)  
   set @PrimKey='leadID'
  else if(@CostcenterID=89)  
   set @PrimKey='opportunityID' 
  else if(@CostcenterID=88)  
   set @PrimKey='CampaignID' 
  else if(@CostcenterID=73)  
   set @PrimKey='CaseID' 
  else if(@CostcenterID=76)  
   set @PrimKey='BOMID' 

	select @TableName=tablename from adm_features with(nolock) where featureid=@CostcenterID  
	
	set @sql='select @i=min('+@PrimKey+'),@cnt=max('+@PrimKey+') from '+@TableName +'  with(nolock)'

	exec sp_executesql @sql,N'@i INT output,@cnt INT output',@i output, @cnt output 

	set @sql='alter table '+@TableName+' add temp INT'
	exec(@sql)  

	while(@i<=@cnt)  
	begin  
		begin try
			set @ColumnText=''
			set @sql='select @ColumnText='+@ColumnName+' from '+@TableName+' with(nolock) 
			where '+@PrimKey+'='+convert(nvarchar,@i)
			
			exec sp_executesql @sql,N'@ColumnText nvarchar(max)   output',@ColumnText output  
			set @val=''
			if(@ColumnText is not null and @ColumnText<>'')
			begin
				set @ii=0
				set @ccnt=LEN(@ColumnText)
				while(@ii<@ccnt)  
				begin  
					set @ii=@ii+1 
					if(isnumeric(Substring(@ColumnText,@ii,1))=1 and Substring(@ColumnText,@ii,1)<>'-' and Substring(@ColumnText,@ii,1)<>'.')
						set @val=@val+Substring(@ColumnText,@ii,1)
				END 
			END
			
			if(@val='')
				set @val=0
				
			set @sql='update '+@TableName+'  
			set temp='+@val+'  
			where '+@PrimKey+'='+convert(nvarchar,@i)  
			exec(@sql)  
		END TRY
		begin catch
			select @sql
		End catch
		set @i=@i+1  
	END 
	
	exec [spCOM_SortCostcenter]  @CCNodeID,@CostcenterID,'temp',@sOrder,@UserID,@LangID 

	set @sql='alter table '+@TableName+' Drop column temp '
	exec(@sql)  

COMMIT TRANSACTION  
SELECT ErrorMessage,ErrorNumber FROM COM_ErrorMessages WITH(nolock) 
WHERE ErrorNumber=100 AND LanguageID=@LangID    
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

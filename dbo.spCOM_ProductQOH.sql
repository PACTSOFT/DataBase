USE PACT2C222
GO
SET ANSI_NULLS, QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spCOM_ProductQOH]
	@ProductID [bigint],
	@DocDate [datetime],
	@Products [nvarchar](max),
	@UserID [bigint],
	@LangID [int] = 1
WITH ENCRYPTION, EXECUTE AS CALLER
AS
BEGIN TRANSACTION        
BEGIN TRY        
SET NOCOUNT ON;      
	declare @sql nvarchar(max),@join nvarchar(max),@Columns  nvarchar(max),@isloc bit,@isdiv bit
	declare @PrefValue nvarchar(200),@table  nvarchar(200),@Group  nvarchar(max)
	  
	  set @Columns=''
	  set @join=''
	   set @Group=''
	   set @isloc=0
	   set @isdiv=0;
	   set @table=''
	select @PrefValue= Value from ADM_GlobalPreferences where Name='EnableLocationWise'      
          
    if(@PrefValue='True')      
    begin      
		set @PrefValue=''    
		select @PrefValue= Value from ADM_GlobalPreferences where Name='Location Stock'      
		if(@PrefValue='True')    
		begin    
			set @isloc=1
			select @table =Name from adm_features where featureid=50002
			
			set @Columns='l.name ['+@table+'],dcccnid2'
			set @Group='l.name,dcccnid2'
			set @join=@join+'	join Com_location l on DCC.dcccnid2=l.NOdeid '
		end  
    end 
    
    set @PrefValue=''
    select @PrefValue= Value from ADM_GlobalPreferences where Name='EnableDivisionWise'                
    if(@PrefValue='True')      
    begin      
		set @PrefValue=''    
		select @PrefValue= Value from ADM_GlobalPreferences where Name='Division Stock'      
		if(@PrefValue='True')    
		begin    
			if(@Columns<>'')
			begin
				set @Columns=@Columns+','
				set @Group=@Group+','
			end
			 select @table =Name from adm_features where featureid=50001
			set @isdiv=1
			set @Group=@Group+'dv.name,dcccnid1'
			set @Columns=@Columns+'dv.name ['+@table+'],dcccnid1'
			set @join=@join+'	join COM_Division dv on DCC.dcccnid1=dv.NOdeid '
		end  
    end
            
        
    set @PrefValue=''    
    select @PrefValue= isnull(Value,'') from ADM_GlobalPreferences where Name='Maintain Dimensionwise stock'      
        
    if(@PrefValue is not null and @PrefValue<>'' and convert(bigint,@PrefValue)>0)      
    begin      
			if(@Columns<>'')
			begin
				set @Columns=@Columns+','
				set @Group=@Group+','
			end
			
			select @table =Name from adm_features where featureid=convert(bigint,@PrefValue)

			set @Columns=@Columns+'c.name ['+@table+'],dcccnid'+convert(nvarchar,(convert(bigint,@PrefValue)-50000))			
			set @Group=@Group+'c.name,dcccnid'+convert(nvarchar,(convert(bigint,@PrefValue)-50000))			

			select @table =tablename from adm_features where featureid=convert(bigint,@PrefValue)
			set @join=@join+'	join '+@table+' c on DCC.dcccnid'+convert(nvarchar,(convert(bigint,@PrefValue)-50000))+'=c.NOdeid '

    end  
	if(@Columns<>'')
	begin	
		set @sql='SELECT '+@Columns+',isnull(sum(UOMConvertedQty*VoucherType),0) QOH,D.ProductID FROM INV_DocDetails D WITH(NOLOCK)      
		INNER JOIN COM_DocCCData DCC ON DCC.InvDocDetailsID=D.InvDocDetailsID'+@join+
		'WHERE '
		 if(@Products is not null and @Products<>'')
			set @sql=@sql+'D.ProductID in('+@Products+')'
		 else
			set @sql=@sql+'D.ProductID='+convert(nvarchar,@ProductID)
		
		 set @sql=@sql+' AND IsQtyIgnored=0 AND D.DocDate<='+convert(nvarchar,convert(float,@DocDate))+' and (VoucherType=-1 or VoucherType=1)
		group by D.ProductID,'+@Group
	end
	else
	begin
		set @sql='SELECT isnull(sum(UOMConvertedQty*VoucherType),0) QOH,D.ProductID FROM INV_DocDetails D WITH(NOLOCK)      
		INNER JOIN COM_DocCCData DCC ON DCC.InvDocDetailsID=D.InvDocDetailsID'+
		' WHERE D.ProductID='+convert(nvarchar,@ProductID)+' AND IsQtyIgnored=0 AND D.DocDate<='+convert(nvarchar,convert(float,@DocDate))+' and (VoucherType=-1 or VoucherType=1) 
		 group by D.ProductID' 
	end
	print @sql
    exec(@sql)
    
    if(@isloc=1)
		select nodeid,Name from COM_Location With(NOLOCK)
		where IsGroup=0 order by lft
	else if(@isdiv=1)	
		select nodeid,Name from COM_Division With(NOLOCK)
		where IsGroup=0 order by lft
	else if(@table<>'')
	BEGIN
		set @sql='select nodeid,Name from '+@table+' With(NOLOCK)
		where IsGroup=0 order by lft'
		exec(@sql)
	END		
	
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

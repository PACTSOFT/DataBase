USE PACT2C222
GO
SET ANSI_NULLS, QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spACC_PostDeprReverseJV]
	@PostCOSTCENTERID [bigint],
	@DeprVoucherNo [nvarchar](50),
	@DeptID [nvarchar](max),
	@CompanyGUID [nvarchar](50),
	@GUID [nvarchar](50),
	@UserName [nvarchar](50),
	@UserID [int] = 0,
	@LangID [int] = 1
WITH ENCRYPTION, EXECUTE AS CALLER
AS
BEGIN TRANSACTION      
DECLARE @QUERYTEST NVARCHAR(100)  , @IROWNO NVARCHAR(100) , @TYPE NVARCHAR(100)    
BEGIN TRY        
SET NOCOUNT ON;
DECLARE   @XML XML ,@DXML XML , @CNT INT , @ICNT INT , @DocXml nvarchar(max) , @return_value BIGINT ,@DT datetime,@DT_INT INT,@Vendor bigint,@PN nvarchar(50)
DECLARE @DEPID BIGINT ,@VOUCHERNO NVARCHAR(200) ,@DocDate float ,@STATUSID INT  , @AssetNetValue FLOAT,@AssetOldValue Float
DECLARE @AssetID bigint ,@Prefix nvarchar(200),@DeprPostDate nvarchar(50),@CCQUERY nvarchar(max)
declare @DepAmount float,@LocationDimID bigint,@AssDimNodeID bigint,@AssDimID bigint,@LocationID bigint
declare @TblDepr as table(ID int identity(1,1),DeprID bigint,AssetID bigint)
declare @dbl float,@dblCum float,@DeprStartDate int,@DeprEndDate int,@IsPartial bit,@DOCID bigint,@COSTCENTERID BIGINT,@Decimals int
declare @SqlCC nvarchar(max)    
select @Decimals=Value from ADM_GlobalPreferences with(nolock) where Name='DecimalsinAmount'

insert into @TblDepr(DeprID)
execute SPSplitString @DeptID,','

delete from @TblDepr
from ACC_AssetDepSchedule A
inner join @TblDepr T ON A.DPScheduleID=T.DeprID
where DocID is null and DocID=0

update @TblDepr
set AssetID=A.AssetID
from @TblDepr T
inner join ACC_AssetDepSchedule A with(nolock) on A.DPScheduleID=T.DeprID

--Check for next months depreciation exists
if exists (select P.DPScheduleID--,convert(datetime,P.DeprStartDate),P.DPScheduleID,P.DocID,A.* 
	from @TblDepr T
	inner join ACC_AssetDepSchedule A with(nolock) on A.DPScheduleID=T.DeprID
	inner join ACC_AssetDepSchedule P with(nolock) on P.AssetID=A.AssetID and P.DeprStartDate>A.DeprStartDate
	LEFT join @TblDepr TP on TP.DeprID=P.DPScheduleID 
where TP.DeprID is null and (P.DocID is not null and P.DocID!=''))
begin
	RAISERROR('-151',16,1)
end

--Check for partial depreciation exists
set @IsPartial=0
if exists (select A.DPScheduleID from ACC_AssetDepSchedule A with(nolock)
	left join @TblDepr T on A.DPScheduleID=T.DeprID
	where A.VoucherNo=@DeprVoucherNo and T.DeprID is null)
begin
	set @IsPartial=1
end

Set @DT=getdate()   
set @DT_INT=floor(convert(float,@DT))

select @COSTCENTERID=CostCenterID,@DOCID=DocID from ACC_DocDetails with(nolock) where VoucherNo=@DeprVoucherNo
select @DeprPostDate=Value from com_costcenterpreferences with(nolock) where costcenterid=72 and Name='AssetUnpostDepr'

if @IsPartial=1
begin
	CREATE TABLE #tblDocDetail(iLineNo int,Amount float)
	insert into #tblDocDetail
	select DocSeqNo,sum(Amount) Amount from @TblDepr T
	inner join ACC_AssetDeprDocDetails D with(nolock) on D.DPScheduleID=T.DeprID
	group by DocSeqNo
	
	insert into #tblDocDetail
	select iLineNo+1,Amount from #tblDocDetail
	
	if @DeprPostDate like 'ReverseDeprOn%'
	begin
		set @DocXml='<DocumentXML>'
		
		set @SqlCC=''
select @SqlCC=@SqlCC+'+'','+name+'=''+convert(nvarchar,'+name+')' from sys.columns where object_id=object_id('COM_DocCCDATA') and name like 'dcCCNID%'
set @SqlCC=substring(@SqlCC,4,len(@SqlCC))+'+''"/></Row>'''

set @SqlCC='
set @DocXml=''''
select @DT_INT=DocDate,@DocXml=@DocXml+''<Row> <Transactions DocSeqNo="''+convert(nvarchar,DocSeqNo)+''" DocDetailsID="0" DebitAccount="''+convert(nvarchar,D.CreditAccount)+''" CreditAccount="''+convert(nvarchar,D.DebitAccount)+''" 
 Amount="''+convert(nvarchar,T.Amount)+''" AmtFc="''+convert(nvarchar,T.AmountFC)+''" CurrencyID="1" ExchangeRate="1" LineNarration="Depreciation Un-Posting" CommonNarration=" Depreciation Un-Posting" RefNodeID="0">
</Transactions><Numeric /><Alpha/><EXTRAXML/>
<CostCenters Query="'+@SqlCC

set @SqlCC=@SqlCC+'
from ACC_DocDetails D with(nolock) inner join COM_DocCCDATA DCC with(nolock) on D.AccDocDetailsID=DCC.AccDocDetailsID
inner join #tblDocDetail T on T.iLineNo=D.DocSeqNo
where DocID='+convert(nvarchar,@DOCID)+'
order by DocSeqNo

print(@DocXml)
'

EXEC sp_executesql @SqlCC, N'@DT_INT INT OUTPUT, @DocXml nvarchar(max) OUTPUT',@DT_INT OUTPUT,@DocXml OUTPUT

		
		/***select @DT_INT=DocDate,@DocXml=@DocXml+'<Row> <Transactions DocSeqNo="'+convert(nvarchar,DocSeqNo)+'"  DocDetailsID="0" DebitAccount="'+convert(nvarchar,D.CreditAccount)+'" CreditAccount="'+convert(nvarchar,D.DebitAccount)+'" 
Amount="'+convert(nvarchar,T.Amount)+'" AmtFc="'+convert(nvarchar,T.Amount)+'" CurrencyID="1" ExchangeRate="1" LineNarration="Depreciation Un-Posting" CommonNarration=" Depreciation Un-Posting" RefNodeID="0">
</Transactions><Numeric /><Alpha/><EXTRAXML/>
<CostCenters Query="dcccnid1='+convert(nvarchar,dcccnid1)+',dcccnid2='+convert(nvarchar,dcccnid2)+',dcccnid3='+convert(nvarchar,dcccnid3)+',dcccnid4='+convert(nvarchar,dcccnid4)+',dcccnid5='+convert(nvarchar,dcccnid5)
+',dcccnid6='+convert(nvarchar,dcccnid6)+',dcccnid7='+convert(nvarchar,dcccnid7)+',dcccnid8='+convert(nvarchar,dcccnid8)+',dcccnid9='+convert(nvarchar,dcccnid9)+',dcccnid10='+convert(nvarchar,dcccnid10)
+case when dcccnid11>1 then ',dcccnid11='+convert(nvarchar,dcccnid11) else '' end
+case when dcccnid12>1 then ',dcccnid12='+convert(nvarchar,dcccnid12) else '' end
+case when dcccnid13>1 then ',dcccnid13='+convert(nvarchar,dcccnid13) else '' end
+case when dcccnid14>1 then ',dcccnid14='+convert(nvarchar,dcccnid14) else '' end
+case when dcccnid15>1 then ',dcccnid15='+convert(nvarchar,dcccnid15) else '' end
+case when dcccnid16>1 then ',dcccnid16='+convert(nvarchar,dcccnid16) else '' end
+case when dcccnid17>1 then ',dcccnid17='+convert(nvarchar,dcccnid17) else '' end
+case when dcccnid18>1 then ',dcccnid18='+convert(nvarchar,dcccnid18) else '' end
+case when dcccnid19>1 then ',dcccnid19='+convert(nvarchar,dcccnid19) else '' end
+case when dcccnid20>1 then ',dcccnid20='+convert(nvarchar,dcccnid20) else '' end
+case when dcccnid21>1 then ',dcccnid21='+convert(nvarchar,dcccnid21) else '' end
+case when dcccnid22>1 then ',dcccnid22='+convert(nvarchar,dcccnid22) else '' end
+case when dcccnid23>1 then ',dcccnid23='+convert(nvarchar,dcccnid23) else '' end
+case when dcccnid24>1 then ',dcccnid24='+convert(nvarchar,dcccnid24) else '' end
+case when dcccnid25>1 then ',dcccnid25='+convert(nvarchar,dcccnid25) else '' end
+case when dcccnid26>1 then ',dcccnid26='+convert(nvarchar,dcccnid26) else '' end
+case when dcccnid27>1 then ',dcccnid27='+convert(nvarchar,dcccnid27) else '' end
+case when dcccnid28>1 then ',dcccnid28='+convert(nvarchar,dcccnid28) else '' end
+case when dcccnid29>1 then ',dcccnid29='+convert(nvarchar,dcccnid29) else '' end
+case when dcccnid30>1 then ',dcccnid30='+convert(nvarchar,dcccnid30) else '' end
+case when dcccnid31>1 then ',dcccnid31='+convert(nvarchar,dcccnid31) else '' end
+case when dcccnid32>1 then ',dcccnid32='+convert(nvarchar,dcccnid32) else '' end
+case when dcccnid33>1 then ',dcccnid33='+convert(nvarchar,dcccnid33) else '' end
+case when dcccnid34>1 then ',dcccnid34='+convert(nvarchar,dcccnid34) else '' end
+case when dcccnid35>1 then ',dcccnid35='+convert(nvarchar,dcccnid35) else '' end
+case when dcccnid36>1 then ',dcccnid36='+convert(nvarchar,dcccnid36) else '' end
+case when dcccnid37>1 then ',dcccnid37='+convert(nvarchar,dcccnid37) else '' end
+case when dcccnid38>1 then ',dcccnid38='+convert(nvarchar,dcccnid38) else '' end
+case when dcccnid39>1 then ',dcccnid39='+convert(nvarchar,dcccnid39) else '' end
+case when dcccnid40>1 then ',dcccnid40='+convert(nvarchar,dcccnid40) else '' end
+case when dcccnid41>1 then ',dcccnid41='+convert(nvarchar,dcccnid41) else '' end
+case when dcccnid42>1 then ',dcccnid42='+convert(nvarchar,dcccnid42) else '' end
+case when dcccnid43>1 then ',dcccnid43='+convert(nvarchar,dcccnid43) else '' end
+case when dcccnid44>1 then ',dcccnid44='+convert(nvarchar,dcccnid44) else '' end
+case when dcccnid45>1 then ',dcccnid45='+convert(nvarchar,dcccnid45) else '' end
+case when dcccnid46>1 then ',dcccnid46='+convert(nvarchar,dcccnid46) else '' end
+case when dcccnid47>1 then ',dcccnid47='+convert(nvarchar,dcccnid47) else '' end
+case when dcccnid48>1 then ',dcccnid48='+convert(nvarchar,dcccnid48) else '' end
+case when dcccnid49>1 then ',dcccnid49='+convert(nvarchar,dcccnid49) else '' end
+case when dcccnid50>1 then ',dcccnid50='+convert(nvarchar,dcccnid50) else '' end
+',"/></Row>'
		from ACC_DocDetails D with(nolock) inner join COM_DocCCDATA DCC with(nolock) on D.AccDocDetailsID=DCC.AccDocDetailsID
		inner join #tblDocDetail T on T.iLineNo=D.DocSeqNo
		where DocID=@DOCID
		order by DocSeqNo***/

		set @DocXml=@DocXml+'</DocumentXML>'
		--select convert(xml,@DocXml)
		
		if @DeprPostDate='ReverseDeprOnCurrDt'
			set @DT_INT=floor(convert(float,@DT))

		set @Prefix=''
		EXEC [sp_GetDocPrefix] @DocXml,@DT_INT,@COSTCENTERID,@Prefix output 

		EXEC @return_value = [dbo].[spDOC_SetTempAccDocument]
			@CostCenterID = @COSTCENTERID,
			@DocID = 0,
			@DocPrefix = @Prefix,
			@DocNumber = N'',
			@DocDate = @DT_INT,
			@DueDate =NULL,
			@BillNo = NULL,
			@InvDocXML = @DocXml,
			@NotesXML =  N'',
			@AttachmentsXML =  N'',
			@ActivityXML = N'',
			@IsImport = 0,
			@LocationID = 1,
			@DivisionID = 1,
			@WID = 0,
			@RoleID = 1,
			@RefCCID = 72,
			@RefNodeid =1 ,
			@CompanyGUID = @CompanyGUID,
			@UserName = @UserName,
			@UserID = @UserID,
			@LangID = @LangID
				
	--	SELECT * FROM ACC_DOCDETAILS with(nolock) WHERE DOCID=@return_value
		     
		--IF(@return_value < 0 )
		--	continue;
	end
	else
	begin
		RAISERROR('-141',16,1)
	end
end
else
begin
	if @DeprPostDate like 'ReverseDeprOn%'
	begin
		set @DocXml='<DocumentXML>'

		set @SqlCC=''
		select @SqlCC=@SqlCC+'+'','+name+'=''+convert(nvarchar,'+name+')' from sys.columns where object_id=object_id('COM_DocCCDATA') and name like 'dcCCNID%'
		set @SqlCC=substring(@SqlCC,4,len(@SqlCC))+'+''"/></Row>'''

		set @SqlCC='
		set @DocXml=''''
		select @DT_INT=DocDate,@DocXml=@DocXml+''<Row> <Transactions DocSeqNo="''+convert(nvarchar,DocSeqNo)+''" DocDetailsID="0" DebitAccount="''+convert(nvarchar,D.CreditAccount)+''" CreditAccount="''+convert(nvarchar,D.DebitAccount)+''" 
		 Amount="''+convert(nvarchar,D.Amount)+''" AmtFc="''+convert(nvarchar,D.AmountFC)+''" CurrencyID="1" ExchangeRate="1" LineNarration="Depreciation Un-Posting" CommonNarration=" Depreciation Un-Posting" RefNodeID="0">
		</Transactions><Numeric /><Alpha/><EXTRAXML/>
		<CostCenters Query="'+@SqlCC

		set @SqlCC=@SqlCC+'
		from ACC_DocDetails D with(nolock) inner join COM_DocCCDATA DCC with(nolock) on D.AccDocDetailsID=DCC.AccDocDetailsID
		where DocID='+convert(nvarchar,@DOCID)+'
		order by DocSeqNo

		print(@DocXml)
		'

		EXEC sp_executesql @SqlCC, N'@DT_INT INT OUTPUT, @DocXml nvarchar(max) OUTPUT',@DT_INT OUTPUT,@DocXml OUTPUT
		/***
		select @DT_INT=DocDate,@DocXml=@DocXml+'<Row> <Transactions DocSeqNo="'+convert(nvarchar,DocSeqNo)+'"  DocDetailsID="0" DebitAccount="'+convert(nvarchar,D.CreditAccount)+'" CreditAccount="'+convert(nvarchar,D.DebitAccount)+'" 
Amount="'+convert(nvarchar,D.Amount)+'" AmtFc="'+convert(nvarchar,D.AmountFC)+'" CurrencyID="1" ExchangeRate="1" LineNarration="Depreciation Un-Posting" CommonNarration=" Depreciation Un-Posting" RefNodeID="0">
</Transactions><Numeric /><Alpha/><EXTRAXML/>
<CostCenters Query="dcccnid1='+convert(nvarchar,dcccnid1)+',dcccnid2='+convert(nvarchar,dcccnid2)+',dcccnid3='+convert(nvarchar,dcccnid3)+',dcccnid4='+convert(nvarchar,dcccnid4)+',dcccnid5='+convert(nvarchar,dcccnid5)
+',dcccnid6='+convert(nvarchar,dcccnid6)+',dcccnid7='+convert(nvarchar,dcccnid7)+',dcccnid8='+convert(nvarchar,dcccnid8)+',dcccnid9='+convert(nvarchar,dcccnid9)+',dcccnid10='+convert(nvarchar,dcccnid10)
+case when dcccnid11>1 then ',dcccnid11='+convert(nvarchar,dcccnid11) else '' end
+case when dcccnid12>1 then ',dcccnid12='+convert(nvarchar,dcccnid12) else '' end
+case when dcccnid13>1 then ',dcccnid13='+convert(nvarchar,dcccnid13) else '' end
+case when dcccnid14>1 then ',dcccnid14='+convert(nvarchar,dcccnid14) else '' end
+case when dcccnid15>1 then ',dcccnid15='+convert(nvarchar,dcccnid15) else '' end
+case when dcccnid16>1 then ',dcccnid16='+convert(nvarchar,dcccnid16) else '' end
+case when dcccnid17>1 then ',dcccnid17='+convert(nvarchar,dcccnid17) else '' end
+case when dcccnid18>1 then ',dcccnid18='+convert(nvarchar,dcccnid18) else '' end
+case when dcccnid19>1 then ',dcccnid19='+convert(nvarchar,dcccnid19) else '' end
+case when dcccnid20>1 then ',dcccnid20='+convert(nvarchar,dcccnid20) else '' end
+case when dcccnid21>1 then ',dcccnid21='+convert(nvarchar,dcccnid21) else '' end
+case when dcccnid22>1 then ',dcccnid22='+convert(nvarchar,dcccnid22) else '' end
+case when dcccnid23>1 then ',dcccnid23='+convert(nvarchar,dcccnid23) else '' end
+case when dcccnid24>1 then ',dcccnid24='+convert(nvarchar,dcccnid24) else '' end
+case when dcccnid25>1 then ',dcccnid25='+convert(nvarchar,dcccnid25) else '' end
+case when dcccnid26>1 then ',dcccnid26='+convert(nvarchar,dcccnid26) else '' end
+case when dcccnid27>1 then ',dcccnid27='+convert(nvarchar,dcccnid27) else '' end
+case when dcccnid28>1 then ',dcccnid28='+convert(nvarchar,dcccnid28) else '' end
+case when dcccnid29>1 then ',dcccnid29='+convert(nvarchar,dcccnid29) else '' end
+case when dcccnid30>1 then ',dcccnid30='+convert(nvarchar,dcccnid30) else '' end
+case when dcccnid31>1 then ',dcccnid31='+convert(nvarchar,dcccnid31) else '' end
+case when dcccnid32>1 then ',dcccnid32='+convert(nvarchar,dcccnid32) else '' end
+case when dcccnid33>1 then ',dcccnid33='+convert(nvarchar,dcccnid33) else '' end
+case when dcccnid34>1 then ',dcccnid34='+convert(nvarchar,dcccnid34) else '' end
+case when dcccnid35>1 then ',dcccnid35='+convert(nvarchar,dcccnid35) else '' end
+case when dcccnid36>1 then ',dcccnid36='+convert(nvarchar,dcccnid36) else '' end
+case when dcccnid37>1 then ',dcccnid37='+convert(nvarchar,dcccnid37) else '' end
+case when dcccnid38>1 then ',dcccnid38='+convert(nvarchar,dcccnid38) else '' end
+case when dcccnid39>1 then ',dcccnid39='+convert(nvarchar,dcccnid39) else '' end
+case when dcccnid40>1 then ',dcccnid40='+convert(nvarchar,dcccnid40) else '' end
+case when dcccnid41>1 then ',dcccnid41='+convert(nvarchar,dcccnid41) else '' end
+case when dcccnid42>1 then ',dcccnid42='+convert(nvarchar,dcccnid42) else '' end
+case when dcccnid43>1 then ',dcccnid43='+convert(nvarchar,dcccnid43) else '' end
+case when dcccnid44>1 then ',dcccnid44='+convert(nvarchar,dcccnid44) else '' end
+case when dcccnid45>1 then ',dcccnid45='+convert(nvarchar,dcccnid45) else '' end
+case when dcccnid46>1 then ',dcccnid46='+convert(nvarchar,dcccnid46) else '' end
+case when dcccnid47>1 then ',dcccnid47='+convert(nvarchar,dcccnid47) else '' end
+case when dcccnid48>1 then ',dcccnid48='+convert(nvarchar,dcccnid48) else '' end
+case when dcccnid49>1 then ',dcccnid49='+convert(nvarchar,dcccnid49) else '' end
+case when dcccnid50>1 then ',dcccnid50='+convert(nvarchar,dcccnid50) else '' end
+',"/></Row>'
		from ACC_DocDetails D with(nolock) inner join COM_DocCCDATA DCC with(nolock) on D.AccDocDetailsID=DCC.AccDocDetailsID
		where DocID=@DOCID
		order by DocSeqNo***/

		set @DocXml=@DocXml+'</DocumentXML>'
		
	--	select convert(xml,@DocXml)
		
		if @DeprPostDate='ReverseDeprOnCurrDt'
			set @DT_INT=floor(convert(float,@DT))

		set @Prefix=''
		EXEC [sp_GetDocPrefix] @DocXml,@DT_INT,@COSTCENTERID,@Prefix output 

		EXEC @return_value = [dbo].[spDOC_SetTempAccDocument]
			@CostCenterID = @COSTCENTERID,
			@DocID = 0,
			@DocPrefix = @Prefix,
			@DocNumber = N'',
			@DocDate = @DT_INT,
			@DueDate =NULL,
			@BillNo = NULL,
			@InvDocXML = @DocXml,
			@NotesXML =  N'',
			@AttachmentsXML =  N'',
			@ActivityXML = N'',
			@IsImport = 0,
			@LocationID = 1,
			@DivisionID = 1,
			@WID = 0,
			@RoleID = 1,
			@RefCCID = 72,
			@RefNodeid =1 ,
			@CompanyGUID = @CompanyGUID,
			@UserName = @UserName,
			@UserID = @UserID,
			@LangID = @LangID
				
	--	SELECT * FROM ACC_DOCDETAILS with(nolock) WHERE DOCID=@return_value
		     
		--IF(@return_value < 0 )
		--	continue;
	end
	else
	begin
		EXEC @return_value = [dbo].[spDOC_DeleteAccDocument]    
		@CostCenterID = @COSTCENTERID,@DocPrefix = '',@DocNumber = '', @DOcID=   @DOCID,
		@UserID = 1,@UserName = N'ADMIN',@LangID = 1,@RoleID=1
	end
end

if @return_value>0
begin
	UPDATE ACC_Assets
	set ASSETNETVALUE=(AssetNetValue-T.DeprAmount)
	from ACC_Assets A
	inner join 
	(
	select T.AssetID,sum(Amount) DeprAmount 
	from ACC_AssetDeprDocDetails D with(nolock)
	inner join @TblDepr T on D.DPScheduleID=T.DeprID
	group by T.AssetID
	) AS T on A.AssetID=T.AssetID
	
	update ACC_AssetDepSchedule  
	set DOCID=NULL,VOUCHERNO=NULL,DOCDATE=NULL,STATUSID=0
	from @TblDepr T
	inner join ACC_AssetDepSchedule D on D.DPScheduleID=T.DeprID

	delete from ACC_AssetDeprDocDetails where DPScheduleID in (select DeprID from @TblDepr)

	--insert into ACC_AssetChanges(AssetID,ChangeType,ChangeName,StatusID,ChangeDate,AssetOldValue,ChangeValue,AssetNewValue,LocationID,GUID,CreatedBy,CreatedDate)  
	--values(@AssetID,7,'Depreciation Schedule UnPost',1,@DT_INT,@AssetNetValue,@DepAmount,(@AssetNetValue-@DepAmount),NULL,newid(),'ADMIN',convert(float,@DT))  
end

COMMIT TRANSACTION
--ROLLBACK TRANSACTION
     
SELECT ErrorMessage,ErrorNumber FROM COM_ErrorMessages WITH(nolock)     
WHERE ErrorNumber=100 AND LanguageID=@LangID    
SET NOCOUNT OFF;   
RETURN @return_value

END TRY        
BEGIN CATCH        
IF ERROR_NUMBER()=50000    
 BEGIN    
 SELECT ErrorMessage,ErrorNumber FROM COM_ErrorMessages WITH(nolock)     
  WHERE ErrorNumber=ERROR_MESSAGE() AND LanguageID=@LangID    
 END    
 ELSE    
 BEGIN    
  SELECT ErrorMessage, ERROR_MESSAGE() AS ServerMessage,ERROR_NUMBER() as ErrorNumber, ERROR_PROCEDURE()as ProcedureName, ERROR_LINE() AS ErrorLine    
  FROM COM_ErrorMessages WITH(nolock) WHERE ErrorNumber=-999 AND LanguageID=@LangID    
 END     
 ROLLBACK TRANSACTION      
 SET NOCOUNT OFF        
 RETURN -999         
END CATCH   
GO

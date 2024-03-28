USE PACT2C222
GO
SET ANSI_NULLS, QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spADM_SetVATNewDoc]
	@NewDocs [nvarchar](max)
WITH ENCRYPTION, EXECUTE AS CALLER
AS
BEGIN
	declare @i int,@j int,@cnt int,@Type nvarchar(50),@Abbr nvarchar(20),@NewAbbr nvarchar(20),@XML xml,@CostCenterID bigint,@Error nvarchar(max)
	,@DocumentName nvarchar(100),@NewDocumentName nvarchar(100),@LocName nvarchar(100),@TblLocCnt int,@LocCnt int,@TempStr nvarchar(max)
	declare @Tbl as table(ID int identity(1,1),Type nvarchar(20),Abbr nvarchar(20),Name nvarchar(100))
	declare @TblLocs as table(ID int identity(1,1),Text nvarchar(100))
	set @XML=@NewDocs
	insert into @Tbl
	select X.value('@Type','nvarchar(max)'),X.value('@Abbr','nvarchar(max)'),X.value('@Name','nvarchar(max)') from @XML.nodes('XML/Row') AS DATA(X)
	
	insert into @TblLocs
	select X.value('@Text','nvarchar(max)') from @XML.nodes('XML/Locations/loc') AS DATA(X)
	select @TblLocCnt=count(*) from @TblLocs
	set @LocCnt=@TblLocCnt
	if @LocCnt=0
		set @LocCnt=1
	select @i=1,@j=1,@cnt=count(*) from  @Tbl
	declare @Para1 nvarchar(max),@Menu nvarchar(20)
	while(@i<=@cnt)
	begin
		set @j=1
		select @Type=Type,@Abbr=Abbr,@DocumentName=Name from @Tbl where ID=@i
		while(@j<=@LocCnt)
		begin
			if(@LocCnt>1)
				set @NewAbbr=@Abbr+convert(nvarchar,@j)
			else
				set @NewAbbr=@Abbr
			if exists (select * from adm_documentTypes with(nolock) where DocumentAbbr=@NewAbbr)
			begin
				set @Error='Document Abbrevation Exists : '''+@NewAbbr+''''
				RAISERROR(@Error,16,1)
			end
			
			if(@TblLocCnt>0)
				select @NewDocumentName=@DocumentName+' - '+Text from @TblLocs where ID=@j
			else
				select @NewDocumentName=@DocumentName
			--select @Type,@NewDocumentName,@NewAbbr

			--Purchase Invoice
			if @Type='VAT_PISR' or @Type='VAT_RADPM' or @Type='VAT_ADRC'
			begin
				if @Type='VAT_RADPM'
					set @Menu='40015'
				else if @Type='VAT_ADRC'
					set @Menu='40018'
				else if @Type='VAT_PISR'
					set @Menu='40001'
				set @Para1='<Document><Row DocumentType=''1'' DocumentAbbr='''+@NewAbbr+'''  Menu='''+@Menu+'''  DocumentName='''+@NewDocumentName+''' DiscountCommision='''' DiscountInterest='''' BouncePenaltyFld='''' StatusID=''368'' ConvertAs='''' BounceSeries='''' Bounce=''''  Series='''' IntermediateConvertion=''''  OnDiscount='''' /></Document>'
				exec @CostCenterID=spADM_SetDocumentDef 0,1,@Para1
				 ,'<Xml><Row ColFieldType="1" Formula="" Header="Quantity" IsCalculate="1" ></Row><Row ColFieldType="1" Formula="" Header="HoldQuantity" IsCalculate="1" ></Row><Row ColFieldType="1" Formula="" Header="ReserveQuantity" IsCalculate="1" ></Row><Row ColFieldType="1" Formula="" Header="Rate" IsCalculate="1" ></Row></Xml>'
				 ,'<Xml><Row   Group=''Linking'' Name=''Expiredafter'' Value=''0''/><Row  Group=''Common'' Name=''PostDocumentCondition'' Value=''''/><Row   Group=''Common'' Name=''DueDateonBillDate'' Value=''''/><Row   Group=''Common'' Name=''Paymenttermsbasedon'' Value=''''/><Row  Group=''General'' Name=''NewRefLimit'' Value=''0''/><Row   Group=''General'' Name=''Enable Hold'' Value=''False''/><Row   Group=''General'' Name=''FPQty'' Value=''''/><Row   Group=''General'' Name=''BodyFreezeColumn'' Value=''''/><Row   Group=''General'' Name=''SchemesNumericFields'' Value=''''/><Row   Group=''General'' Name=''Autopostdocument'' Value=''''/><Row   Group=''General'' Name=''DefaultProfileID'' Value=''''/><Row   Group=''General'' Name=''ProductFilterField'' Value=''''/><Row  Group=''Linking'' Name=''QOH'' Value=''False''/><Row  Group=''Linking'' Name=''ProductCode'' Value=''False''/><Row  Group=''Linking'' Name=''ProductName'' Value=''False''/><Row  Group=''Linking'' Name=''Qty'' Value=''False''/><Row  Group=''Linking'' Name=''ExecutedQty'' Value=''False''/><Row  Group=''Linking'' Name=''BalanceQty'' Value=''False''/><Row  Group=''Linking'' Name=''LinkValue'' Value=''False''/><Row  Group=''Common'' Name=''ShowAccount'' Value=''Name''/><Row  Group=''Common'' Name=''Check Budget'' Value=''False''/><Row  Group=''Common'' Name=''OnlyExpired'' Value=''False''/><Row  Group=''Common'' Name=''IncludeExpiredMonths'' Value=''0''/><Row  Group=''Common'' Name=''OnlyExpiredMonths'' Value=''0''/><Row  Group=''Common'' Name=''IncludeExpired'' Value=''False''/><Row  Group=''Common'' Name=''IncludeRetest'' Value=''False''/><Row  Group=''Common'' Name=''ExcludePreExpired'' Value=''False''/><Row  Group=''Common'' Name=''DontAllowNegative'' Value=''False''/><Row  Group=''Common'' Name=''SameBatchtoall'' Value=''False''/><Row  Group=''Common'' Name=''QtyonBatch'' Value=''False''/><Row  Group=''Common'' Name=''ShowBatches'' Value=''False''/><Row  Group=''Common'' Name=''AutoBatches'' Value=''False''/><Row  Group=''Common'' Name=''AutoPopulateBatchQty'' Value=''False''/><Row  Group=''Common'' Name=''ScanBatches'' Value=''False''/><Row  Group=''Common'' Name=''Autobatchifsingle'' Value=''False''/><Row  Group=''Common'' Name=''PackLabel'' Value=''False''/><Row  Group=''Common'' Name=''LineWisePacking'' Value=''False''/><Row  Group=''Common'' Name=''PackWiseProds'' Value=''False''/><Row  Group=''Common'' Name=''PackMandScan'' Value=''False''/><Row  Group=''Common'' Name=''EnablePacking'' Value=''False''/><Row  Group=''Static'' Name=''DefaultLabel'' Value=''''/><Row  Group=''Static'' Name=''DefaultPack'' Value=''0''/><Row  Group=''Static'' Name=''LocalRefflds'' Value=''''/><Row  Group=''Static'' Name=''ShowBOE'' Value=''False''/><Row  Group=''Static'' Name=''Billlanding'' Value=''False''/><Row  Group=''Static'' Name=''BilllandingReport'' Value=''0''/><Row  Group=''Static'' Name=''BilllandingMap'' Value=""/><Row  Group=''Static'' Name=''Paypercent'' Value=''0''/><Row  Group=''Static'' Name=''ValueType'' Value=''0''/><Row  Group=''General'' Name=''TransitDOcs'' Value=''''/><Row  Group=''Static'' Name=''Paytermids'' Value=''''/><Row  Group=''Common'' Name=''SplitKit'' Value=''False''/><Row  Group=''Static'' Name=''QuickViewDimensions'' Value=''''/><Row  Group=''Common'' Name=''Select Port'' Value=''False''/><Row  Group=''Common'' Name=''Open Cash Drawer'' Value=''False''/><Row  Group=''Common'' Name=''DecimalsBillWise'' Value=''0''/><Row  Group=''Common'' Name=''DecimalsNetAmount'' Value=''3''/><Row  Group=''Common'' Name=''LockCostCenters'' Value=''0''/><Row  Group=''Common'' Name=''Lock Data Between'' Value=''False''/><Row  Group=''Common'' Name=''LockCostCenterNodes'' Value=''''/><Row  Group=''Common'' Name=''StaticLinkingColumns'' Value="&lt;XML&gt;&lt;Row Name=''ProductCode'' WIDTH=''100'' Header=''ProductCode'' index=''-1'' /&gt;&lt;Row Name=''ProductName'' WIDTH=''100'' Header=''ProductName'' index=''-1'' /&gt;&lt;Row Name=''Qty'' WIDTH=''100'' Header=''Qty'' index=''-1'' /&gt;&lt;Row Name=''QOH'' WIDTH=''100'' Header=''QOH'' index=''-1'' /&gt;&lt;Row Name=''ExecutedQty'' WIDTH=''100'' Header=''ExecutedQty'' index=''-1'' /&gt;&lt;Row Name=''BalanceQty'' WIDTH=''100'' Header=''BalanceQty'' index=''-1'' /&gt;&lt;Row Name=''LinkValue'' WIDTH=''100'' Header=''LinkValue'' index=''-1'' /&gt;&lt;/XML&gt;"/><Row  Group=''COMMON'' Name=''ClubProdBasedon'' Value=''''/></Xml>'
				 ,'<Prefix></Prefix>'
				 ,'<DynamicMappingDetails></DynamicMappingDetails>'
				 ,'','','0','0'
				 ,'<Xml></Xml>','<Xml></Xml>',''
				 ,@Menu,1,'',0,'','','','','<Budgets></Budgets>'
				 ,'<LockedDates><Row  FromDate="01 Jan 1900" ToDate="01 Jan 1900" isEnable="True"/></LockedDates>'
				 ,'admin','admin',1,1,1
				 
				 update adm_documentTypes set [Description]=@Type,CreatedBy=@Type where CostCenterID=@CostCenterID
				 
				 if @Type='VAT_PISR' or @Type='VAT_RADPM' or @Type='VAT_ADRC'
				 begin
					--select * from com_documentpreferences with(nolock) where CostCenterID=@CostCenterID and PrefName like '%type%'
					update com_documentpreferences set PrefValue='True' where CostCenterID=@CostCenterID and PrefName='DonotupdateInventory'
					update com_documentpreferences set PrefValue='False' where CostCenterID=@CostCenterID and PrefName='DonotupdateAccounts'
					if @Type='VAT_PISR'
						update adm_costcenterdef set UserProbableValues=' a.AccountTypeID in (12)' where CostCenterID=@CostCenterID and SysColumnName='DebitAccount' 
					else if @Type='VAT_RADPM'  or @Type='VAT_ADRC'
						update adm_costcenterdef set UserProbableValues=' a.AccountTypeID in (2,1,10)' where CostCenterID=@CostCenterID and SysColumnName='DebitAccount'
					if @Type='VAT_ADRC'
					begin						
						set @TempStr=isnull((select top 1 UserColumnName from adm_costcenterdef with(nolock) where costcenterid=40011 and SysColumnName='DebitAccount'),'Customer')
						update adm_costcenterdef set UserColumnName=@TempStr where costcenterid=@CostCenterID and SysColumnName='CreditAccount'
						update [com_languageresources] set [ResourceData]=@TempStr,[ResourceName]=@TempStr
						where ResourceID in (select ResourceID from adm_costcenterdef with(nolock) where costcenterid=@CostCenterID and SysColumnName='CreditAccount')
						
						update adm_costcenterdef set UserColumnName='Cash/Bank' where costcenterid=@CostCenterID and SysColumnName='DebitAccount'
						update [com_languageresources] set [ResourceData]='Cash/Bank',[ResourceName]='Cash/Bank'
						where ResourceID in (select ResourceID from adm_costcenterdef with(nolock) where costcenterid=@CostCenterID and SysColumnName='DebitAccount')
						
						update adm_costcenterdef set UserColumnName='Cheque Number' where costcenterid=@CostCenterID and SysColumnName='BillNo'
						update [com_languageresources] set [ResourceData]='Cheque Number',[ResourceName]='Cheque Number'
						where ResourceID in (select ResourceID from adm_costcenterdef with(nolock) where costcenterid=@CostCenterID and SysColumnName='BillNo')
						
						update adm_costcenterdef set UserColumnName='Cheque Date' where costcenterid=@CostCenterID and SysColumnName='BillDate'
						update [com_languageresources] set [ResourceData]='Cheque Date',[ResourceName]='Cheque Date'
						where ResourceID in (select ResourceID from adm_costcenterdef with(nolock) where costcenterid=@CostCenterID and SysColumnName='BillDate')
					end 
				 end				 
			end
			else if @Type='VAT_SISR' or @Type='VAT_ADPM' or @Type='VAT_RADRC'
			begin
				if @Type='VAT_ADPM'
					set @Menu='40015'
				else if @Type='VAT_RADRC'
					set @Menu='40018'
				else if @Type='VAT_SISR'
					set @Menu='40011'
				set @Para1='<Document><Row DocumentType=''11'' DocumentAbbr='''+@NewAbbr+'''  Menu='''+@Menu+'''  DocumentName='''+@NewDocumentName+''' DiscountCommision='''' DiscountInterest='''' BouncePenaltyFld='''' StatusID=''368'' ConvertAs='''' BounceSeries='''' Bounce=''''  Series='''' IntermediateConvertion=''''  OnDiscount='''' /></Document>'
				exec @CostCenterID=spADM_SetDocumentDef 0,11,@Para1
				 ,'<Xml><Row ColFieldType="1" Formula="" Header="Quantity" IsCalculate="1" ></Row><Row ColFieldType="1" Formula="" Header="HoldQuantity" IsCalculate="1" ></Row><Row ColFieldType="1" Formula="" Header="ReserveQuantity" IsCalculate="1" ></Row><Row ColFieldType="1" Formula="" Header="Rate" IsCalculate="1" ></Row></Xml>'
				 ,'<Xml><Row   Group=''Linking'' Name=''Expiredafter'' Value=''0''/><Row   Group=''Linking'' Name=''BarcodeField'' Value=''''/><Row  Group=''Common'' Name=''PostDocumentCondition'' Value=''''/><Row   Group=''Common'' Name=''DueDateonBillDate'' Value=''''/><Row   Group=''Common'' Name=''Paymenttermsbasedon'' Value=''''/><Row   Group=''Common'' Name=''PostVoucherDocument'' Value=''''/><Row   Group=''General'' Name=''Enable Hold'' Value=''False''/><Row   Group=''General'' Name=''Enable Reserve'' Value=''False''/><Row   Group=''General'' Name=''SchemesNumericFields'' Value=''''/><Row   Group=''General'' Name=''Autopostdocument'' Value=''''/><Row   Group=''General'' Name=''FPQty'' Value=''''/><Row   Group=''General'' Name=''DefaultProfileID'' Value=''''/><Row   Group=''General'' Name=''ProductFilterField'' Value=''''/><Row   Group=''General'' Name=''EmailBasedOnDimension'' Value=''''/><Row   Group=''General'' Name=''BodyFreezeColumn'' Value=''''/><Row  Group=''Linking'' Name=''QOH'' Value=''False''/><Row  Group=''Linking'' Name=''ProductCode'' Value=''False''/><Row  Group=''Linking'' Name=''ProductName'' Value=''False''/><Row  Group=''Linking'' Name=''Qty'' Value=''False''/><Row  Group=''Linking'' Name=''ExecutedQty'' Value=''False''/><Row  Group=''Linking'' Name=''BalanceQty'' Value=''False''/><Row  Group=''Linking'' Name=''LinkValue'' Value=''False''/><Row  Group=''Common'' Name=''ShowAccount'' Value=''Name''/><Row  Group=''Common'' Name=''Check Budget'' Value=''False''/><Row  Group=''Common'' Name=''OnlyExpired'' Value=''False''/><Row  Group=''Common'' Name=''IncludeExpiredMonths'' Value=''0''/><Row  Group=''Common'' Name=''OnlyExpiredMonths'' Value=''0''/><Row  Group=''Common'' Name=''IncludeExpired'' Value=''False''/><Row  Group=''Common'' Name=''IncludeRetest'' Value=''False''/><Row  Group=''Common'' Name=''ExcludePreExpired'' Value=''False''/><Row  Group=''Common'' Name=''DontAllowNegative'' Value=''False''/><Row  Group=''Common'' Name=''SameBatchtoall'' Value=''False''/><Row  Group=''Common'' Name=''QtyonBatch'' Value=''False''/><Row  Group=''Common'' Name=''ShowBatches'' Value=''False''/><Row  Group=''Common'' Name=''AutoBatches'' Value=''False''/><Row  Group=''Common'' Name=''AutoPopulateBatchQty'' Value=''False''/><Row  Group=''Common'' Name=''ScanBatches'' Value=''False''/><Row  Group=''Common'' Name=''Autobatchifsingle'' Value=''False''/><Row  Group=''Common'' Name=''PackLabel'' Value=''False''/><Row  Group=''Common'' Name=''LineWisePacking'' Value=''False''/><Row  Group=''Common'' Name=''PackWiseProds'' Value=''False''/><Row  Group=''Common'' Name=''PackMandScan'' Value=''False''/><Row  Group=''Common'' Name=''EnablePacking'' Value=''False''/><Row  Group=''Static'' Name=''DefaultLabel'' Value=''''/><Row  Group=''Static'' Name=''DefaultPack'' Value=''0''/><Row  Group=''Static'' Name=''LocalRefflds'' Value=''''/><Row  Group=''Static'' Name=''ShowBOE'' Value=''False''/><Row  Group=''Static'' Name=''Billlanding'' Value=''False''/><Row  Group=''Static'' Name=''BilllandingReport'' Value=''0''/><Row  Group=''Static'' Name=''BilllandingMap'' Value=""/><Row  Group=''Static'' Name=''Paypercent'' Value=''''/><Row  Group=''Static'' Name=''ValueType'' Value=''0''/><Row  Group=''General'' Name=''TransitDOcs'' Value=''''/><Row  Group=''Static'' Name=''Paytermids'' Value=''''/><Row  Group=''Common'' Name=''SplitKit'' Value=''False''/><Row  Group=''Static'' Name=''QuickViewDimensions'' Value=''''/><Row  Group=''Common'' Name=''Select Port'' Value=''False''/><Row  Group=''Common'' Name=''Open Cash Drawer'' Value=''False''/><Row  Group=''Common'' Name=''DecimalsBillWise'' Value=''0''/><Row  Group=''Common'' Name=''DecimalsNetAmount'' Value=''3''/><Row  Group=''Common'' Name=''LockCostCenters'' Value=''0''/><Row  Group=''Common'' Name=''Lock Data Between'' Value=''False''/><Row  Group=''Common'' Name=''LockCostCenterNodes'' Value=''''/><Row  Group=''Common'' Name=''StaticLinkingColumns'' Value="&lt;XML&gt;&lt;Row Name=''ProductCode'' WIDTH=''100'' Header=''ProductCode'' index=''-1'' /&gt;&lt;Row Name=''ProductName'' WIDTH=''100'' Header=''ProductName'' index=''-1'' /&gt;&lt;Row Name=''Qty'' WIDTH=''100'' Header=''Qty'' index=''-1'' /&gt;&lt;Row Name=''QOH'' WIDTH=''100'' Header=''QOH'' index=''-1'' /&gt;&lt;Row Name=''ExecutedQty'' WIDTH=''100'' Header=''ExecutedQty'' index=''-1'' /&gt;&lt;Row Name=''BalanceQty'' WIDTH=''100'' Header=''BalanceQty'' index=''-1'' /&gt;&lt;Row Name=''LinkValue'' WIDTH=''100'' Header=''LinkValue'' index=''-1'' /&gt;&lt;/XML&gt;"/><Row  Group=''COMMON'' Name=''ClubProdBasedon'' Value=''''/></Xml>'
				 ,'<Prefix></Prefix>'
				 ,'<DynamicMappingDetails></DynamicMappingDetails>'
				 ,'','','0','0'
				 ,'<Xml></Xml>','<Xml></Xml>' ,''
				 ,@Menu,'0','',0,'','','',''
				 ,'<Budgets></Budgets>'
				 ,'<LockedDates><Row  FromDate="01 Jan 1900" ToDate="01 Jan 1900" isEnable="True"/></LockedDates>'
				 ,'admin','admin',1,1,1
				 
				 update adm_documentTypes set [Description]=@Type,CreatedBy=@Type where CostCenterID=@CostCenterID
				 
				 if @Type='VAT_SISR' or @Type='VAT_ADPM' or @Type='VAT_RADRC'
				 begin
				--	select * from com_documentpreferences with(nolock) where CostCenterID=@CostCenterID and PrefName like '%type%'
					update com_documentpreferences set PrefValue='True' where CostCenterID=@CostCenterID and PrefName='DonotupdateInventory'
					update com_documentpreferences set PrefValue='False' where CostCenterID=@CostCenterID and PrefName='DonotupdateAccounts'
					if @Type='VAT_SISR'
						update adm_costcenterdef set UserProbableValues=' a.AccountTypeID in (11)' where CostCenterID=@CostCenterID and SysColumnName='CreditAccount' 
					else if @Type='VAT_ADPM' or @Type='VAT_RADRC'
						update adm_costcenterdef set UserProbableValues=' a.AccountTypeID in (2,1,10)' where CostCenterID=@CostCenterID and SysColumnName='CreditAccount' 
					if @Type='VAT_ADPM'
					begin						
						set @TempStr=isnull((select top 1 UserColumnName from adm_costcenterdef with(nolock) where costcenterid=40001 and SysColumnName='CreditAccount'),'Vendor')
						update adm_costcenterdef set UserColumnName=@TempStr where costcenterid=@CostCenterID and SysColumnName='DebitAccount'
						update [com_languageresources] set [ResourceData]=@TempStr,[ResourceName]=@TempStr
						where ResourceID in (select ResourceID from adm_costcenterdef with(nolock) where costcenterid=@CostCenterID and SysColumnName='DebitAccount')
						
						update adm_costcenterdef set UserColumnName='Cash/Bank' where costcenterid=@CostCenterID and SysColumnName='CreditAccount'
						update [com_languageresources] set [ResourceData]='Cash/Bank',[ResourceName]='Cash/Bank'
						where ResourceID in (select ResourceID from adm_costcenterdef with(nolock) where costcenterid=@CostCenterID and SysColumnName='CreditAccount')
						
						update adm_costcenterdef set UserColumnName='Cheque Number' where costcenterid=@CostCenterID and SysColumnName='BillNo'
						update [com_languageresources] set [ResourceData]='Cheque Number',[ResourceName]='Cheque Number'
						where ResourceID in (select ResourceID from adm_costcenterdef with(nolock) where costcenterid=@CostCenterID and SysColumnName='BillNo')
						
						update adm_costcenterdef set UserColumnName='Cheque Date' where costcenterid=@CostCenterID and SysColumnName='BillDate'
						update [com_languageresources] set [ResourceData]='Cheque Date',[ResourceName]='Cheque Date'
						where ResourceID in (select ResourceID from adm_costcenterdef with(nolock) where costcenterid=@CostCenterID and SysColumnName='BillDate')
					end					
				 end
			end
						
			update adm_costcenterdef
			set IsVisible=0 from adm_costcenterdef C with(nolock)
			where C.CostCenterID=@CostCenterID and SysColumnName='IsScheme'

			update adm_costcenterdef
			set CREATEDBy=@Type,GUID=@Type from adm_costcenterdef C with(nolock)
			where C.CostCenterID=@CostCenterID
			
			update com_documentpreferences set PrefValue='False' where CostCenterID=@CostCenterID and PrefName like '%attachment%' and PrefValue='True'
			
		--	select * from adm_documentTypes where CostCenterID=@CostCenterID
		--	select * from adm_costcenterdef where CostCenterID=@CostCenterID
			set @j=@j+1
		end
		set @i=@i+1
	end

--RAISERROR('ABC',16,1)

END
GO

USE PACT2C222
GO
SET ANSI_NULLS, QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spADM_GetBills]
	@FromDate [datetime],
	@ToDate [datetime],
	@IsVoucherWise [bit],
	@From [bigint],
	@To [bigint],
	@tilldate [datetime],
	@CustomerID [bigint],
	@UserName [nvarchar](200),
	@UserID [bigint],
	@LangID [int] = 1
WITH ENCRYPTION, EXECUTE AS CALLER
AS
BEGIN TRANSACTION        
BEGIN TRY        
SET NOCOUNT ON;      
         --select * from inv_docdetails
       declare @sql nvarchar(max),@HCCCID bigint,@HDCCID bigint,@HRCCID bigint,@SIVCCID bigint,@i int,@cnt int,@RetDetID bigint,@rate float,@Actrate float,@RetDays int,@SIVBIllDate nvarchar(200),@Prodid bigint
       declare @HCPricing nvarchar(50),@HCBillingCycle nvarchar(50),@HCBillableFlag nvarchar(50),@HDDeliveryDate nvarchar(50),@HCBillingDay  nvarchar(50),@ActRetDate datetime,@offhireCCCID int,@isOff bit
	   declare @InvDocDetID BIGINT,@DocID BIGINT,@StartDate datetime,@RetDate datetime,@BillingDay nvarchar(200),@Pricing nvarchar(200),@BillingCycle nvarchar(200),@DelDate datetime,@BillDate datetime		
       
       set @offhireCCCID=0
       
       select @HCCCID=Value from COM_CostCenterPreferences WITH(NOLOCK)
       where Name='HireContractDoc' and ISNUMERIC(Value)=1
       
        if(@HCCCID is null or @HCCCID <40000)
			RAISERROR('-461',16,1)
			
		select @HDCCID=Value from COM_CostCenterPreferences WITH(NOLOCK)
		where Name='HireDeliveryDoc' and ISNUMERIC(Value)=1

		if(@HDCCID is null or @HDCCID <40000)
			RAISERROR('-461',16,1)
			
		select @HRCCID=Value from COM_CostCenterPreferences WITH(NOLOCK)
		where Name='HireReturnDoc' and ISNUMERIC(Value)=1

		if(@HRCCID is null or @HRCCID <40000)
			RAISERROR('-461',16,1)
			
		select @SIVCCID=Value from COM_CostCenterPreferences WITH(NOLOCK)
		where Name='SIVDoc' and ISNUMERIC(Value)=1
		
		 if(@SIVCCID is null or @SIVCCID <40000)
			RAISERROR('-461',16,1)
			
		select @offhireCCCID=Value from COM_CostCenterPreferences WITH(NOLOCK)
		where Name='OffHireDoc' and ISNUMERIC(Value)=1
		
		--select @HCPricing=Value from COM_CostCenterPreferences WITH(NOLOCK)
		--where Name='HCPricing' and Value is not null and Value<>''
       
		select @HCBillingCycle=Value from COM_CostCenterPreferences WITH(NOLOCK)
		where Name='HCBillingCycle' and Value is not null and Value<>''
		
		if(@HCBillingCycle is null or @HCBillingCycle='')
			RAISERROR('-461',16,1)
			
		select @HCBillableFlag=Value from COM_CostCenterPreferences WITH(NOLOCK)
		where Name='HCBillableFlag' and Value is not null and Value<>''

		select @HDDeliveryDate=Value from COM_CostCenterPreferences WITH(NOLOCK)
		where Name='HDDeliveryDate' and Value is not null and Value<>''
		
		if(@HDDeliveryDate is null or @HDDeliveryDate='')
			RAISERROR('-461',16,1)
		
		select @SIVBIllDate=Value from COM_CostCenterPreferences WITH(NOLOCK)
		where Name='SIVBillingDate' and Value is not null and Value<>''
		
		if(@SIVBIllDate is null or @SIVBIllDate='')
			RAISERROR('-461',16,1)	
			
		select @HCBillingDay=Value from COM_CostCenterPreferences WITH(NOLOCK)
		where Name='HCBillingDay' and Value is not null and Value<>''
		
	 
		      
		declare @Tab table(id int identity(1,1),InvDocDetID BIGINT,RetDetID BIGINT,DocID BIGINT,DocDate datetime,RetDate datetime,VoucherNo nvarchar(200),HCBillingCycle nvarchar(200),BillDay nvarchar(200),DelDate datetime,rate float,PRID BIGINT)
		create table #ResTab(InvDocDetailsID BIGINT,Billdate datetime,ExlDays float,Amount Float,Fromdate Datetime,Todate Datetime,isoffhire bit,Prodid bigint)
					
		set @sql='select a.InvDocDetailsID,HR.InvDocDetailsID,a.DocID,convert(datetime,a.DocDate),convert(datetime,HR.DocDate),a.VoucherNo,b.'+@HCBillingCycle
		
		if(@HCBillingDay is not null and @HCBillingDay<>'')
			set @sql =@sql+',b.'+@HCBillingDay
		else
			set @sql =@sql+','''''
			
		if(@HDDeliveryDate like 'dcalpha%')
			set @sql =@sql+',HdT.'+@HDDeliveryDate
		else
			set @sql =@sql+',convert(datetime,Hd.'+@HDDeliveryDate+')'
			
		set @sql =@sql+',a.Rate,HD.ProductID from INV_DocDetails a with(nolock)
		join INV_DocDetails Hd with(nolock) on a.InvDocDetailsID=Hd.LinkedInvDocDetailsID '
		
		if(@HDDeliveryDate like 'dcalpha%')
			set @sql =@sql+' join COM_DocTextData HdT with(nolock) on Hd.InvDocDetailsID=HdT.InvDocDetailsID '
			
		set @sql =@sql+'LEFT join INV_DocDetails HR with(nolock) on Hd.InvDocDetailsID=HR.LinkedInvDocDetailsID and HR.CostCenterID ='+convert(nvarchar,@HRCCID) +'
		join COM_DocTextData b with(nolock) on a.InvDocDetailsID=b.InvDocDetailsID  
		where a.statusid=369 and a.CostCenterID ='+convert(nvarchar,@HCCCID)+' and Hd.CostCenterID ='+convert(nvarchar,@HDCCID) 
		if(@HCBillableFlag<>'')
			set @sql =@sql  +' and '+@HCBillableFlag+'=''yes'''
		
		
		if(@IsVoucherWise=0)
			set @sql =@sql +' and a.DocDate between '+convert(nvarchar,convert(float,@FromDate))+' and '+convert(nvarchar,convert(float,@ToDate))
		else
			set @sql =@sql +' and a.docnumber between '+convert(nvarchar,@From)+' and '+convert(nvarchar,@To)
		
		if(@CustomerID>0)
			set @sql =@sql  +' and a.DebitAccount='+convert(nvarchar,@CustomerID)
		set @sql =@sql+' order by a.DocDate,a.DOCprefix,convert(bigint,a.docnumber)'  
	  
		-- print @sql
		insert into @Tab
		exec(@sql)  
				
		select @i=0,@cnt=COUNT(id) from @Tab
		
		while(@i<@cnt)
		BEGIN
			set @i=@i+1
			set @isOff=null
			set @RetDate=null
			set @RetDetID=0
			select @InvDocDetID=InvDocDetID,@rate=rate,@DocID=DocID,@RetDate=RetDate,@BillingDay=BillDay,@BillingCycle=HCBillingCycle,@DelDate=DelDate,@RetDetID=isnull(RetDetID,0),@Prodid=PRID
			from @Tab where id=@i
			
			if(@RetDate is null)				
				set @RetDate=@tilldate
		
			if(@BillingCycle='Daily')
			BEGIN				
				while(@DelDate<=@RetDate)
				BEGIN
					
					if(@offhireCCCID>0 and @RetDate<DATEADD(day,1,@DelDate) and @RetDetID>0)
					BEGIN
						if exists(select a.InvDocDetailsID from INV_DocDetails a with(NOLOCK)
						where costcenterid=@offhireCCCID and LinkedInvDocDetailsID=@RetDetID)
							set @isOff=1
					END
									
					insert into #ResTab(InvDocDetailsID,Amount,Billdate,Fromdate,Todate,isoffhire,Prodid)
					values(@InvDocDetID,@rate,@DelDate,@DelDate,@DelDate,@isOff,@Prodid)
					
					set @DelDate=DATEADD(day,1,@DelDate)
					
					if(@RetDate<@DelDate and @RetDetID>0)
					BEGIN						
						if exists(select  a.InvDocDetailsID from INV_DocDetails a with(NOLOCK)
						join INV_DocDetails HD with(NOLOCK) on a.InvDocDetailsID=HD.LinkedInvDocDetailsID
						where a.InvDocDetailsID=@RetDetID and Hd.CostCenterID =@HDCCID)
						BEGIN													
							set @sql='select @RetDetID=isnull(HR.InvDocDetailsID,0),@RetDate=convert(datetime,HR.DocDate),@DelDate='
							if(@HDDeliveryDate like 'dcalpha%')
								set @sql =@sql+'HdT.'+@HDDeliveryDate
							else
								set @sql =@sql+'convert(datetime,Hd.'+@HDDeliveryDate+')'
								
							set @sql =@sql+',@Prodid=HD.ProductID from INV_DocDetails a with(NOLOCK)
							join INV_DocDetails HD with(NOLOCK) on a.InvDocDetailsID=HD.LinkedInvDocDetailsID '
							if(@HDDeliveryDate like 'dcalpha%')
								set @sql =@sql+' join COM_DocTextData HdT with(nolock) on Hd.InvDocDetailsID=HdT.InvDocDetailsID '
			
							set @sql =@sql+' left join INV_DocDetails HR with(NOLOCK) on HD.InvDocDetailsID=HR.LinkedInvDocDetailsID and HR.CostCenterID ='+convert(nvarchar,@HRCCID) +'
							where a.InvDocDetailsID='+convert(nvarchar,@RetDetID) +' and Hd.CostCenterID ='+convert(nvarchar,@HDCCID) 
							
							set @RetDetID=0
							set @RetDate=null	
							
							exec sp_executesql @sql,N'@RetDetID BIGINT OUTPUT,@RetDate datetime OUTPUT,@DelDate datetime OUTPUT,@Prodid BIGINT OUTPUT',@RetDetID OUTPUT,@RetDate OUTPUT,@DelDate OUTPUT,@Prodid OUTPUT
							
							if(@RetDate is null)				
								set @RetDate=@tilldate
						END
					END
				END
			END
			else if(@BillingCycle='Monthly' or @BillingCycle='Start of Month' or @BillingCycle='End of Month')
			BEGIN
				
				set @BillDate=null
				
				WHILE(1=1)
				BEGIN
					
					set @RetDays=0
					
					if(@BillDate is not null and @RetDate<@BillDate)
							break;
					
					if(@BillDate is null)	
					BEGIN	
						set @StartDate=@DelDate 
						set @BillDate=DATEADD(MONTH,1,@DelDate)
						
						if(@BillingCycle='End of Month')
						BEGIN
							set @BillDate=@BillDate-DAY(@DelDate)
							set @BillingDay=day(DATEADD(dd,-1,dateadd(mm,DATEDIFF(mm,-1,@DelDate),0)))
						END	
						else if(@BillingCycle='Start of Month')
						BEGIN
							set @BillDate=@BillDate-DAY(@DelDate)+1
							set @BillingDay=day(DATEADD(dd,-1,dateadd(mm,DATEDIFF(mm,-1,@DelDate),0)))
						END	
						else if(@BillingDay is not null and @BillingDay<>'' and ISNUMERIC(@BillingDay)=1)
						BEGIN
							if(CONVERT(int,@BillingDay)>DAY(@DelDate))
							BEGIN
								set @BillDate=DATEADD(DAY,CONVERT(int,@BillingDay)-DAY(@DelDate),@DelDate)							
							END
							ELSE
							BEGIN
								set @BillDate=@BillDate-DAY(@DelDate)
								set @BillDate=@BillDate+CONVERT(int,@BillingDay)
							END	
							set @BillingDay=day(DATEADD(dd,-1,dateadd(mm,DATEDIFF(mm,-1,@DelDate),0)))
						END
						else	
							set @BillDate=DATEADD(DAY,-1,@BillDate)	
												
					END	
					else
					BEGIN
						set @BillingDay=''
						set @BillDate=DATEADD(DAY,1,@BillDate)
						set @StartDate=@BillDate 
							
						if(@DelDate>@BillDate)
							set @RetDays=datediff(day,@BillDate,@DelDate)
						
						set @BillDate=DATEADD(MONTH,1,@BillDate)
						set @BillDate=DATEADD(DAY,-1,@BillDate)
						
						if(@BillDate<@DelDate)
							continue;
					END	
					
					if(@BillDate>@tilldate)
						break;
					
					if(@BillDate>@RetDate)
					BEGIN					
						while(@RetDate<@BillDate)
						BEGIN
							if exists(select  a.InvDocDetailsID from INV_DocDetails a with(NOLOCK)
							join INV_DocDetails HD with(NOLOCK) on a.InvDocDetailsID=HD.LinkedInvDocDetailsID
							where a.InvDocDetailsID=@RetDetID and Hd.CostCenterID =@HDCCID)
							BEGIN													
								set @sql='select @RetDetID=isnull(HR.InvDocDetailsID,0),@ActRetDate=convert(datetime,HR.DocDate),@DelDate='
								if(@HDDeliveryDate like 'dcalpha%')
									set @sql =@sql+'HdT.'+@HDDeliveryDate
								else
									set @sql =@sql+'convert(datetime,Hd.'+@HDDeliveryDate+')'
									
								set @sql =@sql+',@Prodid=HD.ProductID from INV_DocDetails a with(NOLOCK)
								join INV_DocDetails HD with(NOLOCK) on a.InvDocDetailsID=HD.LinkedInvDocDetailsID '
								if(@HDDeliveryDate like 'dcalpha%')
									set @sql =@sql+' join COM_DocTextData HdT with(nolock) on Hd.InvDocDetailsID=HdT.InvDocDetailsID '
				
								set @sql =@sql+' left join INV_DocDetails HR with(NOLOCK) on HD.InvDocDetailsID=HR.LinkedInvDocDetailsID and HR.CostCenterID ='+convert(nvarchar,@HRCCID) +'
								where a.InvDocDetailsID='+convert(nvarchar,@RetDetID) +' and Hd.CostCenterID ='+convert(nvarchar,@HDCCID) 
								
								set @RetDetID=0
								set @ActRetDate=null	
								
								exec sp_executesql @sql,N'@RetDetID BIGINT OUTPUT,@ActRetDate datetime OUTPUT,@DelDate datetime OUTPUT,@Prodid BIGINT OUTPUT',@RetDetID OUTPUT,@ActRetDate OUTPUT,@DelDate OUTPUT,@Prodid OUTPUT
								
								
								if(@BillDate<@DelDate)
									set @RetDays=@RetDays+datediff(day,@RetDate,@BillDate)
								else	
									set @RetDays=@RetDays+datediff(day,@RetDate,@DelDate)
								
								set @RetDate=@ActRetDate
								
								if(@RetDate is null)				
									set @RetDate=@tilldate
							END
							ELSE
							BEGIN
								
								if(@offhireCCCID>0 and @RetDetID>0)
								BEGIN
									if exists(select a.InvDocDetailsID from INV_DocDetails a with(NOLOCK)
									where costcenterid=@offhireCCCID and LinkedInvDocDetailsID=@RetDetID)
										set @isOff=1
								END
								
								if(@isOff=1)
								BEGIN
								
									set @Actrate=@rate-((@rate/(datediff(day,@StartDate,@BillDate)+1))*(@RetDays+datediff(day,@RetDate,@BillDate)))

									set @BillDate=@RetDate
								END	
								else
									set @RetDays=@RetDays+datediff(day,@RetDate,@BillDate)
								break;
							END	
						END	
					END	
					
					if(@BillingDay is not null and @BillingDay<>'' and ISNUMERIC(@BillingDay)=1)
					BEGIN					
						set @Actrate=(datediff(day,@StartDate,@BillDate)+1-@RetDays)* (@rate/@BillingDay)
					END
					ELSE if(@RetDays>0 and @isOff is null)
					BEGIN
						set @Actrate=@rate-((@rate/(datediff(day,@StartDate,@BillDate)+1))*@RetDays)
					END
					else if(@isOff is null)
						set @Actrate=@rate
					
					
					if(@BillDate=@RetDate and @offhireCCCID>0 and @RetDetID>0)
					BEGIN
						if exists(select a.InvDocDetailsID from INV_DocDetails a with(NOLOCK)
						where costcenterid=@offhireCCCID and LinkedInvDocDetailsID=@RetDetID)
							set @isOff=1
					END	
					
					if not(@StartDate>@RetDate and @Actrate=0)							
						insert into #ResTab(InvDocDetailsID,Amount,ExlDays,Billdate,Fromdate,Todate,isoffhire,Prodid)
						values(@InvDocDetID,@Actrate,@RetDays,@BillDate,@StartDate,@BillDate,@isOff,@Prodid)
					
					if(@isOff=1)
						break;
					
				END
			END
			else if(@BillingCycle='Weekly')
			BEGIN
				
				set @BillDate=null
				
				WHILE(1=1)
				BEGIN
					
					set @RetDays=0
					
					if(@BillDate is not null and @RetDate<@BillDate)
							break;
					
					if(@BillDate is null)	
					BEGIN	
						set @StartDate=@DelDate 
						set @BillDate=DATEADD(day,6,@DelDate)
						
						if(@BillingDay is not null and @BillingDay<>'' and ISNUMERIC(@BillingDay)=1)
						BEGIN
							if(DATENAME(WEEKDAY,@DelDate)='sunday')
								set @RetDays=0
							else if(DATENAME(WEEKDAY,@DelDate)='monday')
								set @RetDays=1
							else if(DATENAME(WEEKDAY,@DelDate)='tuesday')
								set @RetDays=2
							else if(DATENAME(WEEKDAY,@DelDate)='wednesday')
								set @RetDays=3
							else if(DATENAME(WEEKDAY,@DelDate)='thursday')
								set @RetDays=4
							else if(DATENAME(WEEKDAY,@DelDate)='friday')
								set @RetDays=5
							else if(DATENAME(WEEKDAY,@DelDate)='saturday')
								set @RetDays=6
							
							if(CONVERT(int,@BillingDay)>@RetDays)
							BEGIN
								set @BillDate=DATEADD(DAY,CONVERT(int,@BillingDay)-@RetDays,@DelDate)							
							END
							ELSE
							BEGIN
								set @BillDate=@BillDate-@RetDays
								set @BillDate=@BillDate+CONVERT(int,@BillingDay)
							END	
							set @RetDays=0
						END
					END	
					else
					BEGIN
						set @BillingDay=''
						set @BillDate=DATEADD(DAY,1,@BillDate)
						set @StartDate=@BillDate 
							
						if(@DelDate>@BillDate)
							set @RetDays=datediff(day,@BillDate,@DelDate)
							
						set @BillDate=DATEADD(day,6,@BillDate)
						
						
						if(@BillDate<@DelDate)
							continue;
					END	
					
					if(@BillDate>@tilldate)
						break;
					
					if(@BillDate>@RetDate)
					BEGIN					
						while(@RetDate<@BillDate)
						BEGIN
							if exists(select  a.InvDocDetailsID from INV_DocDetails a with(NOLOCK)
							join INV_DocDetails HD with(NOLOCK) on a.InvDocDetailsID=HD.LinkedInvDocDetailsID
							where a.InvDocDetailsID=@RetDetID and Hd.CostCenterID =@HDCCID)
							BEGIN													
								set @sql='select @RetDetID=isnull(HR.InvDocDetailsID,0),@ActRetDate=convert(datetime,HR.DocDate),@DelDate='
								if(@HDDeliveryDate like 'dcalpha%')
									set @sql =@sql+'HdT.'+@HDDeliveryDate
								else
									set @sql =@sql+'convert(datetime,Hd.'+@HDDeliveryDate+')'
									
								set @sql =@sql+',@Prodid=HD.ProductID from INV_DocDetails a with(NOLOCK)
								join INV_DocDetails HD with(NOLOCK) on a.InvDocDetailsID=HD.LinkedInvDocDetailsID '
								if(@HDDeliveryDate like 'dcalpha%')
									set @sql =@sql+' join COM_DocTextData HdT with(nolock) on Hd.InvDocDetailsID=HdT.InvDocDetailsID '
				
								set @sql =@sql+' left join INV_DocDetails HR with(NOLOCK) on HD.InvDocDetailsID=HR.LinkedInvDocDetailsID and HR.CostCenterID ='+convert(nvarchar,@HRCCID) +'
								where a.InvDocDetailsID='+convert(nvarchar,@RetDetID) +' and Hd.CostCenterID ='+convert(nvarchar,@HDCCID) 
								
								set @RetDetID=0
								set @ActRetDate=null	
								
								exec sp_executesql @sql,N'@RetDetID BIGINT OUTPUT,@ActRetDate datetime OUTPUT,@DelDate datetime OUTPUT,@Prodid BIGINT OUTPUT',@RetDetID OUTPUT,@ActRetDate OUTPUT,@DelDate OUTPUT,@Prodid OUTPUT
								
								
								if(@BillDate<@DelDate)
									set @RetDays=@RetDays+datediff(day,@RetDate,@BillDate)
								else	
									set @RetDays=@RetDays+datediff(day,@RetDate,@DelDate)
									
								set @RetDate=@ActRetDate
								
								if(@RetDate is null)				
									set @RetDate=@tilldate
							END
							ELSE
							BEGIN
								if(@offhireCCCID>0 and @RetDetID>0)
								BEGIN
									if exists(select a.InvDocDetailsID from INV_DocDetails a with(NOLOCK)
									where costcenterid=@offhireCCCID and LinkedInvDocDetailsID=@RetDetID)
										set @isOff=1
								END
								if(@isOff=1)
								BEGIN
								
									set @Actrate=@rate-((@rate/(datediff(day,@StartDate,@BillDate)+1))*(@RetDays+datediff(day,@RetDate,@BillDate)))

									set @BillDate=@RetDate
								END	
								else	
									set @RetDays=@RetDays+datediff(day,@RetDate,@BillDate)							
								break;
							END	
						END	
					END	
										
					if(@BillingDay is not null and @BillingDay<>'' and ISNUMERIC(@BillingDay)=1)
					BEGIN					
						set @Actrate=(datediff(day,@StartDate,@BillDate)+1-@RetDays)* (@rate/7)
					END
					ELSE if(@RetDays>0 and @isOff is null)
					BEGIN
						set @Actrate=@rate-((@rate/(datediff(day,@StartDate,@BillDate)+1))*@RetDays)
					END
					else if(@isOff is null)
						set @Actrate=@rate
					
					if(@BillDate=@RetDate and @offhireCCCID>0 and @RetDetID>0)
					BEGIN
						if exists(select a.InvDocDetailsID from INV_DocDetails a with(NOLOCK)
						where costcenterid=@offhireCCCID and LinkedInvDocDetailsID=@RetDetID)
							set @isOff=1
					END		
						
					insert into #ResTab(InvDocDetailsID,Amount,Exldays,Billdate,Fromdate,Todate,isoffhire,Prodid)
					values(@InvDocDetID,@Actrate,@RetDays,@BillDate,@StartDate,@BillDate,@isOff,@Prodid)
					
					if(@isOff=1)
						break;
				END
			END
		END
		
		
		set @sql=''
		if(@SIVBIllDate like 'dcalpha%')
			set @sql=' select convert(datetime,HdT.'+@SIVBIllDate+') dt,i.LinkedInvDocDetailsID,i.VoucherNo into #tempbill from inv_docdetails i 
					join COM_DocTextData HdT with(nolock) on i.InvDocDetailsID=HdT.InvDocDetailsID where isdate(HdT.'+@SIVBIllDate+')=1 and i.CostCenterID='+convert(nvarchar,@SIVCCID)
					
		set @sql=@sql+' select distinct  a.*,c.voucherno BillNo'
			
		set @sql=@sql+',v.voucherno,v.debitaccount,convert(datetime,v.docdate) docdate,ac.accountname,p.productname 
		from #ResTab a
		join inv_docdetails v on a.InvDocDetailsID=v.InvDocDetailsID
		join acc_accounts ac on ac.accountid=v.debitaccount
		join inv_product p on p.productid=a.Prodid '
		if(@SIVBIllDate like 'dcalpha%')
			set @sql=@sql+'left join #tempbill as c on  a.InvDocDetailsID=c.LinkedInvDocDetailsID   and a.billdate=c.dt'
		else	
			set @sql=@sql+' left join inv_docdetails c on a.InvDocDetailsID=c.LinkedInvDocDetailsID and a.billdate=convert(datetime,c.'+@SIVBIllDate+') and c.costcenterid='+convert(nvarchar,@SIVCCID)
		
		--print @sql
		exec(@sql)
		
		select Name,Value from COM_CostCenterPreferences WITH(NOLOCK)
		where CostCenterID=164 and Name in('SIVDoc','HireContractDoc','SIVBillingDate','OffHireDoc')
		
		
		
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

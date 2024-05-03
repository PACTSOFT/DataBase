USE PACT2C222
GO
SET ANSI_NULLS, QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spSVC_CheckPartQuantities]
	@TicketID [bigint],
	@PIDs [nvarchar](200),
	@USERID [int],
	@LANGID [int]
WITH ENCRYPTION, EXECUTE AS CALLER
AS
BEGIN TRY  
SET NOCOUNT ON;
				declare @Qtyexists bit
				set @Qtyexists=0
		create table  #producttable (pid bigint)

		insert into  #producttable 
		EXEC SPSplitString @PIDs,','
		
		declare @i int, @cnt int, @partid bigint , @productid bigint, @CCTicketID bigint,@locid bigint
		select @CCTicketID=ccticketid,@locid=locationid from svc_serviceticket where serviceticketid=@TicketID

		create table #tempdocdetails(id int identity(1,1), Partid bigint, Productid bigint, balqty float, sno int)

		insert into #tempdocdetails ( partid, Productid , sno)
		select p.partid, p.productid, p.SerialNumber  from svc_serviceticket t with(nolock)
		join  svc_servicepartsinfo p with(nolock) on p.serviceticketid=t.serviceticketid
		join #producttable temp on p.productid=temp.pid
		where p.serviceticketid=@TicketID
		
		
		select @cnt=count(*) from #tempdocdetails
		set @i=1
		while @i<=@cnt
		begin
			declare  @balqty float, @podqty float, @pocqty float, @grcqty float, @pivrqty float, @miqty float
			select @partid=partid, @productid=productid from #tempdocdetails where id=@i
		 
			--select @balqty=sum(quantity*Vouchertype) from inv_docdetails i with(nolock)
			--left join com_Docccdata cc with(nolock) on i.invdocdetailsid=cc.invdocdetailsid
			--where cc.dcccnid42=@CCTicketID and cc.dcccnid2=@locid and i.productid=@productid  and i.isqtyignored=0
			set @balqty= 0
			set @podqty =0
			set @pocqty=0 
			set @grcqty=0 
			set @pivrqty =0 
			set @miqty=0
			--select * from ADM_DocumentTypes
			select * from inv_docdetails i with(nolock)
			left join com_Docccdata cc with(nolock) on i.invdocdetailsid=cc.invdocdetailsid
			where cc.dcccnid42=@CCTicketID and cc.dcccnid2=@locid and i.productid=@productid  and i.costcenterid=41009
			--Service purchase order quantity
			select @podqty=sum(quantity) from inv_docdetails i with(nolock)
			left join com_Docccdata cc with(nolock) on i.invdocdetailsid=cc.invdocdetailsid
			where cc.dcccnid42=@CCTicketID and cc.dcccnid2=@locid and i.productid=@productid  and i.costcenterid=41009
			--Service purchase order cancellation quantity
			select @pocqty=sum(quantity) from inv_docdetails i with(nolock)
			left join com_Docccdata cc with(nolock) on i.invdocdetailsid=cc.invdocdetailsid
			where  cc.dcccnid42=@CCTicketID and  cc.dcccnid2=@locid and i.productid=@productid  and i.costcenterid=41001
			--Service good received cancellation quantity
			select @grcqty=sum(quantity) from inv_docdetails i with(nolock)
			left join com_Docccdata cc with(nolock) on i.invdocdetailsid=cc.invdocdetailsid
			where  cc.dcccnid42=@CCTicketID and  cc.dcccnid2=@locid and i.productid=@productid  and i.costcenterid=41005
			--Service purchase return cancellation quantity
			select @pivrqty=sum(quantity) from inv_docdetails i with(nolock)
			left join com_Docccdata cc with(nolock) on i.invdocdetailsid=cc.invdocdetailsid
			where cc.dcccnid42=@CCTicketID and   cc.dcccnid2=@locid and i.productid=@productid  and i.costcenterid=41010
			--Service Material Issue
			select @miqty=sum(quantity) from inv_docdetails i with(nolock)
			left join com_Docccdata cc with(nolock) on i.invdocdetailsid=cc.invdocdetailsid
			where  cc.dcccnid42=@CCTicketID and  cc.dcccnid2=@locid and i.productid=@productid  and i.costcenterid=41006
			
			set @balqty= @podqty-(isnull(@pocqty,0)+isnull(@grcqty,0)+isnull(@pivrqty,0)+isnull(@miqty,0))
			select @podqty,(isnull(@pocqty,0)),isnull(@grcqty,0),isnull(@pivrqty,0),isnull(@miqty,0)
			--print @podqty 
			--print @pocqty
			--print @grcqty
			--print @pivrqty
			--print @miqty
			if(@balqty is null)
				set @balqty=0
			else if(@balqty>0 and @Qtyexists=0)
				set @Qtyexists=1
			
			update #tempdocdetails set balqty=@balqty  where id=@i 
			set @i=@i+1
		end
		
		 drop table #producttable 
		
 
SET NOCOUNT OFF;  
select CONVERT(bit, @Qtyexists) 
select * from #tempdocdetails
drop table #tempdocdetails 
END TRY  
BEGIN CATCH  
	--Return exception info [Message,Number,ProcedureName,LineNumber]  
	IF ERROR_NUMBER()=50000
	BEGIN		  
		SELECT ErrorMessage,ErrorNumber FROM COM_ErrorMessages WITH(NOLOCK) WHERE ErrorNumber=ERROR_MESSAGE() AND LanguageID=@LangID
	END
	ELSE
	BEGIN
		SELECT ErrorMessage, ERROR_MESSAGE() AS ServerMessage,ERROR_NUMBER() AS ErrorNumber, ERROR_PROCEDURE()AS ProcedureName, ERROR_LINE() AS ErrorLine
		FROM COM_ErrorMessages WITH(NOLOCK) WHERE ErrorNumber=-999 AND LanguageID=@LangID
	END
	 
	SET NOCOUNT OFF  
	RETURN -999   
END CATCH


GO

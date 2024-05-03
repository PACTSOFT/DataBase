USE PACT2C222
GO
SET ANSI_NULLS, QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spSVC_GetStoresDataByTicketID]
	@TicketID [bigint] = 0,
	@LocationID [bigint] = 0,
	@SType [int] = 0,
	@IsQOH [bit] = 0,
	@UserID [bigint],
	@RoleID [int],
	@LangID [int] = 1
WITH ENCRYPTION, EXECUTE AS CALLER
AS
BEGIN TRY  
SET NOCOUNT ON;
	DECLARE @CCLink INT,@SQLIndent NVARCHAR(MAX),@CCTicketsID bigint, @SQLIssue NVARCHAR(MAX)
	DECLARE @CCXML nvarchar(max), @CCTicketIDS nvarchar(max)
			 
	SELECT @CCLink=Value FROM COM_CostCenterPreferences WITH(NOLOCK) WHERE FeatureID=59 AND Name = 'ServiceTicketLinkCostCenter'
	IF @CCLink=0
	BEGIN
		SELECT 1 WHERE 1<>1
		ROLLBACK TRANSACTION
		RETURN 1
		--RAISERROR('-105',16,1) 
	END
		declare @IndentCostcenterid bigint, @ProcureCostcenterID bigint, @IssueCostcenterID bigint
		declare @ReceiveCostcenterid bigint, @ReturnReqCCID bigint
		
		 
	select  @IndentCostcenterid=value from COM_CostCenterPreferences WITH(NOLOCK)  where costcenterid=59 and  Name like 'ServiceIndentDocument' 
	select  @IssueCostcenterID=value from COM_CostCenterPreferences WITH(NOLOCK) where costcenterid=59 and Name like 'ServiceMaterialIssueDocument' 		  
	select  @ProcureCostcenterID=value from COM_CostCenterPreferences WITH(NOLOCK) where costcenterid=59 and Name like 'MaterialProcureDocument' 		  
	select  @ReceiveCostcenterid=value from COM_CostCenterPreferences WITH(NOLOCK) where costcenterid=59 and Name like 'Materialreceivedocument' 		  
	select  @ReturnReqCCID=value from COM_CostCenterPreferences WITH(NOLOCK) where costcenterid=59 and Name like 'ServiceReturnRequestDocument' 		  
				
		 
		
		
		SET @CCLink=@CCLink-50000
		create table #ticketids(id int identity(1,1), CCTicketID int)
		 
		declare @Tcnt int, @j int,@tempid int
		set @j=1
		set @tempid=0
		--Declaration Section
		DECLARE @HasAccess BIT 
		if(@TicketID<>0)  
		begin
			insert into #ticketids(CCTicketID)
			select CCTicketID from svc_ServiceTicket WITH(NOLOCK) WHERE SERVICETICKETID= @TicketID and servicetickettypeid=2 and Locationid=@LocationID
	 	end
		else
		begin   
			insert into #ticketids(CCTicketID)
			select CCTicketID from svc_ServiceTicket WITH(NOLOCK) WHERE servicetickettypeid=2 and Locationid=@LocationID
		end	 
		--to get Stores Indent data based on TicketID
		--SET @SQLIndent='
		SELECT VoucherNo as IndentNumber, ProductID,Quantity DesiredQty,
		T.Rate, T.InvDocDetailsID,T.DocSeqNo,T.CreditAccount,T.Unit as UOMID, T.RefCCID,T.RefNodeID,
		ST.ServiceTicketNumber as TicketNumber
		FROM INV_DocDetails T WITH(NOLOCK)
		LEFT JOIN COM_DocCCData C WITH(NOLOCK) ON T.InvDocDetailsID=C.InvDocDetailsID
		left join SVC_SERVICETICKET ST WITH(NOLOCK) ON dcCCNID42=st.ccticketid  
	 	WHERE T.COSTCENTERID=@IndentCostcenterid and
	 	(c.dcCCNID42 in ( select CCTicketid from #ticketids) and c.dcCCNID42 is not null)
		and (T.RefCCID is not null and T.RefCCID >0)
		--GROUP BY VoucherNo,ProductID,C.dcCCNID29, ST.ServiceTicketNumber, T.Rate, T.InvDocDetailsID,T.DocSeqNo,T.CreditAccount, T.Unit,T.RefCCID,T.RefNodeID 
 
		--print @SQLIndent
		
		--exec (@SQLIndent)
		if(@SType=4)
			SELECT distinct(T.ProductID),T.Quantity-isnull(L.Quantity,0) IssueQty , T.VoucherNo as IssueNumber,
			ST.ServiceTicketNumber as TicketNumber, L.VoucherNo as RefNo, T.CreditAccount,T.DebitAccount,
			T.InvDocDetailsID as IssueInvDocDetailsID, T.Rate, T.DocSeqNo,T.Unit as UOMID, T.RefCCID,T.RefNodeID
			FROM INV_DocDetails T WITH(NOLOCK)
			LEFT JOIN COM_DocCCData C WITH(NOLOCK) ON T.InvDocDetailsID=C.InvDocDetailsID
			left join inv_docdetails L WITH(NOLOCK) on L.LinkedInvDocDetailsID =T.InvDocDetailsID
			left join SVC_SERVICETICKET ST WITH(NOLOCK) ON dcCCNID42=st.ccticketid 
			WHERE T.COSTCENTERID=@ReturnReqCCID and
			(c.dcCCNID42 in ( select CCTicketid from #ticketids  ) and c.dcCCNID42 is not null) 
			and (T.Quantity-isnull(L.Quantity,0))>0
		else 
		 	SELECT T.ProductID, sum(T.Quantity) IssueQty, --T.VoucherNo as IssueNumber,
			ST.ServiceTicketNumber as TicketNumber, L.VoucherNo as RefNo, T.CreditAccount,T.DebitAccount,
			--T.InvDocDetailsID as IssueInvDocDetailsID,T.Rate, 
			T.DocSeqNo,T.Unit as UOMID, T.RefCCID,T.RefNodeID
			FROM INV_DocDetails T WITH(NOLOCK)
			LEFT JOIN COM_DocCCData C WITH(NOLOCK) ON T.InvDocDetailsID=C.InvDocDetailsID
			left join inv_docdetails L WITH(NOLOCK) on L.invdocdetailsid =T.LinkedInvDocDetailsID
			left join SVC_SERVICETICKET ST WITH(NOLOCK) ON dcCCNID42=st.ccticketid 
			WHERE T.COSTCENTERID=@IssueCostcenterID and (c.dcCCNID42 in ( select CCTicketid from #ticketids  ) and c.dcCCNID42 is not null) 
			group by l.Voucherno, t.creditaccount, t.debitaccount, t.productid,t.unit, t.refccid, t.refnodeid,ST.ServiceTicketNumber, T.DocSeqNo
		--	SELECT distinct(T.ProductID),T.Quantity IssueQty, T.VoucherNo as IssueNumber,
		--	ST.ServiceTicketNumber as TicketNumber, L.VoucherNo as RefNo, T.CreditAccount,T.DebitAccount,
		--	T.InvDocDetailsID as IssueInvDocDetailsID, T.Rate, T.DocSeqNo,T.Unit as UOMID, T.RefCCID,T.RefNodeID, T.CostCenterID
		--	FROM INV_DocDetails T WITH(NOLOCK)
		--	LEFT JOIN COM_DocCCData C WITH(NOLOCK) ON T.InvDocDetailsID=C.InvDocDetailsID
		--	left join inv_docdetails L WITH(NOLOCK) on L.invdocdetailsid =T.LinkedInvDocDetailsID
		--	left join SVC_SERVICETICKET ST WITH(NOLOCK) ON dcCCNID42=st.ccticketid 
		--	WHERE T.COSTCENTERID=@IssueCostcenterID and
		--	(c.dcCCNID42 in ( select CCTicketid from #ticketids  ) and c.dcCCNID42 is not null)
		----GROUP BY T.ProductID, C.dcCCNID29, ST.ServiceTicketNumber,T.VoucherNo, L.VoucherNo, T.InvDocDetailsID, T.Rate, T.DocSeqNo,T.Unit, T.RefCCID,T.RefNodeID,T.DebitAccount , T.CreditAccount

		--Getting Other information 
		 SELECT ST.ServiceTicketNumber as TicketNumber, T.VoucherNo as IndentNumber,T.InvDocDetailsID,
		v.make +' - '+v.model+' - '+v.variant +
		case when (cv.Year is null ) then ('') else ( ' - ' +convert(nvarchar,cv.Year)) end as Vehicle,cv.VehicleID,
	 	CASE WHEN (Product.NodeID=1) then ('-') else (Product.Name)  end as Product, 
		Product.Nodeid as Product_Key, 
		P.PRODUCTCODE AS PartCode,T.ProductID as PartCode_Key,  T.UOMConversion, T.UOMConvertedQty as UOMConversionQty,
		case when (Manu.NodeID=1) then '-' else Manu.Code end AS Manufacturer, ST.CCTicketID,
		case when (Cat.NodeID=1) then '-' else Cat.Name end AS Category,UOM.UnitName ,UOM.UOMID, UOM.UOMID as UnitName_Key,
		   PE.ptAlpha1, PE.ptAlpha2,PE.ptAlpha3,PE.ptAlpha4,PE.ptAlpha5,PE.ptAlpha6,PE.ptAlpha7,PE.ptAlpha8,PE.ptAlpha9,PE.ptAlpha10
		  ,PE.ptAlpha11,PE.ptAlpha12,PE.ptAlpha13,PE.ptAlpha14,PE.ptAlpha15,PE.ptAlpha16,PE.ptAlpha17 ,PE.ptAlpha18 , PE.ptAlpha19 ,PE.ptAlpha20
		  ,PE.ptAlpha21,PE.ptAlpha22,PE.ptAlpha23,PE.ptAlpha24,PE.ptAlpha25,PE.ptAlpha26,PE.ptAlpha27,PE.ptAlpha28,PE.ptAlpha29,PE.ptAlpha30
		  ,PE.ptAlpha31,PE.ptAlpha32,PE.ptAlpha33,PE.ptAlpha34,PE.ptAlpha35,PE.ptAlpha36,PE.ptAlpha37,PE.ptAlpha38,PE.ptAlpha39,PE.ptAlpha40
		  ,PE.ptAlpha41,PE.ptAlpha42,PE.ptAlpha43,PE.ptAlpha44,PE.ptAlpha45,PE.ptAlpha46,PE.ptAlpha47,PE.ptAlpha48,PE.ptAlpha49,PE.ptAlpha50,
		  ccmap.CCNID49 AS Sponsor, cv.RegNumberNodeID, cv.RegCCID 
		FROM INV_DocDetails T WITH(NOLOCK)
		LEFT JOIN COM_DocCCData C WITH(NOLOCK) ON T.InvDocDetailsID=C.InvDocDetailsID
		LEFT JOIN INV_PRODUCT P WITH(NOLOCK) ON T.PRODUCTID=P.PRODUCTID
		LEFT JOIN INV_PRODUCTEXTENDED PE WITH(NOLOCK) ON P.PRODUCTID=PE.PRODUCTID
		left join com_uom uom WITH(NOLOCK) on T.Unit=uom.UOMID
		LEFT JOIN COM_CCCCDATA CCDATA WITH(NOLOCK) ON CCDATA.NODEID=T.PRODUCTID AND CCDATA.COSTCENTERID=3
		LEFT JOIN COM_CC50029 Product WITH(NOLOCK) ON Product.NODEID=c.dcCCNID29 
		LEFT JOIN COM_CCCCDATA CCProductData WITH(NOLOCK) ON CCProductData.NODEID=Product.NodeID AND CCProductData.COSTCENTERID=50029
		LEFT JOIN COM_CC50023 Manu WITH(NOLOCK) ON Manu.NODEID=CCDATA.CCNID23 and CCDATA.CostCenterID = 3
		LEFT JOIN COM_Category Cat WITH(NOLOCK) ON Cat.NODEID=CCProductData.CCNID6  
		left join SVC_SERVICETICKET ST WITH(NOLOCK) ON ST.CCTICKETID=C.DCCCNID42
		LEFT JOIN SVC_CUSTOMERSVEHICLE CV WITH(NOLOCK) ON st.CustomerVehicleID= cv.CV_ID
		LEFT JOIN SVC_CUSTOMERS CUS WITH(NOLOCK) ON CV.CustomerID= CUS.CustomerID
		left join SVC_CustomerCostCenterMap ccmap WITH(NOLOCK) on CUS.CUSTOMERID= CCMAP.CustomerID
		left join svc_vehicle v WITH(NOLOCK) on cv.Vehicleid=v.vehicleid 
		WHERE  T.COSTCENTERID=@IndentCostcenterID and
		c.dcCCNID42 in ( select CCTicketid from #ticketids  ) and T.RefCCID is not null and T.RefCCID>0
	 	 
		select  SysColumnName, UserColumnName from adm_Costcenterdef WITH(NOLOCK) 
		where costcenterid=3 and (usercolumnname LIKE '%billable%' or usercolumnname LIKE 'bill%')
			 
		create table #temp(id int identity(1,1), ProductID bigint, LocationID bigint, QOH float)
		Insert into #temp(ProductID, LocationID,QOH)
		SELECT ProductID,@LocationID,0
		FROM INV_DocDetails T WITH(NOLOCK)
		LEFT JOIN COM_DocCCData C WITH(NOLOCK) ON T.InvDocDetailsID=C.InvDocDetailsID
		LEFT JOIN SVC_SERVICETICKET ST WITH(NOLOCK) ON dcCCNID42=st.ccticketid
	 	WHERE  T.COSTCENTERID=@IndentCostcenterID and c.dcCCNID42 IN (select CCTicketid from #ticketids)
 
		if(@IsQOH=1)
			begin
			declare @i int,@cnt int, @ProductID bigint,@DocDate datetime,@QOH float,@HOLDQTY float, @RESERVEQTY float, @AvgRate float,@CommittedQTY float,@BalQOH float
			set @i=1
			set @CCXML='<XML><Row CostCenterID="50002" NODEID="'+convert(nvarchar,@LocationID)+'" /></XML>'
	 		select @cnt=count(*) from #temp
	 		set @DocDate=getdate() 
			while @i<=@cnt
			begin
				select @ProductID=productid from #temp where id=@i 
				if((select isnull(value,0) from com_costcenterpreferences where costcenterid=3 and Name like 'TempPartProduct')<>@ProductID)			
					EXEC [spDOC_StockAvgValue] @ProductID,@CCXML,@DocDate,0,0,0, 1,0,0,0,0  ,@QOH OUTPUT,@HOLDQTY OUTPUT,@CommittedQTY output,@RESERVEQTY OUTPUT,@AvgRate OUTPUT,@BalQOH  OUTPUT   
				else
					set @QOH=0
				update #temp set QOH=@QOH where productid=@ProductID and id=@i
				set @i=@i+1
			end 
		end
		select * from #temp 
				 
		if(@SType=1)
		begin 	
				select DocumentLinkDefID, CostcenterColIDLinked,C.UserColumnName, C.SysColumnName  from [COM_DocumentLinkDef] DL WITH(NOLOCK) 
				LEFT JOIN ADM_COSTCENTERDEF C WITH(NOLOCK) ON C.CostcenterColID= DL.CostcenterColIDLinked
				where Costcenteridbase=@IssueCostcenterid and Costcenteridlinked =@IndentCostcenterid
		end
		else if(@SType=2)
		begin  
				select DocumentLinkDefID, CostcenterColIDLinked,C.UserColumnName, C.SysColumnName  from [COM_DocumentLinkDef] DL WITH(NOLOCK) 
				LEFT JOIN ADM_COSTCENTERDEF C WITH(NOLOCK)  ON C.CostcenterColID= DL.CostcenterColIDLinked
				where Costcenteridbase=@ProcureCostcenterID and Costcenteridlinked =@IndentCostcenterid
		end
		else if(@SType=3)
		begin 
				select DocumentLinkDefID, CostcenterColIDLinked,C.UserColumnName, C.SysColumnName  from [COM_DocumentLinkDef] DL WITH(NOLOCK) 
				LEFT JOIN ADM_COSTCENTERDEF C WITH(NOLOCK) ON C.CostcenterColID= DL.CostcenterColIDLinked
				where Costcenteridbase=59 and Costcenteridlinked =@IssueCostcenterid
		end 
		else if(@SType=4)
		begin 
				select DocumentLinkDefID, CostcenterColIDLinked,C.UserColumnName, C.SysColumnName  from [COM_DocumentLinkDef] DL WITH(NOLOCK) 
				LEFT JOIN ADM_COSTCENTERDEF C WITH(NOLOCK) ON C.CostcenterColID= DL.CostcenterColIDLinked
				where Costcenteridbase=@ReceiveCostcenterid and Costcenteridlinked =@ReturnReqCCID
		end 
		
		--SET @SQLReturn='
		SELECT T.ProductID,T.Quantity IssueQty, T.VoucherNo as IssueNumber,
		ST.ServiceTicketNumber as TicketNumber, L.VoucherNo as RefNo, T.CreditAccount,T.DebitAccount,
		T.InvDocDetailsID as IssueInvDocDetailsID, T.Rate, T.DocSeqNo,T.Unit as UOMID, T.RefCCID,T.RefNodeID
		FROM INV_DocDetails T WITH(NOLOCK)
		LEFT JOIN COM_DocCCData C WITH(NOLOCK) ON T.InvDocDetailsID=C.InvDocDetailsID
		left join inv_docdetails L WITH(NOLOCK) on L.invdocdetailsid =T.LinkedInvDocDetailsID
		left join SVC_SERVICETICKET ST WITH(NOLOCK) ON dcCCNID42=st.ccticketid
		WHERE T.CostCenterID = @ReceiveCostcenterid
		AND (dcCCNID42 in ( select CCTicketid from #ticketids  ) and dcCCNID42 is not null)
		--GROUP BY T.ProductID, ST.ServiceTicketNumber,T.VoucherNo, L.VoucherNo, T.InvDocDetailsID, T.Rate, T.DocSeqNo,T.Unit, T.RefCCID,T.RefNodeID,T.DebitAccount , T.CreditAccount
		
		select CCTicketid from #ticketids			
		drop table #temp
		drop table #ticketids 
		
		--Getting Workflows  
		SELECT distinct [WorkFlowDefID],[CostCenterID],[Action],[Expression],a.WorkFlowID  
		FROM [COM_WorkFlowDef]  a  WITH(NOLOCK)
		join COM_WorkFlow b  WITH(NOLOCK) on a.WorkFlowID=b.WorkFlowID  
		left join COM_Groups g WITH(NOLOCK) on b.GroupID=g.GID
		where IsEnabled=1 and (b.UserID =@UserID or b.roleid=@RoleID  
		or g.roleid=@RoleID)
	   
	   select value from com_costcenterpreferences WITH(NOLOCK) where costcenterid=3 and Name like 'TempPartProduct'		 
				 
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
SET NOCOUNT OFF  
RETURN -999   
END CATCH 



GO

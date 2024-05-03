USE PACT2C222
GO
SET ANSI_NULLS, QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spSVC_GetProductCategory]
	@ProductID [bigint] = 0,
	@LocationID [bigint],
	@VehicleID [bigint] = 0,
	@PartID [bigint] = 0,
	@Sponsor [bigint] = 1,
	@IsQOH [bit] = 0,
	@UserID [bigint],
	@LangID [int] = 1
WITH ENCRYPTION, EXECUTE AS CALLER
AS
BEGIN TRY  
SET NOCOUNT ON;	
 
	DECLARE @ProductType BIGINT,@CategoryID BIGINT

	SELECT  @ProductType=P.ProductTypeID
	FROM INV_Product P WITH(NOLOCK)
	WHERE P.ProductID=@ProductID
	
	if(@Sponsor=0)
		set @Sponsor=1
	
	if(@PartID=0)
		SELECT @CategoryID =CategoryID FROM Inv_Product WITH(NOLOCK)WHERE ProductID=@ProductID
	else
		select @CategoryID = ccnid6 from COM_CCCCDATA WITH(NOLOCK) WHERE COSTCENTERID=50029 AND NODEID=@PartID
		
	IF(@PartID=0)
		SELECT @PartID=CCNID29 FROM COM_CCCCDATA WITH(NOLOCK)WHERE COSTCENTERID=3 AND NODEID=@ProductID
		
	
	--TO GET PRODUCT MASTER DATA
	--SELECT C.NodeID,C.Code,C.Name,P.ProductName PartName,P.ProductCode PartCode,
	--	P.ProductTypeID,ISNULL((SELECT Top 1 ResourceData FROM COM_LanguageResources WHERE ResourceID=INV_ProductTypes.ResourceID AND LanguageID=@LangID),INV_ProductTypes.ProductType) ProductType,
	--	ISNULL(P.SellingRate,0) Rate, COM_CC50023.Code AS Manufacturer
	--FROM INV_Product P WITH(NOLOCK)
	--LEFT JOIN INV_ProductTypes WITH(NOLOCK) ON INV_ProductTypes.ProductTypeID=P.ProductTypeID
	--LEFT JOIN INV_ProductCostCenterMap ON INV_ProductCostCenterMap.PRODUCTID=P.ProductID
	--LEFT JOIN COM_CC50023 ON COM_CC50023.NODEID=INV_ProductCostCenterMap.CCNID23
	--LEFT JOIN COM_Category C WITH(NOLOCK) ON P.CategoryID=C.NodeID
	--WHERE P.ProductID=@ProductID

	SELECT C.NodeID,C.Code,C.Name,P.ProductName PartName,P.ProductCode PartCode,
		P.ProductTypeID,ISNULL((SELECT Top 1 ResourceData FROM COM_LanguageResources WHERE ResourceID=INV_ProductTypes.ResourceID AND LanguageID=@LangID),INV_ProductTypes.ProductType) ProductType,
		ISNULL(P.SellingRate,0) Rate,isnull(P.PurchaseRate,0) PurchaseRate,
		case when (COM_CC50023.NodeID=1) then '-' else COM_CC50023.Code end AS Manufacturer, COM_CC50023.NodeID as Manufacturer_Key,
		COM_CC50029.Name AS Product,COM_CC50029.NodeID AS ProductID, P.UOMID, COM_UOM.UnitName UOM,
		   COM_CC50029.[ccAlpha1] ,COM_CC50029.[ccAlpha2],COM_CC50029.[ccAlpha3],COM_CC50029.[ccAlpha4],COM_CC50029.[ccAlpha5],
		   COM_CC50029.[ccAlpha6],COM_CC50029.[ccAlpha7], COM_CC50029.[ccAlpha8],COM_CC50029.[ccAlpha9],COM_CC50029.[ccAlpha10]
      ,COM_CC50029.[ccAlpha11],COM_CC50029.[ccAlpha12],COM_CC50029.[ccAlpha13],COM_CC50029.[ccAlpha14],COM_CC50029.[ccAlpha15]
      ,COM_CC50029.[ccAlpha16],COM_CC50029.[ccAlpha17],COM_CC50029.[ccAlpha18],COM_CC50029.[ccAlpha19],COM_CC50029.[ccAlpha20]
      ,COM_CC50029.[ccAlpha21],COM_CC50029.[ccAlpha22],COM_CC50029.[ccAlpha23],COM_CC50029.[ccAlpha24],COM_CC50029.[ccAlpha25]
      ,COM_CC50029.[ccAlpha26],COM_CC50029.[ccAlpha27],COM_CC50029.[ccAlpha28],COM_CC50029.[ccAlpha29],COM_CC50029.[ccAlpha30]
      ,COM_CC50029.[ccAlpha31],COM_CC50029.[ccAlpha32],COM_CC50029.[ccAlpha33],COM_CC50029.[ccAlpha34],COM_CC50029.[ccAlpha35]
      ,COM_CC50029.[ccAlpha36],COM_CC50029.[ccAlpha37],COM_CC50029.[ccAlpha38],COM_CC50029.[ccAlpha39],COM_CC50029.[ccAlpha40]
      ,COM_CC50029.[ccAlpha41],COM_CC50029.[ccAlpha42],COM_CC50029.[ccAlpha43],COM_CC50029.[ccAlpha44],COM_CC50029.[ccAlpha45]
      ,COM_CC50029.[ccAlpha46],COM_CC50029.[ccAlpha47],COM_CC50029.[ccAlpha48],COM_CC50029.[ccAlpha49],COM_CC50029.[ccAlpha50] 
	  ,PV.VehicleID
	FROM INV_Product P WITH(NOLOCK)
	LEFT JOIN INV_ProductExtended PE WITH(NOLOCK) ON PE.ProductID=P.ProductID
	LEFT JOIN INV_ProductTypes WITH(NOLOCK) ON INV_ProductTypes.ProductTypeID=P.ProductTypeID
	LEFT JOIN COM_CCCCDATA ON COM_CCCCDATA.NodeID=P.ProductID and COM_CCCCDATA.CostCenterID = 3
	LEFT JOIN COM_CC50023 ON COM_CC50023.NODEID=COM_CCCCDATA.CCNID23 and COM_CCCCDATA.CostCenterID = 3
	LEFT JOIN COM_Category C WITH(NOLOCK) ON C.NodeID=@CategoryID
	--in (select top 1 ccnid6 from   COM_CCCCData where CostCenterID=50029 and NodeID=@PartID)
	LEFT JOIN COM_UOM WITH(NOLOCK) ON COM_UOM.UOMID=P.UOMID
	LEFT JOIN COM_CC50029 WITH(NOLOCK)ON COM_CC50029.NODEID=@PartID  
	LEFT JOIN SVC_PRODUCTVEHICLE PV WITH(NOLOCK)ON PV.ProductID=P.ProductID
	WHERE P.ProductID=@ProductID 

	--print @Sponsor
	--print @CategoryID
	--print @LocationID
	--print	@PartID
	--SHOP SUPPLIES DISCOUNT
	if(@Sponsor=1)
	begin 
		SELECT TOP 1 ProductPercentage,ProductAmount , LabPercentage,LabAmt
		FROM SVC_ShopSupplies WITH(NOLOCK) 
		WHERE Category=@CategoryID AND WEF<=CONVERT(FLOAT,getdate()) AND Location=@LocationID
		ORDER BY WEF DESC
	end
	else if(@Sponsor>1)
	begin
		print @CategoryID
		declare @ccAlpha1 varchar(11)
		select @ccAlpha1 =isnull(ccAlpha1,'Y') from com_cc50049 where Nodeid=@Sponsor
		if (@ccAlpha1='Y' OR @ccAlpha1='y')
			SELECT TOP 1 ProductPercentage,ProductAmount , LabPercentage,LabAmt
			FROM SVC_ShopSupplies WITH(NOLOCK) 
			WHERE Category=@CategoryID AND WEF<=CONVERT(FLOAT,getdate()) AND Location=@LocationID
			ORDER BY WEF DESC
		else  if (@ccAlpha1='N' OR @ccAlpha1='n')
				SELECT TOP 1 0 ProductPercentage,0 ProductAmount , 0 LabPercentage,0 LabAmt
			FROM SVC_ShopSupplies WITH(NOLOCK) 
			WHERE Category=@CategoryID AND WEF<=CONVERT(FLOAT,getdate()) AND Location=@LocationID
			ORDER BY WEF DESC
		else
			SELECT TOP 1 0 ProductPercentage,0 ProductAmount , 0 LabPercentage,0 LabAmt
	end
	declare @Tier bigint
	select @Tier =FeatureID-50000 from adm_Features WITH(NOLOCK) where name like 'Tier%'

	--COSTCENTER WISE RATE 
	if(@PartID>0) 
			SELECT * 
			FROM COM_CCPrices WITH(NOLOCK)
			WHERE WEF<=CONVERT(FLOAT,GETDATE()) AND ProductID=@ProductID 
			AND CCNID11 in (select CCNID11 from COM_CCCCData WITH(NOLOCK)where  costcenterid=50002 and nodeid=@LocationID)
			--AND CCNID29 IN (SELECT CCNID29 FROM COM_CCCCDATA WHERE COSTCENTERID=3 AND NODEID=@ProductID)
			AND CCNID29 =@PartID
			and CCNID24 IN (SELECT SEGMENTID FROM SVC_VEHICLE WITH(NOLOCK) WHERE VEHICLEID=@VehicleID)   
			ORDER BY WEF DESC  
	else 
			SELECT * FROM COM_CCPrices WITH(NOLOCK)
			WHERE WEF<=CONVERT(FLOAT,GETDATE()) AND ProductID=@ProductID 
			AND CCNID11 in (select CCNID11 from COM_CCCCData WITH(NOLOCK) where  costcenterid=50002 and nodeid=@LocationID) 
			AND CCNID29 IN (SELECT CCNID29 FROM COM_CCCCDATA WITH(NOLOCK) WHERE COSTCENTERID=3 AND NODEID=@ProductID) 
			and CCNID24 IN (SELECT SEGMENTID FROM SVC_VEHICLE WITH(NOLOCK) WHERE VEHICLEID=@VehicleID)   
			ORDER BY WEF DESC 

	--TAX DETAILS
	DECLARE @I INT,@COUNT INT,@ColID BIGINT,@Value FLOAT
	DECLARE @TblCols TABLE(ID INT IDENTITY(1,1), ColID BIGINT,[Value] FLOAT)

	--added by pranathi for vat default if value does not exists as 14.5
	declare @VatColID bigint
	select @VatColID =	  costcentercolid from adm_costcenterdef c  WITH(NOLOCK) 
	join com_languageresources l  WITH(NOLOCK)  on c.resourceid=l.resourceid AND L.LANGUAGEID=1
	where costcenterid=59 and l.RESOURCEDATA='VAT' AND SYSCOLUMNNAME LIKE 'dcNum%'
	
	INSERT INTO @TblCols(ColID)
	SELECT CostCenterColID FROM ADM_DocumentDef WITH(NOLOCK) WHERE CostCenterID=59

	SELECT @I=1,@COUNT=COUNT(*) FROM @TblCols

	WHILE(@I<=@COUNT)
	BEGIN
		SELECT @ColID=ColID,@Value=NULL FROM @TblCols WHERE ID=@I

	if (exists (SELECT TOP 1 [Value] FROM COM_CCTaxes WITH(NOLOCK) WHERE WEF<=CONVERT(FLOAT,GETDATE()) AND ColID=@ColID AND (CCNID2=@LocationID  and ProductID=@ProductID )))
	begin
		SELECT TOP 1 @Value=[Value] FROM COM_CCTaxes WITH(NOLOCK) WHERE WEF<=CONVERT(FLOAT,GETDATE()) AND ColID=@ColID 
		AND (CCNID2=@LocationID  and ProductID=@ProductID)	ORDER BY WEF DESC
	end
	--else
	--begin
	--	SELECT TOP 1 @Value=[Value] FROM COM_CCTaxes WITH(NOLOCK) WHERE WEF<=CONVERT(FLOAT,GETDATE()) AND ColID=@ColID 
	--	AND (CCNID2=@LocationID  or ProductID=@ProductID)	ORDER BY WEF DESC
	--end
	 
		IF(@Value is null and @VatColID =@ColID and @ProductType=1)
			set @Value=14.5  
			
		IF @Value IS NULL
			DELETE FROM @TblCols WHERE ID=@I
		ELSE
			UPDATE @TblCols SET [Value]=@Value WHERE ID=@I

		SET @I=@I+1
	END

	DELETE FROM @TblCols WHERE [Value] IS NULL
	SELECT * FROM @TblCols

	--LINK PRODUTS
	
	--SELECT P.ProductCode, P.ProductName ProductName,P.productid [ProductName_Key], B.LinkType,P.ProductTypeID, @ProductID Parent
	--FROM INV_ProductBundles B INNER JOIN INV_Product P WITH(NOLOCK) ON B.ProductID=P.ProductID
	--WHERE B.ParentProductID=@ProductID AND B.LinkType>0 order by b.linktype;

	--declare @partid bigint
	declare @producttypeid int 
	select @producttypeid=producttypeid from inv_product where productid=@ProductID
	declare @costcenterid bigint, @ccfname nvarchar(10), @tabName nvarchar(15), @SQL nvarchar(max)
	select @costcenterid=value from com_costcenterpreferences WITH(NOLOCK) where name='LinkedProductDimension'
	set @tabName= (select TableName from adm_features WITH(NOLOCK) where featureid=@costcenterid)
	if @costcenterid >50000
	set @ccfname='CCNID'+convert(nvarchar,@costcenterid-50000)
	if(@PartID=0)
	begin
		set @SQL='select P.ProductCode, P.ProductName ProductName,P.productid [ProductName_Key], B.LinkType,P.ProductTypeID, '+convert(nvarchar,@ProductID)+' Parent, B.NodeID Product_Key
		from INV_LinkedProducts B WITH(NOLOCK) join INV_Product p WITH(NOLOCK) on B.ProductID=p.ProductID
		join '+@tabName+' cc on b.nodeid=cc.Nodeid 
		where B.Nodeid <>1 and 
		B.Nodeid in (select '+@ccfname +' as partid from com_ccccdata where nodeid='+convert(nvarchar,@ProductID)+' and costcenterid=3)'
	end
	else if(@producttypeid<>6)
	begin
		set @SQL='select P.ProductCode, P.ProductName ProductName,P.productid [ProductName_Key], B.LinkType,P.ProductTypeID, '+convert(nvarchar,@ProductID)+' Parent, '+convert(nvarchar,@PartID)+' Product_Key
		from INV_LinkedProducts B WITH(NOLOCK) join INV_Product p  WITH(NOLOCK) on B.ProductID=p.ProductID 
		where B.Nodeid <>1 and 
		B.Nodeid ='+convert(nvarchar,@PartID)+' '
	end
	else
	select '' ProductCode
	exec(@SQL);
	
	if(@IsQOH=1)
	begin
		create table #temp(id int identity(1,1), ProductID bigint, LocationID bigint, QOH float)
		Insert into #temp(ProductID, LocationID)
		SELECT @ProductID,@LocationID
		  
		declare @j int,@cnt int,  @DocDate datetime,@QOH float,@HOLDQTY float, @RESERVEQTY float, @AvgRate float, @CCXML nvarchar(max),@BalQOH float
		set @j=1
		set @CCXML='<XML><Row CostCenterID="50002" NODEID="'+convert(nvarchar,@LocationID)+'" /></XML>'
		select @cnt=count(*) from #temp
		set @DocDate=getdate() 
		while @j<=@cnt
		begin 
			select @ProductID=productid from #temp where id=@j 
			EXEC [spDOC_StockAvgValue] @ProductID,@CCXML,@DocDate,0,0,0, 1,0,0,0,0  ,@QOH OUTPUT,@HOLDQTY OUTPUT,@RESERVEQTY OUTPUT,@AvgRate OUTPUT,@BalQOH   OUTPUT  
			update #temp set QOH=@QOH where productid=@ProductID and id=@j
			set @j=@j+1
		end
		select ProductID, LocationID,0, QOH as BALANCE  FROM #temp
		drop table #temp
	end
	else
		select @ProductID ProductID,@LocationID LocationID,0, 0 as BALANCE
			
	select  SysColumnName, UserColumnName from adm_Costcenterdef WITH(NOLOCK) where costcenterid=50029 and (usercolumnname ='Billable' or usercolumnname ='Bill')

 	--INSURANCE DETAILS DISCOUNT
	SELECT ProductPercentage,ProductAmount, LabPercentage, LabAmt , Insurance
	FROM SVC_InsuranceDetails WITH(NOLOCK) 
	WHERE Category=@CategoryID AND WEF<=CONVERT(FLOAT,getdate()) AND Location=@LocationID
	ORDER BY WEF DESC
	declare @CatID bigint
	select @CatID= categoryid from INV_Product where ProductID=@ProductID
	--80-20 percentage for service items
	SELECT top 1 * FROM COM_CCPrices WITH(NOLOCK)
	WHERE WEF<=CONVERT(FLOAT,GETDATE()) AND CCNID6=@CatID
	and SellingRateD>0 and SellingRateE>0 
	ORDER BY WEF DESC
	
	select * from COM_UOM WITH(NOLOCK) where isproductwise=1 and productid=@ProductID 
	 
 
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

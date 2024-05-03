USE PACT2C222
GO
SET ANSI_NULLS, QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spSVC_GetCatalogScreenDetails]
	@CATEGORYID [bigint] = 0,
	@PARTCATEGORY [bigint] = 0,
	@VIEWPARTSCATEGORYDATA [bigint] = 0,
	@WHERE [nvarchar](max) = NULL,
	@PartID [bigint] = 0,
	@VehicleID [bigint] = 0,
	@LocationID [bigint] = 0,
	@UserID [bigint],
	@LangID [int] = 1
WITH ENCRYPTION, EXECUTE AS CALLER
AS
BEGIN TRANSACTION
BEGIN TRY	
SET NOCOUNT ON
			
		DECLARE @Dt float	
		SET @Dt=convert(float,getdate())--Setting Current Date  
		DECLARE @HasAccess bit, @SQL NVARCHAR(MAX)
		 
		IF	 @VIEWPARTSCATEGORYDATA=1
		BEGIN
		if(@PartID>1)
		begin
 		 	SET @SQL='SELECT P.ProductCode, P.ProductName ProductName,P.productid [ProductName_Key], 
			M.NAME AS Manufacturer, round(P.SellingRate,2) as SellingRate, P.ProductTypeID,P.UOMID,
			U.UnitName, Part.NodeID as Part_Key, Part.Name as Part
			--,PV.VehicleID
			FROM INV_Product P WITH(NOLOCK)
			LEFT JOIN COM_CCCCData PCCMAP WITH(NOLOCK) ON P.PRODUCTID=PCCMAP.Nodeid and PCCMAP.CostCenterID = 3
			LEFT JOIN COM_CC50023 M ON  M.NODEID=PCCMAP.CCNID23   and PCCMAP.CostCenterID = 3
			LEFT JOIN COM_CC50029  Part ON Part.NODEID=PCCMAP.CCNID29 and PCCMAP.CostCenterID = 3 
 			LEFT JOIN 	COM_UOM U ON U.UOMID=P.UOMID
			--LEFT JOIN SVC_PRODUCTVEHICLE PV ON PV.ProductID=P.ProductID
			WHERE P.IsGroup=0 AND  PCCMAP.CCNID29= '+convert(nvarchar,@PartID)+' AND ' +@WHERE +'
			UNION
			SELECT P.ProductCode, P.ProductName ProductName,P.productid [ProductName_Key], 
			'''' Manufacturer, round(P.SellingRate,2) as SellingRate, P.ProductTypeID,P.UOMID,
			U.UnitName, Part.NodeID as Part_Key, Part.Name as Part
			--,PV.VehicleID
			FROM INV_Product P WITH(NOLOCK)
			LEFT JOIN COM_CC50029  Part ON Part.NODEID= '+convert(nvarchar,@PartID)+'
			 LEFT JOIN 	COM_UOM U ON U.UOMID=P.UOMID
			--LEFT JOIN SVC_PRODUCTVEHICLE PV ON PV.ProductID=P.ProductID
			WHERE P.PRODUCTID IN (SELECT VALUE from com_costcenterpreferences where costcenterid=3 and name like ''TempPartProduct'')'
		end
		else
		begin
			SET @SQL='SELECT P.ProductCode, P.ProductName ProductName,P.productid [ProductName_Key], 
			M.NAME AS Manufacturer, round(P.SellingRate,2) as SellingRate, P.ProductTypeID,P.UOMID,
			U.UnitName, Part.NodeID as Part_Key, Part.Name as Part
			--,PV.VehicleID
			FROM INV_Product P WITH(NOLOCK)
			LEFT JOIN COM_CCCCData PCCMAP WITH(NOLOCK) ON P.PRODUCTID=PCCMAP.Nodeid and PCCMAP.CostCenterID = 3
			LEFT JOIN COM_CC50023 M ON  M.NODEID=PCCMAP.CCNID23   and PCCMAP.CostCenterID = 3
			LEFT JOIN COM_CC50029  Part ON Part.NODEID=PCCMAP.CCNID29 and PCCMAP.CostCenterID = 3 
 			LEFT JOIN 	COM_UOM U ON U.UOMID=P.UOMID
			--LEFT JOIN SVC_PRODUCTVEHICLE PV ON PV.ProductID=P.ProductID
			WHERE P.IsGroup=0 AND   ' +@WHERE +'
			UNION
			SELECT P.ProductCode, P.ProductName ProductName,P.productid [ProductName_Key], 
			'''' Manufacturer, round(P.SellingRate,2) as SellingRate, P.ProductTypeID,P.UOMID,
			U.UnitName, Part.NodeID as Part_Key, Part.Name as Part
			--,PV.VehicleID
			FROM INV_Product P WITH(NOLOCK)
			LEFT JOIN COM_CC50029  Part ON Part.NODEID= '+convert(nvarchar,@PartID)+'
			 LEFT JOIN 	COM_UOM U ON U.UOMID=P.UOMID
			--LEFT JOIN SVC_PRODUCTVEHICLE PV ON PV.ProductID=P.ProductID
			WHERE P.PRODUCTID IN (SELECT VALUE from com_costcenterpreferences where costcenterid=3 and name like ''TempPartProduct'')'
		end
			print @SQL
			EXEC(@SQL);
  		
  			create table #temp(id int identity(1,1), ProductID bigint, LocationID bigint, QOH float)
			SET @SQL='insert into #temp(ProductID)
			SELECT  P.productid  
			FROM INV_Product P  WITH(NOLOCK)
			LEFT JOIN COM_CCCCData PCCMAP WITH(NOLOCK) ON P.PRODUCTID=PCCMAP.Nodeid and PCCMAP.CostCenterID = 3
			LEFT JOIN COM_CC50023 M ON  M.NODEID=PCCMAP.CCNID23   and PCCMAP.CostCenterID = 3
			LEFT JOIN COM_CC50029  Part ON Part.NODEID=PCCMAP.CCNID29 and PCCMAP.CostCenterID = 3 
 			LEFT JOIN 	COM_UOM U ON U.UOMID=P.UOMID
			--LEFT JOIN SVC_PRODUCTVEHICLE PV ON PV.ProductID=P.ProductID
			WHERE P.IsGroup=0 AND '+@WHERE
			print @SQL
			EXEC(@SQL);
		  
			declare @j int,@cnt int, @ProductID bigint, @DocDate datetime,@QOH float,@HOLDQTY float, @RESERVEQTY float, @AvgRate float, @CCXML nvarchar(max),@CommittedQTY float,@BalQOH float
			set @j=1
			set @CCXML='<XML><Row CostCenterID="50002" NODEID="'+convert(nvarchar,@LocationID)+'" /></XML>'
	 		select @cnt=count(*) from #temp
	 		set @DocDate=getdate() 
			while @j<=@cnt
			begin
				select @ProductID=productid from #temp where id=@j 
				EXEC [spDOC_StockAvgValue] @ProductID,@CCXML,@DocDate,0,0,0, 1,0,0,0,0  ,@QOH OUTPUT,@HOLDQTY OUTPUT,@CommittedQTY output,@RESERVEQTY OUTPUT,@AvgRate OUTPUT,@BalQOH  OUTPUT   
				update #temp set QOH=@QOH, LocationID=@LocationID where productid=@ProductID and id=@j
				set @j=@j+1
			end
			select ProductID, LocationID,0, QOH as BALANCE from #temp
		
			--WITH rOWS AS(
			--select ProductID, (case when (vouchertype=1) then sum(quantity) else 0 end) as RctQty, 
			--(case when (vouchertype=-1) then sum(quantity) else 0 end) as issQty  
			--from inv_docdetails 
			--where isqtyignored=0 
			--group by ProductID,vouchertype)
	
			--SELECT ProductID, Sum(RctQty) as RctQty,Sum(issQty) as IssQty,Sum(RctQty)-Sum(issQty) AS BALANCE FROM rOWS group by ProductID
 			 
			select c.*,(select segmentid from svc_vehicle WITH(NOLOCK) where vehicleid=@VehicleID) as SegmentID  from com_ccprices c where ccnid24 in (select segmentid from svc_vehicle WITH(NOLOCK) where vehicleid=@VehicleID)	 and wef in (select max(wef) from com_Ccprices WITH(NOLOCK) where  wef <=@Dt )
		
			--COSTCENTER WISE RATE 
			SELECT * FROM COM_CCPrices WITH(NOLOCK)
			WHERE WEF<=CONVERT(FLOAT,GETDATE()) AND ProductID in (select ProductID from #temp) 
			AND CCNID11 in (select CCNID11 from COM_CCCCData WITH(NOLOCK) where  costcenterid=50002 and nodeid=@LocationID)
			AND CCNID29 IN (SELECT CCNID29 FROM COM_CCCCDATA WITH(NOLOCK) WHERE COSTCENTERID=3 AND NODEID in (select ProductID from #temp))
			and CCNID24 IN (SELECT SEGMENTID FROM SVC_VEHICLE WITH(NOLOCK) WHERE VEHICLEID=@VehicleID)    
			ORDER BY WEF DESC
			drop table #temp
			
		END
		ELSE
		BEGIN
			SELECT * FROM SVC_PartCategory WITH(NOLOCK)
			IF @CATEGORYID>0
			BEGIN
				 SELECT DISTINCT SUBCATEGORYID,SubCategoryName FROM SVC_PartCategory WITH(NOLOCK) WHERE CATEGORYID=@CATEGORYID  
	 				
			END		 
			IF @PARTCATEGORY>0
			BEGIN
					 SELECT * FROM SVC_PartCategory WITH(NOLOCK) WHERE PARTCATEGORYID=@PARTCATEGORY

					 SELECT ROW_NUMBER() OVER(ORDER BY p.productid asc) AS 'sno',SVC_PartCategoryMap.PRODUCTID [ProductName_Key],SVC_PartCategoryMap.PartCategoryMapID PrimaryKey
					 ,P.ProductCode [ProductName],COM_CC50023.NODEID [Name_Key],COM_CC50023.Name, p.UOMID FROM SVC_PartCategoryMap WITH(NOLOCK)
					 LEFT JOIN COM_CC50023 WITH(NOLOCK) ON COM_CC50023.NODEID=SVC_PartCategoryMap.Manufacturer
					 LEFT JOIN INV_PRODUCT P WITH(NOLOCK) ON P.PRODUCTID=SVC_PartCategoryMap.PRODUCTID WHERE PartCategoryID=@PARTCATEGORY

					 SELECT ROW_NUMBER() OVER(ORDER BY sv.vehicleid asc) AS 'sno',SVC_PartVehicle.PARTVEHICLEID PrimaryKey,SV.MAKEID [Make_Key],SV.Make,SV.MODEL [Model],SV.MODELID[MODEL_KEY],
					 SV.StartYear ,SV.VARIANTID [Variant_Key],SV.VARIANT [Variant],SV.SegmentID SegmentID,SV.SEGMENT Segment,SVC_PartVehicle.SKILLHOURS LabourHrs,COM_CC50018.NodeID [Name_Key],COM_CC50018.Code Name,
					 SVC_PartVehicle.VehicleID FROM SVC_PartVehicle WITH(NOLOCK)
					 LEFT JOIN COM_CC50018 WITH(NOLOCK) ON COM_CC50018.NODEID=SVC_PartVehicle.SKILLLEVEL
					 LEFT JOIN SVC_VEHICLE SV WITH(NOLOCK) ON SV.VEHICLEID=SVC_PartVehicle.VEHICLEID WHERE PartCategoryMapID IN (
					 SELECT PartCategoryMapID  FROM SVC_PartCategoryMap WITH(NOLOCK) WHERE PartCategoryID=@PARTCATEGORY)  
					
			END
		END
COMMIT TRANSACTION
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
ROLLBACK TRANSACTION
SET NOCOUNT OFF  
RETURN -999   
END CATCH  

GO

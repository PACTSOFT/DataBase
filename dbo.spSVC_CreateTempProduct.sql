USE PACT2C222
GO
SET ANSI_NULLS, QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spSVC_CreateTempProduct]
	@ProductID [bigint],
	@Vehicles [nvarchar](max),
	@CategoryID [bigint],
	@CustomFieldsQuery [nvarchar](max),
	@CustomCostCenterFieldsQuery [nvarchar](max),
	@PurchasePrice [float],
	@SellingPrice [float],
	@ProductCode [nvarchar](500),
	@ProductName [nvarchar](500),
	@INVDOCDETAILSID [bigint],
	@COMPANYGUID [nvarchar](50),
	@USERNAME [nvarchar](50),
	@USERID [int],
	@LANGID [int]
WITH ENCRYPTION, EXECUTE AS CALLER
AS
BEGIN TRANSACTION  
BEGIN TRY  
SET NOCOUNT ON;
	
	DECLARE @UOMID BIGINT,@SalesAccountID BIGINT,@PurchaseAccountID BIGINT,@COGSAccountID BIGINT,@ClosingStockAccountID BIGINT
	DECLARE @ValuationID BIGINT,@StatusID BIGINT,@VALUE NVARCHAR(200)	,@Dt float
	SET @Dt=CONVERT(FLOAT,GETDATE())
	IF(@ProductID=0)
	BEGIN
		SET @VALUE=''
		SELECT @VALUE=VALUE FROM COM_COSTCENTERPREFERENCES WHERE COSTCENTERID=3 AND NAME='DefaultUOM'
		IF(@VALUE<>'')
			SET @UOMID=CONVERT(BIGINT,@VALUE)
			
		SET @VALUE=''
		SELECT @VALUE=VALUE FROM COM_COSTCENTERPREFERENCES WHERE COSTCENTERID=3 AND NAME='DefaultProductValuation'
		IF(@VALUE='FIFO')
			SET @ValuationID=1
		ELSE IF(@VALUE='LIFO')
			SET @ValuationID=2
		ELSE
			SET @ValuationID=3
			
		SET @VALUE=''
		SELECT  @VALUE=USERDEFAULTVALUE FROM ADM_COSTCENTERDEF WHERE COSTCENTERID=3 AND SYSCOLUMNNAME='SalesAccountID'
		IF(@VALUE<>'')
			SET @SalesAccountID=CONVERT(BIGINT,@VALUE)
		SET @VALUE=''		
	    SELECT  @VALUE=USERDEFAULTVALUE FROM ADM_COSTCENTERDEF WHERE COSTCENTERID=3 AND SYSCOLUMNNAME='PurchaseAccountID'
	    IF(@VALUE<>'')
			SET @PurchaseAccountID=CONVERT(BIGINT,@VALUE)
	    SET @VALUE=''
	    SELECT  @VALUE=USERDEFAULTVALUE FROM ADM_COSTCENTERDEF WHERE COSTCENTERID=3 AND SYSCOLUMNNAME='COGSAccountID'
	    IF(@VALUE<>'')
			SET @COGSAccountID=CONVERT(BIGINT,@VALUE)
	    SET @VALUE=''
	    SELECT  @VALUE=USERDEFAULTVALUE FROM ADM_COSTCENTERDEF WHERE COSTCENTERID=3 AND SYSCOLUMNNAME='ClosingStockAccountID'
		IF(@VALUE<>'')
			SET @ClosingStockAccountID=CONVERT(BIGINT,@VALUE)
		SET @VALUE=''
	    SELECT  @VALUE=USERDEFAULTVALUE FROM ADM_COSTCENTERDEF WHERE COSTCENTERID=3 AND SYSCOLUMNNAME='StatusID'
		IF(@VALUE<>'')
			SET @StatusID=CONVERT(BIGINT,@VALUE)
			
		EXEC	@ProductID = [dbo].[spINV_SetProduct]
		@ProductID = 0,
		@ProductCode = @ProductCode,
		@ProductName = @ProductName,
		@AliasName = @ProductName,
		@ProductTypeID = 1,
		@StatusID = @StatusID,
		@UOMID = @UOMID,
		
		@BarcodeID = 0,
		@Description = N'',
		@SelectedNodeID = 0,
		@IsGroup = 0,
		@CustomFieldsQuery =@CustomFieldsQuery,
		@CustomCostCenterFieldsQuery = @CustomCostCenterFieldsQuery,
		@ProductVehicleXML = @Vehicles,
		@ContactsXML = N'',
		@NotesXML = N'',
		@AttachmentsXML = N'',
		@SubstitutesXML = N'',
		@VendorsXML = N'',
		@SerializationXML = N'',
		@KitXML = N'',
		@LinkedProductsXML = N'',
		@MatrixSeqno = 0,
		@AttributesXML = N'',
		@AttributesData = N'',
		@AttributesColumnsData = N'',
		@HasSubItem = 0,
		@ItemProductData = N'',
		@AssignCCCCData = N'',
		@ProductWiseUOMData = N'',
		@ProductWiseUOMData1 = N'',
		@CompanyGUID = @COMPANYGUID,
		@GUID = N'',
		@UserName = @USERNAME,
		@UserID = @USERID,
		@LangID = @LANGID  
		
		UPDATE INV_Product SET
		ValuationID = @ValuationID,
		SalesAccountID = @SalesAccountID,
		PurchaseAccountID = @PurchaseAccountID,
		COGSAccountID = @COGSAccountID,
		ClosingStockAccountID = @ClosingStockAccountID,
		PurchaseRate = @PurchasePrice,
		SellingRate = @SellingPrice 
		WHERE ProductID=@ProductID
	END
	
	if(@ProductID>0)
	begin	
		if  exists (select CCnid6 from COM_CCCCData where CostCenterID=3 and nodeid=@ProductID and Ccnid6<>1)
		begin
			declare @cat bigint
			set @cat=1
			select @cat=ccnid6 from COM_CCCCData where CostCenterID=3 and nodeid=@ProductID  
			update INV_Product set CategoryID=@cat where productid=@ProductID
		end
		
		WHILE(@INVDOCDETAILSID IS NOT NULL AND @INVDOCDETAILSID>0)
		BEGIN
			if exists (	select p.servicepartsinfoid from svc_servicepartsinfo p
			left join svc_serviceticket t on p.serviceticketid=t.serviceticketid 
			left join inv_docdetails d on t.ccticketid=d.refnodeid 
			inner join com_docccdata doccc on d.invdocdetailsid=doccc.invdocdetailsid
			 where   p.productid =d.productid and  doccc.dcccnid29=p.partid and
			 p.productid in (select Value from com_costcenterpreferences where costcenterid=3 and Name like 'TempPartProduct')
			and d.INVDOCDETAILSID=	@INVDOCDETAILSID)
			begin  
				update svc_servicepartsinfo set productid=@PRODUCTID, rate=@SellingPrice, ispriceupdated=1
				 where  servicepartsinfoid 
				in (select p.servicepartsinfoid from svc_servicepartsinfo p
				left join svc_serviceticket t on p.serviceticketid=t.serviceticketid 
				left join inv_docdetails d on t.ccticketid=d.refnodeid 
				inner join com_docccdata doccc on d.invdocdetailsid=doccc.invdocdetailsid
				 where   p.productid =d.productid and  doccc.dcccnid29=p.partid and
				 p.productid in (select Value from com_costcenterpreferences where costcenterid=3 and Name like 'TempPartProduct')
				and d.INVDOCDETAILSID=	@INVDOCDETAILSID) 
			end
			
			UPDATE INV_DOCDETAILS
			SET PRODUCTID=@PRODUCTID
			WHERE INVDOCDETAILSID	=@INVDOCDETAILSID	
			
			delete from inv_Tempinfo  WHERE INVDOCDETAILSID	=@INVDOCDETAILSID
			
			SELECT @INVDOCDETAILSID=LinkedInvDocDetailsID FROM INV_DOCDETAILS WHERE INVDOCDETAILSID=@INVDOCDETAILSID
			
		END	   
		if @Vehicles is not null and @Vehicles <>''
		begin  
			declare @XML xml
			set @XML=@Vehicles
			--print @Vehicles
			 INSERT INTO SVC_ProductVehicle(ProductID, VehicleID, CompanyGUID, GUID, Createdby, CreatedDate)
			SELECT  @ProductID,X.value('@VehicleID','bigint'),@CompanyGUID, newid(),@UserName,@Dt  
			from @XML.nodes('Row') as DATA(X)
			WHERE X.value('@Action','NVARCHAR(10)')='NEW'	and  X.value('@VehicleID','bigint') not in 
			(select vehicleid from svc_productvehicle where productid =@ProductID)
		end 
	end	  	 
 
COMMIT TRANSACTION    
SET NOCOUNT OFF; 
SELECT ErrorMessage,ErrorNumber FROM COM_ErrorMessages WITH(nolock) 
WHERE ErrorNumber=100 AND LanguageID=@LangID   
RETURN @PRODUCTID
END TRY  
BEGIN CATCH  
	--Return exception info [Message,Number,ProcedureName,LineNumber]  
	if(@ProductID=-999)
		RETURN -999
 	IF ERROR_NUMBER()=50000
	BEGIN		  
		SELECT ErrorMessage,ErrorNumber FROM COM_ErrorMessages WITH(NOLOCK) WHERE ErrorNumber=ERROR_MESSAGE() AND LanguageID=@LangID
	END
	ELSE
	BEGIN
		SELECT ErrorMessage, ERROR_MESSAGE() AS ServerMessage,ERROR_NUMBER() AS ErrorNumber, ERROR_PROCEDURE()AS ProcedureName, ERROR_LINE() AS ErrorLine
		FROM COM_ErrorMessages WITH(NOLOCK) WHERE ErrorNumber=-999 AND LanguageID=@LangID
	END
	ROLLBACK TRANSACTION
	SET NOCOUNT OFF  
	RETURN -999   
END CATCH 
   
   

GO

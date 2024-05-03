USE PACT2C222
GO
SET ANSI_NULLS, QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spRPT_StockBalance]
	@BalanceType [bit],
	@LocationWHERE [nvarchar](max) = NULL,
	@FromDate [datetime],
	@ToDate [datetime],
	@IncludeUpPostedDocs [bit],
	@CurrencyType [int],
	@CurrencyID [int] = 0,
	@IsOuputCall [int] = 0,
	@Bal [float] OUTPUT
WITH ENCRYPTION, EXECUTE AS CALLER
AS
SET NOCOUNT ON;  

	DECLARE @TblProducts AS TABLE(ProductID BIGINT)
	DECLARE @SPInvoice cursor, @nStatusOuter int
	DECLARE @ProductID BIGINT,@SQL NVARCHAR(MAX),@TagSQL NVARCHAR(MAX),@From nvarchar(20),@To nvarchar(20),@UnAppSQL nvarchar(50)
	DECLARE @Qty FLOAT,@AvgRate FLOAT,@StockValue FLOAT,@COGS FLOAT,@CurrWHERE nvarchar(30),@DimWhere NVARCHAR(MAX)

	set @From=convert(nvarchar,convert(float,@FromDate))
	set @To=convert(nvarchar,convert(float,@ToDate))
	
	set @DimWhere=''
	SET @TagSQL=''
	IF @LocationWHERE IS NOT NULL AND @LocationWHERE<>''
	BEGIN
		SET @DimWhere=' AND DCC.DCCCNID2 IN ('+@LocationWHERE+') '
		SET @TagSQL=' INNER JOIN COM_DocCCData DCC WITH(nolock) ON DCC.InvDocDetailsID=D.InvDocDetailsID AND DCC.DCCCNID2 IN ('+@LocationWHERE+') '
	END
	
	IF @BalanceType=0 and exists (SELECT * FROM ADM_FinancialYears with(nolock) where InvClose=1 and ToDate=@ToDate)
	BEGIN
		SET @SQL='
		SELECT @Bal=sum(BalValue)
		FROM INV_ProductClose DCC WITH(NOLOCK)
		WHERE CloseDate='+convert(nvarchar,convert(int,@ToDate))+@DimWhere
		EXEC sp_executesql @SQL,N'@Bal float output',@Bal OUTPUT
		select @Bal Balance
		return 1
	END

	IF @IncludeUpPostedDocs=0
		SET @UnAppSQL=' AND D.StatusID=369'
	ELSE
		SET @UnAppSQL=''
		
	IF @CurrencyID>0
	BEGIN
		SET @CurrWHERE=' AND D.CurrencyID='+CONVERT(NVARCHAR,@CurrencyID)
	END
	ELSE
	BEGIN
		SET @CurrWHERE=''
	END
	
	--INSERT INTO @TblProducts
	--SELECT ProductID FROM INV_Product WHERE IsGroup=0 AND ProductTypeId<>6
	
	IF @BalanceType=1
	BEGIN
		SET @SQL='SELECT D.ProductID
		FROM Inv_DocDetails D WITH(NOLOCK)'+@TagSQL+'
		INNER JOIN INV_Product P WITH(NOLOCK) ON P.ProductID=D.ProductID
		WHERE (VoucherType=1 OR VoucherType=-1) AND IsQtyIgnored=0 AND P.ProductTypeId<>6 AND P.ProductTypeId<>10 and (D.DocDate<'+@From+' OR (D.DocumentType=3 AND D.DocDate<='+@To+'))'+@UnAppSQL+@CurrWHERE+'
		GROUP BY D.ProductID
		HAVING sum(VoucherType*UOMConvertedQty)>0'
		--print(@SQL)
		INSERT INTO @TblProducts
		EXEC(@SQL)
	END
	ELSE
	BEGIN
		SET @SQL='SELECT D.ProductID
		FROM Inv_DocDetails D WITH(NOLOCK)'+@TagSQL+'
		INNER JOIN INV_Product P WITH(NOLOCK) ON P.ProductID=D.ProductID
		WHERE (VoucherType=1 OR VoucherType=-1) AND IsQtyIgnored=0 AND P.ProductTypeId<>6 AND P.ProductTypeId<>10 and D.DocDate<='+@To+@UnAppSQL+@CurrWHERE+'
		GROUP BY D.ProductID
		HAVING sum(VoucherType*UOMConvertedQty)>0'
		--print(@SQL)
		INSERT INTO @TblProducts
		EXEC(@SQL)
	END
	
	SET @SPInvoice = cursor for 
	SELECT ProductID FROM @TblProducts
	--SELECT ProductID,ValuationID FROM INV_Product WHERE IsGroup=0
	
	
	DECLARE @Tbl AS TABLE(ProductID BIGINT,Qty FLOAT,AvgRate FLOAT,StockValue FLOAT)
	
	OPEN @SPInvoice 
	SET @nStatusOuter = @@FETCH_STATUS
	
	FETCH NEXT FROM @SPInvoice Into @ProductID
	SET @nStatusOuter = @@FETCH_STATUS
	
	WHILE(@nStatusOuter <> -1)
	BEGIN

		EXEC [spRPT_AvgRate] @BalanceType,@ProductID,@DimWhere,'',@FromDate,@ToDate,@IncludeUpPostedDocs,0,@CurrencyID,0,'',0,@Qty OUTPUT,@AvgRate OUTPUT,@StockValue OUTPUT,@COGS OUTPUT
		
		IF @Qty>0
		BEGIN
			INSERT INTO @Tbl(ProductID,Qty,AvgRate,StockValue)
			VALUES(@ProductID,@Qty,@AvgRate,@StockValue)
		END
	--	select @ProductID
	
	--print(@ProductID)
	
		FETCH NEXT FROM @SPInvoice Into @ProductID
		SET @nStatusOuter = @@FETCH_STATUS
	END
	
	SELECT @Bal=SUM(StockValue) FROM @Tbl
		
	IF @IsOuputCall=0
		SELECT @Bal Balance
	
	--SELECT * FROM @Tbl
GO

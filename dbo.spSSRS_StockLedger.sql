USE PACT2C222
GO
SET ANSI_NULLS, QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spSSRS_StockLedger]
	@Products [nvarchar](max),
	@DimensionID [int],
	@LocationWHERE [nvarchar](max) = NULL,
	@DIMWHERE [nvarchar](max),
	@WHERE [nvarchar](max),
	@FromDate [datetime],
	@ToDate [datetime],
	@IncludeUpPostedDocs [bit],
	@DefValuation [int] = 0,
	@CurrencyType [int],
	@CurrencyID [int] = 0,
	@SELECTQUERY [nvarchar](max),
	@FROMQUERY [nvarchar](max),
	@SortTransactionsBy [nvarchar](50),
	@UserID [int],
	@LangID [int]
WITH ENCRYPTION, EXECUTE AS CALLER
AS
BEGIN TRY  
SET NOCOUNT ON;  

	DECLARE @SQL NVARCHAR(MAX),@From NVARCHAR(20),@To NVARCHAR(20),@TagSQL NVARCHAR(MAX),@Order NVARCHAR(100),@CloseDt nvarchar(20),
			@PRD_I INT,@PRD_COUNT INT,@ProductID INT,@UnAppSQL NVARCHAR(50),@Valuation INT,@ShowNegativeStock bit,
			@CurrWHERE nvarchar(30),@ValColumn nvarchar(20),@GrossColumn nvarchar(20),@TransactionsBy nvarchar(100),
			@TransactionsByOp nvarchar(100),@TransactionsByOpHardClose nvarchar(50),
			@DateFilterCol nvarchar(60),@DateFilterLPRate nvarchar(60),@DateFilterOp1 nvarchar(120),@DateFilterOp2 nvarchar(80),@Extracol nvarchar(max),
			@strSQL nvarchar(max),@Transcol nvarchar(max)

	DECLARE @k int,@kcnt int			

	DECLARE @TblOpening AS TABLE(ProductID INT,OpQty FLOAT,AvgRate FLOAT,OpValue FLOAT,DocumentType INT)	
	CREATE TABLE #Tbl(ID INT IDENTITY(1,1) NOT NULL PRIMARY KEY,PRODUCTID INT,Date DATETIME,Qty FLOAT,RecRate FLOAT,RecValue FLOAT,VoucherType INT,
					  DocumentType INT,AVGRATE FLOAT,UOMConvertedQty float,COGS float,BalanceQty float,BalanceValue float,docdate datetime,IssValue float,InvDocDetailsID INT)
	CREATE TABLE #TblTransactions(ID INT IDENTITY(1,1) NOT NULL PRIMARY KEY,PRODUCTID INT,Date DATETIME,Qty FLOAT,RecRate FLOAT,RecValue FLOAT,VoucherType INT,
					  DocumentType INT,AVGRATE FLOAT,UOMConvertedQty float,COGS float,BalanceQty float,BalanceValue float,docdate datetime,IssValue float,InvDocDetailsID INT)
	CREATE TABLE #Tblextracols(Rptcol1 nvarchar(max))	
	DECLARE @tblBalanceBF AS TABLE(ProductID INT,ProductName NVARCHAR(MAX),BalanceQty FLOAT,AvgRate FLOAT,BalanceValue FLOAT,VoucherType INT)	
	
	Create Table #TblProds (ProductID INT,ProductName NVARCHAR(MAX))
	set @strSQL=''
	SET @strSQL=' DECLARE @TDate FLOAT
				  SET @TDate='+CONVERT(NVARCHAR,CONVERT(FLOAT,@ToDate))+'
				  Insert Into #TblProds
						SELECT P.ProductID,P.ProductName FROM INV_Product P WITH(NOLOCK) 
				     		   WHERE P.IsGroup=0 AND P.ProductTypeId<>6 AND P.ProductTypeId!=10 AND P.ProductID IN ('+@Products+') 
							   AND P.ProductID IN (SELECT D.ProductID FROM Inv_DocDetails D WITH(NOLOCK) WHERE (D.VoucherType=1 OR D.VoucherType=-1) AND D.IsQtyIgnored=0
							   AND D.DocDate<=@TDate GROUP BY D.ProductID) Order By P.ProductName '
	--print @strSQL						 
	Exec (@strSQL)
	 

	
	set @Extracol=''
	set @strSQL=''
	set @Transcol=''
	
	SET @TagSQL=''
	SET @Order=''
	SET @UnAppSQL=''
	SET @CurrWHERE=''
	SET @ValColumn=''
	SET @GrossColumn=''
	SET @TransactionsBy=''
	SET @TransactionsByOp=''
	SET @TransactionsByOpHardClose=''
	SET @DateFilterCol=''
	SET @DateFilterLPRate=''
	SET @DateFilterOp1=''
	SET @DateFilterOp2=''
	
	
	

	if(select Value from adm_globalpreferences with(nolock) where Name='ShowNegativeStockInReports')='True'
		set @ShowNegativeStock=1
	else
		set @ShowNegativeStock=0
		
	SET @From=CONVERT(FLOAT,@FromDate)
	SET @To=CONVERT(FLOAT,@ToDate)
	SET @Valuation=@DefValuation
	
	IF @IncludeUpPostedDocs=0
		SET @UnAppSQL=' AND D.StatusID=369'
	ELSE
		SET @UnAppSQL=' AND D.StatusID<>376'

	IF @CurrencyID>0
	BEGIN
		SET @ValColumn='StockValueFC'
		SET @GrossColumn='GrossFC'
		SET @CurrWHERE=' AND D.CurrencyID='+CONVERT(NVARCHAR,@CurrencyID)
		
	END
	ELSE
	BEGIN
		IF @CurrencyType=1
		BEGIN
			SET @ValColumn='StockValueBC'
			SET @GrossColumn='(Gross/ExhgRtBC)'
		END
		ELSE
		BEGIN
			SET @ValColumn='StockValue'
			SET @GrossColumn='Gross'
		END
		SET @CurrWHERE=''
	END
	
	SELECT @CloseDt=convert(nvarchar(20), max(ToDate)+1) FROM ADM_FinancialYears with(nolock) where InvClose=1 and ToDate<convert(int,@FromDate)
	
	if isnull(@SortTransactionsBy,'')=''
	begin
		set @SortTransactionsBy='OP,DocDate'
		set @TransactionsBy='CONVERT(DATETIME,D.DocDate) DocDate'
		set @Transcol=' DocDate DateTime'
		set @TransactionsByOp='D.DocDate DocDate'
		set @TransactionsByOpHardClose=''
		set @DateFilterCol=' AND D.DocDate BETWEEN '+@From+' AND '+@To
		set @DateFilterOp1=' AND (D.DocDate<@FromDate OR (D.DocumentType=3 AND D.DocDate<=@ToDate))'
		set @DateFilterOp2=' AND D.DocDate<@FromDate'
		set @DateFilterLPRate=' AND D.DocDate<='+@To
		if(@CloseDt is not null)
		begin
			set @DateFilterCol=' and D.DocDate>='+@CloseDt+@DateFilterCol
			set @DateFilterOp1=' and D.DocDate>='+@CloseDt+@DateFilterOp1
			set @DateFilterOp2=' and D.DocDate>='+@CloseDt+@DateFilterOp2
		end		
	end
	else if @SortTransactionsBy='CreatedDate'
	begin
		set @SortTransactionsBy='OP,DocDate,CreateTime'
		set @TransactionsBy='CONVERT(DATETIME,D.CreatedDate) DocDate,CONVERT(DATETIME,D.CreatedDate) CreateTime'
		set @Transcol=' DocDate DateTime,CreateTime Datetime'
		set @TransactionsByOp='D.CreatedDate DocDate,D.CreatedDate CreateTime'
		set @TransactionsByOpHardClose=',null CreateTime'
		set @DateFilterCol=' AND D.CreatedDate>='+@From+' AND D.CreatedDate<'+convert(nvarchar,convert(int,@To)+1)
		set @DateFilterOp1=' AND (D.CreatedDate<@FromDate OR (D.DocumentType=3 AND D.CreatedDate<@ToDate+1))'
		set @DateFilterOp2=' AND D.CreatedDate<@FromDate'
		set @DateFilterLPRate=' AND D.CreatedDate<'+convert(nvarchar,convert(int,@To)+1)
		if(@CloseDt is not null)
		begin
			set @DateFilterCol=' and D.CreatedDate>='+@CloseDt+@DateFilterCol
			set @DateFilterOp1=' and D.CreatedDate>='+@CloseDt+@DateFilterOp1
			set @DateFilterOp2=' and D.CreatedDate>='+@CloseDt+@DateFilterOp2
		end	
	end
	else if @SortTransactionsBy='DocDate,CreatedDate'
	begin
		set @SortTransactionsBy='OP,DocDate,CTime'
		set @TransactionsBy='CONVERT(DATETIME,D.DocDate) DocDate,CONVERT(DATETIME,D.CreatedDate) CTime'
		set @Transcol=' DocDate DateTime,CTime Datetime'
		set @TransactionsByOp='D.DocDate DocDate,D.CreatedDate CTime'
		set @TransactionsByOpHardClose=',null CTime'
		set @DateFilterCol=' AND D.DocDate BETWEEN '+@From+' AND '+@To
		set @DateFilterOp1=' AND (D.DocDate<@FromDate OR (D.DocumentType=3 AND D.DocDate<=@ToDate))'
		set @DateFilterOp2=' AND D.DocDate<@FromDate'
		set @DateFilterLPRate=' AND D.DocDate<='+@To
		if(@CloseDt is not null)
		begin
			set @DateFilterCol=' and D.DocDate>='+@CloseDt+@DateFilterCol
			set @DateFilterOp1=' and D.DocDate>='+@CloseDt+@DateFilterOp1
			set @DateFilterOp2=' and D.DocDate>='+@CloseDt+@DateFilterOp2
		end
	end
	else if @SortTransactionsBy='ModifiedDate'
	begin
		set @SortTransactionsBy='OP,DocDate,ModTime'
		set @TransactionsBy='CONVERT(DATETIME,D.ModifiedDate) DocDate,CONVERT(DATETIME,D.ModifiedDate) ModTime'
		set @Transcol=' DocDate DateTime,ModTime Datetime'
		set @TransactionsByOp='D.ModifiedDate DocDate,D.ModifiedDate ModTime'
		set @TransactionsByOpHardClose=',null ModTime'
		set @DateFilterCol=' AND D.ModifiedDate>='+@From+' AND D.ModifiedDate<'+convert(nvarchar,convert(int,@To)+1)
		set @DateFilterOp1=' AND (D.ModifiedDate<@FromDate OR (D.DocumentType=3 AND D.ModifiedDate<@ToDate+1))'
		set @DateFilterOp2=' AND D.ModifiedDate<@FromDate'
		set @DateFilterLPRate=' AND D.ModifiedDate<'+convert(nvarchar,convert(int,@To)+1)
		if(@CloseDt is not null)
		begin
			set @DateFilterCol=' and D.ModifiedDate>='+@CloseDt+@DateFilterCol
			set @DateFilterOp1=' and D.ModifiedDate>='+@CloseDt+@DateFilterOp1
			set @DateFilterOp2=' and D.ModifiedDate>='+@CloseDt+@DateFilterOp2
		end
	end
	else if @SortTransactionsBy='DocDate,ModifiedDate'
	begin
		set @SortTransactionsBy='OP,DocDate,ModTime'
		set @TransactionsBy='CONVERT(DATETIME,D.DocDate) DocDate,CONVERT(DATETIME,D.ModifiedDate) ModTime'
		set @Transcol=' DocDate DateTime,ModTime Datetime'
		set @TransactionsByOp='D.DocDate,D.ModifiedDate ModTime'
		set @TransactionsByOpHardClose=',null ModTime'
		set @DateFilterCol=' AND D.DocDate BETWEEN '+@From+' AND '+@To
		set @DateFilterOp1=' AND (D.DocDate<@FromDate OR (D.DocumentType=3 AND D.DocDate<=@ToDate))'
		set @DateFilterOp2=' AND D.DocDate<@FromDate'
		set @DateFilterLPRate=' AND D.DocDate<='+@To
		if(@CloseDt is not null)
		begin
			set @DateFilterCol=' and D.DocDate>='+@CloseDt+@DateFilterCol
			set @DateFilterOp1=' and D.DocDate>='+@CloseDt+@DateFilterOp1
			set @DateFilterOp2=' and D.DocDate>='+@CloseDt+@DateFilterOp2
		end
	end	
	print '@DateFilterCol'
	print @DateFilterCol
	print @UnAppSQL
	SET @TagSQL=''
	
	IF ((ISNULL(@LocationWHERE,'')<>'' AND @LocationWHERE<>NULL) OR (ISNULL(@DIMWHERE,'')<>'' AND @DIMWHERE<>NULL))
	begin
		IF (ISNULL(@LocationWHERE,'')<>'' AND @LocationWHERE<>NULL)
			set @DIMWHERE=@DIMWHERE+' AND DCC.DCCCNID'+CONVERT(NVARCHAR,@DimensionID-50000)+' IN ('+@LocationWHERE+') '
		set @TagSQL=@DIMWHERE			
		set @Order=@SortTransactionsBy+',ST DESC,VoucherType DESC,VoucherNo,RecQty DESC'
	end
	else
	begin
		set @Order=@SortTransactionsBy+',ST DESC,VoucherNo,VoucherType DESC,RecQty DESC'
	end
	
	--START : SELECTQUERY COLUMNS
	INSERT INTO #Tblextracols(Rptcol1)
		exec SPSplitString @SELECTQUERY,','
	
	Delete From #Tblextracols where isnull(Rptcol1,'')=''
	Select @k=1 ,@kcnt=count(*) from #Tblextracols 
	While(@k<=@kcnt)
	Begin
		set @Extracol=@Extracol+',Rptcol'+convert(nvarchar(max),@k) +' nvarchar(max)'
	Set @k=@k+1
	End
	--END : SELECTQUERY COLUMNS
	
	if(@DefValuation=4)
		set @SELECTQUERY=@SELECTQUERY+','+@GrossColumn+' Gross'
	
	if(@DefValuation=8)
		set @SELECTQUERY=@SELECTQUERY+','+@GrossColumn+' BatchValue'
		
	--Reconcile flag
	declare @XML xml,@Cogs nvarchar(50),@IsReconcile bit
	set @XML=(Select CustomPreferences From ADM_RevenUReports with(nolock) where ReportID=14)
	set @Cogs=''
	set @IsReconcile=0
	select @Cogs=X.value('COGS[1]','nvarchar(50)'),@IsReconcile=X.value('Reconcile[1]','bit') from @XML.nodes('XML') as Data(X)
	if(isnull(@Cogs,'')<>'')
		set @IsReconcile=0
		
	--Temp Table	
	CREATE Table #tblMain(ProductID INT,ProductName nvarchar(max))
		set @strSQL='alter table #tblMain add '+ @Transcol + ',VoucherNo nvarchar(200),InvDocDetailsID int,CustomerName nvarchar(200),RecQty float,RecUnit nvarchar(100) '
		set @strSQL=@strSQL+',RecRate float,RecValue float,IssQty float,IssUnit nvarchar(100) ,IssRate float,IssValue float,UOMConvertedQty float,VoucherType int'
		set @strSQL=@strSQL+',DocumentType int,OP int,ST int'
	if(isnull(@Extracol,'')<>'')
		set @strSQL=@strSQL+@Extracol
	if(@DefValuation=4)
		set @strSQL=@strSQL+', Gross float '
	if(@DefValuation=8)
		set @strSQL=@strSQL+', BatchValue nvarchar(200),BatchValue1 nvarchar(200)'	

	set @strSQL=@strSQL+',AvgRate float,COGS float,BalanceQty float,IsReconcile bit,BalanceValue float'	
	--print @strSQL
	exec (@strSQL)
	
	INSERT INTO #tblmain(ProductID,ProductName,BalanceQty ,AvgRate ,BalanceValue,VoucherType) SELECT ProductID,ProductName,0,0,0,0 FROM #TblProds
	SET @SQL=' INSERT INTO #tblMain
		SELECT P.ProductID,P.ProductName,'+@TransactionsBy+',D.VoucherNo,D.InvDocDetailsID,case when D.DocumentType=5 then Dr.AccountName else A.AccountName end CustomerName,
		D.Quantity RecQty,UOM.UnitName RecUnit,D.'+@ValColumn+'/D.Quantity RecRate,D.'+@ValColumn+' RecValue,
		NULL IssQty,NULL IssUnit,NULL IssRate,NULL IssValue,D.UOMConvertedQty,D.VoucherType,D.DocumentType,case when D.DocumentType=3 then 1 else 2 end OP,case when D.DocumentType=5 then 1 else 2 end ST'
	if(@DefValuation=8)
		SET @SQL=@SQL+',D.'+@ValColumn+' BatchValue'	
	SET @SQL=@SQL+@SELECTQUERY+',0 avgrate,0 COGS,0 BalanceQty,0 IsReconcile,0 BalanceValue
		FROM INV_DocDetails D WITH(NOLOCK) 
		INNER JOIN INV_Product P WITH(NOLOCK) ON P.ProductID=D.ProductID
		LEFT JOIN COM_DocCCData DCC WITH(NOLOCK) ON DCC.InvDocDetailsID=D.InvDocDetailsID '+@FROMQUERY+'
		LEFT JOIN COM_UOM UOM WITH(NOLOCK) ON UOM.UOMID=D.Unit
		LEFT JOIN ACC_Accounts A WITH(NOLOCK) ON A.AccountID=D.CreditAccount
		LEFT JOIN ACC_Accounts Dr WITH(NOLOCK) ON Dr.AccountID=D.DebitAccount 
		WHERE P.ProductID IN ('+@Products+') AND IsQtyIgnored=0 AND D.VoucherType=1 AND D.DocumentType<>3 AND Quantity>0'
	 if(ISNULL(@DateFilterCol,'')<>'')
		SET @SQL=@SQL+@DateFilterCol
	 if(ISNULL(@UnAppSQL,'')<>'')
		SET @SQL=@SQL+@UnAppSQL
	 if(ISNULL(@CurrWHERE,'')<>'')
		SET @SQL=@SQL+@CurrWHERE
	 if(ISNULL(@WHERE,'')<>'' AND @WHERE<>NULL)
		SET @SQL=@SQL+ISNULL(@WHERE,'')
	 if(ISNULL(@TagSQL,'')<>'')
		SET @SQL=@SQL+' '+@TagSQL
		
	SET @SQL=@SQL+' UNION ALL
		SELECT P.ProductID,P.ProductName,'+@TransactionsBy+',D.VoucherNo,D.InvDocDetailsID,A.AccountName,
		NULL RecQty,NULL RecUnit,NULL RecRate,NULL RecValue,
		Quantity IssQty,UOM.UnitName IssUnit,D.'+@ValColumn+'/D.Quantity IssRate,D.'+@ValColumn+' IssValue,D.UOMConvertedQty,D.VoucherType,D.DocumentType,2 OP,case when D.DocumentType=5 then 1 else 0 end ST'
	if(@DefValuation=8)
		SET @SQL=@SQL+',CASE WHEN P.ProductTypeID=5 THEN ISNULL((SELECT TOP 1 BD.'+@ValColumn+'/BD.Quantity FROM INV_DocDetails BD WITH(NOLOCK) WHERE BD.InvDocDetailsID=D.RefInvDocDetailsID AND BD.BatchID=D.BatchID),0)*D.Quantity ELSE D.'+@ValColumn+' END BatchValue'	
	SET @SQL=@SQL+@SELECTQUERY+',0 avgrate,0 COGS,0 BalanceQty,0 IsReconcile,0 BalanceValue
		FROM INV_DocDetails D WITH(NOLOCK) 
		INNER JOIN INV_Product P WITH(NOLOCK) ON P.ProductID=D.ProductID
		LEFT JOIN COM_DocCCData DCC WITH(NOLOCK) ON DCC.InvDocDetailsID=D.InvDocDetailsID '+@FROMQUERY+'
		LEFT JOIN COM_UOM UOM WITH(NOLOCK) ON UOM.UOMID=D.Unit
		LEFT JOIN ACC_Accounts A WITH(NOLOCK) ON A.AccountID=D.DebitAccount
		WHERE P.ProductID IN ('+@Products+') AND IsQtyIgnored=0 AND D.VoucherType=-1 AND Quantity>0'
	if(ISNULL(@DateFilterCol,'')<>'')
		SET @SQL=@SQL+@DateFilterCol
	 if(ISNULL(@UnAppSQL,'')<>'')
		SET @SQL=@SQL+@UnAppSQL
	 if(ISNULL(@CurrWHERE,'')<>'')
		SET @SQL=@SQL+@CurrWHERE
	 if(ISNULL(@WHERE,'')<>'' AND @WHERE<>NULL)
		SET @SQL=@SQL+ISNULL(@WHERE,'')
	 if(ISNULL(@TagSQL,'')<>'')
		SET @SQL=@SQL+' '+@TagSQL
	SET @SQL=@SQL+' ORDER BY '+@Order
	SET @SQL=@SQL+' INSERT INTO #Tbl SELECT PRODUCTID,DOCDATE,RecQty,RecRate,RecValue,VoucherType,DocumentType,0,UOMConvertedQty,0,0,0,docdate,IssValue,InvDocDetailsID from #tblMain WHERE VOUCHERTYPE<>0'
	print(@SQL)
	EXEC(@SQL)
	
	DECLARE @LPRateI int,@LPRateCNT int
	DECLARE @TblLastRate AS TABLE(ID INT IDENTITY(1,1) NOT NULL PRIMARY KEY,ProductID INT,Rate FLOAT)
	if (@DefValuation=4 or @DefValuation=5)
	begin
		SET @SQL='SELECT P.ProductID,P.ProductName,'
		if @DefValuation=4
			SET @SQL=@SQL+@GrossColumn+'/UOMConvertedQty RecRate'
		else if @DefValuation=5
			SET @SQL=@SQL+@ValColumn+'/UOMConvertedQty RecRate'
		SET @SQL=@SQL+'
			FROM INV_DocDetails D WITH(NOLOCK) 
			INNER JOIN INV_Product P WITH(NOLOCK) ON P.ProductID=D.ProductID
			LEFT JOIN COM_DocCCData DCC WITH(NOLOCK) ON DCC.InvDocDetailsID=D.InvDocDetailsID '+@FROMQUERY+'
			LEFT JOIN ACC_Accounts A WITH(NOLOCK) ON A.AccountID=D.CreditAccount
			WHERE P.ProductID IN ('+@Products+') AND IsQtyIgnored=0 AND D.VoucherType=1 AND D.DocumentType<>3 AND Quantity>0'
		 if(ISNULL(@DateFilterLPRate,'')<>'')
			SET @SQL=@SQL+@DateFilterLPRate
		 if(ISNULL(@UnAppSQL,'')<>'')
			SET @SQL=@SQL+@UnAppSQL
		 if(ISNULL(@CurrWHERE,'')<>'')
			SET @SQL=@SQL+@CurrWHERE
		 if(ISNULL(@WHERE,'')<>'' AND @WHERE<>NULL)
			SET @SQL=@SQL+ISNULL(@WHERE,'')
		 if(ISNULL(@TagSQL,'')<>'')
			SET @SQL=@SQL+' '+@TagSQL
		SET @SQL=@SQL+' ORDER BY P.ProductID,DocDate,VoucherNo'
	    --print(@SQL)
		insert into @TblLastRate
		EXEC(@SQL)
		
		SELECT @LPRateCNT=COUNT(*) FROM @TblLastRate
	end
	
	DECLARE @TblProducts AS TABLE(ID INT IDENTITY(1,1) NOT NULL PRIMARY KEY,ProductID INT,ProductName NVARCHAR(MAX))
	DECLARE @TblOpeningTransaction AS TABLE(ProductID INT,Qty FLOAT,Rate FLOAT,DocumentType INT)

	INSERT INTO @TblProducts(ProductID,ProductName)
		SELECT ProductID,ProductName FROM #TblProds
		
	--EXEC SPSplitString @Products,','
	
	SELECT @PRD_I=1,@PRD_COUNT=COUNT(*) FROM @TblProducts
				
	DECLARE @TotalSaleSQL NVARCHAR(MAX),@RecQty FLOAT,@RecRate FLOAT,@RecValue FLOAT,@VoucherType INT
	DECLARE	@I INT,@COUNT INT,@TotalSaleQty FLOAT,@ID INT,@AvgRate FLOAT,@DocumentType INT
	
	DECLARE @Tbl AS TABLE(ID INT IDENTITY(1,1) NOT NULL PRIMARY KEY,Date FLOAT,Qty FLOAT,RecRate FLOAT,RecValue FLOAT,VoucherType INT,DocumentType INT)
	DECLARE @TransactionsFound BIT,@SALESQTY FLOAT,@Qty FLOAT,@StockValue FLOAT,@IsOpening BIT
	DECLARE @lstRecTbl AS TABLE(ID INT,Qty FLOAT,Rate FLOAT,DocumentType INT)
	CREATE TABLE #lstRecTbl2 (ID INT,Qty FLOAT,Rate FLOAT,DocumentType INT)

	IF @TagSQL IS NOT NULL AND @TagSQL<>''
		SET @TagSQL=' INNER JOIN COM_DocCCData DCC WITH(NOLOCK) ON DCC.InvDocDetailsID=D.InvDocDetailsID '+@TagSQL
	ELSE
		SET @TagSQL=''	
		
	WHILE(@PRD_I<=@PRD_COUNT)
	BEGIN
		SELECT @ProductID=ProductID FROM @TblProducts WHERE ID=@PRD_I
		
		SELECT @AvgRate=0, @Qty=0,@StockValue=0,@IsOpening=1
		
		IF @DefValuation=0
			SELECT @Valuation=ValuationID FROM INV_Product WITH(NOLOCK) WHERE ProductID=@ProductID
			
		SET @SQL='DECLARE @FromDate FLOAT,@ToDate FLOAT,@ProductID INT
				  SET @FromDate='+CONVERT(NVARCHAR,CONVERT(FLOAT,@FromDate))+'
				  SET @ToDate='+CONVERT(NVARCHAR,CONVERT(FLOAT,@ToDate))+'
				  SET @ProductID='+CONVERT(NVARCHAR,@ProductID)+' '

		IF @IsOpening=1
		BEGIN
			SET @SQL=@SQL+'SELECT DocDate,Qty,RecRate,RecValue,VoucherType,DocumentType FROM ('
			if(@CloseDt is not null)
			begin
				SET @SQL=@SQL+'
						SELECT CloseDate DocDate'+@TransactionsByOpHardClose+',''HardClose'' VoucherNo,Qty,Rate RecRate,BalValue RecValue,1 VoucherType,0 DocumentType,1 OP,2 ST
						FROM INV_ProductClose DCC WITH(NOLOCK)
						WHERE ProductID=@ProductID AND CloseDate='+convert(nvarchar,(@CloseDt-1))
			 if(ISNULL(@DIMWHERE,'')<>'' AND @DIMWHERE<>NULL)
				SET @SQL=@SQL+' '+ISNULL(@WHERE,'')
				
				SET @SQL=@SQL+' UNION ALL '
			end
			SET @SQL=@SQL+'
				SELECT '+@TransactionsByOp+',D.VoucherNo,D.UOMConvertedQty Qty,D.'+@ValColumn+'/D.UOMConvertedQty RecRate,D.'+@ValColumn+' RecValue,D.VoucherType,D.DocumentType,case when D.DocumentType=3 then 1 else 2 end OP,case when D.DocumentType=5 then 1 else 2 end ST
				FROM INV_DocDetails D WITH(NOLOCK) '+@TagSQL+'
				WHERE D.ProductID=@ProductID AND D.IsQtyIgnored=0 AND D.UOMConvertedQty!=0 AND D.VoucherType=1'
				if(ISNULL(@DateFilterOp1,'')<>'')
					SET @SQL=@SQL+@DateFilterOp1
				if(ISNULL(@UnAppSQL,'')<>'')
					SET @SQL=@SQL+@UnAppSQL
				if(ISNULL(@CurrWHERE,'')<>'')
					SET @SQL=@SQL+@CurrWHERE
				if(ISNULL(@WHERE,'')<>'' AND @WHERE<>NULL)
					SET @SQL=@SQL+ISNULL(@WHERE,'')
				
			SET @SQL=@SQL+' UNION ALL
				SELECT '+@TransactionsByOp+',D.VoucherNo,D.UOMConvertedQty,0 RecRate'
				if @DefValuation=7
					SET @SQL=@SQL+',D.'+@ValColumn+' RecValue'
				else if @DefValuation=8
					SET @SQL=@SQL+',CASE WHEN P.ProductTypeID=5 THEN ISNULL((SELECT TOP 1 BD.'+@ValColumn+'/BD.Quantity FROM INV_DocDetails BD WITH(NOLOCK) WHERE BD.InvDocDetailsID=D.RefInvDocDetailsID AND BD.BatchID=D.BatchID),0)*D.Quantity ELSE D.'+@ValColumn+' END RecValue'
				else
					SET @SQL=@SQL+',0 RecValue'					
				SET @SQL=@SQL+',-1 VoucherType,D.DocumentType,2 OP,case when D.DocumentType=5 then 1 else 0 end ST
								FROM INV_DocDetails D WITH(NOLOCK) '
				if @DefValuation=8
					SET @SQL=@SQL+'INNER JOIN INV_Product P WITH(NOLOCK) ON P.ProductID=D.ProductID '
				SET @SQL=@SQL+@TagSQL+'
					WHERE D.ProductID=@ProductID AND D.IsQtyIgnored=0 AND D.VoucherType=-1'
				 if(ISNULL(@DateFilterOp2,'')<>'')
					SET @SQL=@SQL+@DateFilterOp2
				 if(ISNULL(@UnAppSQL,'')<>'')
					SET @SQL=@SQL+@UnAppSQL
				 if(ISNULL(@CurrWHERE,'')<>'')
					SET @SQL=@SQL+@CurrWHERE
				 if(ISNULL(@WHERE,'')<>'' AND @WHERE<>NULL)
					SET @SQL=@SQL+ISNULL(@WHERE,'')
		END
		SET @SQL=@SQL+') AS T'
		
		--BELOW CODE COMMENTED TO ADD ST ORDER BY 
		SET @SQL=@SQL+' ORDER BY '+replace(@Order,',RecQty DESC',',Qty DESC')--DocDate,ST DESC,VoucherNo,VoucherType DESC'
		
		print(@SQL)
		--print(@TotalSaleSQL)
		
		DELETE FROM @Tbl
		INSERT INTO @Tbl(Date,Qty,RecRate,RecValue,VoucherType,DocumentType)
		EXEC(@SQL)
		
		SELECT @I=1, @COUNT=COUNT(*) FROM @Tbl
		DECLARE @SPInvoice cursor, @nStatusOuter int
		DECLARE @lstI INT,@lstCNT INT,@lstQty FLOAT,@lstRate FLOAT,@lstDocumentType INT
		DECLARE @dblValue FLOAT,@dblUOMRate FLOAT,@OpBalanceQty FLOAT,@dblAvgRate FLOAT,@OpBalanceValue FLOAT,@dblCOGS FLOAT,@r int
		set @r=1
		IF @Valuation=6
		BEGIN
			DECLARE @Date float,@dtDate datetime,@Mn int,@Yr int,@PrMn int,@PrYr int,@dblQty float,@dblMnOpValue float,@dblIssueQty float,@dblPrevAvgRate float
		
			SET @SPInvoice = cursor for 
			SELECT Date,VoucherType,Qty,RecValue,ID,DocumentType FROM @Tbl
			
			OPEN @SPInvoice 
			SET @nStatusOuter = @@FETCH_STATUS
			
			SELECT @I=1, @COUNT=COUNT(*) FROM @Tbl
			
			FETCH NEXT FROM @SPInvoice Into @Date,@VoucherType,@RecQty,@RecValue,@ID,@DocumentType
			SET @nStatusOuter = @@FETCH_STATUS
			
			set @dblQty=0
			set @dblValue=0
			set @OpBalanceQty=0
			set @dblMnOpValue=0
			set @dblPrevAvgRate=0
			set @dblIssueQty=0
			
			WHILE(@nStatusOuter <> -1)
			BEGIN
				set @dtDate=convert(datetime,@Date)
				set @Mn=month(@dtDate)
				set @Yr=year(@dtDate)
	
				if (@PrMn is null or @PrMn!=@Mn or @PrYr!=@Yr)
                begin
					if(@PrMn is not null)
                    begin
						if(@dblQty>0)
							set @dblPrevAvgRate=(@dblMnOpValue+@dblValue)/@dblQty
						set @dblAvgRate=@dblPrevAvgRate
                        set @dblQty=(@dblQty-@dblIssueQty);
                        set @dblMnOpValue=@dblQty*@dblAvgRate;
                     end
                     set @PrMn=@Mn
                     set @PrYr=@Yr
                     set @dblIssueQty=0
                     set @dblValue=0
                end
                if @VoucherType=1
                begin
				    if (@DocumentType!= 6 and @DocumentType!=39)
                    begin
                        set @dblQty=@dblQty+@RecQty
                        set @dblValue=@dblValue+@RecValue
                    end
                end
                else
                begin
                    set @dblIssueQty=@dblIssueQty+@RecQty
                end

				FETCH NEXT FROM @SPInvoice Into @Date,@VoucherType,@RecQty,@RecValue,@ID,@DocumentType
				SET @nStatusOuter = @@FETCH_STATUS
			END
			
			set @OpBalanceQty=@dblQty-@dblIssueQty
			set @dblAvgRate=@dblPrevAvgRate
			if(@PrMn is not null)
            begin				
                if @dblQty>0
                    set @dblAvgRate=(@dblMnOpValue+@dblValue)/@dblQty
            end
            set @OpBalanceValue=@OpBalanceQty*@dblAvgRate
           
		END
		ELSE
		BEGIN
			SET @SPInvoice = cursor for 
			SELECT VoucherType,Qty,RecValue,ID,DocumentType FROM @Tbl
			
			OPEN @SPInvoice 
			SET @nStatusOuter = @@FETCH_STATUS
			
			FETCH NEXT FROM @SPInvoice Into @VoucherType,@RecQty,@RecValue,@ID,@DocumentType
			SET @nStatusOuter = @@FETCH_STATUS

			SELECT @OpBalanceValue=0,@OpBalanceQty=0,@lstI=1,@lstCNT=0,@dblAvgRate=0
	
			delete from @lstRecTbl
			
			--Set Last Purchase Rate
			if (@Valuation=4 or @Valuation=5)
			begin
				set @dblAvgRate=0
				set @LPRateI=@LPRateCNT
				while(@LPRateI>0)
				begin
					SELECT @dblAvgRate=Rate FROM @TblLastRate where ProductID=@ProductID and ID=@LPRateI
					if @@rowcount=1
						break
					set @LPRateI=@LPRateI-1
				end
			end
			
			SET @I=1
			WHILE(@nStatusOuter <> -1)
			BEGIN
				if(@RecQty<0)
				begin
					set @RecQty=-@RecQty
					set @VoucherType=-@VoucherType
				end	
			
				if @VoucherType=1
				begin
						
					set @dblValue = @RecValue
					set @dblUOMRate = @dblValue / @RecQty;
					
					if (@OpBalanceQty < 0)
					begin
						set @OpBalanceQty = @RecQty + @OpBalanceQty;
						if (Abs(@OpBalanceQty) < 0.00000001)
							set @OpBalanceQty = 0;
						if @ShowNegativeStock=0--NegStkChange
						begin
							if (@OpBalanceQty > 0)
								set @RecQty = @OpBalanceQty;
							else
								set @RecQty = 0;
						end
					end
					else
					begin
						SET @OpBalanceQty = @OpBalanceQty+@RecQty;
					end
					
					if (@Valuation=4 or @Valuation=5)--Last Purchase Rate/Landing Rate
						 set @dblUOMRate=@dblAvgRate
	              --       select @RecQty,@ShowNegativeStock
					if ((@RecQty>0 and @ShowNegativeStock=0) or (@RecQty!=0 and @ShowNegativeStock=1))--NegStkChange (@RecQty>0)
					begin
						--For Sales Return Voucher Avg Rate will be current Avg Rate
						if (@DocumentType=6 or @DocumentType=39)
						BEGIN
							if @dblAvgRate IS NULL
								set @dblAvgRate=0
							if (@Valuation=7 OR @Valuation=8)
								set @dblAvgRate=@dblUOMRate
							else
								set @dblUOMRate=@dblAvgRate
						END
						if @ShowNegativeStock=0
						begin
							if (@OpBalanceValue < 0)
								set @OpBalanceValue=0
						end
						set @OpBalanceValue += @RecQty*@dblUOMRate
					end
					
					if (@Valuation!=4 and @Valuation!=5)
					begin
						if @ShowNegativeStock=0--NegStkChange
						begin
							if @OpBalanceQty>0
								set @dblAvgRate=@OpBalanceValue/@OpBalanceQty;
							else
							begin
								set @dblAvgRate = 0;
								set @OpBalanceValue = 0;
							end
						end
						else
						begin
							if @OpBalanceQty!=0
								set @dblAvgRate=@OpBalanceValue/@OpBalanceQty;
						end
					end

					if (@RecQty>0)
					begin
						SELECT @lstCNT=@lstCNT+1
						INSERT INTO @lstRecTbl(ID,Qty,Rate,DocumentType)
						VALUES(@lstCNT,@RecQty,@dblUOMRate,@DocumentType)
					end
					--select convert(datetime,@Date),@dblAvgRate,@RecQty
				end
				else
				begin
					set @OpBalanceQty=@OpBalanceQty-@RecQty

					if (@Valuation=3 or @Valuation=4 or @Valuation=5)--WEIGHTED AVGG
						set @OpBalanceValue = @dblAvgRate * @OpBalanceQty;
					else if (@Valuation=7 or @Valuation=8)--Invoice Rate
					begin
						set @OpBalanceValue=@OpBalanceValue-@RecValue
						if(@OpBalanceValue<0)
							set @OpBalanceValue=0
						if(@OpBalanceQty<=0)
							set @dblAvgRate=0
						else	
							set @dblAvgRate=@OpBalanceValue/@OpBalanceQty
					end
					else if (@Valuation = 1 OR @Valuation = 2)--FIFO & LIFO
					begin
						set @dblCOGS = 0;
						
						if (@Valuation=1)
						begin
							while(@lstI<=@lstCNT)
							begin
								SELECT @lstQty=Qty,@lstRate=Rate FROM @lstRecTbl WHERE ID=@lstI
								set @RecQty=@RecQty-@lstQty
								if(@RecQty<0)
								begin
									set @dblCOGS=@dblCOGS+(@lstQty+@RecQty)*@lstRate
									UPDATE @lstRecTbl SET Qty=-@RecQty WHERE ID=@lstI
									break;
								end
								else
								begin
									set @dblCOGS=@dblCOGS+(@lstQty*@lstRate);
									set @lstI=@lstI+1
									if (@RecQty=0)
										break;
								end
							end
						end
						else if (@Valuation=2)
						begin
							set @lstI=@lstCNT
							while(@lstI>=1)
							begin
								SELECT @lstQty=Qty,@lstRate=Rate FROM @lstRecTbl WHERE ID=@lstI
								if @lstQty IS NULL
									continue;
								
								set @RecQty=@RecQty-@lstQty
								if(@RecQty<0)
								begin
									set @dblCOGS=@dblCOGS+(@lstQty+@RecQty)*@lstRate
									UPDATE @lstRecTbl SET Qty=-@RecQty WHERE ID=@lstI
									break;
								end
								else
								begin
									set @dblCOGS=@dblCOGS+(@lstQty*@lstRate);
									DELETE FROM @lstRecTbl WHERE ID=@lstI
							        
									set @lstI=@lstI-1
									if (@RecQty=0)
										break;
								end
							end
						end

						set @OpBalanceValue=@OpBalanceValue-@dblCOGS;

						if (@OpBalanceValue < 0)
							set @OpBalanceValue = 0;
						
						if (@Valuation!=4 and @Valuation!=5)
						begin
							if (@OpBalanceQty > 0)
								set @dblAvgRate = @OpBalanceValue / @OpBalanceQty;
							--else
							--	set @dblAvgRate = 0;
						end

					end
				end
				
				FETCH NEXT FROM @SPInvoice Into @VoucherType,@RecQty,@RecValue,@ID,@DocumentType
				SET @nStatusOuter = @@FETCH_STATUS
			END
		END -- End of else of if val=6
			
		IF @OpBalanceQty=0
		BEGIN
			SET @OpBalanceValue=0
		END
		
		CLOSE @SPInvoice
		DEALLOCATE @SPInvoice
		
		
		IF (@OpBalanceQty<>0 or @dblAvgRate>0) -- AvgRate condition added  if stock return document is comes as first row
		BEGIN
			INSERT INTO @TblOpening
			VALUES(@ProductID,@OpBalanceQty,@dblAvgRate,@OpBalanceValue,@DocumentType)
			
			IF @OpBalanceQty>0
			BEGIN
				IF @Valuation=1
					INSERT INTO @TblOpeningTransaction(ProductID,Qty,Rate,DocumentType)
					SELECT @ProductID ProductID,Qty,Rate,DocumentType FROM @lstRecTbl WHERE ID>=@lstI --ORDER BY ID
				ELSE IF @Valuation=2
					INSERT INTO @TblOpeningTransaction(ProductID,Qty,Rate,DocumentType)
					SELECT @ProductID ProductID,Qty,Rate,DocumentType FROM @lstRecTbl ORDER BY ID
			END
		END
		
		SET @PRD_I=@PRD_I+1
	END
	
	--Products Opening Data
	--SELECT * FROM @TblOpening 
	
	--SELECT @BalQty,@AvgRate,@BalValue
	--SELECT * FROM @TblOpeningTransaction
	
	--REPORT DATA--------------------------------------------------------------------------------------------------
	DECLARE @Gross FLOAT,@PrdName nvarchar(max),@IsValExist bit,@RRRecQty float,@RRRecValue float,@RDocumentType int,@RIssValue float,@RBatchValue float,@RstrPeriodMn DATETIME,@INVID FLOAT
	--DECLARE @Mn int,@Yr int,@PrMn int,@PrYr int
	SET @IsValExist=0
	--PRODUCT LOOP
	SELECT @PRD_I=1,@PRD_COUNT=COUNT(*) FROM @TblProducts
	WHILE(@PRD_I<=@PRD_COUNT)
	BEGIN
		set @OpBalanceQty=0
		set @OpBalanceValue=0
		set @dblAvgRate=0
		set @IsValExist=0
		set @dblQty=0
		set @dblIssueQty=0
		SET @INVID=0
		set @lstCNT=0
		set @lstI=1
		set @PrdName=''
		TRUNCATE TABLE #lstRecTbl2
		SELECT @ProductID=ProductID,@PrdName=ProductName FROM @TblProducts WHERE ID=@PRD_I
		SELECT @AvgRate=0, @Qty=0,@StockValue=0,@IsOpening=1
		IF @DefValuation=0
			SELECT @Valuation=ValuationID FROM INV_Product WITH(NOLOCK) WHERE ProductID=@ProductID
		SELECT @OpBalanceQty=isnull(opqty,0),@OpBalanceValue=isnull(OpValue,0),@dblAvgRate=isnull(AvgRate,0) FROM @TblOpening WHERE ProductID=@ProductID
		if((select count(*) from @TblOpeningTransaction where ProductID=@ProductID)>0)
		BEGIN
			if (@Valuation = 1 or @Valuation = 2)
			begin
				
				SELECT @lstCNT=@lstCNT+1
				INSERT INTO #lstRecTbl2(ID,Qty,Rate,DocumentType) SELECT @lstCNT,qty,Rate,DocumentType FROM @TblOpeningTransaction WHERE ProductID=@ProductID
			end
		END
		if((select count(*) from @TblOpening where ProductID=@ProductID)>0)
		BEGIN
		PRINT '1'
			if((select count(*) from #tblmain where ProductID=@ProductID)>1)
				UPDATE #tblmain SET BalanceQty=@OpBalanceQty ,AvgRate=@dblAvgRate ,BalanceValue=@OpBalanceValue WHERE ProductID=@ProductID AND VOUCHERTYPE=0
			else
				DELETE FROM #tblmain WHERE ProductID=@ProductID AND VOUCHERTYPE=0
		END
		ELSE
		BEGIN
		PRINT '2'
			DELETE FROM #tblmain WHERE ProductID=@ProductID AND VOUCHERTYPE=0
		END
		PRINT '@OpBalanceQty'
		PRINT @OpBalanceQty
		----valuation 4,5,6
		if(@Valuation=4 and @Valuation=5)
		begin
			SELECT @I=1, @COUNT=COUNT(*) FROM #Tbl WHERE VOUCHERTYPE<>0
			WHILE(@I<=@COUNT)
			BEGIN
			print '4'
				SELECT @dblQty=UOMConvertedQty,@dblValue=RecValue from #Tbl where ProductID=@ProductID and VoucherType=1
				print @dblQty
				if(@dblQty>0 and @IsValExist=0)
				begin
					 set @dblAvgRate = @dblValue / @dblQty
	 			 	set @IsValExist=1	
				end
				
			SET @I=@I+1
			END
		end
		else if(@Valuation=6)
		begin
			DECLARE @strPeriodMn datetime,@RRecQty float,@UUOMConvertedQty float,@RRecValue float,@DDocumentType int
			set @RRecQty=0
			set @dblMnOpValue = 0
			set @dblIssueQty = 0 
			set @dblPrevAvgRate = @dblAvgRate
			set @dblQty = @OpBalanceQty
            set @dblMnOpValue = @OpBalanceValue
            SELECT @I=1, @COUNT=COUNT(*) FROM #Tbl
			WHILE(@I<=@COUNT)
			BEGIN
				SELECT @strPeriodMn=convert(datetime,DocDate),@RRecQty=RecQty,@DDocumentType=DocumentType,
					   @UUOMConvertedQty=UOMConvertedQty,@RRecValue=RecValue from #Tbl where ProductID=@ProductID
			    set @Mn=month(@strPeriodMn)
			    set @Yr=year(@strPeriodMn)
				 if (@PrMn is null or @PrMn!=@Mn or @PrYr!=@Yr)--(@strPrev != @strPeriodMn)
                 begin
                     --if (@I > 0)
                     if(@PrMn is not null)
                     begin
                         if (@dblQty > 0)
                         begin
                            set @dblPrevAvgRate = (@dblMnOpValue + @dblValue) / @dblQty                                
                         end
                         set @dblQty = (@dblQty - @dblIssueQty)
                     end
                     --set @strPrev = @strPeriodMn
                      set @PrMn=@Mn
                 set @PrYr=@Yr
                     set @dblIssueQty = 0
                     set @dblValue = 0
                 end

                 if (@RRecQty > 0)
                 begin
                     if (@DDocumentType != 6 and @DDocumentType != 39)
                     begin
                         set @dblQty +=@UUOMConvertedQty
                         set @dblValue +=@RRecValue
                     end
                 end
                 else
                 begin
                     set @dblIssueQty += @UUOMConvertedQty
                 end
			SET @I=@I+1
			END
		end
		---		
		TRUNCATE TABLE #TblTransactions
		
		--ROWS OF PRODUCT
		INSERT INTO #TblTransactions 
			SELECT PRODUCTID ,Date ,Qty ,RecRate ,	RecValue ,VoucherType ,DocumentType ,AVGRATE ,UOMConvertedQty ,COGS ,BalanceQty ,BalanceValue ,	docdate ,IssValue,InvDocDetailsID  from #Tbl
			WHERE ProductID=@ProductID ORDER BY ProductID,DocDate
		SELECT @I=1, @COUNT=COUNT(*) FROM #TblTransactions
		WHILE(@I<=@COUNT)
		BEGIN
			    --#region Balance Data
				set @dblQty=0
				set @RRRecQty=0	
				set @RRRecValue=0
				--set @RstrPeriodMn=''
				set @RDocumentType=0
				set @RIssValue=0
				SET @RBatchValue=0
				SET @INVID=0
		
                SELECT @dblQty=UOMConvertedQty ,@RRRecQty=Qty,@RRRecValue=RecValue,@RstrPeriodMn=convert(DATETIME,docdate),@INVID=InvDocDetailsID,
								@RDocumentType=DocumentType,@RIssValue=IssValue from #TblTransactions where ProductID=@ProductID and id=@i
               if (@RRRecQty > 0)
               begin
                    set @dblValue = @RRRecValue
					set @dblUOMRate = @dblValue / @dblQty;

                    if (@OpBalanceQty < 0)
                   begin
                        set @OpBalanceQty = @dblQty + @OpBalanceQty;
                        if (Abs(@OpBalanceQty) < 0.00000001)
                           set @OpBalanceQty = 0;
                        if (@ShowNegativeStock=0)
                        begin
                            if (@OpBalanceQty > 0)
                                set @dblQty = @OpBalanceQty;
                            else
                            begin
                                set @dblQty = 0;
                            end
                        end
                    end
                    else
                    begin
                        set @OpBalanceQty += @dblQty;
                    end

                    if (@Valuation = 4 or @Valuation = 5)--Last Rate
                    begin
                        set @dblUOMRate = @dblAvgRate;
                    end
                    else if (@Valuation = 6)--Periodic Monthly
                    begin
                        set @strPeriodMn = @RstrPeriodMn
                    end

                    if (@dblQty > 0)
                    begin
                        --For Sales Return Voucher Avg Rate will be current Avg Rate
                        if (@RDocumentType= 6 or @RDocumentType= 39)
                        begin
                            if (@Valuation = 7)
                                set @dblAvgRate = @dblUOMRate;
                            else
                                set @dblUOMRate = @dblAvgRate;

                          	UPDATE #Tbl SET COGS=@dblQty * @dblAvgRate WHERE  PRODUCTID=@ProductID and DocumentType=@RDocumentType AND InvDocDetailsID=@INVID
                        end
                       --Code added to stop -ve avg rate
                        if (@ShowNegativeStock=0)
                        begin
                            if (@OpBalanceValue < 0)
                                set @OpBalanceValue = 0;
                        end
                        set @OpBalanceValue += @dblQty * @dblUOMRate;
                    end

                    if (@Valuation != 4 and @Valuation != 5 and @Valuation != 6)
                    begin
                        if (@ShowNegativeStock=0)
                        begin
                            if (@OpBalanceQty > 0)
                                set @dblAvgRate = @OpBalanceValue / @OpBalanceQty;
                            else
                            begin
                                set @dblAvgRate = 0;
                                set @OpBalanceValue = 0;
                            end
                        end
                        else
                        begin
                            if (@OpBalanceQty != 0)
                                set @dblAvgRate = @OpBalanceValue / @OpBalanceQty;
                        end
                    end


                    if (@dblQty > 0)
                    begin
						if (@Valuation = 1 or @Valuation = 2)
						begin
							SELECT @lstCNT=@lstCNT+1
							INSERT INTO #lstRecTbl2(ID,Qty,Rate,DocumentType)
							VALUES(@lstCNT,@dblQty,@dblUOMRate,@RDocumentType)
						end
                    end
                end
                else
                begin
                    set  @OpBalanceQty -= @dblQty;
                    if (@Valuation = 3 or @Valuation = 4 or @Valuation = 5)--WEIGHTED AVGG
                    begin
                        set @OpBalanceValue = @dblAvgRate * @OpBalanceQty;
                        UPDATE #Tbl SET COGS=@dblQty * @dblAvgRate WHERE  PRODUCTID=@ProductID and DocumentType=@RDocumentType AND InvDocDetailsID=@INVID
                    end
                    else if (@Valuation = 6)--Periodic Monthly
                    begin
                    print '@RstrPeriodMn'
                    print @RstrPeriodMn
                       set @strPeriodMn = @RstrPeriodMn;
                       set @OpBalanceValue = @dblAvgRate * @OpBalanceQty;
                        UPDATE #Tbl SET COGS=@dblQty * @dblAvgRate WHERE  PRODUCTID=@ProductID and DocumentType=@RDocumentType AND InvDocDetailsID=@INVID
                    end
                    else if (@Valuation = 7)--Invoice Rate
                    begin
                        set @OpBalanceValue = @OpBalanceValue -@RIssValue
                        if (@OpBalanceValue < 0)
                            set @OpBalanceValue = 0;
                        if (@OpBalanceQty = 0)
                        begin
                            set @dblAvgRate = 0;
                            set @OpBalanceValue = 0;
                        end
                        else
                            set @dblAvgRate = @OpBalanceValue / @OpBalanceQty;
                            
                        UPDATE #Tbl SET COGS=@RIssValue WHERE  PRODUCTID=@ProductID and DocumentType=@RDocumentType AND InvDocDetailsID=@INVID
                    end
                    else if (@Valuation = 8)--Batch Rate
                    begin
                        set @OpBalanceValue = @OpBalanceValue - @RBatchValue
                        if (@OpBalanceValue < 0)
                            set @OpBalanceValue = 0;
                        if (@OpBalanceQty = 0)
                        begin
                            set @dblAvgRate = 0;
                            set @OpBalanceValue = 0;
                        end
                        else
                           set  @dblAvgRate = @OpBalanceValue / @OpBalanceQty;
                        UPDATE #Tbl SET COGS=@RBatchValue WHERE  PRODUCTID=@ProductID and DocumentType=@RDocumentType AND InvDocDetailsID=@INVID
                    end
                    else if (@Valuation = 1 or @Valuation = 2)--FIFO & LIFO
					begin
                        set @dblCOGS = 0
						if (@Valuation=1)
						begin
							while(@lstI<=@lstCNT)
							begin
								SELECT @lstQty=Qty,@lstRate=Rate FROM #lstRecTbl2 WHERE ID=@lstI
								 set @dblQty = @dblQty -@lstQty
								if(@dblQty<0)
								begin
									set @dblCOGS=@dblCOGS+(@lstQty+@dblQty)*@lstRate
									UPDATE #lstRecTbl2 SET Qty=-@dblQty WHERE ID=@lstI
									break;
								end
								else
								begin
									set @dblCOGS=@dblCOGS+(@lstQty*@lstRate)
									set @lstI=@lstI+1
									if (@dblQty=0)
										break;
								end
							end
						end
						else if (@Valuation=2)
						begin
							set @lstI=@lstCNT
							while(@lstI>=1)
							begin
								SELECT @lstQty=Qty,@lstRate=Rate FROM #lstRecTbl2 WHERE ID=@lstI
								if @lstQty IS NULL
									continue;
								
								set @dblQty=@dblQty-@lstQty
								if(@dblQty<0)
								begin
								
									set @dblCOGS=@dblCOGS+(@lstQty+@dblQty)*@lstRate
									UPDATE #lstRecTbl2 SET Qty=-@dblQty WHERE ID=@lstI
									break;
								end
								else
								begin
									set @dblCOGS=@dblCOGS+(@lstQty*@lstRate);
								
									DELETE FROM #lstRecTbl2 WHERE ID=@lstI
									set @lstI=@lstI-1
									set @lstCNT=@lstCNT-1
									if (@dblQty=0)
										break;
								end
							end
						end
						
				         set  @OpBalanceValue = @OpBalanceValue - @dblCOGS;

                        if (@OpBalanceValue < 0)
                            set @OpBalanceValue = 0;

                        if (@Valuation != 4 and @Valuation != 5)
                        begin
                            if (@OpBalanceQty > 0)
                                set @dblAvgRate = @OpBalanceValue / @OpBalanceQty;
                        end
                        print '@dblCOGS'
                        print @dblCOGS
	                    UPDATE #Tbl SET COGS=@dblCOGS WHERE  PRODUCTID=@ProductID and DocumentType=@RDocumentType AND InvDocDetailsID=@INVID
                    end
                end

                if (@OpBalanceQty = 0)
                    set @OpBalanceValue = 0
                    
                UPDATE #Tbl SET AvgRate=@dblAvgRate WHERE  PRODUCTID=@ProductID and DocumentType=@RDocumentType  AND InvDocDetailsID=@INVID
                UPDATE #Tbl SET BalanceQty=@OpBalanceQty WHERE  PRODUCTID=@ProductID and DocumentType=@RDocumentType AND InvDocDetailsID=@INVID
                UPDATE #Tbl SET BalanceValue=@OpBalanceValue WHERE  PRODUCTID=@ProductID and DocumentType=@RDocumentType AND InvDocDetailsID=@INVID
		
		SET @I=@I+1
		END
					
		IF @OpBalanceQty=0
			SET @OpBalanceValue=0
		
		SET @PRD_I=@PRD_I+1
	END
	--
	--SELECT * FROM #Tbl
	UPDATE T set AvgRate=T1.AvgRate,COGS=T1.COGS,BalanceQty=T1.BalanceQty,BalanceValue=T1.BalanceValue,IsReconcile=@IsReconcile from #tblmain T,#Tbl T1 where T.ProductID=T1.ProductID
			and T.DocumentType=T1.DocumentType and T.InvDocDetailsID=T1.InvDocDetailsID and convert(datetime,T.DocDate)=convert(datetime,T1.DocDate)
			
	UPDATE T set ProductName=T.ProductName+'-'+ T1.ProductCode from #tblmain T,Inv_Product T1 with(nolock) where T.ProductID=T1.ProductID
			
	--SELECT * FROM #tblmain
	IF ((ISNULL(@LocationWHERE,'')<>'' AND @LocationWHERE<>NULL) OR (ISNULL(@DIMWHERE,'')<>'' AND @DIMWHERE<>NULL))
	begin
		SELECT * FROM #tblmain ORDER BY +@TransactionsByOp+',ST DESC,VoucherType DESC,VoucherNo,RecQty DESC'
	end
	else
	begin
		SELECT * FROM #tblmain ORDER BY +@TransactionsByOp+',ST DESC,VoucherNo,VoucherType DESC,RecQty DESC'
	end
	DROP TABLE #Tbl
	drop table #tblmain
	drop table #TblTransactions
	drop table #Tblextracols
	DROP TABLE #lstRecTbl2
	DROP TABLE #TblProds
	
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
		SELECT ErrorMessage, ERROR_MESSAGE() AS ServerMessage,ERROR_NUMBER() AS ErrorNumber, ERROR_PROCEDURE()AS ProcedureName, ERROR_LINE() AS ErrorLine
		FROM COM_ErrorMessages WITH(NOLOCK) WHERE ErrorNumber=-999 AND LanguageID=@LangID
	END
SET NOCOUNT OFF  
RETURN -999   
END CATCH
GO

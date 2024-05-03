USE PACT2C222
GO
SET ANSI_NULLS, QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spADM_SetImportDataServicestoDimension]
	@XML [nvarchar](max),
	@COSTCENTERID [bigint],
	@CompanyGUID [nvarchar](50),
	@UserName [nvarchar](50),
	@UserID [bigint],
	@LangID [int] = 1
WITH ENCRYPTION, EXECUTE AS CALLER
AS
BEGIN TRANSACTION
BEGIN TRY
SET NOCOUNT ON	
		--Declaration Section  fgsdgfsd gsdfg fsdg
		DECLARE	@return_value int,@failCount int
		DECLARE @NodeID bigint, @Table NVARCHAR(50),@SQL NVARCHAR(max),@ParentGroupName NVARCHAR(200),@PK NVARCHAR(50)
		DECLARE @AccountCode nvarchar(max),@GUID nvarchar(max),@AccountName nvarchar(max),@AliasName nvarchar(max)
        DECLARE @StatusID int,@ExtraFields NVARCHAR(max),@ExtraUserDefinedFields NVARCHAR(max),@CostCenterFields NVARCHAR(max),@PrimaryContactQuery nvarchar(max), @LinkFields NVARCHAR(MAX), @LinkOption NVARCHAR(MAX)
		DECLARE @SelectedNode bigint, @IsGroup bit
        DECLARE @CreditDays int, @CreditLimit float  
        DECLARE @PurchaseAccount bigint,@Purchase nvarchar(max)
        DECLARE @SalesAccount bigint,@Sales nvarchar(max)
        DECLARE @DebitDays int, @DebitLimit float
		DECLARE @IsBillwise bit, @TypeID int, @ValuationID   int,@Dt float
		DECLARE @Make nvarchar(400),@Model nvarchar(400),@Year nvarchar(400),@Variant nvarchar(400),@Segment nvarchar(400),@VehicleID bigint
		DECLARE @tempCode NVARCHAR(max),@DUPLICATECODE NVARCHAR(300),@DUPNODENO INT,@PARENTCODE NVARCHAR(max)
		DECLARE @tempName NVARCHAR(max),@DUPLICATEName NVARCHAR(300), @DUPNODENOCODE INT
		DECLARE @TempGuid NVARCHAR(max),@HasAccess BIT,@DATA XML,@Cnt INT,@I INT, @CCID INT
	    SET @DATA=@XML
		SET @Dt=CONVERT(FLOAT,GETDATE())--Setting Current Date  
		
		--SP Required Parameters Check
		IF @CompanyGUID IS NULL OR @CompanyGUID=''
		BEGIN
			RAISERROR('-100',16,1)
		END

		SELECT Top 1 @Table=SysTableName FROM ADM_CostCenterDef WITH(NOLOCK) WHERE CostCenterID=@CostCenterId
		IF(@COSTCENTERID=3)
			SET @PK='ProductID'
			 
		-- Create Temp Table
		CREATE TABLE #temptbl(ID int identity(1,1),
           [AccountCode] nvarchar(500)
           ,[AccountName] nvarchar(max)
           ,[AliasName] nvarchar(max)
           ,[StatusID] int
		   ,SelectedNode bigint
		   ,ParentGroupName NVARCHAR(200)
           ,[IsGroup] bit
           ,[CreditDays] int
           ,[CreditLimit] float
           ,[PurchaseAccount] nvarchar(500)
           ,[SalesAccount] nvarchar(500)
           ,[DebitDays] int
           ,[DebitLimit] float
		   ,IsBillwise bit
		   ,TypeID int
		   ,ValuationID   int,ExtraFields nvarchar(max),ExtraUserDefinedFields nvarchar(max),CostCenterFields nvarchar(max),
		   PrimaryContactQuery nvarchar(max), LinkFields nvarchar(max), LinkOption nvarchar(max)  
		   ,Make nvarchar(400),Model nvarchar(400),Year nvarchar(400),Variant nvarchar(400),Segment nvarchar(400),VehicleID int)
	 

		INSERT INTO #temptbl
           ([AccountCode]
           ,[AccountName]
           ,[AliasName]
           ,[StatusID]
			,SelectedNode
			,ParentGroupName
           ,[IsGroup]
           ,[CreditDays]
           ,[CreditLimit]
           ,[PurchaseAccount]
           ,[SalesAccount]
           ,[DebitDays]
           ,[DebitLimit]
			,IsBillwise
			,TypeID
			,ValuationID,ExtraFields ,ExtraUserDefinedFields ,CostCenterFields,PrimaryContactQuery,LinkFields, LinkOption
			,Make ,Model ,Year ,Variant ,Segment,VehicleID )          
		SELECT
			X.value('@AccountCode','nvarchar(500)')
           ,X.value('@AccountName','nvarchar(max)')
           ,isnull(X.value('@AliasName','nvarchar(max)'),'')
           ,X.value('@StatusID','int')           
           ,isnull(X.value('@SelectedNode','bigint'),0)
           ,isnull(X.value('@GroupName','nvarchar(200)'),'')
           ,isnull(X.value('@IsGroup','bit'),0)
           ,isnull(X.value('@CreditDays','int'),0)
           ,isnull(X.value('@CreditLimit','float'),0)
           ,X.value('@PurchaseAccount','nvarchar(max)')
           ,X.value('@SalesAccount','nvarchar(max)')
           ,isnull(X.value('@DebitDays','int'),0)
           ,isnull(X.value('@DebitLimit','float'),0)
			,isnull(X.value('@IsBillwise','bit'),0)
			,case when X.value('@TypeID','int') is null and @COSTCENTERID=2 then 7
			else isnull(X.value('@TypeID','int'),1) end
			,isnull(X.value('@ValuationID','int'),1)
			,isnull(X.value('@ExtraFields ','nvarchar(max)'),'')
			,isnull(X.value('@ExtraUserDefinedFields ','nvarchar(max)'),'')
			,isnull(X.value('@CostCenterFields','nvarchar(max)'),'')
			,isnull(X.value('@PrimaryContactQuery','nvarchar(max)'),'')
			,isnull(X.value('@LinkFields','nvarchar(max)'),'')
			,isnull(X.value('@LinkOption','nvarchar(max)'),'')
			,X.value('@Make','nvarchar(400)'),X.value('@Model','nvarchar(400)'),X.value('@Year','nvarchar(400)')
			,X.value('@Variant','nvarchar(400)'),X.value('@Segment','nvarchar(400)'),X.value('@VehicleID','int')

 		from @DATA.nodes('/XML/Row') as Data(X)
		
		SELECT @I=1, @Cnt=count(ID) FROM #temptbl 
		set @failCount=0
		WHILE(@I<=@Cnt)  
		BEGIN
		begin try
				 	select @AccountCode    = AccountCode 
					,@AccountName    =  AccountName  
					,@AliasName    = AliasName 
					,@StatusID    = StatusID 
					,@SelectedNode    = SelectedNode
					,@ParentGroupName=ParentGroupName
					,@IsGroup    = IsGroup 
					,@CreditDays    = CreditDays 
					,@CreditLimit    = CreditLimit 
					,@Purchase    = PurchaseAccount 
					,@Sales    = SalesAccount 
					,@DebitDays    = DebitDays 
					,@DebitLimit    = DebitLimit 
					,@IsBillwise    = IsBillwise 
					,@TypeID    = TypeID 
					,@ValuationID             = ValuationID  
					,@ExtraFields=ExtraFields ,@ExtraUserDefinedFields=ExtraUserDefinedFields ,@CostCenterFields=CostCenterFields
					,@PrimaryContactQuery=PrimaryContactQuery 
					,@LinkFields=LinkFields,
					@LinkOption=LinkOption,
					@VehicleID=VehicleID,@Make=Make ,@Model =Model ,@Year =Year ,@Variant =Variant ,@Segment=Segment
					from  #temptbl where ID=@I
	  
			if(@LinkOption is not null and @LinkOption <>'')
				set @LinkOption ='<XML><Row LinkedProductID=''-1''  '+ @LinkOption+' Qty=''0'' Rate=''0'' />'
			--<Row  LinkedProductID="-1"  CostCenterID="50029" NodeID="14"/>

	 		if(@LinkFields is not null and @LinkFields<>'')
			begin
			
				if  exists(select ProductID from dbo.INV_Product  with(nolock) where ProductName=@AccountName)
				begin
					set @NodeID=(select top 1 ProductID from dbo.INV_Product with(nolock) where ProductName=@AccountName)
				end 
			    set @LinkFields =@LinkOption +'<Row RowNo=''1'' LinkedProductID=''0'' '+ @LinkFields+' Qty=''0'' Rate=''0'' /></XML>'
		 		print @LinkFields
		 		 	--link products based on dimension
				EXEC [spINV_SetLinkedProducts] @LinkFields,@CompanyGUID,@UserName,@UserID,@LangID 
 	  		end
 		 
			End Try
			 Begin Catch
				 
			end Catch
			 
			set @I=@I+1

	end

COMMIT TRANSACTION  
--ROLLBACK TRANSACTION  


if(@COSTCENTERID=3)
begin
	SET @SQL='SELECT ProductID NodeID,ProductName Name FROM '+@Table+' WITH(nolock)where ProductName in ( 
	SELECT X.value(''@AccountName'',''nvarchar(500)'')
	from @sml.nodes(''/XML/Row'') as Data(X))'

	EXEC sp_executesql @SQL, N'@sml xml', @XML	
end
 	 

SELECT ErrorMessage,ErrorNumber FROM COM_ErrorMessages WITH(nolock) 
WHERE ErrorNumber=100 AND LanguageID=@LangID
SET NOCOUNT OFF;  
RETURN @failCount  
END TRY  
BEGIN CATCH  
	--Return exception info [Message,Number,ProcedureName,LineNumber]  
	IF ERROR_NUMBER()=50000
	BEGIN
		SELECT * FROM [ACC_Accounts] WITH(nolock) WHERE AccountCode=@AccountCode  
		SELECT ErrorMessage,ErrorNumber FROM COM_ErrorMessages WITH(nolock) 
		WHERE ErrorNumber=ERROR_MESSAGE() AND LanguageID=@LangID
	END
	ELSE IF ERROR_NUMBER()=547
	BEGIN
		SELECT ErrorMessage, ERROR_MESSAGE() AS ServerMessage,ERROR_NUMBER() as ErrorNumber, ERROR_PROCEDURE()as ProcedureName, ERROR_LINE() AS ErrorLine FROM COM_ErrorMessages WITH(nolock)
		WHERE ErrorNumber=-110 AND LanguageID=@LangID
	END
	ELSE IF ERROR_NUMBER()=2627
	BEGIN
		SELECT ErrorMessage, ERROR_MESSAGE() AS ServerMessage,ERROR_NUMBER() as ErrorNumber, ERROR_PROCEDURE()as ProcedureName, ERROR_LINE() AS ErrorLine FROM COM_ErrorMessages WITH(nolock)
		WHERE ErrorNumber=-116 AND LanguageID=@LangID
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

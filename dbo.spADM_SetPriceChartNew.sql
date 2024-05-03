USE PACT2C222
GO
SET ANSI_NULLS, QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spADM_SetPriceChartNew]
	@ProfileID [bigint],
	@ProfileName [nvarchar](max) = null,
	@SelectedNodeID [bigint],
	@IsGroup [bit],
	@PriceXML [nvarchar](max) = null,
	@DeleteXML [nvarchar](max) = null,
	@PriceType [smallint],
	@IsImport [bit] = 0,
	@CompanyGUID [nvarchar](50) = null,
	@UserName [nvarchar](50),
	@RoleID [bigint],
	@LangID [int] = 1
WITH ENCRYPTION, EXECUTE AS CALLER
AS
BEGIN TRANSACTION  
BEGIN TRY  
SET NOCOUNT ON;
		--Declaration Section  
		DECLARE @Dt FLOAT ,@XML XML,@HasAccess BIT
		DECLARE @Tbl1 TABLE(ID INT IDENTITY(1,1),CCID INT)
		DECLARE @Tbl2 TABLE(ID INT IDENTITY(1,1),CCNodeID BIGINT)
		DECLARE @TblXML TABLE(ID INT IDENTITY(1,1),ProductID BIGINT,WEF DATETIME,CCID NVARCHAR(500),CCNodeID NVARCHAR(500),
			PurchaseRate FLOAT,PurchaseRateA FLOAT,PurchaseRateB FLOAT,PurchaseRateC FLOAT,
			PurchaseRateD FLOAT,PurchaseRateE FLOAT,PurchaseRateF FLOAT,PurchaseRateG FLOAT,
			SellingRate FLOAT,SellingRateA FLOAT,SellingRateB FLOAT,SellingRateC FLOAT,
			SellingRateD FLOAT,SellingRateE FLOAT,SellingRateF FLOAT,SellingRateG FLOAT)

	set @Dt=convert(float,getdate())
	SET @XML=@PriceXML

	IF(@IsImport=1 and @ProfileID>0)
	BEGIN
		delete from COM_CCPrices   where PriceCCID in (select PriceCCID from com_ccprices c
		join @XML.nodes('/XML/Row') as Data(X) on c.profileid=@ProfileID and c.WEF=CONVERT(FLOAT,X.value('@WEF','DATETIME')) and c.PRoductid=ISNULL(X.value('@ProductID','BIGINT'),0) and
		PurchaseRate=ISNULL(X.value('@PurchaseRate','FLOAT'),0) and PurchaseRateA=ISNULL(X.value('@PurchaseRateA','FLOAT'),0) and
		PurchaseRateB=ISNULL(X.value('@PurchaseRateB','FLOAT'),0) and PurchaseRateC=ISNULL(X.value('@PurchaseRateC','FLOAT'),0) and
		PurchaseRateD=ISNULL(X.value('@PurchaseRateD','FLOAT'),0) and PurchaseRateE=ISNULL(X.value('@PurchaseRateE','FLOAT'),0) and
		PurchaseRateF=ISNULL(X.value('@PurchaseRateF','FLOAT'),0) and PurchaseRateG=ISNULL(X.value('@PurchaseRateG','FLOAT'),0) and
		SellingRate=ISNULL(X.value('@SellingRate','FLOAT'),0) and SellingRateA=ISNULL(X.value('@SellingRateA','FLOAT'),0) and
		SellingRateB=ISNULL(X.value('@SellingRateB','FLOAT'),0) and SellingRateC=ISNULL(X.value('@SellingRateC','FLOAT'),0) and
		SellingRateD=ISNULL(X.value('@SellingRateD','FLOAT'),0) and SellingRateE=ISNULL(X.value('@SellingRateE','FLOAT'),0) and
		SellingRateF=ISNULL(X.value('@SellingRateF','FLOAT'),0) and SellingRateG=ISNULL(X.value('@SellingRateG','FLOAT'),0) and
		ReorderLevel=ISNULL(X.value('@ReorderLevel','FLOAT'),0) and ReorderQty=ISNULL(X.value('@ReorderQty','FLOAT'),0)  and 
		c.ccnid1= ISNULL(X.value('@CC1','BIGINT'),0) and c.ccnid2 = ISNULL(X.value('@CC2','BIGINT'),0) and 
		c.ccnid3= ISNULL(X.value('@CC3','BIGINT'),0) and c.ccnid4 = ISNULL(X.value('@CC4','BIGINT'),0) and 
		c.ccnid5= ISNULL(X.value('@CC5','BIGINT'),0) and c.ccnid6 = ISNULL(X.value('@CC6','BIGINT'),0) and 
		c.ccnid7= ISNULL(X.value('@CC7','BIGINT'),0) and c.ccnid8 = ISNULL(X.value('@CC8','BIGINT'),0) and 
		c.ccnid9= ISNULL(X.value('@CC9','BIGINT'),0) and c.ccnid10= ISNULL(X.value('@CC10','BIGINT'),0) and  
		c.ccnid11= ISNULL(X.value('@CC11','BIGINT'),0) and c.ccnid12 = ISNULL(X.value('@CC12','BIGINT'),0) and 
		c.ccnid13= ISNULL(X.value('@CC13','BIGINT'),0) and c.ccnid14 = ISNULL(X.value('@CC14','BIGINT'),0) and 
		c.ccnid15= ISNULL(X.value('@CC15','BIGINT'),0) and c.ccnid16 = ISNULL(X.value('@CC16','BIGINT'),0) and 
		c.ccnid17= ISNULL(X.value('@CC17','BIGINT'),0) and c.ccnid18 = ISNULL(X.value('@CC18','BIGINT'),0) and 
		c.ccnid19= ISNULL(X.value('@CC19','BIGINT'),0) and c.ccnid20 = ISNULL(X.value('@CC20','BIGINT'),0) and  
		c.ccnid21= ISNULL(X.value('@CC21','BIGINT'),0) and c.ccnid22 = ISNULL(X.value('@CC22','BIGINT'),0) and 
		c.ccnid23= ISNULL(X.value('@CC23','BIGINT'),0) and c.ccnid24 = ISNULL(X.value('@CC24','BIGINT'),0) and 
		c.ccnid25= ISNULL(X.value('@CC25','BIGINT'),0) and c.ccnid26 = ISNULL(X.value('@CC26','BIGINT'),0) and 
		c.ccnid27= ISNULL(X.value('@CC27','BIGINT'),0) and c.ccnid28 = ISNULL(X.value('@CC28','BIGINT'),0) and 
		c.ccnid29= ISNULL(X.value('@CC29','BIGINT'),0) and c.ccnid30 = ISNULL(X.value('@CC30','BIGINT'),0) and  
		c.ccnid31= ISNULL(X.value('@CC21','BIGINT'),0) and c.ccnid32 = ISNULL(X.value('@CC22','BIGINT'),0) and 
		c.ccnid33= ISNULL(X.value('@CC23','BIGINT'),0) and c.ccnid34 = ISNULL(X.value('@CC24','BIGINT'),0) and 
		c.ccnid35= ISNULL(X.value('@CC25','BIGINT'),0) and c.ccnid36 = ISNULL(X.value('@CC26','BIGINT'),0) and 
		c.ccnid37= ISNULL(X.value('@CC27','BIGINT'),0) and c.ccnid38 = ISNULL(X.value('@CC28','BIGINT'),0) and 
		c.ccnid39= ISNULL(X.value('@CC29','BIGINT'),0) and c.ccnid40 = ISNULL(X.value('@CC30','BIGINT'),0) and 
		c.ccnid41= ISNULL(X.value('@CC21','BIGINT'),0) and c.ccnid42 = ISNULL(X.value('@CC22','BIGINT'),0) and 
		c.ccnid43= ISNULL(X.value('@CC23','BIGINT'),0) and c.ccnid44 = ISNULL(X.value('@CC24','BIGINT'),0) and 
		c.ccnid45= ISNULL(X.value('@CC25','BIGINT'),0) and c.ccnid46 = ISNULL(X.value('@CC26','BIGINT'),0) and 
		c.ccnid47= ISNULL(X.value('@CC27','BIGINT'),0) and c.ccnid48 = ISNULL(X.value('@CC28','BIGINT'),0) and 
		c.ccnid49= ISNULL(X.value('@CC29','BIGINT'),0) and c.ccnid50 = ISNULL(X.value('@CC30','BIGINT'),0) and 
		c.TillDate=CONVERT(FLOAT,X.value('@TillDate','DATETIME')))

	END
	
	
	IF @ProfileID=0--NEW
	BEGIN
		DECLARE @lft bigint,@rgt bigint,@Selectedlft bigint,@Selectedrgt bigint,@Depth int,@ParentID bigint
		DECLARE @SelectedIsGroup bit

		IF EXISTS (SELECT ProfileID FROM COM_CCPricesDefn WITH(nolock) WHERE ProfileName=@ProfileName) 
			RAISERROR('-112',16,1) 
			
		if @SelectedNodeID=0
			set @SelectedNodeID=-1

		--To Set Left,Right And Depth of Record
		SELECT @SelectedIsGroup=IsGroup,@Selectedlft =lft,@Selectedrgt=rgt,@ParentID=ParentID,@Depth=Depth
		from COM_CCPricesDefn with(NOLOCK) where ProfileID=@SelectedNodeID

		--IF No Record Selected or Record Doesn't Exist
		IF(@SelectedIsGroup is null) 
			select @SelectedNodeID=ProfileID,@SelectedIsGroup=IsGroup,@Selectedlft =lft,@Selectedrgt=rgt,@ParentID=ParentID,@Depth=Depth
			from COM_CCPricesDefn with(NOLOCK) where ParentID =0
					
		IF(@SelectedIsGroup = 1)--Adding Node Under the Group
		BEGIN
			UPDATE COM_CCPricesDefn SET rgt = rgt + 2 WHERE rgt > @Selectedlft;
			UPDATE COM_CCPricesDefn SET lft = lft + 2 WHERE lft > @Selectedlft;
			SET @lft =  @Selectedlft + 1
			SET @rgt =	@Selectedlft + 2
			SET @ParentID = @SelectedNodeID
			SET @Depth = @Depth + 1
		END
		ELSE IF(@SelectedIsGroup = 0)--Adding Node at Same level
		BEGIN
			UPDATE COM_CCPricesDefn SET rgt = rgt + 2 WHERE rgt > @Selectedrgt;
			UPDATE COM_CCPricesDefn SET lft = lft + 2 WHERE lft > @Selectedrgt;
			SET @lft =  @Selectedrgt + 1
			SET @rgt =	@Selectedrgt + 2 
		END
		ELSE  --Adding Root
		BEGIN
				SET @lft =  1
				SET @rgt =	2 
				SET @Depth = 0
				SET @ParentID =0
				SET @IsGroup=1
		END
		
		-- Insert statements for procedure here
		INSERT INTO COM_CCPricesDefn(ProfileName,PriceType,
						[IsGroup],[Depth],[ParentID],[lft],[rgt],
						[CompanyGUID],[GUID],[CreatedBy],[CreatedDate])
						VALUES
						(@ProfileName,@PriceType,
						@IsGroup,@Depth,@ParentID,@lft,@rgt,
						@CompanyGUID,newid(),@UserName,@Dt)
		--To get inserted record primary key
		SET @ProfileID=SCOPE_IDENTITY()
			
		INSERT INTO COM_CCPrices
       ([ProfileID],[ProfileName],[ProductID],UOMID,[WEF],PriceType
       ,[AccountID],VehicleID,CurrencyID
	   ,PurchaseRate,PurchaseRateA,PurchaseRateB,PurchaseRateC,PurchaseRateD,PurchaseRateE,PurchaseRateF,PurchaseRateG
	   ,SellingRate,SellingRateA,SellingRateB,SellingRateC,SellingRateD,SellingRateE,SellingRateF,SellingRateG,
       ReorderLevel,ReorderQty,[CCNID1],[CCNID2],[CCNID3],[CCNID4],[CCNID5],[CCNID6],[CCNID7],[CCNID8],[CCNID9],[CCNID10]
       ,[CCNID11],[CCNID12],[CCNID13],[CCNID14],[CCNID15],[CCNID16],[CCNID17],[CCNID18],[CCNID19],[CCNID20]
       ,[CCNID21],[CCNID22],[CCNID23],[CCNID24],[CCNID25],[CCNID26],[CCNID27],[CCNID28],[CCNID29],[CCNID30]
       ,[CCNID31],[CCNID32],[CCNID33],[CCNID34],[CCNID35],[CCNID36],[CCNID37],[CCNID38],[CCNID39],[CCNID40]
       ,[CCNID41],[CCNID42],[CCNID43],[CCNID44],[CCNID45],[CCNID46],[CCNID47],[CCNID48],[CCNID49],[CCNID50]
       ,[CompanyGUID],[GUID],[CreatedBy],[CreatedDate],TillDate,Remarks) 
		SELECT @ProfileID,@ProfileName,ISNULL(X.value('@ProductID','BIGINT'),0),ISNULL(X.value('@UOMID','BIGINT'),0),CONVERT(FLOAT,X.value('@WEF','DATETIME')),ISNULL(X.value('@Type','smallint'),0),
		ISNULL(X.value('@AccountID','BIGINT'),0),ISNULL(X.value('@VID','BIGINT'),0),ISNULL(X.value('@CurrencyID','INT'),0),
		ISNULL(X.value('@PurchaseRate','FLOAT'),0),ISNULL(X.value('@PurchaseRateA','FLOAT'),0),ISNULL(X.value('@PurchaseRateB','FLOAT'),0),ISNULL(X.value('@PurchaseRateC','FLOAT'),0),ISNULL(X.value('@PurchaseRateD','FLOAT'),0),ISNULL(X.value('@PurchaseRateE','FLOAT'),0),ISNULL(X.value('@PurchaseRateF','FLOAT'),0),ISNULL(X.value('@PurchaseRateG','FLOAT'),0),
		ISNULL(X.value('@SellingRate','FLOAT'),0),ISNULL(X.value('@SellingRateA','FLOAT'),0),ISNULL(X.value('@SellingRateB','FLOAT'),0),ISNULL(X.value('@SellingRateC','FLOAT'),0),ISNULL(X.value('@SellingRateD','FLOAT'),0),ISNULL(X.value('@SellingRateE','FLOAT'),0),ISNULL(X.value('@SellingRateF','FLOAT'),0),ISNULL(X.value('@SellingRateG','FLOAT'),0),
		ISNULL(X.value('@ReorderLevel','FLOAT'),0),ISNULL(X.value('@ReorderQty','FLOAT'),0),ISNULL(X.value('@CC1','BIGINT'),0),ISNULL(X.value('@CC2','BIGINT'),0),ISNULL(X.value('@CC3','BIGINT'),0),ISNULL(X.value('@CC4','BIGINT'),0),ISNULL(X.value('@CC5','BIGINT'),0),ISNULL(X.value('@CC6','BIGINT'),0),ISNULL(X.value('@CC7','BIGINT'),0),ISNULL(X.value('@CC8','BIGINT'),0),ISNULL(X.value('@CC9','BIGINT'),0),ISNULL(X.value('@CC10','BIGINT'),0),
		ISNULL(X.value('@CC11','BIGINT'),0),ISNULL(X.value('@CC12','BIGINT'),0),ISNULL(X.value('@CC13','BIGINT'),0),ISNULL(X.value('@CC14','BIGINT'),0),ISNULL(X.value('@CC15','BIGINT'),0),ISNULL(X.value('@CC16','BIGINT'),0),ISNULL(X.value('@CC17','BIGINT'),0),ISNULL(X.value('@CC18','BIGINT'),0),ISNULL(X.value('@CC19','BIGINT'),0),ISNULL(X.value('@CC20','BIGINT'),0),
		ISNULL(X.value('@CC21','BIGINT'),0),ISNULL(X.value('@CC22','BIGINT'),0),ISNULL(X.value('@CC23','BIGINT'),0),ISNULL(X.value('@CC24','BIGINT'),0),ISNULL(X.value('@CC25','BIGINT'),0),ISNULL(X.value('@CC26','BIGINT'),0),ISNULL(X.value('@CC27','BIGINT'),0),ISNULL(X.value('@CC28','BIGINT'),0),ISNULL(X.value('@CC29','BIGINT'),0),ISNULL(X.value('@CC30','BIGINT'),0),
		ISNULL(X.value('@CC31','BIGINT'),0),ISNULL(X.value('@CC32','BIGINT'),0),ISNULL(X.value('@CC33','BIGINT'),0),ISNULL(X.value('@CC34','BIGINT'),0),ISNULL(X.value('@CC35','BIGINT'),0),ISNULL(X.value('@CC36','BIGINT'),0),ISNULL(X.value('@CC37','BIGINT'),0),ISNULL(X.value('@CC38','BIGINT'),0),ISNULL(X.value('@CC39','BIGINT'),0),ISNULL(X.value('@CC40','BIGINT'),0),
		ISNULL(X.value('@CC41','BIGINT'),0),ISNULL(X.value('@CC42','BIGINT'),0),ISNULL(X.value('@CC43','BIGINT'),0),ISNULL(X.value('@CC44','BIGINT'),0),ISNULL(X.value('@CC45','BIGINT'),0),ISNULL(X.value('@CC46','BIGINT'),0),ISNULL(X.value('@CC47','BIGINT'),0),ISNULL(X.value('@CC48','BIGINT'),0),ISNULL(X.value('@CC49','BIGINT'),0),ISNULL(X.value('@CC50','BIGINT'),0),
		@CompanyGUID,NEWID(),@UserName,CONVERT(FLOAT,GETDATE()),CONVERT(FLOAT,X.value('@TillDate','DATETIME')),X.value('@Remarks','nvarchar(max)')
		FROM @XML.nodes('/XML/Row') as Data(X)
			
	END
	ELSE
	BEGIN--EDIT
		--Dont Check Go For New Inserts If its is coming from search
		IF @ProfileID!=-100
		BEGIN
			IF EXISTS (SELECT ProfileID FROM COM_CCPricesDefn WITH(nolock) WHERE ProfileName=@ProfileName AND ProfileID!=@ProfileID) 
			RAISERROR('-112',16,1) 
			
			UPDATE COM_CCPricesDefn
			SET ProfileName=@ProfileName,PriceType=@PriceType,[GUID]=newid(),ModifiedBy=@UserName,ModifiedDate=@Dt
			WHERE ProfileID=@ProfileID
						
			INSERT INTO COM_CCPrices
		   ([ProfileID],[ProfileName],[ProductID],UOMID,[WEF],PriceType
		   ,[AccountID],VehicleID,CurrencyID
		   ,PurchaseRate,PurchaseRateA,PurchaseRateB,PurchaseRateC,PurchaseRateD,PurchaseRateE,PurchaseRateF,PurchaseRateG
		   ,SellingRate,SellingRateA,SellingRateB,SellingRateC,SellingRateD,SellingRateE,SellingRateF,SellingRateG,
		   ReorderLevel,ReorderQty,[CCNID1],[CCNID2],[CCNID3],[CCNID4],[CCNID5],[CCNID6],[CCNID7],[CCNID8],[CCNID9],[CCNID10]
		   ,[CCNID11],[CCNID12],[CCNID13],[CCNID14],[CCNID15],[CCNID16],[CCNID17],[CCNID18],[CCNID19],[CCNID20]
		   ,[CCNID21],[CCNID22],[CCNID23],[CCNID24],[CCNID25],[CCNID26],[CCNID27],[CCNID28],[CCNID29],[CCNID30]
		   ,[CCNID31],[CCNID32],[CCNID33],[CCNID34],[CCNID35],[CCNID36],[CCNID37],[CCNID38],[CCNID39],[CCNID40]
		   ,[CCNID41],[CCNID42],[CCNID43],[CCNID44],[CCNID45],[CCNID46],[CCNID47],[CCNID48],[CCNID49],[CCNID50]
		   ,[CompanyGUID],[GUID],[CreatedBy],[CreatedDate],TillDate,Remarks) 
			SELECT @ProfileID,@ProfileName,ISNULL(X.value('@ProductID','BIGINT'),0),ISNULL(X.value('@UOMID','BIGINT'),0),CONVERT(FLOAT,X.value('@WEF','DATETIME')),ISNULL(X.value('@Type','smallint'),0),
			ISNULL(X.value('@AccountID','BIGINT'),0),ISNULL(X.value('@VID','BIGINT'),0),ISNULL(X.value('@CurrencyID','INT'),0),
			ISNULL(X.value('@PurchaseRate','FLOAT'),0),ISNULL(X.value('@PurchaseRateA','FLOAT'),0),ISNULL(X.value('@PurchaseRateB','FLOAT'),0),ISNULL(X.value('@PurchaseRateC','FLOAT'),0),ISNULL(X.value('@PurchaseRateD','FLOAT'),0),ISNULL(X.value('@PurchaseRateE','FLOAT'),0),ISNULL(X.value('@PurchaseRateF','FLOAT'),0),ISNULL(X.value('@PurchaseRateG','FLOAT'),0),
			ISNULL(X.value('@SellingRate','FLOAT'),0),ISNULL(X.value('@SellingRateA','FLOAT'),0),ISNULL(X.value('@SellingRateB','FLOAT'),0),ISNULL(X.value('@SellingRateC','FLOAT'),0),ISNULL(X.value('@SellingRateD','FLOAT'),0),ISNULL(X.value('@SellingRateE','FLOAT'),0),ISNULL(X.value('@SellingRateF','FLOAT'),0),ISNULL(X.value('@SellingRateG','FLOAT'),0),
			ISNULL(X.value('@ReorderLevel','FLOAT'),0),ISNULL(X.value('@ReorderQty','FLOAT'),0),ISNULL(X.value('@CC1','BIGINT'),0),ISNULL(X.value('@CC2','BIGINT'),0),ISNULL(X.value('@CC3','BIGINT'),0),ISNULL(X.value('@CC4','BIGINT'),0),ISNULL(X.value('@CC5','BIGINT'),0),ISNULL(X.value('@CC6','BIGINT'),0),ISNULL(X.value('@CC7','BIGINT'),0),ISNULL(X.value('@CC8','BIGINT'),0),ISNULL(X.value('@CC9','BIGINT'),0),ISNULL(X.value('@CC10','BIGINT'),0),
			ISNULL(X.value('@CC11','BIGINT'),0),ISNULL(X.value('@CC12','BIGINT'),0),ISNULL(X.value('@CC13','BIGINT'),0),ISNULL(X.value('@CC14','BIGINT'),0),ISNULL(X.value('@CC15','BIGINT'),0),ISNULL(X.value('@CC16','BIGINT'),0),ISNULL(X.value('@CC17','BIGINT'),0),ISNULL(X.value('@CC18','BIGINT'),0),ISNULL(X.value('@CC19','BIGINT'),0),ISNULL(X.value('@CC20','BIGINT'),0),
			ISNULL(X.value('@CC21','BIGINT'),0),ISNULL(X.value('@CC22','BIGINT'),0),ISNULL(X.value('@CC23','BIGINT'),0),ISNULL(X.value('@CC24','BIGINT'),0),ISNULL(X.value('@CC25','BIGINT'),0),ISNULL(X.value('@CC26','BIGINT'),0),ISNULL(X.value('@CC27','BIGINT'),0),ISNULL(X.value('@CC28','BIGINT'),0),ISNULL(X.value('@CC29','BIGINT'),0),ISNULL(X.value('@CC30','BIGINT'),0),
			ISNULL(X.value('@CC31','BIGINT'),0),ISNULL(X.value('@CC32','BIGINT'),0),ISNULL(X.value('@CC33','BIGINT'),0),ISNULL(X.value('@CC34','BIGINT'),0),ISNULL(X.value('@CC35','BIGINT'),0),ISNULL(X.value('@CC36','BIGINT'),0),ISNULL(X.value('@CC37','BIGINT'),0),ISNULL(X.value('@CC38','BIGINT'),0),ISNULL(X.value('@CC39','BIGINT'),0),ISNULL(X.value('@CC40','BIGINT'),0),
			ISNULL(X.value('@CC41','BIGINT'),0),ISNULL(X.value('@CC42','BIGINT'),0),ISNULL(X.value('@CC43','BIGINT'),0),ISNULL(X.value('@CC44','BIGINT'),0),ISNULL(X.value('@CC45','BIGINT'),0),ISNULL(X.value('@CC46','BIGINT'),0),ISNULL(X.value('@CC47','BIGINT'),0),ISNULL(X.value('@CC48','BIGINT'),0),ISNULL(X.value('@CC49','BIGINT'),0),ISNULL(X.value('@CC50','BIGINT'),0),
			@CompanyGUID,NEWID(),@UserName,CONVERT(FLOAT,GETDATE()),CONVERT(FLOAT,X.value('@TillDate','DATETIME')),X.value('@Remarks','nvarchar(max)')
			FROM @XML.nodes('/XML/Row') as Data(X)
			WHERE X.value('@PriceCCID','BIGINT') IS NULL
		END
		
		UPDATE COM_CCPrices
		SET WEF=CONVERT(FLOAT,X.value('@WEF','DATETIME')),
			PriceType=ISNULL(X.value('@Type','smallint'),0),
			PurchaseRate=ISNULL(X.value('@PurchaseRate','FLOAT'),0),
			PurchaseRateA=ISNULL(X.value('@PurchaseRateA','FLOAT'),0),
			PurchaseRateB=ISNULL(X.value('@PurchaseRateB','FLOAT'),0),
			PurchaseRateC=ISNULL(X.value('@PurchaseRateC','FLOAT'),0),
			PurchaseRateD=ISNULL(X.value('@PurchaseRateD','FLOAT'),0),
			PurchaseRateE=ISNULL(X.value('@PurchaseRateE','FLOAT'),0),
			PurchaseRateF=ISNULL(X.value('@PurchaseRateF','FLOAT'),0),
			PurchaseRateG=ISNULL(X.value('@PurchaseRateG','FLOAT'),0),
			SellingRate=ISNULL(X.value('@SellingRate','FLOAT'),0),
			SellingRateA=ISNULL(X.value('@SellingRateA','FLOAT'),0),
			SellingRateB=ISNULL(X.value('@SellingRateB','FLOAT'),0),
			SellingRateC=ISNULL(X.value('@SellingRateC','FLOAT'),0),
			SellingRateD=ISNULL(X.value('@SellingRateD','FLOAT'),0),
			SellingRateE=ISNULL(X.value('@SellingRateE','FLOAT'),0),
			SellingRateF=ISNULL(X.value('@SellingRateF','FLOAT'),0),
			SellingRateG=ISNULL(X.value('@SellingRateG','FLOAT'),0),
			ReorderLevel=ISNULL(X.value('@ReorderLevel','FLOAT'),0),
			ReorderQty=ISNULL(X.value('@ReorderQty','FLOAT'),0),
			TillDate=CONVERT(FLOAT,X.value('@TillDate','DATETIME')),
			Remarks=X.value('@Remarks','nvarchar(max)')
		FROM @XML.nodes('/XML/Row') as Data(X),COM_CCPrices P
		WHERE X.value('@PriceCCID','BIGINT') IS NOT NULL AND P.PriceCCID=X.value('@PriceCCID','BIGINT')
		
		--Delete Rows
		IF @DeleteXML IS NOT NULL AND @DeleteXML!=''
		BEGIN
			SET @XML=@DeleteXML
			DELETE FROM COM_CCPrices
			WHERE PriceCCID IN (SELECT X.value('@ID','BIGINT') FROM @XML.nodes('/XML/Row') as Data(X))
			
		END
	END
	
	--Added to set default inactive if action exists
	SET @HasAccess=dbo.fnCOM_HasAccess(@RoleID,40,156)
	if(@HasAccess!=0)
		update COM_CCPricesDefn set statusid=2 where profileid=@ProfileID


	--To Set Used CostCenters with Group Check
	EXEC [spADM_SetPriceTaxUsedCC] 1,@ProfileID,1
	
	--select * from COM_CCPricesDefn with(nolock) where ProfileID=@ProfileID
	--select * from COM_CCPriceTaxCCDefn with(nolock) where ProfileID=@ProfileID
	--select * from COM_CCPrices with(nolock) where ProfileID=@ProfileID
	

COMMIT TRANSACTION  
--ROLLBACK TRANSACTION

SELECT ErrorMessage,ErrorNumber FROM COM_ErrorMessages WITH(nolock) 
WHERE ErrorNumber=100 AND LanguageID=@LangID     
SET NOCOUNT OFF;  
RETURN @ProfileID  
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

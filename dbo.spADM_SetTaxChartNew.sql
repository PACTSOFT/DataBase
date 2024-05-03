USE PACT2C222
GO
SET ANSI_NULLS, QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spADM_SetTaxChartNew]
	@ProfileID [bigint],
	@ProfileName [nvarchar](50) = null,
	@SelectedNodeID [bigint],
	@IsGroup [bit],
	@TaxXML [nvarchar](max) = null,
	@DeleteXML [nvarchar](max) = null,
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
	DECLARE @Dt FLOAT ,@HasAccess BIT
	DECLARE @CCID NVARCHAR(500),@CCNodeID NVARCHAR(500),@XML XML
	DECLARE @Tbl1 TABLE(ID INT IDENTITY(1,1),CCID INT)
	DECLARE @Tbl2 TABLE(ID INT IDENTITY(1,1),CCNodeID BIGINT)
	DECLARE @TblXML TABLE(ID INT IDENTITY(1,1),DocID INT,ColID BIGINT,Price FLOAT,WEF DATETIME,CCID NVARCHAR(500),CCNodeID NVARCHAR(500))
	DECLARE @I INT,@Count INT,@GroupID BIGINT
	DECLARE @SPInvoice cursor, @nStatusOuter int
	DECLARE @CCUpdate NVARCHAR(MAX),@CCTaxID bigint,@SQL nvarchar(max)
		,@DocID int,@ColID BIGINT,@ProductID BIGINT,@Price FLOAT,@WEF FLOAT,@AccountID BIGINT,@VID BIGINT,@TillDate FLOAT,@Message NVARCHAR(MAX)

	IF @CompanyGUID IS NULL OR @CompanyGUID=''
		set @CompanyGUID='CompanyGUID'
	
	set @Dt=convert(float,getdate())
	SET @XML=@TaxXML
	
	if(@IsImport=1  and @ProfileID>0)
	begin
		delete from [COM_CCTaxes]   where cctaxid in (select cctaxid from [COM_CCTaxes] c
		join @XML.nodes('/XML/Row') as Data(X) on c.profileid=@ProfileID and DocID = X.value('@DocID','bigint') and ColID = X.value('@ColID','bigint') 
		and c.WEF=CONVERT(FLOAT,X.value('@WEF','DATETIME')) and c.PRoductid=ISNULL(X.value('@ProductID','BIGINT'),0) and
		value=ISNULL(X.value('@Price','FLOAT'),0)  and 
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
		c.ccnid31= ISNULL(X.value('@CC31','BIGINT'),0) and c.ccnid32 = ISNULL(X.value('@CC32','BIGINT'),0) and 
		c.ccnid33= ISNULL(X.value('@CC33','BIGINT'),0) and c.ccnid34 = ISNULL(X.value('@CC34','BIGINT'),0) and 
		c.ccnid35= ISNULL(X.value('@CC35','BIGINT'),0) and c.ccnid36 = ISNULL(X.value('@CC36','BIGINT'),0) and 
		c.ccnid37= ISNULL(X.value('@CC37','BIGINT'),0) and c.ccnid38 = ISNULL(X.value('@CC38','BIGINT'),0) and 
		c.ccnid39= ISNULL(X.value('@CC39','BIGINT'),0) and c.ccnid40 = ISNULL(X.value('@CC40','BIGINT'),0) and 
		c.ccnid41= ISNULL(X.value('@CC41','BIGINT'),0) and c.ccnid42 = ISNULL(X.value('@CC42','BIGINT'),0) and 
		c.ccnid43= ISNULL(X.value('@CC43','BIGINT'),0) and c.ccnid44 = ISNULL(X.value('@CC44','BIGINT'),0) and 
		c.ccnid45= ISNULL(X.value('@CC45','BIGINT'),0) and c.ccnid46 = ISNULL(X.value('@CC46','BIGINT'),0) and 
		c.ccnid47= ISNULL(X.value('@CC47','BIGINT'),0) and c.ccnid48 = ISNULL(X.value('@CC48','BIGINT'),0) and 
		c.ccnid49= ISNULL(X.value('@CC49','BIGINT'),0) and c.ccnid50 = ISNULL(X.value('@CC50','BIGINT'),0) and 
		c.ccnid49= ISNULL(X.value('@CC49','BIGINT'),0) and c.ccnid50 = ISNULL(X.value('@CC50','BIGINT'),0) 
		and isnull(c.TillDate,0)=isnull(CONVERT(FLOAT,X.value('@TillDate','DATETIME')),0)
		and isnull(c.[Message],'')=isnull(X.value('@Message','NVARCHAR(MAX)'),'')
		)
	end 
	 
		IF @ProfileID=0--NEW
		BEGIN
			DECLARE @lft bigint,@rgt bigint,@Selectedlft bigint,@Selectedrgt bigint,@Depth int,@ParentID bigint
			DECLARE @SelectedIsGroup bit
	
			IF EXISTS (SELECT ProfileID FROM COM_CCTaxesDefn WITH(nolock) WHERE ProfileName=@ProfileName) 
				RAISERROR('-112',16,1) 
			
			if @SelectedNodeID=0
				set @SelectedNodeID=-1

			--To Set Left,Right And Depth of Record
			SELECT @SelectedIsGroup=IsGroup,@Selectedlft =lft,@Selectedrgt=rgt,@ParentID=ParentID,@Depth=Depth
			from COM_CCTaxesDefn with(NOLOCK) where ProfileID=@SelectedNodeID

			--IF No Record Selected or Record Doesn't Exist
			IF(@SelectedIsGroup is null) 
				select @SelectedNodeID=ProfileID,@SelectedIsGroup=IsGroup,@Selectedlft =lft,@Selectedrgt=rgt,@ParentID=ParentID,@Depth=Depth
				from COM_CCTaxesDefn with(NOLOCK) where ParentID =0
						
			IF(@SelectedIsGroup = 1)--Adding Node Under the Group
			BEGIN
				UPDATE COM_CCTaxesDefn SET rgt = rgt + 2 WHERE rgt > @Selectedlft;
				UPDATE COM_CCTaxesDefn SET lft = lft + 2 WHERE lft > @Selectedlft;
				SET @lft =  @Selectedlft + 1
				SET @rgt =	@Selectedlft + 2
				SET @ParentID = @SelectedNodeID
				SET @Depth = @Depth + 1
			END
			ELSE IF(@SelectedIsGroup = 0)--Adding Node at Same level
			BEGIN
				UPDATE COM_CCTaxesDefn SET rgt = rgt + 2 WHERE rgt > @Selectedrgt;
				UPDATE COM_CCTaxesDefn SET lft = lft + 2 WHERE lft > @Selectedrgt;
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
			INSERT INTO COM_CCTaxesDefn(ProfileName,
							[IsGroup],[Depth],[ParentID],[lft],[rgt],
							[CompanyGUID],[GUID],[CreatedBy],[CreatedDate])
							VALUES
							(@ProfileName,
							@IsGroup,@Depth,@ParentID,@lft,@rgt,
							@CompanyGUID,newid(),@UserName,@Dt)
			--To get inserted record primary key
			SET @ProfileID=SCOPE_IDENTITY() 
			
			SET @SPInvoice = cursor for 
			SELECT X.value('@DocID','INT'),X.value('@ColID','BIGINT'),ISNULL(X.value('@ProductID','BIGINT'),0),X.value('@Price','FLOAT'),CONVERT(FLOAT,X.value('@WEF','DATETIME'))
				,ISNULL(X.value('@AccountID','BIGINT'),0),ISNULL(X.value('@VID','BIGINT'),0),CONVERT(FLOAT,X.value('@TillDate','DATETIME')),X.value('@Message','NVARCHAR(MAX)')
				,isnull(X.value('@CCUpdate','NVARCHAR(MAX)'),'')
			FROM @XML.nodes('/XML/Row') as Data(X)
			WHERE X.value('@CCTaxID','BIGINT') IS NULL

			OPEN @SPInvoice 
			SET @nStatusOuter = @@FETCH_STATUS
			
			FETCH NEXT FROM @SPInvoice Into @DocID,@ColID,@ProductID,@Price,@WEF,@AccountID,@VID,@TillDate,@Message,@CCUpdate
			SET @nStatusOuter = @@FETCH_STATUS
			WHILE(@nStatusOuter <> -1)
			BEGIN
				INSERT INTO COM_CCTaxes([ProfileID],[ProfileName]
				   ,[DocID],[ColID],[ProductID],[Value],[WEF],[AccountID],VehicleID,TillDate,[Message]
				   ,[CompanyGUID],[GUID],[CreatedBy],[CreatedDate]) 
				SELECT @ProfileID,@ProfileName
					,@DocID,@ColID,@ProductID,@Price,@WEF,@AccountID,@VID,@TillDate,@Message
					,@CompanyGUID,NEWID(),@UserName,CONVERT(FLOAT,GETDATE())
				set @CCTaxID=Scope_Identity()
				--select @CCTaxID,@CCUpdate
				if @CCUpdate!=''
				begin
					set @SQL='update COM_CCTaxes set '+substring(@CCUpdate,2,len(@CCUpdate)-1)+' where CCTaxID='+convert(nvarchar,@CCTaxID)
					exec(@SQL)
				end
				
				FETCH NEXT FROM @SPInvoice Into @DocID,@ColID,@ProductID,@Price,@WEF,@AccountID,@VID,@TillDate,@Message,@CCUpdate
				SET @nStatusOuter = @@FETCH_STATUS
			END
		END
		ELSE
		BEGIN--EDIT
			--Dont Check Go For New Inserts If its is coming from search
			IF @ProfileID!=-100
			BEGIN
				IF EXISTS (SELECT ProfileID FROM COM_CCTaxesDefn WITH(nolock) WHERE ProfileName=@ProfileName AND ProfileID!=@ProfileID) 
					RAISERROR('-112',16,1) 
				
				UPDATE COM_CCTaxesDefn
				SET ProfileName=@ProfileName,[GUID]=newid(),ModifiedBy=@UserName,ModifiedDate=@Dt
				WHERE ProfileID=@ProfileID

				SET @SPInvoice = cursor for 
				SELECT X.value('@DocID','INT'),X.value('@ColID','BIGINT'),ISNULL(X.value('@ProductID','BIGINT'),0),X.value('@Price','FLOAT'),CONVERT(FLOAT,X.value('@WEF','DATETIME'))
					,ISNULL(X.value('@AccountID','BIGINT'),0),ISNULL(X.value('@VID','BIGINT'),0),CONVERT(FLOAT,X.value('@TillDate','DATETIME')),X.value('@Message','NVARCHAR(MAX)')
					,isnull(X.value('@CCUpdate','NVARCHAR(MAX)'),'')
				FROM @XML.nodes('/XML/Row') as Data(X)
				WHERE X.value('@CCTaxID','BIGINT') IS NULL
				
				OPEN @SPInvoice 
				SET @nStatusOuter = @@FETCH_STATUS
				
				FETCH NEXT FROM @SPInvoice Into @DocID,@ColID,@ProductID,@Price,@WEF,@AccountID,@VID,@TillDate,@Message,@CCUpdate
				SET @nStatusOuter = @@FETCH_STATUS
				WHILE(@nStatusOuter <> -1)
				BEGIN
					INSERT INTO COM_CCTaxes([ProfileID],[ProfileName]
					   ,[DocID],[ColID],[ProductID],[Value],[WEF],[AccountID],VehicleID,TillDate,[Message]
					   ,[CompanyGUID],[GUID],[CreatedBy],[CreatedDate]) 
					SELECT @ProfileID,@ProfileName
						,@DocID,@ColID,@ProductID,@Price,@WEF,@AccountID,@VID,@TillDate,@Message
						,@CompanyGUID,NEWID(),@UserName,CONVERT(FLOAT,GETDATE())
					set @CCTaxID=Scope_Identity()
					--select @CCTaxID,@CCUpdate
					if @CCUpdate!=''
					begin
						set @SQL='update COM_CCTaxes set '+substring(@CCUpdate,2,len(@CCUpdate)-1)+' where CCTaxID='+convert(nvarchar,@CCTaxID)
						exec(@SQL)
					end
					
					FETCH NEXT FROM @SPInvoice Into @DocID,@ColID,@ProductID,@Price,@WEF,@AccountID,@VID,@TillDate,@Message,@CCUpdate
					SET @nStatusOuter = @@FETCH_STATUS
				END
			END
			
			UPDATE COM_CCTaxes
			SET DocID=CONVERT(FLOAT,X.value('@DocID','INT')),
				ColID=CONVERT(FLOAT,X.value('@ColID','BIGINT')),
				WEF=CONVERT(FLOAT,X.value('@WEF','DATETIME')),
				TillDate=CONVERT(FLOAT,X.value('@TillDate','DATETIME')),
				Value=ISNULL(X.value('@Price','FLOAT'),0),
				[Message]=X.value('@Message','NVARCHAR(MAX)')
			FROM @XML.nodes('/XML/Row') as Data(X),COM_CCTaxes P
			WHERE X.value('@CCTaxID','BIGINT') IS NOT NULL AND P.CCTaxID=X.value('@CCTaxID','BIGINT')
			
			--Delete Rows
			IF @DeleteXML IS NOT NULL AND @DeleteXML!=''
			BEGIN
				SET @XML=@DeleteXML
				DELETE FROM COM_CCTaxes
				WHERE CCTaxID IN (SELECT X.value('@ID','BIGINT') FROM @XML.nodes('/XML/Row') as Data(X))
				
			END
		END
	
	 	--Added to set default inactive if action exists
		SET @HasAccess=dbo.fnCOM_HasAccess(@RoleID,45,156)
		if(@HasAccess!=0)
		begin
			update COM_CCTaxesDefn set statusid=2 where profileid=@ProfileID
			update COM_CCTaxes  set statusid=2 where profileid=@ProfileID
		end 
	--To Set Used CostCenters with Group Check
	EXEC [spADM_SetPriceTaxUsedCC] 2,@ProfileID,1
	

	--select * from COM_CCTaxesDefn with(nolock) where ProfileID=@ProfileID
	--select * from COM_CCPriceTaxCCDefn with(nolock) where DefType=2 and ProfileID=@ProfileID
	--select * from COM_CCTaxes with(nolock) where ProfileID=@ProfileID
	
	
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

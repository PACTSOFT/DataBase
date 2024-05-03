USE PACT2C222
GO
SET ANSI_NULLS, QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spSVC_SetCustomizeTicket]
	@NumericXML [nvarchar](max),
	@LinkXML [nvarchar](max),
	@CompanyGUID [nvarchar](50),
	@UserName [nvarchar](50),
	@USERID [int],
	@LANGID [int]
WITH ENCRYPTION, EXECUTE AS CALLER
AS
BEGIN TRANSACTION  
BEGIN TRY  
SET NOCOUNT ON;
		--Declaration Section  	
		DECLARE @XML xml,@I INT,@Cnt INT
		DECLARE @ColFieldType INT,@Header NVARCHAR(500),@FORMULA NVARCHAR(MAX)
		DECLARE @DebitAccount BIGINT,@CreditAccount BIGINT,@PostingType INT,@RoundOff INT,@IsDrAccountDisplayed BIT,@IsCrAccountDisplayed BIT
		DECLARE @IsRoundOffEnabled BIT,@IsDistributionEnabled BIT,@ColumnCostCenterID int,@IsCalculate bit, @IsReadOnly bit, @IsVisible Bit
		DECLARE @DistributionColID BIGINT,@RoundOffLineWise INT,@ListViewTypeID BIGINT,@CostCenterColID BIGINT
		DECLARE @SectionID INT,@IsMandatory BIT,@UserDefaultValue NVARCHAR(200),@SectionName  NVARCHAR(200)
		DECLARE @LinkDefID BIGINT, @SectionSeqNumber INT
		DECLARE @CrRefID bigint, @CrRefColID bigint, @DrRefID bigint, @DrRefColID bigint
	 
	 
		DECLARE @tblList AS TABLE(ID int identity(1,1),ColFieldType INT,
			Header NVARCHAR(200),FORMULA  NVARCHAR(max),
			DebitAccount BIGINT,CreditAccount BIGINT,PostingType INT,RoundOff INT,
			DistributionColID BIGINT,RoundOffLineWise INT,ColumnCostCenterID int,ListViewTypeID int,
			SectionID INT,IsMandatory BIT, IsReadOnly bit, UserDefaultValue NVARCHAR(200),SectionName  NVARCHAR(200),
			IsCrAccountDisplayed BIT,IsDrAccountDisplayed BIT,
			CostCenterColID BIGINT,IsCalculate bit, SectionSeqNumber int,
			CrRefID bigint  ,CrRefColID bigint,DrRefID bigint,DrRefColID bigint, IsVisible bit)

		SET @XML=@NumericXML

		INSERT INTO @tblList
		SELECT  X.value('@ColFieldType','INT'),
		X.value('@Header','NVARCHAR(200)'), X.value('@Formula','NVARCHAR(max)'),X.value('@DebitAccount','BIGINT'), X.value('@CreditAccount','BIGINT'), X.value('@PostingType','INT'), X.value('@RoundOff','INT'), 
		X.value('@DistributionColID','BIGINT'), X.value('@RoundOffLineWise','INT'),  X.value('@ColumnCostCenterID','INT'), X.value('@ListViewTypeID','INT'),
		X.value('@SectionID','INT'), X.value('@IsMandatory','BIT'), X.value('@IsReadOnly','BIT'), 
		X.value('@UserDefaultValue','NVARCHAR(200)'), X.value('@SectionName','NVARCHAR(200)'), 
		X.value('@IsCrAccountDisplayed','BIT'), X.value('@IsDrAccountDisplayed','BIT'), X.value('@CostCenterColID','BIGINT'), X.value('@IsCalculate','BIT'), X.value('@SectionSeqNumber','int'),
		X.value('@CrRefID','bigint'), X.value('@CrRefColID','bigint'), X.value('@DrRefID','bigint'), X.value('@DrRefColID','bigint'), X.value('@IsVisible','BIT')
 		from @XML.nodes('/Xml/Row') as Data(X)

		--SELECT * FROM @tblList	

		DELETE FROM [ADM_DocumentDef] WHERE [DocumentTypeID]=59 AND [CostCenterID]=59
	 
		--Set loop initialization varaibles
		SELECT @I=1, @Cnt=count(*) FROM @tblList

		WHILE(@I<=@Cnt)  
		BEGIN
		
			SELECT @ColFieldType=1 ,@Header=Header,@Formula=Formula,
				@DebitAccount=DebitAccount,@CreditAccount=CreditAccount,@PostingType=PostingType,@RoundOff=RoundOff,
				@DistributionColID =DistributionColID ,@RoundOffLineWise =RoundOffLineWise ,@ColumnCostCenterID =ColumnCostCenterID,@ListViewTypeID=ListViewTypeID,
				@SectionID =SectionID ,@IsMandatory =IsMandatory ,@UserDefaultValue =UserDefaultValue ,@SectionName  =SectionName  ,
				@IsCrAccountDisplayed =IsCrAccountDisplayed ,@IsDrAccountDisplayed =IsDrAccountDisplayed ,@CostCenterColID =CostCenterColID ,
				@IsCalculate=IsCalculate, @SectionSeqNumber=SectionSeqNumber, @IsReadOnly=IsReadOnly,
				@CrRefID =CrRefID,@CrRefColID =CrRefColID ,@DrRefID =DrRefID ,@DrRefColID=DrRefColID,@IsVisible=IsVisible
			FROM @tblList WHERE ID=@I

			UPDATE [ADM_CostCenterDef] 
			SET IsColumnInUse=0
			WHERE [CostCenterID]=59 AND SysColumnName LIKE 'dcNum%'

			UPDATE [ADM_CostCenterDef] 
			SET IsColumnInUse=1
			FROM [ADM_CostCenterDef] C INNER JOIN @tblList TBL ON TBL.CostCenterColID=C.CostCenterColID
			WHERE [CostCenterID]=59 AND SysColumnName LIKE 'dcNum%'
			
			
			UPDATE [ADM_CostCenterDef] 
			SET IsColumnInUse=1, SectionSeqNumber=@SectionSeqNumber, IsEditable=@IsReadOnly, IsVisible=@IsVisible
			FROM [ADM_CostCenterDef] C INNER JOIN @tblList TBL ON TBL.CostCenterColID=C.CostCenterColID
			WHERE [CostCenterID]=59 AND SysColumnName LIKE 'dcNum%' 
			and c.CostCenterColID in (select CostCenterColID from @tblList where id=@I)
			
			
			IF(@RoundOff>0)
				SET @IsRoundOffEnabled=1
			ELSE
				SET @IsRoundOffEnabled=0

			IF(@RoundOff>0)
				SET @IsDistributionEnabled=1
			ELSE
				SET @IsDistributionEnabled=0
				
			if(@CrRefColID is not null and @CrRefColID>0)
			begin   
				select @ColumnCostCenterID=CostCenterID from ADM_CostCenterDef where CostCenterColID=@CrRefColID
				if(@ColumnCostCenterID>50000)
				begin
					select  @CrRefID= CostCenterColID from ADM_CostCenterDef              
					 where CostCenterID=59 and ColumnCostCenterID=@ColumnCostCenterID  			 
				end
			end
			if(@DrRefColID is not null and @DrRefColID>0)
			begin	
				select @ColumnCostCenterID=CostCenterID from ADM_CostCenterDef where CostCenterColID=@DrRefColID
				if(@ColumnCostCenterID>50000)
				begin
					select  @DrRefID= CostCenterColID from ADM_CostCenterDef              
					 where CostCenterID=59 and ColumnCostCenterID=@ColumnCostCenterID  	
				end
			end
			
			IF EXISTS(SELECT CostCenterColID FROM ADM_DocumentDef WHERE CostCenterColID=@CostCenterColID) 
			BEGIN
				UPDATE ADM_DocumentDef
				SET  [DebitAccount] = @DebitAccount
					,[CreditAccount] = @CreditAccount
					,[Formula] = @Formula
					,[PostingType] = @PostingType
					,[RoundOff] = @RoundOff
					,[IsRoundOffEnabled] = @IsRoundOffEnabled
					,RoundOffLineWise=@RoundOffLineWise
					,[IsDrAccountDisplayed] = @IsDrAccountDisplayed
					,[IsCrAccountDisplayed] = @IsCrAccountDisplayed
					,[IsDistributionEnabled] = @IsDistributionEnabled
					,[DistributionColID] =@DistributionColID	 
					,IsCalculate=@IsCalculate			
					,CrRefID=@CrRefID, CrRefColID=@CrRefColID , DrRefID =@DrRefID,DrRefColID =@DrRefColID
				WHERE CostCenterColID=@CostCenterColID
			END
			ELSE
			BEGIN 
				INSERT INTO [ADM_DocumentDef]
						   ([DocumentTypeID],[CostCenterID],[CostCenterColID]
						   ,[DebitAccount],[CreditAccount],[Formula]
						   ,[PostingType],[RoundOff],[RoundOffLineWise]
						   ,[IsRoundOffEnabled],[IsDrAccountDisplayed],[IsCrAccountDisplayed]
						   ,[IsDistributionEnabled],[DistributionColID],[IsCalculate]
						   ,[CompanyGUID],[GUID],[CreatedBy],[CreatedDate]
						   ,CrRefID, CrRefColID, DrRefID, DrRefColID)
				VALUES(59,59,@CostCenterColID
						   ,@DebitAccount,@CreditAccount,@Formula
						   ,@PostingType,@RoundOff,@RoundOffLineWise
						   ,@IsRoundOffEnabled,@IsDrAccountDisplayed,@IsCrAccountDisplayed
						   ,@IsDistributionEnabled,@DistributionColID,@IsCalculate
						   ,@CompanyGUID,newid() ,@UserName,convert(float,getdate())
						   ,@CrRefID, @CrRefColID, @DrRefID, @DrRefColID )
			END 


			IF(@Header!='Quantity' and @Header!='Rate' and @Header!='Gross')
			BEGIN
				UPDATE COM_LanguageResources
				SET ResourceData=@Header
				WHERE ResourceID=(SELECT ResourceID FROM ADM_CostCenterDef
				WHERE CostCenterColID=@CostCenterColID) AND LanguageID=@LangID
			END

			SET @I=@I+1
		END
--SELECT UserColumnName,IsColumnInUse FROM [ADM_CostCenterDef] 
--WHERE [CostCenterID]=59 AND SysColumnName LIKE 'dcNum%'
SET @XML=@LinkXML              
          
   DELETE FROM COM_DocumentLinkDetails where DocumentLinkDefID in (
   select DocumentLinkDefID FROM [COM_DocumentLinkDef]              
   WHERE CostCenterIDBase=59)
    
    DELETE FROM [COM_DocumentLinkDef]              
	WHERE CostCenterIDBase=59
	
  --DELETE FROM [COM_DocumentLinkDef]              
  --WHERE CostCenterIDBase=59 AND DocumentLinkDefID NOT IN               
  --(SELECT  X.value('@DocumentLinkDefID','bigint') FROM  @XML.nodes('/Xml/Row') as Data(X)              
  --WHERE  X.value('@DocumentLinkDefID','bigint')> 0 )     
  
           
  if(@LinkXML IS NOT NULL AND @LinkXML <>'')              
  BEGIN              
  
  		 SET @LinkDefID=0
  		 if(@LinkDefID=0)
  		 begin
		   INSERT INTO [COM_DocumentLinkDef]              
				([CostCenterIDLinked] 
				,[CostCenterIDBase]              
				,[CostCenterColIDBase]   
				,[CostCenterColIDLinked]   
				,[CompanyGUID]              
				,[GUID]              
				,[CreatedBy]              
				,[CreatedDate])  
			select distinct X.value('@CostCenterIDLinked','bigint'),
				59
				,22777				 
				,111				 
				,@CompanyGUID 
				,'GUID'
				,@UserName
				,CONVERT(FLOAT,GETDATE()) from @XML.nodes('/Xml/Row') as Data(X) 
				     			
				set @LinkDefID=scope_identity()	
		 end
		 
		
 	 
		insert into COM_DocumentLinkDetails(DocumentLinkDeFID,
											CostCenterColIDBase,
											CostCenterColIDLinked,
											CompanyGUID,
											GUID,
											CreatedBy,
											CreatedDate)
		select @LinkDefID,X.value('@CostCenterColIDBase','bigint'),X.value('@CostCenterColIDLink','bigint'),@CompanyGUID,NEWID() ,@UserName,CONVERT(FLOAT,GETDATE())
		from @XML.nodes('/Xml/Row') as Data(X)
   END

COMMIT TRANSACTION    
--ROLLBACK TRANSACTION
SET NOCOUNT OFF; 
SELECT ErrorMessage,ErrorNumber FROM COM_ErrorMessages WITH(nolock) 
WHERE ErrorNumber=100 AND LanguageID=@LangID  
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
	ROLLBACK TRANSACTION
	SET NOCOUNT OFF  
	RETURN -999   
END CATCH 


GO

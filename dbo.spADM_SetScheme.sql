USE PACT2C222
GO
SET ANSI_NULLS, QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spADM_SetScheme]
	@ProfileID [bigint],
	@ProfileName [nvarchar](50),
	@SchemeXML [nvarchar](max) = null,
	@CompanyGUID [nvarchar](50) = null,
	@UserName [nvarchar](50),
	@UserID [bigint],
	@LangID [int] = 1
WITH ENCRYPTION, EXECUTE AS CALLER
AS
BEGIN TRANSACTION  
BEGIN TRY  
SET NOCOUNT ON;
		--Declaration Section  
		DECLARE @Dt FLOAT ,@XML XML,@SchemeID BIGINT
		
		DECLARE @TblXML TABLE(ID INT IDENTITY(1,1),Schemexml nvarchar(max))
		DECLARE @I INT,@Count INT,@Price FLOAT,@WEF DATETIME,@GroupID BIGINT

		SET @Dt=convert(float,getdate())--Setting Current Date      
		SET @XML=@SchemeXML

		IF EXISTS (SELECT SchemeID FROM [ADM_SchemesDiscounts] WITH(nolock) 
		WHERE [ProfileName]=@ProfileName and ProfileID<>@ProfileID)  
		BEGIN  
			RAISERROR('-108',16,1)  
		END 

		DELETE FROM [ADM_SchemesDiscounts] 
		WHERE ProfileID=@ProfileID and SchemeID not in 
		(select X.value('@SchemeID','BIGINT')
		FROM @XML.nodes('/XML/Row/XML') as Data(X) where X.value('@SchemeID','BIGINT')<>0)
			
		 
		 if(@ProfileID=0)
			select @ProfileID=isnull(MAX(ProfileID),0)+1 from [ADM_SchemesDiscounts] with(nolock)

		INSERT INTO @TblXML      
		SELECT CONVERT(NVARCHAR(MAX), X.query('XML'))
		from @XML.nodes('/XML/Row') as Data(X)      
	  
		set @I=0
		SELECT @Count=MAX(ID) FROM @TblXML
		
		WHILE @I<@Count
		BEGIN 
			set @I=@I+1
			SELECT @XML=Schemexml  FROM @TblXML  WHERE ID=@I  
			
			select @SchemeID=ISNULL(X.value('@SchemeID','BIGINT'),0)
			FROM @XML.nodes('/XML') as Data(X)
			
			
			if(@SchemeID=0)
			BEGIN						       
				INSERT INTO [ADM_SchemesDiscounts]
				   ([ProfileID],[ProfileName],[ProductID],[AccountID]
				   ,FromDate,ToDate,StatusID,FromQty,ToQty,FromValue,ToValue,Percentage,IsQtyPercent
				   ,Quantity,Value,[CCNID1],[CCNID2],[CCNID3],[CCNID4],[CCNID5],[CCNID6],[CCNID7],[CCNID8],[CCNID9],[CCNID10]
				   ,[CCNID11],[CCNID12],[CCNID13],[CCNID14],[CCNID15],[CCNID16],[CCNID17],[CCNID18],[CCNID19],[CCNID20]
				   ,[CCNID21],[CCNID22],[CCNID23],[CCNID24],[CCNID25],[CCNID26],[CCNID27],[CCNID28],[CCNID29],[CCNID30]
				   ,[CCNID31],[CCNID32],[CCNID33],[CCNID34],[CCNID35],[CCNID36],[CCNID37],[CCNID38],[CCNID39],[CCNID40]
				   ,[CCNID41],[CCNID42],[CCNID43],[CCNID44],[CCNID45],[CCNID46],[CCNID47],[CCNID48],[CCNID49],[CCNID50]
				   ,[CompanyGUID],[GUID],[CreatedBy],[CreatedDate])

				SELECT @ProfileID,@ProfileName,ISNULL(X.value('@ProductID','BIGINT'),1),ISNULL(X.value('@AccountID','BIGINT'),1),CONVERT(FLOAT,X.value('@FromDate','DATETIME')),CONVERT(FLOAT,X.value('@ToDate','DATETIME')),
					ISNULL(X.value('@StatusID','BIGINT'),0),ISNULL(X.value('@FromQty','FLOAT'),0),ISNULL(X.value('@ToQty','FLOAT'),0),ISNULL(X.value('@FromValue','FLOAT'),0),ISNULL(X.value('@ToValue','FLOAT'),0),ISNULL(X.value('@Percentage','FLOAT'),0),
					ISNULL(X.value('@IsQtyPercent','INT'),0),ISNULL(X.value('@Quantity','FLOAT'),0),ISNULL(X.value('@Value','FLOAT'),0),ISNULL(X.value('@CC1','BIGINT'),1),ISNULL(X.value('@CC2','BIGINT'),1),ISNULL(X.value('@CC3','BIGINT'),1),ISNULL(X.value('@CC4','BIGINT'),1),ISNULL(X.value('@CC5','BIGINT'),1),ISNULL(X.value('@CC6','BIGINT'),1),ISNULL(X.value('@CC7','BIGINT'),1),ISNULL(X.value('@CC8','BIGINT'),1),ISNULL(X.value('@CC9','BIGINT'),1),ISNULL(X.value('@CC10','BIGINT'),1),
					ISNULL(X.value('@CC11','BIGINT'),1),ISNULL(X.value('@CC12','BIGINT'),1),ISNULL(X.value('@CC13','BIGINT'),1),ISNULL(X.value('@CC14','BIGINT'),1),ISNULL(X.value('@CC15','BIGINT'),1),ISNULL(X.value('@CC16','BIGINT'),1),ISNULL(X.value('@CC17','BIGINT'),1),ISNULL(X.value('@CC18','BIGINT'),1),ISNULL(X.value('@CC19','BIGINT'),1),ISNULL(X.value('@CC20','BIGINT'),1),
					ISNULL(X.value('@CC21','BIGINT'),1),ISNULL(X.value('@CC22','BIGINT'),1),ISNULL(X.value('@CC23','BIGINT'),1),ISNULL(X.value('@CC24','BIGINT'),1),ISNULL(X.value('@CC25','BIGINT'),1),ISNULL(X.value('@CC26','BIGINT'),1),ISNULL(X.value('@CC27','BIGINT'),1),ISNULL(X.value('@CC28','BIGINT'),1),ISNULL(X.value('@CC29','BIGINT'),1),ISNULL(X.value('@CC30','BIGINT'),1),
					ISNULL(X.value('@CC31','BIGINT'),1),ISNULL(X.value('@CC32','BIGINT'),1),ISNULL(X.value('@CC33','BIGINT'),1),ISNULL(X.value('@CC34','BIGINT'),1),ISNULL(X.value('@CC35','BIGINT'),1),ISNULL(X.value('@CC36','BIGINT'),1),ISNULL(X.value('@CC37','BIGINT'),1),ISNULL(X.value('@CC38','BIGINT'),1),ISNULL(X.value('@CC39','BIGINT'),1),ISNULL(X.value('@CC40','BIGINT'),1),
					ISNULL(X.value('@CC41','BIGINT'),1),ISNULL(X.value('@CC42','BIGINT'),1),ISNULL(X.value('@CC43','BIGINT'),1),ISNULL(X.value('@CC44','BIGINT'),1),ISNULL(X.value('@CC45','BIGINT'),1),ISNULL(X.value('@CC46','BIGINT'),1),ISNULL(X.value('@CC47','BIGINT'),1),ISNULL(X.value('@CC48','BIGINT'),1),ISNULL(X.value('@CC49','BIGINT'),1),ISNULL(X.value('@CC50','BIGINT'),1),
					@CompanyGUID,NEWID(),@UserName,CONVERT(FLOAT,GETDATE())
				FROM @XML.nodes('/XML') as Data(X)
				 SET @SchemeID=@@IDENTITY  
			END
			ELSE
			BEGIN
			
			
				if exists(select IsQtyFreeOffer from INV_DocDetails  with(nolock) where IsQtyFreeOffer=@SchemeID)
				BEGIN
						declare @BaseVal float,@chgValue float
						select @BaseVal=[FromQty]from  [ADM_SchemesDiscounts]	Where SchemeID=@SchemeID
						select @chgValue=ISNULL(X.value('@FromQty','float'),0) FROM @XML.nodes('/XML') as Data(X)
						
						if(@BaseVal<>@chgValue)
						BEGIN
							RAISERROR('-405',16,1)  
						END
						
						select @BaseVal=[ToQty]from  [ADM_SchemesDiscounts]	Where SchemeID=@SchemeID
						select @chgValue=ISNULL(X.value('@ToQty','float'),0) FROM @XML.nodes('/XML') as Data(X)
						
						if(@BaseVal<>@chgValue)
						BEGIN
							RAISERROR('-405',16,1)  
						END
						select @BaseVal=[FromValue]from  [ADM_SchemesDiscounts]	Where SchemeID=@SchemeID
						select @chgValue=ISNULL(X.value('@FromValue','float'),0) FROM @XML.nodes('/XML') as Data(X)
						
						if(@BaseVal<>@chgValue)
						BEGIN
							RAISERROR('-405',16,1)  
						END
						select @BaseVal=[ToValue]from  [ADM_SchemesDiscounts]	Where SchemeID=@SchemeID
						select @chgValue=ISNULL(X.value('@ToValue','float'),0) FROM @XML.nodes('/XML') as Data(X)
						
						if(@BaseVal<>@chgValue)
						BEGIN
							RAISERROR('-405',16,1)  
						END
						select @BaseVal=Quantity from  [ADM_SchemesDiscounts]	Where SchemeID=@SchemeID
						select @chgValue=ISNULL(X.value('@Quantity','float'),0) FROM @XML.nodes('/XML') as Data(X)
						
						if(@BaseVal<>@chgValue)
						BEGIN
							RAISERROR('-405',16,1)  
						END
						select @BaseVal=Value from  [ADM_SchemesDiscounts]	Where SchemeID=@SchemeID
						select @chgValue=ISNULL(X.value('@Value','float'),0) FROM @XML.nodes('/XML') as Data(X)
						
						if(@BaseVal<>@chgValue)
						BEGIN
							RAISERROR('-405',16,1)  
						END

						select @BaseVal=Percentage from  [ADM_SchemesDiscounts]	Where SchemeID=@SchemeID
						select @chgValue=ISNULL(X.value('@Percentage','float'),0) FROM @XML.nodes('/XML') as Data(X)
						
						IF(CONVERT(INT,@BaseVal)<>CONVERT(INT,@chgValue))
						BEGIN
							RAISERROR('-405',16,1)  
						END
						--if(@BaseVal<>@chgValue)
						--BEGIN
						--	RAISERROR('-405',16,1)  
						--END
				END
				Update [ADM_SchemesDiscounts]
				set [ProfileID]         =@ProfileID
				   ,[ProfileName]		=@ProfileName
				   ,[FromDate]			=CONVERT(FLOAT,X.value('@FromDate','DATETIME'))
				   ,[ToDate]			=CONVERT(FLOAT,X.value('@ToDate','DATETIME'))
				   ,[StatusID]			=ISNULL(X.value('@StatusID','bigint'),0)
				   ,[FromQty]			=ISNULL(X.value('@FromQty','float'),0)
				   ,[ToQty]				=ISNULL(X.value('@ToQty','float'),0)
				   ,[FromValue]			=ISNULL(X.value('@FromValue','float'),0)
				   ,[ToValue]			=ISNULL(X.value('@ToValue','float'),0)
				   ,[Percentage]		=ISNULL(X.value('@Percentage','float'),0)
				   ,IsQtyPercent		=ISNULL(X.value('@IsQtyPercent','INT'),0)
				   ,[Quantity]			=ISNULL(X.value('@Quantity','float'),0)
				   ,[Value]				=ISNULL(X.value('@Value','float'),0)
				   ,[ProductID]			=ISNULL(X.value('@ProductID','bigint'),1)
				   ,[UOMID]				=ISNULL(X.value('@UOMID','bigint'),1)
				   ,[AccountID]			=ISNULL(X.value('@AccountID','bigint'),1)
				   ,[CCNID1]			=ISNULL(X.value('@CC1','bigint'),1)
				   ,[CCNID2]			=ISNULL(X.value('@CC2','bigint'),1)
				   ,[CCNID3]			=ISNULL(X.value('@CC3','bigint'),1)
				   ,[CCNID4]			=ISNULL(X.value('@CC4','bigint'),1)
				   ,[CCNID5]			=ISNULL(X.value('@CC5','bigint'),1)
				   ,[CCNID6]			=ISNULL(X.value('@CC6','bigint'),1)
				   ,[CCNID7]			=ISNULL(X.value('@CC7','bigint'),1)
				   ,[CCNID8]			=ISNULL(X.value('@CC8','bigint'),1)
				   ,[CCNID9]			=ISNULL(X.value('@CC9','bigint'),1)
				   ,[CCNID10]			=ISNULL(X.value('@CC10','bigint'),1)
				   ,[CCNID11]			=ISNULL(X.value('@CC11','bigint'),1)
				   ,[CCNID12]			=ISNULL(X.value('@CC12','bigint'),1)
				   ,[CCNID13]			=ISNULL(X.value('@CC13','bigint'),1)
				   ,[CCNID14]			=ISNULL(X.value('@CC14','bigint'),1)
				   ,[CCNID15]			=ISNULL(X.value('@CC15','bigint'),1)
				   ,[CCNID16]			=ISNULL(X.value('@CC16','bigint'),1)
				   ,[CCNID17]			=ISNULL(X.value('@CC17','bigint'),1)
				   ,[CCNID18]			=ISNULL(X.value('@CC18','bigint'),1)
				   ,[CCNID19]			=ISNULL(X.value('@CC19','bigint'),1)
				   ,[CCNID20]			=ISNULL(X.value('@CC20','bigint'),1)
				   ,[CCNID21]			=ISNULL(X.value('@CC21','bigint'),1)
				   ,[CCNID22]			=ISNULL(X.value('@CC22','bigint'),1)
				   ,[CCNID23]			=ISNULL(X.value('@CC23','bigint'),1)
				   ,[CCNID24]			=ISNULL(X.value('@CC24','bigint'),1)
				   ,[CCNID25]			=ISNULL(X.value('@CC25','bigint'),1)
				   ,[CCNID26]			=ISNULL(X.value('@CC26','bigint'),1)
				   ,[CCNID27]			=ISNULL(X.value('@CC27','bigint'),1)
				   ,[CCNID28]			=ISNULL(X.value('@CC28','bigint'),1)
				   ,[CCNID29]			=ISNULL(X.value('@CC29','bigint'),1)
				   ,[CCNID30]			=ISNULL(X.value('@CC30','bigint'),1)
				   ,[CCNID31]			=ISNULL(X.value('@CC31','bigint'),1)
				   ,[CCNID32]			=ISNULL(X.value('@CC32','bigint'),1)
				   ,[CCNID33]			=ISNULL(X.value('@CC33','bigint'),1)
				   ,[CCNID34]			=ISNULL(X.value('@CC34','bigint'),1)
				   ,[CCNID35]			=ISNULL(X.value('@CC35','bigint'),1)
				   ,[CCNID36]			=ISNULL(X.value('@CC36','bigint'),1)
				   ,[CCNID37]			=ISNULL(X.value('@CC37','bigint'),1)
				   ,[CCNID38]			=ISNULL(X.value('@CC38','bigint'),1)
				   ,[CCNID39]			=ISNULL(X.value('@CC39','bigint'),1)
				   ,[CCNID40]			=ISNULL(X.value('@CC40','bigint'),1)
				   ,[CCNID41]			=ISNULL(X.value('@CC41','bigint'),1)
				   ,[CCNID42]			=ISNULL(X.value('@CC42','bigint'),1)
				   ,[CCNID43]			=ISNULL(X.value('@CC43','bigint'),1)
				   ,[CCNID44]			=ISNULL(X.value('@CC44','bigint'),1)
				   ,[CCNID45]			=ISNULL(X.value('@CC45','bigint'),1)
				   ,[CCNID46]			=ISNULL(X.value('@CC46','bigint'),1)
				   ,[CCNID47]			=ISNULL(X.value('@CC47','bigint'),1)
				   ,[CCNID48]			=ISNULL(X.value('@CC48','bigint'),1)
				   ,[CCNID49]			=ISNULL(X.value('@CC49','bigint'),1)
				   ,[CCNID50]			=ISNULL(X.value('@CC50','bigint'),1)
				   ,[CompanyGUID]		=@CompanyGUID                   
				   ,ModifiedBy			=@UserName
				   ,ModifiedDate		=CONVERT(FLOAT,GETDATE())
				 FROM @XML.nodes('/XML') as Data(X)
				 Where SchemeID=@SchemeID
			END	
			
			delete from ADM_SchemeProducts Where [SchemeID]=@SchemeID
			INSERT INTO ADM_SchemeProducts([SchemeID],[ProductID],[Quantity],[Value],[Percentage] ,IsQtyPercent,Dim1)
			select @SchemeID,ISNULL(X.value('@ProductID','bigint'),1),ISNULL(X.value('@Quantity','float'),0)
			,ISNULL(X.value('@Value','float'),0),ISNULL(X.value('@Percentage','float'),0)
			,ISNULL(X.value('@IsQtyPercent','BIT'),0),X.value('@Dim1','BIGINT')
			FROM @XML.nodes('/XML/ProductsXML/Row') as Data(X)
			
		END
	--	select * from ADM_SchemeProducts
	--select @XML
		
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
		--if(ERROR_MESSAGE()=-405)
		--	SELECT ErrorMessage+' at row no.'+convert(nvarchar,@I) ErrorMessage,ErrorNumber FROM COM_ErrorMessages WITH(NOLOCK) WHERE ErrorNumber=ERROR_MESSAGE() AND LanguageID=@LangID
		--else
		if(ERROR_MESSAGE()=-405)
		BEGIN
			declare @vno nvarchar(200)
			select @vno=VoucherNo from INV_DocDetails  with(nolock) where IsQtyFreeOffer=@SchemeID
			SELECT ErrorMessage+' :'+convert(nvarchar,@vno) ErrorMessage,ErrorNumber FROM COM_ErrorMessages WITH(NOLOCK) WHERE ErrorNumber=ERROR_MESSAGE() AND LanguageID=@LangID
		END
		else
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

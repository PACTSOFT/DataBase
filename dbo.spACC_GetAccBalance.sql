USE PACT2C222
GO
SET ANSI_NULLS, QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spACC_GetAccBalance]
	@AccountID [bigint] = 0,
	@DocID [bigint] = 0,
	@isinventory [bit],
	@SysDate [datetime],
	@DocDate [datetime],
	@UserID [bigint],
	@LangID [int] = 1
WITH ENCRYPTION, EXECUTE AS CALLER
AS
BEGIN TRANSACTION
BEGIN TRY	
SET NOCOUNT ON

		--Declaration Section
		 DECLARE @DebitAmount FLOAT,@CreditLimt FLOAT,@BalDocDate FLOAT,@BalSysDate FLOAT,@includepdc nvarchar(50),@includeunposted nvarchar(50)
		DECLARE @sql nvarchar(max),@where nvarchar(max)
			set @where=''
			
			select @includepdc=value from adm_globalpreferences
			where name='IncludePDCs'
			
			select @includeunposted=value from adm_globalpreferences
			where name='IncludeUnPostedDocs'
			
			if(@includepdc='true')
			begin
				if(@includeunposted<>'true')
					set @where=@where+' and ((DocumentType not in(14,19) and StatusID=369) or (DocumentType in(14,19) and StatusID=370))'
				else
					set @where=@where+' and (DocumentType not in(14,19) or (DocumentType in(14,19) and StatusID=370))'
				
			end	
			else
				set @where=@where+' and DocumentType not in(14,19)'
			
			if(@DocID>0)
			BEGIN
				if(@isinventory=1)
				BEGIN
					set @where=@where+' and invdocdetailsid not in(select invdocdetailsid from inv_docdetails WITH(NOLOCK) where DocID <>'+CONVERT(nvarchar,@DocID)+')'
				END
				ElSE
					set @where=@where+' and DocID <>'+CONVERT(nvarchar,@DocID)
			END
				
			if(@includeunposted<>'true' and @includepdc<>'true')
				set @where=@where+' and StatusID=369'
			 	--Debit Amount as on Document Date		
			set @sql='SELECT @DebitAmount=SUM(ISNULL(AMOUNT,0)) FROM ACC_DocDetails WITH(NOLOCK) where DebitAccount='+convert(nvarchar,@AccountID)
			+' and DocDate<='+convert(nvarchar,convert(float,@DocDate))+@where
			
			exec sp_executesql @sql,N'@DebitAmount float output',@DebitAmount output
			
			
			--Credit Amount as on Document Date			 
			set @sql='SELECT @CreditLimt=SUM(ISNULL(AMOUNT,0)) FROM ACC_DocDetails WITH(NOLOCK) where CreditAccount='+convert(nvarchar,@AccountID)
			+' and DocDate<='+convert(nvarchar,convert(float,@DocDate))+@where
			
			exec sp_executesql @sql,N'@CreditLimt float output',@CreditLimt output
			
			--Total Amount as on Document Date
			SET @BalDocDate=isnull(@CreditLimt,0)-isnull(@DebitAmount,0)--Balance Amount



			--Debit Amount as on System Date		
			set @sql='SELECT @DebitAmount=SUM(ISNULL(AMOUNT,0)) FROM ACC_DocDetails WITH(NOLOCK) where DebitAccount='+convert(nvarchar,@AccountID)
			+' and DocDate<='+convert(nvarchar,convert(float,@SysDate))+@where
			
			exec sp_executesql @sql,N'@DebitAmount float output',@DebitAmount output
			
			
			--Credit Amount as on System Date			 
			set @sql='SELECT @CreditLimt=SUM(ISNULL(AMOUNT,0)) FROM ACC_DocDetails WITH(NOLOCK) where CreditAccount='+convert(nvarchar,@AccountID)
			+' and DocDate<='+convert(nvarchar,convert(float,@SysDate))+@where
			
			exec sp_executesql @sql,N'@CreditLimt float output',@CreditLimt output
		
			 
			--Total Amount as on System Date
			SET @BalSysDate=isnull(@CreditLimt,0)-isnull(@DebitAmount,0)

			--SELECT @BalSysDate SYS,@BalDocDate DOC
			SELECT AccountName,CreditLimit,@BalSysDate As BalSysDate,@BalDocDate As BalDocDate
				,IsBillwise,AccountTypeID  FROM ACC_ACCOUNTS WITH(NOLOCK) WHERE ACCOUNTID=@AccountID


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

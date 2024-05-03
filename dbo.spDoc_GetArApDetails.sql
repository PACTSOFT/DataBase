USE PACT2C222
GO
SET ANSI_NULLS, QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spDoc_GetArApDetails]
	@AccountID [bigint] = 0,
	@DocDate [datetime],
	@docno [nvarchar](500) = NULL,
	@linkedids [nvarchar](max),
	@DocumentType [int],
	@UserID [bigint],
	@LangID [int] = 1
WITH ENCRYPTION, EXECUTE AS CALLER
AS
BEGIN TRANSACTION
BEGIN TRY	
SET NOCOUNT ON
	
	DECLARE @I INT,@CNT INT

	if(@DocumentType=38)
	BEGIN
		DECLARE @Tblids AS TABLE(ID INT NOT NULL IDENTITY(1,1),DetailsID BIGINT)
		INSERT INTO @Tblids(DetailsID)
		exec SPSplitString @linkedids,','  
		
			set @I=0
			WHILE(1=1)
			BEGIN
				SET @CNT=(SELECT Count(*) FROM @Tblids)
				INSERT INTO @Tblids(DetailsID)
				SELECT INV.LinkedInvDocDetailsID
				FROM INV_DocDetails INV with(nolock) 
				INNER JOIN @Tblids T ON INV.InvDocDetailsID=T.DetailsID AND ID>@I
				where INV.LinkedInvDocDetailsID is not null and INV.LinkedInvDocDetailsID>0
				
				IF @CNT=(SELECT Count(*) FROM @Tblids)
					BREAK
				SET @I=@CNT
			END
			
		select * from (
		select a.DocNo,a.Amount,abs(a.Amount)-abs(sum(isnull(b.Amount,0))) Bal from com_billwisenonacc a WITH(NOLOCK)
		left join com_billwisenonacc b WITH(NOLOCK) on a.DocNo=b.RefDocNO and b.Docno<>@docno
		join inv_docdetails d WITH(NOLOCK) on a.DocNo=d.Voucherno
		join @Tblids id on d.InvDocDetailsID=id.DetailsID
		where a.RefDocNO=''
		group by a.DocNo,a.Amount) as t
		where Bal>0.001
	END
	ELSE
	BEGIN
		select * from (
		select a.DocNo,a.Amount,abs(a.Amount)-abs(sum(isnull(b.Amount,0))) Bal from com_billwisenonacc a WITH(NOLOCK)
		left join com_billwisenonacc b WITH(NOLOCK) on a.DocNo=b.RefDocNO and b.Docno<>@docno
		where a.AccountID is not null and a.AccountID=@AccountID and a.RefDocNO=''
		group by a.DocNo,a.Amount) as t
		where Bal>0.001
		
		if(@linkedids<>'')
		BEGIN
			
			DECLARE @Tbl AS TABLE(ID INT NOT NULL IDENTITY(1,1), DetailsID BIGINT,LinkedInvDocDetailsID BIGINT)
			
			INSERT INTO @Tbl(DetailsID)
			exec SPSplitString @linkedids,','  
			set @I=0
			WHILE(1=1)
			BEGIN
				SET @CNT=(SELECT Count(*) FROM @Tbl)
				INSERT INTO @Tbl(DetailsID,LinkedInvDocDetailsID)
				SELECT INV.InvDocDetailsID,CASE WHEN T.LinkedInvDocDetailsID IS NULL THEN INV.LinkedInvDocDetailsID ELSE T.LinkedInvDocDetailsID END
				FROM INV_DocDetails INV with(nolock) 
				INNER JOIN @Tbl T ON INV.LinkedInvDocDetailsID=T.DetailsID AND ID>@I
				
				IF @CNT=(SELECT Count(*) FROM @Tbl)
					BREAK
				SET @I=@CNT
			END
			
			 	
			select a.docno from Com_BillwiseNonAcc a WITH(NOLOCK)
			join inv_docdetails b WITH(NOLOCK) on a.docno=b.voucherno
			join @Tbl c on b.InvDocDetailsID=c.DetailsID
			where a.accountid is not null and refdocno=''
			
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

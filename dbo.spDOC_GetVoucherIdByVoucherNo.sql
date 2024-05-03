USE PACT2C222
GO
SET ANSI_NULLS, QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spDOC_GetVoucherIdByVoucherNo]
	@DocumentID [bigint],
	@VoucherNo [nvarchar](max),
	@IsInventoryDoc [bit] = 0,
	@UserID [bigint],
	@LangID [int] = 1
WITH ENCRYPTION, EXECUTE AS CALLER
AS
BEGIN TRY  
SET NOCOUNT ON;
		--Declaration Section
		DECLARE @VoucherID BIGINT
		
		SET @VoucherID=0

		IF @DocumentID=59
		BEGIN
			SELECT TOP 1 @VoucherID=ServiceTicketID FROM SVC_ServiceTicket WITH(NOLOCK)
			WHERE ServiceTicketNumber=@VoucherNo
		END
		else IF @DocumentID=84
		BEGIN
			SELECT TOP 1 @VoucherID=SvcContractID FROM CRM_ServiceContract WITH(NOLOCK)
			WHERE DocID=@VoucherNo
		END
		else IF @DocumentID=86
		BEGIN
			SELECT TOP 1 @VoucherID=LEADID FROM CRM_LEADS WITH(NOLOCK)
			WHERE CODE=@VoucherNo
		END
		else IF @DocumentID=89
		BEGIN
			SELECT TOP 1 @VoucherID=OPPORTUNITYID FROM CRM_OPPORTUNITIES WITH(NOLOCK)
			WHERE CODE=@VoucherNo
		END
		else IF @DocumentID=73
		BEGIN
			SELECT TOP 1 @VoucherID=CASEID FROM CRM_CASES WITH(NOLOCK)
			WHERE CASENUMBER=@VoucherNo
		END
		ELSE IF @DocumentID=78
		BEGIN
			SELECT TOP 1 @VoucherID=MFGOrderID FROM PRD_MFGOrder WITH(NOLOCK)
			WHERE OrderNumber=@VoucherNo
		END
		ELSE IF @DocumentID=88
		BEGIN
			SELECT TOP 1 @VoucherID=CAMPAIGNID FROM CRM_Campaigns WITH(NOLOCK)
			WHERE CODE=@VoucherNo
		END
		else IF @DocumentID=95 OR @DocumentID=104
		BEGIN
			SELECT TOP 1 @VoucherID=ContractID FROM REN_Contract WITH(NOLOCK)
			WHERE RefContractID=0 AND SNO=convert(bigint,@VoucherNo) AND CostCenterID=@DocumentID
		END
		else IF @DocumentID=103 OR @DocumentID=129
		BEGIN
			SELECT TOP 1 @VoucherID=QuotationID FROM REN_Quotation WITH(NOLOCK)
			WHERE SNO=convert(bigint,@VoucherNo) AND CostCenterID=@DocumentID
		END
		ELSE IF @DocumentID>50000 and @DocumentID<50100
		BEGIN
			select @VoucherNo='select @VoucherID=NodeID from '+TableName+' with(nolock) where Code='''+@VoucherNo+'''' from ADM_Features with(Nolock) where FeatureID=@DocumentID
			EXEC sp_executesql @VoucherNo,N'@VoucherID INT OUTPUT',@VoucherID OUTPUT
		END
		ELSE
		BEGIN
			IF @IsInventoryDoc=1
			BEGIN
				SELECT TOP 1 @VoucherID=DocID FROM INV_DocDetails WITH(NOLOCK)
				WHERE CostCenterID=@DocumentID AND substring(VoucherNo, len(DocAbbr)+2,len(VoucherNo))=@VoucherNo
			END
			ELSE
			BEGIN
				SELECT TOP 1 @VoucherID=DocID FROM ACC_DocDetails WITH(NOLOCK)
				WHERE CostCenterID=@DocumentID AND substring(VoucherNo, len(DocAbbr)+2,len(VoucherNo))=@VoucherNo
			END
		END

		IF @VoucherID=0
		BEGIN
			SELECT ErrorMessage,ErrorNumber FROM COM_ErrorMessages WITH(NOLOCK) WHERE ErrorNumber=-118 AND LanguageID=@LangID
		END
		
		--print(@VoucherID)

SET NOCOUNT OFF;   
RETURN @VoucherID
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
SET NOCOUNT OFF  
RETURN -999   
END CATCH
GO

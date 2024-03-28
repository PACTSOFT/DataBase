USE PACT2C222
GO
SET ANSI_NULLS, QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[SPCRM_GetBillingFreequence]
	@TemplateID [int]
WITH ENCRYPTION, EXECUTE AS CALLER
AS
select BillfrequencyName,BillfrequencyID from CRM_ContractTemplate
where ContractTemplID=@TemplateID


	RETURN
GO

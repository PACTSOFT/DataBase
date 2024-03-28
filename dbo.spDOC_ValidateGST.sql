USE PACT2C222
GO
SET ANSI_NULLS, QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spDOC_ValidateGST]
	@CCID [int],
	@VoucherType [int],
	@DocID [bigint],
	@DocNo [nvarchar](50)
WITH ENCRYPTION, EXECUTE AS CALLER
AS
if @VoucherType=0
		return
GO

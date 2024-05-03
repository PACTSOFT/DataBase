USE PACT2C222
GO
SET ANSI_NULLS, QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spREN_PostContract]
	@date [datetime],
	@RcptXML [nvarchar](max) = NULL,
	@PDRcptXML [nvarchar](max) = NULL,
	@ComRcptXML [nvarchar](max) = NULL,
	@SIVXML [nvarchar](max) = NULL,
	@RentRcptXML [nvarchar](max) = NULL,
	@WONO [nvarchar](500),
	@LocationID [bigint],
	@DivisionID [bigint],
	@RoleID [bigint],
	@CompanyGUID [nvarchar](50),
	@UserName [nvarchar](50),
	@UserID [int] = 0,
	@LangID [int] = 1
WITH ENCRYPTION, EXECUTE AS CALLER
AS
BEGIN TRANSACTION    
BEGIN TRY    
SET NOCOUNT ON;  
  --Declaration Section  
   

Declare @RcptCCID BIGint,@ComRcptCCID bigint,@SIVCCID bigint,@RentRcptCCID bigint,@return_value int,@PrefValue nvarchar(200)
 if(@RcptXML is not null and @RcptXML<>'')
  begin
		select @RcptCCID=CONVERT(int,Value) from COM_CostCenterPreferences WITH(nolock)
		where CostCenterID=95 and Name='ContractBankReceipt'
	
	print 12
		EXEC	@return_value = [dbo].[spDOC_SetAccountDocument]
		@CostCenterID = @RcptCCID,
		@DocID = 0,
		@DocPrefix = N'',
		@DocNumber =1,
		@DocDate = @date,
		@DueDate = NULL,
		@BillNo = @wono,
		@InvDocXML = @RcptXML,
		@NotesXML = N'',
		@AttachmentsXML = N'',
		@IsImport = 0,
		@LocationID = @LocationID,
		@DivisionID = @DivisionID,
		@WID = 0,
		@RoleID = @RoleID,
		@CompanyGUID = @CompanyGUID,
		@UserName = @UserName,
		@UserID = @UserID,
		@LangID = @LangID
		print 2
  end
   
  
    if(@PDRcptXML is not null and @PDRcptXML<>'')
  begin
		select @RcptCCID=CONVERT(int,Value) from COM_CostCenterPreferences WITH(nolock)
		where CostCenterID=95 and Name='ContractPostDatedReceipt'
	print 3
		EXEC	@return_value = [dbo].[spDOC_SetAccountDocument]
		@CostCenterID = @RcptCCID,
		@DocID = 0,
		@DocPrefix = N'',
		@DocNumber =1,
		@DocDate = @date,
		@DueDate = NULL,
		@BillNo = @wono,
		@InvDocXML = @PDRcptXML,
		@NotesXML = N'',
		@AttachmentsXML = N'',
		@IsImport = 0,
		@LocationID = @LocationID,
		@DivisionID = @DivisionID,
		@WID = 0,
		@RoleID = @RoleID,
		@CompanyGUID = @CompanyGUID,
		@UserName = @UserName,
		@UserID = @UserID,
		@LangID = @LangID
		print 4
  end

  
    if(@ComRcptXML is not null and @ComRcptXML<>'')
  begin
		select @RcptCCID=CONVERT(int,Value) from COM_CostCenterPreferences WITH(nolock)
		where CostCenterID=95 and Name='ContractBankReceipt'
	print 5
		EXEC	@return_value = [dbo].[spDOC_SetAccountDocument]
		@CostCenterID = @RcptCCID,
		@DocID = 0,
		@DocPrefix = N'',
		@DocNumber =1,
		@DocDate = @date,
		@DueDate = NULL,
		@BillNo = @wono,
		@InvDocXML = @ComRcptXML,
		@NotesXML = N'',
		@AttachmentsXML = N'',
		@IsImport = 0,
		@LocationID = @LocationID,
		@DivisionID = @DivisionID,
		@WID = 0,
		@RoleID = @RoleID,
		@CompanyGUID = @CompanyGUID,
		@UserName = @UserName,
		@UserID = @UserID,
		@LangID = @LangID
		print 6
  end
	

 if(@SIVXML is not null and @SIVXML<>'')
  begin
		select @RcptCCID=CONVERT(int,Value) from COM_CostCenterPreferences WITH(nolock)
		where CostCenterID=95 and Name='ContractSalesInvoice'
  
		 EXEC	@return_value = [dbo].[spDOC_SetInvDocument]
				@CostCenterID = @RcptCCID,
				@DocID = 0,
				@DocPrefix = N'',
				@DocNumber = N'',
				@DocDate = @date,
				@DueDate = NULL,
				@BillNo = @wono,
				@InvDocXML =@SIVXML,
				@BillWiseXML = N'',
				@NotesXML = N'',
				@AttachmentsXML = N'',
				@IsImport = 0,
				@LocationID = @LocationID,
				@DivisionID = @DivisionID ,
				@WID = 0,
				@RoleID = @RoleID,
				@DocAddress = N'',
				@CompanyGUID = @CompanyGUID,
				@UserName = @UserName,
				@UserID = @UserID,
				@LangID = @LangID 
 
	END 


    IF(@RentRcptXML is not null and @RentRcptXML<>'')
	begin
  
		select @RcptCCID=CONVERT(int,Value) from COM_CostCenterPreferences WITH(nolock)
		where CostCenterID=95 and Name='ContractRentReceipt'
	
		DECLARE @XML XML ,@CNT INT
	 
			SET @XML =   @RentRcptXML 
			 

	CREATE TABLE #tblList(ID int identity(1,1),TRANSXML NVARCHAR(MAX))    
	INSERT INTO #tblList  
	SELECT  CONVERT(NVARCHAR(MAX),  X.query('/SIV/DocumentXML') )
	from @XML.nodes('/SIV/DocumentXML') as Data(X)  

	
	SELECT @CNT = COUNT(ID) FROM #tblList

	DECLARE @ICNT INT
	SET @ICNT = 0
	WHILE(@ICNT < @CNT)
	BEGIN
	SET @ICNT =@ICNT+1
	DECLARE @AA XML 
	SELECT @AA = TRANSXML  FROM #tblList WHERE  ID = @ICNT
	
	DECLARE @DocXml nvarchar(max) 
	Set @DocXml = convert(nvarchar(max), @AA)
	EXEC	@return_value = [dbo].[spDOC_SetAccountDocument]
		@CostCenterID = @RcptCCID,
		@DocID = 0,
		@DocPrefix = N'',
		@DocNumber =1,
		@DocDate = @date,
		@DueDate = NULL,
		@BillNo = @wono,
		@InvDocXML = @DocXml,
		@NotesXML = N'',
		@AttachmentsXML = N'',
		@IsImport = 0,
		@LocationID = @LocationID,
		@DivisionID = @DivisionID,
		@WID = 0,
		@RoleID = @RoleID,
		@CompanyGUID = @CompanyGUID,
		@UserName = @UserName,
		@UserID = @UserID,
		@LangID = @LangID
  end
END  
	
 
  
COMMIT TRANSACTION
SET NOCOUNT OFF;    
RETURN 1  
END TRY    
BEGIN CATCH    
 --Return exception info [Message,Number,ProcedureName,LineNumber]    
 IF ERROR_NUMBER()=50000  
 BEGIN  
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
  end 
 ROLLBACK TRANSACTION  
 SET NOCOUNT OFF    
 RETURN -999    

END CATCH  
  
  
  
GO

USE PACT2C222
GO
SET ANSI_NULLS, QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spREN_RefundContract]
	@ContractID [bigint],
	@RefundDate [datetime],
	@SRTXML [nvarchar](max) = NULL,
	@RentRecID [bigint] = 0,
	@LocationID [bigint] = 0,
	@divisionID [bigint] = 0,
	@RoleID [bigint] = 0,
	@CompanyGUID [nvarchar](50),
	@GUID [nvarchar](50),
	@UserName [nvarchar](50),
	@UserID [int] = 0,
	@LangID [int] = 1
WITH ENCRYPTION, EXECUTE AS CALLER
AS
BEGIN TRANSACTION    
DECLARE @QUERYTEST NVARCHAR(100)  , @IROWNO NVARCHAR(100) , @TYPE NVARCHAR(100)  
BEGIN TRY      
SET NOCOUNT ON;   
  
	DECLARE @Dt float,@XML xml,@return_value int,@SNO int,@RcptCCID BIGint,@tempAmt float
	DECLARE  @CNT INT ,  @ICNT INT,@AA XML,@DocXml nvarchar(max) ,@BillWiseXMl nvarchar(max) 
	SET @Dt=convert(float,getdate())--Setting Current Date   

	UPDATE REN_CONTRACT
	SET STATUSID = 450 ,RefundDate = CONVERT(FLOAT , @RefundDate)
	WHERE ContractID = @ContractID or RefContractID=@ContractID   
    
	select @SNO=ISNULL(max(SNO),0)  from [REN_Contract] with(NOLOCK) WHERE   CONTRACTID = @ContractID
	   
 	
	if(@SRTXML is not null and @SRTXML<>'')
	BEGIN
		select @RcptCCID=CONVERT(int,Value) from COM_CostCenterPreferences WITH(nolock)
		where CostCenterID=95 and Name='ContractSalesReturn'

		SET @XML = @SRTXML
		declare  @tblListSIVTemp TABLE(ID int identity(1,1),TRANSXML NVARCHAR(MAX) ,Documents NVARCHAR(200))        
		INSERT INTO @tblListSIVTemp    
		SELECT  CONVERT(NVARCHAR(MAX),  X.query('DocumentXML'))   ,  CONVERT(NVARCHAR(200),X.query('Documents'))                 
		from @XML.nodes('/SIV//ROWS') as Data(X)    

		SELECT @CNT = COUNT(ID) FROM @tblListSIVTemp  

		SET @ICNT = 0  
		WHILE(@ICNT < @CNT)  
		BEGIN  
			SET @ICNT =@ICNT+1  

			SELECT @AA = TRANSXML    FROM @tblListSIVTemp WHERE  ID = @ICNT  

			Set @DocXml = convert(nvarchar(max), @AA)  

			if exists(SELECT IsBillwise FROM ACC_Accounts WHERE AccountID=@RentRecID and IsBillwise=1)
			begin
				IF EXISTS(select Value from ADM_GLOBALPREFERENCES where NAME  = 'On')
				BEGIN
					set @XML=@DocXml
					select top 1 @tempAmt=X.value('@Gross',' float')  
					from @XML.nodes('/DocumentXML/Row/Transactions') as Data(X)        
					set @BillWiseXMl='<BillWise> <Row DocSeqNo="1" AccountID="'+convert(nvarchar,@RentRecID)+'" AmountFC="-'+CONVERT(nvarchar,@tempAmt)+'" AdjAmount="-'+CONVERT(nvarchar,@tempAmt)+'" AdjCurrID="1" AdjExchRT="1" IsNewReference="1" Narration="" IsDocPDC="0" ></Row></BillWise>'
				END
				ELSE
				BEGIN
					set @BillWiseXMl=''
				END
			end
			else
			begin
				set @BillWiseXMl=''
			end

				set @DocXml=Replace(@DocXml,'<RowHead/>','')
				set @DocXml=Replace(@DocXml,'</DocumentXML>','')
				set @DocXml=Replace(@DocXml,'<DocumentXML>','')

			EXEC	@return_value = [dbo].[spDOC_SetTempInvDoc]
			@CostCenterID = @RcptCCID,
			@DocID = 0,
			@DocPrefix = N'',
			@DocNumber = N'',
			@DocDate = @RefundDate,
			@DueDate = NULL,
			@BillNo = @SNO,
			@InvDocXML =@DocXml,
			@BillWiseXML = @BillWiseXMl,
			@NotesXML = N'',
			@AttachmentsXML = N'',
			@ActivityXML  = N'', 
			@IsImport = 0,
			@LocationID = @LocationID,
			@DivisionID = @DivisionID ,
			@WID = 0,
			@RoleID = @RoleID,
			@DocAddress = N'',
			@RefCCID = 95,
			@RefNodeid  = @ContractID,
			@CompanyGUID = @CompanyGUID,
			@UserName = @UserName,
			@UserID = @UserID,
			@LangID = @LangID 
			
			INSERT INTO  [REN_ContractDocMapping]  
			([ContractID],[Type],[Sno],DocID,COSTCENTERID,IsAccDoc,DocType,ContractCCID)  			        
			values(@ContractID,101,@SNO+@ICNT,@return_value,@RcptCCID,0,0,95)

		END
	END 

 	
COMMIT TRANSACTION     
   
 SELECT ErrorMessage,ErrorNumber FROM COM_ErrorMessages WITH(nolock)   
WHERE ErrorNumber=100 AND LanguageID=@LangID  
SET NOCOUNT OFF;   
   
RETURN @ContractID      
END TRY      
BEGIN CATCH 
 if(@return_value is null or  @return_value<>-999)   
 BEGIN        
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
 END   
 ROLLBACK TRANSACTION    
 END
 SET NOCOUNT OFF      
 RETURN -999       
  
  
END CATCH 

GO

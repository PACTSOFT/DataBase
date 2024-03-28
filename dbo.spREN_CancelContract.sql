﻿USE PACT2C222
GO
SET ANSI_NULLS, QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spREN_CancelContract]
	@ContractID [bigint],
	@SCostCenterID [bigint],
	@CompanyGUID [nvarchar](50),
	@UserName [nvarchar](50),
	@UserID [int] = 0,
	@RoleID [int] = 0,
	@LangID [int] = 1
WITH ENCRYPTION, EXECUTE AS CALLER
AS
BEGIN TRANSACTION      
BEGIN TRY        
SET NOCOUNT ON;     
    
	DECLARE @Dt float,@XML xml,@CNT bigint,@I BIGINT,@return_value int,@AUDITSTATUS NVARCHAR(50),@CancelDOCID bigint
	DECLARE     @DELETEDOCID BIGINT , @DELETECCID BIGINT , @DELETEISACC BIT,@AuditTrial BIT,@IsAccDoc BIT
	DECLARE @DELDocPrefix NVARCHAR(50), @DELDocNumber NVARCHAR(500),@CostCenterID int,@stat int
	SET @Dt=convert(float,getdate())

	SET @AUDITSTATUS= 'CancelContract'  
	
	SElect @stat=STATUSID from REN_CONTRACT  WITH(NOLOCK)	
	WHERE ContractID = @ContractID
	
	if(@stat in(428,465))
	BEGIN
		Exec @return_value =[dbo].[spREN_CancelTermination]    
			@ContractID=@ContractID,      
			@SCostCenterID=@SCostCenterID,  
			@CompanyGUID=@CompanyGUID,      
			@UserName=@UserName,    
			@UserID =@UserID,      
			@LangID =@LangID   
			
	END
	
	
	UPDATE REN_CONTRACT  
	SET STATUSID = 451 
	WHERE ContractID = @ContractID  or RefContractID = @ContractID 
	
--------------------------Cancel  POSTINGS --------------------------  
      
IF( @SCostCenterID  = 95)  
BEGIN    
      
    DECLARE  @tblXML TABLE(ID int identity(1,1),DOCID bigint,COSTCENTERID int,IsAccDoc bit)
	INSERT INTO @tblXML       
    select DocID,COSTCENTERID,IsAccDoc from [REN_ContractDocMapping]  with(nolock)
    where  [ContractID]=@ContractID and [Type]>0 and ContractCCID=95
	
	set @I=0
	select @CNT=max(ID) from @tblXML
	WHILE(@I <  @CNT)      
	BEGIN                
		SET @I = @I+1  
		SELECT @DELETEDOCID = DOCID,@IsAccDoc=IsAccDoc FROM @tblXML WHERE ID = @I      
        
        if(@IsAccDoc=1) 
        BEGIN
			SELECT @DELDocPrefix = DocPrefix,@CancelDOCID=DocID, @DELDocNumber=  DocNumber , @DELETECCID = COSTCENTERID FROM dbo.ACC_DocDetails with(nolock)
			WHERE DOCID = @DELETEDOCID      
			IF @DELDocNumber IS NOT NULL
			BEGIN
			
			 EXEC @return_value = [dbo].[spDOC_SuspendAccDocument]  
			 @CostCenterID = @DELETECCID, 
			 @DocID=@CancelDOCID,
			 @DocPrefix = @DELDocPrefix,  
			 @DocNumber = @DELDocNumber, 
			 @Remarks=N'', 
			 @UserID = @UserID,  
			 @UserName = @UserName,
			 @RoleID=@RoleID,
			 @LangID = @LangID  
			  
			END
		END	
		ELSE
		BEGIN
			SELECT @DELDocPrefix = DocPrefix,@CancelDOCID=DocID, @DELDocNumber=  DocNumber , @DELETECCID = COSTCENTERID FROM dbo.INV_DocDetails with(nolock)      
			WHERE DOCID = @DELETEDOCID      
			IF @DELDocNumber IS NOT NULL
			BEGIN
				EXEC @return_value = spDOC_SuspendInvDocument        
				 @CostCenterID = @DELETECCID, 
				 @DocID=@CancelDOCID,
				 @DocPrefix = @DELDocPrefix,  
				 @DocNumber = @DELDocNumber, 
				 @Remarks=N'', 
				 @UserID = @UserID,  
				 @UserName = @UserName, 
				 @RoleID=@RoleID, 
				 @LangID = @LangID  
			END
		END       
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

USE PACT2C222
GO
SET ANSI_NULLS, QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spREN_ApproveContractDocs]
	@COSTCENTERID [int],
	@ContractID [bigint] = 0,
	@IsApprove [bit],
	@RejRemarks [nvarchar](500) = '',
	@CompanyGUID [nvarchar](500),
	@RoleID [bigint] = 1,
	@UserID [bigint] = 1,
	@UserName [nvarchar](500),
	@LangID [int] = 1
WITH ENCRYPTION, EXECUTE AS CALLER
AS
BEGIN TRANSACTION      
BEGIN TRY        
SET NOCOUNT ON;        
      
 DECLARE @TBLCNT INT  , @INCCNT INT ,@TOTCNT INT ,@DocType int,@stat int,@Contractstat int,@type int  
 DECLARE @DELDocPrefix NVARCHAR(50), @DELDocNumber NVARCHAR(500) ,@level int,@maxLevel int,@WID int,@renref bigint     
 DECLARE @return_value int  , @DocID BIGINT , @CCID BIGINT , @IsAccDoc BIT   
   
 DECLARE  @tblListDEL TABLE(ID int identity(1,1),ContractID BIGINT , DocID BIGINT, COSTCENTERID BIGINT ,IsAccDoc BIT,stat int)          
	
	if(@COSTCENTERID=103 or @COSTCENTERID=129)
	BEGIN
		select @Contractstat=StatusID,@WID=workflowid from REN_Quotation WITH(NOLOCK) where QuotationID=@ContractID
		
		if(@WID>0)
		begin
				set @level=(SELECT  top 1  LevelID FROM [COM_WorkFlow]   WITH(NOLOCK) 
				where WorkFlowID=@WID and  UserID =@UserID)

				if(@level is null )
					set @level=(SELECT top 1 LevelID FROM [COM_WorkFlow]  WITH(NOLOCK)  
					where WorkFlowID=@WID and  RoleID =@RoleID)

				if(@level is null ) 
					set @level=(SELECT top 1  LevelID FROM [COM_WorkFlow]   WITH(NOLOCK) 
					where WorkFlowID=@WID and  GroupID in (select GroupID from COM_Groups WITH(NOLOCK) where UserID=@UserID))

				if(@level is null )
					set @level=( SELECT top 1  LevelID FROM [COM_WorkFlow] WITH(NOLOCK) 
					where WorkFlowID=@WID and  GroupID in (select GroupID from COM_Groups WITH(NOLOCK) 
					where RoleID =@RoleID))

				select @maxLevel=max(LevelID) from COM_WorkFlow WITH(NOLOCK)  where WorkFlowID=@WID  
				
				if(@IsApprove=0)
					set @Contractstat=470
				else if(@level is not null and  @maxLevel is not null and @maxLevel>@level)
				begin							
					set @Contractstat=466
				END
				ELSE if(@COSTCENTERID=129)
					set @Contractstat=467	
				else
					set @Contractstat=426	
				
				update REN_Quotation
				set StatusID=@Contractstat,WorkFlowLevel=@level
				where QuotationID=@ContractID	
				
				update REN_Quotation
				set StatusID=@Contractstat,WorkFlowLevel=@level
				where RefQuotation=@ContractID		  
		END
			
		if(@Contractstat=466 and @COSTCENTERID=129)
		BEGIN
			INSERT INTO @tblListDEL        
			SELECT @ContractID,a.DOCID ,a.CostCenterID , 0,StatusID   FROM INV_DOCDETAILS a WITH(NOLOCK)
			join REN_CONTRACTDOCMAPPING b WITH(NOLOCK) on a.DocID=b.DocID 
			WHERE ContractCCID=129 and CONTRACTID = @ContractID  AND ISACCDOC = 0    and RefNodeID = @ContractID    

			INSERT INTO @tblListDEL   
			SELECT @ContractID,a.DOCID ,a.CostCenterID , 1,StatusID FROM ACC_DOCDETAILS a WITH(NOLOCK)
			join REN_CONTRACTDOCMAPPING b WITH(NOLOCK) on a.DocID=b.DocID 
			WHERE ContractCCID=129 and CONTRACTID = @ContractID AND ISACCDOC = 1  and RefNodeID = @ContractID    
		END	
			
	END	
	else
	BEGIN
		select @Contractstat=StatusID,@renref=RenewRefID,@WID=workflowid from REN_Contract WITH(NOLOCK) where ContractID=@ContractID
	
		if(@Contractstat=465)
		BEGIN
			INSERT INTO @tblListDEL        
			SELECT @ContractID,a.DOCID ,a.CostCenterID , 0,StatusID   FROM INV_DOCDETAILS a WITH(NOLOCK)
			join REN_CONTRACTDOCMAPPING b WITH(NOLOCK) on a.DocID=b.DocID 
			WHERE CONTRACTID = @ContractID  AND ISACCDOC = 0  and RefNodeID = @ContractID and b.Type<0   

			INSERT INTO @tblListDEL   
			SELECT @ContractID,a.DOCID ,a.CostCenterID , 1,StatusID FROM ACC_DOCDETAILS a WITH(NOLOCK)
			join REN_CONTRACTDOCMAPPING b WITH(NOLOCK) on a.DocID=b.DocID 
			WHERE CONTRACTID = @ContractID AND ISACCDOC = 1  and RefNodeID = @ContractID  and b.Type<0
			
			update REN_Contract  
			set StatusID=428
			where ContractID=@ContractID		  
		END
		ELSE
		BEGIN
			
			if(@WID>0)
			begin
				set @level=(SELECT  top 1  LevelID FROM [COM_WorkFlow]   WITH(NOLOCK) 
				where WorkFlowID=@WID and  UserID =@UserID)

				if(@level is null )
					set @level=(SELECT top 1 LevelID FROM [COM_WorkFlow]  WITH(NOLOCK)  
					where WorkFlowID=@WID and  RoleID =@RoleID)

				if(@level is null ) 
					set @level=(SELECT top 1  LevelID FROM [COM_WorkFlow]   WITH(NOLOCK) 
					where WorkFlowID=@WID and  GroupID in (select GroupID from COM_Groups WITH(NOLOCK) where UserID=@UserID))

				if(@level is null )
					set @level=( SELECT top 1  LevelID FROM [COM_WorkFlow] WITH(NOLOCK) 
					where WorkFlowID=@WID and  GroupID in (select GroupID from COM_Groups WITH(NOLOCK) 
					where RoleID =@RoleID))

				select @maxLevel=max(LevelID) from COM_WorkFlow WITH(NOLOCK)  where WorkFlowID=@WID  
				
				if(@IsApprove=0)
					set @Contractstat=470
				else if(@level is not null and  @maxLevel is not null and @maxLevel>@level)
				begin							
					set @Contractstat=466
				END
				ELSE
				BEGIN
					if(@renref is not null and @renref>0)
						set @Contractstat=427
					else
						set @Contractstat=426	
				END
				
				update REN_Contract  
				set StatusID=@Contractstat,WorkFlowLevel=@level
				where ContractID=@ContractID		  
				
			END
			
			if(@Contractstat in(426,427))
			BEGIN
				INSERT INTO @tblListDEL        
				SELECT @ContractID,a.DOCID ,a.CostCenterID , 0,StatusID   FROM INV_DOCDETAILS a WITH(NOLOCK)
				join REN_CONTRACTDOCMAPPING b WITH(NOLOCK) on a.DocID=b.DocID 
				WHERE ContractCCID=@COSTCENTERID and  CONTRACTID = @ContractID  AND ISACCDOC = 0    and RefNodeID = @ContractID    

				INSERT INTO @tblListDEL   
				SELECT @ContractID,a.DOCID ,a.CostCenterID , 1,StatusID FROM ACC_DOCDETAILS a WITH(NOLOCK)
				join REN_CONTRACTDOCMAPPING b WITH(NOLOCK) on a.DocID=b.DocID 
				WHERE ContractCCID=@COSTCENTERID and CONTRACTID = @ContractID AND ISACCDOC = 1  and RefNodeID = @ContractID    
			END	
		END
	END
	
	if(@WID>0)
	begin		
		INSERT INTO COM_Approvals(CCID,CCNODEID,StatusID,Date,Remarks,UserID   
			  ,CompanyGUID,GUID,CreatedBy,CreatedDate,WorkFlowLevel,DocDetID)      
			VALUES(@COSTCENTERID,@ContractID,@Contractstat,CONVERT(FLOAT,getdate()),@RejRemarks,@UserID
			  ,@CompanyGUID,newid(),@UserName,CONVERT(FLOAT,getdate()),isnull(@level,0),0)
	END
	
SET @INCCNT = 1   
  
SELECT @TOTCNT = COUNT(*) FROM @tblListDEL   
   
WHILE (@INCCNT <= @TOTCNT)  
BEGIN  
	SELECT    @DocID= DocID  , @CCID = COSTCENTERID , @IsAccDoc = IsAccDoc,@stat=stat   FROM @tblListDEL WHERE ID  = @INCCNT  

	IF( @IsAccDoc  = 1)  
	BEGIN  
		select @DocType=DocumentType from ADM_DocumentTypes where CostCenterID=@CCID 
		if (@DocType in(14,19))
		BEGIN
			select @type=Type from REN_ContractDocMapping with(nolock) where contractid=@ContractID and IsAccDoc=1 and DocID=@DocID
			if(@stat in(371,372,441))
			BEGIN
				if(@Contractstat=465 and @type<>-4)--Terminated 
					UPDATE ACC_DocDetails  
					SET StatusID =   452
					WHERE DocID = @DocID AND COSTCENTERID = @CCID AND REFCCID = @COSTCENTERID AND REFNODEID  = @ContractID  
				ELSE	
					UPDATE ACC_DocDetails  
					SET StatusID =   370-- PDC      441 -- APPROVED      
					WHERE DocID = @DocID AND COSTCENTERID = @CCID AND REFCCID = @COSTCENTERID AND REFNODEID  = @ContractID  
			END	
		END
		ELSE
		BEGIN		
			UPDATE ACC_DocDetails  
			SET StatusID =   369-- POSTED      441 -- APPROVED      
			WHERE DocID = @DocID AND COSTCENTERID = @CCID AND REFCCID = @COSTCENTERID AND REFNODEID  = @ContractID   
		END	
	END  
	ELSE  
	BEGIN  
		UPDATE INV_DocDetails  
		SET StatusID =  369 --POSTED 441 -- APPROVED       
		WHERE DocID = @DocID AND COSTCENTERID = @CCID AND REFCCID = @COSTCENTERID AND REFNODEID  = @ContractID  
		
		UPDATE ACC_DocDetails  
		SET StatusID =   369-- POSTED      441 -- APPROVED 
		from INV_DocDetails a     
		WHERE a.DocID = @DocID AND a.COSTCENTERID = @CCID AND a.REFCCID = @COSTCENTERID AND a.REFNODEID  = @ContractID   
		and ACC_DocDetails.InvDocdetailsID=a.InvDocdetailsID
 
	END  
	SET @INCCNT = @INCCNT +  1  
       
     --SELECT  StatusID FROM INV_DOCDETAILS WHERE DocID = @DocID  AND REFCCID = 95 AND REFNODEID  = @ContractID   
END  
   
     
COMMIT TRANSACTION      
SET NOCOUNT OFF;        
SELECT ErrorMessage,ErrorNumber FROM COM_ErrorMessages WITH(nolock)       
WHERE ErrorNumber=100 AND LanguageID=@LangID      
      
RETURN 1      
END TRY      
BEGIN CATCH        
 --Return exception info [Message,Number,ProcedureName,LineNumber]        
 IF ERROR_NUMBER()=50000      
 BEGIN      
  SELECT ErrorMessage,ErrorNumber FROM COM_ErrorMessages WITH(nolock) WHERE ErrorNumber=ERROR_MESSAGE() AND LanguageID=@LangID      
 END      
 ELSE IF ERROR_NUMBER()=547      
 BEGIN      
  SELECT ErrorMessage, ERROR_MESSAGE() AS ServerMessage,ERROR_NUMBER() as ErrorNumber, ERROR_PROCEDURE()as ProcedureName, ERROR_LINE() AS ErrorLine FROM COM_ErrorMessages WITH(nolock)      
  WHERE ErrorNumber=-110 AND LanguageID=@LangID      
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

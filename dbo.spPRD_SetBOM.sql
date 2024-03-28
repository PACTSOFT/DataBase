USE PACT2C222
GO
SET ANSI_NULLS, QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spPRD_SetBOM]
	@BOMID [bigint] = 0,
	@BOMCode [nvarchar](200),
	@BOMName [nvarchar](500),
	@ProductID [bigint] = 0,
	@UOMID [int],
	@FPQty [float] = 1,
	@LocationID [bigint] = 0,
	@DivisionID [bigint] = 0,
	@Description [nvarchar](500) = NULL,
	@StatusID [int],
	@BOMTypeID [int] = 1,
	@BOMTypeName [nvarchar](50) = NULL,
	@IsGroup [bit],
	@SelectedNodeID [int],
	@Date [datetime],
	@BOMProductXML [nvarchar](max) = NULL,
	@BOMExpenseXML [nvarchar](max) = NULL,
	@BOMResourceXML [nvarchar](max) = NULL,
	@CustomFieldsQuery [nvarchar](max) = null,
	@CustomCostCenterFieldsQuery [nvarchar](max) = null,
	@ProductionMethodXML [nvarchar](max) = null,
	@CompanyGUID [nvarchar](50),
	@GUID [varchar](50),
	@UserName [nvarchar](50),
	@WID [int] = 0,
	@RoleID [int] = 0,
	@UserID [int] = 0,
	@LangId [int] = 1
WITH ENCRYPTION, EXECUTE AS CALLER
AS
SET NOCOUNT ON     
 BEGIN TRANSACTION    
 BEGIN TRY    
      
      
    DECLARE @Dt FLOAT, @lft bigint,@rgt bigint,@TempGuid nvarchar(50),@Selectedlft bigint,@Selectedrgt bigint,@HasAccess bit,@IsDuplicateNameAllowed bit,@IsBOMCodeAutoGen bit  ,@IsIgnoreSpace bit  ,    
 @Depth int,@ParentID bigint,@SelectedIsGroup int , @XML XML,@ParentCode nvarchar(200),@UpdateSql nvarchar(max)  ,@ProductionXML XML  ,@BOMCCID bigint,@HistoryStatus NVARCHAR(50)
    
    SET @HasAccess=dbo.fnCOM_HasAccess(@RoleID,76,133)
    if(@HasAccess=1)
		set @StatusID=464
       
  --FOR BOMNAME Duplicate Check    
    
  --GETTING PREFERENCE      
  SELECT @IsDuplicateNameAllowed=Value FROM COM_CostCenterPreferences WITH(nolock) WHERE COSTCENTERID=76 and  Name='DuplicateNameAllowed'      
  SELECT @IsBOMCodeAutoGen=Value FROM COM_CostCenterPreferences  WITH(nolock) WHERE COSTCENTERID=76 and  Name='CodeAutoGen'      
  SELECT @IsIgnoreSpace=Value FROM COM_CostCenterPreferences  WITH(nolock) WHERE COSTCENTERID=76 and  Name='IgnoreSpaces'      
  
  --DUPLICATE CHECK      
  IF @IsDuplicateNameAllowed IS NOT NULL AND @IsDuplicateNameAllowed=0      
  BEGIN      
    IF @IsIgnoreSpace IS NOT NULL AND @IsIgnoreSpace=1      
   BEGIN      
    IF @BOMID=0      
    BEGIN      
     IF EXISTS (SELECT BOMID FROM PRD_BillOfMaterial WITH(nolock) WHERE replace(BOMName,' ','')=replace(@BOMName,' ',''))      
     BEGIN      
      RAISERROR('-112',16,1)      
     END      
    END      
    ELSE      
    BEGIN      
     IF EXISTS (SELECT BOMID FROM PRD_BillOfMaterial WITH(nolock) WHERE replace(BOMName,' ','')=replace(@BOMName,' ','') AND BOMID <> @BOMID)      
     BEGIN      
      RAISERROR('-112',16,1)           
     END      
    END      
   END      
   ELSE      
   BEGIN      
    IF @BOMID=0      
    BEGIN      
     IF EXISTS (SELECT BOMID FROM PRD_BillOfMaterial WITH(nolock) WHERE BOMName=@BOMName)      
     BEGIN      
      RAISERROR('-112',16,1)      
     END      
    END      
    ELSE      
    BEGIN      
     IF EXISTS (SELECT BOMID FROM PRD_BillOfMaterial WITH(nolock) WHERE BOMName=@BOMName AND BOMID <> @BOMID)      
     BEGIN      
      RAISERROR('-112',16,1)      
     END      
    END      
   END    
  END    
 --IF( @BOMID = 0 )    
 --BEGIN    
 -- IF EXISTS (SELECT BOMID FROM PRD_BillOfMaterial WITH(nolock) WHERE replace(BOMName,' ','')=replace(@BOMName,' ',''))      
 --  BEGIN      
 --   RAISERROR('-112',16,1)      
 --  END      
 --END     
       
  SET @Dt=convert(float,getdate())--Setting Current Date      
         
  IF @BOMID = 0--------START INSERT RECORD-----------      
  BEGIN
	set @HistoryStatus='Add'
	
	--CREATE BOM--      
     --To Set Left,Right And Depth of Record      
    SELECT @SelectedIsGroup=IsGroup,@Selectedlft =lft,@Selectedrgt=rgt,@ParentID=ParentID,@Depth=Depth      
    from PRD_BillOfMaterial with(NOLOCK) where BOMID=@SelectedNodeID      
          
    --IF No Record Selected or Record Doesn't Exist      
    if(@SelectedIsGroup is null)       
     select @SelectedNodeID=BOMId,@SelectedIsGroup=IsGroup,@Selectedlft =lft,@Selectedrgt=rgt,@ParentID=ParentID,@Depth=Depth      
     from [PRD_BillOfMaterial] with(NOLOCK) where ParentID =0      
                
    if(@SelectedIsGroup = 1)--Adding Node Under the Group      
     BEGIN      
      UPDATE [PRD_BillOfMaterial] SET rgt = rgt + 2 WHERE rgt > @Selectedlft;      
      UPDATE [PRD_BillOfMaterial] SET lft = lft + 2 WHERE lft > @Selectedlft;      
      set @lft =  @Selectedlft + 1      
      set @rgt = @Selectedlft + 2      
      set @ParentID = @SelectedNodeID      
      set @Depth = @Depth + 1      
     END      
    else if(@SelectedIsGroup = 0)--Adding Node at Same level      
     BEGIN      
      UPDATE [PRD_BillOfMaterial] SET rgt = rgt + 2 WHERE rgt > @Selectedrgt;      
      UPDATE [PRD_BillOfMaterial] SET lft = lft + 2 WHERE lft > @Selectedrgt;      
      set @lft =  @Selectedrgt + 1      
      set @rgt = @Selectedrgt + 2       
     END      
    else  --Adding Root      
     BEGIN      
      set @lft =  1      
      set @rgt = 2       
      set @Depth = 0      
      set @ParentID =0      
      set @IsGroup=1      
     END     
     
 --GENERATE CODE      
    IF @IsBOMCodeAutoGen IS NOT NULL AND @IsBOMCodeAutoGen=1 AND @BOMID=0      
    BEGIN     
     SELECT @ParentCode=[BOMCode]      
     FROM [PRD_BillOfMaterial] WITH(NOLOCK) WHERE BOMID=@ParentID        
      
     --CALL AUTOCODEGEN      
     EXEC [spCOM_SetCode] 76,@ParentCode,@BOMCode OUTPUT        
    END      
     INSERT INTO PRD_BillOfMaterial    
      (BOMCode,BOMDate    
      ,BOMName    
      ,StatusId    
      ,BOMTypeID    
      ,BOMTypeName    
      ,ProductID,UOMID,FPQty
      ,DivisionID    
      ,LocationID    
      ,Description    
      ,Depth    
      ,ParentID    
      ,lft    
      ,rgt    
      ,IsGroup    
      ,CompanyGUID    
      ,GUID    
      ,CreatedBy    
      ,CreatedDate,ModifiedDate)    
    Values     
      (@BOMCode,CONVERT(float,@Date )  
      ,@BOMName    
      ,@StatusID    
      ,@BOMTypeID    
      ,@BOMTypeName    
      ,@ProductID,@UOMID,@FPQty
      ,@LocationID    
      ,@DivisionID    
      ,@Description    
      ,@Depth    
      ,@ParentID    
      ,@lft    
      ,@rgt    
      ,@IsGroup    
      ,@CompanyGUID    
      ,newid()    
      ,@UserName    
      ,@Dt,@Dt)    
         
     SET @BOMID=SCOPE_IDENTITY()     
    
 --Handling of Extended Table      
    INSERT INTO [PRD_BillOfMaterialExtended]([BOMID],[CreatedBy],[CreatedDate])      
    VALUES(@BOMID, @UserName, @Dt)     
      
     INSERT INTO COM_CCCCDATA ([CostCenterID] ,[NodeID] ,[Guid],[CreatedBy],[CreatedDate])  
     VALUES(76,@BOMID,newid(),  @UserName, @Dt)    
  
        
  END --------END INSERT RECORD-----------      
 ELSE  --------START UPDATE RECORD-----------      
  BEGIN
	
	set @HistoryStatus='Update'
	
    SELECT @TempGuid=[GUID] from PRD_BillOfMaterial  WITH(NOLOCK)       
      WHERE BOMID=@BOMID     
         
      IF(@TempGuid!=@Guid)--IF RECORD ALREADY UPDATED BY SOME OTHER USER i.e DIRTY READ        
      BEGIN        
       RAISERROR('-101',16,1)       
      END        
      ELSE        
       BEGIN      
           UPDATE [PRD_BillOfMaterial]    
   SET [BOMCode]=@BOMCode    
   ,[BOMName]= @BOMName    
   ,[StatusID] = @StatusID    
   ,[BOMTypeID] = @BOMTypeID    
   ,[BOMTypeName] = @BOMTypeName    
   ,[ProductID]=@ProductID
   ,UOMID=@UOMID
   ,FPQty=@FPQty
   ,[LocationID]=@LocationID    
   ,[DivisionID]=@DivisionID    
   ,[Description] = @Description   
   ,BOMDate=CONVERT(float,@Date )   
   ,[GUID] = @Guid    
   ,[ModifiedBy] = @UserName    
   ,[ModifiedDate] = @Dt    
      WHERE BOMID = @BOMID    
       END    
     
  END   
  
	--CHECK WORKFLOW
	EXEC spCOM_CheckCostCentetWF 76,@BOMID,@WID,@RoleID,@UserID,@UserName,@StatusID output
      
  --Update Extra fields      
  set @UpdateSql='update [PRD_BillOfMaterialExtended]      
  SET '+@CustomFieldsQuery+'[ModifiedBy] ='''+ @UserName      
    +''',[ModifiedDate] =@Dt WHERE BOMID='+convert(nvarchar,@BOMID)      
    EXEC sp_executesql @UpdateSql,N'@Dt float',@Dt
    
   set @UpdateSql='update COM_CCCCDATA    
 SET '+@CustomCostCenterFieldsQuery+'[ModifiedBy] ='''+ @UserName+''',[ModifiedDate] =@Dt WHERE NodeID = '+convert(nvarchar,@BOMID) + ' AND CostCenterID = 76 '   
 EXEC sp_executesql @UpdateSql,N'@Dt float',@Dt
    
    
   SET @XML=@BOMProductXML    
 DELETE FROM PRD_BOMProducts WHERE  [BOMID] =@BOMID 
        
 IF (@BOMProductXML IS NOT NULL AND @BOMProductXML <> '')      
   BEGIN      
    --INSERT RECORD INTO BOM PRODUCTS    
    INSERT INTO  [PRD_BOMProducts]    
       ([BOMID]    
       ,[ProductUse]    
       ,[ProductID]   ,FilterOn 
       ,[Quantity]    
       ,[UOMID]    
       ,[UnitPrice]    
       ,[ExchgRT]    
       ,[CurrencyID]    
       ,[Value]    
       ,[Wastage]    
       ,[CreatedBy]    
       ,[CreatedDate]    
       )    
    SELECT @BOMID , X.value('@ProductUse','int'),X.value('@ProductID','BIGINT'),X.value('@FilterOn','BIGINT'),       
    X.value('@Quantity','float'),X.value('@UOMID','bigint'),X.value('@UnitPrice','float'),      
    X.value('@ExchgRT','float'),X.value('@CurrencyID','bigint'),X.value('@Value','float'),X.value('@Wastage','float'),    
    @UserName,@Dt      
   FROM @XML.nodes('/BOMProductXML/Row') as Data(X)     
   END    

    SET @XML=@BOMExpenseXML    
       
    DELETE FROM [PRD_Expenses] WHERE [BOMID] =@BOMID
  IF (@BOMExpenseXML IS NOT NULL AND @BOMExpenseXML <> '')      
    BEGIN      
    INSERT INTO [PRD_Expenses]    
       ([BOMID]    
       ,[ResourceID],Name  
       ,[CreditAccountID],[DebitAccountID]    
       ,[ExchgRT]    
       ,[CurrencyID]    
       ,[Value]    
       ,[CreatedBy]    
       ,[CreatedDate])    
   SELECT @BOMID ,  X.value('@ResourceID','bigint'),X.value('@Name','NVARCHAR(500)') ,X.value('@CreditAccountID','BIGINT'),X.value('@DebitAccountID','BIGINT'),            
   X.value('@ExchgRT','float'),X.value('@CurrencyID','bigint'),X.value('@Value','float'),    
   @UserName,@Dt      
   FROM @XML.nodes('/BOMExpenseXML/Row') as Data(X)     
    END     
        
    SET @XML=@BOMResourceXML  
    DELETE FROM [PRD_BOMResources]  WHERE [BOMID]=@BOMID 
    
 IF (@BOMResourceXML IS NOT NULL AND @BOMResourceXML <> '')      
    BEGIN      
    INSERT INTO [PRD_BOMResources]    
       ([BOMID]    
       ,[ResourceID]    
       ,[Hours]    
       ,[ExchgRT]    
       ,[CurrencyID]    
       ,[Value]    
       ,[CreatedBy]    
       ,[CreatedDate],MachineDim1,MachineDim2)    
    SELECT @BOMID ,  X.value('@ResourceID','bigint') ,X.value('@Hours','float'),       
    X.value('@ExchgRT','float'),X.value('@CurrencyID','bigint'),X.value('@Value','float'),    
    @UserName,@Dt,X.value('@MachineDim1','bigint'), X.value('@MachineDim2','bigint')      
   FROM @XML.nodes('/BOMResourceXML/Row') as Data(X)     

    END     
     
  set @ProductionXML=@ProductionMethodXML   
 if(@ProductionMethodXML is not null and @ProductionMethodXML <> '')  
  begin  
    
  delete from PRD_ProductionMethod where BOMID=@BOMID and MOID is NULL  
    
  insert into PRD_ProductionMethod  ([SequenceNo],[BOMID]
           ,[MOID]
           ,[Particulars]
           ,[CompanyGUID]
           ,[GUID]
           ,[CreatedBy]
           ,[CreatedDate]
           ,[ModifiedBy]
           ,[ModifiedDate])
  select X.value('@SequenceNo','bigint'),@BOMID,NULL,X.value('@Particulars','nvarchar(200)'),@CompanyGUID    
      ,newid()    
      ,@UserName    
      ,@Dt
      ,@UserName    
      ,@Dt
       from @ProductionXML.nodes('/XML/Row') as data(X)  
    
  end  
     SELECT @BOMCCID=Convert(bigint,isnull(Value,0)) FROM COM_CostCenterPreferences WITH(nolock) WHERE COSTCENTERID=76 and  Name='BomDimension'      
  
	if(@BOMCCID>50000)
	begin
		declare @CCStatusID bigint
		set @CCStatusID = (select top 1 statusid from com_status WITH(nolock) where costcenterid=@BOMCCID)
		declare @NID bigint, @CCIDBom bigint
		select @NID = CCNodeID, @CCIDBom=CCID  from PRD_BillOfMaterial WITH(nolock) where BOMID=@BOMID
		iF(@CCIDBom<>@BOMCCID)
		BEGIN
			if(@NID>0)
			begin 
			Update PRD_BillOfMaterial set CCID=0, CCNodeID=0 where BOMID=@BOMID
			DECLARE @RET INT
				EXEC	@RET = [dbo].[spCOM_DeleteCostCenter]
					@CostCenterID = @CCIDBom,
					@NodeID = @NID,
					@RoleID=1,
					@UserID = @UserID,
					@LangID = @LangID
			end	
			set @NID=0
			set @CCIDBom=0 
		END
		    
		
		declare @return_value int
		if(@NID is null or @NID =0)
		begin 
			EXEC	@return_value = [dbo].[spCOM_SetCostCenter]
			@NodeID = 0,@SelectedNodeID = 1,@IsGroup = 0,
			@Code = @BOMCode,
			@Name = @BOMName,
			@AliasName='',
			@PurchaseAccount=0,@SalesAccount=0,@StatusID=@CCStatusID,
			@CustomFieldsQuery=NULL,@AddressXML='',@AttachmentsXML=NULL,
			@CustomCostCenterFieldsQuery=NULL,@ContactsXML=null,@NotesXML=NULL,
			@CostCenterID = @BOMCCID,@CompanyGUID=@COMPANYGUID,@GUID='',@UserName='admin',@RoleID=1,@UserID=1 , @CheckLink = 0
			
			 -- Link Dimension Mapping
			INSERT INTO COM_DocBridge (CostCenterID, NodeID,InvDocID, AccDocID, RefDimensionID  , RefDimensionNodeID ,  CompanyGUID, guid, Createdby, CreatedDate,Abbreviation)
			values(76, @BOMID,0,0,@BOMCCID,@return_value,'',newid(),@UserName, @dt,'BOM')

 		end
		else
		begin
			declare @Gid nvarchar(50) , @Table nvarchar(100), @CGid nvarchar(50)
			declare @NodeidXML nvarchar(max) 
			select @Table=Tablename from adm_features WITH(nolock) where featureid=@BOMCCID
			declare @str nvarchar(max) 
			set @str='@Gid nvarchar(50) output' 
			set @NodeidXML='set @Gid= (select GUID from '+convert(nvarchar,@Table)+' WITH(nolock) where NodeID='+convert(nvarchar,@NID)+')'
				exec sp_executesql @NodeidXML, @str, @Gid OUTPUT 
				
			--select	@Gid,@NID
			EXEC	@return_value = [dbo].[spCOM_SetCostCenter]
			@NodeID = @NID,@SelectedNodeID = 1,@IsGroup = 0,
			@Code = @BOMCode,
			@Name = @BOMName,
			@AliasName='',
			@PurchaseAccount=0,@SalesAccount=0,@StatusID=@CCStatusID,
			@CustomFieldsQuery=NULL,@AddressXML=null,@AttachmentsXML=NULL,
			@CustomCostCenterFieldsQuery=NULL,@ContactsXML=null,@NotesXML=NULL,
			@CostCenterID = @BOMCCID,@CompanyGUID=@CompanyGUID,@GUID=@Gid,@UserName='admin',@RoleID=1,@UserID=1, @CheckLink = 0	
 		end 
		
		Update PRD_BillOfMaterial set CCID=@BOMCCID, CCNodeID=@return_value where BOMID=@BOMID
		DECLARE @CCMapSql nvarchar(max)
		set @CCMapSql='update COM_CCCCDATA  
		SET CCNID'+convert(nvarchar,(@BOMCCID-50000))+'='+CONVERT(NVARCHAR,@return_value)+'  WHERE NodeID = '+convert(nvarchar,@BOMID) + ' AND CostCenterID = 76' 
		EXEC (@CCMapSql)
		

		Exec [spDOC_SetLinkDimension]
					@InvDocDetailsID=@BOMID, 
					@Costcenterid=76,         
					@DimCCID=@BOMCCID,
					@DimNodeID=@return_value,
					@UserID=@UserID,    
					@LangID=@LangID    
	end
	
	if exists(SELECT Value FROM COM_CostCenterPreferences WITH(NOLOCK) WHERE CostCenterID=76 and Name='AuditTrial' and Value='True')
	begin
		exec @return_value=spADM_AuditData 2,76,@BOMID,@HistoryStatus,'',1,1
		--if @return_value!=1
		--	set @ExtendedColsXML=' With Audit Trial Error'
	end
     
 COMMIT TRANSACTION    
 SELECT ErrorMessage,ErrorNumber FROM COM_ErrorMessages WITH(nolock)       
WHERE ErrorNumber=100 AND LanguageID=@LangID      
SET NOCOUNT OFF;        
RETURN @BOMID    
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
 END      
 ROLLBACK TRANSACTION      
 SET NOCOUNT OFF        
 RETURN -999         
END CATCH 
GO

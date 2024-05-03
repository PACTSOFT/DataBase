USE PACT2C222
GO
SET ANSI_NULLS, QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spREN_SetContract]
	@ContractID [bigint],
	@ContractPrefix [nvarchar](50),
	@ContractNumber [bigint],
	@ContractDate [datetime],
	@LinkedQuotationID [bigint],
	@StatusID [int] = 0,
	@SelectedNodeID [bigint],
	@IsGroup [bit] = 0,
	@PropertyID [bigint] = 0,
	@UnitID [bigint] = 0,
	@MultiUnitIds [nvarchar](max),
	@MultiUnitName [nvarchar](max) = NULL,
	@TenantID [bigint] = 0,
	@RentRecID [bigint] = 0,
	@IncomeID [bigint] = 0,
	@Purpose [nvarchar](500) = NULL,
	@StartDate [datetime],
	@EndDate [datetime],
	@TotalAmount [float],
	@NonRecurAmount [float],
	@RecurAmount [float],
	@ContractXML [nvarchar](max) = NULL,
	@PayTermsXML [nvarchar](max) = NULL,
	@RcptXML [nvarchar](max) = NULL,
	@PDRcptXML [nvarchar](max) = NULL,
	@ComRcptXML [nvarchar](max) = NULL,
	@SIVXML [nvarchar](max) = NULL,
	@RentRcptXML [nvarchar](max) = NULL,
	@WONO [nvarchar](500),
	@LocationID [bigint],
	@DivisionID [bigint],
	@RoleID [bigint],
	@ContractLocationID [bigint],
	@ContractDivisionID [bigint],
	@ContractCurrencyID [bigint],
	@CustomFieldsQuery [nvarchar](max) = null,
	@CustomCostCenterFieldsQuery [nvarchar](max) = null,
	@TermsConditions [nvarchar](500) = NULL,
	@SalesmanID [bigint],
	@AccountantID [bigint],
	@LandlordID [bigint],
	@Narration [nvarchar](500),
	@CostCenterID [int],
	@AttachmentsXML [nvarchar](max),
	@ActivityXML [nvarchar](max),
	@NotesXML [nvarchar](max),
	@ExtndTill [datetime],
	@basedon [nvarchar](50),
	@RenewRefID [bigint],
	@WID [int],
	@RecurDuration [int],
	@Refno [bigint],
	@parContractID [bigint],
	@IsExtended [bit],
	@CompanyGUID [nvarchar](50),
	@GUID [nvarchar](50),
	@UserName [nvarchar](50),
	@UserID [int] = 0,
	@LangID [int] = 1
WITH ENCRYPTION, EXECUTE AS CALLER
AS
BEGIN TRANSACTION          
DECLARE @QUERYTEST NVARCHAR(100)  , @IROWNO NVARCHAR(100) , @TYPE int,@fldsno int
BEGIN TRY            
SET NOCOUNT ON;         
        
	DECLARE @Dt float,@XML xml,@TempGuid nvarchar(50),@HasAccess bit,@IsDuplicateNameAllowed bit,@IsAccountCodeAutoGen bit          
	DECLARE @UpdateSql nvarchar(max),@ParentCode nvarchar(200),@CCCCCData XML,@IsIgnoreSpace bit          
	DECLARE @lft bigint,@rgt bigint,@Selectedlft bigint,@Selectedrgt bigint,@Depth int,@ParentID bigint          
	DECLARE @SelectedIsGroup bit,@SNO BIGINT,@Prefix NVARCHAR(500)
	declare @CNT INT ,  @ICNT INT  ,@level int,@maxLevel int,@Occurrence int
	DECLARE @DDValue DateTime,@DDXML nvarchar(max),@ScheduleID BIGINT       
	DECLARE @return_value int,@unitGUId  NVARCHAR(max)       
	DECLARE @AccountType xml,@AccValue nvarchar(100),@Documents xml,@DocIDValue nvarchar(100),@TempDocIDValue nvarchar(100)   
	declare @tempxml xml,@tempAmt Float,@tempSno int    
	DECLARE @DELETEDOCID BIGINT,@DELETECCID BIGINT,@DELETEISACC BIT       	     
	DECLARE @AUDITSTATUS NVARCHAR(50),@PrefValue NVARCHAR(500),@Dimesion bigint   
	SET @AUDITSTATUS= 'EDIT'    

    declare @cpref nvarchar(200) ,@CCStatusID int   
	select  @PrefValue = Value from COM_CostCenterPreferences   WITH(nolock)  where CostCenterID=95 and  Name = 'LinkDocument'   
	SET @Dt=convert(float,getdate())--Setting Current Date        

	if(@MultiUnitIDs is not null and  @MultiUnitIDs<>'')
	BEGIN                  
		set @DDXML ='if exists(SELECT ContractID, ContractPrefix, ContractDate,convert(datetime,StartDate) StartDate,                   
		convert(datetime, EndDate) EndDate,  ContractNumber, StatusID                       
		FROM REN_Contract with(nolock)                      
		WHERE ( '''+convert(nvarchar,@StartDate)+'''   between CONVERT(datetime, StartDate) and CONVERT(datetime, EndDate)      
		or       '''+convert(nvarchar,@EndDate)+'''  between CONVERT(datetime, StartDate) and CONVERT(datetime, EndDate)
	 	or	CONVERT(datetime, StartDate) between '''+convert(nvarchar,@StartDate)+''' and  '''+convert(nvarchar,@EndDate)+''' 
	 	or CONVERT(datetime, EndDate) between '''+convert(nvarchar,@StartDate)+''' and  '''+convert(nvarchar,@EndDate)+'''  )             
		AND UnitID in('+@MultiUnitIDs+') and    StatusID not in(428,451) '
		
		if(@ContractID>0)
			set @DDXML =@DDXML+' and ContractID<>'+convert(nvarchar,@ContractID)+' and RefContractID<>'+convert(nvarchar,@ContractID)
		set @DDXML =@DDXML+') RAISERROR(''-520'',16,1)'		 
	END
	ELSE
		set @DDXML='if exists(SELECT ContractID, ContractPrefix, ContractDate,convert(datetime,StartDate) StartDate,                   
		convert(datetime, EndDate) EndDate,  ContractNumber, StatusID                       
		FROM REN_Contract with(nolock)                      
		WHERE ( '''+convert(nvarchar,@StartDate)+'''   between CONVERT(datetime, StartDate) and CONVERT(datetime, EndDate)      
		or       '''+convert(nvarchar,@EndDate)+'''  between CONVERT(datetime, StartDate) and CONVERT(datetime, EndDate)
		or	CONVERT(datetime, StartDate) between '''+convert(nvarchar,@StartDate)+''' and  '''+convert(nvarchar,@EndDate)+''' 
	 	or CONVERT(datetime, EndDate) between '''+convert(nvarchar,@StartDate)+''' and  '''+convert(nvarchar,@EndDate)+'''   )             
		AND UnitID = '+convert(nvarchar,@UnitID)+' and    StatusID <> 428   and    StatusID <> 451   
		and ContractID<>'+convert(nvarchar,@ContractID )+')
		RAISERROR(''-520'',16,1)'		 

	if(@CostCenterID=95)
	BEGIN
		print @DDXML
		exec(@DDXML)
		 
		set @DDXML='if exists(SELECT QuotationID from REN_Quotation with(nolock)                      
		WHERE ( '''+convert(nvarchar,@StartDate)+'''   between CONVERT(datetime, StartDate) and CONVERT(datetime, EndDate)      
		or       '''+convert(nvarchar,@EndDate)+'''  between CONVERT(datetime, StartDate) and CONVERT(datetime, EndDate)
		or	CONVERT(datetime, StartDate) between '''+convert(nvarchar,@StartDate)+''' and  '''+convert(nvarchar,@EndDate)+''' 
	 	or CONVERT(datetime, EndDate) between '''+convert(nvarchar,@StartDate)+''' and  '''+convert(nvarchar,@EndDate)+'''   )             
		AND UnitID = '+convert(nvarchar,@UnitID)+' and StatusID =467
		and QuotationID<>'+convert(nvarchar,@LinkedQuotationID )+')
		RAISERROR(''-520'',16,1)'	
		exec(@DDXML)
		
		if(@LinkedQuotationID>0)
		BEGIN
			update REN_Quotation 
			set StatusID =468 
			where QuotationID=@LinkedQuotationID
		END
	END
  
    --User acces check FOR Notes      
	IF (@NotesXML IS NOT NULL AND @NotesXML <> '')      
	BEGIN      
		SET @HasAccess=dbo.fnCOM_HasAccess(@RoleID,95,8)      

		IF @HasAccess=0      
		BEGIN      
			RAISERROR('-105',16,1)      
		END      
	END      

	--User acces check FOR Attachments      
	IF (@AttachmentsXML IS NOT NULL AND @AttachmentsXML <> '')      
	BEGIN      
		SET @HasAccess=dbo.fnCOM_HasAccess(@RoleID,@CostCenterID,12)      

		IF @HasAccess=0      
		BEGIN      
			RAISERROR('-105',16,1)      
		END      
	END      
   
	if(@MultiUnitIds is not null and @MultiUnitIds<>'' and @MultiUnitName is not null and @MultiUnitName<>'' )
	BEGIN    
        set @UnitID=0
		if(@ContractID>0 and exists (select UnitID from REN_Units with(nolock) where ContractID=@ContractID))
		BEGIN
			 select @UnitID=UnitID,@unitGUId=GUID from REN_Units with(nolock) where ContractID=@ContractID	
		END
		else
			set @unitGUId=Newid()
		
		EXEC @return_value = [dbo].[spREN_SetUnits]  
		  @UNITID = @UNITID,  
		  @PROPERTYID = @PropertyID,  
		  @CODE = @MultiUnitName,  
		  @NAME = @MultiUnitName,   
		  @STATUSID = 424,  
		  @IsGroup = 0,  
		  @SelectedNodeID = 1,  
		   
		  @DETAILSXML = '',  
		  @StaticFieldsQuery = '',
		  @CustomCostCenterFieldsQuery = '',  
		  @CustomCCQuery = '',  
		     
		  @AttachmentsXML = '', 
		  @UnitRateXML = '',         
		  @CompanyGUID = @CompanyGUID,  
		  @GUID =@unitGUId,  
		  @UserName = @UserName,  
		  @UserID = @UserID,  
		  @LangId = @LangID  
		 
		if(@return_value>0)
		begin
			set @UnitID=@return_value
			
			DECLARE @SQL NVARCHAR(MAX)
			SET @SQL='DECLARE @UNITTYPEID BIGINT,@ANNAULRENT FLOAT
			SELECT @UNITTYPEID=MAX(NODEID),@ANNAULRENT=SUM(AnnualRent) FROM REN_Units with(nolock) where UNITID IN ('+@MultiUnitIds+')
			UPDATE REN_Units SET NODEID=@UNITTYPEID ,AnnualRent=@ANNAULRENT WHERE UnitID='+CONVERT(NVARCHAR,@UnitID)
			EXEC(@SQL)
			
			SET @SQL='UPDATE DEST
			   SET DEST.CCNID1 = SRC.CCNID1
				  ,DEST.CCNID2 = SRC.CCNID2
				  ,DEST.CCNID3 = SRC.CCNID3
				  ,DEST.CCNID4 = SRC.CCNID4
				  ,DEST.CCNID5 = SRC.CCNID5
				  ,DEST.CCNID6 = SRC.CCNID6
				  ,DEST.CCNID7 = SRC.CCNID7
				  ,DEST.CCNID8 = SRC.CCNID8
				  ,DEST.CCNID9 = SRC.CCNID9
				  ,DEST.CCNID10 = SRC.CCNID10
				  ,DEST.CCNID11 = SRC.CCNID11
				  ,DEST.CCNID12 = SRC.CCNID12
				  ,DEST.CCNID13 = SRC.CCNID13
				  ,DEST.CCNID14 = SRC.CCNID14
				  ,DEST.CCNID15 = SRC.CCNID15
				  ,DEST.CCNID16 = SRC.CCNID16
				  ,DEST.CCNID17 = SRC.CCNID17
				  ,DEST.CCNID18 = SRC.CCNID18
				  ,DEST.CCNID19 = SRC.CCNID19
				  ,DEST.CCNID20 = SRC.CCNID20
				  ,DEST.CCNID21 = SRC.CCNID21
				  ,DEST.CCNID22 = SRC.CCNID22
				  ,DEST.CCNID23 = SRC.CCNID23
				  ,DEST.CCNID24 = SRC.CCNID24
				  ,DEST.CCNID25 = SRC.CCNID25
				  ,DEST.CCNID26 = SRC.CCNID26
				  ,DEST.CCNID27 = SRC.CCNID27
				  ,DEST.CCNID28 = SRC.CCNID28
				  ,DEST.CCNID29 = SRC.CCNID29
				  ,DEST.CCNID30 = SRC.CCNID30
				  ,DEST.CCNID31 = SRC.CCNID31
				  ,DEST.CCNID32 = SRC.CCNID32
				  ,DEST.CCNID33 = SRC.CCNID33
				  ,DEST.CCNID34 = SRC.CCNID34
				  ,DEST.CCNID35 = SRC.CCNID35
				  ,DEST.CCNID36 = SRC.CCNID36
				  ,DEST.CCNID37 = SRC.CCNID37
				  ,DEST.CCNID38 = SRC.CCNID38
				  ,DEST.CCNID39 = SRC.CCNID39
				  ,DEST.CCNID40 = SRC.CCNID40
				  ,DEST.CCNID41 = SRC.CCNID41
				  ,DEST.CCNID42 = SRC.CCNID42
				  ,DEST.CCNID43 = SRC.CCNID43
				  ,DEST.CCNID44 = SRC.CCNID44
				  ,DEST.CCNID45 = SRC.CCNID45
				  ,DEST.CCNID46 = SRC.CCNID46
				  ,DEST.CCNID47 = SRC.CCNID47
				  ,DEST.CCNID48 = SRC.CCNID48
				  ,DEST.CCNID49 = SRC.CCNID49
				  ,DEST.CCNID50 = SRC.CCNID50
			FROM COM_CCCCData SRC WITH(NOLOCK),COM_CCCCData DEST WITH(NOLOCK)
			WHERE SRC.CostCenterID=93 AND SRC.NodeID IN ('+@MultiUnitIds+')
			AND DEST.CostCenterID=93 AND DEST.NodeID='+CONVERT(NVARCHAR,@UnitID)
			EXEC(@SQL)
			
			IF EXISTS (SELECT * FROM ADM_GlobalPreferences WITH(NOLOCK) WHERE Name='VATVersion' AND Value is not null AND Value<>'')
			BEGIN
				SET @SQL='UPDATE DEST
				   SET DEST.CCNID58 = SRC.CCNID38
					  ,DEST.CCNID59 = SRC.CCNID39
					  ,DEST.CCNID60 = SRC.CCNID40
					  ,DEST.CCNID61 = SRC.CCNID41
					  ,DEST.CCNID62 = SRC.CCNID42
				FROM COM_CCCCData SRC WITH(NOLOCK),COM_CCCCData DEST WITH(NOLOCK)
				WHERE SRC.CostCenterID=93 AND SRC.NodeID IN ('+@MultiUnitIds+')
				AND DEST.CostCenterID=93 AND DEST.NodeID='+CONVERT(NVARCHAR,@UnitID)
				EXEC(@SQL)
			END
			
			SET @SQL='UPDATE DEST
			SET DEST.Alpha1 = SRC.Alpha1
			  ,DEST.Alpha2 = SRC.Alpha2
			  ,DEST.Alpha3 = SRC.Alpha3
			  ,DEST.Alpha4 = SRC.Alpha4
			  ,DEST.Alpha5 = SRC.Alpha5
			  ,DEST.Alpha6 = SRC.Alpha6
			  ,DEST.Alpha7 = SRC.Alpha7
			  ,DEST.Alpha8 = SRC.Alpha8
			  ,DEST.Alpha9 = SRC.Alpha9
			  ,DEST.Alpha10 = SRC.Alpha10
			  ,DEST.Alpha11 = SRC.Alpha11
			  ,DEST.Alpha12 = SRC.Alpha12
			  ,DEST.Alpha13 = SRC.Alpha13
			  ,DEST.Alpha14 = SRC.Alpha14
			  ,DEST.Alpha15 = SRC.Alpha15
			  ,DEST.Alpha16 = SRC.Alpha16
			  ,DEST.Alpha17 = SRC.Alpha17
			  ,DEST.Alpha18 = SRC.Alpha18
			  ,DEST.Alpha19 = SRC.Alpha19
			  ,DEST.Alpha20 = SRC.Alpha20
			  ,DEST.Alpha21 = SRC.Alpha21
			  ,DEST.Alpha22 = SRC.Alpha22
			  ,DEST.Alpha23 = SRC.Alpha23
			  ,DEST.Alpha24 = SRC.Alpha24
			  ,DEST.Alpha25 = SRC.Alpha25
			  ,DEST.Alpha26 = SRC.Alpha26
			  ,DEST.Alpha27 = SRC.Alpha27
			  ,DEST.Alpha28 = SRC.Alpha28
			  ,DEST.Alpha29 = SRC.Alpha29
			  ,DEST.Alpha30 = SRC.Alpha30
			  ,DEST.Alpha31 = SRC.Alpha31
			  ,DEST.Alpha32 = SRC.Alpha32
			  ,DEST.Alpha33 = SRC.Alpha33
			  ,DEST.Alpha34 = SRC.Alpha34
			  ,DEST.Alpha35 = SRC.Alpha35
			  ,DEST.Alpha36 = SRC.Alpha36
			  ,DEST.Alpha37 = SRC.Alpha37
			  ,DEST.Alpha38 = SRC.Alpha38
			  ,DEST.Alpha39 = SRC.Alpha39
			  ,DEST.Alpha40 = SRC.Alpha40
			  ,DEST.Alpha41 = SRC.Alpha41
			  ,DEST.Alpha42 = SRC.Alpha42
			  ,DEST.Alpha43 = SRC.Alpha43
			  ,DEST.Alpha44 = SRC.Alpha44
			  ,DEST.Alpha45 = SRC.Alpha45
			  ,DEST.Alpha46 = SRC.Alpha46
			  ,DEST.Alpha47 = SRC.Alpha47
			  ,DEST.Alpha48 = SRC.Alpha48
			  ,DEST.Alpha49 = SRC.Alpha49
			  ,DEST.Alpha50 = SRC.Alpha50
			FROM REN_UnitsExtended SRC WITH(NOLOCK),REN_UnitsExtended DEST WITH(NOLOCK)
			WHERE SRC.UnitID IN ('+@MultiUnitIds+') AND DEST.UnitID='+CONVERT(NVARCHAR,@UnitID)
			EXEC(@SQL)
		end
	END
	
	
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
		
		if(@level is not null and  @maxLevel is not null and @maxLevel>@level)
		begin			
		    --set @StatusID=466
			set @StatusID=440
		END
	END
      
	IF @ContractID=0          
	BEGIN         
		SET @AUDITSTATUS = 'ADD'  
	          
		SELECT @SelectedIsGroup=IsGroup,@Selectedlft =lft,@Selectedrgt=rgt,@ParentID=ParentID,@Depth=Depth          
		from [REN_Contract] with(NOLOCK) where ContractID=@SelectedNodeID          
	           
		select @SNO=ISNULL(max(SNO),0)+1 from [REN_Contract] (holdlock) WHERE CostCenterID=@CostCenterID
		
		if (select count(*) from ren_contract with(nolock) where propertyid=@PropertyID and CostCenterID=@CostCenterID and contractnumber=@ContractNumber)>0
		begin
			select @ContractNumber=ISNULL(max(ContractNumber),0)+1 from ren_contract with(nolock)
			where propertyid=@PropertyID and CostCenterID=@CostCenterID
		end
  
		--IF No Record Selected or Record Doesn't Exist          
		if(@SelectedIsGroup is null)           
			select @SelectedNodeID=ContractID,@SelectedIsGroup=IsGroup,@Selectedlft =lft,@Selectedrgt=rgt,@ParentID=ParentID,@Depth=Depth          
			from [REN_Contract] with(NOLOCK) where ParentID =0          
        
        if(@SelectedIsGroup is null and exists (select * from [REN_Contract] with(NOLOCK) where CostCenterID=@CostCenterID))   
			select top 1 @SelectedNodeID=ParentID,@SelectedIsGroup=IsGroup,@Selectedlft =lft,@Selectedrgt=rgt,@ParentID=ParentID,@Depth=Depth          
			from [REN_Contract] with(NOLOCK) where CostCenterID=@CostCenterID
			order by sno desc
			         
		if(@SelectedIsGroup = 1)--Adding Node Under the Group          
		BEGIN          
			UPDATE REN_Contract SET rgt = rgt + 2 WHERE rgt > @Selectedlft;          
			UPDATE REN_Contract SET lft = lft + 2 WHERE lft > @Selectedlft;          
			set @lft =  @Selectedlft + 1          
			set @rgt = @Selectedlft + 2          
			set @ParentID = @SelectedNodeID          
			set @Depth = @Depth + 1          
		END          
		else if(@SelectedIsGroup = 0)--Adding Node at Same level          
		BEGIN          
			UPDATE REN_Contract SET rgt = rgt + 2 WHERE rgt > @Selectedrgt;          
			UPDATE REN_Contract SET lft = lft + 2 WHERE lft > @Selectedrgt;          
			set @lft =  @Selectedrgt + 1          
			set @rgt = @Selectedrgt + 2           
		END          
		else  --Adding Root          
		BEGIN          
			set @lft =  1          
			set @rgt = 2           
			set @Depth = 0          
			set @ParentID =0          
			set @IsGroup=0          
		END          
       
		set @return_value = 1     
		set @Dimesion = 0   
        
		if(@PrefValue is not null and @PrefValue<>'' and  @CostCenterID = 95)      
		begin    
			set @Dimesion=0      
			begin try      
				select @Dimesion=convert(BIGINT,@PrefValue)      
			end try      
			begin catch      
				set @Dimesion=0      
			end catch      
			if(@Dimesion>0)      
			begin      
				select @CCStatusID =statusid from com_status with(nolock) where costcenterid=@Dimesion and [status] = 'Active'    
				select @cpref = name from [REN_property] with(nolock) where nodeid  =  @ContractPrefix   
				set @cpref =  @cpref +  '-'+ convert(nvarchar, @ContractNumber)  

				EXEC @return_value = [dbo].[spCOM_SetCostCenter]    
				@NodeID = 0,@SelectedNodeID = 0,@IsGroup = @IsGroup,    
				@Code = @SNO,    
				@Name = @cpref,    
				@AliasName=@cpref,    
				@PurchaseAccount=0,@SalesAccount=0,@StatusID=@CCStatusID,    
				@CustomFieldsQuery=NULL,@AddressXML=NULL,@AttachmentsXML=NULL,    
				@CustomCostCenterFieldsQuery=NULL,@ContactsXML=NULL,@NotesXML=NULL,    
				@CostCenterID = @Dimesion,@CompanyGUID=@COMPANYGUID,@GUID='',@UserName='admin',
				@RoleID=1,@UserID=1, @CheckLink = 0    
			end      
		end       
      
		--INSERT CONTRACT      
		INSERT INTO  [REN_Contract]        
			  ([ContractPrefix],SNO,QuotationID        
			  ,[ContractDate]        
			  ,[ContractNumber]        
			  ,[StatusID]        
			  ,[PropertyID]        
			  ,[UnitID]        
			  ,[TenantID]        
			  ,[RentAccID]        
			  ,[IncomeAccID]        
			  ,[Purpose]        
			  ,[StartDate]        
			  ,[EndDate]   
			  ,[ExtendTill]        
			  ,[TotalAmount]        
			  ,[NonRecurAmount]        
			  ,[RecurAmount]        
			  ,[Depth]        
			  ,[ParentID]        
			  ,[lft]        
			  ,[rgt]        
			  ,[IsGroup]        
			  ,[CompanyGUID]        
			  ,[GUID]        
			  ,[CreatedBy]        
			  ,[CreatedDate]       
			  ,[LocationID]      
			  ,[DivisionID]      
			  ,[CurrencyID]        
			  ,[TermsConditions]    
			  ,[SalesmanID]    
			  ,[AccountantID]      
			  ,[LandlordID]    
			  ,Narration    
			  ,[CostCenterID],CCNodeID,CCID,VacancyDate,BasedOn,RenewRefID
			  ,WorkFlowID,WorkFlowLevel,AgeOfRenewal,RecurDuration,Refno,parentContractID,IsExtended)        
		VALUES(@ContractPrefix,  @SNO,@LinkedQuotationID,     
				CONVERT(FLOAT,@ContractDate),        
				@ContractNumber,        
				@StatusID,        
				@PropertyID,        
				@UnitID,        
				@TenantID,        
				@RentRecID,        
				@IncomeID,        
				@Purpose,        
				CONVERT(FLOAT,@StartDate),        
				CONVERT(FLOAT,@EndDate),   
				CONVERT(FLOAT,@ExtndTill),        
				@TotalAmount,        
				@NonRecurAmount,        
				@RecurAmount ,      
				@Depth,      
				@SelectedNodeID,      
				@lft,      
				@rgt,      
				@IsGroup,        
				@CompanyGUID,          
				newid(),          
				@UserName,          
				@Dt,      
				@ContractLocationID,      
				@ContractDivisionID,      
				@ContractCurrencyID,      
				@TermsConditions,    
				@SalesmanID,    
				@AccountantID,    
				@LandlordID,    
				@Narration,    
				@CostCenterID ,isnull( @return_value ,0) ,@Dimesion, CONVERT(FLOAT,@EndDate),@basedon,@RenewRefID
				,@WID,@level,0,@RecurDuration,@Refno,@parContractID,@IsExtended)        
		IF @@ERROR<>0 BEGIN ROLLBACK TRANSACTION RETURN -101 END        
			set @ContractID=SCOPE_IDENTITY()        
		
		IF @parContractID IS NOT NULL AND @parContractID>0
		BEGIN
			UPDATE [REN_Contract] SET NoOfContratcs=(SELECT count(*) FROM [REN_Contract] WITH(NOLOCK) WHERE parentContractID=@parContractID)
			WHERE ContractID=@parContractID
		END
		
		IF @RenewRefID IS NOT NULL AND @RenewRefID>0
		BEGIN
			UPDATE [REN_Contract] SET AgeOfRenewal=(SELECT isnull(AgeOfRenewal,0)+1 FROM [REN_Contract] WITH(NOLOCK) WHERE ContractID=@RenewRefID)
			WHERE ContractID=@ContractID
		END
		
		INSERT INTO REN_ContractExtended([NodeID],[CreatedBy],[CreatedDate])        
		VALUES(@ContractID, @UserName, @Dt)        

		INSERT INTO COM_CCCCDATA ([CostCenterID] ,[NodeID] ,[Guid],[CreatedBy],[CreatedDate])      
		VALUES(95,@ContractID,newid(),  @UserName, @Dt)      
       
	END -- END CREATE        
	ELSE --UPDATE
	BEGIN
		if(@WID=0)
		BEGIN      
			set @TempDocIDValue=0
			select @SNO=SNO,@TempDocIDValue=isnull(WorkFlowID,0),@level=WorkFlowLevel from [REN_Contract] with(nolock) WHERE ContractID =  @ContractID			
		END
		ELSE
		BEGIN
			select @SNO=SNO from [REN_Contract] with(nolock) WHERE ContractID =  @ContractID
			set @TempDocIDValue=@WID
		END	
		
		
		UPDATE  [REN_Contract]      
		SET [ContractDate] =  CONVERT(FLOAT,@ContractDate) 
			,QuotationID=@LinkedQuotationID
			,[StatusID] = @StatusID      
			,[PropertyID] = @PropertyID      
			,[UnitID] = @UnitID      
			,[TenantID] = @TenantID      
			,[RentAccID] = @RentRecID      
			,[IncomeAccID] = @IncomeID      
			,[Purpose] = @Purpose      
			,[StartDate] = CONVERT(FLOAT,@StartDate)      
			,[EndDate] = CONVERT(FLOAT,@EndDate)     
			,[ExtendTill] = CONVERT(FLOAT,@ExtndTill)     
			,[TotalAmount] = @TotalAmount      
			,[NonRecurAmount] = @NonRecurAmount      
			,[RecurAmount] = @RecurAmount      
			,[CompanyGUID] = @CompanyGUID      
			,[GUID] = @GUID      
			,[ModifiedBy] = @UserName      
			,[ModifiedDate] =@Dt 
			,[LocationID] = @ContractLocationID      
			,[DivisionID] =@ContractDivisionID      
			,[CurrencyID] =@ContractCurrencyID      
			,[TermsConditions] =@TermsConditions      
			,[SalesmanID] =@SalesmanID    
			,[AccountantID] =@AccountantID    
			,[LandlordID] = @LandlordID    
			,[Narration] = @Narration 
			,VacancyDate= CONVERT(FLOAT,@EndDate)
			,BasedOn=@basedon   
			,WorkFlowID=@TempDocIDValue,WorkFlowLevel=@level
			,RecurDuration=@RecurDuration
			,IsExtended=@IsExtended
		WHERE ContractID =  @ContractID      
      
		if(@PrefValue is not null and @PrefValue<>''  and  @CostCenterID = 95 )      
		begin     
			set @Dimesion=0      
			begin try      
				select @Dimesion=convert(BIGINT,@PrefValue)      
			end try      
			begin catch      
				set @Dimesion=0       
			end catch      
		      
			declare @NID bigint, @CCIDAcc bigint    
		     
			select @NID =isnull(CCNodeID,0), @CCIDAcc=CCID  from Ren_Contract with(nolock) where ContractID=@ContractID             
	  
			if(@Dimesion>0)    
			begin  
				declare @Gid nvarchar(50)=''
				IF(@NID>1)
				BEGIN
					declare @Table nvarchar(100), @NodeidXML nvarchar(max)     
					select @Table=Tablename from adm_features with(nolock) where featureid=@Dimesion    
					declare @str nvarchar(max)     
					set @str='@Gid nvarchar(50) output'     
					set @NodeidXML='set @Gid= (select GUID from '+convert(nvarchar,@Table)+' with(nolock) where NodeID='+convert(nvarchar,@NID)+')'    

					exec sp_executesql @NodeidXML, @str, @Gid OUTPUT     
				END
				ELSE
					SET @NID=0
					
				select  @CCStatusID =statusid from com_status with(nolock) where costcenterid=@Dimesion and status = 'Active'    
				select @cpref = name from [REN_property] with(nolock) where nodeid  =   @ContractPrefix  
				set @cpref =  @cpref + '-'+ convert(nvarchar, @ContractNumber)  

				EXEC @return_value = [dbo].[spCOM_SetCostCenter]    
				@NodeID = @NID,
				@SelectedNodeID = 1,
				@IsGroup = @IsGroup,    
				@Code = @SNO,    
				@Name = @cpref,    
				@AliasName=@cpref,    
				@PurchaseAccount=0,@SalesAccount=0,@StatusID=@CCStatusID,    
				@CustomFieldsQuery=NULL,@AddressXML=NULL,@AttachmentsXML='',    
				@CustomCostCenterFieldsQuery=NULL,@ContactsXML=null,@NotesXML=NULL,    
				@CostCenterID = @Dimesion,@CompanyGUID=@CompanyGUID,@GUID=@Gid,@UserName='admin',@RoleID=1,@UserID=1 , @CheckLink = 0     

				Update Ren_Contract set CCID=@Dimesion, CCNodeID=@return_value where ContractID=@ContractID          
				
			END    
		END       
	END--UPDATE
	
	IF(@ContractXML IS NOT NULL AND @ContractXML<>'')        
	BEGIN        
		SET @XML= @ContractXML          

		DELETE FROM [REN_ContractParticulars] WHERE CONTRACTID = @ContractID        

		INSERT INTO [REN_ContractParticulars]        
				([ContractID]        
				,[CCID]        
				,[CCNodeID]        
				,[CreditAccID]        
				,[ChequeNo]        
				,[ChequeDate]        
				,[PayeeBank]        
				,[DebitAccID]   
				,[RentAmount]    
				,[Discount]         
				,[Amount]        
				,[Sno]      
				,[IsRecurr],Narration ,VatPer,VatAmount         
				,[CompanyGUID]        
				,[GUID]        
				,[CreatedBy]        
				,[CreatedDate],TasjeelAmount,Detailsxml,AdvanceAccountID,InclChkGen,VatType,TaxCategoryID
				,RecurInvoice,PostDebit,TaxableAmt,Sqft,Rate,LocationID)   
		SELECT @ContractID , X.value('@CCID','BIGINT'),         
				X.value('@CCNodeID','BIGINT'),          
				X.value('@CreditAccID','BIGINT'),         
				X.value('@ChequeNo','NVARCHAR(200)'),        
				CONVERT(float,X.value('@ChequeDate','Datetime')),        
				X.value('@PayeeBank','nvarchar(500)'),        
				X.value('@DebitAccID','BIGINT'),    
				X.value('@RentAmount','float'),    
				X.value('@Discount','float'),       
				X.value('@Amount','float'),        
				X.value('@SNO','int'),      
				X.value('@IsRecurr','bit'),  X.value('@Narration','nvarchar(max)'), 
				X.value('@VatPer','float'),
				X.value('@VatAmount','float'),    
				@CompanyGUID,          
				newid(),          
				@UserName,          
				@Dt,X.value('@TasjeelAmount','float'),convert(nvarchar(max), X.query('XML'))  ,         
				X.value('@AdvanceAccountID','BIGINT'), X.value('@InclChkGen','INT')
				, X.value('@VatType','Nvarchar(50)'),X.value('@TaxCategoryID','BIGINT')
				, X.value('@Recur','BIT'),X.value('@PostDebit','bit'),X.value('@TaxableAmt','float')
				, X.value('@Sqft','float'),X.value('@Rate','float'),        
				X.value('@LocationID','BIGINT')
				
		FROM @XML.nodes('/ContractXML/Rows/Row') as Data(X) 
	END        

	IF(@PayTermsXML IS NOT NULL AND @PayTermsXML<>'')        
	BEGIN        
		SET @XML= @PayTermsXML          

		DELETE FROM [REN_ContractPayTerms] WHERE CONTRACTID = @ContractID        

		INSERT INTO  [REN_ContractPayTerms]        
				([ContractID]        
				,[ChequeNo]        
				,[ChequeDate]        
				,[CustomerBank]        
				,[DebitAccID]        
				,[Amount],RentAmount       
				,[SNO]       
				,[Narration]      
				,[CompanyGUID]        
				,[GUID]        
				,[CreatedBy]        
				,[CreatedDate],Period,PostingDate,LocationID,Particular )  
		SELECT @ContractID  ,        
				X.value('@ChequeNo','NVARCHAR(200)'),        
				Convert(float,X.value('@ChequeDate','Datetime')),        
				X.value('@CustomerBank','nvarchar(500)'),        
				X.value('@DebitAccID','BIGINT'),        
				X.value('@Amount','float'), X.value('@RentAmount','float'),       
				X.value('@SNO','int'),      
				X.value('@Narration','nvarchar(MAX)'),      
				@CompanyGUID,          
				newid(),          
				@UserName,          
				@Dt         , X.value('@Period','BIGINT'),
				Convert(float,X.value('@PostingDate','Datetime')),        
				X.value('@LocationID','BIGINT'),        
				X.value('@Particular','BIGINT')
		FROM @XML.nodes('/PayTermXML/Rows/Row') as Data(X)          
	END    
	
	declare @tabPart table(id int identity(1,1),NodeID bigint,PartXML nvarchar(max))
	insert into @tabPart
	select NodeID,Detailsxml from [REN_ContractParticulars] WITH(NOLOCK)       
	where CONTRACTID = @ContractID and Detailsxml is not null
	
	Delete from REN_ContractParticularsDetail where ContractID=@ContractID and Costcenterid=@CostCenterID
	
	SELECT @ICNT = 0,@CNT = COUNT(ID) FROM @tabPart            
	WHILE(@ICNT < @CNT)      
	BEGIN      
		SET @ICNT =@ICNT+1 
		SELECT @DDXML = PartXML,@ParentID=NodeID   FROM @tabPart WHERE  ID = @ICNT 

		SET @XML= @DDXML 
		if(@DDXML like '%UnitsRow%')
			INSERT INTO  REN_ContractParticularsDetail
			([ContractID],ParticularNodeID,FromDate,ToDate,Unit,Period,Amount,Rate,CostCenterID,Discount,ActAmount,Distribute,Narration)  
			SELECT @ContractID,@ParentID,Convert(float,X.value('@FromDate','Datetime')),        
			Convert(float,X.value('@ToDate','Datetime')),        
			X.value('@Unit','BIGINT'),        
			X.value('@Period','BIGINT'),        
			X.value('@Amount','float'),
			ISNULL(X.value('@Rate','float'),0),
			@CostCenterID,
			ISNULL(X.value('@Discount','float'),0),
			ISNULL(X.value('@ActAmount','float'),0),
			X.value('@Distribute','INT'),      
			X.value('@Narration','nvarchar(MAX)')
			FROM @XML.nodes('/XML/UnitsRow/Row') as Data(X) 
		ELSE
			INSERT INTO  REN_ContractParticularsDetail
			([ContractID],ParticularNodeID,FromDate,ToDate,Unit,Period,Amount,Rate,CostCenterID,Discount,ActAmount,Distribute,Narration)  
			SELECT @ContractID,@ParentID,Convert(float,X.value('@FromDate','Datetime')),        
			Convert(float,X.value('@ToDate','Datetime')),        
			X.value('@Unit','BIGINT'),        
			X.value('@Period','BIGINT'),        
			X.value('@Amount','float'),
			ISNULL(X.value('@Rate','float'),0),
			@CostCenterID,
			ISNULL(X.value('@Discount','float'),0),
			ISNULL(X.value('@ActAmount','float'),0),
			X.value('@Distribute','INT'),      
			X.value('@Narration','nvarchar(MAX)')
			FROM @XML.nodes('/XML/Row') as Data(X)   
	END

	--Inserts Multiple Notes      
	IF (@NotesXML IS NOT NULL AND @NotesXML <> '')      
	BEGIN      
		SET @XML=@NotesXML      

		--If Action is NEW then insert new Notes      
		INSERT INTO COM_Notes(FeatureID,CostCenterID,FeaturePK,Note,         
		GUID,CreatedBy,CreatedDate)      
		SELECT 95,95,@ContractID,Replace(X.value('@Note','NVARCHAR(MAX)'),'@~',''),  
		newid(),@UserName,@Dt      
		FROM @XML.nodes('/NotesXML/Row') as Data(X)      
		WHERE X.value('@Action','NVARCHAR(10)')='NEW'      

		--If Action is MODIFY then update Notes      
		UPDATE COM_Notes      
		SET Note=Replace(X.value('@Note','NVARCHAR(MAX)'),'@~',''),  
		GUID=newid(),      
		ModifiedBy=@UserName,      
		ModifiedDate=@Dt      
		FROM COM_Notes C with(nolock)      
		INNER JOIN @XML.nodes('/NotesXML/Row') as Data(X)        
		ON convert(bigint,X.value('@NoteID','bigint'))=C.NoteID      
		WHERE X.value('@Action','NVARCHAR(500)')='MODIFY'      

		--If Action is DELETE then delete Notes      
		DELETE FROM COM_Notes      
		WHERE NoteID IN(SELECT X.value('@NoteID','bigint')      
		FROM @XML.nodes('/NotesXML/Row') as Data(X)      
		WHERE X.value('@Action','NVARCHAR(10)')='DELETE')      

	END      
      
	--Inserts Multiple Attachments      
	IF (@AttachmentsXML IS NOT NULL AND @AttachmentsXML <> '')      
	BEGIN      
		SET @XML=@AttachmentsXML      

		INSERT INTO COM_Files(FilePath,ActualFileName,RelativeFileName,    
		FileExtension,FileDescription,IsProductImage,FeatureID,CostCenterID,FeaturePK,      
		GUID,CreatedBy,CreatedDate)      
		SELECT X.value('@FilePath','NVARCHAR(500)'),X.value('@ActualFileName','NVARCHAR(50)'),X.value('@RelativeFileName','NVARCHAR(50)'),      
		X.value('@FileExtension','NVARCHAR(50)'),X.value('@FileDescription','NVARCHAR(500)'),X.value('@IsProductImage','bit'),@CostCenterID,@CostCenterID,@ContractID,      
		X.value('@GUID','NVARCHAR(50)'),@UserName,@Dt      
		FROM @XML.nodes('/AttachmentsXML/Row') as Data(X)        
		WHERE X.value('@Action','NVARCHAR(10)')='NEW'      

		--If Action is MODIFY then update Attachments      
		UPDATE COM_Files      
		SET FilePath=X.value('@FilePath','NVARCHAR(500)'),      
		ActualFileName=X.value('@ActualFileName','NVARCHAR(50)'),      
		RelativeFileName=X.value('@RelativeFileName','NVARCHAR(50)'),      
		FileExtension=X.value('@FileExtension','NVARCHAR(50)'),      
		FileDescription=X.value('@FileDescription','NVARCHAR(500)'),      
		IsProductImage=X.value('@IsProductImage','bit'),            
		GUID=X.value('@GUID','NVARCHAR(50)'),      
		ModifiedBy=@UserName,      
		ModifiedDate=@Dt      
		FROM COM_Files C with(nolock)      
		INNER JOIN @XML.nodes('/AttachmentsXML/Row') as Data(X)        
		ON convert(bigint,X.value('@AttachmentID','bigint'))=C.FileID      
		WHERE X.value('@Action','NVARCHAR(500)')='MODIFY'      

		--If Action is DELETE then delete Attachments      
		DELETE FROM COM_Files      
		WHERE FileID IN(SELECT X.value('@AttachmentID','bigint')      
		FROM @XML.nodes('/AttachmentsXML/Row') as Data(X)      
		WHERE X.value('@Action','NVARCHAR(10)')='DELETE')      
	END      
      
	if(@ActivityXml<>'')      
		exec spCom_SetActivitiesAndSchedules @ActivityXml,95,@ContractID,@CompanyGUID,@Guid,@UserName,@dt,@LangID     
  
	set @UpdateSql='update COM_CCCCDATA SET '+@CustomCostCenterFieldsQuery+'[ModifiedBy] ='''+ @UserName+''',
	[ModifiedDate] =' + convert(nvarchar,@Dt) +' WHERE NodeID ='+convert(nvarchar,@ContractID) + ' AND CostCenterID = 95'       
          
	exec(@UpdateSql)      
      
  --CHECK AUDIT TRIAL ALLOWED AND INSERTING AUDIT TRIAL DATA        
    
	DECLARE @AuditTrial BIT        
	SET @AuditTrial=0        
	SELECT @AuditTrial= CONVERT(BIT,VALUE)  FROM [COM_COSTCENTERPreferences] with(nolock)     
	WHERE CostCenterID=95  AND NAME='AllowAudit'      
	    
	IF (@AuditTrial=1 AND @CostCenterID=95 )      
	BEGIN       
      
		INSERT INTO  [REN_Contract_History]    
           ([ContractID]    
           ,[ContractPrefix]    
           ,[ContractDate]    
           ,[ContractNumber]    
           ,[StatusID]    
           ,[PropertyID]    
           ,[UnitID]    
           ,[TenantID]    
           ,[RentAccID]    
           ,[IncomeAccID]    
           ,[Purpose]    
           ,[StartDate]    
           ,[EndDate]    
           ,[ExtendTill]   
           ,[TotalAmount]    
           ,[NonRecurAmount]    
           ,[RecurAmount]    
           ,[Depth]    
           ,[ParentID]    
           ,[lft]    
           ,[rgt]    
           ,[IsGroup]    
           ,[CompanyGUID]    
           ,[GUID]    
           ,[CreatedBy]    
           ,[CreatedDate]    
           ,[ModifiedBy]    
           ,[ModifiedDate]    
           ,[TerminationDate]    
           ,[Reason]    
           ,[LocationID]    
           ,[DivisionID]    
           ,[CurrencyID]    
           ,[TermsConditions]    
           ,[SalesmanID]    
           ,[AccountantID]    
           ,[LandlordID]    
           ,[Narration]    
           ,[SNO]    
           ,[CostCenterID]    
           ,[HistoryStatus])    
		  SELECT [ContractID]    
		  ,[ContractPrefix]    
		  ,[ContractDate]    
		  ,[ContractNumber]    
		  ,[StatusID]    
		  ,[PropertyID]    
		  ,[UnitID]    
		  ,[TenantID]    
		  ,[RentAccID]    
		  ,[IncomeAccID]    
		  ,[Purpose]    
		  ,[StartDate]    
		  ,[EndDate]  
		  ,[ExtendTill]    
		  ,[TotalAmount]    
		  ,[NonRecurAmount]    
		  ,[RecurAmount]    
		  ,[Depth]    
		  ,[ParentID]    
		  ,[lft]    
		  ,[rgt]    
		  ,[IsGroup]    
		  ,[CompanyGUID]    
		  ,[GUID]    
		  ,[CreatedBy]    
		  ,[CreatedDate]    
		  ,[ModifiedBy]    
		  ,[ModifiedDate]    
		  ,[TerminationDate]    
		  ,[Reason]    
		  ,[LocationID]    
		  ,[DivisionID]    
		  ,[CurrencyID]    
		  ,[TermsConditions]    
		  ,[SalesmanID]    
		  ,[AccountantID]    
		  ,[LandlordID]    
		  ,[Narration]    
		  ,[SNO]    
		  ,[CostCenterID] , @AUDITSTATUS     
		FROM [REN_Contract]  with(nolock) 
		WHERE  [ContractID]  = @ContractID AND COSTCENTERID = 95    
      
		INSERT INTO  [REN_ContractParticulars_History]    
           ([NodeID]    
           ,[ContractID]    
           ,[CCID]    
           ,[CCHistoryID]    
           ,[CreditAccID]    
           ,[ChequeNo]    
           ,[ChequeDate]    
           ,[PayeeBank]    
           ,[DebitAccID]    
           ,[RentAmount]    
		   ,[Discount]    
           ,[Amount]    
           ,[CompanyGUID]    
           ,[GUID]    
           ,[CreatedBy]    
           ,[CreatedDate]    
           ,[ModifiedBy]    
           ,[ModifiedDate]    
           ,[Sno]    
           ,[Narration]    
           ,[IsRecurr],TasjeelAmount,Detailsxml,AdvanceAccountID,InclChkGen)    
		 SELECT [NodeID]    
		  ,[ContractID]    
		  ,[CCID]    
		  ,[CCNodeID]    
		  ,[CreditAccID]    
		  ,[ChequeNo]    
		  ,[ChequeDate]    
		  ,[PayeeBank]    
		  ,[DebitAccID]    
		  ,[RentAmount]    
		  ,[Discount]    
		  ,[Amount]    
		  ,[CompanyGUID]    
		  ,[GUID]    
		  ,[CreatedBy]    
		  ,[CreatedDate]    
		  ,[ModifiedBy]    
		  ,[ModifiedDate]    
		  ,[Sno]    
		  ,[Narration]    
		  ,[IsRecurr] ,TasjeelAmount,Detailsxml,AdvanceAccountID ,InclChkGen    
		FROM  [REN_ContractParticulars] 
		with(nolock) WHERE  [ContractID]  = @ContractID    
      
		INSERT INTO  [REN_ContractPayTerms_History]    
           ([NodeID]    
           ,[ContractID]    
           ,[ChequeNo]    
           ,[ChequeDate]    
           ,[CustomerBank]    
           ,[DebitAccID]    
           ,[Amount]    
           ,[CompanyGUID]    
           ,[GUID]    
           ,[CreatedBy]    
           ,[CreatedDate]    
           ,[ModifiedBy]    
           ,[ModifiedDate]    
           ,[Sno]    
           ,[Narration],Period,PostingDate)
		SELECT [NodeID]    
		  ,[ContractID]    
		  ,[ChequeNo]    
		  ,[ChequeDate]    
		  ,[CustomerBank]    
		  ,[DebitAccID]    
		  ,[Amount]    
		  ,[CompanyGUID]    
		  ,[GUID]    
		  ,[CreatedBy]    
		  ,[CreatedDate]    
		  ,[ModifiedBy]    
		  ,[ModifiedDate]    
		  ,[Sno]    
		  ,[Narration],Period ,PostingDate   
		FROM  [REN_ContractPayTerms] with(nolock) WHERE  [ContractID]  = @ContractID    
      
		INSERT INTO [REN_ContractExtended_History]    
           ( [NodeID]    
           ,[CreatedBy]    
           ,[CreatedDate]    
           ,[ModifiedBy]    
           ,[ModifiedDate]    
           ,[alpha1]    
           ,[alpha2]    
           ,[alpha3]    
           ,[alpha4]    
           ,[alpha5]    
           ,[alpha6]    
           ,[alpha7]    
           ,[alpha8]    
           ,[alpha9]    
           ,[alpha10]    
           ,[alpha11]    
           ,[alpha12]    
           ,[alpha13]    
           ,[alpha14]    
           ,[alpha15]    
           ,[alpha16]    
           ,[alpha17]    
           ,[alpha18]    
           ,[alpha19]    
           ,[alpha20]    
           ,[alpha21]    
           ,[alpha22]    
           ,[alpha23]    
           ,[alpha24]    
           ,[alpha25]    
           ,[alpha26]    
           ,[alpha27]    
           ,[alpha28]    
           ,[alpha29]    
           ,[alpha30]    
           ,[alpha31]    
           ,[alpha32]    
           ,[alpha33]    
           ,[alpha34]    
           ,[alpha35]    
           ,[alpha36]    
           ,[alpha37]    
           ,[alpha38]    
           ,[alpha39]    
           ,[alpha40]    
           ,[alpha41]    
           ,[alpha42]    
           ,[alpha43]    
           ,[alpha44]    
           ,[alpha45]    
           ,[alpha46]    
           ,[alpha47]    
           ,[alpha48]    
           ,[alpha49]    
           ,[alpha50]    
           ,[HistoryStatus])    
		SELECT [NodeID]    
		  ,[CreatedBy]    
		  ,[CreatedDate]    
		  ,[ModifiedBy]    
		  ,[ModifiedDate]    
		  ,[alpha1]    
		  ,[alpha2]    
		  ,[alpha3]    
		  ,[alpha4]    
		  ,[alpha5]    
		  ,[alpha6]    
		  ,[alpha7]    
		  ,[alpha8]    
		  ,[alpha9]    
		  ,[alpha10]    
		  ,[alpha11]    
		  ,[alpha12]    
		  ,[alpha13]    
		  ,[alpha14]    
		  ,[alpha15]    
		  ,[alpha16]    
		  ,[alpha17]    
		  ,[alpha18]    
		  ,[alpha19]    
		  ,[alpha20]    
		  ,[alpha21]    
		  ,[alpha22]    
		  ,[alpha23]    
		  ,[alpha24]    
		  ,[alpha25]    
		  ,[alpha26]    
		  ,[alpha27]    
		  ,[alpha28]    
		  ,[alpha29]    
		  ,[alpha30]    
		  ,[alpha31]    
		  ,[alpha32]    
		  ,[alpha33]    
		  ,[alpha34]    
		  ,[alpha35]    
		  ,[alpha36]    
		  ,[alpha37]    
		  ,[alpha38]    
		  ,[alpha39]    
		  ,[alpha40]    
		  ,[alpha41]    
		  ,[alpha42]    
		  ,[alpha43]    
		  ,[alpha44]    
		  ,[alpha45]    
		  ,[alpha46]    
		  ,[alpha47]    
		  ,[alpha48]    
		  ,[alpha49]    
		  ,[alpha50], @AUDITSTATUS     
		FROM  [REN_ContractExtended] with(nolock) WHERE  [NodeID]  = @ContractID    
	END         
    --------------------------  POSTINGS --------------------------      
       
        
         
	Declare @RcptCCID BIGint,@ComRcptCCID bigint,@SIVCCID bigint,@RentRcptCCID bigint     
	Declare @BnkRcpt BIGINT  , @PDRcpt BIGINT , @CommRcpt bigint , @SalesInv BIGINT, @RentRcpt BIGINT      
	DECLARE  @StatusValue int ,@IsRes bit    
	DECLARE @AA XML  , @DateXML XML       
	DECLARE @DocXml nvarchar(max)       
				
	--SELECT @StatusValue = isnull(VALUE,369) FROM COM_COSTCENTERPREFERENCES    
	--WHERE COSTCENTERID = 95 AND NAME = 'PostDocStatus'    

	IF(@CostCenterID = 95)    
	BEGIN    
        
        
	IF(@SIVXML is not null and @SIVXML<>'')      
	BEGIN      
		select @ParentID=CONVERT(int,Value) from COM_CostCenterPreferences WITH(nolock)      
		where CostCenterID=95 and Name='ContractSalesInvoice'      
		SET @XML = @SIVXML    

		declare  @tblExistingSIVXML TABLE (ID int identity(1,1),DOCID bigint)           
		declare @totalPreviousSIVXML bigint,@BillWiseXMl Nvarchar(max)    
		insert into @tblExistingSIVXML     
		select DOCID from  [REN_ContractDocMapping] with(nolock)   
		where contractid=@ContractID and Doctype =4 AND ContractCCID= 95    

		select @totalPreviousSIVXML=COUNT(id) from @tblExistingSIVXML     

		CREATE TABLE #tblListSIVTemp(ID int identity(1,1),TRANSXML NVARCHAR(MAX) ,Documents NVARCHAR(MAX),Recurxml NVARCHAR(MAX))            
		INSERT INTO #tblListSIVTemp        
		SELECT  CONVERT(NVARCHAR(MAX),  X.query('DocumentXML')),CONVERT(NVARCHAR(MAX),X.query('Documents')),CONVERT(NVARCHAR(MAX),X.query('recurXML'))                     
		from @XML.nodes('/SIV//ROWS') as Data(X)        

		SELECT @CNT = COUNT(ID) FROM #tblListSIVTemp      

		SET @ICNT = 0      
		WHILE(@ICNT < @CNT)      
		BEGIN      
			SET @ICNT =@ICNT+1      

			SELECT @AA = TRANSXML , @Documents = Documents    FROM #tblListSIVTemp WHERE  ID = @ICNT      

			Set @DocXml = convert(nvarchar(max), @AA)      

			SELECT   @tempSno =  X.value ('@CONTRACTSNO', 'int'),@RcptCCID =  ISNULL(X.value ('@CostCenterid', 'int'),@ParentID)
			from @Documents.nodes('/Documents') as Data(X)     

			SELECT   @DocIDValue=0    
			SELECT   @DocIDValue = DOCID from @tblExistingSIVXML where ID=@ICNT    

			SET @DocIDValue = ISNULL(@DocIDValue,0)    
			if exists(SELECT IsBillwise FROM ACC_Accounts with(nolock) WHERE AccountID=@RentRecID and IsBillwise=1)    
			begin    
				IF EXISTS(select Value from ADM_GLOBALPREFERENCES with(nolock) where NAME  = 'On')    
				BEGIN    
					set @tempxml=@DocXml    
					select @tempAmt=sum(X.value('@Amount',' float'))
					from @tempxml.nodes('/DocumentXML/Row/AccountsXML/Accounts') as Data(X)            
					set @BillWiseXMl='<BillWise> <Row DocSeqNo="1" AccountID="'+convert(nvarchar,@RentRecID)+'" AmountFC="'+CONVERT(nvarchar,@tempAmt)+'" AdjAmount="'+CONVERT(nvarchar,@tempAmt)+'" 
					AdjCurrID="1" AdjExchRT="1" IsNewReference="1" Narration="" IsDocPDC="0" ></Row></BillWise>'    
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

			set @Prefix=''
			EXEC [sp_GetDocPrefix] @DocXml,@ContractDate,@RcptCCID,@Prefix   output

			set @DocXml=Replace(@DocXml,'<RowHead/>','')
			set @DocXml=Replace(@DocXml,'</DocumentXML>','')
			set @DocXml=Replace(@DocXml,'<DocumentXML>','')

			EXEC @return_value = [dbo].[spDOC_SetTempInvDoc]      
			@CostCenterID = @RcptCCID,      
			@DocID = @DocIDValue,      
			@DocPrefix = @Prefix,      
			@DocNumber = N'',      
			@DocDate = @ContractDate,      
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

			SET @SalesInv  = @return_value      

			set @Documents=null
			SELECT @Documents = Recurxml FROM #tblListSIVTemp WHERE  ID = @ICNT  
			
			set @Occurrence=0
			SELECT  @Occurrence=count(X.value ('@Date', 'Datetime' ))
			from @Documents.nodes('/recurXML/Row') as Data(X)
			if(@Occurrence>0)
			BEGIN		 
				set @ScheduleID=0
				select @ScheduleID=ScheduleID from COM_CCSchedules WITH(NOLOCK)
				where CostCenterID=@RcptCCID and NodeID=@SalesInv
				if(@ScheduleID=0)
				BEGIN
					INSERT INTO COM_Schedules(Name,StatusID,FreqType,FreqInterval,FreqSubdayType,FreqSubdayInterval,
					FreqRelativeInterval,FreqRecurrenceFactor,StartDate,EndDate,Occurrence,RecurAutoPost,
					CompanyGUID,GUID,CreatedBy,CreatedDate)
					VALUES('Contract',1,0,0,0,0,0,0,@StartDate,@EndDate,@Occurrence,0,
							@CompanyGUID,NEWID(),@UserName,@Dt)
					SET @ScheduleID=SCOPE_IDENTITY()  

					INSERT INTO COM_CCSchedules(CostCenterID,NodeID,ScheduleID,CreatedBy,CreatedDate)
					VALUES(@RcptCCID,@SalesInv,@ScheduleID,@UserName,@Dt)
					
					INSERT INTO COM_UserSchedules(ScheduleID,GroupID,RoleID,UserID,CreatedBy,CreatedDate)
					values(@ScheduleID,0,0,@UserID,@UserName,@Dt)
				END
				ELSE
				BEGIN
					update COM_Schedules
					set StartDate=@StartDate,EndDate=@EndDate,Occurrence=@Occurrence
					where ScheduleID=@ScheduleID
				END
				
				delete from COM_SchEvents
				where ScheduleID=@ScheduleID
				
				INSERT INTO COM_SchEvents(ScheduleID,EventTime,Message,StatusID,StartFlag,StartDate,EndDate,CompanyGUID,[GUID],CreatedBy,CreatedDate,
				SubCostCenterID,NODEID,AttachmentID)
				select @ScheduleID,CONVERT(FLOAT,X.value ('@Date', 'Datetime' )),'Contract',1,0,CONVERT(FLOAT,X.value ('@Date', 'Datetime' )),CONVERT(FLOAT,X.value ('@Date', 'Datetime' )),
				@CompanyGUID,NEWID(),@UserName,CONVERT(FLOAT,GETDATE()),@ParentID,@SNO,X.value ('@Seq', 'INT' )
				from @Documents.nodes('/recurXML/Row') as Data(X)	
			END

			IF(@DocIDValue = 0 )    
			BEGIN    
				INSERT INTO [REN_ContractDocMapping]([ContractID],[Type],[Sno],DocID,CostcenterID,IsAccDoc,DocType,ContractCCID)
				values(@ContractID,1,@tempSno,@SalesInv,@RcptCCID,0,4,95)
			END      
			else    
			begin    
				update [REN_ContractDocMapping]    
				set [Sno]= @tempSno
				where [ContractID]=@ContractID and DocID=@DocIDValue    
			end
		END    
       
		IF(@totalPreviousSIVXML > @CNT)    
		BEGIN    
			WHILE(@CNT <  @totalPreviousSIVXML)    
			BEGIN    

				SET @CNT = @CNT+1    
				SELECT @DELETEDOCID = DOCID FROM @tblExistingSIVXML WHERE ID = @CNT    

				SELECT @DELETECCID = COSTCENTERID FROM dbo.INV_DocDetails   with(nolock)    
				WHERE DOCID = @DELETEDOCID    

				EXEC @return_value = [spDOC_DeleteInvDocument]      
				@CostCenterID = @DELETECCID,      
				@DocPrefix = '',      
				@DocNumber = '',  
				@DOCID = @DELETEDOCID,
				@UserID = 1,      
				@UserName = N'ADMIN',      
				@LangID = 1,
				@RoleID=1

				DELETE FROM REN_ContractDocMapping 
				WHERE CONTRACTID = @CONTRACTID  AND DOCID =  @DELETEDOCID and DOCTYPE =4 AND ContractCCID = 95    
				
				set @ScheduleID=0
				select @ScheduleID=ScheduleID from COM_CCSchedules WITH(NOLOCK)
				where CostCenterID=@DELETECCID and NodeID=@DELETEDOCID
				
				if(@ScheduleID>0)
				BEGIN
					delete from COM_CCSchedules
					where ScheduleID=@ScheduleID
					
					delete from COM_UserSchedules
					where ScheduleID=@ScheduleID
					
					delete from COM_SchEvents
					where ScheduleID=@ScheduleID
					
					delete from COM_Schedules
					where ScheduleID=@ScheduleID
				END
			END
		END 
	END       
     		
	IF(@RcptXML is not null and @RcptXML<>'')      
	BEGIN      

		SET @XML = @RcptXML    

		CREATE TABLE #tblListReceiptXML(ID int identity(1,1),TRANSXML NVARCHAR(MAX)  , AccountType NVARCHAR(100) ,Documents NVARCHAR(200) )          
		INSERT INTO #tblListReceiptXML        
		SELECT  CONVERT(NVARCHAR(MAX),  X.query('DocumentXML'))   ,  CONVERT(NVARCHAR(MAX),  X.query('AccountType')), CONVERT(NVARCHAR(200), X.query('Documents') )                 
		from @XML.nodes('/ReceiptXML/ROWS') as Data(X)        

		SELECT @AA = TRANSXML , @AccountType = AccountType , @Documents = Documents  FROM #tblListReceiptXML WHERE  ID = 1      

		SELECT   @AccValue =  X.value ('@DD', 'NVARCHAR(100)' ) ,@IsRes=X.value('@IsRes', 'BIT' )            
		from @AccountType.nodes('/AccountType') as Data(X)     

		if not(@IsRes is not null and @IsRes=1 and @LinkedQuotationID is not null and @LinkedQuotationID>0)
		BEGIN
			set @DocIDValue=0    

			select @DocIDValue=DOCID from  [REN_ContractDocMapping] with(nolock) 
			where contractid=@ContractID and Doctype =1 AND ContractCCID = 95    

			IF(@AccValue = 'BANK')    
			BEGIN    
				select @RcptCCID=CONVERT(int,Value) from COM_CostCenterPreferences WITH(nolock)      
				where CostCenterID=95 and Name='ContractPostDatedReceipt'      
			END    
			ELSE  IF(@AccValue = 'CASH')    
			BEGIN    
				select @RcptCCID=CONVERT(int,Value) from COM_CostCenterPreferences WITH(nolock)      
				where CostCenterID=95 and Name='ContractCashReceipt'      
			END    
			ELSE  IF(@AccValue = 'JV')    
			BEGIN    
				select @RcptCCID=CONVERT(int,Value) from COM_CostCenterPreferences WITH(nolock)      
				where CostCenterID=95 and Name='ContractJVReceipt'      
			END    

			set @DELETECCID=0    
			IF(@DocIDValue>0)    
			BEGIN    
				SELECT  @DELETECCID = COSTCENTERID FROM dbo.ACC_DocDetails  with(nolock)     
				WHERE DOCID = @DocIDValue    
			END     
			if(@DocIDValue>0 AND @DELETECCID <> 0 and @RcptCCID<>@DELETECCID)    
			begin    
				EXEC @return_value = [dbo].[spDOC_DeleteAccDocument]      
				@CostCenterID = @DELETECCID,      
				@DocPrefix = '',      
				@DocNumber = '',  
				@DOCID = @DocIDValue,
				@UserID = 1,      
				@UserName = N'ADMIN',      
				@LangID = 1,
				@RoleID=1

				DELETE FROM REN_ContractDocMapping 
				WHERE CONTRACTID = @CONTRACTID  AND DOCID =  @DocIDValue and DOCTYPE =1 AND ContractCCID = 95    

				set @DocIDValue=0       
			end    

			SET @DocXml = convert(nvarchar(max), @AA)      
			SET @DocIDValue = ISNULL(@DocIDValue,0)    
			if(@DocIDValue = '')    
			set @DocIDValue=0    
			SET @ICNT = 0      
			WHILE(@ICNT =0)      
			BEGIN      
				SET @ICNT =@ICNT+1      

				set @TempDocIDValue =0
				SELECT   @TempDocIDValue =  X.value('@DocID', 'NVARCHAR(100)'),@DDValue=ISNULL(X.value('@DDate', 'DateTime'),@ContractDate)
				from @Documents.nodes('/Documents') as Data(X)     
				set @BillWiseXMl=''
				if(@TempDocIDValue is not null and @TempDocIDValue<>'' and convert(bigint,@TempDocIDValue)>0 and @TempDocIDValue= @DocIDValue)
				BEGIN
					set @tempxml=@DocXml    
					select @tempAmt=X.value ('@Amount', 'FLOAT' )            
					from @tempxml.nodes('/DocumentXML/Row/Transactions') as Data(X)  
					if exists(select DOCID from Acc_docdetails with(nolock) where  DOCID=@DocIDValue and Amount=@tempAmt and StatusID in(369,429) and DocumentType=19)
						continue;
					if exists(select DOCID from Acc_docdetails with(nolock) 
					where  DOCID=@DocIDValue and Amount=@tempAmt and CreditAccount=@lft)
					BEGIN
						set @BillWiseXMl='<XML DontChangeBillwise="1" ></XML>'
					END		
				END 
				set @Prefix=''
				EXEC [sp_GetDocPrefix] @DocXml,@DDValue,@RcptCCID,@Prefix   output

				EXEC @return_value = [dbo].[spDOC_SetTempAccDocument]      
				@CostCenterID = @RcptCCID,      
				@DocID = @DocIDValue,      
				@DocPrefix = @Prefix,      
				@DocNumber =1,      
				@DocDate = @DDValue,      
				@DueDate = NULL,      
				@BillNo = @SNO,      
				@InvDocXML = @DocXml,      
				@NotesXML = N'',      
				@AttachmentsXML = N'',      
				@ActivityXML  = @BillWiseXMl,     
				@IsImport = 0,      
				@LocationID = @ContractLocationID,      
				@DivisionID = @ContractDivisionID,      
				@WID = 0,      
				@RoleID = @RoleID,      
				@RefCCID = 95,    
				@RefNodeid = @ContractID ,    
				@CompanyGUID = @CompanyGUID,      
				@UserName = @UserName,      
				@UserID = @UserID,      
				@LangID = @LangID      

				SET @BnkRcpt  = @return_value 
				
				IF(@DocIDValue = 0 )    
				BEGIN    
					INSERT INTO [REN_ContractDocMapping]([ContractID],[Type],[Sno],DocID,CostcenterID,IsAccDoc,DocType,ContractCCID)      
					VALUES(@ContractID,2,1,@BnkRcpt,@RcptCCID,1,1,95)      
				END     
			END
		END	
		DROP TABLE #tblListReceiptXML    
	END      

        
    declare  @tblExistingPDRcptXML TABLE (ID int identity(1,1),DOCID bigint)           
    insert into @tblExistingPDRcptXML     
    select DOCID from  [REN_ContractDocMapping] with(nolock)   
    where contractid=@ContractID and Doctype =2 AND ContractCCID = 95 
    order by sno   
    declare @totalPreviousPDRcptXML bigint    
    select @CNT=0,@totalPreviousPDRcptXML=COUNT(id) from @tblExistingPDRcptXML     
   
	IF(@PDRcptXML is not null and @PDRcptXML<>'')      
	BEGIN      
	   
		DECLARE @MPSNO NVARCHAR(MAX)       

		SET @XML =   @PDRcptXML       
		CREATE TABLE #tblListPDR(ID int identity(1,1),TRANSXML NVARCHAR(MAX) , DateXML NVARCHAR(MAX), AccountType NVARCHAR(100) ,Documents NVARCHAR(200) )          
		INSERT INTO #tblListPDR        
		SELECT  CONVERT(NVARCHAR(MAX),  X.query('DocumentXML')) ,  CONVERT(NVARCHAR(MAX),  X.query('ChequeDocDate')) ,  CONVERT(NVARCHAR(MAX),  X.query('AccountType')) ,  CONVERT(NVARCHAR(200),  X.query('Documents'))                  
		from @XML.nodes('/PDR/ROWS') as Data(X)        

		SELECT @ICNT = 0,@CNT = COUNT(ID) FROM #tblListPDR      
   
		WHILE(@ICNT < @CNT)      
		BEGIN      
			SET @ICNT =@ICNT+1      

			SELECT @AA = TRANSXML , @DateXML = DateXML , @AccountType = AccountType , @Documents = Documents  
			FROM #tblListPDR WHERE  ID = @ICNT      

			SELECT   @AccValue =  X.value ('@DD', 'NVARCHAR(100)' )            
			from @AccountType.nodes('/AccountType') as Data(X)      

			set @DocIDValue=0    
			SELECT @DocIDValue = DOCID   FROM @tblExistingPDRcptXML WHERE  ID = @ICNT     

			SET @DocIDValue = ISNULL(@DocIDValue,0)    
          
			IF(@AccValue = 'BANK')    
			BEGIN    
				select @RcptCCID=CONVERT(int,Value) from COM_CostCenterPreferences WITH(nolock)      
				where CostCenterID=95 and Name='ContractPostDatedReceipt'      
			END    
			ELSE  IF(@AccValue = 'CASH')    
			BEGIN    
				select @RcptCCID=CONVERT(int,Value) from COM_CostCenterPreferences WITH(nolock)      
				where CostCenterID=95 and Name='ContractCashReceipt'      
			END    
			ELSE  IF(@AccValue = 'JV')    
			BEGIN    
				select @RcptCCID=CONVERT(int,Value) from COM_CostCenterPreferences WITH(nolock)      
				where CostCenterID=95 and Name='ContractJVReceipt'      
			END    

			Set @DocXml = convert(nvarchar(max), @AA)      

			set @DELETECCID=0    
			
			IF(@DocIDValue>0)    
			BEGIN    
				SELECT  @DELETECCID = COSTCENTERID FROM dbo.ACC_DocDetails  with(nolock)     
				WHERE DOCID = @DocIDValue    
			END 
			    
			if(@DocIDValue >0 AND @DELETECCID <> 0 and @RcptCCID<>@DELETECCID)    
			begin   
				EXEC @return_value = [dbo].[spDOC_DeleteAccDocument]      
				@CostCenterID = @DELETECCID,      
				@DocPrefix = '',      
				@DocNumber = '',  
				@DOCID = @DocIDValue,      
				@UserID = 1,      
				@UserName = N'ADMIN',      
				@LangID = 1,
				@RoleID=1

				DELETE FROM REN_ContractDocMapping WHERE CONTRACTID = @CONTRACTID  AND DOCID =  @DocIDValue and DOCTYPE =2 AND ContractCCID = 95    

				set @DocIDValue=0       
			end    
     
			set @TempDocIDValue =0
			SELECT   @TempDocIDValue =  X.value ('@DocID', 'NVARCHAR(100)'),@DDValue=ISNULL(X.value ('@DDate', 'DateTime'),@ContractDate)            
			from @Documents.nodes('/Documents') as Data(X)     
			set @BillWiseXMl=''
			if(@TempDocIDValue is not null and @TempDocIDValue<>'' and convert(bigint,@TempDocIDValue)>0 and @TempDocIDValue= @DocIDValue)
			BEGIN
				set @tempxml=@DocXml    
				select @tempAmt=X.value ('@Amount', 'FLOAT'),@lft =X.value ('@CreditAccount', 'BIGINT')
				from @tempxml.nodes('/DocumentXML/Row/Transactions') as Data(X)  
				if exists(select DOCID from Acc_docdetails with(nolock) where  DOCID=@DocIDValue and Amount=@tempAmt and StatusID in(369,429) and DocumentType=19)
					continue;
				if exists(select DOCID from Acc_docdetails with(nolock) 
				where  DOCID=@DocIDValue and Amount=@tempAmt and CreditAccount=@lft)
				BEGIN
					set @BillWiseXMl='<XML DontChangeBillwise="1" ></XML>'
				END	
			END  
      
			set @Prefix=''
			EXEC [sp_GetDocPrefix] @DocXml,@DDValue,@RcptCCID,@Prefix   output

			EXEC @return_value = [dbo].[spDOC_SetTempAccDocument]      
			@CostCenterID = @RcptCCID,      
			@DocID = @DocIDValue,      
			@DocPrefix =@Prefix,      
			@DocNumber =1,      
			@DocDate = @DDValue,				        
			@DueDate = NULL,      
			@BillNo = @SNO,      
			@InvDocXML = @DocXml,      
			@NotesXML = N'',      
			@AttachmentsXML = N'',      
			@ActivityXML  = @BillWiseXMl,     
			@IsImport = 0,      
			@LocationID = @ContractLocationID,      
			@DivisionID = @ContractDivisionID,      
			@WID = 0,      
			@RoleID = @RoleID,      
			@RefCCID = 95,    
			@RefNodeid = @ContractID ,    
			@CompanyGUID = @CompanyGUID,      
			@UserName = @UserName,      
			@UserID = @UserID,      
			@LangID = @LangID      

			SET @PDRcpt  = @return_value      
         
			set @XML = @AA      

			IF(@DocIDValue = 0 )    
			BEGIN    
				INSERT INTO  [REN_ContractDocMapping]([ContractID],[Type],[Sno],DocID,CostcenterID,IsAccDoc,DocType,ContractCCID)      
				values(@ContractID,2,@ICNT +1,@PDRcpt,@RcptCCID,1,2,95  )        
			END    
		END        
	END      
      
   IF(@totalPreviousPDRcptXML > @CNT)    
   BEGIN           
  WHILE(@CNT <  @totalPreviousPDRcptXML)    
  BEGIN    
          
   SET @CNT = @CNT+1    
   SELECT @DELETEDOCID = DOCID FROM @tblExistingPDRcptXML WHERE ID = @CNT    
       
   SELECT  @DELETECCID = COSTCENTERID FROM dbo.ACC_DocDetails with(nolock)      
   WHERE DOCID = @DELETEDOCID    
      
     EXEC @return_value = [dbo].[spDOC_DeleteAccDocument]      
    @CostCenterID = @DELETECCID,      
    @DocPrefix = '',      
    @DocNumber = '',  
    @DOCID = @DELETEDOCID,      
    @UserID = 1,      
    @UserName = N'ADMIN',      
    @LangID = 1,
    @RoleID=1
           
     DELETE FROM REN_ContractDocMapping WHERE CONTRACTID = @CONTRACTID  AND DOCID =  @DELETEDOCID and DOCTYPE =2 AND ContractCCID = 95    
         
    END    
  END    
    SELECT @CNT=0    
        
   IF(@ComRcptXML is not null and @ComRcptXML<>'')      
   BEGIN      
      
  SET @XML =   @ComRcptXML       
        
  declare  @tblExistingComRcptXML TABLE (ID int identity(1,1),DOCID bigint)           
  insert into @tblExistingComRcptXML     
  select DOCID from  [REN_ContractDocMapping]   with(nolock) 
  where contractid=@ContractID and Doctype =3 AND ContractCCID = 95    
  declare @totalPreviousComRcptXML bigint    
  select @totalPreviousComRcptXML=COUNT(id) from @tblExistingComRcptXML     
      
      
  CREATE TABLE #tblListCOM(ID int identity(1,1),TRANSXML NVARCHAR(MAX) , DateXML NVARCHAR(MAX) , AccountType NVARCHAR(100),Documents NVARCHAR(200) )            
  INSERT INTO #tblListCOM        
  SELECT  CONVERT(NVARCHAR(MAX),  X.query('DocumentXML')) ,  CONVERT(NVARCHAR(MAX),  X.query('ChequeDocDate'))  ,  CONVERT(NVARCHAR(MAX),  X.query('AccountType'))  ,  CONVERT(NVARCHAR(200),  X.query('Documents'))                    
  from @XML.nodes('/PARTICULARS//ROWS') as Data(X)        
    
  SELECT @CNT = COUNT(ID) FROM #tblListCOM      
    
  SET @ICNT = 0      
   WHILE(@ICNT < @CNT)      
   BEGIN      
   SET @ICNT =@ICNT+1      
    
   SELECT @AA = TRANSXML , @DateXML = DateXML, @AccountType = AccountType  , @Documents = Documents   FROM #tblListCOM WHERE  ID = @ICNT      
    
   Set @DocXml = convert(nvarchar(max), @AA)      
    
   --Set @DDXML = convert(nvarchar(max), @DateXML)      
    
    
   SELECT   @DocIDValue=0    
   SELECT   @DocIDValue = DOCID from @tblExistingComRcptXML where ID=@ICNT    
    
   SET @DocIDValue = ISNULL(@DocIDValue,0)    
    
   SELECT   @AccValue =  X.value ('@DD', 'NVARCHAR(100)' )            
   from @AccountType.nodes('/AccountType') as Data(X)      
       
   IF(@AccValue = 'BANK')    
   BEGIN    
    declare @prefVal nvarchar(50)    
    set @prefVal=''    
    select @prefVal=Value from COM_CostCenterPreferences WITH(nolock)      
    where CostCenterID=95 and Name='ParticularsPDC'      
    if(@prefVal <>'' and @prefVal='True')    
    begin    
     select @RcptCCID=CONVERT(int,Value) from COM_CostCenterPreferences WITH(nolock)      
     where CostCenterID=95 and Name='ContractPostDatedReceipt'      
    end    
    else    
    begin    
     select @RcptCCID=CONVERT(int,Value) from COM_CostCenterPreferences WITH(nolock)      
     where CostCenterID=95 and Name='ContractBankReceipt'      
    end     
   END    
   ELSE     
   BEGIN    
    select @RcptCCID=CONVERT(int,Value) from COM_CostCenterPreferences WITH(nolock)      
    where CostCenterID=95 and Name='ContractCashReceipt'      
   END    
       
       
	set @DELETECCID=0    
	IF(@DocIDValue>0)    
	BEGIN    
		SELECT  @DELETECCID = COSTCENTERID FROM dbo.ACC_DocDetails with(nolock)      
		WHERE DOCID = @DocIDValue    
	END  
	  
	if(@DocIDValue>0 AND @DELETECCID <> 0 and @RcptCCID<>@DELETECCID)    
	begin    
		EXEC @return_value = [dbo].[spDOC_DeleteAccDocument]      
		@CostCenterID = @DELETECCID,      
		@DocPrefix = '',      
		@DocNumber = '',  
		@DOCID = @DocIDValue,      
		@UserID = 1,      
		@UserName = N'ADMIN',      
		@LangID = 1,
		@RoleID=1

		DELETE FROM REN_ContractDocMapping 
		WHERE CONTRACTID = @CONTRACTID  AND DOCID =  @DocIDValue and DOCTYPE =3 AND ContractCCID = 95    

		set @DocIDValue=0       
	end    
    
	set @Prefix=''
	EXEC [sp_GetDocPrefix] @DocXml,@ContractDate,@RcptCCID,@Prefix   output

	EXEC @return_value = [dbo].[spDOC_SetTempAccDocument]      
	@CostCenterID = @RcptCCID,      
	@DocID = @DocIDValue,      
	@DocPrefix = @Prefix,      
	@DocNumber =1,      
	@DocDate = @ContractDate,        
	@DueDate = NULL,      
	@BillNo = @SNO,      
	@InvDocXML = @DocXml,      
	@NotesXML = N'',      
	@AttachmentsXML = N'',     
	@ActivityXML  = N'',      
	@IsImport = 0,      
	@LocationID = @ContractLocationID,      
	@DivisionID = @ContractDivisionID,      
	@WID = 0,      
	@RoleID = @RoleID,      
	@RefCCID = 95,    
	@RefNodeid = @ContractID ,    
	@CompanyGUID = @CompanyGUID,      
	@UserName = @UserName,      
	@UserID = @UserID,      
	@LangID = @LangID      
         
    SET @CommRcpt  = @return_value      
    
    set @XML = @AA      
         
	IF(@DocIDValue = 0 )    
	BEGIN    
		INSERT INTO [REN_ContractDocMapping]([ContractID],[Type],[Sno],DocID,CostcenterID,IsAccDoc,DocType,ContractCCID    )      
		SELECT  @ContractID,1,X.value('@CONTRACTSNO','int'),@CommRcpt,@RcptCCID,1,3,95        
		FROM @XML.nodes('/DocumentXML/Row/Transactions') as Data(X)      
	END      
END      
       
    IF(@totalPreviousComRcptXML > @CNT)    
    BEGIN    
		WHILE(@CNT <  @totalPreviousComRcptXML)    
		BEGIN    
			SET @CNT = @CNT+1    
			SELECT @DELETEDOCID = DOCID FROM @tblExistingComRcptXML WHERE ID = @CNT    

			SELECT @DELETECCID = COSTCENTERID FROM dbo.ACC_DocDetails with(nolock)   
			WHERE DOCID = @DELETEDOCID    

			EXEC @return_value = [dbo].[spDOC_DeleteAccDocument]      
			@CostCenterID = @DELETECCID,      
			@DocPrefix = '',      
			@DocNumber = '',  
			@DOCID = @DELETEDOCID,
			@UserID = 1,      
			@UserName = N'ADMIN',      
			@LangID = 1,
			@RoleID=1

			DELETE FROM REN_ContractDocMapping 
			WHERE CONTRACTID = @CONTRACTID  AND DOCID =  @DELETEDOCID and DOCTYPE =3 AND ContractCCID = 95    
		END    
    END    
END      
         
       
      
	IF(@RentRcptXML is not null and @RentRcptXML<>'')      
	BEGIN   
		select @RcptCCID=CONVERT(int,Value) from COM_CostCenterPreferences WITH(nolock)      
		where CostCenterID=95 and Name='ContractRentReceipt'      
		SET @XML =   @RentRcptXML       
	   
		declare  @tblExistingRcs TABLE (ID int identity(1,1),DOCID bigint)           
		insert into @tblExistingRcs     
		select DOCID from  [REN_ContractDocMapping]  with(nolock)  
		where contractid=@ContractID and DOCTYPE =5 AND ContractCCID = 95    
		declare @totalPreviousRcts bigint    
		select @totalPreviousRcts=COUNT(id) from @tblExistingRcs     
       
  CREATE TABLE #tblList(ID int identity(1,1),TRANSXML NVARCHAR(MAX) , DateXML NVARCHAR(MAX))           
  INSERT INTO #tblList        
  SELECT  CONVERT(NVARCHAR(MAX),  X.query('DocumentXML') ) ,  CONVERT(NVARCHAR(MAX),  X.query('ChequeDocDate'))          
  from @XML.nodes('/RENTRCT/ROWS') as Data(X)        
       
  SELECT @CNT = COUNT(ID) FROM #tblList      
   SET @ICNT = 0      
  WHILE(@ICNT < @CNT)      
  BEGIN      
   SET @ICNT =@ICNT+1      
       
   SELECT @AA = TRANSXML , @DateXML = DateXML  FROM #tblList WHERE  ID = @ICNT      
       
   if( @totalPreviousRcts>=@ICNT)    
   begin    
  SELECT @DocIDValue = DOCID   FROM @tblExistingRcs WHERE  ID = @ICNT      
   end    
   else    
   begin    
  SELECT @DocIDValue=0    
   end    
   --Set @DDXML = convert(nvarchar(max), @DateXML)      
        
   SELECT   @DDValue =  X.value ('@DD', 'Datetime' )            
   from @DateXML.nodes('/ChequeDocDate') as Data(X)      
         
   Set @DocXml = convert(nvarchar(max), @AA) 
        set @Prefix=''
     EXEC [sp_GetDocPrefix] @DocXml,@ContractDate,@RcptCCID,@Prefix   output
     
   EXEC @return_value = [dbo].[spDOC_SetTempAccDocument]      
    @CostCenterID = @RcptCCID,      
    @DocID = @DocIDValue,       
    @DocPrefix = @Prefix,      
    @DocNumber =1,      
   -- @DocDate = @ContractDate,       
    @DocDate = @DDValue,       
    @DueDate = NULL,      
    @BillNo = @SNO,      
    @InvDocXML = @DocXml,       
    @NotesXML = N'',      
    @AttachmentsXML = N'',     
    @ActivityXML  = N'',      
    @IsImport = 0,      
    @LocationID = @ContractLocationID,      
    @DivisionID = @ContractDivisionID,      
    @WID = 0,      
    @RoleID = @RoleID,      
    @RefCCID = 95,    
    @RefNodeid = @ContractID ,    
    @CompanyGUID = @CompanyGUID,      
    @UserName = @UserName,      
    @UserID = @UserID,      
    @LangID = @LangID      

		SET @RentRcpt  = @return_value      

		set @XML = @AA      
        
        SELECT @type=ISNULL(X.value('@NodeID','int'),1),@fldsno=X.value('@CONTRACTSNO','int')
		FROM @XML.nodes('/DocumentXML/Row/Transactions') as Data(X)  
		
		IF(@DocIDValue = 0 )    
		BEGIN    
			INSERT INTO [REN_ContractDocMapping]([ContractID],[Type],[Sno],DocID,CostcenterID,IsAccDoc,DocType,ContractCCID)              
			values(@ContractID,@type,@fldsno,@RentRcpt,@RcptCCID,1,5,95)			       
		END    
		ELSE
		BEGIN
			update [REN_ContractDocMapping]
			set [Type]=@type,[Sno]=@fldsno
			where [ContractID]=@ContractID and DocID=@DocIDValue
		END
	END      
       
   IF(@totalPreviousRcts > @CNT)    
   BEGIN    
          
    WHILE(@CNT <  @totalPreviousRcts)    
    BEGIN    
         
  SET @CNT = @CNT+1    
  SELECT @DELETEDOCID = DOCID FROM @tblExistingRcs WHERE ID = @CNT    
      
  SELECT @DELETECCID = COSTCENTERID FROM dbo.ACC_DocDetails    with(nolock)   
  WHERE DOCID = @DELETEDOCID    
        
    EXEC @return_value = [dbo].[spDOC_DeleteAccDocument]      
   @CostCenterID = @DELETECCID,      
   @DocPrefix = '',      
    @DocNumber = '',  
    @DOCID = @DELETEDOCID,      
   @UserID = 1,      
   @UserName = N'ADMIN',      
   @LangID = 1,
   @RoleID=1
          
    DELETE FROM REN_ContractDocMapping WHERE CONTRACTID = @CONTRACTID  AND DOCID =  @DELETEDOCID and DOCTYPE =5 AND ContractCCID= 95     
        
   END    
   END    
       
 END   
 
     
    END     
    ELSE  IF (@CostCenterID = 104)    
    BEGIN    
        
     IF(@SIVXML is not null and @SIVXML<>'')      
   BEGIN      
  select @ParentID=CONVERT(int,Value) from COM_CostCenterPreferences WITH(nolock)      
  where CostCenterID=104 and Name='PurchasePInvoice'      
  SET @XML = @SIVXML    
         
  declare  @tblExistingPIVXML TABLE (ID int identity(1,1),DOCID bigint)           
  insert into @tblExistingPIVXML     
  select DOCID from  [REN_ContractDocMapping] with(nolock)   
  where contractid=@ContractID and Doctype =4 AND ContractCCID = 104    
  declare @totalPreviousPIVXML bigint    
  select @totalPreviousPIVXML=COUNT(id) from @tblExistingPIVXML     
   
   CREATE TABLE #tblListPIVTemp(ID int identity(1,1),TRANSXML NVARCHAR(MAX) ,Documents NVARCHAR(200),Recurxml NVARCHAR(MAX))            
   INSERT INTO #tblListPIVTemp        
   SELECT  CONVERT(NVARCHAR(MAX),  X.query('DocumentXML'))   ,  CONVERT(NVARCHAR(200),X.query('Documents')),CONVERT(NVARCHAR(MAX),X.query('recurXML')) 
   from @XML.nodes('/PIV//ROWS') as Data(X)        
       
   SELECT @CNT = COUNT(ID) FROM #tblListPIVTemp      
        
   SET @ICNT = 0      
   WHILE(@ICNT < @CNT)      
   BEGIN      
   SET @ICNT =@ICNT+1      
         
   SELECT @AA = TRANSXML , @Documents = Documents    FROM #tblListPIVTemp WHERE  ID = @ICNT      
        
   Set @DocXml = convert(nvarchar(max), @AA)      
        
         
   SELECT   @tempSno =  X.value ('@CONTRACTSNO', 'int' ),@RcptCCID =  ISNULL(X.value ('@CostCenterid', 'int'),@ParentID)            
   from @Documents.nodes('/Documents') as Data(X)      
   
   		SELECT   @DocIDValue=0    
		SELECT   @DocIDValue = DOCID from @tblExistingPIVXML where ID=@ICNT   
    
   SET @DocIDValue = ISNULL(@DocIDValue,0)    
       
   if exists(SELECT IsBillwise FROM ACC_Accounts with(nolock) WHERE AccountID=@RentRecID and IsBillwise=1)    
  begin    
   IF EXISTS(select Value from ADM_GLOBALPREFERENCES with(nolock) where NAME  = 'On')    
   BEGIN    
       
    SET @tempxml =''    
    SET @tempAmt = 0    
    set @tempxml=@DocXml
    
    select @tempAmt=sum(X.value('@Amount',' float'))
	from @tempxml.nodes('/DocumentXML/Row/AccountsXML/Accounts') as Data(X)            
    
    set @BillWiseXMl='<BillWise> <Row DocSeqNo="1" AccountID="'+convert(nvarchar,@RentRecID)+'" AmountFC="-'+CONVERT(nvarchar,@tempAmt)+'" AdjAmount="-'+CONVERT(nvarchar,@tempAmt)+'" AdjCurrID="1" AdjExchRT="1" IsNewReference="1" Narration="" IsDocPDC="0"
  
 ></Row></BillWise>'    
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
         set @Prefix=''
     EXEC [sp_GetDocPrefix] @DocXml,@ContractDate,@RcptCCID,@Prefix   output
   
   	set @DocXml=Replace(@DocXml,'<RowHead/>','')
	set @DocXml=Replace(@DocXml,'</DocumentXML>','')
	set @DocXml=Replace(@DocXml,'<DocumentXML>','')

    EXEC @return_value = [dbo].[spDOC_SetTempInvDoc]      
  @CostCenterID = @RcptCCID,      
  @DocID = @DocIDValue,      
  @DocPrefix = @Prefix,      
  @DocNumber = N'',      
  @DocDate = @ContractDate,      
  @DueDate = NULL,      
  @BillNo = @SNO,      
  @InvDocXML =@DocXml,      
  @BillWiseXML = @BillWiseXMl,      
  @NotesXML = N'',      
  @AttachmentsXML = N'',    
  @ActivityXML = N'',       
  @IsImport = 0,      
  @LocationID = @LocationID,      
  @DivisionID = @DivisionID ,      
  @WID = 0,      
  @RoleID = @RoleID,      
  @DocAddress = N'',      
  @RefCCID = 104,    
  @RefNodeid  = @ContractID,    
  @CompanyGUID = @CompanyGUID,      
  @UserName = @UserName,      
  @UserID = @UserID,      
  @LangID = @LangID       
      
   SET @SalesInv  = @return_value      
      
   
		set @Documents=null
		SELECT @Documents = Recurxml    FROM #tblListPIVTemp WHERE  ID = @ICNT  
		
		set @Occurrence=0
		SELECT  @Occurrence=count(X.value ('@Date', 'Datetime' ))
		from @Documents.nodes('/recurXML/Row') as Data(X)
		if(@Occurrence>0)
		BEGIN		 
			set @ScheduleID=0
			select @ScheduleID=ScheduleID from COM_CCSchedules WITH(NOLOCK)
			where CostCenterID=@RcptCCID and NodeID=@SalesInv
			if(@ScheduleID=0)
			BEGIN
				INSERT INTO COM_Schedules(Name,StatusID,FreqType,FreqInterval,FreqSubdayType,FreqSubdayInterval,
				FreqRelativeInterval,FreqRecurrenceFactor,StartDate,EndDate,Occurrence,RecurAutoPost,
				CompanyGUID,GUID,CreatedBy,CreatedDate)
				VALUES('Purchase Contract',1,0,0,0,0,0,0,@StartDate,@EndDate,@Occurrence,0,
						@CompanyGUID,NEWID(),@UserName,@Dt)
				SET @ScheduleID=SCOPE_IDENTITY()  

				INSERT INTO COM_CCSchedules(CostCenterID,NodeID,ScheduleID,CreatedBy,CreatedDate)
				VALUES(@RcptCCID,@SalesInv,@ScheduleID,@UserName,@Dt)
				
				INSERT INTO COM_UserSchedules(ScheduleID,GroupID,RoleID,UserID,CreatedBy,CreatedDate)
				values(@ScheduleID,0,0,@UserID,@UserName,@Dt)	
			END
			ELSE
			BEGIN
				update COM_Schedules
				set StartDate=@StartDate,EndDate=@EndDate,Occurrence=@Occurrence
				where ScheduleID=@ScheduleID
			END
			
			delete from COM_SchEvents
			where ScheduleID=@ScheduleID
			
			INSERT INTO COM_SchEvents(ScheduleID,EventTime,Message,StatusID,StartFlag,StartDate,EndDate,CompanyGUID,[GUID],CreatedBy,CreatedDate,
			SubCostCenterID,NODEID,AttachmentID)
			select @ScheduleID,CONVERT(FLOAT,X.value ('@Date', 'Datetime' )),'Purchase Contract',1,0,CONVERT(FLOAT,X.value ('@Date', 'Datetime' )),CONVERT(FLOAT,X.value ('@Date', 'Datetime' )),
			@CompanyGUID,NEWID(),@UserName,CONVERT(FLOAT,GETDATE()),@ParentID,@SNO,X.value ('@Seq', 'INT' )
			from @Documents.nodes('/recurXML/Row') as Data(X)
			
		END
  set @XML = @AA      
         
   --UPDATE INV_DocDetails    
   --  SET StatusID = @StatusValue    
   --  WHERE DOCID = @return_value    
         
  IF(@DocIDValue = 0 )    
  BEGIN    
    INSERT INTO  [REN_ContractDocMapping]      
      ([ContractID]      
      ,[Type]      
      ,[Sno]      
      ,DocID      
      ,COSTCENTERID    
      ,IsAccDoc     
      ,DocType     
      ,ContractCCID    
      )
      values(@ContractID,1,@tempSno,@SalesInv,@RcptCCID,0,4,104)
     
   END     
    else    
   begin    
   update [REN_ContractDocMapping]    
   set [Sno]=@tempSno    
    where [ContractID]=@ContractID and DocID=@DocIDValue    
   end         
       
       
   END    
       
   IF(@totalPreviousPIVXML > @CNT)    
    BEGIN    
           
  WHILE(@CNT <  @totalPreviousPIVXML)    
  BEGIN    
          
   SET @CNT = @CNT+1    
   SELECT @DELETEDOCID = DOCID FROM @tblExistingPIVXML WHERE ID = @CNT    
       
   SELECT  @DELETECCID = COSTCENTERID FROM dbo.INV_DocDetails   with(nolock)    
   WHERE DOCID = @DELETEDOCID    
         
     EXEC @return_value = [spDOC_DeleteInvDocument]      
    @CostCenterID = @DELETECCID,      
    @DocPrefix = '',      
    @DocNumber = '',  
    @DOCID = @DELETEDOCID,      
    @UserID = 1,      
    @UserName = N'ADMIN',      
    @LangID = 1,
    @RoleID=1
           
     DELETE FROM REN_ContractDocMapping WHERE CONTRACTID = @CONTRACTID  AND DOCID =  @DELETEDOCID and DOCTYPE =4 AND ContractCCID = 104    
       
       set @ScheduleID=0
			select @ScheduleID=ScheduleID from COM_CCSchedules WITH(NOLOCK)
			where CostCenterID=@DELETECCID and NodeID=@DELETEDOCID
			
			if(@ScheduleID>0)
			BEGIN
				delete from COM_CCSchedules
				where ScheduleID=@ScheduleID
				
				delete from COM_UserSchedules
				where ScheduleID=@ScheduleID
				
				delete from COM_SchEvents
				where ScheduleID=@ScheduleID
				
				delete from COM_Schedules
				where ScheduleID=@ScheduleID
			END  
    END    
    END    
  END       
      
	IF(@PDRcptXML is not null and @PDRcptXML<>'')      
	BEGIN      

		set @MPSNO = 0    

		SET @XML =   @PDRcptXML       
		CREATE TABLE #tblListPDP(ID int identity(1,1),TRANSXML NVARCHAR(MAX) , DateXML NVARCHAR(MAX), AccountType NVARCHAR(100) ,Documents NVARCHAR(200) )          
		INSERT INTO #tblListPDP        
		SELECT  CONVERT(NVARCHAR(MAX),  X.query('DocumentXML')) ,  CONVERT(NVARCHAR(MAX),  X.query('ChequeDocDate')) ,  CONVERT(NVARCHAR(MAX),  X.query('AccountType')) ,  CONVERT(NVARCHAR(200),  X.query('Documents'))                  
		from @XML.nodes('/PDPayment/ROWS') as Data(X)        

		DECLARE  @tblExistingPDPayXML TABLE (ID int identity(1,1),DOCID bigint)           
		INSERT INTO @tblExistingPDPayXML     
		SELECT DOCID from  [REN_ContractDocMapping]  with(nolock)  
		WHERE contractid=@ContractID and Doctype =2 AND ContractCCID = 104 
		order by sno
		   
		DECLARE @totalPreviousPDPayXML bigint    
		SELECT @totalPreviousPDPayXML=COUNT(id) from @tblExistingPDPayXML     

		SELECT @CNT = COUNT(ID) FROM #tblListPDP      

		SET @ICNT = 0      
		WHILE(@ICNT < @CNT)      
		BEGIN      
			SET @ICNT =@ICNT+1      

			SELECT @AA = TRANSXML , @DateXML = DateXML , @AccountType = AccountType , @Documents = Documents  FROM #tblListPDP WHERE  ID = @ICNT      

			SELECT   @AccValue =  X.value('@DD', 'NVARCHAR(100)' )            
			from @AccountType.nodes('/AccountType') as Data(X)      

			set @DocIDValue=0    
			SELECT @DocIDValue = DOCID   FROM @tblExistingPDPayXML WHERE  ID = @ICNT     

			SET @DocIDValue = ISNULL(@DocIDValue,0)    

			IF(@AccValue = 'BANK')    
			BEGIN    
				SELECT @RcptCCID=CONVERT(int,Value) from COM_CostCenterPreferences WITH(nolock)      
				WHERE CostCenterID=104 and Name='PurchasePostDatedPayment'      
			END    
			ELSE  IF(@AccValue = 'CASH')    
			BEGIN    
				SELECT @RcptCCID=CONVERT(int,Value) from COM_CostCenterPreferences WITH(nolock)      
				WHERE CostCenterID=104 and Name='PurchaseCashReceipt'       
			END    
			ELSE  IF(@AccValue = 'JV')    
			BEGIN    
				select @RcptCCID=CONVERT(int,Value) from COM_CostCenterPreferences WITH(nolock)      
				where CostCenterID=104 and Name='PurchaseJVReceipt'      
			END    

			Set @DocXml = convert(nvarchar(max), @AA)      

		

			set @DELETECCID=0    
			IF(@DocIDValue>0)    
			BEGIN    
				SELECT  @DELETECCID = COSTCENTERID FROM dbo.ACC_DocDetails   with(nolock)    
				WHERE DOCID = @DocIDValue  
				if(@DELETECCID=0)
				BEGIN
					DELETE FROM REN_ContractDocMapping WHERE CONTRACTID = @CONTRACTID  AND DOCID =  @DocIDValue and DOCTYPE =2 AND ContractCCID = 104
					set @DocIDValue=0        
				END	
			END     
			if(@DocIDValue>0 AND @DELETECCID <> 0 and @RcptCCID<>@DELETECCID)    
			begin    				        
				EXEC @return_value = [dbo].[spDOC_DeleteAccDocument]      
				@CostCenterID = @DELETECCID,      
				@DocPrefix = '',      
				@DocNumber = '',  
				@DOCID = @DocIDValue,
				@UserID = 1,      
				@UserName = N'ADMIN',      
				@LangID = 1,
				@RoleID=1

				DELETE FROM REN_ContractDocMapping WHERE CONTRACTID = @CONTRACTID  AND DOCID =  @DocIDValue and DOCTYPE =2 AND ContractCCID = 104    

				set @DocIDValue=0       
			end  

			set @TempDocIDValue =0
			SELECT   @TempDocIDValue =  X.value('@DocID', 'NVARCHAR(100)' )            
			from @Documents.nodes('/Documents') as Data(X)      

			if(@TempDocIDValue is not null and @TempDocIDValue<>'' and convert(bigint,@TempDocIDValue)>0 and @TempDocIDValue= @DocIDValue)
			BEGIN

				set @tempxml=@DocXml    
				select @tempAmt=X.value ('@Amount', 'FLOAT' )            
				from @tempxml.nodes('/DocumentXML/Row/Transactions') as Data(X)  

				if exists(select DOCID from Acc_docdetails with(nolock) where  DOCID=@DocIDValue and Amount=@tempAmt and StatusID=369 and DocumentType=14)
				continue;
			END 

			set @Prefix=''
			EXEC [sp_GetDocPrefix] @DocXml,@ContractDate,@RcptCCID,@Prefix   output

			EXEC @return_value = [dbo].[spDOC_SetTempAccDocument]      
			@CostCenterID = @RcptCCID,      
			@DocID = @DocIDValue,      
			@DocPrefix = @Prefix,      
			@DocNumber =1,      
			@DocDate = @ContractDate,      
			--@DocDate = @DDValue,      
			@DueDate = NULL,      
			@BillNo = @SNO,      
			@InvDocXML = @DocXml,      
			@NotesXML = N'',      
			@AttachmentsXML = N'',    
			@ActivityXML  = N'',       
			@IsImport = 0,      
			@LocationID = @ContractLocationID,      
			@DivisionID = @ContractDivisionID,      
			@WID = 0,      
			@RoleID = @RoleID,      
			@RefCCID = 104,    
			@RefNodeid = @ContractID ,    
			@CompanyGUID = @CompanyGUID,      
			@UserName = @UserName,      
			@UserID = @UserID,      
			@LangID = @LangID      

			SET @PDRcpt  = @return_value      

			--    UPDATE ACC_DOCDETAILS    
			--SET StatusID = @StatusValue    
			--WHERE DOCID = @return_value    

			set @XML = @AA      

			IF(@DocIDValue = 0 )    
			BEGIN    
				INSERT INTO  [REN_ContractDocMapping]([ContractID]      
				,[Type],[Sno],DocID,CostcenterID,IsAccDoc    
				,DocType, ContractCCID )
				values(@ContractID,2,@ICNT ,         
				@PDRcpt,@RcptCCID,1,2 ,104) 
			END 
			ELSE
			BEGIN
				update [REN_ContractDocMapping]
				set [Sno]=@ICNT 
				where [ContractID]=@ContractID and DocID=@DocIDValue
			END   

		END      

		IF(@totalPreviousPDPayXML > @CNT)    
		BEGIN    

			WHILE(@CNT <  @totalPreviousPDPayXML)    
			BEGIN    

				SET @CNT = @CNT+1    
				SELECT @DELETEDOCID = DOCID FROM @tblExistingPDPayXML WHERE ID = @CNT    

				SELECT  @DELETECCID = COSTCENTERID FROM dbo.ACC_DocDetails  with(nolock)     
				WHERE DOCID = @DELETEDOCID    

				EXEC @return_value = [dbo].[spDOC_DeleteAccDocument]      
				@CostCenterID = @DELETECCID,      
				@DocPrefix = '',      
				@DocNumber = '',  
				@DOCID = @DELETEDOCID,      
				@UserID = 1,      
				@UserName = N'ADMIN',      
				@LangID = 1,
				@RoleID=1

				DELETE FROM REN_ContractDocMapping WHERE CONTRACTID = @CONTRACTID  AND DOCID =  @DELETEDOCID and DOCTYPE =2 AND ContractCCID = 104    

			END    
		END    

	END      
        
   IF(@ComRcptXML is not null and @ComRcptXML<>'')      
   BEGIN      
      
    SET @XML =   @ComRcptXML       
           
    declare  @tblExistingComPayXML TABLE (ID int identity(1,1),DOCID bigint)           
    insert into @tblExistingComPayXML     
    select DOCID from  [REN_ContractDocMapping]  with(nolock)  
    where contractid=@ContractID and Doctype =3 AND ContractCCID = 104    
    declare @totalPreviousComPayXML bigint    
   select @totalPreviousComPayXML=COUNT(id) from @tblExistingComPayXML     
          
          
   CREATE TABLE #tblListPayCOM(ID int identity(1,1),TRANSXML NVARCHAR(MAX) , DateXML NVARCHAR(MAX) , AccountType NVARCHAR(100),Documents NVARCHAR(200) )            
   INSERT INTO #tblListPayCOM        
   SELECT  CONVERT(NVARCHAR(MAX),  X.query('DocumentXML')) ,  CONVERT(NVARCHAR(MAX),  X.query('ChequeDocDate'))  ,  CONVERT(NVARCHAR(MAX),  X.query('AccountType'))  ,  CONVERT(NVARCHAR(200),  X.query('Documents'))                    
   from @XML.nodes('/PARTICULARS//ROWS') as Data(X)        
       
   SELECT @CNT = COUNT(ID) FROM #tblListPayCOM      
        
   SET @ICNT = 0      
   WHILE(@ICNT < @CNT)      
   BEGIN      
   SET @ICNT =@ICNT+1      
         
   SELECT @AA = TRANSXML , @DateXML = DateXML, @AccountType = AccountType  , @Documents = Documents   FROM #tblListPayCOM WHERE  ID = @ICNT      
         
   Set @DocXml = convert(nvarchar(max), @AA)      
         
   --Set @DDXML = convert(nvarchar(max), @DateXML)      
         
       
   SELECT   @DocIDValue =  X.value ('@DocID', 'NVARCHAR(100)' )            
   from @Documents.nodes('/Documents') as Data(X)      
       
   SET @DocIDValue = ISNULL(@DocIDValue,0)    
      
           
   SELECT   @AccValue =  X.value ('@DD', 'NVARCHAR(100)' )            
   from @AccountType.nodes('/AccountType') as Data(X)      
       
   IF(@AccValue = 'BANK')    
   BEGIN    
       
  set @prefVal=''    
  select @prefVal=Value from COM_CostCenterPreferences WITH(nolock)      
  where CostCenterID=104 and Name='PurchaseParticularsPDC'      
  IF(@prefVal <>'' and @prefVal='True')    
  BEGIN    
   select @RcptCCID=CONVERT(int,Value) from COM_CostCenterPreferences WITH(nolock)      
   where CostCenterID=104 and Name='PurchasePostDatedPayment'      
  END    
  ELSE    
  BEGIN    
   select @RcptCCID=CONVERT(int,Value) from COM_CostCenterPreferences WITH(nolock)      
   where CostCenterID=104 and Name='PurchaseBankPayment'      
  END     
   END    
   ELSE     
   BEGIN    
  select @RcptCCID=CONVERT(int,Value) from COM_CostCenterPreferences WITH(nolock)      
  where CostCenterID=104 and Name='PurchaseCashReceipt'      
   END    
       
        set @Prefix=''
     EXEC [sp_GetDocPrefix] @DocXml,@ContractDate,@RcptCCID,@Prefix   output
   
    EXEC @return_value = [dbo].[spDOC_SetTempAccDocument]      
    @CostCenterID = @RcptCCID,      
    @DocID = @DocIDValue,      
    @DocPrefix = @Prefix,      
    @DocNumber =1,      
    @DocDate = @ContractDate,      
    --@DocDate = @DDValue,      
    @DueDate = NULL,      
    @BillNo = @SNO,      
    @InvDocXML = @DocXml,      
    @NotesXML = N'',      
    @AttachmentsXML = N'',      
    @ActivityXML  = N'',     
    @IsImport = 0,      
    @LocationID = @ContractLocationID,      
    @DivisionID = @ContractDivisionID,      
    @WID = 0,      
    @RoleID = @RoleID,      
    @RefCCID = 104,    
    @RefNodeid = @ContractID ,    
    @CompanyGUID = @CompanyGUID,      
    @UserName = @UserName,      
    @UserID = @UserID,      
    @LangID = @LangID      
      
    SET @CommRcpt  = @return_value      
           
  --    UPDATE ACC_DOCDETAILS    
  --SET StatusID = @StatusValue    
  --WHERE DOCID = @return_value    
         
    set @XML = @AA      
         
  IF(@DocIDValue = 0 )    
  BEGIN    
     INSERT INTO  [REN_ContractDocMapping]      
     ([ContractID]      
     ,[Type]      
     ,[Sno]      
     ,DocID      
     ,CostcenterID      
     ,IsAccDoc      
     ,DocType    
     ,ContractCCID    
     )      
                    
     SELECT  @ContractID  ,        
    1,        
     X.value('@CONTRACTSNO','int'),         
    @CommRcpt,          
    @RcptCCID,      
    1,3,104        
     FROM @XML.nodes('/DocumentXML/Row/Transactions') as Data(X)      
    END      
   END      
       
    IF(@totalPreviousComPayXML > @CNT)    
    BEGIN    
           
  WHILE(@CNT <  @totalPreviousComPayXML)    
  BEGIN    
          
   SET @CNT = @CNT+1    
   SELECT @DELETEDOCID = DOCID FROM @tblExistingComPayXML WHERE ID = @CNT    
       
   SELECT  @DELETECCID = COSTCENTERID FROM dbo.ACC_DocDetails   with(nolock)    
   WHERE DOCID = @DELETEDOCID    
         
     EXEC @return_value = [dbo].[spDOC_DeleteAccDocument]      
    @CostCenterID = @DELETECCID,      
    @DocPrefix = '',      
    @DocNumber = '',  
    @DOCID = @DELETEDOCID,
    @UserID = 1,      
    @UserName = N'ADMIN',      
    @LangID = 1,
    @RoleID=1
           
     DELETE FROM REN_ContractDocMapping WHERE CONTRACTID = @CONTRACTID  AND DOCID =  @DELETEDOCID and DOCTYPE =3 AND ContractCCID = 104    
         
    END    
    END    
   END      
       
      
      
  IF(@RentRcptXML is not null and @RentRcptXML<>'')      
   BEGIN      
        
 select @RcptCCID=CONVERT(int,Value) from COM_CostCenterPreferences WITH(nolock)      
 where CostCenterID=104 and Name='PurchaseBankPayment'      
 SET @XML =   @RentRcptXML       
       
 declare  @tblExistingPayRcs TABLE (ID int identity(1,1),DOCID bigint)           
 insert into @tblExistingPayRcs     
 select DOCID from  [REN_ContractDocMapping]  with(nolock)  
 where contractid=@ContractID and DOCTYPE =5 AND ContractCCID = 104    
 declare @totalPreviousPayRcts bigint    
 select @totalPreviousPayRcts=COUNT(id) from @tblExistingPayRcs     
       
  CREATE TABLE #tblPayList(ID int identity(1,1),TRANSXML NVARCHAR(MAX) , DateXML NVARCHAR(MAX))           
  INSERT INTO #tblPayList        
  SELECT  CONVERT(NVARCHAR(MAX),  X.query('DocumentXML') ) ,  CONVERT(NVARCHAR(MAX),  X.query('ChequeDocDate'))          
  from @XML.nodes('/RENTRCT/ROWS') as Data(X)        
       
  SELECT @CNT = COUNT(ID) FROM #tblPayList      
   SET @ICNT = 0      
  WHILE(@ICNT < @CNT)      
  BEGIN      
   SET @ICNT =@ICNT+1      
       
   SELECT @AA = TRANSXML , @DateXML = DateXML  FROM #tblPayList WHERE  ID = @ICNT      
       
   if( @totalPreviousPayRcts>=@ICNT)    
   begin    
  SELECT @DocIDValue = DOCID   FROM @tblExistingPayRcs WHERE  ID = @ICNT      
   end    
   else    
   begin    
  SELECT @DocIDValue=0    
   end    
   --Set @DDXML = convert(nvarchar(max), @DateXML)      
        
   SELECT   @DDValue =  X.value ('@DD', 'NVARCHAR(MAX)' )            
   from @DateXML.nodes('/ChequeDocDate') as Data(X)      
     
         
   Set @DocXml = convert(nvarchar(max), @AA)     
   
         set @Prefix=''
     EXEC [sp_GetDocPrefix] @DocXml,@ContractDate,@RcptCCID,@Prefix   output
   
   EXEC @return_value = [dbo].[spDOC_SetTempAccDocument]      
    @CostCenterID = @RcptCCID,      
    @DocID = @DocIDValue,      
    @DocPrefix = @Prefix,      
    @DocNumber =1,      
   -- @DocDate = @ContractDate,       
    @DocDate = @DDValue,      
    @DueDate = NULL,      
    @BillNo = @SNO,      
    @InvDocXML = @DocXml,      
    @NotesXML = N'',      
    @AttachmentsXML = N'',      
    @ActivityXML  = N'',     
    @IsImport = 0,      
    @LocationID = @ContractLocationID,      
    @DivisionID = @ContractDivisionID,      
    @WID = 0,      
    @RoleID = @RoleID,      
    @RefCCID = 104,    
    @RefNodeid = @ContractID ,    
    @CompanyGUID = @CompanyGUID,      
    @UserName = @UserName,      
    @UserID = @UserID,      
    @LangID = @LangID      
   
         
       SET @RentRcpt  = @return_value      
      
    --UPDATE ACC_DOCDETAILS    
    --SET StatusID = @StatusValue    
    --WHERE DOCID = @return_value    
        
       set @XML = @AA      
        
      IF(@DocIDValue = 0 )    
    BEGIN    
  INSERT INTO  [REN_ContractDocMapping]      
     ([ContractID]      
     ,[Type]      
     ,[Sno]      
     ,DocID      
     ,CostcenterID      
     ,IsAccDoc    
     ,DocType      
     , ContractCCID    
     )      
                   
     SELECT  @ContractID  ,        
     X.value('@NodeID','int'),         
     X.value('@CONTRACTSNO','int'),         
    @RentRcpt,          
    @RcptCCID,      
    1,5 , 104        
     FROM @XML.nodes('/DocumentXML/Row/Transactions') as Data(X)        
       END    
      
   END      
       
   IF(@totalPreviousPayRcts > @CNT)    
   BEGIN    
          
    WHILE(@CNT <  @totalPreviousPayRcts)    
    BEGIN    
         
  SET @CNT = @CNT+1    
  SELECT @DELETEDOCID = DOCID FROM @tblExistingPayRcs WHERE ID = @CNT    
      
  SELECT  @DELETECCID = COSTCENTERID FROM dbo.ACC_DocDetails   with(nolock)    
  WHERE DOCID = @DELETEDOCID    
        
    EXEC @return_value = [dbo].[spDOC_DeleteAccDocument]      
   @CostCenterID = @DELETECCID,      
   @DocPrefix = '',      
   @DocNumber = '',  
   @DOCID = @DELETEDOCID,      
   @UserID = 1,      
   @UserName = N'ADMIN',      
   @LangID = 1,
   @RoleID=1
          
    DELETE FROM REN_ContractDocMapping WHERE CONTRACTID = @CONTRACTID  AND DOCID =  @DELETEDOCID and DOCTYPE =5 AND ContractCCID= 104     
        
   END    
   END    
       
 END        
         
    END    
      
   -------------------------- END POSTINGS -----------------------      
     
	IF  (  @CostCenterID = 95 )
	BEGIN
		DECLARE @CCNODEIDCONT INT   

		SELECT @CCNODEIDCONT = CCNODEID  ,@Dimesion = CCID FROM REN_CONTRACT  with(nolock)
		WHERE CONTRACTID = @ContractID  
		IF(@Dimesion IS NOT NULL AND @Dimesion <> '' AND  @Dimesion  > 50000)  
		BEGIN  
			DECLARE @CCMapSql nvarchar(max)    

			set @CCMapSql='update COM_CCCCDATA      
			SET CCNID'+convert(nvarchar,(@Dimesion-50000))+'='+CONVERT(NVARCHAR,@CCNODEIDCONT)+'  WHERE NodeID = '+convert(nvarchar,@ContractID) + ' AND CostCenterID = 95'     
			EXEC (@CCMapSql)
			
			set @CCMapSql=' UPDATE COM_DOCCCDATA    
			SET DCCCNID'+convert(nvarchar,(@Dimesion-50000))+'='+CONVERT(NVARCHAR,@CCNODEIDCONT)+'   
			WHERE ACCDOCDETAILSID IN (SELECT ACCDOCDETAILSID  FROM ACC_DOCDETAILS  with(nolock) WHERE REFCCID = 95 AND REFNODEID = '+convert(nvarchar,@ContractID) + ' and DOCID > 0)  
			OR INVDOCDETAILSID IN (SELECT INVDOCDETAILSID  FROM INV_DOCDETAILS  with(nolock) WHERE REFCCID = 95 AND REFNODEID =  '+convert(nvarchar,@ContractID)+ ' and DOCID > 0)'     
			--select @CCMapSql  
			EXEC (@CCMapSql) 
			
			Exec [spDOC_SetLinkDimension]
					@InvDocDetailsID=@ContractID, 
					@Costcenterid=95,         
					@DimCCID=@Dimesion,
					@DimNodeID=@CCNODEIDCONT,
					@UserID=@UserID,    
					@LangID=@LangID    
			
		END 
		
		if(@WID>0)
		BEGIN	 
		 
			INSERT INTO COM_Approvals(CCID,CCNODEID,StatusID,Date,Remarks,UserID   
			  ,CompanyGUID,GUID,CreatedBy,CreatedDate,WorkFlowLevel,DocDetID)      
			VALUES(@COSTCENTERID,@ContractID,@StatusID,CONVERT(FLOAT,getdate()),'',@UserID
			  ,@CompanyGUID,newid(),@UserName,CONVERT(FLOAT,getdate()),isnull(@level,0),0)
	 
		    if(@StatusID not in(426,427))
			BEGIN
				update INV_DOCDETAILS
				set StatusID=371
				FROM INV_DOCDETAILS a WITH(NOLOCK)
				join REN_CONTRACTDOCMAPPING b WITH(NOLOCK) on a.DocID=b.DocID 
				WHERE CONTRACTID = @ContractID  AND ISACCDOC = 0 and RefNodeID = @ContractID    
						
				update ACC_DOCDETAILS
				set StatusID=371
				FROM ACC_DOCDETAILS b WITH(NOLOCK)
				join INV_DOCDETAILS a WITH(NOLOCK) on b.INVDOCDETAILSID=a.INVDOCDETAILSID
				join REN_CONTRACTDOCMAPPING c WITH(NOLOCK) on a.DocID=b.DocID 
				WHERE CONTRACTID = @ContractID  AND ISACCDOC = 0 and a.RefNodeid = @ContractID    

				update ACC_DOCDETAILS
				set StatusID=371
				FROM ACC_DOCDETAILS a WITH(NOLOCK)
				join REN_CONTRACTDOCMAPPING b WITH(NOLOCK) on a.DocID=b.DocID 
				WHERE CONTRACTID = @ContractID AND ISACCDOC = 1  and RefNodeID = @ContractID
			END	
		END	
		
		
		delete from [REN_Contract] where RefContractID=@ContractID
		if(@MultiUnitIds is not null and @MultiUnitIds<>'' )
		BEGIN         
			update REN_Units
			set ContractID=@ContractID
			where UnitID=@UnitID

			declare @ChildUnits table(UnitID BIGINT)  
			insert into @ChildUnits  
			exec SPSplitString @MultiUnitIds,','

			INSERT INTO  [REN_Contract] ([ContractPrefix],SNO,[ContractDate]        
				,[ContractNumber],[StatusID],[PropertyID],[UnitID],[TenantID],[RentAccID],[IncomeAccID]        
				,[Purpose],[StartDate],[EndDate],[ExtendTill],[TotalAmount],[NonRecurAmount],[RecurAmount]        
				,[Depth],[ParentID],[lft],[rgt],[IsGroup],[CompanyGUID],[GUID],[CreatedBy],[CreatedDate]       
				,[LocationID],[DivisionID],[CurrencyID],[TermsConditions],[SalesmanID],[AccountantID],[LandlordID]    
				,Narration,[CostCenterID],CCNodeID,CCID,VacancyDate,BasedOn,RefContractID,RenewRefID,NoOfUnits)
			select [ContractPrefix],SNO,[ContractDate]        
				,[ContractNumber],[StatusID],[PropertyID],b.UnitID,[TenantID],[RentAccID],[IncomeAccID]        
				,[Purpose],[StartDate],[EndDate],[ExtendTill],[TotalAmount],[NonRecurAmount],[RecurAmount]        
				,[Depth],[ParentID],[lft],[rgt],[IsGroup],[CompanyGUID],[GUID],[CreatedBy],[CreatedDate]       
				,[LocationID],[DivisionID],[CurrencyID],[TermsConditions],[SalesmanID],[AccountantID],[LandlordID]    
				,Narration,[CostCenterID],CCNodeID,CCID,VacancyDate,BasedOn,@ContractID,RenewRefID,1 
			FROM [REN_Contract] a with(nolock),@ChildUnits b
			where ContractID=@ContractID
			
			UPDATE REN_Contract SET NoOfUnits=(SELECT COUNT(*) FROM @ChildUnits) WHERE ContractID=@ContractID
			
			select @PrefValue = Value from COM_CostCenterPreferences with(nolock)
			where CostCenterID= 93  and  Name = 'LinkDocument'
			
			set @Dimesion=0

			if(@PrefValue is not null and @PrefValue<>'')
			begin
				begin try
					select @Dimesion=convert(BIGINT,@PrefValue)
				end try
				begin catch
					set @Dimesion=0
				end catch
			END	
			if(@Dimesion>0)
			begin
				Declare @TabName nvarchar(max)     
			 
				select @TabName = TableName  from adm_features with(nolock) where FeatureID=@Dimesion     
				    
				set @CCMapSql=' SELECT @CCNODEIDCONT = NODEID FROM ' + @TabName +'  with(nolock) where   Name = N'''+@MultiUnitName+''''  
			     				 
				EXEC sp_executesql @CCMapSql,N'@CCNODEIDCONT BIGINT OUTPUT', @CCNODEIDCONT OUTPUT  
     
				set @CCMapSql=' UPDATE COM_DOCCCDATA    
				SET DCCCNID'+convert(nvarchar,(@Dimesion-50000))+'='+CONVERT(NVARCHAR,@CCNODEIDCONT)+'   
				WHERE DCCCNID'+convert(nvarchar,(@Dimesion-50000))+'=1 and ( ACCDOCDETAILSID IN (SELECT ACCDOCDETAILSID  FROM ACC_DOCDETAILS with(nolock) WHERE REFCCID = 95 AND REFNODEID = '+convert(nvarchar,@ContractID) + ' and DOCID > 0)  
				OR INVDOCDETAILSID IN (SELECT INVDOCDETAILSID  FROM INV_DOCDETAILS with(nolock) WHERE REFCCID = 95 AND REFNODEID =  '+convert(nvarchar,@ContractID)+ ' and DOCID > 0))'     
				EXEC (@CCMapSql)    
			END 
		END 
	END

	set @UpdateSql='update [REN_ContractExtended] SET '+@CustomFieldsQuery+' [ModifiedBy] ='''+ @UserName+''',
	[ModifiedDate] =' + convert(nvarchar,@Dt) +' WHERE NodeID='+convert(nvarchar,@ContractID)      

	exec(@UpdateSql)      

	set @UpdateSql='update COM_CCCCDATA SET '+@CustomCostCenterFieldsQuery+'[ModifiedBy] ='''+ @UserName+''',
	[ModifiedDate] =' + convert(nvarchar,@Dt) +' WHERE NodeID ='+convert(nvarchar,@ContractID) + ' AND CostCenterID = 95'       
	  
	exec(@UpdateSql)        
 
	--Insert Notifications    
	DECLARE @ActionType INT    
	IF @AUDITSTATUS='ADD'    
		SET @ActionType=1    
	ELSE    
		SET @ActionType=3     
      
	EXEC spCOM_SetNotifEvent @ActionType,95,@ContractID,@CompanyGUID,@UserName,@UserID,@RoleID  
	
	IF(@AUDITSTATUS = 'ADD')
	BEGIN
		select @PrefValue = Value from COM_CostCenterPreferences WITH(nolock)  
		where CostCenterID=95 and  Name = 'CallExternalFunction'  
		
		IF(@PrefValue ='True')
		BEGIN
			EXEC spREN_ExternalFunction 95,@ContractID
		END
	END
	
	if exists(select Value from COM_CostCenterPreferences WITH(nolock)  
		where CostCenterID=95 and  Name = 'UseExternal'  and Value='true')	
		EXEC [spEXT_RentalPostings] @ContractID,@sno,@CompanyGUID,@UserName,@RoleID,@UserID,@LangID

COMMIT TRANSACTION
	--rollback TRANSACTION       
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
			SELECT ErrorMessage, ERROR_MESSAGE() AS ServerMessage,ERROR_NUMBER() as ErrorNumber, ERROR_PROCEDURE()as ProcedureName, ERROR_LINE() AS ErrorLine 
			FROM COM_ErrorMessages WITH(nolock)        
			WHERE ErrorNumber=-110 AND LanguageID=@LangID        
		END        
		ELSE IF ERROR_NUMBER()=2627        
		BEGIN        
			SELECT ErrorMessage, ERROR_MESSAGE() AS ServerMessage,ERROR_NUMBER() as ErrorNumber, ERROR_PROCEDURE()as ProcedureName, ERROR_LINE() AS ErrorLine 
			FROM COM_ErrorMessages WITH(nolock)        
			WHERE ErrorNumber=-116 AND LanguageID=@LangID        
		END        
		ELSE        
		BEGIN        
			SELECT ErrorMessage, ERROR_MESSAGE() AS ServerMessage,ERROR_NUMBER() as ErrorNumber, ERROR_PROCEDURE()as ProcedureName, ERROR_LINE() AS ErrorLine        
			FROM COM_ErrorMessages WITH(nolock) WHERE ErrorNumber=-999 AND LanguageID=@LangID        
		END         
		if(@return_value is null or  @return_value<>-999)     
			ROLLBACK TRANSACTION      
	END        
	SET NOCOUNT OFF            
	RETURN -999
END CATCH     
GO

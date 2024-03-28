USE PACT2C222
GO
SET ANSI_NULLS, QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spREN_GetProperty]
	@PropertyID [int] = 0,
	@ContractType [int] = 0,
	@UserID [int],
	@RoleID [int],
	@LangID [int] = 1
WITH ENCRYPTION, EXECUTE AS CALLER
AS
BEGIN TRANSACTION        
BEGIN TRY         
SET NOCOUNT ON        
    
   	declare @dimCid int,@table nvarchar(50)
	set @dimCid=0
	select @dimCid=Value from COM_CostCenterPreferences WITH(NOLOCK)
	where Name='DimensionWiseContract' and costcenterid=95 and Value is not null and Value<>'' and ISNUMERIC(value)=1
     
          
	select * from REN_Property WITH(NOLOCK) where IsGroup=1        
	    
	SELECT Name,Value from  COM_CostCenterPreferences WITH(NOLOCK) WHERE CostCenterID=92        
	    
	select *,convert(datetime,BondDate) as BD from REN_Property WITH(NOLOCK) where NodeID=@PropertyID        
	      
	select * from COM_STATUS WITH(NOLOCK) where FeatureID=92        
	    
	select * from COM_Lookup WITH(NOLOCK) where Lookuptype=34        
	    
	select * from COM_Lookup WITH(NOLOCK) where Lookuptype=35        
	    
	select * from COM_Lookup WITH(NOLOCK) where Lookuptype=32        
	      
	select * from COM_Lookup WITH(NOLOCK) where Lookuptype=37        
	
	declare @T1 nvarchar(100),@T2 nvarchar(100),@Sql nvarchar(max) ,@T3 nvarchar(100)       
	    
	set @T1=(select TableName from adm_features WITH(NOLOCK) where featureid=(select value from ADM_GlobalPreferences WITH(NOLOCK) where Name='DepositLinkDimension'))        
	set @T2=(select TableName from adm_features WITH(NOLOCK) where featureid=(select value from ADM_GlobalPreferences WITH(NOLOCK) where  Name='UnitLinkDimension'))        
	set @T3=(select TableName from adm_features WITH(NOLOCK) where featureid=(select value from ADM_GlobalPreferences WITH(NOLOCK) where  Name='PropertyParking'))        
	
	DECLARE @DATA NVARCHAR(MAX)    
	IF(@ContractType =0)
	BEGIN    
		SET @DATA='        
		select REN_Particulars.*'
		
		if exists(select * from adm_globalpreferences
			where name ='VATVersion')
			SET @DATA=@DATA+',Tx.Name TaxCategory,SPT.Name SPTypeName'
		else
			SET @DATA=@DATA+','''' TaxCategory,'''' SPTypeName'
		
		if (@dimCid>50000)
			set @DATA=@DATA+' ,Dim.Name Dimname'
		ELSE
			set @DATA=@DATA+' ,'''' Dimname'	
			
		SET @DATA=@DATA+',Bnk.ACCOUNTNAME BankAccount,A.ACCOUNTNAME A,B.ACCOUNTNAME B,Ad.ACCOUNTNAME AdvanceAccountName,'+@T1+'.NAME from REN_Particulars WITH(NOLOCK)        
		LEFT JOIN ACC_ACCOUNTS A WITH(NOLOCK) ON A.AccountID=REN_Particulars.CreditAccountID        
		LEFT JOIN ACC_ACCOUNTS B WITH(NOLOCK) ON B.AccountID=REN_Particulars.DebitAccountID
		LEFT JOIN ACC_ACCOUNTS Bnk WITH(NOLOCK) ON Bnk.AccountID=REN_Particulars.BankAccountID        
		LEFT JOIN ACC_ACCOUNTS Ad WITH(NOLOCK) ON Ad.AccountID=REN_Particulars.AdvanceAccountID'
		
		if (@dimCid>50000)
		BEGIN
			select @table=tablename from adm_features with(NOLOCK) where featureid=@dimCid
			set @DATA=@DATA+' LEFT JOIN '+@table+' Dim WITH(NOLOCK) ON Dim.NodeID=REN_Particulars.DimNodeID '			
		END

		if exists(select * from adm_globalpreferences
			where name ='VATVersion')	 
			SET @DATA=@DATA+' LEFT JOIN COM_CC50060 Tx WITH(NOLOCK) ON Tx.NodeID=REN_Particulars.TaxCategoryID   LEFT JOIN COM_CC50061 SPT WITH(NOLOCK) ON SPT.NodeID=REN_Particulars.SPType      '
		
		SET @DATA=@DATA+' LEFT JOIN '+@T1+' ON '+@T1+'.NodeID=REN_Particulars.ParticularID        
		where PropertyID='+CONVERT(VARCHAR,@PropertyID)+' and Unitid= 0 ' 
		SET  @DATA = @DATA + ' order by '+@T1+'.Code'	        
	END 
	ELSE
	BEGIN
		SET @DATA='        
		select REN_Particulars.*'
		
		if exists(select * from adm_globalpreferences
			where name ='VATVersion')
			SET @DATA=@DATA+',Tx.Name TaxCategory,SPT.Name SPTypeName'
		else
			SET @DATA=@DATA+','''' TaxCategory,'''' SPTypeName'
			
		SET @DATA=@DATA+',Bnk.ACCOUNTNAME BankAccount,A.ACCOUNTNAME A,B.ACCOUNTNAME B,Ad.ACCOUNTNAME AdvanceAccountName,'+@T1+'.NAME from REN_Particulars WITH(NOLOCK)        
		LEFT JOIN ACC_ACCOUNTS A WITH(NOLOCK) ON A.AccountID=REN_Particulars.CreditAccountID        
		LEFT JOIN ACC_ACCOUNTS B WITH(NOLOCK) ON B.AccountID=REN_Particulars.DebitAccountID
		LEFT JOIN ACC_ACCOUNTS Bnk WITH(NOLOCK) ON Bnk.AccountID=REN_Particulars.BankAccountID        
		LEFT JOIN ACC_ACCOUNTS Ad WITH(NOLOCK) ON Ad.AccountID=REN_Particulars.AdvanceAccountID'
		
		if exists(select * from adm_globalpreferences
			where name ='VATVersion')	 
			SET @DATA=@DATA+' LEFT JOIN COM_CC50060 Tx WITH(NOLOCK) ON Tx.NodeID=REN_Particulars.TaxCategoryID  LEFT JOIN COM_CC50061 SPT WITH(NOLOCK) ON SPT.NodeID=REN_Particulars.SPType      '
		
		SET @DATA=@DATA+' LEFT JOIN '+@T1+' ON '+@T1+'.NodeID=REN_Particulars.ParticularID        
		where PropertyID='+CONVERT(VARCHAR,@PropertyID)+' and Unitid= 0  AND ContractType = ' +CONVERT(VARCHAR,@ContractType)   
		SET  @DATA = @DATA + ' order by '+@T1+'.Code'	    
	END
	print @DATA
	EXEC (@DATA)        
          
	select * from REN_PropertyUnits WITH(NOLOCK) where PropertyID=@PropertyID        

	set @Sql ='select NodeID,Name as Particulars from '+@T1+' WITH(NOLOCK)'     
	    
	exec (@Sql)        
	    
	set @Sql ='select NodeID,Name as Type from '+@T2+' WITH(NOLOCK)'            
	    
	exec (@Sql)        
	    
	select * from COM_Lookup WITH(NOLOCK) where Lookuptype=40        
	    
	--Getting data from Opportunities extended table        
	SELECT * FROM  REN_PropertyExtended WITH(NOLOCK)         
	WHERE NodeID=@PropertyID        
	      
	SELECT * FROM ADM_PropertyUserRoleMap  WITH(NOLOCK)      
	WHERE PropertyID = @PropertyID        
	      
	-- GETTING COSTCENTER DATA         
	SELECT * FROM  COM_CCCCDATA WITH(NOLOCK)         
	WHERE NodeID=@PropertyID and CostCenterID = 92         
	     
	set @Sql ='select NodeID,Name as Type from '+@T3+' WITH(NOLOCK)'            
	    
	exec (@Sql)      
	  
	SELECT * FROM COM_Notes WITH(NOLOCK)   
	WHERE FeatureID = 92 AND FeaturePK  = @PropertyID
	
	EXEC [spCOM_GetAttachments] 92,@PropertyID,@UserID
	
	select sh.*,a.AccountName from  REN_PropertyShareHolder sh WITH(NOLOCK)
	left join ACC_Accounts a with(nolock) on sh.account=a.AccountID
	where propertyid=@PropertyID
	
	--WorkFlow
	EXEC spCOM_CheckCostCentetWFApprove 92,@PropertyID,@UserID,@RoleID
	
	
	
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
	ELSE        
	BEGIN        
		SELECT ErrorMessage, ERROR_MESSAGE() AS ServerMessage,ERROR_NUMBER() as ErrorNumber, ERROR_PROCEDURE()as ProcedureName, ERROR_LINE() AS ErrorLine        
		FROM COM_ErrorMessages WITH(nolock) 
		WHERE ErrorNumber=-999 AND LanguageID=@LangID        
	END        
ROLLBACK TRANSACTION        
SET NOCOUNT OFF          
RETURN -999           
END CATCH
GO

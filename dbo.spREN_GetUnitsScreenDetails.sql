USE PACT2C222
GO
SET ANSI_NULLS, QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spREN_GetUnitsScreenDetails]
	@UnitID [bigint] = 0,
	@UserID [bigint],
	@LangID [int] = 1,
	@RoleID [int] = 0
WITH ENCRYPTION, EXECUTE AS CALLER
AS
BEGIN TRANSACTION    
BEGIN TRY     
SET NOCOUNT ON    
	SELECT Name,Value from  COM_CostCenterPreferences WITH(NOLOCK) WHERE CostCenterID=93     
	SELECT * FROM COM_STATUS WITH(NOLOCK) WHERE FeatureID=93    
	SELECT NodeID,Name,isdefault FROM COM_Lookup WITH(NOLOCK) WHERE LookupType=39    
	SELECT NodeID,Name,isdefault FROM COM_Lookup WITH(NOLOCK) WHERE LookupType=38       
	IF @UnitID>0    
	BEGIN
		declare @T1 nvarchar(100),@T2 nvarchar(100),@Sql nvarchar(max)    
		
		SELECT @Sql=b.Name FROM REN_UNITS a WITH(NOLOCK) 
		join COM_Lookup b WITH(NOLOCK) on a.unitstatus=b.NodeID
		WHERE LookupType=46   and UNITID=@UNITID
    
		SELECT *,[Status] StatusID,@Sql UnitStatusName FROM REN_UNITS WITH(NOLOCK) WHERE UNITID=@UNITID    

		set @T1=(select TableName from adm_features WITH(NOLOCK) where featureid=(select value from ADM_GlobalPreferences WITH(NOLOCK) where Name='DepositLinkDimension'))    
		set @T2=(select TableName from adm_features WITH(NOLOCK) where featureid=(select value from ADM_GlobalPreferences WITH(NOLOCK) where  Name='UnitLinkDimension'))    
		DECLARE @DATA NVARCHAR(MAX)    
		SET @DATA='    
		select REN_Particulars.*'
		
		if exists(select * from adm_globalpreferences WITH(NOLOCK) where name ='VATVersion')
			SET @DATA=@DATA+',Tx.Name TaxCategory'
		else
			SET @DATA=@DATA+','''' TaxCategory'
			
		SET @DATA=@DATA+',A.ACCOUNTNAME A,B.ACCOUNTNAME B,Ad.ACCOUNTNAME AdvanceAccountName,'+@T1+'.NAME from REN_Particulars WITH(NOLOCK)    
		JOIN ren_units u  WITH(NOLOCK) on  REN_Particulars.unitid=u.unitid and REN_Particulars.propertyid=u.propertyid
		LEFT JOIN ACC_ACCOUNTS A WITH(NOLOCK) ON A.AccountID=REN_Particulars.CreditAccountID    
		LEFT JOIN ACC_ACCOUNTS B WITH(NOLOCK) ON B.AccountID=REN_Particulars.DebitAccountID   
		LEFT JOIN ACC_ACCOUNTS Ad WITH(NOLOCK) ON Ad.AccountID=REN_Particulars.AdvanceAccountID '
		
		if exists(select * from adm_globalpreferences
			where name ='VATVersion')	 
			SET @DATA=@DATA+' LEFT JOIN COM_CC50060 Tx WITH(NOLOCK) ON Tx.NodeID=REN_Particulars.TaxCategoryID        '
		
		SET @DATA=@DATA+' LEFT JOIN '+@T1+'  WITH(NOLOCK) ON '+@T1+'.NodeID=REN_Particulars.ParticularID    
		where REN_Particulars.UNITID='+CONVERT(VARCHAR,@UNITID)    
		print @DATA
		EXEC (@DATA)    

		SELECT * FROM REN_UnitsExtended WITH(NOLOCK) WHERE UnitID=@UNITID    

		IF(@UnitID>0)    
		BEGIN    
			SELECT TNT.FirstName Tenant, CONVERT(DATETIME, RN.StartDate) AS StartDate, CONVERT(DATETIME, RN.EndDate) AS EndDate    
			FROM  REN_Contract AS RN WITH(NOLOCK)
			LEFT JOIN REN_Tenant AS TNT WITH(NOLOCK) ON TNT.TenantID = RN.TenantID    
			WHERE RN.UnitID=@UNITID  AND RN.COSTCENTERID = 95  
			order by RN.EndDate desc
		END    

	END    
        
         
	SELECT DISTINCT A.PropertyID, B.LANDLORDID FROM [ADM_PropertyUserRoleMap] A WITH(NOLOCK)
	JOIN REN_PROPERTY B WITH(NOLOCK) ON A.PROPERTYID = B.NODEID  
	where A.Userid  =  @UserID or A.RoleID=@RoleID
	
	--Getting CostCenterMap    
	SELECT * FROM COM_CCCCDATA  WITH(NOLOCK)   
	WHERE NodeID = @UNITID AND CostCenterID  = 93     

	--Getting Files  
	SELECT * FROM  COM_Files WITH(NOLOCK)   
	WHERE FeatureID=93 and  FeaturePK=@UNITID  

	SELECT UnitRateID,UnitID , Amount ,Discount , AnnualRent, CONVERT(NVARCHAR(12), CONVERT(DATETIME,WithEffectFrom)) AS WithEffectFrom  
	FROM Ren_UnitRate WITH(NOLOCK)
	WHERE UnitID = @UNITID  
	
	--WorkFlow
	EXEC spCOM_CheckCostCentetWFApprove 93,@UNITID,@UserID,@RoleID  
	
	--History Details
	select H.HistoryID,H.HistoryCCID CCID,H.HistoryNodeID,convert(datetime,FromDate) FromDate,convert(datetime,ToDate) ToDate,H.Remarks
	from COM_HistoryDetails H with(nolock) 
	where H.CostCenterID=93 and H.NodeID=@UNITID --and H.HistoryCCID>50000
	order by FromDate,H.HistoryID
 
        
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

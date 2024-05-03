﻿USE PACT2C222
GO
SET ANSI_NULLS, QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spPAY_GetEmpMasterDetails]
	@NodeID [bigint] = 0,
	@UserID [bigint],
	@RoleID [int],
	@LangID [int] = 1
WITH ENCRYPTION, EXECUTE AS CALLER
AS
BEGIN TRY    
SET NOCOUNT ON;  
	--Declaration Section  
	DECLARE @HasAccess BIT,@Table nvarchar(50),@SQL nvarchar(max),@CostCenterID INT
	SET @CostCenterID=50051
	  
	--User access check   
	SET @HasAccess=dbo.fnCOM_HasAccess(@RoleID,@CostCenterID,2)  

	IF @HasAccess=0  
	BEGIN  
		RAISERROR('-105',16,1)  
	END  

	SELECT *,
	CONVERT(DATETIME,DOJ) as cDOJ,CONVERT(DATETIME,DOB) as cDOB,
	CONVERT(DATETIME,DOConfirmation) as cDOConfirmation,CONVERT(DATETIME,NextAppraisalDate) as cNextAppraisalDate,
	CONVERT(DATETIME,PassportIssDate) as cPassportIssDate,CONVERT(DATETIME,PassportExpDate) as cPassportExpDate,
	CONVERT(DATETIME,VisaIssDate) as cVisaIssDate,CONVERT(DATETIME,VisaExpDate) as cVisaExpDate,
	CONVERT(DATETIME,IqamaIssDate) as cIqamaIssDate,CONVERT(DATETIME,IqamaExpDate) as cIqamaExpDate,
	CONVERT(DATETIME,ContractIssDate) as cContractIssDate,CONVERT(DATETIME,ContractExpDate) as cContractExpDate,CONVERT(DATETIME,ContractExtendDate) as cContractExtendDate,
	CONVERT(DATETIME,IDIssDate) as cIDIssDate,CONVERT(DATETIME,IDExpDate) as cIDExpDate,
	CONVERT(DATETIME,LicenseIssDate) as cLicenseIssDate,CONVERT(DATETIME,LicenseExpDate) as cLicenseExpDate,
	CONVERT(DATETIME,MedicalIssDate) as cMedicalIssDate,CONVERT(DATETIME,MedicalExpDate) as cMedicalExpDate,
	CONVERT(DATETIME,DOResign) as cDOResign,CONVERT(DATETIME,DORelieve) as cDORelieve,
	CONVERT(DATETIME,DOTentRelieve) as cDOTentRelieve,
	CONVERT(DATETIME,OpLeavesAsOn) as cOpLeavesAsOn,CONVERT(DATETIME,OpLOPAsOn) as cOpLOPAsOn
		
	FROM COM_CC50051 WITH(nolock) WHERE NodeID=@NodeID
	    

	--Getting Contacts    
	EXEC [spCom_GetFeatureWiseContacts] @CostCenterID,@NodeID,2,1,1 

	--Getting Notes  
	SELECT NoteID, Note, FeatureID, FeaturePK, CompanyGUID, GUID, CreatedBy, convert(datetime,CreatedDate) as CreatedDate, 
	ModifiedBy, ModifiedDate, CostCenterID FROM  COM_Notes WITH(NOLOCK)   
	WHERE FeatureID=@CostCenterID and  FeaturePK=@NodeID  

	--Getting Files  
	EXEC [spCOM_GetAttachments] @CostCenterID,@NodeID,@UserID

	--Getting Contacts  
	EXEC [spCom_GetFeatureWiseContacts] @CostCenterID,@NodeID,1,1,1

	--Getting Custom CostCenter Extra fields  
	EXEC [spCOM_GetCCCCMapDetails] @CostCenterId,@NodeID,@LangID
		
	--Getting ADDRESS 
	EXEC spCom_GetAddress @CostCenterId,@NodeID,1,1

	SELECT R.* ,
	NID1.NAME as NAME1,NID2.NAME as NAME2,NID3.NAME as NAME3,NID4.NAME as NAME4,NID5.NAME as NAME5,NID6.NAME as NAME6,NID7.NAME as NAME7,NID8.NAME as NAME8,NID9.NAME as NAME9,NID10.NAME  AS NAME10,
	NID11.NAME  AS NAME11,NID12.NAME  AS NAME12,NID13.NAME  AS NAME13,NID14.NAME  AS NAME14,NID15.NAME  AS NAME15,NID16.NAME  AS NAME16,NID17.NAME  AS NAME17,NID18.NAME  AS NAME18,NID19.NAME  AS NAME19,NID20.NAME  AS NAME20,
	NID21.NAME  AS NAME21,NID22.NAME  AS NAME22,NID23.NAME  AS NAME23,NID24.NAME  AS NAME24,NID25.NAME  AS NAME25,NID26.NAME  AS NAME26,NID27.NAME  AS NAME27,NID28.NAME  AS NAME28,NID29.NAME  AS NAME29,NID30.NAME  AS NAME30,
	NID31.NAME  AS NAME31,NID32.NAME  AS NAME32,NID33.NAME  AS NAME33,NID34.NAME  AS NAME34,NID35.NAME  AS NAME35,NID36.NAME  AS NAME36,NID37.NAME  AS NAME37,NID38.NAME  AS NAME38,NID39.NAME  AS NAME39,NID40.NAME  AS NAME40,
	NID41.NAME  AS NAME41,NID42.NAME  AS NAME42,NID43.NAME  AS NAME43,NID44.NAME  AS NAME44,NID45.NAME  AS NAME45,NID46.NAME  AS NAME46,NID47.NAME  AS NAME47,NID48.NAME  AS NAME48,NID49.NAME  AS NAME49,NID50.NAME  AS NAME50 
	FROM COM_CCCCData R WITH(NOLOCK)
	LEFT JOIN COM_DIVISION NID1 WITH(NOLOCK) on R.CCNID1=NID1.NODEID
	LEFT JOIN COM_Location NID2 WITH(NOLOCK) on R.CCNID2=NID2.NODEID
	LEFT JOIN COM_Branch NID3 WITH(NOLOCK) on R.CCNID3=NID3.NODEID
	LEFT JOIN COM_Department NID4 WITH(NOLOCK) on R.CCNID4=NID4.NODEID
	LEFT JOIN COM_Salesman NID5 WITH(NOLOCK) on R.CCNID5=NID5.NODEID
	LEFT JOIN COM_Category NID6 WITH(NOLOCK) on R.CCNID6=NID6.NODEID
	LEFT JOIN COM_Area NID7 WITH(NOLOCK) on R.CCNID7=NID7.NODEID
	LEFT JOIN COM_Teritory NID8 WITH(NOLOCK) on R.CCNID8=NID8.NODEID
	LEFT JOIN COM_CC50009 NID9 WITH(NOLOCK) on R.CCNID9=NID9.NODEID
	LEFT JOIN COM_CC50010 NID10 WITH(NOLOCK) on R.CCNID10=NID10.NODEID
	LEFT JOIN COM_CC50011 NID11 WITH(NOLOCK) on R.CCNID11=NID11.NODEID
	LEFT JOIN COM_CC50012 NID12 WITH(NOLOCK) on R.CCNID12=NID12.NODEID
	LEFT JOIN COM_CC50013 NID13 WITH(NOLOCK) on R.CCNID13=NID13.NODEID
	LEFT JOIN COM_CC50014 NID14 WITH(NOLOCK) on R.CCNID14=NID14.NODEID
	LEFT JOIN COM_CC50015 NID15 WITH(NOLOCK) on R.CCNID15=NID15.NODEID
	LEFT JOIN COM_CC50016 NID16 WITH(NOLOCK) on R.CCNID16=NID16.NODEID
	LEFT JOIN COM_CC50017 NID17 WITH(NOLOCK) on R.CCNID17=NID17.NODEID
	LEFT JOIN COM_CC50018 NID18 WITH(NOLOCK) on R.CCNID18=NID18.NODEID
	LEFT JOIN COM_CC50019 NID19 WITH(NOLOCK) on R.CCNID19=NID19.NODEID 
	LEFT JOIN COM_CC50020 NID20 WITH(NOLOCK) ON R.CCNID20=NID20.NODEID
	LEFT JOIN COM_CC50021 NID21 WITH(NOLOCK) ON R.CCNID21=NID21.NODEID
	LEFT JOIN COM_CC50022 NID22 WITH(NOLOCK) ON R.CCNID22=NID22.NODEID
	LEFT JOIN COM_CC50023 NID23 WITH(NOLOCK) ON R.CCNID23=NID23.NODEID
	LEFT JOIN COM_CC50024 NID24 WITH(NOLOCK) ON R.CCNID24=NID24.NODEID
	LEFT JOIN COM_CC50025 NID25 WITH(NOLOCK) ON R.CCNID25=NID25.NODEID
	LEFT JOIN COM_CC50026 NID26 WITH(NOLOCK) ON R.CCNID26=NID26.NODEID
	LEFT JOIN COM_CC50027 NID27 WITH(NOLOCK) ON R.CCNID27=NID27.NODEID
	LEFT JOIN COM_CC50028 NID28 WITH(NOLOCK) ON R.CCNID28=NID28.NODEID
	LEFT JOIN COM_CC50029 NID29 WITH(NOLOCK) ON R.CCNID29=NID29.NODEID 
	LEFT JOIN COM_CC50030 NID30 WITH(NOLOCK) ON R.CCNID30=NID30.NODEID
	LEFT JOIN COM_CC50031 NID31 WITH(NOLOCK) ON R.CCNID31=NID31.NODEID
	LEFT JOIN COM_CC50032 NID32 WITH(NOLOCK) ON R.CCNID32=NID32.NODEID
	LEFT JOIN COM_CC50033 NID33 WITH(NOLOCK) ON R.CCNID33=NID33.NODEID
	LEFT JOIN COM_CC50034 NID34 WITH(NOLOCK) ON R.CCNID34=NID34.NODEID
	LEFT JOIN COM_CC50035 NID35 WITH(NOLOCK) ON R.CCNID35=NID35.NODEID
	LEFT JOIN COM_CC50036 NID36 WITH(NOLOCK) ON R.CCNID36=NID36.NODEID
	LEFT JOIN COM_CC50037 NID37 WITH(NOLOCK) ON R.CCNID37=NID37.NODEID
	LEFT JOIN COM_CC50038 NID38 WITH(NOLOCK) ON R.CCNID38=NID38.NODEID
	LEFT JOIN COM_CC50039 NID39 WITH(NOLOCK) ON R.CCNID39=NID39.NODEID 
	LEFT JOIN COM_CC50040 NID40 WITH(NOLOCK) ON R.CCNID40=NID40.NODEID
	LEFT JOIN COM_CC50041 NID41 WITH(NOLOCK) ON R.CCNID41=NID41.NODEID
	LEFT JOIN COM_CC50042 NID42 WITH(NOLOCK) ON R.CCNID42=NID42.NODEID
	LEFT JOIN COM_CC50043 NID43 WITH(NOLOCK) ON R.CCNID43=NID43.NODEID
	LEFT JOIN COM_CC50044 NID44 WITH(NOLOCK) ON R.CCNID44=NID44.NODEID
	LEFT JOIN COM_CC50045 NID45 WITH(NOLOCK) ON R.CCNID45=NID45.NODEID
	LEFT JOIN COM_CC50046 NID46 WITH(NOLOCK) ON R.CCNID46=NID46.NODEID
	LEFT JOIN COM_CC50047 NID47 WITH(NOLOCK) ON R.CCNID47=NID47.NODEID
	LEFT JOIN COM_CC50048 NID48 WITH(NOLOCK) ON R.CCNID48=NID48.NODEID
	LEFT JOIN COM_CC50049 NID49 WITH(NOLOCK) ON R.CCNID49=NID49.NODEID 
	LEFT JOIN COM_CC50050 NID50 WITH(NOLOCK) ON R.CCNID50=NID50.NODEID
	WHERE R.CostCenterID=@CostCenterId AND R.NODEID=@NodeID  

	SELECT Code,Name from COM_CC50051 WITH(nolock) WHERE NodeID in 
	(SELECT ParentID from COM_CC50051 with(nolock) where NodeID=@NodeID)
		
	--CCmap display data 
	CREATE TABLE #TBLTEMP(ID INT IDENTITY(1,1),COSTCENTERID BIGINT,NODEID BIGINT)
	CREATE TABLE #TBLTEMP1 (CostCenterId bigint,CostCenterName nvarchar(max),NodeID BIGINT,[Value] NVARCHAR(300), Code nvarchar(300))
	INSERT INTO #TBLTEMP
	SELECT CostCenterID,NODEID  FROM COM_CostCenterCostCenterMap with(nolock) WHERE ParentCostCenterID=@CostCenterId AND ParentNodeID=@NodeID
	DECLARE @COUNT INT,@I INT,@TABLENAME NVARCHAR(300), @CCID BIGINT,@ccNODEID BIGINT,@FEATURENAME NVARCHAR(300), @IsGroup bit
	SELECT @I=1,@COUNT=COUNT(*) FROM #TBLTEMP
	WHILE @I<=@COUNT
	BEGIN
		SELECT @ccNODEID=NODEID,@CCID=CostCenterId FROM #TBLTEMP WHERE ID=@I
		SELECT @FEATURENAME=NAME,@TABLENAME=TABLENAME FROM ADM_FEATURES with(nolock) WHERE FEATUREID =@CCID
		 
		SET @SQL='	IF EXISTS (SELECT NodeID FROM '+@TABLENAME +' 
					WHERE NODEID='+CONVERT(VARCHAR,@ccNODEID) +' and IsGroup=0)
						INSERT INTO #TBLTEMP1 SELECT '+CONVERT(VARCHAR,@CCID)+','''+@FEATURENAME+''',NODEID,NAME,Code FROM '+@TABLENAME +'  with(nolock)
						WHERE NODEID='+CONVERT(VARCHAR,@ccNODEID) +'
					ELSE
						INSERT INTO #TBLTEMP1 SELECT '+CONVERT(VARCHAR,@CCID)+','''+@FEATURENAME+''',NODEID,NAME,Code FROM '+@TABLENAME +'  with(nolock)
						WHERE ParentID='+CONVERT(VARCHAR,@ccNODEID) 
		-- print(@SQL)
		 EXEC (@SQL)
		SET @I=@I+1
	END

	SELECT * FROM #TBLTEMP1
	DROP TABLE #TBLTEMP1
	DROP TABLE #TBLTEMP
		
	--WorkFlow
	EXEC spCOM_CheckCostCentetWFApprove @CostCenterID,@NodeID,@UserID,@RoleID
		
	declare @rptid bigint, @tempsql nvarchar(500)
	SELECT @rptid=CONVERT(bigint,value) from ADM_GlobalPreferences with(nolock) where Name='Report Template Dimension'
	if(@rptid=@CostCenterID)
		SELECT * from ACC_ReportTemplate with(nolock) where drnodeid =@NodeID or crnodeid=@NodeID or templatenodeid =@NodeID
	else
		SELECT '' ACC_ReportTemplate where 1!=1
  
	-- HISTORY Details --12
	SELECT H.HistoryID,H.HistoryCCID CCID,H.HistoryNodeID,convert(datetime,FromDate) FromDate,convert(datetime,ToDate) ToDate,H.Remarks
	from COM_HistoryDetails H with(nolock) 
	where H.CostCenterID=@CostCenterID and H.NodeID=@NodeID and H.HistoryCCID>50000
	order by FromDate,H.HistoryID
	
	--Documents Details --13
	Select * From PAY_EmpDetail a WITH(NOLOCK) Where a.EmployeeID=@NodeID
	
	-- Appraisals Details --14
	SELECT SeqNo,*,convert(datetime,EffectFrom) ApraisalDate 
	FROM PAY_EmpPay WITH(nolock) WHERE EmployeeID=@NodeID
	ORDER BY EffectFrom Asc
	
	-- ACCOUNT LINKING Details --15
	SELECT a.*,b.AccountName as DebitAccountName,c.AccountName as CreditAccountName,d.Name as ComponentName
	FROM PAY_EmpAccountsLinking a WITH(NOLOCK) 
	LEFT JOIN ACC_Accounts b WITH(NOLOCK) on b.AccountID=a.DebitAccountID
	LEFT JOIN ACC_Accounts c WITH(NOLOCK) on c.AccountID=a.CreditAccountID
	LEFT JOIN COM_CC50052 d WITH(NOLOCK) on d.NodeID=a.ComponentID
	WHERE EmpSeqNo=@NodeID
	ORDER BY Type,SNo ASC
	
	
	  
  
SET NOCOUNT OFF;  
RETURN 1  
END TRY  
BEGIN CATCH    
  --Return exception info [Message,Number,ProcedureName,LineNumber]    
  IF ERROR_NUMBER()=50000  
  BEGIN  
   SELECT ErrorMessage,ErrorNumber FROM COM_ErrorMessages WITH(NOLOCK) WHERE ErrorNumber=ERROR_MESSAGE() AND LanguageID=@LangID  
  END  
  ELSE  
  BEGIN  
   SELECT ErrorMessage, ERROR_MESSAGE() AS ServerMessage,ERROR_NUMBER() as ErrorNumber, ERROR_PROCEDURE()as ProcedureName, ERROR_LINE() AS ErrorLine  
   FROM COM_ErrorMessages WITH(NOLOCK) WHERE ErrorNumber=-999 AND LanguageID=@LangID  
  END   
SET NOCOUNT OFF    
RETURN -999     
END CATCH
GO

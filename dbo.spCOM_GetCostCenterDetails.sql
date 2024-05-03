USE PACT2C222
GO
SET ANSI_NULLS, QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spCOM_GetCostCenterDetails]
	@CostCenterID [int] = 0,
	@NodeID [bigint] = 0,
	@UserID [bigint],
	@RoleID [int],
	@LangID [int] = 1,
	@CallType [int] = NULL,
	@AssignedDim [int] = 0
WITH ENCRYPTION, EXECUTE AS CALLER
AS
BEGIN TRY    
SET NOCOUNT ON;  
	--Declaration Section  
	DECLARE @HasAccess BIT,@Table nvarchar(50),@SQL nvarchar(max)   

	IF(@CallType=1)  
	BEGIN
		SELECT a.*,b.GroupName as RibbonGroupName,b.TabID as RibbonTabID FROM ADM_FEATURES a with(nolock) 
		LEFT JOIN ADM_RibbonView b WITH(NOLOCK) on b.FeatureID=a.FeatureID
		WHERE a.FEATUREID>=50000
	END 	  
	ELSE IF(@CallType=2)  
	BEGIN
		IF @AssignedDim=0
			SELECT @SQL='SELECT CC.ParentCostCenterID CCID,'''+max(F.Name)+''' DimName,D.NodeID,D.Name Value 
			from COM_CostCenterCostCenterMap CC with(nolock) 
			INNER JOIN '+F.TableName+' D with(nolock) ON D.NodeID=ParentNodeID
			WHERE CC.CostCenterID='+CONVERT(nvarchar,@CostCenterId)+' AND CC.NodeID='+CONVERT(nvarchar,@NodeID)+' AND CC.ParentCostCenterID='+CONVERT(nvarchar,cc.ParentCostCenterID)
			FROM COM_CostCenterCostCenterMap CC with(nolock) 
			INNER JOIN ADM_Features F with(nolock) ON CC.ParentCostCenterID=F.FeatureID
			WHERE CC.CostCenterID=@CostCenterId AND CC.NodeID=@NodeID
			GROUP BY CC.ParentCostCenterID,F.TableName
		ELSE
			SELECT @SQL='SELECT CC.ParentCostCenterID CCID,'''+max(F.Name)+''' DimName,D.NodeID,D.Name Value 
			from COM_CostCenterCostCenterMap CC with(nolock) 
			INNER JOIN '+F.TableName+' D with(nolock) ON D.NodeID=ParentNodeID
			WHERE CC.CostCenterID='+CONVERT(nvarchar,@CostCenterId)+' AND CC.NodeID='+CONVERT(nvarchar,@NodeID)+' AND CC.ParentCostCenterID='+CONVERT(nvarchar,cc.ParentCostCenterID)
			FROM COM_CostCenterCostCenterMap CC with(nolock) 
			INNER JOIN ADM_Features F with(nolock) ON CC.ParentCostCenterID=F.FeatureID
			WHERE CC.CostCenterID=@CostCenterId AND CC.NodeID=@NodeID AND CC.ParentCostCenterID=@AssignedDim
			GROUP BY CC.ParentCostCenterID,F.TableName 
		exec(@SQL)
	END
	ELSE  
	BEGIN  
  
		--SP Required Parameters Check  
		IF @CostCenterID=0 --OR @NodeID=0  
		BEGIN  
			RAISERROR('-100',16,1)  
		END  
  
		--User access check   
		SET @HasAccess=dbo.fnCOM_HasAccess(@RoleID,@CostCenterID,2)  

		IF @HasAccess=0  
		BEGIN  
		RAISERROR('-105',16,1)  
		END  

		--To get costcenter table name  
		SELECT Top 1 @Table=SysTableName FROM ADM_CostCenterDef WITH(NOLOCK) WHERE CostCenterID=@CostCenterId  

		SET @SQL='SELECT * FROM '+@Table+' WITH(nolock) WHERE NodeID='+convert(nvarchar,@NodeID)    
		EXEC(@SQL)    

		--Getting Contacts    
		EXEC [spCom_GetFeatureWiseContacts] @CostCenterID,@NodeID,2,1,1 

		--Getting Notes  
		SELECT NoteID, Note, FeatureID, FeaturePK, CompanyGUID, GUID, CreatedBy, convert(datetime,CreatedDate) as CreatedDate, 
			ModifiedBy, ModifiedDate, CostCenterID,Progress FROM  COM_Notes WITH(NOLOCK)   
		WHERE FeatureID=@CostCenterID and  FeaturePK=@NodeID  

		--Getting Files  
		EXEC [spCOM_GetAttachments] @CostCenterID,@NodeID,@UserID

		--Getting Contacts  
		EXEC [spCom_GetFeatureWiseContacts] @CostCenterID,@NodeID,1,1,1

		--Getting Custom CostCenter Extra fields  
		--   SELECT * FROM COM_CCCCData WHERE CostCenterID=@CostCenterId AND NODEID=@NodeID  
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

		set @SQL='select Code,Name from '+@Table+' WITH(nolock) WHERE NodeID in 
		(select ParentID from '+@Table+' with(nolock) where NodeID= '+convert(nvarchar,@NodeID)+')'
		 
		exec (@SQL)
		SELECT ConvertedCRMProduct FROM INV_PRODUCT WITH(nolock) WHERE ConvertedCRMProduct=@NodeID

		 --CCmap display data 
		CREATE TABLE #TBLTEMP(ID INT IDENTITY(1,1),COSTCENTERID BIGINT,NODEID BIGINT)
		CREATE TABLE #TBLTEMP1 (CostCenterId bigint,CostCenterName nvarchar(max),NodeID BIGINT,[Value] NVARCHAR(300), Code nvarchar(300))
		INSERT INTO #TBLTEMP
		SELECT CostCenterID,NODEID  FROM COM_CostCenterCostCenterMap with(nolock) WHERE ParentCostCenterID=@CostCenterId AND ParentNodeID=@NodeID
		DECLARE @COUNT INT,@I INT,@TABLENAME NVARCHAR(300), @CCID BIGINT,@ccNODEID BIGINT,@FEATURENAME NVARCHAR(300), @IsGroup bit
		SELECT @I=1,@COUNT=COUNT(*) FROM #TBLTEMP
		WHILE @I<=@COUNT
		BEGIN
			SELECT @ccNODEID=NODEID,@CCID=COSTCENTERID FROM #TBLTEMP WHERE ID=@I
			SELECT @FEATURENAME=NAME,@TABLENAME=TABLENAME FROM ADM_FEATURES with(nolock) WHERE FEATUREID =@CCID
			 
			IF @CCID=7
			BEGIN
				SET @SQL='INSERT INTO #TBLTEMP1 SELECT '+CONVERT(VARCHAR,@CCID)+','''+@FEATURENAME+''',UserID,UserName,UserName FROM '+@TABLENAME +'  with(nolock)
						WHERE UserID='+CONVERT(VARCHAR,@ccNODEID) 
			END
			ELSE
			BEGIN
				SET @SQL='if exists (select NodeID FROM '+@TABLENAME +' 
					 WHERE NODEID='+CONVERT(VARCHAR,@ccNODEID) +' and IsGroup=0)
						INSERT INTO #TBLTEMP1 SELECT '+CONVERT(VARCHAR,@CCID)+','''+@FEATURENAME+''',NODEID,NAME,Code FROM '+@TABLENAME +'  with(nolock)
						WHERE NODEID='+CONVERT(VARCHAR,@ccNODEID) +'
					 else
						INSERT INTO #TBLTEMP1 SELECT '+CONVERT(VARCHAR,@CCID)+','''+@FEATURENAME+''',NODEID,NAME,Code FROM '+@TABLENAME +'  with(nolock)
						WHERE ParentID='+CONVERT(VARCHAR,@ccNODEID) 
			END
			print(@SQL)
			EXEC (@SQL)
			SET @I=@I+1
		END

		SELECT * FROM #TBLTEMP1
		DROP TABLE #TBLTEMP1
		DROP TABLE #TBLTEMP
		
		--WorkFlow
		EXEC spCOM_CheckCostCentetWFApprove @CostCenterID,@NodeID,@UserID,@RoleID

		if exists(select isnull(value,0) from COM_CostCenterPreferences with(nolock) 
		where CostCenterID=76 and Name='JobDimension' and ISNUMERIC(value)=1 and Value=@CostCenterID)
		BEGIN
			declare @StageDim nvarchar(max),@dim nvarchar(max)
			select @StageDim=Value from COM_CostCenterPreferences with(nolock) where Name='StageDimension' 
			set @dim=''
			select @dim=TableName from COM_CostCenterPreferences a with(nolock) 
			join ADM_Features f  with(nolock) on a.Value=f.FeatureID
			where a.Name='JobFilterDim' and isnumeric(a.Value)=1 and convert(bigint,a.Value)>50000

			if(LEN(@StageDim)>0 and ISNUMERIC(@StageDim)=1 and convert(int,@StageDim)>50000)
			begin
				select @StageDim=TableName from ADM_Features with(nolock) where FeatureID=convert(int,@StageDim)
			
				SET @SQL='select st.name,st.NodeID, j.BomID, bom.BOMName,j.ProductID,p.ProductName,j.IsBom,
				j.Qty, isnull(J.UOMID,1) UOMID, u.UnitName,J.StatusID,j.DimID,Remarks'
				if(@dim<>'')
					SET @SQL=@SQL+',Dt.Name DimName '
				SET @SQL=@SQL+' from PRD_JobOuputProducts j with(nolock)
				left join PRD_BillOfMaterial bom with(nolock) on j.BomID=bom.BOMID
				join INV_Product p with(nolock) on j.ProductID=p.ProductID			
				left join COM_UOM u with(nolock) on isnull(j.UOMID,1)=u.UOMID				
				left join PRD_BOMStages bs with(nolock) on bs.StageID=J.StageID
				left join '+@StageDim+' st with(nolock) on bs.StageNodeID=st.NodeID '
				
				if(@dim<>'')
					SET @SQL=@SQL+' left join '+@dim+' dt with(nolock) on j.DimID=dt.NodeID '
					
				SET @SQL=@SQL+' where j.CostCenterID='+CONVERT(NVARCHAR,@CostCenterID)+ 'and j.NodeID='++CONVERT(NVARCHAR,@NodeID)
				exec(@SQL)
			END
			ELSE
			BEGIN
				select j.BomID, bom.BOMName,j.ProductID,p.ProductName,j.IsBom,
				j.Qty, isnull(J.UOMID,1) UOMID, u.UnitName,j.StatusID,Remarks
				from PRD_JobOuputProducts j with(nolock)
				left join PRD_BillOfMaterial bom with(nolock) on j.BomID=bom.BOMID
				join INV_Product p with(nolock) on j.ProductID=p.ProductID			
				left join COM_UOM u with(nolock) on isnull(j.UOMID,1)=u.UOMID			
				where j.CostCenterID=@CostCenterID and j.NodeID=@NodeID
			END
		END
		
		declare @rptid bigint, @tempsql nvarchar(500)
		select @rptid=CONVERT(bigint,value) from ADM_GlobalPreferences with(nolock) where Name='Report Template Dimension'
		if(@rptid=@CostCenterID)
			select * from ACC_ReportTemplate with(nolock) where drnodeid =@NodeID or crnodeid=@NodeID or templatenodeid =@NodeID
		else
			select '' ACC_ReportTemplate where 1!=1
			
		--History Details
		select H.HistoryID,H.HistoryCCID CCID,H.HistoryNodeID,convert(datetime,FromDate) FromDate,convert(datetime,ToDate) ToDate,H.Remarks
		from COM_HistoryDetails H with(nolock) 
		where H.CostCenterID=@CostCenterID and H.NodeID=@NodeID and (H.HistoryCCID>50000 or H.HistoryCCID in(2,3))
		order by FromDate,H.HistoryID	
	
		--Status Details
		select StatusMapID,CostCenterID,[Status],convert(datetime,FromDate) FromDate,convert(datetime,ToDate) ToDate
		from [COM_CostCenterStatusMap] with(nolock)
		where CostCenterID=@CostCenterID and NodeID=@NodeID
		order by FromDate,ToDate
	END  
  
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

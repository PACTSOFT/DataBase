USE PACT2C222
GO
SET ANSI_NULLS, QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spADM_DeleteProductionData]
	@ModuleID [int],
	@DIMENSIONLIST [nvarchar](max),
	@UserID [int] = 1,
	@LangID [int] = 1
WITH ENCRYPTION, EXECUTE AS CALLER
AS
SET NOCOUNT ON;    
IF(@ModuleID=4)--PRODUCTION
BEGIN  
	CREATE TABLE #TAB(ID BIGINT IDENTITY (1,1),COSTCENTERID BIGINT,SID BIGINT)  
	DECLARE @I INT,@RC INT,@SNO BIGINT,@TABLENAME NVARCHAR(100),@STRQRY NVARCHAR(MAX),@DIMID BIGINT,@COSTCENTERID BIGINT,@J INT,@TRC INT  
	DECLARE @Tbl1 TABLE(ID INT IDENTITY(1,1),FeatureID INT)  
	DECLARE @Tbl TABLE(ID INT IDENTITY(1,1),FeatureID INT)  
	INSERT INTO @Tbl1  
	  EXEC SPSplitString @DIMENSIONLIST,','  

	INSERT INTO @Tbl select featureid from @Tbl1  order by featureid  DESC
	DELETE FROM @Tbl1 
	   
	SET @J=1  
	SELECT @TRC=COUNT(*) FROM @Tbl  
	WHILE(@J<=@TRC)  
	BEGIN  
		 SELECT @COSTCENTERID=FeatureID FROM @Tbl WHERE ID=@J  
		 IF(@COSTCENTERID=78)--MANUFACTURING ORDER  
		 BEGIN  
			  TRUNCATE TABLE #TAB  
			  INSERT INTO #TAB SELECT @COSTCENTERID,MFGOrderID FROM PRD_MFGOrder WHERE MFGOrderID>1   
			  SET @I=1  
			  SELECT @RC=COUNT(*) FROM #TAB  
			  WHILE(@I<=@RC)  
			  BEGIN  
				SELECT @SNO=SID FROM #TAB WHERE ID=@I  
				EXEC spPRD_DeleteMO  @SNO ,@UserID ,'ADMIN' ,@LangID ,1  
			  SET @I=@I+1  
			  END  
		 END  
		 ELSE IF(@COSTCENTERID=76)--BILL OF MATERIAL  
		 BEGIN  
			  TRUNCATE TABLE #TAB  
			  INSERT INTO #TAB SELECT @COSTCENTERID,BOMID FROM PRD_BillOfMaterial where BOMID>1  
			  SET @I=1  
			  SELECT @RC=COUNT(*) FROM #TAB  
			  WHILE(@I<=@RC)  
			  BEGIN  
				SELECT @SNO=SID FROM #TAB WHERE ID=@I  
				EXEC spPRD_DeleteBOMDetails  @SNO ,@LangID  
			     
			  SET @I=@I+1  
			  END  
			  
			  --Stage Dimension
			  SET @STRQRY=''  
			  Select @DIMID=Isnull(Value,0) From [COM_CostCenterPreferences] Where CostCenterId=76 AND Name='StageDimension'  
			  SET @TABLENAME='COM_CC'+CONVERT(NVARCHAR,@DIMID)  
			  TRUNCATE TABLE #TAB  
			  SET @STRQRY='INSERT INTO #TAB SELECT '+ CONVERT(VARCHAR,@DIMID) +',NODEID FROM '+ CONVERT(VARCHAR,@TABLENAME) +' where NODEID>2'  
			  --PRINT (@STRQRY)  
			  EXEC (@STRQRY)  
			  SET @I=1  
			  SELECT @RC=COUNT(*) FROM #TAB  
			  WHILE(@I<=@RC)  
			  BEGIN  
				SELECT @SNO=SID FROM #TAB WHERE ID=@I  
				EXEC spCOM_DeleteCostCenter @DIMID ,@SNO ,1 ,@UserID ,@LangID     
			  SET @I=@I+1  
			  END  
		  
			  --Bom Dimension
			  SET @STRQRY=''  
			  Select @DIMID=Isnull(Value,0) From [COM_CostCenterPreferences] Where CostCenterId=76 AND Name='BomDimension'  
			  SET @TABLENAME='COM_CC'+CONVERT(NVARCHAR,@DIMID)  
			  TRUNCATE TABLE #TAB  
			  SET @STRQRY='INSERT INTO #TAB SELECT '+ CONVERT(VARCHAR,@DIMID) +',NODEID FROM '+ CONVERT(VARCHAR,@TABLENAME) +' where NODEID>2'  
			  --PRINT (@STRQRY)  
			  EXEC (@STRQRY)  
			  SET @I=1  
			  SELECT @RC=COUNT(*) FROM #TAB  
			  select * from #TAB
			  WHILE(@I<=@RC)  
			  BEGIN  
				SELECT @SNO=SID FROM #TAB WHERE ID=@I  
				EXEC spCOM_DeleteCostCenter @DIMID ,@SNO ,1 ,@UserID ,@LangID     
			  SET @I=@I+1  
			  END  
			  --
		 END  
		 ELSE IF(@COSTCENTERID=71)--MACHINE/RESOURCES  
		 BEGIN  
			  SET @STRQRY=''  
			  Select @DIMID=Isnull(Value,0) From [COM_CostCenterPreferences] Where CostCenterId=76 AND Name='MachineDimension'  
			  SET @TABLENAME='COM_CC'+CONVERT(NVARCHAR,@DIMID)  
			  TRUNCATE TABLE #TAB  
			  SET @STRQRY='INSERT INTO #TAB SELECT '+ CONVERT(VARCHAR,@DIMID) +',NODEID FROM '+ CONVERT(VARCHAR,@TABLENAME) +' where NODEID>2'  
			  PRINT (@STRQRY)  
			  EXEC (@STRQRY)  
			  SET @I=1  
			  SELECT @RC=COUNT(*) FROM #TAB  
			  WHILE(@I<=@RC)  
			  BEGIN  
				SELECT @SNO=SID FROM #TAB WHERE ID=@I  
				EXEC spCOM_DeleteCostCenter @DIMID ,@SNO ,1 ,@UserID ,@LangID     
			  SET @I=@I+1  
			  END  
			  print '71'
		 END  
		 ELSE --JOBS  
		 BEGIN  
			  --Deleting preference dimensions
			  SET @STRQRY=''  
			  Select @DIMID=Isnull(Value,0) From [COM_CostCenterPreferences] Where CostCenterId=76 AND Name='JobDimension'  
			  SET @TABLENAME='COM_CC'+CONVERT(NVARCHAR,@DIMID)  
			  TRUNCATE TABLE #TAB  
			  SET @STRQRY='INSERT INTO #TAB SELECT '+ CONVERT(VARCHAR,@DIMID) +',NODEID FROM '+ CONVERT(VARCHAR,@TABLENAME) +' where NODEID>2'  
			  PRINT (@STRQRY)  
			  EXEC (@STRQRY)  
			  SET @I=1  
			  SELECT @RC=COUNT(*) FROM #TAB  
			  select * from #TAB
			  WHILE(@I<=@RC)  
			  BEGIN  
				SELECT @SNO=SID FROM #TAB WHERE ID=@I  
				EXEC spCOM_DeleteCostCenter @DIMID ,@SNO ,1 ,@UserID ,@LangID     
			  SET @I=@I+1  
			  END  
		 END  
	SET @J=@J+1   
	END  
DROP TABLE #TAB  
END	
ELSE IF(@ModuleID=13)--PAYROLL
BEGIN 
BEGIN TRANSACTION  
BEGIN TRY 
	PRINT 'PAYROLL'
	CREATE TABLE #TblDeleteRows(idid bigint identity(1,1), ID BIGINT,BatchID BIGINT,linkinv bigint,DOCID bigint)

	INSERT INTO  #TblDeleteRows	
	SELECT InvDocDetailsID,BatchID,LinkedInvDocDetailsID,DOCID FROM [INV_DocDetails] WHERE (COSTCENTERID IN (40055,40056,40057,40063,40062,40059,40054,40058,40067,40073,40071,40072,40065,40078,40076,40080,40060,40081) OR DocumentType=68) --68 Recording of Data
	
	DELETE T FROM COM_DocCCData t join #TblDeleteRows a on t.InvDocDetailsID=a.ID		

	DELETE T FROM [COM_DocNumData] t join #TblDeleteRows a on t.InvDocDetailsID=a.ID

	set @STRQRY='DELETE T FROM [PAY_DocNumData] t join #TblDeleteRows a on t.InvDocDetailsID=a.ID'
	EXEC(@STRQRY)
	
	DELETE T FROM [COM_DocTextData] T join #TblDeleteRows a on t.InvDocDetailsID=a.ID
	
	drop table #TblDeleteRows

	DELETE FROM [COM_DocID] WHERE ID in (select DOCID from INV_DocDetails WHERE (COSTCENTERID IN (40055,40056,40057,40063,40062,40059,40054,40058,40067,40073,40071,40072,40065,40078,40076,40080,40060,40081) OR DocumentType=68) )

	DELETE FROM COM_CCCCData where (costcenterid in (40055,40056,40057,40063,40062,40059,40054,40058,40067,40073,40071,40072,40065,40078,40076,40080,40060,40081)
									OR CostCenterID IN(Select CostCenterID FROM ADM_DocumentTypes WITH(NOLOCK) WHERE DocumentType=68))
	
	DELETE FROM [INV_DocDetails] where (costcenterid in (40055,40056,40057,40063,40062,40059,40054,40058,40067,40073,40071,40072,40065,40078,40076,40080,40060,40081) OR DocumentType=68)
	
	DELETE FROM COM_CostCenterCodeDef WHERE (COSTCENTERID IN (40055,40056,40057,40063,40062,40059,40054,40058,40067,40073,40071,40072,40065,40078,40076,40080,40060,40081)
						OR CostCenterID IN(Select CostCenterID FROM ADM_DocumentTypes WITH(NOLOCK) WHERE DocumentType=68)) 	AND ISNULL(CODEPREFIX,'')<>''
 
	UPDATE COM_CostCenterCodeDef SET CurrentCodeNumber=0,CodeNumberLength=1 
	WHERE (COSTCENTERID IN (40055,40056,40057,40063,40062,40059,40054,40058,40067,40073,40071,40072,40065,40078,40076,40080,40060,40081) 
	OR CostCenterID IN(Select CostCenterID FROM ADM_DocumentTypes WITH(NOLOCK) WHERE DocumentType=68) ) AND ISNULL(CODEPREFIX,'')=''
	
	TRUNCATE TABLE PAY_EmployeeLeaveDetails
	TRUNCATE TABLE PAY_EmpMonthlyAdjustments
	TRUNCATE TABLE PAY_EmpMonthlyArrears
	TRUNCATE TABLE PAY_EmpMonthlyDues

	COMMIT TRANSACTION  
	SET NOCOUNT OFF;    
	SELECT ErrorMessage,ErrorNumber FROM COM_ErrorMessages WITH(nolock)   
	WHERE ErrorNumber=102 AND LanguageID=@LangID  
	RETURN 1  
	END TRY  
	BEGIN CATCH    
	PRINT ERROR_NUMBER()
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
END
GO

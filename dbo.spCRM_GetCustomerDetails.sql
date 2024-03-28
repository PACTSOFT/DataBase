USE PACT2C222
GO
SET ANSI_NULLS, QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spCRM_GetCustomerDetails]
	@CustomerID [bigint] = 0,
	@UserID [bigint],
	@RoleID [int],
	@LangID [int] = 1
WITH ENCRYPTION, EXECUTE AS CALLER
AS
BEGIN TRANSACTION
BEGIN TRY	
SET NOCOUNT ON


		 create table #tblUsers(username nvarchar(100))
		insert into #tblUsers
		exec [spADM_GetUserNamebyOwner] @UserID 
		
		--Declaration Section
		DECLARE @HasAccess bit

		--SP Required Parameters Check
		IF (@CustomerID < 1)
		BEGIN
			RAISERROR('-100',16,1)
		END


		--User acces check
		SET @HasAccess=dbo.fnCOM_HasAccess(@RoleID,83,2)
		
		IF @HasAccess=0
		BEGIN
			RAISERROR('-105',16,1)
		END

		--Getting the main data from customers table
	    SELECT * FROM  CRM_Customer WITH(NOLOCK) 
		WHERE CustomerID=@CustomerID

		--Getting data from Customers extended table
		SELECT * FROM  CRM_CustomerExtended WITH(NOLOCK) 
		WHERE CustomerID=@CustomerID

		--Getting Contacts
		EXEC [spCom_GetFeatureWiseContacts] 83,@CustomerID,3,1,1

		--Getting Notes
		SELECT     NoteID, Note, FeatureID, FeaturePK, CompanyGUID, GUID, CreatedBy, convert(datetime,CreatedDate) as CreatedDate, 
		ModifiedBy, ModifiedDate, CostCenterID
		FROM         COM_Notes WITH(NOLOCK) 
		WHERE FeatureID=83 and  FeaturePK=@CustomerID
			
	 
		--Getting ADDRESS 
		EXEC spCom_GetAddress 83,@CustomerID,1,1

		--Getting Contacts
		EXEC [spCom_GetFeatureWiseContacts] 83,@CustomerID,1,1,1				 
		
		--Getting Files
		EXEC [spCOM_GetAttachments] 83,@CustomerID,@UserID

			--Getting CostCenterMap
		SELECT * FROM  COM_CCCCData WITH(NOLOCK) 
		WHERE NodeID=@CustomerID and CostCenterID=83

			
		IF(EXISTS(SELECT * FROM CRM_Activities WHERE CostCenterID=83 AND NodeID=@CustomerID))
			EXEC spCRM_GetFeatureByActvities @CustomerID,83,'',@UserID,@LangID  
		ELSE
			SELECT 1 WHERE 1<>1
				 
			select C.CaseID,C.CaseNumber,C.CustomerID,CC.CustomerName,C.ProductID,P.ProductName, CONVERT(datetime,C.CreatedDate) as CreatedDate,C.ParentID from crm_cases C
			left join crm_customer CC on CC.CustomerID = C.CustomerID
			left join INV_Product P on P.ProductID = C.ProductID
			where C.CustomerID=@CustomerID

		  	EXEC [spCOM_GetCCCCMapDetails] 83,@CustomerID,@LangID
		  	SELECT ConvertFromCustomerID FROM Acc_Accounts WITH(nolock) WHERE ConvertFromCustomerID=@CustomerID 		  	
		  	
		--CCmap display data 
		CREATE TABLE #TBLTEMP(ID INT IDENTITY(1,1),COSTCENTERID BIGINT,NODEID BIGINT)
		CREATE TABLE #TBLTEMP1 (CostCenterId bigint,CostCenterName nvarchar(max),NodeID BIGINT,[Value] NVARCHAR(300),Code NVARCHAR(300))
		INSERT INTO #TBLTEMP
		SELECT CostCenterID,NODEID  FROM COM_CostCenterCostCenterMap WHERE ParentCostCenterID=83 AND ParentNodeID=@CustomerID
		DECLARE @COUNT INT,@I INT,@TABLENAME NVARCHAR(300),@SQL NVARCHAR(MAX),@CCID BIGINT,@NODEID BIGINT,@FEATURENAME NVARCHAR(300), @IsGroup bit
		SELECT @I=1,@COUNT=COUNT(*) FROM #TBLTEMP
		WHILE @I<=@COUNT
		BEGIN
			SELECT @NODEID=NODEID,@CCID=CostCenterId FROM #TBLTEMP WHERE ID=@I
			SELECT @FEATURENAME=NAME,@TABLENAME=TABLENAME FROM ADM_FEATURES WHERE FEATUREID =@CCID
			 
				--IF @CCID>50000
				SET @SQL='if exists (select NodeID FROM '+@TABLENAME +' 
					     WHERE NODEID='+CONVERT(VARCHAR,@NODEID) +' and IsGroup=0)
							INSERT INTO #TBLTEMP1 SELECT '+CONVERT(VARCHAR,@CCID)+','''+@FEATURENAME+''',NODEID,NAME,Code FROM '+@TABLENAME +' 
									 WHERE NODEID='+CONVERT(VARCHAR,@NODEID) +'
					     else
							INSERT INTO #TBLTEMP1 SELECT '+CONVERT(VARCHAR,@CCID)+','''+@FEATURENAME+''',NODEID,NAME,Code FROM '+@TABLENAME +' 
									 WHERE ParentID='+CONVERT(VARCHAR,@NODEID) 
					     
			-- print(@SQL)
			 EXEC (@SQL)
			SET @I=@I+1
		END
		
		SELECT * FROM #TBLTEMP1
		DROP TABLE #TBLTEMP1
		DROP TABLE #TBLTEMP
		
		SELECT ConvertFromCustomerID FROM COM_Contacts C WITH(NOLOCK)
		LEFT JOIN Acc_Accounts A WITH(nolock) ON A.AccountID=C.FeaturePK
		WHERE C.FeatureID=2 AND ConvertFromCustomerID=@CustomerID

		SELECT ConvertFromCustomerID FROM COM_Address AD WITH(NOLOCK)
		LEFT JOIN Acc_Accounts A WITH(nolock) ON A.AccountID=AD.FeaturePK
		WHERE AD.FeatureID=2 AND ConvertFromCustomerID=@CustomerID

		SELECT ConvertFromCustomerID FROM COM_CostCenterCostCenterMap CCM WITH(NOLOCK)
		LEFT JOIN Acc_Accounts A WITH(nolock) ON A.AccountID=CCM.ParentNodeID
		WHERE CCM.ParentCostCenterID=2 AND ConvertFromCustomerID=@CustomerID
		  
COMMIT TRANSACTION
SET NOCOUNT OFF;
RETURN @CustomerID
END TRY
BEGIN CATCH  
	--Return exception info [Message,Number,ProcedureName,LineNumber]  
	IF ERROR_NUMBER()=50000
	BEGIN
		SELECT ErrorMessage,ErrorNumber FROM COM_ErrorMessages WITH(nolock) WHERE ErrorNumber=ERROR_MESSAGE() AND LanguageID=@LangID
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

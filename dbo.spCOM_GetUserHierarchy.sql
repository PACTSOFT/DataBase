USE PACT2C222
GO
SET ANSI_NULLS, QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spCOM_GetUserHierarchy]
	@UserID [bigint] = 1,
	@FEATURE [bigint] = 0,
	@LangID [int] = 1
WITH ENCRYPTION, EXECUTE AS CALLER
AS
BEGIN TRANSACTION
BEGIN TRY	
SET NOCOUNT ON

		--Declaration Section
		DECLARE @USERNAME NVARCHAR(300)
		SELECT @USERNAME=UserName FROM ADM_Users WITH(NOLOCK) WHERE UserID=@UserID
		DECLARE @TABLE TABLE(ID INT IDENTITY(1,1),USERNAME NVARCHAR(300),USERID INT)
		--GET ASSIGNED USERS BY GROUP OWNER
		INSERT INTO @TABLE
		select UserName,UserID from dbo.adm_users WITH(NOLOCK) where userid in (select nodeid from dbo.COM_CostCenterCostCenterMap WITH(NOLOCK) where 
		Parentcostcenterid=7 and costcenterid=7 and ParentNodeid=@UserID) 
		union 
		select UserName,UserID from adm_users where Userid=@UserID
		
		--GET ASSIGNED USERS
		INSERT INTO @TABLE
		SELECT USERNAME,UserID FROM ADM_Users WITH(NOLOCK) WHERE UserID IN (
		SELECT   UserID from CRM_Assignment with(nolock) where CCID=@FEATURE  and IsTeam=0
		AND UserID=@UserID) --and CCNODEID=A.LeadID

		--GET GROUP USERS
		INSERT INTO @TABLE
		SELECT USERNAME,UserID FROM ADM_Users WITH(NOLOCK) WHERE UserID IN 
		( select UserID from COM_GROUPS with(nolock) where   GROUPNAME<>'' AND UserID=@UserID AND GID  IN    
		(select teamnodeid from CRM_Assignment with(nolock) where CCID=@FEATURE   and ISGROUP=1) ) 
		
		--GET ROLES USERS
		INSERT INTO @TABLE
		SELECT USERNAME,UserID FROM ADM_Users WITH(NOLOCK) WHERE UserID IN (
		select  UserID from ADM_UserRoleMap with(nolock) where ROLEID IN    
		(select teamnodeid from CRM_Assignment with(nolock) where CCID=@FEATURE AND UserID=@UserID and ISROLE=1) )

		--GET TEAM USERS
		INSERT INTO @TABLE
		SELECT USERNAME,UserID FROM ADM_Users WITH(NOLOCK) WHERE UserID IN
		(select userid from crm_teams with(nolock) where isowner=0 and  teamid in              
		( select teamnodeid from CRM_Assignment with(nolock) where CCID=@FEATURE AND UserID=@UserID and IsTeam=1))  
			
	   	INSERT INTO @TABLE --GET  GROUP OWNER BY ASSIGNED USER
	   	SELECT USERNAME,UserID FROM ADM_Users WITH(NOLOCK) WHERE UserID IN(
		 select UserID from CRM_Assignment with(nolock) where CCID=@FEATURE
	    AND USERID IN ( 
	    select nodeid from dbo.COM_CostCenterCostCenterMap with(nolock) where 
	   Parentcostcenterid=7 and costcenterid=7 and ParentNodeid=@UserID) )
		
 		
		-- TO GET SUB CHILD ITEMS  FROM CHILD ITEMS
		/*    A
			  |	
			|   |	
			B   C
		
		TO GET 'B' USERS AND 'C' USERS   
		*/
		CREATE TABLE #TblUsers(iUserID int)
		CREATE TABLE #TblQueue(iUserID int)
		Create TABLE #TblTemp (ID int identity(1,1), iUserID int)
		declare @i int
		declare @iTemp int
		declare @iTempUserID int
		declare @QueueLen int
		declare @DUSERID int
		
		SET @DUSERID=@UserID
		SET @QueueLen=1

		INSERT INTO #TblQueue 
		select @DUSERID

		WHILE @QueueLen<>0
		BEGIN

		SET @DUSERID=(select top 1 iUserID from #TblQueue)
		INSERT INTO #TblUsers
		SELECT @DUSERID

		delete from #TblQueue where iUserID=@DUSERID

		INSERT INTO #TblTemp(iUserID)
		select nodeid from dbo.COM_CostCenterCostCenterMap WITH(NOLOCK) where 
		 Parentcostcenterid=7 and costcenterid=7 and ParentNodeid=@DUSERID
 
 		SET @i=(select count(ID) from #TblTemp)
 		 
		WHILE @i<>0
		BEGIN 
		SET @iTempUserID=(select iUserID from #TblTemp WHERE ID=@i)
		SET @iTemp=(select count(*) from #TblQueue where iUserID=@iTempUserID)
		IF @iTemp = 0
		BEGIN
			SET @iTemp=(select count(*) from #TblUsers where iUserID=@iTempUserID) 
			IF @iTemp = 0
			BEGIN
				INSERT INTO #TblQueue
				SELECT @iTempUserID
			END
		END
		SET @i=@i-1
		END
		TRUNCATE TABLE #TblTemp
		SET @QueueLen=(select count(*) from #TblQueue)
		END
		
		INSERT INTO @TABLE
		SELECT USERNAME,UserID FROM ADM_Users WITH(NOLOCK) WHERE UserID IN (
		select iUserID from #TblUsers WHERE UserID<>@UserID)    
		
		 
		SELECT DISTINCT USERNAME,UserID FROM  @TABLE

COMMIT TRANSACTION
SET NOCOUNT OFF;
RETURN 1
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







 
/****** Object:  StoredProcedure [dbo].[spCom_GetCostCenterSummary]    Script Date: 07/15/2014 16:14:32 ******/
SET ANSI_NULLS ON
GO

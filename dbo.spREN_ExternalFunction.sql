USE PACT2C222
GO
SET ANSI_NULLS, QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spREN_ExternalFunction]
	@CostCenterID [bigint],
	@NodeID [bigint],
	@UserID [int] = 1,
	@LangID [int] = 1
WITH ENCRYPTION, EXECUTE AS CALLER
AS
BEGIN
	
	DECLARE @UserName NVARCHAR(50),@Password NVARCHAR(50),@RoleID INT=28,@CompanyIndex INT
	SELECT @UserName=U.NAME,@Password=C.SNO FROM REN_Contract C WITH(NOLOCK)
	LEFT JOIN dbo.REN_Units U WITH(NOLOCK) ON U.UnitID=C.UnitID
	WHERE C.ContractID=@NodeID 
	
	IF EXISTS (SELECT  AUSR.UserName FROM [PACT2C].[dbo].[ADM_USERS] AUSR WITH(NOLOCK)  
				LEFT JOIN [ADM_USERS] USR WITH(NOLOCK) ON AUSR.UserName = USR.UserName  
				WHERE  AUSR.UserName = @UserName and IsUserDeleted=0)
	BEGIN
		UPDATE [ADM_USERS] SET PASSWORD=@Password WHERE UserName = @UserName
		UPDATE [PACT2C].[dbo].[ADM_USERS] SET PASSWORD=@Password WHERE UserName = @UserName
	END
	ELSE
	BEGIN
		
		SELECT @CompanyIndex=DBIndex FROM [PACT2C].[dbo].[ADM_COMPANY] WITH(NOLOCK)
		WHERE DBName=db_name()
		
		exec spADM_SetUser 
		 '0'
		 ,@RoleID
		 ,@UserName
		 ,@Password
		 ,11
		 ,'1'
		 ,''
		 ,@CompanyIndex
		 ,''
		 ,''
		 ,''
		 ,0
		 ,''
		 ,''
		 ,'admin'
		 ,'a8f17d43-7263-456c-8231-f7d2a15fd96f'
		 ,'admin'
		 ,1
		 ,1
	END			
	
END





GO

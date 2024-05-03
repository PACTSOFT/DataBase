USE PACT2C222
GO
SET ANSI_NULLS, QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spADM_AssignInfo]
	@LocationWhere [nvarchar](max) = null,
	@DivisionWhere [nvarchar](max) = null,
	@UserID [bigint]
WITH ENCRYPTION, EXECUTE AS CALLER
AS
DECLARE @SQL nvarchar(max),@Where nvarchar(max)

	set @Where=''
	if @LocationWhere is not null and @LocationWhere!=''
		set @Where=' and R.RoleID!=1 and R.RoleID IN (select ParentNodeID from COM_CostCenterCostCenterMap with(nolock) where ParentCostCenterID=6 and CostCenterID=50002 and NodeID in ('+@LocationWhere+'))'
	if @DivisionWhere is not null and @DivisionWhere!=''
		set @Where=@Where+' and R.RoleID!=1 and R.RoleID IN (select ParentNodeID from COM_CostCenterCostCenterMap with(nolock) where ParentCostCenterID=6 and CostCenterID=50001 and NodeID in ('+@DivisionWhere+'))'

	--Groups
	SELECT GID,GroupName FROM COM_Groups WITH(NOLOCK)
	Group By GID,GroupName
	HAVING GroupName IS NOT NULL
	ORDER BY GroupName
	   
	--Roles
	SET @SQL='SELECT RoleID, Name FROM ADM_PRoles R WITH(NOLOCK) WHERE StatusID=434'
	if @Where!=''
		SET @SQL=@SQL+@Where
	SET @SQL=@SQL+' ORDER BY Name'
	EXEC(@SQL)
	
	--Getting All Users
	SET @SQL='SELECT distinct U.UserID,U.UserName FROM ADM_Users U WITH(NOLOCK)
	inner join ADM_UserRoleMap R WITH(NOLOCK) ON U.UserID=R.UserId
	WHERE U.StatusID=1'+@Where+'
	ORDER BY U.UserName'
	EXEC(@SQL)
GO

USE PACT2C222
GO
SET ANSI_NULLS, QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spADM_GetClientUserDetails]
	@UserName [nvarchar](500),
	@LangID [int] = 1,
	@EXEVersionNo [nvarchar](max) = ''
WITH ENCRYPTION, EXECUTE AS CALLER
AS
BEGIN TRY     
SET NOCOUNT ON    
    
	--Declaration Section    
	DECLARE @HasAccess bit,@Ret int,@UserID BIGINT,@RoleID BIGINT,@VersionNo nvarchar(50),@EmpID BIGINT,@StatusID int 

	--SP Required Parameters Check    
	if(@UserName='')    
	BEGIN    
		RAISERROR('-100',16,1)    
	END    

	select @UserID=UserID from ADM_Users WITH(NOLOCK) where UserName=@UserName and IsUserDeleted = 0
	select @RoleID=RoleID from ADM_UserRoleMap WITH(NOLOCK)  where UserID =@UserID and IsDefault=1
	
	-- Toget EmpId In MobileApplication START
	SELECT @EmpID=EMP.NodeID 
	FROM COM_CostCenterCostCenterMap CCMAP WITH(NOLOCK),COM_CC50051 EMP WITH(NOLOCK)
	WHERE CCMAP.NodeID=EMP.NodeID AND CCMAP.COSTCENTERID=50051 AND CCMAP.ParentNodeID=@UserID
	----- END		
	
	declare @Dt float
	set @Dt=floor(convert(float,getdate()))
	
	select @StatusID=M.[Status]
	from [COM_CostCenterStatusMap] M WITH(NOLOCK)
	where CostCenterID=7 and NodeID=@UserID and ((FromDate is null and ToDate is null) or (FromDate is not null and FromDate<=@Dt and ToDate is null)
	 or (ToDate is not null and @Dt between FromDate and ToDate))
	
	SELECT a.UserID,a.UserName,a.Password,isnull(@StatusID,a.StatusID) StatusID
	,(select top 1 s.[Status] from dbo.COM_Status s  WITH(NOLOCK) where s.StatusID =isnull(@StatusID,a.StatusID)) [Status]
	,a.DefaultLanguage,r.RoleID,r.RoleType,r.Name,r.ExtraXML,a.Email1,a.IsPassEncr,@EmpID EmpID,a.LocationID,a.DivisionID
	,datediff(d,convert(datetime,a.PwdModifiedOn),getdate()) PwdModifiedDays
	,(SELECT TOP 1 [GUID]+'.'+FileExtension FROM COM_Files WITH(NOLOCK) WHERE FeatureID=7 AND IsProductImage=1 AND FileDescription='USERPHOTO' AND  FeaturePK=a.UserID ) UserPhoto
	FROM dbo.ADM_Users a  WITH(NOLOCK)  
	JOIN [PACT2C].dbo.ADM_Users ADMUSR WITH(NOLOCK) ON ADMUSR.USERNAME collate database_default= a.USERNAME collate database_default 
	join  dbo.ADM_PRoles r  WITH(NOLOCK) on r.RoleID=@RoleID
	WHERE a.IsUserDeleted = 0 and a.UserName=@UserName
	
	set @VersionNo=(select top 1 VersionNo from dbo.ADM_Versions WITH(NOLOCK)  order by CONVERT(int,REPLACE(VersionNo,'.','')) desc)
	if exists(select PatchVersion from PACT2C.dbo.ADM_Patches with(nolock) where Version=@EXEVersionNo)
	begin
		select @VersionNo VersionNo,PatchVersion,FileName,Size,convert(datetime,LastModifiedOn) LastModifiedOn from PACT2C.dbo.ADM_Patches with(nolock) where Version=@EXEVersionNo
		order by FileName		
	end
	else
	begin
		select @VersionNo VersionNo
	end

	SELECT Name,Value FROM ADM_GlobalPreferences WITH(NOLOCK) 
	WHERE Name='LW  Login' or Name='EnableLocationWise' or Name='EnableDivisionWise' or Name='Login' or Name='Registers' or name='Application can Auto-Upgrade' or name='Upgrade Server' or name='Upgrade Server(Local)'
	 or name='IsOffline' or name='PwdHardning' or name='PwdExpiry'
	union	
	select case when FeatureID=50002 THEN 'LocationName' else 'DivisionName' end as Name,Name Value from adm_features with(nolock)
	where FeatureID in(50001,50002)

	IF EXISTS(SELECT Value FROM ADM_GlobalPreferences WITH(NOLOCK)  WHERE Name='EnableLocationWise' AND Value='True')  
	BEGIN  
		---------------
		declare @isemp bit,@empseqno bigint,@emplocseqno bigint
		if exists(select nodeid from com_cc50051 with(nolock) where LoginUserID=@username)
		begin
			set @isemp=1
			select @empseqno = nodeid from com_cc50051 with(nolock) where LoginUserID=@username
		end

		if(@isemp=1)
		begin
			select @emplocseqno= ISNULL(CCNID2,1) FROM COM_CCCCDATA WITH(NOLOCK) WHERE CostCenterID=50051 AND NodeID=@empseqno
			select DISTINCT l.NodeID,l.Code,l.Name,l.IsGroup,l.lft from COM_Location l  WITH(NOLOCK)
			where l.NodeID=@emplocseqno
		end
		else
		begin
			select DISTINCT l.NodeID,l.Code,l.Name,l.IsGroup,l.lft,CASE WHEN ParentCostCenterID=6 THEN ParentNodeID ELSE 0 END RoleID 
			from COM_Location l  WITH(NOLOCK)
			join COM_Location g  WITH(NOLOCK) on l.lft between g.lft and g.rgt 
			join COM_CostCenterCostCenterMap c WITH(NOLOCK) on g.NodeID=c.NodeID and CostCenterID=50002
			where (ParentCostCenterID=7 and ParentNodeID=@UserID) or (ParentCostCenterID=6 and (ParentNodeID=@RoleID 
			or ParentNodeID IN (select M.RoleID 
			from ADM_UserRoleMap M WITH(NOLOCK)
			where M.UserID=@UserID and M.Status=1 and M.IsDefault=0 
			and ((M.FromDate is null and M.ToDate is null) or (M.FromDate is not null and M.FromDate<=@Dt and M.ToDate is null)
			 or (M.ToDate is not null and @Dt between M.FromDate and M.ToDate)))
			 ))
			order by l.IsGroup,l.lft
		end

		---------------
			
		--select DISTINCT l.NodeID,l.Code,l.Name,l.IsGroup,l.lft from COM_Location l  WITH(NOLOCK)
		--join COM_Location g  WITH(NOLOCK) on l.lft between g.lft and g.rgt 
		--join COM_CostCenterCostCenterMap c WITH(NOLOCK) on g.NodeID=c.NodeID and CostCenterID=50002
		--where (ParentCostCenterID=7 and ParentNodeID=@UserID) or (ParentCostCenterID=6 and ParentNodeID=@RoleID)
		--order by l.IsGroup,l.lft
	END
	else
		select 1 Location where 1!=1

	select R.RoleID,R.Name RoleName,R.Description,IsDefault--,M.Status,FromDate,ToDate 
	from ADM_UserRoleMap M WITH(NOLOCK)
	inner join ADM_PRoles R with(nolock) on R.RoleID=M.RoleID
	where UserID=@UserID and M.Status=1 and IsDefault=0 and R.RoleID!=@RoleID
	and ((FromDate is null and ToDate is null) or (FromDate is not null and FromDate<=@Dt and ToDate is null)
	 or (ToDate is not null and @Dt between FromDate and ToDate))
	union all
	select RoleID,Name RoleName,Description,1  from ADM_PRoles WITH(NOLOCK) where RoleID=@RoleID
	order by IsDefault desc,RoleName

	--IF EXISTS(SELECT Value FROM ADM_GlobalPreferences WITH(NOLOCK)  WHERE Name='EnableDivisionWise' AND Value='True') 
	--BEGIN  
	--	select DISTINCT l.NodeID,l.Code,l.Name,l.IsGroup,l.lft from COM_Division l  WITH(NOLOCK)
	--	join COM_Division g WITH(NOLOCK)  on l.lft between g.lft and g.rgt 
	--	join COM_CostCenterCostCenterMap c WITH(NOLOCK) on g.NodeID=c.NodeID and CostCenterID=50001
	--	where (ParentCostCenterID=7 and ParentNodeID=@UserID) or (ParentCostCenterID=6 and ParentNodeID=@RoleID)
	--	order by l.lft
	--END
	--else
	--	select 1 Division where 1!=1

	select  NodeID,parentid,IsGroup,Name+'~'+Code Location from COM_Location  WITH(NOLOCK) 

	select  NodeID,parentid,IsGroup,Name+'~'+Code Division from COM_Division WITH(NOLOCK) 
	
	select DISTINCT RoleID from ADM_UserRoleMap WITH(NOLOCK) where UserID=@UserID and [Status]=2

SET NOCOUNT OFF;    
return @Ret
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
SET NOCOUNT OFF      
RETURN -999       
END CATCH
GO

USE PACT2C222
GO
SET ANSI_NULLS, QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spCOM_GetAttachments]
	@CostCenterID [bigint] = 0,
	@NodeID [bigint] = 0,
	@UserID [bigint]
WITH ENCRYPTION, EXECUTE AS CALLER
AS
if 'True'=(select Value from com_costcenterpreferences with(nolock) where CostCenterID=@CostCenterID and Name='UserWiseAttachments')
begin
	declare @I int,@CNT int,@UID int
	declare @TblFileUsr as Table(ID int identity(1,1),UserID int)
	
	insert into @TblFileUsr(UserID) 
	Values(@UserID)
	
	set @I=1
	set @CNT=1
	while(@I<=@CNT)
	begin
		select @UID=UserID from @TblFileUsr WHERE ID=@I
		
		insert into @TblFileUsr(UserID)
		
		select NodeID 
		from COM_CostCenterCostCenterMap C WITH(NOLOCK)		
		left join @TblFileUsr T on T.UserID=C.NodeID
		where parentcostcenterid=7 and parentnodeid=@UID and costcenterid=7 and T.UserID is null
		
		set @I=@I+1
		select @CNT=count(*) from @TblFileUsr
	end
	
	select CONVERT(DATETIME,ValidTill) ValidTill,CONVERT(DATETIME,IssueDate) IssDate,CONVERT(DATETIME,f.ModifiedDate) ModifiedDate,CONVERT(DATETIME,f.CreatedDate) CreatedDate,F.* 
	from @TblFileUsr T
	inner join ADM_Users U with(nolock) on U.UserID=T.UserID
	inner join COM_Files F with(nolock) on F.CreatedBy=U.UserName
	where FeatureID=@CostCenterID and  FeaturePK=@NodeID  
end
else
begin
	SELECT CONVERT(DATETIME,ValidTill) ValidTill,CONVERT(DATETIME,IssueDate) IssDate,CONVERT(DATETIME,ModifiedDate) ModifiedDate,CONVERT(DATETIME,CreatedDate) CreatedDate,* FROM  COM_Files WITH(NOLOCK)
	WHERE FeatureID=@CostCenterID and  FeaturePK=@NodeID  
end

GO

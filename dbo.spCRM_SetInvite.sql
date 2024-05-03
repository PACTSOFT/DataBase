USE PACT2C222
GO
SET ANSI_NULLS, QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spCRM_SetInvite]
	@CCID [int] = 0,
	@CCNODEID [bigint] = 0,
	@TeamNodeID [bigint] = 0,
	@USERID [bigint] = 0,
	@IsTeam [bit] = 0,
	@UsersList [nvarchar](max) = null,
	@RolesList [nvarchar](max) = null,
	@GroupsList [nvarchar](max) = null,
	@CompanyGUID [nvarchar](50),
	@UserName [nvarchar](50),
	@LangID [int] = 1,
	@InviteComments [nvarchar](max)
WITH ENCRYPTION, EXECUTE AS CALLER
AS
BEGIN TRANSACTION      
BEGIN TRY      
SET NOCOUNT ON;   


DECLARE @ID BIGINT , @IsRole BIT=0, @IsGroup BIT=0 ,@I INT,@COUNT INT ,@USER INT ,@ActivityID bigint

if( @CCNODEID>0)
BEGIN
	if exists(select InviteRefActID  from CRM_Activities where InviteRefActID=@CCNODEID)
	begin 
		delete from CRM_Assignment where IsFromActivity in (select activityid from CRM_Activities with(nolock) where statusid=7 and InviteRefActID=@CCNODEID)
		delete from CRM_Activities where statusid=7 and InviteRefActID=@CCNODEID 
	end 
	INSERT INTO  CRM_Activities
	(ActivityTypeID, ScheduleID, CostCenterID, NodeID, StatusID, Subject, Priority
	, PctComplete, Location, IsAllDayActivity, ActualCloseDate, ActualCloseTime, CustomerID
	, Remarks, AssignUserID, AssignRoleID, AssignGroupID, CompanyGUID, GUID, Description
	, CreatedBy, CreatedDate, ModifiedBy, ModifiedDate, StartDate, EndDate, StartTime, EndTime
	, Alpha1, Alpha2, Alpha3, Alpha4, Alpha5, Alpha6, Alpha7, Alpha8, Alpha9, Alpha10, Alpha11
	, Alpha12, Alpha13, Alpha14, Alpha15, Alpha16, Alpha17, Alpha18, Alpha19, Alpha20
	, Alpha21, Alpha22, Alpha23, Alpha24, Alpha25, Alpha26, Alpha27, Alpha28, Alpha29, Alpha30
	, Alpha31, Alpha32, Alpha33, Alpha34, Alpha35, Alpha36, Alpha37, Alpha38, Alpha39, Alpha40
	, Alpha41, Alpha42, Alpha43, Alpha44, Alpha45, Alpha46, Alpha47, Alpha48, Alpha49, Alpha50
	, CCNID1, CCNID2, CCNID3, CCNID4, CCNID5, CCNID6, CCNID7, CCNID8, CCNID9, CCNID10
	, CCNID11, CCNID12, CCNID13, CCNID14, CCNID15, CCNID16, CCNID17, CCNID18, CCNID19, CCNID20
	, CCNID21, CCNID22, CCNID23, CCNID24, CCNID25, CCNID26, CCNID27, CCNID28, CCNID29, CCNID30
	, CCNID31, CCNID32, CCNID33, CCNID34, CCNID35, CCNID36, CCNID37, CCNID38, CCNID39, CCNID40
	, CCNID41, CCNID42, CCNID43, CCNID44, CCNID45, CCNID46, CCNID47, CCNID48, CCNID49, CCNID50
	, AccountID, RefNo, CustomerType, InviteComments, InviteStatus)
	SELECT 
	 ActivityTypeID, ScheduleID, CostCenterID, NodeID, 7, Subject, Priority, PctComplete  
	, Location, IsAllDayActivity, ActualCloseDate, ActualCloseTime, CustomerID, Remarks, AssignUserID, AssignRoleID, AssignGroupID
	, CompanyGUID, GUID, Description, @UserName, CONVERT(FLOAT,GETDATE()), '', NULL, StartDate, EndDate, StartTime, EndTime
	, Alpha1, Alpha2, Alpha3, Alpha4, Alpha5, Alpha6, Alpha7, Alpha8, Alpha9, Alpha10
	, Alpha11, Alpha12, Alpha13, Alpha14, Alpha15, Alpha16, Alpha17, Alpha18, Alpha19, Alpha20
	, Alpha21, Alpha22, Alpha23, Alpha24, Alpha25, Alpha26, Alpha27, Alpha28, Alpha29, Alpha30
	, Alpha31, Alpha32, Alpha33, Alpha34, Alpha35, Alpha36, Alpha37, Alpha38, Alpha39, Alpha40
	, Alpha41, Alpha42, Alpha43, Alpha44, Alpha45, Alpha46, Alpha47, Alpha48, Alpha49, Alpha50
	, CCNID1, CCNID2, CCNID3, CCNID4, CCNID5, CCNID6, CCNID7, CCNID8, CCNID9, CCNID10
	, CCNID11, CCNID12, CCNID13, CCNID14, CCNID15, CCNID16, CCNID17, CCNID18, CCNID19, CCNID20
	, CCNID21, CCNID22, CCNID23, CCNID24, CCNID25, CCNID26, CCNID27, CCNID28, CCNID29, CCNID30
	, CCNID31, CCNID32, CCNID33, CCNID34, CCNID35, CCNID36, CCNID37, CCNID38, CCNID39, CCNID40
	, CCNID41, CCNID42, CCNID43, CCNID44, CCNID45, CCNID46, CCNID47, CCNID48, CCNID49, CCNID50
	, AccountID, RefNo, CustomerType,@InviteComments,''  FROM CRM_ACTIVITIES WHERE ACTIVITYID=@CCNODEID
	set @ActivityID=scope_identity() 
END

	declare @CostCenterID bigint, @NodeID bigint
	select @CostCenterID=costcenterid, @NodeID = nodeid from CRM_ACTIVITIES WHERE ACTIVITYID= @ActivityID

  	EXEC [spCRM_SetActivityAssignment] @CostCenterID,@NodeID,@TeamNodeID,@USERID,@IsTeam,@UsersList,@RolesList,@GroupsList,@CompanyGUID,
						@UserName,@LangID,@ActivityID
	
	create table #temp (id int identity(1,1),AssignmentID bigint, ActivityID bigint, UserID bigint)
	insert into #temp
	select AssignmentID, IsFromActivity, UserID from CRM_Assignment where IsFromActivity=@ActivityID
	declare @acnt int, @cnt int, @AssignmentID bigint, @tempActID bigint, @tempUId bigint
	set @acnt=1
	select @cnt=COUNT(*) from #temp
	while @acnt<=@cnt
	begin
	
		set @tempActID=0
		select @AssignmentID=assignmentid,@tempUId=UserID  from #temp where id=@acnt
		
		if not exists( select assignmentid from CRM_Assignment where UserID=@tempUId and IsFromActivity in 
		(select activityid from CRM_Activities where InviteRefActID=@CCNODEID))
		begin 
			INSERT INTO  CRM_Activities
			(ActivityTypeID, ScheduleID, CostCenterID, NodeID, StatusID, Subject, Priority
			, PctComplete, Location, IsAllDayActivity, ActualCloseDate, ActualCloseTime, CustomerID
			, Remarks, AssignUserID, AssignRoleID, AssignGroupID, CompanyGUID, GUID, Description
			, CreatedBy, CreatedDate, ModifiedBy, ModifiedDate, StartDate, EndDate, StartTime, EndTime
			, Alpha1, Alpha2, Alpha3, Alpha4, Alpha5, Alpha6, Alpha7, Alpha8, Alpha9, Alpha10, Alpha11
			, Alpha12, Alpha13, Alpha14, Alpha15, Alpha16, Alpha17, Alpha18, Alpha19, Alpha20
			, Alpha21, Alpha22, Alpha23, Alpha24, Alpha25, Alpha26, Alpha27, Alpha28, Alpha29, Alpha30
			, Alpha31, Alpha32, Alpha33, Alpha34, Alpha35, Alpha36, Alpha37, Alpha38, Alpha39, Alpha40
			, Alpha41, Alpha42, Alpha43, Alpha44, Alpha45, Alpha46, Alpha47, Alpha48, Alpha49, Alpha50
			, CCNID1, CCNID2, CCNID3, CCNID4, CCNID5, CCNID6, CCNID7, CCNID8, CCNID9, CCNID10
			, CCNID11, CCNID12, CCNID13, CCNID14, CCNID15, CCNID16, CCNID17, CCNID18, CCNID19, CCNID20
			, CCNID21, CCNID22, CCNID23, CCNID24, CCNID25, CCNID26, CCNID27, CCNID28, CCNID29, CCNID30
			, CCNID31, CCNID32, CCNID33, CCNID34, CCNID35, CCNID36, CCNID37, CCNID38, CCNID39, CCNID40
			, CCNID41, CCNID42, CCNID43, CCNID44, CCNID45, CCNID46, CCNID47, CCNID48, CCNID49, CCNID50
			, AccountID, RefNo, CustomerType, InviteComments, InviteStatus, InviteRefActID)
			SELECT 
			 ActivityTypeID, ScheduleID, CostCenterID, NodeID, 7, Subject, Priority, PctComplete  
			, Location, IsAllDayActivity, ActualCloseDate, ActualCloseTime, CustomerID, Remarks, AssignUserID, AssignRoleID, AssignGroupID
			, CompanyGUID, GUID, Description, @UserName, CONVERT(FLOAT,GETDATE()), '', NULL, StartDate, EndDate, StartTime, EndTime
			, Alpha1, Alpha2, Alpha3, Alpha4, Alpha5, Alpha6, Alpha7, Alpha8, Alpha9, Alpha10
			, Alpha11, Alpha12, Alpha13, Alpha14, Alpha15, Alpha16, Alpha17, Alpha18, Alpha19, Alpha20
			, Alpha21, Alpha22, Alpha23, Alpha24, Alpha25, Alpha26, Alpha27, Alpha28, Alpha29, Alpha30
			, Alpha31, Alpha32, Alpha33, Alpha34, Alpha35, Alpha36, Alpha37, Alpha38, Alpha39, Alpha40
			, Alpha41, Alpha42, Alpha43, Alpha44, Alpha45, Alpha46, Alpha47, Alpha48, Alpha49, Alpha50
			, CCNID1, CCNID2, CCNID3, CCNID4, CCNID5, CCNID6, CCNID7, CCNID8, CCNID9, CCNID10
			, CCNID11, CCNID12, CCNID13, CCNID14, CCNID15, CCNID16, CCNID17, CCNID18, CCNID19, CCNID20
			, CCNID21, CCNID22, CCNID23, CCNID24, CCNID25, CCNID26, CCNID27, CCNID28, CCNID29, CCNID30
			, CCNID31, CCNID32, CCNID33, CCNID34, CCNID35, CCNID36, CCNID37, CCNID38, CCNID39, CCNID40
			, CCNID41, CCNID42, CCNID43, CCNID44, CCNID45, CCNID46, CCNID47, CCNID48, CCNID49, CCNID50
			, AccountID, RefNo, CustomerType, InviteComments, InviteStatus,@CCNODEID   FROM CRM_ACTIVITIES WHERE ACTIVITYID=@ActivityID 
			set @tempActID=scope_identity() 
			update CRM_Assignment set IsFromActivity=@tempActID where AssignmentID=@AssignmentID 
		end
		else 
		begin
			delete from CRM_Assignment where AssignmentID=@AssignmentID
		end
		set @acnt=@acnt+1
	end 
	delete from CRM_Activities where ActivityID =@ActivityID
						
						
COMMIT TRANSACTION  
SET NOCOUNT OFF; 
RETURN @ActivityID 
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
ROLLBACK TRANSACTION    
SET NOCOUNT OFF      
RETURN -999       
END CATCH    
    
    
    
GO

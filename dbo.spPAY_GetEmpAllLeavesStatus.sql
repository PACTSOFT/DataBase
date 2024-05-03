USE PACT2C222
GO
SET ANSI_NULLS, QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spPAY_GetEmpAllLeavesStatus]
	@EmployeeID [varchar](20) = '442',
	@CostCenterID [int] = 50051,
	@PayrollDate [datetime] = '01-apr-2019'
WITH ENCRYPTION, EXECUTE AS CALLER
AS
BEGIN          
      
 DECLARE @GRADE as int      
 DECLARE @TotCount int     
 DECLARE @Counter int     
 DECLARE @TotAssign int     
 DECLARE @TotTaken int       
 DECLARE @LeaveId int     
 DECLARE @CURRDATE DATETIME    
 SET @CURRDATE=GETDATE()    
 DECLARE @FromDate DATETIME    
 DECLARE @ToDate DATETIME    
 SELECT @GRADE=ISNULL(CCNID53,0) FROM COM_CCCCData WITH(NOLOCK) WHERE CostCenterID=50051 AND NodeID=@EmployeeID         
 --print @GRADE    
 CREATE TABLE #EmpLeaveList (ID INT IDENTITY(1,1),LeaveId varchar(50),LeaveName varchar(100),ShortName varchar(5),TotAssignLeave float,TakenLeave float,Balance float)    
     
 INSERT INTO #EmpLeaveList    select Nodeid as LeaveId,Name as LeaveName,Left(isnull(AliasName,''),2) as ShortName,0,0,0 from COM_CC50052  where NodeId in ( SELECT  componentid FROM COM_CC50054 WITH(NOLOCK)         
 WHERE GradeID=@Grade and CONVERT(DATETIME,PAYROLLDATE)>=CONVERT(DATETIME,@PayrollDate) and type=4)     
 --select * from #EmpLeaveList    
 select @TotCount= count(*) from #EmpLeaveList      
  SET @Counter=1     
    
 WHILE (@Counter<=@TotCount)    
 BEGIN     
  SELECT @LeaveId=LeaveId FROM #EmpLeaveList WHERE ID=@Counter     
  --set @LeaveId=12      
  declare @EssTempTable table(TotAssign float,a varchar(20),b datetime,c datetime,d varchar(20),e varchar(20),f varchar(20),g varchar(20))      
  insert into @EssTempTable    
  Exec [spPAY_ExtGetAssignedLeaves] @EmployeeID,@LeaveId,@CURRDATE       
  select @TotAssign= TotAssign,@FromDate=b,@ToDate=c from @EssTempTable     
    
SELECT @TotTaken=isnull(td.dcalpha7,0)     
FROM   COM_DocTextData td,COM_DocccData dc,inv_docdetails id ,COM_CC50052 lt    
WHERE  id.invdocdetailsid=td.invdocdetailsid     
    and id.invdocdetailsid=dc.invdocdetailsid    
    and td.invdocdetailsid=dc.invdocdetailsid    
    and id.statusid not in (372,376)    
    and lt.nodeid=DC.dcccnid52    
    and id.COSTCENTERID=40062    
    and dc.dcccnid51=442    
   AND DC.DCCCNID52=@LeaveId    
    and (    
        CONVERT(DATETIME,dcAlpha4) between CONVERT(DATETIME,@FromDate) and CONVERT(DATETIME,@ToDate)    
     or CONVERT(DATETIME,dcAlpha5) between CONVERT(DATETIME,@FromDate) and CONVERT(DATETIME,@ToDate)    
     or CONVERT(DATETIME,@FromDate) between CONVERT(DATETIME,dcAlpha4) and CONVERT(DATETIME,dcAlpha5)    
     or CONVERT(DATETIME,@ToDate) between CONVERT(DATETIME,dcAlpha4) and CONVERT(DATETIME,dcAlpha4))     
      
      
  update #EmpLeaveList set  TotAssignLeave=@TotAssign,TakenLeave=@TotTaken WHERE ID=@Counter     
      
  set @TotAssign=0    
  set @TotTaken=0    
  delete from @EssTempTable    
          
 SET @Counter=@Counter+1    
 END    
     
 select  LeaveId,  LeaveName,ShortName,isnull(TotAssignLeave,0) as TotAssignLeave ,isnull(TakenLeave,0) as TakenLeave,isnull(TotAssignLeave-TakenLeave,0) as Balance
 --,58 as Percentage,((TakenLeave/TotAssignLeave)*100) as Percentage1 from #EmpLeaveList   
  ,58-TotAssignLeave as Percentage  from #EmpLeaveList   
     
 drop table #EmpLeaveList    
         
     
     
     
     
                
                
     
      
       
          
         
END 
GO

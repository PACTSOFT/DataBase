USE PACT2C222
GO
SET ANSI_NULLS, QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spRpt_RentalReportsNew]
	@ReportType [bigint],
	@FromDate [datetime],
	@ToDate [datetime],
	@WHERE1 [nvarchar](max),
	@WHERE2 [nvarchar](max),
	@FromTag [nvarchar](max),
	@SelectTag [nvarchar](max),
	@MaxSelectTag [nvarchar](max),
	@OrderBy [nvarchar](max),
	@UserID [bigint],
	@LangID [int]
WITH ENCRYPTION, EXECUTE AS CALLER
AS
Begin Try    
SET NOCOUNT ON;  
DECLARE @SQL NVARCHAR(MAX),@From nvarchar(50),@To nvarchar(50),@Tbl nvarchar(20),@TblCol nvarchar(50)
SET @From=convert(nvarchar,CONVERT(FLOAT,@FromDate))
SET @To=convert(nvarchar,CONVERT(FLOAT,@ToDate))


IF @ReportType=73--GetPropertyProfitSummary
BEGIN
	SET @SQL=' SELECT P.Name [Property],U.Name [Unit],T.FirstName [Tenant],CONVERT(DATETIME,C.StartDate) [StartDate],CONVERT(DATETIME,C.EndDate) EndDate,CONVERT(DATETIME,C.TerminationDate) TerminationDate,RS.Status ContractStatus,C.ContractNumber,U.AnnualRent,
CP.Amount TotalAmount,CASE WHEN CONVERT(DATETIME,C.EndDate)  >= '+@From+'  THEN  CP.Amount  else 0 end AS ActiveAmount,
0.0 RentDay,0.0 ReportDays,0.0 RentMonth,0.0 RentAmountMonth,0.0 RentTotMonths,0.0 Rent,C.SNO,C.SNO TrackNo,T.Phone1 Phone1,U.Lft UnitLft '+@SelectTag+'
FROM REN_Property P with(nolock) 
JOIN REN_Contract C with(nolock) ON C.PropertyID=P.NodeID AND C.IsGroup <> 1 AND C.COSTCENTERID = 95
LEFT JOIN COM_STATUS RS with(nolock) ON  RS.StatusID=C.StatusID 
JOIN REN_Units U with(nolock)  ON C.UnitID=U.UnitID AND CONVERT(DATETIME,C.StartDate) <= '+@To+' AND CONVERT(DATETIME,ISNULL(C.TerminationDate,C.EndDate)) >= '+@From+'     
JOIN REN_Tenant T with(nolock) ON  C.TenantID=T.TenantID 
JOIN REN_ContractParticulars CP with(nolock) ON C.CONTRACTID = CP.CONTRACTID  AND CP.SNO = 1'+@FromTag+'
where C.StatusID <>451  AND C.CONTRACTID NOT IN (SELECT RenewRefID FROM REN_Contract with(nolock) 
WHERE RenewRefID>0 AND CONVERT(DATETIME,StartDate) <= '+@To+' AND CONVERT(DATETIME,ISNULL(TerminationDate,EndDate)) >= '+@From+' )  
'+@WHERE1+'
order by P.Name'+@OrderBy  -- AND C.STATUSID <> 428 earlier we were filtering terminated records here
	EXEC(@SQL)
END
ELSE IF @ReportType=209--Contract Due for Renewal
BEGIN
	SET @SQL='declare @todate datetime
set @todate=convert(datetime,'+@To+')
SELECT contractid,MAX(Sno) Sno,MAX(Property) Property,MAX(Unit) Unit,MAX(Tenant) Tenant,MAX(Phone1) Phone1,MAX(Phone2) Phone2,MAX(Purpose) Purpose,
MAX(StartDate) StartDate,MAX(EndDate) EndDate,MAX(Rent) Rent,MAX(TotalAmount) TotalAmount,MAX(UnitStatus) UnitStatus,MAX(NoOfDays) NoOfDays,
MIN([Status]) [Status],MAX(UnitID) UnitID'+@MaxSelectTag+'
FROM (
SELECT distinct C.contractid,C.Sno, 
P.Name Property,U.Name Unit,
T.FirstName Tenant,T.Phone1 Phone1,
T.Phone2 Phone2,C.Purpose Purpose,
CONVERT(DATETIME,C.StartDate) StartDate,
CONVERT(DATETIME,C.EndDate) EndDate,
(CP.RentAmount -isnull(Discount,0))  Rent,
C.TotalAmount TotalAmount, L.Name UnitStatus,
datediff(day,CONVERT(DATETIME,C.EndDate),@todate) NoOfDays,''Pending'' [Status],U.UnitID'+@SelectTag+'
FROM REN_Contract C with(nolock)
left join ren_contract CU on CU.RefContractID=C.ContractID
join REN_Property P with(nolock) on C.PropertyID=P.NodeID
join REN_Units U with(nolock) on C.UnitID=U.UnitID
left join com_lookup L with(nolock) on U.unitstatus=L.nodeid
join REN_Tenant T with(nolock) on C.TenantID=T.TenantID 
left join REN_ContractParticulars CP with(nolock) on C.CONTRACTID=CP.CONTRACTID  and CP.CCNodeID=3 '+@FromTag+'
join (select UnitID,max(EndDate) EndDate from
		(select C.UnitID,max(C.EndDate) EndDate from ren_contract C with(nolock) left join ren_contract CU with(nolock) on CU.RefContractID=C.ContractID where CU.ContractID is null group by C.UnitID
		union all
		select CU.UnitID,max(C.EndDate) EndDate from ren_contract C with(nolock) inner join ren_contract CU with(nolock) on CU.RefContractID=C.ContractID group by CU.UnitID) as t
	group by UnitID) T6 ON (CU.UnitID is not null and T6.UnitID=CU.UnitID and T6.EndDate=C.EndDate) or (T6.UnitID=C.UnitID and T6.EndDate=C.EndDate)
WHERE convert(datetime,C.EndDate) <= @todate and (C.statusid=427 or C.statusid=426) '+@WHERE1+'
union all
SELECT distinct C.contractid,C.Sno, 
P.Name Property,U.Name Unit,
T.FirstName Tenant,T.Phone1 Phone1,
T.Phone2 Phone2,C.Purpose Purpose,
CONVERT(DATETIME,C.StartDate) StartDate,
CONVERT(DATETIME,C.EndDate) EndDate,
(CP.RentAmount -isnull(Discount,0)) Rent,
C.TotalAmount TotalAmount, L.Name UnitStatus,
datediff(day,CONVERT(DATETIME,C.EndDate),@todate) NoOfDays,''Un-Approved'' [Status],U.UnitID'+@SelectTag+'
FROM REN_Contract C with(nolock)
left join ren_contract CU on CU.RefContractID=C.ContractID
join REN_Property P with(nolock) on C.PropertyID=P.NodeID
join REN_Units U with(nolock) on C.UnitID=U.UnitID
left join com_lookup L with(nolock) on U.unitstatus=L.nodeid
join REN_Tenant T with(nolock) on C.TenantID=T.TenantID 
left join REN_ContractParticulars CP with(nolock) on C.CONTRACTID=CP.CONTRACTID  and CP.CCNodeID=3 '+@FromTag+'
join (select UnitID,max(EndDate) EndDate from
		(select C.UnitID,max(C.EndDate) EndDate from ren_contract C with(nolock) left join ren_contract CU with(nolock) on CU.RefContractID=C.ContractID where CU.ContractID is null and c.statusid<>440 group by C.UnitID
		union all
		select CU.UnitID,max(C.EndDate) EndDate from ren_contract C with(nolock) inner join ren_contract CU with(nolock) on CU.RefContractID=C.ContractID where c.statusid<>440 group by CU.UnitID) as T
	group by UnitID) T6 ON (CU.UnitID is not null and T6.UnitID=CU.UnitID and T6.EndDate=C.EndDate) or (T6.UnitID=C.UnitID and T6.EndDate=C.EndDate)
WHERE convert(datetime,C.EndDate) <= @todate and  (C.statusid=427 or C.statusid=426)  '+@WHERE1+' )
AS T
GROUP BY contractid
ORDER BY Property,UnitID'
--print(@SQL)
	EXEC(@SQL)
END
ELSE IF @ReportType=210--Contract Due for Renewal
BEGIN
	SET @SQL='SELECT P.Name PName,U.Name UName,T.LeaseSignatory LeaseSignatory,T.Email TEmail,T.Phone1 TPhone1,T.Fax TFax,
CONVERT(DATETIME,C.StartDate) StartDate,CONVERT(DATETIME,C.EndDate) EndDate,
CP.RentAmount RentAmount,CP.Discount Discount,CP.Amount Amount,C.TotalAmount'+@SelectTag+'
FROM REN_Contract C with(nolock)
join REN_Property P with(nolock) on C.PropertyID=P.NodeID
join REN_Units U with(nolock) on C.UnitID=U.UnitID
join REN_Tenant T with(nolock) on C.TenantID=T.TenantID
join REN_ContractParticulars CP with(nolock) on C.CONTRACTID=CP.CONTRACTID  AND CP.SNO = 1
'+@FromTag+'
WHERE C.STATUSID not in (428,450,451) and U.unitid not in (select unitid from REN_Contract with(nolock) where ContractID in  (SELECT CASE WHEN STATUSID=450 THEN MAX(CONTRACTID) ELSE MIN(ContractID) END
 FROM REN_Contract with(nolock)
WHERE  UnitID=U.UnitID  AND PropertyID=C.PropertyID  AND CONVERT(DATETIME,STARTDATE) <=(dateadd(day,90,getdate()))  AND CONVERT(DATETIME,EndDate) >=(dateadd(day,90,getdate())) 
GROUP BY UnitID,PropertyID,StatusID, StartDate))   
and convert(datetime,C.EndDate) between getdate() and (dateadd(day,90,getdate())) 
'+@WHERE1+'
ORDER BY PName,U.NAME'
 	EXEC(@SQL)
END
ELSE IF @ReportType=211--Daily Activity Report
BEGIN
	SET @SQL='
DECLARE @FROM FLOAT,@TO FLOAT
SET @FROM='+@From+'
SET @TO='+@To+'

SELECT P.Name PropertyName,P.Code PropertyCode,U.Name UnitName,U.Code UnitCode,T.FirstName TenantName,C.TotalAmount,CP.Amount,CP.RentAmount,CS.[Status],C.CreatedBy,C.SNO SNO,
CONVERT(DATETIME,C.ContractDate) ContractDate,CONVERT(DATETIME,C.StartDate) StartDate,CONVERT(DATETIME,C.EndDate) EndDate,CONVERT(DATETIME,C.TerminationDate) TerminationDate,CONVERT(DATETIME,C.VacancyDate) VacancyDate,CONVERT(DATETIME,C.RefundDate) RefundDate,
--CONVERT(DATETIME,ISNULL(C.VacancyDate,( CASE WHEN C.StatusID=450 THEN ISNULL(C.RefundDate,C.VacancyDate) ELSE C.ContractDate END )))  TransactionDate
(CASE when C.StatusID=450 then ISNULL(CONVERT(DATETIME,C.RefundDate),CONVERT(DATETIME,C.VacancyDate)) ELSE (CASE when C.StatusID=428 then CONVERT(DATETIME,TerminationDate) else CONVERT(DATETIME,ContractDate) END) END) TransactionDate
'+@SelectTag+'
FROM REN_Contract C WITH(NOLOCK)
JOIN REN_Property P WITH(NOLOCK) ON P.NodeID=C.PropertyID
JOIN REN_Units U WITH(NOLOCK) ON U.UnitID=C.UnitID
JOIN REN_Tenant T WITH(NOLOCK) ON T.TenantID=C.TenantID
JOIN REN_ContractParticulars CP WITH(NOLOCK) ON CP.ContractID=C.ContractID AND CP.Sno=1 
JOIN COM_Status CS WITH(NOLOCK) ON CS.StatusID=C.StatusID AND CS.CostCenterID=95
'+@FromTag+'
WHERE C.CostCenterID=95 
--AND ISNULL(C.VacancyDate,( CASE WHEN C.StatusID=450 THEN ISNULL(C.RefundDate,C.VacancyDate) ELSE C.ContractDate END )) BETWEEN FROM AND @TO
AND (Case when C.statusid=450 then ISNULL(convert(datetime,C.RefundDate),convert(datetime,C.VacancyDate)) else (Case when C.Statusid=428 then convert(datetime,TerminationDate) else convert(datetime,ContractDate) END) END) BETWEEN @FROM AND @TO
'+@WHERE1+'
ORDER BY P.Name,U.Name'
 	EXEC(@SQL)
END
ELSE IF @ReportType=212 or @ReportType=213--Unit Vacant List
BEGIN
	SET @SQL='
DECLARE @FROM FLOAT
SET @FROM='+@From+'
DECLARE @UnitID BIGINT,@StatusID BIGINT,@TotalAmount FLOAT,@I INT,@COUNT INT,@ContractID BIGINT
DECLARE @NoofDays INT,@VacantSince DATETIME

DECLARE @TAB TABLE(ID INT IDENTITY(1,1) PRIMARY KEY,UnitID BIGINT,CurrentRent FLOAT,Status NVARCHAR(10),NoofDays INT,VacantSince DATETIME)

INSERT INTO @TAB (UnitID)
SELECT RU.UnitID
FROM REN_Units RU WITH(NOLOCK) 
LEFT JOIN REN_Property RP WITH(NOLOCK) ON RP.NodeID=RU.PropertyID
left join COM_Lookup LK WITH(NOLOCK) on RU.UnitStatus=lk.NodeID
WHERE RU.UnitID>1 AND RP.Name <> RU.Name AND RU.IsGroup=0 AND RU.Status=424 and ru.UnitStatus=306 
'+@WHERE1+'
SELECT @I=1,@COUNT=COUNT(*) FROM @TAB
WHILE(@I<=@COUNT)
BEGIN
	SET @StatusID=0
	SET @TotalAmount=0
	SET @ContractID=0
	SELECT @UnitID=UnitID FROM @TAB WHERE ID=@I

	SELECT TOP 1 @ContractID=CONTRACTID,@StatusID=StatusID
	,@VacantSince=(CASE WHEN StatusID = 450 THEN ( CASE WHEN RefundDate IS NOT NULL THEN CONVERT(DATETIME,RefundDate) ELSE CONVERT(DATETIME,VacancyDate) END ) 
			ELSE CONVERT(DATETIME,TerminationDate) END )
	,@NoofDays=(CASE WHEN StatusID = 450 THEN (CASE WHEN RefundDate IS NOT NULL THEN DATEDIFF(DAY, CONVERT(DATETIME,RefundDate),CONVERT(DATETIME,@FROM) ) 
			ELSE DATEDIFF(DAY, CONVERT(DATETIME,VacancyDate),CONVERT(DATETIME,@FROM) ) END )
			ELSE DATEDIFF(DAY, CONVERT(DATETIME,TerminationDate),CONVERT(DATETIME,@FROM) ) END )  
	FROM REN_Contract WITH(NOLOCK) WHERE StatusID<>451 AND UNITID=@UnitID ORDER BY StartDate DESC
	
	SELECT @TotalAmount=SUM(RentAmount) FROM REN_ContractParticulars WITH(NOLOCK) WHERE ContractID=@ContractID
	
	IF @StatusID=427 OR @StatusID=426 OR @StatusID=466
	BEGIN
		UPDATE @TAB SET CurrentRent=@TotalAmount,Status=''Occupied'',NoofDays=@NoofDays,VacantSince=@VacantSince WHERE ID=@I
	END
	ELSE IF @StatusID=440
	BEGIN
		UPDATE @TAB SET CurrentRent=@TotalAmount,Status=''UnAproved'',NoofDays=@NoofDays,VacantSince=@VacantSince WHERE ID=@I
	END
	ELSE IF @StatusID=428 OR @StatusID=450
	BEGIN 
		IF EXISTS (SELECT * FROM REN_Quotation WITH(NOLOCK) WHERE COSTCENTERID=129 AND UNITID=@UnitID AND CONVERT(DATETIME,@FROM) BETWEEN CONVERT(DATETIME,STARTDATE) AND CONVERT(DATETIME,ENDDATE) and statusid=467 )
			UPDATE @TAB SET CurrentRent=@TotalAmount,Status=''Reserved'',NoofDays=@NoofDays,VacantSince=@VacantSince WHERE ID=@I
		ELSE
			UPDATE @TAB SET CurrentRent=@TotalAmount,Status=''Vacant'',NoofDays=@NoofDays,VacantSince=@VacantSince WHERE ID=@I
	END
	ELSE
	BEGIN 
		IF EXISTS (SELECT * FROM REN_Quotation WITH(NOLOCK) WHERE COSTCENTERID=129 AND UNITID=@UnitID AND CONVERT(DATETIME,@FROM) BETWEEN CONVERT(DATETIME,STARTDATE) AND CONVERT(DATETIME,ENDDATE) and statusid=467 )
			UPDATE @TAB SET CurrentRent=@TotalAmount,Status=''Reserved'',NoofDays=@NoofDays,VacantSince=@VacantSince WHERE ID=@I
		ELSE
			UPDATE @TAB SET CurrentRent=@TotalAmount,Status=''Vacant'',NoofDays=@NoofDays,VacantSince=@VacantSince WHERE ID=@I
	END
	set @I=@I+1
END

SELECT T.*,P.NAME Building,U.NAME UnitNo,C18.NAME UnitType,U.UnitStatus,U.RentableArea UnitArea,U.RentPerSQFT UnitRate,U.AnnualRent EstimatedRent
'+@SelectTag+'
FROM @TAB T
JOIN REN_Units U WITH(NOLOCK) on T.UnitID=U.UnitID
LEFT JOIN REN_Property P WITH(NOLOCK) ON P.NodeID=U.PropertyID
LEFT JOIN COM_CC50018 C18 WITH(NOLOCK) ON C18.NodeID=U.NodeID
'+@FromTag
IF @ReportType=212
	SET @SQL=@SQL+' WHERE (T.Status=''Vacant'' OR T.Status=''Reserved'')'
SET @SQL=@SQL+' order by P.Name,VacantSince'
 	EXEC(@SQL)
END
ELSE IF @ReportType=214--Unit Status Summary
BEGIN
	SET @SQL='DECLARE @FROMDATE FLOAT
SET @FROMDATE=FLOOR(CONVERT(FLOAT,GETDATE()))
DECLARE @TAB TABLE (ID INT IDENTITY(1,1),ContractID BIGINT,StatusID INT,PropertyID BIGINT,UnitID BIGINT,TenantID BIGINT,StartDate FLOAT,EndDate FLOAT)
INSERT INTO @TAB
SELECT RC.ContractID,RC.StatusID,RC.PropertyID,RC.UnitID,RC.TenantID,RC.StartDate,
CASE WHEN RC.StatusID=428 THEN RC.TerminationDate WHEN RC.StatusID=450 THEN ISNULL(RC.RefundDate,RC.VacancyDate) ELSE RC.EndDate END EndDate
FROM REN_Contract RC WITH(NOLOCK)
WHERE RC.ContractID>1 AND RC.CostCenterID=95 AND RC.StartDate<=@FROMDATE

SELECT Property,UnitType,COUNT(*) NoOfUnits'+@MaxSelectTag+'
,SUM(CASE WHEN UnitStatus=''Occupied'' THEN 1 ELSE 0 END) Occupied
,SUM(CASE WHEN UnitStatus=''Expired '' THEN 1 ELSE 0 END) Expired 
,SUM(CASE WHEN UnitStatus=''Vacant'' THEN 1 ELSE 0 END) Vacant FROM (
SELECT P.Name Property,U.Name Unit,UT.Name UnitType
,CASE WHEN RC.StatusID=428 OR RC.StatusID=450 THEN ''Vacant'' WHEN RC.EndDate <= @FROMDATE THEN ''Expired'' ELSE ''Occupied''  END UnitStatus 
'+@SelectTag+'
FROM @TAB RC
JOIN (SELECT UnitID ,MAX(StartDate) StartDate FROM @TAB GROUP BY UnitID) AS T2 ON T2.UnitID=RC.UnitID AND T2.StartDate=RC.StartDate
JOIN REN_Units U WITH(NOLOCK) ON U.UnitID=RC.UnitID
JOIN REN_Property P WITH(NOLOCK) ON P.NodeID=RC.PropertyID
JOIN COM_CC50018 UT WITH(NOLOCK) ON UT.NodeID=U.NodeID'+@FromTag+'
WHERE U.ContractID=0  '+@WHERE1+'
UNION
SELECT P.Name Property,U.Name Unit,UT.Name UnitType,''Vacant''
'+@SelectTag+'
FROM REN_Units U WITH(NOLOCK)
JOIN REN_Property P WITH(NOLOCK) ON P.NodeID=U.PropertyID
JOIN COM_CC50018 UT WITH(NOLOCK) ON UT.NodeID=U.NodeID'+@FromTag+'
WHERE U.UnitID>1 AND U.ContractID=0 AND U.IsGroup=0 AND U.UnitID NOT IN (SELECT DISTINCT UnitID FROM REN_Contract WITH(NOLOCK) WHERE ContractID>1) '+@WHERE1+'
) AS T

GROUP BY Property,UnitType'+@MaxSelectTag+'
order by Property'
	EXEC(@SQL)
END
ELSE IF @ReportType=215--Unit Municipality Case Report
BEGIN
	SET @SQL='
Select * from (

SELECT T.FirstName TenantName,
CONVERT(DATETIME,C.StartDate) CStartDate,CONVERT(DATETIME,C.EndDate) CEndDate,
U.Name UnitName, p.Name Tower,
C.TotalAmount,l.name as UnitStatus,u.TermsConditions'+@SelectTag+'
FROM REN_Contract C with(nolock) 
left join REN_Tenant T with(nolock) on C.TenantID=T.TenantID 
left join   REN_Units U with(nolock) on C.UnitID=U.UnitID   
left join REN_Property p with(nolock) on C.propertyid=p.Nodeid 
left join com_lookup l with(nolock) on u.UnitStatus=l.nodeid'+@FromTag+'
WHERE 1=1  '+@WHERE1+'
group by l.name  ,T.FirstName,C.StartDate, C.EndDate,U.Name,p.Name ,C.TotalAmount ,u.TermsConditions
union 
select null,null,null,
U.name, P.name ,0,l.name,U.TermsConditions'+@SelectTag+'
from ren_units U with(nolock) 
left join com_lookup l with(nolock) on U.UnitStatus=l.nodeid  
left join ren_property P with(nolock) on U.propertyid=P.nodeid'+@FromTag+'
where U.unitid not in (select isnull(unitid,0) from ren_contract with(nolock)) '+@WHERE1+'
group by l.name,U.name,P.name,U.TermsConditions) as t
order by UnitStatus
'
	EXEC(@SQL)
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
		SELECT ErrorMessage, ERROR_MESSAGE() AS ServerMessage,ERROR_NUMBER() AS ErrorNumber, ERROR_PROCEDURE()AS ProcedureName, ERROR_LINE() AS ErrorLine
		FROM COM_ErrorMessages WITH(NOLOCK) WHERE ErrorNumber=-999 AND LanguageID=@LangID
	END
SET NOCOUNT OFF  
RETURN -999   
END CATCH
GO

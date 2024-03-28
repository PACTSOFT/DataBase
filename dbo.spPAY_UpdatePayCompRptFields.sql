﻿USE PACT2C222
GO
SET ANSI_NULLS, QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spPAY_UpdatePayCompRptFields]
WITH ENCRYPTION, EXECUTE AS CALLER
AS
---- APPRAISALS

UPDATE ADM_COSTCENTERDEF SET IsColumnInUse=0 WHERE COSTCENTERID=409  AND (SysColumnName LIKE 'Earning%' OR SysColumnName LIKE 'Deduction%')

Update ADM_COSTCENTERDEF 
SET UserColumnName=CASE WHEN b.FieldType='OverTime' THEN c.Name+' HRS' ELSE c.Name+' ACT' END,IsColumnInUse=1 
--SELECT b.SNo,CASE WHEN b.FieldType='OverTime' THEN c.Name+' HRS' ELSE c.Name+' ACT' END,a.UserColumnName,SUBSTRING(SysColumnName,8,len(SysColumnName)-7)
FROM ADM_COSTCENTERDEF a WITH(NOLOCK)
JOIN COM_CC50054 b WITH(NOLOCK) on b.SNo=SUBSTRING(SysColumnName,8,len(SysColumnName)-7)
JOIN COM_CC50052 c WITH(NOLOCK) on c.NodeID=b.ComponentID
WHERE a.COSTCENTERID=409 AND a.SysColumnName LIKE 'Earning%'
AND b.Type=1 AND b.GradeID=1 AND b.PAYROLLDATE=(Select MAX(PAYROLLDATE) FROM COM_CC50054 WITH(NOLOCK) WHERE GRADEID=1) 

--
Update ADM_COSTCENTERDEF 
SET UserColumnName=CASE WHEN b.FieldType='OverTime' THEN c.Name+' HRS' ELSE c.Name+' ACT' END,IsColumnInUse=1 
--SELECT b.SNo,CASE WHEN b.FieldType='OverTime' THEN c.Name+' HRS' ELSE c.Name+' ACT' END,a.UserColumnName,SUBSTRING(SysColumnName,10,len(SysColumnName)-9)
FROM ADM_COSTCENTERDEF a WITH(NOLOCK)
JOIN COM_CC50054 b WITH(NOLOCK) on b.SNo=SUBSTRING(SysColumnName,10,len(SysColumnName)-9)
JOIN COM_CC50052 c WITH(NOLOCK) on c.NodeID=b.ComponentID
WHERE a.COSTCENTERID=409 AND a.SysColumnName LIKE 'Deduction%' 
AND b.Type=2 AND b.GradeID=1 AND b.PAYROLLDATE=(Select MAX(PAYROLLDATE) FROM COM_CC50054 WITH(NOLOCK) WHERE GRADEID=1) 

---- END :: APPRAISALS

---- PAYROLL EARNINGS

UPDATE ADM_COSTCENTERDEF SET IsColumnInUse=0 WHERE COSTCENTERID=405  AND SysTableName<>'Pay_EmpPay'

Update ADM_COSTCENTERDEF 
SET UserColumnName=CASE WHEN b.FieldType='OverTime' THEN c.Name+' HRS' ELSE c.Name+' ACT' END,IsColumnInUse=1 
--SELECT b.SNo,CASE WHEN b.FieldType='OverTime' THEN c.Name+' HRS' ELSE c.Name+' ACT' END,a.UserColumnName,SUBSTRING(SysColumnName,6,len(SysColumnName)-5)
FROM ADM_COSTCENTERDEF a WITH(NOLOCK)
JOIN COM_CC50054 b WITH(NOLOCK) on b.SNo=SUBSTRING(SysColumnName,6,len(SysColumnName)-5)
JOIN COM_CC50052 c WITH(NOLOCK) on c.NodeID=b.ComponentID
WHERE a.COSTCENTERID=405 AND a.SysColumnName LIKE 'dcNUM%' 
AND b.Type=1 AND b.GradeID=1 AND b.PAYROLLDATE=(Select MAX(PAYROLLDATE) FROM COM_CC50054 WITH(NOLOCK) WHERE GRADEID=1) 

Update ADM_COSTCENTERDEF 
SET UserColumnName=c.Name,IsColumnInUse=1 
--SELECT b.SNo,c.Name,a.UserColumnName,SUBSTRING(SysColumnName,10,len(SysColumnName)-9)
FROM ADM_COSTCENTERDEF a WITH(NOLOCK)
JOIN COM_CC50054 b WITH(NOLOCK) on b.SNo=SUBSTRING(SysColumnName,10,len(SysColumnName)-9)
JOIN COM_CC50052 c WITH(NOLOCK) on c.NodeID=b.ComponentID
WHERE COSTCENTERID=405 AND a.SysColumnName LIKE 'dcCalcNUM%' AND a.SysColumnName NOT LIKE 'dcCalcNUMFC%' 
AND b.Type=1 AND b.GradeID=1 AND b.PAYROLLDATE=(Select MAX(PAYROLLDATE) FROM COM_CC50054 WITH(NOLOCK) WHERE GRADEID=1) 

Update ADM_COSTCENTERDEF 
SET UserColumnName=c.Name+' ARR',IsColumnInUse=1 
--SELECT b.SNo,c.Name+' ARR',a.UserColumnName,SUBSTRING(SysColumnName,9,len(SysColumnName)-8)
FROM ADM_COSTCENTERDEF a WITH(NOLOCK)
JOIN COM_CC50054 b WITH(NOLOCK) on b.SNo=SUBSTRING(SysColumnName,9,len(SysColumnName)-8)
JOIN COM_CC50052 c WITH(NOLOCK) on c.NodeID=b.ComponentID
WHERE COSTCENTERID=405 AND a.SysColumnName LIKE 'dcExchRT%' 
AND b.Type=1 AND b.GradeID=1 AND b.PAYROLLDATE=(Select MAX(PAYROLLDATE) FROM COM_CC50054 WITH(NOLOCK) WHERE GRADEID=1) 

Update ADM_COSTCENTERDEF 
SET UserColumnName=c.Name+' ADJ',IsColumnInUse=1 
--SELECT b.SNo,c.Name+' ADJ',a.UserColumnName,SUBSTRING(SysColumnName,12,len(SysColumnName)-11)
FROM ADM_COSTCENTERDEF a WITH(NOLOCK)
JOIN COM_CC50054 b WITH(NOLOCK) on b.SNo=SUBSTRING(SysColumnName,12,len(SysColumnName)-11)
JOIN COM_CC50052 c WITH(NOLOCK) on c.NodeID=b.ComponentID
WHERE COSTCENTERID=405 AND a.SysColumnName LIKE 'dcCalcNUMFC%' 
AND b.Type=1 AND b.GradeID=1 AND b.PAYROLLDATE=(Select MAX(PAYROLLDATE) FROM COM_CC50054 WITH(NOLOCK) WHERE GRADEID=1) 

---- END :: PAYROLL EARNINGS

---- PAYROLL DEDUCTIONS

UPDATE ADM_COSTCENTERDEF SET IsColumnInUse=0 WHERE COSTCENTERID=406 

Update ADM_COSTCENTERDEF 
SET UserColumnName=CASE WHEN b.FieldType='OverTime' THEN c.Name+' HRS' ELSE c.Name+' ACT' END,IsColumnInUse=1 
--SELECT b.SNo,CASE WHEN b.FieldType='OverTime' THEN c.Name+' HRS' ELSE c.Name+' ACT' END,a.UserColumnName,SUBSTRING(SysColumnName,6,len(SysColumnName)-5)
FROM ADM_COSTCENTERDEF a WITH(NOLOCK)
JOIN COM_CC50054 b WITH(NOLOCK) on b.SNo=SUBSTRING(SysColumnName,6,len(SysColumnName)-5)
JOIN COM_CC50052 c WITH(NOLOCK) on c.NodeID=b.ComponentID
WHERE a.COSTCENTERID=406 AND a.SysColumnName LIKE 'dcNUM%' 
AND b.Type=2 AND b.GradeID=1 AND b.PAYROLLDATE=(Select MAX(PAYROLLDATE) FROM COM_CC50054 WITH(NOLOCK) WHERE GRADEID=1) 

Update ADM_COSTCENTERDEF 
SET UserColumnName=c.Name,IsColumnInUse=1 
--SELECT b.SNo,c.Name,a.UserColumnName,SUBSTRING(SysColumnName,10,len(SysColumnName)-9)
FROM ADM_COSTCENTERDEF a WITH(NOLOCK)
JOIN COM_CC50054 b WITH(NOLOCK) on b.SNo=SUBSTRING(SysColumnName,10,len(SysColumnName)-9)
JOIN COM_CC50052 c WITH(NOLOCK) on c.NodeID=b.ComponentID
WHERE COSTCENTERID=406 AND a.SysColumnName LIKE 'dcCalcNUM%' AND a.SysColumnName NOT LIKE 'dcCalcNUMFC%' 
AND b.Type=2 AND b.GradeID=1 AND b.PAYROLLDATE=(Select MAX(PAYROLLDATE) FROM COM_CC50054 WITH(NOLOCK) WHERE GRADEID=1) 

Update ADM_COSTCENTERDEF 
SET UserColumnName=c.Name+' ARR',IsColumnInUse=1 
--SELECT b.SNo,c.Name+' ARR',a.UserColumnName,SUBSTRING(SysColumnName,9,len(SysColumnName)-8)
FROM ADM_COSTCENTERDEF a 
JOIN COM_CC50054 b on b.SNo=SUBSTRING(SysColumnName,9,len(SysColumnName)-8)
JOIN COM_CC50052 c on c.NodeID=b.ComponentID
WHERE COSTCENTERID=406 AND a.SysColumnName LIKE 'dcExchRT%' 
AND b.Type=2 AND b.GradeID=1 AND b.PAYROLLDATE=(Select MAX(PAYROLLDATE) FROM COM_CC50054 WITH(NOLOCK) WHERE GRADEID=1) 

Update ADM_COSTCENTERDEF 
SET UserColumnName=c.Name+' ADJ',IsColumnInUse=1 
--SELECT b.SNo,c.Name+' ADJ',a.UserColumnName,SUBSTRING(SysColumnName,12,len(SysColumnName)-11)
FROM ADM_COSTCENTERDEF a 
JOIN COM_CC50054 b on b.SNo=SUBSTRING(SysColumnName,12,len(SysColumnName)-11)
JOIN COM_CC50052 c on c.NodeID=b.ComponentID
WHERE COSTCENTERID=406 AND a.SysColumnName LIKE 'dcCalcNUMFC%' 
AND b.Type=2 AND b.GradeID=1 AND b.PAYROLLDATE=(Select MAX(PAYROLLDATE) FROM COM_CC50054 WITH(NOLOCK) WHERE GRADEID=1) 

---- END :: PAYROLL DEDUCTIONS

---- PAYROLL LOANS

UPDATE ADM_COSTCENTERDEF SET IsColumnInUse=0 WHERE COSTCENTERID=407 

Update ADM_COSTCENTERDEF 
SET UserColumnName=c.Name,IsColumnInUse=1 
--SELECT b.SNo,c.Name,a.UserColumnName,SUBSTRING(SysColumnName,10,len(SysColumnName)-9)
FROM ADM_COSTCENTERDEF a 
JOIN COM_CC50054 b on b.SNo=SUBSTRING(SysColumnName,10,len(SysColumnName)-9)
JOIN COM_CC50052 c on c.NodeID=b.ComponentID
WHERE COSTCENTERID=407 AND a.SysColumnName LIKE 'dcCalcNUM%' AND a.SysColumnName NOT LIKE 'dcCalcNUMFC%' 
AND b.Type=3 AND b.GradeID=1 AND b.PAYROLLDATE=(Select MAX(PAYROLLDATE) FROM COM_CC50054 WITH(NOLOCK) WHERE GRADEID=1) 

Update ADM_COSTCENTERDEF 
SET UserColumnName=c.Name+' OPB',IsColumnInUse=1 
--SELECT b.SNo,c.Name+' OPB',a.UserColumnName,SUBSTRING(SysColumnName,9,len(SysColumnName)-8)
FROM ADM_COSTCENTERDEF a 
JOIN COM_CC50054 b on b.SNo=SUBSTRING(SysColumnName,9,len(SysColumnName)-8)
JOIN COM_CC50052 c on c.NodeID=b.ComponentID
WHERE COSTCENTERID=407 AND a.SysColumnName LIKE 'dcExchRT%' 
AND b.Type=3 AND b.GradeID=1 AND b.PAYROLLDATE=(Select MAX(PAYROLLDATE) FROM COM_CC50054 WITH(NOLOCK) WHERE GRADEID=1) 

---- END :: PAYROLL LOANS

---- PAYROLL LEAVES

UPDATE ADM_COSTCENTERDEF SET IsColumnInUse=0 WHERE COSTCENTERID=408 

Update ADM_COSTCENTERDEF 
SET UserColumnName=c.Name+' OPB',IsColumnInUse=1 
--SELECT b.SNo,c.Name+' OPB',a.UserColumnName,SUBSTRING(SysColumnName,6,len(SysColumnName)-5)
FROM ADM_COSTCENTERDEF a 
JOIN COM_CC50054 b on b.SNo=SUBSTRING(SysColumnName,6,len(SysColumnName)-5)
JOIN COM_CC50052 c on c.NodeID=b.ComponentID
WHERE a.COSTCENTERID=408 AND a.SysColumnName LIKE 'dcNUM%' 
AND b.Type=4 AND b.GradeID=1 AND b.PAYROLLDATE=(Select MAX(PAYROLLDATE) FROM COM_CC50054 WITH(NOLOCK) WHERE GRADEID=1) 

Update ADM_COSTCENTERDEF 
SET UserColumnName=c.Name,IsColumnInUse=1 
--SELECT b.SNo,c.Name,a.UserColumnName,SUBSTRING(SysColumnName,10,len(SysColumnName)-9)
FROM ADM_COSTCENTERDEF a 
JOIN COM_CC50054 b on b.SNo=SUBSTRING(SysColumnName,10,len(SysColumnName)-9)
JOIN COM_CC50052 c on c.NodeID=b.ComponentID
WHERE COSTCENTERID=408 AND a.SysColumnName LIKE 'dcCalcNUM%' AND a.SysColumnName NOT LIKE 'dcCalcNUMFC%' 
AND b.Type=4 AND b.GradeID=1 AND b.PAYROLLDATE=(Select MAX(PAYROLLDATE) FROM COM_CC50054 WITH(NOLOCK) WHERE GRADEID=1) 

Update ADM_COSTCENTERDEF 
SET UserColumnName=c.Name+' MOPB',IsColumnInUse=1 
--SELECT b.SNo,c.Name+' MOPB',a.UserColumnName,SUBSTRING(SysColumnName,9,len(SysColumnName)-8)
FROM ADM_COSTCENTERDEF a 
JOIN COM_CC50054 b on b.SNo=SUBSTRING(SysColumnName,9,len(SysColumnName)-8)
JOIN COM_CC50052 c on c.NodeID=b.ComponentID
WHERE COSTCENTERID=408 AND a.SysColumnName LIKE 'dcExchRT%' 
AND b.Type=4 AND b.GradeID=1 AND b.PAYROLLDATE=(Select MAX(PAYROLLDATE) FROM COM_CC50054 WITH(NOLOCK) WHERE GRADEID=1) 

Update ADM_COSTCENTERDEF 
SET UserColumnName=c.Name+' CLB',IsColumnInUse=1 
--SELECT b.SNo,c.Name+' CLB',a.UserColumnName,SUBSTRING(SysColumnName,12,len(SysColumnName)-11)
FROM ADM_COSTCENTERDEF a 
JOIN COM_CC50054 b on b.SNo=SUBSTRING(SysColumnName,12,len(SysColumnName)-11)
JOIN COM_CC50052 c on c.NodeID=b.ComponentID
WHERE COSTCENTERID=408 AND a.SysColumnName LIKE 'dcCalcNUMFC%' 
AND b.Type=4 AND b.GradeID=1 AND b.PAYROLLDATE=(Select MAX(PAYROLLDATE) FROM COM_CC50054 WITH(NOLOCK) WHERE GRADEID=1) 

---- END :: PAYROLL LEAVES

---- UPDATING RESOURCES DATA

UPDATE COM_LANGUAGERESOURCES 
SET ResourceData=b.UserColumnName
--SELECT a.ResourceID,a.ResourceData,b.UserColumnName,b.ResourceID
FROM COM_LANGUAGERESOURCES a WITH(NOLOCK)
JOIN ADM_COSTCENTERDEF b WITH(NOLOCK) on b.ResourceID=a.ResourceID
WHERE b.COSTCENTERID IN(405,406,407,408,409)

---- END :: UPDATING RESOURCES DATA
GO
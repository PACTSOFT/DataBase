USE PACT2C222
GO
SET ANSI_NULLS, QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spREN_GetFloorWiseExpiry]
	@PropertyID [bigint] = 0,
	@Date [datetime],
	@Status [bigint],
	@UserID [bigint],
	@LangID [int] = 1
WITH ENCRYPTION, EXECUTE AS CALLER
AS
BEGIN TRANSACTION    
BEGIN TRY     
SET NOCOUNT ON    
declare @T1 nvarchar(100),@T2 nvarchar(100),@Sql nvarchar(max),@CountSql nvarchar(max) 
  
       
    
set @T1=(select TableName from adm_features where featureid=(select value from ADM_GlobalPreferences where Name='UnitLinkDimension'))   
    
SET @Sql ='SELECT T2.Name AS [Property] ,T0.FloorLookUpID,LKf.Name FloorName ,T0.Name AS [Unit] ,T0.UnitID  UnitID    
,(select top 1 CONVERT(DATETIME,T1.EndDate)  from  REN_Contract T1 where '+convert(nvarchar,convert(float,@Date))+' between T1.StartDate and T1.EndDate and T1.UnitID=T0.UnitID AND T0.Name is not null and T0.Name <>''''  AND T1.IsGroup <> 1) AS [ContractExpiryDate],  
 0 Occupied ,  T2.NodeId AS PropertyId,T0.UnitStatus, LKP.Name StatusName,'  
SET @CountSql='SELECT top 1 count(T0.FloorLookUpID) cnt,FloorLookUpID,T0.PropertyID '  
if(@T1 is  not null and @T1<>'')  
begin  
 SET @Sql =@Sql+' UNTTYPE.Name UnitTypeName  '  
end  
else  
begin  
 SET @Sql =@Sql+' '''' UnitTypeName  '  
end  
  
SET @Sql =@Sql+' FROM REN_Units T0   
  
INNER JOIN REN_Property T2  ON T0.PropertyID=T2.NodeID    
LEFT JOIN COM_LOOKUP LKP ON T0.UnitStatus = LKP.NodeID AND (LKP.LookupType = 46 or LKP.LookupType IS NULL)  
LEFT JOIN COM_LOOKUP LKf ON T0.FloorLookUpID = LKf.NodeID AND (LKf.LookupType = 39 or LKf.LookupType IS NULL)'  
SET @CountSql=@CountSql+' FROM REN_Units T0   
left JOIN REN_Contract T1 ON T1.UnitID=T0.UnitID AND T0.Name is not null and T0.Name <>''''  AND T1.IsGroup <> 1  
INNER JOIN REN_Property T2  ON T0.PropertyID=T2.NodeID    
LEFT JOIN COM_LOOKUP LKP ON T0.UnitStatus = LKP.NodeID AND (LKP.LookupType = 46 or LKP.LookupType IS NULL)  
LEFT JOIN COM_LOOKUP LKf ON T0.FloorLookUpID = LKf.NodeID AND (LKf.LookupType = 39 or LKf.LookupType IS NULL)'  
if(@T1 is  not null and @T1<>'')  
begin  
 SET @Sql =@Sql+' LEFT JOIN '+@T1+' UNTTYPE ON T0.NodeID = UNTTYPE.NodeID'  
 SET @CountSql=@CountSql+' LEFT JOIN '+@T1+' UNTTYPE ON T0.NodeID = UNTTYPE.NodeID'  
end  
 
 SET @Sql =@Sql+' where T0.ContractID=0'  
SET @CountSql=@CountSql+' where T0.ContractID=0'  
  
   
if(@PropertyID>0)  
begin  
 SET @Sql =@Sql+' and T0.PropertyID='+convert(nvarchar,@PropertyID)  
   SET @CountSql=@CountSql+' and T0.PropertyID='+convert(nvarchar,@PropertyID)  
   
end  

if(@Status>0 )  
begin  
   SET @Sql =@Sql+' and   T0.UnitStatus='+convert(nvarchar,@Status)  
  SET @CountSql=@CountSql+' and  T0.UnitStatus='+convert(nvarchar,@Status)   
end  
  
  
SET @Sql =@Sql+' ORDER BY T2.Name,T0.FloorLookUpID'  
SET @CountSql=@CountSql+' group by  T0.PropertyID,T0.FloorLookUpID order by cnt desc'  
EXEC (@Sql)  
print @CountSql   
EXEC (@CountSql)  
  
SELECT NodeID,Name,Status,IsDefault FROM COM_Lookup WHERE LookupType=46  
   
  
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
  SELECT ErrorMessage, ERROR_MESSAGE() AS ServerMessage,ERROR_NUMBER() as ErrorNumber, ERROR_PROCEDURE()as ProcedureName, ERROR_LINE() AS      
ErrorLine    
  FROM COM_ErrorMessages WITH(nolock) WHERE ErrorNumber=-999 AND LanguageID=@LangID   
 END    
ROLLBACK TRANSACTION    
SET NOCOUNT OFF      
RETURN -999       
END CATCH      
 
GO

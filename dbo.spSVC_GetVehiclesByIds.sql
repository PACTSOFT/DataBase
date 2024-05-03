USE PACT2C222
GO
SET ANSI_NULLS, QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spSVC_GetVehiclesByIds]
	@VehicleIDS [nvarchar](max),
	@UserID [bigint],
	@LangID [int] = 1
WITH ENCRYPTION, EXECUTE AS CALLER
AS
BEGIN TRANSACTION
BEGIN TRY	
SET NOCOUNT ON
 
 declare @sql nvarchar(max)
--select * from SVC_Vehicle
 set @sql ='  select distinct SVC_Vehicle.VehicleID,SVC_Vehicle.MakeID,SVC_Vehicle.Make,SVC_Vehicle.ModelID,
			SVC_Vehicle.Model,SVC_Vehicle.VariantID,SVC_Vehicle.Variant,SVC_Vehicle.SegmentID,
			COM_CC50024.name Segment,SVC_Vehicle.Specification  Specification_key,COM_CC50031.name Specification,   
            SVC_Vehicle.EuroBSType  EuroBSType_key,COM_CC50032.name EuroBSType,  
            SVC_Vehicle.Transmission Transmission_key,COM_CC50033.name Transmission,  
            SVC_Vehicle.CC CC_key,COM_CC50034.name CC,  
            SVC_Vehicle.WheelDrive WheelDrive_key,COM_CC50035.name WheelDrive,  
            SVC_Vehicle.SeatCapacity SeatCapacity_key,COM_CC50036.name SeatCapacity,  
            SVC_Vehicle.Fuel Fuel_key,COM_CC50014.name Fuel,StartYear,EndYear
            from SVC_Vehicle with(nolock)  
            inner JOIN COM_CC50024 ON COM_CC50024.NODEID=SVC_Vehicle.SegmentID  
            inner JOIN COM_CC50031 ON COM_CC50031.NODEID=SVC_Vehicle.Specification  
            inner JOIN COM_CC50032 ON COM_CC50032.NODEID=SVC_Vehicle.EuroBSType  
            inner JOIN COM_CC50033 ON COM_CC50033.NODEID=SVC_Vehicle.Transmission  
            inner JOIN COM_CC50034 ON COM_CC50034.NODEID=SVC_Vehicle.CC  
            inner JOIN COM_CC50035 ON COM_CC50035.NODEID=SVC_Vehicle.WheelDrive  
            inner JOIN COM_CC50036 ON COM_CC50036.NODEID=SVC_Vehicle.SeatCapacity  
            inner JOIN COM_CC50014 ON COM_CC50014.NODEID=SVC_Vehicle.Fuel  
         where SVC_Vehicle.vehicleid in ('+@VehicleIDS+')'

print @SQL
exec (@SQL)

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



GO

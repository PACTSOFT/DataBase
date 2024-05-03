USE PACT2C222
GO
SET ANSI_NULLS, QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spSVC_GetDetailsByVehicleID]
	@VehicleID [bigint] = 0,
	@UserID [bigint],
	@LangID [int] = 1
WITH ENCRYPTION, EXECUTE AS CALLER
AS
BEGIN TRY  
SET NOCOUNT ON;
	 
	select  MakeID,Make,ModelID,Model,VariantID,Variant,Make+'-'+Model+'-'+Variant VehicleName,SegmentID,Segment,
	Specification SpecificationID,COM_CC50031.Name Specification,EuroBSType EuroBSTypeID,COM_CC50032.Name EuroBSType,
    Transmission TransmissionID,COM_CC50033.Name Transmission,Fuel FuelID,COM_CC50014.Name Fuel,CC CCID,COM_CC50034.Name CC,
    WheelDrive WheelDriveID,COM_CC50035.Name WheelDrive,SeatCapacity SeatCapacityID,COM_CC50036.Name SeatCapacity 
    from SVC_Vehicle with (nolock)
	LEFT JOIN COM_CC50031  WITH(NOLOCK)  ON COM_CC50031.NODEID=SVC_Vehicle.Specification
	LEFT JOIN COM_CC50032  WITH(NOLOCK) ON COM_CC50032.NODEID=SVC_Vehicle.EuroBSType
	LEFT JOIN COM_CC50033  WITH(NOLOCK) ON COM_CC50033.NODEID=SVC_Vehicle.Transmission
	LEFT JOIN COM_CC50034  WITH(NOLOCK) ON COM_CC50034.NODEID=SVC_Vehicle.CC
	LEFT JOIN COM_CC50035  WITH(NOLOCK)  ON COM_CC50035.NODEID=SVC_Vehicle.WheelDrive
	LEFT JOIN COM_CC50036  WITH(NOLOCK) ON COM_CC50036.NODEID=SVC_Vehicle.SeatCapacity
	LEFT JOIN COM_CC50014  WITH(NOLOCK) ON COM_CC50014.NODEID=SVC_Vehicle.Fuel where VehicleID=@VehicleID

 
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
			SELECT ErrorMessage, ERROR_MESSAGE() AS ServerMessage,ERROR_NUMBER() as ErrorNumber, ERROR_PROCEDURE()as ProcedureName, ERROR_LINE() AS ErrorLine
			FROM COM_ErrorMessages WITH(NOLOCK) WHERE ErrorNumber=-999 AND LanguageID=@LangID
		END
 
SET NOCOUNT OFF  
RETURN -999   
END CATCH


GO

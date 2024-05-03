USE PACT2C222
GO
SET ANSI_NULLS, QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spSVC_GetVehicleScreenDetails]
	@MAKEID [bigint] = 0,
	@MODELID [bigint] = 0,
	@YEAR [nvarchar](50),
	@ENDYEAR [nvarchar](50),
	@VARIANTID [bigint] = 0,
	@ONLOAD [int] = 0,
	@UserID [bigint],
	@LangID [int] = 1
WITH ENCRYPTION, EXECUTE AS CALLER
AS
BEGIN TRANSACTION
BEGIN TRY	
SET NOCOUNT ON
 
IF @ONLOAD=1
BEGIN 
	SELECT DISTINCT MakeID,Make
	FROM SVC_Vehicle WITH(NOLOCK)  WHERE   VehicleID > 0
	
	SELECT DISTINCT NODEID SegmentID,NAME Segment           
	FROM COM_CC50024 WITH(NOLOCK)  
	
	SELECT DISTINCT CATEGORYID,CATEGORYNAME FROM SVC_PartCategory WITH(NOLOCK)

  SELECT  C.CostCenterColID,R.ResourceData,C.SysColumnName,C.UserColumnType,C.ColumnDataType,      
    C.UserDefaultValue,C.UserProbableValues,C.IsMandatory,C.IsEditable,C.IsVisible,C.ColumnCCListViewTypeID,      
    C.IsCostCenterUserDefined,C.IsColumnUserDefined,C.ColumnCostCenterID,C.FetchMaxRows,C.SectionID,C.SectionName      
  FROM ADM_CostCenterDef C WITH(NOLOCK)      
  LEFT JOIN COM_LanguageResources R ON R.ResourceID=C.ResourceID AND R.LanguageID=@LangID      
  WHERE C.CostCenterID = 61   
  ORDER BY C.[ColumnOrder]    


END


IF @MODELID>0 AND @MAKEID>0 AND @VARIANTID>0 --IF MODEL AND MAKE AND VARIANT IS NOT NULL THEN SELECT YEARS OF THAT VARIANT
BEGIN
	SELECT distinct StartYear,EndYear,VehicleID    
			FROM SVC_Vehicle WITH(NOLOCK) WHERE ModelID = @MODELID AND MakeID = @MAKEID  AND VARIANTID=@VARIANTID   ORDER BY StartYear
SELECT DISTINCT  COM_CC50024.NODEID SegmentID,COM_CC50024.CODE Segment           
			FROM SVC_Vehicle WITH(NOLOCK)  
LEFT JOIN COM_CC50024 ON COM_CC50024.NODEID=SVC_Vehicle.SegmentID
WHERE ModelID = @MODELID AND MakeID = @MAKEID  AND VARIANTID=@VARIANTID  

END
IF @MODELID>0 AND @MAKEID>0 AND @YEAR<>'' AND @ENDYEAR='' --IF MODEL AND MAKE AND YEAR IS NOT NULL THEN FETCH VARIANT AND SEGMENT DETAILS
BEGIN
SELECT VariantID,Variant,SegmentID,case when SegmentID=1 then '-' else COM_CC50024.name end Segment ,IsEnabled ,IsVisible, VehicleID,'OLD' 'Record', StartYear,EndYear
,Specification  Specification_key,case when Specification=1 then '-' else COM_CC50031.name end Specification, 
EuroBSType  EuroBSType_key,case when EuroBSType =1 then '-' else COM_CC50032.name end EuroBSType,
Transmission Transmission_key, case when Transmission =1 then '-' else COM_CC50033.name end Transmission,
CC CC_key,case when CC =1 then '-' else  COM_CC50034.name end CC,
WheelDrive WheelDrive_key,case when WheelDrive =1 then '-' else  COM_CC50035.name end WheelDrive,
SeatCapacity SeatCapacity_key,case when SeatCapacity =1 then '-' else COM_CC50036.name end SeatCapacity,
Fuel Fuel_key,case when Fuel=1 then '-' else COM_CC50014.name end Fuel

FROM SVC_Vehicle WITH(NOLOCK)
LEFT JOIN COM_CC50024 ON COM_CC50024.NODEID=SVC_Vehicle.SegmentID
LEFT JOIN COM_CC50031 ON COM_CC50031.NODEID=SVC_Vehicle.Specification
LEFT JOIN COM_CC50032 ON COM_CC50032.NODEID=SVC_Vehicle.EuroBSType
LEFT JOIN COM_CC50033 ON COM_CC50033.NODEID=SVC_Vehicle.Transmission
LEFT JOIN COM_CC50034 ON COM_CC50034.NODEID=SVC_Vehicle.CC
LEFT JOIN COM_CC50035 ON COM_CC50035.NODEID=SVC_Vehicle.WheelDrive
LEFT JOIN COM_CC50036 ON COM_CC50036.NODEID=SVC_Vehicle.SeatCapacity
LEFT JOIN COM_CC50014 ON COM_CC50014.NODEID=SVC_Vehicle.Fuel
 WHERE ModelID = @MODELID AND MakeID = @MAKEID AND (@YEAR between StartYear and EndYear or (@YEAR>StartYear and EndYear=0))

SELECT [VehicleID]
      ,[MakeID]
      ,[Make]
      ,[ModelID]
      ,[Model]
      ,StartYear,EndYear
      ,[VariantID]
      ,[Variant]
      ,[SegmentID]
      ,case when SegmentID=1 then '-' else COM_CC50024.name end Segment 
      ,[IsEnabled]
      ,[IsVisible]
      ,SVC_Vehicle.[CompanyGUID]
      ,SVC_Vehicle.[GUID]
      ,SVC_Vehicle.[CreatedBy]
      ,SVC_Vehicle.[CreatedDate]
      ,SVC_Vehicle.[ModifiedBy]
      ,SVC_Vehicle.[ModifiedDate]
  ,Specification  Specification_key,  case when Specification=1 then '-' else COM_CC50031.name end Specification, 
EuroBSType  EuroBSType_key, case when EuroBSType=1 then '-' else COM_CC50032.name end EuroBSType,  
 Transmission Transmission_key, case when Transmission =1 then '-' else COM_CC50033.name end Transmission,
CC CC_key,case when CC =1 then '-' else  COM_CC50034.name end CC,
WheelDrive WheelDrive_key,case when WheelDrive =1 then '-' else  COM_CC50035.name end WheelDrive,
SeatCapacity SeatCapacity_key,case when SeatCapacity =1 then '-' else COM_CC50036.name end SeatCapacity,
Fuel Fuel_key,case when Fuel=1 then '-' else COM_CC50014.name end Fuel
 
 FROM SVC_Vehicle WITH(NOLOCK)
LEFT JOIN COM_CC50024 ON COM_CC50024.NODEID=SVC_Vehicle.SegmentID
LEFT JOIN COM_CC50031 ON COM_CC50031.NODEID=SVC_Vehicle.Specification
LEFT JOIN COM_CC50032 ON COM_CC50032.NODEID=SVC_Vehicle.EuroBSType
LEFT JOIN COM_CC50033 ON COM_CC50033.NODEID=SVC_Vehicle.Transmission
LEFT JOIN COM_CC50034 ON COM_CC50034.NODEID=SVC_Vehicle.CC
LEFT JOIN COM_CC50035 ON COM_CC50035.NODEID=SVC_Vehicle.WheelDrive
LEFT JOIN COM_CC50036 ON COM_CC50036.NODEID=SVC_Vehicle.SeatCapacity
LEFT JOIN COM_CC50014 ON COM_CC50014.NODEID=SVC_Vehicle.Fuel
 WHERE ModelID = @MODELID AND MakeID = @MAKEID    
END

IF @MODELID>0 AND @MAKEID>0--IF MODEL AND MAKE IS GREATER THAN ZERO THEN GET YEAR BASED ON MODEL AND MAKE
BEGIN
	SELECT distinct StartYear,EndYear
			FROM SVC_Vehicle WITH(NOLOCK) WHERE ModelID = @MODELID AND MakeID = @MAKEID  order by StartYear
SELECT DISTINCT VARIANTID,VARIANT           
			FROM SVC_Vehicle WITH(NOLOCK) WHERE ModelID = @MODELID AND MakeID = @MAKEID    ORDER BY VARIANTID
SELECT row_number() over (order by StartYear) SNO ,[VehicleID]
      ,[MakeID]
      ,[Make]
      ,[ModelID]
      ,[Model]
      ,StartYear,EndYear
      ,[VariantID]
      ,[Variant]
      ,[SegmentID]
      ,case when SegmentID=1 then '-' else COM_CC50024.name end Segment
      ,[IsEnabled]
      ,[IsVisible]
      ,SVC_Vehicle.[CompanyGUID]
      ,SVC_Vehicle.[GUID]
      ,SVC_Vehicle.[CreatedBy]
      ,SVC_Vehicle.[CreatedDate]
      ,SVC_Vehicle.[ModifiedBy]
      ,SVC_Vehicle.[ModifiedDate]
  ,Specification  Specification_key,  case when Specification=1 then '-' else COM_CC50031.name end Specification, 
EuroBSType  EuroBSType_key, case when EuroBSType=1 then '-' else COM_CC50032.name end EuroBSType,  
 Transmission Transmission_key, case when Transmission =1 then '-' else COM_CC50033.name end Transmission,
CC CC_key,case when CC =1 then '-' else  COM_CC50034.name end CC,
WheelDrive WheelDrive_key,case when WheelDrive =1 then '-' else  COM_CC50035.name end WheelDrive,
SeatCapacity SeatCapacity_key,case when SeatCapacity =1 then '-' else COM_CC50036.name end SeatCapacity,
Fuel Fuel_key,case when Fuel=1 then '-' else COM_CC50014.name end Fuel
FROM SVC_Vehicle WITH(NOLOCK)
LEFT JOIN COM_CC50024 ON COM_CC50024.NODEID=SVC_Vehicle.SegmentID
LEFT JOIN COM_CC50031 ON COM_CC50031.NODEID=SVC_Vehicle.Specification
LEFT JOIN COM_CC50032 ON COM_CC50032.NODEID=SVC_Vehicle.EuroBSType
LEFT JOIN COM_CC50033 ON COM_CC50033.NODEID=SVC_Vehicle.Transmission
LEFT JOIN COM_CC50034 ON COM_CC50034.NODEID=SVC_Vehicle.CC
LEFT JOIN COM_CC50035 ON COM_CC50035.NODEID=SVC_Vehicle.WheelDrive
LEFT JOIN COM_CC50036 ON COM_CC50036.NODEID=SVC_Vehicle.SeatCapacity
LEFT JOIN COM_CC50014 ON COM_CC50014.NODEID=SVC_Vehicle.Fuel
WHERE ModelID = @MODELID AND MakeID = @MAKEID    ORDER BY 	StartYear
	
END

 
IF @MAKEID>0--IF MAKE IS GREATER THAN ZERO THEN GET MODELS BASED ON MAKE
BEGIN
	SELECT DISTINCT ModelID,Model            
			FROM SVC_Vehicle WITH(NOLOCK) WHERE MakeID = @MAKEID AND ModelID>0
END

IF @MODELID>0 AND @MAKEID>0 AND @YEAR<>'' AND @ENDYEAR <> '' --IF MODEL AND MAKE AND YEAR IS NOT NULL THEN FETCH VARIANT AND SEGMENT DETAILS
BEGIN
SELECT VariantID,Variant,SegmentID,case when SegmentID=1 then '-' else COM_CC50024.name end Segment ,IsEnabled ,IsVisible, VehicleID,'OLD' 'Record',@YEAR [Year]      
,Specification  Specification_key,  case when Specification=1 then '-' else COM_CC50031.name end Specification, 
EuroBSType  EuroBSType_key, case when EuroBSType=1 then '-' else COM_CC50032.name end EuroBSType,  
 Transmission Transmission_key, case when Transmission =1 then '-' else COM_CC50033.name end Transmission,
CC CC_key,case when CC =1 then '-' else  COM_CC50034.name end CC,
WheelDrive WheelDrive_key,case when WheelDrive =1 then '-' else  COM_CC50035.name end WheelDrive,
SeatCapacity SeatCapacity_key,case when SeatCapacity =1 then '-' else COM_CC50036.name end SeatCapacity,
Fuel Fuel_key,case when Fuel=1 then '-' else COM_CC50014.name end Fuel
			FROM SVC_Vehicle WITH(NOLOCK)
LEFT JOIN COM_CC50024 ON COM_CC50024.NODEID=SVC_Vehicle.SegmentID
LEFT JOIN COM_CC50031 ON COM_CC50031.NODEID=SVC_Vehicle.Specification
LEFT JOIN COM_CC50032 ON COM_CC50032.NODEID=SVC_Vehicle.EuroBSType
LEFT JOIN COM_CC50033 ON COM_CC50033.NODEID=SVC_Vehicle.Transmission
LEFT JOIN COM_CC50034 ON COM_CC50034.NODEID=SVC_Vehicle.CC
LEFT JOIN COM_CC50035 ON COM_CC50035.NODEID=SVC_Vehicle.WheelDrive
LEFT JOIN COM_CC50036 ON COM_CC50036.NODEID=SVC_Vehicle.SeatCapacity
LEFT JOIN COM_CC50014 ON COM_CC50014.NODEID=SVC_Vehicle.Fuel
 WHERE ModelID = @MODELID AND MakeID = @MAKEID AND  (@YEAR between StartYear and EndYear or (@YEAR>StartYear and EndYear=0))
END

IF @ONLOAD=1
BEGIN
	SELECT DISTINCT MakeID,Make,ModelID,Model
	FROM SVC_Vehicle WITH(NOLOCK)  WHERE   VehicleID > 0
END

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

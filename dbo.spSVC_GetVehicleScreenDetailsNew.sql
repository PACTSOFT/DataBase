USE PACT2C222
GO
SET ANSI_NULLS, QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spSVC_GetVehicleScreenDetailsNew]
	@MAKEID [bigint] = 0,
	@MODELID [bigint] = 0,
	@Year [bigint] = 0,
	@VARIANTID [bigint] = 0,
	@SegmentID [bigint] = 0,
	@Specification [bigint] = 0,
	@EuroBSType [bigint] = 0,
	@Transmission [bigint] = 0,
	@Fuel [bigint] = 0,
	@CC [bigint] = 0,
	@WheelDrive [bigint] = 0,
	@SeatCapacity [bigint] = 0,
	@Type [int],
	@UserID [bigint],
	@LangID [int] = 1
WITH ENCRYPTION, EXECUTE AS CALLER
AS
BEGIN TRANSACTION  
BEGIN TRY   
SET NOCOUNT ON  
   
 IF @Type=0  
  BEGIN  
   SELECT DISTINCT MakeID,Make,ModelID,Model  
   FROM SVC_Vehicle WITH(NOLOCK)  WHERE  VehicleID > 0  
  END  
 Else if @Type=1  
  begin  
   select VariantID,Variant from SVC_Vehicle where @MAKEID = MakeID and @MODELID = ModelID --0  
  
   select Distinct vehicleid,SegmentID,
   case when (segmentid=1 or segmentid=0) then ('-') else (COM_CC50024.name) end Segment,
   Specification  Specification_key,
   case when (COM_CC50031.NodeID =1 or COM_CC50031.NodeID=0 ) then ('-') else (COM_CC50031.name) end Specification,   
   EuroBSType  EuroBSType_key,
   case when (COM_CC50032.NodeID=1 or  COM_CC50032.NodeID=0) then ('-') else (COM_CC50032.name) end EuroBSType,  
    Transmission Transmission_key,
    case when (COM_CC50033.NodeID=1 or COM_CC50033.NodeID=0) then ('-') else (COM_CC50033.name) end Transmission,  
    CC CC_key,
    case when (COM_CC50034.NodeID=1 or COM_CC50034.Nodeid=0) then ('-') else (COM_CC50034.name) end  CC,  
    WheelDrive WheelDrive_key,
    case when (COM_CC50035.NodeID=1 ) then ('-') else (COM_CC50035.name) end WheelDrive,  
    SeatCapacity SeatCapacity_key,
    case when (COM_CC50036.Nodeid=1 ) then ('-') else (COM_CC50036.name) end SeatCapacity,  
    Fuel Fuel_key,
    case when (COM_CC50014.Nodeid=1 ) then ('-') else (COM_CC50014.name) end Fuel,  
     StartYear,EndYear   
   from SVC_Vehicle with(nolock)  
    LEFT JOIN COM_CC50024 ON COM_CC50024.NODEID=SVC_Vehicle.SegmentID  
    LEFT JOIN COM_CC50031 ON COM_CC50031.NODEID=SVC_Vehicle.Specification  
    LEFT JOIN COM_CC50032 ON COM_CC50032.NODEID=SVC_Vehicle.EuroBSType  
    LEFT JOIN COM_CC50033 ON COM_CC50033.NODEID=SVC_Vehicle.Transmission  
    LEFT JOIN COM_CC50034 ON COM_CC50034.NODEID=SVC_Vehicle.CC  
    LEFT JOIN COM_CC50035 ON COM_CC50035.NODEID=SVC_Vehicle.WheelDrive  
    LEFT JOIN COM_CC50036 ON COM_CC50036.NODEID=SVC_Vehicle.SeatCapacity  
    LEFT JOIN COM_CC50014 ON COM_CC50014.NODEID=SVC_Vehicle.Fuel  
   where @MAKEID = MakeID and @MODELID = ModelID and @VARIANTID = VariantID --1  

select vehicleid,StartYear,EndYear  from SVC_Vehicle with(nolock) where  @MAKEID = MakeID and @MODELID = ModelID and @VARIANTID = VariantID and @SegmentID = SegmentID and @Specification = Specification and @EuroBSType=EuroBSType 
and @Transmission=Transmission and @Fuel=Fuel and @CC=CC and @WheelDrive=WheelDrive and @SeatCapacity=SeatCapacity  
       
     select CV_ID from dbo.SVC_CustomersVehicle where VehicleID=(select vehicleid  from SVC_Vehicle with(nolock) where  @MAKEID = MakeID and @MODELID = ModelID and @VARIANTID = VariantID and @SegmentID = SegmentID and @Specification = Specification 
     and @EuroBSType=EuroBSType and @Transmission=Transmission and @Fuel=Fuel and @CC=CC and @WheelDrive=WheelDrive and @SeatCapacity=SeatCapacity and ((@year between StartYear and EndYear) and (@year >=StartYear) and (@year <= EndYear)))  
             
   EXEC [spSVC_GetVehicleYears] @MAKEID,@MODELID  
  --  select StartYear,EndYear from SVC_Vehicle where 1 = MakeID and 1 = ModelID  
  
  declare @ENDYEAR int
  SET @ENDYEAR=0
  select @ENDYEAR=EndYear from SVC_Vehicle where MakeID=@MAKEID AND ModelID=@MODELID  
      if(@ENDYEAR is not null and @ENDYEAR = '0')  
      BEGIN
      
     
            select distinct VariantID,Variant,SegmentID,
             case when (segmentid=1 or segmentid=0) then ('-') else (COM_CC50024.name) end Segment,
   Specification  Specification_key,
   case when (COM_CC50031.NodeID =1 or COM_CC50031.NodeID=0 ) then ('-') else (COM_CC50031.name) end Specification,   
   EuroBSType  EuroBSType_key,
   case when (COM_CC50032.NodeID=1 or  COM_CC50032.NodeID=0) then ('-') else (COM_CC50032.name) end EuroBSType,  
    Transmission Transmission_key,
    case when (COM_CC50033.NodeID=1 or COM_CC50033.NodeID=0) then ('-') else (COM_CC50033.name) end Transmission,  
    CC CC_key,
    case when (COM_CC50034.NodeID=1 or COM_CC50034.Nodeid=0) then ('-') else (COM_CC50034.name) end  CC,  
    WheelDrive WheelDrive_key,
    case when (COM_CC50035.NodeID=1 ) then ('-') else (COM_CC50035.name) end WheelDrive,  
    SeatCapacity SeatCapacity_key,
    case when (COM_CC50036.Nodeid=1 ) then ('-') else (COM_CC50036.name) end SeatCapacity,  
    Fuel Fuel_key,
    case when (COM_CC50014.Nodeid=1 ) then ('-') else (COM_CC50014.name) end Fuel,  
            --COM_CC50024.name Segment,Specification  Specification_key,COM_CC50031.name Specification,   
            --EuroBSType  EuroBSType_key,COM_CC50032.name EuroBSType,  
            --Transmission Transmission_key,COM_CC50033.name Transmission,  
            --CC CC_key,COM_CC50034.name CC,  
            --WheelDrive WheelDrive_key,COM_CC50035.name WheelDrive,  
            --SeatCapacity SeatCapacity_key,COM_CC50036.name SeatCapacity,  
            --Fuel Fuel_key,COM_CC50014.name Fuel,
            StartYear,EndYear,VehicleID   
         from SVC_Vehicle with(nolock)  
            LEFT JOIN COM_CC50024 ON COM_CC50024.NODEID=SVC_Vehicle.SegmentID  
            LEFT JOIN COM_CC50031 ON COM_CC50031.NODEID=SVC_Vehicle.Specification  
            LEFT JOIN COM_CC50032 ON COM_CC50032.NODEID=SVC_Vehicle.EuroBSType  
            LEFT JOIN COM_CC50033 ON COM_CC50033.NODEID=SVC_Vehicle.Transmission  
            LEFT JOIN COM_CC50034 ON COM_CC50034.NODEID=SVC_Vehicle.CC  
            LEFT JOIN COM_CC50035 ON COM_CC50035.NODEID=SVC_Vehicle.WheelDrive  
            LEFT JOIN COM_CC50036 ON COM_CC50036.NODEID=SVC_Vehicle.SeatCapacity  
            LEFT JOIN COM_CC50014 ON COM_CC50014.NODEID=SVC_Vehicle.Fuel  
         where @MAKEID = MakeID and @MODELID = ModelID
      END
      ELSE
      BEGIN
      
            select distinct VariantID,Variant,SegmentID,
             case when (segmentid=1 or segmentid=0) then ('-') else (COM_CC50024.name) end Segment,
   Specification  Specification_key,
   case when (COM_CC50031.NodeID =1 or COM_CC50031.NodeID=0 ) then ('-') else (COM_CC50031.name) end Specification,   
   EuroBSType  EuroBSType_key,
   case when (COM_CC50032.NodeID=1 or  COM_CC50032.NodeID=0) then ('-') else (COM_CC50032.name) end EuroBSType,  
    Transmission Transmission_key,
    case when (COM_CC50033.NodeID=1 or COM_CC50033.NodeID=0) then ('-') else (COM_CC50033.name) end Transmission,  
    CC CC_key,
    case when (COM_CC50034.NodeID=1 or COM_CC50034.Nodeid=0) then ('-') else (COM_CC50034.name) end  CC,  
    WheelDrive WheelDrive_key,
    case when (COM_CC50035.NodeID=1 ) then ('-') else (COM_CC50035.name) end WheelDrive,  
    SeatCapacity SeatCapacity_key,
    case when (COM_CC50036.Nodeid=1 ) then ('-') else (COM_CC50036.name) end SeatCapacity,  
    Fuel Fuel_key,
    case when (COM_CC50014.Nodeid=1 ) then ('-') else (COM_CC50014.name) end Fuel,  
            --COM_CC50024.name Segment,Specification  Specification_key,COM_CC50031.name Specification,   
            --EuroBSType  EuroBSType_key,COM_CC50032.name EuroBSType,  
            --Transmission Transmission_key,COM_CC50033.name Transmission,  
            --CC CC_key,COM_CC50034.name CC,  
            --WheelDrive WheelDrive_key,COM_CC50035.name WheelDrive,  
            --SeatCapacity SeatCapacity_key,COM_CC50036.name SeatCapacity,  
            --Fuel Fuel_key,COM_CC50014.name Fuel,
            StartYear,EndYear,VehicleID   
         from SVC_Vehicle with(nolock)  
            LEFT JOIN COM_CC50024 ON COM_CC50024.NODEID=SVC_Vehicle.SegmentID  
            LEFT JOIN COM_CC50031 ON COM_CC50031.NODEID=SVC_Vehicle.Specification  
            LEFT JOIN COM_CC50032 ON COM_CC50032.NODEID=SVC_Vehicle.EuroBSType  
            LEFT JOIN COM_CC50033 ON COM_CC50033.NODEID=SVC_Vehicle.Transmission  
            LEFT JOIN COM_CC50034 ON COM_CC50034.NODEID=SVC_Vehicle.CC  
            LEFT JOIN COM_CC50035 ON COM_CC50035.NODEID=SVC_Vehicle.WheelDrive  
            LEFT JOIN COM_CC50036 ON COM_CC50036.NODEID=SVC_Vehicle.SeatCapacity  
            LEFT JOIN COM_CC50014 ON COM_CC50014.NODEID=SVC_Vehicle.Fuel  
         where @MAKEID = MakeID and @MODELID = ModelID and ((@Year between StartYear and EndYear) and (@Year>=StartYear) and (@Year<=EndYear))  
      END
   end  
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

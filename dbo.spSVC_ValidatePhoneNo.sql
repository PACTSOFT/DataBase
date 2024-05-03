USE PACT2C222
GO
SET ANSI_NULLS, QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spSVC_ValidatePhoneNo]
	@PhoneNo [nvarchar](100),
	@RegNo [nvarchar](50),
	@EditID [bigint] = 0,
	@UserID [bigint],
	@LangID [int] = 1
WITH ENCRYPTION, EXECUTE AS CALLER
AS
BEGIN TRY	
SET NOCOUNT ON
	 DECLARE @ContactCustid bigint, @VehicleCustID bigint 
	 IF(@EditID=0)
	 BEGIN 
		 if exists (select * from COM_Contacts with(nolock) where Featureid=51 and Phone1=@PhoneNo) and @PhoneNo <> ''-- and (@RegNo ='' or @RegNo is null)
		 BEGIN
			select FeaturePK  as CustomerID from COM_Contacts  with(nolock) where Featureid=51 and Phone1=@PhoneNo
			RAISERROR('-361',16,1)
		 END  
		 else if not exists (select * from COM_Contacts with(nolock) where Featureid=51 and Phone1=@PhoneNo) and @PhoneNo <> '' and (@RegNo <> '' and exists (select PlateNumber from SVC_CustomersVehicle with(nolock) where PlateNumber=@RegNo and StatusID=357))
		 BEGIN
				 select  top 1 c.CustomerID, v.VehicleID, v.MakeID,v.ModelID ,c.Year,v.VariantID ,v.SegmentID ,c.PlateNumber ,c.Color ,
					c.Fuel ,c.FuelDelivery  ,c.Cylinders ,c.EngineType from SVC_CustomersVehicle c with(nolock)
				  join svc_vehicle v with(nolock) on c.VehicleID=v.VehicleID 
				  where c.platenumber=@RegNo and c.statusid=357
				RAISERROR('-362',16,1)
		 END 
		 else if  exists (select FeaturePK from COM_Contacts with(nolock) where Featureid=51 and Phone1=@PhoneNo) and @PhoneNo <> '' and (@RegNo <> '' and exists (select CustomerID from SVC_CustomersVehicle with(nolock) where platenumber=@RegNo and StatusID=357))
		 begin  
	
			select @ContactCustid=FeaturePK from COM_Contacts with(nolock) where Featureid=51 and Phone1=@PhoneNo
			select @VehicleCustID=CustomerID from svc_customersvehicle with(nolock) where platenumber=@RegNo
			IF (@ContactCustid=@VehicleCustID)
			begin
				select CustomerID from svc_customersvehicle with(nolock) where platenumber=@RegNo
				RAISERROR('-363',16,1)
			end
		 end
	 END
	 ELSE
	 BEGIN 
	  if exists (select * from COM_Contacts with(nolock) where Featureid=51 and Phone1=@PhoneNo AND FeaturePK<>@EditID) and @PhoneNo <> '' and @RegNo is null
		 BEGIN 
			select FeaturePK  as CustomerID from COM_Contacts with(nolock) where Featureid=51 and Phone1=@PhoneNo AND FeaturePK<>@EditID
			RAISERROR('-361',16,1)
		 END  
		 else if not exists (select * from COM_Contacts with(nolock) where Featureid=51 and Phone1=@PhoneNo AND FeaturePK<>@EditID) and @PhoneNo <> '' and (@RegNo <> '' 
		 and exists (select PlateNumber from SVC_CustomersVehicle with(nolock) where PlateNumber=@RegNo AND CustomerID<>@EditID and StatusID=357))
		 BEGIN
				 select  top 1 c.CustomerID, v.VehicleID, v.MakeID,v.ModelID ,c.Year,v.VariantID ,v.SegmentID ,c.PlateNumber ,c.Color ,
					c.Fuel ,c.FuelDelivery  ,c.Cylinders ,c.EngineType from SVC_CustomersVehicle c with(nolock)
				  join svc_vehicle v with(nolock) on c.VehicleID=v.VehicleID 
				  where c.platenumber=@RegNo and c.statusid=357
				RAISERROR('-362',16,1)
		 END 
		 else if  exists (select FeaturePK from COM_Contacts with(nolock) where Featureid=51 and Phone1=@PhoneNo AND FeaturePK<>@EditID) and @PhoneNo <> '' and (@RegNo <> '' and  
		  exists (select CustomerID from SVC_CustomersVehicle with(nolock) where platenumber=@RegNo AND CustomerID<>@EditID and StatusID=357))
		 begin  
			select @ContactCustid=FeaturePK from COM_Contacts with(nolock) where Featureid=51 and Phone1=@PhoneNo AND FeaturePK<>@EditID
			select @VehicleCustID=CustomerID from svc_customersvehicle with(nolock) where platenumber=@RegNo
			IF (@ContactCustid=@VehicleCustID)
			begin
				select CustomerID from svc_customersvehicle with(nolock) where platenumber=@RegNo AND CustomerID<>@EditID
				RAISERROR('-363',16,1)
			end
		 end
	 END

SET NOCOUNT OFF;
RETURN 1
END TRY
BEGIN CATCH  
	--Return exception info [Message,Number,ProcedureName,LineNumber]  
	IF ERROR_NUMBER()=50000
	BEGIN
		SELECT ErrorMessage,ErrorNumber FROM COM_ErrorMessages WITH(nolock) WHERE ErrorNumber=ERROR_MESSAGE() AND LanguageID=@LangID
	END
SET NOCOUNT OFF  
RETURN -999   
END CATCH  




GO

USE PACT2C222
GO
SET ANSI_NULLS, QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spSVC_SetCustomerVehicle]
	@CustomerID [bigint],
	@VehicleID [bigint],
	@Year [bigint],
	@PlateNo [nvarchar](50),
	@PlateFormat [bit],
	@CustomerVehicleXML [nvarchar](max),
	@ChasisNo [nvarchar](50),
	@CompanyGUID [nvarchar](50),
	@UserName [nvarchar](50)
WITH ENCRYPTION, EXECUTE AS CALLER
AS
BEGIN Transaction
Begin try
Set NoCount oN;
declare @CreatedDate float,@CVID BIGINT
declare @XML xml

set @CreatedDate=convert(Float,getdate())
		--SELECT @CustomerVehicleXML

		IF (@CustomerVehicleXML IS NOT NULL AND @CustomerVehicleXML <> '')
		BEGIN
			 SET @XML=@CustomerVehicleXML 
				
				Update SVC_CustomersVehicle set StatusID=358
				from @XML.nodes('CustomerVehicleXML/Row') as DATA(X)
				WHERE PlateNumber = X.value('@PlateNo','NVARCHAR(300)') 
				and (X.value('@CustomerID','NVARCHAR(300)')<>@CustomerID )--and X.value('@CustomerID','NVARCHAR(300)')<>0)
				and X.value('@Action','NVARCHAR(10)')='NEW'	
			
			--If Action is NEW then insert new Address
			INSERT INTO SVC_CustomersVehicle(CustomerID,VehicleID,PlateNumber,Color,
			FuelDelivery,EngineType,Cylinders,  CompanyGUID, GUID, Createdby, CreatedDate, 
			Insurance,InsuranceExpiryDate,LoyaltyCard, CardNumber, CardExpDate, PolicyNumber,
			 InsuranceName, Year, StatusID, PlateFormat ,ChasisNumber)
			SELECT  @CustomerID,X.value('@VehicleID','bigint'), 
			 X.value('@PlateNo','NVARCHAR(300)'),
			 X.value('@Color','bigint'),
			 X.value('@FuelDelivery','bigint'), 
			 X.value('@EngineType','bigint'), 
			 X.value('@Cylinders','bigint'),@CompanyGUID,newid(),@UserName,@CreatedDate,
			 X.value('@InsuranceId','bigint'),
			 X.value('@InsuranceExpiryDate','NVARCHAR(50)'), 
			 X.value('@LoyaltyCard','int'), 
			 X.value('@CardNo','nvarchar(50)'),
			 X.value('@LoyaltyExpDate','nvarchar(50)'),
			 X.value('@PolicyNo','nvarchar(100)'),
			 X.value('@Insurance','nvarchar(500)'),
			 @Year,357 , @PlateFormat, @ChasisNo
			 from @XML.nodes('CustomerVehicleXML/Row') as DATA(X) 
			 WHERE X.value('@Action','NVARCHAR(10)')='NEW'	
		 END
		 ELSE
		 BEGIN
			insert into SVC_CustomersVehicle (CustomerID,VehicleID,PlateNumber,Color,
			FuelDelivery,Cylinders,EngineType,OdometerIn,OdometerOut,CompanyGUID,GUID,
			CreatedBy,CreatedDate,InsuranceName,InsuranceType,InsuranceNumber,
			InsuranceExpiryDate,Year,StatusID,PlateFormat,ChasisNumber,Insurance)
                                  values(@CustomerID,
									   @Vehicleid,
									   @PlateNo,
									   NULL,
									   NULL,
									   NULL,
									   NULL,
									   NULL,
									   NULL,
									   @CompanyGUID,
									   newid(),
									   @UserName,
									   @CreatedDate,
									   null,
									   NULL,
									   NULL,
									   NULL,
									   @Year,357,@PlateFormat,@ChasisNo,1)
		END
		
		SET @CVID=SCOPE_IDENTITY()
		declare @LinkRegCCID BIGINT
		SELECT @LinkRegCCID=[Value] FROM COM_CostCenterPreferences WITH(NOLOCK) WHERE FeatureID=51 AND [Name]='VehicleRegNumberLink' 
		if(@CVID>0)
		begin
			 declare @regnodeid bigint , @regnum nvarchar(100)
			 select @regnodeid= regnumbernodeid, @regnum=replace(replace(platenumber,' ',''),'-','') from svc_customersvehicle WITH(NOLOCK)  where cv_id=@CVID
			 DECLARE	@return_value int, @SID INT , @Location bigint, @CCMAPXML nvarchar(500)
			
			SELECT @SID=STATUSID FROM COM_STATUS WITH(NOLOCK) WHERE COSTCENTERID=@LinkRegCCID  and Status='Active'
			declare  @Table nvarchar(100) , @NID int
			declare @NodeidXML nvarchar(max) 
			select @Table=Tablename from adm_features where featureid=@LinkRegCCID
			declare @str nvarchar(max) 
			set @str='@NID int output' 
			set @NodeidXML='set @NID= (select NodeID from '+convert(nvarchar,@Table)+' where name='''+@regnum+''' AND STATUSID='+CONVERT(NVARCHAR,@SID)+')' 
		 	exec sp_executesql @NodeidXML, @str, @NID OUTPUT 
			IF(@NID IS NULL)
			SET @NID=0
			
			select @Location=Location from svc_customers where Customerid=@CustomerID
			
			if(@Location>1) 
				SET @CCMAPXML='<XML><Row  CostCenterId="50002" NodeID="'+CONVERT(NVARCHAR,@Location)+'"/></XML>'
			else
				set @CCMAPXML=''	
				
			if(@NID>0)
			begin
				update svc_customersvehicle set regnumbernodeid=@NID, RegCCID=@LinkRegCCID where cv_id=@CVID 
			end 
			ELSE if((@regnodeid is null OR @regnodeid =0)and @NID=0)
			begin 
				SELECT @CVID,@NID,@regnodeid  
				EXEC	@return_value = [dbo].[spCOM_SetCostCenter]
				@NodeID = 0,@SelectedNodeID = 0,@IsGroup = 0,
				@Code = @regnum,
				@Name = @regnum,
				@AliasName=@regnum,
				@PurchaseAccount=0,@SalesAccount=0,@StatusID=@SID,
				@CustomFieldsQuery=NULL,@AddressXML=NULL,@AttachmentsXML=NULL,
				@CustomCostCenterFieldsQuery=NULL,@ContactsXML=NULL,@NotesXML=NULL,
				@CostCenterRoleXML=  @CCMAPXML ,
				@CostCenterID = @LinkRegCCID,@CompanyGUID='dddd',@GUID='GUID',
				@UserName='admin',@RoleID=1,@UserID=1 
				update svc_customersvehicle set regnumbernodeid=@return_value, RegCCID=@LinkRegCCID  where cv_id=@CVID 
			end
			else if(@regnodeid > 0 and @NID=0)
			begin  
				declare @Gid nvarchar(50)-- , @Table nvarchar(100), @CGid nvarchar(50)
			--	declare @NodeidXML nvarchar(max) 
				select @Table=Tablename from adm_features where featureid=@LinkRegCCID
				--declare @str nvarchar(max) 
				set @str='@Gid nvarchar(50) output' 
				set @NodeidXML='set @Gid= (select GUID from '+convert(nvarchar,@Table)+' where NodeID='+convert(nvarchar,@regnodeid)+')' 
				exec sp_executesql @NodeidXML, @str, @Gid OUTPUT 
				
				EXEC	@return_value = [dbo].[spCOM_SetCostCenter]
				@NodeID = @regnodeid,@SelectedNodeID = 0,@IsGroup = 0,
				@Code = @regnum,
				@Name = @regnum,
				@AliasName=@regnum,
				@PurchaseAccount=0,@SalesAccount=0,@StatusID=@SID,
				@CustomFieldsQuery=NULL,@AddressXML=NULL,@AttachmentsXML='',
				@CustomCostCenterFieldsQuery=NULL,@ContactsXML=NULL,@NotesXML=NULL,
				@CostCenterRoleXML=@CCMAPXML,
				@CostCenterID = @LinkRegCCID,@CompanyGUID='dddd',@GUID=@Gid,
				@UserName='admin',@RoleID=1,@UserID=1 
			end 
			
		end
		declare @accid bigint 
		select @regnodeid=regnumbernodeid     from svc_customersvehicle WITH(NOLOCK)  where cv_id=@CVID 
		select @accid=isnull(Accountname,'1')   from svc_customers WITH(NOLOCK)  where customerid=@CustomerID 
		if(@accid is not null and @accid <>'' and @accid>1)
		begin			
			DELETE FROM COM_CostCenterCostCenterMap WHERE ParentCostCenterID=2 AND costcenterid=@LinkRegCCID and NodeID=@regnodeid
			INSERT INTO  COM_CostCenterCostCenterMap (ParentCostCenterID,ParentNodeID,CostCenterID,
			NodeID,GUID,CreatedBy,CreatedDate)
			SELECT 2,@accid,@LinkRegCCID,@regnodeid,NEWID(),'',convert(float,getdate()) --from @CCCCCData.nodes('/XML/Row') as DATA(A)  
		end
		declare @LocID bigint
		select @LocID = X.value('@Location','bigint')  from @XML.nodes('CustomerVehicleXML/Row') as DATA(X) 
			 WHERE X.value('@Action','NVARCHAR(10)')='NEW'	
		if(@regnodeid is not null and @LocID <>'' and @LocID>1)
		begin			
			DELETE FROM COM_CostCenterCostCenterMap WHERE ParentCostCenterID=@LinkRegCCID AND costcenterid=50002 and NodeID=@LocID
			INSERT INTO  COM_CostCenterCostCenterMap (ParentCostCenterID,ParentNodeID,CostCenterID,
			NodeID,GUID,CreatedBy,CreatedDate)
			SELECT @LinkRegCCID,@regnodeid,50002,@LocID,NEWID(),'',convert(float,getdate()) --from @CCCCCData.nodes('/XML/Row') as DATA(A)  
		end
		
Commit Transaction	
--SELECT * FROM SVC_CustomersVehicle WITH(nolock) WHERE CV_ID=@CV_ID
SELECT ErrorMessage,ErrorNumber FROM COM_ErrorMessages WITH(nolock) 
WHERE ErrorNumber=100 AND LanguageID=1
Set NoCount Off;
RETURN  @CVID
END try
Begin catch
	--Return exception info [Message,Number,ProcedureName,LineNumber]  
		
			SELECT ErrorMessage, ERROR_MESSAGE() AS ServerMessage,ERROR_NUMBER() as ErrorNumber, ERROR_PROCEDURE()as ProcedureName, ERROR_LINE() AS ErrorLine
			FROM COM_ErrorMessages WITH(NOLOCK) WHERE ErrorNumber=-999 AND LanguageID=1
		
	ROLLBACK TRANSACTION
end catch
 
GO

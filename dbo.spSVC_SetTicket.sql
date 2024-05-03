USE PACT2C222
GO
SET ANSI_NULLS, QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spSVC_SetTicket]
	@TicketID [bigint],
	@ServiceTicketNumber [nvarchar](50),
	@ServiceTicketTypeID [int],
	@LocationID [bigint],
	@CustomerVehicleID [bigint],
	@FamilyID [bigint],
	@StatusID [int],
	@CustomerStatusID [bigint],
	@ArrivalStatusID [bigint],
	@ArrivalDateTime [datetime] = null,
	@EstimateDateTime [datetime] = null,
	@DeliveryDateTime [datetime] = null,
	@Department [bigint],
	@ServiceEngineer [bigint],
	@Feeback [int],
	@Suggestion [nvarchar](max) = NULL,
	@OtherRequests [nvarchar](max) = NULL,
	@OdometerIn [nvarchar](50) = null,
	@OdometerOut [nvarchar](50) = null,
	@InsuranceExists [bit],
	@InsuranceID [bigint],
	@InsuranceNo [nvarchar](50) = null,
	@InsRemarks [nvarchar](max) = null,
	@PartsAmt [float],
	@PartsDisc [float],
	@LaborAmt [float],
	@LaborDisc [float],
	@SuppAmt [float],
	@SuppDisc [float],
	@SubTotal [float],
	@OverallDis [float],
	@InsuredAmt [float],
	@PrivilegeAmt [float],
	@TaxProfileID [int],
	@Total [float],
	@Balance [float],
	@TaxXML [nvarchar](max),
	@PaymentsXML [nvarchar](max),
	@ServiceDtailsXML [nvarchar](max),
	@OptionsXML [nvarchar](max),
	@VehicleCheckoutXML [nvarchar](max),
	@FeedbackXML [nvarchar](max),
	@PartsXML [nvarchar](max),
	@JobsXML [nvarchar](max),
	@InsuranceClaimXML [nvarchar](max),
	@AttachmentsXML [nvarchar](max),
	@VPlate [nvarchar](300),
	@PlateFormat [bit],
	@VChasisNo [nvarchar](50),
	@VColor [bigint],
	@EstimateAmt [float],
	@AcutalDeliveryDt [datetime] = NULL,
	@SignOffDate [datetime] = null,
	@WRID [nvarchar](100) = NULL,
	@COMPANYGUID [nvarchar](50),
	@USERNAME [nvarchar](50),
	@USERID [int],
	@LANGID [int],
	@GUID [nvarchar](50) = null,
	@DocumentXML [nvarchar](max) = null,
	@LoginRoleID [int] = 1
WITH ENCRYPTION, EXECUTE AS CALLER
AS
BEGIN TRANSACTION  
BEGIN TRY  
SET NOCOUNT ON;
		--Declaration Section  	
		DECLARE @HasAccess BIT, @TempGuid nvarchar(50) 
		DECLARE @CreatedDate FLOAT,@XML XML,@IsEdit BIT, @EstimateDocID bigint, @WODocID bigint
		declare   @ActionType int, @tickettype int

		--User access check 
		SET @HasAccess=dbo.fnCOM_HasAccess(@LoginRoleID,59,1)
		IF @HasAccess=0
		BEGIN
			RAISERROR('-105',16,1)
		END
		
		 SELECT @TempGuid=[GUID] from svc_serviceticket  WITH(NOLOCK)   
		 WHERE serviceticketid=@TicketID 
  
	   IF(@TempGuid!=@GUID and @TicketID>0)--IF RECORD ALREADY UPDATED BY SOME OTHER USER i.e DIRTY READ    
	   BEGIN    
		   RAISERROR('-101',16,1)   
	   END  
		if(@TicketID=0 and exists(select top 1 customervehicleid from svc_serviceticket with(nolock) where customervehicleid=@CustomerVehicleID and ServiceTicketTypeID not in (3,4) order by createddate desc))
		begin
			RAISERROR('-388',16,1)
		end
		else
		if(@TicketID>0 and @tickettype>1 AND
		exists(select top 1 customervehicleid from svc_serviceticket with(nolock) where customervehicleid=@CustomerVehicleID and ServiceTicketTypeID not in (3,4) and serviceticketid<>@TicketID order by createddate desc))
		begin
			RAISERROR('-388',16,1)
		end
		if(@TicketID>0)
			select @tickettype=servicetickettypeid from svc_serviceticket where serviceticketid=@TicketID 
		IF @TicketID=0
		begin
			SET @ActionType=-1008
			SET @IsEdit=0
		end
		ELSE if(@TicketID>0 and @tickettype=@ServiceTicketTypeID and @ServiceTicketTypeID=1)
		begin
			SET @ActionType=-1009
			SET @IsEdit=1
		end
		ELSE if(@TicketID>0 and @tickettype<>@ServiceTicketTypeID and @ServiceTicketTypeID=2 and @tickettype=1)
		begin
			SET @ActionType=-1010
			SET @IsEdit=1
		end
		ELSE if(@TicketID>0 and @tickettype=@ServiceTicketTypeID and @ServiceTicketTypeID=2)
		begin
			SET @ActionType=-1011
			SET @IsEdit=1
		end
		ELSE if(@TicketID>0 and @tickettype<>@ServiceTicketTypeID and @ServiceTicketTypeID=3 and @tickettype=2)
		begin
			SET @ActionType=-1012
			SET @IsEdit=1
		end
		ELSE if(@TicketID>0 and @tickettype=@ServiceTicketTypeID and @ServiceTicketTypeID=3)
		begin
			SET @ActionType=-1013
			SET @IsEdit=1
		end
		
		print @ActionType
		SET @CreatedDate=CONVERT(FLOAT,getdate())


		update dbo.SVC_CustomersVehicle set ChasisNumber= @VChasisNo, Color=@VColor,OdometerIn=@OdometerIn,OdometerOut=@OdometerOut where CV_ID=@CustomerVehicleID
                --EngineType=@VEngine,FuelDelivery=@VFuelDelivery,Cylinders=@VCylinder
 
		IF @IsEdit=0
		BEGIN
		
			--GENERATE CODE
			--IF @IsCustomerCodeAutoGen IS NOT NULL AND @IsCustomerCodeAutoGen=1 AND @CustomerID=0
			BEGIN
				--SELECT @ParentCode=[CustomerCode]
				--FROM [SVC_Customers] WITH(NOLOCK) WHERE CustomerID=@ParentID  

				--CALL AUTOCODEGEN
				EXEC [spCOM_SetCode] 59,'',@ServiceTicketNumber OUTPUT	
					
			END
		--SELECT * FROM SVC_SERVICETICKET
			INSERT INTO SVC_ServiceTicket(ServiceTicketNumber,ServiceTicketTypeID,LocationID,
						CustomerVehicleID,StatusID,CustomerStatusID,ArrivalStatusID,
						ArrivalDateTime,EstimateDateTime,DeliveryDateTime,
						Department,ServiceEngineer,Feeback,Suggestion,OtherRequests,
						OdometerIn,OdometerOut,InsuranceExists,InsuranceID,InsuranceNo,InsRemarks,
						CompanyGUID,GUID,CreatedBy,CreatedDate,FamilyID, WRID)
			VALUES(@ServiceTicketNumber,@ServiceTicketTypeID,@LocationID,
					@CustomerVehicleID,@StatusID,@CustomerStatusID,@ArrivalStatusID,
				    ROUND(CONVERT(FLOAT,@ArrivalDateTime),6),ROUND(CONVERT(FLOAT,@EstimateDateTime),6),ROUND(CONVERT(FLOAT,@DeliveryDateTime),6),
					@Department,@ServiceEngineer,@Feeback,@Suggestion,@OtherRequests,
					@OdometerIn,@OdometerOut,@InsuranceExists,@InsuranceID,@InsuranceNo,@InsRemarks,
					@COMPANYGUID,newid(),@USERNAME,@CreatedDate,@FamilyID, @WRID)
			SET @TicketID=SCOPE_IDENTITY()
			
			DECLARE	@return_value int,@LinkCostCenterID INT
			SELECT @LinkCostCenterID=[Value] FROM COM_CostCenterPreferences WITH(NOLOCK) 
			WHERE FeatureID=59 AND [Name]='ServiceTicketLinkCostCenter'

			IF @LinkCostCenterID>0
			BEGIN
			
			DECLARE @CCMAPXML NVARCHAR(500),@ExtraFields nvarchar(max), @CCFields nvarchar(max), @sysname nvarchar(100),@AccId bigint,@Regid bigint, @RegCCID bigint
			  select @sysname= syscolumnname from ADM_CostCenterDef where costcenterid=@LinkCostCenterID and ColumnCostCenterID=2 and IsColumnUserDefined=1
			  select @RegCCID =isnull(value,0) from com_costcenterpreferences with(nolock) where costcenterid=51 and name='VehicleRegNumberLink'
		
			if(@sysname<>'')
			begin
				select @AccId=isnull(AccountName,1) , @Regid=cv.RegNumberNodeID
				from svc_customers c WITH(NOLOCK) 
				left join	svc_customersvehicle cv with(nolock) on c.customerid=cv.customerid
				where cv.cv_id=@CustomerVehicleID
				if(@AccID >0)
					set @ExtraFields=''+@sysname+' ='''+convert(nvarchar,@AccID)+''','
			--	print @ExtraFields  
			end
			--	select @sysname, @RegCCID
			if(@Regid>0 and @RegCCID>0)
				set @CCFields='CCNID'+convert(nvarchar(100),(@RegCCID-50000))+' = '''+convert(nvarchar,@Regid)+''','
				--select @sysname, @RegCCID
  
		
			SET @CCMAPXML='<XML><Row  CostCenterId="50002" NodeID="'+CONVERT(NVARCHAR,@LocationID)+'"/></XML>'
				EXEC	@return_value = [dbo].[spCOM_SetCostCenter]
					@NodeID = 0,@SelectedNodeID = 0,@IsGroup = 0,
					@Code = @ServiceTicketNumber,
					@Name = @ServiceTicketNumber,
					@AliasName=@ServiceTicketNumber,
					@PurchaseAccount=0,@SalesAccount=0,@StatusID=155,
					@CustomFieldsQuery=@ExtraFields,@AddressXML=NULL,@AttachmentsXML=NULL,
					@CustomCostCenterFieldsQuery=@CCFields,@ContactsXML=NULL,@NotesXML=NULL,
					@CostCenterRoleXML=@CCMAPXML,
					@CostCenterID = @LinkCostCenterID,@CompanyGUID=@COMPANYGUID,@GUID='GUID',
					@UserName='admin',@RoleID=1,@UserID=1
					--@return_value
					UPDATE SVC_ServiceTicket
					SET CCTicketID=@return_value
					WHERE ServiceTicketID=@TicketID
			END

			--INSERT DATE CHANGE NOTIFICATION
			 if(@ArrivalDateTime<>null or @ArrivalDateTime<>'')
				INSERT INTO [SVC_ServiceTicketDatesComm]([ServiceTicketID],[ServiceTicketType],[ArrivalStatusID],[ArrivalDateTime]
							,[EstimateDateTime],[DeliveryDateTime],[CommTemplateID],[CommType],[CommSentDate],[DateChangeReason]
							,[CompanyGUID],[CreatedBy],[CreatedDate])
				VALUES(@TicketID,@ServiceTicketTypeID,@ArrivalStatusID,CONVERT(FLOAT,@ArrivalDateTime)
						,CONVERT(FLOAT,@EstimateDateTime),CONVERT(FLOAT,@DeliveryDateTime),0,0,0,'',
						@COMPANYGUID,@USERID,@CreatedDate)
		END
		ELSE
		BEGIN

			--START-- INSERT HISTORY DATA --START--
			DECLARE @TicketHistoryID BIGINT
					
			INSERT INTO [SVC_ServiceTicketHistory]
				([ServiceTicketID],[ServiceTicketNumber],[ServiceTicketTypeID],[LocationID]
				,[CustomerVehicleID],[StatusID],[CustomerStatusID],[ArrivalStatusID]
				,[ArrivalDateTime],[EstimateDateTime],[DeliveryDateTime],[Department]
				,[ServiceEngineer],[Feeback],[Suggestion],[OtherRequests]
				,[OdometerIn],[OdometerOut],[InsuranceExists],[InsuranceID],[InsuranceNo],InsRemarks
				,[CompanyGUID],[GUID],[CreatedBy],[CreatedDate],[ModifiedBy],[ModifiedDate],[CCTicketID],WRID)
			SELECT [ServiceTicketID],[ServiceTicketNumber],[ServiceTicketTypeID],[LocationID]
				,[CustomerVehicleID],[StatusID],[CustomerStatusID],[ArrivalStatusID]
				,[ArrivalDateTime],[EstimateDateTime],[DeliveryDateTime],[Department]
				,[ServiceEngineer],[Feeback],[Suggestion],[OtherRequests]
				,[OdometerIn],[OdometerOut],[InsuranceExists],[InsuranceID],[InsuranceNo],InsRemarks
				,[CompanyGUID],[GUID],[CreatedBy],[CreatedDate],[ModifiedBy],[ModifiedDate],[CCTicketID],@WRID
			FROM SVC_ServiceTicket WITH(NOLOCK)
			WHERE ServiceTicketID=@TicketID
			SET @TicketHistoryID=SCOPE_IDENTITY()

			INSERT INTO [SVC_ServiceDetailsHistory]
				([ServiceTicketHistoryID],[ServiceDetailsID],[ServiceTicketID],[SerialNumber]
				,[ServiceTypeID],[LocationID],[ReasonID],[ReasonText]
				,[CompanyGUID],[GUID],[CreatedBy],[CreatedDate],[ModifiedBy],[ModifiedDate])
			SELECT @TicketHistoryID,[ServiceDetailsID],[ServiceTicketID],[SerialNumber]
				,[ServiceTypeID],[LocationID],[ReasonID],[ReasonText]
				,[CompanyGUID],[GUID],[CreatedBy],[CreatedDate],[ModifiedBy],[ModifiedDate]
			FROM SVC_ServiceDetails WITH(NOLOCK)
			WHERE ServiceTicketID=@TicketID

			INSERT INTO [SVC_ServicePartsInfoHistory]
			   ([ServiceTicketHistoryID],[ServicePartsInfoID],[ServiceTicketID],[SerialNumber]
			   ,[ProductID],[PartVehicleID],[PackageID],[IsRequired]
			   ,[Quantity],[UOMID],[Rate],[Value]
			   ,[LaborCharge],[PartDiscount],[LaborDiscount],[Gross],[IsDeclined]
			   ,[CompanyGUID],[GUID],[CreatedBy],[CreatedDate],[ModifiedBy],[ModifiedDate]
			   ,[dcNum1],[dcCalcNum1],[dcNum2],[dcCalcNum2]
			   ,[dcNum3],[dcCalcNum3],[dcNum4],[dcCalcNum4]
			   ,[dcNum5],[dcCalcNum5],[dcNum6],[dcCalcNum6]
			   ,[dcNum7],[dcCalcNum7],[dcNum8],[dcCalcNum8]
			   ,[dcNum9],[dcCalcNum9],[dcNum10],[dcCalcNum10]
			   ,[dcNum11],[dcCalcNum11],[dcNum12],[dcCalcNum12]
			   ,[dcNum13],[dcCalcNum13],[dcNum14],[dcCalcNum14]
			   ,[dcNum15],[dcCalcNum15],[dcNum16],[dcCalcNum16]
			   ,[dcNum17],[dcCalcNum17],[dcNum18],[dcCalcNum18]
			   ,[dcNum19],[dcCalcNum19],[dcNum20],[dcCalcNum20],[EstimatedQty]
			   ,SuppPartAmt ,ShopSuppliesPercent,SSLabAmt,SSLabPercent,ShopSuppliesAmt
			   ,InsPartAmount,InsPartPercentage ,InsLabAmount,InsLabPercentage ,InsuredAmt, JobOwner, JobAmount,FinalInsuredAmt,PartID, Billable, UOMConversion, UOMConversionQty,PVALUE,LVALUE, Freight, CalcFreight,UpdatedPrice)
			SELECT @TicketHistoryID,[ServicePartsInfoID],[ServiceTicketID],[SerialNumber]
			   ,[ProductID],[PartVehicleID],[PackageID],[IsRequired]
			   ,[Quantity],[UOMID],[Rate],[Value]
			   ,[LaborCharge],[PartDiscount],[LaborDiscount],[Gross],[IsDeclined]
			   ,[CompanyGUID],[GUID],[CreatedBy],[CreatedDate],[ModifiedBy],[ModifiedDate]
			   ,[dcNum1],[dcCalcNum1],[dcNum2],[dcCalcNum2]
			   ,[dcNum3],[dcCalcNum3],[dcNum4],[dcCalcNum4]
			   ,[dcNum5],[dcCalcNum5],[dcNum6],[dcCalcNum6]
			   ,[dcNum7],[dcCalcNum7],[dcNum8],[dcCalcNum8]
			   ,[dcNum9],[dcCalcNum9],[dcNum10],[dcCalcNum10]
			   ,[dcNum11],[dcCalcNum11],[dcNum12],[dcCalcNum12]
			   ,[dcNum13],[dcCalcNum13],[dcNum14],[dcCalcNum14]
			   ,[dcNum15],[dcCalcNum15],[dcNum16],[dcCalcNum16]
			   ,[dcNum17],[dcCalcNum17],[dcNum18],[dcCalcNum18]
			   ,[dcNum19],[dcCalcNum19],[dcNum20],[dcCalcNum20],[EstimatedQty]
			   ,SuppPartAmt ,ShopSuppliesPercent,SSLabAmt,SSLabPercent,ShopSuppliesAmt
			   ,InsPartAmount,InsPartPercentage ,InsLabAmount,InsLabPercentage ,InsuredAmt, JobOwner, JobAmount,FinalInsuredAmt,PartID, Billable, UOMConversion, UOMConversionQty,PVALUE,LVALUE, Freight, CalcFreight,UpdatedPrice
			FROM SVC_ServicePartsInfo WITH(NOLOCK)
			WHERE ServiceTicketID=@TicketID

			INSERT INTO [SVC_ServiceJobsInfoHistory]
			   ([ServiceTicketHistoryID],[ServicePartsJobsInfoID],[ServiceTicketID],[SerialNumber]
			   ,[PartCategoryID],[PartsAmount],[PartsDiscount],[LaborCharge],[LaborDiscount]
			   ,[IsInsuranceCovered],[InsuranceCoveredAmount],[ShopSupplies],[ShopSuppliesPercent],[ShopSuppliesDiscount]
			   ,[TechnicianPrimary],[TechnicianSecondary],[IsDeclined],[DeclinedUsed]
			   ,[CompanyGUID],[GUID],[CreatedBy],[CreatedDate],[ModifiedBy],[ModifiedDate],Owner,  ShopSuppliesAmt, SSLabAmt, SSLabPercent, Status)
			SELECT @TicketHistoryID,[ServicePartsJobsInfoID],[ServiceTicketID],[SerialNumber]
			   ,[PartCategoryID],[PartsAmount],[PartsDiscount],[LaborCharge],[LaborDiscount]
			   ,[IsInsuranceCovered],[InsuranceCoveredAmount],[ShopSupplies],[ShopSuppliesPercent],[ShopSuppliesDiscount]
			   ,[TechnicianPrimary],[TechnicianSecondary],[IsDeclined],[DeclinedUsed]
			   ,[CompanyGUID],[GUID],[CreatedBy],[CreatedDate],[ModifiedBy],[ModifiedDate],Owner,  ShopSuppliesAmt, SSLabAmt, SSLabPercent, Status
			FROM SVC_ServiceJobsInfo WITH(NOLOCK)
			WHERE ServiceTicketID=@TicketID
			--END-- INSERT HISTORY DATA --END--

			--declare @TempEstimateDeliveryDate float
			--select @TempEstimateDeliveryDate=DeliveryDateTime from SVC_ServiceTicket
			--if(ROUND(CONVERT(FLOAT,@DeliveryDateTime),6)<>@TempEstimateDeliveryDate)
			--begin
			--	set	@ActionType=-1016
			--	set	@IsEdit=1
			--end

			UPDATE SVC_ServiceTicket
			SET ServiceTicketTypeID=@ServiceTicketTypeID,LocationID=@LocationID,
				CustomerVehicleID=@CustomerVehicleID,StatusID=@StatusID,CustomerStatusID=@CustomerStatusID,ArrivalStatusID=@ArrivalStatusID,
				ArrivalDateTime=ROUND(CONVERT(FLOAT,@ArrivalDateTime),6),EstimateDateTime=ROUND(CONVERT(FLOAT,@EstimateDateTime),6),
				DeliveryDateTime=ROUND(CONVERT(FLOAT,@DeliveryDateTime),6),
				Department=@Department,ServiceEngineer=@ServiceEngineer,
				Feeback=@Feeback,Suggestion=@Suggestion,OtherRequests=@OtherRequests,
				OdometerIn=@OdometerIn,OdometerOut=@OdometerOut,InsuranceExists=@InsuranceExists,
				InsuranceID=@InsuranceID,InsuranceNo=@InsuranceNo, InsRemarks=@InsRemarks,
				GUID=newid(),ModifiedBy=@USERNAME,ModifiedDate=@CreatedDate,FamilyID=@FamilyID, WRID=@WRID
			WHERE ServiceTicketID=@TicketID
	 
			IF (@ServiceTicketTypeID=4)
			BEGIN
				UPDATE SVC_ServiceTicket SET ActualDeliveryDateTime = ROUND(CONVERT(FLOAT,@AcutalDeliveryDt),6)
				WHERE ServiceTicketID=@TicketID
				DECLARE	@TableName NVARCHAR(200),@LinkCCID INT, @CCUPDATESQL NVARCHAR(MAX) 
				SELECT @LinkCCID=[Value] FROM COM_CostCenterPreferences WITH(NOLOCK) 
				WHERE FeatureID=59 AND [Name]='ServiceTicketLinkCostCenter'
				SELECT @TableName=tablename from ADM_Features WITH(NOLOCK) where FeatureID=@LinkCCID
				
				set @CCUPDATESQL='update '+@TableName+' set statusID=(SELECT STATUSID FROM COM_STATUS WITH(NOLOCK) WHERE COSTCENTERID =
				'+CONVERT(NVARCHAR,@LinkCCID)+' and status=''In Active'') where nodeid in (select ccticketid from SVC_ServiceTicket WITH(NOLOCK) where 
				ServiceTicketID='+Convert(nvarchar(10),@TicketID)+')'
				print @CCUPDATESQL
				EXEC (@CCUPDATESQL)  
			END
			if(@SignOffDate is not null)
				UPDATE SVC_ServiceTicket SET SignOffDate = ROUND(CONVERT(FLOAT,@SignOffDate),6), SignOff=1 
				WHERE ServiceTicketID=@TicketID 
			else if(@SignOffDate is null)
				UPDATE SVC_ServiceTicket SET SignOffDate = null, SignOff=0, signoffby=null
				WHERE ServiceTicketID=@TicketID
			
			UPDATE SVC_ServiceTicket SET SignOffby = @USERNAME
				WHERE ServiceTicketID=@TicketID and signoffby is null and signoffdate=ROUND(CONVERT(FLOAT,@SignOffDate),6)

			--INSERT DATE CHANGE NOTIFICATION
			SELECT [ServiceTicketID] FROM [SVC_ServiceTicketDatesComm] WITH(NOLOCK)
			WHERE [ServiceTicketID]=@TicketID AND ServiceTicketDatesCommID IN (SELECT MAX(ServiceTicketDatesCommID) FROM [SVC_ServiceTicketDatesComm] WITH(NOLOCK) WHERE [ServiceTicketID]=@TicketID)
				AND ([ServiceTicketType]<>@ServiceTicketTypeID OR [ArrivalStatusID]<>@ArrivalStatusID
					OR [ArrivalDateTime]<>CONVERT(FLOAT,@ArrivalDateTime) OR [EstimateDateTime]<>CONVERT(FLOAT,@EstimateDateTime)
					OR [DeliveryDateTime]<>CONVERT(FLOAT,@DeliveryDateTime))
			IF @@rowcount=1
			BEGIN
				INSERT INTO [SVC_ServiceTicketDatesComm]([ServiceTicketID],[ServiceTicketType],[ArrivalStatusID],[ArrivalDateTime]
							,[EstimateDateTime],[DeliveryDateTime],[CommTemplateID],[CommType],[CommSentDate],[DateChangeReason]
							,[CompanyGUID],[CreatedBy],[CreatedDate])
				VALUES(@TicketID,@ServiceTicketTypeID,@ArrivalStatusID,CONVERT(FLOAT,@ArrivalDateTime)
						,CONVERT(FLOAT,@EstimateDateTime),CONVERT(FLOAT,@DeliveryDateTime),0,0,0,'',
						@COMPANYGUID,@USERID,@CreatedDate)
			END

			
		END

		/****** SERVICE DETAILS INSERT ******/
		SET @XML=@ServiceDtailsXML
		
		DELETE FROM SVC_ServiceDetails WHERE ServiceTicketID=@TicketID
		
		INSERT INTO SVC_ServiceDetails(ServiceTicketID,SerialNumber,ServiceTypeID,LocationID,ReasonID,COMPANYGUID,GUID,CreatedBy,CreatedDate,VoiceofCustomer)
		SELECT @TicketID,A.value('@Sno','INT'),A.value('@Type','INT'),A.value('@Loc','INT'),A.value('@Reason','INT'),@COMPANYGUID,NEWID(),@USERNAME,@CreatedDate,A.value('@VoiceofCustomer','NVARCHAR(MAX)')
		FROM @XML.nodes('/Service/row') AS DATA(A)


		/****** OPTIONS INSERT ******/
		SET @XML=@OptionsXML
		
		DELETE FROM SVC_ServiceDetailsOptions WHERE ServiceTicketID=@TicketID
		
		INSERT INTO SVC_ServiceDetailsOptions(ServiceTicketID,OptionID,GUID,CreatedBy,CreatedDate)
		SELECT @TicketID,A.value('@ID','INT'),NEWID(),@USERNAME,@CreatedDate
		FROM @XML.nodes('/Options/row') AS DATA(A)


		/****** SERVICE PARTS INFO ******/
		SET @XML=@PartsXML
		
		DELETE FROM SVC_ServicePartsInfo WHERE ServiceTicketID=@TicketID
		
		INSERT INTO SVC_ServicePartsInfo(ServiceTicketID,SerialNumber,ProductID,PartVehicleID,PackageID,
				IsRequired,Quantity,EstimatedQty,UOMID,Rate,Value,
				LaborCharge,PartDiscount,LaborDiscount,Gross,IsDeclined,
				[dcNum1],[dcCalcNum1],[dcNum2],[dcCalcNum2],
				[dcNum3],[dcCalcNum3],[dcNum4],[dcCalcNum4],
				[dcNum5],[dcCalcNum5],[dcNum6],[dcCalcNum6],
				[dcNum7],[dcCalcNum7],[dcNum8],[dcCalcNum8],
				[dcNum9],[dcCalcNum9],[dcNum10],[dcCalcNum10],
				[dcNum11],[dcCalcNum11],[dcNum12],[dcCalcNum12],
				[dcNum13],[dcCalcNum13],[dcNum14],[dcCalcNum14],
				[dcNum15],[dcCalcNum15],[dcNum16],[dcCalcNum16],
				[dcNum17],[dcCalcNum17],[dcNum18],[dcCalcNum18],
				[dcNum19],[dcCalcNum19],[dcNum20],[dcCalcNum20],
				COMPANYGUID,GUID,CreatedBy,CreatedDate,Link,Parent 
				,SuppPartAmt ,ShopSuppliesPercent,SSLabAmt,SSLabPercent,ShopSuppliesAmt,
				InsPartAmount,InsPartPercentage ,InsLabAmount,InsLabPercentage ,InsuredAmt, FinalInsuredAmt,JobOwner, JobAmount,PartID, Billable, UOMConversion, UOMConversionQty, PValue, LValue,Freight,CalcFreight,UpdatedPrice)
		SELECT @TicketID,A.value('@Sno','INT'),A.value('@ProductID','BIGINT'),A.value('@PartVehicleID','BIGINT'),A.value('@PackageID','BIGINT'),
				A.value('@IsRequired','BIT'),A.value('@Qty','FLOAT'),A.value('@EstmQty','FLOAT'),A.value('@UOM','BIGINT'),A.value('@Rate','FLOAT'),A.value('@Value','Float'),
				A.value('@LabAmt','FLOAT'),A.value('@PartDisc','FLOAT'),A.value('@LabDisc','FLOAT'),A.value('@Gross','FLOAT'),A.value('@Declined','BIT'),
				ISNULL(A.value('@dcNum1', 'float'),0),ISNULL(A.value('@dcCalcNum1', 'float'),0),ISNULL(A.value('@dcNum2', 'float'),0),ISNULL(A.value('@dcCalcNum2', 'float'),0),
				ISNULL(A.value('@dcNum3', 'float'),0),ISNULL(A.value('@dcCalcNum3', 'float'),0),ISNULL(A.value('@dcNum4', 'float'),0),ISNULL(A.value('@dcCalcNum4', 'float'),0),
				ISNULL(A.value('@dcNum5', 'float'),0),ISNULL(A.value('@dcCalcNum5', 'float'),0),ISNULL(A.value('@dcNum6', 'float'),0),ISNULL(A.value('@dcCalcNum6', 'float'),0),
				ISNULL(A.value('@dcNum7', 'float'),0),ISNULL(A.value('@dcCalcNum7', 'float'),0),ISNULL(A.value('@dcNum8', 'float'),0),ISNULL(A.value('@dcCalcNum8', 'float'),0),
				ISNULL(A.value('@dcNum9', 'float'),0),ISNULL(A.value('@dcCalcNum9', 'float'),0),ISNULL(A.value('@dcNum10', 'float'),0),ISNULL(A.value('@dcCalcNum10', 'float'),0),
				ISNULL(A.value('@dcNum11', 'float'),0),ISNULL(A.value('@dcCalcNum11', 'float'),0),ISNULL(A.value('@dcNum12', 'float'),0),ISNULL(A.value('@dcCalcNum12', 'float'),0),
				ISNULL(A.value('@dcNum13', 'float'),0),ISNULL(A.value('@dcCalcNum13', 'float'),0),ISNULL(A.value('@dcNum14', 'float'),0),ISNULL(A.value('@dcCalcNum14', 'float'),0),
				ISNULL(A.value('@dcNum15', 'float'),0),ISNULL(A.value('@dcCalcNum15', 'float'),0),ISNULL(A.value('@dcNum16', 'float'),0),ISNULL(A.value('@dcCalcNum16', 'float'),0),
				ISNULL(A.value('@dcNum17', 'float'),0),ISNULL(A.value('@dcCalcNum17', 'float'),0),ISNULL(A.value('@dcNum18', 'float'),0),ISNULL(A.value('@dcCalcNum18', 'float'),0),
				ISNULL(A.value('@dcNum19', 'float'),0),ISNULL(A.value('@dcCalcNum19', 'float'),0),ISNULL(A.value('@dcNum20', 'float'),0),ISNULL(A.value('@dcCalcNum20', 'float'),0),
				@COMPANYGUID,NEWID(),@USERNAME,@CreatedDate, A.value('@Link','INT'),A.value('@Parent','INT'),
				A.value('@SuppPartAmt','FLOAT'),A.value('@ShopSuppliesPercent','FLOAT'), A.value('@SSLabAmt','FLOAT') , 
				A.value('@SSLabPercent','FLOAT')
				,A.value('@ShopSuppliesAmt','FLOAT') ,
				A.value('@InsPartAmount','FLOAT'),A.value('@InsPartPercentage','FLOAT'),
				 A.value('@InsLabAmount','FLOAT') , A.value('@InsLabPercentage','FLOAT')
				,A.value('@InsuredAmt','FLOAT') ,A.value('@FinalInsuredAmt','FLOAT') ,  A.value('@JobOwner','BIGINT'),  A.value('@JobAmount','FLOAT') ,A.value('@PartID','FLOAT') ,  A.value('@Billable','nvarchar(1)'),
				 A.value('@UOMConversion','FLOAT') ,A.value('@UOMConversionQty','FLOAT'), A.value('@PValue','FLOAT') ,A.value('@LValue','FLOAT'),A.value('@Freight','FLOAT') ,A.value('@CalcFreight','FLOAT'),A.value('@UpdatePrice','FLOAT')
		FROM @XML.nodes('/Parts/row') AS DATA(A)

		/****** SERVICE JOBS INFO ******/
		SET @XML=@JobsXML
		
		DELETE FROM SVC_ServiceJobsInfo WHERE ServiceTicketID=@TicketID
		
		INSERT INTO SVC_ServiceJobsInfo(ServiceTicketID,SerialNumber,PartCategoryID,
				PartsAmount,PartsDiscount,LaborCharge,LaborDiscount,
				IsInsuranceCovered,InsuranceCoveredAmount,ShopSupplies,ShopSuppliesPercent,ShopSuppliesDiscount,
				TechnicianPrimary,TechnicianSecondary,IsDeclined,
				COMPANYGUID,GUID,CreatedBy,CreatedDate, Owner, ShopSuppliesAmt, SSLabAmt, SSLabPercent, Status)
		SELECT @TicketID,A.value('@Sno','INT'),A.value('@CategoryID','BIGINT'),
				A.value('@PartsAmt','FLOAT'),A.value('@PartsDisc','FLOAT'),A.value('@LaborAmt','FLOAT'),A.value('@LaborDisc','Float'),
				0,0,A.value('@SuppAmt','FLOAT'),A.value('@SuppPercent','FLOAT'),A.value('@SuppDisc','FLOAT'),
				A.value('@PrimaryTech','BIGINT'),A.value('@SecondaryTech','BIGINT'),A.value('@Declined','BIT'),
				@COMPANYGUID,NEWID(),@USERNAME,@CreatedDate, A.value('@Owner','BIGINT'),
				 A.value('@ShopSuppliesAmt','FLOAT'), A.value('@SSLabAmt','FLOAT') ,A.value('@SSLabPercent','FLOAT'), A.value('@Status','nvarchar(20)')
		FROM @XML.nodes('/Jobs/row') AS DATA(A)


		/****** SERVICE TICKET BILL ******/
		SET @XML=@PartsXML
		
		IF @IsEdit=0
		BEGIN
			INSERT INTO SVC_ServiceTicketBill(ServiceTicketID,PartsAmount,PartsDiscount,
					LaborAmount,LaborDiscount,SuppliesAmount,SuppliesDiscount,SubTotal,
					OverallDiscount,TaxProfileID,Total,Balance,
					COMPANYGUID,GUID,CreatedBy,CreatedDate,InsuredAmt,PrivilegeAmt,EstimateAmt)
			VALUES(@TicketID,@PartsAmt,@PartsDisc,
					@LaborAmt,@LaborDisc,@SuppAmt,@SuppDisc,@SubTotal,
					@OverallDis,@TaxProfileID,@Total,@Balance,
					@COMPANYGUID,NEWID(),@USERNAME,@CreatedDate, @InsuredAmt, @PrivilegeAmt,@EstimateAmt)
		END
		BEGIN
		--declare @tempEstmAmt float
		--select @tempEstmAmt=EstimateAmt from SVC_ServiceTicketBill where ServiceTicketID=@TicketID
		--if(@tempEstmAmt<>@EstimateAmt)
		--begin
		--	SET @ActionType= -1015
		--	SET @IsEdit=1
		--end
			UPDATE SVC_ServiceTicketBill
			SET PartsAmount=@PartsAmt,PartsDiscount=@PartsDisc,
					LaborAmount=@LaborAmt,LaborDiscount=@LaborDisc,
					SuppliesAmount=@SuppAmt,SuppliesDiscount=@SuppDisc,
					SubTotal=@SubTotal,OverallDiscount=@OverallDis,
					TaxProfileID=@TaxProfileID,Total=@Total,Balance=@Balance,
					InsuredAmt=@InsuredAmt, PrivilegeAmt=@PrivilegeAmt,EstimateAmt=@EstimateAmt,
					GUID=NEWID(),ModifiedBy=@USERNAME,ModifiedDate=@CreatedDate
			WHERE ServiceTicketID=@TicketID
		END

		/****** SERVICE TICKET INSURANCE CLAIMS ******/
		SET @XML=@InsuranceClaimXML
		
		DELETE FROM SVC_ServiceTicketClaims WHERE ServiceTicketID=@TicketID
		
		INSERT INTO SVC_ServiceTicketClaims(ServiceTicketID,Sno,ClaimNo,ClaimDate,ClaimAmount,
				ApprovalMode,AppAmount,AppDoc,AppDate,SurveyorID,ClaimNumber,
				COMPANYGUID,GUID,CreatedBy,CreatedDate)
		SELECT @TicketID,A.value('@Sno','INT'),A.value('@ClaimNo','NVARCHAR(50)'),CONVERT(FLOAT,A.value('@ClaimDate','DATETIME')),A.value('@ClaimAmount','FLOAT'),
				A.value('@ApprovalMode','INT'),A.value('@AppAmount','FLOAT'),A.value('@AppDoc','BIGINT'),CONVERT(FLOAT,A.value('@AppDate','DATETIME')),A.value('@Surveyor','BIGINT'),A.value('@ClaimNumber','NVARCHAR(50)'),
				@COMPANYGUID,NEWID(),@USERNAME,@CreatedDate
		FROM @XML.nodes('/Insurance/row') AS DATA(A)


		/****** SERVICE TICKET PAYMENTS ******/
		SET @XML=@PaymentsXML
		
		declare @IsAdvance bit 
			
		DELETE FROM SVC_ServiceTicketBillPayment WHERE ServiceTicketID=@TicketID
		
		INSERT INTO SVC_ServiceTicketBillPayment(ServiceTicketID,PaymentTypeID,PaymentMode,
				PaymentDate,CurrencyID,PaymentAmount,
				InsuranceClaimNo,
				CreditCardTypeID,CreditCardNumber,CreditCardExpiryDate,CreditCardSecurityCode,
				ChequeNumber,ChequeDate,ChequeBankName,ChequeBankRountingNumber,
				GiftCoupanNumber,GiftCoupanType,
				COMPANYGUID,GUID,CreatedBy,CreatedDate,DocDetailsID ,IsAdvance)
		SELECT @TicketID,A.value('@TypeID','INT'),A.value('@Mode','NVARCHAR(20)'),
				CONVERT(FLOAT,A.value('@Date','DATETIME')),A.value('@Currency','INT'),A.value('@Amount','FLOAT'),
				A.value('@INS1','NVARCHAR(50)'),
				A.value('@CC1','INT'),A.value('@CC2','nvarchar(50)'),A.value('@CC3','nvarchar(50)'),A.value('@CC4','nvarchar(50)'),
				A.value('@CQ1','nvarchar(20)'),CONVERT(FLOAT,A.value('@CQ2','DATETIME')),A.value('@CQ3','nvarchar(200)'),A.value('@CQ4','nvarchar(50)'),
				A.value('@GC1','nvarchar(50)'),A.value('@GC2','INT'),			
				@COMPANYGUID,NEWID(),@USERNAME,@CreatedDate,A.value('@DocDetailsID','BIGINT'), A.value('@IsAdvance','BIT')
		FROM @XML.nodes('/Payments/row') AS DATA(A)

		/****** SERVICE TICKET TAXES ******/
		SET @XML=@TaxXML
		
		DELETE FROM SVC_ServiceTicketTaxes WHERE ServiceTicketID=@TicketID
		--select * from SVC_ServiceTicketTaxes
		/****** SERVICE DOCUMENT POSTING ******/
		if(@DocumentXML is not null and @DocumentXML<>'' and (@ServiceTicketTypeID=1 or @ServiceTicketTypeID=2))
		BEGIN
			DECLARE @DocXML xml
			set @DocXML=@DocumentXML  
			declare @docprefix nvarchar(100), @DocCCID bigint, @DocNodeID bigint, @Data xml, @dData nvarchar(max), @RefNodeID bigint, @date datetime
			declare @RoleID bigint ,@wid bigint, @actXML nvarchar(500), @CCGUID nvarchar(50), @DGUID nvarchar(50)
			
			SELECT @docprefix= A.value('@DocPrefix','NVARCHAR(20)'),@RoleID=A.value('@RoleID','BIGINT'),
			@RefNodeID=A.value('@CCTicketID','BIGINT'),@wid=A.value('@WID','BIGINT'),
			@DocCCID=A.value('@CostCenterID','BIGINT'),@DocNodeID=A.value('@DocID','BIGINT'),@dData=Convert(nvarchar(max),A.query('DocumentXML' )),
			@actXML=A.value('@ActivityXML','NVARCHAR(500)')		
			FROM @DocXML.nodes('/XML/Main') AS DATA(A)
			--select @docprefix, @DocCCID, @DocNodeID, @Data 
			
		 --	set @dData=convert(nvarchar(max),@Data)
		
			set @dData=replace(replace(replace(@dData,'<DocumentXML>',''),'</DocumentXML>',''),'<Row>','<Row>')
			print @dData
			set @date=getdate()
			EXEC	@return_value = [dbo].[spDOC_SetTempInvDoc]
			@CostCenterID = @DocCCID,
			@DocID = @DocNodeID,
			@DocPrefix = @docprefix,
			@DocNumber = N'',
			@DocDate = @date,
			@DueDate = NULL,
			@BillNo = '',
			@InvDocXML = @dData,
			@BillWiseXML = N'',
			@NotesXML = N'',
			@AttachmentsXML = N'',
			@ActivityXML = @actXML,
			@IsImport = 0,
			@LocationID = @LocationID,
			@DivisionID = 0 ,
			@WID = @wid,
			@RoleID = @RoleID,			
			@DocAddress = N'',
			@RefCCID =59,
			@RefNodeid  =@RefNodeID,
			@CompanyGUID = @CompanyGUID,
			@UserName = @UserName,
			@UserID = @UserID,
			@LangID = @LangID 
			 
			if(@ServiceTicketTypeID=1)
				set @EstimateDocID=@return_value
			else if(@ServiceTicketTypeID=2)
				set @WODocID=@return_value
			declare @DocGUID nvarchar(50)
			select @DocGUID=guid from inv_docdetails with(nolock) where docid=	@return_value and costcenterid=@DocCCID
		END
		--else if(@DocumentXML is not null and @DocumentXML<>'' and @ServiceTicketTypeID=3)
		--	BEGIN
		--		DECLARE @InvXML xml
		--		set @InvXML=@DocumentXML  
		--		SELECT  A.value('@InvoiceDocid','NVARCHAR(20)') 
		--		FROM @InvXML.nodes('/XML/Main') AS DATA(A)
		--	END
		
		if(@EstimateDocID is null)
			set @EstimateDocID=0
		if(@WODocID is null)
			set @WODocID=0
		/****** SERVICE TICKET ATTACHMENTS ******/
		IF (@AttachmentsXML IS NOT NULL AND @AttachmentsXML <> '')
		BEGIN
			SET @XML=@AttachmentsXML

			INSERT INTO COM_Files(FilePath,ActualFileName,RelativeFileName,
			FileExtension,FileDescription,IsProductImage,FeatureID,CostCenterID,FeaturePK,
			GUID,CreatedBy,CreatedDate)
			SELECT X.value('@FilePath','NVARCHAR(500)'),X.value('@ActualFileName','NVARCHAR(50)'),X.value('@RelativeFileName','NVARCHAR(50)'),
			X.value('@FileExtension','NVARCHAR(50)'),X.value('@FileDescription','NVARCHAR(500)'),X.value('@IsProductImage','bit'),59,59,@TicketID,
			X.value('@GUID','NVARCHAR(50)'),@UserName,@CreatedDate
			FROM @XML.nodes('/AttachmentsXML/Row') as Data(X) 	
			WHERE X.value('@Action','NVARCHAR(10)')='NEW'

			--If Action is MODIFY then update Attachments
			UPDATE COM_Files
			SET FilePath=X.value('@FilePath','NVARCHAR(500)'),
				ActualFileName=X.value('@ActualFileName','NVARCHAR(50)'),
				RelativeFileName=X.value('@RelativeFileName','NVARCHAR(50)'),
				FileExtension=X.value('@FileExtension','NVARCHAR(50)'),
				FileDescription=X.value('@FileDescription','NVARCHAR(500)'),
				IsProductImage=X.value('@IsProductImage','bit'),						
				GUID=X.value('@GUID','NVARCHAR(50)'),
				ModifiedBy=@UserName,
				ModifiedDate=@CreatedDate
			FROM COM_Files C 
			INNER JOIN @XML.nodes('/AttachmentsXML/Row') as Data(X) 	
			ON convert(bigint,X.value('@AttachmentID','bigint'))=C.FileID
			WHERE X.value('@Action','NVARCHAR(500)')='MODIFY'

			--If Action is DELETE then delete Attachments
			DELETE FROM COM_Files
			WHERE FileID IN(SELECT X.value('@AttachmentID','bigint')
				FROM @XML.nodes('/AttachmentsXML/Row') as Data(X)
				WHERE X.value('@Action','NVARCHAR(10)')='DELETE')
		END

		/****** VEHICLE CHECKOUT INSERT ******/
		SET @XML=@VehicleCheckoutXML
		
		DELETE FROM SVC_VehicleCheckout WHERE ServiceTicketID=@TicketID
		
		INSERT INTO SVC_VehicleCheckout(ServiceTicketID,CheckoutID,GUID,CreatedBy,CreatedDate)
		SELECT @TicketID,A.value('@ID','INT'),NEWID(),@USERNAME,@CreatedDate
		FROM @XML.nodes('/Checkout/row') AS DATA(A)
		
		/****** Feedback INSERT ******/
		SET @XML=@FeedbackXML
		
		DELETE FROM SVC_Feedback WHERE ServiceTicketID=@TicketID
		
		INSERT INTO SVC_Feedback(ServiceTicketID,FeedbackID,GUID,CreatedBy,CreatedDate)
		SELECT @TicketID,A.value('@ID','INT'),NEWID(),@USERNAME,@CreatedDate
		FROM @XML.nodes('/Feedback/row') AS DATA(A)
		print @FeedbackXML
		declare @FeedbackRemarks nvarchar(max)
		
		set @FeedbackRemarks =	(select top 1 A.value('@FeedbackRemarks','nvarchar(max)')
		from @XML.nodes('/Feedback/row') AS DATA(A))
		print @FeedbackRemarks
		update svc_serviceticket
		set  FeedbackRemarks= @FeedbackRemarks
		where ServiceTicketID=@TicketID
	
		

		declare @customerid bigint, @vehicleid bigint
		select @customerid=customerid, @vehicleid =vehicleid from svc_Customersvehicle where cv_ID=@CustomerVehicleID

		UPDATE SVC_ServiceTicket SET CustomerID=@customerid, Vehicleid=@vehicleid WHERE ServiceTicketID=@TicketID 

		if(@TicketID>0 and @tickettype<>@ServiceTicketTypeID and @ServiceTicketTypeID=2 and @tickettype=1)
			UPDATE SVC_ServiceTicket
			SET WorkOrderDate=@CreatedDate
			WHERE ServiceTicketID=@TicketID
		if(@TicketID>0 and @tickettype<>@ServiceTicketTypeID and @ServiceTicketTypeID=3 and @tickettype=2)
			UPDATE SVC_ServiceTicket
			SET InvoiceDate=@CreatedDate
			WHERE ServiceTicketID=@TicketID
		--Insert Notifications
		EXEC spCOM_SetNotifEvent @ActionType,59,@TicketID,@CompanyGUID,@UserName,@UserID,-1
		declare @Errormsg nvarchar(500), @errornum bigint

COMMIT TRANSACTION
--ROLLBACK TRANSACTION
SET NOCOUNT OFF;  
SELECT @Errormsg=ErrorMessage , @errornum=ErrorNumber FROM COM_ErrorMessages WITH(nolock) 
WHERE ErrorNumber=100 AND LanguageID=@LangID  
if(@ServiceTicketTypeID=1 or @ServiceTicketTypeID=2)
	SELECT * FROM INV_DocDetails WITH(nolock) WHERE DocID=@WODocID or docid=@EstimateDocID
SELECT @Errormsg, ServiceTicketID, SERVICETICKETNUMBER, CCTicketID, Convert(Datetime,SignOffDate) SignOffDate, SignOffBy,
@EstimateDocID EstimateDocid, @WODocID Workorderdocid, GUID,@DocGUID DocGUID  FROM SVC_ServiceTicket WHERE ServiceTicketID=@TicketID
RETURN @TicketID 
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
	BEGIN TRY
		ROLLBACK TRANSACTION
	END TRY  
	BEGIN CATCH 
	END CATCH

	SET NOCOUNT OFF  
	RETURN -999   
END CATCH  
GO

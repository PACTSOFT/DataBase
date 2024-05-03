USE PACT2C222
GO
SET ANSI_NULLS, QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[SpSVC_SavePartsInfo]
	@PartsInfo [nvarchar](max),
	@TicketID [bigint],
	@USERNAME [nvarchar](50),
	@UserID [bigint],
	@LangID [int] = 0
WITH ENCRYPTION, EXECUTE AS CALLER
AS
BEGIN TRANSACTION  
BEGIN TRY  
SET NOCOUNT ON;
		--Declaration Section 
		declare @dt float, @XML xml
		set @dt=CONVERT(float,getdate())
		
		SET @XML=@PartsInfo
		BEGIN 
			INSERT INTO SVC_ServicePartsInfo(ServiceTicketID,SerialNumber,ProductID,PartVehicleID,PackageID,
					IsRequired,Quantity,EstimatedQty,UOMID,Rate,Value,
					LaborCharge,PartDiscount,LaborDiscount,Gross,IsDeclined,
					COMPANYGUID,GUID,CreatedBy,CreatedDate,Link,Parent)
			SELECT @TicketID,A.value('@Sno','INT'),A.value('@ProductID','BIGINT'),0,A.value('@PackageID','BIGINT'),
					A.value('@IsRequired','BIT'),A.value('@Qty','FLOAT'),A.value('@EstmQty','FLOAT'),A.value('@UOM','BIGINT'),A.value('@Rate','FLOAT'),A.value('@Value','Float'),
					A.value('@LabAmt','FLOAT'),A.value('@PartDisc','FLOAT'),A.value('@LabDisc','FLOAT'),A.value('@Gross','FLOAT'),0,
					'', NEWID(), @USERNAME, @dt, 0, A.value('@ProductID','BIGINT')
			FROM @XML.nodes('/Parts/row') AS DATA(A)
			
			update SVC_ServicePartsInfo set partid=c.ccnid29, UOMCONVERSION=1, UOMCONVERSIONQTY=1 
			from @XML.nodes('/Parts/row') AS DATA(A) 
			left join com_ccccdata c on c.costcenterid=3 and c.nodeid=A.value('@ProductID','BIGINT') 
			
			
        END         
		 
		 
   
COMMIT TRANSACTION    
SET NOCOUNT OFF; 
SELECT ErrorMessage,ErrorNumber FROM COM_ErrorMessages WITH(nolock) 
WHERE ErrorNumber=100 AND LanguageID=@LangID  
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
	ROLLBACK TRANSACTION
	SET NOCOUNT OFF  
	RETURN -999   
END CATCH 







GO

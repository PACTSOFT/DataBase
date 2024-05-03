USE PACT2C222
GO
SET ANSI_NULLS, QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spADM_GetPrintLayouts]
	@Type [int],
	@DocumentID [bigint],
	@DocType [int],
	@LayoutList [nvarchar](max) = NULL,
	@RoleID [bigint],
	@UserID [bigint],
	@DocID [bigint] = 0,
	@LangID [int] = 1
WITH ENCRYPTION, EXECUTE AS CALLER
AS
BEGIN TRY  
SET NOCOUNT ON;
	DECLARE @LocationID BIGINT,@IsLocWise BIT,@IsBasedOn bit

	IF @Type=0
	BEGIN
		--Getting Print Layouts
		SELECT DocPrintLayoutID,Name,IsDefault 
		FROM ADM_DocPrintLayouts WITH(NOLOCK)
		WHERE DocumentID=@DocumentID AND DocType=@DocType
			AND (
				@RoleID=1 
				OR 
					DocPrintLayoutID IN (select DocPrintLayoutID from ADM_DocPrintLayoutsMap WITH(NOLOCK)
						where UserID=@UserID OR RoleID=@RoleID or GroupID IN (select GID from COM_Groups WITH(NOLOCK) where UserID=@UserID or RoleID=@RoleID))
				)
		ORDER BY [Name] ASC
	END
	ELSE IF @Type=1 or @Type=4--Location Wise Print Layout List
	BEGIN
		SET @LocationID=CONVERT(BIGINT,@LayoutList)
		if((select Value from ADM_GlobalPreferences with(nolock) where Name='EnableLocationWise')='True' 
			and (select Value from com_costcenterpreferences where CostCenterID=50002 and Name='IgnoreLWVPT')='False')
			set @IsLocWise=1
		else
			set @IsLocWise=0
			
		declare @PrefValue nvarchar(max)
		declare @TblBasedOn as Table(ID int)
		set @IsBasedOn=0
		select @PrefValue=PrefValue from com_documentpreferences with(nolock) where CostCenterID=@DocumentID and prefName='VPTBasedOn'
		if @DocID!=0 and @PrefValue is not null and @PrefValue!='' and isnumeric(@PrefValue)=1 and convert(int,@PrefValue) > 50000
		begin
			set @IsBasedOn=1
			if exists (select IsInventory from ADM_DocumentTypes with(nolock) where CostCenterID=@DocumentID and IsInventory=1)
				set @PrefValue='select distinct DCC.dcCCNID'+convert(nvarchar,convert(int,@PrefValue)-50000)+' from INV_DocDetails D with(nolock) join COM_DocCCData DCC with(nolock) on DCC.InvDocDetailsID=D.InvDocDetailsID where D.DocID='+convert(nvarchar,@DocID)
			else
				set @PrefValue='select distinct DCC.dcCCNID'+convert(nvarchar,convert(int,@PrefValue)-50000)+' from ACC_DocDetails D with(nolock) join COM_DocCCData DCC with(nolock) on DCC.AccDocDetailsID=D.AccDocDetailsID where D.DocID='+convert(nvarchar,@DocID)
			insert into @TblBasedOn
			exec(@PrefValue)
		end
		
		if @Type=1
		begin
			SELECT DocPrintLayoutID,Name,(select top 1 Copies from COM_DocPrints where TemplateID=DocPrintLayoutID and NodeID=@DocID) Copies
			FROM ADM_DocPrintLayouts P WITH(NOLOCK)			
			WHERE DocumentID=@DocumentID AND DocType=@DocType
			AND (@IsBasedOn=0 OR DocPrintLayoutID IN (select DocPrintLayoutID from ADM_DocPrintLayoutsMap M WITH(NOLOCK)join @TblBasedOn T on T.ID=M.BasedOn))
			AND (@RoleID=1 
				OR 
					(DocPrintLayoutID IN (select DocPrintLayoutID from ADM_DocPrintLayoutsMap WITH(NOLOCK)
						where UserID=@UserID OR RoleID=@RoleID or GroupID IN (select GID from COM_Groups WITH(NOLOCK) where UserID=@UserID or RoleID=@RoleID))
					AND (@IsLocWise=0 OR DocPrintLayoutID IN (select DocPrintLayoutID from ADM_DocPrintLayoutsMap WITH(NOLOCK) where CCNID2=@LocationID))
					)
				)
			ORDER BY IsDefault DESC
			
			SELECT M.MapID,M.DocPrintLayoutID,M.PrintOtherVPT,M.PrintContinue
			FROM ADM_DocPrintLayoutsMap M WITH(NOLOCK)
			WHERE M.PrintOtherVPT IS NOT NULL AND M.DocPrintLayoutID IN (
				SELECT DocPrintLayoutID FROM ADM_DocPrintLayouts WITH(NOLOCK)
				WHERE DocumentID=@DocumentID AND DocType=@DocType
				AND (@IsBasedOn=0 OR DocPrintLayoutID IN (select DocPrintLayoutID from ADM_DocPrintLayoutsMap M WITH(NOLOCK)join @TblBasedOn T on T.ID=M.BasedOn))
				AND (@RoleID=1 
					OR 
						(DocPrintLayoutID IN (select DocPrintLayoutID from ADM_DocPrintLayoutsMap WITH(NOLOCK)
							where UserID=@UserID OR RoleID=@RoleID or GroupID IN (select GID from COM_Groups WITH(NOLOCK) where UserID=@UserID or RoleID=@RoleID))
						AND (@IsLocWise=0 OR DocPrintLayoutID IN (select DocPrintLayoutID from ADM_DocPrintLayoutsMap WITH(NOLOCK) where CCNID2=@LocationID))
						)
					)
				)
			ORDER BY MapID
		end
		else if @Type=4
		begin
			SELECT *
			FROM ADM_DocPrintLayouts P WITH(NOLOCK)			
			WHERE DocumentID=@DocumentID AND DocType=@DocType
			AND (@IsBasedOn=0 OR DocPrintLayoutID IN (select DocPrintLayoutID from ADM_DocPrintLayoutsMap M WITH(NOLOCK)join @TblBasedOn T on T.ID=M.BasedOn))
			AND (@RoleID=1 
				OR 
					(DocPrintLayoutID IN (select DocPrintLayoutID from ADM_DocPrintLayoutsMap WITH(NOLOCK)
						where UserID=@UserID OR RoleID=@RoleID or GroupID IN (select GID from COM_Groups WITH(NOLOCK) where UserID=@UserID or RoleID=@RoleID))
					AND (@IsLocWise=0 OR DocPrintLayoutID IN (select DocPrintLayoutID from ADM_DocPrintLayoutsMap WITH(NOLOCK) where CCNID2=@LocationID))
					)
				)
			ORDER BY IsDefault DESC
			
			SELECT M.MapID,M.DocPrintLayoutID,M.PrintOtherVPT
			FROM ADM_DocPrintLayoutsMap M WITH(NOLOCK)
			WHERE M.PrintOtherVPT IS NOT NULL AND M.DocPrintLayoutID IN (
				SELECT DocPrintLayoutID FROM ADM_DocPrintLayouts WITH(NOLOCK)
				WHERE DocumentID=@DocumentID AND DocType=@DocType
				AND (@IsBasedOn=0 OR DocPrintLayoutID IN (select DocPrintLayoutID from ADM_DocPrintLayoutsMap M WITH(NOLOCK)join @TblBasedOn T on T.ID=M.BasedOn))
				AND (@RoleID=1 
					OR 
						(DocPrintLayoutID IN (select DocPrintLayoutID from ADM_DocPrintLayoutsMap WITH(NOLOCK)
							where UserID=@UserID OR RoleID=@RoleID or GroupID IN (select GID from COM_Groups WITH(NOLOCK) where UserID=@UserID or RoleID=@RoleID))
						AND (@IsLocWise=0 OR DocPrintLayoutID IN (select DocPrintLayoutID from ADM_DocPrintLayoutsMap WITH(NOLOCK) where CCNID2=@LocationID))
						)
					)
				)
				
			ORDER BY MapID
		end
	END
	ELSE IF @Type=2
	BEGIN
		DECLARE @Tbl AS TABLE(ID INT IDENTITY(1,1), Layout BIGINT)
		INSERT INTO @Tbl(Layout)
		EXEC SPSplitString @LayoutList,','

		--@LayoutList
		SELECT *,isnull(D.IsInventory,0) IsInventory
		FROM ADM_DocPrintLayouts L WITH(NOLOCK)
		INNER JOIN @Tbl AS T ON T.Layout=L.DocPrintLayoutID
		left join ADM_DocumentTypes D with(nolock) on D.CostCenterID=L.DocumentID
		ORDER BY ID	
	END
	ELSE IF @Type=3
	BEGIN
		if @DocumentID>40000 and @DocumentID<50000
		begin
			set @DocID=CONVERT(bigint,@LayoutList)
			
			select COUNT(*) PrintCount from COM_DocPrints with(nolock) 
			where CostCenterID=@DocumentID and NodeID=@DocID
			
		end
	END
	
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

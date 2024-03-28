USE PACT2c253
GO
SET ANSI_NULLS, QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spREN_getBAONMOP]
	@MOP [int],
	@propID [int],
	@unitID [int],
	@landlord [int],
	@userid [int],
	@langid [int]
WITH ENCRYPTION, EXECUTE AS CALLER
AS
BEGIN
Declare @MOPP int
set @MOPP=@MOP


--Cheque
if (@MOPP=1)
begin
select Alpha45 BankAccountID,'true' NoofChqvisible,'true' PayBankvisible,'true' ChequeNovisible,'true' ChqStartDatevisible  from ren_units a with(nolock)
join REN_UnitsExtended b with(nolock) on b.unitid=a.unitid
where a.unitid=@unitID
end

--Online Transfer
if (@MOPP=5)
begin
select Alpha46 BankAccountID,'false' NoofChqvisible,'false' PayBankvisible,'true' ChequeNovisible,'Reference No' ChequeNolbl,'false' ChqStartDatevisible from ren_units a with(nolock)
join REN_UnitsExtended b with(nolock) on b.unitid=a.unitid
where a.unitid=@unitID
end
	
--Credit Card
if (@MOPP=4)
begin
select Alpha44 BankAccountID,'false' NoofChqvisible,'false' PayBankvisible,'true' ChequeNovisible,'Reference No' ChequeNolbl,'false' ChqStartDatevisible from ren_units a with(nolock)
join REN_UnitsExtended b with(nolock) on b.unitid=a.unitid
where a.unitid=@unitID
end

--Cash
if (@MOPP=3)
begin
select Alpha43 BankAccountID,'false' NoofChqvisible,'false' PayBankvisible,'false' ChequeNovisible,'false' ChqStartDatevisible from ren_units a with(nolock)
join REN_UnitsExtended b with(nolock) on b.unitid=a.unitid
where a.unitid=@unitID
end

--Ejari
if (@MOPP=6)
begin
select Alpha47 BankAccountID,'true' NoofChqvisible,'true' PayBankvisible,'true' ChequeNovisible,'true' ChqStartDatevisible from ren_units a with(nolock)
join REN_UnitsExtended b with(nolock) on b.unitid=a.unitid
where a.unitid=@unitID
end

--Admin Charges
if (@MOPP=7)
begin
select Alpha48 BankAccountID,'true' NoofChqvisible,'true' PayBankvisible,'true' ChequeNovisible,'true' ChqStartDatevisible from ren_units a with(nolock)
join REN_UnitsExtended b with(nolock) on b.unitid=a.unitid
where a.unitid=@unitID
end

--Security Deposit
if (@MOPP=8)
begin
select Alpha49 BankAccountID,'true' NoofChqvisible,'true' PayBankvisible,'true' ChequeNovisible,'true' ChqStartDatevisible from ren_units a with(nolock)
join REN_UnitsExtended b with(nolock) on b.unitid=a.unitid
where a.unitid=@unitID
end



END



--select * from ADM_CostCenterDef where costcenterid=93 and usercolumnname like '%online%'
GO

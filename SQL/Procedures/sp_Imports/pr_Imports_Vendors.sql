/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2011/08/04  YA      pr_Imports_ReceiptHeaders, pr_Imports_ReceiptDetails
                      & pr_Imports_Vendors: Revised import procedures to import
                      using data elements instead of XML.
  2011/02/07  PK      Created pr_Imports_Vendors, pr_Imports_ASNLPNs, pr_Imports_ASNLPNDetails,
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Imports_Vendors') is not null
  drop Procedure pr_Imports_Vendors;
Go
/*------------------------------------------------------------------------------
  Proc pr_Imports_Vendors:
------------------------------------------------------------------------------*/
Create Procedure pr_Imports_Vendors
  (@xmlData           Xml,
   @Action            TFlag           = null,
   @VendorId          TVendorId       = null,
   @VendorName        TName           = null,
   @AddressLine1      TAddressLine    = null,
   @BusinessUnit      TBusinessUnit   = null,
   @CreatedDate       TDateTime       = null,
   @ModifiedDate      TDateTime       = null,
   @CreatedBy         TUserId         = null,
   @ModifiedBy        TUserId         = null
  )
as
  declare @vVendorContactId  TRecordId,
          @vReturnCode       TInteger;
begin
  SET NOCOUNT ON;

  /* Create an #Errors temp table if it does not exist */
  if object_id('tempdb..#Errors') is null
    create table #Errors(Error varchar(max));

  if(@xmlData is not null)
    begin
      select @VendorId        = Record.Col.value('VendorId[1]', 'TVendorId'),
             @AddressLine1    = Record.Col.value('AddressLine1[1]', 'TAddressLine'),
             @VendorName      = Record.Col.value('VendorName[1]', 'TName'),
             @Action          = Record.Col.value('Action[1]', 'TFlag'),
             @BusinessUnit    = Record.Col.value('BusinessUnit[1]', 'TBusinessUnit'),
             @CreatedDate     = nullif(Record.Col.value('CreatedDate[1]', 'TDateTime'), ''),
             @ModifiedDate    = nullif(Record.Col.value('ModifiedDate[1]', 'TDateTime'), ''),
             @CreatedBy       = Record.Col.value('CreatedBy[1]', 'TUserId'),
             @ModifiedBy      = Record.Col.value('ModifiedBy[1]', 'TUserId')
      from @xmlData.nodes('/Record') as Record(Col);
    end

  /* If the user trying to insert an existing record into the db or
                 trying to update or delete the non existing record
     then we need to resolve what to do based upon control value */
  select @Action = dbo.fn_Imports_ResolveAction('CNT', @Action, @VendorName, @BusinessUnit, null /* UserId */);

  /* Add/Update address of Contact */
  if (@Action = 'I'/* Insert */)
    begin
      insert into Contacts
        (ContactRefId,
         ContactType,
         Name,
         AddressLine1,
         BusinessUnit)
       select @VendorId,
              'V' /* Vendor */,
              @VendorName,
              @AddressLine1,
              @BusinessUnit;

       set @vVendorContactId = Scope_Identity();
     end
  else
  if (@Action = 'U'/* Update */)
    begin
      update Contacts
        set Name          = @VendorName,
            AddressLine1  = @AddressLine1
      where (ContactType = 'V' /* Vendor */) and
            (ContactRefId  = @VendorId);
    end

  /* Create a temp table based on table Vendors into which to insert our xml values */
  select * into #Vendors from Vendors where 1 = 0;

  /* Populate the temp table */
  insert into #Vendors (
    VendorId,
    VendorName,
    VendorContactId,
    Status,
    BusinessUnit,
    CreatedDate,
    ModifiedDate,
    CreatedBy,
    ModifiedBy)
  select
    @VendorId,
    @VendorName,
    @vVendorContactId,
    'A',/* As it cant be null we are updating it directly here with default value */
    @BusinessUnit,
    @CreatedDate,
    @ModifiedDate,
    @CreatedBy,
    @ModifiedBy;

  exec @vReturnCode = pr_Imports_ValidateVendor @Action output,
                                                @VendorId,
                                                @BusinessUnit;

  /* If the action is X then do nothing. */
  if (@Action = 'X' /* DoNothing */)
    return;

  /* If any errors then return to the caller */
  if (@vReturnCode > 0)
    return;

  /* Insert update or Delete based on Action */
  if (@Action = 'I' /* Insert */)
    insert into Vendors (
      VendorId,
      VendorName,
      VendorContactId,
      Status,
      BusinessUnit,
      CreatedDate,
      CreatedBy)
    select
      VendorId,
      VendorName,
      VendorContactId,
      coalesce(nullif(ltrim(rtrim(Status)), ''), 'A' /* Active */),
      BusinessUnit,
      coalesce(CreatedDate, current_timestamp),
      coalesce(CreatedBy, System_User)
    from #Vendors;
  else
  if (@Action = 'U' /* Update */)
    update V1
    set
      V1.VendorName      = V2.VendorName,
      V1.VendorContactId = V2.VendorContactId,
      V1.BusinessUnit    = V2.BusinessUnit,
      V1.ModifiedDate    = coalesce(V2.ModifiedDate, current_timestamp),
      V1.ModifiedBy      = coalesce(V2.ModifiedBy, System_User)
    from Vendors V1 inner join #Vendors V2 on (V1.VendorId = V2.VendorId);
  else
  if (@Action = 'D' /* Delete */)
    update Vendors
    set Status = 'I' /* Inactive */
    where VendorId = @VendorId;
end /* pr_Imports_Vendors */

Go

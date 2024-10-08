/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2018/03/14  TD      fn_SKUs_GetSKUs:Handling proper SKU value (HPI-1827)
  2018/01/09  TK      fn_SKUs_GetSKUs: Validate Scanned SKU with CaseUPC as well (S2G-41)
  2016/04/13  NY      fn_SKUs_GetSKUs, fn_SKUs_GetScannedSKUs : Enhanced temp table to get created and modified date (SRI-527)
  2015/12/10  SV      fn_SKUs_GetSKUs: Handled SKUs such a way that it returns the latest SKU
  2015/11/12  AY      fn_SKUs_GetScannedSKUs, fn_SKUs_GetSKUs: Add/return Ownership
  2014/11/28  DK      fn_SKUs_GetScannedSKUs, fn_SKUs_GetSKUs: Enhanced to return UoM as well
  2013/08/04  AY      fn_SKUs_GetSKUs: Enhanced for multiple UPCs per SKU
  2013/03/20  PKS     Migrated fn_SKUs_GetSKUs and fn_SKUs_GetScannedSKU
------------------------------------------------------------------------------*/

Go

if object_id('dbo.fn_SKUs_GetSKUs') is not null
  drop Function fn_SKUs_GetSKUs;
Go
/*------------------------------------------------------------------------------
  Function fn_SKUs_GetSKUs:
    Function to return the identify the exact SKU based on SKU, UPC or Barcode
    or
    by taking all attributes of SKU (SKU1..SKU5)
------------------------------------------------------------------------------*/
Create Function fn_SKUs_GetSKUs
  (@SKU          TSKU,             /* SKU/UPC/Barcode */
   @BusinessUnit TBusinessUnit,
   @SKU1         TSKU = null,
   @SKU2         TSKU = null,
   @SKU3         TSKU = null,
   @SKU4         TSKU = null,
   @SKU5         TSKU = null)
  -----------------------------
   returns       @ttSKUs table(SKUId        TRecordId,
                               SKU          TSKU,
                               Description  TDescription,
                               Status       TStatus,
                               SKU1         TSKU,
                               SKU2         TSKU,
                               SKU3         TSKU,
                               SKU4         TSKU,
                               SKU5         TSKU,
                               UoM          TUoM,
                               PutawayClass TCategory,
                               Ownership    TOwnership,
                               CreatedDate  TDateTime,
                               ModifiedDate TDateTime)
as
begin
  declare @vSKUId             TRecordId;
  declare @vUPCStripped       TUPC;
  declare @vUPCUsed           TControlValue;
  declare @vCaseUPCUsed       TControlValue;
  declare @vSKUBarcodeUsed    TControlValue;
  declare @vAlternateSKUUsed  TControlValue;
  declare @vMultipleUPCs      TControlValue;

  /* Some clients do not use UPC, some do not use Barcode field and some do
     not use Alternate SKU, so it best to define the usage and perform searches
     as necessary to improve performance */
  select @vUPCUsed          = dbo.fn_Controls_GetAsString('SKU', 'UPCUsed',          'N' /* No */, @BusinessUnit, System_User);
  select @vCaseUPCUsed      = dbo.fn_Controls_GetAsString('SKU', 'CaseUPCUsed',      'N' /* No */, @BusinessUnit, System_User);
  select @vMultipleUPCs     = dbo.fn_Controls_GetAsString('SKU', 'MultipleUPCs',     'N' /* No */, @BusinessUnit, System_User);
  select @vSKUBarcodeUsed   = dbo.fn_Controls_GetAsString('SKU', 'BarcodeUsed',      'N' /* No */, @BusinessUnit, System_User);
  select @vAlternateSKUUsed = dbo.fn_Controls_GetAsString('SKU', 'AlternateSKUUsed', 'N' /* No */, @BusinessUnit, System_User);

  /* Assume we are given SKU
    Some times we will get SKU as blank from the caller, so need to consider it */
  if (coalesce(@SKU, '') <> '')
    begin
      insert into @ttSKUs
      select SKUId, SKU, Description, Status, SKU1, SKU2, SKU3, SKU4, SKU5, UoM, PutawayClass, Ownership, CreatedDate, ModifiedDate
      from SKUs
      where (SKU          = @SKU) and
            (BusinessUnit = @BusinessUnit);

      if (@@rowcount > 0)
        return;

      if (Len(@SKU) = 12 /* UPC-A format */)
        select @vUPCStripped = right(LEFT(@SKU, LEN(@SKU) - 1), len(LEFT(@SKU, LEN(@SKU) - 1))-1);

      /* Fetch using UPC */
      if (@vUPCUsed <> 'N' /* No */)
        begin
          /* In case when user scanned with UPC and there are multiple SKUs with same UPC
             need to return the latest SKU containing the UPC */
          insert into @ttSKUs
          select SKUId, SKU, Description, Status, SKU1, SKU2, SKU3, SKU4, SKU5, UoM, PutawayClass, Ownership, CreatedDate, ModifiedDate
          from SKUs
          where ((UPC         = @SKU) or
                 (UPC         = @vUPCStripped)) and
                --(Status       = 'A') and   We may need to retrieve old SKUs as well
                (BusinessUnit = @BusinessUnit)
          order by SKUId desc;

          if (@@rowcount > 0)
            return;
        end

      /* Check if SKU has multiple UPCs */
      if (@vMultipleUPCs = 'Y' /* Yes */)
        begin
          insert into @ttSKUs
          select S.SKUId, S.SKU, S.Description, S.Status, S.SKU1, S.SKU2, S.SKU3, S.SKU4, S.SKU5, S.UoM, S.PutawayClass, Ownership, S.CreatedDate, S.ModifiedDate
          from SKUs S join SKUAttributes SA on ((SA.AttributeValue = @SKU)           or
                                                (SA.AttributeValue = @vUPCStripped)) and
                                               (SA.AttributeType  = 'UPC')           and
                                               (SA.SKUId          = S.SKUId)         and
                                               (SA.BusinessUnit   = @BusinessUnit)   and
                                               (SA.Status         = 'A' /* Active */);

          if (@@rowcount > 0)
            return;
        end

      /* Fetch by Barcode */
      if (@vSKUBarcodeUsed <> 'N' /* No */)
        begin
          insert into @ttSKUs
          select SKUId, SKU, Description, Status, SKU1, SKU2, SKU3, SKU4, SKU5, UoM, PutawayClass, Ownership, CreatedDate, ModifiedDate
          from SKUs
          where (Barcode      = @SKU) and
                (BusinessUnit = @BusinessUnit);

          if (@@rowcount > 0)
            return;
        end

      /* Fetch by Alternate SKU */
      if (@vAlternateSKUUsed <> 'N' /* No */)
        begin
          insert into @ttSKUs
          select SKUId, SKU, Description, Status, SKU1, SKU2, SKU3, SKU4, SKU5, UoM, PutawayClass, Ownership, CreatedDate, ModifiedDate
          from SKUs
          where (AlternateSKU = @SKU) and
                (BusinessUnit = @BusinessUnit);

          if (@@rowcount > 0)
            return;
        end

      /* Fetch by Alternate SKU */
      if (@vCaseUPCUsed <> 'N' /* No */)
        begin
          insert into @ttSKUs
          select SKUId, SKU, Description, Status, SKU1, SKU2, SKU3, SKU4, SKU5, UoM, PutawayClass, Ownership, CreatedDate, ModifiedDate
          from SKUs
          where (CaseUPC = @SKU) and
                (BusinessUnit = @BusinessUnit);

          if (@@rowcount > 0)
            return;
        end
    end

  /* If none of the above, then fetch using SKU1..SKU5.
     SKU1 is mandatory, others may be null */
  if (@SKU1 is not null)
    begin
      insert into @ttSKUs
      select SKUId, SKU, Description, Status, SKU1, SKU2, SKU3, SKU4, SKU5, UoM, PutawayClass, Ownership, CreatedDate, ModifiedDate
      from SKUs
      where (SKU1               = @SKU1)                     and
            (coalesce(SKU2, '') = coalesce(@SKU2, SKU2, '')) and
            (coalesce(SKU3, '') = coalesce(@SKU3, SKU3, '')) and
            (coalesce(SKU4, '') = coalesce(@SKU4, SKU4, '')) and
            (coalesce(SKU5, '') = coalesce(@SKU5, SKU5, '')) and
            (BusinessUnit       = @BusinessUnit);
    end

  return;
end /* fn_SKUs_GetSKUs */

Go

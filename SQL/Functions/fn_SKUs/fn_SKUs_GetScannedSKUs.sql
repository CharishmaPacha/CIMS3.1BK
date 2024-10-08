/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2016/04/13  NY      fn_SKUs_GetSKUs, fn_SKUs_GetScannedSKUs : Enhanced temp table to get created and modified date (SRI-527)
  2015/11/12  AY      fn_SKUs_GetScannedSKUs, fn_SKUs_GetSKUs: Add/return Ownership
  2014/11/28  DK      fn_SKUs_GetScannedSKUs, fn_SKUs_GetSKUs: Enhanced to return UoM as well
------------------------------------------------------------------------------*/

Go

if object_id('dbo.fn_SKUs_GetScannedSKUs') is not null
  drop Function fn_SKUs_GetScannedSKUs;
Go
/*------------------------------------------------------------------------------
  Function fn_SKUs_GetScannedSKUs:
    Function to return the identify the exact SKU based on SKU, UPC or Barcode
------------------------------------------------------------------------------*/
Create Function fn_SKUs_GetScannedSKUs
  (@SKU          TSKU,             /* SKU/UPC/Barcode */
   @BusinessUnit TBusinessUnit)
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
  declare @vSKUId  TRecordId;

  /* select only by SKU and not components, so pass in defaults for those */
  insert into @ttSKUs
    select * from fn_SKUs_GetSKUs(@SKU, @BusinessUnit,
                                  default, default, default, default, default)

  return
end /* fn_SKUs_GetScannedSKUs */

Go

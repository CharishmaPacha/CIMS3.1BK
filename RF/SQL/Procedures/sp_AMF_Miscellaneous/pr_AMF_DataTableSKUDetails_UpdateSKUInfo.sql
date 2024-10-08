/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/09/30  RIA     pr_AMF_DataTableSKUDetails_UpdateSKUInfo: Added SKUImageURL (CIMSV3-1110)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_AMF_DataTableSKUDetails_UpdateSKUInfo') is not null
  drop Procedure pr_AMF_DataTableSKUDetails_UpdateSKUInfo;
Go
/*------------------------------------------------------------------------------
  Procedure pr_AMF_DataTableSKUDetails_UpdateSKUInfo: This is used to update the SKU related
    information in #DataTableSKUDetails table.
------------------------------------------------------------------------------*/
Create Procedure pr_AMF_DataTableSKUDetails_UpdateSKUInfo
as
begin /* TDataTableSKUDetails */
  /* Update the SKU related info on the table and any custom things can be added later */
  update DTSD
  set DisplaySKU     = coalesce(S.DisplaySKU, S.SKU),
      DisplaySKUDesc = dbo.fn_AppendStrings(coalesce(S.DisplaySKUDesc, S.Description), ' / ', DTSD.InventoryClass1),
      SKU            = S.SKU,
      UPC            = S.UPC,
      AlternateSKU   = S.AlternateSKU,
      Barcode        = S.Barcode,
      InventoryUoM   = S.InventoryUoM,
      UoM            = S.UoM,
      IPUoMDescSL    = 'Case',
      IPUoMDescPL    = 'Cases',
      EAUoMDescSL    = 'Unit',
      EAUoMDescPL    = 'Units',
      SKUImageURL    = S.SKUImageURL
  from #DataTableSKUDetails DTSD join SKUs S on DTSD.SKUId = S.SKUId;

end /* pr_AMF_DataTableSKUDetails_UpdateSKUInfo */

Go


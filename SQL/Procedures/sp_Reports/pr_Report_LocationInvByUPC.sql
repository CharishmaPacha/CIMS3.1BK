/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/08/06  SK      pr_Report_LocationInvByUPC: New procedure to be run by client (HA-3043)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Report_LocationInvByUPC') is not null
  drop Procedure pr_Report_LocationInvByUPC;
Go
/*------------------------------------------------------------------------------
  Proc pr_Report_LocationInvByUPC: This procedure is used to take in list of UPCs
  comma separated as input to return the Location, LPN, Qty of the inventory
  for those UPCs

  e.g.:  'UPC-LabelCode,UPC-LabelCode,UPC-LabelCode,'
------------------------------------------------------------------------------*/
Create Procedure pr_Report_LocationInvByUPC
  (@UPCString        TString,
   @Warehouse        TWarehouse    = null,
   @BusinessUnit     TBusinessUnit = null,
   @UserId           TUserId       = 'cimsro')
as
  declare @vReturnCode        TInteger,
          @vMessageName       TMessageName,
          @vRecordId          TRecordId;

  declare @ttSelectedSKUs as table (RecordId    TRecordId identity(1,1),
                                    UPCString   TString,
                                    UPC         TUPC,
                                    SKUId       TRecordId,
                                    LabelCode   TInventoryClass);

  declare @ttLocationInv  as table (SKU         TSKU,
                                    SKUDesc     TDescription,
                                    UPC         TUPC,
                                    LabelCode   TInventoryClass,
                                    Location    TLocation,
                                    LPN         TLPN,
                                    Quantity    TQuantity,
                                    Warehouse   TWarehouse,

                                    RecordId    TRecordId identity(1,1));
begin
  SET NOCOUNT ON;

  select @vReturnCode  = 0,
         @vMessageName = null,
         @vRecordId    = 0;

  /* Validations */
  if (coalesce(@UPCString, '') = '')
    select @vMessageName = 'UserRunInputStringEmpty';

  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

  /* Get the list of selected SKU+IC into temporary table */
  insert into @ttSelectedSKUs(UPCString)
    select Value from dbo.fn_ConvertStringToDataSet(@UPCString, ',');

  /* Split UPC value & label code values */
  update @ttSelectedSKUs
  set UPC       = case when (charindex('-', UPCString) > 0) then substring(UPCString, 1, charindex('-', UPCString) - 1) else UPCString end,
      LabelCode = case when (charindex('-', UPCString) > 0) then substring(UPCString, charindex('-', UPCString) + 1, len(UPCString)) else null end

  /* Drop unwanted records */
  delete from @ttSelectedSKUs where (UPC is null) and (LabelCode is null);

  /* If no record exists, error out with message */
  if (not exists(select RecordId from @ttSelectedSKUs))
    exec @vReturnCode = pr_Messages_ErrorHandler 'UserRunNoRecordFound';

  /* Extract the on hand inventory based on UPC and label code provided */
  insert into @ttLocationInv (SKU, SKUDesc, UPC, LabelCode, Location, LPN, Quantity, Warehouse)
    select OHI.SKU, OHI.Description, OHI.UPC, OHI.InventoryClass1, OHI.Location, OHI.LPN, OHI.Quantity, OHI.Warehouse
    from @ttSelectedSKUs TT
      join vwExportsOnhandInventory OHI on TT.UPC = OHI.UPC and coalesce(TT.LabelCode, OHI.InventoryClass1) = OHI.InventoryClass1
    where (OHI.Warehouse = coalesce(@Warehouse, OHI.Warehouse)) and
          (OHI.BusinessUnit = coalesce(@BusinessUnit, OHI.BusinessUnit));

  /* Return the data set */
  select * from @ttLocationInv order by UPC, SKU, LabelCode, Location, LPN, Warehouse;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Report_LocationInvByUPC */

Go

/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2022/02/06  TK      pr_Imports_ASNLPNDtl_Insert: Changes to update Ownership and Warehouse on LPN details
                      pr_Imports_ASNLPNDtl_Insert, pr_Imports_ASNLPNDtl_Update: Changes to Import InventoryClasses (HA-260)
  2020/02/04  MS      pr_Imports_ASNLPNDetails, pr_Imports_ASNLPNDtl_Insert,
  2019/02/04  OK      Refactored the code into pr_Imports_ASNLPNDtl_Insert, pr_Imports_ASNLPNDtl_Update, pr_Imports_ASNLPNDtl_Delete
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Imports_ASNLPNDtl_Insert') is not null
  drop Procedure pr_Imports_ASNLPNDtl_Insert;
Go
/*------------------------------------------------------------------------------
  Proc pr_Imports_ASNLPNDtl_Insert: Insert the ASN details from the input temp
   table into the actual table. No AT is required for details as CreatedDate,
   CreatedBy give all necessary info
------------------------------------------------------------------------------*/
Create Procedure pr_Imports_ASNLPNDtl_Insert
  (@ImportASNLPNDetails  TASNLPNImportType READONLY)
as
  declare @vReturnCode        TInteger,
          @vMessageName       TMessageName,
          @vRecordId          TRecordId;
begin
  SET NOCOUNT ON;

  /* Insert the LPN Detail */
  insert into LPNDetails (
    LPNId, CoO, SKUId, OnhandStatus,
    InnerPacks, Quantity,
    UnitsPerPackage,
    ReceivedUnits,
    ReceiptId, ReceiptDetailId,
    Weight, Volume, Lot,
    InventoryClass1, InventoryClass2, InventoryClass3,
    UDF1, UDF2, UDF3, UDF4, UDF5,
    BusinessUnit, CreatedDate, CreatedBy)
  output 'LPN', Inserted.LPNId, null, 'AT_ASNLPNLineInserted' /* Audit Activity */, 'I' /* Action - Insert */,
         Inserted.BusinessUnit, Inserted.ModifiedBy
  into #ImportASNAuditInfo (EntityType, EntityId, EntityKey, ActivityType, Action, BusinessUnit, UserId)
  select
    ASNLD.LPNId, ASNLD.CoO, ASNLD.SKUId, coalesce(ASNLD.OnhandStatus, 'U' /* Unavailable */),
    coalesce(ASNLD.InnerPacks, 0), coalesce(ASNLD.Quantity, 0),
    /* Update the UnitsPerInnerPack from SKUs */
    case when ASNLD.InnerPacks > 0 then ASNLD.Quantity/ASNLD.InnerPacks
         when (S.UnitsPerInnerPack > 0) and (ASNLD.Quantity % S.UnitsPerInnerPack = 0)
           then ASNLD.Quantity/S.UnitsPerInnerPack
         else 0
    end,
    coalesce(ASNLD.ReceivedUnits, 0),
    ASNLD.ReceiptId, ASNLD.ReceiptDetailId,
    coalesce(ASNLD.Weight, 0.00), ASNLD.Volume, ASNLD.Lot, -- ToDo: Enhance to calc Weight and Volume from SKU
    coalesce(trim(ASNLD.InventoryClass1), ''), coalesce(trim(ASNLD.InventoryClass2), ''), coalesce(trim(ASNLD.InventoryClass3), ''),
    ASNLD.LPND_UDF1, ASNLD.LPND_UDF2, ASNLD.LPND_UDF3, ASNLD.LPND_UDF4, ASNLD.LPND_UDF5,
    ASNLD.BusinessUnit, coalesce(nullif(ASNLD.CreatedDate, ''), current_timestamp), coalesce(nullif(ASNLD.CreatedBy, ''), System_User)
  from @ImportASNLPNDetails ASNLD
    join SKUs S on (ASNLD.SKUId = S.SKUId)
  where (RecordAction = 'I' /* Insert */) and (LPNType = 'C'/* Carton */);

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Imports_ASNLPNDtl_Insert */

Go

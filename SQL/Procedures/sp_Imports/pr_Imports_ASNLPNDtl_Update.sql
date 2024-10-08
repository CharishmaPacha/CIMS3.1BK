/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2023/01/20  TK      pr_Imports_ASNLPNDtl_Delete, pr_Imports_ASNLPNDtl_Insert, pr_Imports_ASNLPNDtl_Update,
                      pr_Imports_ASNLPNDtl_Insert, pr_Imports_ASNLPNDtl_Update: Changes to Import InventoryClasses (HA-260)
  2019/02/04  OK      Refactored the code into pr_Imports_ASNLPNDtl_Insert, pr_Imports_ASNLPNDtl_Update, pr_Imports_ASNLPNDtl_Delete
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Imports_ASNLPNDtl_Update') is not null
  drop Procedure pr_Imports_ASNLPNDtl_Update;
Go
/*------------------------------------------------------------------------------
  Proc pr_Imports_ASNLPNDtl_Update: Update the ASN LPN Details using the input
   temp table. We are making an assumption here that LPNDetailId is already
   identified for the record being imported
------------------------------------------------------------------------------*/
Create Procedure pr_Imports_ASNLPNDtl_Update
  (@ImportASNLPNDetails  TASNLPNImportType READONLY)
as
  declare @vReturnCode        TInteger,
          @vMessageName       TMessageName,
          @vRecordId          TRecordId;
begin
  SET NOCOUNT ON;

  /* Update the details */
  update LD1
  set
    LD1.CoO             = LD2.CoO,
    LD1.SKUId           = LD2.SKUId,
    LD1.InnerPacks      = LD2.InnerPacks,
    LD1.Quantity        = LD2.Quantity,
    LD1.UnitsPerPackage = LD2.UnitsPerPackage,
    LD1.ReceiptId       = LD2.ReceiptId,
    LD1.ReceiptDetailId = LD2.ReceiptDetailId,
    LD1.Weight          = LD2.Weight,
    LD1.Volume          = LD2.Volume,
    LD1.Lot             = LD2.Lot,
    LD1.InventoryClass1 = coalesce(trim(LD2.InventoryClass1), ''),
    LD1.InventoryClass2 = coalesce(trim(LD2.InventoryClass2), ''),
    LD1.InventoryClass3 = coalesce(trim(LD2.InventoryClass3), ''),
    LD1.UDF1            = LD2.LPND_UDF1,
    LD1.UDF2            = LD2.LPND_UDF2,
    LD1.UDF3            = LD2.LPND_UDF3,
    LD1.UDF4            = LD2.LPND_UDF4,
    LD1.UDF5            = LD2.LPND_UDF5,
    LD1.ModifiedDate    = coalesce(LD2.ModifiedDate, current_timestamp),
    LD1.ModifiedBy      = coalesce(LD2.ModifiedBy, System_User)
    output 'LPN', Inserted.LPNId, null, 'AT_ASNLPNLineModified' /* Audit Activity */, 'U' /* Action - Update */,
           Inserted.BusinessUnit, Inserted.ModifiedBy
    into #ImportASNAuditInfo (EntityType, EntityId, EntityKey, ActivityType, Action, BusinessUnit, UserId)
  from LPNDetails LD1 inner join @ImportASNLPNDetails LD2 on (LD1.LPNId = LD2.LPNId) and (LD1.LPNDetailId = LD2.LPNDetailId)
  where (LD2.RecordAction = 'U' /* Update */);

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Imports_ASNLPNDtl_Update */

Go

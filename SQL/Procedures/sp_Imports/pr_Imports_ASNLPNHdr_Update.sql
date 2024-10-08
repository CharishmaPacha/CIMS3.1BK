/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/04/22  MS      pr_Imports_ReceiptDetails, pr_Imports_OrderDetail, pr_Imports_ASNLPNHeaders, pr_Imports_ASNLPNs, pr_Imports_ASNLPNHdr_Insert, pr_Imports_ASNLPNHdr_Update
                      pr_Imports_ASNLPNHdr_Insert, pr_Imports_ASNLPNHdr_Update, pr_Imports_ASNLPNHdr_Delete (HPI-2363)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Imports_ASNLPNHdr_Update') is not null
  drop Procedure pr_Imports_ASNLPNHdr_Update;
Go
/*------------------------------------------------------------------------------
  Proc pr_Imports_ASNLPNHdr_Update:
------------------------------------------------------------------------------*/
Create Procedure pr_Imports_ASNLPNHdr_Update
  (@ImportASNLPNHeaders  TASNLPNImportType READONLY)
as
  declare @vReturnCode        TInteger,
          @vMessageName       TMessageName,
          @vRecordId          TRecordId;
begin
  SET NOCOUNT ON;

  /* Update the LPN Header */
  update L1
  set
    L1.PalletId        = L2.PalletId,
    L1.ActualWeight    = L2.LPNWeight,
    L1.Ownership       = L2.Ownership,
    L1.InventoryClass1 = coalesce(trim(L2.InventoryClass1), ''),
    L1.InventoryClass2 = coalesce(trim(L2.InventoryClass2), ''),
    L1.InventoryClass3 = coalesce(trim(L2.InventoryClass3), ''),
    L1.ReceiptId       = L2.ReceiptId,
    L1.ReceiptNumber   = L2.ReceiptNumber,
    L1.ASNCase         = L2.ASNCase,
    L1.ReceivedDate    = L2.ReceivedDate,
    L1.ExpiryDate      = L2.ExpiryDate,
    L1.DestWarehouse   = L2.DestWarehouse,
    L1.Location        = L2.Location,
    L1.UDF1            = L2.LPN_UDF1,
    L1.UDF2            = L2.LPN_UDF2,
    L1.UDF3            = L2.LPN_UDF3,
    L1.UDF4            = L2.LPN_UDF4,
    L1.UDF5            = L2.LPN_UDF5,
    L1.UDF6            = L2.LPN_UDF6,
    L1.UDF7            = L2.LPN_UDF7,
    L1.UDF8            = L2.LPN_UDF8,
    L1.UDF9            = L2.LPN_UDF9,
    L1.UDF10           = L2.LPN_UDF10,
    L1.ModifiedDate    = coalesce(L2.ModifiedDate, current_timestamp),
    L1.ModifiedBy      = coalesce(L2.ModifiedBy, System_User)
  output 'LPN', Inserted.LPNId, Inserted.LPN, 'AT_ASNLPNHeaderModified' /* Audit Activity */, 'U',
         Inserted.BusinessUnit, Inserted.ModifiedBy
  into #ImportASNAuditInfo (EntityType, EntityId, EntityKey, ActivityType, Action, BusinessUnit, UserId)
  from LPNs L1
    join @ImportASNLPNHeaders L2 on (L1.LPNId = L2.LPNId)
  where (L2.RecordAction = 'U');

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Imports_ASNLPNHdr_Update */

Go

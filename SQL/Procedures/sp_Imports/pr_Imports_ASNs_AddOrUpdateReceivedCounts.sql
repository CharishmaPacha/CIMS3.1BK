/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2019/03/07  RIA     pr_Imports_ASNs_AddOrUpdateReceivedCounts: Changes to update status in receivedcounts properly (CID-96)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Imports_ASNs_AddOrUpdateReceivedCounts') is not null
  drop Procedure pr_Imports_ASNs_AddOrUpdateReceivedCounts;
Go
/*------------------------------------------------------------------------------
  Proc pr_Imports_ASNs_AddOrUpdateReceivedCounts:
------------------------------------------------------------------------------*/
Create Procedure pr_Imports_ASNs_AddOrUpdateReceivedCounts
  (@ASNLPNDetailsImported TASNLPNImportType READONLY)
as
  declare @vReturnCode       TInteger,
          @vRecordId         TRecordId,
          @vBusinessUnit     TBusinessUnit;
begin
  SET NOCOUNT ON;

  set @vRecordId = 0;

  if (exists(select * from @ASNLPNDetailsImported where RecordAction = 'I' /* Insert */))
    begin
      insert into ReceivedCounts(ReceiptId,  ReceiptNumber,
                                 ReceiverId, ReceiverNumber,
                                 ReceiptDetailId,
                                 Status,
                                 PalletId, Pallet,
                                 LocationId, Location,
                                 LPNId,LPN,LPNDetailId,
                                 SKUId, SKU,
                                 InnerPacks, Quantity,
                                 UnitsPerPackage,
                                 Ownership, Warehouse, BusinessUnit,
                                 CreatedBy)
                          select ttALDI.ReceiptId, ttALDI.ReceiptNumber,
                                 null /* ReceiverId */, null /* ReceiverNumber */, /* We dont have Receiver info at this stage */
                                 ttALDI.ReceiptDetailId,
                                 'A' /* Active - ReceivedCount status is either Active of Voided */,
                                 L.PalletId, L.Pallet,
                                 L.LocationId, L.Location,
                                 L.LPNId, L.LPN, LD.LPNDetailId,
                                 LD.SKUId, ttALDI.SKU,
                                 LD.InnerPacks, LD.Quantity, LD.UnitsPerPackage,
                                 L.Ownership, L.DestWarehouse, ttALDI.BusinessUnit,
                                 system_user
                          from @ASNLPNDetailsImported ttALDI
                            join LPNs L on (L.LPNId = ttALDI.LPNId)
                            join LPNDetails LD on (L.LPNId = LD.LPNId) and (ttALDI.SKUId = LD.SKUId)
                          where (RecordAction = 'I' /* Insert */);
    end

  if (exists(select * from @ASNLPNDetailsImported where RecordAction = 'U' /* Update */))
    begin
      update RC
      set RC.InnerPacks       = ttALDI.InnerPacks,
          RC.Quantity         = ttALDI.Quantity,
          RC.UnitsPerPackage  = ttALDI.UnitsPerPackage,
          RC.ModifiedDate     = current_timestamp,
          RC.ModifiedBy       = system_user
      from ReceivedCounts RC
        join @ASNLPNDetailsImported ttALDI on (ttALDI.LPNId = RC.LPNId) and (ttALDI.LPNDetailId = RC.LPNDetailId)
      where (ttALDI.RecordAction = 'U' /* Update */);
    end

  /* if ASN details are deleted, then mark the ReceivedCounts as voided */
  if (exists(select * from @ASNLPNDetailsImported where RecordAction = 'D' /* Delete */))
    begin
      update RC
      set RC.Status           = 'V',
          RC.ModifiedDate     = current_timestamp,
          RC.ModifiedBy       = system_user
      from ReceivedCounts RC
        join @ASNLPNDetailsImported ttALDI on (ttALDI.LPNId = RC.LPNId) and (ttALDI.LPNDetailId = RC.LPNDetailId)
      where (ttALDI.RecordAction = 'D' /* Delete */);
    end

end /* pr_Imports_ASNs_AddOrUpdateReceivedCounts */

Go

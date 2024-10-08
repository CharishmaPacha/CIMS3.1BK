/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/04/22  MS      pr_Imports_ReceiptDetails, pr_Imports_OrderDetail, pr_Imports_ASNLPNHeaders, pr_Imports_ASNLPNs, pr_Imports_ASNLPNHdr_Insert, pr_Imports_ASNLPNHdr_Update
                      pr_Imports_ASNLPNHdr_Insert, pr_Imports_ASNLPNHdr_Update, pr_Imports_ASNLPNHdr_Delete (HPI-2363)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Imports_ASNLPNHdr_Insert') is not null
  drop Procedure pr_Imports_ASNLPNHdr_Insert;
Go
/*------------------------------------------------------------------------------
  Proc pr_Imports_ASNLPNHdr_Insert:
------------------------------------------------------------------------------*/
Create Procedure pr_Imports_ASNLPNHdr_Insert
  (@ImportASNLPNHeaders  TASNLPNImportType READONLY)
as
  declare @vReturnCode        TInteger,
          @vMessageName       TMessageName,
          @vRecordId          TRecordId;
begin
  SET NOCOUNT ON;

  /* Insert update or Delete based on Action */
  insert into LPNs (
    LPN, UniqueID, LPNType, Status,
    PalletId, ActualWeight,
    InventoryStatus, OnhandStatus, Ownership,
    InventoryClass1, InventoryClass2, InventoryClass3,
    ReceiptId, ReceiptNumber,
    ASNCase, ReceivedDate, ExpiryDate, DestWarehouse, Location,
    UDF1, UDF2, UDF3, UDF4, UDF5, UDF6, UDF7, UDF8, UDF9, UDF10,
    BusinessUnit, CreatedDate, CreatedBy)
  select
    LPN, LPN, LPNType, coalesce(nullif(ltrim(rtrim(Status)), ''), 'T' /* InTransit */),
    PalletId, LPNWeight,
    coalesce(InventoryStatus, 'N'), OnhandStatus, Ownership,
    coalesce(trim(InventoryClass1), ''), coalesce(trim(InventoryClass2), ''), coalesce(trim(InventoryClass3), ''),
    ReceiptId, ReceiptNumber,
    ASNCase, ReceivedDate, ExpiryDate, DestWarehouse, Location,
    LPN_UDF1, LPN_UDF2, LPN_UDF3, LPN_UDF4, LPN_UDF5, LPN_UDF6, LPN_UDF7, LPN_UDF8, LPN_UDF9, LPN_UDF10,
    BusinessUnit, coalesce(CreatedDate, current_timestamp), coalesce(CreatedBy, System_User)
  from @ImportASNLPNHeaders
  where (RecordAction = 'I' /* Insert */);

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Imports_ASNLPNHdr_Insert */

Go

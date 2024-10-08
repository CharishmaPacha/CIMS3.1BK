/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2014/12/03  SV      pr_Exports_Inv_ExpiryData: Had commented a piece of code which is GNC specific
  2014/09/04  PK      pr_Exports_Inv_ExpiryData: Populating Location field to host table 'uc_sdi_export_invexpirydata'.
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Exports_Inv_ExpiryData') is not null
  drop Procedure pr_Exports_Inv_ExpiryData;
Go
/*------------------------------------------------------------------------------
  Proc pr_Exports_Inv_ExpiryData:
------------------------------------------------------------------------------*/
Create Procedure pr_Exports_Inv_ExpiryData
as
  declare @ttOnhandInventory table (SKU           TSKU,
                                    SKU1          TSKU,
                                    SKU2          TSKU,
                                    SKU3          TSKU,
                                    SKU4          TSKU,
                                    SKU5          TSKU,
                                    Location      TLocation,
                                    Lot           TLot,
                                    ExpiryDate    TDate,
                                    OnhandStatus  TStatus,
                                    Quantity      TQuantity);
begin
  /* As per GNC request, Update the processed records */
  /* Update HostExportInvExpiryData
  set processed_flg = 1
  where coalesce(processed_flg, 0) = 0; */

  insert into @ttOnhandInventory (SKU,
                                  SKU1,
                                  SKU2,
                                  SKU3,
                                  SKU4,
                                  SKU5,
                                  Location,
                                  Lot,
                                  ExpiryDate,
                                  OnhandStatus,
                                  Quantity)
                           select SKU,
                                  SKU1,
                                  SKU2,
                                  SKU3,
                                  SKU4,
                                  SKU5,
                                  Location,
                                  Lot,
                                  ExpiryDate,
                                  OHStatus,
                                  sum(Quantity)
                           from vwExportsOnhandInventory
                           group by SKU, SKU1, SKU2, SKU3, SKU4, SKU5, Lot, ExpiryDate, OHStatus, Location
                           having sum(Quantity) > 0;

  /* insert into external table from temp table */
  /* insert into HostExportInvExpiryData (SKU, SKU1, SKU2, SKU3, SKU4, SKU5, Location,
                                       LotNumber, ExpiryDate, AvailableQty, ReservedQty,
                                       OnhandQuantity, ReceivedQuantity, TransDateTime) */
  select coalesce(SKU,  '') as SKU,
         coalesce(SKU1, '') as SKU1,
         coalesce(SKU2, '') as SKU2,
         coalesce(SKU3, '') as SKU3,
         coalesce(SKU4, '') as SKU4,
         coalesce(SKU5, '') as SKU5,
         coalesce(Location, '') as Location,
         coalesce(Lot, '') as LotNumber,
         coalesce(ExpiryDate, '') as ExpiryDate,
         coalesce(Available, 0) as AvailableQty,
         coalesce(Reserved,  0) as ReservedQty,
         coalesce(Available, 0) + coalesce(Reserved, 0) as OnhandQty,
         coalesce(Received,  0) as ReceivedQty,
         current_timestamp as TransDateTime
  from (select SKU,
               SKU1,
               SKU2,
               SKU3,
               SKU4,
               SKU5,
               Location,
               Lot,
               ExpiryDate,
               OnhandStatus,
               Quantity
        from @ttOnhandInventory) up
  PIVOT (sum(Quantity) For OnhandStatus in (Available, Received, Reserved)) as pvt
end /* pr_Exports_InvExpiryData */

Go

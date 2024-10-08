/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2023/02/14  MS      TOnhandInventorySKUsToShip: Changes to use InventoryKey as Primary Key (BK-1020)
  2023/01/18  MS      TOnhandInventorySKUsToShip: Added Lot & corrected inventorykey computation (BK-992)
  2022/06/22  SRP     Changed Data Type for SKUImageURL (BK-832)
  2022/02/28  LAC     Added TURL (BK-775)
  2022/02/15  AY      TUniqueId: Added (FBV3-774)
  2022/02/02  RKC     Added TLPNDetails.UoM (BK-218)
  2021/10/19  TK      Added TLPNsInfo (HA-3182)
  2021/07/31  TK      TLPNDetails: Added LoadType (HA-3031)
  2021/04/21  TK      TLPNDetails: Added ShipmentId (HA-2641)
  2021/04/04  AY      TLPNDetails: Added PalletType, PickTicket, LoadId, LoadNumber, EntityId (HA-1842)
  2021/01/06  RKC     Added THarmonizedCode (CID-1616)
  2020/11/24  RIA     TDataTableSKUDetails: Added LPNDetailId, OrderDetailId, ReceiptDetailId (CIMSV3-1236)
  2020/10/22  RIA     TDataTableSKUDetails: Added DisplayUDFs1-5 (JL-271)
  2020/09/30  RIA     TDataTableSKUDetails: Added SKUImageURL (CIMSV3-1110)
  2020/09/12  TK      TLPNDetails: Added ConsumedQty (HA-1238)
  2020/09/01  RIA     TDataTableSKUDetails: Added MinQty, MaxQty, CurrentUoM (OB2-1199)
  2020/08/31  RIA     TDataTableSKUDetails: Added LPN, Pallet, NumLPNs, NumPallets, UDFs1-5 (HA-527)
  2020/07/26  TK      TInventoryTransfer: Added more fields required for BulkMove action (HA-1115)
  2020/07/11  TK      TInventoryTransfer: Added ProcessFlag, ActivityType & Comment (HA-1115)
  2020/06/24  VS      Added TOnhandInventorySKUsToShip,TOnhandInventoryResult,TOnhandInventory2 (FB-2029)
  2020/07/01  TK      TLPNDetails: Added PalletId  & Pallet (HA-830)
  2020/06/25  VM      Added TSizeScale, TSizeSpread (HA-1013)
  2020/06/22  TK      Added TInventoryTransfer
                      TLPNDetails: Added more fields as needed (HA-833)
  2020/06/08  RIA     Added QtyOrdered, QtyReceived (HA-491)
  2020/06/08  TK      TLPNDetails: Added WaveNo (HA-820)
  2020/05/24  SK      Added ProcessedFlag field to TLPNDetails (HA-640)
              TK      TLPNDetails: Added InventoryClasses (HA-521)
  2020/05/13  AY      Add InventoryClasses to TDataTableSKUDetails (HA-???)
  2020/04/29  RIA     Added TDataTableSKUDetails (CIMSV3-756)
  2020/04/29  MS      TOnhandInventory: Changes to send InventoyClasses in Exports (HA-323)
  2020/04/25  TK      TLPNDetails: Added LPN, Reference, BusinessUnit & CreatedBy (HA-171)
  2020/03/21  AY      TInventoryClass: Added (CIMS-2984)
  2020/03/01  AY      TSizeList: Added (JL-123)
  2019/09/12  SK      TLPNDetails: Added WaveId (FB-1460)
  2019/09/16  AY      TLPNDetails: New (FB-1351)
  2019/05/28  AY      Added TZones (for list of zones).
  2019/04/28  AY      Deprecated TZoneId in favour of TZone
  2018/11/06  AY      Added TLocationSubType (HPI-2119)
  2018/05/06  DK      TOnhandInventory: Added UnitsToFulfill (FB-1150)
  2018/03/30  YJ      TOnhandInventory: Added SourceSystem (FB-1114)
  2016/09/24  AY      TOnhandInventory: Added index for performance (HPI-GoLive)
  2016/05/30  TK      TOnhandInventory: Added ProcessFlag (HPI-31)
  2016/05/27  TK      TOnhandInventory: Added fields for Logging (HPI-31)
  2016/03/10  RV      Added TOnhandInventory (CIMS-809)
  2015/12/03  SV      Added TSKUChange (SRI-422)
  2015/10/14  PK      Added TBay
  2015/02/13  SV      Moved TOwnership, TWarehouse to Domains_Core as we are using in TRuleSetsTable there
  2014/09/17  PKS     Moved TPutawayRulesInfo to Domains_TempTables.Sql
  2014/08/23  VM      Dropped TPickSequence in this file as it should a varchar and moved it to Domains_Sales
  2014/03/27  TD      Added TPickingClass.
  2014/03/24  AY      TPutawayRulesInfo: Changed PAClass to SKUPAClass and added LPNPAClass
  2013/10/03  AY      Added TPutawayRulesInfo
  2013/03/27  AY      Expanded TLocationType to 10 chars.
  2011/03/01  AY      Expanded TStorageType to 10 chars.
  2011/12/28  VM      Added TTaskBatchNo.
  2011/10/02  AY      Added TSerialNo (to capture GiftCardNo Serial No of product)
  2011/08/10  VM      TZoneId size increased: As we are using LookUps table to store Zones and
                        using LookUpCode field for ZoneId, set it to be equivalent as TLookUpCode size.
  2011/08/04  DP      Added TZoneId.
  2011/01/18  TD      Changed TLocationType, TStorageType from Char(2) to varchar(2).
  2011/01/18  VM      Corrected TRow, TSection, TLevel data types and lengths.
  2010/10/26  VM      TCoE => TCoO
  2010/09/20  PK      Initial revision.
------------------------------------------------------------------------------*/

Go

/* Common */
Create Type TShipmentId                from integer;            Grant References on Type:: TShipmentId                to public;
Create Type TLoadId                    from integer;            Grant References on Type:: TLoadId                    to public;
Create Type TLoadNumber                from varchar(60);        Grant References on Type:: TLoadNumber                to public;
Create Type TQuantity                  from integer;            Grant References on Type:: TQuantity                  to public;
Create Type TDetailLine                from integer;            Grant References on Type:: TDetailLine                to public;

/* PickTickets*/
Create Type TPickTicket                from varchar(50);        Grant References on Type:: TPickTicket                to public;
Create Type TLot                       from varchar(60);        Grant References on Type:: TLot                       to public;

/* SKU */
Create Type TSKU                       from varchar(50);        Grant References on Type:: TSKU                       to public;
Create Type TUoM                       from varchar(60);        Grant References on Type:: TUoM                       to public;
Create Type TUPC                       from varchar(20);        Grant References on Type:: TUPC                       to public;
Create Type TBrand                     from varchar(50);        Grant References on Type:: TBrand                     to public;
Create Type TURL                       from varchar(250);       Grant References on Type:: TURL                       to public;
Create Type TWeight                    from float;              Grant References on Type:: TWeight                    to public;
Create Type TVolume                    from float;              Grant References on Type:: TVolume                    to public;
Create Type TPutawayClass              from varchar(50);        Grant References on Type:: TPutawayClass              to public;
Create Type TPickingClass              from varchar(50);        Grant References on Type:: TPickingClass              to public;
Create Type THarmonizedCode            from varchar(20);        Grant References on Type:: THarmonizedCode            to public;
Create Type TSizeScale                 from varchar(200);       Grant References on Type:: TSizeScale                 to public;
Create Type TSizeSpread                from varchar(200);       Grant References on Type:: TSizeSpread                to public;

/* LPN */
Create Type TLPN                       from varchar(50);        Grant References on Type:: TLPN                       to public;
Create Type TInnerPacks                from integer;            Grant References on Type:: TInnerPacks                to public;
Create Type TCoO                       from varchar(20);        Grant References on Type:: TCoO                       to public;
Create Type TInventoryStatus           from varchar(2);         Grant References on Type:: TInventoryStatus           to public;
Create Type TInventoryClass            from varchar(50);        Grant References on Type:: TInventoryClass            to public;
Create Type TASNCase                   from varchar(50);        Grant References on Type:: TASNCase                   to public;
Create Type TUniqueId                  from varchar(300);       Grant References on Type:: TUniqueId                  to public;

/* LPN Dtls */
Create Type TUnitsPerPack              from integer;            Grant References on Type:: TUnitsPerPack              to public;
Create Type TReceiptLine               from integer;            Grant References on Type:: TReceiptLine               to public;
Create Type TSerialNo                  from varchar(100);       Grant References on Type:: TSerialNo                  to public;

/* Pallets */
Create Type TPallet                    from varchar(50);        Grant References on Type:: TPallet                    to public;

/* Locations */
Create Type TLocation                  from varchar(50);        Grant References on Type:: TLocation                  to public;
Create Type TLocationType              from varchar(10);        Grant References on Type:: TLocationType              to public;
Create Type TLocationSubType           from varchar(10);        Grant References on Type:: TLocationSubType           to public;
Create Type TStorageType               from varchar(10);        Grant References on Type:: TStorageType               to public;
Create Type TLocationPath              from varchar(50);        Grant References on Type:: TLocationPath              to public;
Create Type TRow                       from varchar(10);        Grant References on Type:: TRow                       to public;
Create Type TSection                   from varchar(10);        Grant References on Type:: TSection                   to public;
Create Type TLevel                     from varchar(10);        Grant References on Type:: TLevel                     to public;
Create Type TBay                       from varchar(10);        Grant References on Type:: TBay                       to public;
Create Type TZoneId                    from varchar(60);        Grant References on Type:: TZoneId                    to public; -- deprecated
Create Type TZone                      from varchar(60);        Grant References on Type:: TZone                      to public;
Create Type TZones                     from varchar(200);       Grant References on Type:: TZones                     to public;

Go

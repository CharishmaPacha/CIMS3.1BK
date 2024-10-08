/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/12/15  TK      TOrderDetails: Added More Fields (BK-720)
  2021/07/28  RV      TOrderDetailsToConvertSetSKUs: Added (OB2-1948)
  2021/05/21  TK      TOrderDetails: Added PrepackCode & KitQuantity (HA-2664)
  2021/04/29  VS      TWaveSummary: Added UnitsRequiredtoActivate, UnitsReservedForWave, ToActivateShipCartonQty (HA-2714)
  2021/04/22  RV      TOrderDetails: Added NewInventoryClass1, NewInventoryClass2 and NewInventoryClass3 (HA-2685)
  2021/04/07  TK      TOrderDetails: Added TotalWeight, TotalVolume, LoadId, LoadNumber, ShipmentId (HA-1842)
  2021/03/30  TK      TOrderDetails: Added BulkOrderId (HA-2463)
  2021/03/13  PK      TOrderDetails: Added InventoryClass1, InventoryClass2, InventoryClass3,
                        Ownership, Warehouse to UniqueId.
  2021/03/03  AY      TOrderDetails: Added SortOrder (HA-2127)
  2021/02/21  TK      TOrderDetails: Added ProcessFlag (HA-2033)
  2021/01/11  TK      TOrderDetails: Added ResidualUnits (HA-1899)
  2020/12/11  SJ      TWaveSummary: Added NewSKU & InventoryClasses1 ,2 ,3 & NewInventoryClasses1, 2, 3 (HA-1693)
  2020/09/11  TK      TOrderDetails: Added columns required for Kitting process (HA-1238)
  2020/08/31  AY      TWaveSummary: Renamed BatchNo & added Ownership/WH (HA-1353)
  2020/06/24  SK      TWaveInfo: Added new Table type (HA-906)
  2020/06/22  TK      TOrderDetailsToAllocateTable: Added new SKU, InventoryClasses & SourceSystem (HA-834)
  2020/06/16  TK      TLocationsToReplenish: Added UniqueId (HA-938)
  2020/06/08  TK      TWaveDetailsToReplenish & TLocationsToReplenish: Added InventoryClass (HA-871)
  2020/05/13  TK      TOrderDetails: Added HostOrderLine, DestZone & InventoryClasses (HA-86)
  2020/05/01  TK      TOrderDetails: Added SalesOrder, Lot, PackingGroup, Ownership, Warehouse (HA-172)
  2020/04/26  TK      TAllocableLPNsTable, TOrderDetailsToAllocateTable & TSKUOrderDetailsToAllocate:
                        Added InventoryClass, WaveId & ProcessFlag
                      TAllocableLPNsTable: Added UnitsToAllocate & SortOrder (HA-86)
  2019/09/17  MS      Added TSCAC (CID-1029)
  2019/07/25  RV      TWaveSummary: Added Notification (CID-753)
  2019/06/20  AY      Changed ShipComplete to Percent data type (CID-582)
  2018/10/17  AY      Moved PickSequence to Domain_Tasks
  2018/07/24  VS      Expanded TShipVia to 15 chars (S2GCA-107)
  2018/07/10  TK      TCustPO size expanded to 50 characters (S2G-1013)
  2018/03/30  AY      TWaveSummary: Added
  2018/03/22  TK      TLocationsToReplenish: Added more required to generate replenish order (S2G-385)
  2018/03/20  VM/KSK  TPickBatchSummary: Added PrimaryLocation and SecondaryLocation (S2G-433)
  2018/03/10  YJ      Added several fields to TPickBatchSummary (S2G-381)
  2018/03/07  TK      Added TWaveDetailsToReplenish & TLocationsToReplenish (S2G-364)
  2017/09/29  VM      THTSCode: Added (OB-609)
  2017/08/07  TK      TAllocationRulesTable & TAllocableLPNsTable: Added ReplenishClass (HPI-1625)
  2017/02/10  TK      TSoftAllocationDetails: Added columns PrevUnitsPreAllocated, ReasonToDisQualify, OrderAllocationPercent & RuleId (HPI-1365)
  2016/11/24  VM      TOrderDetailsToAllocateTable: Included Warehouse, KeyValue (FB-826)
  2016/08/29  RA      TPickBatchSummary: Added new field BatchNo & UnitsPreAllocated (CIMS-1064)
  2016/07/27  AY      TPickBatchSummary: Added new field PickLocation
  2016/05/27  TK      TSoftAllocationDetails: Added column QualifiedStatus & fields for Logging (HPI-31)
  2016/05/03  AY      TAllocableLPNsTable: Added NumLines, NumSKUs
  2016/04/27  TK      Added TSKUOrderDetailsToAllocate (FB-648)
  2016/04/01  AY/TK   TSoftAllocationDetails: Added
  2015/11/12  AY      TOrderDetailsToAllocateTable: Added fields Ownership, Lot, Account & UDFs
  2015/10/08  AY      TAllocableLPNs: Added PickPath and UDFs
  2014/09/16  VM      TShipFrom size increased to 50
  2014/12/30  PKS     Added UDF1 to UDF5
  2014/09/11  TD      Added TToteOrderDetails.
  2014/08/23  VM      Added TPickSequence
  2014/05/22  PK      Added TSorterOrderDetails.
  2014/05/21  PV      Added TPickBatchSummary.
  2014/04/23  TD      Added TBatchedOrderDetails.
  2014/04/15  AY      Added TWaveNo and expanded TPickBatchNo
  2014/04/06  TD      Added TOrderDetailsToAllocateTable, TAllocationRulesTable,
  2013/09/17  TD      Added TPickBatchRules.
  2013/07/27  SP      Added TAccount.
  2013/02/08  PK      Added TOrderCategory
  2012/07/15  AY      Added TPickBatchGroup
  2011/09/26  AY      Expanded TShipVia to 10 chars
  2011/07/25  YA      Added TPickBatchNo under domain Batch No.
  2011/07/08  PK      Added TReturnAddrId.
  2010/09/20  PK      Initial revision.
------------------------------------------------------------------------------*/

Go

/* OrderHdrs */
Create Type TSalesOrder                from varchar(50);        Grant References on Type:: TSalesOrder                to public;
Create Type TOrderType                 from varchar(10);        Grant References on Type:: TOrderType                 to public;
Create Type TOrderLine                 from varchar(10);        Grant References on Type:: TOrderLine                 to public;
Create Type TShipToId                  from varchar(50);        Grant References on Type:: TShipToId                  to public;
Create Type TShipVia                   from varchar(15);        Grant References on Type:: TShipVia                   to public;
Create Type TSCAC                      from varchar(50);        Grant References on Type:: TSCAC                      to public;
Create Type TShipFrom                  from varchar(50);        Grant References on Type:: TShipFrom                  to public;
Create Type TCustPO                    from varchar(50);        Grant References on Type:: TCustPO                    to public;
Create Type TReturnAddress             from varchar(50);        Grant References on Type:: TReturnAddress             to public;
Create Type TOrderCategory             from varchar(50);        Grant References on Type:: TOrderCategory             to public;
Create Type TBillToAccount             from varchar(50);        Grant References on Type:: TBillToAccount             to public;
Create Type TAccount                   from varchar(60);        Grant References on Type:: TAccount                   to public;

/* OrderDtls */
--Create Type THostOrderLine             from varchar(10);        Grant References on Type:: THostOrderLine             to public;
Create Type THTSCode                   from varchar(15);        Grant References on Type:: THTSCode                   to public;
Create Type TRetailUnitPrice           from float;              Grant References on Type:: TRetailUnitPrice           to public;
Create Type TCustSKU                   from varchar(60);        Grant References on Type:: TCustSKU                   to public;

/* Batch No */
Create Type TPickBatchNo               from varchar(20);        Grant References on Type:: TPickBatchNo               to public;
Create Type TPickBatchGroup            from varchar(100);       Grant References on Type:: TPickBatchGroup            to public;

/* Wave fields */
Create Type TWaveNo                    from varchar(30);        Grant References on Type:: TWaveNo                    to public;
Create Type TWaveGroup                 from varchar(100);       Grant References on Type:: TWaveGroup                 to public;

Go

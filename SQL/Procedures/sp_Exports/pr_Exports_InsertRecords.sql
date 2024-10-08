/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2022/05/25  VS      pr_Exports_InsertRecords, pr_Exports_AddOrUpdate, pr_Exports_WarehouseTransferForMultipleLPNs:
  2021/04/04  AY      pr_Exports_InsertRecords: On Insert, order by SortOrder (HA-1842)
  2021/01/20  PK      pr_Exports_InsertRecords, pr_Exports_GetData. pr_Exports_CaptureData: Added DesiredShipDate in the dataset (HA-2029)
  2021/02/01  SK      pr_Exports_InsertRecords, pr_Exports_CIMSDE_ExportData, pr_Exports_GetData
  2020/10/20  TK      pr_Exports_InsertRecords: Populate FromLPN info (HA-1516)
  2020/05/06  TK      pr_Exports_LPNData & pr_Exports_InsertRecords: Bug fix in exporting InventoryClass (HA-422)
  2020/04/30  MS      pr_Exports_InsertRecords: Changes to Insert Data into Exports table (HA-323)
  2020/04/28  AY      pr_Exports_InsertRecords: WIP (HA-323)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Exports_InsertRecords') is not null
  drop Procedure pr_Exports_InsertRecords;
Go
/*------------------------------------------------------------------------------
  Proc pr_Exports_InsertRecords:
    Procedures assumes that the caller would insert all the records into #ExportRecords
    and call this proc.

  Assumes caller passes valid information to this, Hence no validations are required.

  #ExportRecords: Exports
------------------------------------------------------------------------------*/
Create Procedure pr_Exports_InsertRecords
  (@TransType          TTypeCode,
   @TransEntity        TEntity,
   @BusinessUnit       TBusinessUnit,

   @Ownership          TOwnership        = null,
   @Warehouse          TWarehouse        = null,
   @SourceSystem       TName             = null
  )

as
  declare @vReturnCode       TInteger,
          @vMessageName      TMessageName,
          @vMessage          TDescription,

          @xmlRulesData      TXML;

begin /* pr_Exports_InsertRecords */
  SET NOCOUNT ON;

  select @vReturnCode    = 0,
         @vMessageName   = null;

  select @xmlRulesData = dbo.fn_XMLNode('RootNode',
                           dbo.fn_XMLNode('TransEntity',     @TransEntity ) +
                           dbo.fn_XMLNode('TransType',       @TransType   ) +
                           dbo.fn_XMLNode('SourceSystem',    @SourceSystem) +
                           dbo.fn_XMLNode('Ownership',       @Ownership   ) +
                           dbo.fn_XMLNode('Warehouse',       @Warehouse   ) +
                           dbo.fn_XMLNode('BusinessUnit',    @BusinessUnit));

  /* Evaluate the rules to determine whether to send exports to host or not,
     what ship via it should be etc. */
  exec pr_RuleSets_ExecuteAllRules 'Export_PreInsertProcess', @xmlRulesData, @BusinessUnit;

  /* Insert the records into the table
     Columns Excluded here: TransDateTime, TransDate, Archived, CreatedDate, ModifiedDate */
  insert into Exports(TransType, TransEntity, TransQty, Status, SKUId,
                      LPNId, LPNDetailId, LocationId, PalletId, HostLocation, ReceiverId, ReceiverNumber,
                      ReceiptId, ReceiptDetailId, HostReceiptLine, ReasonCode, Warehouse, Ownership, SourceSystem,
                      Weight, Volume, Length, Width, Height,
                      Lot, InventoryClass1, InventoryClass2, InventoryClass3,
                      NumPallets, NumLPNs, NumCartons, InnerPacks, Quantity,
                      OrderId, OrderDetailId, ShipmentId, LoadId, DesiredShipDate, ShipVia, ShipViaDesc, Carrier, SCAC, HostShipVia,
                      FreightCharges, FreightTerms, ListNetCharge, AccountNetCharge, InsuranceFee, TrackingNo,
                      TrackingBarcode, Reference, HostOrderLine,
                      ShipToId, ShipToName, ShipToAddressLine1, ShipToAddressLine2, ShipToCity, ShipToState, ShipToCountry,
                      ShipToZip, ShipToPhoneNo, ShipToEmail, ShipToReference1, ShipToReference2, SoldToId, SoldToName,
                      UDF1, UDF2, UDF3, UDF4, UDF5, UDF6, UDF7, UDF8, UDF9, UDF10, UDF11, UDF12, UDF13, UDF14, UDF15,
                      UDF16, UDF17, UDF18, UDF19, UDF20, UDF21, UDF22, UDF23, UDF24, UDF25, UDF26, UDF27, UDF28, UDF29, UDF30,
                      BusinessUnit, CreatedBy, ModifiedBy, PrevSKUId, FromWarehouse,
                      ToWarehouse, FromLPNId, FromLPN, FromLocationId, FromLocation, ToLocationId, ToLocation, MonetaryValue)

    select TransType, coalesce(@TransEntity, TransEntity), TransQty, coalesce(Status, 'N'), SKUId,
           LPNId, LPNDetailId, LocationId, PalletId, HostLocation, ReceiverId, ReceiverNumber,
           ReceiptId, ReceiptDetailId, HostReceiptLine, ReasonCode, Warehouse, Ownership, SourceSystem,
           Weight, Volume, Length, Width, Height,
           coalesce(Lot,''), InventoryClass1, InventoryClass2, InventoryClass3,
           NumPallets, NumLPNs, NumCartons, InnerPacks, Quantity,
           OrderId, OrderDetailId, ShipmentId, LoadId, DesiredShipDate, ShipVia, ShipViaDesc, Carrier, SCAC, HostShipVia,
           FreightCharges, FreightTerms, ListNetCharge, AccountNetCharge, InsuranceFee, TrackingNo,
           TrackingBarcode, Reference, HostOrderLine,
           ShipToId, ShipToName, ShipToAddressLine1, ShipToAddressLine2, ShipToCity, ShipToState, ShipToCountry,
           ShipToZip, ShipToPhoneNo, ShipToEmail, ShipToReference1, ShipToReference2, SoldToId, SoldToName,
           UDF1, UDF2, UDF3, UDF4, UDF5, UDF6, UDF7, UDF8, UDF9, UDF10, UDF11, UDF12, UDF13, UDF14, UDF15,
           UDF16, UDF17, UDF18, UDF19, UDF20, UDF21, UDF22, UDF23, UDF24, UDF25, UDF26, UDF27, UDF28, UDF29, UDF30,
           coalesce(@BusinessUnit, BusinessUnit), CreatedBy, ModifiedBy, PrevSKUId, FromWarehouse,
           ToWarehouse, FromLPNId, FromLPN, FromLocationId, FromLocation, ToLocationId, ToLocation, MonetaryValue
    from #ExportRecords
    order by SortOrder;

ErrorHandler:
   exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Exports_InsertRecords */

Go

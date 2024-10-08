/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/09/23  VS      pr_Imports_OrderDetails, pr_Imports_OrderDetails_LoadData, pr_Imports_OrderHeaders
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Imports_OrderDetails_LoadData') is not null
  drop Procedure pr_Imports_OrderDetails_LoadData;
Go
/*------------------------------------------------------------------------------
  Proc pr_Imports_OrderDetails_LoadData: Loads the data from ##ImportOrderDetails
   or @xmlData or @documentHandle into #ImportOrderDetails for final processing

  Usage: Create #ImportOrderDetails and call this proc with @xmlData, @documentHandle
         or fill in ##ImportOrderDetails and invoke this proc

  #OrderDetailsImport: TOrderDetailsImportType
------------------------------------------------------------------------------*/
Create Procedure pr_Imports_OrderDetails_LoadData
  (@xmlData                 Xml                = null,
   @documentHandle          TInteger           = null,
   @InterfaceLogId          TRecordId          = null,
   @Action                  TFlag              = null,
   @PickTicket              TPickTicket        = null,
   @HostOrderLine           THostOrderLine     = null,
   @LineType                TTypeCode          = null,
   @SKU                     TSKU               = null,
   @UnitsOrdered            TQuantity          = null,
   @UnitsAuthorizedToShip   TQuantity          = null,
   @UnitsShipped            TQuantity          = null,
   @UnitsPerCarton          TQuantity          = null,
   @RetailUnitPrice         TRetailUnitPrice   = null,
   @UnitSalePrice           TPrice             = null,
   @UnitTaxAmount           TMonetaryValue     = null,
   @Lot                     TLot               = null,
   @InventoryClass1         TInventoryClass    = null,
   @InventoryClass2         TInventoryClass    = null,
   @InventoryClass3         TInventoryClass    = null,
   @CustSKU                 TCustSKU           = null,
   @PackingGroup            TCategory          = null,
   @LocationId              TRecordId          = null,
   @UDF1                    TUDF               = null,
   @UDF2                    TUDF               = null,
   @UDF3                    TUDF               = null,
   @UDF4                    TUDF               = null,
   @UDF5                    TUDF               = null,
   @UDF6                    TUDF               = null,
   @UDF7                    TUDF               = null,
   @UDF8                    TUDF               = null,
   @UDF9                    TUDF               = null,
   @UDF10                   TUDF               = null,
   @UDF11                   TUDF               = null,
   @UDF12                   TUDF               = null,
   @UDF13                   TUDF               = null,
   @UDF14                   TUDF               = null,
   @UDF15                   TUDF               = null,
   @UDF16                   TUDF               = null,
   @UDF17                   TUDF               = null,
   @UDF18                   TUDF               = null,
   @UDF19                   TUDF               = null,
   @UDF20                   TUDF               = null,
   @UDF21                   TUDF               = null,
   @UDF22                   TUDF               = null,
   @UDF23                   TUDF               = null,
   @UDF24                   TUDF               = null,
   @UDF25                   TUDF               = null,
   @UDF26                   TUDF               = null,
   @UDF27                   TUDF               = null,
   @UDF28                   TUDF               = null,
   @UDF29                   TUDF               = null,
   @UDF30                   TUDF               = null,
   @BusinessUnit            TBusinessUnit      = null,
   @CreatedDate             TDateTime          = null,
   @ModifiedDate            TDateTime          = null,
   @CreatedBy               TUserId            = null,
   @ModifiedBy              TUserId            = null,
   @HostRecId               TRecordId          = null,
   @IsDESameServer          TFlag              = null,
   @RecordId                TRecordId          = null)
as
begin /* pr_Imports_OrderDetails_LoadData */

  if (@IsDESameServer = 'Y') and (@RecordId is not null)
    insert into #OrderDetailsImport (
      RecordAction, RecordType, PickTicket, HostOrderLine,
      LineType, SKU,
      UnitsOrdered, UnitsAuthorizedToShip, OrigUnitsAuthorizedToShip, UnitsAssigned,
      UnitsPerCarton,
      RetailUnitPrice, UnitSalePrice, UnitTaxAmount,
      Lot, InventoryClass1, InventoryClass2, InventoryClass3, CustSKU, PackingGroup, LocationId,
      OD_UDF1, OD_UDF2, OD_UDF3, OD_UDF4, OD_UDF5, OD_UDF6, OD_UDF7, OD_UDF8, OD_UDF9, OD_UDF10,
      OD_UDF11, OD_UDF12, OD_UDF13, OD_UDF14, OD_UDF15, OD_UDF16, OD_UDF17, OD_UDF18, OD_UDF19, OD_UDF20,
      OD_UDF21, OD_UDF22, OD_UDF23, OD_UDF24, OD_UDF25, OD_UDF26, OD_UDF27, OD_UDF28, OD_UDF29, OD_UDF30,
      BusinessUnit, CreatedDate, ModifiedDate, CreatedBy, ModifiedBy, HostRecId)
    select RecordAction, RecordType, PickTicket, HostOrderLine,
      LineType, SKU,
      UnitsOrdered, UnitsAuthorizedToShip, OrigUnitsAuthorizedToShip, UnitsAssigned,
      UnitsPerCarton,
      RetailUnitPrice, UnitSalePrice, UnitTaxAmount,
      Lot, InventoryClass1, InventoryClass2, InventoryClass3, CustSKU, PackingGroup, LocationId,
      OD_UDF1, OD_UDF2, OD_UDF3, OD_UDF4, OD_UDF5, OD_UDF6, OD_UDF7, OD_UDF8, OD_UDF9, OD_UDF10,
      OD_UDF11, OD_UDF12, OD_UDF13, OD_UDF14, OD_UDF15, OD_UDF16, OD_UDF17, OD_UDF18, OD_UDF19, OD_UDF20,
      OD_UDF21, OD_UDF22, OD_UDF23, OD_UDF24, OD_UDF25, OD_UDF26, OD_UDF27, OD_UDF28, OD_UDF29, OD_UDF30,
      BusinessUnit, CreatedDate, ModifiedDate, CreatedBy, ModifiedBy, RecordId
      from ##ImportOrderDetails
      where RecordId = @RecordId
  else
  if (@IsDESameServer = 'Y')
    insert into #OrderDetailsImport (
      RecordAction, RecordType, PickTicket, HostOrderLine,
      LineType, SKU,
      UnitsOrdered, UnitsAuthorizedToShip, OrigUnitsAuthorizedToShip, UnitsAssigned,
      UnitsPerCarton,
      RetailUnitPrice, UnitSalePrice, UnitTaxAmount,
      Lot, InventoryClass1, InventoryClass2, InventoryClass3, CustSKU, PackingGroup, LocationId,
      OD_UDF1, OD_UDF2, OD_UDF3, OD_UDF4, OD_UDF5, OD_UDF6, OD_UDF7, OD_UDF8, OD_UDF9, OD_UDF10,
      OD_UDF11, OD_UDF12, OD_UDF13, OD_UDF14, OD_UDF15, OD_UDF16, OD_UDF17, OD_UDF18, OD_UDF19, OD_UDF20,
      OD_UDF21, OD_UDF22, OD_UDF23, OD_UDF24, OD_UDF25, OD_UDF26, OD_UDF27, OD_UDF28, OD_UDF29, OD_UDF30,
      BusinessUnit, CreatedDate, ModifiedDate, CreatedBy, ModifiedBy, HostRecId)
    select RecordAction, RecordType, PickTicket, HostOrderLine,
      LineType, SKU,
      UnitsOrdered, UnitsAuthorizedToShip, OrigUnitsAuthorizedToShip, UnitsAssigned,
      UnitsPerCarton,
      RetailUnitPrice, UnitSalePrice, UnitTaxAmount,
      Lot, InventoryClass1, InventoryClass2, InventoryClass3, CustSKU, PackingGroup, LocationId,
      OD_UDF1, OD_UDF2, OD_UDF3, OD_UDF4, OD_UDF5, OD_UDF6, OD_UDF7, OD_UDF8, OD_UDF9, OD_UDF10,
      OD_UDF11, OD_UDF12, OD_UDF13, OD_UDF14, OD_UDF15, OD_UDF16, OD_UDF17, OD_UDF18, OD_UDF19, OD_UDF20,
      OD_UDF21, OD_UDF22, OD_UDF23, OD_UDF24, OD_UDF25, OD_UDF26, OD_UDF27, OD_UDF28, OD_UDF29, OD_UDF30,
      BusinessUnit, CreatedDate, ModifiedDate, CreatedBy, ModifiedBy, RecordId
      from ##ImportOrderDetails
  else
  /* Dump from XML or input params into temp table variable for processing */
  if (@documentHandle is not null)
    begin
      insert into #OrderDetailsImport (
        InputXML,
        RecordType,
        RecordAction,
        PickTicket,
        SKU,
        HostOrderLine,
        ParentHostLineNo,
        LineType,
        UnitsOrdered,
        UnitsAuthorizedToShip,
        UnitsPerCarton,
        UnitsPerInnerPack,
        RetailUnitPrice,
        UnitSalePrice,
        UnitTaxAmount,
        Lot,
        InventoryClass1,
        InventoryClass2,
        InventoryClass3,
        CustSKU,
        PackingGroup,
        OD_UDF1,
        OD_UDF2,
        OD_UDF3,
        OD_UDF4,
        OD_UDF5,
        OD_UDF6,
        OD_UDF7,
        OD_UDF8,
        OD_UDF9,
        OD_UDF10,
        OD_UDF11,
        OD_UDF12,
        OD_UDF13,
        OD_UDF14,
        OD_UDF15,
        OD_UDF16,
        OD_UDF17,
        OD_UDF18,
        OD_UDF19,
        OD_UDF20,
        OD_UDF21,
        OD_UDF22,
        OD_UDF23,
        OD_UDF24,
        OD_UDF25,
        OD_UDF26,
        OD_UDF27,
        OD_UDF28,
        OD_UDF29,
        OD_UDF30,
        BusinessUnit,
        CreatedDate,
        ModifiedDate,
        CreatedBy,
        ModifiedBy,
        HostRecId,
        OrigUnitsAuthorizedToShip,
        UnitsAssigned
        )
      select
        *,
        UnitsAuthorizedToShip, /* Original Units Authorized To Ship */
        0/* As it cant be null we are assigning the default value */
      from OPENXML(@documentHandle, '//msg/msgBody/Record[RecordType/text()="OD"]', 2)
      with
      (
        InputXML              nvarchar(max)   '@mp:xmltext',
        RecordType            TRecordType,
        RecordAction          TAction       'Action',
        PickTicket            TPickTicket,
        SKU                   TSKU,
        HostOrderLine         THostOrderLine,
        ParentHostLineNo      THostOrderLine,
        LineType              TTypeCode,
        UnitsOrdered          TQuantity,
        UnitsAuthorizedToShip TQuantity,
        UnitsPerCarton        TQuantity,
        UnitsPerInnerpack     TQuantity,
        RetailUnitPrice       TRetailUnitPrice,
        UnitSalePrice         TUnitPrice,
        UnitTaxAmount         TMonetaryValue,
        Lot                   TLot,
        InventoryClass1       TInventoryClass,
        InventoryClass2       TInventoryClass,
        InventoryClass3       TInventoryClass,
        CustSKU               TCustSKU,
        PackingGroup          TCategory,
        OD_UDF1               TUDF,
        OD_UDF2               TUDF,
        OD_UDF3               TUDF,
        OD_UDF4               TUDF,
        OD_UDF5               TUDF,
        OD_UDF6               TUDF,
        OD_UDF7               TUDF,
        OD_UDF8               TUDF,
        OD_UDF9               TUDF,
        OD_UDF10              TUDF,
        OD_UDF11              TUDF,
        OD_UDF12              TUDF,
        OD_UDF13              TUDF,
        OD_UDF14              TUDF,
        OD_UDF15              TUDF,
        OD_UDF16              TUDF,
        OD_UDF17              TUDF,
        OD_UDF18              TUDF,
        OD_UDF19              TUDF,
        OD_UDF20              TUDF,
        OD_UDF21              TUDF,
        OD_UDF22              TUDF,
        OD_UDF23              TUDF,
        OD_UDF24              TUDF,
        OD_UDF25              TUDF,
        OD_UDF26              TUDF,
        OD_UDF27              TUDF,
        OD_UDF28              TUDF,
        OD_UDF29              TUDF,
        OD_UDF30              TUDF,
        BusinessUnit          TBusinessUnit,
        CreatedDate           TDateTime  'CreatedDate/text()', -- returns null when CreatedDate is blank node. Acts a NullIf Blank
        ModifiedDate          TDateTime  'ModifiedDate/text()', -- returns null when CreatedDate is blank node. Acts a NullIf Blank
        CreatedBy             TUserId,
        ModifiedBy            TUserId,
        RecordId              TRecordId
       );
    end
  else
  if (not exists (select * from #OrderDetailsImport))
    begin
      insert into #OrderDetailsImport (
        RecordAction, RecordType, PickTicket, HostOrderLine,
        LineType, SKU,
        UnitsOrdered, UnitsAuthorizedToShip, OrigUnitsAuthorizedToShip, UnitsAssigned,
        UnitsPerCarton,
        RetailUnitPrice, UnitSalePrice, UnitTaxAmount,
        Lot, InventoryClass1, InventoryClass2, InventoryClass3, CustSKU, PackingGroup, LocationId,
        OD_UDF1, OD_UDF2, OD_UDF3, OD_UDF4, OD_UDF5, OD_UDF6, OD_UDF7, OD_UDF8, OD_UDF9, OD_UDF10,
        OD_UDF11, OD_UDF12, OD_UDF13, OD_UDF14, OD_UDF15, OD_UDF16, OD_UDF17, OD_UDF18, OD_UDF19, OD_UDF20,
        OD_UDF21, OD_UDF22, OD_UDF23, OD_UDF24, OD_UDF25, OD_UDF26, OD_UDF27, OD_UDF28, OD_UDF29, OD_UDF30,
        BusinessUnit, CreatedDate, ModifiedDate, CreatedBy, ModifiedBy, HostRecId)
      select
        @Action, 'OD', @PickTicket, @HostOrderLine,
        @LineType, @SKU,
        @UnitsOrdered, @UnitsAuthorizedToShip, @UnitsAuthorizedToShip, 0,/* As it cant be null we are assigning the default value */
        @UnitsPerCarton,
        @RetailUnitPrice, coalesce(@UnitSalePrice, 0.0), coalesce(@UnitTaxAmount, 0.0),
        @Lot, @InventoryClass1, @InventoryClass2, @InventoryClass3, @CustSKU, @PackingGroup, @LocationId,
        @UDF1, @UDF2, @UDF3, @UDF4, @UDF5, @UDF6, @UDF7, @UDF8, @UDF9, @UDF10,
        @UDF11, @UDF12, @UDF13, @UDF14, @UDF15, @UDF16, @UDF17, @UDF18, @UDF19, @UDF20,
        @UDF21, @UDF22, @UDF23, @UDF24, @UDF25, @UDF26, @UDF27, @UDF28, @UDF29, @UDF30,
        @BusinessUnit, @CreatedDate, @ModifiedDate, @CreatedBy, @ModifiedBy, @HostRecId;
    end

end /* pr_Imports_OrderDetails_LoadData */

Go

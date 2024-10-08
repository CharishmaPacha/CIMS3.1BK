/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  TShippedLoadsExportType (CIMSDE-34)
  Create Type TShippedLoadsExportType as Table (
  Grant References on Type:: TShippedLoadsExportType   to public;
------------------------------------------------------------------------------*/

Go

/*----------------------------------------------------------------------------*/
/* Type used in SKU Import
   This table structure mimics the record structure of ShippedLoad Export, with few additional fields
   to capture key fields, etc.,. */

Create Type TShippedLoadsExportType as Table (
     RecordId                TRecordId      identity (1,1),
     RecordAction            TAction,
     LoadNumber              TLoadNumber,
     PickTicket              TPickTicket,
     SalesOrder              TSalesOrder,
     SoldToId                TContactRefId,
     ShipToId                TContactRefId,

     SKU                     TSKU,
     SKU1                    TSKU,
     SKU2                    TSKU,
     SKU3                    TSKU,
     SKU4                    TSKU,
     SKU5                    TSKU,

     LPNId                   TRecordId,
     LPN                     TLPN,
     LPNDetailId             TRecordId,

     Pallet                  TPallet,

     Lot                     TLot,
     UnitsShipped            TQuantity,

     UDF1                    TUDF,
     UDF2                    TUDF,
     UDF3                    TUDF,
     UDF4                    TUDF,
     UDF5                    TUDF,
     UDF6                    TUDF,
     UDF7                    TUDF,
     UDF8                    TUDF,
     UDF9                    TUDF,
     UDF10                   TUDF,

     BusinessUnit            TBusinessUnit,
     Ownership               TOwnership,
     CreatedDate             TDateTime      DEFAULT current_timestamp,
     ModifiedDate            TDateTime,
     CreatedBy               TUserId,
     ModifiedBy              TUserId,

     Primary Key             (RecordId),
     Unique                  (RecordAction, SKU, RecordId)
);

Grant References on Type:: TShippedLoadsExportType   to public;

Go

/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2019/01/07  VS      PandALabels: Added New Column CreatedOn to Purge the Data quickly (HPI-2284)
------------------------------------------------------------------------------*/

Go

/*------------------------------------------------------------------------------
  Table: PandALabels - Log for records need to be integrate with PandA System.

  Fields: InBarcode   - Is the key barcode information that PandA would read and
                        apply the label. This is typically the LPN.
          LabelVerify - Is the prirmary barcode on the label that is to be printed.
                        This barcode will be used to verify by PandA that the label
                        has printed as expected.
------------------------------------------------------------------------------*/
Create Table PandALabels (
    RecordId                 TRecordId      identity (1,1) not null,

    LPNId                    TRecordId,
    LPN                      TLPN,
    PalletId                 TRecordId,
    Pallet                   TPallet,
    SKUId                    TRecordId,
    SKU                      TSKU,
    OrderId                  TRecordId,
    PickTicket               TPickTicket,
    WaveId                   TRecordId,
    WaveNo                   TWaveNo,

    InBarcode                TBarcode       not null,
    LabelVerify              TBarcode       not null,
    LabelData                TVarChar,
    ProcessMode              TTypeCode,

    LabelType                TTypeCode      not null,
    LabelFormatName          TName          not null,
    DeviceId                 TDeviceId,     /* Device Id where request generated  */
    StationName              TName,

    ExportStatus             TStatus        default 'N' /* New */,

    LabeledDateTime          TDateTime,
    ExportDateTime           TDateTime,

    InductionStatus          TStatus,
    InductedDate             TDateTime,

    ConfirmationStatus       TStatus,
    ConfirmedDate            TDateTime,

    PandAStation             TName,
    ErrorMessage             TVarChar,

    Archived                 TFlag          default 'N',
    BusinessUnit             TBusinessUnit  not null,
    CreatedDate              TDateTime      default current_timestamp,
    CreatedOn                As convert(date, ConfirmedDate),
    ModifiedDate             TDateTime,
    CreatedBy                TUserId,
    ModifiedBy               TUserId,

    constraint pkPandALabels_RecordId PRIMARY KEY (RecordId)
);

create index ix_PandaLabels_LPN                  on PandALabels (LPN);
create index ix_PandaLabels_InBarcode            on PandALabels (InBarcode);
create index ix_PandaLabels_AExportStatus        on PandALabels (ExportStatus) Include (RecordId, BusinessUnit, LabelFormatName, LPN) where (Archived = 'N');
create index ix_PandaLabels_ConfirmStatus        on PandALabels (ConfirmationStatus) where (Archived = 'N');
create index ix_PandaLabels_InductionStatus      on PandALabels (InductionStatus)    where (Archived = 'N');
create index ix_PandaLabels_CreatedOn            on PandALabels (CreatedOn);

Go

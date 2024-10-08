/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/07/24  RV      ShipLabels: Added TaskId and Priority (S2GCA-1199)
  2019/06/18  TD/VS   ShipLabels: Added Businessunit and carrier to ix_ShipLabel_TrkNo index (S2GCA-1148)
  2020/02/24  YJ      ShipLabels: Added PickTicket (CID-1335)
  2019/05/05  PK      ShipLabels: Added new field Barcode
  2019/02/15  RV      ShipLabels: Made changes to consider Status for computing column IsValidTrackingNo (S2G-1198)
  2019/01/16  RV      ShipLabels: Added new fields CarrierInterface, ManifestExportStatus, ManifestExportTimeStamp and ManifestExportBatch (S2GCA-434)
  2019/01/07  VS      ShipLabels: Added New Column CreatedOn to Purge the Data quickly (HPI-2284)
  2018/09/25  RV      ShipLabels: Added TotalPackages (S2G-1110)
  2018/11/14  AY      ShipLabels: New field IsValidTrackingNo and indices for performance improvement (S2G-Support)
  2018/09/25  RV      ShipLabels: Added TotalPackages (S2G-1110)
  2018/07/11  RV      ShipLabels: ProcessedDateTime (S2G-1021)
  ShipLabels: Added EntityId, ExportStatus
  2018/02/20  RV      ShipLabels: Added WaveId, WaveNo, ExportBatch, ExportInstance (S2G-235)
  2018/02/08  RV      ShipLabels: Added ProcessStatus, ProcessedInstance, ProcessBatch, Carrier (S2G-110)
  2017/04/14  NB      ShipLabels: Added ZPLLabel(CIMS-1259)
  2017/04/13  NB      ShipLabels: Added RequestedShipVia, Changed ShipVia type to TDescription(CIMS-1259)
  2016/06/27  NY      ShipLabels: Added AcctNetCharge and changed existing NetCharge to ListNetCharge (OB-427)
  2015/05/19  RV      ShipLabels: NotificationSource and NotificationTrace
  2013/08/08  SV      ShipLabels: Added OrderId field.
  2013/04/17  VM      ShipLabels: Added Reference.
  2013/04/16  VM      ShipLabels: Added NetCharge.
------------------------------------------------------------------------------*/

Go

/*------------------------------------------------------------------------------
  Table: ShipLabels

    EntityType - Type of Inventory (Ex: Pallet, LPN etc.)
    EntityKey  - Key Value of the Entity (Pallet or LPN etc.)
                 As on now, TPallet and TLPN are both 50 length, in case there are any
                 changes, this shall have to change to use the longer of the two domains
    LabelType  - Type of Label (Ex: Shipping, SmallPackage, Contents etc.)
    Notifications - Save the Messages/Warnings from the Carrier Interface Call
------------------------------------------------------------------------------*/
Create Table ShipLabels (
    RecordId                 TRecordId      identity (1,1) not null,

    EntityType               TEntity        not null default 'L', /* LPNs */
    EntityId                 TRecordId,
    EntityKey                TPallet        not null,

    CartonType               TCartonType,
    PackageLength            TLength,
    PackageWidth             TWidth,
    PackageHeight            THeight,
    PackageVolume            TVolume,
    PackageWeight            TWeight,

    OrderId                  TRecordId,
    PickTicket               TPickTicket,
    TotalPackages            TCount         null,

    TaskId                   TRecordId,
    WaveId                   TRecordId,
    WaveNo                   TPickBatchNo,

    LabelType                TTypeCode      not null default 'S', /* Shipping */
    TrackingNo               TTrackingNo    not null,
    TrackingBarcode          TTrackingNo,                         /* Used to store other tracking number like USPSTracking no coming from UPS etc */
    Barcode                  TBarcode,
    Label                    TShippingLabel,
    ZPLLabel                 TVarchar,
    RequestedShipVia         TShipvia,                            /* ShipVia from Order Header - could be a generic code Ex: BESTUPS */
    ShipVia                  TDescription,                        /* ShipVia - Actual ShipVia which is used to deliver the shipment */
    Carrier                  TCarrier,
    CarrierInterface         TCarrierInterface,
    ServiceSymbol            TCarrier,                            /* This field is specific to ADSI and used to determine Carrier during Voiding the label */
    MSN                      TCarrier,                            /* This field is specific to ADSI and used to determine MSN during Voiding the label */
    FreightTerms             TLookUpCode,
    BillToAccount            TAccount,
    ListNetCharge            TMoney,
    AcctNetCharge            TMoney,
    InsuranceFee             TMoney,
    Status                   TStatus        not null default 'A', -- don't understand this either

    ProcessStatus            TStatus        not null default 'N', /* N: Not yet processed from Label Generator,
                                                                     NR: Not Required,
                                                                     GI: Label Generate In Progress,
                                                                     PA: Pending API - processed by API outbound transaction processor
                                                                     LG: Label Generated,
                                                                     XR: Shipping Docs Export Required,
                                                                     XI: Shipping Docs Export In Progress,
                                                                     XC: Shipping Docs Export Completed,
                                                                     LGE: Error in Label Generation,
                                                                     XE: Error in Shipping Docs Export,
                                                                     IR: Invalid Request */
    ProcessedInstance        varchar(50),    /* Some times we running multiple instance to generate shiping labels, So we are saving which instance processed this label*/
    ProcessBatch             TBatch         not null default 0,
    ProcessedDateTime        TDateTime,

    ExportStatus             TStatus        default 'NR',        /* Export Not required */
    ExportInstance           varchar(50),    /* Some times we running multiple instance to export shiping labels, So we are saving which instance processed this label*/
    ExportBatch              TBatch         not null default 0,
    Priority                 TPriority      not null default 5,

    ManifestExportStatus     TStatus        default 'N',
    ManifestExportTimeStamp  TDateTime,
    ManifestExportBatch      TBatch         not null default 0,

    AlertSent                TFlags         default 'NR', /* Y - Yes, NR - Not required, T - To be sent */

    Reference                TVarchar,       /* to store any additional information retrieved from shipper */
    Notifications            TVarChar,
    NotificationSource       TVarChar,
    NotificationTrace        TVarChar,

    IsValidTrackingNo        As case when (Status = 'A' /* Active */) and
                                          (coalesce(TrackingNo, '') <> '') and
                                          ((Label is not null) or (ZPLLabel is not null))
                                 then 'Y'
                                 else 'N'
                                 end,

    Archived                 TFlag          default 'N',
    BusinessUnit             TBusinessUnit  not null,
    CreatedDate              TDateTime      default getdate(),
    ModifiedDate             TDateTime,
    CreatedBy                TUserId,
    ModifiedBy               TUserId,

    CreatedOn                as convert(date, CreatedDate),

    constraint pkShipLabels_RecordId    primary key (RecordId),
    constraint ukShipLabels_TrackingNo  unique (TrackingNo, EntityKey, LabelType, BusinessUnit)
);

/* used in pr_Allocation_InsertShipLabels and in ShipLabel_GetLPNData */
create index ix_ShipLabel_EntityId               on Shiplabels (EntityId, Status, LabelType) Include(WaveId);
create index ix_ShipLabel_EntityKey              on Shiplabels (EntityKey, BusinessUnit) Include(EntityType, LabelType, Status, TrackingNo);
create index ix_ShipLabel_EntityTypeKey          on Shiplabels (EntityType, EntityKey, LabelType);
create index ix_ShipLabel_OrderId                on Shiplabels (OrderId, IsValidTrackingNo, Status, Archived) include (AcctNetCharge, LabelType, ListNetCharge, ProcessStatus, TotalPackages, EntityKey, BusinessUnit);
/* Both WaveId & TaskId indices helpful for evaluating dependencies */
create index ix_ShipLabel_WaveId                 on Shiplabels (WaveId, IsValidTrackingNo, Status, Archived) Include(ProcessStatus);
create index ix_ShipLabel_TaskId                 on Shiplabels (TaskId, IsValidTrackingNo, Status, Archived);
/* Allocation, Label Generation etc. use below index */
create index ix_ShipLabel_Status                 on ShipLabels (Status, ProcessStatus, ProcessBatch, BusinessUnit) include (WaveId, OrderId, ProcessedInstance, Carrier, CarrierInterface);
create index ix_ShipLabel_ProcessStatus          on ShipLabels (ProcessStatus, BusinessUnit) include (ModifiedDate);
create index ix_ShipLabel_ProcessBatch           on ShipLabels (ProcessBatch, BusinessUnit) include (OrderId, ProcessedInstance, Status, ProcessStatus, TaskId, RecordId);
/* Label export uses below index */
create index ix_ShipLabel_ExportBatch            on ShipLabels (ExportBatch, ProcessStatus, BusinessUnit);
/* Manifest Close */
create index ix_ShipLabel_ManifestClose          on ShipLabels (ManifestExportStatus, Status, BusinessUnit) Include(EntityId, EntityKey, TrackingNo);
/* Used in Returns */
create index ix_ShipLabel_TrkNo                  on ShipLabels (TrackingNo, LabelType) include (Carrier, BusinessUnit);
/* Used for Purging & pr_Archive_ShipLabels */
create index ix_ShipLabel_Archived               on ShipLabels (Archived, CreatedOn) include (EntityKey, RecordId);
/* Used in GetScannedLPN */
create index ix_ShipLabel_Barcode                on ShipLabels (Barcode) include (EntityKey, RecordId, BusinessUnit);

Go

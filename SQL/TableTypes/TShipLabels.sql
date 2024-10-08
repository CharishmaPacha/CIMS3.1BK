/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2023/03/20  VS      TShipLabels: Added FreightTerms, BillToAccount (JLFL-297)
  2023/01/13  RV      TShipLabels: Added Notifications (OBV3-1613)
  2022/11/05  RV      TShipLabels: Added MessageType (OBV3-1361)
  2021/11/26  RV      TShipLabels: InsertRequired changed TFlag to TFlags (CIMSV3-1746)
  2021/07/02  AY      TShipLabels: Added LabelsRequired & ShipmentType (CIMSV3-1525)
  2021/06/13  TK      TShipLabels: Added APIWorkFlow (BK-349)
  Create Type TShipLabels as table (
  grant references on Type:: TShipLabels to public;
------------------------------------------------------------------------------*/

Go

/*----------------------------------------------------------------------------*/
/*
   Integration Method : API/CIMSSI
   Generation Method  : API: JOB, CLR
                        CIMSSI: Interactive, LabelGenerator
   Carrier Interface  : API: CIMSUPS, CIMSFedEx, CIMSUSPSEndicia,
                        CIMSSI: DIRECT, ADSI
*/
Create Type TShipLabels as table (
    RecordId                TRecordId identity (1,1),

    EntityId                TRecordId,
    EntityType              TTypeCode,
    EntityKey               TEntityKey,

    CartonType              TCartonType,
    SKUId                   TRecordId,

    PackageLength           TLength,
    PackageWidth            TWidth,
    PackageHeight           THeight,
    PackageWeight           TWeight,
    PackageVolume           TVolume,

    OrderId                 TRecordId,
    PickTicket              TPickTicket,
    TotalPackages           TCount,
    TaskId                  TRecordId,
    WaveId                  TRecordId,
    WaveNo                  TPickBatchNo,
    WaveType                TTypeCode,
    FreightTerms            TLookUpCode,
    BillToAccount           TAccount,

    LabelType               TTypeCode,
    RequestedShipVia        TShipVia,
    ShipVia                 TShipVia,
    Carrier                 TCarrier,
    IsSmallPackageCarrier   TFlag,

    IntegrationMethod       TName,
    MessageType             TName,
    GenerationMethod        TName,
    CarrierInterface        TCarrierInterface,
    APIWorkFlow             TName, -- deprecated
    LabelsRequired          TFlags, /* S - Shipping label, RL-Return label */
    ShipmentType            TFlags, /* M - Multi-Package shipment, S - Single package shipment */

    Status                  TStatus,
    Priority                TPriority,
    InsertRequired          TFlags,

    ProcessedInstance       TName,
    ProcessBatch            TInteger,
    ProcessStatus           TStatus,

    APITransactionStatus    TStatus,
    Notifications           TVarChar,

    BusinessUnit            TBusinessUnit,
    CreatedBy               TUserId,

    unique                  (InsertRequired, RecordId),
    unique                  (Carrier, InsertRequired, RecordId),
    primary key             (RecordId)
);

grant references on Type:: TShipLabels to public;

Go

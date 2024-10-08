/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/07/24  AY      ReceiptHeaders: Added VendorName (HA-3019)
  2020/11/05  MS      ReceiptHeaders,ReceiptDetails: Added newfields of sorting (JL-294)
  2020/08/05  SJ      ReceiptHeaders: Added AppointmentDateTime (HA-1228)
  2020/06/31  RKC     Receivers & ReceiptHeaders: Add ModifiedOn computed column and index (CIMS-3118)
  2019/09/06  SK      ReceiptHeaders: Modified index based on suggestions from performance dashboard (FB-1303)
  2019/06/07  RT      ReceiptHeaders: Included PrepareRecvFlag (CID-510)
  2019/01/08  TD      ReceiptHeaders: Added HostNumLines
  2018/03/17  AY      ReceiptHeaders: Added SourceSystem (FB-1114)
  2016/03/19  AY      ReceiptHeaders: Added UDF6-10
  2015/09/14  YJ      ReceiptHeaders: Added PickTicket (FB-381)
  2014/12/08  SK      ReceiptHeaders: Addded PreprocessFlag
  2014/11/01  NY      ReceiptHeaders, ReceiptDetails: Added QtyToReceive
  2013/04/11  AY      ReceiptHeaders: Added BillNo, SealNo, InvoiceNo, ContainerNo, DateShipped
  2013/03/27  AY      ReceiptHeaders: Added new fields LPNs/Units InTransit/Received
  2013/02/08  PK      ReceiptHeaders: Added Vessel, NumLPNs, NumUnits, ContainerSize,
------------------------------------------------------------------------------*/

Go

/*------------------------------------------------------------------------------
 Table: ReceiptHeaders
------------------------------------------------------------------------------*/
Create Table ReceiptHeaders (
    ReceiptId                TRecordId      identity (1,1) not null,

    ReceiptNumber            TReceiptNumber not null,
    ReceiptType              TReceiptType   not null default 'P' /* Vendor PO */,
    Status                   TStatus        not null default 'I' /* Initial */,
    PickTicket               TPickTicket,

    VendorId                 TVendorId,
    VendorName               TName,
    Ownership                TOwnership,
    Vessel                   TVessel,
    ContainerSize            TContainerSize,
    Warehouse                TWarehouse,

    HostNumLines             TCount         default 0,
    NumLPNs                  TCount,
    NumUnits                 TCount,
    LPNsInTransit            TCount         not null default 0,
    LPNsReceived             TCount         not null default 0,
    UnitsInTransit           TQuantity      not null default 0,
    UnitsReceived            TQuantity      not null default 0,
    QtyToReceive             TQuantity      not null default 0,

    DateOrdered              TDateTime,
    DateShipped              TDateTime,
    DateExpected             TDateTime,     -- This field is deprecated, use ETAWarhouse instead.

    BillNo                   TBoLNumber,
    SealNo                   TSealNumber,
    InvoiceNo                TInvoiceNo,
    ContainerNo              TContainer,

    ETACountry               TDate,
    ETACity                  TDate,
    ETAWarehouse             TDate,
    AppointmentDateTime      TDateTime,

    SortLanes                TDescription,
    SortOptions              TVarchar,

    UDF1                     TUDF,
    UDF2                     TUDF,
    UDF3                     TUDF,
    UDF4                     TUDF,
    UDF5                     TUDF,
    UDF6                     TUDF,
    UDF7                     TUDF,
    UDF8                     TUDF,
    UDF9                     TUDF,
    UDF10                    TUDF,

    UDF11                    TUDF,
    UDF12                    TUDF,
    UDF13                    TUDF,
    UDF14                    TUDF,
    UDF15                    TUDF,
    UDF16                    TUDF,
    UDF17                    TUDF,
    UDF18                    TUDF,
    UDF19                    TUDF,
    UDF20                    TUDF,

    UDF21                    TUDF,
    UDF22                    TUDF,
    UDF23                    TUDF,
    UDF24                    TUDF,
    UDF25                    TUDF,
    UDF26                    TUDF,
    UDF27                    TUDF,
    UDF28                    TUDF,
    UDF29                    TUDF,
    UDF30                    TUDF,

    PrepareRecvFlag          TFlag          default 'I', /*  I- Ignore, N - Not yet done, Y- Done/Completed */
    PreprocessFlag           TFlag          default 'N',
    SourceSystem             TName          default 'HOST',
    Archived                 TFlag          default 'N',
    BusinessUnit             TBusinessUnit  not null,
    CreatedDate              TDateTime      default current_timestamp,
    ModifiedDate             TDateTime,
    CreatedBy                TUserId,
    ModifiedBy               TUserId,

    ModifiedOn               as cast (ModifiedDate as date),

    constraint pkReceiptHeaders_ReceiptId     PRIMARY KEY (ReceiptId),
    constraint ukReceiptHeaders_ReceiptNumber UNIQUE (ReceiptNumber, BusinessUnit)
);

create index ix_ReceiptHeaders_Archived          on ReceiptHeaders (Archived, Status) Include (ModifiedOn) where (Archived = 'N');
create index ix_ReceiptHeaders_ReceiptId         on ReceiptHeaders (ReceiptId) Include (NumLPNs, LPNsReceived);
create index ix_ReceiptHeaders_PreProcess        on ReceiptHeaders (PreprocessFlag) Include (ReceiptId);

Go

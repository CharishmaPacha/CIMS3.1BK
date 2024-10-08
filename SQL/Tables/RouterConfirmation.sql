/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/11/19  MS      RouterConfirmation: Modified UDF1 to UDF5 (JL-314)
  2020/09/15  AY      Added RouterConfirmation.DivertDateTime, ExternalRecId (JL-65)
  2018/04/24  RV      RouterConfirmation: Added UDFs (S2G-233)
  RouterConfirmation: Added Actual Weight
------------------------------------------------------------------------------*/

Go

/*------------------------------------------------------------------------------
  Table: RouterConfirmation

  When cartons (LPNs) are routed to a destination, DCMS would update CIMS by giving
  a confirmation for the same. In some cases, there could be an inline scanner and
  DCMS may confirm with the actual weight of the carton as well.

------------------------------------------------------------------------------*/
Create Table RouterConfirmation (
    RecordId                 TRecordId      identity (1,1) not null,

    LPNId                    TRecordId,
    LPN                      TLPN,
    ActualWeight             TWeight        default 0.0,

    Destination              TLocation,
    DivertDateTime           TDateTime,
    DivertDate               TDate,
    DivertTime               TTime,

    ProcessedStatus          TStatus        default 'N' /* Need to be processed */,
    ProcessedDateTime        TDateTime,
    ProcessedOn              As convert(date, ProcessedDateTime),
    ExternalRecId            TUDF,

    RC_UDF1                  TUDF,
    RC_UDF2                  TUDF,
    RC_UDF3                  TUDF,
    RC_UDF4                  TUDF,
    RC_UDF5                  TUDF,

    Archived                 TFlag          default 'N',
    BusinessUnit             TBusinessUnit  not null,
    CreatedDate              TDateTime      default current_timestamp,
    ModifiedDate             TDateTime,
    CreatedBy                TUserId,
    ModifiedBy               TUserId,

    constraint pkRouterConfirmation_RecordId PRIMARY KEY (RecordId)
);

create index ix_RouterConfirmation_LPNId         on RouterConfirmation (LPNId) Include (Archived);
create index ix_RouterConfirmation_LPN           on RouterConfirmation (LPN) Include (Archived);
create index ix_RouterConfirmation_PStatus       on RouterConfirmation (ProcessedStatus) Include (RecordId, LPN, Destination);
/* Purging */
create index ix_RouterConfirmation_ProcessedOn   on RouterConfirmation (Archived, ProcessedOn) Include (ProcessedStatus);

Go

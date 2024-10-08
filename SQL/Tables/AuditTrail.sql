/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/07/25  AY      Audit Trail: Added ProductionDate, index ix_AuditTrail_ProductionDate (HA-3019)
  2017/03/03  AY      AuditTrail: Added ActivityDate and index by the same for optimization (HPI-1119)
  2013/07/17  TD      Added ProductivityId to AuditTrail Table.
  2012/09/04  AY      AuditTrail: Added NumOrders, ProductivityFlag
------------------------------------------------------------------------------*/

Go

/*------------------------------------------------------------------------------
 Table: AuditTransactions

 ActivityType   - can be BatchPick, UnitPick, LPNPick etc.
 ProductionDate - is the date the activity is considered to have happened for
                  tracking/reporting purposes. By default anything before 3AM
                  is considered to have happened the prior day. This may change
                  from client to client in which case it would be dropped and
                  new formula added as needed.
------------------------------------------------------------------------------*/
Create Table AuditTrail (
    AuditId                  TRecordId      identity (1,1) not null,
    ActivityType             TActivityType,
    ActivityDateTime         TDateTime      default current_timestamp,

    NumOrders                TCount,
    NumPallets               TCount,
    NumLPNs                  TCount,
    NumSKUs                  TCount,

    InnerPacks               TInnerpacks,
    Quantity                 TQuantity,

    Comment                  TVarChar,
    Archived                 TFlag          default 'N',
    ProductivityFlag         TFlag          default 'N',
    ProductivityId           TRecordId,

    ActivityDate             As (cast(ActivityDateTime as date)),
    ProductionDate           As case when datepart(hh, ActivityDateTime) < 3 then dateadd(dd, -1, cast(ActivityDateTime as date))
                                     else (cast(ActivityDateTime as date))
                                end,

    DeviceId                 TDeviceId,
    BusinessUnit             TBusinessUnit  not null,
    UserId                   TUserId,

    constraint pkAuditTrail_AuditId PRIMARY KEY (AuditId)
);

create index ix_AuditTrail_ActivityType           on AuditTrail (ActivityType, BusinessUnit) include (ActivityDateTime);
/* Used by sp_Productivity procedures */
create index ix_AuditTrail_ProductivityFlag       on AuditTrail (ProductivityFlag, BusinessUnit, ActivityDate, UserId) Include (ActivityType);
create index ix_AuditTrial_ActivityDate           on AuditTrail (ActivityDate, UserId) Include (AuditId);
/* Used for KPIs */
create index ix_AuditTrail_ProductionDate         on AuditTrail (ProductionDate, BusinessUnit, ActivityType) Include (AuditId);

Go

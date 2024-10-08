/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

   2020/05/14  MS      Initial revision(HA-202)
------------------------------------------------------------------------------*/

Go

declare @EntityType  TName;

select @EntityType = 'RCV_EntityInfo'; /* Receiver */

delete from UIEntityInfo where (EntityType = @EntityType);

insert into UIEntityInfo
            (EntityType,   RelationType,  DisplayCaption,     ContextName,                     LayoutDescription,  SelectionName,  ContentType,  DbSourceType,  DbSource,           FormName,                   BusinessUnit)
      select @EntityType,  'P',           null,               @EntityType + '_Main',           null,               null,           'Html',       null,          null,               'RCV_EntityInfo_Parent',    BusinessUnit from vwBusinessUnits
/* Summary of Entity */
union select @EntityType,  'D',           null,               @EntityType + '_SummaryInfo',    'Standard',         @EntityType,    'Html',       'P',           'pr_Receivers_GetSummaryInfo',
                                                                                                                                                                                    'RCV_EntityInfo_SummaryForm',BusinessUnit from vwBusinessUnits
/* Header */
-- None defined at this time
/* Details/Tabs */
union select @EntityType,  'D',           'Receiver Summary', @EntityType + '_Summary',        'Standard',         @EntityType,    'List',       'V',           'vwReceivedCounts', null,                       BusinessUnit from vwBusinessUnits
union select @EntityType,  'D',           'LPNs',             @EntityType + '_LPNs',           'Standard',         @EntityType,    'List',       'V',           'vwLPNs',           null,                       BusinessUnit from vwBusinessUnits
union select @EntityType,  'D',           'Audit Trail',      @EntityType + '_AuditTrail',     'Standard',         @EntityType,    'List',       'V',           'vwATEntity',       null,                       BusinessUnit from vwBusinessUnits

Go

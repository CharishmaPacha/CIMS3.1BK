/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2012/10/12  AY      Rules for All Target and Walmart variations
  2012/09/27  AY      Define label for walmart prepacks.
  2012/09/20  AY      Initial revision.
------------------------------------------------------------------------------*/

delete from LabelRules;

Go

/*------------------------------------------------------------------------------*/
/* LabelRules */
/*------------------------------------------------------------------------------*/

insert into LabelRules (
                 EntityType,  LabelFormatName,    SoldToId, ShipToId, UoM, Status, SortSeq, BusinessUnit)
          select 'Ship',      'walmart4x6_t5000', 'W050A',  null,     'EA', 'A',   1,       BusinessUnit from vwBusinessUnits
union all select 'Ship',      'walmart4x6_t5000', 'W050A',  null,     'PP', 'A',   1,       BusinessUnit from vwBusinessUnits
union all select 'Ship',      'targetDC_t5000',   'T050A',  null,     'EA', 'A',   1,       BusinessUnit from vwBusinessUnits
union all select 'Ship',      'target_assortment','T050A',  null,     'PP', 'A',   2,       BusinessUnit from vwBusinessUnits

union all select 'Ship',      'targetDC_t5000',   'T060A',  null,     'EA', 'A',   1,       BusinessUnit from vwBusinessUnits
union all select 'Ship',      'target_assortment','T060A',  null,     'PP', 'A',   2,       BusinessUnit from vwBusinessUnits

union all select 'Ship',      'walmart4x6_t5000', 'W050D',  null,     'PP', 'A',   1,       BusinessUnit from vwBusinessUnits
union all select 'Ship',      'walmart4x6_t5000', 'W050D',  null,     'EA', 'A',   1,       BusinessUnit from vwBusinessUnits

Go

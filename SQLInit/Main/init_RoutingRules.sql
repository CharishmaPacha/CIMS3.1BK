/*------------------------------------------------------------------------------
  (c) Foxfire Technologies (India) Ltd. Hyderabad, India

  Revision History:

  Date        Person  Comments

  2021/10/01  RV      Initial Revision (BK-628)
------------------------------------------------------------------------------*/

Go

declare @BusinessUnit TBusinessUnit;

delete from RoutingRules;

/* Most implementations have only one BU, so get the first one and use it */
select Top 1 @BusinessUnit = BusinessUnit
from vwBusinessUnits
order by SortSeq;

/*------------------------------------------------------------------------------
 Routing rules
------------------------------------------------------------------------------*/

Go

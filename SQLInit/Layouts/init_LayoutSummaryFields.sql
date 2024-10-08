/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

/* Use only for generic summary fields */
  2021/04/20  AY      Added UnitsToShip (HA GoLive)
  2021/03/16  RV      Added EstimatedCartons (HA Golive)
  2020/06/05  TK      Added NumTasks (HA-859)
  2019/04/26  RKC     Added Volume & Weight fields(CIMSV3-194)
  2019/03/23  VS      Added Waves fields(cimsv3-193)
  2019/03/23  AY      Added OrderDetail/OrderHeader fields
  2017/08/30  NB      Initial revision.
------------------------------------------------------------------------------*/

Go

declare @ContextName           TName,
        @LayoutDescription     TDescription,
        @BusinessUnit          TBusinessUnit,
        @CreatedBy             TUserId,
        @ttLayoutSummaryFields TLayoutSummaryFields;

select @CreatedBy = 'cimsdba';

/******************************************************************************/
/* Generic = applies to all contexts and all layouts */
/******************************************************************************/
delete from @ttLayoutSummaryFields;
select @ContextName       = null,
       @LayoutDescription = null; -- Applicable to all layouts

insert into @ttLayoutSummaryFields
             (FieldName,          SummaryType, DisplayFormat,           AggregateMethod)
      select 'Quantity',          'Sum',       '{0:###,###,###}',       null
union select 'InnerPacks',        'Sum',       '{0:###,###,###}',       null
union select 'NumPackages',       'Sum',       '{0:###,###,###}',       null
union select 'NumLPNs',           'Sum',       '{0:###,###,###}',       null
union select 'EstimatedCartons',  'Sum',       '{0:###,###,###}',       null
union select 'NumPallets',        'Sum',       '{0:###,###,###}',       null
union select 'NumOrders',         'Sum',       '{0:###,###,###}',       null
union select 'NumWaves',          'Sum',       '{0:###,###,###}',       null
union select 'NumPallets',        'Sum',       '{0:###,###,###}',       null
union select 'NumUnits',          'Sum',       '{0:###,###,###}',       null
union select 'NumLocations',      'Sum',       '{0:###,###,###}',       null
union select 'NumLines',          'Sum',       '{0:###,###,###}',       null

union select 'TotalInnerPacks',   'Sum',       '{0:###,###,###}',       null
union select 'TotalUnits',        'Sum',       '{0:###,###,###}',       null
union select 'Weight',            'Sum',       '{0:###,###,###}',       null
union select 'Volume',            'Sum',       '{0:###,###,###}',       null

/*----------------------------------------------------------------------------*/
/* LPN Details */
union select 'ReservedQuantity',  'Sum',       '{0:###,###,###}',       null
union select 'ReceivedUnits',     'Sum',       '{0:###,###,###}',       null
/*----------------------------------------------------------------------------*/
/* Order Details */
union select 'UnitsOrdered',      'Sum',       '{0:###,###,###}',       null
union select 'UnitsAuthorizedToShip',
                                  'Sum',       '{0:###,###,###}',       null
union select 'OrigUnitsAuthorizedToShip',
                                  'Sum',       '{0:###,###,###}',       null

union select 'UnitsAssigned',     'Sum',       '{0:###,###,###}',       null
union select 'UnitsPreAllocated', 'Sum',       '{0:###,###,###}',       null
union select 'UnitsToAllocate',   'Sum',       '{0:###,###,###}',       null
/*----------------------------------------------------------------------------*/
/* Order Headers */
union select 'UnitsPicked',       'Sum',       '{0:###,###,###}',       null
union select 'UnitsPacked',       'Sum',       '{0:###,###,###}',       null
union select 'UnitsStaged',       'Sum',       '{0:###,###,###}',       null
union select 'UnitsLoaded',       'Sum',       '{0:###,###,###}',       null
union select 'UnitsShipped',      'Sum',       '{0:###,###,###}',       null
union select 'UnitsToShip',       'Sum',       '{0:###,###,###}',       null

union select 'LPNsAssigned',      'Sum',       '{0:###,###,###}',       null
union select 'LPNsPicked',        'Sum',       '{0:###,###,###}',       null
union select 'LPNsPacked',        'Sum',       '{0:###,###,###}',       null
union select 'LPNsStaged',        'Sum',       '{0:###,###,###}',       null
union select 'LPNsLoaded',        'Sum',       '{0:###,###,###}',       null
union select 'LPNsShipped',       'Sum',       '{0:###,###,###}',       null
/*----------------------------------------------------------------------------*/
/* ROH/ROD */
union select 'UnitsInTransit',    'Sum',       '{0:###,###,###}',       null
union select 'UnitsReceived',     'Sum',       '{0:###,###,###}',       null
union select 'QtyToReceive',      'Sum',       '{0:###,###,###}',       null
union select 'LPNsInTransit',     'Sum',       '{0:###,###,###}',       null
union select 'QtyOrdered',        'Sum',       '{0:###,###,###}',       null
union select 'QtyInTransit',      'Sum',       '{0:###,###,###}',       null
union select 'QtyReceived',       'Sum',       '{0:###,###,###}',       null
/*----------------------------------------------------------------------------*/
/* Task */
union select 'CompletedCount',     'Sum',       '{0:###,###,###}',       null
union select 'DetailCount',        'Sum',       '{0:###,###,###}',       null
union select 'DetailInnerPacks',   'Sum',       '{0:###,###,###}',       null
union select 'DetailQuantity',     'Sum',       '{0:###,###,###}',       null
union select 'InnerPacksToPick',   'Sum',       '{0:###,###,###}',       null
union select 'InnerPacksCompleted','Sum',       '{0:###,###,###}',       null
union select 'NumTasks',           'Sum',       '{0:###,###,###}',       null
union select 'NumPicks',           'Sum',       '{0:###,###,###}',       null
union select 'NumPicksCompleted',  'Sum',       '{0:###,###,###}',       null
union select 'UnitsCompleted',     'Sum',       '{0:###,###,###}',       null
union select 'UnitsToPick',        'Sum',       '{0:###,###,###}',       null
/*----------------------------------------------------------------------------*/
/* Wave (and Wave Summary) */
union select 'UnitsShort',         'Sum',       '{0:###,###,###}',       null
union select 'UnitsNeeded',        'Sum',       '{0:###,###,###}',       null

exec pr_Setup_LayoutSummaryFields @ContextName, @LayoutDescription, @ttLayoutSummaryFields;

Go

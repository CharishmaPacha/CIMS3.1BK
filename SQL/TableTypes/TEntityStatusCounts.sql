/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  ********************************* IMPORTANT *********************************
  There is a Base version of this TableType exists. Taken here for additional fields.
  So, if there are any common fields to be added, MUST consider adding the same in Base version as well.
  *****************************************************************************

  2021/04/14  AY      TEntityStatusCounts: Expanded to include count and udfs (HA-2466)
  2018/10/10  AY      TEntityStatusCounts: Added Weight & Volume (S2G-368)
  2018/07/25  VM      TEntityStatusCounts: Added NumInnerPacks (S2G-1006)
  2014/09/17  PKS     Added TPutawayRulesInfo and TEntityStatusCounts to Domains_TempTables.Sql
------------------------------------------------------------------------------*/

Go

if type_id('dbo.TEntityStatusCounts') is not null drop type TEntityStatusCounts;
/*----------------------------------------------------------------------------*/
/* Table Type to use for summarizing counts by Entity, Type or Status */
Create Type TEntityStatusCounts as Table (
    Entity                   TEntity,
    EntityType               TTypeCode,
    EntityStatus             TStatus,
    EntityOnhandStatus       TStatus,
    NumEntities              TCount,
    NumPallets               TCount,
    NumLPNs                  TCount,
    NumCases                 TCount,
    NumInnerPacks            TCount,
    NumUnits                 TQuantity,
    Weight                   TWeight,
    Volume                   TVolume,

    Count1                   TCount,
    Count2                   TCount,
    Count3                   TCount,
    Count4                   TCount,
    Count5                   TCount,

    UDF1                     TUDF,
    UDF2                     TUDF,
    UDF3                     TUDF,
    UDF4                     TUDF,
    UDF5                     TUDF,

    RecordId                 TRecordId      identity (1,1),
    Primary Key              (RecordId)
);

Grant References on Type:: TEntityStatusCounts to public;

Go

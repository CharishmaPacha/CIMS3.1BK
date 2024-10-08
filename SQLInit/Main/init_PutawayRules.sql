/*------------------------------------------------------------------------------
  (c) Foxfire Technologies (India) Ltd. Hyderabad, India

  Revision History:

  Date        Person  Comments

  2020/09/08  MS      Setup Putaway rules using V3 standards (CIMSV3-1028)
  2020/04/21  RKC     Added PARules for pallet PA (HA-210)
  2020/04/20  TK      Corrected Generic PARules (HA-210)
  2020/02/19  AY      Do not pass in any BU for setup - Rules should apply to active BUs
  2015/12/12  TD      Added LocationClass (CIMS-1750)
  2014/12/23  VM      Added rules for Picklane locations
  2014/10/12  TK      Added default PutawayRules.
  2013/08/30  TD      Added Warehouse.
  2013/05/31  AY      Added rules for PA of LPNs to Picklanes.
  2103/05/28  TD      Added PAType.
  2013/05/23  VM      Initial revision for TLP
------------------------------------------------------------------------------*/

Go

declare @vSKUPutawayClass   TCategory,
        @vLPNPutawayClass   TCategory,
        @vPutawayZone       TLookupCode,
        @vSequenceSeries    TInteger,
        @vSeqOffset         TInteger,
        @vWarehouses        TVarchar; -- CSV of Warehouses, null means rules would be set up for all active WHs

declare @ttPARules          TPutawayRulesInfo;

/* Drop temp table if exists and/or Create new one */
if object_id('tempdb..#PARules') is not null drop table #PARules;
select * into #PARules from @ttPARules;

/*------------------------------------------------------------------------------*/
/* LPNs putawawy to Picklane Location if location is empty */
/*------------------------------------------------------------------------------*/

delete from #PARules
insert into #PARules
            (SequenceNo, PAType, PalletType, LPNType,   PutawayZone, LocationType, StorageType, LocationStatus, Location, LocationClass, SKUExists, Status)
/* Putaway LPNs to Picklanes first */
      select 1001,       'L',    null,       'C',       null,        'K',          'U',         'U',            null,     null,          'Y',       'I'
union select 1002,       'L',    null,       'C',       null,        'K',          'U',         'E',            null,     null,          'Y',       'A'
union select 1003,       'LP',   null,       'C',       null,        'K',          'U',         'U',            null,     null,          'Y',       'I'
union select 1004,       'LP',   null,       'C',       null,        'K',          'U',         'E',            null,     null,          'Y',       'A'

/* These are sample rules setup to give an idea on how to configure the rules
   Params are SKUPutawayClass, LPNPutawayClass, PutawayZone, Series, SeqOffSet */
exec pr_Setup_PutawayRules '01',     '1',      'P01',    null,     null,     @vWarehouses, 'I' /* Delete & Add */
exec pr_Setup_PutawayRules '01',     '2',      'P01',    null,     null,     @vWarehouses, 'I' /* Delete & Add */
exec pr_Setup_PutawayRules '01',     '3',      'P01',    null,     null,     @vWarehouses, 'I' /* Delete & Add */
exec pr_Setup_PutawayRules '01',     null,     'P01',    null,     null,     @vWarehouses, 'I' /* Delete & Add */
exec pr_Setup_PutawayRules null,     null,     'P01',    null,     null,     @vWarehouses, 'I' /* Delete & Add */
exec pr_Setup_PutawayRules null,     null,     null ,    null,     null,     @vWarehouses, 'I' /* Delete & Add */

/*------------------------------------------------------------------------------*/
/* PA Classes 1,2,3 for Reserve Locations */
/*------------------------------------------------------------------------------*/

delete from #PARules
insert into #PARules
             (SequenceNo, PAType, PalletType, LPNType,   PutawayZone, LocationType, StorageType, LocationStatus, Location, LocationClass, SKUExists, Status)
/* Putaway LPNs to Reserve locations */
      select  1005,       'L',    null,       'C',       null,        'R',          'L',         'U',            null,     null,          'Y',       'A'
union select  1006,       'L',    null,       'C',       null,        'R',          'L',         'E',            null,     null,          'N',       'A'
union select  1007,       'LP',   null,       'C',       null,        'R',          'LA',        'U',            null,     null,          'Y',       'A'
union select  1008,       'LP',   null,       'C',       null,        'R',          'LA',        'E',            null,     null,          'N',       'A'
union select  1009,       'A',    null,       'C',       null,        'R',          'A',         'U',            null,     null,          'Y',       'A'
union select  1010,       'A',    null,       'C',       null,        'R',          'A',         'E',            null,     null,          'N',       'A'

/* These are sample rules setup to give an idea on how to configure the rules
  Params are SKUPutawayClass, LPNPutawayClass, PutawayZone, Series, SeqOffSet */
exec pr_Setup_PutawayRules '01',     '1',      'P01',    null,     null,     @vWarehouses, 'I' /* Delete & Add */
exec pr_Setup_PutawayRules '01',     '2',      'P01',    null,     null,     @vWarehouses, 'I' /* Delete & Add */
exec pr_Setup_PutawayRules '01',     '3',      'P01',    null,     null,     @vWarehouses, 'I' /* Delete & Add */
exec pr_Setup_PutawayRules '01',     null,     'P01',    null,     null,     @vWarehouses, 'I' /* Delete & Add */
exec pr_Setup_PutawayRules null,     null,     'P01',    null,     null,     @vWarehouses, 'I' /* Delete & Add */
exec pr_Setup_PutawayRules null,     null,     null ,    null,     null,     @vWarehouses, 'I' /* Delete & Add */

Go

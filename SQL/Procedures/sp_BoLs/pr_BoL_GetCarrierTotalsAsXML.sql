/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/05/31  SK      pr_BoL_GetCarrierTotalsAsXML: Default to 0 when entries are missing (HA-2676)
  2012/12/30  AY      Added pr_BoL_GetCarrierDetailsAsXML, pr_BoL_GetCarrierTotalsAsXML
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_BoL_GetCarrierTotalsAsXML') is not null
  drop Procedure pr_BoL_GetCarrierTotalsAsXML;
Go
/*------------------------------------------------------------------------------
  Proc pr_BoL_GetCarrierTotalsAsXML:
------------------------------------------------------------------------------*/
/* Summarizes and Returns totals info in Carrier Details table variable as an XML */
Create Procedure pr_BoL_GetCarrierTotalsAsXML
  (@CarrierDetails    TBoLCarrierDetails ReadOnly,
   @BoLNumber         TBoLNumber,
   @IsSupplement      TFlag  = 'Y',
   @xmlCarrierTotals  XML    = null output)
as
begin
  /* Generate the totals xml for Carrier Details */
  select @xmlCarrierTotals = (select coalesce(sum(HandlingUnitQty), 0) as HandlingUnitTotalQty,
                                     coalesce(sum(PackageQty), 0)      as PackageTotalQty,
                                     coalesce(sum(Weight), 0)          as Weight,
                                     @BoLNumber                        as BoLNumber
                              from @CarrierDetails
                              for xml raw('CarrierDetailTotals'), elements);

  /* If supplement page, then prefix nodes with 'Supplement' */
  if (@IsSupplement in ('Y' /* Normal*/, 'L' /* Large */))
    select @xmlCarrierTotals = replace(convert(varchar(max), @xmlCarrierTotals),
                                        'CarrierDetailTotals', 'SupplementCarrierDetailTotals');
end /* pr_BoL_GetCarrierTotalsAsXML */

Go

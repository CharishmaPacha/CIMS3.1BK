/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/04/27  RKC     pr_BoL_GenerateOrderDetails, pr_BoL_GetCustomerOrderTotalsAsXML: Made changes to get the correct weight on the BOLs (HA-2650)
                      pr_BoL_GetCustomerOrderDetailsAsXML and pr_BoL_GetCustomerOrderTotalsAsXML
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_BoL_GetCustomerOrderTotalsAsXML') is not null
  drop Procedure pr_BoL_GetCustomerOrderTotalsAsXML;
Go
/*------------------------------------------------------------------------------
  Proc pr_BoL_GetCustomerOrderTotalsAsXML: Summarizes and Returns totals info in
    Customer Order Details table variable as an XML
------------------------------------------------------------------------------*/
Create Procedure pr_BoL_GetCustomerOrderTotalsAsXML
  (@CustomerOrderDetails     TBoLCustomerOrderDetails ReadOnly,
   @BoLId                    TRecordId,
   @IsSupplement             TFlag  = 'Y',
   @xmlCustomerOrderTotals   XML    = null output)
as
  declare @vBoLId            TBoLId,
          @vBoLNumber        TBoLNumber,
          @vNumPallets       TCount,
          @vPalletWeight     TWeight,
          @vPalletTareWeight TInteger,
          @vBusinessUnit     TBusinessUnit;
begin
  /* Initialize values */
  select @vPalletTareWeight = 0;

  /* Get BoLNumber from BoL table */
  select @vBoLNumber = BoLNumber
  from BoLs
  where (BoLId = @BoLId);

  /* Get NumPallets counts from BOLCarrierDetails */
  select @vNumPallets   = sum(HandlingUnitQty),
         @vBusinessUnit = min(BusinessUnit)
  from BoLCarrierDetails
  where (BoLId            = @BoLId) and
        (HandlingUnitType = 'plts');

  /* Get the PalletTareWeight and Volume and update accordingly */
  select @vPalletTareWeight = dbo.fn_Controls_GetAsInteger('BoL', 'PalletTareWeight', '35' /* lbs */, @vBusinessUnit, null);

  /* Calculate the Pallet weight */
  select @vPalletWeight = coalesce(@vNumPallets, 0) * @vPalletTareWeight;

  /* Generate the totals xml for Customer Order Details */
  select @xmlCustomerOrderTotals = (select sum(NumPackages)                                      as NumPackages,
                                           round((coalesce(sum(Weight), 0) + @vPalletWeight), 0) as Weight,
                                           @vBoLNumber                                           as BoLNumber
                                    from @CustomerOrderDetails
                                    for xml raw('CustomerOrderTotals'), elements);

  /* If supplement page, then prefix nodes with 'Supplement' */
  if (@IsSupplement in ('Y' /* Normal*/, 'L' /* Large */))
    select @xmlCustomerOrderTotals = replace(convert(varchar(max), @xmlCustomerOrderTotals),
                                             'CustomerOrderTotals', 'SupplementCustomerOrderTotals');
end /* pr_BoL_GetCustomerOrderTotalsAsXML */

Go

/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/03/28  TK      pr_BoL_GetCustomerOrderDetailsAsXML: Changes to fn_GenerateSequence data set (HA-2471)
                      pr_BoL_GetCarrierDetailsAsXML and pr_BoL_GetCustomerOrderDetailsAsXML: Included BCD nad BOD reference fields (FB-2225)
  2018/06/07  AY      pr_BoL_GetCustomerOrderDetailsAsXML: Clean-up, send UDFs (S2G-923)
                      pr_BoL_GetCustomerOrderDetailsAsXML and pr_BoL_GetCustomerOrderTotalsAsXML
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_BoL_GetCustomerOrderDetailsAsXML') is not null
  drop Procedure pr_BoL_GetCustomerOrderDetailsAsXML;
Go
/*------------------------------------------------------------------------------
  Proc pr_BoL_GetCustomerOrderDetailsAsXML:
------------------------------------------------------------------------------*/
/* Returns info in Customer Order Details table variable as an XML */
Create Procedure pr_BoL_GetCustomerOrderDetailsAsXML
  (@CustomerOrderDetails     TBoLCustomerOrderDetails ReadOnly,
   @BoLNumber                TBoLNumber,
   @IsSupplement             TFlag  = 'Y',
   @RequiredRows             TCount = null,
   @xmlCustomerOrderDetails  XML    = null output)
as
  declare @vCustomerOrderDetails TBoLCustomerOrderDetails,
          @vRowCount             TCount;
begin
  /* Copy to local variable as param cannot be modified */
  insert into @vCustomerOrderDetails
    select * from @CustomerOrderDetails;

  select @vRowCount = @@rowcount;

  /* In case there are less than the required number of rows, then generate lines to fill up to 5 */
  if (@vRowCount < @RequiredRows)
    insert into @vCustomerOrderDetails (SortSeq)
      select SequenceNo from dbo.fn_GenerateSequence(@vRowCount /* Start */, @RequiredRows /* End */, null /* Count */)

  /* Update Page number here ..
     Get the Ceil value of SortSeq/No.Of rows per page. */
  update @vCustomerOrderDetails
  set PageNumber = Ceiling(cast(SortSeq as Float) / 28);

  /* Generate xml for Carrier  Details of main page */
  select @xmlCustomerOrderDetails = (select top (@RequiredRows)
                                            CustomerOrderNumber   as CustomerOrderNumber,
                                            NumPackages           as NumPackages,
                                            coalesce(Weight, 0)   as Weight,
                                            coalesce(Palletized, '')
                                                                  as PalletOrSlip,
                                            AdditionalShipperInfo as AdditionalShipperInfo,
                                            @BoLNumber            as BoLNumber,
                                            PageNumber            as PageNumber,
                                            UDF1                  as UDF1,
                                            UDF2                  as UDF2,
                                            UDF3                  as UDF3,
                                            UDF4                  as UDF4,
                                            UDF5                  as UDF5,
                                            BODGroupCriteria      as BODGroupCriteria,
                                            BOD_Reference1        as BOD_Reference1,
                                            BOD_Reference2        as BOD_Reference2,
                                            BOD_Reference3        as BOD_Reference3,
                                            BOD_Reference4        as BOD_Reference4,
                                            BOD_Reference5        as BOD_Reference5
                               from @vCustomerOrderDetails
                               order by SortSeq
                               FOR XML RAW('CustomerOrderDetail'), TYPE, ELEMENTS XSINIL, ROOT('CustomerOrderDetails'));

  /* If supplement page, then prefix nodes with 'Supplement' */
  if (@IsSupplement in ('Y' /* Normal */, 'L' /* Large */))
    select @xmlCustomerOrderDetails = replace(convert(varchar(max), @xmlCustomerOrderDetails),
                                        'CustomerOrderDetail', 'SupplementCustomerOrderDetail');
end /* pr_BoL_GetCustomerOrderDetailsAsXML */

Go

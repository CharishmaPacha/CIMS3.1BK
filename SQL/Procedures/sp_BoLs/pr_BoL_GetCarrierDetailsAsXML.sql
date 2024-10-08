/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2023/10/10  LAC     pr_BoL_GetCarrierDetailsAsXML:Made changes to print NMFCClass on report (MBW-589)
                      pr_BoL_GetCarrierDetailsAsXML and pr_BoL_GetCustomerOrderDetailsAsXML: Included BCD nad BOD reference fields (FB-2225)
  2020/10/22  PHK/TK  pr_BoL_GetCarrierDetailsAsXML: Made this change to insert null into the Hazardous column for empty rows
  2020/06/10  RT      pr_BoL_GetCarrierDetailsAsXML: To prevent the #Error in rdlc (HA-825)
  2013/01/25  YA/TD   pr_BoL_GetCarrierDetailsAsXML: Sending empty values for Hazardous.
  2012/12/30  AY      Added pr_BoL_GetCarrierDetailsAsXML, pr_BoL_GetCarrierTotalsAsXML
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_BoL_GetCarrierDetailsAsXML') is not null
  drop Procedure pr_BoL_GetCarrierDetailsAsXML;
Go
/*------------------------------------------------------------------------------
  Proc pr_BoL_GetCarrierDetailsAsXML:
------------------------------------------------------------------------------*/
/* Returns info in Carrier Details table variable as an XML */
Create Procedure pr_BoL_GetCarrierDetailsAsXML
  (@CarrierDetails     TBoLCarrierDetails ReadOnly,
   @BoLNumber          TBoLNumber,
   @IsSupplement       TFlag  = 'Y',
   @RequiredRows       TCount = null,
   @xmlCarrierDetails  XML    = null output)
as
  declare @vCarrierDetails TBoLCarrierDetails,
          @vRequiredRows   TCount,
          @Count           TCount;
begin
  /* Initialize */
  select @xmlCarrierDetails = null;

  /* Copy to local variable as param cannot be modified */
  insert into @vCarrierDetails
    select * from @CarrierDetails;

  select @Count = @@rowcount,
         @vRequiredRows =  Case
                             when @IsSupplement = 'N' /* No */     then 5
                             when @IsSupplement = 'Y' /* Normal - Common Supplement */ then 14
                             when @IsSupplement = 'L' /* Large  - Single Supplement */  then (Ceiling(cast(@Count as Float) / 28) * 28)
                           end;

  /* In case there are less than the required number of rows, then generate lines to fill up to 5 */
  /* By default Temptable passing "N" for Hazardous.. So for blank rows it is inserted as "N".
     so we made this change to insert null into the dangerous column for empty rows */
  if (@Count < @vRequiredRows)
    insert into @vCarrierDetails (SortSeq, Hazardous)
      select 0, '' from dbo.fn_GenerateSequence(@Count /* Start */, @vRequiredRows /* End */, null /* Count */)

  /* Update Page number here ..
     Get the Ceiling value of SortSeq/No.Of rows per page. */
  update @vCarrierDetails
  set PageNumber = Ceiling(cast(SortSeq as Float) / 28);

  /* Generate xml for Carrier  Details of main page */
  select @xmlCarrierDetails = (select top (@vRequiredRows)
                                      HandlingUnitType as HandlingUnitType,
                                      coalesce(HandlingUnitQty, 0)
                                                       as HandlingUnitQty,
                                      PackageType      as PackageType,
                                      coalesce(PackageQty, 0)
                                                       as PackageQty,
                                      coalesce(Weight, 0)
                                                       as Weight,
                                      Hazardous        as Hazardous,
                                      CommDescription  as CommodityDescription,
                                      NMFCCode         as NMFCCode,
                                      CommClass        as CommodityClass,
                                      @BoLNumber       as BoLNumber,
                                      PageNumber       as PageNumber,
                                      ''               as BCDGroupCriteria,
                                      ''               as BCD_Reference1,
                                      ''               as BCD_Reference2,
                                      ''               as BCD_Reference3,
                                      ''               as BCD_Reference4,
                                      ''               as BCD_Reference5
                               from @vCarrierDetails
                               order by HandlingUnitQty desc,PackageQty desc,SortSeq
                               FOR XML RAW('CarrierDetail'), TYPE, ELEMENTS XSINIL, ROOT('CarrierDetails'));

  /* If supplement page, then prefix nodes with 'Supplement' */
  if (@IsSupplement in ('Y' /* Normal*/, 'L' /* Large */))
    select @xmlCarrierDetails = replace(convert(varchar(max), @xmlCarrierDetails),
                                        'CarrierDetail', 'SupplementCarrierDetail');
end /* pr_BoL_GetCarrierDetailsAsXML */

Go

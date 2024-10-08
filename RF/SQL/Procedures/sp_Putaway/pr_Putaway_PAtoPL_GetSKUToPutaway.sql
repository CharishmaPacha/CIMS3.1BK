/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2019/09/17  VS/AY   pr_Putaway_PAtoPL_GetSKUToPutaway: order by PutawaySequence (CID-1039)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Putaway_PAtoPL_GetSKUToPutaway') is not null
  drop Procedure pr_Putaway_PAtoPL_GetSKUToPutaway;
Go
/*------------------------------------------------------------------------------
  Procedure pr_Putaway_PAtoPL_GetSKUToPutaway:

  Processes the requests for Location Inquiry for Location Inquiry work flow
------------------------------------------------------------------------------*/
Create Procedure pr_Putaway_PAtoPL_GetSKUToPutaway
  (@PalletId       TRecordId,
   @DeviceId       TDeviceId,
   @UserId         TUserId,
   @RFFormAction   TMessageName,
   @BusinessUnit   TBusinessUnit,
   @vPADetailsXML  TXML output)
as
  declare @vxmlPADetails             xml,
          @vxmlPAList                xml,
          @vLPN                      TLPN,
          @vLPNId                    TRecordId,
          @vLPNDetailId              TRecordId,
          @vPallet                   TPallet,
          @vPalletId                 TRecordId,
          @vSKU                      TSKU,
          @vSKUId                    TRecordId,
          @vCurrPASequence           TControlValue,
          @vPutawaySequence          TControlValue,
          @vReturnCode               TInteger,
          @vMessageName              TMessageName;
begin /* pr_Putaway_PAtoPL_GetSKUToPutaway */

  /* Get the current Sequence */
  select @vCurrPASequence = PickSequence
  from Devices
  where (DeviceId     = (@DeviceId + '@' + @UserId)) and
        (BusinessUnit = @BusinessUnit);

  /* Get the Pallet LPN Details */
  select L.LPN LPN, S.SKU SKU, replace(S.Description, '''', '') SKUDescription,
         LD.Quantity, LD.LPNId, LD.LPNDetailId, S.SKUId,
         LOC.Location PrimaryLocation, S.UPC, L.PalletId,
         (coalesce(LOC.PutawayPath, '') + coalesce(LOC.Location, 'ZZZZ') +
          coalesce(S.SKUSortOrder, '') + coalesce(S.SKU, '')) PutawaySequence
  into #PutawayDetails
  from  LPNs L
    join LPNDetails LD on L.LPNId = LD.LPNId
    join SKUs S on LD.SKUId = S.SKUId
    left outer join Locations LOC on LOC.LocationId = S.PrimaryLocationId and LOC.Status in ('E', 'U')
  where (L.PalletId = @PalletId);

  /* Putaway Details has the list of all SKUs, we need to suggest the first SKU to the user */
  if (coalesce(@vCurrPASequence, '') <> '')
    select top 1 @vLPN             = LPN,
                 @vLPNId           = LPNId,
                 @vLPNDetailId     = LPNDetailId,
                 @vSKUId           = SKUId,
                 @vPutawaySequence = PutawaySequence
    from #PutawayDetails
    where (PutawaySequence > @vCurrPASequence)
    order by PutawaySequence;

  /* Putaway Details has the list of all SKUs, we need to suggest the first SKU to the user */
  if (@vLPNDetailId is null)
    select top 1 @vLPN             = LPN,
                 @vLPNId           = LPNId,
                 @vLPNDetailId     = LPNDetailId,
                 @vSKUId           = SKUId,
                 @vPutawaySequence = PutawaySequence
    from #PutawayDetails
    order by PutawaySequence;

  /* Capture the detail of the next SKU to Putaway */
  select @vxmlPADetails = (select right(LPN, 10) LPNRight10, *
                           from #PutawayDetails
                           where (LPNDetailId = @vLPNDetailId)
                           order by PutawaySequence
                           for xml raw('PADetails'), Elements);

  /* Get the all LPNs against given Pallet */
  select @vxmlPAList = (select LPN, SKU, SKUDescription, Quantity
                        from #PutawayDetails
                        order by PutawaySequence
                        for Xml Raw('LPNDetail'), elements XSINIL, Root('PALLETLPNDETAILS'));

  /* Build xml of putaway details */
  select @vPADetailsXML = '';
  with FlatXML as
  (
    select dbo.fn_XMLNode('PADetails_' + c.value('(local-name(.))[1]', 'nvarchar(max)'), replace(c.value('(.)[1]', 'nvarchar(max)'), '''', '''''')) DetailNode
    from @vxmlPADetails.nodes('/PADetails/*') as t(c)
  )
  select @vPADetailsXML = @vPADetailsXML + DetailNode from FlatXML;

  select @vPADetailsXML = @vPADetailsXML + convert(varchar(max), @vxmlPAList);

end /* pr_Putaway_PAtoPL_GetSKUToPutaway */

Go


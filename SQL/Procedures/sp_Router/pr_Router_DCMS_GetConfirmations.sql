/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Router_DCMS_GetConfirmations') is not null
  drop Procedure pr_Router_DCMS_GetConfirmations;
Go
/*------------------------------------------------------------------------------
  pr_Router_DCMS_GetConfirmations: Procedure to get the Router confirmations from
    SDI DCMS and insert into CIMS table for processing
------------------------------------------------------------------------------*/
Create Procedure pr_Router_DCMS_GetConfirmations
  (@BusinessUnit TBusinessUnit,
   @UserId       TUserId)
as
  declare @vReturnCode         TInteger,
          @vMessageName        TMessageName,
          @vRecordId           TRecordId,

          @vRecIdToUpdate      TRecordId,
          @vLPN                TLPN;

begin /* pr_Router_DCMS_GetConfirmations */
  select @vReturnCode    = 0,
         @vMessageName   = null,
         @vRecIdToUpdate = 0;

  /* Retrieving data from DCMSCartonDivert and insert into our RouterConfirmation table*/
  select 0 as LPNId, CD.CartonLPN as DCMSLPN, CD.Destination, CD.DivertTime, CD.RecId, space(50) as LPN
  into #DCMSDivertedCartons
  from DCMS_vwCartonDivert CD

  /* Fetch the LPNId for the given cartons assuming DCMS has given our LPN */
  update DC
  set LPNId = L.LPNId,
      LPN   = L.LPN
  from #DCMSDivertedCartons DC left outer join LPNs L on (L.LPN = DC.DCMSLPN)
  where DC.LPNId = 0;

  /* Fetch the LPNId for the given cartons assuming DCMS has given the UCCBarcode */
  update DC
  set LPNId = L.LPNId,
      LPN   = L.LPN
  from #DCMSDivertedCartons DC left outer join LPNs L on (L.UCCBarcode = DC.DCMSLPN)
  where DC.LPNId = 0;

  insert into RouterConfirmation (LPNId, LPN, Destination, DivertDateTime, BusinessUnit, CreatedBy, ExternalRecId)
    select DC.LPNId, DC.LPN, DC.Destination, DC.DivertTime, @BusinessUnit, @UserId, DC.RecId
    from #DCMSDivertedCartons DC

  /* If records exist, Ack */
  while (exists (select * from #DCMSDivertedCartons where RecId > @vRecIdToupdate))
    begin
      select top 1 @vRecIdToUpdate = RecId,
                   @vLPN           = DCMSLPN
      from #DCMSDivertedCartons
      where RecId > @vRecIdToUpdate
      order by RecId

      exec DCMS_pr_CartonDivertACK 'CIMS', @vRecIdToupdate, @vLPN, 0 /* ErrorCode: None */;
    end

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Router_DCMS_GetConfirmations */

Go

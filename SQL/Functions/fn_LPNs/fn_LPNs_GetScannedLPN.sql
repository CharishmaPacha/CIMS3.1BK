/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2018/10/04  YJ      fn_LPNs_GetScannedLPN: Strip off -1 from TForce labels (S2GCA-98)
  2017/11/20  AY      fn_LPNs_GetScannedLPN: Check against ASN Case as well (OB-662)
  2017/04/10  TK      fn_LPNs_GetScannedLPN: Changes to signature to consider what type of checks needs to be done (HPI-1490)
  2016/12/02  AY      fn_LPNs_GetScannedLPN: Old LPN numbers being confused with LPNIds (HPI-GoLive)
  2016/09/13  AY      fn_LPNs_GetScannedLPN: Enhanced for FedEx TrackingNo (HPI-GoLive)
  2016/02/15  TK      fn_LPNs_GetScannedLPN: Initial Revision (CIMS-723)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.fn_LPNs_GetScannedLPN') is not null
  drop Function fn_LPNs_GetScannedLPN;
Go
/*------------------------------------------------------------------------------
  fn_LPNs_GetScannedLPN:
    This function returns LPNId where user Scans LPN or UCCBarcode or TrackingNo.

  Options:
    I - Checks whether user has scanned LPNId
    L - Checks whether user has scanned LPN
    T - Checks whether user has scanned Tracking No
    U - Checks whether user has scanned UCCBarcode
    A - ASN Case
------------------------------------------------------------------------------*/
Create Function fn_LPNs_GetScannedLPN
  (@LPN          TLPN,             /* LPNId/LPN/TrackingNo/UCCBarcode */
   @BusinessUnit TBusinessUnit,
   @Options      TFlags = 'LTU')
  -----------------------------
   returns       TRecordId /* LPN Id */
as
begin
  declare @vLPNId         TRecordId,
          @vInputLen      TInteger,
          @vLPNCheck      TFlag,
          @vOptions       TFlags;

  select @vLPNId        = null,
         @vInputLen     = Len(@LPN),
         @vLPNCheck     = 'N',
         @vOptions      = @Options;

  /* If no input is given, then return null */
  if (@LPN is null)
    return (null);

  /* Strip off -1 from TForce labels to add these cartons to the pallet */
  select @LPN = ltrim(rtrim(replace(@LPN, '-1', '')));

  /* HPI has old cartons which are numeric and 6 digits long, try first,
     else next statement assumes it an LPN Id. Even though this is specific
     to HPI, retaining this as we may encounter similar issue in future with
     other clients where we re-use their old LPN numbers */
  if (IsNumeric(@LPN) > 0) and (@vInputLen = 6)
    begin
      select @vLPNId = LPNId
      from LPNs
      where (LPN          = @LPN) and
            (BusinessUnit = @BusinessUnit);
    end

  /* If numeric and less than 8 digits, then try LPN Id */
  if (@vLPNId is null) and
     (IsNumeric(@LPN) > 0) and (@vInputLen <= 8) and
     (charindex('I', @vOptions) > 0)
    begin
      select @vLPNId = LPNId
      from LPNs
      where (LPNId        = @LPN) and
            (BusinessUnit = @BusinessUnit);
    end

  /* If not numeric and len = 10 then it could be LPN, if len is 5 then it could be cart position */
  /* May have to use control vars to get these lengths */
  if (@vLPNId is null) and
     (IsNumeric(@LPN) = 0) and
     (@vInputLen in (10 /* LPN */, 5 /* Cart Position */)) and
     (charindex('L', @vOptions) > 0)
    begin
      select @vLPNId = LPNId
      from LPNs
      where (LPN          = @LPN) and
            (BusinessUnit = @BusinessUnit);

      select @vLPNCheck = 'Y' /* checked for LPN */
    end

  /* Check if it is an ASN case */
  if (@vLPNId is null) and
     (charindex('A' /* ASN Case */, @vOptions) > 0)
    select @vLPNId = LPNId
    from LPNs
    where (ASNCase      = @LPN         ) and
          (BusinessUnit = @BusinessUnit);

  /* UCCBarcode is numeric and either 14 or 20 digits in length - so try that */
  if (@vLPNId is null) and
     (IsNumeric(@LPN) > 0) and
     (@vInputLen in (14, 20 /* UCCBarcode */)) and
     (charindex('U', @vOptions) > 0)
    select @vLPNId = LPNId
    from LPNs
    where (UCCBarcode   = @LPN         ) and
          (BusinessUnit = @BusinessUnit);

  /* Try Tracking no otherwise - UPS Tracking nos always start with 1Z..
     we will have to expand this logic to narrow down for other tracking nos */
  if (@vLPNId is null) and
     ((@LPN like '1Z%') or (@vInputLen > 10)) and
     (charindex('T', @vOptions) > 0)
    select @vLPNId = LPNId
    from LPNs
    where (TrackingNo   = @LPN         ) and
          (BusinessUnit = @BusinessUnit);

  /* FedEx tracking no > 22 */
  if (@vLPNId is null) and
     (@vInputLen > 22) and
     (charindex('T', @vOptions) > 0)
    select @vLPNId = LPNId
    from LPNs
    where (TrackingNo   = right(@LPN, 12)) and
          (BusinessUnit = @BusinessUnit);

  /* In case we have failed all options, then try LPN */
  if (@vLPNId is null) and
     (@vLPNCheck = 'N')
    select @vLPNId = LPNId
    from LPNs
    where (LPN          = @LPN) and
          (BusinessUnit = @BusinessUnit);

  return(@vLPNId);
end /* fn_LPNs_GetScannedLPN */

Go

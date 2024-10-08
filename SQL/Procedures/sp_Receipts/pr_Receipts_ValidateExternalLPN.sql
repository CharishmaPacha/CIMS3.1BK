/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2018/02/08  AY      pr_Receipts_ValidateExternalLPN: Enhance to match with pattern (S2G-224)
                      pr_Receipts_ReceiveExternalLPN & pr_Receipts_ValidateExternalLPN: Initial Revision (S2G-20)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Receipts_ValidateExternalLPN') is not null
  drop Procedure pr_Receipts_ValidateExternalLPN;
Go
/*------------------------------------------------------------------------------
  Proc pr_Receipts_ValidateExternalLPN: This procedure validates whether the
    scanned LPN is valid or not
------------------------------------------------------------------------------*/
Create Procedure pr_Receipts_ValidateExternalLPN
  (@XMLData          TXML,
   @LPN              TLPN,
   @BusinessUnit     TBusinessUnit,
   ----------------------------------
   @IsValidLPN       TFlags output)
as
  declare @vReturnCode        TInteger,
          @vMessageName       TMessageName,

          @vRuleSetId         TRecordId,
          @vControlCategory   TCategory,

          @vPrefix            TControlValue,
          @vLength            TControlValue,
          @vRange             TControlValue,
          @vPattern           TControlValue,

          @vRangeFrom         TInteger,
          @vRangeTo           TInteger;
begin
  SET NOCOUNT ON;

  set @IsValidLPN = 'N'/* No */;

  /* Evaluate rules and find out control category */
  exec pr_RuleSets_Evaluate 'ReceiveToLPN_Controls', @XMLData, @vControlCategory output;

  /* get control values to validate scanned LPN */
  select @vPrefix  = dbo.fn_Controls_GetAsString(@vControlCategory, 'Prefix',  '' /* Ignore */, @BusinessUnit, System_User),
         @vLength  = dbo.fn_Controls_GetAsString(@vControlCategory, 'Length',  '' /* Ignore */, @BusinessUnit, System_User),
         @vRange   = dbo.fn_Controls_GetAsString(@vControlCategory, 'Range',   '' /* Ignore */, @BusinessUnit, System_User),
         @vPattern = dbo.fn_Controls_GetAsString(@vControlCategory, 'Pattern', '' /* Ignore */, @BusinessUnit, System_User);

  /* Validate against the pattern, and if it doesn't match then exit */
  if (@vPattern <> '') and (PatIndex(@vPattern, @LPN) = 0)
    return;

  /* if Prefix is not empty then check whether LPN starts with that prefix or not,
     if not just return else continue with next validation */
  if (@vPrefix <> '') and (@LPN not like @vPrefix + '%')
    return;

  /* if Length is greater than 0 then check whether scanned LPN length is less than
     control value, if not just return else continue with next validation */
  if (coalesce(nullif(@vLength, ''), 0) <> 0) and (len(@LPN) > @vLength)
    return;

  /* If Range is specified then check whether the scanned LPN lies with the range or not,
     if not just return else continue with next validation if there is any */
  if (@vRange <> '')
    begin
      /* Range is a comma separated value (From, To), so extract from & to Ranges */
      if(charindex(',', @vRange) > 0)
        select @vRangeFrom = substring(@vRange, 1, charindex(',', @vRange) - 1),
               @vRangeTo   = substring(@vRange, charindex(',', @vRange) + 1, len(@vRange));
      else
        /* Range format is not correct then just return */
        return;

      /* Check if the scanned LPN is in Range or not */
      if (@LPN not between @vRangeFrom and @vRangeTo)
        return;
    end

  /* If we are here then all conditions would have been passed, so set validation flag to 'Yes' */
  set @IsValidLPN = 'Y'

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Receipts_ValidateExternalLPN */

Go

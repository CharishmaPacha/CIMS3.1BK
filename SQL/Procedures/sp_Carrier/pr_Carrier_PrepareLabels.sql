/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Carrier_PrepareLabels') is not null
  drop Procedure pr_Carrier_PrepareLabels;
Go
/*------------------------------------------------------------------------------
  Proc pr_Carrier_PrepareLabels: Labels are received from the carrier as binary
    data and these need to be converted. This procedure loops thru #PackageLabels
    and prepares them to be saved into ShipLabels

  #PackageLabels: TPackageLabels
------------------------------------------------------------------------------*/
Create Procedure pr_Carrier_PrepareLabels
  (@BusinessUnit         TBusinessUnit,
   @UserId               TUserId)
as
  declare @vReturnCode            TInteger,
          @vMessageName           TMessageName,
          @vRecordId              TRecordId,

          @vLabelImageType        TTypeCode,
          @vLabelRotation         TDescription,
          @vLabelType             TTypeCode,
          @vLabelImage            TVarchar,
          @vZPLLabel              TVarchar,
          @vRotatedLabelImage     TVarchar,
          @vStuffZPL              TControlValue,
          @vCarrier               TCarrier,

          @vLPNId                 TRecordId,
          @vLPN                   TLPN;

begin /* pr_Carrier_PrepareLabels */
  SET NOCOUNT ON;

  /* Initialize */
  select @vReturnCode   = 0,
         @vMessageName  = null,
         @vRecordid     = 0;

  /* Get the control to clear unwanted stuff from ZPL */
  select @vStuffZPL  = dbo.fn_Controls_GetAsString('ShipLabels', 'StuffAdditionalInfoOnZPL', 'N', @BusinessUnit, null /* UserId */);

  while (exists (select * from #PackageLabels where RecordId > @vRecordId))
    begin
      select top 1
             @vRecordId       = RecordId,
             @vLabelImageType = LabelImageType,
             @vLabelRotation  = LabelRotation,
             @vLabelImage     = LabelImage,
             @vCarrier        = Carrier
      from #PackageLabels
      where (RecordId > @vRecordId);

      /* For other than ZPL image type like png, gif rotate based upon the label rotation if required by using CLR method */
      if (@vLabelImageType <> 'ZPL')
        begin
          if (coalesce(@vLabelRotation, '') <> '')
            exec pr_CLR_RotateBase64Image @vLabelImage, @vLabelRotation, @vRotatedLabelImage out;

          /* Update #PackageLabels with the rotated image */
          update #PackageLabels
          set RotatedLabelImage = dbo.fn_Base64ToBinary(coalesce(@vRotatedLabelImage, @vLabelImage))
          where (RecordId = @vRecordId);
        end
      else
      if (@vLabelImageType = 'ZPL' /* ZPL Label */)
        begin
          select @vZPLLabel = @vLabelImage;

          /* Stuff some additional information on the ZPL label */
          if ((@vZPLLabel is not null) and (@vStuffZPL = 'Y'/* Yes */))
            exec pr_ShipLabel_CustomizeZPL @vLPN, @vCarrier, @vZPLLabel, @BusinessUnit, @UserId, @vZPLLabel output;

          /* For some reason, ZPL labels are inverted, so correct it */
          select @vZPLLabel = dbo.fn_Base64ToVarchar(@vZPLLabel)
          select @vZPLLabel = replace(@vZPLLabel, '^POI', '^PON');

          /* Update #PackageLabels with the rotated image */
          update #PackageLabels
          set ZPLLabel = coalesce(@vZPLLabel, @vLabelImage)
          where (RecordId = @vRecordId);
        end
    end /* while */

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Carrier_PrepareLabels */

Go

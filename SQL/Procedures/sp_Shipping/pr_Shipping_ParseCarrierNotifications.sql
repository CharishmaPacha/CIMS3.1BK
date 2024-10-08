/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Shipping_ParseCarrierNotifications') is not null
  drop Procedure pr_Shipping_ParseCarrierNotifications ;
Go
/*------------------------------------------------------------------------------
  Proc pr_Shipping_ParseCarrierNotifications : To return the UPS and FEDEX Error message
   split into Notifications, NotificationSource and NotificationTrace
------------------------------------------------------------------------------*/
Create Procedure pr_Shipping_ParseCarrierNotifications
  (@RecordId              TRecordId     = null,
   @CarrierNotifications  TVarchar      = null,
   @Carrier               TCarrier      = null,
   @ShipVia               TShipVia      = null,
   @CarrierInterface      TControlValue = null,
   @Notifications         TVarchar output,
   @NotificationSource    TVarchar output,
   @NotificationTrace     TVarchar output
  )
as
  declare @vReturnCode        TInteger,
          @vMessageName       TMessageName,
          @vRecordId          TRecordId,
          @vStartPosition     TRecordId,
          @vEndPosition       TRecordId,
          @vTracePosition     TRecordId,
          @vSourceStartIndex  TInteger,
          @vTraceStartIndex   TInteger;

begin
  SET NOCOUNT ON;

  select @vReturnCode        = 0,
         @vMessageName       = null,
         @vRecordId          = 0,
         @NotificationSource = @CarrierNotifications;

  if (@RecordId is not null)
    select @Carrier              = Carrier,
           @ShipVia              = ShipVia,
           @CarrierNotifications = Notifications
    from ShipLabels
    where RecordId = @RecordId;

  /* If there is no Error, then exit */
  if (charindex('Error', @CarrierNotifications) = 0)
    return(0);

  if (@Carrier = 'UPS' or @ShipVia like 'UPS%')
    begin
      /* Get the Indexes for Source and StackTrace */
      select @vSourceStartIndex = charindex('Source:', @CarrierNotifications),
             @vTraceStartIndex  = charindex('StackTrace:', @CarrierNotifications);

      /* Check Whether Notification have Strings like Error, Source and StackTrace */
      /* Split the Notification with respect to Error , Source and StackTrace */
      if (charindex('Error:', @CarrierNotifications) > 0 and @vSourceStartIndex > 0 and @vTraceStartIndex > 0)
        select @NotificationSource = substring(@CarrierNotifications, @vSourceStartIndex, @vTraceStartIndex-@vSourceStartIndex),
               @NotificationTrace  = substring(@CarrierNotifications, @vTraceStartIndex, len(@CarrierNotifications)),
               @Notifications      = substring(@CarrierNotifications, 1, @vSourceStartIndex-1);
       else
         select @Notifications = @CarrierNotifications;

      /* Eliminate the HardError */
      select @vStartPosition = charindex('Hard', @Notifications)
      select @vEndPosition   = charindex(']', @Notifications, 1);
      select @Notifications  = substring(@Notifications, @vEndPosition + 1, len(@Notifications))
    end
  else
  if (@Carrier = 'FEDEX' or @ShipVia like '%FEDX%')
    begin
      select @vStartPosition = charindex('Message:', @CarrierNotifications)
      select @vEndPosition   = charindex('Source:', @CarrierNotifications)
      select @vTracePosition = charindex('ERROR Notification no.:', @CarrierNotifications)

      if (charindex('Error', @CarrierNotifications) > 0)
        begin
          select @Notifications      = substring(@CarrierNotifications, @vStartPosition, (@vEndPosition-@vStartPosition));
          select @NotificationTrace  = substring(@CarrierNotifications, @vTracePosition, @vStartPosition-1);
          select @NotificationSource = substring(@CarrierNotifications, @vEndPosition, (len(@CarrierNotifications)-@vEndPosition)+1);
        end
      else
        begin
          select @NotificationSource = @CarrierNotifications,
                 @Notifications      = null;
        end

      select @Notifications = replace(@Notifications, 'Message:', 'Error:');
    end

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Shipping_ParseCarrierNotifications  */

Go

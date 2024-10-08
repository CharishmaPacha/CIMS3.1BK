/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2016/09/13  PSK     pr_ShipLabel_GetLPNData:
                        Added new function fn_ShipLabel_GetNotification
                        Made changes to return the weight and shipping notification (HPI-642)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.fn_ShipLabel_GetNotification') is not null
  drop Function fn_ShipLabel_GetNotification;
Go
/*------------------------------------------------------------------------------
  Function fn_ShipLabel_GetNotification: Returns the ship Notifications
------------------------------------------------------------------------------*/
Create Function fn_ShipLabel_GetNotification
  (@LPN    TLPN)
  -----------------
  returns  TVarChar
as
begin
  declare @vShipNotifications TVarChar;

  /* Get ShipNotifications */
  select @vShipNotifications = Notifications
  from  ShipLabels
  where (EntityKey = @LPN);

  return @vShipNotifications;
end /* fn_ShipLabel_GetNotification */

Go

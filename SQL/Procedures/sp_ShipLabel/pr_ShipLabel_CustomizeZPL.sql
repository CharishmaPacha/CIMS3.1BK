/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2018/06/06  PK      Remaned pr_ShipLabel_SetLPNData as pr_ShipLabel_GetPrintDataStream and changed the parameters and added a output parameter to send
                        the PrintDataStream (S2G-921).
                      Added pr_ShipLabel_CustomizeZPL (S2G-921)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_ShipLabel_CustomizeZPL') is not null
  drop Procedure pr_ShipLabel_CustomizeZPL;
Go
/*------------------------------------------------------------------------------
  Proc pr_ShipLabel_CustomizeZPL:
  This procedure will take the label data stream and customize it by adding
  some additional information to it and return as a output.
------------------------------------------------------------------------------*/
Create Procedure pr_ShipLabel_CustomizeZPL
  (@LPN              TLPN,
   @Carrier          TCarrier,
   @DataStream       TVarchar,
   @BusinessUnit     TBusinessUnit,
   @UserId           TUserId,
   @ResultDataStream TVarchar output)
as
  declare @vCharIndex       TInteger,
          @vPrintDataStream TVarChar,
          @vLabelFormatName TName;

begin
  /* Get the LabelFormatName to stuff the ZPL Labels */
  select @vLabelFormatName = case when @Carrier = 'UPS' then 'ShipLabel_UPS'
                                  when @Carrier = 'FEDEX' then 'ShipLabel_FEDEX'
                                  else null
                             end;

  /* Get the PrintDataStream to stuff in the ZPL label */
  exec pr_ShipLabel_GetPrintDataStream @LPN, @vLabelFormatName, @BusinessUnit, @vPrintDataStream output;

  /* Get the ZPL end value charater index to stuff the additional info */
  select @vCharIndex = charindex('^XZ', @DataStream);

  /* Update the ZPL label with the gathered information */
  select @ResultDataStream = stuff(@DataStream, @vCharIndex, 0, @vPrintDataStream);

end /* pr_ShipLabel_CustomizeZPL */

Go

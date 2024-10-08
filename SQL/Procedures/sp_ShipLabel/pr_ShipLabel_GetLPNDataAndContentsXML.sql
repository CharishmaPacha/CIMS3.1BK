/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2016/06/28  DK      Added new procedure pr_ShipLabel_GetLPNDataAndContentsXML
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_ShipLabel_GetLPNDataAndContentsXML') is not null
  drop Procedure pr_ShipLabel_GetLPNDataAndContentsXML;
Go
/*------------------------------------------------------------------------------
  Proc pr_ShipLabel_GetLPNDataAndContentsXML: Returns the data set to be used to print a UCC Label.

  This procedure is called from Bartender labels.

  @LPNs xml structure:
  <Root>
    <LPNs>
      <LPN> </LPN>
      <LPN> </LPN>
    </LPNs>
  </Root>
------------------------------------------------------------------------------*/
Create Procedure pr_ShipLabel_GetLPNDataAndContentsXML
  (@LPNs             XML           = null,
   @LPN              TLPN          = null,
   @LPNId            TRecordId     = null,
   @Operation        TOperation    = null,
   @BusinessUnit     TBusinessUnit = null,
   @LabelFormatName  TName         = null)
as
  declare @vReturnCode          TInteger,
          @vMessageName         TMessageName,
          @vUserId              TUserId;

begin
  set NOCOUNT ON;
  select @vReturnCode   = 0,
         @vMessagename  = null,
         @vUserId       = System_User;

  /* If LabelFormatName is not specified, then get from XML */
  if (@LabelFormatName is null)
    select @LabelFormatName = Record.Col.value('LabelFormatName[1]',   'TName')
    from @LPNs.nodes('Root') as Record(Col);

  exec pr_ShipLabel_GetLPNDataAndContents @LPN, @LPNId, @Operation, @BusinessUnit, @LabelFormatName, @LPNs;

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_ShipLabel_GetLPNDataAndContentsXML */

Go

/*------------------------------------------------------------------------------
Proc pr_ShipLabel_GetLPNDataXML: Procedures takes as input a list of LPNs as
  XML and returns a dataset with the ShipLabelData for each of those LPNs

InputXML:
<root>
  <EntityKey></EntityKey>
</root>
------------------------------------------------------------------------------*/

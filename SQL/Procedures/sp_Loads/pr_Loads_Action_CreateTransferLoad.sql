/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/04/19  AY      pr_Loads_Action_CreateTransferLoad: Changes w/ additional validations (HA GoLive)
  2021/04/07  KBB/TK  pr_Loads_Action_CreateTransferLoad: Added the Validation while Creating Transfer Lods with Shiptoid desc (HA-2551)
                      pr_Loads_Action_CreateTransferLoad: Initial Revision (HA-830)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Loads_Action_CreateTransferLoad') is not null
  drop Procedure pr_Loads_Action_CreateTransferLoad;
Go
/*------------------------------------------------------------------------------
  Proc pr_Loads_Action_CreateTransferLoad: Creates a load that is used for transfers

    The main inputs for Transfers load is ShipVia, ShipFrom & ShipTo
------------------------------------------------------------------------------*/
Create Procedure pr_Loads_Action_CreateTransferLoad
  (@EntityXML       xml,
   @BusinessUnit    TBusinessUnit,
   @UserId          TUserId,
   @ResultXML       TXML = null output)
as
  declare @vReturnCode                TInteger,
          @vMessageName               TMessageName,
          @vMessage                   TMessage,

          @vLoadId                    TRecordId,
          @vLoadNumber                TLoadNumber,
          @vLoadType                  TLookUpCode,
          @vShipFrom                  TShipFrom,
          @vShipToId                  TShipToId,
          @vValidShipToId             TShipToId,
          @vShipVia                   TShipVia,
          @vDesiredShipDate           TDate,
          @vDockLocation              TLocation;
begin
  SET NOCOUNT ON;

  /* Initialize */
  select @vReturnCode  = 0,
         @vMessageName = null;

  /* Read inputs from XML */
  select @vLoadType        = Record.Col.value('LoadType[1]',     'TLookUpCode'),
         @vShipFrom        = Record.Col.value('ShipFrom[1]',     'TShipFrom'),
         @vShipToId        = Record.Col.value('ShipToId[1]',     'TShipToId'),
         @vShipVia         = Record.Col.value('ShipVia[1]',      'TShipVia'),
         @vDockLocation    = Record.Col.value('DockLocation[1]', 'TLocation'),
         @vDesiredShipDate = cast(getdate() as date)
  from @EntityXML.nodes('/Root/Data') as Record(Col);

  select @vValidShipToId = LookUpCode
  from vwLookUps
  where (LookUpCode     = @vShipToId) and
        (LookUpCategory = 'Warehouse') and
        (BusinessUnit   = @BusinessUnit);

  /* There are chances that user is keying in look up display description so get look up code in that case */
  if (@vValidShipToId is null)
    select @vValidShipToId = LookUpCode
    from vwLookUps
    where (LookUpDisplayDescription = @vShipToId) and
          (LookUpCategory           = 'Warehouse') and
          (BusinessUnit             = @BusinessUnit);

  /* Validations */
  if (@vShipFrom = @vShipToId)
    set @vMessageName = 'CreateTransferLoad_ShipFromShipToCannotBeSame';
  else
  if (coalesce(@vShipFrom, '') = '')
    set @vMessageName ='CreateTransferLoad_ShipFromIsRequired';
  else
  if (coalesce(@vShipToId, '') = '')
    set @vMessageName ='CreateTransferLoad_ShipToIsRequired';
  else
  if (@vValidShipToId is null)
    set @vMessageName = 'CreateTransferLoad_InvalidShipToId';

  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

  /* Invoke procedure that creates new load  - default ship date to today */
  exec pr_Load_CreateNew @UserId = @UserId, @BusinessUnit = @BusinessUnit,
                         @LoadType = @vLoadType, @ShipVia = @vShipVia, @ShipFrom = @vShipFrom,
                         @DesiredShipDate = @vDesiredShipDate,
                         @FromWarehouse = @vShipFrom, @ShipToId = @vValidShipToId, @DockLocation = @vDockLocation,
                         @LoadId = @vLoadId out, @LoadNumber = @vLoadNumber out, @Message = @vMessage out;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Loads_Action_CreateTransferLoad */

Go

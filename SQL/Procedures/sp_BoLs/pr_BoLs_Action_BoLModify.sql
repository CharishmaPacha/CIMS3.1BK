/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_BoLs_Action_BoLModify') is not null
  drop Procedure pr_BoLs_Action_BoLModify;
Go
/*------------------------------------------------------------------------------
  Proc pr_BoLs_Action_BoLModify:
------------------------------------------------------------------------------*/
Create Procedure pr_BoLs_Action_BoLModify
  (@xmlData       xml,
   @BusinessUnit  TBusinessUnit,
   @UserId        TUserId,
   @ResultXML     TXML           = null output)
as
  /* Declare local variables */
  declare @vReturnCode                TInteger,
          @vMessageName               TMessageName,
          @vRecordId                  TRecordId,
          @vEntity                    TEntity,
          @vAction                    TAction,

          @vBoLId                     TRecordId,
          @vBoLNumber                 TBoLNumber,
          @vFoB                       TFlags,
          @vBoLCID                    TBoLCID,
          @vSealNumber                TSealNumber,
          @vProNumber                 TProNumber,
          @vTrailerNumber             TTrailerNumber,
          @vShipToLocation            TShipToLocation,
          @vBillToAddressId           TContactRefId,
          @vShipToAddressId           TContactRefId,
          @vBoLInstructions           TVarchar,
          @vFreightTerms              TLookUpCode,

          @vRecordsUpdated            TCount,
          @vTotalRecords              TCount,
          @vMessage                   TXML;
begin /* pr_BoLs_Action_BoLModify */
  SET NOCOUNT ON;

  select @vReturnCode     = 0,
         @vMessage        = null,
         @vRecordId       = 0;

  select @vBoLId                   = Record.Col.value('BoLId[1]',            'TRecordId'),
         @vBoLNumber               = Record.Col.value('BolNumber[1]',       'TBoLNumber'),
         @vShipToLocation          = Record.Col.value('ShipToLocation[1]',  'TShipToLocation'),
         @vFoB                     = Record.Col.value('FoB[1]',             'TFlags'),
         @vBoLCID                  = Record.Col.value('BoLCID[1]',          'TBoLCID'),
         @vTrailerNumber           = Record.Col.value('TrailerNumber[1]',   'TTrailerNumber'),
         @vSealNumber              = Record.Col.value('SealNumber[1]',      'TSealNumber'),
         @vProNumber               = Record.Col.value('ProNumber[1]',       'TProNumber'),
         @vBoLInstructions         = Record.Col.value('BoLInstructions[1]', 'TVarchar'),
         @vFreightTerms            = Record.Col.value('FreightTerms[1]',    'TLookUpCode'),
         @vShipToAddressId         = Record.Col.value('ShipToAddressId[1]', 'TContactRefId'),
         @vBillToAddressId         = Record.Col.value('BillToAddressId[1]', 'TContactRefId')
  from @xmlData.nodes('/Root/Data') as Record(Col)
  OPTION ( OPTIMIZE FOR ( @xmlData = null ) );

  /*  Call the Proc to do the updates */
  exec pr_BoL_UpdateBoL @vBoLId, @vBoLNumber, @vTrailerNumber, @vSeaLNumber, @vProNumber, null /* ShipVia */, @vBillToAddressId,
                        @vShipToAddressId, @vFreightTerms , @vShipToLocation, @vFoB, @vBoLCID , @vBoLInstructions ,@vMessage output;

  /* Return Result Message */
  insert into #ResultMessages (MessageType, MessageName) select 'I', @vMessage;

  return(coalesce(@vReturnCode, 0));
end /* pr_BoLs_Action_BoLModify */

Go

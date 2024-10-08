/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_BoLs_Action_BoLOrderDetailsModify') is not null
  drop Procedure pr_BoLs_Action_BoLOrderDetailsModify;
Go
/*------------------------------------------------------------------------------
  Proc pr_BoL_Action_BoLOrderDetailsModify:
------------------------------------------------------------------------------*/
Create Procedure pr_BoLs_Action_BoLOrderDetailsModify
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

          @vBoLOrderDetailId          TRecordId,
          @vBoLNumber                 TBoLNumber,
          @vCustomerOrderNo           TCustPO,
          @vNumPackages               TCount,
          @vWeight                    TWeight,
          @vPalletized                TFlag,
          @vShipperInfo               TDescription,

          @vRecordsUpdated            TCount,
          @vTotalRecords              TCount,
          @vMessage                   TXML;
begin /* pr_BoLs_Action_BoLOrderDetailsModify */
  SET NOCOUNT ON;

  select @vReturnCode     = 0,
         @vMessage        = null,
         @vRecordId       = 0;

  select @vBoLOrderDetailId  = Record.Col.value('BoLOrderDetailId[1]', 'TRecordId'),
         @vBoLNumber         = Record.Col.value('BolNumber[1]',        'TBoLNumber'),
         @vNumPackages       = Record.Col.value('NumPackages[1]',      'TCount'),
         @vWeight            = Record.Col.value('Weight[1]',           'TWeight'),
         @vPalletized        = Record.Col.value('Palletized[1]',       'TFlag'),
         @vShipperInfo       = Record.Col.value('ShipperInfo[1]',      'TDescription')
  from @xmlData.nodes('/Root/Data') as Record(Col)
  OPTION ( OPTIMIZE FOR ( @xmlData = null ) );

  /* Call the Proc to do the updates */
  exec pr_BoLOrderDetails_Update @vBoLOrderDetailId, @vBoLNumber,
                                 @NumLPNs     = @vNumPackages,
                                 @Weight      = @vWeight,
                                 @Palletized  = @vPalletized,
                                 @ShipperInfo = @vShipperInfo,
                                 @Message     = @vMessage output;

  /* Return Result Message */
  insert into #ResultMessages (MessageType, MessageName) select 'I', @vMessage;

  return(coalesce(@vReturnCode, 0));
end /* pr_BoLs_Action_BoLOrderDetailsModify */

Go

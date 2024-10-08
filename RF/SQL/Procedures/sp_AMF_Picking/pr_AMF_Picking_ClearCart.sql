/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2019/06/17  RIA     Added : pr_AMF_Picking_ClearCart (CID-591)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_AMF_Picking_ClearCart') is not null
  drop Procedure pr_AMF_Picking_ClearCart;
Go
/*------------------------------------------------------------------------------
  Procedure pr_AMF_Picking_ClearCart:

  Processes the requests for Clear Cart work flow
------------------------------------------------------------------------------*/
Create Procedure pr_AMF_Picking_ClearCart
  (@InputXML     TXML,
   @DataXML      TXML output,
   @UIInfoXML    TXML output,
   @InfoXML      TXML output,
   @ErrorXML     TXML output)
as
  declare @vInputXML               xml,
          @vrfcProcInputxml        xml,
          @vrfcProcOutputxml       xml,
          @vPalletDetails          xml,
          @vTaskInfoxml            xml,
          @vSuccessMessage         TMessage,
          @vPalletId               TRecordId,
          @vPallet                 TPallet,
          @vUserId                 TUserId,
          @vBusinessUnit           TBusinessUnit,
          @vMessage                TMessage,
          @vTaskId                 TRecordId,
          @vActivityLogId          TRecordId,
          @vTransactionFailed      TBoolean;

  declare @ttPallets               TEntityKeysTable;
begin /* pr_AMF_Picking_ClearCart */

  select @vInputXML = convert(xml, @InputXML);

  /* Initialize */
  select @DataXML   = convert(varchar(max), @vInputXML.query('Root/Data')),
         @UIInfoXML = convert(varchar(max), @vInputXML.query('Root/UIInfo')),
         @ErrorXML  = null,
         @InfoXML   = null;

  select @vPallet        = Record.Col.value('(Data/Pallet)[1]',                     'TPallet'      ),
         @vUserId        = Record.Col.value('(SessionInfo/UserName)[1]',            'TUserId'      ),
         @vBusinessUnit  = Record.Col.value('(SessionInfo/BusinessUnit)[1]',        'TBusinessUnit')
  from @vInputXML.nodes('/Root') as Record(Col);

  /* Insert values into temp table to call V2 proc */
  insert into @ttPallets (EntityId, EntityKey)
    select PalletId, Pallet
    from Pallets
    where (Pallet = @vPallet) and (BusinessUnit = @vBusinessUnit);

  /* Execute V2 procedure */
  exec pr_Pallets_ClearCart @ttPallets, @vUserId, @vBusinessUnit, @vMessage output;

  if(@vMessage like '%Successful%')
    begin
      select @vMessage = dbo.fn_Messages_Build('AMF_ClearCart_Successful', @vPallet, null, null, null, null);
      select @InfoXML = dbo.fn_AMF_BuildSuccessXML(@vMessage);
    end
  else
  if(@vMessage like '%NoneUpdated%')
    begin
      select @vMessage = dbo.fn_Messages_Build('AMF_ClearCart_NotCleared', @vPallet, null, null, null, null);
      select @vrfcProcOutputxml = '<ERRORDETAILS><ERRORINFO>' +
                                     dbo.fn_XMLNode('ErrorMessage',  @vMessage) +
                                  '</ERRORINFO></ERRORDETAILS>'
                                  ;

      select @ErrorXML  = dbo.fn_AMF_BuildErrorXML(@vrfcProcOutputxml);
    end

end /* pr_AMF_Picking_ClearCart */

Go


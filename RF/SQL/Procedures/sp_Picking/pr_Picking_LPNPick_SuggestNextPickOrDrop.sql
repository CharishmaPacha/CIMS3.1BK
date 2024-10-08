/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Picking_LPNPick_SuggestNextPickOrDrop') is not null
  drop Procedure pr_Picking_LPNPick_SuggestNextPickOrDrop;
Go
/*------------------------------------------------------------------------------
  Procedure pr_Picking_LPNPick_SuggestNextPickOrDrop:

  Processes the requests to suggest drop location
------------------------------------------------------------------------------*/
Create Procedure pr_Picking_LPNPick_SuggestNextPickOrDrop
  (@xmlInput          xml,
   @xmlRFCProcOutput  xml,
   @RFFormAction      TMessageName  = null,
   @DataXML           TXML output,
   @UIInfoXML         TXML output,
   @InfoXML           TXML output,
   @ErrorXML          TXML output)
as
          /* Standard variables */
  declare @vReturnCode               TInteger,
          @vMessage                  TMessage,
          @vMessageName              TMessageName,
          @vSuccessMessage           TMessage,
          @vxmlInput                 xml,
          @vxmlOutput                xml,
          @vxmlRFCProcInput          xml,
          @vxmlRFCProcOutput         xml,
          @vrfcProcInputxml          TXML,
          @vrfcProcOutputxml         TXML,
          @vTransactionFailed        TBoolean,
          /* Input variables */
          @vBusinessUnit             TBusinessUnit,
          @vUserId                   TUserId,
          @vDeviceId                 TDeviceId,
          @vErrorMessage             TMessage,
          @vErrorNumber              TMessage;
          /* Functional variables */
  declare @vDataXML                  TXML,
          @vTaskInfoXML              TXML,
          @vPalletInfoXML            TXML,
          @vOutstandingPicksxml      TXML,
          @vxmlOutstandingPicks      xml,
          /* Pallet */
          @vPalletId                 TRecordId,
          @vxmlPalletDetails         xml,
          @vPalletToDrop             TPallet,
          @vPalletUnitsPicked        TInteger,
          @vNextPickFromLocation     TLocation,
          @vNextLPNToPick            TLPN,
          /* Task */
          @vTaskId                   TRecordId,
          @vActivityLogId            TRecordId;
begin /* pr_Picking_LPNPick_SuggestNextPickOrDrop */

  /* Initialize */
  select @vPalletToDrop = null;

  /* Verify whether the task pick is completed, and there are no more picks left */
  if (coalesce(@RFFormAction, '') <> 'PAUSEPICKING')
    select @vNextPickFromLocation  = Record.Col.value('Location[1]',     'TLocation'),
           @vNextLPNToPick         = Record.Col.value('LPN[1]',          'TLPN'),
           @vErrorNumber           = Record.Col.value('ErrorNumber[1]',  'TMessage'),
           @vErrorMessage          = Record.Col.value('ErrorMessage[1]', 'TMessage')
    from @xmlRFCProcOutput.nodes('/BATCHPICKDETAILS/BATCHPICKINFO')  as Record(Col)
    OPTION (OPTIMIZE FOR (@xmlRFCProcOutput = null));

  /* If PausePicking we are going to drop anyway, otherwise, if there is a no next pick
     then suggest drop of Pallet */
  if (@RFFormAction = 'PAUSEPICKING') or
     ((coalesce(@vNextPickFromLocation, '') = '') and (coalesce(@vNextLPNToPick, '') = ''))
    begin
      select @vErrorNumber = null, @vErrorMessage = null; -- reset vars as their purpose for this validation is over
      select @vxmlRFCProcInput = (select Record.Col.value('(SessionInfo/DeviceId)[1]',             'TDeviceId'    ) as DeviceId,
                                         Record.Col.value('(SessionInfo/UserName)[1]',             'TUserId'      ) as UserId,
                                         Record.Col.value('(SessionInfo/BusinessUnit)[1]',         'TBusinessUnit') as BusinessUnit,
                                         'DropPallet'                                                               as Operation,
                                         Record.Col.value('(Data/m_LPNPickInfo_PickToPallet)[1]',  'TPallet'      ) as Pallet,
                                         Record.Col.value('(Data/m_LPNPickInfo_TaskId)[1]',        'TRecordId'    ) as TaskId
                                  from @xmlInput.nodes('/Root') as Record(Col)
                                  for xml raw('DropPalletInfo'), elements);

       /* Build the xml in the format expected by the ValidatePallet procedure */
       select @vxmlRFCProcInput = convert(xml, dbo.fn_XMLNode('ValidateDropPallet', convert(varchar(max), @vxmlRFCProcInput)));

       exec pr_RFC_Picking_ValidatePallet @vxmlRFCProcInput, @vxmlRFCProcOutput output;

       exec pr_AMF_EvaluateExecResult @vxmlRFCProcOutput, @vTransactionFailed output,
                                      @ErrorXML output, @DataXML output;

       if (@vTransactionFailed <= 0)
         begin
           /* Read PalletId from response, to ascertain response returned has drop pallet detail */
           select @vPalletToDrop = Record.Col.value('(Pallet)[1]',  'TPallet'),
                  @vTaskId       = Record.Col.value('(TaskId)[1]',  'TRecordId')
           from @vxmlRFCProcOutput.nodes('/ValidateDropPallet/DropPalletResponse') as Record(Col)
           OPTION (OPTIMIZE FOR (@vxmlRFCProcOutput = null));

           /* Get Task info to fill the form */
           exec pr_AMF_Info_GetTaskInfoXML @vTaskId, 'PalletToDrop', @vTaskInfoXML output;

           /* Get PalletDetails as XML from vwPallets for the Input Pallet */
           with PalletCounts
           as
           (
             select Min(SKU) PalletSKU, Min(SKUDescription) PalletSKUDescription, count(distinct SKUId) SKUCount, count(distinct LPNId) LPNCount,
             sum(Quantity) TotalQty, count(distinct OrderId) OrderCount
             from vwLPNDetails where PalletId in (select PalletId from Pallets where Pallet = @vPalletToDrop)
           )
           select @vxmlPalletDetails = (select case when SKUCount > 1 then 'Multiple' else PalletSKU end as SKU,
                                        case when SKUCount > 1 then 'Multiple' else PalletSKUDescription end as SKUDescription,
                                        *
                                        from PalletCounts for xml raw('PalletDetails'), Elements);

           select @vDataXML = '';
           with ResponseDetails as
           (
             select dbo.fn_XMLNode('DROPPALLETRESPONSE' + c.value('(local-name(.))[1]', 'nvarchar(max)'), replace(c.value('(.)[1]', 'nvarchar(max)'), '''', '''''')) ResponseDetail
             from @vxmlRFCProcOutput.nodes('/ValidateDropPallet/DropPalletResponse/*') as t(c)
             union
             select dbo.fn_XMLNode('PALLETDETAILS' + c.value('(local-name(.))[1]', 'nvarchar(max)'), replace(c.value('(.)[1]', 'nvarchar(max)'), '''', '''''')) ResponseDetail
             from @vxmlPalletDetails.nodes('/PalletDetails/*') as t(c)
           )
           select @vDataXML = @vDataXML + ResponseDetail from ResponseDetails;

           exec pr_AMF_Info_GetOutstandingPicks @vTaskId, @vOutstandingPicksxml output, @vxmlOutstandingPicks output;

           select @DataXML = dbo.fn_XmlNode('Data', @vDataXML + coalesce(@vTaskInfoXML, '') + coalesce(@vOutstandingPicksxml, ''));
         end
    end
  else
    /* If we are here, then it isn't a Pause and there is another LPN to Pick.
       Convert V2 Response to AMF Format */
    exec pr_Picking_LPNPick_BuildNextPickResponse @xmlRFCProcOutput, @DataXML output;

end /* pr_Picking_LPNPick_SuggestNextPickOrDrop */

Go


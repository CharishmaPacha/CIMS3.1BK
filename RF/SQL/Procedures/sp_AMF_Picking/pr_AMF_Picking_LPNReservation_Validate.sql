/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/04/22  RIA     pr_AMF_Picking_LPNReservation_Validate: Control to prompt Pallet (HA-2684)
  2020/12/22  TK      pr_AMF_Picking_LPNReservation_ValidateLPN: Changes to reserve a partially allocate LPN (HA-1821)
  pr_AMF_Picking_LPNReservation_ValidateLPN: Changes to retrieve filter value (HA-1263)
  2020/06/29  RIA     pr_AMF_Picking_LPNReservation_ValidateLPN: Changes to use table instead of view (HA-789)
  pr_AMF_Picking_LPNReservation_Validate, pr_AMF_Picking_LPNReservation_ValidateLPN: Code Refactoring (HA-789)
  2020/06/21  TK      pr_AMF_Picking_LPNReservation_Validate, pr_AMF_Picking_LPNReservation_ValidateLPN &
  pr_AMF_Picking_LPNReservation_ValidateLPN: Validate Pallet and return it to screen (HA-789)
  2020/05/27  RIA     Changes to pr_AMF_Picking_LPNReservation_Confirm, pr_AMF_Picking_LPNReservation_ValidateLPN (HA-521)
  2020/05/25  RIA     Added: pr_AMF_Picking_LPNReservation_ValidateLPN (HA-521)
  2020/05/23  SK      pr_AMF_Picking_LPNReservation_Validate, pr_AMF_Picking_LPNReservation_Confirm:
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_AMF_Picking_LPNReservation_Validate') is not null
  drop Procedure pr_AMF_Picking_LPNReservation_Validate;
Go
/*------------------------------------------------------------------------------
  Procedure pr_AMF_Picking_LPNReservation_Validate: Validates the Wave or PickTicket scanned
    and returns the details of available inventory that can be reserved and later picked
------------------------------------------------------------------------------*/
Create Procedure pr_AMF_Picking_LPNReservation_Validate
  (@InputXML     TXML,
   @DataXML      TXML output,
   @UIInfoXML    TXML output,
   @InfoXML      TXML output,
   @ErrorXML     TXML output)
as
          /* Standard variables */
  declare @vReturnCode               TInteger,
          @vMessageName              TMessageName,
          @vxmlInput                 xml,
          @vxmlRFCProcInput          xml,
          @vxmlRFCProcOutput         xml,
          @vrfcProcInputxml          TXML,
          @vrfcProcOutputxml         TXML,
          @vTransactionFailed        TBoolean,
          /* Input variables */
          @vBusinessUnit              TBusinessUnit,
          @vUserId                    TUserId,
          @vDeviceId                  TDeviceId,
          /* Functional variables */
          @vPromptPallet             TFlags;
begin /* pr_AMF_Picking_LPNReservation_Validate */

  select @vxmlInput = convert(xml, @InputXML);  /* Convert input into xml var */

  /* Initialize */
  select @DataXML   = convert(varchar(max), @vxmlInput.query('Root/Data')),
         @UIInfoXML = convert(varchar(max), @vxmlInput.query('Root/UIInfo')),
         @ErrorXML  = null,
         @InfoXML   = null;

  /* Fetch the input values */
  select @vBusinessUnit    = Record.Col.value('(SessionInfo/BusinessUnit)[1]',                  'TBusinessUnit'),
         @vUserId          = Record.Col.value('(SessionInfo/UserName)[1]',                      'TUserId'      ),
         @vDeviceId        = Record.Col.value('(SessionInfo/DeviceId)[1]',                      'TDeviceId'    )
  from @vxmlInput.nodes('/Root') as Record(Col)
  OPTION ( OPTIMIZE FOR ( @vxmlInput = null ) );

  /* Build V2 Input Xml */
  select @vxmlRFCProcInput = (select Record.Col.value('(SessionInfo/BusinessUnit)[1]',   'TBusinessUnit') as BusinessUnit,
                                     Record.Col.value('(SessionInfo/UserName)[1]',       'TUserId'      ) as UserId,
                                     Record.Col.value('(SessionInfo/DeviceId)[1]',       'TDeviceId'    ) as DeviceId,
                                     Record.Col.value('(Data/WaveNo)[1]',                'TWaveNo'      ) as PickBatchNo,
                                     Record.Col.value('(Data/PickTicket)[1]',            'TPickTicket'  ) as PickTicket,
                                     Record.Col.value('(Data/Operation)[1]',             'TOperation'   ) as Operation,
                                     Record.Col.value('(Data/SelectedSKU)[1]',           'TSKU'         ) as SelectedSKU
                              from @vxmlInput.nodes('/Root') as Record(Col)
                              for xml raw('ConfirmLPNReservations'), elements);

  /* Validate Wave or PickTicket or both when given */
  exec pr_Reservation_ValidateWaveOrPickTicket @vxmlRFCProcInput, @vxmlRFCProcOutput output;

  /* Evaluate XML Result */
  exec pr_AMF_EvaluateExecResult @vxmlRFCProcOutput, @vTransactionFailed output,
                                 @ErrorXML output, @DataXML output;

  /* Build response in the required format to show in the screen */
  exec pr_AMF_Info_GetLPNReservationInfoXML @vxmlRFCProcOutput, null /* SKUId */, @DataXML output;

  /* Get the control to prompt pallet input for user */
  select @vPromptPallet = dbo.fn_Controls_GetAsBoolean('LPNReservation', 'PromptPallet', 'Y' /* Yes */, @vBusinessUnit, @vUserId)

  /* Add the node to DataXML, as we will be setting the focus based on this control */
  select @DataXML = dbo.fn_XMLAddNode(@DataXML, 'Data', dbo.fn_XMLNode('PromptPallet', @vPromptPallet));
end /* pr_AMF_Picking_LPNReservation_Validate */

Go


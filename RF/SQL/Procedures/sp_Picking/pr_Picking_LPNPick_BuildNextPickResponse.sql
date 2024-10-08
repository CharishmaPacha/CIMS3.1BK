/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Picking_LPNPick_BuildNextPickResponse') is not null
  drop Procedure pr_Picking_LPNPick_BuildNextPickResponse;
Go
/*------------------------------------------------------------------------------
  Procedure pr_Picking_LPNPick_BuildNextPickResponse: When there is another pick to be
   done, this procedure is called to build the response in V3 desired format
------------------------------------------------------------------------------*/
Create Procedure pr_Picking_LPNPick_BuildNextPickResponse
  (@xmlInput     xml,
   @OutputXML    TXML output)
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
          @vDeviceId                 TDeviceId;
          /* Functional variables */
  declare @vDataXML                  TXML,
          @vLPN                      TLPN,
          @vLPNId                    TRecordId,
          @vActivityLogId            TRecordId;
begin /* pr_Picking_LPNPick_BuildNextPickResponse */

  /* Get LPN */
  select @vLPN = Record.Col.value('(BATCHPICKINFO/LPN)[1]', 'TLPN')
  from @xmlInput.nodes('/BATCHPICKDETAILS') as Record(Col)
  OPTION (OPTIMIZE FOR (@xmlInput = null));

  /* below statement will read all the nodes within the response and merge them into one single xml
     AMF format expects all information under <Data> */
  select @vDataXML = '';
  with ResponseDetails as
  (
    select dbo.fn_XMLNode('LPNPickInfo_' + c.value('(local-name(.))[1]', 'nvarchar(max)'), replace(c.value('(.)[1]', 'nvarchar(max)'), '''', '''''')) ResponseDetail
    from @xmlInput.nodes('/BATCHPICKDETAILS/BATCHPICKINFO/*') as t(c)
    union
    select dbo.fn_XMLNode('Options_' + c.value('(local-name(.))[1]', 'nvarchar(max)'), replace(c.value('(.)[1]', 'nvarchar(max)'), '''', '''''')) ResponseDetail
    from @xmlInput.nodes('/BATCHPICKDETAILS/OPTIONS/BATCHPICKING/*') as t(c)
  )
  select @vDataxml = @vDataxml + ResponseDetail from ResponseDetails;

  /*  read the pick list from the response and add it to data node list */
  select @OutputXML = dbo.fn_XMLNode('Data', @vDataXML + dbo.fn_XMLNode('LPNRight10', right(@vLPN, 10)) +
                                             coalesce(convert(varchar(max), @xmlInput.query('BATCHPICKDETAILS/PICKLIST')), ''));

end /* pr_Picking_LPNPick_BuildNextPickResponse */

Go


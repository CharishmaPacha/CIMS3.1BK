/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2019/06/23  AY      pr_AMF_RaiseErrorAndReset: New method to return blank data and errors
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_AMF_RaiseErrorAndReset') is not null
  drop Procedure pr_AMF_RaiseErrorAndReset;
Go
/*------------------------------------------------------------------------------
  Procedure pr_AMF_RaiseErrorAndReset: In some cases, when a transaction
    fails, we would need to reset the form and in such cases, we would want to
    clear the form and show the error message.
    V3RF is build with conditional forms which show the data based upon the input
    and DataXML is always required, so we want to build a dummy DataXML in this
    case.
------------------------------------------------------------------------------*/
Create Procedure pr_AMF_RaiseErrorAndReset
  (@MessageName   TMessage,
   @Value1        TDescription = null,
   @Value2        TDescription = null,
   @Value3        TDescription = null,
   @Value4        TDescription = null,
   @Value5        TDescription = null,
  -----------------------------------
   @DataXML       TXML = null output,
   @ErrorXML      TXML = null output)
as
begin /* pr_AMF_RaiseErrorAndReset */

  /* We are only sending zeros for all typically used ids so that the form
     can be cleared based upon these conditions */
  select @DataXML = (select 0 EntityId,
                            0 LPNId,
                            0 TaskId,
                            0 OrderId,
                            0 PalletId,
                            0 ReceiptId
                   for Xml Raw(''), elements, Root('Data'));

  /* Build the error */
  select @ErrorXML =  '<Errors><Messages>' +
                       dbo.fn_AMF_GetMessageXML(dbo.fn_Messages_Build(@MessageName, @Value1, @Value2, @Value3, @Value4, @Value5)) +
                    '</Messages></Errors>';

end /* pr_AMF_RaiseErrorAndReset */

Go


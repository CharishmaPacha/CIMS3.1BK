/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/01/21  VS      pr_OrderHeaders_SendShipConfirmationEmail: Made changes to get PickTicket and ShipVia (BK-117)
  2018/09/28  AY      pr_OrderHeaders_SendShipConfirmationEmail: Integrate rules to supress emails to some customers (HPI-2059)
  2016/09/01  DK      pr_OrderHeaders_SendShipConfirmationEmail: Added procedure (HPI-374)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_OrderHeaders_SendShipConfirmationEmail') is not null
  drop Procedure pr_OrderHeaders_SendShipConfirmationEmail;
Go
/*------------------------------------------------------------------------------
  Proc  pr_OrderHeaders_SendShipConfirmationEmail: Send ship confirm email to
   the ShipToEmail address with the tracking numbers. Some end clients may not
   need such emails which can be configured in the rules
------------------------------------------------------------------------------*/
Create Procedure pr_OrderHeaders_SendShipConfirmationEmail
  (@OrderId       TRecordId,
   @TemplateName  TName           = 'ShipConfirmation',
   @AlertId       TRecordId       = null,    /* Future use */
   @Subject       TDescription    = null output,
   @Recipients    TVarChar        = null output,
   @EmailBody     TVarChar        = null output,
   @EmailItemId   TInteger        = null output)
as
  declare @vReturnCode            TInteger,
          @vMessageName           TMessageName,

          @vTemplateText          TVarChar,
          @xmlRulesData           TXML,
          @xmlData                XML,
          @vTrackingURL           TResult,
          @vTrackingHyperLink     TResult,
          @vTrackingNos           TResult,
          @vProfileName           TName,
          @vBusinessUnit          TBusinessUnit,
          @vDefaultEmail          TVarChar,
          @vOverrideEmail         TVarChar,
          @vSuppressConfirmation  TFlags;
begin
  SET NOCOUNT ON;

  select @vReturnCode  = 0,
         @vMessageName = null;

  select @vTemplateText = TemplateDetail,
         @vBusinessUnit = BusinessUnit
  from ContentTemplates
  where (TemplateName = @TemplateName);

  select @vDefaultEmail = @vBusinessUnit + 'support@cloudimsystems.com';

  /* get control value and Messages here */
  select @Subject        = dbo.fn_Messages_GetDescription('ShipConfirmation_Subject'),
         @vProfileName   = dbo.fn_Controls_GetAsString('DBMail', 'ShipNotificationProfile', 'CIMS', @vBusinessUnit, ''),
         @vOverrideEmail = dbo.fn_Controls_GetAsString('DBMail', 'ShipNotificationOverrideEmail', @vDefaultEmail, @vBusinessUnit, '');

  /* Build XML data */
  set @xmlRulesData = (select datename(dw, ShippedDate) + ', ' + convert(varchar, ShippedDate, 107 /* mm dd, yyyy */) as Shipdate,
                              cast(cast(TotalWeight as decimal(5,2)) as varchar) + ' lbs' as TotalWeightDesc, *
                       from vwPackingListHeaders
                       where (OrderId = @OrderId)
                       for xml raw('RootNode'), elements, binary base64)

  select @xmlData = convert(xml, @xmlRulesData);

  /* The recipient email in control var overrides the customer ShipToEmail, because in test, we want
     to always send to our client and not the end customer. OverrideEmail control var should exist
     and be blank to send emails to end customers */
  if (coalesce(@vOverrideEmail, '') <> '')
    select @Recipients = @vOverrideEmail;
  else
    select @Recipients = Record.Col.value('ShipToEmailId[1]', 'TEmailAddress')
    from @xmlData.nodes('RootNode') as Record(Col);

  /* For some customers we may not want to send email confirmations */
  exec pr_RuleSets_Evaluate 'Order_ShipConfirm_SuppressEmail', @xmlRulesData, @vSuppressConfirmation output;

  /* Get the TrackingUrl and replace that in the Template. The URL also has
     keyword TrackingNos for UPS (as both require in different formats) as well
     as TrackingNo (which is the readable text to the user) */
  exec pr_RuleSets_Evaluate 'TrackingUrls', @xmlRulesData, @vTrackingURL output;
  select @vTemplateText = replace(@vTemplateText, '~TrackingURL~', @vTrackingURL);

  /* Get the TrackingNumbers to build the hyperlink */
  exec pr_RuleSets_Evaluate 'TrackingNo_HyperLink', @xmlRulesData, @vTrackingHyperLink output;

  select @vTrackingHyperLink = replace(@vTrackingHyperLink, '$ ', '%20');
  --select @vTrackingHyperLink = replace(@vTrackingHyperLink, '  ', '');

  select @vTemplateText = replace(@vTemplateText, 'TrackingNoLink', coalesce(@vTrackingHyperLink, ''));

  /* Get the TrackingNumbers. This is needed to show the Tracking numbers as visible to user */
  exec pr_RuleSets_Evaluate 'TrackingNos', @xmlRulesData, @vTrackingNos output;
  select @vTemplateText = replace(@vTemplateText, '~TrackingNos~', @vTrackingNos);

  /* Calling function fn_SubstitueXMLValues for substituting the specific values from @xmlData into @RuleCondition */
  select @vTemplateText = dbo.fn_SubstituteXMLValues(@vTemplateText, @xmlRulesData);

  select @vTemplateText = replace(@vTemplateText, '''', '');
  select @EmailBody     = replace(@vTemplateText, '|', '<br>');

  /* If we don't know who to send to, or don't have anything to send, then exit */
  if (coalesce(@Recipients, '') = '') or (coalesce(@EmailBody, '') = '')
    begin
      select @vReturnCode = 1;
      goto ExitHandler;
    end

  /* send db mail with the shipment confirmation */
  exec msdb.dbo.sp_send_dbmail @profile_name = @vProfileName,
                               @Recipients   = @Recipients,
                               @subject      = @Subject,
                               @body_format  = 'HTML',
                               @body         = @EmailBody,
                               @mailitem_id  = @EmailItemId output;

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0))
end /*  pr_OrderHeaders_SendShipConfirmationEmail */

Go

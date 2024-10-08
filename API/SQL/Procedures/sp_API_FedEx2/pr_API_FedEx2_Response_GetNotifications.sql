/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2024/02/12  RV      Initial Version (CIMSV3-3396)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_API_FedEx2_Response_GetNotifications') is not null
  drop Procedure pr_API_FedEx2_Response_GetNotifications;
Go
/*------------------------------------------------------------------------------
  Proc pr_API_FedEx2_Response_GetNotifications: Retrieves the notifications from the
    FedEx response and returns the severity and errors/warnings. Fedex returns Errors
    in '$.errors' and warnings in '$.output.transactionShipments[0].alerts'.
    Only 400 exceptions are handled here. 401 - Unauthorized would be handled by API.
    A response can have either/or/both Errors and Alerts.

  We may get the following json:

  Ex1:
  400: BadRequest
  {
      "transactionId": "39d0a4f6-5635-4328-a77c-facd94f0de77",
      "customerTransactionId": "624deea6-b709-470c-8c39-4b5511281492",
      "errors": [
          {
               "code": "SHIPPER.COUNTRY.INVALID",
              "message": "We are not able to retrieve the message for the warning or error."
          }
      ]
  }

  Ex2:
  401: Unauthorized
  {
      "error": "invalid_request",
      "error_description": "CXS JWT is expired"
  }

  Ex3:
  401: Unauthorized
  {
    "error_description": "Invalid CXS JWT"
  }

  Ex4:
  "alerts": [
  {
     "code": "SHIPMENT.SHIPDATESTAMP.INVALID",
     "message": "We are not able to retrieve the message for the warning or error.",
     "alertType": "WARNING",
     "parameterList": []
  },
  {
     "code": "RATING.IS.UNAVAILABLE",
     "message": "We are not able to retrieve the message for the warning or error.",
     "alertType": "WARNING",
     "parameterList": []
  }
  ]

 #Notifications TCarrierResponseNotifications -- created by caller
------------------------------------------------------------------------------*/
Create Procedure pr_API_FedEx2_Response_GetNotifications
  (@ResponseJSON             TNVarchar,
   @BusinessUnit             TBusinessUnit,
   @UserId                   TUserId,
   @Severity                 TString  output,
   @Notifications            TVarchar output,
   @NotificationDetails      TVarchar output)
as
  declare @vReturnCode                  TInteger,
          @vMessageName                 TMessageName,

          @vError                       TString,
          @vErrorCode                   TString,
          @vErrorDesc                   TMessage;

begin /* pr_API_FedEx2_Response_GetNotifications */
  SET NOCOUNT ON;

  /* Initialize */
  select @vReturnCode  = 0,
         @vMessageName = null;

  /*-------------------- Notifications --------------------*/
  /* Get all the errors into a hash table */
  insert into #Notifications
  select 'Error' HighestSeverity, 'Error' Severity, *, Message as SeverityMessage, 1 as SeverityLevel
  from OPENJSON(@ResponseJSON, '$.errors')
  with
  (
    Message           TMessage    '$.message',
    Code              TString     '$.code',
    SequenceNumber    TInteger    '$',
    TrackingNumber    TTrackingNo '$'
  );

  /* Get all the alerts into the hash table */
  insert into #Notifications
  select *, Message as SeverityMessage, 2 as SeverityLevel
  from OPENJSON(@ResponseJSON, '$.output.transactionShipments[0].alerts')
  with
  (
    HighestSeverity   TString     '$.alertType',
    Severity          TString     '$.alertType',
    Message           TMessage    '$.message',
    Code              TString     '$.code',
    SequenceNumber    TInteger    '$',
    TrackingNumber    TTrackingNo '$'
  );

  /* We are seeing no description in many cases, so use Code in those instances. */
  update #Notifications
  set SeverityMessage = coalesce(nullif(Message, 'We are not able to retrieve the message for the warning or error.'), Code);

  /* We have two severity levels 1. Errors, 2. Alerts/Warnings. If there is an errror, we consider
     the Final severity as Error; if no error, then we consider it as Warning */
  select @Severity = Severity from #Notifications order by SeverityLevel;

  /* Extract the errors & alerts node to save the details in NotificationSource  */
  select @NotificationDetails = concat_ws('; ', JSON_QUERY(@ResponseJSON, '$.errors'),
                                                JSON_QUERY(@ResponseJSON, '$.output.transactionShipments[0].alerts'));

  /* Build the Notifications including Errors & Alerts */
  select @Notifications = string_agg(Msg, ', ')
  from (select Severity + ': ' + string_agg(SeverityMessage, '; ') Msg from #Notifications group by Severity) M;

  /* If there are no Notifications, then it could be a fault */
  if not exists(select * from #Notifications)
    begin
      /*-------------------- ErrorInfo --------------------*/
      /* Note: Please retain all columns in the query, as they may be used elsewhere */
      select * into #ErrorInfo
      from OPENJSON(@ResponseJSON, '$')
      with
      (
        Cause           TMessage    '$',
        ErrorCode       TString     '$.error',
        ErrorDesc       TMessage    '$.error_description'
      );

      /* Get the Error Info. We may get the errors with only error_description */
      if exists(select * from #ErrorInfo where ErrorDesc is not null)
        select @Severity   = 'Fault',
               @vError     = Cause,
               @vErrorCode = ErrorCode,
               @vErrorDesc = ErrorDesc
        from #ErrorInfo;

      /* Build the Fatal Error related information */
      select @Notifications = concat(@vErrorCode, ': ', @vErrordesc)
    end

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_API_FedEx2_Response_GetNotifications */

Go

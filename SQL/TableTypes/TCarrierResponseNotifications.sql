/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2024/02/19  RV      TCarrierResponseNotifications: Added SeverityLevel (CIMSV3-3396)
  2022/11/04  VS      TCarrierResponseNotifications: Initial Version (OBV3-1353)
  Create Type TCarrierResponseNotifications as Table (
  grant references on Type:: TCarrierResponseNotifications to public;
------------------------------------------------------------------------------*/

Go

/*----------------------------------------------------------------------------*/
Create Type TCarrierResponseNotifications as Table (
    HighestSeverity          TString,
    Severity                 TString,
    Message                  TMessage,
    Code                     TString,
    SequenceNumber           TInteger,
    TrackingNumber           TTrackingNo,
    SeverityMessage          TMessage,
    SeverityLevel            TInteger)

grant references on Type:: TCarrierResponseNotifications to public;

Go

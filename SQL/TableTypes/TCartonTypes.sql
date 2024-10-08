/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  TCartonTypes: Added OrderId
  2020/07/24  TK      TCartonTypes & TCubeCartonHdr: Added Dimensions (S2GCA-1202)
  2020/05/06  TK      TDetailsToCube, TCubeCartonHdrs, TCubeCartonDtls & TCartonTypes:
------------------------------------------------------------------------------*/

Go

/*------------------------------------------------------------------------------*/
/* Holds list of carton types for one or more CartonGroups */
Create Type TCartonTypes as Table (
    OrderId                  TRecordId,
    CartonGroup              TCartonGroup,
    CartonType               TCartonType,
    EmptyCartonSpace         TInteger,
    EmptyWeight              TFloat,

    MaxWeight                TWeight,
    MaxUnits                 TInteger,
    MaxCartonDimension       TFloat,
    FirstDimension           TFloat,
    SecondDimension          TFloat,
    ThirdDimension           TFloat,

    RecordId                 TRecordId      identity(1,1),
    Primary Key              (RecordId)
);

Grant References on Type:: TCartonTypes  to public;

Go

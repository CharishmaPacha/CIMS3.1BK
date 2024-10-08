/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2018/02/04  TK      Added TDependencies (S2G-179)
  Create Type TDependencies as Table (
  Grant References on Type:: TDependencies to public;
------------------------------------------------------------------------------*/

Go

Create Type TDependencies as Table (
    DependencyFlags          TFlags,
    Count                    TCount,

    RecordId                 TRecordId      identity (1,1)
);

Grant References on Type:: TDependencies to public;

Go

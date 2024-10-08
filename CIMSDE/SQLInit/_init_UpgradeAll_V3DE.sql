/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2024/10/08  VM      Config changes as CIMS SQL is on Git (BK-1113)
  2024/02/28  VM      Moved to run Inits from CIMSDECreate.sql to _init_UpgradeAll_V3DE.sql (CIMSV3-3430)
  2024/01/30  VM      Initial Revision (HA-3952)
------------------------------------------------------------------------------*/
/* Apply DE related init changes to a CIMS DE Database */

/* Inits */
Input ..\..\SQLInit\Main\init_BusinessUnits.sql;
Input .\Main\init_DE_Sequences.sql;
Input .\Main\init_DE_Control.sql;

Go

/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/11/22  TK      Added init_InterfaceFields_6River_GroupCancel.sql (CID-1513)
  2020/11/16  TK      Added init_InterfaceFields_6River_GroupUpdate.sql (CID-1514)
  2020/11/16  TK      Added init_InterfaceFields_6River_PickWave.sql (CID-1498)
  2020/11/02  NB      Initial Revision
------------------------------------------------------------------------------*/
/* Apply API related init changes to a CIMS Database */

/* Inits */
Input .\Main\init_APIIntegrations.sql;
Input .\Main\init_APIConfiguration.sql;
Input .\Main\init_InterfaceFields_6River_GroupCancel.sql;
Input .\Main\init_InterfaceFields_6River_GroupUpdate.sql;
Input .\Main\init_InterfaceFields_6River_PickWave.sql;
Input .\Main\init_Sequences.sql;

Go

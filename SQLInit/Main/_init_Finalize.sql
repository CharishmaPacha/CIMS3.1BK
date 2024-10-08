/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2023/12/13  VM      Run pr_Fields_SetupMissingFields to identify missing fields and add them to Fields table (CIMSV3-3291)
  2022/08/10  VM      Initial Revision (HA-2976)
------------------------------------------------------------------------------*/
/* This file is used to do any required final updates on data after all initializations from CIMS and custom files are done on the blank DB
   like example - all LayoutFields.FieldVisbleIndex should be sequenced properly after all fields visiblility is initialized from
                  both CIMS and custom files */

Go

/*------------------------------------------------------------------------------
  Call pr_Fields_AddMissingFields to setup the rest of missing fields

  Why it should be called in init_Finalize: As there are some views created in other scripts like
  init_InterfaceFields.sql etc, we need to call this at the end after all of objects/data created
  to findout the missing fields and set them up in Fields table.
-----------------------------------------------------------------------------*/
exec pr_Fields_SetupMissingFields;


Go

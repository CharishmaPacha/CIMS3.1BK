/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2022/02/21  AY      TPackDetails: Added Inventory Key (FBV3-886)
  2021/10/12  RV      TPackDetails: Added PackingGroup, UnitsPicked and PackGroupKey (BK-636)
  2019/07/05  MS      Added TPackDetails (CID-609)
  2011/09/07  AA      Initial revision.
------------------------------------------------------------------------------*/

Go

Create Type TTransactionKey            from varchar(22);        Grant References on Type:: TTransactionKey            to public;

Go

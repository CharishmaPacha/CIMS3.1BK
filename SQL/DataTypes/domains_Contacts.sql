/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2023/07/28  VM      Address Info domains: Moved to Base (CIMSV3-2974)
  2023/07/18  VM      TEmailAddress: Moved to Base (CIMSV3-2959)
  2022/10/26  VS/AY   Changed TContactType length to 10 (OBV3-1301)
  2021/01/25  PHK     Added TVendorNumber (JLFL-71)
  2019/07/01  KSK     Added TTaxId (CID-632)
  2015/07/03  TK      Added TCityStateZip
  2015/03/29  SV      Added TAddressRegion
  2012/09/13  AY      Added TShipToStore
  2010/09/20  PK      Initial revision.
------------------------------------------------------------------------------*/

Go

/* Customer */
Create Type TCustomerId           from varchar(50);      grant references on Type:: TCustomerId        to public;
Create Type TShipToStore          from varchar(20);      grant references on Type:: TShipToStore       to public;

/* Vendor */
Create Type TVendorId             from varchar(50);      grant references on Type:: TVendorId          to public;
Create Type TVendorNumber         from varchar(60);      grant references on Type:: TVendorNumber      to public;

Go

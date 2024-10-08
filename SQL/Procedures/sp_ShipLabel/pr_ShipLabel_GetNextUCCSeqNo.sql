/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2012/06/27  PKS     Added pr_ShipLabel_GetNextUCCSeqNo.
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_ShipLabel_GetNextUCCSeqNo') is not null
  drop Procedure pr_ShipLabel_GetNextUCCSeqNo;
Go
/*------------------------------------------------------------------------------
Proc pr_ShipLabel_GetNextUCCSeqNo:
------------------------------------------------------------------------------*/
Create Procedure pr_ShipLabel_GetNextUCCSeqNo
  (@UserId          TUserId,
   @BusinessUnit    TBusinessUnit,
   @UCCBarCode      TBarcode output,

   @UCCPackageType  TBarcode = null output,
   @UCCManfCode     TBarcode = null output,
   @UCCSeqNo        TBarcode = null output,
   @UCCCheckDigit   TBarcode = null output)
as
begin
  /* Get PackageType. */
  select @UCCPackageType = dbo.fn_Controls_GetAsString ('UCCSeqNo', 'PackageType', '0' /* Default */, @BusinessUnit, @UserId);

  /* Get Manufacturer code. */
  select @UCCManfCode = dbo.fn_Controls_GetAsString ('UCCSeqNo', 'ManufacturerCode', '0' /* Default */, @BusinessUnit, @UserId);

  /* Pad Manufacturer Code to desired length */
  select @UCCManfCode = dbo.fn_pad(@UCCManfCode, 7 /* Fixed */);

  /* Get Next SeqNo of UCCSeqNo */
  exec pr_Controls_GetNextSeqNoStr 'UCCSeqNo', 1 /* Increment */, @UserId, @BusinessUnit, @UCCSeqNo output;

  /* Compute check digit */
  select @UCCCheckDigit = dbo.fn_GetMod10CheckDigit(@UCCPackageType + @UCCManfCode + @UCCSeqNo);

  /* Framing UCCBarCode value. */
  set @UCCBarCode = '00' + @UCCPackageType + @UCCManfCode + @UCCSeqNo + @UCCCheckDigit;
end/* pr_ShipLabel_GetNextUCCSeqNo */

Go

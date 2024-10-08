/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2012/04/15  YA      Changed BusinessUnit from 'LOEH' to 'TD' as Topson Downs specific.
------------------------------------------------------------------------------*/

declare @FirstPalletId      TRecordId,
        @FirstPallet        TPallet,
        @LastPalletId       TRecordId,
        @LastPallet         TPallet,
        @NumPalletsCreated  TCount,
        @Warehouse          TWarehouse,
        @BusinessUnit       TBusinessUnit;

select top 1 @Warehouse = LookUpCode
from vwLookUps
where (LookupCategory = 'Warehouse');

select top 1 @BusinessUnit = BusinessUnit
from vwBusinessUnits;

/* Generate Pallets for Inventory
*/
exec pr_Pallets_GeneratePalletLPNs
   'I',                   /* @PalletType         */
   100,                   /* @NumPalletsToCreate */
   null,                  /* @PalletFormat       */
   0,                     /* @NumLPNsPerPallet   */
   null,                  /* @LPNType - Cart     */
   null,                  /* @LPNFormat          */
   @Warehouse,            /* @DestWarehouse      */
   @BusinessUnit,         /* @BusinessUnit       */
   'rfcadmin',            /* @UserId             */
   @FirstPalletId         output,
   @FirstPallet           output,
   @LastPalletId          output,
   @LastPallet            output,
   @NumPalletsCreated     output;

Go

/* Generate Pallets for Picking Carts

exec pr_Pallets_GeneratePalletLPNs
   'C',                   /* @PalletType         */
   20,                    /* @NumPalletsToCreate */
   null,                  /* @PalletFormat       */
   0,                     /* @NumLPNsPerPallet   */
   null,                  /* @LPNType - Cart     */
   null,                  /* @LPNFormat          */
   @Warehouse,            /* @DestWarehouse      */
   @BusinessUnit,         /* @BusinessUnit       */
   'rfcadmin',            /* @UserId             */
   @FirstPalletId         output,
   @FirstPallet           output,
   @LastPalletId          output,
   @LastPallet            output,
   @NumPalletsCreated     output;     */

Go

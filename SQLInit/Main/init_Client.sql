/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2011/09/08  VM      Moved Generating Carts to init_Pallets.sql
  2011/08/19  NB      Added Generating Carts
  2011/08/19  VM      Removed inactivating RFReceiving as we decided to use this file only for
                        client specific terminology changes, hence inactivation of RFReceiving is done directly
                        in init_Permissions file.
  2011/08/17  YA      Updated few table descriptions (LPN => Control # and LPNs => Control #s)
  2011/08/12  VM      Initial revision.
------------------------------------------------------------------------------*/

/* This file is used to set client specific settings/configurations in Database */

/* LOEH - Loehmann's specific - Loehmann's wants to show LPN as Control #
   LPN      => Control #      - Singular
   LPNs     => Control #s     - Plural
   Pallet   => Cart
   Pallets  => Carts
*/

/* Commented the below code as it is Loehmanns specific */
--declare @LPNCaptionOriginal        varchar(50),   /* for Singular - LPN */
--        @LPNCaptionClientSpecific  varchar(50),
--        @LPNsCaptionOriginal       varchar(50),   /* for plural - LPNs */
--        @LPNsCaptionClientSpecific varchar(50),

--        @PalletCaptionOriginal        varchar(50),   /* for Singular - Pallet*/
--        @PalletCaptionClientSpecific  varchar(50),
--        @PalletsCaptionOriginal       varchar(50),   /* for plural - Pallets */
--        @PalletsCaptionClientSpecific varchar(50);

--select @LPNCaptionOriginal           = 'LPN',
--       @LPNCaptionClientSpecific     = 'Control#',
--       @LPNsCaptionOriginal          = 'LPNs',
--       @LPNsCaptionClientSpecific    = 'Control#s',
--       @PalletCaptionOriginal        = 'Pallet',
--       @PalletCaptionClientSpecific  = 'Cart',
--       @PalletsCaptionOriginal       = 'Pallets',
--       @PalletsCaptionClientSpecific = 'Carts';

--/* Look-Ups */
--update LookUps set LookUpDescription = replace(LookUpDescription, @LPNCaptionOriginal,  @LPNCaptionClientSpecific);
--update LookUps set LookUpDescription = replace(LookUpDescription, @LPNsCaptionOriginal, @LPNsCaptionClientSpecific);

--/* Messages */
--update Messages set Description = replace(Description, @LPNCaptionOriginal, @LPNCaptionClientSpecific);
--update Messages set Description = replace(Description, @LPNsCaptionOriginal, @LPNsCaptionClientSpecific);

--update Messages set Description = replace(Description, @PalletCaptionOriginal, @PalletCaptionClientSpecific);
--update Messages set Description = replace(Description, @PalletsCaptionOriginal, @PalletsCaptionClientSpecific);

--/* Controls */
--update Controls set Description = replace(Description, @LPNCaptionOriginal, @LPNCaptionClientSpecific);
--update Controls set Description = replace(Description, @LPNsCaptionOriginal, @LPNsCaptionClientSpecific);

--/* Permissions */
--update Permissions set Description = replace(Description, @LPNCaptionOriginal, @LPNCaptionClientSpecific);
--update permissions set Description = replace(Description, @LPNsCaptionOriginal, @LPNsCaptionClientSpecific);

--/* Entity Types */
--update EntityTypes set TypeDescription = replace(TypeDescription, @LPNCaptionOriginal, @LPNCaptionClientSpecific);
--update EntityTypes set TypeDescription = replace(TypeDescription, @LPNsCaptionOriginal, @LPNsCaptionClientSpecific);

--Go

/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2013/03/15  NY      Initial revision for Latin Products
------------------------------------------------------------------------------*/

Go

/* Receiving Locations - Rows 01 to 06 */
exec pr_Locations_Generate
   'LP', 'ATLGA', 'FFI',       -- @BusinessUnit, @Warehouse, @UserId
   'D'  /* Receiving */,       -- @LocationType
   'L'  /* LPNs */,            -- @StorageType
   '<Row>-<Level>-<Section>',  -- @LocationFormat
   /* Row */
   '01',  '06',  Default, 'N', -- Start, end, Increment, CharSet
   /* section */
   '01',  '04',  Default, 'N', -- Start, end, Increment, CharSet
   /* Level */
   '1',   '1',   Default, 'N'  -- Start, end, Increment, CharSet;

Go

/* Reserve Locations - Rows 01 to 06 */
exec pr_Locations_Generate
   'LP', 'ATLGA', 'FFI',       -- @BusinessUnit, @Warehouse, @UserId
   'R'  /* Reserve */,         -- @LocationType
   'L'  /* LPNs */,            -- @StorageType
   '<Row>-<Level>-<Section>',  -- @LocationFormat
   /* Row */
   '01',  '06',  Default, 'N', -- Start, end, Increment, CharSet
   /* section */
   '01',  '04',  Default, 'N', -- Start, end, Increment, CharSet
   /* Level */
   '2',   '4',   Default, 'N'  -- Start, end, Increment, CharSet;

Go

/* Piclane Locations - Rows 07 to 12 */
exec pr_Locations_Generate
   'LP', 'ATLGA', 'FFI',       -- @BusinessUnit, @Warehouse, @UserId
   'K'  /* Picklane */,        -- @LocationType
   'U'  /* Units */,           -- @StorageType
   '<Row>-<Level>-<Section>',  -- @LocationFormat
   /* Row */
   '07',  '12',  Default, 'N', -- Start, end, Increment, CharSet
   /* section */
   '01',  '05',  Default, 'N', -- Start, end, Increment, CharSet
   /* Level */
   '1',   '5',   Default, 'N'  -- Start, end, Increment, CharSet;

Go

/* Piclane Locations - Rows 13 to 14  */
exec pr_Locations_Generate
   'LP', 'ATLGA', 'FFI',       -- @BusinessUnit, @Warehouse, @UserId
   'K'  /* Picklanes */,       -- @LocationType
   'U'  /* Units */,           -- @StorageType
   '<Row>-<Level>-<Section>',  -- @LocationFormat
   /* Row */
   '13',  '14',  Default, 'N', -- Start, end, Increment, CharSet
   /* section */
   '01',  '05',  Default, 'N', -- Start, end, Increment, CharSet
   /* Level */
   '1',   '6',   Default, 'N'  -- Start, end, Increment, CharSet;

Go

/* Piclane Locations - Rows 15 to 24  */
exec pr_Locations_Generate
   'LP', 'ATLGA', 'FFI',       -- @BusinessUnit, @Warehouse, @UserId
   'K'  /* Picklanes */,       -- @LocationType
   'U'  /* Units */,           -- @StorageType
   '<Row>-<Level>-<Section>',  -- @LocationFormat
   /* Row */
   '15',  '24',  Default, 'N', -- Start, end, Increment, CharSet
   /* section */
   '01',  '06',  Default, 'N', -- Start, end, Increment, CharSet
   /* Level */
   '1',   '3',   Default, 'N'  -- Start, end, Increment, CharSet;

Go

/* Piclane Locations - Rows 25 to 32  */
exec pr_Locations_Generate
   'LP', 'ATLGA', 'FFI',       -- @BusinessUnit, @Warehouse, @UserId
   'K'  /* Picklanes */,       -- @LocationType
   'U'  /* Units */,           -- @StorageType
   '<Row>-<Level>-<Section>',  -- @LocationFormat
   /* Row */
   '25',  '32',  Default, 'N', -- Start, end, Increment, CharSet
   /* section */
   '01',  '06',  Default, 'N', -- Start, end, Increment, CharSet
   /* Level */
   '1',   '4',   Default, 'N'  -- Start, end, Increment, CharSet;

Go

/* Reserve Locations - Rows 25 to 32  */
exec pr_Locations_Generate
   'LP', 'ATLGA', 'FFI',       -- @BusinessUnit, @Warehouse, @UserId
   'R'  /* Reserve */,         -- @LocationType
   'L'  /* LPNs */,            -- @StorageType
   '<Row>-<Level>-<Section>',  -- @LocationFormat
   /* Row */
   '25',  '32',  Default, 'N', -- Start, end, Increment, CharSet
   /* section */
   '01',  '06',  Default, 'N', -- Start, end, Increment, CharSet
   /* Level */
   '5',   '5',   Default, 'N'  -- Start, end, Increment, CharSet;

Go

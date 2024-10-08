/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2012/09/20  AY      LabelRules: New table to determine the labels to print for orders.
------------------------------------------------------------------------------*/

Go

/*------------------------------------------------------------------------------
  Table: LabelRules

    EntityType       - Type of Entity the Label is applicable for.
                       Ex: LPN, Location, CartonContents, ShipLabel etc.
    PrintOptions     - XML that defines certain options to be used at time of
                       printing, like size of the label.
------------------------------------------------------------------------------*/
-- Create Table LabelRules (
--     RecordId           TRecordId       identity (1,1) not null,
--
--     EntityType         TEntity         not null default 'ShipLabel',
--     LabelFormatName    TName           not null,
--
--     /* Criteria */
--     SoldToId           TCustomerId,
--     ShipToId           TShipToId,
--     UoM                TUoM,
--
--     Status             TStatus         not null default 'A' /* Active*/,
--     SortSeq            TSortSeq                 default 0,
--
--     BusinessUnit       TBusinessUnit   not null,
--     CreatedDate        TDateTime       default current_timestamp,
--     ModifiedDate       TDateTime,
--     CreatedBy          TUserId,
--     ModifiedBy         TUserId,
--
--     constraint pkLabelRules_RecordId PRIMARY KEY (RecordId)
-- );

Go

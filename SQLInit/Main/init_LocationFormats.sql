/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/11/15  MS      Corrections as per New Format (CIMSV3-1210)
  2014/04/16  TK      Changes to control data using procedure
  2012/04/16  AY      Initial revision for TD
------------------------------------------------------------------------------*/

Go

/*------------------------------------------------------------------------------
 Location Formats
 -----------------------------------------------------------------------------*/
declare @LocationFormats TLookUpsTable, @LookUpCategory TCategory = 'LocationFormat';

insert into @LocationFormats
       (LookUpCode,  LookUpDescription,                         Status)
values ('LF1',       '<LocationType>-<Row>-<Section>-<Level>',  'A'),
       ('LF2',       '<LocationType>-<Row>-<Level>-<Section>',  'A'),
       ('LF3',       '<Row>-<Section>-<Level>',                 'A'),
       ('LF4',       'P-<Row>-<Level>',                         'A'),
       ('LF5',       'E-<Row>-<Level>-<Section>',               'I'),
       ('LF6',       'R-<Row>-<Level>-<Section>',               'I')

exec pr_LookUps_Setup @LookUpCategory, @LocationFormats, @LookUpCategoryDesc =  'Location Format';

Go

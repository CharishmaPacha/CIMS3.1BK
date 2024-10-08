/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2011/09/16  AA      Initial Revision.
------------------------------------------------------------------------------*/

/*------------------------------------------------------------------------------*/
/* ShipVia Service Details */
/*------------------------------------------------------------------------------*/
delete from ShipViaServiceDetails;

insert into ShipViaServiceDetails (Carrier,        ShipVia,  CarrierServiceCode,  IsActive,  BusinessUnit,  StandardAttributes)
                            select 'FEDEX',        'FXSP',   'SMART_POST',          1,         BusinessUnit,  '<LABELIMAGETYPE>PNG</LABELIMAGETYPE><LABELFORMAT>COMMON2D</LABELFORMAT><LABELSTOCKSIZE>PAPER_4X6</LABELSTOCKSIZE><CARRIER>FEDEX</CARRIER><SERVICECODE>SMART_POST</SERVICECODE><PACKAGINGTYPE>YOUR_PACKAGING</PACKAGINGTYPE><RATEREQUESTTYPES>ACCOUNT</RATEREQUESTTYPES><SMARTPOSTINDICIATYPE>PARCEL_SELECT</SMARTPOSTINDICIATYPE><SMARTPOSTENDORSEMENT>ADDRESS_CORRECTION</SMARTPOSTENDORSEMENT><SMARTPOSTHUBID>5531</SMARTPOSTHUBID>'  from vwBusinessUnits
                      union select 'FEDEX',        'FEDXG',  'FEDEX_GROUND',        1,         BusinessUnit,  '<LABELIMAGETYPE>PNG</LABELIMAGETYPE><LABELFORMAT>COMMON2D</LABELFORMAT><LABELSTOCKSIZE>PAPER_4X6</LABELSTOCKSIZE><CARRIER>FEDEX</CARRIER><SERVICECODE>FEDEX_GROUND</SERVICECODE><PACKAGINGTYPE>YOUR_PACKAGING</PACKAGINGTYPE><RATEREQUESTTYPES>ACCOUNT</RATEREQUESTTYPES><ISCODSHIPMENT>false</ISCODSHIPMENT>'                                                                                                                          from vwBusinessUnits
                      union select 'FEDEX',        'FEDX1',  'STANDARD_OVERNIGHT',  1,         BusinessUnit,  '<LABELIMAGETYPE>PNG</LABELIMAGETYPE><LABELFORMAT>COMMON2D</LABELFORMAT><LABELSTOCKSIZE>PAPER_4X6</LABELSTOCKSIZE><CARRIER>FEDEX</CARRIER><SERVICECODE>STANDARD_OVERNIGHT</SERVICECODE><PACKAGINGTYPE>YOUR_PACKAGING</PACKAGINGTYPE><RATEREQUESTTYPES>ACCOUNT</RATEREQUESTTYPES><ISCODSHIPMENT>false</ISCODSHIPMENT>'                                                                                                                    from vwBusinessUnits
                      union select 'FEDEX',        'FEDX2',  'FEDEX_2_DAY',         1,         BusinessUnit,  '<LABELIMAGETYPE>PNG</LABELIMAGETYPE><LABELFORMAT>COMMON2D</LABELFORMAT><LABELSTOCKSIZE>PAPER_4X6</LABELSTOCKSIZE><CARRIER>FEDEX</CARRIER><SERVICECODE>FEDEX_2_DAY</SERVICECODE><PACKAGINGTYPE>YOUR_PACKAGING</PACKAGINGTYPE><RATEREQUESTTYPES>ACCOUNT</RATEREQUESTTYPES><ISCODSHIPMENT>false</ISCODSHIPMENT>'                                                                                                                           from vwBusinessUnits

Go

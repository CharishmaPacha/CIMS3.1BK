/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2023/09/08  AY      Add FedEx OneRate Service (MBW-464)
  2023/02/13  VS      Added FEDXICP (FedEx - International Connect Plus) (OBV3-1721)
  2023/01/01  AY      Added FEDX2AM (OBV3-1500)
  2022/10/21  RKC     Added FEDEXIPD (OBV3-1270)
  2022/06/07  RV      FEDEX: Electronic trade documents setup for FEDEX internation services (HA-3531)
  2022/04/18  AY      Setup UPS services that are valid (OBV3-610)
  2021/11/26  OK      Coorected CarrierServiceCode for UPSC and UPS STD GROUND (BK-706)
  2021/08/23  OK      Added UPS Mail Innovations services and inactivated internations UPS MI services (BK-506)
  2021/04/29  AY      Setup SCAC for Fedex ShipVias
  2021/02/22  AY      Added AMXB/NRSH
  2021/01/29  TK      Corrected SCAC code for UPS ship vias (BK-142)
  2020/12/24  RV      Corrected the shipvias to add the carrier service code node to the standard attributes (HA-1775)
  2020/11/28  AY      Added TBD as a Shipvia - to be used when user does not know ShipVia (CIMSV3-792)
  2020/09/28  VM      Several changes as per VM/AY discussions (CIMSV3-1105)
  2020/09/22  VM      Reverted to send cimsdba in UserId as now setup procedures handling it (HA-1425)
  2020/05/27  SPP     Changed shipvias LTL,Generic,UPS,UPPS enabled (HA-517)
  2018/09/14  RV      Added and corrected the TForce Service Carrier Codes (S2GCA-260)
  2018/07/25  AY      Sorted and eliminated duplicates from LTL Carriers
  2018/05/23  YJ      Added Shipvias for LTL: Migrated from onsite staging (S2G-727)
  2017/10/16  YJ      Enhanced to handle multiple BusinessUnits (CIMS-1346)
  2017/08/09  LRA     Change all Shipvias using procedure (cIMS-1346)
  2017/05/17  DK      Added FEDXIEF, FEDXI1P and UPSWSR (CIMS-1315)
  2017/03/20  NB/PK   Added ShipVia codes for ADSI Shipping Codes(CIMS-1259)
  2017/01/17  NB      Added FEDX1SAT and UPS1SAT, Introduced update statement for Special Services(HPI-1270)
  2016/07/18  DK      Added FEDXGR shipvia and update UPSGR (HPI-193).
  2016/06/20  KN      Added:DHL Ship vias (NBD-554).
  2016/04/20  KN      Added LABELDPI flag in standard attributes for USPS ship vias(NBD-527)
  2016/04/20  KN      Added ADDINSURANCE flag in standard attributes for USPS ship vias(NBD-409)
  2016/04/10  AY      Added SCAC codes for UPS/FedEx/USPS
  2016/02/10  KN      Added ShipVias for USPS.(NBD-162)
  2016/01/18  YJ      Added ShipVias for FEDEX.(NBD-90)
  2016/01/18  YJ      Added ShipVias for FEDEX,UPS.(NBD-90)
  2015/12/11  NY      Added WWEX
  2015/11/05  NY      Added ShipVia CLLQ (TDAX-301)
  2015/09/18  PK      Added FEDXIE - WIP (FB-404)
  2015/09/09  KN      Added UPS International ship vias.
  2015/05/14  DK      Modified PACKAGINGTYPE node values in StandardAttributes column.
  2015/04/21  AY      Added generic LTL carrier.
  2015/03/01  PK      Added UPSMIEC', 'UPSMIEX', 'UPSMIP', 'UPSS1G' 'UPSSPBPM', 'UPSS1L', 'UPSSPM'.
  2014/12/09  DK      Added FEDX3.
  2013/04/18  VM      StandarAttributes -> ServiceCode => CarrierServiceCode for FEDEX.
  2013/04/12  YA      Included UPS related carrier details.
  2012/06/21  PKS     ShipVia data as given by Alex Perez.
  2011/09/16  AA      Initial Revision.
------------------------------------------------------------------------------*/

/*------------------------------------------------------------------------------*/
/* ShipVias */
/*------------------------------------------------------------------------------*/

/******************************************************************************/
/* FEDEX

  FedEx One Rate - FOR
    Is a special service that is allowed for
    FIRST_OVERNIGHT, PRIORITY_OVERNIGHT, STANDARD_OVERNIGHT
    FEDEX_2_DAY, FEDEX_2_DAY_AM and EXPRESS_SAVER services
    i.e all AIR/Domestic services
    and
    Carton Types of FEDEX_ENVELOPE, FEDEX_SMALL_BOX, FEDEX_MEDIUM_BOX
    FEDEX_LARGE_BOX, EDEX_EXTRA_LARGE_BOX, FEDEX_PAK, FEDEX_TUBE

  Smart Post:
    Setup the HubId for the customer using this table
    https://developer.fedex.com/api/en-us/guides/api-reference.html#smartposthubids
*/
/******************************************************************************/
declare @ShipVias TShipViasTable, @Carrier  TCarrier = 'FEDEX', @BusinessUnit TBusinessUnit, @UserId TUserId, @SA TVarchar;

/* Service classes */
declare @SCAir     TVarchar = '<SERVICECLASS>AIR</SERVICECLASS><SERVICECLASSDESC>Air</SERVICECLASSDESC>',
        @SCGround  TVarchar = '<SERVICECLASS>GND</SERVICECLASS><SERVICECLASSDESC>Ground</SERVICECLASSDESC>',
        @R         TVarchar = '<ISRESIDENTIAL>true</ISRESIDENTIAL>',
        /* SmartPost: The default supported hub ID for FedEx sandbox API might indeed be 5531 for testing purposes,
                      but in a production environment, each client would have their own unique hub ID assigned by FedEx */
        @SP        TVarchar = '<SMARTPOSTINDICIATYPE>PARCEL_SELECT</SMARTPOSTINDICIATYPE><SMARTPOSTENDORSEMENT>ADDRESS_CORRECTION</SMARTPOSTENDORSEMENT><SMARTPOSTHUBID>5531</SMARTPOSTHUBID>';

declare @LabelAttributes TVarchar = '<LABELIMAGETYPE>PNG</LABELIMAGETYPE><LABELFORMAT>COMMON2D</LABELFORMAT><LABELSTOCKSIZE>STOCK_4X6</LABELSTOCKSIZE><PACKAGINGTYPE></PACKAGINGTYPE><SIGNATUREOPTIONTYPE>DIRECT</SIGNATUREOPTIONTYPE><ISCODSHIPMENT>false</ISCODSHIPMENT><RATEREQUESTTYPES>LIST</RATEREQUESTTYPES>';
select @SA = @LabelAttributes;

/* Special Services */
declare @SS_ETD TVarchar = '<SERVICETYPE>ETD</SERVICETYPE>' /* ETD: Electronic Trade Documents */;
/* FexEx One Rate Special Service: Add this as special service to any ShipVia which is applicable for OneRate program
   if Client wants the same service level with OneRate and non-OneRate billing, then we could setup two ShipVias
   to distinguish the same.
*/
declare @SSFedExOneRate  TVarchar = '<SERVICETYPE>FEDEX_ONE_RATE</SERVICETYPE>'

insert into @ShipVias
            (ShipVia,       Description,                                CarrierServiceCode,                    Status,    SortSeq,  SCAC,        StandardAttributes,        SpecialServices)
      select 'FEDXSP',      'FedEx - Smart Post',                       'SMART_POST',                          'A',       1,        'FDEG',      @SA + @SP,                 null
union select 'FEDXG',       'FedEx - Ground',                           'FEDEX_GROUND',                        'A',       2,        'FDEG',      @SA + @SCGround,           null
union select 'FEDXGR',      'FedEx - Ground Residential',               'FEDEX_GROUND',                        'A',       3,        'FDEG',      @SA + @SCGround + @R,      null
union select 'FEDXGH',      'FedEx - Ground Home',                      'GROUND_HOME_DELIVERY',                'A',       4,        'FDEG',      @SA + @SCGround,           null
/*----*/
union select 'FEDX1',       'FedEx - Overnight',                        'STANDARD_OVERNIGHT',                  'A',       10,       'FDEN',      @SA + @SCAir,              null
union select 'FEDX1O',      'FedEx - First Overnight',                  'FIRST_OVERNIGHT',                     'A',       11,       'FDEN',      @SA + @SCAir,              null
union select 'FEDX1P',      'FedEx - Priority Overnight',               'PRIORITY_OVERNIGHT',                  'A',       12,       'FDEN',      @SA + @SCAir,              null
union select 'FEDX2',       'FedEx - 2 Day',                            'FEDEX_2_DAY',                         'A',       13,       'FDEN',      @SA + @SCAir,              null
union select 'FEDX2AM',     'FedEx - 2 Day AM',                         'FEDEX_2_DAY_AM',                      'A',       14,       'FDEN',      @SA + @SCAir,              null
union select 'FEDXXS',      'FedEx - Express Saver',                    'FEDEX_EXPRESS_SAVER',                 'A',       15,       'FDEN',      @SA + @SCAir,              null
/*----*/
union select 'FEDXI1F',     'FedEx - International First',              'INTERNATIONAL_FIRST',                 'A',       20,       'FDEN',      @SA + @SCAir,              @SS_ETD
union select 'FEDXI1P',     'FedEx - International Priority',           'FEDEX_INTERNATIONAL_PRIORITY',        'A',       21,       'FDEN',      @SA + @SCAir,              @SS_ETD
union select 'FEDEXIPE',    'FedEx - International Priority Express',   'FEDEX_INTERNATIONAL_PRIORITY_EXPRESS','A',       22,       'FDEN',      @SA + @SCAir,              @SS_ETD
union select 'FEDXIE',      'FedEx - International Economy',            'INTERNATIONAL_ECONOMY',               'A',       23,       'FDEN',      @SA + @SCAir,              @SS_ETD
union select 'FEDXICP',     'FedEx - International Connect Plus',       'FEDEX_INTERNATIONAL_CONNECT_PLUS',    'A',       24,       'FDEN',      @SA + @SCAir,              @SS_ETD

/* Implemented for OB but not tested in production */
union select 'FEDEXIPD',    'FedEx - International Pri. Dist',          'INTERNATIONAL_PRIORITY_DISTRIBUTION', 'I',       25,       'FEDEXIPD',  @SA,                       @SS_ETD

/* Not implemented */
union select 'FEDEXIED',    'FedEx - International Economy Dist',       'INTERNATIONAL_ECONOMY_DISTRIBUTION',  'I',       26,       '',          @SA,                       @SS_ETD
union select 'FEDEXIGD',    'FedEx - International Ground. Dist',       'INTL_GROUND_DISTRIBUTION',            'I',       27,       '',          @SA,                       @SS_ETD

union select 'FEDX1F',      'FedEx - 1st Day Freight',                  'FEDEX_1_DAY_FREIGHT',                 'I',       40,       'FEXF',      @SA,                       null
union select 'FEDX2F',      'FedEx - 2nd Day Freight',                  'FEDEX_2_DAY_FREIGHT',                 'I',       41,       'FEXF',      @SA,                       null
union select 'FEDX3F',      'FedEx - 3rd Day Freight',                  'FEDEX_3_DAY_FREIGHT',                 'I',       42,       'FEXF',      @SA,                       null

union select 'FEDXIEF',     'FedEx - International Economy Freight',    'INTERNATIONAL_ECONOMY_FREIGHT',       'I',       50,       'FDEN',      @SA,                       @SS_ETD
union select 'FEDEXIPF',    'FedEx - International Priority Freight',   'INTERNATIONAL_PRIORITY_FREIGHT',      'I',       51,       'FDEN',      @SA,                       @SS_ETD

update @ShipVias set SortSeq = 100 + SortSeq;

exec pr_Setup_Shipvias @Carrier, @ShipVias, 'IU' /* Insert/Update */, @BusinessUnit, @UserId, 'Y' /* Is SmallPackageCarrier */;

Go

/******************************************************************************/
/* UPS */
/******************************************************************************/
declare @ShipVias TShipViasTable, @Carrier  TCarrier = 'UPS', @BusinessUnit TBusinessUnit, @UserId TUserId, @SA TVarChar;

declare @LabelAttributes TVarchar = '<LABELIMAGETYPE>PNG</LABELIMAGETYPE><LABELFORMAT>COMMON2D</LABELFORMAT><LABELSTOCKSIZE>PAPER_4X6</LABELSTOCKSIZE><PACKAGINGTYPE></PACKAGINGTYPE><RATEREQUESTTYPES>ACCOUNT</RATEREQUESTTYPES><ISCODSHIPMENT>false</ISCODSHIPMENT>';

/* Service classes */
declare @SCAir     TVarchar = '<SERVICECLASS>AIR</SERVICECLASS><SERVICECLASSDESC>Air</SERVICECLASSDESC>',
        @SCGround  TVarchar = '<SERVICECLASS>GND</SERVICECLASS><SERVICECLASSDESC>Ground</SERVICECLASSDESC>',
        @R         TVarchar = '<ISRESIDENTIAL>true</ISRESIDENTIAL>';

select @SA = @LabelAttributes;

insert into @ShipVias
            (ShipVia,        Description,                                CarrierServiceCode,                 Status, SortSeq, StandardAttributes,                          SpecialServices)
      select 'UPSG',         'UPS Ground',                               'UPSG',                             'A',    1,       @SA,                                         null
union select 'UPS1',         'UPS Next Day Air',                         'UPS1',                             'A',    2,       @SA + @SCAir,                                null
union select 'UPS2',         'UPS Second Day Air',                       'UPS2',                             'A',    3,       @SA + @SCAir,                                null
union select 'UPS3',         'UPS 3 Day select',                         'UPS3',                             'A',    4,       @SA + @SCAir,                                null

union select 'UPSNEA',       'UPS Next Day Air Early AM',                'UPSNEA',                           'A',    5,       @SA + @SCAir,                                null
union select 'UPSNAS',       'UPS Next Day Air Saver',                   'UPSNAS',                           'A',    6,       @SA + @SCAir,                                null

union select 'UPS2DAA',      'UPS 2nd Day Air AM',                       'UPS2DAA',                          'A',    7,       @SA,                                         null

/* Residential is not a service, it is just to note that we are delivering to residential address. This can be used if
   if we know if the address is residential for sure */
union select 'UPSGR',        'UPS Ground Residential',                   'UPSG',                             'A',    10,      @SA + @R,                                    null
union select 'UPS1R',        'UPS Next Day Residential',                 'UPS1',                             'I',    11,      @SA + @R,                                    null
union select 'UPS2R',        'UPS 2 Day Residential',                    'UPS2',                             'I',    12,      @SA + @R,                                    null
union select 'UPS3R',        'UPS 3 Day Residential',                    'UPS3',                             'I',    13,      @SA + @R,                                    null

/* Saturday delivery is a special service, so we use this to denote that it is next day + Saturday delivery */
union select 'UPS1SAT',      'UPS Next Day Saturday Delivery',           'UPS1',                             'A',    14,      @SA,                                         '<SERVICETYPE>SD</SERVICETYPE>'
union select 'UPSS',         'UPS Saver',                                'UPSS',                             'A',    15,      @SA + @SCAir,                                null

/* International Shipments - Originating in USA */
union select 'UPSWECDDP',    'UPS Worldwide Economy DDP',                'UPSWECDDP',                        'A',    21,      @SA,                                         null
union select 'UPSWECDDU',    'UPS Worldwide Economy DDU',                'UPSWECDDU',                        'A',    22,      @SA,                                         null
union select 'UPSWE',        'UPS Worldwide Express',                    'UPSWE',                            'A',    23,      @SA,                                         null
union select 'UPSWEP',       'UPS Worldwide Express Plus',               'UPSWEP',                           'A',    24,      @SA,                                         null
union select 'UPSWSR',       'UPS Worldwide Saver',                      'UPSWSR',                           'A',    25,      @SA,                                         null
union select 'UPSWX',        'UPS Worldwide Expedited',                  'UPSWX',                            'A',    26,      @SA,                                         null
union select 'UPSC',         'UPS Standard',                             'UPSST',                            'A',    27,      @SA,                                         null

union select 'UPSWEPF',      'UPS Worldwide Express Freight',            'UPSWEPF',                          'A',    28,      @SA,                                         null

union select 'UPSWEC',       'UPS Worldwide Economy',                    'UPSWEC',                           'A',    29,      @SA,                                         null
union select 'UPSEC',        'UPS Express Critical',                     'UPSEC',                            'I',    30,      @SA,                                         null

/* Mail Innovations and Sure Post */
union select 'UPSMIFC',      'UPS First Class',                          'UPSMIFC',                          'A',    31,      @SA + '<PACKAGINGTYPE>First Class</PACKAGINGTYPE>',     null
union select 'UPSMIPM',      'UPS Priority Mail',                        'UPSMIPM',                          'A',    32,      @SA + '<PACKAGINGTYPE>Priority</PACKAGINGTYPE>',        null
union select 'UPSMIEX',      'UPS Expedited Mail Innovations',           'UPSMIEX',                          'A',    33,      @SA + '<PACKAGINGTYPE>Parcel Post</PACKAGINGTYPE>',     null
union select 'UPSMIP',       'UPS Priority Mail Innovations',            'UPSMIP',                           'A',    34,      @SA + '<PACKAGINGTYPE>Parcels</PACKAGINGTYPE>',         null
union select 'UPSMIEC',      'UPS Economy Mail Innovations',             'UPSMIEC',                          'A',    35,      @SA + '<PACKAGINGTYPE>Parcels</PACKAGINGTYPE>',         null
union select 'UPSMIR',       'UPS Mail Innovations Returns',             'UPSMIR',                           'I',    36,      @SA + '<PACKAGINGTYPE>Parcels</PACKAGINGTYPE>',         null

/* Sure Post - requires MailerId */
union select 'UPSS1L',       'UPS Sure Post Less Than 1LB',              'UPSS1L',                           'A',    41,      @SA + '<PACKAGINGTYPE>YOUR_PACKAGING</PACKAGINGTYPE>',  null
union select 'UPSS1G',       'UPS Sure Post 1LB or Greater',             'UPSS1G',                           'A',    42,      @SA + '<PACKAGINGTYPE>YOUR_PACKAGING</PACKAGINGTYPE>',  null
union select 'UPSSPBPM',     'UPS Sure Post BPM',                        'UPSSPBPM',                         'A',    43,      @SA + '<PACKAGINGTYPE>YOUR_PACKAGING</PACKAGINGTYPE>',  null
union select 'UPSSPM',       'UPS Sure Post Media',                      'UPSSPM',                           'A',    44,      @SA + '<PACKAGINGTYPE>YOUR_PACKAGING</PACKAGINGTYPE>',  null

union select 'UPS EXPRESS SAV',  'UPS Express Saver',                    'UPS EXPRESS SAV',                  'A',    45,      @SA,                                                    null
union select 'UPS SAT',          'UPS Saturday Delivery',                'UPS SAT',                          'I',    46,      @SA,                                                    null

/* No such services from UPS */
--union select 'UPS3PBEX',   'UPS Express 3PB',                          'UPS 3PB EXPRESS',                  'I',    51,      @SA,                                                    null
--union select 'UPS3PBG',    'UPS Standard Ground 3PB',                  'UPS 3PB GROUND',                   'I',    52,      @SA,                                                    null
--union select 'UPSSTDG',    'UPS Standard Ground Service',              'UPSST',                            'I',    53,      @SA,                                                    null

update @ShipVias set SortSeq = 200 + RecordId;

exec pr_Setup_Shipvias @Carrier, @ShipVias, 'IU' /* Insert/update */, @BusinessUnit, @UserId, 'Y' /* Is SmallPackageCarrier */, 'UPSN' /* SCAC */;

Go

/******************************************************************************/
/* USPS */
/******************************************************************************/
declare @ShipVias TShipViasTable, @Carrier  TCarrier = 'USPS', @BusinessUnit TBusinessUnit, @UserId TUserId, @SA TVarChar;

declare @LabelAttributes TVarchar = '<LABELIMAGETYPE>PDF</LABELIMAGETYPE><LABELFORMAT>COMMON2D</LABELFORMAT><LABELSTOCKSIZE>PAPER_4X6</LABELSTOCKSIZE><LABELDPI>2</LABELDPI><PACKAGINGTYPE></PACKAGINGTYPE><RATEREQUESTTYPES>ACCOUNT</RATEREQUESTTYPES><ISCODSHIPMENT>false</ISCODSHIPMENT><ADDINSURANCE>NO</ADDINSURANCE>';
select @SA = @LabelAttributes;

insert into @ShipVias
            (ShipVia,       Description,                                CarrierServiceCode,          Status,    BusinessUnit,  StandardAttributes, SpecialServices)
      select 'USPS',        'USPS',                                     'USPS',                      'I',       null,          @SA,                null
union select 'USPSL',       'USPS Letter',                              'USPS_Letter',               'I',       null,          @SA,                null

union select 'USPSF',       'USPS First Class Mail',                    'USPS_FirstClass',           'A',       null,          @SA,                null
/* For "USPS Priority Mail" and "USPS Express Mail" always set ADDINSURANCE to NO since insurance  is included in price of service  */
union select 'USPSP',       'USPS Priority Mail',                       'USPS_Priority',             'A',       null,          @SA,                null
union select 'USPSE',       'USPS Express Mail',                        'USPS_Express',              'A',       null,          @SA,                null
union select 'USPSS',       'USPS Standard/Parcel',                     'USPS_ParcelPost',           'A',       null,          @SA,                null

union select 'USPSFI',      'USPS First Class Mail International',      'USPS_FirstClassMailIntl',   'A',       null,          @SA,                null
/* For "USPS Priority Mail International" and "USPS Express Mail International" always set ADDINSURANCE to NO since insurance  is included in price of service  */
union select 'USPSPI',      'USPS Priority Mail International',         'USPS_PriorityMailIntl',     'A',       null,          @SA,                null
union select 'USPSEI',      'USPS Express Mail International',          'USPS_ExpressMailIntl',      'A',       null,          @SA,                null

union select 'USPSFC',      'USPS First Class Mail Canada',             'USPS_FirstClass',           'A',       null,          @SA,                null
union select 'USPSPC',      'USPS Priority Mail Canada',                'USPS_Priority',             'A',       null,          @SA,                null

exec pr_Setup_Shipvias @Carrier, @ShipVias, 'IU' /* Insert/Update */, @BusinessUnit, @UserId, 'Y' /* Is SmallPackageCarrier */;

Go

/*----------------------------------------------------------------------------*/
declare @ShipVias TShipViasTable, @Carrier  TCarrier = 'DHL', @BusinessUnit TBusinessUnit, @UserId TUserId, @SA TVarChar;

declare @LabelAttributes TVarchar = '<LABELIMAGETYPE>PDF</LABELIMAGETYPE><LABELFORMAT>COMMON2D</LABELFORMAT><LABELSTOCKSIZE>Item6X4_PDF</LABELSTOCKSIZE><LABELDPI>300</LABELDPI><CARRIERSERVICECODE>0</CARRIERSERVICECODE><LOCALPRODUCTCODE>0</LOCALPRODUCTCODE><PACKAGINGTYPE></PACKAGINGTYPE><RATEREQUESTTYPES>ACCOUNT</RATEREQUESTTYPES><ISCODSHIPMENT>false</ISCODSHIPMENT><ADDINSURANCE>NO</ADDINSURANCE>'

select @SA = @LabelAttributes;

insert into @ShipVias
            (ShipVia,       Description,                                CarrierServiceCode,          Status,    BusinessUnit,  StandardAttributes, SpecialServices)
      select 'DHLLOG',      'DHL LOGISTICS SERVICES',                   '0',                         'I',       null,          @SA,                null
union select 'DHLDOT',      'DHL DOMESTIC EXPRESS',                     '1',                         'I',       null,          @SA,                null
union select 'DHLB2C-D',    'DHL B2C-Doc',                              '2',                         'I',       null,          @SA,                null
union select 'DHLB2C',      'DHL B2C',                                  '3',                         'I',       null,          @SA,                null
union select 'DHLNFO',      'DHL JETLINE',                              '4',                         'I',       null,          @SA,                null
union select 'DHLSPL-D',    'DHL SPRINTLINE-Doc',                       '5',                         'I',       null,          @SA,                null
union select 'DHLOBC',      'DHL SECURELINE-Doc',                       '6',                         'I',       null,          @SA,                null
union select 'DHLXED-D',    'DHL EXPRESS EASY-Doc',                     '7',                         'I',       null,          @SA,                null
union select 'DHLXEP',      'DHL EXPRESS EASY',                         '8',                         'I',       null,          @SA,                null
union select 'DHLEPA-D',    'DHL EUROPACK-Doc',                         '9',                         'I',       null,          @SA,                null
union select 'DHLAR',       'DHL AUTO REVERSALS',                       'A',                         'I',       null,          @SA,                null
union select 'DHLBBX-D',    'DHL BREAK BULK EXPRESS-Doc',               'B',                         'I',       null,          @SA,                null
union select 'DHLCMX-D',    'DHL MEDICAL EXPRESS-Doc',                  'C',                         'I',       null,          @SA,                null
union select 'DHLDOX-D',    'DHL EXPRESS WORLDWIDE-Doc',                'D',                         'I',       null,          @SA,                null
union select 'DHLTDE',      'DHL EXPRESS 9:00',                         'E',                         'I',       null,          @SA,                null
union select 'DHLFRT',      'DHL FREIGHT WORLDWIDE',                    'F',                         'I',       null,          @SA,                null
union select 'DHLDES-D',    'DHL DOMESTIC ECONOMY select-Doc',          'G',                         'I',       null,          @SA,                null
union select 'DHLESI',      'DHL ECONOMY select',                       'H',                         'I',       null,          @SA,                null
union select 'DHLBBE-D',    'DHL BREAK BULK ECONOMY-Doc',               'I',                         'I',       null,          @SA,                null
union select 'DHLJBX',      'DHL JUMBO BOX',                            'J',                         'I',       null,          @SA,                null
union select 'DHLTDK-D',    'DHL EXPRESS 9:00-Doc',                     'K',                         'I',       null,          @SA,                null
union select 'DHLTDL-D',    'DHL EXPRESS 10:30-Doc',                    'L',                         'I',       null,          @SA,                null
union select 'DHLTDM',      'DHL EXPRESS 10:30',                        'M',                         'I',       null,          @SA,                null
union select 'DHLDOM-D',    'DHL DOMESTIC EXPRESS-Doc',                 'N',                         'I',       null,          @SA,                null
union select 'DHLDOL-D',    'DHL DOM EXPRESS 10:30-Doc',                'O',                         'I',       null,          @SA,                null
union select 'DHLWPX',      'DHL EXPRESS WORLDWIDE',                    'P',                         'I',       null,          @SA,                null
union select 'DHLWMX',      'DHL MEDICAL EXPRESS',                      'Q',                         'I',       null,          @SA,                null
union select 'DHLGMB-D',    'DHL GLOBALMAIL BUSINESS-Doc',              'R',                         'I',       null,          @SA,                null
union select 'DHLSDX-D',    'DHL SAME DAY-Doc',                         'S',                         'I',       null,          @SA,                null
union select 'DHLTDT-D',    'DHL EXPRESS 12:00-Doc',                    'T',                         'I',       null,          @SA,                null
union select 'DHLECX-D',    'DHL EXPRESS WORLDWIDE-Doc',                'U',                         'I',       null,          @SA,                null
union select 'DHLEPP',      'DHL EUROPACK',                             'V',                         'I',       null,          @SA,                null
union select 'DHLESU-D',    'DHL ECONOMY select-Doc',                   'W',                         'I',       null,          @SA,                null
union select 'DHXPDL-D',    'DHL EXPRESS ENVELOPE-Doc',                 'X',                         'I',       null,          @SA,                null
union select 'DHTDYL',      'DHL EXPRESS 12:00',                        'Y',                         'I',       null,          @SA,                null
union select 'DHDC' ,       'DHL Destination Charges',                  'Z',                         'I',       null,          @SA,                null

--exec pr_Setup_Shipvias @Carrier, @ShipVias, 'IU' /* Insert/Update */, @BusinessUnit, @UserId, 'N' /* Is SmallPackageCarrier */;

Go

/*----------------------------------------------------------------------------*/
/* These are alphabetically sorted, please maintain that orders */
declare @ShipVias TShipViasTable, @Carrier  TCarrier = 'LTL', @BusinessUnit TBusinessUnit, @UserId TUserId, @SA TVarchar;
select @SA = '';

insert into @ShipVias
            (ShipVia,       Description,                                CarrierServiceCode, Status, StandardAttributes, SpecialServices)
      select '855B',        'GALE TRIANGLE',                            'M',                'A',    @SA,                 null
union select 'A55G',        'GALE TRIANGLE',                            'M',                'A',    @SA,                 null
union select 'AACT',        'AAA COOPER',                               'M',                'A',    @SA,                 null
union select 'AAIE',        'ADMIRAL AIR',                              'A',                'A',    @SA,                 null
union select 'ABFF',        'ABF FREIGHT SYSTEM',                       'M',                'A',    @SA,                 null
union select 'ABFS',        'ABF FREIGHT SYSTEMS',                      'M',                'A',    @SA,                 null
union select 'ACTF',        'ACTION FREIGHT',                           'M',                'A',    @SA,                 null
union select 'AEXB',        'ADMIRAL AIR',                              'A',                'A',    @SA,                 null
union select 'AFCS',        'AMERICAN FREIGHT',                         'M',                'A',    @SA,                 null
union select 'AFFT',        'AFFCO TRANSPORT INC.',                     'M',                'A',    @SA,                 null
union select 'AFNW',        'AFNW',                                     'M',                'A',    @SA,                 null
union select 'ALGW',        'ADMIRAL GROUND',                           'M',                'A',    @SA,                 null
union select 'ALWF',        'ALLIED TRUCK',                             'M',                'A',    @SA,                 null
union select 'AMAN',        'AMAN',                                     'M',                'A',    @SA,                 null
union select 'AMMY',        'AMERICAN FAST FREIGHT',                    'M',                'A',    @SA,                 null
union select 'AMXB',        'AM EXPRESS',                               'M',                'A',    @SA,                 null
union select 'ANSH',        'ALLIANCE SHIPPERS',                        'M',                'A',    @SA,                 null
union select 'ANTT',        'ARNOLD TRANSPORTATION',                    'M',                'A',    @SA,                 null
union select 'APIV',        'ALLIANCE SHIPPERS',                        'M',                'A',    @SA,                 null
union select 'APLL',        'APL LOGISTICS',                            'M',                'A',    @SA,                 null
union select 'APLS',        'AMERICAN PRESIDENTS LINE',                 'M',                'A',    @SA,                 null
union select 'APPG',        'APPLEGATE TRUCKING',                       'M',                'A',    @SA,                 null
union select 'APPL',        'APPAREL MOVERS',                           'M',                'A',    @SA,                 null
union select 'AQSM',        'ATS PAK TEK',                              'M',                'A',    @SA,                 null
union select 'ARPY',        'AMERICAN TRANSPORT',                       'M',                'A',    @SA,                 null
union select 'ASIV',        'ALLIANCE SHIPPERS',                        'M',                'A',    @SA,                 null
union select 'ATJL',        'ANDRUS TRANSPORTATION',                    'M',                'A',    @SA,                 null
union select 'AVRT',        'AVERITT EXPRESS',                          'M',                'A',    @SA,                 null
union select 'BCBQ',        'BCBQ TEAM',                                'M',                'A',    @SA,                 null
union select 'BCJI',        'BCJ TRUCKING INC.',                        'M',                'A',    @SA,                 null
union select 'BKHL',        'BACKHAUL',                                 'M',                'A',    @SA,                 null
union select 'BNAF',        'BAX GLOBAL',                               'M',                'A',    @SA,                 null
union select 'BNLS',        'BNSF LOGISTICS',                           'M',                'A',    @SA,                 null
union select 'BNUN',        'BARR-NUNN TRANSPORTATION',                 'M',                'A',    @SA,                 null
union select 'BOER',        'D BOER',                                   'M',                'A',    @SA,                 null
union select 'BOMN',        'D.M. BOWMAN',                              'M',                'A',    @SA,                 null
union select 'BQTF',        'APOLLO TRANSFFER',                         'M',                'A',    @SA,                 null
union select 'BSWT',        'BESTWAY',                                  'M',                'A',    @SA,                 null
union select 'BTVP',        'BEST OVERNITE-LTL SVC',                    'M',                'A',    @SA,                 null
union select 'BYLR',        'BAYLOR TRUCKING',                          'M',                'A',    @SA,                 null
union select 'CAIE',        'CALIF.TRANSPORT EX.',                      'C',                'A',    @SA,                 null
union select 'CAXD',        'CANNON EXPRESS',                           'M',                'A',    @SA,                 null
union select 'CDNK',        'CELADON',                                  'M',                'A',    @SA,                 null
union select 'CENF',        'CENTRAL FREIGHT',                          'M',                'A',    @SA,                 null
union select 'CFCF',        'CARDINAL FREIGHT CARRIERS',                'M',                'A',    @SA,                 null
union select 'CFFO',        'SDR DISTRIBUTION',                         'M',                'A',    @SA,                 null
union select 'CFIT',        'CFI TRANSPORT',                            'M',                'A',    @SA,                 null
union select 'CFSM',        'COLONIAL FREIGHT SYSTEMS',                 'C',                'A',    @SA,                 null
union select 'CFSO',        'CELESTIAL FRT SOLUTION',                   'M',                'A',    @SA,                 null
union select 'CFWY',        'CONSOLIDATED FREIGHTWAYS',                 'M',                'A',    @SA,                 null
union select 'CGMC',        'CITY FASHION/CITY LOGISTICS',              'M',                'A',    @SA,                 null
union select 'CGOR',        'CARGO TRANSPORTERS',                       'M',                'A',    @SA,                 null
union select 'CGXS',        'CARGO EXPRESS',                            'C',                'A',    @SA,                 null
union select 'CLLQ',        'Coyote Logistics',                         'M',                'A',    @SA,                 null
union select 'CNRC',        'CANADIAN NATIONAL RAILWAY',                'M',                'A',    @SA,                 null
union select 'CNTT',        'CENTRAL TRANSPORT',                        'M',                'A',    @SA,                 null
union select 'CNWY',        'CONWAY TRANSPORTATION',                    'M',                'A',    @SA,                 null
union select 'COGM',        'CONSOLIDATED GARMENT INDS.',               'M',                'A',    @SA,                 null
union select 'CPQL',        'COMPLETE LOGISTICS',                       'M',                'A',    @SA,                 null
union select 'CRCR',        'CRETE CARRIER CORPORATION',                'M',                'A',    @SA,                 null
union select 'CRPS',        'CRST VAN EXPEDITED',                       'M',                'A',    @SA,                 null
union select 'CRST',        'CRST INTERNATIONAL',                       'M',                'A',    @SA,                 null
union select 'CSRD',        'CROSSROADS',                               'M',                'A',    @SA,                 null
union select 'CTEV',        'CALIFORNIA TRANSPORT ENTERPRISES INC',     'M',                'A',    @SA,                 null
union select 'CTII',        'CENTRAL TRANSPORT',                        'M',                'A',    @SA,                 null
union select 'CUPU',        'CUSTOMER PICK UP',                         'M',                'A',    @SA,                 null
union select 'CVEN',        'COVENANT TRANSPORT',                       'M',                'A',    @SA,                 null
union select 'DAFH',        'DEPENDABLE AIR FREIGHT',                   'AE',               'A',    @SA,                 null
union select 'DART',        'DART TRANSIT COMPANY',                     'M',                'A',    @SA,                 null
union select 'DATT',        'DAT TRUCKING',                             'M',                'A',    @SA,                 null
union select 'DCGD',        'DCG DISTRIBUTION',                         'M',                'A',    @SA,                 null
union select 'DEBE',        'DEBOER',                                   'M',                'A',    @SA,                 null
union select 'DHLC',        'DHL AIRWAYS INC.',                         'A',                'A',    @SA,                 null
union select 'DID',         'DIAMOND DELIVERY',                         'L',                'A',    @SA,                 null
union select 'DINL',        'DART INTERNATIONAL',                       'M',                'A',    @SA,                 null
union select 'DLTL',        'DAY & ROSS',                               'M',                'A',    @SA,                 null
union select 'DMBW',        'DM BOWMAN',                                'M',                'A',    @SA,                 null
union select 'DMLT',        'D & M LGISTICS',                           'M',                'A',    @SA,                 null
union select 'DMSD',        'DMS EXPRESS',                              'M',                'A',    @SA,                 null
union select 'DOLR',        'DOTLINE TRANSPORTAION',                    'M',                'A',    @SA,                 null
union select 'DPHE',        'DEPENDABLE HIGHWAY EXPRESS',               'C',                'A',    @SA,                 null
union select 'DRXQ',        'DART EXPRESS CANADA LTD',                  'M',                'A',    @SA,                 null
union select 'DSGR',        'DESIGN TRANSPROTATION',                    'M',                'A',    @SA,                 null
union select 'DUGN',        'DUGAN TRUCK',                              'M',                'A',    @SA,                 null
union select 'DYXI',        'DYNAMIC',                                  'M',                'A',    @SA,                 null
union select 'EASI',        'ESSENTIAL AIR',                            'A',                'A',    @SA,                 null
union select 'ECHS',        'ECHO GLOBAL LOGISTICS',                    'M',                'A',    @SA,                 null
union select 'EDXI',        'EDI EXPRESS',                              'M',                'A',    @SA,                 null
union select 'EFWI',        'EASTERN FREIGHT WAYS,INC',                 'M',                'A',    @SA,                 null
union select 'EGAH',        'EAGLE AIR',                                'A',                'A',    @SA,                 null
union select 'EGPO',        'EAGLE TRANSPORTATION CO',                  'M',                'A',    @SA,                 null
union select 'ENGL',        'CRENGLAND',                                'M',                'A',    @SA,                 null
union select 'EUSA',        'EAGLE AIR',                                'A',                'A',    @SA,                 null
union select 'EXEL',        'EXCEL TRASPORTATION',                      'M',                'A',    @SA,                 null
union select 'EXLA',        'ESTES EXPRESS',                            'M',                'A',    @SA,                 null
union select 'EZWE',        'EZ WORLD WIDE EXPRESS',                    'A',                'A',    @SA,                 null
union select 'F&V',         'F & V TRUCKING',                           'M',                'A',    @SA,                 null
union select 'FABT',        'FABCO TRUCKING',                           'M',                'A',    @SA,                 null
union select 'FDCC',        'FEDEX SURFACE TRANSPORTATION',             'U',                'A',    @SA,                 null
union select 'FDEG',        'FEDEX GROUND COLLECT',                     'C',                'A',    @SA,                 null
union select 'FDFF',        'FEDEX AIR EXPEDITE',                       'A',                'A',    @SA,                 null
union select 'FEET',        'FFE TRANSPORTATION SERV',                  'M',                'A',    @SA,                 null
union select 'FMIX',        'FMI',                                      'M',                'A',    @SA,                 null
union select 'FMWT',        'FOX MIDWEST',                              'M',                'A',    @SA,                 null
union select 'FTXP',        'FIRST EXPRESS',                            'M',                'A',    @SA,                 null
union select 'FWDN',        'FORWARD AIR',                              'M',                'A',    @SA,                 null
union select 'FXFE',        'FEDEX FREIGHT LTL EAST',                   'M',                'A',    @SA,                 null
union select 'FXFW',        'FEDEX FREIGHT LTL WEST',                   'M',                'A',    @SA,                 null
union select 'FXNL',        'FEDERAL EXPRESS NATIONAL',                 'M',                'A',    @SA,                 null
union select 'GBEA',        'GILBERT USA',                              'M',                'A',    @SA,                 null
union select 'GBXI',        'GILBERT EXPRESS',                          'M',                'A',    @SA,                 null
union select 'GCTQ',        'GULF COAST TRANSPORT',                     'M',                'A',    @SA,                 null
union select 'GESS',        'GENESIS TRUCKING',                         'M',                'A',    @SA,                 null
union select 'GILW',        'GILBERTWEST',                              'M',                'A',    @SA,                 null
union select 'GITD',        'G.I. TRUCKING',                            'M',                'A',    @SA,                 null
union select 'GLLD',        'GLEN COE /TRUCKER',                        'M',                'A',    @SA,                 null
union select 'GLTN',        'PERFORMANCE TEAM/GALE TRIANGLE INC.',      'M',                'A',    @SA,                 null
union select 'GOBA',        'GLOBAL TRANSPORTAION',                     'M',                'A',    @SA,                 null
union select 'GORK',        'GORDON TRUCKING',                          'M',                'A',    @SA,                 null
union select 'GPTC',        'G & P TRUCKING',                           'M',                'A',    @SA,                 null
union select 'GTSD',        'GAINEY TRANSPORTATION SERVICES',           'M',                'A',    @SA,                 null
union select 'GURZ',        'GURZA INTERNATIONAL LIMITED',              'M',                'A',    @SA,                 null
union select 'HBGI',        'HBGI',                                     'M',                'A',    @SA,                 null
union select 'HBXL',        'HILL BROTHERS',                            'M',                'A',    @SA,                 null
union select 'HCIN',        'HUB CITY INDIANAPOLIS',                    'M',                'A',    @SA,                 null
union select 'HFS',         'HONOLULU HONFREIGHT',                      'M',                'A',    @SA,                 null
union select 'HJBT',        'J.B. HUNT TRANSPORT',                      'M',                'A',    @SA,                 null
union select 'HKEY',        'HAWK EYE',                                 'M',                'A',    @SA,                 null
union select 'HLTG',        'HIGHLAND TRANSPORTATION',                  'M',                'A',    @SA,                 null
union select 'HMHE',        'HMH',                                      'M',                'A',    @SA,                 null
union select 'HRMN',        'HRMN',                                     'M',                'A',    @SA,                 null
union select 'HSAR',        'HOOSIAR AIR TRANSPORT',                    'A',                'A',    @SA,                 null
union select 'HUBG',        'HUB CITY GROUP',                           'M',                'A',    @SA,                 null
union select 'IDSL',        'INTERMODAL SERVICES',                      'M',                'A',    @SA,                 null
union select 'IMWS',        'INTERMODAL',                               'M',                'A',    @SA,                 null
union select 'INII',        'INTERSTATE NJ',                            'M',                'A',    @SA,                 null
union select 'INST',        'INTERSTATE',                               'M',                'A',    @SA,                 null
union select 'INTD',        'INTERSTATE DISTRIBUTOR',                   'M',                'A',    @SA,                 null
union select 'IRDC',        'INTEGRITY RETAIL DISTRIBUTIN INC.',        'M',                'A',    @SA,                 null
union select 'ISCO',        'INTERMODEL SALES CORPORATION',             'M',                'A',    @SA,                 null
union select 'JADE',        'JA-DEL',                                   'M',                'A',    @SA,                 null
union select 'JAGH',        'JAG LOGISTICS',                            'M',                'A',    @SA,                 null
union select 'JBHT',        'J.B.HUNT',                                 'M',                'A',    @SA,                 null
union select 'JCPT',        'NNEW ENGLAND MOTOR FREIGT',                'M',                'A',    @SA,                 null
union select 'KBTL',        'BRIAN KURTZ TRUCKING',                     'M',                'A',    @SA,                 null
union select 'KBTR',        'K&B TRANSPORTATION',                       'M',                'A',    @SA,                 null
union select 'KIGE',        'KINGS EXPRESS',                            'M',                'A',    @SA,                 null
union select 'KNIG',        'KNIGHT TRANSPORTATION INC',                'M',                'A',    @SA,                 null
union select 'KOHC',        'INTERSTATE',                               'M',                'A',    @SA,                 null
union select 'KOHL',        'KOHLS BACKHAUL',                           'M',                'A',    @SA,                 null
union select 'KYSO',        'KEYSTONE TRUCKING',                        'M',                'A',    @SA,                 null
union select 'LAND',        'LAND TRANSPORT',                           'M',                'A',    @SA,                 null
union select 'LDLO',        'LAD FORD',                                 'M',                'A',    @SA,                 null
union select 'LHBT',        'LHP TRANSPORTATION',                       'M',                'A',    @SA,                 null
union select 'MCIF',        'MONETTI',                                  'M',                'A',    @SA,                 null
union select 'MDTA',        'MIDLAND TRANSPORTATION CO',                'M',                'A',    @SA,                 null
union select 'MGAS',        'MORGAN SOUTHERN',                          'M',                'A',    @SA,                 null
union select 'MILI',        'MIRACLE LOGISTICS',                        'M',                'A',    @SA,                 null
union select 'MIQI',        'MIQI DITRIBUTION',                         'M',                'A',    @SA,                 null
union select 'MKII',        'MARK 7',                                   'M',                'A',    @SA,                 null
union select 'MLOG',        'MENLO WORLDWIDE',                          'M',                'A',    @SA,                 null
union select 'MOAV',        'MACH 1',                                   'A',                'A',    @SA,                 null
union select 'MOWS',        'MOTOT WEST INC.',                          'M',                'A',    @SA,                 null
union select 'MVT-',        'MVT. SERVICES,INC',                        'M',                'A',    @SA,                 null
union select 'MWUS',        'MIDWEST',                                  'M',                'A',    @SA,                 null
union select 'MXOT',        'MAXONX TRUCKING, INC',                     'M',                'A',    @SA,                 null
union select 'NAFT',        'NAFT',                                     'M',                'A',    @SA,                 null
union select 'NART',        'NART',                                     'M',                'A',    @SA,                 null
union select 'NAVE',        'NAVAJO EXPRESS',                           'M',                'A',    @SA,                 null
union select 'NDCW',        'NFI INDUSTRYS',                            'M',                'A',    @SA,                 null
union select 'NDWC',        'NFINDUSTRY (DO NOT USE) INVALID!',         'C',                'A',    @SA,                 null
union select 'NEMF',        'NEW ENGLAND MOTOR FREIGHT',                'M',                'A',    @SA,                 null
union select 'NEXD',        'NEXT DAY MOTOR FREIGHT',                   'M',                'A',    @SA,                 null
union select 'NFTI',        'NATIONAL FREIGHT',                         'M',                'A',    @SA,                 null
union select 'NLRT',        'NATIONAL RETAIL SYSTEMS',                  'M',                'A',    @SA,                 null
union select 'NRSH',        'NATIONAL RETAIL TRANSPORTATION',           'M',                'A',    @SA,                 null
union select 'NRTV',        'NATIONAL RETAIL TRANSPORTATION',           'M',                'A',    @SA,                 null
union select 'NTRA',        'NORTRAN',                                  'L',                'A',    @SA,                 null
union select 'NWDR',        'NATION WIDE TRANSPORT',                    'M',                'A',    @SA,                 null
union select 'ODFL',        'OLD DOMINION',                             'M',                'A',    @SA,                 null
union select 'OHF',         'OAK HARBOR FRT',                           'M',                'A',    @SA,                 null
union select 'OLD',         'OLD DOMINION',                             'M',                'A',    @SA,                 null
union select 'ORGC',        'ORANGE COURIER',                           'M',                'A',    @SA,                 null
union select 'OTMO',        'ON TIME TRANSPORTATION',                   'M',                'A',    @SA,                 null
union select 'OVNT',        'OVNT NYELLOW FREIGHT SYSTEM',              'M',                'A',    @SA,                 null
union select 'PAXR',        'PAX',                                      'M',                'A',    @SA,                 null
union select 'PCCT',        'PACER CARTAGE',                            'M',                'A',    @SA,                 null
union select 'PCIG',        'PCI TRANSPORTATION INC.',                  'M',                'A',    @SA,                 null
union select 'PDSS',        'PDS TRUCKING',                             'M',                'A',    @SA,                 null
union select 'PFLP',        'PACIFIC LOGISTICS',                        'M',                'A',    @SA,                 null
union select 'PFMP',        'PERFORMANCE',                              'M',                'A',    @SA,                 null
union select 'PGLI',        'PACER TRANSPORTATION',                     'L',                'A',    @SA,                 null
union select 'PJAX',        'PJAX',                                     'M',                'A',    @SA,                 null
union select 'PMXL',        'PAYSTAR LOGISTICS',                        'M',                'A',    @SA,                 null
union select 'POHP',        'POHL TRANSPORTATION',                      'M',                'A',    @SA,                 null
union select 'PSAT',        'PALMETTO STATE TRANSPORTATION',            'M',                'A',    @SA,                 null
union select 'PTTL',        'PRIME TRANSPORT',                          'M',                'A',    @SA,                 null
union select 'PXCI',        'PAX',                                      'M',                'A',    @SA,                 null
union select 'QPMT',        'JB HUNT TRANSPORTATION',                   'M',                'A',    @SA,                 null
union select 'RBTW',        'C.H.ROBINSON',                             'M',                'A',    @SA,                 null
union select 'RCRD',        'RECORD TRANSPORT INC.',                    'M',                'A',    @SA,                 null
union select 'RDWY',        'ROADWAY',                                  'M',                'A',    @SA,                 null
union select 'RETL',        'USF REDDAWAY',                             'M',                'A',    @SA,                 null
union select 'RFXI',        'REFRIGERATED FOOD XPRESS',                 'M',                'A',    @SA,                 null
union select 'RLOR',        'ROLO TRANSPORTATION',                      'M',                'A',    @SA,                 null
union select 'ROCN',        'ROCOR TRANSPORTATION CO',                  'M',                'A',    @SA,                 null
union select 'ROEV',        'ROEHL TRANSPORTATION',                     'C',                'A',    @SA,                 null
union select 'ROFF',        'ROFF LOGISTICS INC',                       'M',                'A',    @SA,                 null
union select 'RUAN',        'RUAN TRANSPORT CORP',                      'M',                'A',    @SA,                 null
union select 'RVGL',        'RAIL VAN',                                 'M',                'A',    @SA,                 null
union select 'RYSS',        'RYDER TRANSPORTATION',                     'M',                'A',    @SA,                 null
union select 'SAIA',        'MOTOR FREIGHT LINE INC',                   'M',                'A',    @SA,                 null
union select 'SCLD',        'SCULLY DISTRIBUTION SERVICES',             'M',                'A',    @SA,                 null
union select 'SCNN',        'SCHNEIDER',                                'M',                'A',    @SA,                 null
union select 'SEFL',        'SWIFT INTERMODAL-SOUTHER EASTERN FREIGHT', 'M',                'A',    @SA,                 null
union select 'SHAF',        'SHAFFER',                                  'M',                'A',    @SA,                 null
union select 'SHKE',        'SHARKEY',                                  'C',                'A',    @SA,                 null
union select 'SITM',        'SITTON MOTOR LINE',                        'M',                'A',    @SA,                 null
union select 'SLEF',        'SUNLINE EXPRESS',                          'M',                'A',    @SA,                 null
union select 'SLSN',        'SALSON',                                   'C',                'A',    @SA,                 null
union select 'SNCK',        'SCHNEIDER NATIONAL',                       'M',                'A',    @SA,                 null
union select 'SOCS',        'SECO TRANSPORTATION',                      'M',                'A',    @SA,                 null
union select 'SQTK',        'SPIRIT TRUCK LINE',                        'M',                'A',    @SA,                 null
union select 'SSHA',        'STREAMLINE',                               'M',                'A',    @SA,                 null
union select 'STFT',        'STEADFAST TRANSPORTATION',                 'M',                'A',    @SA,                 null
union select 'STTR',        'STEVENS TRANSPORT',                        'M',                'A',    @SA,                 null
union select 'SWFT',        'SWIFT TRANSPORTATION INC.',                'M',                'A',    @SA,                 null
union select 'TAEQ',        'TARGET EXPRESS',                           'M',                'A',    @SA,                 null
union select 'TAKN',        'TAKEN',                                    'M',                'A',    @SA,                 null
union select 'TIMP',        'TIMELY TRANSPORT',                         'M',                'A',    @SA,                 null
union select 'TLAY',        'TIMCO LOGISTICS SYSTEMS INC.',             'C',                'A',    @SA,                 null
union select 'TNTT',        'TNT BEST',                                 'M',                'A',    @SA,                 null
union select 'TOTA',        'TOTALLINE TRANSPORT',                      'M',                'A',    @SA,                 null
union select 'TPIL',        'TPIL',                                     'M',                'A',    @SA,                 null
union select 'TPQL',        'TRANSPLACE',                               'M',                'A',    @SA,                 null
union select 'TROS',        'TRANSPORT SPECIALIST',                     'M',                'A',    @SA,                 null
union select 'TRPL',        'TRASPLACE',                                'M',                'A',    @SA,                 null
union select 'TRSL',        'TRANSX LIMITED',                           'M',                'A',    @SA,                 null
union select 'UNIQ',        'UNIQUE TRUCKING',                          'M',                'A',    @SA,                 null
union select 'UNIS',        'UNISHIPPER',                               'M',                'A',    @SA,                 null
union select 'UPGF',        'UPS FREIGHT',                              'M',                'A',    @SA,                 null
union select 'UPSN',        'UPS',                                      'U',                'A',    @SA,                 null
union select 'UPSN',        'UPS',                                      'U',                'A',    @SA,                 null
union select 'USCS',        'UPS SUPPLY CHAIN SOLUTIONS',               'A',                'A',    @SA,                 null
union select 'USFB',        'USF',                                      'C',                'A',    @SA,                 null
union select 'USIT',        'USA TRUCKING',                             'M',                'A',    @SA,                 null
union select 'USRE',        'US EXPRESS DEDICATED',                     'M',                'A',    @SA,                 null
union select 'USXI',        'US EXPRESS',                               'M',                'A',    @SA,                 null
union select 'UTRI',        'USA TRUCK, INC',                           'M',                'A',    @SA,                 null
union select 'UWDC',        'UWDC',                                     'C',                'A',    @SA,                 null
union select 'VIKN',        'VIKING',                                   'M',                'A',    @SA,                 null
union select 'VITR',        'VITRANS',                                  'M',                'A',    @SA,                 null
union select 'VKGT',        'VIKING',                                   'M',                'A',    @SA,                 null
union select 'VSXP',        'WRAGTIME',                                 'M',                'A',    @SA,                 null
union select 'WALM',        'WALMART',                                  'M',                'A',    @SA,                 null
union select 'WENP',        'WERNER',                                   'M',                'A',    @SA,                 null
union select 'WERN',        'WERNER TRANSPORTATION',                    'M',                'A',    @SA,                 null
union select 'WIEB',        'WIEBE',                                    'M',                'A',    @SA,                 null
union select 'WKNG',        'WATKINS',                                  'M',                'A',    @SA,                 null
union select 'WPLG',        'WEN-PARKER',                               'M',                'A',    @SA,                 null
union select 'WQCT',        'WEST COAST TRANSPORT',                     'M',                'A',    @SA,                 null
union select 'WSTR',        'WESTERN REGIONAL',                         'M',                'A',    @SA,                 null
union select 'WSXI',        'WSXI',                                     'M',                'A',    @SA,                 null
union select 'WTGG',        'WTG LOGISTICS INTERMODAL',                 'C',                'A',    @SA,                 null
union select 'WTON',        'WILLIS SHAW',                              'M',                'A',    @SA,                 null
union select 'WWEX',        'WorldWide Express',                        'M',                'A',    @SA,                 null
union select 'WXPI',        'WESTERN EXPRESS',                          'M',                'A',    @SA,                 null
union select 'XTLT',        'XTL TRANSPORT INC.',                       'M',                'A',    @SA,                 null
union select 'YFSY',        'YELLOW FREIGHT SYSTEM',                    'M',                'A',    @SA,                 null
union select 'YFSY',        'YELLOW FREIGHT SYSTEM',                    'M',                'A',    @SA,                 null
union select 'YRC',         'YRC INC',                                  'M',                'A',    @SA,                 null
union select 'YRCI',        'YRC INC',                                  'M',                'A',    @SA,                 null
union select 'ZMTL',        'ZIMMERMAN TRUCK LINES',                    'M',                'A',    @SA,                 null

exec pr_Setup_Shipvias @Carrier, @ShipVias, 'IU' /* Insert/Update */, @BusinessUnit, @UserId, 'N' /* Is SmallPackageCarrier */;

Go

/*----------------------------------------------------------------------------*/
declare @ShipVias TShipViasTable, @Carrier  TCarrier = 'Generic', @BusinessUnit TBusinessUnit, @UserId TUserId;

insert into @ShipVias
            (ShipVia,            Description,                                CarrierServiceCode,          Status,    BusinessUnit,  StandardAttributes, SpecialServices)
      select 'SEE PO',           'SEE P.O.',                                 'M',                         'A',       null,          '',                 null
union select 'LTL',              'LTL Carrier',                              'M',                         'A',       null,          '',                 null
union select 'CFR',              'Call for Routing',                         'M',                         'A',       null,          '',                 null
union select 'TBD',              'To be determined',                         'M',                         'A',       null,          '',                 null
union select 'BEST WAY',         'Contact Traffic -LTL',                     'BEST WAY',                  'A',       null,          null,               null
union select 'BEST WAY COLL',    'Contact Traffic - B/W Collect',            'BEST WAY COLL',             'A',       null,          null,               null

exec pr_Setup_Shipvias @Carrier, @ShipVias, 'IU' /* Insert/Update */, @BusinessUnit, @UserId, 'N' /* Is SmallPackageCarrier */;

Go

/*----------------------------------------------------------------------------*/
/* ADSI Codes for Rate and Ship API - These have to be enabled when client using ADSI */
declare @ShipVias TShipViasTable, @Carrier  TCarrier = 'Generic', @BusinessUnit TBusinessUnit, @UserId TUserId;

insert into @ShipVias
            (ShipVia,            Description,                                CarrierServiceCode,          Status,    BusinessUnit,  StandardAttributes,                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         SpecialServices)
      select 'BESTRATE',         'Best of All',                              'BESTRATE',                  'A',       null,          '<LABELIMAGETYPE>PNG</LABELIMAGETYPE><LABELSTOCKSIZE>PAPER_4X6</LABELSTOCKSIZE><CARRIERSERVICECODE>BESTRATE</CARRIERSERVICECODE><PACKAGINGTYPE></PACKAGINGTYPE><RATEREQUESTTYPES>LIST</RATEREQUESTTYPES><SIGNATUREOPTIONTYPE>DIRECT</SIGNATUREOPTIONTYPE><ADDINSURANCE>NO</ADDINSURANCE><ISCODSHIPMENT>false</ISCODSHIPMENT>',                                                                                                                                                                              null
union select 'BESTUPS',          'Best of UPS',                              'BESTUPS',                   'A',       null,          '<LABELIMAGETYPE>PNG</LABELIMAGETYPE><LABELSTOCKSIZE>PAPER_4X6</LABELSTOCKSIZE><CARRIERSERVICECODE>BESTUPS</CARRIERSERVICECODE><PACKAGINGTYPE></PACKAGINGTYPE><RATEREQUESTTYPES>LIST</RATEREQUESTTYPES><SIGNATUREOPTIONTYPE>DIRECT</SIGNATUREOPTIONTYPE><ADDINSURANCE>NO</ADDINSURANCE><ISCODSHIPMENT>false</ISCODSHIPMENT>',                                                                                                                                                                               null
union select 'BESTFEDX',         'Best of Fedex',                            'BESTFEDEX',                 'A',       null,          '<LABELIMAGETYPE>PNG</LABELIMAGETYPE><LABELSTOCKSIZE>PAPER_4X6</LABELSTOCKSIZE><CARRIERSERVICECODE>BESTFEDEX</CARRIERSERVICECODE><PACKAGINGTYPE></PACKAGINGTYPE><RATEREQUESTTYPES>LIST</RATEREQUESTTYPES><SIGNATUREOPTIONTYPE>DIRECT</SIGNATUREOPTIONTYPE><ADDINSURANCE>NO</ADDINSURANCE><ISCODSHIPMENT>false</ISCODSHIPMENT>',                                                                                                                                                                             null
union select 'BESTUPSFDX',       'Best of UPS and Fedex',                    'BESTUPSFDX',                'A',       null,          '<LABELIMAGETYPE>PNG</LABELIMAGETYPE><LABELSTOCKSIZE>PAPER_4X6</LABELSTOCKSIZE><CARRIERSERVICECODE>BESTUPSFDX</CARRIERSERVICECODE><PACKAGINGTYPE></PACKAGINGTYPE><RATEREQUESTTYPES>LIST</RATEREQUESTTYPES><SIGNATUREOPTIONTYPE>DIRECT</SIGNATUREOPTIONTYPE><ADDINSURANCE>NO</ADDINSURANCE><ISCODSHIPMENT>false</ISCODSHIPMENT>',                                                                                                                                                                            null
union select 'BESTGND',          'Best Ground',                              'BESTGND',                   'A',       null,          '<LABELIMAGETYPE>PNG</LABELIMAGETYPE><LABELSTOCKSIZE>PAPER_4X6</LABELSTOCKSIZE><CARRIERSERVICECODE>BESTGND</CARRIERSERVICECODE><PACKAGINGTYPE></PACKAGINGTYPE><RATEREQUESTTYPES>LIST</RATEREQUESTTYPES><SIGNATUREOPTIONTYPE>DIRECT</SIGNATUREOPTIONTYPE><ADDINSURANCE>NO</ADDINSURANCE><ISCODSHIPMENT>false</ISCODSHIPMENT>',                                                                                                                                                                               null
union select 'BEST1DAY',         'Best 1 Day',                               'BEST1DAY',                  'A',       null,          '<LABELIMAGETYPE>PNG</LABELIMAGETYPE><LABELSTOCKSIZE>PAPER_4X6</LABELSTOCKSIZE><CARRIERSERVICECODE>BEST1DAY</CARRIERSERVICECODE><PACKAGINGTYPE></PACKAGINGTYPE><RATEREQUESTTYPES>LIST</RATEREQUESTTYPES><SIGNATUREOPTIONTYPE>DIRECT</SIGNATUREOPTIONTYPE><ADDINSURANCE>NO</ADDINSURANCE><ISCODSHIPMENT>false</ISCODSHIPMENT>',                                                                                                                                                                              null
union select 'BEST2DAY',         'Best 2 Day',                               'BEST2DAY',                  'A',       null,          '<LABELIMAGETYPE>PNG</LABELIMAGETYPE><LABELSTOCKSIZE>PAPER_4X6</LABELSTOCKSIZE><CARRIERSERVICECODE>BEST2DAY</CARRIERSERVICECODE><PACKAGINGTYPE></PACKAGINGTYPE><RATEREQUESTTYPES>LIST</RATEREQUESTTYPES><SIGNATUREOPTIONTYPE>DIRECT</SIGNATUREOPTIONTYPE><ADDINSURANCE>NO</ADDINSURANCE><ISCODSHIPMENT>false</ISCODSHIPMENT>',                                                                                                                                                                              null
union select 'BEST3DAY',         'Best 3 Day',                               'BEST3DAY',                  'A',       null,          '<LABELIMAGETYPE>PNG</LABELIMAGETYPE><LABELSTOCKSIZE>PAPER_4X6</LABELSTOCKSIZE><CARRIERSERVICECODE>BEST3DAY</CARRIERSERVICECODE><PACKAGINGTYPE></PACKAGINGTYPE><RATEREQUESTTYPES>LIST</RATEREQUESTTYPES><SIGNATUREOPTIONTYPE>DIRECT</SIGNATUREOPTIONTYPE><ADDINSURANCE>NO</ADDINSURANCE><ISCODSHIPMENT>false</ISCODSHIPMENT>',                                                                                                                                                                              null
union select 'BESTAIR',          'Best Air',                                 'BESTAIR',                   'A',       null,          '<LABELIMAGETYPE>PNG</LABELIMAGETYPE><LABELSTOCKSIZE>PAPER_4X6</LABELSTOCKSIZE><CARRIERSERVICECODE>BESTAIR</CARRIERSERVICECODE><PACKAGINGTYPE></PACKAGINGTYPE><RATEREQUESTTYPES>LIST</RATEREQUESTTYPES><SIGNATUREOPTIONTYPE>DIRECT</SIGNATUREOPTIONTYPE><ADDINSURANCE>NO</ADDINSURANCE><ISCODSHIPMENT>false</ISCODSHIPMENT>',                                                                                                                                                                               null
union select 'BESTINT',          'Best International',                       'BESTINT',                   'A',       null,          '<LABELIMAGETYPE>PNG</LABELIMAGETYPE><LABELSTOCKSIZE>PAPER_4X6</LABELSTOCKSIZE><CARRIERSERVICECODE>BESTINT</CARRIERSERVICECODE><PACKAGINGTYPE></PACKAGINGTYPE><RATEREQUESTTYPES>LIST</RATEREQUESTTYPES><SIGNATUREOPTIONTYPE>DIRECT</SIGNATUREOPTIONTYPE><ADDINSURANCE>NO</ADDINSURANCE><ISCODSHIPMENT>false</ISCODSHIPMENT>',                                                                                                                                                                               null

--exec pr_Setup_Shipvias @Carrier, @ShipVias, 'IU' /* Insert/Update */, @BusinessUnit, @UserId;

Go

/*----------------------------------------------------------------------------*/
/* FORWARD AIR */
declare @ShipVias TShipViasTable,  @Carrier  TCarrier = 'FORWARD AIR',  @BusinessUnit TBusinessUnit, @UserId TUserId;
insert into @ShipVias
            (ShipVia,    Description,                              CarrierServiceCode,                 Status, StandardAttributes,                      SpecialServices)
      select 'FWRD',     null,                                     'M',                                'I',    '<SERVICELEVEL>null</SERVICELEVEL>',     null

--exec pr_Setup_Shipvias @Carrier, @ShipVias, 'IU' /* Insert/Update */, @BusinessUnit, @UserId, 'N' /* Is SmallPackageCarrier */;

Go

/*----------------------------------------------------------------------------*/
/* PUROLATOR */
declare @ShipVias TShipViasTable, @BusinessUnit TBusinessUnit, @UserId TUserId, @SA TVarChar = '';
declare  @Carrier TCarrier = 'PURO',  @SCAC TSCAC = 'PURO';

insert into @ShipVias
            (ShipVia,            Description,                      CarrierServiceCode,                 Status, StandardAttributes, SpecialServices)
      select 'PURO GROUND',      'Purolator Ground',               'PURO GROUND',                      'A',    @SA,                null
union select 'PURO NEXT DAY',    'Purolator Next Day',             'PURO NEXT DAY',                    'A',    @SA,                null
union select 'PURO SATURDAY',    'Purolator Saturday Delivery',    'PURO SATURDAY',                    'A',    @SA,                null
union select 'PURO-3PB-1030AM',  'PURO Next 10:30am 3rd Party',    'PURO-3PB-1030AM',                  'A',    @SA,                null
union select 'PURO-3PB-GRND',    'PURO Ground 3rd Party Bill',     'PURO-3PB-GRND',                    'A',    @SA,                null
union select 'PURO-3PB-NEXT',    'PURO NextDay 3rd Party Billing', 'PURO-3PB-NEXT',                    'A',    @SA,                null

--exec pr_Setup_Shipvias @Carrier, @ShipVias, 'IU' /* Insert/Update */, @BusinessUnit, @UserId, 'Y' /* Is SmallPackageCarrier */, @SCAC;

Go

/*----------------------------------------------------------------------------*/
/* TFORCE */
declare @ShipVias TShipViasTable, @BusinessUnit TBusinessUnit, @UserId TUserId, @SA TVarChar = '';
declare  @Carrier TCarrier = 'TFORCE',  @SCAC TSCAC = 'TFORCE';

insert into @ShipVias
            (ShipVia,            Description,                      CarrierServiceCode,                 Status, StandardAttributes)
      select 'TFORCE-AT',        'TF Same Day Air Special',        'TForce Same Day Air SPECIAL DELIVERY',
                                                                                                       'A',   '<SERVICELEVEL>TFORCE Air Special</SERVICELEVEL>'
/* Next Day */
union select 'TFORCE-A9',        'TF Next Day by 9:00 AM',         'TForce Next Day By 9:00 AM',       'A',    @SA
union select 'TFORCE-A1',        'TF Next Day by 10:00 AM',        'TForce Next Day By 10:00 AM',      'A',    @SA
union select 'TFORCE-AN',        'TF Next Day by Noon',            'TForce Next Day By Noon',          'A',    @SA
union select 'TFORCE-A3',        'TF Next Day by 3pm',             'TForce Next Day By 3:00 PM',       'A',    @SA
/* Second Day */
union select 'TFORCE-AD',        'TF Second Day',                  'TForce Second Day',                'A',    @SA
/* Ground */
union select 'TFORCE-GE',        'TF Ground Expedited',            'TForce Ground Expedited',          'A',    @SA
union select 'TFORCE-GD',        'TF Ground by 5:00',              'TForce Ground by 5:00',            'A',    @SA
union select 'TFORCE-G9',        'TF Ground By 9:00 AM',           'TForce Ground By 9:00 AM',         'A',    @SA
union select 'TFORCE-G1',        'TF Ground By 10:00 AM',          'TForce Ground By 10:00 AM',        'A',    @SA
union select 'TFORCE-GN',        'TF Ground by Noon',              'TForce Ground by Noon',            'A',    @SA
/* Propak */
union select 'TFORCE-AP',        'TF Propak By Noon',              'TForce Propak By Noon',            'A',    @SA

--exec pr_Setup_Shipvias @Carrier, @ShipVias, 'IU' /* Insert/Update */, @BusinessUnit, @UserId, 'Y' /* Is SmallPackageCarrier */, @SCAC;

Go

/*----------------------------------------------------------------------------*/
/* CANADAPOST */
declare @ShipVias TShipViasTable, @BusinessUnit TBusinessUnit, @UserId TUserId, @SA TVarChar = '';
declare  @Carrier TCarrier = 'CANADAPOST',  @SCAC TSCAC = 'CANADAPOST';

insert into @ShipVias
            (ShipVia,            Description,                      CarrierServiceCode,                 Status, StandardAttributes,                          SpecialServices)
      select 'CP-Expedited',     'Canada Post Expedited',          'CP-EXPEDITED',                     'A',    '<SERVICELEVEL>EXPEDITED</SERVICELEVEL>',    null
union select 'CP-Express',       'Canada Post Express',            'CP-EXPRESS',                       'A',    '<SERVICELEVEL>EXPRESS</SERVICELEVEL>',      null

--exec pr_Setup_Shipvias @Carrier, @ShipVias, 'IU' /* Insert/Update */, @BusinessUnit, @UserId, 'Y' /* Is SmallPackageCarrier */, @SCAC;

Go

/*----------------------------------------------------------------------------*/
/* CANPAR */
declare @ShipVias TShipViasTable, @BusinessUnit TBusinessUnit, @UserId TUserId, @SA TVarChar = '';
declare @Carrier TCarrier = 'CANPAR',  @SCAC TSCAC = 'CANPAR';

insert into @ShipVias
            (ShipVia,            Description,                      CarrierServiceCode,                 Status,  StandardAttributes,                            SpecialServices)
      select 'CANPAR-EXPRESS',   'Canpar Express',                 'CANPAR-EXPRESS',                   'A',     '<SERVICELEVEL>CANPAR-EXPRESS</SERVICELEVEL>', null
union select 'CANPAR-GROUND',    'Canpar Ground',                  'CANPAR-GROUND',                    'A',     '<SERVICELEVEL>CANPAR-GROUND</SERVICELEVEL>',  null

--exec pr_Setup_Shipvias @Carrier, @ShipVias, 'IU' /* Insert/Update */, @BusinessUnit, @UserId, 'Y' /* Is SmallPackageCarrier */, @SCAC;

Go

/*----------------------------------------------------------------------------*/
/* LOOMIS */
declare @ShipVias TShipViasTable, @BusinessUnit TBusinessUnit, @UserId TUserId, @SA TVarChar = '';
declare @Carrier TCarrier = 'LOOMIS',  @SCAC TSCAC = 'LOOMIS';

insert into @ShipVias
            (ShipVia,            Description,                      CarrierServiceCode,                 Status, StandardAttributes,                                            SpecialServices)
      select 'LOOMIS-EXPRESS',   'Loomis Express',                 'LOOMIS-EXPRESS',                   'A',    '<SERVICELEVEL>EXPRESS</SERVICELEVEL><SCAC>LOOMIS</SCAC>',     null
union select 'LOOMIS-GROUND',    'Loomis Ground',                  'LOOMIS-GROUND',                    'A',    '<SERVICELEVEL>GROUND</SERVICELEVEL><SCAC>LOOMIS</SCAC>',      null

--exec pr_Setup_Shipvias @Carrier, @ShipVias, 'IU' /* Insert/Update */, @BusinessUnit, @UserId, 'Y' /* Is SmallPackageCarrier */, @SCAC;

Go

/* Update Special Services
SERVICETYPE - SD - Saturday Delivery

Below update statement has to be expanded/modified based to accomodoate other special services
which may be introduced in future.
*/
update ShipVias
set SpecialServices = '<SERVICETYPE>SD</SERVICETYPE>'
where (ShipVia in ('FEDX1SAT', 'UPS1SAT'));

Go
/*----------------------------------------------------------------------------*/
/* Designate Small Package Carriers */

update ShipVias
set IsSmallPackageCarrier = 'Y'/* Yes */
where (Carrier in('FEDEX', 'UPS', 'USPS', 'DHL', 'CANPAR', 'CANADAPOST', 'TFORCE', 'PURO', 'LOOMIS'));

/*

Constantly, clients keep requesting what carriers and services we support for UPS/USPS and FedEx. Here is the answer

select Carrier, ShipVia, Description, Status FROM ShipVias
where Carrier NOT IN ('LTL', 'Generic')
order by carrier, ShipVia

select LookUpCode FreightTerms, LookupDescription FreightTermsDescription, StatusDescription Status
 FROM dbo.vwLookUps where LookUpCategory = 'FreightTerms'


*/

Go

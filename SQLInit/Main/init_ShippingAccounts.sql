/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2024/08/10  RV      Added account FedExTrack for tracking (BK-1132)
  2023/09/15  RV      Added ClientId and ClientSecret (MBW-495)
  2023/09/08  RV      Added UPS OAuth account information (MBW-437)
  2021/01/11  RV      Migrated FFI shipping accounts from CIMS Dev2.0 (CIMSV3-1307)
  2016/02/10  KN      Added SortType , EntryFacility in  USPS account details.(NBD-270)
  2016/03/03  YJ      Added ShippingAcctName column to handle ukShippingAccounts_AccountName
  2016/02/10  KN      Added USPS account details.(NBD-162)
  2015/09/11  KN      Modified UPS account details for supporting UPS mail Innovation.
  2013/04/12  YA      Included UPS account details.
  2013/04/04  PK      Updated AccountDetails with new key information
  2011/09/16  AA      Initial Revision.
------------------------------------------------------------------------------*/

/*------------------------------------------------------------------------------*/
/* Shipping Account Details */
/*------------------------------------------------------------------------------*/
delete from ShippingAccounts;

insert into ShippingAccounts
             (Carrier,     ShipVia,  ShippingAcctName, UserId,             Password,                    ShipperAccountNumber, ShipperMeterNumber, ShipperAccessKey,   MasterAccount, Status,  BusinessUnit,  AccountDetails)
      select 'FEDEX',      'FEDXSP', 'FEDXSP',         '7VTzpsdDIGt1nC5N', 'F37Z4CseN51t0MMYWVXa9vJ8w', '510087445',          '118548091',        null,               null,          'A',     BusinessUnit,  null  from vwBusinessUnits
union select 'FEDEX',      null,     'FEDEX',          '7VTzpsdDIGt1nC5N', 'F37Z4CseN51t0MMYWVXa9vJ8w', '510087445',          '118548091',        null,               null,          'A',     BusinessUnit,  null  from vwBusinessUnits
union select 'USPS',       null,     'USPS',           '2506269',          'EVethErtherseRe',           '2506269',            null,               null,               null,          'A',     BusinessUnit,  '<OTHERDETAILS><SORTTYPE>5</SORTTYPE><ENTRYFACILITY>2</ENTRYFACILITY></OTHERDETAILS>'
                                                                                                                                                                                                                   from vwBusinessUnits
union select 'DHL',        null,     'DHL',            'xmlSupplyCT',      'Wm6uz0D5t8',                '803921577',          null,               null,               null,          'A',     BusinessUnit,  '<OTHERDETAILS></OTHERDETAILS>'
/* For ADSI Interface, only ShippingAcctName is needed. This must match the Shipper Account Name on ADSI Server Setup */                                                                                           from vwBusinessUnits
union select 'ADSI',       null,     'CIMSADSI',       null,               null,                        null,                 null,               null,               null,          'A',     BusinessUnit,  null  from vwBusinessUnits

/* Token Authentictaion Carriers */
/* UPS stoped to give access key along with shipper account, So need to use OAUTH2 to generate the token to generate the SPLs.
  
   To create an client id and clien secret need to go through the following URL.
     https://developer.ups.com/?loc=en_US

   Steps to generate Authorization code:
   1) Need to browse the following URL: Need to change the client provided Id and redirect URL.
       https://www.ups.com/lasso/signin?client_id=OrGdGrdl2fSVSCkMPNAkAjQKGaPehN9aXLp6uwL8aGABAlRz&redirect_uri=https://cloudimsystems.com&response_type=code&scope=read&type=ups_com_api
   2) After browsed the above URL redirects to the UPS Login and need to provide the UserName and Password. Ex: UserName: UPS_FFI, Password: UPS@fF1
   3) It validates and redirected to the URL which are provided in the first step with client authorization code in the URL.
   4) Copy the redirected authentication code and update the column TokenAuthenticationCode with the authentication code against the GenerateToken
      Message type in the APIConfiguration table.
 */
insert into ShippingAccounts
             (Carrier,     ShipVia,  ShippingAcctName, UserId,             Password,                    ShipperAccountNumber, ShipperMeterNumber, ShipperAccessKey,   MasterAccount, Status,  BusinessUnit,  AccountDetails, ClientId, ClientSecret, TokenAuthenticationCode, RedirectURI)
       select 'UPS',       null,     'UPS',            'UPS_FFI',          'UPS@fF1',                   'F95314',             '118545138',        '5D32852E2243A5D8', null,          'A',     BusinessUnit,  null,           'wNiQjq0aJ8pi9GL4FshexTWvKUA04v14mn2fAbVAvOJA2Yvl',
                                                                                                                                                                                                                                       'kHqqAX6PC7j4QUqjWW7x561swUFJ9PEg4JTNnekMRggmb3RoBFHni82A6UYfDQOX',
                                                                                                                                                                                                                                                     null,                    'https://cloudimsystems.com' from vwBusinessUnits

/*------------------------------------------------------------------------------*/
/* API Carrier Accounts for Tracking: Some carriers, such as FedEx, provide separate accounts specifically for tracking purposes */
/*------------------------------------------------------------------------------*/
insert into ShippingAccounts
             (Carrier,     ShipVia,  ShippingAcctName,  UserId,             Password,                    ShipperAccountNumber, ShipperMeterNumber, ShipperAccessKey,   MasterAccount, Status,  SortSeq,      BusinessUnit,  AccountDetails, ClientId, ClientSecret, TokenAuthenticationCode, RedirectURI)
       select 'FEDEX',     'Track',  'FedExTrack',      null,               null,                        '740561073',          null,               null,               null,          'A',     30,           BusinessUnit,  null,           'l740920411b08f41a19f7e1e604d5de465',
                                                                                                                                                                                                                                                      '1659bf21e6f7496f8c3d1126eede2216',
                                                                                                                                                                                                                                                                    null,                    null from vwBusinessUnits

Go

/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2024/02/12  RV      Added CIMSFEDEX2OAUTH and CIMSFEDEX2 (CIMSV3-3397)
  2023/09/03  RV      Added CIMSUPSOAUTH2 and CIMSUPS2 (MBW-437)
  2021/05/21  RV      CIMSUPS: Included the authentication info in header info (CIMSV3-1453)
  2021/02/16  RV      Added new CIMSUPS - Tracking integration
                                CIMSUSPS - Tracking (BK-157)
  2020/10/21  NB      Added CIMS API, updated 6River API Details(CID-1486, CID-1481)
  2020/09/28  NB      Initial Revision(CID-1481)
------------------------------------------------------------------------------*/

Go

declare @IntegrationType TTypeCode,
        @BaseURL         TURL;

delete from APIIntegrations;
/*------------------------------------------------------------------------------*/
select @IntegrationType = 'INBOUND';

insert into APIIntegrations
            (IntegrationName, Description,      BaseUrl,                                     AuthenticationType, AuthenticationInfo,  IntegrationType,  BusinessUnit)
      select '6RiverCIMS',    '6River to CIMS', 'http://cimswms.net/api/cid/6rivercims',     'BASIC',            'username:password', @IntegrationType, BusinessUnit from BusinessUnits
union select 'CIMS',          'CIMS API',       'http://cimswms.net/api/cid/cims',           'BASIC',            'username:password', @IntegrationType, BusinessUnit from BusinessUnits

/*------------------------------------------------------------------------------*/
select @IntegrationType = 'OUTBOUND';

insert into APIIntegrations
            (IntegrationName, Description,      BaseUrl,                                     AuthenticationType, AuthenticationInfo,    IntegrationType,  BusinessUnit)
      select 'CIMS6River',    'CIMS to 6River', 'https://intdes.6river.org/cfs/v2',          'BASIC',            'INTDES:0m8SBtwLL2sx', @IntegrationType, BusinessUnit from BusinessUnits

/*------------------------------------------------------------------------------*/
/* UPS */
select @IntegrationType = 'OUTBOUND';

/* The URLs for testing and production are different, so use the appropriate one and comment the other
   Overwrite it if needed */
select @BaseURL         = case
                            when ((db_name() like '%Staging%') or (db_name() like '%Prod%')) then
                              'https://wwwcie.ups.com'
                            else
                              'https://onlinetools.ups.com'
                          end;

insert into APIIntegrations
            (IntegrationName, Description,      BaseUrl,                                     AuthenticationType, AuthenticationInfo, HeaderInfo, SecurityProtocolInfo,   IntegrationType,  BusinessUnit)
      select 'CIMSUPS',       'CIMS to UPS',    @BaseURL,                                    'BASIC',            'UPS_FFI:UPS@fF1',  '<Root><Username>UPS_FFI</Username><Password>UPS@fF1</Password><AccessLicenseNumber>5D32852E2243A5D8</AccessLicenseNumber></Root>',
                                                                                                                                                 'SSLRequired',          @IntegrationType, BusinessUnit from BusinessUnits

/*------------------------------------------------------------------------------*/
/* CIMSUPSOAUTH2: UPS Integration with OAUTH2.0

   To create a client id and client secret need to go through the following URL.
     https://developer.ups.com/?loc=en_US

   Steps to generate Authorization code:
   1) Need to browse the following URL: Need to change the client provided Id and redirect URL.
       https://www.ups.com/lasso/signin?client_id=OrGdGrdl2fSVSCkMPNAkAjQKGaPehN9aXLp6uwL8aGABAlRz&redirect_uri=https://cloudimsystems.com&response_type=code&scope=read&type=ups_com_api
   2) After browsed the above URL redirects to the UPS Login and need to provide the UserName and Password. Ex: UserName: UPS_FFI, Password: UPS@fF1
   3) It validates and redirected to the URL which are provided in the first step with client authorization code in the URL.
   4) Copy the redirected authentication code and update the column TokenAuthenticationCode with the authentication code against the GenerateToken
      Message type in the APIConfiguration table.

   API Documentation: https://developer.ups.com/api/reference?loc=en_US

   Note:
    For Token generate API requires BASIC authentication, for other API methods of UPS requires BEARER token,
     So need to use two different Integrations. */

select @IntegrationType = 'OUTBOUND';

/* The URLs for testing and production are different, so use the appropriate one and comment the other
   Overwrite it if needed */
select @BaseURL         = case
                            when (db_name() like '%Staging%' or db_name() like '%Dev%' or db_name() like '%Test%') then
                              'https://wwwcie.ups.com'
                            else
                              'https://onlinetools.ups.com'
                          end;

insert into APIIntegrations
            (IntegrationName, Description,          BaseUrl,                                     AuthenticationType, AuthenticationInfo, HeaderInfo, SecurityProtocolInfo,   IntegrationType,  BusinessUnit)
      select 'CIMSUPSOAUTH2', 'CIMS to UPS OAUTH2', @BaseURL,                                    'BASIC',            'wNiQjq0aJ8pi9GL4FshexTWvKUA04v14mn2fAbVAvOJA2Yvl:kHqqAX6PC7j4QUqjWW7x561swUFJ9PEg4JTNnekMRggmb3RoBFHni82A6UYfDQOX',
                                                                                                                                         null,       'SSLRequired',          @IntegrationType, BusinessUnit from BusinessUnits

/*------------------------------------------------------------------------------*/
/* CIMSUPSOAUTH2: UPS Integration with OAUTH2.0 */
select @IntegrationType = 'OUTBOUND';

/* The URLs for testing and production are different, so use the appropriate one and comment the other
   Overwrite it if needed */
select @BaseURL         = case
                            when (db_name() like '%Staging%' or db_name() like '%Dev%' or db_name() like '%Test%') then
                              'https://wwwcie.ups.com/api'
                            else
                              'https://onlinetools.ups.com/api'
                          end;

insert into APIIntegrations
            (IntegrationName, Description,          BaseUrl,                                     AuthenticationType, AuthenticationInfo, HeaderInfo, SecurityProtocolInfo,   IntegrationType,  BusinessUnit)
      select 'CIMSUPS2',      'CIMS to UPS OAUTH2', @BaseURL,                                    'BEARER',           null,               null,       'SSLRequired',          @IntegrationType, BusinessUnit from BusinessUnits

/*------------------------------------------------------------------------------*/
/* USPS */

/* The URLs for testing and production are different, so use the appropriate one and comment the other
   Overwrite it if needed */
select @BaseURL         = case
                            when ((db_name() like '%Staging%') or (db_name() like '%Prod%')) then
                              'https://secure.shippingapis.com'
                            else
                              'https://production.shippingapis.com'
                          end;

insert into APIIntegrations
            (IntegrationName, Description,      BaseUrl,                                     AuthenticationType, AuthenticationInfo, HeaderInfo, SecurityProtocolInfo,   IntegrationType,  BusinessUnit)
      select 'CIMSUSPS',      'CIMS to USPS',   'https://secure.shippingapis.com',           '',                 null,               null     ,  'SSLRequired',          @IntegrationType, BusinessUnit from BusinessUnits

/*------------------------------------------------------------------------------*/
/* CIMSFEDEX2OAUTH: FEDEX Integration with OAUTH2.0 */

select @IntegrationType = 'OUTBOUND';

/* The URLs for testing and production are different, so use the appropriate one and comment the other
   Overwrite it if needed */
select @BaseURL         = case
                            when (db_name() like '%Staging%' or db_name() like '%Dev%' or db_name() like '%Test%') then
                              'https://apis-sandbox.fedex.com'
                            else
                              'https://apis.fedex.com'
                          end;

insert into APIIntegrations
            (IntegrationName,    Description,            BaseUrl,   AuthenticationType, AuthenticationInfo, HeaderInfo, SecurityProtocolInfo,   IntegrationType,  BusinessUnit)
      select 'CIMSFEDEX2OAUTH',  'CIMS to FEDEX OAUTH2', @BaseURL,  'NONE',             null,               null,       'SSLRequired',          @IntegrationType, BusinessUnit from BusinessUnits

/*------------------------------------------------------------------------------*/
/* CIMSFEDEX2: FEDEX Integration with OAUTH2.0 */
select @IntegrationType = 'OUTBOUND';

select @BaseURL         = case
                            when (db_name() like '%Staging%' or db_name() like '%Prod%') then
                              'https://apis.fedex.com'
                            else
                              'https://apis-sandbox.fedex.com'
                          end;

insert into APIIntegrations
            (IntegrationName, Description,            BaseUrl,   AuthenticationType, AuthenticationInfo, HeaderInfo, SecurityProtocolInfo,   IntegrationType,  BusinessUnit)
      select 'CIMSFEDEX2',    'CIMS to FEDEX OAUTH2', @BaseURL,  'BEARER',           null,               null,       'SSLRequired',          @IntegrationType, BusinessUnit from BusinessUnits

Go

/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2023/09/15  RV      ShippingAccounts: ClientId and ClientSecret (MBW-495)
  2023/09/08  RV      ShippingAccounts: Added Token related columns (MBW-437)
  2016/04/21  AY      ShippingAccounts: Unique key changed to include Carrier
  2016/02/26  TK      ShippingAccounts: Added Unique key constraint (LL-276)
------------------------------------------------------------------------------*/

Go

/*------------------------------------------------------------------------------
  Table: ShippingAccounts

  AccountDetails - Holds the account specific information - to use when processing
                   shipping transactions or generating labels with web services
                   Ex:
                   <ACCOUNTDETAILS>
                      <USERID>ekTKHG8vJTEhdRl2</USERID>
                      <PASSWORD>MWTmKJD9ehY90BCpdeEwy12HL</PASSWORD>
                      <ACCOUNTNUMBER>510087909</ACCOUNTNUMBER>
                      <METERNUMBER>118545138</METERNUMBER>
                   </ACCOUNTDETAILS>

  ClientId : Shipping account client id

  ClientSecret: Secrete key of the shipping account, which is provided by the carrier.

  TokenAuthenticationInfo: May have the client authorization code and other details

  TokenType: Few of the API integration supports token based authentication, so save the generated token type. Ex: Bearer.

  TokenStatus: At the time of token generation API returns the status of token.

  AccessToken: To perform the any action in API we need to send this access key along with the API request.

  AccessTokenGeneratedAt: Access token generated time. It returns in UNIX format

  AccessTokenExpiresIn: Access token expires time in seconds.

  RefreshToken: This token requires to refresh the access token.

  RefreshTokenGeneratedAt: Refresh token generated time. It returns in UNIX format

  RefreshTokenExpiresIn: Refresh token expires time in seconds.
------------------------------------------------------------------------------*/
Create Table ShippingAccounts (
    RecordId                 TRecordId      identity (1,1) not null,

    ShippingAcctName         TAccountName,

    Carrier                  TCarrier       not null,
    ShipVia                  TShipvia,

    UserId                   TUserId,
    Password                 TPassword,

    ShipperAccountNumber     TAccount,
    ShipperMeterNumber       TMeterNumber,
    ShipperAccessKey         TAccessKey,

    MasterAccount            TAccountName,

    Status                   TStatus        not null default 'A' /* Active*/,
    SortSeq                  TSortSeq       default 0,
    BusinessUnit             TBusinessUnit  not null,

    AccountDetails           varchar(max),

    ClientId                 TVarchar,
    ClientSecret             TVarchar,
    TokenAuthenticationCode  TVarchar,
    RedirectURI              TURL,
    TokenType                TTypeCode,
    TokenStatus              TStatus,
    AccessToken              TVarchar,
    AccessTokenIssuedAt      TDateTime,
    AccessTokenExpiresAt     TDateTime,
    RefreshToken             TVarchar,
    RefreshTokenIssuedAt     TDateTime,
    RefreshTokenExpiresAt    TDateTime,

    SA_UDF1                  TUDF,
    SA_UDF2                  TUDF,
    SA_UDF3                  TUDF,
    SA_UDF4                  TUDF,
    SA_UDF5                  TUDF,

    CreatedDate              TDateTime      default getdate(),
    ModifiedDate             TDateTime,
    CreatedBy                TUserId,
    ModifiedBy               TUserId,

    constraint pkShippingAccount_RecordId     primary key (RecordId),
    constraint ukShippingAccounts_AccountName unique (Carrier, ShippingAcctName, BusinessUnit)
);

Go

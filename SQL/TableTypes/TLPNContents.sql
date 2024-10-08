/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/06/24  AY      TLPNContents: Return data set of pr_ShipLabel_GetLPNContents (HA-1013)
  2020/01/07  MJ      TLPNContentsLabelData, TLPNShipLabelData: Added ShipToAddress3 (CID-1240)
  2019/07/18  MJ      TLPNContentsLabelData: Added PackedBy (CID-822)
  2019/04/10  MS      Added TLPNContentsLabelData & TLPNContentLabelDetails (CID-221)
  Create Type TLPNContents as Table (
  Grant References on Type:: TLPNContents to public;
  Create Type TLPNContentsLabelData as Table (
  Grant References on Type:: TLPNContentsLabelData to public;
  Create Type TLPNContentsLabelDetails as Table (
  Grant References on Type:: TLPNContentsLabelDetails to public;
------------------------------------------------------------------------------*/

Go

/*----------------------------------------------------------------------------*/
/* Return data set of pr_ShipLabel_GetLPNContents. This may be used in conjuction
   with TLPNShipLabelData so the fields should not repeat and hence any common
   fields are prefixed with LC_ */
Create Type TLPNContents as Table (
    LC_LPN                   TLPN,
    LC_TrackingNo            TTrackingNo,
    LC_UCCBarcode            TBarcode,
    LC_PackedDate            TDateTime,
    LC_PackedBy              TUserId,
    LC_PackageSeqNo          TInteger,
    LC_TotalPackages         TInteger,

    LabelSNo                 TInteger,      /* Row is a Keyword - What is this for ? */
                                            /* Ans: No of total labels required to print content label */

    /* LPNDetailLine1 Info */
    LPNLine01                TDetailLine,
    SKU01                    TSKU,
    Quantity01               TQuantity,
    UnitsAuthorizedToShip01  TQuantity,
    UPC01                    TUPC,
    CustSKU01                TCustSKU,
    SKUDescription01         TDescription,
    SKU101                   TSKU,
    SKU201                   TSKU,
    SKU301                   TSKU,
    SKU401                   TSKU,
    SKU501                   TSKU,

    /* LPNDetailLine2 Info */
    LPNLine02                TDetailLine,
    SKU02                    TSKU,
    Quantity02               TQuantity,
    UnitsAuthorizedToShip02  TQuantity,
    UPC02                    TUPC,
    CustSKU02                TCustSKU,
    SKUDescription02         TDescription,
    SKU102                   TSKU,
    SKU202                   TSKU,
    SKU302                   TSKU,
    SKU402                   TSKU,
    SKU502                   TSKU,

    /* LPNDetailLine3 Info */
    LPNLine03                TDetailLine,
    SKU03                    TSKU,
    Quantity03               TQuantity,
    UnitsAuthorizedToShip03  TQuantity,
    UPC03                    TUPC,
    CustSKU03                TCustSKU,
    SKUDescription03         TDescription,
    SKU103                   TSKU,
    SKU203                   TSKU,
    SKU303                   TSKU,
    SKU403                   TSKU,
    SKU503                   TSKU,

    /* LPNDetailLine4 Info */
    LPNLine04                TDetailLine,
    SKU04                    TSKU,
    Quantity04               TQuantity,
    UnitsAuthorizedToShip04  TQuantity,
    UPC04                    TUPC,
    CustSKU04                TCustSKU,
    SKUDescription04         TDescription,
    SKU104                   TSKU,
    SKU204                   TSKU,
    SKU304                   TSKU,
    SKU404                   TSKU,
    SKU504                   TSKU,

    /* LPNDetailLine5 Info */
    LPNLine05                TDetailLine,
    SKU05                    TSKU,
    Quantity05               TQuantity,
    UnitsAuthorizedToShip05  TQuantity,
    UPC05                    TUPC,
    CustSKU05                TCustSKU,
    SKUDescription05         TDescription,
    SKU105                   TSKU,
    SKU205                   TSKU,
    SKU305                   TSKU,
    SKU405                   TSKU,
    SKU505                   TSKU,

    /* LPNDetailLine6 Info */
    LPNLine06                TDetailLine,
    SKU06                    TSKU,
    Quantity06               TQuantity,
    UnitsAuthorizedToShip06  TQuantity,
    UPC06                    TUPC,
    CustSKU06                TCustSKU,
    SKUDescription06         TDescription,
    SKU106                   TSKU,
    SKU206                   TSKU,
    SKU306                   TSKU,
    SKU406                   TSKU,
    SKU506                   TSKU,

    /* LPNDetailLine7 Info */
    LPNLine07                TDetailLine,
    SKU07                    TSKU,
    Quantity07               TQuantity,
    UnitsAuthorizedToShip07  TQuantity,
    UPC07                    TUPC,
    CustSKU07                TCustSKU,
    SKUDescription07         TDescription,
    SKU107                   TSKU,
    SKU207                   TSKU,
    SKU307                   TSKU,
    SKU407                   TSKU,
    SKU507                   TSKU,

    /* LPNDetailLine8 Info */
    LPNLine08                TDetailLine,
    SKU08                    TSKU,
    Quantity08               TQuantity,
    UnitsAuthorizedToShip08  TQuantity,
    UPC08                    TUPC,
    CustSKU08                TCustSKU,
    SKUDescription08         TDescription,
    SKU108                   TSKU,
    SKU208                   TSKU,
    SKU308                   TSKU,
    SKU408                   TSKU,
    SKU508                   TSKU,

    /* LPNDetailLine9 Info */
    LPNLine09                TDetailLine,
    SKU09                    TSKU,
    Quantity09               TQuantity,
    UnitsAuthorizedToShip09  TQuantity,
    UPC09                    TUPC,
    CustSKU09                TCustSKU,
    SKUDescription09         TDescription,
    SKU109                   TSKU,
    SKU209                   TSKU,
    SKU309                   TSKU,
    SKU409                   TSKU,
    SKU509                   TSKU,

    /* LPNDetailLine10 Info */
    LPNLine10                TDetailLine,
    SKU10                    TSKU,
    Quantity10               TQuantity,
    UnitsAuthorizedToShip10  TQuantity,
    UPC10                    TUPC,
    CustSKU10                TCustSKU,
    SKUDescription10         TDescription,
    SKU110                   TSKU,
    SKU210                   TSKU,
    SKU310                   TSKU,
    SKU410                   TSKU,
    SKU510                   TSKU,

    /* LPNDetailLine11 Info */
    LPNLine11                TDetailLine,
    SKU11                    TSKU,
    Quantity11               TQuantity,
    UnitsAuthorizedToShip11  TQuantity,
    UPC11                    TUPC,
    CustSKU11                TCustSKU,
    SKUDescription11         TDescription,
    SKU111                   TSKU,
    SKU211                   TSKU,
    SKU311                   TSKU,
    SKU411                   TSKU,
    SKU511                   TSKU,

    /* LPNDetailLine12 Info */
    LPNLine12                TDetailLine,
    SKU12                    TSKU,
    Quantity12               TQuantity,
    UnitsAuthorizedToShip12  TQuantity,
    UPC12                    TUPC,
    CustSKU12                TCustSKU,
    SKUDescription12         TDescription,
    SKU112                   TSKU,
    SKU212                   TSKU,
    SKU312                   TSKU,
    SKU412                   TSKU,
    SKU512                   TSKU,

    /* LPNDetailLine13 Info */
    LPNLine13                TDetailLine,
    SKU13                    TSKU,
    Quantity13               TQuantity,
    UnitsAuthorizedToShip13  TQuantity,
    UPC13                    TUPC,
    CustSKU13                TCustSKU,
    SKUDescription13         TDescription,
    SKU113                   TSKU,
    SKU213                   TSKU,
    SKU313                   TSKU,
    SKU413                   TSKU,
    SKU513                   TSKU,

    /* LPNDetailLine14 Info */
    LPNLine14                TDetailLine,
    SKU14                    TSKU,
    Quantity14               TQuantity,
    UnitsAuthorizedToShip14  TQuantity,
    UPC14                    TUPC,
    CustSKU14                TCustSKU,
    SKUDescription14         TDescription,
    SKU114                   TSKU,
    SKU214                   TSKU,
    SKU314                   TSKU,
    SKU414                   TSKU,
    SKU514                   TSKU,

    /* LPNDetailLine15 Info */
    LPNLine15                TDetailLine,
    SKU15                    TSKU,
    Quantity15               TQuantity,
    UnitsAuthorizedToShip15  TQuantity,
    UPC15                    TUPC,
    CustSKU15                TCustSKU,
    SKUDescription15         TDescription,
    SKU115                   TSKU,
    SKU215                   TSKU,
    SKU315                   TSKU,
    SKU415                   TSKU,
    SKU515                   TSKU,

    /* LPNDetailLine16 Info */
    LPNLine16                TDetailLine,
    SKU16                    TSKU,
    Quantity16               TQuantity,
    UnitsAuthorizedToShip16  TQuantity,
    UPC16                    TUPC,
    CustSKU16                TCustSKU,
    SKUDescription16         TDescription,
    SKU116                   TSKU,
    SKU216                   TSKU,
    SKU316                   TSKU,
    SKU416                   TSKU,
    SKU516                   TSKU,

    /* LPNDetailLine17 Info */
    LPNLine17                TDetailLine,
    SKU17                    TSKU,
    Quantity17               TQuantity,
    UnitsAuthorizedToShip17  TQuantity,
    UPC17                    TUPC,
    CustSKU17                TCustSKU,
    SKUDescription17         TDescription,
    SKU117                   TSKU,
    SKU217                   TSKU,
    SKU317                   TSKU,
    SKU417                   TSKU,
    SKU517                   TSKU,

    /* LPNDetailLine18 Info */
    LPNLine18                TDetailLine,
    SKU18                    TSKU,
    Quantity18               TQuantity,
    UnitsAuthorizedToShip18  TQuantity,
    UPC18                    TUPC,
    CustSKU18                TCustSKU,
    SKUDescription18         TDescription,
    SKU118                   TSKU,
    SKU218                   TSKU,
    SKU318                   TSKU,
    SKU418                   TSKU,
    SKU518                   TSKU,

    /* LPNDetailLine19 Info */
    LPNLine19                TDetailLine,
    SKU19                    TSKU,
    Quantity19               TQuantity,
    UnitsAuthorizedToShip19  TQuantity,
    UPC19                    TUPC,
    CustSKU19                TCustSKU,
    SKUDescription19         TDescription,
    SKU119                   TSKU,
    SKU219                   TSKU,
    SKU319                   TSKU,
    SKU419                   TSKU,
    SKU519                   TSKU,

    /* LPNDetailLine20 Info */
    LPNLine20                TDetailLine,
    SKU20                    TSKU,
    Quantity20               TQuantity,
    UnitsAuthorizedToShip20  TQuantity,
    UPC20                    TUPC,
    CustSKU20                TCustSKU,
    SKUDescription20         TDescription,
    SKU120                   TSKU,
    SKU220                   TSKU,
    SKU320                   TSKU,
    SKU420                   TSKU,
    SKU520                   TSKU,

    /* LPNDetailLine21 Info */
    LPNLine21                TDetailLine,
    SKU21                    TSKU,
    Quantity21               TQuantity,
    UnitsAuthorizedToShip21  TQuantity,
    UPC21                    TUPC,
    CustSKU21                TCustSKU,
    SKUDescription21         TDescription,
    SKU121                   TSKU,
    SKU221                   TSKU,
    SKU321                   TSKU,
    SKU421                   TSKU,
    SKU521                   TSKU,

    /* LPNDetailLine22 Info */
    LPNLine22                TDetailLine,
    SKU22                    TSKU,
    Quantity22               TQuantity,
    UnitsAuthorizedToShip22  TQuantity,
    UPC22                    TUPC,
    CustSKU22                TCustSKU,
    SKUDescription22         TDescription,
    SKU122                   TSKU,
    SKU222                   TSKU,
    SKU322                   TSKU,
    SKU422                   TSKU,
    SKU522                   TSKU,

    /* LPNDetailLine23 Info */
    LPNLine23                TDetailLine,
    SKU23                    TSKU,
    Quantity23               TQuantity,
    UnitsAuthorizedToShip23  TQuantity,
    UPC23                    TUPC,
    CustSKU23                TCustSKU,
    SKUDescription23         TDescription,
    SKU123                   TSKU,
    SKU223                   TSKU,
    SKU323                   TSKU,
    SKU423                   TSKU,
    SKU523                   TSKU,

    /* LPNDetailLine24 Info */
    LPNLine24                TDetailLine,
    SKU24                    TSKU,
    Quantity24               TQuantity,
    UnitsAuthorizedToShip24  TQuantity,
    UPC24                    TUPC,
    CustSKU24                TCustSKU,
    SKUDescription24         TDescription,
    SKU124                   TSKU,
    SKU224                   TSKU,
    SKU324                   TSKU,
    SKU424                   TSKU,
    SKU524                   TSKU,

    /* LPNDetailLine25 Info */
    LPNLine25                TDetailLine,
    SKU25                    TSKU,
    Quantity25               TQuantity,
    UnitsAuthorizedToShip25  TQuantity,
    UPC25                    TUPC,
    CustSKU25                TCustSKU,
    SKUDescription25         TDescription,
    SKU125                   TSKU,
    SKU225                   TSKU,
    SKU325                   TSKU,
    SKU425                   TSKU,
    SKU525                   TSKU,

    /* LPNDetailLine26 Info */
    LPNLine26                TDetailLine,
    SKU26                    TSKU,
    Quantity26               TQuantity,
    UnitsAuthorizedToShip26  TQuantity,
    UPC26                    TUPC,
    CustSKU26                TCustSKU,
    SKUDescription26         TDescription,
    SKU126                   TSKU,
    SKU226                   TSKU,
    SKU326                   TSKU,
    SKU426                   TSKU,
    SKU526                   TSKU,

    /* LPNDetailLine27 Info */
    LPNLine27                TDetailLine,
    SKU27                    TSKU,
    Quantity27               TQuantity,
    UnitsAuthorizedToShip27  TQuantity,
    UPC27                    TUPC,
    CustSKU27                TCustSKU,
    SKUDescription27         TDescription,
    SKU127                   TSKU,
    SKU227                   TSKU,
    SKU327                   TSKU,
    SKU427                   TSKU,
    SKU527                   TSKU,

    /* LPNDetailLine28 Info */
    LPNLine28                TDetailLine,
    SKU28                    TSKU,
    Quantity28               TQuantity,
    UnitsAuthorizedToShip28  TQuantity,
    UPC28                    TUPC,
    CustSKU28                TCustSKU,
    SKUDescription28         TDescription,
    SKU128                   TSKU,
    SKU228                   TSKU,
    SKU328                   TSKU,
    SKU428                   TSKU,
    SKU528                   TSKU,

    /* LPNDetailLine29 Info */
    LPNLine29                TDetailLine,
    SKU29                    TSKU,
    Quantity29               TQuantity,
    UnitsAuthorizedToShip29  TQuantity,
    UPC29                    TUPC,
    CustSKU29                TCustSKU,
    SKUDescription29         TDescription,
    SKU129                   TSKU,
    SKU229                   TSKU,
    SKU329                   TSKU,
    SKU429                   TSKU,
    SKU529                   TSKU,

    /* LPNDetailLine30 Info */
    LPNLine30                TDetailLine,
    SKU30                    TSKU,
    Quantity30               TQuantity,
    UnitsAuthorizedToShip30  TQuantity,
    UPC30                    TUPC,
    CustSKU30                TCustSKU,
    SKUDescription30         TDescription,
    SKU130                   TSKU,
    SKU230                   TSKU,
    SKU330                   TSKU,
    SKU430                   TSKU,
    SKU530                   TSKU,

    LC_TotalLines            TCount,
    LC_TotalQuantity         TQuantity,
    LC_TotalLabels           TCount
);

Grant References on Type:: TLPNContents to public;

Go

/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2024/05/29  VS      TCarrierDocuments: Table Type added (FBV3-1752)
------------------------------------------------------------------------------*/

Go

/*------------------------------------------------------------------------------*/
Create Type TCarrierDocuments as Table (
    DocumentType           TString,
    ImageType              TVarchar,
    CopiesToPrint          TInteger,
    Image                  TVarchar
);

grant references on Type:: TCarrierDocuments  to public;

Go
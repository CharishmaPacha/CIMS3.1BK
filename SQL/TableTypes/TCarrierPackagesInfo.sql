/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2024/02/24. AY      TCarrierPackagesInfo: Added CI related fields (CIMSV3-3434)
  2024/02/16  AY      TCarrierPackagesInfo: Added LabelReference[1-5]/[Type.Value] for FedEx API (CIMSV3-3395)
  2023/12/05  AY      TCarrierPackagesInfo: Added PackageWeight (JLFL-320)
  2023/08/21  RV      TCarrierPackagesInfo: Added DimensionUoM
  2023/08/16  RV      TCarrierPackagesInfo: Initial Version
  Create Type TCarrierPackagesInfo as Table (
  grant references on Type:: TCarrierPackagesInfo to public;
------------------------------------------------------------------------------*/

Go

/*----------------------------------------------------------------------------*/
/* #CarrierPackageInfo is the hash table that would hold all the info related
   to the packages of the shipment. This would be built with all fields in
   LPNs table and below additional fields */
Create Type TCarrierPackagesInfo as Table (
  EntityType                   TEntity,
  EntityKey                    TEntityKey,
  PackageType                  TDescription,
  PackageDescription           TDescription,

  InsuranceRequired            TFlags,
  InsuredValue                 TMoney,

  CartonDetailsXML             TXML,
  CartonLength                 TLength,
  CartonWidth                  TLength,
  CartonHeight                 TLength,

  CNNDescription               TDescription, --?
  PackageWeight                TWeight,
  PackageWeightOz              TWeight,
  WeightUoM                    TUoM,
  DimensionUoM                 TUoM,

  CIPurpose                    TDescription,
  CITerms                      TDescription,
  CIDate                       TDate,
  CINumber                     TLPN,
  CIFreightCharge              TMoney,
  CIInsuranceValue             TMoney,
  CIOtherCharges               TMoney,
  CIComments                   TVarchar,
  CISaveInDB                   TControlValue,

  LabelReference1              TReference,
  LabelReference2              TReference,
  LabelReference3              TReference,
  LabelReference4              TReference,
  LabelReference5              TReference,
  LabelReference1Type          TReference,
  LabelReference1Value         TReference,
  LabelReference2Type          TReference,
  LabelReference2Value         TReference,
  LabelReference3Type          TReference,
  LabelReference3Value         TReference,
  LabelReference4Type          TReference,
  LabelReference4Value         TReference,
  LabelReference5Type          TReference,
  LabelReference5Value         TReference
);

grant references on Type:: TCarrierPackagesInfo to public;

Go

/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2016/03/11  RV      pr_Exports_OnhandInventoryByOwner: Return data as xml instead of data set and Calling procedure signature changed (CIMS-809)
                      pr_Exports_OnhandInventoryByOwner: Initial revision
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Exports_OnhandInventoryByOwner') is not null
  drop Procedure pr_Exports_OnhandInventoryByOwner;
Go
/*------------------------------------------------------------------------------
  Proc pr_Exports_OnhandInventoryByOwner: This procedure is used by DataExchange to
   get OnHand inventory for each owner and write each dataset returned to a separate file.

  If caller passes Ownership then we would just return the OnHand inventory for that particular Owner.
  If caller does not pass Ownership then we would consider Integration Type and based upon that
    we would get applicable owners, process them one by one and return OnHand inventory dataset. For
    example if it is ExportIOHCSV then we would only get the owners for which we need to export IOH
    as CSV.

  when there are no more owner to process i.e. on the last owner, the procedure returns
  IterateFlag = N to indicate to DE that it can stop iterations
------------------------------------------------------------------------------*/
Create Procedure pr_Exports_OnhandInventoryByOwner
  (@IntegrationType   TAction    = null,
   @BusinessUnit      TBusinessUnit,
   @Warehouse         TWarehouse = null,
   @Ownership         TOwnership = null          output,
   @IterateFlag       TFlag      = 'N' /* No */  output,
   @OwnershipRecId    TRecordId  = null          output,
   @XmlResult         xml        = null          output)
as
  /* variables declaration */
  declare @vReturnCode         TInteger,
          @vMessageName        TMessageName,
          @vMessage            TDescription,

          @vOutputZeroQtySKUs  TFlag,
          @vOwnerCount         TCount,
          @vRecordId           TRecordId;

  /* temp tables declaration */
  declare @ttMappedSet table (IntegrationType  TAction,
                              Ownership        TOwnership,
                              MappingRecordId  TRecordId,
                              RecordId         TRecordId Identity(1,1));

  -- let us make a temp table definition for this if we need it
  declare @ttOnHandInventoryByOwner table (SKU                 TSKU,
                                           SKU1                TSKU,
                                           SKU2                TSKU,
                                           SKU3                TSKU,
                                           SKU4                TSKU,
                                           SKU5                TSKU,
                                           LPN                 TLPN,
                                           Location            TLocation,
                                           Ownership           TOwnership,
                                           LotNumber           TLot,
                                           Warehouse           TWarehouse,
                                           ExpiryDate          TDate,
                                           LPNType             TTypeCode,
                                           LPNTypeDescription  TDescription,
                                           AvailableQty        TQuantity,
                                           ReservedQty         TQuantity,
                                           OnhandQty           TQuantity,
                                           ReceivedQty         TQuantity,
                                           TransDateTime       TDateTime);

begin /* pr_Exports_OnhandInventoryByOwner */

   /* Initialize variables */
   select @Warehouse          = nullif(@Warehouse,       ''),
          @Ownership          = nullif(@Ownership,       ''),
          @OwnershipRecId     = coalesce(nullif(@OwnershipRecId, ''), 0),
          @IterateFlag        = 'N' /* No */,
          @vRecordId          = 0,
          @vOutputZeroQtySKUs = 1;

  /* if Ownership is not specified then get the Owners from LookUps and process them. Note that
     if no lookups are setup for the Integration Type then Ownership remains null and all
     IOH is returned */
  if (@Ownership is null)
    begin
      /* For the given integration type, get the list of owners to export OHI */
      insert into @ttMappedSet (Ownership, MappingRecordId)
        select TargetValue, RecordId
        from dbo.fn_GetMappedSet('CIMS', 'HOST', 'Ownership', 'Integration' /* Operation */,  @BusinessUnit)
        where (SourceValue = @IntegrationType);

      select @vOwnerCount = @@rowcount;

      /* Get next Owner in the sequence defined in Mapping */
      select top 1 @OwnershipRecId = MappingRecordId,
                   @Ownership      = Ownership,
                   @vRecordId      = RecordId
      from @ttMappedSet
      where (MappingRecordId > @OwnershipRecId)
      order by MappingRecordId;

      /* If this was not the last owner then set IterateFlag to Yes */
      if (@vOwnerCount <> @vRecordId)
        set @IterateFlag = 'Y' /* Yes */;
    end

  /* Return dataset */
  exec pr_Exports_OnhandInventory @Warehouse, @Ownership, @OutputZeroQtySKUs = @vOutputZeroQtySKUs, @XmlResult = @XmlResult output;

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Exports_OnhandInventoryByOwner */

Go


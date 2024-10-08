/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2018/05/24  VM      fn_Notes_GetBoLNotes: Get ShipmentId direclty from Shipments table itself (S2G-838)
  2018/05/11  RT      fn_Notes_GetBoLNotes: Returns distinct special instructions for different Orders
                                            related to given BoLNumber(S2G-829)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.fn_Notes_GetBoLNotes') is not null
  drop Function fn_Notes_GetBoLNotes;
Go
/*------------------------------------------------------------------------------
  Func fn_Notes_GetBoLNotes: Returns distinct special instructions for different Orders
                             related to given BoLNumber
------------------------------------------------------------------------------*/
Create Function fn_Notes_GetBoLNotes
  (@BoLNumber         TBoLNumber,
   @BusinessUnit      TBusinessUnit)
  ----------------------------------
   Returns            TVarchar
as
begin
  declare @vNote         TVarchar;

  declare @ttShipments  table(EntityId TRecordId);

  /* insert the Shipmentid's into the temp table for the given BolNumber */
  insert into @ttShipments(EntityId)
    select ShipmentId from Shipments
    where (BoLNumber    = @BoLNumber) and
          (BusinessUnit = @BusinessUnit);

  /* stuff all the distinct Notes for Differents Orders based on ShipmentId */
  select @vNote =  stuff((select distinct ',' + N.Note
                          from Notes N
                            join OrderShipments OS on (OS.OrderId = N.EntityId)
                            join @ttShipments ttS on (ttS.EntityId = OS.ShipmentId)
                          where (N.NoteType = 'SI') and  /* Special Instructions */
                                (N.Status   = 'A') /* Active */
                          for XML PATH(''), type).value('.','TVarchar'), 1, 1,'');

  return(coalesce(@vNote, ''));

end /* fn_Notes_GetBoLNotes */

Go

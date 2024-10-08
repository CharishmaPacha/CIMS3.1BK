 /*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/11/20  MS      Initial Revision.
------------------------------------------------------------------------------*/

Go

if object_id('dbo.vwRouterConfirmations') is not null
  drop View dbo.vwRouterConfirmations;
Go

Create View dbo.vwRouterConfirmations (
  RecordId,

  LPNId,
  LPN,

  Destination,
  DivertDateTime,
  DivertDate,
  DivertTime,

  WaveId,
  WaveNo,
  OrderId,
  PickTicket,
  ReceiptId,
  ReceiptNumber,
  ReceiverId,
  ReceiverNumber,

  EstimatedWeight,
  ActualWeight,

  ProcessedStatus,
  ProcessedDateTime,
  ProcessedOn,
  ExternalRecId,

  RC_UDF1,
  RC_UDF2,
  RC_UDF3,
  RC_UDF4,
  RC_UDF5,

  vwRC_UDF1,
  vwRC_UDF2,
  vwRC_UDF3,
  vwRC_UDF4,
  vwRC_UDF5,

  Archived,
  BusinessUnit,
  CreatedDate,
  ModifiedDate,
  CreatedBy,
  ModifiedBy
)As
select
  RC.RecordId,

  RC.LPNId,
  RC.LPN,

  RC.Destination,
  RC.DivertDateTime,
  RC.DivertDate,
  RC.DivertTime,

  L.PickBatchId,
  L.PickBatchNo,
  L.OrderId,
  L.PickTicketNo,
  L.ReceiptId,
  L.ReceiptNumber,
  L.ReceiverId,
  L.ReceiverNumber,

  L.EstimatedWeight,
  L.ActualWeight,

  RC.ProcessedStatus,
  RC.ProcessedDateTime,
  RC.ProcessedOn,
  RC.ExternalRecId,

  RC.RC_UDF1,
  RC.RC_UDF2,
  RC.RC_UDF3,
  RC.RC_UDF4,
  RC.RC_UDF5,

  cast(' ' as varchar(50)), /* vwRC_UDF1 */
  cast(' ' as varchar(50)), /* vwRC_UDF2 */
  cast(' ' as varchar(50)), /* vwRC_UDF3 */
  cast(' ' as varchar(50)), /* vwRC_UDF4 */
  cast(' ' as varchar(50)), /* vwRC_UDF5 */

  RC.Archived,
  RC.BusinessUnit,
  RC.CreatedDate,
  RC.ModifiedDate,
  RC.CreatedBy,
  RC.ModifiedBy
from
  RouterConfirmation RC
    left outer join LPNs L on (RC.LPNId = L.LPNId);

Go

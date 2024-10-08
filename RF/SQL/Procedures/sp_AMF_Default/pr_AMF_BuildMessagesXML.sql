/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/11/24  MS      pr_AMF_BuildMessagesXML: Bug fix to display complete msg in UI (JL-306)
  2020/09/08  RV      pr_AMF_BuildMessagesXML: Initial version
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_AMF_BuildMessagesXML') is not null
  drop Procedure pr_AMF_BuildMessagesXML;
Go
/*------------------------------------------------------------------------------
  Prod pr_AMF_BuildMessagesXML
    This procedure checks the input info/warnings/errors exist or not if exists then concatenate with the
    the Result messages table and returns AMF compliant xml with the message, warnings and errors from the temp table, which are inserted in the core procedure
------------------------------------------------------------------------------*/
Create Procedure pr_AMF_BuildMessagesXML
  (@InfoXML     TXML,
   @WarningsXML TXML,
   @ErrorsXML   TXML,
   @MessagesXML TXML = null output)
as
declare @vXMLInfo          XML,
        @vXMLWarnings      XML,
        @vXMLErrors        XML,

        @vInfoXML          TXML,
        @vErrorsXML        TXML,
        @vWarningsXML      TXML;

begin /* pr_AMF_BuildMessagesXML */
  select @MessagesXML = null;

  /* Build message text if required */
  if (exists(select * from #ResultMessages))
    begin
      /* Build the Message text if needed */
      update #ResultMessages
      set MessageText = dbo.fn_Messages_Build (MessageName, coalesce(Value1, EntityKey), Value2, Value3, Value4, Value5)
      where (MessageText is null) and (MessageName is not null);

      /* If message type is not given, assume it is info */
      update #ResultMessages set MessageType = 'I' where MessageType is null;
    end

  /* If info xml already exists and there are info messages in #ResultMessages, then merge them into #ResultMessages */
  if ((coalesce(@InfoXML, '') <> '') and (exists(select * from #ResultMessages where MessageType = 'I')))
    begin
      select @vXMLInfo = cast (@InfoXML as xml);

      /* Insert messages from input param into #Results */
      insert into #ResultMessages(MessageType, MessageText)
        select  'I' /* Info */, Record.Col.value('DisplayText[1]', 'TVarchar')
        from @vXMLInfo.nodes('Info/Messages/Message') as Record(Col);
    end

  if (exists(select * from #ResultMessages where MessageType = 'I'))
    begin
      /* Rebuild XML with merged messages */
      select @vInfoXML = (select MessageText DisplayText
                          from #ResultMessages
                          where MessageType = 'I' /* Info */
                          for xml raw('Message'), elements, root('Messages'));

      select @vInfoXML = dbo.fn_XMLNode('Info', @vInfoXML);
    end
  else
    /* if there are no records in #ResultMessages, use the input as is */
    select @vInfoXML = @InfoXML;

  /* If warnings xml already exists and there are info messages in #ResultMessages, then merge them into #ResultMessages */
  if ((coalesce(@WarningsXML, '') <> '') and (exists(select * from #ResultMessages where MessageType = 'W')))
    begin
      select @vXMLWarnings = cast (@WarningsXML as xml);

      insert into #ResultMessages(MessageType, MessageText)
        select 'W' /* Warnings */, Record.Col.value('DisplayText[1]', 'TDescription')
        from @vXMLWarnings.nodes('Warnings/Messages/Message') as Record(Col);
    end

  /* Build the Info xml */
  if (exists(select * from #ResultMessages where MessageType = 'W'))
    begin
      /* Build the Warnings xml from the temp table */
      select @vWarningsXML = (select MessageText DisplayText
                              from #ResultMessages
                              where MessageType = 'W' /* Warning */
                              for xml raw('Message'), elements, root('Messages'));

      select @vWarningsXML = dbo.fn_XMLNode('Warnings', @vWarningsXML);
    end
  else
    /* if there are no records in #ResultMessages, use the input as is */
    select @vXMLWarnings = @WarningsXML;

  /* If erros xml already exists and there are info messages in #ResultMessages, then merge them into #ResultMessages */
  if ((coalesce(@ErrorsXML, '') <> '') and (exists(select * from #ResultMessages where MessageType = 'E')))
    begin
      select @vXMLErrors = cast (@ErrorsXML as xml);

      insert into #ResultMessages(MessageType, MessageText)
        select  'E' /* Errors */, Record.Col.value('DisplayText[1]', 'TDescription')
        from @vXMLErrors.nodes('Errors/Messages/Message') as Record(Col);
    end

  if (exists(select * from #ResultMessages where MessageType = 'E'))
    begin
      /* Build the Errors xml from the temp table */
      select @vErrorsXML = (select MessageText DisplayText
                            from #ResultMessages
                            where MessageType = 'E' /* Error */
                            for xml raw('Message'), elements, root('Messages'));

      select @vErrorsXML = dbo.fn_XMLNode('Errors', @vErrorsXML);
    end
  else
    /* if there are no records in #ResultMessages, use the input as is */
    select @vErrorsXML = @ErrorsXML;

  select @MessagesXML = coalesce(@vInfoXML,     '') +
                        coalesce(@vWarningsXML, '') +
                        coalesce(@vErrorsXML,   '');
end /* pr_AMF_BuildMessagesXML */

Go


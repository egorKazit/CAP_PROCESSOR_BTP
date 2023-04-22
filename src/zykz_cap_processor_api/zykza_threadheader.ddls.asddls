@EndUserText.label: 'Thread header API'
@AccessControl.authorizationCheck: #NOT_REQUIRED
define root view entity ZYKZA_ThreadHeader
  provider contract transactional_query
  as projection on ZYKZR_ThreadHeaderTP
{
  key UUID,
      SourceUUID,
      Thread,
      Name,
      Status,
      ProcessedFlag,
      /* Associations */
      _ThreadItemTP : redirected to composition child ZYKZA_ThreadItem
}

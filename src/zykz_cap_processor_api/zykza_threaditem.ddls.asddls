@EndUserText.label: 'Thread item API'
@AccessControl.authorizationCheck: #NOT_REQUIRED
define view entity ZYKZA_ThreadItem
  as projection on ZYKZR_ThreadItemTP
{
  key UUID,
      ThreadUUID,
      Item,
      Type,
      NameOrContent,
      /* Associations */
      _ThreadHeaderTP : redirected to parent ZYKZA_ThreadHeader
}

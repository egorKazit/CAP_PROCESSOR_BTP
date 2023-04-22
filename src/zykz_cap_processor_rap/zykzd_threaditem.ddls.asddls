@EndUserText.label: 'Create Thread Item Entity'
define abstract entity ZYKZD_ThreadItem
{
  key ItemUUID      : sysuuid_c32;
      Item          : abap.int2;
      Type          : zykz_cap_item_type;
      NameOrContent : abap.string(0);
      Header        : association to parent ZYKZD_ThreadHeader;
}

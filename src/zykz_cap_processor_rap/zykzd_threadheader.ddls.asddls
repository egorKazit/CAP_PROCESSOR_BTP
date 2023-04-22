@EndUserText.label: 'Create Thread Header Root Entity'
define root abstract entity ZYKZD_ThreadHeader
{
  key SourceUUID : sysuuid_c32;
      Thread     : abap.string(0);
      Name       : zykz_cap_name;
      _Items     : composition [0..*] of ZYKZD_ThreadItem;
}

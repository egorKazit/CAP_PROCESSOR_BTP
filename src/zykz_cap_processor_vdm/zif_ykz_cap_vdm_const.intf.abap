INTERFACE zif_ykz_cap_vdm_const
  PUBLIC .

  CONSTANTS:
    BEGIN OF status,
      Initial    TYPE zykz_cap_status VALUE '0',
      InApproval TYPE zykz_cap_status VALUE '1',
      Approved   TYPE zykz_cap_status VALUE '2',
      Rejected   TYPE zykz_cap_status VALUE '3',
      Abandoned  TYPE zykz_cap_status VALUE '4',
    END OF status,
    BEGIN OF item_type,
      note       TYPE zykz_cap_item_type VALUE '1',
      attachment TYPE zykz_cap_item_type VALUE '2',
    END OF item_type.
ENDINTERFACE.

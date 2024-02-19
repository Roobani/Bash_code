#!/bin/bash
rsync_cmd="rsync -av --exclude .git/ --exclude .gitignore"
source_base="/opt/kencove/src-13"
dest_base="/opt/kencove/kencove_V13_addons_sodexis"

${source_base}/dev_tools/git_update/git_update.sh
sleep 5
set -x
${rsync_cmd} ${source_base}/sodexis_modules/account_ar_import/ ${dest_base}/account_ar_import/
echo;echo
${rsync_cmd} ${source_base}/community_modules/account-fiscal-rule/account_avatax/ ${dest_base}/account_avatax/
echo;echo
${rsync_cmd} ${source_base}/community_modules/account-fiscal-rule/account_avatax_exemption/ ${dest_base}/account_avatax_exemption/
echo;echo
${rsync_cmd} ${source_base}/community_modules/account-fiscal-rule/account_avatax_sale/ ${dest_base}/account_avatax_sale/
echo;echo
${rsync_cmd} ${source_base}/community_modules/account-fiscal-rule/account_fiscal_position_rule/ ${dest_base}/account_fiscal_position_rule/
echo;echo
${rsync_cmd} ${source_base}/community_modules/account-fiscal-rule/account_fiscal_position_rule_sale/ ${dest_base}/account_fiscal_position_rule_sale/
echo;echo
${rsync_cmd} ${source_base}/community_modules/bank-payment/account_payment_mode/ ${dest_base}/account_payment_mode/
echo;echo
${rsync_cmd} ${source_base}/community_modules/bank-payment/account_payment_partner/ ${dest_base}/account_payment_partner/
echo;echo
${rsync_cmd} ${source_base}/community_modules/bank-payment/account_payment_sale/ ${dest_base}/account_payment_sale/
echo;echo
${rsync_cmd} ${source_base}/community_modules/avatax_connector/avatax_connector/ ${dest_base}/avatax_connector/
echo;echo
${rsync_cmd} ${source_base}/sodexis_modules/avatax_exemption/ ${dest_base}/avatax_exemption/
echo;echo
${rsync_cmd} ${source_base}/sodexis_apps_store/credit-management/credit_management/ ${dest_base}/credit_management/
echo;echo
${rsync_cmd} ${source_base}/sodexis_modules/customer_email_preference/ ${dest_base}/customer_email_preference/
echo;echo
${rsync_cmd} ${source_base}/kencove/kencove/customer_reports/ ${dest_base}/customer_reports/
echo;echo
${rsync_cmd} ${source_base}/sodexis_modules/data_cleaning/ ${dest_base}/data_cleaning/
echo;echo
${rsync_cmd} ${source_base}/sodexis_modules/data_merge/ ${dest_base}/data_merge/
echo;echo
${rsync_cmd} ${source_base}/sodexis_modules/data_merge_crm/ ${dest_base}/data_merge_crm/
echo;echo
${rsync_cmd} ${source_base}/sodexis_modules/data_merge_utm/ ${dest_base}/data_merge_utm/
echo;echo
${rsync_cmd} ${source_base}/sodexis_modules/edi/ ${dest_base}/edi/
echo;echo
${rsync_cmd} ${source_base}/tiny_apps/tiny_apps/email_auto_resend/ ${dest_base}/email_auto_resend/
echo;echo
${rsync_cmd} ${source_base}/kencove/kencove/email_templates_customization/ ${dest_base}/email_templates_customization/
echo;echo
${rsync_cmd} ${source_base}/sodexis_apps_store/finance_charge/finance_charge/ ${dest_base}/finance_charge/
echo;echo
${rsync_cmd} ${source_base}/sodexis_modules/ftp/ ${dest_base}/ftp/
echo;echo
${rsync_cmd} ${source_base}/kencove/kencove/kencove/ ${dest_base}/kencove/
echo;echo
${rsync_cmd} ${source_base}/kencove/kencove/kencove_install/ ${dest_base}/kencove_install/
echo;echo
${rsync_cmd} ${source_base}/community_modules/social/mail_debrand/ ${dest_base}/mail_debrand/
echo;echo
${rsync_cmd} ${source_base}/tiny_apps/tiny_apps/mail_debrand_ext/ ${dest_base}/mail_debrand_ext/
echo;echo
#${rsync_cmd} ${source_base}/community_modules/social/mail_outbound_static/ ${dest_base}/mail_outbound_static/
#echo;echo
${rsync_cmd} ${source_base}/community_modules/partner-contact/partner_ref_unique/ ${dest_base}/partner_ref_unique/
echo;echo
${rsync_cmd} ${source_base}/tiny_apps/tiny_apps/partner_unique_reference/ ${dest_base}/partner_unique_reference/
echo;echo
${rsync_cmd} ${source_base}/sodexis_apps_store/authorize-backend/payment_authorize_backend/ ${dest_base}/payment_authorize_backend/
echo;echo
${rsync_cmd} ${source_base}/tiny_apps/tiny_apps/payment_workflow_authorize_exception/ ${dest_base}/payment_workflow_authorize_exception/
echo;echo
${rsync_cmd} ${source_base}/tiny_apps/tiny_apps/product_category_change_warning/ ${dest_base}/product_category_change_warning/
echo;echo
${rsync_cmd} ${source_base}/tiny_apps/tiny_apps/product_unique_reference/ ${dest_base}/product_unique_reference/
echo;echo
${rsync_cmd} ${source_base}/community_modules/purchase-workflow/purchase_delivery_split_date/ ${dest_base}/purchase_delivery_split_date/
echo;echo
${rsync_cmd} ${source_base}/community_modules/purchase-workflow/purchase_location_by_line/ ${dest_base}/purchase_location_by_line/
echo;echo
${rsync_cmd} ${source_base}/sodexis_apps_store/purchase-vendorbill-advance/purchase_vendorbill_advance/ ${dest_base}/purchase_vendorbill_advance/
echo;echo
${rsync_cmd} ${source_base}/community_modules/queue/queue_job/ ${dest_base}/queue_job/
echo;echo
${rsync_cmd} ${source_base}/tiny_apps/tiny_apps/sale_order_active/ ${dest_base}/sale_order_active/
echo;echo
${rsync_cmd} ${source_base}/sodexis_apps_store/authorize-backend/sod_sale_payment_method/ ${dest_base}/sod_sale_payment_method/
echo;echo
${rsync_cmd} ${source_base}/tiny_apps/tiny_apps/stock_auto_check_availability/ ${dest_base}/stock_auto_check_availability/
echo;echo
${rsync_cmd} ${source_base}/tiny_apps/tiny_apps/stock_prevent_done_qty/ ${dest_base}/stock_prevent_done_qty/
echo;echo
${rsync_cmd} ${source_base}/tiny_apps/tiny_apps/stock_reordering_rules/ ${dest_base}/stock_reordering_rules/
echo;echo
${rsync_cmd} ${source_base}/sodexis_modules/stock_split_by_warehouse/ ${dest_base}/stock_split_by_warehouse/
echo;echo
${rsync_cmd} ${source_base}/tiny_apps/tiny_apps/web_widget_m2o_default_search_more/ ${dest_base}/web_widget_m2o_default_search_more/
echo;echo
${rsync_cmd} ${source_base}/community_modules/sale-workflow/sale_automatic_workflow_payment_mode/ ${dest_base}/sale_automatic_workflow_payment_mode/
echo;echo
${rsync_cmd} ${source_base}/community_modules/sale-workflow/sale_automatic_workflow/ ${dest_base}/sale_automatic_workflow/
echo;echo
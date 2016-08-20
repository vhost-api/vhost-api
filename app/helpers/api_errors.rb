# frozen_string_literal: true
# Helper module for error lookups
module ApiErrors
  LOOKUP_TABLE = {
    # general errors 10xx
    internal_error:
      ['1000', 500, 'internal server error, please contact an administrator'],

    malformed_request:
      ['1001', 400, 'malformed request data'],

    authentication_failed:
      ['1002', 401, 'authentication failed'],

    unauthorized:
      ['1003', 403, 'insufficient permission or quota exhausted'],

    not_found:
      ['1004', 404, 'requested resource does not exist'],

    resource_conflict:
      ['1005', 409, 'resource conflict, cannot apply request data'],

    invalid_request:
      ['1006', 422, 'invalid request, check request data for endpoint'],

    failed_create:
      ['1007', 500, 'could not create'],

    failed_update:
      ['1008', 500, 'could not update'],

    failed_delete:
      ['1009', 500, 'could not delete'],

    invalid_query:
      ['1010', 400, 'invalid query parameters'],

    quota_apikey:
      ['1011', 403, 'apikey quota exhausted'],

    db_connection_failed:
      ['1012', 500, 'database connection failed'],

    # group controller specific 11xx
    invalid_group:
      ['1100', 422, 'invalid group name'],

    # user controller specific 12xx
    invalid_login:
      ['1200', 422, 'invalid login'],

    # domain controller specific 13xx
    invalid_domain:
      ['1300', 422, 'invalid domain name'],

    # dkim controller specific 14xx
    invalid_dkim_selector:
      ['1400', 422, 'invalid selector'],

    invalid_dkim_domain_id:
      ['1401', 422, 'invalid domain_id'],

    invalid_dkim_keypair:
      ['1402', 422, 'invalid private or public key, specify both or none'],

    invalid_dkim_keypair_update:
      ['1403',
       422,
       'specify both or none, call POST :id/regenerate for a fresh keypair'],

    invalid_dkim_private_key:
      ['1404', 422, 'invalid private key'],

    invalid_dkim_public_key:
      ['1405', 422, 'invalid public key'],

    # dkimsigning controller specific 15xx
    invalid_dkimsigning_author:
      ['1500', 422, 'invalid author'],

    dkimsigning_author_too_long:
      ['1501', 422, 'author is too long, must be less than 255 characters'],

    invalid_dkimsigning_dkim_id:
      ['1502', 422, 'invalid dkim_id'],

    dkimsigning_mismatch:
      ['1503', 422, 'author does not belong to request dkim/domain'],

    # mailaccount controller specific 16xx
    invalid_email:
      ['1600', 422, 'invalid email address'],

    email_too_long:
      ['1601', 422, 'email address too long, must be less than 255 characters'],

    email_mismatch:
      ['1602', 422, 'email address does not belong to requested domain'],

    domain_mismatch:
      ['1603', 422, 'requested domain is invalid for email adress'],

    invalid_sieve_script:
      ['1604', 422, 'invalid sieve script, verify correct syntax'],

    sieve_script_size:
      ['1605', 422, 'sieve script size exceeds allowed limit'],

    sieve_script_type:
      ['1606', 422, 'uploaded file has wrong type'],

    sieve_script_size_quota:
      ['1607', 422, 'sieve script size exceeds quota for this mailaccount'],

    sieve_actions_quota:
      ['1608', 422, 'sieve actions exceed quota for this mailaccount'],

    sieve_redirects_quota:
      ['1609', 422, 'sieve redirects exceed quota for this mailaccount'],

    # mailalias controller specific 17xx
    invalid_alias_destinations:
      ['1700', 422, 'invalid destinations'],

    # mailsource controller specific 18xx
    invalid_sources:
      ['1800', 422, 'invalid sources'],

    # apikey controller specific 19xx
    invalid_apikey:
      ['1900', 422, 'invalid apikey'],

    apikey_length:
      ['1901', 422, 'invalid apikey, has to be 64 characters']

    # dns zone controller specific 20xx

    # dns record controller specific 21xx

  }.freeze

  module_function

  def [](identifier)
    code, status, message = LOOKUP_TABLE[identifier]
    { code: code, status: status, message: message }
  end
end

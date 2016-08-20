# frozen_string_literal: true
def check_email_address(email: nil)
  # check if requested email is "valid"
  return_api_error(ApiErrors.[](:invalid_email)) unless email.count('@') == 1
  return_api_error(ApiErrors.[](:email_too_long)) unless email.length <= 254
  true
end

def check_email_localpart(email: nil, domain: nil)
  localpart_error = ApiErrors.[](:invalid_email)
  # check if localpart contains only allowed chars
  lpart = email.chomp("@#{domain}")
  return_api_error(localpart_error) unless lpart =~ %r{^[a-z]+[a-z0-9._-]*$}
  return_api_error(localpart_error) if lpart =~ %r{\.\.{1,}}
  return_api_error(localpart_error) if %w(. _ -).include?(lpart[-1, 1])
  true
end

def check_domain_for_email_address(domain_id: nil, email: nil)
  mismatch_error = ApiErrors.[](:domain_mismatch)
  # check if requested domain_id matches given email address
  str_domain = email.split('@')[1]
  did = domain_id
  return_api_error(mismatch_error) unless str_domain == Domain.get(did).name
  true
end

def check_email_address_for_domain(email: nil, domain_id: nil)
  check_email_address(email: email)
  mismatch_error = ApiErrors.[](:email_mismatch)
  # check if requested email belongs to requested domain
  str_domain = email.split('@')[1]
  did = domain_id
  return_api_error(mismatch_error) unless str_domain == Domain.get(did).name
  check_email_localpart(email: email, domain: str_domain)
  true
end

def check_dkim_author(author: nil)
  # some messages
  length_error = ApiErrors.[](:dkimsigning_author_too_long)
  author_error = ApiErrors.[](:invalid_dkimsigning_author)

  # check if requested author is "valid"
  return_api_error(length_error) unless author.length <= 254
  if author.include?('@')
    return_api_error(author_error) unless author.count('@') == 1
  end
  true
end

def check_dkim_domain(str_domain: nil, dkim_id: nil)
  mismatch_error = ApiErrors.[](:dkimsigning_mismatch)
  return_api_error(mismatch_error) unless str_domain == Domain.get(
    Dkim.get(dkim_id).domain_id
  ).name
  true
end

def check_dkim_author_for_dkim(author: nil, dkim_id: nil)
  check_dkim_author(author: author)
  # check if requested email belongs to requested domain
  str_domain = if author.include?('@')
                 author.split('@')[1]
               else
                 author
               end
  check_dkim_domain(str_domain: str_domain, dkim_id: dkim_id)
  true
end

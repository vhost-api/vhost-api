# frozen_string_literal: true
def check_email_address(email: nil)
  # some messages
  msg_invalid = 'invalid email address'
  msg_length = 'email address is too long'

  # check if requested email is "valid"
  raise(ArgumentError, msg_invalid) unless email.count('@') == 1
  raise(ArgumentError, msg_length) unless email.length <= 254
  true
end

def check_email_localpart(email: nil, domain: nil)
  msg_invalid = 'invalid email address'
  # check if localpart contains only allowed chars
  lpart = email.chomp("@#{domain}")
  raise(ArgumentError, msg_invalid) unless lpart =~ %r{^[a-z]+[a-z0-9._-]*$}
  raise(ArgumentError, msg_invalid) if lpart =~ %r{\.\.{1,}}
  raise(ArgumentError, msg_invalid) if %w(. _ -).include?(lpart[-1, 1])
  true
end

def check_email_address_for_domain(email: nil, domain_id: nil)
  check_email_address(email: email)
  msg_mismatch = 'email address does not belong to requested domain'
  # check if requested email belongs to requested domain
  str_domain = email.split('@')[1]
  did = domain_id
  raise(ArgumentError, msg_mismatch) unless str_domain == Domain.get(did).name
  check_email_localpart(email: email, domain: str_domain)
  true
end

def check_dkim_author(author: nil)
  # some messages
  msg_invalid = 'invalid author'
  msg_length = 'author is too long'

  # check if requested author is "valid"
  raise(ArgumentError, msg_length) unless author.length <= 254
  if author.include?('@')
    raise(ArgumentError, msg_invalid) unless author.count('@') == 1
  end
  true
end

def check_dkim_domain(str_domain: nil, dkim_id: nil)
  msg_mismatch = 'author does not belong to requested dkim/domain'
  raise(ArgumentError, msg_mismatch) unless str_domain == Domain.get(
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

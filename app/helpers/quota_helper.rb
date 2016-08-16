# frozen_string_literal: true

# @return [Fixnum]
def allocated_customers(user)
  result = user.packages.map(&:quota_customers)
               .reduce(0, :+) unless user.reseller?
  result = user.customers.size if user.reseller?
  result
end

# @return [Fixnum]
def allocated_domains(user)
  result = user.domains.size
  result += user.customers.domains.size if user.reseller?
  result
end

# @return [Fixnum]
def allocated_mail_accounts(user)
  result = user.domains.mail_accounts.size
  result += user.customers.domains.mail_accounts.size if user.reseller?
  result
end

# @return [Fixnum]
def allocated_mail_aliases(user)
  result = user.domains.mail_aliases.size
  result += user.customers.domains.mail_aliases.size if user.reseller?
  result
end

# @return [Fixnum]
def allocated_mail_sources(user)
  result = user.domains.mail_sources.size
  result += user.customers.domains.mail_sources.size if user.reseller?
  result
end

# @return [Fixnum]
def allocated_mail_storage(user)
  result = user.domains.mail_accounts.map(&:quota).reduce(0, :+)
  result += user.customers.domains.mail_accounts
                .map(&:quota).reduce(0, :+) if user.reseller?
  result
end

# @return [Fixnum]
def allocated_apikeys(user)
  result = user.apikeys.size
  result += user.customers.apikeys.size if user.reseller?
  result
end

# @return [Fixnum]
def allocated_ssh_pubkeys(user)
  result = user.ssh_pubkeys.size
  result += user.customers.ssh_pubkeys.size if user.reseller?
  result
end

# @return [Fixnum]
def allocated_vhosts(user)
  result = user.vhosts.size
  result += user.customers.vhosts.size if user.reseller?
  result
end

# @return [Fixnum]
def allocated_vhost_storage(user)
  result = user.vhosts.map(&:quota).reduce(0, :+)
  result += user.customers.vhosts.map(&:quota).reduce(0, :+) if user.reseller?
  result
end

# @return [Fixnum]
def allocated_databases(user)
  result = user.databases.size
  result += user.customers.databases.size if user.reseller?
  result
end

# @return [Fixnum]
def allocated_database_users(user)
  result = user.database_users.size
  result += user.customers.database_users.size if user.reseller?
  result
end

# @return [Fixnum]
def allocated_sftp_users(user)
  result = user.vhosts.sftp_users.size
  result += user.customers.vhosts.sftp_users.size if user.reseller?
  result
end

# @return [Fixnum]
def allocated_shell_users(user)
  result = user.vhosts.shell_users.size
  result += user.customers.vhosts.shell_users.size if user.reseller?
  result
end

# @return [Fixnum]
def allocated_dns_zones(user)
  result = user.packages.map(&:quota_dns_zones).reduce(0, :+)
  result = user.customers.map(&:packages).map(&:quota_dns_zones)
               .reduce(0, :+) if user.reseller?
  result
end

# @return [Fixnum]
def allocated_dns_records(user)
  result = user.packages.map(&:quota_dns_records).reduce(0, :+)
  result = user.customers.map(&:packages).map(&:quota_dns_records)
               .reduce(0, :+) if user.reseller?
  result
end

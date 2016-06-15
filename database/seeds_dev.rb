# frozen_string_literal; false
group_list = [
  ['admin', true],
  ['reseller', true],
  ['user', true]
]
group_list.each do |group|
  Group.new(name: group[0],
            enabled: group[1]).save
end

user_list = [
  ['Admin', 'admin', 'secret', true, Group.first(name: 'admin')],
  ['Thore Bödecker', 'fox', 'geheim', true, Group.first(name: 'admin')],
  ['Max Mustermann', 'max', 'muster', true, Group.first(name: 'user')],
  ['Customer 1', 'customer1', 'customer1', true, Group.first(name: 'user')],
  ['Customer 2', 'customer2', 'customer2', true, Group.first(name: 'user')],
  ['Customer 3', 'customer3', 'customer3', true, Group.first(name: 'user')],
  ['Reseller 1', 'reseller1', 'reseller1', true, Group.first(name: 'reseller'),
   %w(customer1 customer2 customer3)],
  ['Customer 4', 'customer4', 'customer4', true, Group.first(name: 'user')],
  ['Customer 5', 'customer5', 'customer5', true, Group.first(name: 'user')],
  ['Reseller 2', 'reseller2', 'reseller2', true, Group.first(name: 'reseller'),
   %w(customer4 customer5)]
]
user_list.each do |user|
  u = User.new(name: user[0],
               login: user[1],
               password: user[2],
               enabled: user[3],
               group: user[4])

  if user[4].name == 'reseller'
    user[5].each do |client|
      u.customers << User.first(login: client)
    end
  end

  u.save
end

domain_list = [
  ['foobar.com', true, true, true, 'admin'],
  ['foxxx0.de', true, true, true, 'fox'],
  ['example.net', true, true, true, 'max'],
  ['herpderp.org', true, true, true, 'customer1'],
  ['schalala.net', true, true, true, 'customer2'],
  ['everything.eu', true, true, true, 'customer3'],
  ['archlinux.sexy', true, true, true, 'reseller1'],
  ['kernel.org', true, true, true, 'reseller1'],
  ['serious.business', true, true, true, 'customer4'],
  ['big.company', true, true, true, 'customer5']
]
domain_list.each do |domain|
  Domain.new(name: domain[0],
             mail_enabled: domain[1],
             dns_enabled: domain[2],
             enabled: domain[3],
             user: User.first(login: domain[4])).save
end

mailaccount_list = [
  ['me@foobar.com', 'top secret!', 1_048_576, 1, 'Dwarf', true, false],
  ['me2@foobar.com', 'penis', 10_485_760, 1, 'Smurf', true, true],
  ['me3@foobar.com', 'senf1979', 1_048_576, 1, 'Myself', false, true],
  ['nagios@foobar.com', 'windows ist foll dohf', 10_485_760, 1, 'Nagios', true,
   true],
  ['me@foxxx0.de', 'herpderp1234', 269_715_200, 2, 'Thore Bödecker', true,
   true],
  ['bob@example.net', '9876543210', 10_485_760, 3, 'Bob Bobbington', true,
   true],
  ['alice@example.net', '!aaaaaaaaaaaaa?', 536_870_912, 3, 'Alice Wonderland',
   true, true]
]
mailaccount_list.each do |mailaccount|
  MailAccount.new(email: mailaccount[0],
                  password: gen_doveadm_pwhash(mailaccount[1]),
                  receiving_enabled: mailaccount[5],
                  quota: mailaccount[2],
                  enabled: mailaccount[6],
                  domain_id: mailaccount[3],
                  realname: mailaccount[4]).save
end

mailalias_mailaccount_list = [
  ['aliastest@foobar.com', %w(me@foobar.com me2@foobar.com me3@foobar.com), 1],
  ['postmaster@foxxx0.de', 'me@foxxx0.de', 2],
  ['hostmaster@foxxx0.de', 'me@foxxx0.de', 2],
  ['webmaster@foxxx0.de', 'me@foxxx0.de', 2],
  ['abuse@foxxx0.de', 'me@foxxx0.de', 2],
  ['blog@foxxx0.de', 'me@foxxx0.de', 2],
  ['b@example.net', 'bob@example.net', 3],
  ['postmaster@example.net', 'bob@example.net', 3],
  ['hostmaster@example.net', 'bob@example.net', 3],
  ['webmaster@example.net', 'bob@example.net', 3],
  ['abuse@example.net', 'bob@example.net', 3],
  ['a@example.net', 'alice@example.net', 3]
]
mailalias_mailaccount_list.each do |mals_macc|
  MailAlias.new(address: mals_macc[0],
                enabled: true,
                domain_id: mals_macc[2]).save
  [*mals_macc[1]].each do |macc|
    acc = MailAccount.first(email: macc)
    acc.mail_aliases << MailAlias.first(address: mals_macc[0])
    acc.save
  end
end

mailsource_mailaccount_list = [
  ['me@foobar.com', 'me@foobar.com', 1],
  ['me2@foobar.com', 'me2@foobar.com', 1],
  ['me3@foobar.com', 'me3@foobar.com', 1],
  ['test@foobar.com', %w(me@foobar.com me2@foobar.com me3@foobar.com), 1],
  ['postmaster@foxxx0.de', 'me@foxxx0.de', 2],
  ['hostmaster@foxxx0.de', 'me@foxxx0.de', 2],
  ['webmaster@foxxx0.de', 'me@foxxx0.de', 2],
  ['abuse@foxxx0.de', 'me@foxxx0.de', 2],
  ['blog@foxxx0.de', 'me@foxxx0.de', 2],
  ['bob@example.net', 'bob@example.net', 3],
  ['postmaster@example.net', 'bob@example.net', 3],
  ['hostmaster@example.net', 'bob@example.net', 3],
  ['webmaster@example.net', 'bob@example.net', 3],
  ['abuse@example.net', 'bob@example.net', 3],
  ['alice@example.net', 'alice@example.net', 3]
]
mailsource_mailaccount_list.each do |msrc_macc|
  MailSource.new(address: msrc_macc[0],
                 enabled: true,
                 domain_id: msrc_macc[2]).save
  [*msrc_macc[1]].each do |macc|
    acc = MailAccount.first(email: macc)
    acc.mail_sources << MailSource.first(address: msrc_macc[0])
    acc.save
  end
end

# foobar.com
@dkim1 = Dkim.new(domain_id: 1)
@dkim1.selector = 'mail'
@dkim1.private_key = <<-EOF
-----BEGIN RSA PRIVATE KEY-----
TODO
-----END RSA PRIVATE KEY-----
EOF
@dkim1.public_key = <<-EOF
-----BEGIN PUBLIC KEY-----
TODO
-----END PUBLIC KEY-----
EOF
@dkim1.enabled = true
@dkim1.save

# foxxx0.de
@dkim2 = Dkim.new(domain_id: 2)
@dkim2.selector = 'mail'
@dkim2.private_key = <<-EOF
-----BEGIN RSA PRIVATE KEY-----
TODO
-----END RSA PRIVATE KEY-----
EOF
@dkim2.public_key = <<-EOF
-----BEGIN PUBLIC KEY-----
TODO
-----END PUBLIC KEY-----
EOF
@dkim2.enabled = true
@dkim2.save

# example.net
@dkim3 = Dkim.new(domain_id: 3)
@dkim3.selector = 'mail'
@dkim3.private_key = <<-EOF
-----BEGIN RSA PRIVATE KEY-----
TODO
-----END RSA PRIVATE KEY-----
EOF
@dkim3.public_key = <<-EOF
-----BEGIN PUBLIC KEY-----
TODO
-----END PUBLIC KEY-----
EOF
@dkim3.enabled = true
@dkim3.save

dkimsigning_list = [
  ['foobar.com', 1],
  ['foxxx0.de', 2],
  ['example.net', 3]
]
dkimsigning_list.each do |dkimsigning|
  DkimSigning.new(author: dkimsigning[0],
                  dkim_id: dkimsigning[1],
                  enabled: true).save
end

ipv4_list = [
  [1, '127.0.0.1'],
  [2, '10.1.2.3']
]
ipv4_list.each do |ipv4|
  Ipv4Address.new(id: ipv4[0],
                  address: IPAddr.new(ipv4[1])).save
end

ipv6_list = [
  [1, '::1'],
  [2, 'fe80::1']
]
ipv6_list.each do |ipv6|
  Ipv6Address.new(id: ipv6[0],
                  address: IPAddr.new(ipv6[1])).save
end

php_rt_list = [
  [1, 'none', '0.0'],
  [2, 'php56', '5.6.22'],
  [3, 'php7', '7.0.7']
]
php_rt_list.each do |php_rt|
  PhpRuntime.new(id: php_rt[0],
                 name: php_rt[1],
                 version: php_rt[2]).save
end

vhost_list = [
  [1, 'foxxx0.de', 2, 2, false, 1, 'c1web1', 'c1web1', true, 1],
  [2, 'ipv4.foxxx0.de', 2, 1, true, 3, 'c1web2', 'c1web2', true, 1],
  [3, 'ipv6.foxxx0.de', 1, 2, true, 3, 'c1web3', 'c1web3', true, 1],
  [4, 'paste.foxxx0.de', 2, 2, true, 3, 'c1web4', 'c1web4', true, 1],
  [5, 'blog.foxxx0.de', 2, 2, false, 1, 'c1web5', 'c1web5', true, 1],
  [6, 'example.net', 2, 2, false, 1, 'c1web6', 'c1web6', true, 1],
  [7, 'mail.example.net', 2, 2, false, 1, 'c1web7', 'c1web7', true, 1]
]
vhost_list.each do |vhost|
  Vhost.new(id: vhost[0],
            fqdn: vhost[1],
            ipv4_address_id: vhost[2],
            ipv6_address_id: vhost[3],
            php_enabled: vhost[4],
            php_runtime_id: vhost[5],
            os_uid: vhost[6],
            os_gid: vhost[7],
            enabled: vhost[8],
            user_id: vhost[9]).save
end

# '1test!sftplogin?' = {md5}f5NspiyFx2u8dxbZARAcjQ==
sftp_user_list = [
  [1, 'c1web5-1', '{md5}f5NspiyFx2u8dxbZARAcjQ==',
   '/srv/http/vhost/blog.foxxx0.de', true, 5]
]
sftp_user_list.each do |sftp_user|
  SftpUser.new(id: sftp_user[0],
               username: sftp_user[1],
               password: sftp_user[2],
               homedir: sftp_user[3],
               enabled: sftp_user[4],
               vhost_id: sftp_user[5]).save
end

# create the 3 necessary views
adapter = DataMapper.repository(:default).adapter
case adapter.options[:adapter]
when 'mysql'
  # mail_sendas_permissions
  adapter.execute('CREATE OR REPLACE ALGORITHM = TEMPTABLE VIEW '\
      '`mail_sendas_maps` AS '\
      'SELECT `mail_sources`.`address` AS `source`, '\
      '`mail_accounts`.`email` AS `user` '\
      'FROM `mail_account_mail_sources` '\
      'LEFT JOIN `mail_accounts` ON '\
      '`mail_account_mail_sources`.`mail_account_id` = `mail_accounts`.`id` '\
      'AND `mail_accounts`.`enabled` = 1 '\
      'RIGHT JOIN `mail_sources` ON '\
      '`mail_account_mail_sources`.`mail_source_id` = `mail_sources`.`id` '\
      'AND `mail_sources`.`enabled` = 1;')
  # mail_alias_maps
  adapter.execute('CREATE OR REPLACE ALGORITHM = TEMPTABLE VIEW '\
      '`mail_alias_maps` AS '\
      'SELECT `mail_aliases`.`address` AS `source`, '\
      "GROUP_CONCAT(`mail_accounts`.`email` SEPARATOR ' ') AS `destination` "\
      'FROM (`mail_accounts` '\
      'RIGHT JOIN (`mail_account_mail_aliases` '\
      'LEFT JOIN `mail_aliases` ON '\
      '(((`mail_account_mail_aliases`.`mail_alias_id` = `mail_aliases`.`id`) '\
      'AND (`mail_aliases`.`enabled` = 1)))) ON '\
      '(((`mail_account_mail_aliases`.`mail_account_id` = `mail_accounts`.`id`) '\
      'AND (`mail_accounts`.`enabled` = 1)))) '\
      'GROUP BY `mail_aliases`.`address`;')
  # dkim_lookup
  adapter.execute('CREATE OR REPLACE ALGORITHM = TEMPTABLE VIEW '\
      '`dkim_lookup` AS '\
      'SELECT `dkims`.`id` AS `id`, `domains`.`name` AS `domain_name`, '\
      '`dkims`.`selector` AS `selector`, '\
      '`dkims`.`private_key` AS `private_key` '\
      'FROM `dkims` RIGHT JOIN `domains` ON '\
      '`dkims`.`domain_id` = `domains`.`id` '\
      'AND `domains`.`enabled` = 1 WHERE `dkims`.`enabled` = 1;')
  # sftp proftpd user lookup
  adapter.execute('CREATE OR REPLACE ALGORITHM = TEMPTABLE VIEW '\
      '`sftp_user_maps` AS '\
      'SELECT `sftp_users`.`username` AS `username`, '\
      '`sftp_users`.`password` AS passwd, `vhosts`.`os_uid` AS uid, '\
      '`vhosts`.`os_gid` AS gid, `sftp_users`.`homedir` AS homedir, '\
      "'/bin/false' AS shell "\
      'FROM `sftp_users` '\
      'RIGHT JOIN `vhosts` ON '\
      '`sftp_users`.`vhost_id` = `vhosts`.`id` WHERE `vhosts`.`enabled` = 1 '\
      'AND `sftp_users`.`enabled` = 1;')
when 'postgres'
  puts 'postgres views not implemented yet!'
when 'sqlite'
  puts 'sqlite views not implemented yet!'
else
  puts 'unknown database adapter!'
end

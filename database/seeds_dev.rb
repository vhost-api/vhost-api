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
  ['me@foobar.com', 'topsecret!', 1_048_576, 'Dwarf', true, false],
  ['me2@foobar.com', 'penis', 10_485_760, 'Smurf', true, true],
  ['me3@foobar.com', 'senf1979', 1_048_576, 'Myself', false, true],
  ['nagios@foobar.com', 'folldohf', 10_485_760, 'Nagios', true, true],
  ['me@foxxx0.de', 'derp1234', 269_715_200, 'Thore Bödecker', true, true],
  ['bob@example.net', '9876543210', 10_485_760, 'Bob Bobbington', true, true],
  ['alice@example.net', '!abcd?', 536_870_912, 'Alice Wonderland', true, true],
  ['test@herpderp.org', '1234', 1_048_576, 'Test Customer 1', true, true],
  ['foo@herpderp.org', '1234', 1_048_576, 'Foo Customer 1', true, true],
  ['bar@herpderp.org', '1234', 1_048_576, 'Bar Customer 1', true, true],
  ['test@schalala.net', '1234', 1_048_576, 'Test Customer 2', true, true],
  ['herp@schalala.net', '1234', 1_048_576, 'Herp Customer 2', true, true],
  ['derp@schalala.net', '1234', 1_048_576, 'Derp Customer 2', true, true],
  ['test@everything.eu', '1234', 1_048_576, 'Test Customer 3', true, true],
  ['me@everything.eu', '1234', 1_048_576, 'Me Customer 3', true, true],
  ['he@everything.eu', '1234', 1_048_576, 'He Customer 3', true, true],
  ['she@everything.eu', '1234', 1_048_576, 'She Customer 3', true, true],
  ['test@archlinux.sexy', '1234', 1_048_576, 'Test Reseller 1', true, true],
  ['res1@archlinux.sexy', '1234', 1_048_576, 'Reseller 1', true, true],
  ['test@kernel.org', '1234', 1_048_576, 'Test Reseller 1', true, true],
  ['res1@kernel.org', '1234', 1_048_576, 'Reseller 1', true, true],
  ['support@kernel.org', '1234', 1_048_576, 'Support Reseller 1', true, true],
  ['test@serious.business', '1234', 1_048_576, 'Test Customer 4', true, true],
  ['sarah@serious.business', '1234', 1_048_576, 'Sarah Customer 4', true, true],
  ['cust4@serious.business', '1234', 1_048_576, 'Customer 4', true, true],
  ['test@big.company', '1234', 1_048_576, 'Test Customer 5', true, true],
  ['carl@big.company', '1234', 1_048_576, 'Carl Customer 5', true, true],
  ['steven@big.company', '1234', 1_048_576, 'Steven Customer 5', true, true],
  ['cust5@big.company', '1234', 1_048_576, 'Customer 5', true, true]
]
mailaccount_list.each do |mailaccount|
  MailAccount.new(email: mailaccount[0],
                  password: gen_doveadm_pwhash(mailaccount[1]),
                  receiving_enabled: mailaccount[4],
                  quota: mailaccount[2],
                  enabled: mailaccount[5],
                  domain_id: Domain.first(name: mailaccount[0].split('@')[1]).id,
                  realname: mailaccount[3]).save
end

mailalias_mailaccount_list = [
  ['aliastest@foobar.com', %w(me@foobar.com me2@foobar.com me3@foobar.com)],
  ['postmaster@foxxx0.de', 'me@foxxx0.de'],
  ['hostmaster@foxxx0.de', 'me@foxxx0.de'],
  ['webmaster@foxxx0.de', 'me@foxxx0.de'],
  ['abuse@foxxx0.de', 'me@foxxx0.de'],
  ['blog@foxxx0.de', 'me@foxxx0.de'],
  ['b@example.net', 'bob@example.net'],
  ['postmaster@example.net', 'bob@example.net'],
  ['hostmaster@example.net', 'bob@example.net'],
  ['webmaster@example.net', 'bob@example.net'],
  ['abuse@example.net', 'bob@example.net'],
  ['a@example.net', 'alice@example.net'],
  ['postmaster@herpderp.org', 'test@herpderp.org'],
  ['hostmaster@herpderp.org', 'test@herpderp.org'],
  ['webmaster@herpderp.org', 'test@herpderp.org'],
  ['admin@herpderp.org', 'test@herpderp.org'],
  ['foobar@herpderp.org', 'foo@herpderp.org'],
  ['f@herpderp.org', 'foo@herpderp.org'],
  ['barfoo@herpderp.org', 'bar@herpderp.org'],
  ['b@herpderp.org', 'bar@herpderp.org'],
  ['postmaster@schalala.net', 'test@schalala.net'],
  ['hostmaster@schalala.net', 'test@schalala.net'],
  ['webmaster@schalala.net', 'test@schalala.net'],
  ['admin@schalala.net', 'test@schalala.net'],
  ['herpderp@schalala.net', 'herp@schalala.net'],
  ['h@schalala.net', 'herp@schalala.net'],
  ['derpherp@schalala.net', 'derp@schalala.net'],
  ['d@schalala.net', 'derp@schalala.net'],
  ['postmaster@everything.eu', 'test@everything.eu'],
  ['hostmaster@everything.eu', 'test@everything.eu'],
  ['webmaster@everything.eu', 'test@everything.eu'],
  ['admin@everything.eu', 'test@everything.eu'],
  ['myself@everything.eu', 'me@everything.eu'],
  ['m@everything.eu', 'me@everything.eu'],
  ['himself@everything.eu', 'he@everything.eu'],
  ['h@everything.eu', 'he@everything.eu'],
  ['herself@everything.eu', 'she@everything.eu'],
  ['s@everything.eu', 'she@everything.eu'],
  ['postmaster@archlinux.sexy', 'test@archlinux.sexy'],
  ['hostmaster@archlinux.sexy', 'test@archlinux.sexy'],
  ['webmaster@archlinux.sexy', 'test@archlinux.sexy'],
  ['admin@archlinux.sexy', 'test@archlinux.sexy'],
  ['reseller1@archlinux.sexy', 'res1@archlinux.sexy'],
  ['r1@archlinux.sexy', 'res1@archlinux.sexy'],
  ['postmaster@kernel.org', 'test@kernel.org'],
  ['hostmaster@kernel.org', 'test@kernel.org'],
  ['webmaster@kernel.org', 'test@kernel.org'],
  ['admin@kernel.org', 'test@kernel.org'],
  ['reseller1@kernel.org', 'res1@kernel.org'],
  ['r1@kernel.org', 'res1@kernel.org'],
  ['postmaster@serious.business', 'test@serious.business'],
  ['hostmaster@serious.business', 'test@serious.business'],
  ['webmaster@serious.business', 'test@serious.business'],
  ['admin@serious.business', 'test@serious.business'],
  ['s@serious.business', 'sarah@serious.business'],
  ['customer4@serious.business', 'cust4@serious.business'],
  ['c4@serious.business', 'cust4@serious.business'],
  ['postmaster@big.company', 'test@big.company'],
  ['hostmaster@big.company', 'test@big.company'],
  ['webmaster@big.company', 'test@big.company'],
  ['admin@big.company', 'test@big.company'],
  ['s@big.company', 'steven@big.company'],
  ['steve@big.company', 'steven@big.company'],
  ['customer5@big.company', 'cust5@big.company'],
  ['c5@big.company', 'cust5@big.company']
]
mailalias_mailaccount_list.each do |mals_macc|
  MailAlias.new(
    address: mals_macc[0],
    enabled: true,
    domain_id: Domain.first(name: mals_macc[0].split('@')[1]).id
  ).save
  [*mals_macc[1]].each do |macc|
    acc = MailAccount.first(email: macc)
    acc.mail_aliases << MailAlias.first(address: mals_macc[0])
    acc.save
  end
end

mailsource_mailaccount_list = [
  ['me@foobar.com', 'me@foobar.com'],
  ['me2@foobar.com', 'me2@foobar.com'],
  ['me3@foobar.com', 'me3@foobar.com'],
  ['test@foobar.com', %w(me@foobar.com me2@foobar.com me3@foobar.com)],
  ['postmaster@foxxx0.de', 'me@foxxx0.de'],
  ['hostmaster@foxxx0.de', 'me@foxxx0.de'],
  ['webmaster@foxxx0.de', 'me@foxxx0.de'],
  ['abuse@foxxx0.de', 'me@foxxx0.de'],
  ['blog@foxxx0.de', 'me@foxxx0.de'],
  ['bob@example.net', 'bob@example.net'],
  ['postmaster@example.net', 'bob@example.net'],
  ['hostmaster@example.net', 'bob@example.net'],
  ['webmaster@example.net', 'bob@example.net'],
  ['abuse@example.net', 'bob@example.net'],
  ['alice@example.net', 'alice@example.net']
]
mailsource_mailaccount_list.each do |msrc_macc|
  MailSource.new(address: msrc_macc[0],
                 enabled: true,
                 domain_id: Domain.first(name: msrc_macc[0].split('@')[1]).id).save
  [*msrc_macc[1]].each do |macc|
    acc = MailAccount.first(email: macc)
    acc.mail_sources << MailSource.first(address: msrc_macc[0])
    acc.save
  end
end

# DKIM keys
Domain.all.each do |d|
  dkim = Dkim.new(domain_id: d.id, enabled: true)
  dkim.selector = 'mail'
  dkim.private_key = <<-EOF
-----BEGIN RSA PRIVATE KEY-----
some random private characters.......
-----END RSA PRIVATE KEY-----
EOF
  dkim.public_key = <<-EOF
-----BEGIN PUBLIC KEY-----
some random public characters.......
-----END PUBLIC KEY-----
EOF
  dkim.save
end

# DKIM author <-> key assignment
Dkim.all.each do |dk|
  DkimSigning.new(author: dk.domain.name,
                  dkim_id: dk.id,
                  enabled: true).save
end

ipv4_list = [
  ['127.0.0.1'],
  ['10.1.2.3']
]
ipv4_list.each do |ipv4|
  Ipv4Address.new(address: IPAddr.new(ipv4[0]), enabled: true).save
end

ipv6_list = [
  ['::1'],
  ['fe80::dead:beef']
]
ipv6_list.each do |ipv6|
  Ipv6Address.new(address: IPAddr.new(ipv6[0]), enabled: true).save
end

php_rt_list = [
  ['none', '0.0'],
  ['php56', '5.6.22'],
  ['php7', '7.0.7']
]
php_rt_list.each do |php_rt|
  PhpRuntime.new(name: php_rt[0],
                 version: php_rt[1],
                 enabled: true).save
end

vhost_list = [
  ['foxxx0.de', '10.1.2.3', 'fe80::dead:beef', false, 'none', 'c2web1', 'c2web1', true, 'fox'],
  ['ipv4.foxxx0.de', '10.1.2.3', '::1', true, 'php7', 'c2web2', 'c2web2', true, 'fox'],
  ['ipv6.foxxx0.de', '127.0.0.1', 'fe80::dead:beef', true, 'php7', 'c2web3', 'c2web3', true, 'fox'],
  ['paste.foxxx0.de', '10.1.2.3', 'fe80::dead:beef', true, 'php7', 'c2web4', 'c2web4', true, 'fox'],
  ['blog.foxxx0.de', '10.1.2.3', 'fe80::dead:beef', false, 'none', 'c2web5', 'c2web5', true, 'fox'],
  ['example.net', '10.1.2.3', 'fe80::dead:beef', false, 'none', 'c3web6', 'c3web6', true, 'max'],
  ['mail.example.net', '10.1.2.3', 'fe80::dead:beef', true, 'php56', 'c3web7', 'c3web7', true, 'max']
]
vhost_list.each do |vhost|
  Vhost.new(fqdn: vhost[0],
            ipv4_address_id: Ipv4Address.first(address: vhost[1]).id,
            ipv6_address_id: Ipv6Address.first(address: vhost[2]).id,
            php_enabled: vhost[3],
            php_runtime_id: PhpRuntime.first(name: vhost[4]).id,
            os_uid: vhost[5],
            os_gid: vhost[6],
            enabled: vhost[7],
            user_id: User.first(login: vhost[8]).id).save
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

# create the 4 necessary views
adapter = DataMapper.repository(:default).adapter
case adapter.options[:adapter].upcase
when 'POSTGRES'
  # dkim_lookup
  adapter.execute('CREATE OR REPLACE VIEW "dkim_lookup"
    AS
      SELECT
        "dkims"."id" AS "id",
        "domains"."name" AS "domain_name",
        "dkims"."selector" AS "selector",
        "dkims"."private_key" AS "private_key"
      FROM ("domains"
        LEFT JOIN "dkims"
          ON "dkims"."domain_id" = "domains"."id"
          AND "domains"."enabled" = TRUE)
      WHERE "dkims"."enabled" = TRUE;')
  # mail_alias_maps
  adapter.execute('CREATE OR REPLACE VIEW "mail_alias_maps"
    AS
      SELECT
        "mail_aliases"."address" AS "source",
        string_agg("mail_accounts"."email", \' \') AS "destination"
      FROM ("mail_account_mail_aliases"
        LEFT JOIN "mail_accounts"
          ON "mail_account_mail_aliases"."mail_account_id" = "mail_accounts"."id"
          AND "mail_accounts"."enabled" = TRUE
        RIGHT JOIN "mail_aliases"
          ON "mail_account_mail_aliases"."mail_alias_id" = "mail_aliases"."id"
          AND "mail_aliases"."enabled" = TRUE)
      WHERE "mail_accounts"."email" IS NOT NULL
      GROUP BY "mail_aliases"."address";')
  # mail_sendas_maps
  adapter.execute('CREATE OR REPLACE VIEW "mail_sendas_maps"
    AS
      SELECT
        "mail_sources"."address" AS "source",
        "mail_accounts"."email" AS "user"
      FROM ("mail_account_mail_sources"
        LEFT JOIN "mail_accounts"
          ON "mail_account_mail_sources"."mail_account_id" = "mail_accounts"."id"
          AND "mail_accounts"."enabled" = TRUE
        RIGHT JOIN "mail_sources"
          ON "mail_account_mail_sources"."mail_source_id" = "mail_sources"."id"
          AND "mail_sources"."enabled" = TRUE)
      WHERE "mail_accounts"."email" IS NOT NULL;')
  # sftp_user_maps
  adapter.execute('CREATE OR REPLACE VIEW "sftp_user_maps"
    AS
      SELECT
        "sftp_users"."username" AS "username",
        "sftp_users"."password" AS "passwd",
        "vhosts"."os_uid" AS "uid",
        "vhosts"."os_gid" AS "gid",
        "sftp_users"."homedir" AS "homedir",
        \'/bin/false\'::text AS "shell"
      FROM "sftp_users"
        RIGHT JOIN "vhosts"
          ON "sftp_users"."vhost_id" = "vhosts"."id"
      WHERE "vhosts"."enabled" = TRUE
        AND "sftp_users"."enabled" = TRUE;')
when 'MYSQL'
  # dkim_lookup
  adapter.execute('CREATE OR REPLACE ALGORITHM = TEMPTABLE VIEW `dkim_lookup`
    AS
      SELECT
        `dkims`.`id` AS `id`,
        `domains`.`name` AS `domain_name`,
        `dkims`.`selector` AS `selector`,
        `dkims`.`private_key` AS `private_key`
      FROM `dkims`
        RIGHT JOIN `domains`
          ON `dkims`.`domain_id` = `domains`.`id`
          AND `domains`.`enabled` = 1
      WHERE `dkims`.`enabled` = 1;')
  # mail_alias_maps
  adapter.execute('CREATE OR REPLACE ALGORITHM = TEMPTABLE VIEW `mail_alias_maps`
    AS
      SELECT
        `mail_aliases`.`address` AS `source`,
        group_concat(`mail_accounts`.`email` separator \' \') AS `destination`
      FROM (`mail_account_mail_aliases`
        LEFT JOIN `mail_accounts`
          ON `mail_account_mail_aliases`.`mail_account_id` = `mail_accounts`.`id`
          AND `mail_accounts`.`enabled` = 1
        RIGHT JOIN `mail_aliases`
          ON `mail_account_mail_aliases`.`mail_alias_id` = `mail_aliases`.`id`
          AND `mail_aliases`.`enabled` = 1)
      WHERE `mail_accounts`.`email` IS NOT NULL
      GROUP BY `mail_aliases`.`address`;')
  # mail_sendas_maps
  adapter.execute('CREATE OR REPLACE ALGORITHM = TEMPTABLE VIEW `mail_sendas_maps`
    AS
      SELECT
        `mail_sources`.`address` AS `source`,
        `mail_accounts`.`email` AS `user`
      FROM (`mail_account_mail_sources`
        LEFT JOIN `mail_accounts`
          ON `mail_account_mail_sources`.`mail_account_id` = `mail_accounts`.`id`
          AND `mail_accounts`.`enabled` = 1
        RIGHT JOIN `mail_sources`
          ON `mail_account_mail_sources`.`mail_source_id` = `mail_sources`.`id`
          AND `mail_sources`.`enabled` = 1)
      WHERE `mail_accounts`.`email` IS NOT NULL;')
  # sftp proftpd user lookup
  adapter.execute('CREATE OR REPLACE ALGORITHM = TEMPTABLE VIEW `sftp_user_maps`
    AS
      SELECT
        `sftp_users`.`username` AS `username`,
        `sftp_users`.`password` AS passwd,
        `vhosts`.`os_uid` AS uid,
        `vhosts`.`os_gid` AS gid,
        `sftp_users`.`homedir` AS homedir,
        \'/bin/false\' AS shell
      FROM `sftp_users`
        RIGHT JOIN `vhosts`
          ON `sftp_users`.`vhost_id` = `vhosts`.`id`
      WHERE `vhosts`.`enabled` = 1
        AND `sftp_users`.`enabled` = 1;')
else
  raise 'Error: unsupported database adapter!'
end

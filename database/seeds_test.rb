# frozen_string_literal: true
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
  ['Admin', 'admin', 'secret', true, 'admin', nil],
  ['Thore Bödecker', 'fox', 'geheim', true, 'admin', nil],
  ['Max Mustermann', 'max', 'muster', true, 'user', nil],
  ['Reseller 1', 'reseller1', 'reseller1', true, 'reseller', nil],
  ['Customer 1', 'customer1', 'customer1', true, 'user', 'reseller1'],
  ['Customer 2', 'customer2', 'customer2', true, 'user', 'reseller1'],
  ['Customer 3', 'customer3', 'customer3', true, 'user', 'reseller1'],
  ['Reseller 2', 'reseller2', 'reseller2', true, 'reseller', nil],
  ['Customer 4', 'customer4', 'customer4', true, 'user', 'reseller2'],
  ['Customer 5', 'customer5', 'customer5', true, 'user', 'reseller2']
]
user_list.each do |user|
  g = Group.first(name: user[4])
  u = User.create(name: user[0],
                  login: user[1],
                  password: user[2],
                  enabled: user[3],
                  group: g)
  next if user[5].nil?
  u.reseller_id = User.first(login: user[5]).id
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
                  domain: Domain.first(name: mailaccount[0].split('@')[1]),
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
    domain: Domain.first(name: mals_macc[0].split('@')[1])
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
                 domain: Domain.first(name: msrc_macc[0].split('@')[1])).save
  [*msrc_macc[1]].each do |macc|
    acc = MailAccount.first(email: macc)
    acc.mail_sources << MailSource.first(address: msrc_macc[0])
    acc.save
  end
end

# DKIM keys
Domain.all.each do |d|
  dkim = Dkim.new(domain: d, enabled: true)
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
                  dkim: dk,
                  enabled: true).save
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

ipv4_list = [
  ['127.0.0.1', User.all.map(&:login)],
  ['10.1.1.1', User.all.map(&:login)],
  ['10.2.2.2', %w(customer1 customer2)],
  ['10.2.2.3', %w(customer3)],
  ['10.3.3.3', %w(reseller2 customer4)],
  ['10.4.4.4', %w(max)]
]
ipv4_list.each do |ipv4|
  users = User.all(id: 0)
  ipv4[1].each do |u|
    users.concat(User.all(login: u))
  end
  Ipv4Address.new(address: IPAddr.new(ipv4[0]),
                  enabled: true,
                  users: users).save
end

ipv6_list = [
  ['::1', User.all.map(&:login)],
  ['fe80::dead:beef', User.all.map(&:login)],
  ['fe80::beef:1', %w(reseller1 customer1 customer2)],
  ['fe80::beef:2', %w(reseller1)],
  ['fe80::beef:3', %w(reseller2 customer4)],
  ['fe80::beef:4', %w(max)]
]
ipv6_list.each do |ipv6|
  users = User.all(id: 0)
  ipv6[1].each { |u| users.concat(User.all(login: u)) }
  Ipv6Address.new(address: IPAddr.new(ipv6[0]),
                  enabled: true,
                  users: users).save
end

vhost_list = [
  ['foxxx0.de', :vhost, '10.1.1.1', 'fe80::dead:beef', false, 'none', true,
   'fox'],
  ['ipv4.foxxx0.de', :vhost, '10.1.1.1', '::1', true, 'php7', true, 'fox'],
  ['ipv6.foxxx0.de', :vhost, '127.0.0.1', 'fe80::dead:beef', true, 'php7', true,
   'fox'],
  ['paste.foxxx0.de', :vhost, '10.1.1.1', 'fe80::dead:beef', true, 'php7', true,
   'fox'],
  ['p.foxxx0.de', :alias, :none, '10.1.1.1', 'fe80::dead:beef',
   'paste.foxxx0.de', true, 'fox'],
  ['blog.foxxx0.de', :vhost, '10.1.1.1', 'fe80::dead:beef', false, 'none', true,
   'fox'],
  ['example.net', :vhost, '10.1.1.1', 'fe80::dead:beef', false, 'none', true,
   'max'],
  ['mail.example.net', :vhost, '10.4.4.4', 'fe80::beef:4', true, 'php56', true,
   'max'],
  ['webmail.example.net', :alias, :permanent, '10.4.4.4', 'fe80::beef:4',
   'mail.example.net', true, 'max'],
  ['herpderp.org', :vhost, '10.1.1.1', 'fe80::beef:1', false, 'none', true,
   'customer1'],
  ['test.herpderp.org', :vhost, '10.2.2.2', 'fe80::beef:1', false, 'none', true,
   'customer1'],
  ['sub.herpderp.org', :vhost, '10.1.1.1', 'fe80::dead:beef', false, 'none',
   true, 'customer1'],
  ['schalala.net', :vhost, '10.2.2.2', 'fe80::beef:1', false, 'none', true,
   'customer2'],
  ['test.schalala.net', :vhost, '10.2.2.2', 'fe80::dead:beef', false, 'none',
   true, 'customer2'],
  ['sub.schalala.net', :vhost, '10.1.1.1', 'fe80::beef:1', false, 'none', true,
   'customer2'],
  ['everything.eu', :vhost, '10.1.1.1', 'fe80::dead:beef', false, 'none', true,
   'customer3'],
  ['foo.everything.eu', :vhost, '10.2.2.3', 'fe80::dead:beef', false, 'none',
   true, 'customer3'],
  ['serious.business', :vhost, '10.3.3.3', 'fe80::beef:3', false, 'none', true,
   'customer4'],
  ['big.company', :vhost, '10.1.1.1', 'fe80::dead:beef', false, 'none', true,
   'customer5'],
  ['archlinux.sexy', :vhost, '10.2.2.3', 'fe80::beef:2', false, 'none', true,
   'reseller1'],
  ['kernel.org', :vhost, '10.1.1.1', 'fe80::dead:beef', false, 'none', true,
   'reseller1'],
  ['herp.herpderp.org', :alias, :none, '10.1.1.1', 'fe80::dead:beef',
   'sub.herpderp.org', true, 'customer1'],
  ['derp.herpderp.org', :alias, :none, '10.1.1.1', 'fe80::dead:beef',
   'sub.herpderp.org', true, 'customer1'],
  ['merp.herpderp.org', :alias, :none, '10.1.1.1', 'fe80::dead:beef',
   'test.herpderp.org', true, 'customer1'],
  ['blerp.herpderp.org', :alias, :none, '10.1.1.1', 'fe80::dead:beef',
   'test.herpderp.org', true, 'customer1'],
  ['bar.schalala.net', :alias, :none, '10.1.1.1', 'fe80::dead:beef',
   'schalala.net', true, 'customer2'],
  ['xyz.schalala.net', :alias, :none, '10.1.1.1', 'fe80::dead:beef',
   'schalala.net', true, 'customer2'],
  ['bla.everything.eu', :alias, :none, '10.1.1.1', 'fe80::dead:beef',
   'everything.eu', true, 'customer3'],
  ['funny.serious.business', :alias, :none, '10.1.1.1', 'fe80::dead:beef',
   'serious.business', true, 'customer4'],
  ['little.big.company', :alias, :none, '10.1.1.1', 'fe80::dead:beef',
   'big.company', true, 'customer5'],
  ['cdn.archlinux.sexy', :alias, :none, '10.1.1.1', 'fe80::dead:beef',
   'archlinux.sexy', true, 'reseller1'],
  ['login.herpderp.org', :alias, :temporary, '10.1.1.1', 'fe80::dead:beef',
   'herpderp.org', true, 'customer1'],
  ['hodor.herpderp.org', :alias, :temporary, '10.1.1.1', 'fe80::dead:beef',
   'herpderp.org', true, 'customer1'],
  ['moved.herpderp.org', :alias, :permanent, '10.1.1.1', 'fe80::dead:beef',
   'herpderp.org', true, 'customer1'],
  ['gone.herpderp.org', :alias, :permanent, '10.1.1.1', 'fe80::dead:beef',
   'herpderp.org', true, 'customer1'],
  ['cdn.kernel.org', :alias, :temporary, '10.1.1.1', 'fe80::dead:beef',
   'archlinux.sexy', true, 'reseller1'],
  ['svn.kernel.org', :alias, :permanent, '10.1.1.1', 'fe80::dead:beef',
   'kernel.org', true, 'reseller1']
]
vhost_list.each do |vhost|
  case vhost[1]
  when :alias
    parent_vhost = Vhost.first(fqdn: vhost[5])
    Vhost.create(fqdn: vhost[0],
                 type: :alias,
                 redirect_type: vhost[2],
                 ipv4_address: Ipv4Address.first(address: vhost[3]),
                 ipv6_address: Ipv6Address.first(address: vhost[4]),
                 php_enabled: false,
                 php_runtime: PhpRuntime.first(name: 'none'),
                 os_uid: parent_vhost.os_uid,
                 os_gid: parent_vhost.os_uid,
                 parent: parent_vhost,
                 enabled: vhost[6],
                 user: User.first(login: vhost[7]))
  when :vhost
    vhost_basedir = '/srv/http/vhost/clients'
    u = User.first(login: vhost[7])
    v = Vhost.create(fqdn: vhost[0],
                     type: :vhost,
                     ipv4_address: Ipv4Address.first(address: vhost[2]),
                     ipv6_address: Ipv6Address.first(address: vhost[3]),
                     php_enabled: vhost[4],
                     php_runtime: PhpRuntime.first(name: vhost[5]),
                     enabled: vhost[6],
                     user: u)
    v.document_root = [vhost_basedir,
                       'client' + u.id.to_s,
                       'web' + v.id.to_s,
                       'htdocs'].map(&:to_s).join('/')
    v.os_uid = 'c' + u.id.to_s + 'web' + v.id.to_s
    v.os_gid = 'c' + u.id.to_s + 'web' + v.id.to_s
    v.save
  end
end

# '1test!sftplogin?' = {md5}f5NspiyFx2u8dxbZARAcjQ==
sftp_user_list = [
  ['{md5}f5NspiyFx2u8dxbZARAcjQ==', 'blog.foxxx0.de', true],
  ['{md5}f5NspiyFx2u8dxbZARAcjQ==', 'mail.example.net', true],
  ['{md5}f5NspiyFx2u8dxbZARAcjQ==', 'herpderp.org', true],
  ['{md5}f5NspiyFx2u8dxbZARAcjQ==', 'sub.herpderp.org', true],
  ['{md5}f5NspiyFx2u8dxbZARAcjQ==', 'test.schalala.net', true],
  ['{md5}f5NspiyFx2u8dxbZARAcjQ==', 'foo.everything.eu', true],
  ['{md5}f5NspiyFx2u8dxbZARAcjQ==', 'serious.business', true],
  ['{md5}f5NspiyFx2u8dxbZARAcjQ==', 'big.company', true],
  ['{md5}f5NspiyFx2u8dxbZARAcjQ==', 'archlinux.sexy', true],
  ['{md5}f5NspiyFx2u8dxbZARAcjQ==', 'kernel.org', true]
]
sftp_user_list.each do |sftp_user|
  v = Vhost.first(fqdn: sftp_user[1])
  u_home = v.document_root.gsub(%r{/htdocs}, '')
  u = SftpUser.create(username: SecureRandom.hex(8),
                      homedir: u_home,
                      password: sftp_user[0],
                      vhost: v,
                      enabled: sftp_user[2])
  u.username = [v.os_uid, u.id].join('-')
  u.save
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
          ON "dkims"."domain_id"="domains"."id"
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
          ON
            "mail_account_mail_aliases"."mail_account_id"="mail_accounts"."id"
          AND "mail_accounts"."enabled" = TRUE
        RIGHT JOIN "mail_aliases"
          ON "mail_account_mail_aliases"."mail_alias_id"="mail_aliases"."id"
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
          ON "mail_account_mail_sources"."mail_account_id"="mail_accounts"."id"
          AND "mail_accounts"."enabled" = TRUE
        RIGHT JOIN "mail_sources"
          ON "mail_account_mail_sources"."mail_source_id"="mail_sources"."id"
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
          ON "sftp_users"."vhost_id"="vhosts"."id"
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
          ON `dkims`.`domain_id`=`domains`.`id`
          AND `domains`.`enabled` = 1
      WHERE `dkims`.`enabled` = 1;')
  # mail_alias_maps
  adapter.execute('CREATE OR REPLACE ALGORITHM = TEMPTABLE
  VIEW `mail_alias_maps`
    AS
      SELECT
        `mail_aliases`.`address` AS `source`,
        group_concat(`mail_accounts`.`email` separator \' \') AS `destination`
      FROM (`mail_account_mail_aliases`
        LEFT JOIN `mail_accounts`
          ON `mail_account_mail_aliases`.`mail_account_id`=`mail_accounts`.`id`
          AND `mail_accounts`.`enabled` = 1
        RIGHT JOIN `mail_aliases`
          ON `mail_account_mail_aliases`.`mail_alias_id`=`mail_aliases`.`id`
          AND `mail_aliases`.`enabled` = 1)
      WHERE `mail_accounts`.`email` IS NOT NULL
      GROUP BY `mail_aliases`.`address`;')
  # mail_sendas_maps
  adapter.execute('CREATE OR REPLACE ALGORITHM = TEMPTABLE
  VIEW `mail_sendas_maps`
    AS
      SELECT
        `mail_sources`.`address` AS `source`,
        `mail_accounts`.`email` AS `user`
      FROM (`mail_account_mail_sources`
        LEFT JOIN `mail_accounts`
          ON `mail_account_mail_sources`.`mail_account_id`=`mail_accounts`.`id`
          AND `mail_accounts`.`enabled` = 1
        RIGHT JOIN `mail_sources`
          ON `mail_account_mail_sources`.`mail_source_id`=`mail_sources`.`id`
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
          ON `sftp_users`.`vhost_id`=`vhosts`.`id`
      WHERE `vhosts`.`enabled` = 1
        AND `sftp_users`.`enabled` = 1;')
else
  raise 'Error: unsupported database adapter!'
end

# frozen_string_literal: true

# rubocop:disable Metrics/LineLength
group_list = [
  ['admin', true],
  ['reseller', true],
  ['user', true]
]
group_list.each do |group|
  Group.new(name: group[0], enabled: group[1]).save
end

user_list = [
  ['admin', 'admin', SecureRandom.hex(8), true, 'admin']
]
user_list.each do |user|
  u = User.new(name: user[0], login: user[1], password: user[2], enabled: user[3],
               group_id: Group.first(name: user[4]).id)
  u.save
  puts "Created User #{u.name} with login #{u.login} and password #{user[2]}"
end

package_list = [
  ['default', 0, true, 'admin']
]
package_list.each do |package|
  Package.new(name: package[0],
              price_unit: package[1],
              quota_apikeys: 1,
              enabled: package[2],
              user: User.first(login: package[3])).save
end

# create the necessary views
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
  # dkim_signing_lookup
  adapter.execute('CREATE OR REPLACE VIEW "dkim_lookup_signing"
    AS
      SELECT
        "dkim_signings"."id" AS "id",
        "dkim_signings"."author" AS "author",
        "dkim_signings"."dkim_id" AS "dkim_id"
      FROM ("dkims"
        LEFT JOIN "dkim_signings"
          ON "dkim_signings"."dkim_id"="dkims"."id"
          AND "dkims"."enabled" = TRUE
        LEFT JOIN "domains"
          ON "dkims"."domain_id"="domains"."id"
          AND "domains"."enabled" = TRUE)
      WHERE "dkim_signings"."enabled" = TRUE;')
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
        LEFT JOIN "domains"
          ON
            "mail_accounts"."domain_id"="domains"."id"
        RIGHT JOIN "mail_aliases"
          ON "mail_account_mail_aliases"."mail_alias_id"="mail_aliases"."id"
          AND "mail_aliases"."enabled" = TRUE)
      WHERE "mail_accounts"."email" IS NOT NULL
      AND "domains"."enabled" = TRUE
      AND "domains"."mail_enabled" = TRUE
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
        LEFT JOIN "domains"
          ON
            "mail_accounts"."domain_id"="domains"."id"
        RIGHT JOIN "mail_sources"
          ON "mail_account_mail_sources"."mail_source_id"="mail_sources"."id"
          AND "mail_sources"."enabled" = TRUE)
      WHERE "mail_accounts"."email" IS NOT NULL
      AND "domains"."enabled" = TRUE
      AND "domains"."mail_enabled" = TRUE;')
  # mail_forwarding_maps
  adapter.execute('CREATE OR REPLACE VIEW "mail_forwarding_maps"
    AS
      SELECT
        "mail_forwardings"."address" AS "source",
        "mail_forwardings"."destinations" AS "destination"
      FROM "mail_forwardings"
        LEFT JOIN "domains"
          ON
            "mail_forwardings"."domain_id"="domains"."id"
      WHERE "mail_forwardings"."address" IS NOT NULL
      AND "mail_forwardings"."destinations" IS NOT NULL
      AND "mail_forwardings"."enabled" = TRUE
      AND "domains"."enabled" = TRUE
      AND "domains"."mail_enabled" = TRUE;')
  # mail_user_maps
  adapter.execute('CREATE OR REPLACE VIEW "mail_user_maps"
    AS
      SELECT
        "mail_accounts"."email" AS "email",
        "mail_accounts"."password" AS "password",
        "mail_accounts"."quota" AS "quota"
      FROM "mail_accounts"
        LEFT JOIN "domains"
          ON
            "mail_accounts"."domain_id"="domains"."id"
      WHERE "mail_accounts"."email" IS NOT NULL
      AND "mail_accounts"."enabled" = TRUE
      AND "mail_accounts"."receiving_enabled" = TRUE
      AND "domains"."enabled" = TRUE
      AND "domains"."mail_enabled" = TRUE;')
  # sftp_user_maps
  adapter.execute('CREATE OR REPLACE VIEW "sftp_user_maps"
    AS
      SELECT
        "sftp_users"."username" AS "username",
        "sftp_users"."password" AS "passwd",
        "vhosts"."os_uid" AS "uid",
        "vhosts"."os_gid" AS "gid",
        "sftp_users"."homedir" AS "homedir",
        \'/bin/nologin\'::text AS "shell"
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
  # dkim_signing_lookup
  adapter.execute('CREATE OR REPLACE ALGORITHM = TEMPTABLE
  VIEW `dkim_lookup_signing`
    AS
      SELECT
        `dkim_signings`.`id` AS `id`,
        `dkim_signings`.`author` AS `author`,
        `dkim_signings`.`dkim_id` AS `dkim_id`
      FROM (`dkims`
        LEFT JOIN `dkim_signings`
          ON `dkim_signings`.`dkim_id`=`dkims`.`id`
          AND `dkims`.`enabled` = TRUE
        LEFT JOIN `domains`
          ON `dkims`.`domain_id`=`domains`.`id`
          AND `domains`.`enabled` = TRUE)
      WHERE `dkim_signings`.`enabled` = TRUE;')
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
        LEFT JOIN `domains`
          ON
            `mail_accounts`.`domain_id`=`domains`.`id`
        RIGHT JOIN `mail_aliases`
          ON `mail_account_mail_aliases`.`mail_alias_id`=`mail_aliases`.`id`
          AND `mail_aliases`.`enabled` = 1)
      WHERE `mail_accounts`.`email` IS NOT NULL
      AND `domains`.`enabled` = 1
      AND `domains`.`mail_enabled` = 1
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
        LEFT JOIN `domains`
          ON
            `mail_accounts`.`domain_id`=`domains`.`id`
        RIGHT JOIN `mail_sources`
          ON `mail_account_mail_sources`.`mail_source_id`=`mail_sources`.`id`
          AND `mail_sources`.`enabled` = 1)
      WHERE `mail_accounts`.`email` IS NOT NULL
      AND `domains`.`enabled` = 1
      AND `domains`.`mail_enabled` = 1;')
  # mail_forwarding_maps
  adapter.execute('CREATE OR REPLACE ALGORITHM = TEMPTABLE
  VIEW `mail_forwarding_maps`
    AS
      SELECT
        `mail_forwardings`.`address` AS `source`,
        `mail_forwardings`.`destinations` AS `destination`
      FROM `mail_forwardings`
        LEFT JOIN `domains`
          ON
            `mail_forwardings`.`domain_id`=`domains`.`id`
      WHERE `mail_forwardings`.`address` IS NOT NULL
      AND `mail_forwardings`.`destinations` IS NOT NULL
      AND `mail_forwardings`.`enabled` = 1
      AND `domains`.`enabled` = 1
      AND `domains`.`mail_enabled` = 1;')
  # mail_user_maps
  adapter.execute('CREATE OR REPLACE ALGORITHM = TEMPTABLE
  VIEW `mail_user_maps`
    AS
      SELECT
        `mail_accounts`.`email` AS `email`,
        `mail_accounts`.`password` AS `password`,
        `mail_accounts`.`quota` AS `quota`
      FROM `mail_accounts`
        LEFT JOIN `domains`
          ON
            `mail_accounts`.`domain_id`=`domains`.`id`
      WHERE `mail_accounts`.`email` IS NOT NULL
      AND `mail_accounts`.`enabled` = 1
      AND `mail_accounts`.`receiving_enabled` = 1
      AND `domains`.`enabled` = 1
      AND `domains`.`mail_enabled` = 1;')
  # sftp proftpd user lookup
  adapter.execute('CREATE OR REPLACE ALGORITHM = TEMPTABLE VIEW `sftp_user_maps`
    AS
      SELECT
        `sftp_users`.`username` AS `username`,
        `sftp_users`.`password` AS passwd,
        `vhosts`.`os_uid` AS uid,
        `vhosts`.`os_gid` AS gid,
        `sftp_users`.`homedir` AS homedir,
        \'/bin/nologin\' AS shell
      FROM `sftp_users`
        RIGHT JOIN `vhosts`
          ON `sftp_users`.`vhost_id`=`vhosts`.`id`
      WHERE `vhosts`.`enabled` = 1
        AND `sftp_users`.`enabled` = 1;')
else
  raise 'Error: unsupported database adapter!'
end

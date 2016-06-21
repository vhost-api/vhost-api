group_list = [
  ['admin', true]
]
group_list.each do |group|
  Group.new(name: group[0], enabled: group[1]).save
end

user_list = [
  ['admin', 'admin', 'secret', true, 1]
]
user_list.each do |user|
  User.new(name: user[0], login: user[1], password: user[2], enabled: user[3],
           group_id: user[4]).save
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

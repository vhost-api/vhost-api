# frozen_string_literal; false
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

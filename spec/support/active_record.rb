require 'active_record'

class ActiveRecord::Base
  establish_connection 'sqlite3:tmp/db.sqlite3'
end

class Model < ActiveRecord::Base
end

table_name = SecureRandom.hex
Model.table_name = table_name

migration = ActiveRecord::Migration.new

migration.create_table table_name do |t|
  t.integer 'integer'
  t.string 'string'
  t.datetime 'datetime'
  t.boolean 'boolean'
  t.text 'text'
end

integers = [1, 2, 3, 4, 5, 5, 5]
strings = ['yo', 'hi', 'hello', 'hola', '好！', 'хорошо', '']
datetimes = [DateTime.new(1900, 1, 1), DateTime.new(2000, 1, 1), DateTime.new(2100, 1, 1)]
booleans = [true, false]
texts = %w(yo hi hello)

10.times do |i|
  m = Model.new(integer: integers[i],
                string: strings[i],
                datetime: datetimes[i],
                boolean: booleans[i],
                text: texts[i])
  m.save!
end

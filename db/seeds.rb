# This file contains all the record creation needed to seed the database with its default values.
# The data can be created alongside the db with db:setup (or loaded with the rake db:seed).

if User.exists?
  puts "Database already initialized. Nothing done"
else

  data = "#{RAILS_ROOT}/db/data.sql"
  schema_wip = "#{RAILS_ROOT}/db/schema_wip.sql"
  conf = Rails.configuration.database_configuration[Rails.env]

  system("psql #{conf['database']} -U #{conf['username']} -f #{data}")
  system("psql #{conf['database']} -U #{conf['username']} -f #{schema_wip}")

  Institution.create(
    :name => "Gruppo di lavoro Dolly",
    :email => "info@example.com",
    :address => "Indirizzo",
    :phone => "012 3456789",
    :user_id => 1
  )

  users = User.create([
    {
      :first_name => "SuperAdmin",
      :last_name => "Dolly",
      :login => "superadmin_dolly",
      :email => "superadmin@example.com",
      :password => "superadmin_dolly",
      :password_confirmation => "superadmin_dolly",
      :role_id => 4,
      :institution_id => 1
    },
    {
      :first_name => "Admin",
      :last_name => "Dolly",
      :login => "admin_dolly",
      :email => "admin@example.com",
      :password => "admin_dolly",
      :password_confirmation => "admin_dolly",
      :role_id => 3,
      :institution_id => 1
    }
  ])

end

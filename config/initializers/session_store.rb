# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random,
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key         => '_dolly_session',
  :secret      => 'a99a3ce12fef4baf3d9c8c2c89cb5d71ca05d97102dc6313b8954b940221b327a403628e94133042426e53a58897b1e87b0c19a4a78bf6b9b8b28044dcef5d10'
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
#
#OPTIMIZE: db session store temporarily disabled because of IE and Win browsers problem
# ActionController::Base.session_store = :active_record_store
#

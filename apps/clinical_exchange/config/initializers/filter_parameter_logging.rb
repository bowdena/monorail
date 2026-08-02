# Be sure to restart your server when you modify this file.

# Configure parameters to be partially matched (e.g. passw matches password) and filtered from the log file.
# Use this to limit dissemination of sensitive information.
# See the ActiveSupport::ParameterFilter documentation for supported notations and behaviors.
Rails.application.config.filter_parameters += [
  :passw, :email, :secret, :token, :_key, :crypt, :salt, :certificate, :otp, :ssn, :cvv, :cvc
]

# Search criteria identify a patient. The URN stays readable — it is the
# identifier staff quote to each other, and the log is far less useful
# without it — but a name and date of birth together are enough to
# recognise someone, so they are blanked. Conduit's own audit line is
# deliberately left complete: recording what was searched is its job.
Rails.application.config.filter_parameters += [ :first_name, :date_of_birth ]

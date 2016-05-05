# Be sure to restart your server when you modify this file.

# Configure sensitive parameters which will be filtered from the log file.
Rails.application.config.filter_parameters += [:password, :passphrase, :passphrase_confirmation, :key_pair, :password_confirmation, :card_number, :ccv, :account_number, :bsb]

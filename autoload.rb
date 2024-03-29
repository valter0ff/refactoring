require 'i18n'
require 'pry-byebug'
require_relative 'config/i18n_config'
require_relative 'lib/helpers/database_loader'
require_relative 'lib/helpers/validations'
require_relative 'lib/entities/base_card'
require_relative 'lib/entities/usual_card'
require_relative 'lib/entities/capitalist_card'
require_relative 'lib/entities/virtual_card'
require_relative 'lib/entities/account'
require_relative 'lib/operations/money_operations'
require_relative 'lib/operations/put_money'
require_relative 'lib/operations/withdraw_money'
require_relative 'lib/operations/send_money'
require_relative 'lib/operations/card_operations'
require_relative 'lib/main_console'

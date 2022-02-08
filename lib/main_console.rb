class MainConsole
  include DatabaseLoader

  DATA_FILE = File.expand_path('../db/accounts.yml', __dir__)
  DIR_NAME = 'db'.freeze
  CARD_COMMANDS = I18n.t('commands.card').values
  MONEY_COMMANDS = { I18n.t('commands.money.put') => PutMoney,
                     I18n.t('commands.money.withdraw') => WithdrawMoney,
                     I18n.t('commands.money.send') => SendMoney }.freeze

  attr_reader :current_account

  def console
    puts I18n.t(:hello)
    input = gets.chomp
    case input
    when I18n.t('commands.create_acc') then create_account
    when I18n.t('commands.load_acc') then load_account
    else
      exit
    end
  end

  def create_account
    @current_account = Account.new.create
    updated_accounts = accounts << current_account
    store_to_file(updated_accounts, DATA_FILE, DIR_NAME)
    main_menu
  end

  def load_account
    return create_first_account if accounts.empty?

    authorize
    main_menu
  end

  def create_first_account
    puts I18n.t('common.create_first_account')
    gets.chomp == I18n.t('commands.positive') ? create_account : console
  end

  def main_menu
    loop do
      show_commands
      command = gets.chomp
      exit if command == I18n.t('commands.exit')
      case command
      when *(CARD_COMMANDS + MONEY_COMMANDS.keys) then operations(command)
      when I18n.t('commands.destroy_acc') then destroy_account && exit
      else puts I18n.t('errors.wrong_command')
      end
    end
  end

  def operations(command)
    case command
    when *CARD_COMMANDS then CardOperations.call(current_account, command)
    when *MONEY_COMMANDS.keys then MONEY_COMMANDS[command].call(current_account)
    end
    save_database
  end

  def destroy_account
    puts I18n.t('common.destroy_account')
    return unless gets.chomp == I18n.t('commands.positive')

    updated_accounts = accounts.delete_if { |acc| acc.login == current_account.login }
    store_to_file(updated_accounts, DATA_FILE, DIR_NAME)
  end

  private

  def authorize
    loop do
      puts I18n.t('ask_phrases.login')
      login = gets.chomp
      puts I18n.t('ask_phrases.password')
      password = gets.chomp
      @current_account = find_account(login, password)
      break if current_account

      puts I18n.t('errors.user_not_exists')
    end
  end

  def find_account(login, password)
    accounts.find { |acc| acc.login == login && acc.password == password }
  end

  def accounts
    load_from_file(DATA_FILE) || []
  end

  def save_database
    updated_accounts = accounts.collect { |acc| current_account if acc.login == current_account.login }
    store_to_file(updated_accounts, DATA_FILE, DIR_NAME)
  end

  def show_commands
    puts I18n.t('common.welcome', name: current_account.name)
    puts I18n.t(:main_operations)
  end
end

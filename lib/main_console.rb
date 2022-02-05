class MainConsole
  include DatabaseLoader

  DATA_FILE = File.expand_path('../db/accounts.yml', __dir__)
  DIR_NAME = 'db'.freeze
  CARD_COMMANDS = I18n.t('commands.card').values
  MONEY_COMMANDS = I18n.t('commands.money').values

  attr_accessor :current_account

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
    updated_accounts = accounts  << @current_account
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
      when *(CARD_COMMANDS + MONEY_COMMANDS) then operations(command)
      when I18n.t('commands.destroy_acc') then destroy_account && exit
      else puts I18n.t('errors.wrong_command')
      end
    end
  end

  def operations(command)
    case command
    when *CARD_COMMANDS then CardOperations.call(@current_account, command)
    when *MONEY_COMMANDS then money_operations(command)
    end
    save_database
  end

  def money_operations(command)
    case command
    when I18n.t('commands.money.put') then put_money
    when I18n.t('commands.money.withdraw') then withdraw_money
    when I18n.t('commands.money.send') then send_money
    end
  end

  def withdraw_money
    puts 'Choose the card for withdrawing:'
    answer, a2, a3 = nil #answers for gets.chomp
    if @current_account.cards.any?
      @current_account.cards.each_with_index do |c, i|
        puts "- #{c.number}, #{c.type}, press #{i + 1}"
      end
      puts "press `exit` to exit\n"
      loop do
        answer = gets.chomp
        break if answer == 'exit'
        if answer.to_i <= @current_account.cards.length && answer.to_i > 0
          current_card = @current_account.cards[answer.to_i - 1]
          loop do
            puts 'Input the amount of money you want to withdraw'
            amount = gets.chomp
            if amount.to_i > 0
              money_left = current_card.balance - amount.to_i - current_card.withdraw_tax(amount.to_i)
              if money_left > 0
                current_card.balance = money_left
                @current_account.cards[answer.to_i - 1] = current_card
                save_database
                puts "Money #{amount.to_i} withdrawed from #{current_card.number}$. Money left: #{current_card.balance}$. Tax: #{current_card.withdraw_tax(amount.to_i)}$"
                return
              else
                puts "You don't have enough money on card for such operation"
                return
              end
            else
              puts 'You must input correct amount of $'
              return
            end
          end
        else
          puts "You entered wrong number!\n"
          return
        end
      end
    else
      puts "There is no active cards!\n"
    end
  end

  def put_money
    puts 'Choose the card for putting:'

    if @current_account.cards.any?
      @current_account.cards.each_with_index do |c, i|
        puts "- #{c.number}, #{c.type}, press #{i + 1}"
      end
      puts "press `exit` to exit\n"
      loop do
        answer = gets.chomp
        break if answer == 'exit'
        if answer.to_i <= @current_account.cards.length && answer.to_i > 0
          current_card = @current_account.cards[answer.to_i - 1]
          loop do
            puts 'Input the amount of money you want to put on your card'
            amount = gets.chomp
            if amount.to_i > 0
              if current_card.put_tax(amount.to_i) >= amount.to_i
                puts 'Your tax is higher than input amount'
                return
              else
                new_money_amount = current_card.balance + amount.to_i - current_card.put_tax(amount.to_i)
                current_card.balance = new_money_amount
                @current_account.cards[answer.to_i - 1] = current_card
                save_database
                puts "Money #{amount.to_i} was put on #{current_card.number}. Balance: #{current_card.balance}. Tax: #{current_card.put_tax(amount.to_i)}"
                return
              end
            else
              puts 'You must input correct amount of money'
              return
            end
          end
        else
          puts "You entered wrong number!\n"
          return
        end
      end
    else
      puts "There is no active cards!\n"
    end
  end

  def send_money
    puts 'Choose the card for sending:'

    if @current_account.cards.any?
      @current_account.cards.each_with_index do |c, i|
        puts "- #{c.number}, #{c.type}, press #{i + 1}"
      end
      puts "press `exit` to exit\n"
      answer = gets.chomp
      exit if answer == 'exit'
      if answer.to_i <= @current_account.cards.length && answer.to_i > 0
        sender_card = @current_account.cards[answer.to_i - 1]
      else
        puts 'Choose correct card'
        return
      end
    else
      puts "There is no active cards!\n"
      return
    end

    puts 'Enter the recipient card:'
    a2 = gets.chomp
    if a2.length > 15 && a2.length < 17
      all_cards = accounts.map(&:card).flatten
      if all_cards.select { |card| card.number == a2 }.any?
        recipient_card = all_cards.detect { |card| card.number == a2 }
      else
        puts "There is no card with number #{a2}\n"
        return
      end
    else
      puts 'Please, input correct number of card'
      return
    end

    loop do
      puts 'Input the amount of money you want to withdraw'
      amount = gets.chomp
      if amount.to_i > 0
        sender_balance = sender_card.balance - amount.to_i - sender_card.sender_tax(amount.to_i)
        recipient_balance = recipient_card.balance + amount.to_i - recipient_card.put_tax(amount.to_i)

        if sender_balance < 0
          puts "You don't have enough money on card for such operation"
        elsif recipient_card.put_tax(amount.to_i) >= amount.to_i
          puts 'There is no enough money on sender card'
        else
          sender_card.balance = sender_balance
          @current_account.cards[answer.to_i - 1] = sender_card
          new_accounts = []
          accounts.each do |ac|
            if ac.login == @current_account.login
              new_accounts.push(@current_account)
            elsif ac.card.map(&:number).include? a2
              recipient = ac
              new_recipient_cards = []
              recipient.card.each do |card|
                if card.number == a2
                  card.balance = recipient_balance
                end
                new_recipient_cards.push(card)
              end
              recipient.card = new_recipient_cards
              new_accounts.push(recipient)
            end
          end
          store_to_file(new_accounts, DATA_FILE, DIR_NAME)
          puts "Money #{amount.to_i}$ was put on #{recipient_card.number}. Balance: #{recipient_balance}. Tax: #{recipient_card.sender_tax(amount.to_i)}$\n"
          puts "Money #{amount.to_i}$ was put on #{sender_card.number}. Balance: #{sender_balance}. Tax: #{sender_card.sender_tax(amount.to_i)}$\n"
          break
        end
      else
        puts 'You entered wrong number!\n'
      end
    end
  end

  def destroy_account
    puts I18n.t('common.destroy_account')
    return unless gets.chomp == I18n.t('commands.positive')

    updated_accounts = accounts.delete_if { |acc| acc.login == @current_account.login }
    store_to_file(updated_accounts, DATA_FILE, DIR_NAME)
  end

  private

  def authorize
    loop do
      puts I18n.t('ask_phrases.login')
      login = gets.chomp
      puts I18n.t('ask_phrases.password')
      password = gets.chomp
      @current_account = accounts.find { |acc| acc.login == login && acc.password == password }
      break if @current_account

      puts I18n.t('errors.user_not_exists')
    end
  end

  def accounts
    load_from_file(DATA_FILE) || []
  end

  def save_database
    updated_accounts = accounts.collect { |acc| @current_account if acc.login == @current_account.login }
    store_to_file(updated_accounts, DATA_FILE, DIR_NAME)
  end

  def show_commands
    puts I18n.t('common.welcome', name: @current_account.name)
    puts I18n.t(:main_operations)
  end
end

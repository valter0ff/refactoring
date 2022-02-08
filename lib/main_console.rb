class MainConsole
  include DatabaseLoader
  DATA_FILE = File.expand_path('../db/accounts.yml', __dir__)
  DIR_NAME = 'db'.freeze

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
      puts "\nWelcome, #{@current_account.name}"
      puts 'If you want to:'
      puts '- show all cards - press SC'
      puts '- create card - press CC'
      puts '- destroy card - press DC'
      puts '- put money on card - press PM'
      puts '- withdraw money on card - press WM'
      puts '- send money to another card  - press SM'
      puts '- destroy account - press `DA`'
      puts '- exit from account - press `exit`'

      command = gets.chomp

      if command == 'SC' || command == 'CC' || command == 'DC' || command == 'PM' || command == 'WM' || command == 'SM' || command == 'DA' || command == 'exit'
        if command == 'SC'
          show_cards
        elsif command == 'CC'
          create_card
        elsif command == 'DC'
          destroy_card
        elsif command == 'PM'
          put_money
        elsif command == 'WM'
          withdraw_money
        elsif command == 'SM'
          send_money
        elsif command == 'DA'
          destroy_account
          exit
        elsif command == 'exit'
          exit
          break
        end
      else
        puts "Wrong command. Try again!\n"
      end
    end
  end

  def create_card
    loop do
      puts 'You could create one of 3 card types'
      puts '- Usual card. 2% tax on card INCOME. 20$ tax on SENDING money from this card. 5% tax on WITHDRAWING money. For creation this card - press `usual`'
      puts '- Capitalist card. 10$ tax on card INCOME. 10% tax on SENDING money from this card. 4$ tax on WITHDRAWING money. For creation this card - press `capitalist`'
      puts '- Virtual card. 1$ tax on card INCOME. 1$ tax on SENDING money from this card. 12% tax on WITHDRAWING money. For creation this card - press `virtual`'
      puts '- For exit - press `exit`'

      ct = gets.chomp
      if ct == 'usual' || ct == 'capitalist' || ct == 'virtual'
        if ct == 'usual'
          card = {
            type: 'usual',
            number: 16.times.map{rand(10)}.join,
            balance: 50.00
          }
        elsif ct == 'capitalist'
          card = {
            type: 'capitalist',
            number: 16.times.map{rand(10)}.join,
            balance: 100.00
          }
        elsif ct == 'virtual'
          card = {
            type: 'virtual',
            number: 16.times.map{rand(10)}.join,
            balance: 150.00
          }
        end
        @current_account.cards << card
        updated_accounts = accounts.collect { |acc| @current_account if acc.login == @current_account.login }
        store_to_file(updated_accounts, DATA_FILE, DIR_NAME)
        break
      else
        puts "Wrong card type. Try again!\n"
      end
    end
  end

  def destroy_card
    loop do
      if @current_account.cards.any?
        puts 'If you want to delete:'

        @current_account.cards.each_with_index do |c, i|
          puts "- #{c[:number]}, #{c[:type]}, press #{i + 1}"
        end
        puts "press `exit` to exit\n"
        answer = gets.chomp
        break if answer == 'exit'
        if answer&.to_i.to_i <= @current_account.cards.length && answer&.to_i.to_i > 0
          puts "Are you sure you want to delete #{@current_account.cards[answer&.to_i.to_i - 1][:number]}?[y/n]"
          a2 = gets.chomp
          if a2 == 'y'
            @current_account.cards.delete_at(answer&.to_i.to_i - 1)
            updated_accounts = accounts.collect { |acc| @current_account if acc.login == @current_account.login }
            store_to_file(updated_accounts, DATA_FILE, DIR_NAME)
            break
          else
            return
          end
        else
          puts "You entered wrong number!\n"
        end
      else
        puts "There is no active cards!\n"
        break
      end
    end
  end

  def show_cards
    if @current_account.cards.any?
      @current_account.cards.each do |c|
        puts "- #{c[:number]}, #{c[:type]}"
      end
    else
      puts "There is no active cards!\n"
    end
  end

  def withdraw_money
    puts 'Choose the card for withdrawing:'
    answer, a2, a3 = nil #answers for gets.chomp
    if @current_account.cards.any?
      @current_account.cards.each_with_index do |c, i|
        puts "- #{c[:number]}, #{c[:type]}, press #{i + 1}"
      end
      puts "press `exit` to exit\n"
      loop do
        answer = gets.chomp
        break if answer == 'exit'
        if answer&.to_i.to_i <= @current_account.cards.length && answer&.to_i.to_i > 0
          current_card = @current_account.cards[answer&.to_i.to_i - 1]
          loop do
            puts 'Input the amount of money you want to withdraw'
            amount = gets.chomp
            if amount&.to_i.to_i > 0
              money_left = current_card[:balance] - amount&.to_i.to_i - withdraw_tax(current_card[:type], current_card[:balance], current_card[:number], amount&.to_i.to_i)
              if money_left > 0
                current_card[:balance] = money_left
                @current_account.cards[answer&.to_i.to_i - 1] = current_card
                updated_accounts = accounts.collect { |acc| @current_account if acc.login == @current_account.login }
                store_to_file(updated_accounts, DATA_FILE, DIR_NAME)
                puts "Money #{amount&.to_i.to_i} withdrawed from #{current_card[:number]}$. Money left: #{current_card[:balance]}$. Tax: #{withdraw_tax(current_card[:type], current_card[:balance], current_card[:number], amount&.to_i.to_i)}$"
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
        puts "- #{c[:number]}, #{c[:type]}, press #{i + 1}"
      end
      puts "press `exit` to exit\n"
      loop do
        answer = gets.chomp
        break if answer == 'exit'
        if answer&.to_i.to_i <= @current_account.cards.length && answer&.to_i.to_i > 0
          current_card = @current_account.cards[answer&.to_i.to_i - 1]
          loop do
            puts 'Input the amount of money you want to put on your card'
            amount = gets.chomp
            if amount&.to_i.to_i > 0
              if put_tax(current_card[:type], current_card[:balance], current_card[:number], amount&.to_i.to_i) >= amount&.to_i.to_i
                puts 'Your tax is higher than input amount'
                return
              else
                new_money_amount = current_card[:balance] + amount&.to_i.to_i - put_tax(current_card[:type], current_card[:balance], current_card[:number], amount&.to_i.to_i)
                current_card[:balance] = new_money_amount
                @current_account.cards[answer&.to_i.to_i - 1] = current_card
                updated_accounts = accounts.collect { |acc| @current_account if acc.login == @current_account.login }
                store_to_file(updated_accounts, DATA_FILE, DIR_NAME)
                puts "Money #{amount&.to_i.to_i} was put on #{current_card[:number]}. Balance: #{current_card[:balance]}. Tax: #{put_tax(current_card[:type], current_card[:balance], current_card[:number], amount&.to_i.to_i)}"
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
        puts "- #{c[:number]}, #{c[:type]}, press #{i + 1}"
      end
      puts "press `exit` to exit\n"
      answer = gets.chomp
      exit if answer == 'exit'
      if answer&.to_i.to_i <= @current_account.cards.length && answer&.to_i.to_i > 0
        sender_card = @current_account.cards[answer&.to_i.to_i - 1]
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
      if all_cards.select { |card| card[:number] == a2 }.any?
        recipient_card = all_cards.detect { |card| card[:number] == a2 }
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
      a3 = gets.chomp
      if a3&.to_i.to_i > 0
        sender_balance = sender_card[:balance] - a3&.to_i.to_i - sender_tax(sender_card[:type], sender_card[:balance], sender_card[:number], a3&.to_i.to_i)
        recipient_balance = recipient_card[:balance] + a3&.to_i.to_i - put_tax(recipient_card[:type], recipient_card[:balance], recipient_card[:number], a3&.to_i.to_i)

        if sender_balance < 0
          puts "You don't have enough money on card for such operation"
        elsif put_tax(recipient_card[:type], recipient_card[:balance], recipient_card[:number], a3&.to_i.to_i) >= a3&.to_i.to_i
          puts 'There is no enough money on sender card'
        else
          sender_card[:balance] = sender_balance
          @current_account.cards[answer&.to_i.to_i - 1] = sender_card
          new_accounts = []
          accounts.each do |ac|
            if ac.login == @current_account.login
              new_accounts.push(@current_account)
            elsif ac.card.map { |card| card[:number] }.include? a2
              recipient = ac
              new_recipient_cards = []
              recipient.card.each do |card|
                if card[:number] == a2
                  card[:balance] = recipient_balance
                end
                new_recipient_cards.push(card)
              end
              recipient.card = new_recipient_cards
              new_accounts.push(recipient)
            end
          end
          store_to_file(new_accounts, DATA_FILE, DIR_NAME)
          puts "Money #{a3&.to_i.to_i}$ was put on #{sender_card[:number]}. Balance: #{recipient_balance}. Tax: #{put_tax(sender_card[:type], sender_card[:balance], sender_card[:number], a3&.to_i.to_i)}$\n"
          puts "Money #{a3&.to_i.to_i}$ was put on #{a2}. Balance: #{sender_balance}. Tax: #{sender_tax(sender_card[:type], sender_card[:balance], sender_card[:number], a3&.to_i.to_i)}$\n"
          break
        end
      else
        puts 'You entered wrong number!\n'
      end
    end
  end

  def destroy_account
    puts 'Are you sure you want to destroy account?[y/n]'
    a = gets.chomp
    if a == 'y'
      updated_accounts = accounts.delete_if { |acc| acc.login == @current_account.login }
      store_to_file(updated_accounts, DATA_FILE, DIR_NAME)
    end
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

  def withdraw_tax(type, balance, number, amount)
    if type == 'usual'
      return amount * 0.05
    elsif type == 'capitalist'
      return amount * 0.04
    elsif type == 'virtual'
      return amount * 0.88
    end
    0
  end

  def put_tax(type, balance, number, amount)
    if type == 'usual'
      return amount * 0.02
    elsif type == 'capitalist'
      return 10
    elsif type == 'virtual'
      return 1
    end
    0
  end

  def sender_tax(type, balance, number, amount)
    if type == 'usual'
      return 20
    elsif type == 'capitalist'
      return amount * 0.1
    elsif type == 'virtual'
      return 1
    end
    0
  end

  def accounts
    load_from_file(DATA_FILE) || []
  end
end

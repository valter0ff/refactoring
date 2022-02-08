OVERRIDABLE_FILENAME = 'spec/fixtures/account.yml'.freeze

COMMON_PHRASES = {
  create_first_account: "There is no active accounts, do you want to be the first?[y/n]\n",
  destroy_account: "Are you sure you want to destroy account?[y/n]\n",
  if_you_want_to_delete: 'If you want to delete:',
  choose_card: 'Choose the card for putting:',
  choose_card_withdrawing: 'Choose the card for withdrawing:',
  choose_card_for_sending: 'Choose the card for sending:',
  enter_recipient_card: 'Enter the recipient card:',
  input_amount: 'Input the amount of money you want to put on your card',
  withdraw_amount: 'Input the amount of money you want to withdraw',
  exit_command: 'press `exit` to exit'
}.freeze

HELLO_PHRASE = I18n.t(:hello).freeze

ASK_PHRASES = {
  name: 'Enter your name',
  login: 'Enter your login',
  password: 'Enter your password',
  age: 'Enter your age'
}.freeze

CREATE_CARD_PHRASE = I18n.t('cards.create_card').freeze

ACCOUNT_VALIDATION_PHRASES = {
  name: {
    first_letter: 'Your name must not be empty and starts with first upcase letter'
  },
  login: {
    present: 'Login must present',
    longer: 'Login must be longer then 4 symbols',
    shorter: 'Login must be shorter then 20 symbols',
    exists: 'Such account is already exists'
  },
  password: {
    present: 'Password must present',
    longer: 'Password must be longer then 6 symbols',
    shorter: 'Password must be shorter then 30 symbols'
  },
  age: {
    length: 'Your Age must be greeter then 23 and lower then 90'
  }
}.freeze

ERROR_PHRASES = {
  user_not_exists: 'There is no account with given credentials',
  wrong_command: 'Wrong command. Try again!',
  no_active_cards: "There is no active cards!\n",
  wrong_card_type: "Wrong card type. Try again!\n",
  wrong_number: "You entered wrong number!\n",
  correct_amount: 'You must input correct amount of money',
  tax_higher: 'Your tax is higher than input amount',
  incorrect_card_number: 'Please, input correct number of card',
  no_such_card: 'There is no card with number',
  not_enough_money: 'You dont have enough money on card for such operation',
  not_enough_money_on_sender: 'There is no enough money on sender card'
}.freeze

MAIN_OPERATIONS_TEXT = I18n.t(:main_operations).freeze

CARDS = {
  usual: {
    type: 'usual',
    balance: 50.00
  },
  capitalist: {
    type: 'capitalist',
    balance: 100.00
  },
  virtual: {
    type: 'virtual',
    balance: 150.00
  }
}.freeze

CARD_COMMANDS = {
  'SC' => :show_cards,
  'CC' => :create_card,
  'DC' => :destroy_card
}.freeze

MONEY_COMMANDS = {
  'PM' => PutMoney,
  'WM' => WithdrawMoney,
  'SM' => SendMoney
}.freeze

RSpec.describe MainConsole do
  let(:current_subject) { described_class.new }

  before { stub_const('MainConsole::DATA_FILE', OVERRIDABLE_FILENAME) }

  describe '#console' do
    context 'when correct method calling' do
      after do
        current_subject.console
      end

      it 'create account if input is create' do
        allow(current_subject).to receive_message_chain(:gets, :chomp) { 'create' }
        expect(current_subject).to receive(:create_account)
      end

      it 'load account if input is load' do
        allow(current_subject).to receive_message_chain(:gets, :chomp) { 'load' }
        expect(current_subject).to receive(:load_account)
      end

      it 'leave app if input is exit or some another word' do
        allow(current_subject).to receive_message_chain(:gets, :chomp) { 'another' }
        expect(current_subject).to receive(:exit)
      end
    end

    context 'with correct output' do
      it do
        allow(current_subject).to receive_message_chain(:gets, :chomp) { 'test' }
        allow(current_subject).to receive(:exit)
        expect(current_subject).to receive(:puts).with(HELLO_PHRASE)
        current_subject.console
      end
    end
  end

  describe '#create_account' do
    let(:success_name_input) { 'Denis' }
    let(:success_age_input) { '72' }
    let(:success_login_input) { 'Denis' }
    let(:success_password_input) { 'Denis1993' }
    let(:success_inputs) { [success_name_input, success_age_input, success_login_input, success_password_input] }
    let(:fake_account) { Account.new }

    context 'with success result' do
      before do
        allow(fake_account).to receive_message_chain(:gets, :chomp).and_return(*success_inputs)
        allow(current_subject).to receive(:main_menu)
        allow(Account).to receive(:new).and_return(fake_account)
        allow(current_subject).to receive(:accounts).and_return([])
      end

      after do
        File.delete(OVERRIDABLE_FILENAME) if File.exist?(OVERRIDABLE_FILENAME)
      end

      it 'with correct output' do
        allow(File).to receive(:open)
        ASK_PHRASES.each_value { |phrase| expect(fake_account).to receive(:puts).with(phrase) }
        ACCOUNT_VALIDATION_PHRASES.values.map(&:values).each do |phrase|
          expect(fake_account).not_to receive(:puts).with(phrase)
        end
        current_subject.create_account
      end

      it 'write to file Account instance' do
        current_subject.create_account
        expect(File.exist?(OVERRIDABLE_FILENAME)).to be true
        accounts = YAML.load_file(OVERRIDABLE_FILENAME)
        expect(accounts).to be_a Array
        expect(accounts.size).to be 1
        accounts.map { |account| expect(account).to be_a(Account) }
      end
    end

    context 'with errors' do
      before do
        all_inputs = current_inputs + success_inputs
        allow(File).to receive(:open)
        allow(fake_account).to receive_message_chain(:gets, :chomp).and_return(*all_inputs)
        allow(current_subject).to receive(:main_menu)
        allow(Account).to receive(:new).and_return(fake_account)
      end

      context 'with name errors' do
        context 'without small letter' do
          let(:error_input) { 'some_test_name' }
          let(:error) { ACCOUNT_VALIDATION_PHRASES[:name][:first_letter] }
          let(:current_inputs) { [error_input, success_age_input, success_login_input, success_password_input] }

          it { expect { current_subject.create_account }.to output(/#{error}/).to_stdout }
        end
      end

      context 'with login errors' do
        let(:current_inputs) { [success_name_input, success_age_input, error_input, success_password_input] }

        context 'when present' do
          let(:error_input) { '' }
          let(:error) { ACCOUNT_VALIDATION_PHRASES[:login][:present] }

          it { expect { current_subject.create_account }.to output(/#{error}/).to_stdout }
        end

        context 'when longer' do
          let(:error_input) { 'E' * 3 }
          let(:error) { ACCOUNT_VALIDATION_PHRASES[:login][:longer] }

          it { expect { current_subject.create_account }.to output(/#{error}/).to_stdout }
        end

        context 'when shorter' do
          let(:error_input) { 'E' * 21 }
          let(:error) { ACCOUNT_VALIDATION_PHRASES[:login][:shorter] }

          it { expect { current_subject.create_account }.to output(/#{error}/).to_stdout }
        end

        context 'when exists' do
          let(:error_input) { 'Denis1345' }
          let(:error) { ACCOUNT_VALIDATION_PHRASES[:login][:exists] }

          before do
            allow(Validations).to receive(:accounts) { [instance_double('Account', login: error_input)] }
          end

          it { expect { current_subject.create_account }.to output(/#{error}/).to_stdout }
        end
      end

      context 'with age errors' do
        let(:current_inputs) { [success_name_input, error_input, success_login_input, success_password_input] }
        let(:error) { ACCOUNT_VALIDATION_PHRASES[:age][:length] }

        context 'with length minimum' do
          let(:error_input) { '22' }

          it { expect { current_subject.create_account }.to output(/#{error}/).to_stdout }
        end

        context 'with length maximum' do
          let(:error_input) { '91' }

          it { expect { current_subject.create_account }.to output(/#{error}/).to_stdout }
        end
      end

      context 'with password errors' do
        let(:current_inputs) { [success_name_input, success_age_input, success_login_input, error_input] }

        context 'when absent' do
          let(:error_input) { '' }
          let(:error) { ACCOUNT_VALIDATION_PHRASES[:password][:present] }

          it { expect { current_subject.create_account }.to output(/#{error}/).to_stdout }
        end

        context 'when longer' do
          let(:error_input) { 'E' * 5 }
          let(:error) { ACCOUNT_VALIDATION_PHRASES[:password][:longer] }

          it { expect { current_subject.create_account }.to output(/#{error}/).to_stdout }
        end

        context 'when shorter' do
          let(:error_input) { 'E' * 31 }
          let(:error) { ACCOUNT_VALIDATION_PHRASES[:password][:shorter] }

          it { expect { current_subject.create_account }.to output(/#{error}/).to_stdout }
        end
      end
    end
  end

  describe '#load_account' do
    context 'without active accounts' do
      it do
        allow(current_subject).to receive(:accounts).and_return([])
        expect(current_subject).to receive(:create_first_account)
        current_subject.load_account
      end
    end

    context 'with active accounts' do
      let(:login) { 'Johnny' }
      let(:password) { 'johnny1' }

      before do
        allow(current_subject).to receive_message_chain(:gets, :chomp).and_return(*all_inputs)
        allow(current_subject).to receive(:accounts) {
                                    [instance_double('Account', login: login, password: password)]
                                  }
      end

      context 'with correct output' do
        let(:all_inputs) { [login, password] }

        it do
          expect(current_subject).to receive(:main_menu)
          [ASK_PHRASES[:login], ASK_PHRASES[:password]].each do |phrase|
            expect(current_subject).to receive(:puts).with(phrase)
          end
          current_subject.load_account
        end
      end

      context 'when account exists' do
        let(:all_inputs) { [login, password] }

        it do
          expect(current_subject).to receive(:main_menu)
          expect { current_subject.load_account }.not_to output(/#{ERROR_PHRASES[:user_not_exists]}/).to_stdout
        end
      end

      context 'when account doesn\t exists' do
        let(:all_inputs) { ['test', 'test', login, password] }

        it do
          expect(current_subject).to receive(:main_menu)
          expect { current_subject.load_account }.to output(/#{ERROR_PHRASES[:user_not_exists]}/).to_stdout
        end
      end
    end
  end

  describe '#create_first_account' do
    let(:cancel_input) { 'sdfsdfs' }
    let(:success_input) { 'y' }

    it 'with correct outout' do
      allow(current_subject).to receive_message_chain(:gets, :chomp)
      expect(current_subject).to receive(:console)
      expect { current_subject.create_first_account }.to output(COMMON_PHRASES[:create_first_account]).to_stdout
    end

    it 'calls create if user inputs is y' do
      allow(current_subject).to receive_message_chain(:gets, :chomp) { success_input }
      expect(current_subject).to receive(:create_account)
      current_subject.create_first_account
    end

    it 'calls console if user inputs is not y' do
      allow(current_subject).to receive_message_chain(:gets, :chomp) { cancel_input }
      expect(current_subject).to receive(:console)
      current_subject.create_first_account
    end
  end

  describe '#main_menu' do
    let(:name) { 'John' }
    let(:destroy_command) { 'DA' }

    before { allow(current_subject).to receive(:loop).and_yield }

    context 'with correct output' do
      it do
        allow(current_subject).to receive(:operations)
        allow(current_subject).to receive_message_chain(:gets, :chomp).and_return('SC')
        current_subject.instance_variable_set(:@current_account, instance_double('Account', name: name))
        expect(current_subject).to receive(:puts).with(/Welcome, #{name}/)
        expect(current_subject).to receive(:puts).with(MAIN_OPERATIONS_TEXT)
        current_subject.main_menu
      end
    end

    context 'when commands used' do
      let(:undefined_command) { 'undefined' }

      it 'calls specific methods on predefined commands' do
        allow(current_subject).to receive(:show_commands)
        current_subject.instance_variable_set(:@current_account, instance_double('Account', name: name))
        allow(current_subject).to receive(:save_database_after)
        MONEY_COMMANDS.each do |command, klass_name|
          allow(klass_name).to receive(:new).and_return(double.as_null_object)
          expect(klass_name).to receive(:new).with(any_args)
          allow(current_subject).to receive_message_chain(:gets, :chomp).and_return(command)
          current_subject.main_menu
        end
        CARD_COMMANDS.each_key do |command|
          expect(CardOperations).to receive(:call).with(any_args)
          allow(current_subject).to receive_message_chain(:gets, :chomp).and_return(command)
          current_subject.main_menu
        end
      end

      it 'calls destroy_account when destroy command' do
        allow(current_subject).to receive_message_chain(:gets, :chomp).and_return(destroy_command)
        allow(current_subject).to receive(:show_commands)
        allow(current_subject).to receive(:save_database_after)
        expect(current_subject).to receive(:destroy_account)
        current_subject.main_menu
      end

      it 'outputs incorrect message on undefined command' do
        current_subject.instance_variable_set(:@current_account, instance_double('Account', name: name))
        allow(current_subject).to receive_message_chain(:gets, :chomp).and_return(undefined_command)
        expect { current_subject.main_menu }.to output(/#{ERROR_PHRASES[:wrong_command]}/).to_stdout
      end
    end
  end

  describe '#destroy_account' do
    let(:cancel_input) { 'sdfsdfs' }
    let(:success_input) { 'y' }
    let(:correct_login) { 'test' }
    let(:fake_login) { 'test1' }
    let(:fake_login2) { 'test2' }
    let(:correct_account) { instance_double('Account', login: correct_login) }
    let(:fake_account) { instance_double('Account', login: fake_login) }
    let(:fake_account2) { instance_double('Account', login: fake_login2) }
    let(:accounts) { [correct_account, fake_account, fake_account2] }

    after do
      File.delete(OVERRIDABLE_FILENAME) if File.exist?(OVERRIDABLE_FILENAME)
    end

    it 'with correct output' do
      allow(current_subject).to receive_message_chain(:gets, :chomp)
      expect { current_subject.destroy_account }.to output(COMMON_PHRASES[:destroy_account]).to_stdout
    end

    context 'when deleting' do
      it 'deletes account if user inputs is y' do
        allow(current_subject).to receive_message_chain(:gets, :chomp) { success_input }
        allow(current_subject).to receive(:accounts) { accounts }
        current_subject.instance_variable_set(:@current_account, instance_double('Account', login: correct_login))

        current_subject.destroy_account

        expect(File.exist?(OVERRIDABLE_FILENAME)).to be true
        file_accounts = YAML.load_file(OVERRIDABLE_FILENAME)
        expect(file_accounts).to be_a Array
        expect(file_accounts.size).to be 2
      end

      it 'doesnt delete account' do
        allow(current_subject).to receive_message_chain(:gets, :chomp) { cancel_input }

        current_subject.destroy_account

        expect(File.exist?(OVERRIDABLE_FILENAME)).to be false
      end
    end
  end

  describe ::CardOperations do
    let(:current_subject) { described_class.new(account, command) }
    let(:account) { instance_double('Account', cards: cards) }
    let(:usual_card) { UsualCard.new }
    let(:capitalist_card) { CapitalistCard.new }
    let(:virtual_card) { VirtualCard.new }

    describe '#show_cards' do
      let(:cards) { [usual_card, capitalist_card, virtual_card] }
      let(:command) { 'SC' }

      it 'calls #new' do
        allow(described_class).to receive(:new).and_return(current_subject)
        expect(described_class).to receive(:new)
        described_class.call(account, command)
      end

      it 'display cards if there are any' do
        current_subject.instance_variable_set(:@account, instance_double('Account', cards: cards))
        cards.each { |card| expect(current_subject).to receive(:puts).with("- #{card.number}, #{card.type}") }
        current_subject.call
      end

      it 'outputs error if there are no active cards' do
        current_subject.instance_variable_set(:@account, instance_double('Account', cards: []))
        expect(current_subject).to receive(:puts).with(ERROR_PHRASES[:no_active_cards])
        current_subject.call
      end
    end

    describe '#create_card' do
      let(:cards) { [] }
      let(:command) { 'CC' }

      before { allow(current_subject).to receive(:loop).and_yield }

      context 'with correct output' do
        CARDS.each do |_card_type, card_info|
          it do
            allow(current_subject).to receive_message_chain(:gets, :chomp) { card_info[:type] }
            expect(current_subject).to receive(:puts).with(CREATE_CARD_PHRASE)
            current_subject.call
          end
        end
      end

      context 'when exit if first gets is exit' do
        it do
          allow(current_subject).to receive(:puts).with(CREATE_CARD_PHRASE)
          allow(current_subject).to receive_message_chain(:gets, :chomp) { 'exit' }
          expect(current_subject).to receive(:exit)
          current_subject.call
        end
      end

      context 'when correct card choose' do
        CARDS.each do |card_type, card_info|
          it "create card with #{card_type} type" do
            allow(current_subject).to receive(:puts).with(CREATE_CARD_PHRASE)
            allow(current_subject).to receive_message_chain(:gets, :chomp) { card_info[:type] }

            current_subject.call

            expect(current_subject.account.cards.first.type).to eq card_info[:type]
            expect(current_subject.account.cards.first.balance).to eq card_info[:balance]
            expect(current_subject.account.cards.first.number.length).to be 16
          end
        end
      end

      context 'when incorrect card choose' do
        it do
          allow(current_subject).to receive_message_chain(:gets, :chomp).and_return('test', 'usual')

          expect { current_subject.call }.to output(/#{ERROR_PHRASES[:wrong_card_type]}/).to_stdout
        end
      end
    end

    describe '#destroy_card' do
      let(:command) { 'DC' }

      context 'without cards' do
        let(:cards) { [] }

        it 'shows message about not active cards' do
          current_subject.instance_variable_set(:@current_account, instance_double('Account', cards: []))
          expect { current_subject.call }.to output(/#{ERROR_PHRASES[:no_active_cards]}/).to_stdout
        end
      end

      context 'with cards' do
        let(:cards) { [usual_card, capitalist_card, virtual_card] }

        context 'with correct output' do
          it do
            allow(current_subject).to receive_message_chain(:gets, :chomp) { 'exit' }
            expect { current_subject.call }.to output(/#{COMMON_PHRASES[:if_you_want_to_delete]}/).to_stdout
            cards.each_with_index do |card, i|
              message = /- #{card.number}, #{card.type}, press #{i + 1}/
              expect { current_subject.call }.to output(message).to_stdout
            end
            current_subject.call
          end
        end

        context 'when exit if first gets is exit' do
          it do
            allow(current_subject).to receive_message_chain(:gets, :chomp) { 'exit' }
            current_subject.call
          end
        end

        context 'with incorrect input of card number' do
          it do
            allow(current_subject).to receive_message_chain(:gets, :chomp).and_return(cards.length + 1, 'exit')
            expect { current_subject.call }.to output(/#{ERROR_PHRASES[:wrong_number]}/).to_stdout
          end

          it do
            allow(current_subject).to receive_message_chain(:gets, :chomp).and_return(-1, 'exit')
            expect { current_subject.call }.to output(/#{ERROR_PHRASES[:wrong_number]}/).to_stdout
          end
        end

        context 'with correct input of card number' do
          let(:accept_for_deleting) { 'y' }
          let(:reject_for_deleting) { 'asdf' }
          let(:deletable_card_number) { 1 }

          it 'accept deleting' do
            commands = [deletable_card_number, accept_for_deleting]
            allow(current_subject).to receive_message_chain(:gets, :chomp).and_return(*commands)

            expect { current_subject.call }.to change { account.cards.size }.by(-1)
            expect(current_subject.account.cards).not_to include(usual_card)
          end

          it 'decline deleting' do
            commands = [deletable_card_number, reject_for_deleting]
            allow(current_subject).to receive_message_chain(:gets, :chomp).and_return(*commands)

            expect { current_subject.call }.not_to change(account.cards, :size)
          end
        end
      end
    end
  end

  describe ::MoneyOperations do
    let(:account) { instance_double('Account', cards: fake_cards) }
    let(:subject_account) { current_subject.instance_variable_get(:@account) }
    let(:fake_cards) { [] }
    let(:usual_card) { UsualCard.new }
    let(:capitalist_card) { CapitalistCard.new }
    let(:virtual_card) { VirtualCard.new }

    describe PutMoney do
      let(:current_subject) { described_class.new(account) }

      context 'without cards' do
        it 'shows message about not active cards' do
          expect { current_subject.call }.to output(/#{ERROR_PHRASES[:no_active_cards]}/).to_stdout
        end
      end

      context 'with cards' do
        let(:fake_cards) { [capitalist_card, usual_card, virtual_card] }

        context 'with correct output' do
          it do
            allow(current_subject).to receive(:gets).and_return('exit')
            expect { current_subject.call }.to output(/#{COMMON_PHRASES[:choose_card]}/).to_stdout
            fake_cards.each_with_index do |card, i|
              message = /- #{card.number}, #{card.type}, press #{i + 1}/
              expect { current_subject.call }.to output(message).to_stdout
            end
            current_subject.call
          end
        end

        context 'when exit if first gets is exit' do
          it do
            allow(current_subject).to receive(:gets).and_return('exit')
            expect(current_subject.call).to be nil
          end
        end

        context 'with incorrect input of card number' do
          it do
            allow(current_subject).to receive(:gets).and_return((fake_cards.length + 1).to_s)
            expect { current_subject.call }.to output(/#{ERROR_PHRASES[:wrong_number]}/).to_stdout
          end

          it do
            allow(current_subject).to receive(:gets).and_return('-1')
            expect { current_subject.call }.to output(/#{ERROR_PHRASES[:wrong_number]}/).to_stdout
          end
        end

        context 'with correct input of card number' do
          let(:fake_cards) { [capitalist_card, usual_card, virtual_card] }
          let(:chosen_card_number) { 1 }
          let(:incorrect_money_amount) { -2 }
          let(:default_balance) { 50.0 }
          let(:correct_money_amount_lower_than_tax) { 5 }
          let(:amount_greater_than_tax) { 50 }

          before do
            allow(current_subject).to receive_message_chain(:gets, :chomp).and_return(*commands)
          end

          context 'with correct output' do
            let(:commands) { [chosen_card_number, incorrect_money_amount] }

            it do
              expect { current_subject.call }.to output(/#{COMMON_PHRASES[:input_amount]}/).to_stdout
            end
          end

          context 'with amount lower then 0' do
            let(:commands) { [chosen_card_number, incorrect_money_amount] }

            it do
              expect { current_subject.call }.to output(/#{ERROR_PHRASES[:correct_amount]}/).to_stdout
            end
          end

          context 'with amount greater then 0' do
            context 'with tax greater than amount' do
              let(:commands) { [chosen_card_number, correct_money_amount_lower_than_tax] }

              it do
                expect { current_subject.call }.to output(/#{ERROR_PHRASES[:tax_higher]}/).to_stdout
              end
            end

            context 'with tax lower than amount' do
              let(:commands) { [chosen_card_number, amount_greater_than_tax.to_s] }
              let(:chosen_card_number) { '2' }

              # rubocop:disable Layout/LineLength

              it do
                allow(current_subject).to receive(:gets).and_return(*commands)
                new_balance = usual_card.balance + amount_greater_than_tax - usual_card.put_tax(amount_greater_than_tax)
                expect { current_subject.call }.to output(
                  /Money #{amount_greater_than_tax} was put on #{usual_card.number}. Balance: #{new_balance}. Tax: #{usual_card.put_tax(amount_greater_than_tax)}/
                ).to_stdout
              end

              # rubocop:enable Layout/LineLength
            end
          end
        end
      end
    end

    describe WithdrawMoney do
      let(:current_subject) { described_class.new(account) }

      context 'without cards' do
        let(:fake_cards) { [] }

        it 'shows message about not active cards' do
          allow(account).to receive(:cards) { fake_cards }
          current_subject.instance_variable_set(:@current_account, account)
          expect { current_subject.call }.to output(/#{ERROR_PHRASES[:no_active_cards]}/).to_stdout
        end
      end

      context 'with cards' do
        let(:fake_cards) { [capitalist_card, usual_card, virtual_card] }

        context 'with correct output' do
          it do
            allow(account).to receive(:cards) { fake_cards }
            current_subject.instance_variable_set(:@current_account, account)
            allow(current_subject).to receive_message_chain(:gets, :chomp) { 'exit' }
            expect { current_subject.call }.to output(/#{COMMON_PHRASES[:choose_card_withdrawing]}/).to_stdout
            fake_cards.each_with_index do |card, i|
              message = /- #{card.number}, #{card.type}, press #{i + 1}/
              expect { current_subject.call }.to output(message).to_stdout
            end
            current_subject.call
          end
        end

        context 'when exit if first gets is exit' do
          it do
            allow(account).to receive(:cards) { fake_cards }
            current_subject.instance_variable_set(:@current_account, account)
            allow(current_subject).to receive_message_chain(:gets, :chomp) { 'exit' }
            current_subject.call
          end
        end

        context 'with incorrect input of card number' do
          before do
            allow(account).to receive(:cards) { fake_cards }
            current_subject.instance_variable_set(:@current_account, account)
          end

          it do
            allow(current_subject).to receive_message_chain(:gets, :chomp).and_return(fake_cards.length + 1, 'exit')
            expect { current_subject.call }.to output(/#{ERROR_PHRASES[:wrong_number]}/).to_stdout
          end

          it do
            allow(current_subject).to receive_message_chain(:gets, :chomp).and_return(-1, 'exit')
            expect { current_subject.call }.to output(/#{ERROR_PHRASES[:wrong_number]}/).to_stdout
          end
        end

        context 'with correct input of card number' do
          let(:fake_cards) { [capitalist_card, usual_card, virtual_card] }
          let(:chosen_card_number) { 1 }
          let(:incorrect_money_amount) { -2 }
          let(:default_balance) { 50.0 }
          let(:correct_money_amount_lower_than_tax) { 5 }
          let(:amount_greater_than_tax) { 50 }

          before do
            allow(current_subject).to receive_message_chain(:gets, :chomp).and_return(*commands)
          end

          context 'with correct output' do
            let(:commands) { [chosen_card_number, incorrect_money_amount] }

            it do
              expect { current_subject.call }.to output(/#{COMMON_PHRASES[:withdraw_amount]}/).to_stdout
            end
          end

          context 'with amount greater then 0' do
            context 'with low balance' do
              let(:amount_greater_than_balance) { '100' }
              let(:commands) { [chosen_card_number, amount_greater_than_balance] }

              it do
                expect { current_subject.call }.to output(/#{ERROR_PHRASES[:not_enough_money]}/).to_stdout
              end
            end

            context 'with amount lower balance' do
              let(:amount_lower_balance) { 20 }
              let(:commands) { [chosen_card_number, amount_lower_balance.to_s] }
              let(:chosen_card_number) { '2' }

              # rubocop:disable Layout/LineLength
              it do
                allow(current_subject).to receive(:gets).and_return(*commands)
                new_balance = usual_card.balance - (amount_lower_balance + usual_card.withdraw_tax(amount_lower_balance))
                expect { current_subject.call }.to output(
                  /Money #{amount_lower_balance} was withdrawed from #{usual_card.number}. Balance: #{new_balance}. Tax: #{usual_card.withdraw_tax(amount_lower_balance)}/
                ).to_stdout
              end

              # rubocop:enable Layout/LineLength
            end
          end
        end
      end
    end

    describe SendMoney do
      let(:current_subject) { described_class.new(account) }
      let(:account2) { instance_double('Account', cards: fake_cards2) }
      let(:subject_accounts) { current_subject.instance_variable_get(:@accounts) }
      let(:accounts) { [account, account2] }
      let(:fake_cards2) { [capitalist_card2, usual_card2, virtual_card2] }
      let(:usual_card2) { UsualCard.new }
      let(:capitalist_card2) { CapitalistCard.new }
      let(:virtual_card2) { VirtualCard.new }

      before do
        current_subject.instance_variable_set(:@accounts, accounts)
      end

      context 'without cards' do
        it 'shows message about not active cards' do
          expect { current_subject.call }.to output(/#{ERROR_PHRASES[:no_active_cards]}/).to_stdout
        end
      end

      context 'with cards' do
        let(:fake_cards) { [capitalist_card, usual_card, virtual_card] }

        context 'with correct output' do
          it do
            allow(current_subject).to receive(:gets).and_return('exit')
            expect { current_subject.call }.to output(/#{COMMON_PHRASES[:card_for_sending]}/).to_stdout
            fake_cards.each_with_index do |card, i|
              message = /- #{card.number}, #{card.type}, press #{i + 1}/
              expect { current_subject.call }.to output(message).to_stdout
            end
            current_subject.call
          end
        end

        context 'with correct input of card number' do
          let(:sender_card_number) { '1' }
          let(:incorrect_money_amount) { '-2' }
          let(:correct_money_amount_lower_than_tax) { '5' }
          let(:amount_greater_tax) { '50' }
          let(:recipient_card_number) { capitalist_card2.number.to_s }
          let(:incorrect_recipient_card_number) { '1111111111111111' }
          let(:short_recipient_card_number) { '11111' }

          before do
            allow(current_subject).to receive(:gets).and_return(*commands)
            allow(current_subject).to receive(:loop).and_yield
          end

          context 'with incorrect recipient card number' do
            let(:commands) { [sender_card_number, incorrect_recipient_card_number] }

            it do
              expect { current_subject.call }.to output(/#{COMMON_PHRASES[:enter_recipient_card]}/).to_stdout
            end

            it do
              expect { current_subject.call }.to output(
                /#{ERROR_PHRASES[:no_such_card]}/
              ).to_stdout
            end
          end

          context 'with to short recipient card number' do
            let(:commands) { [sender_card_number, short_recipient_card_number] }

            it do
              expect { current_subject.call }.to output(/#{ERROR_PHRASES[:incorrect_card_number]}/).to_stdout
            end
          end

          context 'with correct recipient card number' do
            let(:commands) { [sender_card_number, recipient_card_number, incorrect_money_amount] }

            it do
              expect { current_subject.call }.to output(/#{COMMON_PHRASES[:withdraw_amount]}/).to_stdout
            end
          end

          context 'with amount greater then 0' do
            context 'when low balance' do
              let(:amount_greater_than_balance) { '100' }
              let(:commands) { [sender_card_number, recipient_card_number, amount_greater_than_balance] }

              it do
                expect { current_subject.call }.to output(/#{ERROR_PHRASES[:not_enough_money]}/).to_stdout
              end
            end

            context 'when recipient card put_tax more than amount' do
              let(:amount_lower_than_put_tax) { '5' }
              let(:commands) { [sender_card_number, recipient_card_number, amount_lower_than_put_tax] }

              it do
                expect { current_subject.call }.to output(/#{ERROR_PHRASES[:not_enough_money_on_sender]}/).to_stdout
              end
            end

            context 'with correct amount' do
              let(:correct_amount) { 20 }
              let(:commands) { [sender_card_number, recipient_card_number, correct_amount.to_s] }
              let(:sender_card_number) { '2' }

              # rubocop:disable Layout/LineLength
              it do
                allow(current_subject).to receive(:gets).and_return(*commands)
                new_balance = capitalist_card2.balance + correct_amount - capitalist_card2.put_tax(correct_amount)
                expect { current_subject.call }.to output(
                  /Money #{correct_amount} was put on #{capitalist_card2.number}. Balance: #{new_balance}. Tax: #{capitalist_card2.put_tax(correct_amount)}/
                ).to_stdout
              end

              it do
                allow(current_subject).to receive(:gets).and_return(*commands)
                new_sender_balance = usual_card.balance - (correct_amount + usual_card.sender_tax(correct_amount))
                expect { current_subject.call }.to output(
                  /Money #{correct_amount} was withdrawed from #{usual_card.number}. Balance: #{new_sender_balance}. Tax: #{usual_card.sender_tax(correct_amount)}/
                ).to_stdout
              end

              # rubocop:enable Layout/LineLength
            end
          end
        end
      end
    end
  end
end

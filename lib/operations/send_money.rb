class SendMoney < MoneyOperations
  include DatabaseLoader

  CHOOSE_CARD = I18n.t('common.choose_card_for_sending').freeze
  INPUT_AMOUNT = I18n.t('common.withdraw_amount').freeze
  CARD_NUMBER_LENGTH = 16

  def initialize(account)
    @accounts = load_from_file(MainConsole::DATA_FILE) || []
    super(account)
  end

  def call
    cards_present_wrapper do
      sender_card = setup_card
      return unless sender_card

      recipient_card = set_recipient_card
      return unless recipient_card

      make_transaction(sender_card, recipient_card)
    end
  end

  private

  def set_recipient_card
    puts I18n.t('common.enter_recipient_card')
    answer = gets.chomp
    return puts I18n.t('errors.incorrect_card_number') if answer.size != CARD_NUMBER_LENGTH

    recipient_card = @accounts.flat_map(&:cards).find { |card| card.number == answer }
    return puts I18n.t('errors.no_such_card', card_number: answer) unless recipient_card

    recipient_card
  end

  def make_transaction(sender_card, recipient_card)
    loop do
      amount = gets_amount
      next unless amount
      next puts I18n.t('errors.not_enough_money') if low_balance?(sender_card, amount)
      next puts I18n.t('errors.not_enough_money_on_sender') if recipient_card.put_tax(amount) >= amount

      change_balance(recipient_card, sender_card, amount)
      complete_msg(recipient_card, sender_card, amount)
      break
    end
  end

  def low_balance?(sender_card, amount)
    sender_card.balance < (amount + sender_card.sender_tax(amount))
  end

  def change_balance(recipient_card, sender_card, amount)
    recipient_card.balance += (amount - recipient_card.put_tax(amount))
    sender_card.balance -= (amount + sender_card.sender_tax(amount))
  end

  def complete_msg(recipient_card, sender_card, amount)
    send_money_msg(recipient_card, amount)
    withdraw_money_msg(sender_card, amount)
  end

  def send_money_msg(recipient_card, amount)
    print I18n.t('money.put_on_card', amount: amount, card: recipient_card.number)
    print I18n.t('money.balance', balance: recipient_card.balance)
    puts I18n.t('money.tax', tax: recipient_card.put_tax(amount))
  end

  def withdraw_money_msg(sender_card, amount)
    print I18n.t('money.withdrawed', amount: amount, card: sender_card.number)
    print I18n.t('money.balance', balance: sender_card.balance)
    puts I18n.t('money.tax', tax: sender_card.sender_tax(amount))
  end
end

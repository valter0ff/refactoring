class MoneyOperations
  def self.call(...)
    new(...).call
  end

  def initialize(account)
    @account = account
  end

  def call
    cards_present_wrapper do
      card = setup_card
      return unless card

      make_transaction(card)
    end
  end

  private

  def cards_present_wrapper
    return puts I18n.t('errors.no_active_cards') if @account.cards.empty?

    yield
  end

  def setup_card
    card_list
    answer = check_exit
    return unless answer

    return unless choice_card_correct(answer)

    @account.cards[answer.to_i - 1]
  end

  def card_list
    choose_card_message
    @account.cards.each_with_index do |card, index|
      puts "- #{card.number}, #{card.type}, press #{index + 1}"
    end
  end

  def check_exit
    puts I18n.t('common.exit_command')
    answer = gets.chomp
    return if answer == I18n.t('commands.exit')

    answer
  end

  def choice_card_correct(answer)
    answer.to_i.between?(1, @account.cards.size) ? true : puts(I18n.t('errors.wrong_number'))
  end

  def make_transaction(card)
    amount = gets_amount
    return unless amount

    ability = check_ability_transaction(card, amount)
    return unless ability

    change_balance(card, amount)
    complete_msg(card, amount)
  end

  def gets_amount
    input_amount_message
    amount = gets.chomp.to_i
    return puts I18n.t('errors.correct_amount') unless amount.positive?

    amount
  end

  def choose_card_message
    puts self.class::CHOOSE_CARD
  end

  def check_ability_transaction(card, amount)
    raise NotImplementedError
  end

  def change_balance(card, amount)
    raise NotImplementedError
  end

  def input_amount_message
    puts self.class::INPUT_AMOUNT
  end

  def complete_msg(card, amount)
    raise NotImplementedError
  end
end

class CardOperations
  CARD_TYPES = {
    I18n.t('cards.types.usual') => UsualCard,
    I18n.t('cards.types.capitalist') => CapitalistCard,
    I18n.t('cards.types.virtual') => VirtualCard
  }.freeze
  COMMANDS = {
    I18n.t('commands.card.show_all') => :show_cards,
    I18n.t('commands.card.create') => :create_card,
    I18n.t('commands.card.destroy') => :destroy_card
  }.freeze

  def self.call(...)
    new(...).call
  end

  def initialize(account, command)
    @account = account
    @command = command
  end

  def call
    method(COMMANDS[@command]).call
  end

  def show_cards
    return puts I18n.t('errors.no_active_cards') if @account.cards.empty?

    @account.cards.each { |card| puts "- #{card.number}, #{card.type}" }
  end

  def create_card
    loop do
      puts I18n.t('cards.create_card')
      card_type = gets.chomp
      case card_type
      when I18n.t('commands.exit') then exit
      when *CARD_TYPES.keys then break @account.cards << CARD_TYPES[card_type].new
      else puts I18n.t('errors.wrong_card_type')
      end
    end
  end

  def destroy_card
    return puts I18n.t('errors.no_active_cards') if @account.cards.empty?

    loop do
      delete_card_list
      answer = gets.chomp
      return if answer == I18n.t('commands.exit')

      next puts I18n.t('errors.wrong_number') unless card_number_correct?(answer)

      break delete_card(answer.to_i)
    end
  end

  private

  def card_number_correct?(number)
    number.to_i.between?(1, @account.cards.size)
  end

  def delete_card_list
    puts I18n.t('common.if_you_want_to_delete')
    @account.cards.each_with_index do |card, index|
      puts "- #{card.number}, #{card.type}, press #{index + 1}"
    end
    puts I18n.t('common.exit_command')
  end

  def delete_card(num)
    puts I18n.t('common.sure_to_delete', card: @account.cards[num - 1].number)
    choice = gets.chomp
    return unless choice == I18n.t('commands.positive')

    @account.cards.delete_at(num - 1)
  end
end

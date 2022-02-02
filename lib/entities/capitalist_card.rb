class CapitalistCard < BaseCard
  attr_reader :number, :type
  attr_accessor :balance

  def initialize
    @number = generate_number
    @balance = 100.00
    @type = I18n.t('cards.types.capitalist')
    @put = { rate: 0, fixed: 10 }
    @withdraw = { rate: 0.04, fixed: 0 }
    @send = { rate: 0.1, fixed: 0 }
    super
  end
end

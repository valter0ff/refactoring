class UsualCard < BaseCard
  attr_reader :number, :type
  attr_accessor :balance

  def initialize
    @number = generate_number
    @balance = 50.00
    @type = I18n.t('cards.types.usual')
    @put = { rate: 0.02, fixed: 0 }
    @withdraw = { rate: 0.05, fixed: 0 }
    @send = { rate: 0, fixed: 20 }
    super
  end
end

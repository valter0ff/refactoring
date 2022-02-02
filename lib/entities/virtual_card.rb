class VirtualCard < BaseCard
  attr_reader :number, :type
  attr_accessor :balance

  def initialize
    @number = generate_number
    @balance = 150.00
    @type = I18n.t('cards.types.virtual')
    @put = { rate: 0, fixed: 1 }
    @withdraw = { rate: 0.88, fixed: 0 }
    @send = { rate: 0, fixed: 1 }
    super
  end
end

class BaseCard
  attr_reader :put, :withdraw, :send

  CARD_NUMBER_LENGTH = 16
  ALLOWED_NUMBERS = (0..9).freeze

  def generate_number
    Array.new(CARD_NUMBER_LENGTH) { rand(ALLOWED_NUMBERS) }.join
  end

  def put_tax(amount)
    (amount * put[:rate]) + put[:fixed]
  end

  def withdraw_tax(amount)
    (amount * withdraw[:rate]) + withdraw[:fixed]
  end

  def sender_tax(amount)
    (amount * send[:rate]) + send[:fixed]
  end
end

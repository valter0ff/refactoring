class BaseCard
  attr_reader :put, :withdraw, :send

  def generate_number
    Array.new(16) { rand(9) }.join
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

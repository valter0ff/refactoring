class Account
  ATTRIBUTES = %i[name age login password].freeze

  attr_reader :name, :age, :login, :password, :cards, :errors

  def initialize
    @cards = []
    @errors = []
  end

  def create
    loop do
      ATTRIBUTES.each(&method(:get_input))
      errors.compact!
      break if errors.empty?

      errors.map(&method(:puts))
      errors.clear
    end
    self
  end

  private

  def get_input(attribute_name)
    puts I18n.t("ask_phrases.#{attribute_name}")
    input = instance_variable_set("@#{attribute_name}", gets.chomp)
    errors << Validations.public_send("validate_#{attribute_name}", input)
  end
end

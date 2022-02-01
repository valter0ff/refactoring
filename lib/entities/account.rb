class Account
  include DatabaseLoader

  attr_reader :name, :age, :login, :password, :cards, :errors

  def initialize
    @cards = []
    @errors = []
  end

  def create
    loop do
      name_input
      age_input
      login_input
      password_input
      break if errors.compact.empty?

      errors.compact.map(&method(:puts))
      errors.clear
    end
    self
  end

  private

  def name_input
    puts I18n.t('ask_phrases.name')
    @name = gets.chomp
    errors << Validations.validate_name(@name)
  end

  def age_input
    puts I18n.t('ask_phrases.age')
    @age = gets.chomp.to_i
    errors << Validations.validate_age(@age)
  end

  def login_input
    puts I18n.t('ask_phrases.login')
    @login = gets.chomp
    errors << Validations.validate_login(@login, accounts)
  end

  def password_input
    puts I18n.t('ask_phrases.password')
    @password = gets.chomp
    errors << Validations.validate_password(@password)
  end

  def accounts
    load_from_file(MainConsole::DATA_FILE) || []
  end
end

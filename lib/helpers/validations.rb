class Validations
  extend DatabaseLoader

  LOGIN_MIN_LENGTH = 4
  LOGIN_MAX_LENGTH = 20
  PASS_MIN_LENGTH = 6
  PASS_MAX_LENGTH = 30
  AGE_MIN = 23
  AGE_MAX = 90

  class << self
    def validate_name(input)
      return I18n.t('validation.name.first_letter') if input.empty? || input.capitalize != input
    end

    def validate_age(input)
      return I18n.t('validation.age.length') unless input.to_i.between?(AGE_MIN, AGE_MAX)
    end

    def validate_login(input)
      return I18n.t('validation.login.present') if input.empty?
      return I18n.t('validation.login.longer') if input.length < LOGIN_MIN_LENGTH
      return I18n.t('validation.login.shorter') if input.length > LOGIN_MAX_LENGTH
      return I18n.t('validation.login.exists') if accounts.find { |acc| acc.login == input }
    end

    def validate_password(input)
      return I18n.t('validation.password.present') if input.empty?
      return I18n.t('validation.password.longer') if input.length < PASS_MIN_LENGTH
      return I18n.t('validation.password.shorter') if input.length > PASS_MAX_LENGTH
    end

    def accounts
      load_from_file(MainConsole::DATA_FILE) || []
    end
  end
end

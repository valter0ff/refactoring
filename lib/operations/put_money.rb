class PutMoney < MoneyOperations
  private

  def choose_card_message
    puts I18n.t('common.choose_card')
  end

  def check_ability_transaction(card, amount)
    card.put_tax(amount) >= amount ? puts(I18n.t('errors.tax_higher')) : true
  end

  def change_balance(card, amount)
    card.balance += (amount - card.put_tax(amount))
  end

  def input_amount_message
    puts I18n.t('common.input_amount')
  end

  def complete_msg(card, amount)
    print I18n.t('money.put_on_card', amount: amount, card: card.number)
    print I18n.t('money.balance', balance: card.balance)
    puts I18n.t('money.tax', tax: card.put_tax(amount))
  end
end

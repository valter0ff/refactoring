class WithdrawMoney < MoneyOperations
  private

  def choose_card_message
    puts I18n.t('common.choose_card_withdrawing')
  end

  def check_ability_transaction(card, amount)
    low_balance?(card, amount) ? puts(I18n.t('errors.not_enough_money')) : true
  end

  def low_balance?(card, amount)
    card.balance < (amount + card.withdraw_tax(amount))
  end

  def change_balance(card, amount)
    card.balance -= (amount + card.withdraw_tax(amount))
  end

  def input_amount_message
    puts I18n.t('common.withdraw_amount')
  end

  def complete_msg(card, amount)
    print I18n.t('money.withdrawed', amount: amount, card: card.number)
    print I18n.t('money.balance', balance: card.balance)
    puts I18n.t('money.tax', tax: card.withdraw_tax(amount))
  end
end

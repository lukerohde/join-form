class SetPendingAndCompleteOnSubscription < ActiveRecord::Migration
  def up
  	execute "Update subscriptions set pending = true where source ilike 'nuw-api%'"
  	execute "update subscriptions set pending = false, completed_at = updated_at where (pay_method in ('CC', 'AB') and (coalesce(partial_account_number, '') <> '' or (coalesce(partial_card_number, '') <> '' and coalesce(stripe_token, '') <> ''))) or (pay_method in ('ABR', 'PRD') and coalesce(signature_vector, '') <> '')"
  end

  def down
  end
end

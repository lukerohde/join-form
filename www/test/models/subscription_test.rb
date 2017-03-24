require 'test_helper'

class SubscriptionTest < ActiveSupport::TestCase
  test "step reported correctly, consequetive times" do
    s = subscriptions(:completed_subscription)
    assert s.step == :thanks
    # was failing the second time because of a problem with person authorization
    assert s.step == :thanks, "second assertion fails"
  end

  test "save without updating timestamps" do
    params = subscriptions(:completed_subscription).attributes.except("id", "updated_at", "created_at")
    s = Subscription.new(params)
    s.save_without_validation!
    s.reload
    assert !s.new_record?, "record should have saved"
    assert s.updated_at != nil, "new record should have saved with time stamps"

    u = s.updated_at
    s.frequency = "Q"
    s.pay_method = "-"
    s.save!
    assert s.updated_at != u, "timestamps should have changed"

    u = s.updated_at
    s.frequency = "W"
    s.save_without_validation!
    assert s.updated_at == u, "timestamps shouldn't have changed"
  end

  test "step 1 - contact details" do
    s = Subscription.new()
    s.person = Person.new()
    s.join_form = join_forms(:one)

    assert s.step == :contact_details
  end

  test "step 2 - address" do
    s = subscriptions(:contact_details_only_subscription)
    assert s.step == :address
  end

  test "step 3 - no custom columns - pay_method" do
    s = subscriptions(:contact_details_with_address_subscription)
    assert s.step == :pay_method
  end

  test "step 3 - custom columns - miscellaneous" do
    s = subscriptions(:contact_details_with_address_subscription)
    s.update(join_form: join_forms(:column_list))
    assert s.step == :miscellaneous
  end


  test "step 4 - pay method" do
    s = subscriptions(:contact_details_with_subscription_subscription)
    assert s.step == :pay_method
  end

  test "step 5 - thanks" do
    s = subscriptions(:completed_subscription)
    assert s.step == :thanks
  end

  test "step 1 - contact details validation fail" do
    s = Subscription.new()
    s.person = Person.new()
    s.join_form = join_forms(:one)

    assert s.save == false
    assert s.errors.messages == {
      :"person.email"=>["can't be blank"],
      :"person.union"=>["can't be blank"],
      :"person.first_name"=>["can't be blank"]
    }
    assert s.step == :contact_details
  end

  test "step 2 - address validation fail" do
    s = subscriptions(:contact_details_only_subscription)
    assert s.save == false
    assert s.errors.messages == {
     :base=>["You must complete your address"]
    }
    assert s.step == :address
  end

  test "step 3 - subscription validation fail" do
    s = subscriptions(:contact_details_with_address_subscription)
    s.update(join_form: join_forms(:column_list))
    assert s.save == false
    assert s.errors.messages == {
      :worksite=>["can't be blank"],
      :employer=>["can't be blank"]
    }, 'expecting worksite and employer validation messages only'

    assert s.step == :miscellaneous
  end

  test "step 4 - pay method validation fail" do
    s = subscriptions(:contact_details_with_subscription_subscription)
    assert s.save == false
    assert s.errors.messages == {
      :pay_method=>["must be specified"],
      :plan=>["can't be blank"],
      :frequency=>["can't be blank"]
    }

    assert s.step == :pay_method
  end

  test "step 4 - pay method validation fail - AB" do
    s = subscriptions(:contact_details_with_subscription_subscription)
    s.pay_method = "AB"
    assert s.save == false
    assert s.errors.messages == {
      :bsb=>["must be properly formatted BSB e.g. 123-123"],
      :account_number=>["must be properly formatted e.g. 123456"],
      :plan=>["can't be blank"],
      :frequency=>["can't be blank"]
    }

    assert s.step == :pay_method
  end

  test "step 4 - pay method validation fail - CC" do
    s = subscriptions(:contact_details_with_subscription_subscription)

    assert s.update(pay_method: "CC") == false

    assert s.errors.messages == {
      :card_number=>["couldn't be validated by our payment gateway.  Please try again."],
      :plan=>["can't be blank"],
      :frequency=>["can't be blank"]
    }

    assert s.step == :pay_method

  end

  test "step 1 - contact details validation pass" do
    s = Subscription.new()
    s.person = Person.new()
    s.person.union = supergroups(:owner)
    s.join_form = join_forms(:one)

    assert s.update(person_attributes: { email: 'asdf@asdf.com', first_name: "asdf" })
    assert s.step == :address
    s.reload
    assert s.step == :address

  end

  test "step 1 - contact details validation pass - address not required, custom columns on" do
    s = Subscription.new()
    s.person = Person.new()
    s.person.union = supergroups(:owner)
    s.join_form = join_forms(:address_off_column_list)

    #Subscription.any_instance.stubs(:address_required?).returns(false)
    assert s.update(person_attributes: { email: 'asdf@asdf.com', first_name: "asdf" })
    assert_equal :miscellaneous, s.step, "before save"
    s.reload
    assert_equal :miscellaneous, s.step, "after save"
  end

  test "step 1 - contact details validation pass - address not required" do
    s = Subscription.new()
    s.person = Person.new()
    s.person.union = supergroups(:owner)
    s.join_form = join_forms(:address_off)

    #Subscription.any_instance.stubs(:address_required?).returns(false)
    assert s.update(person_attributes: { email: 'asdf@asdf.com', first_name: "asdf" })
    assert_equal :pay_method, s.step, "before save"
    s.reload
    assert_equal :pay_method, s.step, "after save"
  end


  test "step 2 - address validation pass - custom columns off" do
    s = subscriptions(:contact_details_only_subscription)
    assert s.update(person_attributes: { id: s.person.id, address1: "adsf", suburb: "asdf", state: "asdf", postcode: "1123", union_id: supergroups(:owner).id })
    #binding.pry
    assert s.step == :pay_method
    s.reload
    assert s.step == :pay_method
  end

  test "step 2 - address validation pass - custom columns on" do
    s = subscriptions(:contact_details_only_subscription)
    s.update(join_form: join_forms(:column_list))

    assert s.update(person_attributes: { id: s.person.id, address1: "adsf", suburb: "asdf", state: "asdf", postcode: "1123", union_id: supergroups(:owner).id })
    assert s.step == :miscellaneous
    s.reload
    assert s.step == :miscellaneous
  end

  test "step 3 - miscellaneous validation pass" do
    s = subscriptions(:contact_details_with_address_subscription)
    s.update(join_form: join_forms(:column_list))

    assert s.update(data: {employer: "asdf", worksite: "asdf"})
    assert s.step == :pay_method
    s.reload
    assert s.step == :pay_method
  end

  test "step 4 - pay_method validation australian bank pass" do
    s = subscriptions(:contact_details_with_subscription_subscription)
    result = s.join_form.union.update( old_passphrase: '1234567890123456789012345678901234567890', passphrase: '1234567890123456789012345678901234567890', passphrase_confirmation: '1234567890123456789012345678901234567890')

    assert s.update!(pay_method: "AB", plan: "asdf", frequency: "F", bsb: "123-123", account_number: "123456", partial_account_number: "123xxx")

    assert s.step == :thanks
    s.reload
    assert s.step == :thanks
  end

  test "step 4 - pay_method validation credit card pass" do
    s = subscriptions(:contact_details_with_subscription_subscription)
    result = s.join_form.union.update( old_passphrase: '1234567890123456789012345678901234567890', passphrase: '1234567890123456789012345678901234567890', passphrase_confirmation: '1234567890123456789012345678901234567890')

    Stripe::Customer.expects(:create).returns (OpenStruct.new(id: 123))
    Stripe::Charge.expects(:create).returns (true)

    s.person.union = s.join_form.union
    assert s.update_with_payment({pay_method: "CC", plan: "asdf", frequency: "F", stripe_token: "asdf", partial_card_number: "xxxxxxxxxxxxx123"}, s.join_form.union)

    assert s.step == :thanks
    s.reload
    assert s.step == :thanks
  end


end

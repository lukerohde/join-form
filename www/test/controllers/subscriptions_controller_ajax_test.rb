require 'test_helper'
#require 'database_cleaner'
#DatabaseCleaner.strategy = :transaction


class SubscriptionsControllerAjaxTest < Capybara::Rails::JSTestCase #ActionDispatch::IntegrationTest

  def setup
    super

    WickedPdf.any_instance.stubs(:pdf_from_url).returns("PDF MOCK")
    Date.stubs(:today).returns(Date.parse('2017-01-01'))
    SubscriptionsController.any_instance.expects(:nuw_end_point_person_put).returns(nil)
    #SubscriptionsController.any_instance.expects(:nuw_end_point_person_get).returns(nil)

  end

  def teardown
    Date.unstub(:today)
    WickedPdf.any_instance.unstub(:pdf_from_url)
    SubscriptionsController.any_instance.unstub(:nuw_end_point_person_put)
    #SubscriptionsController.any_instance.unstub(:nuw_end_point_person_get)

    super
  end

  test "payroll deduction" do

    @join_form = join_forms(:js_testing2)
    @union = @join_form.union

    @subscription = subscriptions(:column_list)
    visit edit_join_path(:en, @union, @join_form, @subscription.token)

    select_wait "Deduct my union dues from my pay", from: "Payment Method"
    page.execute_script('sig.regenerate([{"lx":10,"ly":10,"mx":60,"my":60},{"lx":60,"ly":10,"mx":10,"my":60}])')

    click_button "Join Now"
    page.must_have_content "Online Membership Card"

  end

  test "direct debit release" do
    @join_form = join_forms(:js_testing2)
    @union = @join_form.union

    @subscription = subscriptions(:column_list)

    visit edit_join_path(:en, @union, @join_form, @subscription.token)

    select_wait "Get my bank account from my employer", from: "Payment Method"

    select_wait "Monthly - $29.99", from: "Payment Frequency"

    dd = find('#subscription_deduction_date').all('option')[2].text # first and second option are defaults for cc and dd respectively, pick thrid
    select_wait dd, from: "Deduction Date"

    page.execute_script('sig.regenerate([{"lx":10,"ly":10,"mx":60,"my":60},{"lx":60,"ly":10,"mx":10,"my":60}])')

    click_button "Join Now"
    page.must_have_content "Online Membership Card"

  end

  test "credit card and ajax changes to deduction date" do
    @join_form = join_forms(:js_testing1)
    @union = @join_form.union

    #Capybara.current_driver = :selenium

    @subscription = subscriptions(:column_list)
    visit edit_join_path(:en, @union, @join_form, @subscription.token)

    select_wait "Australian bank account", from: "Payment Method"
    select_wait "Monthly - $29.99", from: "Payment Frequency"
    dd = find('#subscription_deduction_date').all('option')[2].text # first and second option are defaults for cc and dd respectively, pick thrid
    select_wait dd, from: "Deduction Date"

    # check that the description of charge is updated
    assert has_content? "reoccurring fee of $29.99"

    select_wait "Credit card", from: "Payment Method"
    # check if selected values are preserved when switching pay method
    assert has_select?("Payment Frequency", selected: "Monthly - $29.99"), "Frequency not persisted"
    page.save_screenshot('step2.jpg', full:true)
    assert has_select?("Deduction Date", selected: dd), "Deduction Date not persisted"

    # check if invalid ABR date is reset to CC default when changing payment type
    select_wait "Australian bank account", from: "Payment Method"
    dd = find('#subscription_deduction_date').all('option')[-1].text # select last option for dd which isn't available for cc
    select_wait dd, from: "Deduction Date"

    select_wait "Credit card", from: "Payment Method"
    dd = find('#subscription_deduction_date').all('option')[0].text
    assert has_select?("Deduction Date", selected: dd), "Invalid DD date should have reset to default first option"

    # select a date not used, prior to changing to quarterly
    dd = find('#subscription_deduction_date').all('option')[3].text
    select_wait dd, from: "Deduction Date"

    # Ensure deduction date is not shown for quarterly
    select_wait "Quarterly - $39.99", from: "Payment Frequency"
    assert has_no_select?("Deduction Date"), "Deduction Date shouldn't be present for quarterly"

    select_wait "Monthly - $29.99", from: "Payment Frequency"
    #dd = find('#subscription_deduction_date').all('option')[0].text
    assert has_select?("Deduction Date", selected: dd), "deduction date should have persisted to default after choosing quarterly, then monthly"

    # post credit card
    fill_in "Credit Card Number", with: "4242424242424242"
    select_wait "12", from: "subscription_expiry_month"
    select_wait Date.today.year + 1, from: "subscription_expiry_year"
    fill_in "CCV", with: "123"

    click_button "Join Now"
    page.must_have_content "Online Membership Card"

  end


  test "direct debit w/deduction date" do
    @join_form = join_forms(:js_testing1)
    @union = @join_form.union

    @subscription = subscriptions(:column_list)
    visit edit_join_path(:en, @union, @join_form, @subscription.token)

    select_wait "Australian bank account", from: "Payment Method"

    select_wait "Monthly - $29.99", from: "Payment Frequency"
    dd = find('#subscription_deduction_date').all('option')[2].text # first and second option are defaults for cc and dd respectively, pick thrid
    select_wait dd, from: "Deduction Date"

    fill_in "BSB", with: "123-123"
    fill_in "Account Number", with: "4242424242424242"

    click_button "Join Now"
    page.must_have_content "Online Membership Card"
  end


  test "direct debit w/no deduction date" do

    @join_form = join_forms(:js_testing3)
    @union = @join_form.union

    @subscription = subscriptions(:column_list)
    visit edit_join_path(:en, @union, @join_form, @subscription.token)

    select_wait "Australian bank account", from: "Payment Method"

    select_wait "Weekly - $9.99", from: "Payment Frequency"
    assert has_no_select?("Deduction Date"), "Deduction Date shouldn't be present for quarterly"

    fill_in "BSB", with: "123-123"
    fill_in "Account Number", with: "4242424242424242"

    click_button "Join Now"
    page.must_have_content "Online Membership Card"

    @subscription.reload
    assert @subscription.deduction_date.nil?, "deduction date should not be set"
  end

  test "existing cc pay_method, when AB and CC are valid, has next_payment_date" do

    @join_form = join_forms(:js_testing1)
    @union = @join_form.union

    @subscription = subscriptions(:completed_cc_subscription_no_api_call)
    np  = @subscription.next_payment_date

    visit edit_join_path(:en, @union, @join_form, @subscription.token)

    assert has_select?("Payment Method", selected: "Use the credit card I have file"), "should default to existing payment method"
    assert has_no_select?("Deduction Date"), "The fixture is quarterly so deduction date shouldn't be shown."
    page.must_have_content "Your next debit is currently scheduled for"

    click_button "Renew Now"
    page.must_have_content "Online Membership Card"

    @subscription.reload
    assert @subscription.deduction_date_required? == false, "when there was no deduction date, it shouldn't be required after posting,  this prevents the next payment date getting written over the api"
  end

  test "existing dd pay_method, when AB and CC aren't valid, has no next_payment_date" do
    #Capybara.current_driver = :selenium

    @join_form = join_forms(:js_testing2)
    @union = @join_form.union

    @subscription = subscriptions(:completed_dd_subscription_no_api_call)
    np  = @subscription.next_payment_date

    visit edit_join_path(:en, @union, @join_form, @subscription.token)

    assert has_select?("Payment Method", selected: "Get my bank account from my employer"), "should not default to existing payment method"

    #TODO fix bug switching to existing bank account, partial accounts fields not hidden, so aren't posted back, and pay method isn't posted back, the option can't render
    select_wait "Use the bank account I have on file", from: "Payment Method"
    assert has_no_select?("Deduction Date"), "The fixture is quarterly so deduction date shouldn't be shown."
    select_wait "Weekly - $9.99", from: "Payment Frequency"
    page.wont_have_content "Your next debit is currently scheduled for" # fixture has no advanced next payment date
    dd = find('#subscription_deduction_date').all('option')[2].text # first and second option are defaults for cc and dd respectively, pick thrid
    select_wait dd, from: "Deduction Date"

    page.execute_script('sig.regenerate([{"lx":10,"ly":10,"mx":60,"my":60},{"lx":60,"ly":10,"mx":10,"my":60}])')

    click_button "Renew Now"
    page.must_have_content "Online Membership Card"

    @subscription.reload
    assert @subscription.deduction_date_required? == true, "when there was a deduction date, it should be required after posting,  this prevents the next payment date getting written over the api"
    assert @subscription.deduction_date == Date.parse(dd), "deducction date wasn't set"

    assert @subscription.signature_image.url.present?, "expected signature image" # TODO got to get rid of the double save thing.
  end


end

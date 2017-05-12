require 'test_helper'
#require 'database_cleaner'
#DatabaseCleaner.strategy = :transaction


class SubscriptionsControllerAjaxTest < Capybara::Rails::JSTestCase #ActionDispatch::IntegrationTest

  def setup
    super

    WickedPdf.any_instance.stubs(:pdf_from_url).returns("PDF MOCK")
    Date.stubs(:today).returns(Date.parse('2017-01-01'))
  end

  def teardown
    Date.unstub(:today)
    WickedPdf.any_instance.unstub(:pdf_from_url)

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


  test "direct debit" do
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



end

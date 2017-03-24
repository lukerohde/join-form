require 'test_helper'

class DeductionDateOptions < ActiveSupport::TestCase
  def setup
    @subscription = subscriptions(:contact_details_with_subscription_subscription)
    Date.stubs(:today).returns(Date.new(2017,1,1))
  end

  def date_range(start_date,end_date)
    Array(Date.parse(start_date)..Date.parse(end_date)).reject(&:weekend?)
  end

  def deduction_dates_match(freq, from, start_date, end_date)
    Date.expects(:today).returns(Date.parse(from))
    @subscription.frequency = freq
    @subscription.available_deduction_dates == date_range(start_date, end_date)
  end

  def assert_deduction_dates_match(freq, from, start_date, end_date)
    Date.expects(:today).returns(Date.parse(from))
    @subscription.frequency = freq

    assert @subscription.available_deduction_dates == date_range(start_date, end_date),
      "Failed for '#{@subscription.pay_method}' '#{freq}' from '#{from}', got #{@subscription.available_deduction_dates}"
  end

  def assert_no_deduction_dates(freq)
    @subscription.frequency = freq
    assert @subscription.available_deduction_dates == [], "Didn't expect '#{@subscription.pay_method}' '#{freq}' to have deduction dates, got #{@subscription.available_deduction_dates}"
  end

  test "deduction date for australian bank without deferral" do
    @subscription.pay_method = 'AB'
    assert_deduction_dates_match 'W', '2017-01-01', '2017-01-02', '2017-01-08'
    assert_deduction_dates_match 'F', '2017-01-01', '2017-01-02', '2017-01-15'
    assert_deduction_dates_match 'M', '2017-01-01', '2017-01-02', '2017-02-01'
    assert_no_deduction_dates 'Q'
    assert_no_deduction_dates 'Y'
  end

  test "deduction date for australian bank release without deferral" do
    @subscription.pay_method = 'ABR'
    assert_deduction_dates_match 'W', '2017-01-01', '2017-01-02', '2017-01-08'
    assert_deduction_dates_match 'F', '2017-01-01', '2017-01-02', '2017-01-15'
    assert_deduction_dates_match 'M', '2017-01-01', '2017-01-02', '2017-02-01'
    assert_no_deduction_dates 'Q'
    assert_no_deduction_dates 'Y'
  end

  test "deduction date for credit card without deferral" do
    @subscription.pay_method = 'CC'
    assert_deduction_dates_match 'W', '2017-01-01', '2017-01-01', '2017-01-07'
    assert_deduction_dates_match 'F', '2017-01-01', '2017-01-01', '2017-01-14'
    assert_deduction_dates_match 'M', '2017-01-01', '2017-01-01', '2017-01-31'
    assert_deduction_dates_match 'M', '2017-01-31', '2017-01-31', '2017-02-28'
    assert_deduction_dates_match 'M', '2017-02-28', '2017-02-28', '2017-03-27'
    assert_deduction_dates_match 'M', '2017-03-01', '2017-03-01', '2017-03-31'
    assert_no_deduction_dates 'Q'
    assert_no_deduction_dates 'Y'
  end

  test "deduction date for payroll deduction without deferral" do
    @subscription.pay_method = 'PRD'
    assert_no_deduction_dates 'W'
    assert_no_deduction_dates 'F'
    assert_no_deduction_dates 'M'
    assert_no_deduction_dates 'Q'
    assert_no_deduction_dates 'Y'
  end

  test "deduction date options" do
    @presenter = SubscriptionPresenter.new(@subscription)
    @subscription.pay_method = "CC"
    @subscription.frequency = "W"
    Date.stubs(:today).returns(Date.new(2017,1,1))
    assert_equal @presenter.deduction_date_options.count, 5
    assert_equal @presenter.deduction_date_options[0], ["Monday,  2 January 2017", '2017-01-02']
  end

  def validate_deduction_date(pm, freq, from, dd, explanation)
    @subscription.pay_method = pm
    @subscription.frequency = freq
    Date.stubs(:today).returns(Date.parse(from))
    @subscription.deduction_date = dd
    @subscription.valid?
    @subscription.errors.messages[:deduction_date]
  end

  def assert_invalid_deduction_date(pm, freq, from, dd, explanation)
    error = validate_deduction_date(pm, freq, from, dd, explanation)
    assert error.present?, "No error thrown for deduction date '#{dd}' for '#{pm}' '#{freq}' on '#{from}': #{explanation}"
  end

  def assert_valid_deduction_date(pm, freq, from, dd, explanation)
    error = validate_deduction_date(pm, freq, from, dd, explanation)
    assert error.blank?, "Error thrown for deduction date '#{dd}' for '#{pm}' '#{freq}' on '#{from}': #{explanation} - #{error}"
  end

  test "invalid direct debit deduction date, without deferral" do
    assert_invalid_deduction_date "AB", "W", '2017-01-03', '2017-01-02', "can't have a deduction date in the past"
    assert_invalid_deduction_date "AB", "W", '2017-01-02', '2017-01-02', "can't have a same day deduction"
    assert_invalid_deduction_date "AB", "W", '2016-12-31', '2017-01-01', "can't have a weekend deduction"
    assert_invalid_deduction_date "AB", "W", '2017-01-02', '2017-01-10', "can't have a deduction beyond one week"

    assert_invalid_deduction_date "AB", "F", '2017-01-02', '2017-01-02', "can't have a same day deduction"
    assert_invalid_deduction_date "AB", "F", '2017-01-02', '2017-01-17', "can't have a deduction beyond two weeks"

    assert_invalid_deduction_date "AB", "M", '2017-01-02', '2017-01-2', "can't have a same day deduction date"
    assert_invalid_deduction_date "AB", "M", '2017-01-02', '2017-02-3', "can't have a beyond one month"

    # Testing current behaviour which may change - i.e. no deduction date is valid
    assert_invalid_deduction_date "AB", "Q", '2017-01-02', '2017-01-3', "no deduction date is valid"
    assert_invalid_deduction_date "AB", "H", '2017-01-02', '2017-01-3', "no deduction date is valid"
    assert_invalid_deduction_date "AB", "Y", '2017-01-02', '2017-01-3', "no deduction date is valid"
  end

  test "valid direct debit deduction date, without deferral" do
    assert_valid_deduction_date "AB", "W", '2017-01-02', '2017-01-03', "can have a same day deduction"
    assert_valid_deduction_date "AB", "W", '2017-01-02', '2017-01-09', "can have a deduction date at the end of the week"
    assert_valid_deduction_date "AB", "F", '2017-01-02', '2017-01-16', "can have a deduction date at the end of next week"
    assert_valid_deduction_date "AB", "M", '2017-01-02', '2017-02-02', "can have a deduction date at the start of next month"
  end

  test "invalid direct debit release deduction date, without deferral" do
    assert_invalid_deduction_date "ABR", "W", '2017-01-03', '2017-01-02', "can't have a deduction date in the past"
    assert_invalid_deduction_date "ABR", "W", '2017-01-02', '2017-01-02', "can't have a same day deduction"
    assert_invalid_deduction_date "ABR", "W", '2016-12-31', '2017-01-01', "can't have a weekend deduction"
    assert_invalid_deduction_date "ABR", "W", '2017-01-02', '2017-01-10', "can't have a deduction beyond one week"

    assert_invalid_deduction_date "ABR", "F", '2017-01-02', '2017-01-02', "can't have a same day deduction"
    assert_invalid_deduction_date "ABR", "F", '2017-01-02', '2017-01-17', "can't have a deduction beyond two weeks"

    assert_invalid_deduction_date "ABR", "M", '2017-01-02', '2017-01-2', "can't have a same day deduction date"
    assert_invalid_deduction_date "ABR", "M", '2017-01-02', '2017-02-3', "can't have a beyond one month"

    # Testing current behaviour which may change - i.e. no deduction date is valid
    assert_invalid_deduction_date "ABR", "Q", '2017-01-02', '2017-01-3', "no deduction date is valid"
    assert_invalid_deduction_date "ABR", "H", '2017-01-02', '2017-01-3', "no deduction date is valid"
    assert_invalid_deduction_date "ABR", "Y", '2017-01-02', '2017-01-3', "no deduction date is valid"
  end

  test "valid direct debit release deduction date, without deferral" do
    assert_valid_deduction_date "ABR", "W", '2017-01-02', '2017-01-03', "can have a same day deduction"
    assert_valid_deduction_date "ABR", "W", '2017-01-02', '2017-01-09', "can have a deduction date at the end of the week"
    assert_valid_deduction_date "ABR", "F", '2017-01-02', '2017-01-16', "can have a deduction date at the end of next week"
    assert_valid_deduction_date "ABR", "M", '2017-01-02', '2017-02-02', "can have a deduction date at the start of next month"
  end

  test "invalid credit card deduction date, without deferral" do
    assert_invalid_deduction_date "CC", "W", '2017-01-03', '2017-01-02', "can't have a deduction date in the past"
    assert_invalid_deduction_date "CC", "W", '2017-01-01', '2017-01-01', "can't have a weekend deduction"
    assert_invalid_deduction_date "CC", "W", '2017-01-02', '2017-01-9', "can't have a deduction beyond one week"

    assert_invalid_deduction_date "CC", "F", '2017-01-02', '2017-01-16', "can't have a deduction beyond two weeks"

    assert_invalid_deduction_date "CC", "M", '2017-01-02', '2017-02-2', "can't have a beyond one month"

    # Testing current behaviour which may change - i.e. no deduction date is valid
    assert_invalid_deduction_date "CC", "Q", '2017-01-02', '2017-01-3', "no deduction date is valid"
    assert_invalid_deduction_date "CC", "H", '2017-01-02', '2017-01-3', "no deduction date is valid"
    assert_invalid_deduction_date "CC", "Y", '2017-01-02', '2017-01-3', "no deduction date is valid"
  end

  test "valid credit card deduction date, without deferral" do
    assert_valid_deduction_date "CC", "W", '2017-01-02', '2017-01-02', "can have a same day deduction"
    assert_valid_deduction_date "CC", "W", '2017-01-02', '2017-01-06', "can have a deduction date at the end of the week"
    assert_valid_deduction_date "CC", "F", '2017-01-02', '2017-01-13', "can have a deduction date at the end of next week"
    assert_valid_deduction_date "CC", "M", '2017-01-02', '2017-02-01', "can have a deduction date at the start of next month"
  end

  test "invalid PRD deduction date, without deferral" do
    # Testing current behaviour which may change - i.e. no deduction date is valid
    assert_invalid_deduction_date "PRD", "W", '2017-01-02', '2017-01-3', "no deduction date is valid"
    assert_invalid_deduction_date "PRD", "F", '2017-01-02', '2017-01-3', "no deduction date is valid"
    assert_invalid_deduction_date "PRD", "M", '2017-01-02', '2017-01-3', "no deduction date is valid"
    assert_invalid_deduction_date "PRD", "Q", '2017-01-02', '2017-01-3', "no deduction date is valid"
    assert_invalid_deduction_date "PRD", "H", '2017-01-02', '2017-01-3', "no deduction date is valid"
    assert_invalid_deduction_date "PRD", "Y", '2017-01-02', '2017-01-3', "no deduction date is valid"
  end
end

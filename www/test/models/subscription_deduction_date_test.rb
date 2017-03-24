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
    @subscription.pay_method = "CC"
    @subscription.frequency = "W"
    Date.stubs(:today).returns(Date.new(2017,1,1))
    assert_equal @subscription.deduction_date_options.count, 5
    assert_equal @subscription.deduction_date_options[0], ["Monday,  2 January 2017", '2017-01-02']
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
    assert error.blank?, "Error thrown for deduction date '#{dd}' for '#{pm}' '#{freq}' on '#{from}': #{explanation}"
  end

  test "invalid direct debit deduction date, without deferral" do
    assert_invalid_deduction_date "AB", "W", '2017-01-03', '2017-01-02', "can't have a deduction date in the past"
    assert_invalid_deduction_date "AB", "W", '2017-01-02', '2017-01-02', "can't have a same day deduction"
    assert_invalid_deduction_date "AB", "W", '2017-01-01', '2017-01-01', "can't have a weekend deduction"
    assert_invalid_deduction_date "AB", "W", '2017-01-02', '2017-01-10', "can't have a deduction beyond one week"
    assert_valid_deduction_date "AB", "W", '2017-01-02', '2017-01-3', "can't have a deduction beyond one week"
    # TODO check more frequencies, and deferral
  end

  test "invalid credit card deduction date, without deferral" do
    assert_invalid_deduction_date "CC", "W", '2017-01-03', '2017-01-02', "can't have a deduction date in the past"
    assert_valid_deduction_date "CC", "W", '2017-01-02', '2017-01-02', "can have a same day deduction"
    assert_invalid_deduction_date "CC", "W", '2017-01-01', '2017-01-01', "can't have a weekend deduction"
    assert_invalid_deduction_date "CC", "W", '2017-01-02', '2017-01-10', "can't have a deduction beyond one week"
    # TODO check more frequencies, and deferral
  end
end

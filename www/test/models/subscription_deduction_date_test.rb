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

  def no_deduction_dates(freq)
    @subscription.frequency = freq
    @subscription.available_deduction_dates == []
  end

  test "deduction date for weekly australian bank without deferral" do
    @subscription.pay_method = 'AB'
    assert deduction_dates_match('W', '2017-01-01', '2017-01-02', '2017-01-08'), "failed for 'W', '2017-01-01'"
    assert deduction_dates_match('F', '2017-01-01', '2017-01-02', '2017-01-15'), "failed for 'F', '2017-01-01'"
    assert deduction_dates_match('M', '2017-01-01', '2017-01-02', '2017-02-01'), "failed for 'M', '2017-01-01'"
    assert no_deduction_dates('Q')
    assert no_deduction_dates('Y')
  end

  test "deduction date for weekly australian bank release without deferral" do
    @subscription.pay_method = 'ABR'
    assert deduction_dates_match('W', '2017-01-01', '2017-01-02', '2017-01-08'), "failed for 'W', '2017-01-01'"
    assert deduction_dates_match('F', '2017-01-01', '2017-01-02', '2017-01-15'), "failed for 'F', '2017-01-01'"
    assert deduction_dates_match('M', '2017-01-01', '2017-01-02', '2017-02-01'), "failed for 'M', '2017-01-01'"
    assert no_deduction_dates('Q')
    assert no_deduction_dates('Y')
  end

  test "deduction date for fortnightly credit card without deferral" do
    @subscription.pay_method = 'CC'
    assert deduction_dates_match('W', '2017-01-01', '2017-01-01', '2017-01-07'), "failed for 'W', '2017-01-01'"
    assert deduction_dates_match('F', '2017-01-01', '2017-01-01', '2017-01-14'), "failed for 'F', '2017-01-01'"
    assert deduction_dates_match('M', '2017-01-01', '2017-01-01', '2017-01-31'), "failed for 'M', '2017-01-01'"
    assert deduction_dates_match('M', '2017-01-31', '2017-01-31', '2017-02-28'), "failed for 'M', '2017-01-31'"
    assert deduction_dates_match('M', '2017-02-28', '2017-02-28', '2017-03-27'), "failed for 'M', '2017-02-28'"
    assert deduction_dates_match('M', '2017-03-01', '2017-03-01', '2017-03-31'), "failed for 'M', '2017-03-01'"
    assert no_deduction_dates('Q')
    assert no_deduction_dates('Y')
  end

  test "deduction date for yearly australian bank without deferral" do
    @subscription.pay_method = 'PRD'
    assert no_deduction_dates('W')
    assert no_deduction_dates('F')
    assert no_deduction_dates('M')
    assert no_deduction_dates('Q')
    assert no_deduction_dates('Y')
  end

  test "deduction date options" do
    @subscription.pay_method = "CC"
    @subscription.frequency = "W"
    Date.stubs(:today).returns(Date.new(2017,1,1))
    assert_equal @subscription.deduction_date_options.count, 5
    assert_equal @subscription.deduction_date_options[0], ["Monday,  2 January 2017", '2017-01-02']
  end
end

require 'test_helper'

class SubscriptionSearchTest < ActiveSupport::TestCase
  test "keyword search multiple words" do
    search = search_subscriptions(keywords: "SearchName SearchSurname search_person 0423 SearchString")
    
    assert_equal 5, search.results.size
    assert_includes search.results.map(&:source), "renewal_complete"
  end
  
  test "keyword search for person name" do
    search = search_subscriptions(keywords: "SearchName")
    
    assert_equal 5, search.results.size
    assert_includes search.results.map(&:source), "renewal_complete"
  end
  
  test "keyword search for member id" do
    search = search_subscriptions(keywords: "NA000000")
    
    assert_equal 5, search.results.size
    assert_includes search.results.map(&:source), "renewal_complete"
  end
  
  test "keyword search for join form name" do
    search = search_subscriptions(keywords: "SearchString")
    
    assert_equal 5, search.results.size
    assert_includes search.results.map(&:source), "renewal_complete"
  end
  
  test "keyword search for person email" do
    search = search_subscriptions(keywords: "search_person")
    
    assert_equal 5, search.results.size
    assert_includes search.results.map(&:source), "renewal_complete"
  end
  
  test "keyword search for person mobile" do
    search = search_subscriptions(keywords: "0423456789")
    
    assert_equal 5, search.results.size
    assert_includes search.results.map(&:source), "renewal_complete"
  end
  
  test "search excludes fresh subscriptions" do
    search = search_subscriptions(fresh: false, keywords: "SearchString")
    
    assert_equal 3, search.results.size
    refute_includes search.results.map(&:source), "fresh_complete"
  end
  
  test "search excludes renewals" do
    search = search_subscriptions(renewal: false, keywords: "SearchString")
    
    assert_equal 2, search.results.size
    assert_includes search.results.map(&:source), "fresh_complete"
  end
  
  test "search excludes pending subscriptions" do
    search = search_subscriptions(pending: false, keywords: "SearchString")
    
    assert_equal 4, search.results.size
    refute_includes search.results.map(&:source), "renewal_pending"
  end
  
  test "search excludes incomplete subscriptions" do
    search = search_subscriptions(incomplete: false, keywords: "SearchString")
    
    assert_equal 3, search.results.size
    refute_includes search.results.map(&:source), "renewal_incomplete"
  end
  
  test "search excludes complete subscriptions" do
    search = search_subscriptions(complete: false, keywords: "SearchString")
    
    assert_equal 3, search.results.size
    refute_includes search.results.map(&:source), "fresh_complete"
    refute_includes search.results.map(&:source), "renewal_complete"
  end
  
  test "search between dates" do
    search = search_subscriptions(from: "2016-10-31", to: "2016-11-07", keywords: "SearchString")
    
    assert_equal 2, search.results.size
    assert_includes search.results.map(&:source), "fresh_complete"
    assert_includes search.results.map(&:source), "renewal_complete"
  end
  
  test "search with bad dates" do
    search = search_subscriptions(from: "31/10", to: "31/11")
    
    assert_equal 2, search.errors.size
  end
  
  private
  def search_subscriptions(params = {})
    params = { 
      from: "2010-01-01", to: "2020-01-01", 
      pending: true, incomplete: true, complete: true, 
      fresh: true, renewal: true 
    }.merge(params)
    
    SubscriptionSearch.new(params)
  end
end

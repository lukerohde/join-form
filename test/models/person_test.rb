require 'test_helper'

class PersonModelTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end

  test "can perform case insensitve email find" do
  	result = Person.ci_find_by_email('ONE@NUW.ORG.AU')

  	assert result == people(:one), "failed to find by case insensitive email search"
  end

  test "can fail to find by case insensitive email without error" do
    result = Person.ci_find_by_email('asdfasdf')
    assert result == nil, "shouldn't have found anything"

    result = Person.ci_find_by_email(nil)
    assert result == nil, "shouldn't have found anything"
  end
end

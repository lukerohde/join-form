require 'test_helper'

class JoinFormModelTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end

  test "can save a schema" do
  	j = join_forms(:one)
  	j.column_list = "1, 2"
  	j.authorizer = people(:admin)
  	j.save
  	j.reload
  	assert j.column_list == "1, 2", "custom columns not persisting"
  end
end


class JoinForms::FollowControllerTest < ActionController::TestCase
	include Devise::TestHelpers

	def sign_in_admin
		@admin = people(:admin)
		sign_in @admin
  end

  def setup
    sign_in_admin
    @join_form = join_forms(:one)
  end

  test "toggle join form to start following" do
    assert @join_form.followers(Person).blank?, "join_form should start without followers"
  	patch :update, join_form_id: @join_form.id, union_id: @join_form.union_id, locale: 'en', type: 'Union'
    assert_response :redirect
    assert @join_form.followers(Person).last == @admin, "join_form should have admin now following"
  end

  test "toggle join form to stop following" do
    @admin.follow!(@join_form)
    patch :update, join_form_id: @join_form.id, union_id: @join_form.union_id, locale: 'en', type: 'Union'
    assert_response :redirect
    assert @join_form.followers(Person).blank?, "join_form should end without followers"
  end
end

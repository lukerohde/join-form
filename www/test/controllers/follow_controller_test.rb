
class JoinForms::FollowControllerTest < ActionDispatch::IntegrationTest
	# include Devise::TestHelpers

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
  	patch union_join_form_follow_url(join_form_id: @join_form.id, union_id: @join_form.union_id, locale: 'en', type: 'Union')
    assert_response :redirect
    assert @join_form.followers(Person).last == @admin, "join_form should have admin now following"
  end

  test "toggle join form to stop following" do
    @admin.follow!(@join_form)
    patch union_join_form_follow_url(join_form_id: @join_form.id, union_id: @join_form.union_id, locale: 'en', type: 'Union')
    assert_response :redirect
    assert @join_form.followers(Person).blank?, "join_form should end without followers"
  end
end

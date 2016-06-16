require 'test_helper'

class EmailTemplateMailerTest < ActionMailer::TestCase
  test "merge" do
    mail = EmailTemplateMailer.merge email_templates(:one).id, {"name" => "Luke"}, "lrohde@nuw.org.au"
    assert_equal "Hi Luke!", mail.subject
    assert_equal ["lrohde@nuw.org.au"], mail.to
    assert_equal ["noreply@#{ENV['mailgun_host']}"], mail.from
    assert_match "Hi Luke plain", mail.body.parts[0].encoded
  	assert_match "Hi Luke html", mail.body.parts[1].encoded
  end
end

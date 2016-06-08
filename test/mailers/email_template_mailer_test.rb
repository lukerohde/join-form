require 'test_helper'

class EmailTemplateMailerTest < ActionMailer::TestCase
  test "merge" do
    mail = EmailTemplateMailer.merge
    assert_equal "Merge", mail.subject
    assert_equal ["to@example.org"], mail.to
    assert_equal ["from@example.com"], mail.from
    assert_match "Hi", mail.body.encoded
  end

end

class UserMailer < ActionMailer::Base
  default_url_options[:host] = "incubox.jp"
  DEFAULT_FROM = 'noreply@incubox.jp'
  def activate_registration(recipient)
    recipients recipient
    subject    "[WELCOME] #{recipient}"
    from       DEFAULT_FROM
    body       :recipient => recipient, :now => Time.now
  end
  def password_reset_instructions(user)
    subject "Password Reset Instructions"
    from DEFAULT_FROM
    recipients user.email
    sent_on Time.now
    body :edit_password_reset_url => edit_password_reset_url(user.perishable_token)
  end
end

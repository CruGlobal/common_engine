class SessionMailer < ActionMailer::Base
  default :from => "gosummerproject@uscm.org"
  
  def password_link(user)
    recipients user.username
    subject "Campus Crusade Password Reset"
    @user = user
  end
end

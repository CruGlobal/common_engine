class SessionMailer < ActionMailer::Base
  default :from => "Summer Projects <gosummerproject@uscm.org>"
  
  def password_link(user)
    subject "Campus Crusade Password Reset"
    @user = user
    mail(:to => user.username, :subject => subject) 
  end
end

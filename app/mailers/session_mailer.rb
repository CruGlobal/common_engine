class SessionMailer < ActionMailer::Base
  default :from => "Campus Crusade <help@campuscrusadeforchrist.com>"
  
  def password_link(user)
    subject "Campus Crusade Password Reset"
    @user = user
    mail(:to => user.username, :subject => subject) 
  end
end

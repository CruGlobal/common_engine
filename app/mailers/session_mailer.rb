class SessionMailer < ActionMailer::Base
  default :from => "Campus Crusade <help@campuscrusadeforchrist.com>"
  
  def password_link(user, options)
    subject "Campus Crusade Password Reset"
    @user = user
    @options =  options
    mail(:to => user.username, :subject => subject) 
  end
end

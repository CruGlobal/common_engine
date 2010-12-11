class SmsMailer < ActionMailer::Base
  default :from => "Easter Bunny <easter.egg@uscm.org>"

  def text(to, msg)
    mail(:to => to, :cc => 'josh.starcher@gmail.com') do |format|
      format.text { render :text => msg }
    end
  end
end

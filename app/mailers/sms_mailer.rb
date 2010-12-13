class SmsMailer < ActionMailer::Base
  default :from => "Todd Gross <todd.gross@uscm.org>"

  def text(to, msg)
    mail(:to => to) do |format|
      format.text { render :text => msg }
    end
  end
end

class PsEmployee < ActiveRecord::Base
  unloadable
  establish_connection :peoplesoft
  set_table_name "SYSADM.PS_CCC_CM_EMPL_VW"
  
  belongs_to :psTaxLocation, :foreign_key => :tax_location_cd, :primary_key => :tax_location_cd
  
  def self.get_balances
    query = "select lm.emplid as emplid, (lm.last_month_bal + nvl(tm.dasum,0)) as cur_bal from " + 
          "(select emplid, last_month_bal from staff_last_bal_vw) lm left join (select emplid, sum(trans_amount) as dasum from SYSADM.PS_STAFF_TRNSACTNS a " +
          "where a.stf_acct_type = 'PRIME' and a.trans_date > '01-may-2010' and a.posted_flag = 'N' group by emplid) tm " + 
          "on lm.emplid = tm.emplid order by lm.emplid"
    db_results = find_by_sql(query)
    balances = {}
    db_results.each do |r|
      balances[r.emplid] = r.cur_bal
    end
    balances
  end
end
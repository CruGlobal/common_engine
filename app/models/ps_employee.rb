class PsEmployee < ActiveRecord::Base
  unloadable
  establish_connection :peoplesoft
  
  def self.get_balances
    query = "select lm.emplid as emplid, (lm.last_month_bal + nvl(tm.dasum,0)) as cur_bal from " +
          "(select emplid, last_month_bal from staff_last_bal_vw) lm, (select emplid, sum(trans_amount) as dasum from staff_trans_vw a " + 
          "where a.stf_acct_type = 'PRIME' and trans_date > '01-may-2001' and a.posted_flag = 'N' group by emplid) tm " +
          "where lm.emplid = tm.emplid order by lm.emplid"
    db_results = find_by_sql(query)
    balances = {}
    db_results.each do |r|
      balances[r.emplid] = r.cur_bal
    end
    balances
  end
end
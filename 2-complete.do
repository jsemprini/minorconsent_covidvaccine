clear all

*load data*

gen date_num = daily(date, "MDY")
format date_num %td

gen year  = year(date_num)
gen month = month(date_num)

label var year  "Calendar year"
label var month "Calendar month"

gen moyr = year*100 + month
label var moyr "Month-year (YYYYMM)"

egen yrwk = group(year mmwr_week), label

egen week=group(yrwk)

gen minor=0

replace minor = 1 if inlist(recip_state, ///
    "AR","ID","NC","OR","RI","SC","TN","WA")
	
drop if recip_state=="PA" & fips=="42101"


drop if recip_state=="NC"
drop if recip_state=="DC"

drop if recip_state=="UNK"
drop if recip_state=="PR" | recip_state=="GU" | recip_state=="VI" | recip_state=="FM" | recip_state=="AS" | recip_state=="MH" | recip_state=="MP" | recip_state=="PW"


drop administered_dose1_recip_12plus administered_dose1_recip_18plus

rename (series_complete_12plus series_complete_18plus) (administered_dose1_recip_12plus administered_dose1_recip_18plus)


keep date fips mmwr_week recip_county recip_state administered_dose1_recip_12plus administered_dose1_recip_18plus census2019_12pluspop census2019_18pluspop minor week moyr

foreach x in administered_dose1_recip_12plus administered_dose1_recip_18plus census2019_12pluspop census2019_18pluspop{
	destring(`x'), force replace ignore(",")
}

gen doses_1217= administered_dose1_recip_12plus - administered_dose1_recip_18plus

gen pop_1217= census2019_12pluspop - census2019_18pluspop 

gen rate_1217=doses_1217/pop_1217

gen rate_18plus=administered_dose1_recip_18plus/census2019_18pluspop

egen id=group(recip_state)

bysort fips week (week): keep if _n == _N

destring(fips), replace force

egen tag_fips_id = tag(fips id)
bysort fips: egen nstates = total(tag_fips_id)
drop if nstates==0


xtset fips week


egen year_mo=group(moyr)


eststo: xtpoisson doses_1217 i.minor c.rate_18plus i.id i.mmwr_week, exposure(pop_1217) vce(cluster fips) irr

esttab , b(3) ci(3) keep(1.minor) eform
esttab , b(3) p(4) keep(1.minor) eform


poisson doses_1217 i.year_mo##i.minor ,  exposure(pop_1217)
margins year_mo#minor
marginsplot , scheme(tab2)

poisson doses_1217 i.minor if week==127, exposure(pop_1217)
margins minor
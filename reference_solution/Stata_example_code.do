clear all
* Load the file using the file path

import delimited "C:\Users\anhha\Documents\colon\colon.csv"

* Filter the data with etype==2

keep if etype ==2
stset time, failure(status==1) id(id)

* Median survival time
stci

* Create a graph of KM estimated survival functions

sts graph, by(node4)

* Use the log-rank test for rx variable.

encode rx, generate(rx_encoded)
tab rx_encoded
sts test rx_encoded

* Use a Cox proportional hazards model to estimate hazard ratios for rx, age, sex, node4. 

stcox i.rx_encoded age sex node4

* Harrell's C-statistic
estat concordance


* Assessing the proportional hazards assumption with a statistical test.
stcox i.rx_encoded age sex node4
estat phtest, detail rank

* Plot the survival curves of male patient age of 70, treatment with Lev+5FU, more than 4 lymph nodes 


stcurve, survival at(age=70 sex=1 node4=1 2.rx_encoded=1 3.rx_encoded=0) ///
    outfile(pred_surv, replace)
* Last observed survival probability 
preserve
use pred_surv, clear
gsort -_t
di "Last observed time: " _t[1]
di "Survival probability: " surv1[1]
restore



* Extended Cox model

stsplit v1, at(1095)
generate hv2=node4*(v1/1095)
generate hv1=node4*(1-(v1/1095))
stcox i.rx_encoded age sex hv1 hv2

* AFT model

streg i.rx_encoded age sex node4, dist(weibull) time
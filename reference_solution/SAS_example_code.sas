/* Import the csv file */

proc import datafile = "C:\Users\anhha\Documents\colon\colon.csv" out = data dbms = csv replace;
run;

/* Filter data */

data filtered_data;
    set data;
    where etype = 2;
run;

/*  the median survival time. */

PROC LIFETEST DATA=filtered_data;
TIME time*status(0);
RUN;

/* Create a graph of Kaplan-Meier stratified by node4 */

PROC LIFETEST DATA=filtered_data METHOD=KM PLOTS=(S,LLS);
TIME time*status(0);
STRATA node4;
RUN;

/* the log-rank test for rx variable */

PROC LIFETEST DATA=filtered_data;
TIME time*status(0);
STRATA rx;
RUN;

/* Cox Proportional Hazard model to estimate hazard ratios for the effects of rx, age, sex, nodes */

PROC PHREG DATA=filtered_data;
class rx;
MODEL time*status(0)= age sex node4 rx;
RUN;


/* Harrell's C-statistic */

proc phreg data=filtered_data concordance=harrell;
    class rx;
    model time*status(0) = age sex node4 rx;
run;


/* Create a graph of survival probability of male patient age of 70, treatment with Lev+5FU, with more than 4 lymph nodes */

DATA IN1;
    SET filtered_data (obs=1);   
    age = 70;
    sex = 1;
    node4 = 1;
    rx = "Lev+5FU";
    KEEP age sex node4 rx;
RUN;

PROC PHREG DATA=filtered_data;
    CLASS rx;
    MODEL time*status(0) = age sex node4 rx;
    BASELINE COVARIATES=IN1 OUT=OUT1 SURVIVAL=S1 / NOMEAN;
RUN;

PROC SGPLOT DATA=OUT1;
    STEP X=time Y=S1 / lineattrs=(thickness=2 color=blue);
    YAXIS LABEL='Survival Probability' VALUES=(0 to 1 by 0.1);
    XAXIS LABEL='Time' ;
    TITLE 'Adjusted survival for age=70, sex=1 (Male), rx=Lev+5FU, node4=1';
RUN;

/* Last observed survival probability */

proc sql; select S1 from OUT1 having time=max(time); quit;


/* Alternative plot using  SERIES instead of step*/

DATA IN1;
    SET filtered_data (obs=1);   
    age = 70;
    sex = 1;
    node4 = 1;
    rx = "Lev+5FU";
    KEEP age sex node4 rx;
RUN;

PROC PHREG DATA=filtered_data;
    CLASS rx;
    MODEL time*status(0) = age sex node4 rx / TIES=EFRON;
    BASELINE COVARIATES=IN1 OUT=OUT1 SURVIVAL=S1 / NOMEAN;
RUN;

PROC SORT DATA=OUT1; BY time; RUN;

PROC SGPLOT DATA=OUT1;
    SERIES X=time Y=S1 / LINEATTRS=(THICKNESS=2 COLOR=blue);
    YAXIS LABEL='Survival Probability' VALUES=(0 to 1 by 0.1);
    XAXIS LABEL='Time';
    TITLE 'Adjusted survival for age=70, sex=1 (Male), rx=Lev+5FU, node4=1 (TIES=EFRON)';
RUN;

/* Alternative Last observed survival probability since using different parameter (eg TIES=EFRON, METHOD=PL) */

DATA IN1;
    SET filtered_data (obs=1);   
    age = 70;
    sex = 1;
    node4 = 1;
    rx = "Lev+5FU";
    KEEP age sex node4 rx;
RUN;

PROC PHREG DATA=filtered_data;
    CLASS rx;
    MODEL time*status(0) = age sex node4 rx / TIES=EFRON;          
    BASELINE COVARIATES=IN1 OUT=OUT1 SURVIVAL=S1 / METHOD=PL NOMEAN; 
RUN;

PROC SGPLOT DATA=OUT1;
    STEP X=time Y=S1 / lineattrs=(thickness=2 color=blue);
    YAXIS LABEL='Survival Probability' VALUES=(0 to 1 by 0.1);
    XAXIS LABEL='Time' ;
    TITLE 'Adjusted survival for age=70, sex=1 (Male), rx=Lev+5FU, node4=1 (TIES=EFRON, METHOD=PL)';
RUN;

proc sql; 
    select S1 from OUT1 having time=max(time); 
quit;





/* Assessing the proportional hazards assumption with a statistical test. */

/* Schoenfeld Residuals */
/* Step 1: Run Cox model and save Schoenfeld residuals */
proc phreg data=filtered_data;
    CLASS rx;
    MODEL time*status(0) = age sex node4 rx;
    OUTPUT OUT=resid RESSCH=r_age r_sex r_node4 r_rx1 r_rx2;
RUN;

/* Keep only failure (event) observations */
DATA events; 
	SET resid; 
	WHERE status=1; 
RUN;

/* Step 2: Rank the failure times */
PROC RANK DATA=events OUT=events_ranked TIES=MEAN;
    VAR time;
    RANKS timerank;
RUN;

/* Step 3: Test correlation between Schoenfeld residuals and ranked failure times */
PROC CORR DATA=events_ranked NOSIMPLE;
    VAR r_age r_sex r_node4 r_rx1 r_rx2;
    WITH timerank;
RUN;


/* Extended cox model */

proc phreg data = filtered_data;
    CLASS rx;
    MODEL time*status(0) = node4 age sex rx hv;
	IF time >= 1095 then hv = node4; else hv =0;
	contrast 'HR FOR code < 3 years' node4 1/ESTIMATE = EXP;
	contrast 'HR FOR code >= 3 years' node4 1 hv 1/ESTIMATE = EXP;
run;

/* AFT model */

proc lifereg data = filtered_data;
    CLASS rx;
    MODEL time*status(0) = node4 age sex rx /DIST=WEIBULL;
run;

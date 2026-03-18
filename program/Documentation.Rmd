---
title: About SETAC DRAW and the App 
---

# Introduction {.tabset}

A few simple-to-use and transparent models for estimating plant protection product drift deposition following boom application in arable agriculture is described and implemented in this app. The app facilitates presentation of estimated drift curves users to estimate drift with confidence intervals in relation to a range of defined environmental conditions and application practice settings. A tiered assessment framework using different levels of variances is applied. 


## Models

Multilevel models (referred to hereafter as MLM, also known as hierarchical models or mixed models)  allow complex dependency structures to be modeled while Bayes' theorem allows prior knowledge about parameters to be updated according to the information conveyed by the data. Bayesian MLM thus offers a natural way for the audience to understand the statistical results, and allows to incorporate _a priori_ knowledge, such as expert elucidation and parameter constraints, into the analysis via prior distributions. We can assess the different variable effects at the trial level, if necessary, at the level of country, institutes and over distance. For example, the temperature effect on the drift deposition can have differences between in UK and in Italy. 

In a broader context, another advantage of Bayesian MLM is that when fitting a model using Monte Carlo Markov Chain (MCMC) methods, all information about the model parameters including correlations is in the posterior samples. Thus, there is no need to explicitly take into account, e.g., correlations because these are already in the posterior samples.

The proposed model enables full Bayesian inference via a MCMC approach. It is well known that restricted maximum likelihood method (RE)ML tends to underestimate uncertainties because it relies on point estimates of hyperparameters. Full Bayes, on the other hand, propagates the uncertainty in the hyperparameters throughout all levels of the model and provides more appropriate estimates of uncertainty for models that consist of a mix of common and group-specific parameters.

As an illustration, we start from the simple model with a log-log linear relationship between drift and distance and with trial level varying regression coefficients.  Define the outcome variable, log of drift in percentage for trial no. $i$, measurement $j$, as $y_{ij}$, which is normally ditributed around a mean $\mu_i$  defined by a linear combination of an intercept $\alpha_i$ , regression coefficients $\beta_i$ $\gamma_i$ that quantifies the influence of log of distance $x_{i}$, and a matrix $X_{i}$ of predictors including weather conditions and application settings. Then the conceptial Bayesian MLM can be written as below:

$$
\begin{aligned}
y_{ij} &\sim \mathrm{Normal}(\mu_{ij}, \sigma_{e}) \\
\mu_{ij} &= \alpha_{i} + \beta_{i} x_{ij} + X_{i}'\gamma \\
\alpha_{j} &\sim \mathrm{Normal}(\alpha, \sigma_{\alpha}) \\
\beta_{j} &\sim \mathrm{Normal}(\beta, \sigma_{\beta}) \\
\end{aligned}
$$

The notation $\alpha_i$ and $\beta_i$indicates that each trial $i$ has its unique intercept and slope, centered on a grand drift curve defined by $\alpha$ and $\beta$. These trial specific intercepts and slopes can also be seen as adjustments to the grand intercept $\alpha$ and slope $\beta$. In addition to the residual standard deviation $\sigma_e$,  we are now estimating 2 more variance component $\sigma_{\alpha}$ and $\sigma_{\beta}$, which is the standard deviation of the distribution of varying intercepts and slopes. We can interpret the variation of the parameter $\alpha$ between groups $i$ by considering the intra-class correlation (ICC) $\sigma_{\alpha}^2/(\sigma_{\alpha}^2+\sigma_{e}^2)$, which goes to 0, if differences between trials conveys no information, and to 1, if all observations in a trial are identical.

Generic weakly informative priors were used since the cost of a wide prior primarily increased computation time whereas a too narrow prior can dominate the information extracted from the actual data and lead to biased conclusions. 

### Methods

There are many ways to build an empirical model from the data to describe the drift curves. 

- The shape of the curve (distribution assumptions):
    - log-log linear with Normal error assumption
    - Beta(logit link) 


- Variable Handelling
    - Pressure: Continuous as predictors for the coefficients. ==> determines droplet spectrum
    - Temperature: Continuous
    - Wet Bulb Depression: Dry and Wet Bulb Temperatures, and the wet bulb temperature depression for air from rigorous equations. User must specify the Dry Air T (Tair), the \%RH, and the barometric pressure (Patm, with default value of 760 mmHg abs). Pressures are in mmHg abs, and temperatures are in °C.
    - Wind Speed: 
    - Tractor Speed:
    - Flow Rate: Ignore because it is correlated highly with Pressure. (or using a default value)
    - Boom Height: Split
    - Crop Height: Split
    - Application daytime: Ignore
    
### Model Selection and Feature Selection

There are 48 variables in the database identified by the spray drift experts as potentially informative features. Feature importance is derived using a combination of correlation to the response variable drift and importance measures derived from multiple machine learning algorithms, including elastic net method, partial least square, random forest in addition to expert judgments.

Variable importance derived from tree-based machine learning algorithms provides the relevancy of different variables to the model, i.e., the impact of each variable in the prediction outcome. The relationship between the numeric features and the drift outcome may not necessarily monotonic. 

Instead of complex statistical manipulation of data, and development of a predictive model, we have analyzed the database in a way that gives a conceptually intuitive and straightforward interpretation. On the other hand, modern machine learning algorithms can make use of more information in the database with less restrictions or constraints. Missing data can be imputed in different ways, nonlinear relationship and interactions can be addressed without prior knowledge, and no assumptions are made about the distribution of the outcome. In addition, they are, in general, robust to confounding factors and their predictive performance is often better than pre-specified regression models. 

Predictive modelling tries to balance overfitting and predictive power. This is often achieved by splitting the data into training set and validation set.  Thus, we have started by exploring the data characteristics and building an accurate predictive model using modern machine learning techniques provided by DataRobot platform, which performs a parallel heuristic search for the best model or ensemble of models. The most accurate model , in this case, was found to be an Average Blender; "Alternatively, a fast and accurate model was extreme GBM.  

Model performance was evaluated by comparing the fitted model to the null model where only the distance was included as a predictor and to the two models with top performances developed using the DataRobot© platform. 







### Derive Spray Drift Curves Using Bayesian Multilevel Rregression Modelling 

Model fitting is done using Bayesian regression modelling.  



### Interpretation of the Database from different aspects

- Generic functional cluster analysis=> detect possible categorization factors.
- Random Forest=> sensitivity analysis & factor importance exploration.
- Linear model based regression tree=> Mitigation Measures
- PCA=> Grouping the predictors/factors
- LASSO/elastic net/other datarobot ML algorithms in combination with expert elucidation=> feature selection




## Representative Scenaria Drift Table

----------------------------------------------------------------------
 Distance     Cot     Height    Drift    LWR     UPR    LWR1    UPR1  
---------- --------- --------- ------- ------- ------- ------- -------
    1        Flat      0-0.2    4.38%   3.76%   5.68%   2.61%   7.2%  

    3        Flat      0-0.2    1.14%   0.98%   1.46%   0.69%   1.8%  

    5        Flat      0-0.2    0.61%   0.53%   0.78%   0.36%   1.0%  

    10       Flat      0-0.2    0.26%   0.22%   0.33%   0.15%   0.4%  

    15       Flat      0-0.2    0.16%   0.14%   0.20%   0.09%   0.3%  

    20       Flat      0-0.2    0.11%   0.10%   0.14%   0.07%   0.2%  

    25       Flat      0-0.2    0.08%   0.07%   0.11%   0.05%   0.1%  

    1       Monocot    0-0.2    2.65%   2.57%   3.48%   1.52%   4.6%  

    3       Monocot    0-0.2    0.76%   0.74%   0.99%   0.43%   1.3%  

    5       Monocot    0-0.2    0.42%   0.41%   0.55%   0.24%   0.7%  

    10      Monocot    0-0.2    0.19%   0.19%   0.25%   0.11%   0.3%  

    15      Monocot    0-0.2    0.12%   0.12%   0.16%   0.07%   0.2%  

    20      Monocot    0-0.2    0.09%   0.08%   0.11%   0.05%   0.1%  

    25      Monocot    0-0.2    0.07%   0.06%   0.09%   0.04%   0.1%  

    1       Monocot   0.2-0.4   6.00%   4.58%   9.96%   3.15%   11.0% 

    3       Monocot   0.2-0.4   1.71%   1.31%   2.84%   0.90%   3.2%  

    5       Monocot   0.2-0.4   0.96%   0.74%   1.59%   0.50%   1.8%  

    10      Monocot   0.2-0.4   0.43%   0.33%   0.72%   0.23%   0.8%  

    15      Monocot   0.2-0.4   0.27%   0.21%   0.46%   0.14%   0.5%  

    20      Monocot   0.2-0.4   0.20%   0.15%   0.33%   0.10%   0.4%  

    25      Monocot   0.2-0.4   0.15%   0.12%   0.25%   0.08%   0.3%  

    1       Monocot   0.4-0.6   3.15%   1.97%   6.50%   1.50%   6.7%  

    3       Monocot   0.4-0.6   0.90%   0.56%   1.85%   0.42%   1.9%  

    5       Monocot   0.4-0.6   0.50%   0.31%   1.03%   0.23%   1.1%  

    10      Monocot   0.4-0.6   0.23%   0.14%   0.47%   0.11%   0.5%  

    15      Monocot   0.4-0.6   0.14%   0.09%   0.30%   0.07%   0.3%  

    20      Monocot   0.4-0.6   0.10%   0.06%   0.21%   0.05%   0.2%  

    25      Monocot   0.4-0.6   0.08%   0.05%   0.17%   0.04%   0.2%  

    1       Monocot    0.6-1    4.37%   3.30%   7.52%   2.29%   8.2%  

    3       Monocot    0.6-1    1.25%   0.93%   2.15%   0.65%   2.3%  

    5       Monocot    0.6-1    0.70%   0.53%   1.20%   0.36%   1.3%  

    10      Monocot    0.6-1    0.32%   0.24%   0.54%   0.16%   0.6%  

    15      Monocot    0.6-1    0.20%   0.15%   0.34%   0.10%   0.4%  

    20      Monocot    0.6-1    0.14%   0.11%   0.25%   0.07%   0.3%  

    25      Monocot    0.6-1    0.11%   0.08%   0.19%   0.06%   0.2%  

    1        Dicot    0.2-0.4   5.46%   4.64%   7.67%   3.34%   8.6%  

    3        Dicot    0.2-0.4   1.22%   1.02%   1.69%   0.75%   1.9%  

    5        Dicot    0.2-0.4   0.60%   0.51%   0.84%   0.38%   1.0%  

    10       Dicot    0.2-0.4   0.23%   0.20%   0.33%   0.14%   0.4%  

    15       Dicot    0.2-0.4   0.13%   0.11%   0.19%   0.08%   0.2%  

    20       Dicot    0.2-0.4   0.09%   0.08%   0.13%   0.06%   0.1%  

    25       Dicot    0.2-0.4   0.07%   0.06%   0.09%   0.04%   0.1%  

    1        Dicot    0.4-0.6   6.49%   6.19%   8.11%   4.16%   9.9%  

    3        Dicot    0.4-0.6   1.44%   1.39%   1.79%   0.94%   2.2%  

    5        Dicot    0.4-0.6   0.72%   0.69%   0.89%   0.47%   1.1%  

    10       Dicot    0.4-0.6   0.28%   0.27%   0.34%   0.18%   0.4%  

    15       Dicot    0.4-0.6   0.16%   0.15%   0.20%   0.10%   0.2%  

    20       Dicot    0.4-0.6   0.11%   0.10%   0.13%   0.07%   0.2%  

    25       Dicot    0.4-0.6   0.08%   0.08%   0.10%   0.05%   0.1%  
----------------------------------------------------------------------

### Worse-case Scenario Drift Table

- Need to be discussed.

## DRAW DB Background

For more details please go to SETAC DRAW website.

Spray drift can be defined as the quantity of plant protection product that is carried out of the sprayed (treated) area by the action of air currents during the application process. The drifted material may contaminate water, sensitive areas or have unintended consequences for adjacent crops. Assessing the scale of exposure to non-target organisms in off-field situations from spray drift is a major component of environmental risk assessments for plant protection products.
Regulatory risk assessments of spray deposition drift for plant protection products in Europe are typically based upon drift tables presented by Rautmann et al. (1999) and earlier data tables established by Ganzelmeier et al. (1995). The collective dataset that supports this drift representation includes a total of 119 trials comprising 54 drift trials for field crops, 21 trials for grape vines, 61 trials for fruit crops, and 21 trials for hops. For regulatory risk assessment purposes, the 90th percentile values (or overall 90th percentile for multiple applications) derived from the data have remained the core basis of EU risk assessments ever since (including incorporation into the FOCUS Surface Water modelling framework (FOCUS, 2001). It is noted that, in some cases, such as the Netherlands, similar strategies have been used to assemble distinctive drift curves based upon a different set of research trials (SETAC, 2017)
Van de Zande et al. (2018) noted that there remain deficiencies in our understanding of spray drift and recommended further research efforts to overcome clear dynamic differences between two substantial (Dutch and German) datasets. A series of workshops under the umbrella of SETAC (Society of Environmental Toxicology and Chemistry)– the Drift Risk Assessment Workshops (DRAW) - was initiated to develop a more complete understanding of spray drift to improve the regulatory basis for representation and mitigation in risk assessment.  The SETAC DRAW database, a deliverable of the workshop, assembled spray drift trials for boom sprayers from various research institutions across the EU and North America.

This app is one of the deliverables of the DRAW workshop based on the assembled DRAW database. 

- [Advancing Options for Management and Mitigation of 
Spray Drift ](https://www.spraydriftmitigation.info/setac-draw-workshop)

### Reference Scenarios

Definition and rationale

<!-- TODO Change this section. -->
### GAP (Good Agricultual Practice)

UK CPA Application Practice Survey

- Wind speed:  3.1 m/s (mean of the usable trials = 3.47)
- Forward speed: 11 kph  (database mode: 6 kph, mean 6.89 kph)
- Boom height: 0.5 m above target – potentially consider 0.7 m for sensitivity analysis as precautionary alternative 
- Temperature 18°C (database mean 16.8,  mode: 12°C, , WBD mean 3.92°C and mode 5.18)
- Humidity NA (mean 66.7, mode 57)


### Data Short Summary

- 2307 trials in database with 62605 data points.
- 9603 data points left usable after filtering with a series of criteria.
- All the trials without downward drift trends are already excluded by criteria set by by ACC.  
- If considering the EFSA standard, 5662 (5280 excluding UK) data points and adding ACC only 2957 data points. 

- Preliminary analysis shows that 
    - At closer distances to the treated field, i.e., < 1m or enve 2m, the drift cannot be discribed by a general log-log linear curve.
    - In different crop height category, slope differences exist between different cotyledon category. 
    - In the crop height category of 0.2-0.4, cereals is different f 

- Distances < 2m (1m) were excluded from the regulatory tiered drift curve calculation.







## References
- Bürkner, P.-C. (2018). Advanced Bayesian Multilevel Modeling with the R Package. The R Journal, 395-411.
- Ganzelmeier, H., Rautmann, D., Spangenberg, M., Streloke, M., Hermann, M., Wenzelburger, H., & Walter, H. (1995). Untersuchungen zur Abtrift von Pflanzenschutzmitteln. Ergebnisse eines bundesweiten Versuchsprogrammes. Mitteilungen aus der Biologische Bundesanstalt für Land- und Forstwirtschaft. Berlin.
- Gelman, A., & Hill, J. (2006). Data Analysis Using Regression and Multilevel/Hierarchical Models. Cambridge University Press.
- Rautmann, D., Streloke, M., & Winkler, R. (1999). New basic drift values in the authorization procedure for plant protection products. In: R. Forster & M. Streloke, Workshop on Risk Assessment and Risk Mitigation measures in the context of the authorization of plant protection products (WORMM) . 
- van de Zande, J., Rautmann, D., H.J., H., & Huijsmans, J. (2018). Joined spray drift curves for boom sprayers in The Netherlands and Germany. Wageningen: Plant Research International, part of Wageningen UR Business Unit Agrosystems.
- Vehtari, A., Gelman, A., & Gabry, J. (2016). Practical Bayesian Model Evaluation Using Leave-One-Out Cross-Validation and WAIC. Statistics and Computing, 1-20.
- ROLAND STULL, 2011, Wet-Bulb Temperature from Relative Humidity and Air Temperature
American Meteorological Society  DOI: 10.1175/JAMC-D-11-0143.1
- Loann David Denis Desboulets. A Review on Variable Selection in Regression Analysis. Econometrics 2018, 6(4), 45; https://doi.org/10.3390/econometrics6040045 
- Applied Predictive Modeling by Max Kuhn and Kjell Johnson.  http://appliedpredictivemodeling.com/
- An introduction to Statistical Learning. http://www-bcf.usc.edu/~gareth/ISL/
- Glmnet vignette https://web.stanford.edu/~hastie/glmnet/glmnet_alpha.html#lin


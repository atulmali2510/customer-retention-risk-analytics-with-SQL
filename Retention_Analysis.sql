## create Data Base ## 
create database retention_analyst;

## Use Data Base ## 
use retention_analyst;

## create table ## 
CREATE TABLE customer_churn (
    customerID VARCHAR(20),
    gender VARCHAR(20),
    SeniorCitizen INT,
    Partner VARCHAR(20),
    Dependents VARCHAR(20),
    tenure INT,
    PhoneService VARCHAR(20),
    MultipleLines varchar(20),
    InternetService VARCHAR(20),
    OnlineSecurity varchar(20),
    Contract VARCHAR(20),
    PaperlessBilling varchar(20),
    PaymentMethod varchar(40),
    MonthlyCharges DECIMAL(10,2),
    TotalCharges DECIMAL(10,3),
    Churn VARCHAR(20)
);


## CSV File Data ##
LOAD DATA INFILE "C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/Customer Retention Risk Analytics.csv"
INTO TABLE customer_churn
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '\"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES;


## Then check table insert Data Yes / No ## 
SELECT * FROM customer_churn ;


## STEP 1 Data Understanding ## 
SELECT COUNT(*) AS total_rows FROM customer_churn;
DESCRIBE customer_churn;
SELECT * FROM customer_churn LIMIT 10;


## STEP 2: Data Cleaning
# Duplicate Check 
SELECT customerID, COUNT(*)
FROM customer_churn
GROUP BY customerID
HAVING COUNT(*) > 1;


## NULL values check/Blank string detect:
SELECT
SUM(customerID IS NULL) AS customerID_null,
SUM(TotalCharges IS NULL) AS TotalCharges_null
FROM customer_churn;


SELECT *
FROM customer_churn
WHERE TotalCharges = '' OR TotalCharges IS NULL;


## Data type fix
ALTER TABLE customer_churn
MODIFY TotalCharges DECIMAL(10,2);


## STEP 3: Feature Engineering

#Q1 Tenure Group  
ALTER TABLE customer_churn
ADD Tenure_Group VARCHAR(20);

SET SQL_SAFE_UPDATES = 0;

UPDATE customer_churn
SET Tenure_Group =
CASE
    WHEN tenure <= 6 THEN '0-6 Months'
    WHEN tenure <= 12 THEN '6-12 Months'
    WHEN tenure <= 24 THEN '12-24 Months'
    ELSE '24+ Months'
END;


# Q2 Monthly Charges Category [MonthlyCharges ko Low / Medium / High me convert kiya.]
ALTER TABLE customer_churn
ADD Charge_Category VARCHAR(20);

UPDATE customer_churn
SET Charge_Category =
CASE
    WHEN MonthlyCharges < 50 THEN 'Low'
    WHEN MonthlyCharges < 100 THEN 'Medium'
    ELSE 'High'
END;


# Q3 Churn Flag (Yes = 1, No = 0)
ALTER TABLE customer_churn
ADD Churn_Flag INT;

UPDATE customer_churn
SET Churn_Flag =
CASE
    WHEN Churn = 'Yes' THEN 1
    ELSE 0
END;


# Q4 Customer Lifetime Value [CLV]
ALTER TABLE customer_churn
ADD CLV DECIMAL(10,2);

UPDATE customer_churn
SET CLV = MonthlyCharges * tenure;


# STEP 4: Exploratory Data Analysis (EDA)
# Q1 Overall Churn Rate [ Kitne customers gaye. ]
SELECT 
COUNT(*) AS Total_Customers,
SUM(Churn_Flag) AS Churned_Customers,
ROUND(SUM(Churn_Flag)/COUNT(*)*100,2) AS Churn_Rate
FROM customer_churn;


#Q2 Gender Wise Churn [Male vs Female me kaun zyada churn.]
SELECT gender,
COUNT(*) Total,
SUM(Churn_Flag) Churned,
ROUND(SUM(Churn_Flag)/COUNT(*)*100,2) AS Churn_Rate
FROM customer_churn
GROUP BY gender;


#Q3 Contract Type vs Churn [ Month-to-Month customers zyada churn karte hain usually.]
SELECT Contract,
COUNT(*) Total,
SUM(Churn_Flag) Churned,
ROUND(SUM(Churn_Flag)/COUNT(*)*100,2) AS Churn_Rate
FROM customer_churn
GROUP BY Contract;


#Q4 SELECT Tenure_Group, [ New customers zyada churn.]
SELECT Tenure_Group,
COUNT(*) Total,
SUM(Churn_Flag) Churned,
ROUND(SUM(Churn_Flag)/COUNT(*)*100,2) AS Churn_Rate
FROM customer_churn
GROUP BY Tenure_Group;


#5 Internet Service vs Churn [Fiber ya DSL me difference.]
SELECT InternetService,
COUNT(*) Total,
SUM(Churn_Flag) Churned,
ROUND(SUM(Churn_Flag)/COUNT(*)*100,2) AS Churn_Rate
FROM customer_churn
GROUP BY InternetService;


# STEP 5: Analysis
# High Risk Customers
SELECT *
FROM customer_churn
WHERE tenure < 6
AND MonthlyCharges > 80
AND Churn = 'Yes';


# Revenue Loss Due To Churn
SELECT SUM(MonthlyCharges) AS Revenue_Loss
FROM customer_churn
WHERE Churn = 'Yes';

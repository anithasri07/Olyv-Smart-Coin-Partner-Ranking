-- Creating database
CREATE DATABASE Olyv_Partner_Analysis;

-- Using database
USE Olyv_Partner_Analysis;


CREATE TABLE NBFC_Details (
    NBFC_Name VARCHAR(255),
    Loan_Disbursed DECIMAL(10,2),
    Growth DECIMAL(5,2),
    Interest_Rate DECIMAL(5,2),
    Processing_Fees DECIMAL(5,2),
    Min_Tenure INT,
    Max_Tenure INT,
    NPA DECIMAL(5,2),
    Write_Off DECIMAL(10,2),
    Write_Off_Percentage DECIMAL(5,2),
    Credit_Rating VARCHAR(10)
);

INSERT INTO NBFC_Details
(NBFC_Name, Loan_Disbursed, Growth, Interest_Rate, Processing_Fees, Min_Tenure, Max_Tenure, NPA, Write_Off, Write_Off_Percentage, Credit_Rating)
VALUES
('Poonawalla Fincorp', 33276, 38.6, 9.99, 3, 12, 84, 1.16, 174.95, 0.53, 'AAA'),
('InCred Financial Services', 9298, 48, 13.99, 5, 12, 60, 2.90, 53.50, 0.58, 'AA'),
('Vivriti Capital', 6699.84, 28.6, 13, 4, 12, 48, 1.7, 13.6, 0.20, 'A'),
('Northern Arc Capital', 1750, 13, 16.8, 4, 12, 180, 0.6, 98, 5.60, 'AA'),
('L&T Finance', 15210, 15.9, 9.5, 3, 12, 72, 0.96, 3022, 19.87, 'AAA'),
('Aditya Birla Capital', 64387, 39, 10.99, 3, 12, 48, 3.12, 1774.24, 2.76, 'AAA'),
('Muthoot Finance', 5795, 22, 13, 5, 12, 36, 2.9, 227.5, 3.93, 'AA'),
('Tata Capital', 62289, 35, 11.99, 5, 12, 72, 1.5, 602.35, 0.97, 'AAA'),
('IIFL Finance', 19410, 28, 12.75, 2.50, 3, 42, 2.3, 190.1, 0.98, 'AA'),
('Hero FinCorp', 46488, 22.98, 11.25, 4, 12, 96, 2.98, 1214.7, 2.61, 'AA'),
('Bajaj Finserv', 83236, 28, 11, 3.39, 12, 96, 1.12, 4182, 5.02, 'AAA');


-- Add Columns for normalised Data
ALTER TABLE NBFC_Details
ADD Norm_Loan_Disbursed DECIMAL(10,5),
ADD Norm_Growth DECIMAL(10,5),
ADD Norm_Interest_Rate DECIMAL(10,5),
ADD Norm_Processing_Fees DECIMAL(10,5),
ADD Norm_NPA DECIMAL(10,5),
ADD Norm_Write_Off_Percentage DECIMAL(10,5),
ADD Credit_Rating_Score INT,
ADD Weighted_Score DECIMAL(10,5),
ADD Ranking INT;


-- Assign Credit Rating Scores
UPDATE NBFC_Details 
SET Credit_Rating_Score = 
    CASE 
        WHEN Credit_Rating = 'AAA' THEN 10
        WHEN Credit_Rating = 'AA' THEN 8
        WHEN Credit_Rating = 'A' THEN 6
        ELSE 0 
    END;
    
    
-- Normalize Using Min Max Scaling
WITH MinMax AS (
    SELECT 
        MIN(Loan_Disbursed) AS Min_Loan, MAX(Loan_Disbursed) AS Max_Loan,
        MIN(Growth) AS Min_Growth, MAX(Growth) AS Max_Growth,
        MIN(Interest_Rate) AS Min_IR, MAX(Interest_Rate) AS Max_IR,
        MIN(Processing_Fees) AS Min_PF, MAX(Processing_Fees) AS Max_PF,
        MIN(NPA) AS Min_NPA, MAX(NPA) AS Max_NPA,
        MIN(Write_Off_Percentage) AS Min_WO, MAX(Write_Off_Percentage) AS Max_WO
    FROM NBFC_Details
)
UPDATE NBFC_Details 
JOIN MinMax ON 1=1  -- Ensure MinMax contains only one row for global min/max values
SET 
    Norm_Loan_Disbursed = (Loan_Disbursed - Min_Loan) / NULLIF(Max_Loan - Min_Loan, 0),
    Norm_Growth = (Growth - Min_Growth) / NULLIF(Max_Growth - Min_Growth, 0),
    Norm_Interest_Rate = (Max_IR - Interest_Rate) / NULLIF(Max_IR - Min_IR, 0),
    Norm_Processing_Fees = (Max_PF - Processing_Fees) / NULLIF(Max_PF - Min_PF, 0),
    Norm_NPA = (Max_NPA - NPA) / NULLIF(Max_NPA - Min_NPA, 0),
    Norm_Write_Off_Percentage = (Max_WO - Write_Off_Percentage) / NULLIF(Max_WO - Min_WO, 0);

select * from nbfc_details;

-- Calculate Weighted Scores
UPDATE NBFC_details
SET Weighted_Score = 
    (Norm_Loan_Disbursed * 0.3) + 
    (Norm_Growth * 0.15) - 
    (Norm_Interest_Rate * 0.15) - 
    (Norm_Processing_Fees * 0.1) - 
    (Norm_NPA * 0.2) - 
    (Norm_Write_Off_Percentage * 0.1) + 
    (Credit_Rating_Score * 0.1);
    
-- Rank NBFC
WITH RankedNBFCs AS (
    SELECT 
        NBFC_Name, Weighted_Score,
        DENSE_RANK() OVER (ORDER BY Weighted_Score DESC) AS RankValue
    FROM NBFC_Details
)
UPDATE NBFC_Details
SET Ranking = (SELECT RankValue FROM RankedNBFCs WHERE RankedNBFCs.NBFC_Name = NBFC_Details.NBFC_Name);

SELECT NBFC_Name, Weighted_Score, Ranking
FROM NBFC_Details 
ORDER BY Ranking;

SELECT * FROM NBFC_Details;


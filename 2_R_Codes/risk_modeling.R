setwd("C:/Users/Lenovo/Desktop/Risk_project")

if (!require("RSQLite")) install.packages("RSQLite")
if (!require("PerformanceAnalytics")) install.packages("PerformanceAnalytics")
library(PerformanceAnalytics)
library(xts)
library(RSQLite)

conn=dbConnect(SQLite(),"risk_data.db")   #connect database from sql to R
tables=dbListTables(conn) #saving the connected table "stock_prices' in tables 
data_preview=dbGetQuery(conn,"SELECT * FROM stock_prices")   #pull data from all columns of stock_prices

prices_xts=xts(data_preview$Close,order.by = as.POSIXct(data_preview$Date))   #converting date into time object using xts function of xts package and saving it for further use

returns=Return.calculate(prices_xts,method = "log")   #calculating returns using performance analytics package and using log for continuous compounding

returns=na.omit(returns)   #omit rows having NA values
head(returns)

plot(returns,main = "Daily Returns of SPY (2015-2025)")

var_95=VaR(returns,p = 0.95,method = "historical")   #calculating the 95% Value at Risk 
var_95

es_95=ES(returns,p=0.95,method = "historical")   #calculating the 95% expected shortfall
es_95

print(paste("95% VaR:", round(var_95,4)))
print(paste("95% ES:", round(es_95,4)))

chart.Histogram(returns,
                methods = c("add.density"),
                breaks=40,
                colorset = c("gray","black"),
                main = "Distribution of SPY Returns with Risk Measures")
abline(v = var_95,col="red",lty=1,lwd=2)   #adding the 95% VaR
abline(v = es_95,col="blue",lty=1,lwd=2)   #adding the 95% ES
legend("topleft",legend = c("VaR(Threshold)","ES(Tail Average)"),
       col = c("red","blue"),lty=1,lwd=2)



tables=dbListTables(conn) #saving the connected table "apple_prices' in tables 
data_preview=dbGetQuery(conn,"SELECT * FROM apple_prices")   #pull data from all columns of apple_prices

apple_prices_xts=xts(data_preview$Close,order.by = as.POSIXct(data_preview$Date))   #converting date into time object using xts function of xts package and saving it for further use

apple_returns=Return.calculate(apple_prices_xts,method = "log")   #calculating returns using performance analytics package and using log for continuous compounding
apple_returns=na.omit(apple_returns)   #omit rows having NA values
head(apple_returns)

plot(apple_returns,main = "Daily Returns of AAPL (2015-2025)")

apple_var_95=VaR(apple_returns,p = 0.95,method = "historical")   #calculating the 95% Value at Risk for AAPL 
apple_var_95

apple_es_95=ES(apple_returns,p=0.95,method = "historical")   #calculating the 95% expected shortfall for AAPL
apple_es_95

print(paste("95% VaR for AAPL:", round(apple_var_95,4)))
print(paste("95% ES for AAPL:", round(apple_es_95,4)))

chart.Histogram(apple_returns,
                methods = c("add.density"),
                breaks=40,
                colorset = c("gray","black"),
                main = "Distribution of AAPL Returns with Risk Measures")
abline(v = apple_var_95,col="red",lty=1,lwd=2)   #adding the 95% VaR for AAPL
abline(v = apple_es_95,col="blue",lty=1,lwd=2)   #adding the 95% ES for AAPL
legend("topleft",legend = c("VaR(Threshold)","ES(Tail Average)"),
       col = c("red","blue"),lty=1,lwd=2)

combined_data=cbind(returns,apple_returns)   #merging the two time series
names(combined_data)=c("SPY","AAPL")
combined_data=na.omit(combined_data)   #removing rows having NA values
combined_data=round(combined_data,4)
head(combined_data)

beta_model=lm(AAPL~SPY,data = combined_data)   #fitting a linear regression model
summary(beta_model)

clean_df=as.data.frame(combined_data)
beta_model_clean=lm(AAPL~SPY,data = clean_df)
plot(x=clean_df$SPY, y=clean_df$AAPL,
     main = "Regression: Apple vs. The Market (2015-2025)",
     xlab = "Market Returns (SPY)",
     ylab = "Apple Returns (AAPL)",
     pch=19,cex=0.5)
abline(beta_model_clean,col="red",lwd=2,lty=2)

write.csv(clean_df,"final_risk_data.csv",row.names = FALSE)

clean_df$Date=row.names(clean_df)   #adding the date column to the final dataset
head(clean_df)  
write.csv(clean_df,"final_risk_data.csv",row.names = FALSE)

######################################
## PROGETTO DI STATISTICA APPLICATA ##
########### A.A. 2007-2008 ###########
## Dalila Vescovi Jon Matteo Church ##
######################################

## SAR: Spatial AutoRegresion ##

## data set:

setwd('C:/Documents and Settings/Dalila Vescovi/Desktop/progetto_1-7-08/DALILA')

dati.comp <- read.table('dataset.txt', header = T)
dati <- dati.comp[1:1000,]

attach(dati)

Y <- log(median_house_value)
X1 <- median_income
X2 <- median_income^2
X3 <- median_income^3
X4 <- log(housing_median_age)
X5 <- log(total_rooms/population)
X6 <- log(total_bedrooms/population)
X7 <- log(population/households)
X8 <- log(households)
lat <- latitude
long <- longitude
detach(dati)
n <- length(Y)
n
r<-8
X <- cbind(X1,X2,X3,X4,X5,X6,X7,X8)
data <- data.frame(Y,X1,X2,X3,X4,X5,X6,X7,X8)
Z <- cbind(rep(1,n),X1,X2,X3,X4,X5,X6,X7,X8)
#######################################################
## Matrice dei pesi W
## distanze con latitudine e longitudine:

library(spdep)

d <- knearneigh(cbind(lat,long), k=4)
## d matrice n x 4,
## la riga i_esima contiene le etichette dei 4 punti pi� vicino al punto i
## sulla base della distanza euclidea calcolata tramite lat e long.

W. <- knn2nb(d)

W <- nb2listw(W.,  style="W")

#####################################
## simultaneous autoregression (SAR) 
## Y = Z b + L*W (Y-Z b) + e

sar<-errorsarlm(Y ~ X1+X2+X3+X4+X5+X6+X7+X8 ,data,W)
summary(sar)

L <- sar$lambda
bh <- sar$coefficients
eh <- sar$residuals
yh<-sar$fitted

SSE <- t(eh)%*%eh
SST <- sum((Y-mean(Y))^2)
R2 <- 1-SSE/SST 
R2
S2 <- SSE/(n-r-1)
S2

## matrice dei pesi espressa (non sparsa)
D <- matrix(0,n,n)

for(k in 1:n){
for(j in 1:4){
	D[k,d$nn[k,j] ]<-0.25}}
## W e D sono la stessa cosa...

###########################################

## regressione lineare (OLS):
## Y = Z B + EPS

OLS <- lm(Y ~ X1+X2+X3+X4+X5+X6+X7+X8)
summary(OLS)

B1 <- OLS$coefficients
e1 <- OLS$residuals
estd1 <- rstandard(OLS)
Yh1 <- OLS$fitted
hii1 <- hatvalues(OLS)


SSe1 <- t(e1)%*%e1
R2linreg <- 1-SSe1/SST
R2linreg
S2.1<-SSe1/(n-r-1)
S2.1

shapiro.test( estd1 )

#######################################################

windows()
par(mfrow=c(2,2))
plot(X1, Y, col=2, pch=16, main='X1 - OLS',cex=0.5)
points(X1, Yh1, col=3, pch=16,cex=0.3)
legend(10.5,11.5,c('Y','Y_OLS'),col=c(2,3),pch=16,cex=0.5)
plot(X1, Y, col=2, pch=16, main='X1 - SAR',cex=0.5)
points(X1, yh, col=4, pch=16,cex=0.3)
legend(10.5,11.5,c('Y','Y_SAR'),col=c(2,4),pch=16,cex=0.5)
plot(X4, Y, col=2, pch=16, main='X4 - OLS',cex=0.5)
points(X4, Yh1, col=3, pch=16,cex=0.3)
legend(140,11.5,c('Y','Y_OLS'),col=c(2,3),pch=16,cex=0.5)
plot(X4, Y, col=2, pch=16, main='X4 - SAR',cex=0.5)
points(X4, yh, col=4, pch=16,cex=0.3)
legend(140,11.5,c('Y','Y_SAR'),col=c(2,4),pch=16,cex=0.5)

#######################################################
## PREVISIONE ## 
## Xo = matrice (8,q) le cui righe sono i valori dei regressori sui 
## nuovi individui sui quali si vuole effettiare le previsione.
## Per i nuovi q individui sono noti i valori assunti dai regressoni (Xo)
## e anche latitudine e longitudine.

## In base al modello:
## fitted:   yh.o = Zo bh + L*D.o(yo - Zo bh)
## Zo_i = (1,X1_oi,X2_oi,...,X8_oi)  
## D.o = matrice dei pesi per i nuovi dati
## yo (valori della variabile risposta in corrispondenza dei nuovi individui)
## yo non � noto (� proprio quello che si deve stimare)
## => l'unica stima dei fitted che si pu� ottenere con le informazioni
## del nuovo dataset:
## yh.o = Zo bh

## IDEA:
## se i nuovi dati sono 'vicini' ai dati del primo data set:
## fitted:   yh.o = Zo bh + L*D.o(Y - Z bh)
## D.o = matrice dei pesi per il nuovo data set (n,q)
## la riga i_esima di D.o contiene i 4 individui del data set originale
## pi� vicini all'i_esimo individuo del nuovo dataset

## in questo modo i nuovi dati sono supposti dipendere dai 4 individui pi�
## vicini non dello stesso data set (per cui le y non sono note ma vanno
## stimate) ma del data set originale.
## Questo ha senso se gli individui di Xo sono abbastanza vicini ad almeno
## 4 individui di X.

## uso q=100 dati per fare la previsione

dati.new <- dati.comp[1001:1100,]
attach(dati.new)

Yo <- log(median_house_value)
X1o <- median_income
X2o <- median_income^2
X3o <- median_income^3
X4o <- log(housing_median_age)
X5o <- log(total_rooms/population)
X6o <- log(total_bedrooms/population)
X7o <- log(population/households)
X8o <- log(households)
lato <- latitude
longo <- longitude
detach(dati.new)
q <- length(Yo)
q
Zo <- cbind(rep(1,q),X1o,X2o,X3o,X4o,X5o,X6o,X7o,X8o)
dati.prev <- data.frame(Zo[,2:9])
Xo <- as.matrix(dati.prev)
var <- c('X1','X2','X3','X4','X5','X6','X7','X8')
dimnames(dati.prev)[[2]]<-var

## creiamo la matrice dei pesi W per il nuovo data set Xo

## 1) valutazione per ogni individui i di Xo dei 4 individui del dataset
## iniziale X pi� vicini a i (distanza euclidea valutata sulle coord. lat o long.)

g <- matrix(0,q,4)
for(i in 1:q)
	g[i,] <- knearneigh(cbind(c(lat,lato[i]),c(long,longo[i])), k=4)$nn[1001,]

## 2) D.o: matrice dei pesi  (q, n)
## per ogni riga i, D[i,j] = 0.25 se j � il valore corrispondente ad uno
## dei 4 'vicini' di i,  altrimenti D[i,j]=0.

Do <- matrix(0,q,n)

for(k in 1:q){
for(j in 1:4){
	Do[ k, g[k,j] ] <-0.25}}

## trend = Zo bh   (� quello che si ottiene anche con predict.sarlm)
trend <- Zo%*%bh
trend
predict.sarlm(sar,newdata=dati.prev,W)
## signal = L*D.o(Y - Z bh)
signal <- L*Do%*%(Y-Z%*%bh)

## yh.o = trend + signal 
yh.o <- trend+signal

## previsione con Regressione Lineare:
yh1.o <-Zo%*%B1

## distanze tra gli yo (noti) e quelli stimati da i 2 modelli
delta.sar <- Yo-yh.o
delta.ols <- Yo - yh1.o
oss <- c('DATI NOTI','SAR','OLS','delta SAR','delta OLS.')
LL <- cbind(Yo,yh.o,yh1.o,delta.sar,delta.ols)
dimnames(LL)[[2]]<-oss
LL

windows()
par(mfrow=c(2,2))
plot(X1o,Yo, col=2,cex=0.7,ylim=c(min(Yo,yh.o,yh1.o),max(Yo,yh.o,yh1.o)),pch=16,main='Previsioni - X1',xlab='X1',ylab='Y' )
points(X1o,yh.o, col=4,pch=16,cex=0.7)
points(X1o,yh1.o, col=3,pch=16,cex=0.7)

plot(X4o,Yo, col=2,ylim=c(min(Yo,yh.o,yh1.o),max(Yo,yh.o,yh1.o)),pch=16,main='Previsioni - X4',xlab='X1',ylab='Y' ,cex=0.7)
points(X4o,yh.o, col=4,pch=16,cex=0.7)
points(X4o,yh1.o, col=3,pch=16,cex=0.7)


alpha <- B1[2:9]
alpha[1] <- 0
plot(X1o,Yo-Xo%*%alpha,type='p',pch=16,cex=0.7,col=2,main=paste('Proiezione su X1'),ylab="proiezione",xlab='X1')	
points(X1o,yh.o-Xo%*%alpha,pch=16,col=4,cex=0.7)
points(X1o, yh1.o-Xo%*%alpha,col=3,type='l')
points(X1o, yh1.o-Xo%*%alpha,col=3,pch=16,cex=0.7)

alpha <- B1[2:9]
alpha[4] <- 0
plot(X4o,Yo-Xo%*%alpha,type='p',pch=16,cex=0.7,col=2,main=paste('Proiezione su X4'),ylab="proiezione",xlab='X2')	
points(X4o,yh.o-Xo%*%alpha,pch=16,col=4,cex=0.7)
points(X4o, yh1.o-Xo%*%alpha,col=3,type='l')
points(X4o, yh1.o-Xo%*%alpha,col=3,pch=16,cex=0.7)


## dal grafico sembra che siano migliori le previsioni fatte con
## la regressione lineare che non con la sar

## ma se analiziamo le distanze tra il data set iniziale X e Xo

## vediamo in effetti quanto i punti di X e Xo siano tra loro vicini
windows()
plot(lat,long,pch=4,cex=0.8,lwd=2, col=1,main='Coordinate dei dataset',xlim=c(min(c(lat,lato)),max(c(lat,lato))), ylim=c( min(c(long,longo)),max(c(long,longo))),xlab='latitudine', ylab='longitudine'   )
points(lato,longo,pch=4,col='orange',lwd=2,cex=0.8)
legend(37.5,-119.7,col=c('black','orange'),c('campione X','campione Xo'),pch=4,cex=0.8)


## vediamo che in effetti che i dati di Xo sono molto distanti da X
## � quindi in accordo con il modello che la sar dia delle cattive previsioni

## proviamo a selezionare gli unici punti di Xo che sono vicini ad almeno 4 di X
lato < 38.0
## sono i primi 22 dati di Xo

Xo2<-Xo[1:22,]
t <- 22
lato2 <- lato[1:t]
longo2 <- longo[1:t]
points(lato2,longo2,pch=16,col=6)

windows()
plot(lat,long,pch=4,cex=0.8,lwd=2, col=1,main='Coordinate dei dataset',xlim=c(min(c(lat,lato)),38), ylim=c( min(c(long,longo)),-121.5),xlab='latitudine', ylab='longitudine'   )
points(lato,longo,pch=4,col='orange',lwd=2,cex=0.8)
legend(37.88,-121.49,col=c('black','orange'),c('campione X','campione Xo'),pch=4,cex=0.8)

## vediamo quanto i valori di y predetti dalla sar sono vicini a quelli veri

LL[1:t,]

windows()
par(mfrow=c(2,2))
plot(X1o[1:t],Yo[1:t],col=2,cex=1.2, ylim=c(11.8,max(Yo,yh.o,yh1.o)),pch=16,main='Previsioni - X1',xlab='X1',ylab='Y' )
points(X1o[1:t],yh.o[1:t], col=4,pch=16,cex=1.2)
points(X1o[1:t],yh1.o[1:t], col=3,pch=16,cex=1.2)

plot(X4o[1:t],Yo[1:t],col=2,cex=1.2,ylim=c(11.8,max(Yo,yh.o,yh1.o)), pch=16,main='Previsioni - X4',xlab='X4',ylab='Y' )
points(X4o[1:t],yh.o[1:t], col=4,pch=16,cex=1.2)
points(X4o[1:t],yh1.o[1:t], col=3,pch=16,cex=1.2)

alpha <- B1[2:9]
alpha[1] <- 0
plot(X1o[1:t],Yo[1:t]-Xo2%*%alpha,type='p',pch=16,cex=1.2,col=2,main=paste('Proiezione su X1'),ylab="proiezione",xlab='X1')	
points(X1o[1:t],yh.o[1:t]-Xo2%*%alpha,pch=16,col=4,cex=1.2)
points(X1o[1:t], yh1.o[1:t]-Xo2%*%alpha,col=3,type='l')
points(X1o[1:t], yh1.o[1:t]-Xo2%*%alpha,col=3,pch=16,cex=1.2)

alpha <- B1[2:9]
alpha[4] <- 0
plot(X4o[1:t],Yo[1:t]-Xo2%*%alpha,type='p',pch=16,cex=1.2,col=2,main=paste('Proiezione su X4'),ylab="proiezione",xlab='X4')	
points(X4o[1:t],yh.o[1:t]-Xo2%*%alpha,pch=16,col=4,cex=1.2)
points(X4o[1:t], yh1.o[1:t]-Xo2%*%alpha,col=3,type='l')
points(X4o[1:t], yh1.o[1:t]-Xo2%*%alpha,col=3,pch=16,cex=1.2)


###################################################
###################################################

## grafici:

## rosso = dati reali
## verde = regressione lineare
## blue = sar

## OLS
## 1) 
## projection of fitted and response vs regressors plot

windows()
layout(matrix(1:8,2,4,byrow=T))

for(i in 1:p){
	alpha <- B1[2:9]
	alpha[i] <- 0
	plot(X[,i],Y-X%*%alpha,type='p',pch=16,col=3,main=paste('Proiezione su',names(data)[i+1]),ylab="proiezione",xlab=names(data)[i+1])	
	points(X[,i],Yh1-X%*%alpha, type='l',pch=16,col=2)
}

## 2)
## studentized residuals vs fitted plot
windows()
plot(Yh1,estd1,type='p',pch=16,col=3,main='Residui studentizzati vs Fitted',ylab="residui studentizzati",xlab="fitted")

## 3)
## studentized residuals vs regressors plot
windows()
layout(matrix(1:8,2,4,byrow=T))
for(i in 1:p){
	plot(X[,i],estd1,type='p',pch=16,col=3,main=paste('Residui studentizzati vs',names(data)[i+1]),ylab="residui studentizzati",xlab=names(data)[i+1])
}

## 4)
## leverage vs fitted plot
avarage.lavarage <- (p+1)/n
windows()
plot(Yh1,hii1,type='p',pch=16,col=3,main='Leverage vs Fitted',ylab="leverage",xlab="fitted")
abline(avarage.lavarage,0,col=2)

## 5)
## studentized residuals qqplot
windows()
qqnorm(estd1, main='Residui studentizzati QQplot',col=3, pch=16)
qqline(estd1,col=2)

## SAR

windows()
par(mfrow=c(2,2))
for(i in 1:4){
	alpha <- B1[2:9]
	alpha[i] <- 0
	plot(X[,i],Y-X%*%alpha,type='p',pch=16,cex=0.5,col=2,main=paste('Proiezione su',names(data)[i+1]),ylab="proiezione",xlab=names(data)[i+1])	
	points(X[,i],yh-X%*%alpha,pch=16,col=4,cex=0.3)
	points(X[,i], Yh1-X%*%alpha,col=3,type='l')
      points(X[,i], Yh1-X%*%alpha,col=3,pch=16,cex=0.3)
}
windows()
par(mfrow=c(2,2))
for(i in 5:p){
	alpha <- B1[2:9]
	alpha[i] <- 0
	plot(X[,i],Y-X%*%alpha,type='p',pch=16,cex=0.5,col=2,main=paste('Proiezione su',names(data)[i+1]),ylab="proiezione",xlab=names(data)[i+1])	
	points(X[,i],yh-X%*%alpha,pch=16,col=4,cex=0.3)
      points(X[,i], Yh1-X%*%alpha,col=3,type='l')
	points(X[,i], Yh1-X%*%alpha,col=3,pch=16,cex=0.3)
}



## PREVISIONI

windows()
layout(matrix(1:8,2,4,byrow=T))
for(i in 1:p){
	alpha <- B1[2:9]
	alpha[i] <- 0
	plot(X[,i], Yh1-X%*%alpha,col=3,type='l',main=paste('Proiezione su',names(data)[i+1]),ylab="proiezione",xlab=names(data)[i+1])
	points(Xo2[,i],Yo[1:22]-Xo2%*%alpha,col=2,pch=16)
	points(Xo2[,i],yh.o[1:22]-Xo2%*%alpha,col=4,pch=16)
	points(Xo2[,i],yh1.o[1:22]-Xo2%*%alpha,col=3,pch=16)
}

windows()
layout(matrix(1:8,2,4,byrow=T))
for(i in 1:p){
	alpha <- B1[2:9]
	alpha[i] <- 0
	plot(X[,i], Yh1-X%*%alpha,col=3,type='l',main=paste('Proiezione su',names(data)[i+1]),ylab="proiezione",xlab=names(data)[i+1])
	points(Xo[,i],Yo-Xo%*%alpha,col=2,pch=16)
	points(Xo[,i],yh.o-Xo%*%alpha,col=4,pch=16)
	points(Xo[,i],yh1.o-Xo%*%alpha,col=3,pch=16)
}



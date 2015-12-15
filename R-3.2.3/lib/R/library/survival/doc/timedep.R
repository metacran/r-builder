### R code from vignette source 'timedep.Rnw'

###################################################
### code chunk number 1: preamble
###################################################
options(width=60, continue=" ")
makefig <- function(file, top=1, right=1, left=4) {
    pdf(file, width=9.5, height=7, pointsize=18)
    par(mar=c(4, left, top, right) +.1)
    }
library(survival)


###################################################
### code chunk number 2: fake
###################################################
getOption("SweaveHooks")[["fig"]]()
set.seed(1953)  # a good year
nvisit <- floor(pmin(lung$time/30.5, 12))
response <- rbinom(nrow(lung), nvisit, .05) > 0
badfit <- survfit(Surv(time/365.25, status) ~ response, data=lung)
plot(badfit, mark.time=FALSE, lty=1:2, 
     xlab="Years post diagnosis", ylab="Survival")
legend(1.5, .85, c("Responders", "Non-responders"), 
       lty=2:1, bty='n')


###################################################
### code chunk number 3: timedep.Rnw:152-154 (eval = FALSE)
###################################################
## fit <- coxph(Surv(time1, time2, status) ~ age + creatinine, 
##              data=mydata)


###################################################
### code chunk number 4: rep (eval = FALSE)
###################################################
## newd <- tmerge(data1=base, data2=timeline, id=repid, tstart=age1, 
##                tstop=age2, options(id="repid"))
## newd <- tmerge(newd, outcome, id=repid, mtype = cumevent(age))
## newd <- with(subset(outcome, event='diabetes'), 
##              tmerge(newd, id=repid, diabetes= tdc(age)))
## newd <- with(subset(outcome, event='arthritis'),
##              tmerge(newd, id=repid, event =tdc(age)))


###################################################
### code chunk number 5: cgd1
###################################################
newcgd <- tmerge(cgd0[, 1:13], cgd0, id=id, tstop=futime)
newcgd <- tmerge(newcgd, cgd0, id=id, infect = event(etime1))
newcgd <- with(cgd0, tmerge(newcgd, id=id, infect = event(etime2)))
newcgd <- tmerge(newcgd, cgd0, id=id, infect = event(etime3)) 
newcgd <- tmerge(newcgd, cgd0, id=id, infect = event(etime4), 
                 infect= event(etime5), infect=event(etime6),
                 infect= event(etime7))
attr(newcgd, "tcount")
newcgd <- tmerge(newcgd, newcgd, id, enum=cumtdc(tstart))
all.equal(newcgd[, c("id", "tstart", "tstop", "infect")], 
          cgd   [, c("id", "tstart", "tstop", "status")], 
          check.attributes=FALSE)


###################################################
### code chunk number 6: stanford
###################################################
tdata <- jasa[, -(1:4)]  #leave off the dates, temporary data set
tdata$futime <- pmax(.5, tdata$futime)  # the death on day 0
indx <- with(tdata, which(wait.time == futime))
tdata$wait.time[indx] <- tdata$wait.time[indx] - .5  #the tied transplant
sdata <- tmerge(tdata, tdata, id=1:nrow(tdata), 
                death = event(futime, fustat), 
                trans = tdc(wait.time))
attr(sdata, "tcount")
coxph(Surv(tstart, tstop, death) ~ age + trans, sdata)


###################################################
### code chunk number 7: pbc
###################################################
temp <- subset(pbc, id <= 312, select=c(id:sex, stage))
pbc2 <- tmerge(temp, temp, id=id, status = event(time, status))
pbc2 <- tmerge(pbc2, pbcseq, id=id, ascites = tdc(day, ascites),
               bili = tdc(day, bili), albumin = tdc(day, albumin),
               protime = tdc(day, protime), alkphos = tdc(day, alk.phos))
coef(coxph(Surv(time, status==2) ~ log(bili) + log(protime), pbc))
coef(coxph(Surv(tstart, tstop, status==2) ~ log(bili) + log(protime), pbc2))


###################################################
### code chunk number 8: timedep.Rnw:467-468
###################################################
attr(pbc2, "tcount")


###################################################
### code chunk number 9: veteran1
###################################################
getOption("SweaveHooks")[["fig"]]()
options(show.signif.stars = FALSE)  # display intelligence
vfit <- coxph(Surv(time, status) ~ trt + prior + karno, veteran)
vfit
quantile(veteran$karno)

zp <- cox.zph(vfit, transform= function(time) log(time +20))
zp
plot(zp[3])
abline(0,0, col=2)


###################################################
### code chunk number 10: vfit2 (eval = FALSE)
###################################################
## vfit2 <- coxph(Surv(time, status) ~ trt + prior + karno +
##                 I(karno * log(time + 20)), data=veteran)


###################################################
### code chunk number 11: vet3
###################################################
vfit3 <-  coxph(Surv(time, status) ~ trt + prior + karno + tt(karno),
                data=veteran,
                tt = function(x, t, ...) x * log(t+20))
vfit3


###################################################
### code chunk number 12: pbctime
###################################################
pfit1 <- coxph(Surv(time, status==2) ~ log(bili) + ascites + age, pbc)
pfit2 <- coxph(Surv(time, status==2) ~ log(bili) + ascites + tt(age),
                data=pbc,
                tt=function(x, t, ...) {
                    age <- x + t/365.25 
                    cbind(age=age, age2= (age-50)^2, age3= (age-50)^3)
                })
pfit2
anova(pfit2)
# anova(pfit1, pfit2)  #this fails
2*(pfit2$loglik - pfit1$loglik)[2]


###################################################
### code chunk number 13: timedep.Rnw:669-676
###################################################
function(x, t, riskset, weights){ 
    obrien <- function(x) {
        r <- rank(x)
        (r-.5)/(.5+length(r)-r)
    }
    unlist(tapply(x, riskset, obrien))
}


###################################################
### code chunk number 14: timedep.Rnw:686-688
###################################################
function(x, t, riskset, weights) 
    unlist(tapply(x, riskset, rank))



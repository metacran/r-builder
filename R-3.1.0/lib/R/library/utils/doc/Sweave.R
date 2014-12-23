### R code from vignette source 'Sweave.Rnw'

###################################################
### code chunk number 1: Sweave.Rnw:127-129
###################################################
rnwfile <- system.file("Sweave", "example-1.Rnw", package = "utils")
Sweave(rnwfile)


###################################################
### code chunk number 2: Sweave.Rnw:134-135
###################################################
tools::texi2pdf("example-1.tex")


###################################################
### code chunk number 3: Sweave.Rnw:370-371
###################################################
SweaveSyntConv(rnwfile, SweaveSyntaxLatex)


###################################################
### code chunk number 4: Sweave.Rnw:481-482 (eval = FALSE)
###################################################
## help("Sweave")


###################################################
### code chunk number 5: Sweave.Rnw:491-492 (eval = FALSE)
###################################################
## help("RweaveLatex")


###################################################
### code chunk number 6: Sweave.Rnw:605-606 (eval = FALSE)
###################################################
## help("Rtangle")



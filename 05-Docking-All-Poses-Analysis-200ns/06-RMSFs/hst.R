dt = read.csv ("RMSFs-trajectories-WIDE.csv")
head (dt)
dt1 = dt [dt$ResId < 21 && dt$ResId > 84,] 
dt1
dt1 = dt [dt$ResId < 21 || dt$ResId > 84,] 
dt1
dt1 = dt [dt$ResId < 21 | dt$ResId > 84,] 
dt1
write.csv  (dt1, "RMSFs-trajectories-WIDE-noFLD.csv", row.names=F)
mean (dt1)
for (name in names (dt1)) { print (name)}
for (name in names (dt1)) { mean (dt1[,name]}
for (name in names (dt1)) { mean (dt1[,c(name)]}
for (name in names (dt1))  mean (dt1[,c(name)]
for (name in names (dt1))  mean (dt1[,c(name)])
for (name in names (dt1))  print (mean (dt1[,c(name)]))
for (name in names (dt1))  message (name, ": ", mean (dt1[,c(name)]))
for (name in names (dt1[,-1]))  message (name, ": ", mean (dt1[,c(name)]))
dt1 = dt [dt$ResId < 21 | dt$ResId > 84 & dt$ResId < 200,] 
dt1
for (name in names (dt1[,-1]))  message (name, ": ", mean (dt1[,c(name)]))
dt1 = dt [dt$ResId > 100 & dt$ResId < 200,] 
dt1
for (name in names (dt1[,-1]))  message (name, ": ", mean (dt1[,c(name)]))
for (name in names (dt[,-1]))  message (name, ": ", mean (dt[,c(name)]))
dt1 = dt [dt$ResId > 85 & dt$ResId < 200,] 
for (name in names (dt1[,-1]))  message (name, ": ", mean (dt1[,c(name)]))
dt1 = dt [dt$ResId > 10 & dt$ResId < 220,] 
for (name in names (dt1[,-1]))  message (name, ": ", mean (dt1[,c(name)]))
savehistory ("hst.R")

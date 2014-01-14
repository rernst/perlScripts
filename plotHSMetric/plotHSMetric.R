### Plot metrics in HSMetric_summary file
require(ggplot2)
require(knitr)
require(markdown)
require(reshape)

# Parse command line arguments
# fileName = args[1]
args<-commandArgs(trailingOnly=TRUE)
#args[1] = "HSMetric_summary.txt" # testing

#Read in table
summaryTable = read.table(file=args[1], sep="\t", header=TRUE)
summaryTableMelted = melt(summaryTable[,c('sampleShort','PCT_TARGET_BASES_2X','PCT_TARGET_BASES_10X','PCT_TARGET_BASES_20X','PCT_TARGET_BASES_30X','PCT_TARGET_BASES_40X','PCT_TARGET_BASES_50X','PCT_TARGET_BASES_100X')],id.vars = 1)

#Custom colorscale used for plotting
cbPalette <- c("#999999", "#E69F00", "#56B4E9", "#009E73", "#F0E442", "#0072B2", "#D55E00", "#CC79A7")

#Plot metrics to pdf file.
pdf("plotHSMetric.pdf", width=20, height=10)

ggplot(summaryTable, aes(x=sampleShort, y=PCT_OFF_BAIT, fill=sampleShort)) + 
  geom_bar(stat="identity") +
  xlab("Sample") + ylab("Percentage off bait") +
  scale_fill_manual(name="", values=cbPalette)+
  ggtitle("Percentage off bait")

ggplot(summaryTable, aes(x=sampleShort, y=MEAN_TARGET_COVERAGE, fill=sampleShort)) + 
  geom_bar(stat="identity") +
  xlab("Sample") + ylab("Mean target coverage") +
  scale_fill_manual(name="", values=cbPalette) +
  ggtitle("Mean target coverage")

ggplot(summaryTableMelted,aes(x = sampleShort, y = value)) + 
  geom_bar(aes(fill=variable), stat="identity",position = "dodge") +
  xlab("Sample") + ylab("Percentage") +
  scale_fill_manual(name="", values=cbPalette) +
  ggtitle("Percentage target bases")

#Plot bait and target interval files.
plot(0:10, type = "n", xaxt="n", yaxt="n", bty="n", xlab = "", ylab = "")
text(5, 8, paste("Bait interval file =",levels(summaryTable$baitIntervals), sep=" "))
text(5, 7, paste("Target interval file= ", levels(summaryTable$targetIntervals), sep=" "))

dev.off() #close pdf

#Generate .html based on R Markdown
knit("plotHSMetric.Rmd")
markdownToHTML('plotHSMetric.md', 'plotHSMetric.html', options=c("use_xhml"))

#Transpose and write table
summaryTableT = t(summaryTable)
write.table(summaryTableT, file="HSMetric_summary_transposed.txt", sep="\t", col.names=FALSE, row.names=FALSE, na="", quote=FALSE)
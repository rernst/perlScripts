### Plot metrics in HSMetric_summary file
require(ggplot2)
require(knitr)
require(markdown)
require(reshape)

# Parse command line arguments
args<-commandArgs(trailingOnly=TRUE)
fileName = args[1]
rootDir = args[2]
runName = args[3]
#fileName = "HSMetric_summary.txt" # testing
#rootDir = "." #testing

#Read in table
summaryTable = read.table(file=fileName, sep="\t", header=TRUE, stringsAsFactors=FALSE)
summaryTableMelted = melt(summaryTable[,c('sampleShort','PCT_TARGET_BASES_2X','PCT_TARGET_BASES_10X','PCT_TARGET_BASES_20X','PCT_TARGET_BASES_30X','PCT_TARGET_BASES_40X','PCT_TARGET_BASES_50X','PCT_TARGET_BASES_100X')],id.vars = 1)

#Custom colorscale used for plotting
cbPalette <- c("#999999", "#E69F00", "#56B4E9", "#009E73", "#F0E442", "#0072B2", "#D55E00", "#CC79A7")

#Plot metrics to pdf file.
pdf(paste(runName,"picardMetrics.pdf", sep="."), width=20, height=10)

for(i in 1:nrow(summaryTable)) {
  sample = paste(summaryTable[i,]$sample, summaryTable[i,]$sample, sep="/")
  
  insert_size_metrics = paste(sample,"_MERGED_sorted_dedup_MultipleMetrics.txt.insert_size_metrics", sep="")
  quality_by_cycle_metrics = paste(sample,"_MERGED_sorted_dedup_MultipleMetrics.txt.quality_by_cycle_metrics", sep="")
  quality_distribution_metrics = paste(sample,"_MERGED_sorted_dedup_MultipleMetrics.txt.quality_distribution_metrics", sep="")
  
  insert_size_metrics.table = read.table(file=insert_size_metrics, skip=8, head=TRUE)
  quality_by_cycle_metrics.table = read.table(file=quality_by_cycle_metrics, head=TRUE)
  quality_distribution_metrics.table = read.table(file=quality_distribution_metrics, head=TRUE)
  
  print(ggplot(insert_size_metrics.table, aes(x=insert_size, y=All_Reads.fr_count)) + 
    geom_bar(stat="identity", width=1, fill="#0072B2") +
    xlab("Insert size") + ylab("Count") +
    scale_fill_manual(name="", values=cbPalette)+
    ggtitle(paste("Insert size for all reads in", summaryTable[i,]$sample, sep=" ")))
  
  print(ggplot(quality_by_cycle_metrics.table, aes(x=CYCLE, y=MEAN_QUALITY)) + 
    geom_bar(stat="identity", width=1, fill="#0072B2") +
    xlab("Cycle") + ylab("Mean Quality") +
    scale_fill_manual(name="", values=cbPalette)+
    ggtitle(paste("Quality by cycle in", summaryTable[i,]$sample, sep=" ")))
  
  print(ggplot(quality_distribution_metrics.table, aes(x=QUALITY, y=COUNT_OF_Q)) + 
    geom_bar(stat="identity", fill="#0072B2") +
    xlab("Quality Score") + ylab("Observations") +
    scale_fill_manual(name="", values=cbPalette)+
    ggtitle(paste("Quality score distribution in", summaryTable[i,]$sample, sep=" ")))
}

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
text(5, 8, paste("Bait interval file =",unique(summaryTable$baitIntervals), sep=" "))
text(5, 7, paste("Target interval file= ", unique(summaryTable$targetIntervals), sep=" "))

dev.off() #close pdf

#Generate .html based on R Markdown
workingDir = getwd()
knit(paste(rootDir,"plotIlluminaMetrics_markdown.Rmd", sep="/"))
markdownToHTML("plotIlluminaMetrics_markdown.md", paste(runName,"picardMetrics.html",sep="."), options=c("use_xhml"))

#Transpose and write table
summaryTableT = t(summaryTable)
write.table(summaryTableT, file=paste(runName,"HSMetric_summary.transposed.txt", sep="."), col.names=FALSE, na="", quote=FALSE, sep="\t")
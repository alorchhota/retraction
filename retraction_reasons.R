### function to get reasons from a retraction xml file
get_reasons <- function(fn){
  require(xml2)
  # read xml
  data = read_xml(fn, as_html = T)
  # find all div nodes
  nodes<-xml_find_all(data, ".//div")
  # filter out the nodes where the attribute class="rReason"
  nodes<-nodes[which(xml_attr(nodes, "class") == "rReason")]
  # get values (as character strings)
  reasons = xml_text(nodes)
  reasons = sub(pattern = "\\+", replacement = "", x = reasons)
  return(reasons)
}

### function to get the number of retracted papers
get_number_of_retractions <- function(fn){
  require(xml2)
  # read xml
  data = read_xml(fn, as_html = T)
  # find all div nodes
  nodes<-xml_find_all(data, ".//tr")
  # filter out the nodes where the attribute class="rReason"
  nodes<-nodes[which(xml_attr(nodes, "class") == "mainrow")]
  # get total number of entries
  n_entries <- length(nodes)
  return(n_entries)
}

### files and labels
retraction_files = list.files(path = "data/", pattern = "*.xml", full.names = T)
retraction_labels = gsub(x = basename(retraction_files), pattern = "_[0-9]+_entries.xml$|.xml$", replacement = "")

### read retraction files
n_retractions = sapply(retraction_files, get_number_of_retractions)
names(n_retractions) = retraction_labels
reasons = lapply(retraction_files, get_reasons)
names(reasons) = retraction_labels

### add overall reasons
overall_field_labels = retraction_labels[! retraction_labels %in% c("nature_science_cell_all_time", "jhu_affiliation_all_time") ]
overall_n_retraction = sum(n_retractions[overall_field_labels])
overall_reasons = unlist(reasons[overall_field_labels])

retraction_labels[length(retraction_labels) + 1] = "overall"
n_retractions["overall"] = overall_n_retraction
reasons[["overall"]] = overall_reasons

### get top reasons in each field
n_top_reasons = 10
top_reasons = lapply(reasons, function(rs){
  counts = table(rs)
  counts = counts[order(counts, decreasing = T)]
  counts =counts[seq_len(n_top_reasons)]
  return(counts)
})

### plot
library(ggplot2)
plt_fn = "results/top_reasons_for_retractions.pdf"
pdf(plt_fn, width = 7, height = 4)
for(lbl in retraction_labels){
  tr = top_reasons[[lbl]]
  plt_df = data.frame(reason = factor(names(tr), levels = names(tr)[order(tr)]), 
                      count = as.numeric(tr),
                      count_label = sprintf("%s/%s", as.numeric(tr), n_retractions[lbl]),
                      stringsAsFactors = F)
  g <- ggplot(data=plt_df, aes(x=reason, y=count)) +
    geom_bar(stat="identity", fill="steelblue") + 
    geom_text(aes(label=count_label), hjust=1.1, color="white", size=3.5)+
    theme_bw() +
    xlab("") + 
    ylab("Number of retracted articles") + 
    ggtitle(sprintf("Top reasons: %s", lbl)) +
    coord_flip()
  print(g)
}
dev.off()
